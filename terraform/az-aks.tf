###############################################################################
# Main kubernetes cluster

locals {
  aks_name = "aks-${var.project_name_short}-${var.env}-${var.location}${var.global_index}"

  # Default AKS values
  aks_net_dns_service_ip     = "10.2.0.10"
  aks_net_service_cidr       = "10.2.0.0/24"
  aks_net_docker_bridge_cidr = "172.17.0.1/16"

  aks_net_outbound_type = "loadBalancer"
  aks_dns_name_prefix   = "${var.project_name_short}-host"
  aks_pool_system_name  = "system"
}

resource "azurerm_kubernetes_cluster" "aks" {
  resource_group_name                 = azurerm_resource_group.rg.name
  location                            = var.location
  name                                = local.aks_name
  kubernetes_version                  = var.kubernetes_version
  private_cluster_enabled             = true
  node_resource_group                 = "${azurerm_resource_group.rg.name}-aks"
  dns_prefix                          = local.aks_dns_name_prefix
  private_dns_zone_id                 = "None"
  private_cluster_public_fqdn_enabled = true

  linux_profile {
    admin_username = var.admin_user
    ssh_key {
      key_data = tls_private_key.admin_ssh_key.public_key_openssh
    }
  }

  default_node_pool {
    name                         = local.aks_pool_system_name
    node_count                   = var.aks_pool_system_count
    vnet_subnet_id               = module.vnet.vnet_subnets[local.subnet_id_aks]
    vm_size                      = var.aks_pool_system_vm_size
    only_critical_addons_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }
  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_identity.id
    client_id                 = azurerm_user_assigned_identity.aks_identity.client_id
    object_id                 = azurerm_user_assigned_identity.aks_identity.principal_id
  }

  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = "azure"
    dns_service_ip     = local.aks_net_dns_service_ip
    outbound_type      = local.aks_net_outbound_type
    service_cidr       = local.aks_net_service_cidr
    docker_bridge_cidr = local.aks_net_docker_bridge_cidr
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [data.azuread_group.admins.object_id]
  }

  tags = {
    environment = var.env
  }

  depends_on = [azurerm_user_assigned_identity.aks_identity]
}

###############################################################################
# User node pool: master (small VMs)
resource "azurerm_kubernetes_cluster_node_pool" "small" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = var.aks_pool_user_small_name
  vm_size               = var.aks_pool_user_small_vm_size
  node_count            = var.aks_pool_user_small_count
  node_taints           = ["agentpool=${var.aks_pool_user_small_name}:NoSchedule"]
  vnet_subnet_id        = module.vnet.vnet_subnets[local.subnet_id_aks]

  tags = {
    environment = var.env
  }
}

###############################################################################
# User node pool: data (big VMs)
resource "azurerm_kubernetes_cluster_node_pool" "big" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = var.aks_pool_user_big_name
  vm_size               = var.aks_pool_user_big_vm_size
  node_count            = var.aks_pool_user_big_count
  node_taints           = ["agentpool=${var.aks_pool_user_big_name}:NoSchedule"]
  vnet_subnet_id        = module.vnet.vnet_subnets[local.subnet_id_aks]

  tags = {
    environment = var.env
  }
}
