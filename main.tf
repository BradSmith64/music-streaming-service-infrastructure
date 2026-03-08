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

resource "azurerm_storage_container" "landing_zone" {
  name                  = "songs-landing-zone"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_servicebus_namespace" "sb" {
  name                = "sb-music-${random_id.id.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "uploads" {
  name         = "song-uploaded"
  namespace_id = azurerm_servicebus_namespace.sb.id
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
  max_size_gb    = 32 # General Purpose starts at 32GB
  auto_pause_delay_in_minutes = 30 # Minimum pause delay
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

  app_settings = {
    "ConnectionStrings__DefaultConnection" = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "SongStorage__AccountName"             = azurerm_storage_account.st.name
    "SongStorage__AccountKey"              = azurerm_storage_account.st.primary_access_key
    "SongStorage__ContainerName"           = azurerm_storage_container.music.name
    "SongStorage__ExpiryMinutes"           = "60"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"       = "false"
    "ENABLE_ORYX_BUILD"                    = "false"
    "ASPNETCORE_ENVIRONMENT"               = "Development" # Enable Swagger for POC
  }

  site_config {
    application_stack {
      dotnet_version = "8.0" 
    }
    always_on = false # F1 does not support always_on
    cors {
      allowed_origins = ["*"]
      support_credentials = false
    }
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

resource "azurerm_resource_group" "rg_func" {
  name     = "${var.resource_group_name}-func"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-music-${random_id.id.hex}"
  location            = azurerm_resource_group.rg_func.location
  resource_group_name = azurerm_resource_group.rg_func.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "ai" {
  name                = "ai-music-${random_id.id.hex}"
  location            = azurerm_resource_group.rg_func.location
  resource_group_name = azurerm_resource_group.rg_func.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = var.tags
}

resource "azurerm_service_plan" "func_asp" {
  name                = "asp-func-music-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg_func.name
  location            = azurerm_resource_group.rg_func.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption Plan (Free tier)
  tags                = var.tags
}

resource "azurerm_linux_function_app" "func" {
  name                = "func-music-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg_func.name
  location            = azurerm_resource_group.rg_func.location

  storage_account_name       = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  service_plan_id            = azurerm_service_plan.func_asp.id

  site_config {
    application_stack {
      dotnet_version = "8.0" # Matches the backend API
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai.connection_string
    "ConnectionStrings__DefaultConnection"    = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "ServiceBus__ConnectionString"           = azurerm_servicebus_namespace.sb.default_primary_connection_string
    "SongStorage__AccountName"                = azurerm_storage_account.st.name
    "SongStorage__AccountKey"                 = azurerm_storage_account.st.primary_access_key
    "SongStorage__MusicContainer"             = azurerm_storage_container.music.name
    "SongStorage__LandingZoneContainer"       = azurerm_storage_container.landing_zone.name
    "AzureWebJobsStorage"                     = azurerm_storage_account.st.primary_connection_string
  }

  tags = var.tags
}

resource "azurerm_eventgrid_system_topic" "st_topic" {
  name                   = "evgt-storage-music-${random_id.id.hex}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_storage_account.st.location
  source_arm_resource_id = azurerm_storage_account.st.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  tags                   = var.tags
}

resource "azurerm_eventgrid_system_topic_event_subscription" "st_sub" {
  count               = var.enable_event_grid_subscription ? 1 : 0
  name                = "evgs-song-uploaded"
  system_topic        = azurerm_eventgrid_system_topic.st_topic.name
  resource_group_name = azurerm_resource_group.rg.name

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.func.id}/functions/SongUploadBroker"
    max_events_per_batch = 1
    preferred_batch_size_in_kilobytes = 64
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${azurerm_storage_container.landing_zone.name}/blobs/"
  }
}

# --- GitHub Secrets Automation ---

resource "github_actions_secret" "frontend_swa_token" {
  repository      = var.github_frontend_repo
  secret_name     = "AZURE_STATIC_WEB_APPS_API_TOKEN"
  plaintext_value = azurerm_static_web_app.frontend.api_key
}

# Backend Secret (Example: Constructing Secret for App Service)
# Note: For full automation, consider using a Service Principal for backend deployment
resource "github_actions_secret" "backend_app_name" {
  repository      = var.github_backend_repo
  secret_name     = "AZURE_WEBAPP_NAME"
  plaintext_value = azurerm_linux_web_app.backend.name
}

resource "github_actions_secret" "backend_client_id" {
  repository      = var.github_backend_repo
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = var.azure_client_id
}

resource "github_actions_secret" "backend_client_secret" {
  repository      = var.github_backend_repo
  secret_name     = "AZURE_CLIENT_SECRET"
  plaintext_value = var.azure_client_secret
}

resource "github_actions_secret" "backend_tenant_id" {
  repository      = var.github_backend_repo
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = var.azure_tenant_id
}

resource "github_actions_secret" "backend_subscription_id" {
  repository      = var.github_backend_repo
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = var.azure_subscription_id
}

resource "github_actions_secret" "frontend_backend_url" {
  repository      = var.github_frontend_repo
  secret_name     = "BACKEND_API_URL"
  plaintext_value = "https://${azurerm_linux_web_app.backend.default_hostname}"
}
