locals {
  backend_address_pool_ip_address = cidrhost(azurerm_subnet.cluster_system_node_pool.address_prefixes[0], 254)
  ssl_certificate_name            = azurerm_key_vault_certificate.main.name
  host_name                       = "${var.project}.${local.dns_zone_name}"
}

resource "azurerm_public_ip" "gateway" {
  name                = "pip-${local.resource_suffix}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.context_name
}

resource "azurerm_user_assigned_identity" "gateway" {
  name                = "id-${local.resource_suffix}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "gateway_key_vault_secrets_user" {
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gateway.principal_id
  scope                = "/subscriptions/${data.azurerm_client_config.main.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.KeyVault/vaults/${azurerm_key_vault.main.name}/secrets/${azurerm_key_vault_certificate.main.name}"
}

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "waf-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
    request_body_check          = true
  }
}

resource "azurerm_application_gateway" "main" {
  depends_on = [
    azurerm_role_assignment.gateway_key_vault_secrets_user
  ]
  name                = "agw-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.main.id
  enable_http2        = true

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gateway.id]
  }

  autoscale_configuration {
    min_capacity = var.application_gateway_min_capacity
    max_capacity = var.application_gateway_max_capacity
  }

  backend_address_pool {
    name         = "default"
    ip_addresses = [local.backend_address_pool_ip_address]
  }

  backend_http_settings {
    name                  = "default"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    probe_name            = "default"
  }

  frontend_ip_configuration {
    name                 = "default"
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  gateway_ip_configuration {
    name      = "default"
    subnet_id = azurerm_subnet.gateway.id
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "default"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = local.host_name
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = "default"
    frontend_port_name             = "https"
    protocol                       = "Https"
    host_name                      = local.host_name
    require_sni                    = true
    ssl_certificate_name           = local.ssl_certificate_name
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  request_routing_rule {
    name                        = "http"
    rule_type                   = "Basic"
    http_listener_name          = "http"
    redirect_configuration_name = "default"
    priority                    = 2
  }

  request_routing_rule {
    name                       = "https"
    rule_type                  = "Basic"
    http_listener_name         = "https"
    backend_address_pool_name  = "default"
    backend_http_settings_name = "default"
    priority                   = 1
  }

  probe {
    name                = "default"
    host                = local.host_name
    interval            = 30
    protocol            = "Https"
    path                = "/healthz"
    timeout             = 3
    unhealthy_threshold = 3
  }

  redirect_configuration {
    name                 = "default"
    include_path         = true
    include_query_string = true
    redirect_type        = "Permanent"
    target_listener_name = "https"
  }

  ssl_certificate {
    key_vault_secret_id = azurerm_key_vault_certificate.main.versionless_secret_id
    name                = local.ssl_certificate_name
  }
}
