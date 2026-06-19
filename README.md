# Cloud Security Engineering Project 04: Hardened DevSecOps Pipeline (CI/CD Security & Infrastructure Gatekeeping)

## Overview

I have architected and deployed a production-grade, shift-left DevSecOps continuous integration pipeline designed to automatically intercept and block vulnerable Infrastructure as Code (IaC) deployments before they reach the cloud environment. By orchestrating a Jenkins automation server equipped with the Checkov Static Application Security Testing (SAST) engine, this project establishes a mandatory security gate for all Terraform configurations. The architecture eliminates static credential vulnerabilities via AWS IAM Instance Profiles and archives compliant, verified deployment packages into a tightly locked, KMS-encrypted Amazon S3 vault.

## The Problem

Traditional infrastructure provisioning relies heavily on manual security reviews and post-deployment auditing, which consistently exposes cloud environments to severe operational risks:

* **Static Credential Exposure Liabilities:** Hardcoding long-lived AWS Access Keys or Secret Keys inside build automation dashboards or Git configuration directories creates a high-severity risk vector for lateral workspace compromise if the application repository is breached.

* **Unvalidated Vulnerability Propagation:** Deploying raw Terraform files without automated scanning allows critical misconfigurations, such as public S3 buckets, missing encryption protocols, or open security groups, to be provisioned directly into live production environments.

* **Pipeline Parsing Failures:** Misconfigured package dependencies, stale GPG signing keys, and strict operating system Python environment limits frequently cause automation daemons to crash, disrupting the software delivery lifecycle.

## The Solution

* **Zero-Static-Credential Identity Scoping:** Completely eliminated legacy hardcoded authentication tokens by attaching a strictly scoped AWS IAM Instance Profile to the underlying EC2 build node, granting it dynamic, temporary permissions to upload artifacts securely.

* **Fail-Fast Security Validation Gates:** Integrated the Checkov static analysis framework directly into the Jenkins pipeline to parse configuration files, intercepting AWS compliance violations and forcing an immediate build failure if baseline drift is detected.

* **Secure Artifact Vaulting:** Engineered a hardened Amazon S3 artifact warehouse enforcing AES-256 KMS Server-Side Encryption and absolute Public Access Blocks to safely store verified infrastructure delivery packages.

* **Robust Host Bootstrapping:** Overcame strict Ubuntu 24.04 LTS PEP-668 package constraints by isolating the Python scanning engine within a global symlinked virtual environment, and successfully rotated outdated Jenkins repository keys to maintain stable package integrity.

## Tech Stack

* **Automation Engine:** Jenkins Continuous Integration Server

* **Vulnerability Framework:** Checkov (Prisma Cloud SAST Engine)

* **Storage Registry:** Amazon S3 (SSE-KMS Encrypted Artifact Vault)

* **Compute Hosting:** Amazon EC2 (Ubuntu Server 24.04 LTS)

* **Identity Governance:** AWS IAM (Instance Profiles & Scoped Policies)

* **IaC Engine:** Terraform (v1.0+ / High-Availability Declarative Syntax)

* **Scripting:** Groovy (Declarative Pipelines), Bash, AWS CLI v2

## Architecture Diagram

[Placeholder: Architecture Diagram showing Local Commit -> Jenkins EC2 -> Checkov Scan -> IAM Profile Auth -> S3 Encrypted Upload]

## Project Procedure

### 1. Zero-Trust Identity & Artifact Vault Provisioning

I engineered a secure Amazon S3 bucket to act as the artifact repository, configuring it with default AWS KMS encryption and blocking all public access. To allow the pipeline to communicate with this vault safely, I created an IAM Role restricted purely to S3 Put/Get/List actions and bound it to an IAM Instance Profile.

### 2. Compute Host Deployment & Firewall Hardening

I provisioned a dedicated t3.medium Amazon EC2 instance running Ubuntu 24.04 LTS, attaching the IAM Instance Profile. I secured the perimeter via a Security Group that blocked all global inbound traffic, restricting SSH (Port 22) and Jenkins Web UI (Port 8080) access exclusively to verified administrative IP ranges.

### 3. Automated Environment Bootstrapping & Checkov Configuration

I established a secure shell session into the EC2 node and executed a comprehensive configuration runlist. This sequence resolved package dependencies, deployed Java 21, updated GPG signing keys, installed the AWS CLI, and bypassed Ubuntu's Python environment restrictions to install Checkov globally.

System Bootstrap Execution Script:

```bash
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
```

### 4. Declarative Security Gatekeeper Pipeline

I authored a custom Jenkinsfile utilizing native writeFile primitives to inject a Terraform infrastructure blueprint into the workspace. The pipeline executes Checkov with the --compact flag, evaluating the code against AWS security baselines before compressing and uploading the artifacts to S3.

## Infrastructure as Code (IaC) Architecture

To preserve absolute repeatability and environment portability, the backend system layout is provisioned using version-locked Terraform configurations.

## Directory Layout & Modular Structure

```text
hardened-devsecops-iac-pipeline/
├── provider.tf          # Core initialization and global provider tag constraints
├── variables.tf         # Abstracted input variable types and network parameters
├── s3.tf                # Artifact vault definitions, KMS encryption, and access blocks
├── iam.tf               # Machine profiles, trust relationships, and scoped S3 policies
├── security_groups.tf   # Ingress firewall rules locking administrative ports
├── ec2.tf               # Compute node sizing, profile attachment, and network mapping
└── outputs.tf           # Interactive connection strings and tracking endpoints
```

