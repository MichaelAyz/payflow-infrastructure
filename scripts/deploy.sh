#!/bin/bash
set -e

echo "========================================="
echo "Payflow CD - Bastion Deployment Script"
echo "========================================="

if [ "$#" -ne 2 ]; then
    echo "Usage: ./deploy.sh <OVERLAY_NAME> <IMAGE_TAG>"
    echo "Example: ./deploy.sh ec2 abc123def456"
    exit 1
fi

OVERLAY=$1
IMAGE_TAG=$2

# Gather ECR Configuration automatically from STS
AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Target Overlay: k8s/overlays/$OVERLAY"
echo "Target Image Tag: $IMAGE_TAG"
echo "ECR Registry: $ECR_REGISTRY"
echo ""

# Ensure we are working in an empty tmp directory
WORKSPACE_DIR="/tmp/payflow-deploy"
rm -rf "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

echo ">>> Cloning payflow-wallet repository..."
git clone https://github.com/michaelayz/payflow-wallet.git .

OVERLAY_DIR="k8s/overlays/$OVERLAY"

if [ ! -d "$OVERLAY_DIR" ]; then
    echo "ERROR: Overlay directory $OVERLAY_DIR does not exist in the repository."
    exit 1
fi

cd "$OVERLAY_DIR"

echo ">>> Updating Kustomize image overlays..."
# These keys currently map directly. If your raw Kubernetes deployment limits 
# expect different image names (e.g., image: auth-service), update the string before the =
# Format: kustomize edit set image [ORIGINAL_IMAGE]=NEW_IMAGE:TAG
kustomize edit set image api-gateway=${ECR_REGISTRY}/payflow/api-gateway:${IMAGE_TAG}
kustomize edit set image auth-service=${ECR_REGISTRY}/payflow/auth:${IMAGE_TAG}
kustomize edit set image frontend=${ECR_REGISTRY}/payflow/frontend:${IMAGE_TAG}
kustomize edit set image notification-service=${ECR_REGISTRY}/payflow/notification:${IMAGE_TAG}
kustomize edit set image transaction-service=${ECR_REGISTRY}/payflow/transaction:${IMAGE_TAG}
kustomize edit set image wallet-service=${ECR_REGISTRY}/payflow/wallet:${IMAGE_TAG}

echo ">>> Applying Kustomize manifest to EKS Cluster..."
kubectl apply -k .

echo ">>> Deployment dispatched! Watching rollout status..."
# Ensure the deployment labels below precisely match your K8s metadata
for deployment in api-gateway auth transaction notification frontend wallet; do
  kubectl rollout status deployment/"$deployment" -n payflow --timeout=120s || true
done

echo "========================================="
echo "Rollout sequence complete."
echo "If you need to rollback rapidly, run:"
echo "kubectl rollout undo deployment/<service-name>"
echo "========================================="
