ARG EMR_RELEASE=6.9.0

FROM public.ecr.aws/emr-serverless/spark/emr-$EMR_RELEASE:latest

USER root

# Install sudo in case the user needs to install packages
RUN yum install -y sudo && yum clean all
RUN echo -e 'hadoop ALL=(ALL)NOPASSWD:ALL' > /etc/sudoers.d/hadoop

# Remove the custom resource manager and spark master
RUN sed -Ei 's/^(spark\.submit\.customResourceManager)/#\1/' /etc/spark/conf/spark-defaults.conf
RUN sed -Ei 's/spark\.master.*/spark.master\tlocal[*]/' /etc/spark/conf/spark-defaults.conf

# Enable the Spark UI
RUN sed -Ei 's/^spark\.ui\.enabled.*/spark.ui.enabled\ttrue/' /etc/spark/conf/spark-defaults.conf

# Use the Glue Data Catalog
RUN echo -e "\n# Enable Glue Data Catalog\nspark.sql.catalogImplementation\thive\nspark.hadoop.hive.metastore.client.factory.class\tcom.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory\n" >> /etc/spark/conf/spark-defaults.conf

# Upgrade to AWS CLI v2
RUN yum install -y git unzip
RUN if [ "$TARGETARCH" = "arm64" ]; then curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; else curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; fi && \
     unzip awscliv2.zip && \
     ./aws/install && \
     rm -rf aws awscliv2.zip

# ipykernel depends on pusutil, which does not publish wheels for aarch64
RUN if [ "$TARGETARCH" != "amd64" ]; then yum install -y gcc python3-devel; fi

# Upgrade pip first
RUN python3 -m pip install -U pip

# Enable Jupyter notebooks - can be used when running in a devcontainer or by exposing 8080 and running jupyter server
ENV PATH "/home/hadoop/.local/bin:$PATH"
RUN python3 -m pip install ipykernel jupyter-server
EXPOSE 8080

# Add the gcs connector as well
ADD https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar /usr/share/google/gcs-connector/
RUN chmod -R a+rX /usr/share/google
RUN sed -Ei 's/(spark.driver.extraClassPath.*)$/\1:\/usr\/share\/google\/gcs-connector\/gcs-connector-hadoop3-latest.jar/' /etc/spark/conf/spark-defaults.conf
RUN echo -e "\n#Enable GCS connector\nspark.hadoop.fs.gs.impl\tcom.google.cloud.hadoop.fs.gcs.GoogleHadoopFileSystem\nspark.hadoop.google.cloud.auth.service.account.enable\ttrue\nspark.hadoop.google.cloud.auth.service.account.json.keyfile\t/home/hadoop/.gcp/keyfile.json" >> /etc/spark/conf/spark-defaults.conf
RUN mkdir /home/hadoop/.gcp/ && touch /home/hadoop/.gcp/keyfile.json && chown -R hadoop:hadoop /home/hadoop/.gcp/
# Use with docker run --rm -it -v yourfilefile.json:/home/hadoop/.gcp/keyfile.json spark-local
# This article has a good guide on getting your keyfile https://kashif-sohail.medium.com/read-files-from-google-cloud-storage-bucket-using-local-pyspark-and-jupyter-notebooks-f8bd43f4b42e
# Sample data: df = spark.read.csv("gs://nmfs_odp_afsc/RACE/FBEP/") https://cloud.google.com/blog/products/data-analytics/noaa-datasets-on-google-cloud-for-environmental-exploration

# Jupyter server: python3 -m pip install jupyter-server && export PATH=$PATH:/home/hadoop/.local/bin && jupyter server

USER hadoop:hadoop

ENTRYPOINT [ "/bin/bash" ]