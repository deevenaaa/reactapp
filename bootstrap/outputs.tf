output "storage_account_name" {
  value = azurerm_storage_account.state.name
}
output "storage_resource_group" {
  value = azurerm_resource_group.state.name
}
output "container_name" {
  value = azurerm_storage_container.state.name
}
output "azure_client_id" {
  value = azuread_application_registration.github.client_id
}
output "azure_tenant_id" {
  value = var.tenant_id
}
output "azure_subscription_id" {
  value = var.subscription_id
}
output "github_service_principal_object_id" {
  value = azuread_service_principal.github.object_id
}