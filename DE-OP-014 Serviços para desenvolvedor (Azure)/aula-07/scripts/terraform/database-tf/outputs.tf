output "sql_server_name" {
  value = azurerm_mssql_server.sql_server.name
}

output "sql_database_name" {
  value = azurerm_mssql_database.sql_db.name
}

output "firewall_rule_name" {
  value = azurerm_mssql_firewall_rule.firewall_rule.name
}