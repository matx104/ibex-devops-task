# Simple Jenkins Credentials Setup

## Required Jenkins Credentials

You only need **5 credentials** for the simplified pipeline:

### 1. Docker Hub Login
- **ID:** `docker-hub-creds`
- **Type:** Username with password
- **Username:** Your Docker Hub username
- **Password:** Your Docker Hub password (or access token)

### 2. EC2 SSH Key  
- **ID:** `ec2-ssh-key`
- **Type:** SSH Username with private key
- **Username:** `ec2-user`
- **Private Key:** Paste your EC2 .pem file content

### 3. EC2 Public IP
- **ID:** `ec2-public-ip` 
- **Type:** Secret text
- **Secret:** Your EC2 instance public IP address

### 4. S3 Bucket Name
- **ID:** `s3-bucket-name`
- **Type:** Secret text  
- **Secret:** Your S3 bucket name

### 5. GitHub Token (Optional - for private repos)
- **ID:** `github-token`
- **Type:** Secret text
- **Secret:** Your GitHub Personal Access Token

## Quick Setup Steps

### Step 1: Get Your Values
From your Terraform output:
```bash
terraform output docker_host_public_ip    # For EC2_PUBLIC_IP
terraform output s3_bucket_name           # For S3_BUCKET  
terraform output -raw ssh_private_key_path | xargs cat  # For SSH key
```

### Step 2: Add to Jenkins
1. Go to **Manage Jenkins > Manage Credentials**
2. Click **System > Global credentials > Add Credentials**
3. Add each credential using the table above

### Step 3: GitHub Webhook
1. Go to your GitHub repo → Settings → Webhooks
2. Add webhook URL: `http://your-jenkins-server:8080/github-webhook/`
3. Content type: `application/json`
4. Events: Just push events

### Step 4: Create Jenkins Job
1. New Item → Pipeline
2. Check "GitHub project" and add your repo URL
3. Check "GitHub hook trigger for GITScm polling"
4. Pipeline → Pipeline script from SCM
5. Set repository URL and credentials

## Test Your Setup

```bash
# Test Docker Hub login
echo "your-password" | docker login -u your-username --password-stdin

# Test SSH to EC2
ssh -i /path/to/key.pem ec2-user@your-ec2-ip

# Test GitHub webhook
curl -X POST http://your-jenkins-server:8080/github-webhook/
```

That's it! Your simple CI/CD pipeline is ready to use.