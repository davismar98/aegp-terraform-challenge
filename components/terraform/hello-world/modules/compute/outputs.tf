output "vmss_id" {
  description = "The ID of the Virtual Machine Scale Set."
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_name" {
  description = "The name of the Virtual Machine Scale Set."
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}
