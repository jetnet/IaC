###############################################################################
# Azure Bastion service
locals {
  bastion_name     = "bastion-${var.client_lable}-${var.env}-${var.location}01"
  pip_bastion_name = "pip-${local.bastion_name}"
}

resource "azurerm_public_ip" "pip_bastion" {
  name                = local.pip_bastion_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  # Static IP required by Bastion: https://docs.microsoft.com/en-us/azure/virtual-network/ip-services/public-ip-addresses
  allocation_method = "Static"
  sku               = "Standard"
  tags = {
    environment = var.env
  }
}

resource "azurerm_bastion_host" "main" {
  name                = local.bastion_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tunneling_enabled   = true
  ip_configuration {
    name                 = "${local.bastion_name}-network"
    subnet_id            = module.vnet.vnet_subnets[local.subnet_id_bastion]
    public_ip_address_id = azurerm_public_ip.pip_bastion.id
  }
  tags = {
    environment = var.env
  }
}