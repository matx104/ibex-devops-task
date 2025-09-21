// Jenkinsfile - Jenkins CI/CD Pipeline

pipeline {
    agent any
    
    environment {
        // Docker Hub credentials (configured in Jenkins credentials)
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-creds')
        DOCKER_IMAGE_NAME = 'ibex-webapp'
        DOCKER_HUB_REPO = "${DOCKER_HUB_CREDENTIALS_USR}/${DOCKER_IMAGE_NAME}"
        
        // AWS EC2 SSH credentials (configured in Jenkins credentials)
        EC2_SSH_KEY = credentials('ec2-ssh-key')
        EC2_HOST = credentials('ec2-public-ip')
        EC2_USER = 'ec2-user'
        
        // S3 bucket for artifacts
        S3_BUCKET = credentials('s3-bucket-name')
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    
    parameters {
        string(name: 'GIT_BRANCH', defaultValue: 'main', description: 'Git branch to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip running tests')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                
                script {
                    // Get commit hash for tagging
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.BUILD_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Validate') {
            steps {
                echo 'Validating Dockerfile and application files...'
                sh '''
                    # Check if Dockerfile exists
                    if [ ! -f Dockerfile ]; then
                        echo "ERROR: Dockerfile not found!"
                        exit 1
                    fi
                    
                    # Validate Dockerfile syntax
                    docker run --rm -i hadolint/hadolint < Dockerfile || true
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "Building Docker image with tag: ${env.BUILD_TAG}"
                sh """
                    # Build the Docker image
                    docker build -t ${DOCKER_HUB_REPO}:${env.BUILD_TAG} .
                    
                    # Also tag as latest
                    docker tag ${DOCKER_HUB_REPO}:${env.BUILD_TAG} ${DOCKER_HUB_REPO}:latest
                    
                    # Tag for specific environment
                    docker tag ${DOCKER_HUB_REPO}:${env.BUILD_TAG} ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}
                """
            }
        }
        
        stage('Test') {
            when {
                expression { params.SKIP_TESTS != true }
            }
            steps {
                echo 'Running container tests...'
                sh """
                    # Run the container locally for testing
                    docker run -d --name test-container -p 8080:80 ${DOCKER_HUB_REPO}:${env.BUILD_TAG}
                    
                    # Wait for container to start
                    sleep 5
                    
                    # Test if container is responding
                    curl -f http://localhost:8080 || (docker logs test-container && exit 1)
                    
                    # Clean up test container
                    docker stop test-container
                    docker rm test-container
                """
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                sh """
                    # Login to Docker Hub
                    echo ${DOCKER_HUB_CREDENTIALS_PSW} | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin
                    
                    # Push all tags
                    docker push ${DOCKER_HUB_REPO}:${env.BUILD_TAG}
                    docker push ${DOCKER_HUB_REPO}:latest
                    docker push ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}
                    
                    # Logout from Docker Hub
                    docker logout
                """
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                echo 'Deploying to EC2 instance...'
                sh """
                    # Create deployment script
                    cat > deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

echo "Starting deployment of ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}"

# Login to Docker Hub
echo "${DOCKER_HUB_CREDENTIALS_PSW}" | docker login -u ${DOCKER_HUB_CREDENTIALS_USR} --password-stdin

# Stop and remove existing container
echo "Stopping existing container..."
docker stop ${DOCKER_IMAGE_NAME} 2>/dev/null || true
docker rm ${DOCKER_IMAGE_NAME} 2>/dev/null || true

# Remove old images to save space
docker image prune -f

# Pull the new image
echo "Pulling new image..."
docker pull ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}

# Run the new container
echo "Starting new container..."
docker run -d \\
    --name ${DOCKER_IMAGE_NAME} \\
    -p 80:80 \\
    --restart unless-stopped \\
    ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}

# Verify deployment
sleep 5
if curl -f http://localhost; then
    echo "Deployment successful!"
    
    # Log to S3
    echo "Deployment of ${DOCKER_HUB_REPO}:${params.ENVIRONMENT} successful at \$(date)" > /tmp/deployment.log
    aws s3 cp /tmp/deployment.log s3://${S3_BUCKET}/deployments/\$(date +%Y%m%d_%H%M%S)_deployment.log
else
    echo "Deployment verification failed!"
    docker logs ${DOCKER_IMAGE_NAME}
    exit 1
fi

# Logout from Docker Hub
docker logout
DEPLOY_SCRIPT
                    
                    # Copy script to EC2 and execute
                    scp -i ${EC2_SSH_KEY} -o StrictHostKeyChecking=no deploy.sh ${EC2_USER}@${EC2_HOST}:/tmp/
                    ssh -i ${EC2_SSH_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} 'chmod +x /tmp/deploy.sh && /tmp/deploy.sh'
                """
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    def maxRetries = 5
                    def retryCount = 0
                    def healthy = false
                    
                    while (retryCount < maxRetries && !healthy) {
                        try {
                            sh """
                                curl -f http://${EC2_HOST}
                            """
                            healthy = true
                            echo "Application is healthy!"
                        } catch (Exception e) {
                            retryCount++
                            if (retryCount < maxRetries) {
                                echo "Health check failed, retrying... (${retryCount}/${maxRetries})"
                                sleep 10
                            }
                        }
                    }
                    
                    if (!healthy) {
                        error("Health check failed after ${maxRetries} attempts")
                    }
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                echo 'Running smoke tests...'
                sh """
                    # Test HTTP response
                    response=\$(curl -s -o /dev/null -w "%{http_code}" http://${EC2_HOST})
                    if [ "\$response" != "200" ]; then
                        echo "ERROR: Unexpected HTTP response: \$response"
                        exit 1
                    fi
                    
                    # Test content
                    curl -s http://${EC2_HOST} | grep -q "nginx" || echo "WARNING: Expected content not found"
                    
                    echo "Smoke tests passed!"
                """
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up workspace...'
            sh """
                # Clean up local Docker images
                docker rmi ${DOCKER_HUB_REPO}:${env.BUILD_TAG} || true
                docker rmi ${DOCKER_HUB_REPO}:latest || true
                docker rmi ${DOCKER_HUB_REPO}:${params.ENVIRONMENT} || true
            """
        }
        
        success {
            echo "Pipeline completed successfully!"
            echo "Application is running at: http://${EC2_HOST}"
            
            // Send notification (configure Slack/Email as needed)
            sh """
                echo "Deployment successful for ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}" | \\
                aws s3 cp - s3://${S3_BUCKET}/notifications/success_${env.BUILD_TAG}.txt
            """
        }
        
        failure {
            echo 'Pipeline failed!'
            
            // Rollback mechanism (optional)
            script {
                if (params.ENVIRONMENT == 'prod') {
                    echo 'Initiating rollback for production...'
                    // Add rollback logic here
                }
            }
            
            sh """
                echo "Deployment failed for ${DOCKER_HUB_REPO}:${params.ENVIRONMENT}" | \\
                aws s3 cp - s3://${S3_BUCKET}/notifications/failure_${env.BUILD_TAG}.txt
            """
        }
    }
}