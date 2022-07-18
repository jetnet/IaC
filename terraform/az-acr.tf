###############################################################################
# Azure container registry
locals {
  acr_name = "${var.client_lable}acr${var.project_name_short}${var.env}${var.global_index}"
}

resource "azurerm_container_registry" "acr" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.acr_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
  tags = {
    environment = var.env
  }
  depends_on = [azurerm_storage_account.common]
}
