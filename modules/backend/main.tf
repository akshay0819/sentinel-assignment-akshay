locals {
  full_bucket_name     = "rapyd-sentinel-tf-state-${var.environment}-${var.region}"
  full_lock_table_name = "rapyd-sentinel-tf-lock-${var.environment}"
}

resource "aws_s3_bucket" "tf_backend" {
  bucket = local.full_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "tf-backend"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "tf_backend_versioning" {
  bucket = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.full_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "tf-lock"
    Environment = var.environment
  }
}
