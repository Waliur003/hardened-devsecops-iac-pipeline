// Define variables for the AWS region
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}


// Declare S3 bucket named "devsecops-jenkins-artifacts-sun"
variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store Jenkins artifacts"
  type        = string
  default     = "devsecops-jenkins-artifacts-sun"
}


//Declare Security group name for Jenkins pipeline execution role named "jenkins-security-gatekeeper-sg"
variable "jenkins_sg_name" {
  description = "The name of the security group for Jenkins pipeline execution role"
  type        = string
  default     = "jenkins-security-gatekeeper-sg"
}


//Declare variable for admin IP address to allow access to Jenkins pipeline execution role security group
variable "admin_ip" {
  description = "The IP address to allow access to Jenkins pipeline execution role security group"
  type        = string
  default     = "198.51.100.14/32"
}


////Declare variable for EC2 instance name for Jenkins pipeline execution role named "Jenkins-Security-Gateway"
variable "jenkins_ec2_instance_name" {
  description = "The name of the EC2 instance for Jenkins pipeline execution role"
  type        = string
  default     = "Jenkins-Security-Gateway"
}


//Declare variable for EC2 instance type for Jenkins pipeline execution role named "Jenkins-Security-Gateway"
variable "jenkins_ec2_instance_type" {
  description = "The EC2 instance type for Jenkins pipeline execution role"
  type        = string
  default     = "t3.medium"
}

//Declare variable for EC2 user data script for Jenkins pipeline execution role named "Jenkins-Security-Gateway"
variable "jenkins_ec2_user_data" {
  description = "The user data script for the EC2 instance for Jenkins pipeline execution role"
  type        = string
  default     = <<-EOT
# 1. Update repositories and deploy the Java 21 OpenJDK runtime environment
sudo apt update && sudo apt upgrade -y
sudo apt install openjdk-21-jre-headless -y
sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java

# 2. Download modern 2026 Jenkins repository signing keys to resolve NO_PUBKEY errors
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 3. Install Jenkins Automation Server and reset systemd fail counters
sudo apt update && sudo apt install jenkins -y
sudo systemctl reset-failed jenkins && sudo systemctl restart jenkins

# 4. Install Docker Engine and configure service group permissions
sudo apt install docker.io -y
sudo usermod -aG docker jenkins && sudo usermod -aG docker ubuntu

# 5. Install AWS CLI v2 for automated encrypted S3 artifact uploads
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 6. Resolve PEP-668 and install Checkov SAST globally via a Symlinked Virtual Environment
sudo apt install python3-pip python3-venv -y
sudo mkdir -p /opt/checkov
sudo chown -R ubuntu:ubuntu /opt/checkov
python3 -m venv /opt/checkov/venv

# Activate sandbox, install Checkov, and deactivate
source /opt/checkov/venv/bin/activate
pip install --upgrade pip setuptools
pip install checkov
deactivate

# Create the global system symlink so Jenkins can execute the scanner natively
sudo ln -sf /opt/checkov/venv/bin/checkov /usr/local/bin/checkov
EOT
}


//Declare variable for existing AWS key pair name to be used for EC2 instance launched by Jenkins pipeline for executing pipeline steps
variable "aws_key_name" {
  description = "The name of the existing AWS key pair to be used for EC2 instance launched by Jenkins pipeline for executing pipeline steps"
  type        = string
  default     = "proj4"
}