# Outputs for Azure Hybrid Worker Lab

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_admin_username" {
  description = "Admin username for the VM"
  value       = var.admin_username
}

output "vm_admin_password" {
  description = "Admin password for the VM (sensitive)"
  value       = random_password.vm_password.result
  sensitive   = true
}

output "vm_principal_id" {
  description = "Principal ID of the VM's managed identity"
  value       = azurerm_windows_virtual_machine.vm.identity[0].principal_id
}

output "automation_account_name" {
  description = "Name of the Automation Account"
  value       = azurerm_automation_account.automation.name
}

output "automation_account_id" {
  description = "ID of the Automation Account"
  value       = azurerm_automation_account.automation.id
}

output "automation_hybrid_service_url" {
  description = "Automation Hybrid Service URL used for Hybrid Worker registration"
  value       = data.external.automation_hybrid_url.result.url
}

output "automation_principal_id" {
  description = "Principal ID of the Automation Account's managed identity"
  value       = azurerm_automation_account.automation.identity[0].principal_id
}

output "hybrid_worker_group_name" {
  description = "Name of the Hybrid Runbook Worker Group"
  value       = azurerm_automation_hybrid_runbook_worker_group.worker_group.name
}

output "runbook_name" {
  description = "Name of the test runbook"
  value       = azurerm_automation_runbook.test_hybrid_worker.name
}

output "azure_portal_link" {
  description = "Link to view resources in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_resource_group.rg.id}"
}

output "runbook_link" {
  description = "Link to the runbook in Azure Portal"
  value       = "https://portal.azure.com/#@/resource${azurerm_automation_runbook.test_hybrid_worker.id}"
}
