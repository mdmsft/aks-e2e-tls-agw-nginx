resource "azuread_application" "main" {
  display_name = "app-${local.resource_suffix}"
  owners       = [data.azuread_client_config.main.object_id]
}

resource "azuread_service_principal" "main" {
  application_id               = azuread_application.main.application_id
  owners                       = [data.azuread_client_config.main.object_id]
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "main" {
  application_object_id = azuread_application.main.id
  display_name          = "aks-${local.resource_suffix}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject               = "system:serviceaccount:default:default"
}
