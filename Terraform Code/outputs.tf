//output s3 bucket name
output "s3_bucket_name" {
  description = "The name of the S3 bucket to store Jenkins artifacts"
  value       = aws_s3_bucket.jenkins_artifacts.bucket
}