terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
  }
}

locals {
  resource_suffix = "${var.project}-${var.environment}-${var.location}"
  context_name    = "${var.project}-${var.environment}"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy               = true
      purge_soft_deleted_certificates_on_destroy = true
      purge_soft_deleted_keys_on_destroy         = true
      purge_soft_deleted_secrets_on_destroy      = true
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

data "azurerm_client_config" "main" {}

data "azuread_client_config" "main" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_suffix}"
  location = var.location

  tags = {
    project     = var.project
    environment = var.environment
    location    = var.location
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
