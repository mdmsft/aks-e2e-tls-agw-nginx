resource "azurerm_container_registry" "main" {
  name                   = "cr${var.project}${var.environment}${var.region}"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  admin_enabled          = false
  anonymous_pull_enabled = false
  sku                    = "Premium"
}

resource "azurerm_private_endpoint" "registry" {
  name                = "pe-${local.resource_suffix}-cr"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_dns_zone_group {
    name                 = local.private_dns_zones.registry
    private_dns_zone_ids = [azurerm_private_dns_zone.main["registry"].id]
  }

  private_service_connection {
    name                           = azurerm_container_registry.main.name
    is_manual_connection           = false
    subresource_names              = ["registry"]
    private_connection_resource_id = azurerm_container_registry.main.id
  }
}
