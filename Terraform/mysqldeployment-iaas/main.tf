# Specify the version of the AzureRM provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.0.0"
    }
  }
}

# Include the variables, providers, and outputs
variable "subscription_id" {}
variable "client_id"       {}
variable "client_secret"   {}
variable "tenant_id"       {}

provider "azurerm" {
  features = {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  version = ">=2.0.0"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Public IP Address for VM
resource "azurerm_public_ip" "mysql_vm" {
  name                = "mysql-vm-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Security Group for VM
resource "azurerm_network_security_group" "mysql_nsg" {
  name                = "mysql-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Network Interface for VM
resource "azurerm_network_interface" "mysql_nic" {
  name                = "mysql-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  network_security_group_ids = [azurerm_network_security_group.mysql_nsg.id]
}

# Virtual Machine
resource "azurerm_windows_virtual_machine" "mysql_vm" {
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_DS1_v2"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.mysql_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name = "mysql-vm"

  provision_vm_agent = true

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.boot_diags.primary_blob_endpoint
  }
}

# MySQL Installation Script (Custom Script Extension)
resource "azurerm_virtual_machine_extension" "mysql_installation" {
  name                 = "customscript"
  virtual_machine_id   = azurerm_windows_virtual_machine.mysql_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "script": "./scripts/install_mysql.ps1"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ./scripts/install_mysql.ps1"
    }
PROTECTED_SETTINGS
}

# Firewall Rule for MySQL on VM
resource "azurerm_network_security_rule" "mysql_firewall_rule" {
  name                        = "mysql-firewall-rule"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3306"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.mysql_nsg.name
}

# MySQL Database
resource "azurerm_mysql_database" "mysql_database" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_server.mysql_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
