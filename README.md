# Azure Hybrid Worker Lab - Terraform

Complete Terraform configuration for deploying an Azure Automation Hybrid Worker environment with automated testing, managed identities, and PowerShell automation capabilities.

## 🎯 What This Does

Creates a **production-ready** Azure Hybrid Worker lab with:
- ✅ Windows VM (Windows Server 2022) with system-assigned managed identity
- ✅ Azure Automation Account with system-assigned managed identity
- ✅ Hybrid Worker Group and VM registration
- ✅ PowerShell modules (Az.Accounts, Az.Compute) on both VM and Automation Account
- ✅ Test runbook that uses managed identity authentication
- ✅ Automated runbook execution and testing
- ✅ Contributor role assignments for both managed identities

## 🚀 Quick Start (Azure Cloud Shell)

### 1. Open Azure Cloud Shell
```bash
# Go to: https://shell.azure.com
# Or click the Cloud Shell icon in Azure Portal
```

### 2. Clone this repository
```bash
git clone https://github.com/petarivanov-msft/azure-hybrid-worker-lab.git
cd azure-hybrid-worker-lab
```

### 3. Deploy
```bash
# Initialize Terraform
terraform init

# Deploy (takes ~7-10 minutes)
terraform apply -auto-approve
```

### 4. View Results
After deployment, you'll see outputs with links to your resources in Azure Portal.

### 5. Cleanup
```bash
# Destroy all resources
terraform destroy -auto-approve
```

## 📦 What's Included

- **`main.tf`** - Complete infrastructure (22 resources)
- **`variables.tf`** - Customizable parameters
- **`outputs.tf`** - 14 useful outputs
- **`run-test-runbook.ps1`** - Helper script for manual testing
- **`GUIDE.md`** - Comprehensive user guide
- **`README.md`** - This file

## ⚙️ Configuration

Edit `variables.tf` to customize:
- Azure region (default: eastus)
- Resource prefix (default: hwlab)
- VM size (default: Standard_B2s)
- Admin username (default: azureadmin)
- Auto-test runbook (default: true)

## 💰 Cost Estimation

Approximate monthly costs: **~$38/month** (if VM runs 24/7)
- Standard_B2s VM: ~$30/month
- Automation Account: First 500 minutes free
- Public IP: ~$3/month
- Storage: ~$5/month

**💡 Tip**: Use `terraform destroy` when not needed to avoid costs.

## 📚 What You'll Learn

1. Infrastructure as Code with Terraform
2. Azure Managed Identities
3. Hybrid Workers (run automation outside Azure)
4. Azure Automation & Runbooks
5. PowerShell automation with Az modules
6. RBAC (Role-Based Access Control)
7. External data sources in Terraform
8. Automated testing in IaC

## 🔧 How It Works

### Architecture
```
Azure Subscription
└── Resource Group
    ├── Automation Account (with managed identity)
    │   ├── Hybrid Worker Group
    │   ├── PowerShell Modules (Az.Accounts, Az.Compute)
    │   └── Test Runbook
    ├── Windows VM (with managed identity)
    │   ├── Hybrid Worker Extension
    │   └── PowerShell Modules
    └── Virtual Network
        └── Subnet + NSG + Public IP
```

### Key Features

1. **AutomationHybridServiceUrl Retrieval** - Uses external data source with Azure REST API
2. **Proper Registration Sequence** - VM registered before extension installation
3. **Error Handling** - Graceful handling during destroy operations
4. **Automated Testing** - Runbook automatically executes on deployment

## 🎮 Usage Examples

### Manual Runbook Execution

**Option 1: PowerShell Script**
```powershell
.\run-test-runbook.ps1
```

**Option 2: Azure CLI**
```bash
az automation runbook start \
  --automation-account-name hwlab-automation \
  --resource-group rg-hybrid-worker-lab \
  --name Test-HybridWorker-ManagedIdentity \
  --run-on hwlab-worker-group
```

**Option 3: Azure Portal**
Use the `runbook_link` output to open directly in Azure Portal.

## 🔍 Troubleshooting

See `GUIDE.md` for comprehensive troubleshooting guide.

Common issues already handled:
- ✅ AutomationHybridServiceUrl format errors
- ✅ Worker registration timing issues
- ✅ Destroy operation errors

## 📖 Documentation

- **`GUIDE.md`** - Complete user guide with examples
- **`README.md`** - This quick reference
- [Azure Automation Hybrid Worker](https://learn.microsoft.com/azure/automation/automation-hybrid-runbook-worker)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🎓 Next Steps

1. **Add More Runbooks** - Automate VM management, backups, monitoring
2. **Connect On-Premises** - Install Hybrid Worker on on-prem servers
3. **Integrate Monitoring** - Send logs to Azure Monitor
4. **Multi-Environment** - Use Terraform workspaces for dev/test/prod

## 📄 License

MIT License - See LICENSE file for details.

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## ⚠️ Disclaimer

This is a **lab/demo configuration** for learning purposes. Review and test thoroughly before using in production environments.

---

**Package Version**: 1.0  
**Last Updated**: November 2025  
**Terraform Version**: >= 1.0  
**Provider Versions**: azurerm ~> 3.0, azapi ~> 1.0

---

Made with ❤️ for Azure Automation learners
