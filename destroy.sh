#!/bin/bash
set -e

echo "========================================="
echo "Payflow Infrastructure - Destroy Script"
echo "========================================="

# 1. Prompt for environment
read -p "Destroy which environment? (dev/prod): " ENV
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: Invalid environment. Must be 'dev' or 'prod'."
  exit 1
fi

export TF_VAR_environment="$ENV"
ROOT_DIR=$(pwd)

# 2. Warning and confirmation
echo ""
echo "WARNING: This will destroy ALL infrastructure for environment $ENV."
echo "RDS data, ElastiCache data, and MQ queues will be permanently lost."
echo ""
read -p "Type 'destroy' to confirm: " CONFIRM

# 3. Validation
if [ "$CONFIRM" != "destroy" ]; then
  echo "Destruction cancelled. Exiting."
  exit 0
fi

echo ""
echo "Starting destruction for environment: $ENV"
echo "========================================="

# 4. Destroy in REVERSE order
# a. Bastion Host
echo ">>> Destroying Bastion Host..."
cd "$ROOT_DIR/terraform/aws/bastion"
if [ -d ".terraform" ]; then
  terraform destroy -auto-approve || echo "Warning: Bastion destroy failed or already destroyed."
fi

# b. Managed Services
echo ""
echo ">>> Destroying Managed Services (RDS, ElastiCache, MQ)..."
cd "$ROOT_DIR/terraform/aws/managed-services"
if [ -d ".terraform" ]; then
  terraform destroy -auto-approve || echo "Warning: Managed Services destroy failed or already destroyed."
fi

# c. Spoke VPC & EKS
echo ""
echo ">>> Destroying Spoke VPC and EKS Cluster..."
cd "$ROOT_DIR/terraform/aws/spoke-vpc-eks"
if [ -d ".terraform" ]; then
  # Grab the TGW ID just in case it's needed for destroy (normally state has it, but safe to pass if required by variables)
  TGW_ID=$(cd "$ROOT_DIR/terraform/aws/hub-vpc" && terraform output -raw transit_gateway_id 2>/dev/null || echo "")
  terraform destroy -var="transit_gateway_id=$TGW_ID" -auto-approve || echo "Warning: Spoke VPC destroy failed or already destroyed."
fi

# d. Hub VPC
echo ""
echo ">>> Destroying Hub VPC..."
cd "$ROOT_DIR/terraform/aws/hub-vpc"
if [ -d ".terraform" ]; then
  terraform destroy -auto-approve || echo "Warning: Hub VPC destroy failed or already destroyed."
fi

# 5. Final output
echo ""
echo "========================================="
echo "Destroyed. The S3 state bucket and DynamoDB lock table were NOT deleted."
echo "To remove them manually:"
echo "cd terraform/aws/backend-bootstrap && terraform destroy"
echo "========================================="
