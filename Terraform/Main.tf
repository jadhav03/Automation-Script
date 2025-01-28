# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Or your preferred version
    }
  }
}

provider "azurerm" {
  features {} # Required for some Azure resources
}

# Define variables (adjust as needed)
variable "resource_group_name" {
  type = string
  description = "Name of the resource group"
}

variable "location" {
  type = string
  description = "Azure region for resources"
  default = "West US 2"
}

variable "environment" {
  type = string
  description = "Environment (prd or uat)"
  validation {
    condition     = contains(["prd", "uat"], var.environment)
    error_message = "Environment must be 'prd' or 'uat'."
  }
}

variable "vm_count" {
  type    = number
  description = "Number of VMs to deploy"
  default = 20
}

variable "vnet_count" {
  type    = number
  description = "Number of Virtual Networks to create"
  default = 5
}


variable "vm_size" {
  type    = string
  description = "Size of the virtual machines"
  default = "Standard_S1_T2"
}

variable "admin_username" {
  type    = string
  description = "Admin username for the VMs"
}

variable "admin_password" {
  type    = string
  description = "Admin password for the VMs"
  sensitive = true
}

variable "backup_vault_name" {
  type    = string
  description = "Name of the Recovery Services Vault (optional)"
  default = null
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Virtual Networks
resource "azurerm_virtual_network" "vnet" {
  count                = var.vnet_count
  name                 = "vnet-${count.index}-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  address_space        = ["10.0.${count.index}.0/16"] # Unique address space for each VNet
}

# Create Subnets (one per VNet)
resource "azurerm_subnet" "subnet" {
  count                = var.vnet_count
  name                 = "subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[count.index].name
  address_prefixes     = ["10.0.${count.index}.16/24"] # Subnet within the VNet
}

# Create Recovery Services Vault if not provided
resource "azurerm_recovery_services_vault" "backup_vault" {
  count = var.backup_vault_name == null ? 1 : 0
  name                = "recovery-vault-${var.resource_group_name}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

locals {
  backup_vault_name = var.backup_vault_name != null ? var.backup_vault_name : azurerm_recovery_services_vault.backup_vault[0].name
}


# Create Network Interfaces and VMs (distributed across subnets)
resource "azurerm_network_interface" "nic" {
  count                = var.vm_count
  name                 = "nic-${count.index}-${var.environment}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[count.index % var.vnet_count].id # Distribute across subnets
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "vm" {
  count                  = var.vm_count
  name                   = "vm-${count.index}-${var.environment}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  vm_size                = var.vm_size
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-Server-Ubuntu"
    sku       = "LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk-${count.index}-${var.environment}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS" # Or Premium_LRS
  }

  os_profile {
    computer_name  = "vm-${count.index}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}


# Backup configuration (only for prd and uat)
resource "azurerm_backup_protected_vm" "vm_backup" {
  count = var.environment == "prd" || var.environment == "uat" ? var.vm_count : 0

  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = local.backup_vault_name
  source_vm_id        = azurerm_virtual_machine.vm[count.index].id
  policy_id           = data.azurerm_backup_policy.backup_policy.id # Link to a backup policy (see below)
}

# Backup Policy (define a policy separately)
data "azurerm_backup_policy" "backup_policy" {
  name                = "daily-backup-policy" # Replace with your policy name
  resource_group_name = "backup-rg" # Replace with the resource group where the policy is defined
}


# Example Alert - CPU Percentage High (customize as needed)
resource "azurerm_monitor_metric_alert" "cpu_high_alert" {
  name                = "CPUHighAlert-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_virtual_machine.vm[0].id] # Apply to all VMs if needed; you can iterate here as well
  description         = "Alert when CPU percentage is high"

  criteria {
    metric_name = "Percentage CPU"
    metric_namespace = "Microsoft.Compute/virtualMachines"
    operator        = "GreaterThan"
    threshold       = 80
    aggregation     = "Average"
    frequency       = "PT5M"
    window_size     = "PT15M"
  }

  action {
    action_group_id = data.azurerm_monitor_action_group.action_group.id
  }
}

# Action Group for Alerts (define an action group separately)
data "azurerm_monitor_action_group" "action_group" {
  name                = "email-and-sms-action-group" # Replace with your action group name
  resource_group_name = "monitoring-rg" # Replace with the resource group where the action group is defined
}


output "vm_private_ips" {
  value = [for vm in azurerm_virtual_machine.vm : vm.private_ip_address]
}

