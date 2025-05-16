# Create Public IP Address for the Load Balancer frontend
resource "azurerm_public_ip" "main" {
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  tags                = var.tags

  # For Standard SKU, zones can be specified. If null, Azure's default behavior for the region/resource applies (often zone-redundant).
  zones = var.public_ip_sku == "Standard" ? var.public_ip_zones : null
}

# Create the Load Balancer
resource "azurerm_lb" "main" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.lb_sku
  tags                = var.tags

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

# Create Backend Address Pool
# VMs/VMSS NICs will be associated with this pool in the compute module.
resource "azurerm_lb_backend_address_pool" "main" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.main.id
}

# Create Health Probe
resource "azurerm_lb_probe" "main" {
  name                = var.health_probe_name
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = var.health_probe_protocol
  port                = var.health_probe_port
  request_path        = var.health_probe_protocol == "Http" || var.health_probe_protocol == "Https" ? var.health_probe_request_path : null
  interval_in_seconds = var.health_probe_interval_in_seconds
  number_of_probes    = var.health_probe_number_of_probes
}

# Create Load Balancing Rule
resource "azurerm_lb_rule" "main" {
  name                           = var.lb_rule_name
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = var.lb_rule_protocol
  frontend_port                  = var.lb_frontend_port
  backend_port                   = var.lb_backend_port
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.main.id
  enable_tcp_reset               = var.lb_sku == "Standard" ? var.enable_tcp_reset : null # TCP Reset only applicable for Standard SKU
  idle_timeout_in_minutes        = var.idle_timeout_in_minutes
}
