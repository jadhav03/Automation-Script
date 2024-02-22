variable "resource_group_name" {
  description = "The name of the resource group in which to deploy the MySQL VM."
  type        = string
}

variable "location" {
  description = "The Azure region in which to deploy the MySQL VM."
  type        = string
}

variable "vm_name" {
  description = "The name of the Virtual Machine running MySQL."
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

variable "mysql_root_password" {
  description = "The root password for MySQL."
  type        = string
}

variable "mysql_database_name" {
  description = "The name of the MySQL database to create."
  type        = string
}
