# Ibex DevOps Task: AWS Infrastructure & CI/CD Pipeline

## 📋 Project Overview

This project demonstrates a complete DevOps solution featuring:
- **Infrastructure as Code (IaC)** using Terraform for AWS resource provisioning
- **CI/CD Pipeline** using Jenkins/GitLab CI for automated Docker deployment
- **Containerization** with Docker and deployment to EC2
- **Security** implementation with least-privilege IAM policies
- **Monitoring** with S3 artifact storage and health checks

## 🏗️ Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌──────────────┐
│   Git Repo      │────▶│  CI/CD       │────▶│  Docker Hub  │
└─────────────────┘     │  Pipeline    │     └──────────────┘
                        └──────────────┘              │
                               │                      ▼
                               ▼              ┌──────────────┐
                        ┌──────────────┐     │   EC2        │
                        │   Terraform  │     │   Instance   │
                        └──────────────┘     └──────────────┘
                               │                      │
                               ▼                      ▼
                        ┌──────────────┐     ┌──────────────┐
                        │   AWS        │     │   S3 Bucket  │
                        │   Resources  │     │   (Logs)     │
                        └──────────────┘     └──────────────┘
```

## 📁 Project Structure

```
.
├── terraform/
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf             # Variable definitions
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars.example # Example variables file
│   └── scripts/
│       └── user_data.sh         # EC2 initialization script
├── ci-cd/
│   ├── Jenkinsfile              # Jenkins pipeline configuration
│   └── .gitlab-ci.yml           # GitLab CI configuration
├── app/
│   ├── Dockerfile               # Docker container definition
│   ├── nginx.conf               # Nginx configuration
│   ├── index.html               # Demo web application
│   └── package.json             # Node.js dependencies (if applicable)
├── keys/                        # SSH keys (gitignored)
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- AWS Account (Free Tier eligible)
- Terraform >= 1.0
- Docker and Docker Hub account
- Jenkins or GitLab CI setup
- AWS CLI configured
- Git

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd ibex-devops-task
```

### Step 2: Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply -auto-approve

# Save outputs
terraform output -json > ../outputs.json
```

### Step 4: Configure CI/CD Pipeline

#### For Jenkins:
1. Create a new Pipeline job
2. Add credentials:
   - `docker-hub-creds`: Docker Hub username/password
   - `ec2-ssh-key`: SSH private key from Terraform output
   - `ec2-public-ip`: EC2 public IP as secret text
   - `s3-bucket-name`: S3 bucket name as secret text

3. Configure pipeline from SCM using Jenkinsfile

#### For GitLab CI:
1. Add CI/CD variables in GitLab project settings:
   - `CI_REGISTRY_USER`: Docker Hub username
   - `CI_REGISTRY_PASSWORD`: Docker Hub password
   - `EC2_SSH_PRIVATE_KEY`: SSH private key
   - `EC2_HOST_DEV`: EC2 public IP
   - `S3_BUCKET_DEV`: S3 bucket name

### Step 5: Deploy Application

Push code to trigger the pipeline:

```bash
git add .
git commit -m "Deploy application"
git push origin main
```

## 📊 Infrastructure Components

### 1. IAM Configuration

