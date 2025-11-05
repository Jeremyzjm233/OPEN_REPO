# resource "aws_s3_bucket" "terraform-state" {
#   bucket = var.terraform_state_file_bucket

#   lifecycle {
#     prevent_destroy = false

#   }
#   #Enable versioning
#   versioning {
#     enabled = false
#   }
#   #Enable server side encryption
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"

#       }

#     }

#   }

# }
