#!/bin/bash
# github-init.sh - Automated GitHub Repository Setup Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}===================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
   _____ _ _   _    _       _     
  / ____(_) | | |  | |     | |    
 | |  __ _| |_| |__| |_   _| |__  
 | | |_ | | __|  __  | | | | '_ \ 
 | |__| | | |_| |  | | |_| | |_) |
  \_____|_|\__|_|  |_|\__,_|_.__/ 
                                   
  Repository Setup for Ibex DevOps Task
EOF
echo -e "${NC}"

# Check prerequisites
print_header "Checking Prerequisites"

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed"
    echo "Please install git first: https://git-scm.com"
    exit 1
fi
print_success "Git is installed"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_warning "GitHub CLI not found"
    echo "Install with: brew install gh (macOS) or sudo apt install gh (Linux)"
    echo "Or visit: https://cli.github.com"
    read -p "Continue without GitHub CLI? (y/n): " continue_without_gh
    if [[ $continue_without_gh != "y" ]]; then
        exit 1
    fi
    USE_GH_CLI=false
else
    print_success "GitHub CLI is installed"
    USE_GH_CLI=true
fi

# Get user input
print_header "Configuration"

# GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME
if [[ -z "$GITHUB_USERNAME" ]]; then
    print_error "GitHub username is required"
    exit 1
fi

# Repository name
read -p "Repository name [ibex-devops-task]: " REPO_NAME
REPO_NAME=${REPO_NAME:-ibex-devops-task}

# Repository visibility
echo "Repository visibility:"
echo "1) Public"
echo "2) Private"
read -p "Choose (1/2) [1]: " VISIBILITY_CHOICE
VISIBILITY_CHOICE=${VISIBILITY_CHOICE:-1}

if [[ $VISIBILITY_CHOICE == "2" ]]; then
    VISIBILITY="private"
    VISIBILITY_FLAG="--private"
else
    VISIBILITY="public"
    VISIBILITY_FLAG="--public"
fi

# Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_HUB_USERNAME
if [[ -z "$DOCKER_HUB_USERNAME" ]]; then
    print_warning "Docker Hub username not provided - remember to add it later"
fi

# AWS configuration
print_info "AWS credentials will be configured as GitHub Secrets"
print_info "Make sure you have your AWS Access Key ID and Secret Access Key ready"

# Initialize Git repository
print_header "Initializing Git Repository"

if [ ! -d .git ]; then
    git init
    print_success "Git repository initialized"
else
    print_info "Git repository already exists"
fi

# Configure git
git config user.name "$GITHUB_USERNAME"
print_success "Git user configured"

# Create necessary directories
print_header "Creating Directory Structure"

mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE
mkdir -p terraform/scripts
mkdir -p app
mkdir -p docs
mkdir -p scripts
mkdir -p keys

print_success "Directory structure created"

# Copy or create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    print_info "Creating .gitignore"
    cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars
*.auto.tfvars

# SSH Keys
*.pem
*.key
*.pub
keys/

# AWS
.aws/

# Environment
.env
*.env

# IDE
.vscode/
.idea/
*.swp
.DS_Store

# Logs
*.log
logs/

# Docker
.docker/

# Build
dist/
build/
target/

# Temporary
tmp/
temp/
*.tmp
*.bak

# Outputs
outputs.json
instance_ip.txt
EOF
    print_success ".gitignore created"
fi

# Add files to git
print_header "Preparing Git Commit"

git add .
print_success "Files staged for commit"

# Create initial commit
if [ -z "$(git status --porcelain)" ]; then
    print_info "No changes to commit"
else
    git commit -m "Initial commit: Complete DevOps solution with Terraform and CI/CD

    - Terraform Infrastructure as Code
    - Docker containerization  
    - CI/CD pipelines (Jenkins, GitLab, GitHub Actions)
    - Security best practices with IAM least privilege
    - Comprehensive documentation
    - Automated deployment scripts"
    print_success "Initial commit created"
fi

# Create and push to GitHub
print_header "Creating GitHub Repository"

if [[ $USE_GH_CLI == true ]]; then
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        print_warning "Not authenticated with GitHub CLI"
        echo "Running: gh auth login"
        gh auth login
    fi
    
    # Create repository
    print_info "Creating repository on GitHub..."
    if gh repo create "$REPO_NAME" \
        --description "AWS Infrastructure & CI/CD Pipeline - DevOps Engineer Task" \
        $VISIBILITY_FLAG \
        --source . \
        --push \
        --confirm; then
        print_success "Repository created and pushed to GitHub"
        REPO_CREATED=true
    else
        print_warning "Repository might already exist"
        REPO_CREATED=false
    fi
