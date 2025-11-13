# 📦 Azure Hybrid Worker Lab - Complete Package Guide

This is a **production-ready Terraform configuration** that creates a complete Azure Automation Hybrid Worker lab with automated testing, managed identities, and PowerShell automation capabilities.

---

## 📦 What's Included

This package contains everything you need to deploy and test an Azure Hybrid Worker environment:

```
terraform-azure-hybrid-worker-lab/
├── main.tf                      # Complete infrastructure definition (22 resources)
├── variables.tf                 # Customizable deployment parameters
├── outputs.tf                   # Deployment information and links
├── run-test-runbook.ps1         # Helper script for manual runbook execution
├── README.md                    # Technical documentation
└── GUIDE.md                     # This comprehensive guide
```

---

## 🎯 What This Deploys

### Infrastructure Components
| Component | Purpose | Details |
|-----------|---------|---------|
| **Resource Group** | Container for all resources | `rg-hybrid-worker-lab` |
| **Virtual Network** | Network infrastructure | 10.0.0.0/16 with subnet 10.0.1.0/24 |
| **Network Security Group** | Firewall rules | Allows RDP (port 3389) |
| **Public IP** | External access | Dynamic allocation |
| **Network Interface** | VM connectivity | Connected to subnet + NSG |

### Compute & Automation
| Component | Purpose | Details |
|-----------|---------|---------|
| **Windows VM** | Hybrid Worker host | Windows Server 2022, Standard_B2s |
| **Automation Account** | Runbook hosting | Basic SKU with hybrid capabilities |
| **Hybrid Worker Group** | Job routing | `hwlab-worker-group` |
| **Hybrid Worker Registration** | VM enrollment | UUID-based worker ID |
| **Hybrid Worker Extension** | Agent installation | Connects VM to Automation Account |

### Security & Identity
| Component | Purpose | Details |
|-----------|---------|---------|
| **VM Managed Identity** | System-assigned | Contributor role at subscription level |
| **Automation Managed Identity** | System-assigned | Contributor role at subscription level |
| **Role Assignments** | RBAC permissions | Full Azure resource management |

### Automation & Modules
| Component | Purpose | Details |
|-----------|---------|---------|
| **Az.Accounts Module** | Azure authentication | Installed on VM + Automation Account |
| **Az.Compute Module** | VM management | Installed on VM + Automation Account |
| **Test Runbook** | Validation script | 70-line PowerShell runbook with managed identity auth |
| **Custom Script Extension** | Module installation | Installs PowerShell modules on VM |

### Automation Resources
| Component | Purpose | Details |
|-----------|---------|---------|
| **Runbook Publisher** | Deployment automation | null_resource with state checking |
| **Runbook Executor** | Automated testing | null_resource that runs and displays output |

---

## 🚀 Quick Start Guide

### Prerequisites

Before you begin, ensure you have:

1. **Azure CLI** - Installed and authenticated
   ```powershell
   # Check if installed
   az --version
   
   # Login to Azure
   az login
   
   # Verify subscription
   az account show
   ```

2. **Terraform** - Version 1.0 or higher
   ```powershell
   # Check version
   terraform version
   ```

3. **PowerShell** - For automation scripts (pre-installed on Windows)

4. **Azure Subscription** - With permissions to create resources

---

### Deployment Steps

#### 1️⃣ **Initialize Terraform**
```powershell
cd terraform-azure-hybrid-worker-lab
terraform init
```
**What happens**: Downloads required providers (azurerm, azapi, random, external, null)

#### 2️⃣ **Review the Plan** (Optional)
```powershell
terraform plan
```
**What happens**: Shows all 22 resources that will be created without actually creating them

#### 3️⃣ **Deploy Everything**
```powershell
terraform apply -auto-approve
```
**What happens**: 
- Creates all infrastructure (~1-2 minutes)
- Deploys VM (~30 seconds)
- Fetches AutomationHybridServiceUrl (~5 seconds)
- Registers hybrid worker (~3 seconds)
- Installs Hybrid Worker Extension (~3 minutes)
- Installs PowerShell modules (~2-3 minutes)
- Creates and publishes runbook (~20 seconds)
- **Automatically tests the runbook** (~2 minutes)
- Displays runbook output showing successful execution

**Total deployment time**: ~7-10 minutes

#### 4️⃣ **View Results**
After deployment completes, you'll see outputs like:
```
automation_account_name = "hwlab-automation"
automation_hybrid_service_url = "https://[guid].jrds.eus.azure-automation.net/..."
runbook_link = "https://portal.azure.com/#@/resource/..."
vm_name = "hwlab-vm"
vm_principal_id = "[guid]"
automation_principal_id = "[guid]"
```

