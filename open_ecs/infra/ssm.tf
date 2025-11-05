# resource "aws_ssm_parameter" "ecs_task_sg_ssm" {
#   name  = "/${var.project_name}/security_group_id"
#   type  = "SecureString"
#   value = aws_security_group.jdbc_fargate_sg.id
#   # overwrite = true
#   tags = module.tags.tags
# }

resource "aws_ssm_parameter" "ecs_task_subnet_ssm" {
  name      = "/${var.project_name}/subnet_ids"
  type      = "SecureString"
  value     = join(",", data.aws_subnets.public_subnets.ids)
  overwrite = true
}

# resource "aws_ssm_parameter" "ecs_task_definition_arn_ssm" {
#   name  = "/${var.project_name}/task_definition_arn"
#   type  = "SecureString"
#   value = aws_ecs_task_definition.jdbc_task_definition.arn
#   # overwrite = true
#   tags = module.tags.tags
# }
