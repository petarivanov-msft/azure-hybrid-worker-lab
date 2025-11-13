# ==============================================================================
# Step-by-Step Guide: Deploy from Azure Cloud Shell
# ==============================================================================

# DEPLOYMENT INSTRUCTIONS
# ==============================================================================

## Step 1: Open Azure Cloud Shell

Go to: https://shell.azure.com
- OR -
Click the Cloud Shell icon (>_) in the Azure Portal toolbar

Choose "Bash" when prompted (recommended for Terraform)

## Step 2: Verify and Set Correct Subscription

```bash
# List all available subscriptions
az account list --output table

# Show current subscription
az account show

# If you need to switch, set the correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID_OR_NAME"

# Verify it's now set correctly
az account show --query "{Name:name, SubscriptionId:id}" --output table
```

## Step 3: Clone Your Repository

```bash
# Clone the repository
git clone https://github.com/petarivanov-msft/azure-hybrid-worker-lab.git

# Navigate to the directory
cd azure-hybrid-worker-lab
```

## Step 4: Verify Prerequisites

```bash
# Check Terraform is available (Cloud Shell has it pre-installed)
terraform version

# Check Azure CLI is available and authenticated (Cloud Shell auto-authenticates)
az account show

# Verify you're in the correct subscription
az account list --output table
```

## Step 5: (Optional) Customize Configuration

```bash
# Edit variables if needed
code variables.tf

# Or create a terraform.tfvars file
cat > terraform.tfvars <<EOF
location = "eastus"
prefix = "hwlab"
vm_size = "Standard_B2s"
run_test_runbook = true
EOF
```

## Step 5: Deploy Infrastructure

```bash
# Initialize Terraform (downloads providers)
terraform init

# Review what will be created (optional)
terraform plan

# Deploy everything (takes ~7-10 minutes)
terraform apply -auto-approve
```

## Step 7: Monitor Deployment

The deployment will show progress for each resource:
- Resource Group (12s)
- Virtual Network & Networking (5-15s)
- Automation Account (7s)
- Virtual Machine (30s)
- Fetch AutomationHybridServiceUrl (5s)
- Register Hybrid Worker (3s)
- Install Hybrid Worker Extension (3 minutes)
- Install PowerShell modules (2-3 minutes)
- Create and publish runbook (20s)
- Execute test runbook (2 minutes)

## Step 8: View Results

```bash
# View all outputs
terraform output

# View specific output
terraform output runbook_link

# View VM password
terraform output vm_admin_password
```

## Step 9: Test Manually (Optional)

```bash
# Run the test runbook manually
az automation runbook start \
  --automation-account-name hwlab-automation \
  --resource-group rg-hybrid-worker-lab \
  --name Test-HybridWorker-ManagedIdentity \
  --run-on hwlab-worker-group
```

## Step 10: Cleanup

```bash
# When done, destroy all resources to avoid costs
terraform destroy -auto-approve
```

# ==============================================================================
# TROUBLESHOOTING IN CLOUD SHELL
# ==============================================================================

## Issue: Terraform not found
```bash
# Cloud Shell has Terraform pre-installed, but if missing:
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

## Issue: Wrong subscription
```bash
# List all subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

## Issue: Need to restart Cloud Shell
```bash
# Cloud Shell sessions timeout after 20 minutes of inactivity
# Simply refresh the browser to reconnect
# Your files in ~/clouddrive are persisted
```

## Issue: Large output during runbook execution
```bash
# If the runbook output is too large, you can skip auto-execution
# Edit variables.tf and set:
# run_test_runbook = false
```

# ==============================================================================
# CLOUD SHELL TIPS
# ==============================================================================

## Storage
- Cloud Shell mounts an Azure File Share (~5GB) at ~/clouddrive
- Files in ~ are persisted across sessions
- Clone your repo to ~ to keep it between sessions

## Editor
- Use `code filename` to open VS Code in the browser
- Use `nano filename` or `vim filename` for terminal editors

## Session Management
- Sessions timeout after 20 minutes of inactivity
- Use `tmux` to keep sessions alive:
  ```bash
  tmux new -s terraform
  # Run your terraform commands
  # Detach: Ctrl+B then D
  # Reattach: tmux attach -t terraform
  ```

## Performance
- Cloud Shell runs on Standard_D2s_v3 (2 vCPU, 8GB RAM)
- Sufficient for Terraform operations
- If slow, try during off-peak hours

# ==============================================================================
# ESTIMATED TIMELINE
# ==============================================================================

Total time from Cloud Shell to deployed infrastructure: ~10-15 minutes

Breakdown:
- Clone repository: 10 seconds
- Terraform init: 30 seconds
- Terraform apply: 7-10 minutes
- View results: 1 minute

# ==============================================================================
# COST REMINDER
# ==============================================================================

- Cloud Shell: FREE (5GB storage included with Azure subscription)
- Resources created: ~$38/month if VM runs 24/7
- IMPORTANT: Run `terraform destroy` when done to avoid charges!

# ==============================================================================
# NEXT STEPS AFTER DEPLOYMENT
# ==============================================================================

1. Open the runbook_link in Azure Portal to see your runbook
2. Check the VM in Azure Portal to see extensions installed
3. View the Hybrid Worker Group in Automation Account
4. Try creating your own custom runbooks
5. Extend the lab by adding more automation scenarios

# ==============================================================================
# ADDITIONAL RESOURCES
# ==============================================================================

- Azure Cloud Shell Docs: https://docs.microsoft.com/azure/cloud-shell/overview
- Terraform on Cloud Shell: https://docs.microsoft.com/azure/developer/terraform/get-started-cloud-shell
- Azure Automation: https://docs.microsoft.com/azure/automation/
- GitHub Docs: https://docs.github.com

# ==============================================================================