---

## 🔧 How It Works (Technical Deep Dive)

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                                │
│                       (Contributor RBAC Scope)                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │            Resource Group: rg-hybrid-worker-lab                    │ │
│  │                                                                     │ │
│  │  ┌────────────────────────┐         ┌───────────────────────────┐ │ │
│  │  │  Automation Account    │         │      Windows VM           │ │ │
│  │  │   hwlab-automation     │◄────────┤      hwlab-vm             │ │ │
│  │  │                        │ Worker  │                           │ │ │
│  │  │ ┌──────────────────┐  │ Group   │ ┌───────────────────────┐ │ │ │
│  │  │ │ Managed Identity │  │         │ │   Managed Identity    │ │ │ │
│  │  │ │ (Contributor)    │  │         │ │   (Contributor)       │ │ │ │
│  │  │ └──────────────────┘  │         │ └───────────────────────┘ │ │ │
│  │  │                        │         │                           │ │ │
│  │  │ ┌──────────────────┐  │         │ ┌───────────────────────┐ │ │ │
│  │  │ │  Az.Accounts     │  │         │ │   Az.Accounts         │ │ │ │
│  │  │ │  Az.Compute      │  │         │ │   Az.Compute          │ │ │ │
│  │  │ └──────────────────┘  │         │ └───────────────────────┘ │ │ │
│  │  │                        │         │                           │ │ │
│  │  │ ┌──────────────────┐  │         │ ┌───────────────────────┐ │ │ │
│  │  │ │ Test Runbook     │──┼─────────┼►│ Hybrid Worker Ext.    │ │ │ │
│  │  │ │ (PowerShell)     │  │ Runs On │ │ (Agent)               │ │ │ │
│  │  │ └──────────────────┘  │         │ └───────────────────────┘ │ │ │
│  │  └────────────────────────┘         └───────────────────────────┘ │ │
│  │                                                                     │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │         Virtual Network: hwlab-vnet (10.0.0.0/16)            │ │ │
│  │  │  ┌────────────────────────────────────────────────────────┐  │ │ │
│  │  │  │  Subnet: hwlab-subnet (10.0.1.0/24)                    │  │ │ │
│  │  │  │  + NSG (Allow RDP 3389)                                │  │ │ │
│  │  │  │  + Public IP (Dynamic)                                 │  │ │ │
│  │  │  └────────────────────────────────────────────────────────┘  │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 🔑 Key Technical Solutions

#### Problem 1: AutomationHybridServiceUrl Format
**Challenge**: Terraform doesn't expose the GUID-based URL needed for hybrid worker registration

**Solution**: External data source with Azure REST API
```hcl
data "external" "automation_hybrid_url" {
  program = ["pwsh", "-Command", <<EOT
    $result = az rest --method get --url "/subscriptions/.../automationAccounts/...?api-version=2023-11-01"
    $url = $result.properties.automationHybridServiceUrl
    Write-Output (@{url = $url} | ConvertTo-Json)
  EOT
  ]
}
```

#### Problem 2: Worker Registration Sequence
**Challenge**: Extension fails if VM isn't registered first

**Solution**: Three-step process with proper dependencies
1. Create `azurerm_automation_hybrid_runbook_worker` (registers VM with UUID)
2. Wait for registration to complete
3. Install `azurerm_virtual_machine_extension` with hybrid worker agent

#### Problem 3: Runbook Already Published Error
**Challenge**: Terraform-created runbooks are auto-published, causing republish errors

**Solution**: Check state before publishing
```powershell
if ($runbook.state -ne "Published") {
  az automation runbook publish ...
} else {
  Write-Host "Runbook is already published"
}
```

---

## 🎮 Usage Examples

### Automatic Testing (Default)
When you run `terraform apply`, the runbook automatically executes and shows:
```
========== RUNBOOK OUTPUT ==========
Connecting to Azure using Managed Identity...
Successfully connected to Azure!
Subscription: Petar Developer Subscription (16cbe606-...)
Tenant: b3480fa6-...

--- Listing all VMs in the subscription ---
Found 2 VM(s) in the subscription:

VM Name: hwlab-vm
  Resource Group: RG-HYBRID-WORKER-LAB
  Location: eastus
  VM Size: Standard_B2s
  OS Type: Windows
  Provisioning State: Succeeded

--- Getting details about the Hybrid Worker VM ---
VM Name: hwlab-vm
Power State: VM running
VM Agent Status: Ready

Installed Extensions:
  - HybridWorkerExtension (Type: Microsoft.Azure.Automation.HybridWorker...)
  - InstallPowerShellModules (Type: Microsoft.Compute.CustomScriptExtension)

--- Runbook execution completed successfully ---
========== END OUTPUT ==========
```

