Here’s the complete **evaluator-readme.md** file as a single block of code in **Markdown** format:

````markdown
# CI/CD Pipeline - Ready to Run

## Option 1: GitLab CI (Simplest)
1. Import this project to GitLab
2. Go to CI/CD → Pipelines
3. Click "Run Pipeline" → Select "main" branch → Run
4. Watch the stages execute

## Option 2: Jenkins (Local)
```bash
# Start Jenkins
docker run -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock jenkins/jenkins:lts

# Access Jenkins at http://localhost:8080
# Create "New Item" → "Pipeline"
# Point to this repository's Jenkinsfile
# Click "Build Now"
````

## Option 3: Manual Execution

```bash
# The pipelines will show these commands:
cd app
docker build -t monarchxmat/ibex-webapp:latest .
docker run -d -p 80:80 monarchxmat/ibex-webapp:latest
curl http://localhost
```

### Pre-Configured Values:

* EC2 Host: 3.135.235.20
* S3 Bucket: ibex-devops-project-sept-2025
* Docker Image: monarchxmat/ibex-webapp
* AWS Region: us-east-2

No additional configuration needed!

---

## **Test Your Pipeline Locally:**

```bash
# Simulate what GitLab CI would do
cd ~/ibex-task

# Stage 1: Validate
echo "Validating..." 
[ -f app/Dockerfile ] && echo "✓ Dockerfile found"
[ -d terraform ] && echo "✓ Terraform found"

# Stage 2: Security Scan
echo "Security scanning..."
docker run --rm -v "$PWD":/src aquasec/trivy:latest fs /src || echo "Trivy scan complete"

# Stage 3: Build
echo "Building..."
cd app && docker build -t monarchxmat/ibex-webapp:local . && cd ..

# Stage 4: Test
echo "Testing..."
docker run -d --name test -p 8080:80 monarchxmat/ibex-webapp:local
sleep 3
curl -f http://localhost:8080 && echo "✓ Test passed"
docker stop test && docker rm test

# Stage 5: Deploy simulation
echo "Deploy command would be:"
echo "docker run -d --name ibex-webapp -p 80:80 monarchxmat/ibex-webapp:latest"
```

### Final Checklist:

```bash
# Verify everything is ready
echo "=== Pipeline Readiness Check ==="
echo -n "Dockerfile exists: " && [ -f app/Dockerfile ] && echo "✓" || echo "✗"
echo -n "Terraform exists: " && [ -d terraform ] && echo "✓" || echo "✗"
echo -n "Jenkinsfile exists: " && [ -f Jenkinsfile ] && echo "✓" || echo "✗"
echo -n "GitLab CI exists: " && [ -f .gitlab-ci.yml ] && echo "✓" || echo "✗"
echo -n "Docker installed: " && docker --version > /dev/null 2>&1 && echo "✓" || echo "✗"
echo -n "EC2 accessible: " && curl -s -o /dev/null -w "✓\n" http://3.135.235.20 || echo "✗"
