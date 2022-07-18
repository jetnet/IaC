###############################################################################
# Key Vault

locals {
  kv_name                                    = "clnkv-${var.project_name_short}-${var.location}${var.global_index}"
  kv_cert_name_frontend                      = var.project_name
  kv_secret_name_etl_license              = "ETLLicense"
  kv_secret_name_storage_account_conn_string = "${var.client_lable}-AZURE-STORAGE-CONNECTION-STRING"
  kv_secret_name_admin_key                   = "${var.admin_user}-key"
}

resource "azurerm_key_vault" "kv" {
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  enable_rbac_authorization       = true
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  tags = {
    environment = var.env
  }
  depends_on = [azurerm_container_registry.acr]
}

# Current user / SP should be Admin
resource "azurerm_role_assignment" "kv_role_admin_deployer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

  skip_service_principal_aad_check = false # if "true", then "principal_type" is assumed to be "Service Principal"
}

# Admin AD group permissions
resource "azurerm_role_assignment" "kv_role_admins" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_group.admins.object_id
}
# Developers AD group permissions
resource "azurerm_role_assignment" "kv_role_developers" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Reader"
  principal_id         = data.azuread_group.developers.object_id
}

# Store the storage account connection string as a secret
resource "azurerm_key_vault_secret" "storage_account_common_conn_string" {
  name         = local.kv_secret_name_storage_account_conn_string
  key_vault_id = azurerm_key_vault.kv.id
  value        = azurerm_storage_account.common.primary_connection_string
}

# Store the admin's SSH private key as a secret
resource "azurerm_key_vault_secret" "admin_key" {
  name         = local.kv_secret_name_admin_key
  key_vault_id = azurerm_key_vault.kv.id
  value        = tls_private_key.admin_ssh_key.private_key_openssh
}

# Key Vault check: ETL license
# - Secret check returns "404 - Not Found", so the following postcondition check will not kick in
data "azurerm_key_vault_secret" "etl_license_secret" {
  name         = local.kv_secret_name_etl_license
  key_vault_id = azurerm_key_vault.kv.id
  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "ETL license must be uploaded to key vault '${azurerm_key_vault.kv.name}' as '${local.kv_secret_name_etl_license}'"
    }
  }
  depends_on = [
    azurerm_key_vault.kv,
    azurerm_role_assignment.kv_role_admin_deployer
  ]
}

# Key Vault check: PEM certificate for HTTPS in AppGW
# - Certificate check does not return "404 - Not Found", so using a post condition check with a proper error message
data "azurerm_key_vault_certificate" "frontend_cert" {
  name         = local.kv_cert_name_frontend
  key_vault_id = azurerm_key_vault.kv.id
  lifecycle {
    postcondition {
      condition     = self.id != null
      error_message = "PEM frontend certificate must be uploaded to key vault '${azurerm_key_vault.kv.name}' as '${local.kv_cert_name_frontend}'"
    }
  }
  depends_on = [
    azurerm_key_vault.kv,
    azurerm_role_assignment.kv_role_admin_deployer
  ]
}
