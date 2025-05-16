output "vnet_id" {
  description = "The ID of the Virtual Network."
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.main.address_space
}

output "vnet_location" {
  description = "The location of the Virtual Network."
  value       = azurerm_virtual_network.main.location
}

output "subnets" {
  description = "A map of the created subnets, keyed by the logical name provided in the input variable."
  value = {
    for k, s in azurerm_subnet.main : k => {
      id               = s.id
      name             = s.name
      address_prefixes = s.address_prefixes
      # Pass through the role defined in the input for other modules to consume
      role = var.subnets[k].role
    }
  }
}

output "subnet_ids" {
  description = "A map of subnet logical names to their IDs."
  value = {
    for k, s in azurerm_subnet.main : k => s.id
  }
}

output "subnet_names" {
  description = "A map of subnet logical names to their actual Azure names."
  value = {
    for k, s in azurerm_subnet.main : k => s.name
  }
}
