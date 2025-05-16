variable "resource_group_name" {
  description = "The name of the resource group in which to create the network resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the network resources will be created."
  type        = string
}

variable "vnet_name" {
  description = "The name of the Virtual Network."
  type        = string
  default     = "vnet-main"
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network (e.g., [\"10.0.0.0/16\"])."
  type        = list(string)
}

variable "subnets" {
  description = <<EOD
A map of subnet configurations.
Each key is a logical name for the subnet (e.g., "web", "app", "db") and the value is an object with:
  - name: The actual Azure subnet name (can be different from the key, or derived). If null, uses "snet-<vnet_name>-<key>".
  - address_prefixes: A list of CIDR blocks for the subnet (e.g., ["10.0.1.0/24"]).
  - role: An optional descriptive role for the subnet (e.g., "public-facing", "internal-app", "database"). This is for classification and does not directly alter Azure resource properties but can be used by other modules.
  - service_endpoints: (Optional) A list of service endpoints to enable (e.g., ["Microsoft.Sql"]).
  - delegations: (Optional) A list of service delegations. Example:
    delegations = [{
      name = "ACIDelegation"
      service_delegation = {
        name    = "Microsoft.ContainerInstance/containerGroups"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
      }
    }]
EOD
  type = map(object({
    name              = optional(string)
    address_prefixes  = list(string)
    role              = optional(string, "internal") # Default role to "internal"
    service_endpoints = optional(list(string), [])
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    })), [])
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}
