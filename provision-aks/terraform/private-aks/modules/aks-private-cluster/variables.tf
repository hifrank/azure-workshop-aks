variable "rg_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "location" {
  type = string
}

variable "default_agent_pool_subnet_id" {
  type = string
}

variable "default_agent_pool_max_count" {
  default = 3
}

variable "default_agent_pool_count" {
  default = 1
}

variable "default_agent_pool_min_count" {
  default = 1
}

variable "default_agent_pool_vm_sku" {
  default = "Standard_D2_v2"
}


variable "vnet_id" {
  type = string
}

variable "dns_prefix" {
  default = ""
}

variable "network_policy" {
  default = "calico"
}


variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "enable_private_cluster" {
  type    = bool
  default = true
}

