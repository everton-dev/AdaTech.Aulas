output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "function_app_name" {
  value = azurerm_function_app.function_app.name
}