# Payflow AWS EKS Infrastructure

This repository contains the Terraform infrastructure code to migrate the Payflow application to an AWS EKS production-like environment. The architecture follows a strict Hub-and-Spoke topology, prioritizes security via SSM-only bastion access (zero laptop `kubectl`), and utilizes AWS Secrets Manager with External Secrets Operator for secret management.

## 1. Prerequisites
Before beginning, ensure you have the following installed on your local machine:
*   [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.5.0+)
*   [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
*   An active AWS account with credentials configured (`aws configure`)
*   [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) installed for the AWS CLI

## 2. First-time Setup
We prioritize security by strictly passing sensitive variables as environment variables. They should **never** be written to disk.

Export the following required environment variables before orchestrating the infrastructure:
```bash
export TF_VAR_db_password="YourSecureDBPassword123!"
export TF_VAR_mq_password="YourSecureMQPassword123!"
export TF_VAR_jwt_secret="YourSuperSecretJWTKey123!"
```

Once exported, you can execute the spin-up script from the root of the repository:
```bash
chmod +x spinup.sh
./spinup.sh
```
When prompted, enter `dev` (or `prod`). The script will automatically bootstrap the state backend and deploy all modules in the correct dependency order.

## 3. Connecting to Bastion via SSM
For security, the strict Hub-and-Spoke topology isolates the EKS cluster in private subnets with **no public API endpoint**. The only way to interact with the cluster is through the Bastion EC2 instance located in the Hub VPC. Port 22 is disabled.

To connect to the bastion safely using AWS Systems Manager (SSM) Session Manager, run the command generated at the end of the `spinup.sh` script, which looks like this:
```bash
aws ssm start-session --target i-0abcd1234efgh5678 --region us-east-1
```
*(Wait 3-5 minutes after cluster creation before attempting to connect, allowing the SSM agent to register).*

## 4. Deploying the Application

We follow a GitOps strategy, physically separating Continuous Integration (Building/Pushing) from Continuous Deployment (Executing EKS changes).

### CI Phase: GitHub Actions
Instead of risking jump-box memory exhaustion by running Docker inside the `t3.micro` bastion, the deployment starts natively in GitHub using the Actions template bundled inside this repo at: `scripts/github-actions-build-push.yml`.
1. Copy this YAML into your application repository under `.github/workflows/build-push.yml`.
2. Replace `<ACCOUNT_ID>` with your 12-digit AWS Account ID.
3. Every merge immediately logs natively into AWS ECR utilizing a secure OIDC Trust Role (no static keys) and pushes uniquely tagged images mapping to each microservice correctly.

### CD Phase: Deploy from Bastion
Once your CI tags your latest container code in ECR, utilize AWS SSM to securely bridge to the bastion node:
```bash
aws ssm start-session --target <BASTION_ID> --region us-east-1
```
Inside the interactive shell, authenticate locally first:
```bash
aws eks update-kubeconfig --name payflow-eks-cluster --region us-east-1
```

Then securely fetch and execute the Kustomize deployment script:
```bash
# Optional: clone infrastructure repo local strictly inside the isolated sandbox
git clone <your-infra-repo-url> /tmp/infra
cd /tmp/infra/scripts

# Run deploy with your Kubernetes Overlay (e.g. 'ec2') and the corresponding GIT COMMIT SHA your Action just built!
./deploy.sh ec2 <YOUR_IMAGE_TAG>
```
The deploy script securely isolates Kustomization inside memory, updates Docker tags uniquely pointing to ECR URIs seamlessly, and performs `kubectl apply -k .` followed by an automatic status wipe down.

## 5. Tearing Down
To destroy the entire infrastructure and stop incurring costs, run the provided teardown script:
```bash
chmod +x destroy.sh
./destroy.sh
```
When prompted, type `destroy` to confirm. 
**Note:** The state locking DynamoDB table and S3 state bucket deployed by `backend-bootstrap` are deliberately shielded from automatic teardown to preserve state history. 

## 6. Re-running after Teardown
If you want to spin everything back up after a destroy, simply execute `./spinup.sh` again! Since the `backend-bootstrap` S3 bucket still exists, the script will gracefully skip its recreation and automatically lock onto your existing Terraform states to rebuild the Hub/Spoke infrastructure.

If you absolutely must purge the backend manually before a fresh spinup, run:
```bash
cd terraform/aws/backend-bootstrap
terraform destroy
```

## 7. Required Environment Variables

| Variable String | Description | Location Needed |
| :--- | :--- | :--- |
| `TF_VAR_db_password` | RDS PostgreSQL root password | Required for standard `spinup.sh` script execution |
| `TF_VAR_mq_password` | Amazon MQ broker password | Required for standard `spinup.sh` script execution |
| `TF_VAR_jwt_secret` | Auth service JWT Secret string | Required for standard `spinup.sh` script execution |

## 8. Module Dependency Diagram

```text
┌─────────────────────────┐
│                         │
│   backend-bootstrap     │ (S3 Bucket & DynamoDB Locks)
│                         │
└────────────┬────────────┘
             │ State dependency
             ▼
┌─────────────────────────┐
│                         │
│        hub-vpc          │ (Public Bastion Subnet, Transit Gateway)
│                         │
└────────────┬────────────┘
             │ Pass TGW_ID
             ▼
┌─────────────────────────┐
│                         │
│     spoke-vpc-eks       │ (Private Subnets, EKS, IRSA, Add-ons)
│                         │
└────────────┬────────────┘
             │ Pass VPC_ID, Subnets, Node SG
             ▼
┌─────────────────────────┐
│                         │
│    managed-services     │ (RDS, Redis, MQ, Secrets Manager)
│                         │
└─────────────────────────┘

┌─────────────────────────┐
│                         │
│        bastion          │ (EC2 SSM Host inside hub-vpc)
│                         │
└────────────▲────────────┘
             │ Pass Hub VPC Details
        (hub-vpc)
```
