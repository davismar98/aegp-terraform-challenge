
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

  tags       = var.common_tags
  depends_on = [azurerm_resource_group.main]
}

module "security" {
  source = "./modules/security"

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}"
  location            = var.location
  tags                = var.common_tags

  subnets_data = module.network.subnets

  network_security_groups = {
    "web_nsg" = {
      name = "nsg-${var.stage}-web"
      rules = [
        {
          name                       = "AllowLBtoAppOn8080"
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "AzureLoadBalancer"
          destination_address_prefix = "*"
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
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = module.network.subnets["frontend"].address_prefixes[0]
          destination_address_prefix = "*"
          description                = "Allow traffic from Web Subnet to App tier on port 8080"
        }
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
          source_address_prefix      = module.network.subnets["backend"].address_prefixes[0]
          destination_address_prefix = "*"
          description                = "Allow SQL traffic from App Subnet"
        }
      ]
    }
  }

  subnet_nsg_associations = {
    "frontend" = "web_nsg" # Associate the 'frontend' subnet with 'web_nsg'
    "backend"  = "app_nsg" # Associate the 'backend' subnet with 'app_nsg'
    "database" = "db_nsg"  # Associate the 'database' subnet with 'db_nsg'
  }

  depends_on = [azurerm_resource_group.main]
}

module "load_balancer" {
  source = "./modules/load_balancer"

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}"
  location            = var.location
  tags                = var.common_tags

  load_balancer_name = "lb-${var.stage}-helloworld"
  public_ip_name     = "pip-${var.stage}-helloworld-lb"
  public_ip_sku      = "Standard"
  lb_sku             = "Standard"
  public_ip_zones    = ["1", "2", "3"]

  # Frontend port exposed to the internet
  lb_frontend_port = 80 

  # Backend port your application listens on (VMs)
  lb_backend_port = var.app_port

  # Health Probe configuration
  health_probe_port     = var.app_port
  health_probe_protocol = "Tcp"

  depends_on = [azurerm_resource_group.main]
}

module "compute" {
  source = "./modules/compute"

  resource_group_name = "${var.resource_group_name_prefix}-${var.stage}"
  location            = var.location
  tags                = var.common_tags

  vmss_name          = "vmss-${var.stage}-helloworld"
  subnet_id          = module.network.subnets["frontend"].id
  lb_backend_pool_id = module.load_balancer.backend_address_pool_id
  health_probe_id    = module.load_balancer.health_probe_id

  instance_count = var.instance_count          
  vm_sku         = var.vm_sku

  admin_username            = "azureuser"
  admin_ssh_key_public_data = var.admin_ssh_key_public

  autoscaling_enabled     = true
  autoscale_min_count     = var.instance_count
  autoscale_max_count     = var.instance_count * 2
  autoscale_default_count = var.instance_count

  availability_zones = null # ["1", "2", "3"] # null = zone-redundant

  depends_on = [azurerm_resource_group.main]
}
