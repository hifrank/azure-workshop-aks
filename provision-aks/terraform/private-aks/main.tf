provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# 1. provision AKS cluster(4-10m)
###############################################
###############################################
module "aks_cluster" {
  source                       = "./modules/aks-private-cluster"
  enable_private_cluster       = true
  rg_name                      = var.aks_rg_name
  location                     = var.location
  cluster_name                 = var.cluster_name
  dns_prefix                   = var.dns_prefix
  vnet_id                      = var.vnet_id
  default_agent_pool_subnet_id = var.default_agent_pool_subnet_id
}

# 1.2 image registry
###############################################
## habor setting
## ACR
###############################################

# 2 node pool (4m)
###############################################
# 2.1 node pool
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool
# resource "azurerm_kubernetes_cluster_node_pool" "regular" {
#   name                  = "regular"
#   vnet_subnet_id = var.default_agent_pool_subnet_id
#   kubernetes_cluster_id = module.aks_cluster.cluster_id
#   vm_size               = "Standard_B2s"
#   enable_auto_scaling   = true
#   max_count             = 5
#   min_count             = 1

#   tags = {
#     Environment = "Production"
#     Node        = "Regular"
#   }
# }
# 2.2 spot node pool
# https://learn.microsoft.com/en-us/azure/aks/spot-node-pool
# resource "azurerm_kubernetes_cluster_node_pool" "spot" {
#   name                  = "spot"
#   vnet_subnet_id = var.default_agent_pool_subnet_id
#   kubernetes_cluster_id = module.aks_cluster.cluster_id
#   # https://aka.ms/azureskunotavailable
#   vm_size               = "Standard_D2_v5"
#   enable_auto_scaling   = true
#   max_count             = 5
#   min_count             = 1
#   priority              = "Spot"
#   eviction_policy       = "Delete"
#   node_taints           = [
#     "spot:NoSchedule",
#     "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
#     ]
#   node_labels = {
#     "kubernetes.azure.com/scalesetpriority": "spot",
#   }
#   tags = {
#     Environment = "Production"
#     Node        = "Spot"
#   }
# }

# 3. services
###############################################
# 3.1 ingress
# nginx
# agic
# https://learn.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-aks-applicationgateway-ingress

# 3.2 storage class
# application package
## helm/kuctomize
## gitops


# 4 monitoring
