#!/bin/bash
set -e

echo "========================================="
echo "Payflow Infrastructure - Spinup Script"
echo "========================================="

# 1. Check required environment variables
if [ -z "$TF_VAR_db_password" ] || [ -z "$TF_VAR_mq_password" ] || [ -z "$TF_VAR_jwt_secret" ]; then
  echo "ERROR: Missing required sensitive environment variables."
  echo "Please export TF_VAR_db_password, TF_VAR_mq_password, and TF_VAR_jwt_secret before running this script."
  exit 1
fi

# 2. Prompt for environment
read -p "Deploy to which environment? (dev/prod): " ENV
if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
  echo "ERROR: Invalid environment. Must be 'dev' or 'prod'."
  exit 1
fi

export TF_VAR_environment="$ENV"
ROOT_DIR=$(pwd)

echo ""
echo "Starting deployment for environment: $ENV"
echo "========================================="

# 3a. Backend Bootstrap
echo ">>> Bootstrapping Terraform Backend..."
cd "$ROOT_DIR/terraform/aws/backend-bootstrap"
terraform init
terraform apply -auto-approve

# 3b. Hub VPC
echo ""
echo ">>> Deploying Hub VPC..."
cd "$ROOT_DIR/terraform/aws/hub-vpc"
terraform init
terraform apply -var="environment=$ENV" -auto-approve
HUB_VPC_ID=$(terraform output -raw hub_vpc_id)
HUB_PUBLIC_SUBNET_ID=$(terraform output -raw hub_public_subnet_id)
TGW_ID=$(terraform output -raw transit_gateway_id)

# 3c. Spoke VPC & EKS
echo ""
echo ">>> Deploying Spoke VPC and EKS Cluster..."
cd "$ROOT_DIR/terraform/aws/spoke-vpc-eks"
terraform init
terraform apply -var="environment=$ENV" -var="transit_gateway_id=$TGW_ID" -auto-approve
SPOKE_VPC_ID=$(terraform output -raw spoke_vpc_id)
SPOKE_PRIVATE_SUBNETS=$(terraform output -json private_subnet_ids)
NODE_SG_ID=$(terraform output -raw node_security_group_id)

# 3d. Managed Services
echo ""
echo ">>> Deploying Managed Services (RDS, ElastiCache, MQ)..."
cd "$ROOT_DIR/terraform/aws/managed-services"
terraform init
terraform apply \
  -var="environment=$ENV" \
  -var="spoke_vpc_id=$SPOKE_VPC_ID" \
  -var="private_subnet_ids=$SPOKE_PRIVATE_SUBNETS" \
  -var="node_security_group_id=$NODE_SG_ID" \
  -auto-approve

# 3e. Bastion Host
echo ""
echo ">>> Deploying Bastion Host..."
cd "$ROOT_DIR/terraform/aws/bastion"
terraform init
terraform apply \
  -var="environment=$ENV" \
  -var="hub_vpc_id=$HUB_VPC_ID" \
  -var="hub_public_subnet_id=$HUB_PUBLIC_SUBNET_ID" \
  -auto-approve

# 4. Final output
echo ""
echo "========================================="
echo "Infrastructure ready. Connect to bastion with:"
terraform output -raw ssm_connect_command
echo ""
echo ""

# 5. Reminder
echo "Reminder: Run 'aws eks update-kubeconfig --name payflow-eks-cluster --region us-east-1' FROM INSIDE the bastion SSM session. Do not run this from your laptop."
echo "========================================="
