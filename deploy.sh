#!/usr/bin/env bash
set -euo pipefail

# Always run from repo root (where this script sits)
cd "$(dirname "$0")"

TF_DIR="terraform"
cd "$TF_DIR"

# Best-effort: fix ownership if earlier runs used sudo (ignore if not needed)
sudo chown -R "$USER":"$USER" . 2>/dev/null || true

# Clean up any stale local lock and zero-byte state
[ -f .terraform.tfstate.lock.info ] && rm -f .terraform.tfstate.lock.info
if [ -f terraform.tfstate ] && [ ! -s terraform.tfstate ]; then
  rm -f terraform.tfstate
fi

echo "==> terraform init"
terraform init -input=false -reconfigure

echo "==> terraform plan"
terraform plan -input=false -out=tfplan

read -r -p "Continue with deployment? (yes/no) " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo "==> terraform apply"
terraform apply -input=false tfplan

# Try to read a known output without requiring jq
APP_IP="$(terraform output -raw ec2_public_ip 2>/dev/null || true)"

echo "✅ Deployment complete!"
if [ -n "$APP_IP" ]; then
  echo "Application URL: http://$APP_IP"
else
  echo "No 'ec2_public_ip' output found."
  echo "Tip: add to outputs.tf, e.g.:"
  echo '  output "ec2_public_ip" { value = aws_instance.app.public_ip }'
  echo "Then re-apply or run: terraform output"
fi
