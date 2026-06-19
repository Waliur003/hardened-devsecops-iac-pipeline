//Create Data Blcok for EC2 Ubuntu Auto LTS AMI so that we can use the latest Ubuntu Auto LTS AMI for our EC2 instances launched by Jenkins pipeline for executing pipeline steps
data "aws_ami" "ubuntu_auto_lts" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical
}


// Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

// Fetch the subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


//Create Data Block for AWS IAM policy document to define the S3 upload policy for Jenkins pipeline execution role
resource "aws_instance" "jenkins_security_gateway" {
  ami                    = data.aws_ami.ubuntu_auto_lts.id
  instance_type          = var.jenkins_ec2_instance_type
  
  # Use the first default subnet dynamically
  subnet_id              = data.aws_subnets.default.ids[0]
  
  # Reference the security group created for Jenkins pipeline execution role
  vpc_security_group_ids = [aws_security_group.jenkins_security_gatekeeper_sg.id]

  # Reference a variable for your existing key pair
  key_name               = var.aws_key_name
  associate_public_ip_address = true
  user_data              = var.jenkins_ec2_user_data

  tags = {
    Name        = var.jenkins_ec2_instance_name
    Environment = "DevSecOps"
  }
}