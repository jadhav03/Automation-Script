variable "resource_group_name" {
  description = "The name of the resource group in which to deploy the IIS server."
  type        = string
}

variable "location" {
  description = "The Azure region in which to deploy the IIS server."
  type        = string
}

variable "vm_name" {
  description = "The name of the Virtual Machine running IIS."
  type        = string
}

variable "admin_username" {
  description = "The admin username for the Virtual Machine."
  type        = string
}

variable "admin_password" {
  description = "The admin password for the Virtual Machine."
  type        = string
}
