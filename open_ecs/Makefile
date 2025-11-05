# App defaults
ACCOUNT_TYPE ?= nonprod
APP_NAME ?= ac-shopping-airflow
AWS_REGION ?= ap-southeast-2
AWS_DEFAULT_REGION ?= $(AWS_REGION)
STATE_STORE_BUCKET_NAME=ac-shopping-tf-state
STATE_STORE_BUCKET_KEY_NAME=$(APP_NAME)/$(ACCOUNT_TYPE).tfstate
AWS_ACCOUNT_NUMBER := $(shell aws sts get-caller-identity | python3 -c "import sys, json; print(json.load(sys.stdin)['Account'])")
# Export variables into child processes
ECR_IMAGE_NAME =data-service-airflow-dev
.EXPORT_ALL_VARIABLES:

airflow-up:
	docker-compose up --build -d

airflow-down:
	docker-compose down
	
plan:
	bash scripts/execute.sh plan

apply:
	bash scripts/execute.sh apply

destroy:
	bash scripts/execute.sh destroy

build-image:
	bash scripts/execute.sh build-image

clean:
	rm -r postgres_data
