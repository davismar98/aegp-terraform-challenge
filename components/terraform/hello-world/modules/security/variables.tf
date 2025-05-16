variable "resource_group_name" {
  description = "The name of the resource group in which to create the security resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the security resources will be created."
  type        = string
}

variable "network_security_groups" {
  description = "A map of Network Security Group configurations. The key is a logical name for the NSG (e.g., 'web_nsg', 'app_nsg')."
  type = map(object({
    name = string # Actual Azure name for the NSG (e.g., "nsg-web-prod")
    rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string # "Inbound" or "Outbound"
      access                     = string # "Allow" or "Deny"
      protocol                   = string # "Tcp", "Udp", "Icmp", "Esp", "Ah", or "*"
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*") # e.g., "80", "80-100", "80,443,8080-8082"
      source_address_prefix      = optional(string, "*") # e.g., CIDR, IP, "Internet", "VirtualNetwork"
      destination_address_prefix = optional(string, "*") # e.g., CIDR, IP, "VirtualNetwork"
      description                = optional(string)
    }))
  }))
  default = {}
}

variable "subnet_nsg_associations" {
  description = "A map to associate NSGs with subnets. Keys are logical subnet names (e.g., 'frontend' from network module output's 'subnets' map key). Values are the logical NSG names (keys from 'var.network_security_groups') to associate."
  type        = map(string)
  default     = {}
}

variable "subnets_data" {
  description = "The output from the network module (module.network.subnets). Expected to be a map where each value is an object containing subnet details including 'id' and 'name'."
  type = map(object({
    id               = string
    name             = string
    address_prefixes = list(string) # Included for completeness, though not directly used for NSG association by ID
    role             = string       # Included for completeness
  }))
}

variable "tags" {
  description = "A map of tags to apply to all NSGs."
  type        = map(string)
  default     = {}
}
