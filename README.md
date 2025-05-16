# aegp-terraform-challenge

Deployment of a Hello-World application using Terraform and Atmos. 

# The hello-world Terraform Component

This Terraform component deploys a "Hello World" application infrastructure on Azure. It includes a Virtual Network (VNet), subnets, Network Security Groups (NSGs), a Load Balancer, and a Virtual Machine Scale Set (VMSS) to host the application.

## Terraform Modules Overview

The `hello-world` component is structured using several distinct Terraform modules, each responsible for a specific set of resources. This separation of concerns is a core best practice in Terraform, leading to a more maintainable, reusable, and understandable infrastructure codebase. This separation allows for modularity, reusability, maintainability, testability, collabation and clarity.

### Module Breakdown:

1.  **`network` Module (`./modules/network/`)**
    *   **Purpose:** Responsible for creating the foundational networking infrastructure.
    *   **Key Resources:**
        *   Azure Virtual Network (VNet)
        *   Subnets (e.g., for frontend, backend, database tiers)
    *   **Best Practices:** Accepts VNet address space and subnet definitions as inputs, allowing flexible network design. Outputs subnet details for use by other modules.

2.  **`security` Module (`./modules/security/`)**
    *   **Purpose:** Manages network security configurations.
    *   **Key Resources:**
        *   Azure Network Security Groups (NSGs)
        *   NSG Rules
        *   Associations between NSGs and subnets.
    *   **Best Practices:** Takes NSG definitions (including rules) and subnet information as input. This allows for granular control over traffic flow between subnets and to/from the internet.

3.  **`load_balancer` Module (`./modules/load_balancer/`)**
    *   **Purpose:** Sets up the public-facing load balancer to distribute traffic to the application.
    *   **Key Resources:**
        *   Azure Public IP Address
        *   Azure Load Balancer (LB)
        *   LB Frontend IP Configuration
        *   LB Backend Address Pool
        *   LB Health Probe
        *   LB Rules
    *   **Best Practices:** Configures essential load balancing components, exposing parameters like ports and probe settings. Outputs IDs needed by the compute module to join the backend pool.

4.  **`compute` Module (`./modules/compute/`)**
    *   **Purpose:** Deploys the application hosting infrastructure.
    *   **Key Resources:**
        *   Azure Virtual Machine Scale Set (VMSS)
        *   VMSS OS configuration, extensions (e.g., custom script for app setup)
        *   Autoscaling settings for the VMSS.
    *   **Best Practices:** Takes subnet ID, load balancer backend pool ID, and health probe ID as inputs to integrate with the network and load balancer. Manages VMSS configuration, including image, SKU, admin access, and custom data for application deployment.

### File Structure

The `hello-world` component and its modules are organized as follows:

```
hello-world/
├── main.tf                 # Root module main configuration (orchestrates module calls)
├── variables.tf            # Root module variable definitions
├── outputs.tf              # Root module output definitions
├── versions.tf             # Terraform and provider version constraints
├── dev.tfvars              # Example variable values for a 'dev' environment (for direct Terraform usage)
├── modules/
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── scripts/
│   │       └── setup_hello_world.sh  # Example script for VMSS custom_data
│   ├── load_balancer/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md               # This file
```

## Running with Atmos (Example)

While you can run this Terraform component directly using `terraform apply -var-file="dev.tfvars"`, in this case I am using Atmos to manage configurations across multiple environments and stacks.

(WIP)