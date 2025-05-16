variable "resource_group_name" {
  description = "The name of the resource group in which to create the VM Scale Set."
  type        = string
}

variable "location" {
  description = "The Azure region where the VM Scale Set will be created."
  type        = string
}

variable "vmss_name" {
  description = "The name of the Virtual Machine Scale Set."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the VMSS instances will be deployed."
  type        = string
}

variable "lb_backend_pool_id" {
  description = "The ID of the Load Balancer's backend address pool to associate with the VMSS."
  type        = string
}

variable "instance_count" {
  description = "The initial number of VM instances in the scale set."
  type        = number
  default     = 2
}

variable "vm_sku" {
  description = "The SKU for the VM instances in the scale set (e.g., Standard_B1s, Standard_F2s_v2)."
  type        = string
  default     = "Standard_B1s" # Cost-effective for testing
}

variable "admin_username" {
  description = "Administrator username for the VM instances."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_key_public_data" {
  description = "Public SSH key data for the administrator user. If not provided, password authentication will be enabled (not recommended for production)."
  type        = string
  default     = null # It's better to require this or generate a password
}

variable "admin_password" {
  description = "Administrator password for the VM instances. Required if admin_ssh_key_public_data is not provided. Must meet Azure complexity requirements."
  type        = string
  sensitive   = true
  default     = null
  validation {
    condition     = var.admin_ssh_key_public_data != null || (var.admin_ssh_key_public_data == null && var.admin_password != null)
    error_message = "If admin_ssh_key_public_data is not provided, admin_password must be set."
  }
  validation {
    condition     = var.admin_ssh_key_public_data != null || (var.admin_password != null && length(var.admin_password) >= 12)
    error_message = "If admin_password is used, it must be at least 12 characters long."
  }
}

variable "custom_data_script_path" {
  description = "Path to the custom_data script file for VM initialization."
  type        = string
  default     = "./scripts/setup_hello_world.sh" # Relative to this module's path
}

variable "os_disk_caching" {
  description = "Specifies the caching requirements for the OS disk. Possible values are None, ReadOnly and ReadWrite."
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Specifies the storage account type for the OS disk. Possible values are Standard_LRS, StandardSSD_LRS and Premium_LRS."
  type        = string
  default     = "Standard_LRS" # StandardSSD_LRS or Premium_LRS for better performance
}

variable "source_image_reference" {
  description = "Source image for the VM instances. Default is Ubuntu Server 22.04 LTS."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 LTS
    sku       = "22_04-lts-gen2"               # For Gen2 VMs
    version   = "latest"
  }
}

variable "upgrade_policy_mode" {
  description = "Specifies the mode of an upgrade to virtual machines in the scale set. Possible values are Automatic, Manual, Rolling."
  type        = string
  default     = "Automatic" # Or "Rolling" for more control
}

variable "health_probe_id" {
  description = "The ID of the Load Balancer health probe to use for VMSS health checks."
  type        = string
  default     = null # Optional: If null, LB health probe is used. If provided, VMSS uses this for its own health status.
}

# Autoscaling settings
variable "autoscaling_enabled" {
  description = "Enable autoscaling for the VMSS."
  type        = bool
  default     = true
}

variable "autoscale_min_count" {
  description = "Minimum number of instances for autoscaling."
  type        = number
  default     = 1
}

variable "autoscale_max_count" {
  description = "Maximum number of instances for autoscaling."
  type        = number
  default     = 3
}

variable "autoscale_default_count" {
  description = "Default number of instances if no scaling rules are met."
  type        = number
  default     = 2
}

variable "autoscale_cpu_percentage_high" {
  description = "CPU percentage threshold to scale out."
  type        = number
  default     = 75
}

variable "autoscale_cpu_percentage_low" {
  description = "CPU percentage threshold to scale in."
  type        = number
  default     = 25
}

variable "tags" {
  description = "A map of tags to apply to the VM Scale Set."
  type        = map(string)
  default     = {}
}

variable "availability_zones" {
  description = "A list of Availability Zones in which the Virtual Machine Scale Set instances will be created. Applicable for Standard SKU VMs in supporting regions."
  type        = list(string)
  default     = null # e.g. ["1", "2", "3"] - If null, no specific zones are set (region default or zone-redundant if SKU supports).
}
