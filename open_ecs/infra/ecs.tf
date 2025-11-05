resource "aws_ecr_repository" "docker_repository" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_lifecycle_policy" "docker_repository_lifecycly" {
  repository = aws_ecr_repository.docker_repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep only the latest 5 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 5
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.log_group_name}/${var.project_name}-${var.environment}"
  retention_in_days = 5
}

resource "aws_iam_role" "ecs_task_iam_role" {
  name        = "${var.project_name}-${var.environment}-ecs-task-role"
  description = "Allow ECS tasks to access AWS resources"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "ecs_task_policy" {
  name = "${var.project_name}-${var.environment}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/*"
    },
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "dynamodb:*",
        "elasticmapreduce:*",
        "s3:*",
        "ssm:*",
        "glue:*",
        "sqs:*",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds",
        "secretsmanager:ListSecrets",
        "ec2:DescribeSubnets",
        "redshift:GetClusterCredentials",
        "redshift-data:*",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "logs:FilterLogEvents",
        "logs:DescribeLogGroups",
        "logs:GetLogEvents",
        "logs:CreateLogGroup",
        "ecs:StartTelemetrySession",
        "ecs:PutAttributes",
        "ecs:ListAttributes",
        "ecs:ExecuteCommand",
        "ecs:UpdateContainerInstancesState",
        "ecs:StartTask",
        "ecs:RegisterContainerInstance",
        "ecs:DescribeTaskSets",
        "ecs:DescribeTaskDefinition",
        "ecs:ListServices",
        "ecs:Poll",
        "ecs:DescribeCapacityProviders",
        "ecs:RunTask",
        "ecs:ListTasks",
        "ecs:StopTask",
        "ecs:DescribeServices",
        "ecs:SubmitContainerStateChange",
        "ecs:DescribeContainerInstances",
        "ecs:TagResource",
        "ecs:DescribeTasks",
        "ecs:UntagResource",
        "ecs:ListTaskDefinitions",
        "ecs:ListClusters",
        "ecs:SubmitTaskStateChange",
        "ecs:DiscoverPollEndpoint",
        "ecs:UpdateClusterSettings",
        "ecs:DescribeClusters",
        "ecs:ListAccountSettings",
        "ecs:ListTagsForResource",
        "ecs:ListTaskDefinitionFamilies",
        "ecs:UpdateContainerAgent",
        "ecs:ListContainerInstances",
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:DescribeLogStreams",
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
        "xray:GetSamplingStatisticSummaries",
        "glue:StartCrawler",
        "glue:GetCrawler",
        "glue:GetCrawlerMetrics",
        "dms:DescribeReplicationTasks",
        "dms:StartReplicationTask",
        "dms:StopReplicationTask"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ecs_task_iam_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}
