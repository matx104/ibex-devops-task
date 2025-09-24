// Jenkinsfile — commit-hash tagging, simple checkout, sshagent deploy

pipeline {
  agent any

  environment {
    // Docker Hub username+password credential (ID: docker-hub-creds)
    DOCKER_HUB = credentials('docker-hub-creds')   // yields DOCKER_HUB_USR / DOCKER_HUB_PSW
    DOCKER_HUB_USR = "monarchxmat"
    DOCKER_IMAGE_NAME = 'ibex-webapp'
    DOCKER_REPO       = "${DOCKER_HUB_USR}/${DOCKER_IMAGE_NAME}"

    // EC2 info
    EC2_PUBLIC_IP = credentials('ec2-public-ip')   // Secret text with the IP (or just hardcode/plain env)
    EC2_USER      = 'ec2-user'
  }

  parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Deployment environment')
    booleanParam(name: 'SKIP_TESTS', defaultValue: true, description: 'Skip tests')
  }

  triggers {
    githubPush()
  }

  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        sh 'git config --global --add safe.directory "$WORKSPACE" || true'
        git branch: 'main', url: 'https://github.com/matx104/ibex-devops-task.git'
        script {
          env.IMAGE_TAG = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()
          env.BUILD_TAG = "${params.ENVIRONMENT}-${env.BUILD_NUMBER}-${env.IMAGE_TAG}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh """
          set -e
          cd app 
          docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .
          # Optional env alias for easier rollbacks
          docker tag ${DOCKER_REPO}:${IMAGE_TAG} ${DOCKER_REPO}:${params.ENVIRONMENT}
        """
      }
    }

    stage('Test') {
      when { expression { !params.SKIP_TESTS } }
      steps {
        sh """
          set -e
          docker run -d --name test-container -p 8080:80 ${DOCKER_REPO}:${IMAGE_TAG}
          sleep 10
          curl -f http://localhost:8080
          docker stop test-container
          docker rm test-container
        """
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh """
          set -e
          echo ${DOCKER_HUB_PSW} | docker login -u ${DOCKER_HUB_USR} --password-stdin
          docker push ${DOCKER_REPO}:${IMAGE_TAG}
          docker push ${DOCKER_REPO}:${params.ENVIRONMENT}
          docker logout
        """
      }
    }

    stage('Deploy to EC2') {
      steps {
        // Use an SSH private key credential of type "SSH Username with private key" (ID: ec2-ssh-key)
        sshagent(credentials: ['ec2-ssh-key']) {
          sh """
            set -e

            # Build remote deploy script with local env expansion
            cat > /tmp/deploy.sh << EOF
#!/bin/bash
set -e
echo "Deploying ${DOCKER_REPO}:${IMAGE_TAG} to ${EC2_PUBLIC_IP} ..."

echo "${DOCKER_HUB_PSW}" | docker login -u ${DOCKER_HUB_USR} --password-stdin

docker stop ${DOCKER_IMAGE_NAME} 2>/dev/null || true
docker rm ${DOCKER_IMAGE_NAME} 2>/dev/null || true

docker pull ${DOCKER_REPO}:${IMAGE_TAG}
docker run -d \\
  --name ${DOCKER_IMAGE_NAME} \\
  -p 80:80 \\
  --restart unless-stopped \\
  ${DOCKER_REPO}:${IMAGE_TAG}

sleep 5
curl -fsS http://localhost >/dev/null
docker logout
EOF

            chmod +x /tmp/deploy.sh

            # Copy & execute on EC2 (sshagent provides the key; no -i needed)
            scp -o StrictHostKeyChecking=no /tmp/deploy.sh ${EC2_USER}@${EC2_PUBLIC_IP}:/tmp/
            ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_PUBLIC_IP} 'bash /tmp/deploy.sh && rm -f /tmp/deploy.sh'
          """
        }
      }
    }

    stage('Health Check') {
      steps {
        sh """
          set -e
          sleep 10
          code=\$(curl -s -o /dev/null -w "%{http_code}" http://${EC2_PUBLIC_IP})
          if [ "\$code" = "200" ]; then
            echo "Health check passed!"
          else
            echo "Health check failed with status: \$code"
            exit 1
          fi
        """
      }
    }
  }

  post {
    always {
      sh """
        docker rmi ${DOCKER_REPO}:${IMAGE_TAG} || true
        docker system prune -f || true
      """
    }
    success {
      echo "✅ Deployed ${DOCKER_REPO}:${IMAGE_TAG}"
      echo "URL: http://${EC2_PUBLIC_IP}"
    }
    failure {
      echo "❌ Pipeline failed."
    }
  }
}
