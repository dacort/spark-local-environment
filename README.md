# PySpark Local Environment

This is a repository you can clone to easily setup a local PySpark environment for interacting with data on Amazon S3.

It was inspired by this post on Reddit: [(RANT) I think I'll die trying to setup and run Spark with Python in my local environment : dataengineering](https://www.reddit.com/r/dataengineering/comments/10njfnd/rant_i_think_ill_die_trying_to_setup_and_run/)

## Getting Started

> **Note**: The following commands require you to have Docker installed
> Optionally, you can also have Jupyter, VS Code, and AWS credentials

- Build the image

```bash
docker build -t local-spark .
```

- Start a shell in the container

```bash
docker run -it local-spark
```

Now that you're running in the container, you can set AWS credentials to access S3, run `spark-shell` or `pyspark`.

You can also spin up `jupyter server` if you want to connect a notebook.

```
docker run --rm -it -p 8888:8888 local-spark -c "jupyter server --ip='*'"
```

## Configuration

If you want, you can specify a different EMR release version. For example, to get Spark 3.4.0, use EMR 6.12.0 by providing a `--build-arg`.

```bash
docker build --build-arg EMR_RELEASE=6.12.0 -t local-spark:emr-6.12.0 .
docker run -it local-spark:emr-6.12.0
```