### Manual Runbook Execution

**Option 1: PowerShell Script**
```powershell
.\run-test-runbook.ps1
```

**Option 2: Azure CLI**
```powershell
# Start the runbook
$job = az automation runbook start `
  --automation-account-name hwlab-automation `
  --resource-group rg-hybrid-worker-lab `
  --name Test-HybridWorker-ManagedIdentity `
  --run-on hwlab-worker-group | ConvertFrom-Json

# Get job status
az automation job show `
  --automation-account-name hwlab-automation `
  --resource-group rg-hybrid-worker-lab `
  --name $job.name
```

**Option 3: Azure Portal**
1. Open the `runbook_link` from Terraform outputs
2. Click "Start"
3. Select "Run on: Hybrid Worker"
4. Choose "hwlab-worker-group"
5. Click "OK"

### Disable Automatic Testing
Edit `variables.tf`:
```hcl
variable "run_test_runbook" {
  default = false  # Changed from true
}
```

---

## ⚙️ Configuration Options

### Variable Customization

Open `variables.tf` to modify:

```hcl
variable "location" {
  default = "eastus"  # Change to your preferred region
}

variable "prefix" {
  default = "hwlab"  # Change resource name prefix
}

variable "vm_size" {
  default = "Standard_B2s"  # Upgrade for more power
  # Options: Standard_B1s, Standard_B2ms, Standard_D2s_v3, etc.
}

variable "admin_username" {
  default = "azureadmin"  # Change VM admin username
}

variable "run_test_runbook" {
  default = true  # Set to false to skip automatic testing
}
```

### Tag Customization
Edit the `tags` variable in `variables.tf`:
```hcl
variable "tags" {
  default = {
    Environment = "Production"  # Lab, Dev, Prod, etc.
    Purpose     = "Automation"  # Your use case
    Owner       = "YourName"    # Add owner tag
    CostCenter  = "IT-Ops"      # Add cost center
  }
}
```

---

## 📊 Understanding Terraform Outputs

After deployment, Terraform provides these outputs:

| Output | Description | Example Use |
|--------|-------------|-------------|
| `automation_account_name` | Automation Account name | For Azure CLI commands |
| `automation_account_id` | Full resource ID | For ARM templates |
| `automation_hybrid_service_url` | Worker registration URL | Troubleshooting hybrid worker |
| `automation_principal_id` | Managed identity GUID | Assigning additional roles |
| `vm_name` | Virtual machine name | RDP connection |
| `vm_public_ip` | VM's public IP | RDP: `mstsc /v:<ip>` |
| `vm_principal_id` | VM managed identity | Additional role assignments |
| `runbook_name` | Test runbook name | Manual execution |
| `runbook_link` | Direct Azure Portal link | Quick access to runbook |
| `azure_portal_link` | Resource group link | View all resources |
| `vm_admin_username` | VM login username | RDP credentials |
| `vm_admin_password` | VM password (sensitive) | Get with `terraform output vm_admin_password` |

---

## 🔍 Troubleshooting Guide

### Common Issues & Solutions

#### ❌ Issue: "The URL doesn't follow the Hybrid worker registration URL format"
**Cause**: Incorrect AutomationHybridServiceUrl format  
**Solution**: ✅ Already handled! The external data source fetches the correct GUID-based URL automatically.

#### ❌ Issue: "Specified machineId is not associated with automation account"
**Cause**: Extension installed before VM registration  
**Solution**: ✅ Already handled! The configuration registers the VM before installing the extension.

#### ❌ Issue: Extension installation takes 3+ minutes
**Status**: ⚠️ This is normal behavior  
**Explanation**: The Hybrid Worker Extension performs several tasks:
- Downloads agent binaries
- Configures hybrid worker service
- Registers with Automation Account
- Validates connectivity

#### ❌ Issue: Runbook fails with "Connect-AzAccount: No certificate was found"
**Cause**: Managed identity not ready or role not assigned  
**Solution**: 
1. Wait 1-2 minutes for identity propagation
2. Verify role assignment: `az role assignment list --assignee <principal_id>`
3. Re-run the runbook

#### ❌ Issue: "Az.Accounts module not found" in runbook
**Cause**: Module import still in progress  
**Solution**: Check module status:
```powershell
az automation module show `
  --automation-account-name hwlab-automation `
  --resource-group rg-hybrid-worker-lab `
  --name Az.Accounts
```
Wait until `provisioningState` is `Succeeded`

