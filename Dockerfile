# BUILD: docker build --rm -t airflow .
# ORIGINAL SOURCE: https://github.com/puckel/docker-airflow

# FROM --platform=linux/amd64 python:3.9-slim
FROM  --platform=linux/amd64 python:3.9-slim
LABEL version="1.1"
LABEL maintainer="datasquad"

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
# it's possible to use v1-10-stable, but it's a development branch
ARG AIRFLOW_VERSION=2.9.2
ENV AIRFLOW_HOME=/usr/local/airflow
ENV AIRFLOW_GPL_UNIDECODE=yes
# celery config
ARG CELERY_REDIS_VERSION=5.4.0
ARG PYTHON_REDIS_VERSION=5.0.4

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

COPY constraints.txt .

RUN set -ex \
    && buildDeps=' \
    python3-dev \
    libkrb5-dev \
    libsasl2-dev \
    libssl-dev \
    libffi-dev \
    build-essential \
    libblas-dev \
    liblapack-dev \
    libpq-dev \
    git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
    ${buildDeps} \
    sudo \
    python3-pip \
    python3-requests \
    default-mysql-client \
    default-libmysqlclient-dev \
    apt-utils \
    curl \
    rsync \
    locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install --constraint constraints.txt -U pip setuptools wheel \
    && pip install --constraint constraints.txt --no-cache-dir pytz \
    && pip install --constraint constraints.txt --no-cache-dir pyOpenSSL \
    && pip install --constraint constraints.txt --no-cache-dir ndg-httpsclient \
    && pip install --constraint constraints.txt --no-cache-dir pyasn1 \
    && pip install --constraint constraints.txt --no-cache-dir typing_extensions \
    # && pip install --constraint constraints.txt --no-cache-dir mysqlclient \
    && pip install --constraint constraints.txt --no-cache-dir apache-airflow[async,aws,crypto,celery,postgres,password,s3,slack]==${AIRFLOW_VERSION} \
    && pip install --constraint constraints.txt --no-cache-dir werkzeug \
    && pip install --constraint constraints.txt --no-cache-dir redis==${PYTHON_REDIS_VERSION} \
    && pip install --constraint constraints.txt --no-cache-dir celery[redis]==${CELERY_REDIS_VERSION} \
    && pip install --constraint constraints.txt --no-cache-dir flask_oauthlib \
    && pip install --constraint constraints.txt --no-cache-dir SQLAlchemy \
    && pip install --constraint constraints.txt --no-cache-dir Flask-SQLAlchemy \
    && pip install --constraint constraints.txt --no-cache-dir psycopg2-binary \
    && pip install --constraint constraints.txt --no-cache-dir tornado \
    && apt-get purge --auto-remove -yqq ${buildDeps} \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/man \
    /usr/share/doc \
    /usr/share/doc-base


COPY config/entrypoint.sh /entrypoint.sh
RUN sed -i -e 's/\r$//' /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN apt-get update && apt-get install -y \
    unzip \
    && curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
    && unzip awscli-bundle.zip \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    && rm -rf awscli-bundle awscli-bundle.zip


# COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg
# COPY app/dags ${AIRFLOW_HOME}/data/dags
# COPY app/plugins ${AIRFLOW_HOME}/data/plugins

RUN chown -R airflow: ${AIRFLOW_HOME}

ENV PYTHONPATH ${AIRFLOW_HOME}

USER airflow

RUN mkdir -p ${AIRFLOW_HOME}/data
RUN mkdir -p ${AIRFLOW_HOME}/data/dags
RUN mkdir -p ${AIRFLOW_HOME}/data/logs
RUN mkdir -p ${AIRFLOW_HOME}/data/plugins

COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg
# COPY config/webserver_config.py ${AIRFLOW_HOME}/data/webserver_config.py
COPY app/dags/ ${AIRFLOW_HOME}/data/dags/
COPY app/plugins/ ${AIRFLOW_HOME}/data/plugins/
EXPOSE 8080 8793

USER root

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

USER airflow
EXPOSE 8080 5555 8793

WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
