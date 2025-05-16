output "load_balancer_id" {
  description = "The ID of the Azure Load Balancer."
  value       = azurerm_lb.main.id
}

output "public_ip_address" {
  description = "The public IP address of the Load Balancer."
  value       = azurerm_public_ip.main.ip_address
}

output "public_ip_id" {
  description = "The ID of the public IP address."
  value       = azurerm_public_ip.main.id
}

output "frontend_ip_configuration_id" {
  description = "The ID of the frontend IP configuration."
  value       = azurerm_lb.main.frontend_ip_configuration[0].id # Assumes one frontend IP config
}

output "backend_address_pool_id" {
  description = "The ID of the backend address pool. This is used to associate VM NICs."
  value       = azurerm_lb_backend_address_pool.main.id
}

output "health_probe_id" {
  description = "The ID of the health probe."
  value       = azurerm_lb_probe.main.id
}
