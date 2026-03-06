# Azure Infrastructure Mapping

This document maps the local development components of the Music Streaming Service to their corresponding Microsoft Azure services.

## Architecture Overview

| Local Component | Description | Azure Service | Tier |
| :--- | :--- | :--- | :--- |
| **Frontend** | Next.js (React 19) | **Azure App Service** (Linux) | **Free (F1)** |
| **Backend API** | .NET 10 Minimal API | **Azure App Service** (Linux) | **Free (F1)** |
| **Database** | SQL Server (Azure SQL Edge) | **Azure SQL Database** | **Free offer** |
| **Blob Storage** | Azure Blob Storage | **Azure Storage Account** | **Standard LRS** |
| **Secrets/Config** | `.env` / `appsettings.json` | **App Service Configuration** | **Standard** |

---

## Detailed Mapping

### 1. Frontend: Next.js Application
- **Directory:** `music_streaming_service_frontend/`
- **Azure Choice:** **Azure App Service (Linux)**
- **Status:** Pending creation and deployment.
- **Reasoning:** Supports full Next.js features, including Server-Side Rendering (SSR) and dynamic routing.
- **Configuration:** `NEXT_PUBLIC_ENV_URL` maps to the backend API endpoint.

### 2. Backend: .NET 10 Minimal API
- **Directory:** `music_streaming_service/music-streaming-minimal-api/`
- **Azure Choice:** **Azure App Service (Linux)**
- **Reasoning:** Managed hosting for .NET workloads with native support for SQL Server and App Service Configuration.
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
- **Automation:** GitHub Actions pipelines (planned) for automated build and deployment of both the .NET backend and Next.js frontend to Azure App Services.
- **Infrastructure as Code (IaC):** Terraform scripts to automatically provision and manage all Azure resources, including App Services, SQL Database, and Storage Accounts. (Azure Key Vault planned for future secret management).
- **Terraform Execution Policy:** Before executing any Terraform commands that modify infrastructure (e.g., `terraform apply`), Gemini CLI MUST show the `terraform plan` output and explicitly request user approval.
  - **Plan Archival:** Every plan must be saved in three distinct formats (all using the `.tfplan` extension):
    - `tfplan_ddMMyyyy_HHmmss.binary.tfplan`: Binary format for execution via `terraform apply`.
    - `tfplan_ddMMyyyy_HHmmss.tfplan`: Plain text with ANSI color codes (best viewed in VS Code via the 'ANSI Text: Open Preview' command).
    - `tfplan_ddMMyyyy_HHmmss_READABLE.tfplan`: Clean plain text (no colors) for maximum compatibility with any text editor.
  - No infrastructure changes should be applied without this confirmation.
