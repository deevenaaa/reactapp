terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
# Uses your existing Azure CLI login.
provider "azuread" {
  tenant_id = var.tenant_id
}
resource "random_string" "storage_suffix" {
  length  = 6
  upper   = false
  special = false
}
# Separate resource group for Terraform state.
resource "azurerm_resource_group" "state" {
  name     = "reactapp-tfstate-rg"
  location = "koreacentral"
}
# Persistent remote state storage.
resource "azurerm_storage_account" "state" {
  name                            = "reactapptfstate${random_string.storage_suffix.result}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  blob_properties {
    versioning_enabled = true
  }
}
resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
# Register the GitHub Actions application.
resource "azuread_application_registration" "github" {
  display_name     = "github-reactapp-terraform"
  sign_in_audience = "AzureADMyOrg"
}
# Create the service principal.
resource "azuread_service_principal" "github" {
  client_id = azuread_application_registration.github.client_id
}
# Trust only the main branch of your GitHub repository.
resource "azuread_application_federated_identity_credential" "github_main" {
  application_id = azuread_application_registration.github.id
  display_name   = "github-main-branch"
  description    = "GitHub Actions production deployment"
  audiences = [
    "api://AzureADTokenExchange"
  ]
  issuer  = "https://token.actions.githubusercontent.com"
  subject = "repo:${var.github_repository}:ref:refs/heads/main"
}
# Allow GitHub Actions to manage application infrastructure.
resource "azurerm_role_assignment" "github_contributor" {
  scope                            = "/subscriptions/${var.subscription_id}"
  role_definition_name             = "Contributor"
  principal_id                     = azuread_service_principal.github.object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
# Give GitHub Actions access to the Terraform state.
resource "azurerm_role_assignment" "github_storage" {
  scope                            = azurerm_storage_account.state.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azuread_service_principal.github.object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
# Allow your local Azure CLI identity to migrate Terraform state.
data "azurerm_client_config" "current" {}
resource "azurerm_role_assignment" "local_storage" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}