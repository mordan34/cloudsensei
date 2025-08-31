#!/bin/bash
# GitHub Workflows Validation Script
# This script validates the workflow files and checks configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo -e "${BLUE}🔍 Validating GitHub Workflows${NC}"
echo "=================================="

# Check if workflow files exist
check_workflow_files() {
    echo -e "\n${BLUE}Checking workflow files...${NC}"
    
    if [[ -f ".github/workflows/terragrunt-deploy.yml" ]]; then
        print_status "Basic workflow file exists"
    else
        print_error "Basic workflow file missing"
    fi
    
    if [[ -f ".github/workflows/terragrunt-deploy-oidc.yml" ]]; then
        print_status "OIDC workflow file exists"
    else
        print_error "OIDC workflow file missing"
    fi
    
    if [[ -f ".github/workflows/README.md" ]]; then
        print_status "Workflow documentation exists"
    else
        print_warning "Workflow documentation missing"
    fi
}

# Validate YAML syntax
validate_yaml_syntax() {
    echo -e "\n${BLUE}Validating YAML syntax...${NC}"
    
    for workflow in .github/workflows/*.yml; do
        if [[ -f "$workflow" ]]; then
            if command -v yq &> /dev/null; then
                if yq eval . "$workflow" > /dev/null 2>&1; then
                    print_status "$(basename "$workflow") - Valid YAML syntax"
                else
                    print_error "$(basename "$workflow") - Invalid YAML syntax"
                fi
            else
                print_warning "yq not installed - skipping YAML validation"
                break
            fi
        fi
    done
}

# Check required GitHub Actions
check_github_actions() {
    echo -e "\n${BLUE}Checking GitHub Actions usage...${NC}"
    
    # List of expected actions
    expected_actions=(
        "actions/checkout@v4"
        "hashicorp/setup-terraform@v3"
        "aws-actions/configure-aws-credentials@v4"
        "dorny/paths-filter@v2"
        "actions/upload-artifact@v4"
        "actions/download-artifact@v4"
    )
    
    for action in "${expected_actions[@]}"; do
        if grep -r "$action" .github/workflows/ > /dev/null 2>&1; then
            print_status "Using $action"
        else
            print_warning "Missing $action"
        fi
    done
}

# Check terraform/terragrunt structure
check_infrastructure_structure() {
    echo -e "\n${BLUE}Checking infrastructure structure...${NC}"
    
    # Check terraform modules
    if [[ -d "accounts/management/terraform/eu-central-1/network" ]]; then
        print_status "Network Terraform module exists"
    else
        print_error "Network Terraform module missing"
    fi
    
    if [[ -d "accounts/management/terraform/eu-central-1/eks" ]]; then
        print_status "EKS Terraform module exists"
    else
        print_error "EKS Terraform module missing"
    fi
    
    # Check terragrunt configurations
    if [[ -d "accounts/management/terragrunt/eu-central-1/network" ]]; then
        print_status "Network Terragrunt config exists"
    else
        print_error "Network Terragrunt config missing"
    fi
    
    if [[ -d "accounts/management/terragrunt/eu-central-1/eks" ]]; then
        print_status "EKS Terragrunt config exists"
    else
        print_error "EKS Terragrunt config missing"
    fi
}

# Check required files in modules
check_module_files() {
    echo -e "\n${BLUE}Checking module completeness...${NC}"
    
    modules=("accounts/management/terraform/eu-central-1/network" "accounts/management/terraform/eu-central-1/eks")
    required_files=("main.tf" "variables.tf" "outputs.tf")
    
    for module in "${modules[@]}"; do
        module_name=$(basename "$module")
        print_info "Checking $module_name module..."
        
        for file in "${required_files[@]}"; do
            if [[ -f "$module/$file" ]]; then
                print_status "  $file exists"
            else
                print_error "  $file missing"
            fi
        done
    done
    
    # Check terragrunt configs
    terragrunt_configs=("accounts/management/terragrunt/eu-central-1/network" "accounts/management/terragrunt/eu-central-1/eks")
    
    for config in "${terragrunt_configs[@]}"; do
        config_name=$(basename "$config")
        print_info "Checking $config_name terragrunt config..."
        
        if [[ -f "$config/terragrunt.hcl" ]]; then
            print_status "  terragrunt.hcl exists"
        else
            print_error "  terragrunt.hcl missing"
        fi
    done
}

# Check for sensitive information
check_security() {
    echo -e "\n${BLUE}Checking for security issues...${NC}"
    
    # Check for hardcoded secrets
    if grep -r "aws_access_key_id\|aws_secret_access_key" --exclude-dir=.git . 2>/dev/null | grep -v ".github/workflows/README.md" | grep -v ".github/setup-repository.sh" | grep -v ".github/validate-workflows.sh"; then
        print_error "Potential hardcoded AWS credentials found"
    else
        print_status "No hardcoded AWS credentials found"
    fi
    
    # Check for proper secret usage in workflows
    if grep -r "secrets\." .github/workflows/ > /dev/null 2>&1; then
        print_status "Workflows use GitHub secrets"
    else
        print_warning "No GitHub secrets usage found in workflows"
    fi
}

# Generate recommendations
generate_recommendations() {
    echo -e "\n${BLUE}Recommendations:${NC}"
    echo "=================="
    
    echo "1. 🔧 Setup Steps:"
    echo "   - Run: ./.github/setup-repository.sh"
    echo "   - Configure GitHub secrets (AWS credentials)"
    echo "   - Set up GitHub environments (management, staging, production)"
    echo
    echo "2. 🛡️  Security:"
    echo "   - Enable branch protection on main branch"
    echo "   - Require PR reviews before merging"
    echo "   - Configure environment protection rules"
    echo "   - Consider using OIDC instead of access keys"
    echo
    echo "3. 📋 Testing:"
    echo "   - Create a test PR to validate workflow"
    echo "   - Test manual workflow dispatch"
    echo "   - Verify artifact upload/download"
    echo
    echo "4. 📚 Documentation:"
    echo "   - Review .github/workflows/README.md"
    echo "   - Update accounts/management/README.md with your specific configuration"
    echo "   - Document any customizations"
}

# Main execution
main() {
    check_workflow_files
    validate_yaml_syntax
    check_github_actions
    check_infrastructure_structure
    check_module_files
    check_security
    generate_recommendations
    
    echo -e "\n${GREEN}🎉 Workflow validation completed!${NC}"
}

# Run main function
main "$@"