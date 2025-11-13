# Variables for Azure Hybrid Worker Lab

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-hybrid-worker-lab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "hwlab"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Lab"
    Purpose     = "HybridWorker"
  }
}

variable "run_test_runbook" {
  description = "Whether to automatically run the test runbook after deployment"
  type        = bool
  default     = true
}
