locals {
  private_dns_zones = {
    registry = "privatelink.azurecr.io"
    vault    = "privatelink.vaultcore.azure.net"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.address_space]
}

resource "azurerm_subnet" "gateway" {
  name                 = "snet-agw"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 2, 0)]
}

resource "azurerm_subnet" "cluster_system_node_pool" {
  name                 = "snet-aks-sys"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 2, 1)]
}

resource "azurerm_subnet" "cluster_user_node_pool" {
  name                 = "snet-aks-usr"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [cidrsubnet(var.address_space, 2, 2)]
}

resource "azurerm_subnet" "private_endpoints" {
  name                                           = "snet-svc"
  virtual_network_name                           = azurerm_virtual_network.main.name
  resource_group_name                            = azurerm_resource_group.main.name
  address_prefixes                               = [cidrsubnet(var.address_space, 2, 3)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-${local.resource_suffix}-agw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                         = "AllowInternetIn"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_ranges      = ["80", "443"]
    source_address_prefix        = "Internet"
    destination_address_prefixes = azurerm_subnet.gateway.address_prefixes
  }

  security_rule {
    name                       = "AllowGatewayManagerIn"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerIn"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  network_security_group_id = azurerm_network_security_group.gateway.id
  subnet_id                 = azurerm_subnet.gateway.id
}

resource "azurerm_private_dns_zone" "main" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = local.private_dns_zones
  name                  = azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.main.id

  depends_on = [
    azurerm_private_dns_zone.main
  ]
}
