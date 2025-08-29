#!/bin/bash
# GitHub Repository Setup Script for CloudSensei Infrastructure
# This script helps configure the repository for Terragrunt deployments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
AWS_REGION="me-west-1"
PROJECT_NAME="cloudsensei"

echo -e "${BLUE}🚀 CloudSensei Infrastructure - GitHub Repository Setup${NC}"
echo "============================================================"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo -e "\n${BLUE}Checking prerequisites...${NC}"
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI is not installed. Some steps will need manual configuration."
        GITHUB_CLI=false
    else
        GITHUB_CLI=true
    fi
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi
    
    print_status "Prerequisites check completed"
}

# Get AWS account ID
get_aws_account_id() {
    echo -e "\n${BLUE}Getting AWS account information...${NC}"
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured properly."
        print_info "Please run: aws configure"
        exit 1
    fi
    
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    
    print_status "Connected to AWS account: ${AWS_ACCOUNT_ID}"
    print_info "Current user/role: ${AWS_USER_ARN}"
}

# Create S3 bucket for Terraform state
create_s3_bucket() {
    echo -e "\n${BLUE}Creating S3 bucket for Terraform state...${NC}"
    
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID}"
    
    # Check if bucket already exists
    if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
        print_warning "S3 bucket ${BUCKET_NAME} already exists"
    else
        # Create bucket with region constraint for regions other than us-east-1
        if [[ "${AWS_REGION}" == "us-east-1" ]]; then
            aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
        else
            aws s3api create-bucket \
                --bucket "${BUCKET_NAME}" \
                --region "${AWS_REGION}" \
                --create-bucket-configuration LocationConstraint="${AWS_REGION}"
        fi
        print_status "Created S3 bucket: ${BUCKET_NAME}"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "${BUCKET_NAME}" \
        --versioning-configuration Status=Enabled
    print_status "Enabled versioning on S3 bucket"
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "${BUCKET_NAME}" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    print_status "Enabled encryption on S3 bucket"
}

# Create DynamoDB table for state locking
create_dynamodb_table() {
    echo -e "\n${BLUE}Creating DynamoDB table for state locking...${NC}"
    
    TABLE_NAME="${PROJECT_NAME}-terraform-locks"
    
    # Check if table already exists
    if aws dynamodb describe-table --table-name "${TABLE_NAME}" 2>/dev/null; then
        print_warning "DynamoDB table ${TABLE_NAME} already exists"
    else
        aws dynamodb create-table \
            --table-name "${TABLE_NAME}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "${AWS_REGION}"
        
        print_status "Created DynamoDB table: ${TABLE_NAME}"
        print_info "Waiting for table to become active..."
        aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${AWS_REGION}"
        print_status "DynamoDB table is now active"
    fi
}

# Setup GitHub secrets
setup_github_secrets() {
    echo -e "\n${BLUE}Setting up GitHub repository secrets...${NC}"
    
    if [[ "${GITHUB_CLI}" == true ]]; then
        read -p "Enter your GitHub repository (format: owner/repo): " GITHUB_REPO
        if [[ -z "${GITHUB_REPO}" ]]; then
            print_error "GitHub repository is required"
            return
        fi
        
        # Set up basic secrets
        read -s -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID
        echo
        read -s -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
        echo
        
        gh secret set AWS_ACCESS_KEY_ID --body "${AWS_ACCESS_KEY_ID}" --repo "${GITHUB_REPO}"
        gh secret set AWS_SECRET_ACCESS_KEY --body "${AWS_SECRET_ACCESS_KEY}" --repo "${GITHUB_REPO}"
        
        print_status "GitHub secrets configured"
    else
        print_info "Please manually configure the following GitHub secrets:"
        echo "  - AWS_ACCESS_KEY_ID"
        echo "  - AWS_SECRET_ACCESS_KEY"
        echo "  - Or configure AWS_ROLE_TO_ASSUME for OIDC"
    fi
}

# Create GitHub environments
create_github_environments() {
    echo -e "\n${BLUE}Setting up GitHub environments...${NC}"
    
    if [[ "${GITHUB_CLI}" == true ]]; then
        # Create environments
        gh api repos/"${GITHUB_REPO}"/environments/management -X PUT || print_warning "Management environment may already exist"
        gh api repos/"${GITHUB_REPO}"/environments/staging -X PUT || print_warning "Staging environment may already exist"  
        gh api repos/"${GITHUB_REPO}"/environments/production -X PUT || print_warning "Production environment may already exist"
        
        print_status "GitHub environments created"
        print_info "Consider adding protection rules for production environment"
    else
        print_info "Please manually create GitHub environments:"
        echo "  - management (no protection)"
        echo "  - staging (optional protection)"
        echo "  - production (with protection rules)"
    fi
}

# Generate summary
generate_summary() {
    echo -e "\n${GREEN}🎉 Setup completed successfully!${NC}"
    echo "============================================================"
    echo
    echo "📋 Summary of created resources:"
    echo "  • S3 Bucket: ${PROJECT_NAME}-terraform-state-${AWS_ACCOUNT_ID}"
    echo "  • DynamoDB Table: ${PROJECT_NAME}-terraform-locks"
    echo "  • AWS Region: ${AWS_REGION}"
    echo
    echo "📝 Next steps:"
    echo "  1. Commit and push your changes to trigger the workflow"
    echo "  2. Check the Actions tab in GitHub to monitor deployments"
    echo "  3. Configure branch protection rules for main branch"
    echo "  4. Set up environment protection for production"
    echo
    echo "🚀 Example deployment commands:"
    echo "  • Manual deployment: Go to Actions → Terragrunt Infrastructure Deployment → Run workflow"
    echo "  • Automatic deployment: Push changes to main branch"
    echo
    echo "📚 Documentation:"
    echo "  • Workflow README: .github/workflows/README.md"
    echo "  • Infrastructure README: accounts/management/README.md"
}

# Main execution
main() {
    check_prerequisites
    get_aws_account_id
    create_s3_bucket
    create_dynamodb_table
    setup_github_secrets
    create_github_environments
    generate_summary
}

# Run main function
main "$@"