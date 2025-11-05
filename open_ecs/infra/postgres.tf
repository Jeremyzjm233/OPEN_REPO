resource "random_string" "metadata_db_password" {
  length  = 32
  upper   = true
  numeric = true
  special = false
}

resource "aws_security_group" "postgres_public" {
  name        = "${var.project_name}-${var.environment}-postgres-public-sg"
  description = "Allow all inbound for Postgres"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.base_cidr_block}/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres-public-sg"
  }
}

resource "aws_db_subnet_group" "airflow_subnet_group" {
  name       = "${var.project_name}-${var.environment}-db-subnetgroup"
  subnet_ids = data.aws_subnets.public_subnets.ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnetgroup"
  }
}

resource "aws_db_instance" "metadata_db" {
  identifier             = "${var.project_name}-${var.environment}-postgres"
  db_name                = "airflow"
  instance_class         = var.metadata_db_instance_type
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "13"
  skip_final_snapshot    = true
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.airflow_subnet_group.id
  vpc_security_group_ids = [aws_security_group.postgres_public.id]
  username               = "airflow"
  password               = random_string.metadata_db_password.result

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}
