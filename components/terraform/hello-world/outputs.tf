output "resource_group_name" {
  description = "The name of the resource group where resources are deployed."
  value       = azurerm_resource_group.main.name
}

output "load_balancer_public_ip_address" {
  description = "The public IP address of the application load balancer."
  value       = module.load_balancer.public_ip_address
}

output "application_url_by_ip" {
  description = "The URL to access the deployed Hello World application using the public IP address."
  value       = "http://${module.load_balancer.public_ip_address}:${var.app_port}"
  depends_on  = [module.compute] # Ensure compute is up before showing this URL
}
