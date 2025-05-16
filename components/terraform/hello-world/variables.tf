# In components/terraform/hello-world-app/main.tf

# Example variables you would define in the component's variables.tf
variable "resource_group_name_prefix" {
  type        = string
  description = "The name of the resource group where the resources will be created."
  default     = "aegp-challenge"
}
variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
  default     = "East US"
}
variable "stage" {
  type        = string
  description = "The environment name (e.g., dev, test, prod)."
  default     = "dev"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The address space for the virtual network."
  default     = ["10.100.0.0/22"]
}
variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources."
  default = {
    "Project" = "aegp-terraform-challenge"
  }
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create for the app service."
  default     = 1
}

variable "vm_sku" {
  type        = string
  description = "The SKU for the VM instances."
  default     = "Standard_B1s"
}

variable "app_port" {
  type        = number
  description = "value of the port your Hello World app runs on"
  default     = 8080
}

variable "admin_ssh_key_public" {
  type        = string
  description = "Public SSH key for the administrator user. If not provided, password authentication will be enabled (not recommended for production)."
  sensitive   = true
}
