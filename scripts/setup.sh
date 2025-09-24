#!/bin/bash
# setup.sh - Initial setup script
echo "Setting up Ibex DevOps Task environment..."
chmod +x *.sh scripts/*.sh 2>/dev/null || true
terraform -v >/dev/null 2>&1 || echo "⚠️  Terraform not installed"
aws --version >/dev/null 2>&1 || echo "⚠️  AWS CLI not installed"
docker --version >/dev/null 2>&1 || echo "⚠️  Docker not installed"
echo "✅ Setup complete! Run ./deploy.sh to deploy infrastructure"
