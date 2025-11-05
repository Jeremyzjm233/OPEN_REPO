resource "aws_dynamodb_table" "terraform_locks" {
  hash_key = "LockID"
  name = "terraform-locks-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}