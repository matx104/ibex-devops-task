#!/bin/bash
# user_data.sh - EC2 Instance Initialization Script

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install AWS CLI (already installed on Amazon Linux 2)
# Install other useful tools
yum install -y git htop

# Create directories for application
mkdir -p /opt/app
mkdir -p /var/log/app

# Configure AWS CLI region
aws configure set default.region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Log initialization to S3
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "EC2 instance $INSTANCE_ID initialized at $TIMESTAMP" > /tmp/init.log
echo "Docker version: $(docker --version)" >> /tmp/init.log
echo "S3 Bucket: ${s3_bucket}" >> /tmp/init.log

# Upload initialization log to S3
aws s3 cp /tmp/init.log s3://${s3_bucket}/logs/init_$${INSTANCE_ID}_$${TIMESTAMP}.log

# Create a simple startup script
cat > /usr/local/bin/pull-and-run-docker.sh << 'SCRIPT_EOF'
#!/bin/bash
# Script to pull and run Docker container

DOCKER_IMAGE=$1
CONTAINER_NAME=$2

if [ -z "$DOCKER_IMAGE" ] || [ -z "$CONTAINER_NAME" ]; then
    echo "Usage: $0 <docker-image> <container-name>"
    exit 1
fi

# Stop and remove existing container if it exists
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Pull latest image
docker pull $DOCKER_IMAGE

# Run new container
docker run -d \
    --name $CONTAINER_NAME \
    -p 80:80 \
    --restart unless-stopped \
    $DOCKER_IMAGE

# Log deployment
echo "Deployed $DOCKER_IMAGE as $CONTAINER_NAME at $(date)" >> /var/log/app/deployments.log
SCRIPT_EOF

chmod +x /usr/local/bin/pull-and-run-docker.sh

# Create health check script
cat > /usr/local/bin/health-check.sh << 'HEALTH_EOF'
#!/bin/bash
# Health check script

response=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost)
if [ "$response" == "200" ]; then
    echo "Application is healthy"
    exit 0
else
    echo "Application is not responding (HTTP $response)"
    exit 1
fi
HEALTH_EOF

chmod +x /usr/local/bin/health-check.sh


# Deploy Custom Ibex-WebApp
docker pull monarchxmat/ibex-webapp:latest
docker stop ibex-webapp 2>/dev/null || true
docker rm ibex-webapp 2>/dev/null || true
docker run -d --name ibex-webapp -p 80:80 monarchxmat/ibex-webapp:latest

# Signal completion
echo "User data script completed successfully" >> /tmp/init.log
aws s3 cp /tmp/init.log s3://${s3_bucket}/logs/init_complete_$${INSTANCE_ID}_$${TIMESTAMP}.log
