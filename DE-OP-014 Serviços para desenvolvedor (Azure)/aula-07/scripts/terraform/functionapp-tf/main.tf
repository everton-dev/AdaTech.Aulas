resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
}

resource "azurerm_app_service_plan" "asp" {
  name                = "${var.function_app_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = var.service_plan_os
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "function_app" {
  name                       = var.function_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  version                    = var.functions_version
  os_type                    = var.functions_os
  app_settings = {
    "AzureWebJobsStorage"      = azurerm_storage_account.storage.primary_connection_string
    "FUNCTIONS_EXTENSION_VERSION" = var.functions_version
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}