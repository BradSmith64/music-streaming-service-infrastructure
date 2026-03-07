resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "random_id" "id" {
  keepers = {
    # Increment this value to force a resource reset (and fresh quota)
    reset_trigger = "2"
  }
  byte_length = 4
}

resource "azurerm_storage_account" "st" {
  name                     = "music${lower(random_id.id.hex)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "music" {
  name                  = "music"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_mssql_server" "sql" {
  name                         = "sql-music-${random_id.id.hex}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  tags                         = var.tags
}

resource "azurerm_mssql_database" "db" {
  name           = "music-streaming-db"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = "GP_S_Gen5_1" # General Purpose Serverless
  min_capacity   = 0.5
  auto_pause_delay_in_minutes = 60 # Pause after 1 hour of inactivity
  tags           = var.tags
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-music-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1" # Free Tier
  tags                = var.tags
}

resource "azurerm_linux_web_app" "backend" {
  name                = "app-api-music-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      dotnet_version = "8.0" 
    }
    always_on = false # F1 does not support always_on
  }

  app_settings = {
    "ConnectionStrings__DefaultConnection" = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "SongStorage__AccountName"             = azurerm_storage_account.st.name
    "SongStorage__AccountKey"              = azurerm_storage_account.st.primary_access_key
    "SongStorage__ContainerName"           = azurerm_storage_container.music.name
    "SongStorage__ExpiryMinutes"           = "60"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"       = "false"
    "ENABLE_ORYX_BUILD"                    = "false"
  }

  tags = var.tags
}

resource "azurerm_static_web_app" "frontend" {
  name                = "stapp-music-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West Europe" # SWA is available in West Europe
  sku_tier            = "Free"
  sku_size            = "Free"

  app_settings = {
    "BACKEND_API_URL" = "https://${azurerm_linux_web_app.backend.default_hostname}"
  }

  tags = var.tags
}
