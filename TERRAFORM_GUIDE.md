# Terraform Infrastructure Guide

This directory contains the Infrastructure-as-Code (IaC) files required to provision the Azure environment for the Music Streaming Service.

## File Breakdown

### 1. `provider.tf`
**Purpose:** Configures the Terraform "Providers"—the plugins that interact with remote services.
- **Content:** It specifies that we are using the `azurerm` provider (Azure Resource Manager) and sets the required version.

### 2. `variables.tf`
**Purpose:** Defines the input variables that allow the configuration to be flexible and reusable.
- **Content:** Includes definitions for the resource group name, Azure location (e.g., "West Europe"), SQL administrator credentials, and tags. Marking the `sql_admin_password` as `sensitive` ensures it is masked in CLI output.

### 3. `main.tf`
**Purpose:** The primary configuration file where the Azure resources are defined.
- **Content:** 
  - **Resource Group:** A container for all related resources.
  - **Random ID:** Generates a unique suffix for resource names to avoid global naming conflicts (e.g., storage account names).
  - **Storage Account & Container:** Provisions Azure Blob Storage for music files.
  - **SQL Server & Database:** Sets up the backend database for song metadata and likes.
  - **App Service Plan:** Defines the compute resources (Linux F1 - Free) for the backend API.
  - **Backend Web App:** A Linux App Service configured for **.NET 8**.
  - **Frontend Static Web App:** An **Azure Static Web App (SWA)** for the Next.js frontend.

### 4. `outputs.tf`
**Purpose:** Defines the information that Terraform should display once the infrastructure is successfully provisioned.
- **Content:** Outputs the backend and frontend URLs, the SQL server hostname, the storage account name, and the **Static Web App deployment token**. This information is critical for the application deployment phase.

### 5. `terraform.tfvars.template`
**Purpose:** A template for providing actual values for the variables defined in `variables.tf`.
- **Note:** Users should copy this to `terraform.tfvars` (which is typically git-ignored) to provide their specific secrets, like the SQL admin password, without committing them to source control.

## End-to-End File Interaction

Here is how these files work together to build your environment:

1.  **The Inputs (`variables.tf` & `terraform.tfvars`):** Your configuration starts with these. `variables.tf` defines the "contract" (what data is needed), and your `terraform.tfvars` provides the actual values (like your SQL password).
2.  **The Engine (`provider.tf`):** Terraform uses this to download the AzureRM plugin, which translates your code into Azure API calls.
3.  **The Blueprint (`main.tf`):** This is the heart of the system. It uses a **Dependency Chain** to ensure resources are built in the correct order:
    *   It creates the **Resource Group** first.
    *   It generates a **Random ID** to ensure globally unique names for storage and web apps.
    *   It provisions the **SQL Server**, **Database**, and **Storage Account**.
    *   It "wires" the **Backend App** by automatically injecting the SQL connection string and Storage keys into its App Settings.
    *   It configures the **Frontend Static Web App** by injecting the Backend's URL into its `app_settings` for server-side use.
4.  **The Feedback (`outputs.tf`):** After provisioning, Terraform pulls the live URLs and connection strings from the created resources and prints them to your terminal for use in your deployment steps.
5.  **The Memory (`terraform.tfstate`):** Automatically created after a successful run, this file maps your code to the real-world Azure resource IDs.

## Authentication with Service Principal

To authenticate with Azure using a Service Principal (recommended for CI/CD and automation), you have two primary methods. A Service Principal is essentially a "robot user" that Terraform uses to manage your Azure resources.

### 1. Create the Service Principal (Azure CLI)
The fastest way to create a Service Principal with the necessary permissions is using the Azure CLI:

