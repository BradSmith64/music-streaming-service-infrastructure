# Installation Guide: Prerequisites for Deployment

Follow these steps to prepare your local machine for provisioning the Azure infrastructure using Terraform.

## 1. Install Terraform
Terraform is the Infrastructure-as-Code tool that will read your `.tf` files and build your Azure resources.

- **Download:** [Official Terraform Downloads](https://developer.hashicorp.com/terraform/install)
- **Windows (Recommended):** Use `choco install terraform` if you have Chocolatey, or download the ZIP, extract `terraform.exe`, and add it to your System PATH.
- **Verify:** Open a terminal and run:
  ```powershell
  terraform -version
  ```

## 2. Install Azure CLI
The Azure CLI allows Terraform to communicate with your Azure account.

- **Download:** [Official Azure CLI Installer](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
- **Verify:** Open a terminal and run:
  ```powershell
  az --version
  ```

## 3. Authenticate with Azure
Before running Terraform, you must log in to your Azure account so it has permission to create resources.

1. Open your terminal.
2. Run the login command:
   ```powershell
   az login
   ```
3. A browser window will open. Sign in with your Azure credentials.
4. Once successful, the terminal will display your subscription details.

## 4. (Optional) Recommended VS Code Extensions
If you are using Visual Studio Code, these extensions make working with Terraform much easier:
- **HashiCorp Terraform:** Provides syntax highlighting and autocompletion.
- **Azure Account:** Helps manage your Azure subscriptions directly from VS Code.

---

### Ready for Next Session?
Once these are installed and you've run `az login`, you are ready to navigate to the `/music_streaming_cloud_architecture` directory and begin the deployment!
