###############################################################################
# Network local variables
locals {
  # max length of a VNet name must not exceed 64 chars
  vnet_name            = format("vm-%s-%s-%s", substr(local.subscription_name_normalized, 0, 55), var.env, "01")
  subnet_name_aks      = "subnet-aks"
  aks_subnet_id        = 0
  subnet_name_ag       = "subnet-ag"
  subnet_name_func_app = "subnet-func-app"
  subnet_name_bastion  = "AzureBastionSubnet"
}

###############################################################################
# Network security group
# Module info: https://registry.terraform.io/modules/Azure/network-security-group/azurerm/3.6.0
module "nsg-ag" {
  source              = "Azure/network-security-group/azurerm"
  version             = "3.6.0"
  security_group_name = "nsg-${local.subnet_name_ag}"
  resource_group_name = azurerm_resource_group.rg.name

  custom_rules = [
    {
      name                   = "HTTPS"
      priority               = 500
      direction              = "Inbound"
      access                 = "Allow"
      destination_port_range = "443"
      source_address_prefix  = "Internet"
      description            = "Access to UI via secured HTTP"
    },
    {
      name                   = "HTTP"
      priority               = 510
      direction              = "Inbound"
      access                 = "Allow"
      destination_port_range = "80"
      source_address_prefix  = "Internet"
      description            = "Access to AppGW redirect rule for incecured HTTP traffic"
    },
    {
      name                   = "Opensearch-Dashboards"
      priority               = 520
      direction              = "Inbound"
      access                 = "Allow"
      destination_port_range = "8443"
      source_address_prefix  = "Internet"
      description            = "Access to Opensearch Dashboards UI"
    },
    {
      name                   = "ApplicationGatewaySKUv2"
      priority               = 4096
      direction              = "Inbound"
      access                 = "Allow"
      destination_port_range = "65200-65535"
      source_address_prefix  = "GatewayManager"
      description            = "Azure AppGW management traffic"
    }
  ]
  tags = {
    environment = var.env
  }
  depends_on = [azurerm_user_assigned_identity.aks_identity]
}

###############################################################################
# Vnet & Sub-nets
# Module info: https://registry.terraform.io/modules/Azure/vnet/azurerm/2.6.0
module "vnet" {
  source              = "Azure/vnet/azurerm"
  version             = "2.6.0"
  vnet_name           = local.vnet_name
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]
  subnet_prefixes     = [var.subnet_cidr_aks, var.subnet_cidr_ag, var.subnet_cidr_bastion, var.subnet_cidr_func_app]
  subnet_names        = [local.subnet_name_aks, local.subnet_name_ag, local.subnet_name_bastion, local.subnet_name_func_app]
  dns_servers         = [var.vnet_dns_server_default, var.vnet_dns_server_custom]
  nsg_ids = {
    (local.subnet_name_ag) = module.nsg-ag.network_security_group_id
  }
  tags = {
    environment = var.env
  }
  depends_on = [module.nsg-ag]
}
