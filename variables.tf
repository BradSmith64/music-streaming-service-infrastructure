variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-music-streaming-poc"
}

variable "location" {
  description = "Location of the resources"
  type        = string
  default     = "West Europe"
}

variable "sql_admin_username" {
  description = "Admin username for the SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "Admin password for the SQL Server"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "azure_client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "azure_client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
  default     = null
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
  default     = null
}

variable "github_backend_repo" {
  description = "Name of the backend GitHub repository"
  type        = string
  default     = "music-streaming-service"
}

variable "github_frontend_repo" {
  description = "Name of the frontend GitHub repository"
  type        = string
  default     = "music-streaming-service-frontend"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Environment = "POC"
    Project     = "MusicStreaming"
    Owner       = "Brad"
  }
}

variable "enable_event_grid_subscription" {
  description = "Set to true only AFTER the Function App code has been deployed (to allow for handshake validation)."
  type        = bool
  default     = false
}
