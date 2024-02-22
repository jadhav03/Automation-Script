output "public_ip_address" {
  description = "The public IP address of the deployed IIS server."
  value       = azurerm_public_ip.iis_server.ip_address
}
