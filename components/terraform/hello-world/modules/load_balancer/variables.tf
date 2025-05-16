variable "resource_group_name" {
  description = "The name of the resource group in which to create the Load Balancer."
  type        = string
}

variable "location" {
  description = "The Azure region where the Load Balancer will be created."
  type        = string
}

variable "load_balancer_name" {
  description = "The name of the Azure Load Balancer."
  type        = string
}

variable "public_ip_name" {
  description = "The name for the Public IP address associated with the Load Balancer."
  type        = string
}

variable "public_ip_sku" {
  description = "SKU for the Public IP. Standard is recommended. Options: Basic, Standard."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "Invalid Public IP SKU. Must be 'Basic' or 'Standard'."
  }
}

variable "public_ip_allocation_method" {
  description = "Allocation method for the Public IP. Static is recommended for LBs. Options: Static, Dynamic."
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "Invalid Public IP allocation method. Must be 'Static' or 'Dynamic'."
  }
}

variable "lb_sku" {
  description = "SKU for the Load Balancer. Standard is recommended. Options: Basic, Standard, Gateway."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Gateway"], var.lb_sku)
    error_message = "Invalid Load Balancer SKU. Must be 'Basic', 'Standard', or 'Gateway'."
  }
}

variable "frontend_ip_configuration_name" {
  description = "Name for the frontend IP configuration of the Load Balancer."
  type        = string
  default     = "PublicIPAddress"
}

variable "backend_pool_name" {
  description = "Name for the backend address pool."
  type        = string
  default     = "BackendPool"
}

variable "health_probe_name" {
  description = "Name for the health probe."
  type        = string
  default     = "HTTPHealthProbe"
}

variable "health_probe_protocol" {
  description = "Protocol for the health probe. Options: Http, Https, Tcp."
  type        = string
  default     = "Tcp" # Using TCP as it's simpler for a basic Hello World and doesn't require an HTTP endpoint. Change to Http if your app serves a health check page.
  validation {
    condition     = contains(["Http", "Https", "Tcp"], var.health_probe_protocol)
    error_message = "Invalid health probe protocol. Must be 'Http', 'Https', or 'Tcp'."
  }
}

variable "health_probe_port" {
  description = "Port for the health probe."
  type        = number
}

variable "health_probe_request_path" {
  description = "Request path for HTTP/S health probes. Required if protocol is Http or Https."
  type        = string
  default     = null # e.g., "/health" or "/"
  validation {
    condition     = !((var.health_probe_protocol == "Http" || var.health_probe_protocol == "Https") && var.health_probe_request_path == null)
    error_message = "health_probe_request_path must be set if health_probe_protocol is Http or Https."
  }
}

variable "health_probe_interval_in_seconds" {
  description = "Interval in seconds for the health probe."
  type        = number
  default     = 5
}

variable "health_probe_number_of_probes" {
  description = "Number of consecutive probes to determine health status."
  type        = number
  default     = 2
}

variable "lb_rule_name" {
  description = "Name for the load balancing rule."
  type        = string
  default     = "HTTPRule"
}

variable "lb_rule_protocol" {
  description = "Protocol for the load balancing rule. Options: Tcp, Udp, All."
  type        = string
  default     = "Tcp"
  validation {
    condition     = contains(["Tcp", "Udp", "All"], var.lb_rule_protocol)
    error_message = "Invalid load balancing rule protocol. Must be 'Tcp', 'Udp', or 'All'."
  }
}

variable "lb_frontend_port" {
  description = "Frontend port for the load balancing rule (e.g., 80 for HTTP)."
  type        = number
}

variable "lb_backend_port" {
  description = "Backend port for the load balancing rule (e.g., 80 for HTTP on VMs)."
  type        = number
}

variable "enable_tcp_reset" {
  description = "Enable TCP Reset for the load balancing rule. Recommended for Standard SKU."
  type        = bool
  default     = true
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes for the load balancing rule."
  type        = number
  default     = 4 # Default is 4 minutes, max 30 for Standard LB.
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "public_ip_zones" {
  description = "A list of Availability Zones for the Public IP. For Standard SKU, if null, it may default to zone-redundant. Set explicitly e.g. [\"1\",\"2\",\"3\"] or [] for no-zone, or [\"1\"] for a specific zone."
  type        = list(string)
  default     = null # Explicitly null, behavior depends on Azure. For Standard SKU, often defaults to zone-redundant.
}
