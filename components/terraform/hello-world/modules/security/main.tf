# Create Network Security Groups
resource "azurerm_network_security_group" "main" {
  for_each = var.network_security_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = security_rule.value.description
    }
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  # Iterate over the subnet_nsg_associations map
  # For each entry, 'each.key' is the logical subnet name (e.g., "frontend")
  # and 'each.value' is the logical NSG name (e.g., "web_nsg")
  for_each = var.subnet_nsg_associations

  subnet_id                 = var.subnets_data[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.value].id
}
