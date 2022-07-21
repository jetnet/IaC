###############################################################################
# Managed identity
locals {
  identity_name = "id-aks-${var.project_name_short}-${var.location}${var.global_index}"
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = local.identity_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
  tags = {
    environment = var.env
  }
  depends_on = [azurerm_key_vault.kv]
}

# and its roles
resource "azurerm_role_assignment" "acrpull-role" {
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  principal_id                     = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "managed-identity-operator-role" {
  role_definition_name             = "Managed Identity Operator"
  scope                            = azurerm_user_assigned_identity.aks_identity.id
  principal_id                     = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks-subnet-contributer" {
  role_definition_name             = "Network Contributor"
  scope                            = module.vnet.vnet_subnets[local.subnet_id_aks]
  principal_id                     = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}