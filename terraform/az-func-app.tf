###############################################################################
# Azure function app
locals {
  # Servicer plan for (all?) func apps
  app_sp_name = "asp${var.func_app_md_os_code}-${var.project_name_short}-${var.env}${var.global_index}"
  # MD - metadata enrichment func-app
  func_app_md_name = "${var.project_name_short}-md-${var.env}-01"
}

# Service plan for functions
resource "azurerm_service_plan" "sp_fa" {
  name                = local.app_sp_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  os_type             = var.app_sp_fa_os_type
  sku_name            = var.app_sp_fa_sku
}

resource "azurerm_linux_function_app" "md" {
  name                = local.func_app_md_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  storage_account_name = azurerm_storage_account.common.name
  service_plan_id      = azurerm_service_plan.sp_fa.id

  key_vault_reference_identity_id = azurerm_user_assigned_identity.aks_identity.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  app_settings = {
    (var.func_app_md_app_sett_conn_str_name) = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.kv.name};SecretName=${local.kv_secret_name_storage_account_conn_string})"
  }

  site_config {
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.aks_identity.client_id

    application_stack {
      docker {
        registry_url = azurerm_container_registry.acr.login_server
        image_name   = var.func_app_md_image_name
        image_tag    = var.func_app_md_image_tag
      }
    }

    ip_restriction {
      name                      = local.func_app_md_name
      action                    = "Allow"
      priority                  = 10
      virtual_network_subnet_id = module.vnet.vnet_subnets[local.subnet_id_func_app]
    }
  }

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_key_vault_secret.storage_account_common_conn_string
  ]
}

# Vnet integration
resource "azurerm_app_service_virtual_network_swift_connection" "md" {
  app_service_id = azurerm_linux_function_app.md.id
  subnet_id      = module.vnet.vnet_subnets[local.subnet_id_func_app]
}