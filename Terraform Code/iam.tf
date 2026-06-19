// Create IAM policy document for S3 bucket upload access
data "aws_iam_policy_document" "s3_upload_policy" {
  statement {
    sid    = "ArtifactBucketAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::devsecops-jenkins-artifacts-sun",
      "arn:aws:s3:::devsecops-jenkins-artifacts-sun/*",
    ]
  }

  statement {
    sid    = "IaCTestDeployPermissions"
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "s3:ListAllMyBuckets",
    ]

    resources = ["*"]
  }
}


//Create IAM role named "JenkinsPipelineExecutionRole" to be assumed by Jenkins pipeline for executing pipeline steps
resource "aws_iam_role" "jenkins_pipeline_execution_role" {
  name = "JenkinsPipelineExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      } 
    ]
  })

}


//Attach the S3 upload policy to the IAM role named "JenkinsPipelineExecutionRole"
resource "aws_iam_policy" "s3_upload_policy" {
  name        = "JenkinsS3UploadPolicy"
  description = "IAM policy to allow Jenkins pipeline to upload artifacts to S3 bucket"
  policy      = data.aws_iam_policy_document.s3_upload_policy.json
}


//Attach the "JenkinsS3UploadPolicy" to the IAM role named "JenkinsPipelineExecutionRole"
resource "aws_iam_role_policy_attachment" "s3_upload_policy_attachment" {
  role       = aws_iam_role.jenkins_pipeline_execution_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
}

//Create IAM Instance profile named "JenkinsPipelineExecutionInstanceProfile" to be associated with EC2 instances launched by Jenkins pipeline for executing pipeline steps
resource "aws_iam_instance_profile" "jenkins_pipeline_execution_instance_profile" {
  name = "JenkinsPipelineExecutionInstanceProfile"
  role = aws_iam_role.jenkins_pipeline_execution_role.name
}