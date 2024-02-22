output "mysql_vm_public_ip" {
  description = "The public IP address of the deployed MySQL VM."
  value       = azurerm_public_ip.mysql_vm.ip_address
}
