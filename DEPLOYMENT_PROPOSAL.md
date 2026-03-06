# Deployment Proposal: Music Streaming Service

This document outlines the strategy for provisioning a new Azure environment using Terraform and deploying the Music Streaming Service ( .NET 10 Backend & Next.js Frontend).

## 1. Infrastructure Architecture

The new infrastructure is defined in the `/music_streaming_cloud_architecture` directory using Terraform. It includes:

- **Resource Group**: A dedicated container for all project resources.
- **Azure SQL Database**: Hosted on an Azure SQL Server, using the **Serverless General Purpose** tier (aligns with the Azure Free Offer).
- **Azure Blob Storage**: A storage account with a `music` container for song assets (**Standard LRS**).
- **Azure App Service (Linux) - Backend**: Configured for .NET 10 to host the Minimal API (**Free F1 tier**).
- **Azure App Service (Linux) - Frontend**: Configured for Node.js (20 LTS) to host the Next.js application (**Free F1 tier**).
- **App Service Plan**: A shared Linux **Free (F1)** plan for zero-cost hosting during POC/Development.

## 2. Infrastructure Provisioning

### Prerequisites
- Terraform installed locally.
- Azure CLI installed and authenticated (`az login`).
- .NET 10 SDK and Node.js installed.

### Steps
1. Navigate to the infrastructure directory: `cd music_streaming_cloud_architecture`
2. Create your secrets file: `cp terraform.tfvars.template terraform.tfvars`
3. Edit `terraform.tfvars` and set a secure `sql_admin_password`.
4. Initialize and apply:
   ```powershell
   terraform init
   terraform apply
   ```

## 3. Application Deployment

### Backend (.NET 10)
1. Get the connection string from Terraform:
   ```powershell
   $conn = terraform output -raw backend_connection_string
   ```
2. Apply Entity Framework migrations to the Azure SQL Database:
   ```powershell
   dotnet ef database update --project ..\music_streaming_service\music-streaming-infrastructure --startup-project ..\music_streaming_service\music-streaming-minimal-api --connection "$conn"
   ```
3. Seed the database (using `seed.sql` via Azure Data Studio or `sqlcmd`).
4. Publish and deploy the Web App:
   ```powershell
   dotnet publish ..\music_streaming_service\music-streaming-minimal-api -c Release -o ./publish
   # Deploy via Azure CLI or Zip Deploy
   az webapp deployment source config-zip --resource-group rg-music-streaming-poc --name app-api-xxxx --src ./publish.zip
   ```

### Frontend (Next.js)
1. Build the frontend locally, ensuring the `NEXT_PUBLIC_ENV_URL` points to the new backend URL.
2. Deploy the build artifacts to the Frontend App Service.
   *Note: For Next.js on App Service, it is recommended to use the Standalone output mode or a custom start command (`npm run start`).*

### Data (Music Files)
1. Upload your `.mp3` or `.wav` files to the `music` container in the newly created Azure Storage Account. Ensure filenames match those in `seed.sql` (e.g., `sample1.mp3`).

## 4. Cleanup of Old Infrastructure

Once the new environment is verified, delete the old resource group to avoid unnecessary costs:
```powershell
az group delete --name <OLD_RESOURCE_GROUP_NAME> --yes --no-wait
```
