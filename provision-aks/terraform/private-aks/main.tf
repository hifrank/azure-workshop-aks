provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
# 1. provision
module "aks_cluster" {
  source = "./modules/aks-private-cluster"

  rg_name                      = var.aks_rg_name
  location                     = var.location
  cluster_name                 = var.cluster_name
  dns_prefix                   = var.dns_prefix
  vnet_id                      =  var.vnet_id
  default_agent_pool_subnet_id = var.default_agent_pool_subnet_id
}

# image registry
## habor setting
## ACR

# 2 node pool

# 2.1 spot node pool
# 2.2 node pool

# 3.1 ingress
# nginx
# agic

# 3.2 storage class
# application package
## helm/kuctomize
## gitops


# 4 monitoring