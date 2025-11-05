#!/bin/bash

set -eou pipefail

echo "APP_NAME is ${APP_NAME} and ACCOUNT_TYPE is ${ACCOUNT_TYPE}"

die() {
  echo "$2"
  exit "$1"
}

execute_terraform() {
  if which terraform13 2>/dev/null; then
    terraform13 $@
  else
    terraform $@
  fi
}

OPERATION=$1
PLAN_FILE="${APP_NAME}-${ACCOUNT_TYPE}.plan"

echo "Using tf state file ${STATE_STORE_BUCKET_NAME}/${STATE_STORE_BUCKET_KEY_NAME}"

export TF_VAR_account_type="${ACCOUNT_TYPE}"
export TF_VAR_app_name="${APP_NAME}"

if [[ $# != 1 ]]; then
  echo "Usage $(basename "${0}") <plan|apply|destroy>"
  exit 101
fi

cd "infra/"
execute_terraform init \
  -no-color \
  -reconfigure \
  -backend-config "region=${AWS_DEFAULT_REGION}" \
  -backend-config "bucket=${STATE_STORE_BUCKET_NAME}" \
  -backend-config "key=${STATE_STORE_BUCKET_KEY_NAME}" 

case $OPERATION in
build-image)
  cd ..
  echo Logging in to Amazon ECR...
  aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_NUMBER}.dkr.ecr.ap-southeast-2.amazonaws.com
  echo Building the Docker image...     
  docker build -t ${ECR_IMAGE_NAME}:latest .
  docker tag ${ECR_IMAGE_NAME}:latest 721495903582.dkr.ecr.ap-southeast-2.amazonaws.com/${ECR_IMAGE_NAME}:latest
  echo Pushing the Docker image...
  docker push ${AWS_ACCOUNT_NUMBER}.dkr.ecr.ap-southeast-2.amazonaws.com/${ECR_IMAGE_NAME}:latest
  ;;
plan)
  execute_terraform plan \
    -no-color \
    -parallelism=1000 \
    -out "$PLAN_FILE" 
  ;;
apply)
  execute_terraform apply \
    -no-color \
    -auto-approve \
    -input=false \
    -parallelism=1000 
  ;;
destroy)
  execute_terraform destroy \
    -no-color \
    -auto-approve 
  ;;
*)
  die 102 "Unknown OPERATION: $OPERATION"
  ;;
esac
