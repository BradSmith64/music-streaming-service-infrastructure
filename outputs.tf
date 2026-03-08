output "backend_url" {
  value = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "frontend_url" {
  value = "https://${azurerm_static_web_app.frontend.default_host_name}"
}

output "static_web_app_api_token" {
  value     = azurerm_static_web_app.frontend.api_key
  sensitive = true
}

output "backend_publish_profile" {
  value     = azurerm_linux_web_app.backend.site_credential
  sensitive = true
}

output "backend_connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "storage_account_name" {
  value = azurerm_storage_account.st.name
}

output "landing_zone_container" {
  value = azurerm_storage_container.landing_zone.name
}

output "function_app_hostname" {
  value = "https://${azurerm_linux_function_app.func.default_hostname}"
}

output "servicebus_connection_string" {
  value     = azurerm_servicebus_namespace.sb.default_primary_connection_string
  sensitive = true
}
