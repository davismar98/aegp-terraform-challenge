
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name_prefix}-${var.stage}"
  location = var.location
}

module "network" {
  source = "./modules/network"

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}"
  location            = var.location
  vnet_name           = "vnet-${var.stage}-main"
  vnet_address_space  = var.vnet_address_space

  subnets = {
    "frontend" = {
      address_prefixes = [cidrsubnet(var.vnet_address_space[0],2,1)]
      role             = "public-facing"
    },
    "backend" = {
      address_prefixes = [cidrsubnet(var.vnet_address_space[0],2,2)]
      role             = "internal-app"
    },
    "database" = {
      address_prefixes  = [cidrsubnet(var.vnet_address_space[0],2,3)]
      role              = "database"
      service_endpoints = ["Microsoft.Sql"]
    }
  }

  tags       = var.common_tags # From component's variables
  depends_on = [azurerm_resource_group.main]
}

# In components/terraform/hello-world-app/main.tf

# (Assuming module.network is already defined as in the previous example)

# Example variables you would define in the component's variables.tf for NSGs
# variable "web_nsg_rules" { type = list(object(...)) }
# variable "app_nsg_rules" { type = list(object(...)) }
# variable "db_nsg_rules"  { type = list(object(...)) }

module "security" {
  source = "./modules/security" # Path to your security module

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}" # From component's variables
  location            = var.location            # From component's variables
  tags                = var.common_tags         # From component's variables

  # Pass the subnets data from the network module
  subnets_data = module.network.subnets

  network_security_groups = {
    "web_nsg" = {                   # Logical name for this NSG
      name = "nsg-${var.stage}-web" # Actual Azure name
      rules = [
        {
          name                       = "AllowLBtoAppOn8080"
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"              # Your application port
          source_address_prefix      = "AzureLoadBalancer" # Service Tag for Azure LB
          destination_address_prefix = "*"                 # Or module.network.subnets["backend"].address_prefixes[0]
          description                = "Allow traffic from Azure Load Balancer to App tier on port 8080"
        }
      ]
    },
    "app_nsg" = {
      name = "nsg-${var.stage}-app"
      rules = [
        {
          name                       = "AllowFromWebSubnet"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp" # Or specific app protocol
          source_port_range          = "*"
          destination_port_range     = "8080"                                                 # Example app port
          source_address_prefix      = module.network.subnets["frontend"].address_prefixes[0] # Assuming "frontend" is the logical key for your web subnet
          destination_address_prefix = "*"
          description                = "Allow traffic from Web Subnet to App tier on port 8080"
        }
        # Potentially allow outbound to database subnet or specific Azure services
      ]
    },
    "db_nsg" = {
      name = "nsg-${var.stage}-db"
      rules = [
        {
          name                   = "AllowFromAppSubnetToSQL"
          priority               = 100
          direction              = "Inbound"
          access                 = "Allow"
          protocol               = "Tcp"
          source_port_range      = "*"
          destination_port_range = "1433" # MS SQL Port
          # Use the address prefix of the app subnet.
          # This requires knowing the logical name used in module.network.subnets output
          source_address_prefix      = module.network.subnets["backend"].address_prefixes[0] # Assuming "backend" is the logical key for your app subnet
          destination_address_prefix = "*"
          description                = "Allow SQL traffic from App Subnet"
        }
      ]
    }
  }

  # Define which NSG to associate with which logical subnet
  # The keys here ("frontend", "backend", "database") must match the keys
  # used when defining subnets in the network module.
  # The values ("web_nsg", "app_nsg", "db_nsg") must match the keys
  # used in the network_security_groups map above.
  subnet_nsg_associations = {
    "frontend" = "web_nsg" # Associate the 'frontend' subnet with 'web_nsg'
    "backend"  = "app_nsg" # Associate the 'backend' subnet with 'app_nsg'
    "database" = "db_nsg"  # Associate the 'database' subnet with 'db_nsg'
  }

  depends_on = [azurerm_resource_group.main]
}

module "load_balancer" {
  source = "./modules/load_balancer" # Path to your load_balancer module

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}" # From component's variables
  location            = var.location            # From component's variables
  tags                = var.common_tags         # From component's variables

  load_balancer_name = "lb-${var.stage}-helloworld"
  public_ip_name     = "pip-${var.stage}-helloworld-lb"
  public_ip_sku      = "Standard" # Recommended
  lb_sku             = "Standard" # Recommended
  public_ip_zones    = ["1", "2", "3"]

  # Frontend port exposed to the internet
  lb_frontend_port = 80 # For HTTP access

  # Backend port your application listens on (VMs)
  lb_backend_port = var.app_port

  # Health Probe configuration
  health_probe_port     = var.app_port # Probe the same port the app listens on
  health_probe_protocol = "Tcp"        # TCP is simplest if app doesn't have a dedicated /health endpoint
  # If using "Http" or "Https" for health_probe_protocol, set health_probe_request_path:
  # health_probe_request_path = "/" # Or your specific health check path

  # You can customize other LB settings via variables if needed
  depends_on = [azurerm_resource_group.main]
}

module "compute" {
  source = "./modules/compute" # Path to your compute module

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}" # From component's variables
  location            = var.location            # From component's variables
  tags                = var.common_tags         # From component's variables

  vmss_name          = "vmss-${var.stage}-helloworld"
  subnet_id          = module.network.subnets["frontend"].id # Assuming "frontend" is your web subnet
  lb_backend_pool_id = module.load_balancer.backend_address_pool_id
  health_probe_id    = module.load_balancer.health_probe_id # Use LB's health probe for VMSS health

  instance_count = 2              # Initial count, will be managed by autoscale if enabled
  vm_sku         = "Standard_B1s" # Or your preferred SKU

  admin_username            = "azureuser"
  admin_ssh_key_public_data = var.admin_ssh_key_public # Pass your public SSH key
  # If not using SSH keys (not recommended for prod):
  # admin_password = var.vm_admin_password # Ensure this var is defined and sensitive

  # Autoscaling settings (can be customized via component variables)
  autoscaling_enabled     = true
  autoscale_min_count     = 1
  autoscale_max_count     = 3
  autoscale_default_count = 2

  availability_zones = null # ["1", "2", "3"] # null = zone-redundant

  depends_on = [azurerm_resource_group.main]
}
