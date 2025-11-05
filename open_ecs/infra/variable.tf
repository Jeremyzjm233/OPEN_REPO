variable "aws_region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_name" {
  type    = string
  default = "ac-shopping-data-nonprod-vpc"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "project_name" {
  type    = string
  default = "data-service-airflow"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "base_cidr_block" {
  type    = string
  default = "10.0.0.0"
}

variable "log_group_name" {
  type    = string
  default = "ecs/fargate"
}

variable "image_version" {
  type    = string
  default = "latest"
}

variable "metadata_db_instance_type" {
  type    = string
  default = "db.m5.large"
}

variable "celery_backend_instance_type" {
  type    = string
  default = "cache.t2.small"
}

variable "terraform_state_file_bucket" {
  type    = string
  default = "ac-shopping-terraform-state"

}

variable "terraform_state_file_key" {
  type    = string
  default = "airflow_ecs.tfstate"

}