else
    # Manual instructions
    print_warning "GitHub CLI not available. Please create repository manually:"
    echo ""
    echo "1. Go to: https://github.com/new"
    echo "2. Repository name: $REPO_NAME"
    echo "3. Description: AWS Infrastructure & CI/CD Pipeline - DevOps Engineer Task"
    echo "4. Visibility: $VISIBILITY"
    echo "5. DON'T initialize with README, .gitignore, or license"
    echo "6. Click 'Create repository'"
    echo ""
    read -p "Press Enter when repository is created..."
    REPO_CREATED=false
fi

# Set remote origin
if [[ $REPO_CREATED == false ]]; then
    print_info "Setting remote origin..."
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
    git branch -M main
    git push -u origin main
    print_success "Repository linked and pushed"
fi

# Configure GitHub Secrets (if using gh CLI)
if [[ $USE_GH_CLI == true ]]; then
    print_header "Configuring GitHub Secrets"
    
    echo "Would you like to configure GitHub Secrets now? (y/n)"
    read -p "> " CONFIGURE_SECRETS
    
    if [[ $CONFIGURE_SECRETS == "y" ]]; then
        # AWS Credentials
        print_info "Configuring AWS credentials..."
        read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
        read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo ""
        
        gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID"
        gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY"
        print_success "AWS credentials configured"
        
        # Docker Hub
        if [[ -n "$DOCKER_HUB_USERNAME" ]]; then
            print_info "Configuring Docker Hub credentials..."
            read -s -p "Docker Hub Token/Password: " DOCKER_HUB_TOKEN
            echo ""
            
            gh secret set DOCKER_HUB_USERNAME --body "$DOCKER_HUB_USERNAME"
            gh secret set DOCKER_HUB_TOKEN --body "$DOCKER_HUB_TOKEN"
            print_success "Docker Hub credentials configured"
        fi
        
        # S3 Bucket Name
        read -p "S3 Bucket Name (must be unique) [ibex-devops-artifacts-${RANDOM}]: " S3_BUCKET_NAME
        S3_BUCKET_NAME=${S3_BUCKET_NAME:-"ibex-devops-artifacts-${RANDOM}"}
        gh secret set S3_BUCKET_NAME --body "$S3_BUCKET_NAME"
        print_success "S3 bucket name configured"
        
        print_warning "Note: EC2_SSH_PRIVATE_KEY will be generated by Terraform"
    else
        print_info "Skipping secrets configuration"
        print_warning "Remember to configure secrets in: Settings → Secrets and variables → Actions"
    fi
fi

# Add repository topics
if [[ $USE_GH_CLI == true ]]; then
    print_header "Adding Repository Topics"
    gh repo edit --add-topic "terraform"
    gh repo edit --add-topic "aws"
    gh repo edit --add-topic "docker"
    gh repo edit --add-topic "devops"
    gh repo edit --add-topic "ci-cd"
    gh repo edit --add-topic "infrastructure-as-code"
    print_success "Repository topics added"
fi

# Create initial release
if [[ $USE_GH_CLI == true ]]; then
    print_header "Creating Initial Release"
    
    git tag -a v1.0.0 -m "Initial release: Complete DevOps solution"
    git push origin v1.0.0
    
    gh release create v1.0.0 \
        --title "v1.0.0 - Initial Release" \
        --notes "Complete AWS Infrastructure and CI/CD Pipeline solution
        
Features:
- Terraform Infrastructure as Code  
- Docker containerization
- Multi-platform CI/CD (Jenkins, GitLab, GitHub Actions)
- Security best practices
- Comprehensive documentation
- Automated deployment scripts"
    
    print_success "Release v1.0.0 created"
fi

# Final summary
print_header "Setup Complete! 🎉"

echo -e "${GREEN}Your GitHub repository is ready!${NC}"
echo ""
echo "Repository URL: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo "Visibility: $VISIBILITY"
echo ""

if [[ $USE_GH_CLI == true ]]; then
    echo "Quick Actions:"
    echo "  Open in browser:  gh repo view --web"
    echo "  View workflows:   gh workflow list"
    echo "  Check secrets:    gh secret list"
    echo "  Run workflow:     gh workflow run deploy.yml"
else
    echo "Next Steps:"
    echo "1. Go to: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/settings/secrets/actions"
    echo "2. Add the following secrets:"
    echo "   - AWS_ACCESS_KEY_ID"
    echo "   - AWS_SECRET_ACCESS_KEY"
    echo "   - DOCKER_HUB_USERNAME"
    echo "   - DOCKER_HUB_TOKEN"
    echo "   - S3_BUCKET_NAME"
    echo "   - EC2_SSH_PRIVATE_KEY (after Terraform creates it)"
fi

echo ""
echo "Documentation:"
echo "  - README.md: Main documentation"
echo "  - GITHUB_SETUP.md: Detailed setup guide"
echo "  - docs/: Additional documentation"
echo ""

print_info "Remember to:"
echo "  1. Review and update terraform/terraform.tfvars"
echo "  2. Test the GitHub Actions workflow"
echo "  3. Enable branch protection for 'main' branch"
echo "  4. Configure additional security settings"
echo ""

print_success "Happy DevOps! 🚀"