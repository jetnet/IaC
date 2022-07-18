###############################################################################
# Azure container registry
locals {
  storage_account_common_name = "${var.client_lable}${var.region_code}${var.project_name_short}${var.env}${var.global_index}"
}

resource "azurerm_storage_account" "common" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = local.storage_account_common_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  routing {
    publish_internet_endpoints = false
  }
  tags = {
    environment = var.env
  }
  depends_on = [azurerm_resource_group.rg]
}