## Detailed File-by-File Technical Breakdown

### System Provider Scoping (`provider.tf`)

Restricts the compilation environment to the standard AWS Provider v5.0+ module tree and embeds a centralized tagging definition.

### Variable Abstractions (`variables.tf`)

Parameterizes the artifact bucket name and management IP addresses, keeping code decoupled from hardcoded strings.

### Artifact Vault Engineering (`s3.tf`)

Provisions the backend bucket with forced server-side encryption and absolute public access blocks to guarantee artifact confidentiality.

### Zero-Trust Access Control (`iam.tf`)

Establishes an un-aliased execution role restricted strictly to the EC2 service principal and attaches it to an instance profile, enabling secure credential injection onto the host.

### Automation Compute Architecture (`ec2.tf & security_groups.tf`)

Provisions the core EC2 instance and stateful firewall, ensuring the host possesses the resources to run heavy compilation threads while blocking public internet scanning bots.

## Verification and Results

### Verified Pipeline Defensive Block (The Red Build)

Injected a raw, unhardened S3 bucket configuration into the pipeline. Monitoring logs verified that the integrated Checkov security scanner immediately intercepted 7 critical vulnerabilities (including disabled versioning and missing encryption), failed the build parameters, and terminated the delivery workflow prior to artifact archiving.

### Verified Automated Remediation Execution

Updated the pipeline IaC template to include aws_s3_bucket_server_side_encryption_configuration, strict aws_s3_bucket_public_access_block restrictions, and properly nested # checkov:skip directives for optional compliance rules.

### Verified Successful Artifact Deployment (The Green Build)

Executed the patched code block. Checkov returned a clean scan. The pipeline smoothly advanced, leveraged its native IAM Instance Profile to authenticate without static credentials, and successfully uploaded the archive directly into the Amazon S3 vault.

## Verification Screenshots

### 1. The "Red Build" – SAST Engine Intercepting Vulnerabilities

**What this shows:** The Jenkins console output during the initial pipeline run containing an intentionally vulnerable Terraform configuration.

**Technical Proof:** Demonstrates the Checkov SAST engine successfully parsing the IaC, identifying 7 critical security violations (e.g., missing KMS encryption, open public access), throwing an exit code 1, and safely aborting the deployment before the infrastructure could be built.

<img width="1905" height="2547" alt="Screenshot 1" src="https://github.com/user-attachments/assets/94545b8c-9f47-412f-a938-c72a05c0aca4" />


### 2. The "Green Build" – 100% Compliant Infrastructure

**What this shows:** The Jenkins console output after patching the Terraform configuration with automated remediations.

**Technical Proof:** Displays the Prisma Cloud scan results registering 13 Passed checks, 0 Failed checks, and 3 properly Skipped checks. This proves the ability to write hardened IaC that satisfies rigorous enterprise compliance frameworks.

<img width="1896" height="3179" alt="Screenshot 2" src="https://github.com/user-attachments/assets/1ebe741f-1b5e-402c-ab16-29f44585db72" />


### 3. Secure Artifact Deployment via Machine Identity

**What this shows:** The final stage of the successful Jenkins pipeline execution.

**Technical Proof:** Validates that the aws s3 cp command executed flawlessly, compressing the compliant .tf files and uploading the terraform-deployment.tar.gz artifact directly into the encrypted Amazon S3 vault.

<img width="1919" height="910" alt="Screenshot 3" src="https://github.com/user-attachments/assets/25177f43-0d4d-4a41-ae13-93ba58942878" />


### 4. Zero-Trust Architecture – IAM Instance Profile Binding

**What this shows:** The Amazon EC2 dashboard view of the Jenkins build node.

**Technical Proof:** Highlights the JenkinsPipelineExecutionRole attached directly to the underlying compute instance. This verifies the zero-trust identity architecture, proving that the pipeline authenticates to S3 dynamically via the AWS Metadata Service without relying on dangerous, hardcoded Access Keys.

<img width="1919" height="909" alt="Screenshot 4" src="https://github.com/user-attachments/assets/d0e42d08-e031-4a64-be2f-443eebb09ae9" />


## Future Improvements

* **Git Webhook Integration:** Connect the Jenkins orchestrator directly to a private source repository via HTTPS webhook triggers to automatically launch the SAST scanning loop on every single code commit.

* **Dynamic Communication Alerts:** Implement notification plugins to instantly alert the DevSecOps channels when Checkov intercepts a critical infrastructure vulnerability, providing exact failure logs.

* **Multi-Tool Scanning Matrix:** Introduce tfsec and tflint as parallel scanning stages inside the Jenkinsfile to catch logical syntax errors alongside security policies.

## Notes

This architecture demonstrates a modern, end-to-end framework for building highly automated, secure software supply chain shipping lanes. It showcases specialized cloud core competencies in structuring edge security scanners, managing infrastructure parameters via version-locked IaC code templates, establishing zero-trust machine access perimeters, and enforcing active compliance tracking loops.

**Bottom Line:** The Hardened DevSecOps Pipeline demonstrates how to physically block insecure cloud infrastructure from ever reaching the provisioning stage. By resolving complex system package routing issues, orchestrating a zero-trust AWS machine identity framework, and deploying a rigorous Checkov SAST engine, this architecture ensures absolute compliance alignment and stops data breaches before the infrastructure is even built.
