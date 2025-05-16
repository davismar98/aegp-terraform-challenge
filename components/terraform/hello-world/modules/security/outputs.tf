output "network_security_group_ids" {
  description = "A map of logical NSG names to their Azure resource IDs."
  value = {
    for k, nsg in azurerm_network_security_group.main : k => nsg.id
  }
}

output "network_security_groups" {
  description = "Details of the created Network Security Groups."
  value       = azurerm_network_security_group.main
}
