# Azure Hybrid Worker Lab - Terraform Configuration

This Terraform configuration creates a complete Azure lab environment with:
1. ✅ A Windows Virtual Machine (VM) with system-managed identity
2. ✅ An Azure Automation Account with system-managed identity
3. ✅ Onboards the VM as a Hybrid Runbook Worker
4. ✅ Enables system-managed identity on both VM and Automation Account
5. ✅ Assigns Contributor role to both managed identities at subscription level

## Key Features

- **Proper URL Handling**: Uses Azure REST API to fetch the correct `AutomationHybridServiceUrl`
- **Worker Registration**: Registers the VM in the Hybrid Worker Group before installing the extension
- **Identity & RBAC**: Both the VM and Automation Account have system-assigned managed identities with Contributor role
- **Complete Infrastructure**: Includes VNet, Subnet, NSG, Public IP, and all necessary network components

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (>= 1.0)
- Azure CLI installed and authenticated (`az login`)
- An active Azure subscription

## Resources Created

- **Resource Group**: Container for all resources
- **Virtual Network & Subnet**: Network infrastructure
- **Network Security Group**: Allows RDP access (port 3389)
- **Public IP**: For VM remote access
- **Network Interface**: Connects VM to network
- **Windows VM**: Windows Server 2022 with system-managed identity
- **Automation Account**: With system-managed identity enabled
- **Hybrid Worker Group**: For organizing hybrid workers
- **VM Extension**: Installs and configures the Hybrid Worker agent
- **Role Assignments**: Contributor role for both managed identities

## Configuration

You can customize the deployment by modifying variables in `variables.tf` or creating a `terraform.tfvars` file:

```hcl
resource_group_name = "rg-hybrid-worker-lab"
location            = "East US"
prefix              = "hwlab"
vm_size             = "Standard_B2s"
admin_username      = "azureadmin"
```

## Deployment Steps

1. **Initialize Terraform**
   ```powershell
   terraform init
   ```

2. **Validate Configuration**
   ```powershell
   terraform validate
   ```

3. **Review Planned Changes**
   ```powershell
   terraform plan
   ```

4. **Apply Configuration**
   ```powershell
   terraform apply -auto-approve
   ```

5. **View Outputs**
   ```powershell
   terraform output
   ```

6. **Retrieve VM Password** (stored securely)
   ```powershell
   terraform output -raw vm_admin_password
   ```

## Accessing Resources

After deployment:
- Use the `azure_portal_link` output to view resources in Azure Portal
- RDP to the VM using the public IP, admin username, and password from outputs
- Access the Automation Account to create and run runbooks on the hybrid worker

## Security Notes

- The VM password is randomly generated and marked as sensitive
- RDP access is allowed from any IP (modify NSG rules for production use)
- Both VM and Automation Account have Contributor role at subscription level
- Consider using Azure Bastion instead of public IP for production environments

## Cleanup

To destroy all resources:

```powershell
terraform destroy -auto-approve
```

## Architecture

```
Azure Subscription
└── Resource Group
    ├── Virtual Network
    │   └── Subnet
    ├── Network Security Group
    ├── Public IP
    ├── Network Interface
    ├── Windows VM (with Managed Identity + Contributor Role)
    │   └── Hybrid Worker Extension
    └── Automation Account (with Managed Identity + Contributor Role)
        └── Hybrid Worker Group
```

## Troubleshooting

- If the VM extension fails, check that the VM can reach Azure Automation endpoints
- Ensure your Azure subscription has sufficient quota for the VM size
- Role assignments may take a few minutes to propagate
- Check the Azure Portal activity log for detailed error messages

## Additional Resources

- [Azure Automation Hybrid Worker Documentation](https://learn.microsoft.com/azure/automation/automation-hybrid-runbook-worker)
- [Azure Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
