#!/bin/bash
# destroy.sh - Destroy infrastructure
echo "⚠️  This will destroy all infrastructure!"
echo "Are you sure? (yes/no)"
read confirm
if [ "$confirm" == "yes" ]; then
    cd ../terraform
    terraform destroy -auto-approve
    echo "✅ Infrastructure destroyed"
fi
