output "client_id" {
  value = azuread_application.main.application_id
}

output "registry_name" {
  value = azurerm_container_registry.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_tenant_id" {
  value = azurerm_key_vault.main.tenant_id
}

output "backend_address_pool_ip_address" {
  value = local.backend_address_pool_ip_address
}
