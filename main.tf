provider "aws" {
  region = "us-east-1"  # Same region as before
}

# 1. Create the S3 Bucket (for Terraform state)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "rgers3.tfstate-backend[0].com"  # Must be globally unique
  force_destroy = true  # Optional: Allows deletion even if not empty
}

# 2. Enable Versioning (Critical for state recovery)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Block ALL Public Access (MUST for state buckets)
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.terraform_state.id

  # Block ALL public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. (Optional) Add Encryption (Recommended)
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # AWS-managed key
    }
  }
}

# 5. (Optional) State Locking with DynamoDB (Prevent conflicts)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}