**Least Privilege Policy Design:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Management",
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RunInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/ManagedBy": "Terraform"
        }
      }
    }
  ]
}
```

**Rationale:**
- Resources are tagged for identification
- Actions limited to essential operations
- Condition ensures only managed resources are affected

### 2. EC2 Instance

- **Instance Type**: t2.micro (Free Tier)
- **AMI**: Amazon Linux 2 (latest)
- **Security Group**: 
  - SSH (22) from specified IPs
  - HTTP (80) from anywhere
- **IAM Role**: S3 write access for logs
- **User Data**: Automated Docker installation

### 3. S3 Bucket

- **Purpose**: Store application artifacts and deployment logs
- **Security**: 
  - Public access blocked
  - Versioning enabled
  - Server-side encryption
- **IAM Policy**: EC2 instance has write-only access

## 🔄 CI/CD Pipeline Stages

### Pipeline Flow:

1. **Checkout**: Clone repository
2. **Validate**: Dockerfile linting and security scanning
3. **Build**: Create Docker image with unique tags
4. **Test**: Run container tests
5. **Push**: Upload to Docker Hub
6. **Deploy**: SSH to EC2 and update container
7. **Verify**: Health checks and smoke tests

### Deployment Process:

```bash
# On EC2 instance
docker stop old-container
docker rm old-container
docker pull new-image
docker run -d -p 80:80 new-image
```

## 🔒 Security Considerations

1. **SSH Keys**: Generated automatically by Terraform
2. **Secrets Management**: 
   - Stored in CI/CD credential manager
   - Never committed to repository
3. **Network Security**:
   - Security groups restrict access
   - SSH limited to specified IPs
4. **IAM Policies**: 
   - Least privilege principle
   - Resource-based conditions
5. **Container Security**:
   - Non-root user in container
   - Security scanning with Trivy

## 📝 Deployment Verification

### 1. Check Infrastructure:
```bash
terraform output
# Note the EC2 public IP
```

### 2. Verify Application:
```bash
curl http://<EC2_PUBLIC_IP>
# Should return the demo webpage
```

### 3. Check Logs in S3:
```bash
aws s3 ls s3://<bucket-name>/logs/
```

### 4. SSH to Instance:
```bash
ssh -i keys/ibex-devops-key.pem ec2-user@<EC2_PUBLIC_IP>
docker ps
```

## 🔄 Rollback Procedure

### Manual Rollback:
```bash
# SSH to EC2
ssh -i keys/ibex-devops-key.pem ec2-user@<EC2_PUBLIC_IP>

# List available images
docker images

# Run previous version
docker stop current-container
docker run -d -p 80:80 previous-image:tag
```

### Automated Rollback:
- Jenkins: Run pipeline with `ROLLBACK=true` parameter
- GitLab: Trigger manual rollback job

## 🧹 Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -auto-approve
```

## 📈 Monitoring & Logging

- **Application Logs**: Stored in S3 bucket
- **Docker Logs**: `docker logs <container-name>`
- **EC2 Monitoring**: CloudWatch metrics
- **Pipeline Logs**: Jenkins/GitLab CI interface

## 🎯 Success Criteria

✅ Terraform provisions all AWS resources successfully  
✅ EC2 instance is accessible via SSH and HTTP  
✅ Docker is installed and running on EC2  
✅ S3 bucket created with proper permissions  
✅ CI/CD pipeline builds and pushes Docker image  
✅ Application deployed and accessible on port 80  
✅ Health checks pass  
✅ Deployment logs stored in S3  

## 🛠️ Troubleshooting

### Common Issues:

1. **Terraform Apply Fails**
   - Check AWS credentials: `aws sts get-caller-identity`
   - Verify region settings
   - Ensure unique S3 bucket name

2. **SSH Connection Refused**
   - Check security group rules
   - Verify key permissions: `chmod 400 keys/*.pem`
   - Confirm EC2 instance is running

3. **Docker Deployment Fails**
   - Check Docker Hub credentials
   - Verify EC2 has internet access
   - Review user data script logs: `/var/log/cloud-init-output.log`

4. **Application Not Accessible**
   - Check security group port 80 is open
   - Verify Docker container is running: `docker ps`
   - Check nginx logs: `docker logs <container>`

## 📚 Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)

## 📧 Contact

For questions about this submission:
- Email: [muhammad.atx@gmail.com]
- GitHub: [https://github.com/matx104]
- LinkedIn: [https://www.linkedin.com/in/matx104/]

---

**Note**: This project was created as part of the Ibex Multi-Cloud DevOps Engineer interview process. All resources are designed to run within AWS Free Tier limits.
## 📊 [View Technical Presentation](./PRESENTATION.md)
