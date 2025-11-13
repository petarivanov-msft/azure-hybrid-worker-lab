# Main Terraform configuration for Azure Hybrid Worker Lab

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"

  tags = var.tags
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nsg_nic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Random password for VM
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = random_password.vm_password.result

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Automation Account with system-assigned managed identity
resource "azurerm_automation_account" "automation" {
  name                = "${var.prefix}-automation"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Fetch AutomationHybridServiceUrl using external data source
data "external" "automation_hybrid_url" {
  program = ["pwsh", "-Command", <<-EOT
    try {
      $result = az rest --method get --url "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Automation/automationAccounts/${azurerm_automation_account.automation.name}?api-version=2023-11-01" 2>$null | ConvertFrom-Json
      if ($result.properties.automationHybridServiceUrl) {
        $url = $result.properties.automationHybridServiceUrl
        $output = @{url = $url} | ConvertTo-Json -Compress
        Write-Output $output
      } else {
        Write-Output '{"url":"placeholder"}'
      }
    } catch {
      # During destroy, the resource might not exist
      Write-Output '{"url":"placeholder"}'
    }
  EOT
  ]

  depends_on = [
    azurerm_automation_account.automation
  ]
}

# Generate a unique ID for the hybrid worker
resource "random_uuid" "worker_id" {}

# Hybrid Runbook Worker Group
resource "azurerm_automation_hybrid_runbook_worker_group" "worker_group" {
  name                    = "${var.prefix}-worker-group"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
}

# Register VM as Hybrid Worker in the group
resource "azurerm_automation_hybrid_runbook_worker" "worker" {
  automation_account_name = azurerm_automation_account.automation.name
  resource_group_name     = azurerm_resource_group.rg.name
  worker_group_name       = azurerm_automation_hybrid_runbook_worker_group.worker_group.name
  vm_resource_id          = azurerm_windows_virtual_machine.vm.id
  worker_id               = random_uuid.worker_id.result
}

# VM Extension to install Hybrid Worker
resource "azurerm_virtual_machine_extension" "hybrid_worker" {
  name                       = "HybridWorkerExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Automation.HybridWorker"
  type                       = "HybridWorkerForWindows"
  type_handler_version       = "1.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    AutomationAccountURL = data.external.automation_hybrid_url.result.url
  })

  protected_settings = jsonencode({
    HybridWorkerGroupName = azurerm_automation_hybrid_runbook_worker_group.worker_group.name
  })

  depends_on = [
    azurerm_automation_hybrid_runbook_worker.worker,
    data.external.automation_hybrid_url
  ]

  tags = var.tags
}

# Get current subscription data
data "azurerm_subscription" "current" {}

# Assign Contributor role to Automation Account managed identity
resource "azurerm_role_assignment" "automation_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.automation.identity[0].principal_id

  depends_on = [
    azurerm_automation_account.automation
  ]
}

# Assign Contributor role to VM managed identity
resource "azurerm_role_assignment" "vm_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_windows_virtual_machine.vm.identity[0].principal_id

  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
}

# Custom Script Extension to install PowerShell modules on the VM
resource "azurerm_virtual_machine_extension" "powershell_modules" {
  name                       = "InstallPowerShellModules"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name Az.Accounts -Force -AllowClobber; Install-Module -Name Az.Compute -Force -AllowClobber; Write-Host 'PowerShell modules installed successfully'\""
  })

  depends_on = [
    azurerm_virtual_machine_extension.hybrid_worker
  ]

  tags = var.tags
}

# Import Az.Accounts module into Automation Account
resource "azurerm_automation_module" "az_accounts" {
  name                    = "Az.Accounts"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts"
  }
}

# Import Az.Compute module into Automation Account
resource "azurerm_automation_module" "az_compute" {
  name                    = "Az.Compute"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Compute"
  }

  depends_on = [
    azurerm_automation_module.az_accounts
  ]
}

