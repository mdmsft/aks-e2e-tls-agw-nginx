resource "azurerm_key_vault" "main" {
  name                       = substr("kv-${var.project}-${var.environment}-${var.region}", 0, 24)
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  enable_rbac_authorization  = true
  sku_name                   = "standard"
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
}

resource "azurerm_role_assignment" "key_vault_administrator" {
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.main.id
  principal_id         = data.azurerm_client_config.main.object_id
}

resource "azurerm_key_vault_certificate" "main" {
  name         = var.project
  key_vault_id = azurerm_key_vault.main.id

  certificate {
    contents = filebase64("./tls.pfx")
  }

  depends_on = [
    azurerm_role_assignment.key_vault_administrator
  ]
}

resource "azurerm_role_assignment" "application_key_vault_secrets_user" {
  role_definition_name = "Key Vault Secrets User"
  scope                = "/subscriptions/${data.azurerm_client_config.main.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}/providers/Microsoft.KeyVault/vaults/${azurerm_key_vault.main.name}/secrets/${azurerm_key_vault_certificate.main.name}"
  principal_id         = azuread_service_principal.main.object_id
}

resource "azurerm_private_endpoint" "vault" {
  name                = "pe-${local.resource_suffix}-kv"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = local.private_dns_zones.vault
    private_dns_zone_ids = [azurerm_private_dns_zone.main["vault"].id]
  }

  private_service_connection {
    name                           = azurerm_key_vault.main.name
    is_manual_connection           = false
    subresource_names              = ["vault"]
    private_connection_resource_id = azurerm_key_vault.main.id
  }
}
