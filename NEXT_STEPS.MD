# Next Steps: Infrastructure & Deployment

This document outlines the roadmap for setting up Terraform and GitHub Actions for the Music Streaming Service.

## 1. Terraform Setup (Infrastructure as Code)
- **Installation & Basics:** Guide through Terraform CLI installation and setting up the Azure provider (`azurerm`).
- **Resource Definition:** Create `.tf` files to provision:
    - Azure App Service (Linux) for the .NET Backend.
    - Azure App Service (Linux) for the Next.js Frontend (SSR support).
    - Azure SQL Database (Free offer).
    - Azure Storage Account (Blob Storage).
- **State Management:** Configure local or remote state to track infrastructure changes safely.

## 2. GitHub Actions Pipelines (CI/CD)
- **Azure Authentication:** Use Azure CLI to create a Service Principal or configure OIDC for secure communication between GitHub and Azure.
- **Backend Workflow:**
    - Restore, build, and publish the .NET 10 API.
    - Deploy the artifact to the Backend App Service.
- **Frontend Workflow:**
    - Install dependencies and build the Next.js application.
    - Deploy the build to the Frontend App Service, ensuring SSR is correctly configured.
- **Secrets Management:** Securely store Azure credentials and connection strings in GitHub Actions Secrets.

## 3. Deployment Validation
- Verify the API is reachable and the database migrations are applied.
- Confirm the Next.js frontend is correctly communicating with the backend API via the `NEXT_PUBLIC_ENV_URL`.
