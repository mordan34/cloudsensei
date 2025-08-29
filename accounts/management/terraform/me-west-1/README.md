# CloudSensei Infrastructure - ME-West-1 Region

This directory contains Terragrunt and Terraform configurations for deploying infrastructure in the Middle East (UAE) - `me-west-1` region.

## Architecture Overview

The infrastructure consists of two main components:

1. **Network Layer** (`network/`) - VPC, subnets, NAT gateways, route tables
2. **EKS Cluster** (`eks/`) - Amazon Elastic Kubernetes Service cluster with managed node groups

## Directory Structure

```
me-west-1/
├── README.md
├── network/
│   ├── main.tf           # VPC and networking resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   └── terragrunt.hcl    # Terragrunt configuration
└── eks/
    ├── main.tf           # EKS cluster and node group resources
    ├── variables.tf      # Input variables
    ├── outputs.tf        # Output values
    └── terragrunt.hcl    # Terragrunt configuration
```

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS CLI** configured with appropriate credentials
2. **Terragrunt** installed (version >= 0.50.0)
3. **Terraform** installed (version >= 1.0)
4. **S3 bucket** for Terraform state storage
5. **DynamoDB table** for state locking

### Required AWS Resources

Create these resources before deployment:

```bash
# S3 bucket for state storage (replace ACCOUNT_ID with your AWS account ID)
aws s3api create-bucket \
  --bucket cloudsensei-terraform-state-ACCOUNT_ID \
  --region me-west-1 \
  --create-bucket-configuration LocationConstraint=me-west-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket cloudsensei-terraform-state-ACCOUNT_ID \
  --versioning-configuration Status=Enabled

# DynamoDB table for state locking
aws dynamodb create-table \
  --table-name cloudsensei-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region me-west-1
```

## Network Configuration

The network module creates:

- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnets**: 2 subnets across different AZs
  - 10.0.1.0/24 (AZ-a)
  - 10.0.2.0/24 (AZ-b)
- **Private Subnets**: 2 subnets across different AZs
  - 10.0.10.0/24 (AZ-a)
  - 10.0.20.0/24 (AZ-b)
- **NAT Gateways**: One per public subnet for high availability
- **Route Tables**: Separate routing for public and private subnets
- **Internet Gateway**: For public internet access

### Key Features

- High availability across multiple AZs
- Proper subnet tagging for EKS integration
- Encrypted NAT Gateway traffic
- Comprehensive resource tagging

## EKS Configuration

The EKS module creates:

- **EKS Cluster**: Kubernetes 1.28
- **Managed Node Group**: Auto-scaling worker nodes
- **Security Groups**: Proper network isolation
- **IAM Roles**: Least privilege access
- **KMS Encryption**: For secrets and EBS volumes
- **CloudWatch Logging**: Comprehensive audit trail
- **OIDC Provider**: For service account integration

### Key Features

- **Security**: 
  - KMS encryption for secrets and EBS volumes
  - Security groups with minimal required access
  - Private API endpoint access
  - CloudWatch logging enabled

- **High Availability**:
  - Multi-AZ node placement
  - Auto-scaling group configuration
  - Load balancer integration ready

- **Scalability**:
  - Configurable node group sizes
  - Support for spot and on-demand instances
  - Multiple instance type support

## Deployment Instructions

### 1. Deploy Network Infrastructure

```bash
cd accounts/management/terraform/me-west-1/network
terragrunt plan
terragrunt apply
```

### 2. Deploy EKS Cluster

```bash
cd ../eks
terragrunt plan
terragrunt apply
```

### 3. Configure kubectl

After deployment, configure kubectl to connect to your cluster:

```bash
aws eks update-kubeconfig \
  --region me-west-1 \
  --name cloudsensei-mgmt-eks \
  --profile your-aws-profile
```

## Resource Configuration

### Default Values

| Component | Resource | Default Value |
|-----------|----------|---------------|
| VPC | CIDR | 10.0.0.0/16 |
| EKS | Version | 1.28 |
| EKS | Instance Type | t3.medium |
| EKS | Node Count | 2 (min: 1, max: 4) |
| EKS | Disk Size | 50 GiB |
| EKS | Capacity Type | ON_DEMAND |

### Customization

You can customize the deployment by modifying the `inputs` section in the respective `terragrunt.hcl` files.

## Security Considerations

1. **Network Isolation**: Worker nodes run in private subnets
2. **Encryption**: All data encrypted at rest and in transit
3. **IAM**: Least privilege access patterns
4. **Logging**: Comprehensive audit trails
5. **Updates**: Regular security patch management required

## Cost Optimization

- Use Spot instances for non-production workloads
- Right-size instance types based on workload requirements
- Monitor and adjust auto-scaling parameters
- Consider Reserved Instances for long-term deployments

## Monitoring and Maintenance

### CloudWatch Integration

- Cluster logs automatically sent to CloudWatch
- Custom dashboards can be created for monitoring
- Set up alerts for cluster health and capacity

### Updates

- Regularly update Kubernetes version
- Keep node AMIs up to date
- Monitor security advisories

## Cleanup

To destroy the infrastructure:

```bash
# Destroy EKS first (due to dependencies)
cd accounts/management/terraform/me-west-1/eks
terragrunt destroy

# Then destroy network infrastructure
cd ../network
terragrunt destroy
```

## Troubleshooting

### Common Issues

1. **State Lock**: If deployment fails with state lock errors, check DynamoDB table
2. **Permissions**: Ensure AWS credentials have necessary permissions
3. **Quotas**: Check AWS service quotas for EKS and EC2
4. **Dependencies**: Ensure network module is deployed before EKS

### Support

For issues specific to this infrastructure:
1. Check Terragrunt logs for detailed error messages
2. Verify AWS resource limits and quotas
3. Ensure proper IAM permissions
4. Check AWS service health in the region

## Version History

- v1.0.0: Initial infrastructure setup with VPC and EKS