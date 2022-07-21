###############################################################################
# Azure application gateway
locals {
  ag_name     = "appgw-${var.client_lable}-${var.env}-${var.location}01"
  pip_ag_name = "pip-${local.ag_name}"

  # Opensearch Dashboards services prefix
  ag_svc_prfx_osdb = "osdb"
  # UI services prefix
  ag_svc_prfx_ui = "ui"

  # Certificates
  ag_ssl_cert_name = "appgw-${var.project_name}"

  # Probes and Backend pools
  ag_probe_os_name               = "be-prob-${local.ag_svc_prfx_osdb}"
  ag_backend_settings_ui_name    = "be-sett-${local.ag_svc_prfx_ui}"
  ag_backend_settings_os_db_name = "be-sett-${local.ag_svc_prfx_osdb}"
  ag_backend_pool_ui_name        = "be-pool-${local.ag_svc_prfx_ui}"
  ag_backend_pool_os_db_name     = "be-pool-${local.ag_svc_prfx_osdb}"

  # Public IP and Frontend ports
  ag_frontend_port_ui_http_name       = "fe-port-http-${local.ag_svc_prfx_ui}"
  ag_frontend_port_ui_https_name      = "fe-port-https-${local.ag_svc_prfx_ui}"
  ag_frontend_port_os_db_https_name   = "fe-port-https-${local.ag_svc_prfx_osdb}"
  ag_frontend_ip_configuration_public = "public-ip"

  # Listeners
  ag_listener_ui_http_name     = "lsnr-http-${local.ag_svc_prfx_ui}"
  ag_listener_ui_https_name    = "lsnr-https-${local.ag_svc_prfx_ui}"
  ag_listener_os_db_https_name = "lsnr-https-${local.ag_svc_prfx_osdb}"

  # Routing rules and redirects
  ag_request_routing_rule_ui_http_name     = "rule-http-${local.ag_svc_prfx_ui}"
  ag_request_routing_rule_ui_https_name    = "rule-https-${local.ag_svc_prfx_ui}"
  ag_request_routing_rule_os_db_https_name = "rule-https-${local.ag_svc_prfx_osdb}"
  ag_redirect_configuration_ui_http_name   = "rdr-http-https-${local.ag_svc_prfx_ui}"
}

resource "azurerm_public_ip" "pip_appgw" {
  name                = local.pip_ag_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  domain_name_label   = "${var.project_name}-${var.env}" # requires: "Microsoft.Network/publicIPAddresses/write" permissions
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = var.env
  }
}

resource "azurerm_application_gateway" "main" {
  name                = local.ag_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "${local.ag_name}-ip"
    subnet_id = module.vnet.vnet_subnets[local.subnet_id_appgw]
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  #############################################################################
  # Backend custom probes, settings and pools
  probe {
    name                                      = local.ag_probe_os_name
    protocol                                  = var.os_db_protocol
    path                                      = "/"
    interval                                  = 60
    timeout                                   = 120
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      # "Unauthorized" should be a valid response too, as we want to use Opensearch authentication
      status_code = ["200-401"]
      body        = ""
    }
  }

  backend_http_settings {
    name                                = local.ag_backend_settings_ui_name
    cookie_based_affinity               = "Disabled"
    port                                = var.ui_port
    protocol                            = var.ui_protocol
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  backend_http_settings {
    name                                = local.ag_backend_settings_os_db_name
    cookie_based_affinity               = "Disabled"
    port                                = var.os_db_port
    protocol                            = var.os_db_protocol
    request_timeout                     = 30
    probe_name                          = local.ag_probe_os_name
    pick_host_name_from_backend_address = true
  }

  backend_address_pool {
    name         = local.ag_backend_pool_ui_name
    ip_addresses = [var.ui_ip_address]
  }

  backend_address_pool {
    name         = local.ag_backend_pool_os_db_name
    ip_addresses = [var.os_db_ip_address]
  }

  #############################################################################
  # SSL certificates
  ssl_certificate {
    name                = local.ag_ssl_cert_name
    key_vault_secret_id = data.azurerm_key_vault_certificate.frontend_cert.secret_id
  }

  #############################################################################
  # Frontend ports and IP configuration
  frontend_ip_configuration {
    name                 = local.ag_frontend_ip_configuration_public
    public_ip_address_id = azurerm_public_ip.pip_appgw.id
  }

  frontend_port {
    name = local.ag_frontend_port_ui_http_name
    port = 80
  }

  frontend_port {
    name = local.ag_frontend_port_ui_https_name
    port = 443
  }

  frontend_port {
    name = local.ag_frontend_port_os_db_https_name
    port = 8443
  }

  #############################################################################
  # Listeners for UI (https), UI redirect (http - https), Opensearch Dashboards
  http_listener {
    name                           = local.ag_listener_ui_http_name
    frontend_ip_configuration_name = local.ag_frontend_ip_configuration_public
    frontend_port_name             = local.ag_frontend_port_ui_http_name
    protocol                       = "Http"
  }

  http_listener {
    name                           = local.ag_listener_ui_https_name
    frontend_ip_configuration_name = local.ag_frontend_ip_configuration_public
    frontend_port_name             = local.ag_frontend_port_ui_https_name
    protocol                       = "Https"
    ssl_certificate_name           = local.ag_ssl_cert_name
  }

  http_listener {
    name                           = local.ag_listener_os_db_https_name
    frontend_ip_configuration_name = local.ag_frontend_ip_configuration_public
    frontend_port_name             = local.ag_frontend_port_os_db_https_name
    protocol                       = "Https"
    ssl_certificate_name           = local.ag_ssl_cert_name
  }

  #############################################################################
  # Request routing rules and redirects
  redirect_configuration {
    name                 = local.ag_redirect_configuration_ui_http_name
    redirect_type        = "Permanent"
    include_path         = false
    include_query_string = false
    target_listener_name = local.ag_listener_ui_https_name
  }

  request_routing_rule {
    name                        = local.ag_request_routing_rule_ui_http_name
    rule_type                   = "Basic"
    http_listener_name          = local.ag_listener_ui_http_name
    redirect_configuration_name = local.ag_redirect_configuration_ui_http_name
    priority                    = 10000
  }
  request_routing_rule {
    name                       = local.ag_request_routing_rule_ui_https_name
    rule_type                  = "Basic"
    http_listener_name         = local.ag_listener_ui_https_name
    backend_address_pool_name  = local.ag_backend_pool_ui_name
    backend_http_settings_name = local.ag_backend_settings_ui_name
    priority                   = 10010
  }

  request_routing_rule {
    name                       = local.ag_request_routing_rule_os_db_https_name
    rule_type                  = "Basic"
    http_listener_name         = local.ag_listener_os_db_https_name
    backend_address_pool_name  = local.ag_backend_pool_os_db_name
    backend_http_settings_name = local.ag_backend_settings_os_db_name
    priority                   = 10020
  }

  lifecycle {
    ignore_changes = [
      #  backend_address_pool,
      #  backend_http_settings,
      #  frontend_port,
      #  http_listener,
      #  request_routing_rule,
      #  ssl_certificate,
      #  redirect_configuration,
      tags
    ]
  }

  depends_on = [
    # time_sleep.wait_60_seconds,
    azurerm_key_vault_access_policy.kvaccess_aks_identity,
    data.azurerm_key_vault_certificate.frontend_cert
  ]
}