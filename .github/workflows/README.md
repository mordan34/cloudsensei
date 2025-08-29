# GitHub Workflows for CloudSensei Infrastructure

This directory contains GitHub Actions workflows for managing CloudSensei infrastructure deployment using Terragrunt and Terraform.

## Workflows

### `terragrunt-deploy.yml`

This workflow handles the deployment of infrastructure components in the management account using Terragrunt.

## Features

### 🔍 Smart Change Detection
- Uses `dorny/paths-filter` to detect changes in specific modules
- Only deploys modules that have changed
- Supports manual deployment of all modules via workflow dispatch

### 🏗️ Dependency Management
- Network infrastructure is deployed first (VPC, subnets, NAT gateways)
- EKS cluster deployment waits for network completion
- Proper error handling and rollback capabilities

### 🛡️ Security Best Practices
- Uses GitHub environments for deployment protection
- Requires manual approval for production deployments
- Stores Terraform plans as artifacts for review
- Uses OIDC for AWS authentication (recommended)

### 📊 Multi-Environment Support
- Supports management, staging, and production environments
- Environment-specific configurations via GitHub environments
- Manual workflow dispatch with environment selection

## Triggers

### Automatic Triggers
- **Push to main/develop**: Runs validation and applies changes to main branch
- **Pull Request to main**: Runs validation and planning only
- **File Changes**: Only triggers when Terraform or Terragrunt files change

### Manual Triggers
- **Workflow Dispatch**: Manually trigger with environment and action selection
- Actions: `plan`, `apply`, `destroy`
- Environments: `management`, `staging`, `production`

## Workflow Jobs

### 1. `detect-changes`
- Detects which modules have changed
- Creates a deployment matrix for subsequent jobs
- Outputs boolean flags for network and EKS changes

### 2. `validate`
- Runs in parallel for all changed modules
- Validates Terraform syntax and configuration
- Generates and uploads Terraform plans as artifacts

### 3. `deploy-network`
- Deploys network infrastructure (VPC, subnets, etc.)
- Only runs if network changes detected
- Requires manual approval in production environments

### 4. `deploy-eks`
- Deploys EKS cluster and node groups
- Depends on successful network deployment
- Updates kubeconfig and verifies cluster health

### 5. `cleanup`
- Merges and manages Terraform plan artifacts
- Runs regardless of deployment success/failure

### 6. `notify`
- Provides deployment status summary
- Can be extended to send notifications to Slack/Teams

## Setup Requirements

### GitHub Secrets

The workflow requires the following secrets to be configured in your GitHub repository:

```bash
# AWS Credentials (if not using OIDC)
AWS_ACCESS_KEY_ID         # AWS Access Key ID
AWS_SECRET_ACCESS_KEY     # AWS Secret Access Key

# Alternative: AWS OIDC Configuration (Recommended)
AWS_ROLE_TO_ASSUME        # ARN of the IAM role to assume
AWS_WEB_IDENTITY_TOKEN_FILE # Token file for OIDC authentication
```

### GitHub Environments

Create the following environments in your GitHub repository settings:

1. **management**
   - No approval required
   - Used for development/testing deployments

2. **staging**
   - Optional: Require approval from reviewers
   - Used for pre-production testing

3. **production**
   - **Require approval** from designated reviewers
   - Used for production deployments

### AWS Prerequisites

Ensure the following AWS resources exist before running the workflow:

```bash
# S3 bucket for Terraform state (replace ACCOUNT_ID with your AWS account ID)
aws s3api create-bucket \
  --bucket cloudsensei-terraform-state-ACCOUNT_ID \
  --region me-west-1 \
  --create-bucket-configuration LocationConstraint=me-west-1

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name cloudsensei-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region me-west-1
```

## Usage Examples

### Automatic Deployment
```bash
# 1. Make changes to Terraform/Terragrunt files
git add accounts/management/terraform/me-west-1/network/main.tf
git commit -m "feat: update VPC CIDR block"
git push origin main

# 2. Workflow automatically detects changes and deploys network module
```

### Manual Deployment
1. Go to **Actions** tab in GitHub
2. Select **Terragrunt Infrastructure Deployment** workflow
3. Click **Run workflow**
4. Choose:
   - Environment: `management` | `staging` | `production`
   - Action: `plan` | `apply` | `destroy`
5. Click **Run workflow**

### Pull Request Validation
```bash
# 1. Create feature branch
git checkout -b feature/update-eks-version

# 2. Make changes
git add accounts/management/terraform/me-west-1/eks/variables.tf
git commit -m "feat: update EKS to version 1.29"

# 3. Push and create PR
git push origin feature/update-eks-version

# 4. Workflow runs validation and planning automatically
```

## Monitoring and Troubleshooting

### Viewing Deployment Status
- Check the **Actions** tab in GitHub for workflow runs
- Review job logs for detailed information
- Download Terraform plan artifacts for review

### Common Issues

1. **State Lock Errors**
   ```bash
   # Manually unlock if needed (use with caution)
   terragrunt force-unlock <LOCK_ID>
   ```

2. **Permission Errors**
   - Verify AWS credentials have necessary permissions
   - Check IAM policies for Terraform/Terragrunt operations

3. **Dependency Failures**
   - Network module must be deployed before EKS
   - Check if network deployment completed successfully

### Debugging

Enable debug logging by adding to your workflow run:
```yaml
env:
  TF_LOG: DEBUG
  TG_LOG: DEBUG
```

## Security Considerations

### Secrets Management
- Use GitHub's encrypted secrets for sensitive data
- Consider using AWS OIDC for keyless authentication
- Rotate AWS credentials regularly

### Environment Protection
- Configure branch protection rules for main branch
- Require PR reviews before merging infrastructure changes
- Use environment-specific approval workflows

### Audit Trail
- All deployments are logged in GitHub Actions
- Terraform state changes are tracked in AWS CloudTrail
- Plan artifacts provide change history

## Extending the Workflow

### Adding New Modules
1. Create Terraform module in `accounts/management/terraform/me-west-1/`
2. Create Terragrunt configuration in `accounts/management/terragrunt/me-west-1/`
3. Update workflow path filters in `detect-changes` job
4. Add new deployment job following existing pattern

### Multi-Region Support
1. Duplicate module structure for new regions
2. Update workflow matrix to include region parameter
3. Configure region-specific secrets and environments

### Notification Integration
```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    channel: '#infrastructure'
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Version History

- v1.0.0: Initial workflow with basic deployment capabilities
- v1.1.0: Added change detection and matrix strategy
- v1.2.0: Enhanced security with environment protection