# Create a runbook that connects with managed identity and lists VMs
resource "azurerm_automation_runbook" "test_hybrid_worker" {
  name                    = "Test-HybridWorker-ManagedIdentity"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.automation.name
  log_verbose             = true
  log_progress            = true
  description             = "Test runbook that uses managed identity to connect to Azure and list VMs"
  runbook_type            = "PowerShell"

  content = <<-EOT
    <#
    .SYNOPSIS
        Test runbook for Hybrid Worker using Managed Identity
    
    .DESCRIPTION
        This runbook demonstrates how to:
        1. Connect to Azure using the system-assigned managed identity
        2. List all VMs in the subscription
        3. Get details about the current VM
    #>
    
    # Connect to Azure using the system-assigned managed identity
    Write-Output "Connecting to Azure using Managed Identity..."
    try {
        Connect-AzAccount -Identity -ErrorAction Stop
        Write-Output "Successfully connected to Azure!"
        
        # Get the current subscription context
        $context = Get-AzContext
        Write-Output "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
        Write-Output "Tenant: $($context.Tenant.Id)"
        
    } catch {
        Write-Error "Failed to connect to Azure: $_"
        throw
    }
    
    # List all VMs in the subscription
    Write-Output "`n--- Listing all VMs in the subscription ---"
    try {
        $vms = Get-AzVM
        Write-Output "Found $($vms.Count) VM(s) in the subscription:"
        
        foreach ($vm in $vms) {
            Write-Output "`nVM Name: $($vm.Name)"
            Write-Output "  Resource Group: $($vm.ResourceGroupName)"
            Write-Output "  Location: $($vm.Location)"
            Write-Output "  VM Size: $($vm.HardwareProfile.VmSize)"
            Write-Output "  OS Type: $($vm.StorageProfile.OsDisk.OsType)"
            Write-Output "  Provisioning State: $($vm.ProvisioningState)"
        }
    } catch {
        Write-Error "Failed to list VMs: $_"
    }
    
    # Get details about the current VM (hwlab-vm)
    Write-Output "`n--- Getting details about the Hybrid Worker VM ---"
    try {
        $currentVM = Get-AzVM -ResourceGroupName "rg-hybrid-worker-lab" -Name "hwlab-vm" -Status
        Write-Output "VM Name: $($currentVM.Name)"
        Write-Output "Power State: $($currentVM.PowerState)"
        Write-Output "VM Agent Status: $($currentVM.VMAgent.Statuses[0].DisplayStatus)"
        
        # Display VM extensions
        Write-Output "`nInstalled Extensions:"
        foreach ($ext in $currentVM.Extensions) {
            Write-Output "  - $($ext.Name) (Type: $($ext.Type))"
        }
        
    } catch {
        Write-Error "Failed to get current VM details: $_"
    }
    
    Write-Output "`n--- Runbook execution completed successfully ---"
  EOT

  depends_on = [
    azurerm_automation_module.az_compute,
    azurerm_automation_hybrid_runbook_worker.worker
  ]

  tags = var.tags
}

# Publish the runbook (make it available for execution)
resource "null_resource" "publish_runbook" {
  provisioner "local-exec" {
    command = <<-EOT
      # Check if runbook is already published
      $runbook = az automation runbook show `
        --automation-account-name ${azurerm_automation_account.automation.name} `
        --resource-group ${azurerm_resource_group.rg.name} `
        --name ${azurerm_automation_runbook.test_hybrid_worker.name} | ConvertFrom-Json
      
      if ($runbook.state -ne "Published") {
        Write-Host "Publishing runbook..." -ForegroundColor Cyan
        az automation runbook publish `
          --automation-account-name ${azurerm_automation_account.automation.name} `
          --resource-group ${azurerm_resource_group.rg.name} `
          --name ${azurerm_automation_runbook.test_hybrid_worker.name}
      } else {
        Write-Host "Runbook is already published" -ForegroundColor Green
      }
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azurerm_automation_runbook.test_hybrid_worker
  ]

  triggers = {
    runbook_content = sha256(azurerm_automation_runbook.test_hybrid_worker.content)
  }
}

# Run the test runbook on the hybrid worker
resource "null_resource" "run_test_runbook" {
  count = var.run_test_runbook ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Starting test runbook on hybrid worker..." -ForegroundColor Cyan
      
      # Start the runbook job
      $job = az automation runbook start `
        --automation-account-name ${azurerm_automation_account.automation.name} `
        --resource-group ${azurerm_resource_group.rg.name} `
        --name ${azurerm_automation_runbook.test_hybrid_worker.name} `
        --run-on ${azurerm_automation_hybrid_runbook_worker_group.worker_group.name} | ConvertFrom-Json
      
      $jobName = $job.name
      Write-Host "Job started: $jobName" -ForegroundColor Green
      
      # Wait for job completion (max 2 minutes)
      $maxWait = 120
      $waited = 0
      $status = "Running"
      
      while ($status -notin @("Completed", "Failed", "Stopped", "Suspended") -and $waited -lt $maxWait) {
        Start-Sleep -Seconds 5
        $waited += 5
        
        $jobStatus = az automation job show `
          --automation-account-name ${azurerm_automation_account.automation.name} `
          --resource-group ${azurerm_resource_group.rg.name} `
          --name $jobName | ConvertFrom-Json
        
        $status = $jobStatus.status
        Write-Host "." -NoNewline
      }
      
      Write-Host ""
      Write-Host "Job Status: $status" -ForegroundColor $(if ($status -eq "Completed") { "Green" } else { "Red" })
      
      if ($status -eq "Completed") {
        Write-Host "`n========== RUNBOOK OUTPUT ==========" -ForegroundColor Green
        
        $subscriptionId = az account show --query id -o tsv
        $outputUrl = "/subscriptions/$subscriptionId/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Automation/automationAccounts/${azurerm_automation_account.automation.name}/jobs/$jobName/output?api-version=2023-11-01"
        
        $output = az rest --method get --url $outputUrl
        Write-Host $output
        
        Write-Host "`n========== END OUTPUT ==========" -ForegroundColor Green
      } else {
        Write-Host "Job did not complete successfully. Status: $status" -ForegroundColor Red
      }
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    null_resource.publish_runbook,
    azurerm_virtual_machine_extension.hybrid_worker,
    azurerm_virtual_machine_extension.powershell_modules
  ]

  triggers = {
    # Run this every time to test the setup
    always_run = timestamp()
  }
}
