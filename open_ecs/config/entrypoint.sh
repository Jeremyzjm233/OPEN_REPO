#!/bin/bash
# export FERNET_KEY=$(aws ssm get-parameter --name "/${SERVICE_NAME}/fernet_key" --region "${AWS_REGION}" --with-decryption --query 'Parameter.Value' --output text)
# export POSTGRES_USER=$(aws ssm get-parameter --name "/${SERVICE_NAME}/rds_username" --region "${AWS_REGION}" --query 'Parameter.Value' --output text)

export AIRFLOW_USERNAME=admin
export AIRFLOW_EMAIL=datasquad645@gmail.com
export AIRFLOW_PASSWORD=admin
case "$1" in
  webserver)
    export REDIS_HOST=${REDIS_HOST}
    export REDIS_PORT=${REDIS_PORT}
    airflow db init
		sleep 15
    airflow users delete -u $AIRFLOW_USERNAME
    airflow users create -r Admin -u $AIRFLOW_USERNAME -e $AIRFLOW_EMAIL -f admin -l user -p $AIRFLOW_PASSWORD
    exec airflow webserver >> /dev/stdout
    ;;
  scheduler)
    export REDIS_HOST=${REDIS_HOST}
    export REDIS_PORT=${REDIS_PORT}
    sleep 15
    exec airflow "$@" >> /dev/stdout
    ;;
  worker)
    export REDIS_HOST=${REDIS_HOST}
    export REDIS_PORT=${REDIS_PORT}
    exec airflow celery worker >> /dev/stdout 
    ;;
  flower)
  export REDIS_HOST=${REDIS_HOST}
  export REDIS_PORT=${REDIS_PORT}
  exec airflow celery flower >> /dev/stdout 
  ;;
  triggerer)
    export REDIS_HOST=${REDIS_HOST}
    export REDIS_PORT=${REDIS_PORT}
    sleep 15
    exec airflow "$@" >> /dev/stdout
    ;;
  version)
    exec airflow "$@"
    ;;
  *)
    exec "$@"
    ;;
esac
