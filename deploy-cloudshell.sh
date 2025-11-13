#!/bin/bash

# ==============================================================================
# Azure Cloud Shell Quickstart Script
# ==============================================================================
# This script automates the deployment of Azure Hybrid Worker Lab
# Run this in Azure Cloud Shell (Bash)
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "=========================================="
echo "  Azure Hybrid Worker Lab Deployment"
echo "=========================================="
echo -e "${NC}"

# Step 1: Verify prerequisites
echo -e "${GREEN}Step 1: Verifying prerequisites...${NC}"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform not found${NC}"
    echo "Installing Terraform..."
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
    unzip terraform_1.6.0_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm terraform_1.6.0_linux_amd64.zip
fi

echo -e "${CYAN}Terraform version:${NC}"
terraform version

# Check Azure CLI
echo -e "${CYAN}Azure CLI version:${NC}"
az version --output tsv | head -n 1

# Show current subscription
echo -e "${CYAN}Current Azure subscription:${NC}"
az account show --query "{Name:name, SubscriptionId:id, TenantId:tenantId}" --output table

# Confirm subscription
read -p "$(echo -e ${YELLOW}Is this the correct subscription? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please set the correct subscription:${NC}"
    echo "az account list --output table"
    echo "az account set --subscription YOUR_SUBSCRIPTION_ID"
    exit 1
fi

# Step 2: Initialize Terraform
echo -e "\n${GREEN}Step 2: Initializing Terraform...${NC}"
terraform init

# Step 3: Validate configuration
echo -e "\n${GREEN}Step 3: Validating Terraform configuration...${NC}"
terraform validate

# Step 4: Plan (optional)
read -p "$(echo -e ${YELLOW}Show Terraform plan before applying? [y/N]: ${NC})" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform plan
    read -p "$(echo -e ${YELLOW}Continue with deployment? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Deployment cancelled${NC}"
        exit 0
    fi
fi

# Step 5: Deploy
echo -e "\n${GREEN}Step 4: Deploying infrastructure...${NC}"
echo -e "${YELLOW}This will take approximately 7-10 minutes${NC}"
echo -e "${YELLOW}Progress will be shown below...${NC}\n"

start_time=$(date +%s)

terraform apply -auto-approve

end_time=$(date +%s)
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

# Step 6: Display results
echo -e "\n${GREEN}=========================================="
echo "  Deployment Complete!"
echo "==========================================${NC}"
echo -e "Duration: ${CYAN}${minutes}m ${seconds}s${NC}\n"

echo -e "${GREEN}Outputs:${NC}"
terraform output

echo -e "\n${CYAN}=========================================="
echo "  Important Links"
echo "==========================================${NC}"

echo -e "\n${YELLOW}View your resources:${NC}"
terraform output azure_portal_link

echo -e "\n${YELLOW}View the runbook:${NC}"
terraform output runbook_link

echo -e "\n${YELLOW}Get VM password:${NC}"
echo "terraform output vm_admin_password"

echo -e "\n${CYAN}=========================================="
echo "  What's Next?"
echo "==========================================${NC}"

echo -e "\n1. ${GREEN}Test the runbook manually:${NC}"
echo "   az automation runbook start \\"
echo "     --automation-account-name hwlab-automation \\"
echo "     --resource-group rg-hybrid-worker-lab \\"
echo "     --name Test-HybridWorker-ManagedIdentity \\"
echo "     --run-on hwlab-worker-group"

echo -e "\n2. ${GREEN}View all outputs:${NC}"
echo "   terraform output"

echo -e "\n3. ${GREEN}Connect to VM via RDP:${NC}"
echo "   Username: $(terraform output -raw vm_admin_username)"
echo "   Password: terraform output -raw vm_admin_password"
echo "   IP: $(terraform output -raw vm_public_ip)"

echo -e "\n4. ${RED}Cleanup when done (to avoid costs):${NC}"
echo "   terraform destroy -auto-approve"

echo -e "\n${CYAN}=========================================="
echo "  Cost Reminder"
echo "==========================================${NC}"
echo -e "${YELLOW}Resources cost approximately $38/month${NC}"
echo -e "${RED}Run 'terraform destroy' when finished!${NC}\n"

# Save outputs to file
echo -e "${GREEN}Saving outputs to deployment-info.txt...${NC}"
{
    echo "Azure Hybrid Worker Lab - Deployment Information"
    echo "================================================="
    echo "Deployed at: $(date)"
    echo "Duration: ${minutes}m ${seconds}s"
    echo ""
    echo "Outputs:"
    echo "--------"
    terraform output
} > deployment-info.txt

echo -e "${GREEN}✅ Deployment information saved to deployment-info.txt${NC}\n"
