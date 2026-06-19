//Declare S3 bucket resource
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "Jenkins Artifacts"
    Environment = "DevSecOps"
  }
}


//Block All Public Access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "jenkins_artifacts_block" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


//Enable versioning on the S3 bucket
resource "aws_s3_bucket_versioning" "jenkins_artifacts_versioning" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}


//Enable object ownership to bucket owner ACL Disabled
resource "aws_s3_bucket_ownership_controls" "jenkins_artifacts_ownership" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


//Enable server-side encryption with SSE-KMS with default AWS managed key for S3 KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "jenkins_artifacts_encryption" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}


//Enable bucket lifecycle policy that aborts incomplete multipart uploads after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "jenkins_artifacts_lifecycle" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  rule {
    id     = "AbortIncompleteMultipartUpload"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}