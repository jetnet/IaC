###############################################################################
# Tenant data
data "azurerm_client_config" "current" {}

###############################################################################
# Current subscription
data "azurerm_subscription" "current" {
}
locals {
  subscription_name_normalized = replace(data.azurerm_subscription.current.display_name, " ", "")
}

###############################################################################
# Main Resource Group
resource "azurerm_resource_group" "rg" {
  # commendted out, since some environments are not compliant with the naming policy
  # name     = "RG-${local.subscription_name_normalized}-${var.project_name_short}-01-${var.env}"
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = var.env
  }
}

###############################################################################
# AAD security groups for admins and developers, they get created manually
data "azuread_group" "admins" {
  display_name     = var.aad_group_admins
  security_enabled = true
}
data "azuread_group" "developers" {
  display_name     = var.aad_group_developers
  security_enabled = true
}

###############################################################################
# Generate an SSH key for AKS nodes and for admin VM
resource "tls_private_key" "admin_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
