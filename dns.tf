locals {
  dns_zone_name                = split("/", var.dns_zone_id)[8]
  dns_zone_resource_group_name = split("/", var.dns_zone_id)[4]
}

data "azurerm_dns_zone" "main" {
  name                = local.dns_zone_name
  resource_group_name = local.dns_zone_resource_group_name
}

resource "azurerm_dns_a_record" "main" {
  name                = var.project
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_dns_zone.main.resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_public_ip.gateway.id
}
