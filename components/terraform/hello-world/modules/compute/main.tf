# Read the custom_data script content
data "local_file" "custom_data_script" {
  filename = "${path.module}/${var.custom_data_script_path}"
}

# Encode custom_data to base64
data "cloudinit_config" "custom_data_cloudinit" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.local_file.custom_data_script.content
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = var.vmss_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vm_sku
  instances           = var.instance_count # Initial instance count, managed by autoscale profile if enabled
  admin_username      = var.admin_username
  custom_data         = data.cloudinit_config.custom_data_cloudinit.rendered # Use base64 encoded cloud-init
  tags                = var.tags

  # Use SSH key if provided, otherwise use password (ensure password is set if no key)
  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_key_public_data != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.admin_ssh_key_public_data
    }
  }

  # Enable password authentication if no SSH key is provided and password is set
  disable_password_authentication = var.admin_ssh_key_public_data != null
  admin_password                  = var.admin_ssh_key_public_data == null ? var.admin_password : null

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  network_interface {
    name    = "nic-${var.vmss_name}" # Base name for NICs
    primary = true

    ip_configuration {
      name      = "ipconfig-${var.vmss_name}"
      primary   = true
      subnet_id = var.subnet_id
      # Associate with Load Balancer backend pool
      load_balancer_backend_address_pool_ids = [var.lb_backend_pool_id]
    }
  }

  # Upgrade policy
  upgrade_mode = var.upgrade_policy_mode

  # Health probe for VMSS (optional, can use LB probe implicitly)
  # If specified, VMSS uses this for its own instance health determination.
  # The LB probe is still essential for the LB to route traffic.
  health_probe_id = var.health_probe_id

  # Ensure instances are not over-provisioned beyond what's necessary
  overprovision = false # Set to true if faster scale-out is needed at the cost of temporary extra instances

  # Zone balancing for Standard SKU VMs (recommended for production)
  # If your region supports availability zones and vm_sku is Standard
  zones = var.availability_zones
}

# Autoscaler Profile for the VM Scale Set
resource "azurerm_monitor_autoscale_setting" "main" {
  count = var.autoscaling_enabled ? 1 : 0 # Only create if autoscaling is enabled

  name                = "autoscale-${var.vmss_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.main.id
  tags                = var.tags

  profile {
    name = "defaultProfile"

    capacity {
      default = var.autoscale_default_count
      minimum = var.autoscale_min_count
      maximum = var.autoscale_max_count
    }

    # Scale out rule (CPU high)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M" # 1 minute
        statistic          = "Average"
        time_window        = "PT5M" # 5 minutes
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.autoscale_cpu_percentage_high
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1" # Increase instance count by 1
        cooldown  = "PT5M" # 5 minutes cooldown
      }
    }

    # Scale in rule (CPU low)
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.autoscale_cpu_percentage_low
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1" # Decrease instance count by 1
        cooldown  = "PT5M"
      }
    }
  }
}
