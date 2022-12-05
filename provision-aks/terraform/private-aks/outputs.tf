output "get_cluster_credential" {
  value = "az aks get-credentials --name ${module.aks_cluster.cluster_name} --resource-group ${module.aks_cluster.resource_group_name} --admin"
}
