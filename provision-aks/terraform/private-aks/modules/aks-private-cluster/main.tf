# create managed identity for AKS control panel
# https://learn.microsoft.com/en-us/azure/aks/use-managed-identity#bring-your-own-control-plane-managed-identity
resource "azurerm_user_assigned_identity" "this" {
  location            = var.location
  name                = format("mi-%s", var.cluster_name)
  resource_group_name = var.rg_name
}
data "azurerm_resource_group" "this" {
  name = var.rg_name
}

# Assign contributor permission for the resource group of AKS
resource "azurerm_role_assignment" "this_rg" {
  scope                = data.azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

# assign network contributor role
resource "azurerm_role_assignment" "this_vnet" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}


# create private DNS zone for AKS
resource "azurerm_private_dns_zone" "this" {
  name                = format("%s.privatelink.%s.azmk8s.io", var.dns_prefix, var.location)
  resource_group_name = var.rg_name
}

resource "azurerm_role_assignment" "this_dns_zone" {
  scope                = azurerm_private_dns_zone.this.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}

# create route table for AKS
resource "azurerm_route_table" "this" {
  name                          = format("route-%s", var.cluster_name)
  location                      = var.location
  resource_group_name           = var.rg_name
  disable_bgp_route_propagation = false
  tags                          = var.tags
}

# add route to route table.
# resource "azurerm_route" "this" {
#   name                = concat("route-", var.cluster_name, "-default")
#   resource_group_name = var.rg_name
#   route_table_name    = azurerm_route_table.this.name
#   address_prefix      = "10.1.0.0/16"
#   next_hop_type       = "VirtualAppliance"
# }

resource "azurerm_kubernetes_cluster" "this" {
  location            = var.location
  name                = var.cluster_name
  resource_group_name = var.rg_name
  dns_prefix          = var.dns_prefix
  tags                = var.tags
  # enable private cluster
  private_cluster_enabled = true

  # use the prirvate dns zone we created
  private_dns_zone_id = azurerm_private_dns_zone.this.id

  default_node_pool {
    name          = "default"
    type          = "VirtualMachineScaleSets"
    vm_size       = var.default_agent_pool_vm_sku
    vnet_subnet_id = var.default_agent_pool_subnet_id


    enable_auto_scaling = true
    node_count          = var.default_agent_pool_count
    max_count           = var.default_agent_pool_max_count
    min_count           = var.default_agent_pool_min_count
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  auto_scaler_profile {

  }

  automatic_channel_upgrade = "stable"

  depends_on = [
    azurerm_role_assignment.this_dns_zone,
  ]
}
