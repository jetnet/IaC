###############################################################################
# Key Vault

locals {
  kv_name                                    = "clnkv-${var.project_name_short}-${var.location}${var.global_index}"
  kv_cert_name_frontend                      = var.project_name
  kv_secret_name_etl_license              = "ETLLicense"
  kv_secret_name_storage_account_conn_string = "${var.client_lable}-AZURE-STORAGE-CONNECTION-STRING"
  kv_secret_name_admin_key                   = "${var.admin_user}-key"

  kv_certificate_permissions_read = tolist(["Get", "List"])
  kv_key_permissions_read         = tolist(["Get", "List"])
  kv_secret_permissions_read      = tolist(["Get", "List"])
  kv_storage_permissions_read     = tolist(["Get", "List"])

  kv_certificate_permissions_all = tolist(["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"])
  kv_key_permissions_all         = tolist(["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"])
  kv_secret_permissions_all      = tolist(["Backup", "Delete", "Get", "List", "Recover", "Restore", "Set"])
  kv_storage_permissions_all     = tolist(["Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"])

  kv_certificate_permissions_full = concat(local.kv_certificate_permissions_all, ["Purge"])
  kv_key_permissions_full         = concat(local.kv_key_permissions_all, ["Purge"])
  kv_secret_permissions_full      = concat(local.kv_secret_permissions_all, ["Purge"])
  kv_storage_permissions_full     = concat(local.kv_storage_permissions_all, ["Purge"])
}

resource "azurerm_key_vault" "kv" {
  name                = local.kv_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Do not use Azure RBAC, because Application Gateway does not support it properly:
  # https://docs.microsoft.com/en-us/azure/application-gateway/key-vault-certs#key-vault-azure-role-based-access-control-permission-model
  enable_rbac_authorization = false

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  tags = {
    environment = var.env
  }
  depends_on = [azurerm_container_registry.acr]
}

# Make sure the current account has full access to the key vault items
resource "azurerm_key_vault_access_policy" "kvaccess_deployer" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = local.kv_certificate_permissions_full
  key_permissions         = local.kv_key_permissions_full
  secret_permissions      = local.kv_secret_permissions_full
  storage_permissions     = local.kv_storage_permissions_full
}

# Admins: full access to the key vault items
resource "azurerm_key_vault_access_policy" "kvaccess_admins" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_group.admins.object_id

  certificate_permissions = local.kv_certificate_permissions_full
  key_permissions         = local.kv_key_permissions_full
  secret_permissions      = local.kv_secret_permissions_full
  storage_permissions     = local.kv_storage_permissions_full
}

# Developers: read access to the key vault items
resource "azurerm_key_vault_access_policy" "kvaccess_developers" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_group.developers.object_id

  certificate_permissions = local.kv_certificate_permissions_read
  key_permissions         = local.kv_key_permissions_read
  secret_permissions      = local.kv_secret_permissions_read
  storage_permissions     = local.kv_storage_permissions_read
}

# Main ("AKS") identity: read-only access
resource "azurerm_key_vault_access_policy" "kvaccess_aks_identity" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.aks_identity.principal_id

  certificate_permissions = local.kv_certificate_permissions_read
  key_permissions         = local.kv_key_permissions_read
  secret_permissions      = local.kv_secret_permissions_read
  storage_permissions     = local.kv_storage_permissions_read
}

# Store the storage account connection string as a secret
resource "azurerm_key_vault_secret" "storage_account_common_conn_string" {
  name         = local.kv_secret_name_storage_account_conn_string
  key_vault_id = azurerm_key_vault.kv.id
  value        = azurerm_storage_account.common.primary_connection_string
  depends_on = [
    azurerm_key_vault.kv,
    azurerm_key_vault_access_policy.kvaccess_deployer
  ]
}

# Store the admin's SSH private key as a secret
resource "azurerm_key_vault_secret" "admin_key" {
  name         = local.kv_secret_name_admin_key
  key_vault_id = azurerm_key_vault.kv.id
  value        = tls_private_key.admin_ssh_key.private_key_openssh
  depends_on = [
    azurerm_key_vault.kv,
    azurerm_key_vault_access_policy.kvaccess_deployer
  ]
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
    azurerm_key_vault_access_policy.kvaccess_deployer
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
      error_message = <<EOM
        PEM frontend certificate must be uploaded to key vault '${azurerm_key_vault.kv.name}' as '${local.kv_cert_name_frontend}', e.g.:
        az keyvault certificate import --vault-name "${azurerm_key_vault.kv.name}" -n "${local.kv_cert_name_frontend}" -f "/path/to/${var.project_name}-${var.env}.pfx" -o none

        Make sure, the ETL license is uploaded as well, e.g.:
        az keyvault secret set "${azurerm_key_vault.kv.name}" -n  "${local.kv_secret_name_etl_license}" -f "/path/to/${local.kv_secret_name_etl_license}.lic" -o none

      EOM
    }
  }
  depends_on = [
    azurerm_key_vault.kv,
    azurerm_key_vault_access_policy.kvaccess_deployer
  ]
}
