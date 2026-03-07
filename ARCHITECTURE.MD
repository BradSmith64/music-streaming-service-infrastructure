# Azure Infrastructure Mapping

This document maps the local development components of the Music Streaming Service to their corresponding Microsoft Azure services.

## Architecture Overview

| Local Component | Description | Azure Service | Tier |
| :--- | :--- | :--- | :--- |
| **Frontend** | Next.js (React 19) | **Azure Static Web App** | **Free** |
| **Backend API** | .NET 8 (LTS) | **Azure App Service** (Linux) | **Free (F1)** |
| **Database** | SQL Server (Azure SQL Edge) | **Azure SQL Database** | **Free offer** |
| **Blob Storage** | Azure Blob Storage | **Azure Storage Account** | **Standard LRS** |
| **Secrets/Config** | `.env` / `appsettings.json` | **App Service Configuration** | **Standard** |

---

## Detailed Mapping

### 1. Frontend: Next.js Application
- **Directory:** `music_streaming_service_frontend/`
- **Azure Choice:** **Azure Static Web App (SWA)**
- **Status:** **Implemented and Deployed via GitHub Actions.**
- **Reasoning:** Optimized for modern frontend frameworks like Next.js. Provides a managed serverless backend for Server-Side Rendering (SSR) and API routes, while serving static assets from a global CDN. This decouples the frontend quota from the backend App Service Plan.
- **Configuration:** Automatically builds and deploys to Azure on every push to the `main` branch.

### 2. Backend: .NET 8 (LTS) Minimal API
- **Directory:** `music_streaming_service/music-streaming-minimal-api/`
- **Azure Choice:** **Azure App Service (Linux)**
- **Reasoning:** Retargeted to **.NET 8.0** to ensure full compatibility with the Azure App Service Linux **Free (F1) tier** and stable Swashbuckle (Swagger) support.
- **Configuration:** Environment-specific settings managed via App Service Configuration.

### 3. Database: SQL Server
- **Local Environment:** Azure SQL Edge (Docker)
- **Azure Choice:** **Azure SQL Database**
- **Terminology:** In this project, **"Uploading to the database"** refers to operations on the Azure SQL instance in the `rg-music-streaming-poc` resource group.
- **Tier:** **Free offer** (Serverless, General Purpose)
- **Networking:** "Allow Azure services and resources to access this server" enabled to permit communication from the App Services.
- **Reasoning:** Fully managed SQL Server instance for relational data storage and EF Core compatibility.
- **Migrations:** Managed via EF Core CLI using production connection strings.

### 4. Storage: Azure Blob Storage (Song Storage)
- **Terminology:** In this project, **"Song Storage"** refers specifically to the `music` container.
- **Integration:** `music-streaming-infrastructure/internal/adapters/SongStorage_AzureBlobStorage.cs`
- **Azure Choice:** **Azure Storage Account (Blob Storage)**
- **Reasoning:** Durable object storage for music files and media assets.
- **Configuration:** Secured via Shared Access Signatures (SAS) or Storage Account Keys (managed in App Service Config).

### 5. Deployment & CI/CD
- **Source Control:** GitHub
- **Automation:** **GitHub Actions pipelines** for automated build and deployment of both the .NET backend and Next.js frontend to Azure.
- **Infrastructure as Code (IaC):** Terraform scripts provision and manage all Azure resources, including App Services, SQL Database, and Storage Accounts.
- **Terraform Execution Policy:** Before executing any Terraform commands that modify infrastructure (e.g., `terraform apply`), Gemini CLI MUST show the `terraform plan` output and explicitly request user approval.
  - **Plan Archival:** Every plan must be saved in three distinct formats (all using the `.tfplan` extension).
  - No infrastructure changes should be applied without this confirmation.

### 6. Azure Deployment Configuration (Linux App Service)

The Azure App Service is configured via Terraform to support reliable zip deployments of pre-compiled .NET binaries. 

**Key Settings:**
- **`SCM_DO_BUILD_DURING_DEPLOYMENT = false`**: Prevents the server from attempting to rebuild the uploaded zip.
- **`ENABLE_ORYX_BUILD = false`**: Ensures the server uses the binaries provided in the deployment package.

For the step-by-step **"Clean and Deploy"** procedure, please refer to the application-level guide:
**`music-streaming-minimal-api/DEPLOYMENT_GUIDE.md`**