```powershell
# 1. Login to Azure
az login

# 2. Get your Subscription ID
az account show --query id -o tsv

# 3. Create the Service Principal with 'Contributor' access
az ad sp create-for-rbac --name "music-streaming-terraform" --role Contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

**Important:** The output will contain a `password` (your Client Secret). **Save this immediately**, as you cannot retrieve it later.

### 2. Find IDs in the Azure Portal
If you prefer the browser or need to find existing IDs:

1.  **Application (Client) ID & Tenant ID:**
    *   Go to **Microsoft Entra ID** (formerly Azure AD) > **App registrations**.
    *   Select your application (e.g., "music-streaming-terraform").
    *   Copy the **Application (client) ID** and **Directory (tenant) ID**.
2.  **Client Secret:**
    *   In your App registration, go to **Certificates & secrets** > **Client secrets**.
    *   Click **+ New client secret**. Copy the **Value** (not the Secret ID).
3.  **Permissions:**
    *   Go to **Subscriptions** > Select your subscription > **Access control (IAM)**.
    *   Ensure your Service Principal is listed with the **Contributor** role.

### 3. Mapping to Terraform
Once you have the IDs, map them to your `terraform.tfvars` or environment variables:

| Terraform Variable | Azure CLI Field | Azure Portal Location |
| :--- | :--- | :--- |
| `azure_client_id` | `appId` | Application (client) ID |
| `azure_client_secret` | `password` | Client Secret **Value** |
| `azure_tenant_id` | `tenant` | Directory (tenant) ID |
| `azure_subscription_id` | `N/A` | Subscription ID |

### Method 1: Environment Variables (Recommended for CI/CD)
Terraform's AzureRM provider automatically looks for specific environment variables. This is the most secure method because it doesn't require hardcoding credentials in any files.

Set these variables in your shell:

- `ARM_CLIENT_ID`: Your Service Principal Application ID.
- `ARM_CLIENT_SECRET`: Your Service Principal Secret.
- `ARM_SUBSCRIPTION_ID`: Your Azure Subscription ID.
- `ARM_TENANT_ID`: Your Azure Tenant ID.

### Method 2: Terraform Variables (`terraform.tfvars`)
If you prefer to define credentials explicitly in your configuration, use the variables added to `variables.tf`.

1.  Copy `terraform.tfvars.template` to `terraform.tfvars`.
2.  Fill in the `azure_subscription_id`, `azure_client_id`, `azure_client_secret`, and `azure_tenant_id` fields.

> **Warning:** Never commit your `terraform.tfvars` file to source control as it contains sensitive credentials.

## Basic Workflow

1.  **Initialize:** `terraform init` (Downloads the Azure provider).
2.  **Plan and Archival:** Generate timestamped plans in three formats for review and execution (all using the `.tfplan` extension):
    ```powershell
    $timestamp = Get-Date -Format "ddMMyyyy_HHmmss"
    # Binary plan for execution
    terraform plan -out="tfplan_$timestamp.binary.tfplan"
    # ANSI color plan for VS Code preview
    terraform show "tfplan_$timestamp.binary.tfplan" | Out-File -FilePath "tfplan_$timestamp.tfplan" -Encoding utf8
    # Clean plain text plan for general reading
    terraform show -no-color "tfplan_$timestamp.binary.tfplan" | Out-File -FilePath "tfplan_$timestamp_READABLE.tfplan" -Encoding utf8
    ```
3.  **Review and Approval:** Review the generated `.tfplan` files (use **'ANSI Text: Open Preview'** in VS Code for colors) and explicitly approve the changes.
4.  **Apply:** Apply the approved **binary** plan file:
    ```bash
    terraform apply "tfplan_ddMMyyyy_HHmmss.binary.tfplan"
    ```
5.  **Destroy:** `terraform destroy` (Deletes all resources managed by this configuration).

## Source Control Best Practices

To keep your infrastructure secure and your repository clean, follow these guidelines for Git:

### ✅ What to Commit
- **`*.tf` files**: `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`. These define your architecture.
- **`terraform.tfvars.template`**: A safe template for others to follow.
- **`TERRAFORM_GUIDE.md`**: Documentation for the team.

### ❌ What NOT to Commit
- **`.terraform/` folder**: This contains local provider binaries and can be regenerated with `terraform init`.
- **`terraform.tfstate` and `terraform.tfstate.backup`**: These contain the "truth" about your infrastructure and often include sensitive data in plain text. (Use a remote backend like Azure Blob Storage for team collaboration).
- **`terraform.tfvars`**: This file contains your actual secrets (passwords, keys).
- **`.terraform.lock.hcl`**: (Optional) While some teams commit this to lock provider versions, it can sometimes cause issues in mixed OS environments.