#### ❌ Issue: Terraform apply fails with "already exists"
**Cause**: Previous partial deployment  
**Solution**:
```powershell
# Import existing resources or destroy
terraform destroy -auto-approve
terraform apply -auto-approve
```

---

## 🧹 Cleanup

### Remove All Resources
```powershell
# Destroy everything (takes ~2-3 minutes)
terraform destroy -auto-approve
```

### Destroy Sequence
Terraform removes resources in this order:
1. null_resources (runbook execution)
2. Role assignments
3. Runbook
4. Automation modules
5. VM extensions
6. Hybrid worker registration
7. Hybrid worker group
8. Automation Account
9. Virtual machine
10. Network interface
11. Network security group
12. Public IP
13. Subnet
14. Virtual network
15. Resource group

**Cost Note**: All resources are destroyed, no ongoing charges after cleanup.

---

## 💰 Cost Estimation

Approximate monthly costs (US East, pay-as-you-go):

| Resource | Cost | Notes |
|----------|------|-------|
| Standard_B2s VM | ~$30/month | 2 vCPU, 4 GB RAM |
| Automation Account (Basic) | $0 + job runtime | First 500 minutes free/month |
| Public IP (Dynamic) | ~$3/month | Only when VM is running |
| Storage (OS Disk 127GB) | ~$5/month | Standard HDD |
| Network (VNet, NSG) | Free | No egress charges in this lab |
| **Total** | **~$38/month** | If VM runs 24/7 |

**Cost Savings**:
- Deallocate VM when not needed: `az vm deallocate ...` (saves VM compute cost)
- Use smaller VM size for testing: `Standard_B1s` (~$8/month)

---

## 📚 What You Can Learn

This lab demonstrates:

1. **Infrastructure as Code** - Complete environment defined in Terraform
2. **Managed Identities** - Passwordless authentication to Azure
3. **Hybrid Workers** - Run automation outside Azure (VM, on-prem, other clouds)
4. **Azure Automation** - Runbook creation and execution
5. **PowerShell Automation** - Azure management with Az modules
6. **RBAC** - Role-based access control
7. **External Data Sources** - Integrating REST APIs with Terraform
8. **null_resource** - Terraform provisioners for complex operations
9. **Dependency Management** - Proper resource ordering
10. **Automated Testing** - Validation as part of deployment

---

## 🎓 Next Steps

### Extend This Lab

1. **Add More Runbooks**
   - Create runbooks for VM management, backup, monitoring
   - Schedule runbooks to run automatically

2. **Connect On-Premises Systems**
   - Install Hybrid Worker on on-premises servers
   - Manage on-prem resources from Azure Automation

3. **Integrate with Azure Monitor**
   - Send runbook output to Log Analytics
   - Create alerts based on runbook results

4. **Add More Azure Services**
   - Azure Key Vault for secrets management
   - Azure Storage for runbook artifacts
   - Azure Monitor for logging

5. **Multi-Environment Setup**
   - Use Terraform workspaces for dev/test/prod
   - Implement remote state with Azure Storage

---

## 📖 Reference Documentation

- [Azure Automation Hybrid Worker](https://learn.microsoft.com/azure/automation/automation-hybrid-runbook-worker)
- [Azure Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Automation REST API](https://learn.microsoft.com/rest/api/automation/)
- [PowerShell Az Modules](https://learn.microsoft.com/powershell/azure/)

---

## 📄 License & Disclaimer

This is a **lab/demo configuration** provided as-is for learning purposes.

**⚠️ Important**:
- Review and test thoroughly before using in production
- Follow your organization's security and compliance requirements
- Monitor costs in your Azure subscription
- This configuration uses Contributor role for simplicity - use least-privilege in production

---

## 🤝 Support

If you encounter issues:
1. Check the **Troubleshooting Guide** above
2. Review Terraform output for error messages
3. Check Azure Portal for resource status
4. Verify Azure CLI authentication: `az account show`

---

## 🎉 Success Criteria

You'll know everything is working when:
- ✅ All 22 resources deployed successfully
- ✅ VM appears as "Ready" in Hybrid Worker Group
- ✅ Runbook executes and shows VM list
- ✅ Managed identity authentication works
- ✅ Extensions show as "Succeeded" in Azure Portal

---

**Package Version**: 1.0  
**Last Updated**: November 2025  
**Terraform Version**: >= 1.0  
**Provider Versions**: azurerm ~> 3.0, azapi ~> 1.0
