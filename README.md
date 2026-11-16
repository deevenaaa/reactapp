# React Application – Automated Azure Infrastructure & CI/CD

![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-blue)

![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)

![Docker](https://img.shields.io/badge/Container-Docker-blue)

![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-black)

![Deployment](https://img.shields.io/badge/Deployment-Azure%20Linux%20VM-success)

## 1. Project Overview

This project implements an automated CI/CD and Infrastructure as Code (IaC) solution for deploying a React application to an Azure Linux Virtual Machine.

The infrastructure is provisioned using Terraform, Docker images are built and published to Docker Hub, and GitHub Actions automates the application deployment.

The project also includes a separate Terraform bootstrap setup that creates the Azure resources required for remote Terraform state management and GitHub Actions authentication.

The deployment process is designed to be repeatable, secure, and recoverable.

### Key Features

- Automated React application testing and production builds.

- Docker image creation and publishing to Docker Hub.

- Azure infrastructure provisioning using Terraform.

- Azure Blob Storage for remote Terraform state.

- GitHub Actions authentication using OpenID Connect (OIDC).

- Automated Azure Linux VM configuration and application deployment.

- Docker container health verification.

- Terraform plan review and destructive-change protection.

- Separate bootstrap and application infrastructure configurations.

---

## 2. Architecture

```text

                 Developer

                     |

                     |

                GitHub Push

                     |

                     v

             GitHub Repository

                     |

                     v

              GitHub Actions

                     |

          +----------+----------+

          |                     |

          v                     v

      CI Pipeline          Docker Pipeline

          |                     |

     npm install                |

     npm test                   |

     npm build                  |

          |                     |

          |                     v

          |                Docker Build

          |                     |

          |                     v

          |                Docker Hub

          |                     |

          v                     |

    Terraform Pipeline          |

          |                     |

          v                     |

      Azure OIDC Login          |

          |                     |

          v                     |

     Terraform Init             |

          |                     |

          v                     |

    Azure Blob State             |

          |                     |

          v                     |

    Terraform Plan              |

          |                     |

          v                     |

    Safety Validation           |

          |                     |

          v                     |

    Terraform Apply              |

          |                     |

          +----------+----------+

                     |

                     v

               Azure VM

                     |

                     v

             Docker Image Pull

                     |

                     v

             React Application

                     |

                     v

              HTTP Port 80

```

### Infrastructure Components

| Component | Purpose |

|---|---|

| Azure Resource Group | Organizes project infrastructure |

| Azure Storage Account | Stores remote Terraform state |

| Azure Blob Container | Holds the Terraform state file |

| Microsoft Entra ID | Manages application identity |

| Federated Identity Credential | Enables GitHub OIDC authentication |

| Azure Virtual Network | Provides VM networking |

| Network Security Group | Controls network traffic |

| Azure Linux VM | Hosts the React application |

| Docker Hub | Stores application images |

| GitHub Actions | Automates CI/CD |

---

## 3. Repository Structure

```text

reactapp/

│

├── bootstrap/

│   ├── main.tf

│   ├── variables.tf

│   ├── outputs.tf

│   └── terraform.tfvars

│

├── terraform/

│   ├── main.tf

│   ├── variables.tf

│   ├── outputs.tf

│   ├── backend.tf

│   ├── backend.hcl

│   └── .terraform.lock.hcl

│

├── .github/

│   └── workflows/

│       └── main-cd.yml

│

├── public/

├── src/

├── Dockerfile

├── .dockerignore

├── package.json

├── package-lock.json

├── README.md

└── .gitignore

```

**Important:** `terraform.tfvars` must not be committed if it contains sensitive information. The example above shows the local bootstrap configuration; use `terraform.tfvars.example` in Git instead.

---

# 4. Prerequisites

Install the following tools on your local machine:

| Tool | Purpose |

|---|---|

| Git | Source code management |

| Node.js 24 | React application |

| Docker Desktop | Container development |

| Azure CLI | Azure authentication |

| Terraform | Infrastructure provisioning |

| VS Code | Development environment |

Verify installations:

```powershell

git --version

node --version

npm --version

docker --version

az version

terraform version

```

You also need:

- An active Azure subscription.

- An Azure account with permission to create resources and configure Microsoft Entra applications and role assignments.

- A GitHub repository.

- A Docker Hub account.

- An SSH key pair for the Azure VM.

---

# 5. Step 1 – Clone the Repository

```powershell

git clone https://github.com/deevenaa/reactapp.git

cd reactapp

```

Install application dependencies:

```powershell

npm ci

```

Run tests:

```powershell

npm test -- --watchAll=false

```

Build the React application:

```powershell

npm run build

```

---

# 6. Step 2 – Bootstrap Azure Infrastructure

The bootstrap configuration must run before the main Terraform infrastructure configuration.

Its responsibility is to create the resources required for Terraform remote state and GitHub Actions authentication.

### Resources created by bootstrap

1. Terraform state Resource Group.

2. Azure Storage Account.

3. Private Blob Storage Container.

4. Microsoft Entra application registration.

5. Service principal.

6. GitHub OIDC federated identity credential.

7. Azure RBAC role assignments.

### 6.1 Authenticate with Azure

Open PowerShell:

```powershell

az login

```

Select the Azure subscription:

```powershell

az account set --subscription "<AZURE_SUBSCRIPTION_ID>"

```

Verify the selected subscription:

```powershell

az account show --output table

```

### 6.2 Configure Bootstrap Variables

Navigate to the bootstrap directory:

```powershell

cd bootstrap

```

Create `terraform.tfvars`:

```hcl

subscription_id = "<AZURE_SUBSCRIPTION_ID>"

tenant_id = "<AZURE_TENANT_ID>"

github_repository = "deevenaa/reactapp"

github_oidc_subject = "repo:deevenaa@163495548/reactapp@1440937483:ref:refs/heads/main"

```

The OIDC subject above reflects the repository identity shown in the current GitHub Actions authentication log. Verify it against the current token if the repository is renamed, transferred, or its identity changes.

### 6.3 Initialize Bootstrap Terraform

Bootstrap uses local Terraform state because it creates the Storage Account required by the main Terraform configuration.

```powershell

terraform init

```

Format the configuration:

```powershell

terraform fmt -recursive

```

Validate:

```powershell

terraform validate

```

Review the infrastructure plan:

```powershell

terraform plan -out=bootstrap.tfplan

```

Apply:

```powershell

terraform apply bootstrap.tfplan

```

### 6.4 Retrieve Bootstrap Outputs

```powershell

terraform output

```

Retrieve individual values:

```powershell

terraform output -raw storage_account_name

terraform output -raw storage_resource_group

terraform output -raw container_name

terraform output -raw azure_client_id

terraform output -raw azure_tenant_id

terraform output -raw azure_subscription_id

```

Record these values securely.

**Important:** Bootstrap Terraform state is local. Back up `terraform.tfstate` and its backup securely. Do not delete these files after creating the resources. They are required for Terraform to manage the resources it created.

---

# 7. Step 3 – Configure Terraform Remote State

The main infrastructure Terraform project uses Azure Blob Storage for remote state.

This ensures that GitHub Actions and local Terraform operations use the same infrastructure state.

### 7.1 Backend Configuration

Inside the `terraform` directory, `backend.tf`:

```hcl

terraform {

  backend "azurerm" {}

}

```

Create `backend.hcl`:

```hcl

resource_group_name  = "reactapp-tfstate-rg"

storage_account_name = "<BOOTSTRAP_STORAGE_ACCOUNT_NAME>"

container_name       = "tfstate"

key                  = "reactapp-prod.tfstate"

use_azuread_auth = true

```

Replace the Storage Account name with the actual bootstrap output.

### 7.2 Initialize Main Terraform

Navigate to the infrastructure directory:

```powershell

cd ../terraform

```

Initialize the backend:

```powershell

terraform init -backend-config="backend.hcl"

```

Validate the configuration:

```powershell

terraform validate

```

Format the Terraform files:

```powershell

terraform fmt -recursive

```

Generate the provider lock file:

```powershell

terraform providers lock

```

This generates:

```text

.terraform.lock.hcl

```

Commit this lock file to GitHub so that Terraform uses consistent provider selections.

### 7.3 Run Terraform Plan

```powershell

terraform plan

```

Review all planned infrastructure changes before applying.

For a new environment:

```powershell

terraform apply

```

The main Terraform configuration provisions the application infrastructure in Azure.

---

# 8. Step 4 – Configure GitHub Secrets and Variables

After bootstrap succeeds, configure the GitHub repository with the newly generated Azure identity and Storage Account details.

Navigate to:

**GitHub Repository → Settings → Secrets and variables → Actions**

## 8.1 GitHub Secrets

Create the following repository secrets:

| Secret Name | Value |

|---|---|

| `AZURE_CLIENT_ID` | Bootstrap output `azure_client_id` |

| `AZURE_TENANT_ID` | Bootstrap output `azure_tenant_id` |

| `AZURE_SUBSCRIPTION_ID` | Bootstrap output `azure_subscription_id` |

| `SSH_PUBLIC_KEY` | Public SSH key used by Terraform |

| `DOCKERHUB_USERNAME` | Docker Hub username |

| `DOCKERHUB_TOKEN` | Docker Hub access token |

For the SSH public key, use the contents of your `.pub` file, not your private SSH key.

## 8.2 GitHub Repository Variables

Create the following repository variables:

| Variable Name | Example Value |

|---|---|

| `AZURE_ADMIN_SOURCE_CIDR` | `YOUR_PUBLIC_IP/32` |

| `AZURE_RESOURCE_GROUP` | `reactapp-infra-rg` |

| `AZURE_VM_NAME` | `reactapp-vm` |

| `TFSTATE_CONTAINER` | `tfstate` |

| `TFSTATE_LOCATION` | `koreacentral` |

| `TFSTATE_RESOURCE_GROUP` | `reactapp-tfstate-rg` |

| `TFSTATE_STORAGE_ACCOUNT` | Actual bootstrap Storage Account name |

**Important:** Whenever the bootstrap process creates a new Storage Account, update `TFSTATE_STORAGE_ACCOUNT` with the newly generated name.

Also verify the other Azure identity secrets against the new bootstrap outputs. Do not reuse credentials belonging to a deleted or previous Entra application.

---

# 9. Step 5 – Configure GitHub OIDC Authentication

GitHub Actions authenticates to Azure using OpenID Connect (OIDC).

This avoids storing an Azure client secret in GitHub.

### Authentication flow

```text

GitHub Actions

      |

      v

Request OIDC Token

      |

      v

Microsoft Entra ID

      |

      v

Validate Federated Credential

      |

      v

Issue Azure Access Token

      |

      v

Access Azure Resources

```

The federated identity credential must have the following configuration:

| Property | Value |

|---|---|

| Issuer | `https://token.actions.githubusercontent.com` |

| Audience | `api://AzureADTokenExchange` |

| Subject | Exact GitHub Actions OIDC subject for the main branch |

The current subject used by this repository is:

```text

repo:deevenaa@163495548/reactapp@1440937483:ref:refs/heads/main

```

Terraform bootstrap manages this credential automatically.

If the repository identity or branch changes, update the Terraform configuration and apply the bootstrap changes using the locally retained bootstrap state.

### Required GitHub Actions permissions

```yaml

permissions:

  contents: read

  id-token: write

```

The `id-token: write` permission allows GitHub Actions to request the OIDC token.

---

# 10. Step 6 – Configure Docker Hub

Create a Docker Hub repository named:

```text

reactapp

```

Generate a Docker Hub access token.

Configure these GitHub secrets:

```text

DOCKERHUB_USERNAME

DOCKERHUB_TOKEN

```

The application image is published using the following naming convention:

### Development branch

```text

deevenaaa/reactapp:dev-latest

deevenaaa/reactapp:dev-<commit-sha>

```

### Main branch

```text

deevenaaa/reactapp:latest

deevenaaa/reactapp:main-<commit-sha>

```

This allows development and production images to be tracked separately.

---

# 11. Step 7 – GitHub Actions CI/CD Pipeline

The GitHub Actions workflow automates testing, building, infrastructure provisioning, image publishing, and deployment.

Workflow location:

```text

.github/workflows/main-cd.yml

```

### Pipeline execution

| Job | Development (`dev`) | Production (`main`) |

|---|---|---|

| CI – Test and Build | Yes | Yes |

| Terraform Provisioning | No | Yes |

| Docker Build and Push | Yes | Yes |

| Azure VM Deployment | No | Yes |

### Job 1 – CI

- Checks out the repository.

- Installs Node.js 20.

- Installs dependencies using `npm ci`.

- Runs application tests.

- Builds the React application.

### Job 2 – Terraform Provisioning

Runs only on the main branch.

- Authenticates to Azure through OIDC.

- Initializes Terraform with Azure Blob remote state.

- Validates Terraform configuration.

- Generates an infrastructure plan.

- Checks for destructive resource deletions or replacements.

- Applies the approved Terraform plan.

- Displays infrastructure details.

### Job 3 – Docker Build and Push

- Builds the Docker image.

- Authenticates to Docker Hub.

- Publishes the commit-specific image.

- Publishes the appropriate latest tag.

### Job 4 – Azure VM Deployment

Runs only on the main branch.

- Authenticates to Azure through OIDC.

- Uses Azure VM Run Command.

- Waits for cloud-init initialization.

- Starts Docker.

- Pulls the latest production image.

- Removes the previous application container.

- Starts the new container.

- Verifies application availability.

The application is exposed through HTTP port 80.

**Backend configuration requirement:** The GitHub Actions Terraform initialization must include all required backend settings, including the state Resource Group:

```yaml

- name: Terraform Init

  working-directory: terraform

  run: |

    terraform init -input=false \

      -backend-config="resource_group_name=${{ vars.TFSTATE_RESOURCE_GROUP }}" \

      -backend-config="storage_account_name=${{ vars.TFSTATE_STORAGE_ACCOUNT }}" \

      -backend-config="container_name=${{ vars.TFSTATE_CONTAINER }}" \

      -backend-config="key=reactapp-prod.tfstate" \

      -backend-config="use_azuread_auth=true"

```

This is important when using Azure AD authentication with a Storage Account that has key-based authentication disabled.

---

# 12. Step 8 – Deploy the Application

Once bootstrap and GitHub configuration are complete, push your code.

### Development deployment

```powershell

git checkout dev

git add .

git commit -m "Update React application"

git push origin dev

```

This triggers:

1. CI testing.

2. React production build.

3. Docker image build.

4. Docker image publishing with development tags.

It does not deploy to the production Azure VM.

### Production deployment

```powershell

git checkout main

git merge dev

git push origin main

```

This triggers:

1. CI testing.

2. Terraform infrastructure provisioning.

3. Terraform safety checks.

4. Docker image build and publishing.

5. Azure VM deployment.

6. Application health verification.

Monitor the workflow from:

**GitHub → Actions → React App – Terraform + Docker + Azure CD**

---

# 13. Step 9 – Verify Azure Deployment

After successful deployment, open the Azure Portal.

Navigate to:

**Azure Portal → Virtual Machines → reactapp-vm**

Check:

- VM provisioning state.

- VM power state.

- Public IP address.

- Network Security Group rules.

- Docker container status.

### Verify using Azure CLI

```powershell

az vm show `

  --resource-group reactapp-infra-rg `

  --name reactapp-vm `

  --show-details `

  --output table

```

### Verify Docker container

Connect to the VM or use Azure Run Command:

```bash

sudo docker ps

```

Check container logs:

```bash

sudo docker logs reactapp-prod

```

Check application response:

```bash

curl -I http://localhost/

```

### Access the application

Open:

```text

http://<AZURE_VM_PUBLIC_IP>

```

The React application should now be accessible through the VM's public IP address.

---

# 14. Infrastructure Recovery and Re-creation

This project separates bootstrap infrastructure from application infrastructure.

That separation is important because the main Terraform configuration requires the remote Storage Account before it can initialize.

### Scenario A – Azure VM is deleted

1. Push a change to the main branch or manually run the GitHub Actions workflow.

2. Terraform checks the existing remote state.

3. Terraform identifies the missing VM.

4. Terraform recreates the required VM resources.

5. The deployment job pulls the Docker image.

6. The React application is deployed again.

This assumes the remote Terraform state and required bootstrap resources still exist.

### Scenario B – Main infrastructure is deleted

If the application Resource Group or VM infrastructure is deleted but the state Storage Account remains:

1. Keep the existing remote state.

2. Run the main Terraform workflow.

3. Review the Terraform plan.

4. Confirm that missing infrastructure will be recreated.

5. Apply the changes.

6. Allow the deployment job to deploy the application.

Do not delete the remote state when the infrastructure still needs to be managed.

### Scenario C – Terraform state Storage Account is deleted

The main Terraform workflow cannot initialize its remote backend while the Storage Account is missing.

Recovery procedure:

1. Authenticate to Azure locally.

2. Navigate to the bootstrap directory.

3. Restore the backed-up bootstrap Terraform state.

4. Verify the bootstrap configuration.

5. Run Terraform plan.

6. Recreate the state Storage Account and Blob Container.

7. Restore the previous remote state blob from a backup if it exists.

8. Verify that the restored state matches the actual Azure resources.

9. Update GitHub repository variables if the Storage Account name changes.

10. Verify Azure identity secrets and federated credentials.

11. Initialize the main Terraform backend.

12. Run Terraform plan and review all changes before applying.

**Important:** A newly created empty Storage Account does not contain the previous Terraform state. Recreating the Storage Account alone does not restore infrastructure tracking.

### Scenario D – Complete environment rebuild

If all project infrastructure and the remote Terraform state have been deleted:

1. Recover the bootstrap Terraform state backup if available.

2. Run the bootstrap configuration locally.

3. Create the new Storage Account and Blob Container.

4. Create or update the Microsoft Entra application and federated credential.

5. Retrieve the new bootstrap outputs.

6. Update GitHub secrets and repository variables.

7. Initialize the main Terraform backend.

8. Confirm that the remote state is genuinely new and empty.

9. Run Terraform plan.

10. Review the complete infrastructure creation plan.

11. Apply Terraform.

12. Build and publish the Docker image.

13. Deploy the application to the newly created Azure VM.

14. Verify the application through the VM public IP.

If the old bootstrap state is lost, do not blindly run Terraform against existing resources. First inspect Azure for existing resources and identities, then import or reconcile them into Terraform state as appropriate.

---

# 15. Security and Production Considerations

The following practices are important for maintaining a secure deployment.

### Identity and Authentication

- Use GitHub OIDC instead of long-lived Azure client secrets.

- Store credentials in GitHub Secrets.

- Use Azure RBAC to control access.

- Restrict SSH access to a trusted public IP address.

- Never commit SSH private keys.

### Terraform State

- Use Azure Blob Storage for remote state.

- Disable public access to the state container.

- Disable Storage Account shared-key authentication.

- Enable Blob versioning.

- Preserve secure backups of bootstrap state.

- Commit `.terraform.lock.hcl`.

- Never commit Terraform state files or sensitive variable files.

### Docker

- Use versioned Docker images.

- Keep the production image separate from development images.

- Use Docker restart policies.

- Monitor container logs and health.

### Infrastructure Deployment

- Review Terraform plans before applying.

- Protect production resources from accidental deletion.

- Keep infrastructure provisioning separate from application deployment.

- Avoid exposing unnecessary VM ports.

- Use a controlled recovery procedure when state is missing.

### Recommended Future Improvements

- Terraform state backup and recovery automation.

- VM deployment using blue-green or rolling deployment.

- Container rollback to the previous healthy image.

- Azure Monitor and Log Analytics.

- HTTPS using a domain name and TLS certificate.

- Azure Container Registry integration.

- Terraform policy checks and approval gates.

- Resource deletion protection for critical resources.

---

# 16. Important Files That Should Not Be Committed

Add the following to `.gitignore`:

```gitignore

# Terraform working directory

.terraform/

# Terraform state

*.tfstate

*.tfstate.*

# Terraform plan files

*.tfplan

tfplan

bootstrap.tfplan

# Terraform variable files

terraform.tfvars

*.auto.tfvars

# Crash logs

crash.log

crash.*.log

# SSH private keys

*.pem

id_rsa

id_ed25519

```

Do commit:

```text

*.tf

backend.tf

backend.hcl

.terraform.lock.hcl

terraform.tfvars.example

README.md

```

The backend configuration contains resource names, not credentials, but review it before publishing. Never commit access keys, SAS tokens, private keys, passwords, or other secrets.

---

# 17. Final Deployment Checklist

### Initial Setup

- [ ] Azure subscription configured.

- [ ] Azure CLI installed and authenticated.

- [ ] Terraform installed.

- [ ] Docker Hub repository created.

- [ ] Bootstrap Terraform initialized locally.

- [ ] Azure Storage Account created.

- [ ] Private Terraform state container created.

- [ ] Microsoft Entra application created.

- [ ] GitHub federated credential configured.

- [ ] Bootstrap state backed up securely.

### GitHub Configuration

- [ ] Azure Client ID configured.

- [ ] Azure Tenant ID configured.

- [ ] Azure Subscription ID configured.

- [ ] SSH public key configured.

- [ ] Docker Hub username configured.

- [ ] Docker Hub access token configured.

- [ ] Terraform state Storage Account variable updated.

- [ ] Terraform state Resource Group variable updated.

- [ ] Azure VM and Resource Group variables configured.

- [ ] Admin source CIDR configured.

### CI/CD

- [ ] GitHub Actions workflow committed.

- [ ] OIDC login successful.

- [ ] Terraform backend initialized.

- [ ] Terraform plan successful.

- [ ] Destructive-change check successful.

- [ ] Terraform apply successful.

- [ ] Docker image published.

- [ ] Azure VM deployment successful.

- [ ] Docker container running.

- [ ] Application accessible through public IP.

---

## 18. Project Outcome

This project demonstrates an automated cloud deployment workflow using:

- React for the frontend application.

- Docker for containerization.

- Docker Hub for image storage.

- Terraform for infrastructure provisioning.

- Microsoft Azure for cloud infrastructure.

- Azure Blob Storage for remote Terraform state.

- Microsoft Entra ID and OIDC for secure authentication.

- GitHub Actions for continuous integration and deployment.

The final result is a repeatable deployment process in which application changes pushed to GitHub can be tested, containerized, published, and deployed to Azure automatically.

**Deployment flow:**

```text

Developer → GitHub → GitHub Actions → Terraform → Azure VM → Docker → React Application

```
 
### Scenario A – Azure VM is deleted

1. Push a change to the main branch or manually run the GitHub Actions workflow.

2. Terraform checks the existing remote state.

3. Terraform identifies the missing VM.

4. Terraform recreates the required VM resources.

5. The deployment job pulls the Docker image.

6. The React application is deployed again.

This assumes the remote Terraform state and required bootstrap resources still exist.

### Scenario B – Main infrastructure is deleted

If the application Resource Group or VM infrastructure is deleted but the state Storage Account remains:

1. Keep the existing remote state.

2. Run the main Terraform workflow.

3. Review the Terraform plan.

4. Confirm that missing infrastructure will be recreated.

5. Apply the changes.

6. Allow the deployment job to deploy the application.

Do not delete the remote state when the infrastructure still needs to be managed.

### Scenario C – Terraform state Storage Account is deleted

The main Terraform workflow cannot initialize its remote backend while the Storage Account is missing.

Recovery procedure:

1. Authenticate to Azure locally.

2. Navigate to the bootstrap directory.

3. Restore the backed-up bootstrap Terraform state.

4. Verify the bootstrap configuration.

5. Run Terraform plan.

6. Recreate the state Storage Account and Blob Container.

7. Restore the previous remote state blob from a backup if it exists.

8. Verify that the restored state matches the actual Azure resources.

9. Update GitHub repository variables if the Storage Account name changes.

10. Verify Azure identity secrets and federated credentials.

11. Initialize the main Terraform backend.

12. Run Terraform plan and review all changes before applying.

**Important:** A newly created empty Storage Account does not contain the previous Terraform state. Recreating the Storage Account alone does not restore infrastructure tracking.

### Scenario D – Complete environment rebuild

If all project infrastructure and the remote Terraform state have been deleted:

1. Recover the bootstrap Terraform state backup if available.

2. Run the bootstrap configuration locally.

3. Create the new Storage Account and Blob Container.

4. Create or update the Microsoft Entra application and federated credential.

5. Retrieve the new bootstrap outputs.

6. Update GitHub secrets and repository variables.

7. Initialize the main Terraform backend.

8. Confirm that the remote state is genuinely new and empty.

9. Run Terraform plan.

10. Review the complete infrastructure creation plan.

11. Apply Terraform.

12. Build and publish the Docker image.

13. Deploy the application to the newly created Azure VM.

14. Verify the application through the VM public IP.

If the old bootstrap state is lost, do not blindly run Terraform against existing resources. First inspect Azure for existing resources and identities, then import or reconcile them into Terraform state as appropriate.

---

# 15. Security and Production Considerations

The following practices are important for maintaining a secure deployment.

### Identity and Authentication

- Use GitHub OIDC instead of long-lived Azure client secrets.

- Store credentials in GitHub Secrets.

- Use Azure RBAC to control access.

- Restrict SSH access to a trusted public IP address.

- Never commit SSH private keys.

### Terraform State

- Use Azure Blob Storage for remote state.

- Disable public access to the state container.

- Disable Storage Account shared-key authentication.

- Enable Blob versioning.

- Preserve secure backups of bootstrap state.

- Commit `.terraform.lock.hcl`.

- Never commit Terraform state files or sensitive variable files.

### Docker

- Use versioned Docker images.

- Keep the production image separate from development images.

- Use Docker restart policies.

- Monitor container logs and health.

### Infrastructure Deployment

- Review Terraform plans before applying.

- Protect production resources from accidental deletion.

- Keep infrastructure provisioning separate from application deployment.

- Avoid exposing unnecessary VM ports.

- Use a controlled recovery procedure when state is missing.

### Recommended Future Improvements

- Terraform state backup and recovery automation.

- VM deployment using blue-green or rolling deployment.

- Container rollback to the previous healthy image.

- Azure Monitor and Log Analytics.

- HTTPS using a domain name and TLS certificate.

- Azure Container Registry integration.

- Terraform policy checks and approval gates.

- Resource deletion protection for critical resources.

---

# 16. Important Files That Should Not Be Committed

Add the following to `.gitignore`:

```gitignore

# Terraform working directory

.terraform/

# Terraform state

*.tfstate

*.tfstate.*

# Terraform plan files

*.tfplan

tfplan

bootstrap.tfplan

# Terraform variable files

terraform.tfvars

*.auto.tfvars

# Crash logs

crash.log

crash.*.log

# SSH private keys

*.pem

id_rsa

id_ed25519

```

Do commit:

```text

*.tf

backend.tf

backend.hcl

.terraform.lock.hcl

terraform.tfvars.example

README.md

```

The backend configuration contains resource names, not credentials, but review it before publishing. Never commit access keys, SAS tokens, private keys, passwords, or other secrets.

---

# 17. Final Deployment Checklist

### Initial Setup

- [ ] Azure subscription configured.

- [ ] Azure CLI installed and authenticated.

- [ ] Terraform installed.

- [ ] Docker Hub repository created.

- [ ] Bootstrap Terraform initialized locally.

- [ ] Azure Storage Account created.

- [ ] Private Terraform state container created.

- [ ] Microsoft Entra application created.

- [ ] GitHub federated credential configured.

- [ ] Bootstrap state backed up securely.

### GitHub Configuration

- [ ] Azure Client ID configured.

- [ ] Azure Tenant ID configured.

- [ ] Azure Subscription ID configured.

- [ ] SSH public key configured.

- [ ] Docker Hub username configured.

- [ ] Docker Hub access token configured.

- [ ] Terraform state Storage Account variable updated.

- [ ] Terraform state Resource Group variable updated.

- [ ] Azure VM and Resource Group variables configured.

- [ ] Admin source CIDR configured.

### CI/CD

- [ ] GitHub Actions workflow committed.

- [ ] OIDC login successful.

- [ ] Terraform backend initialized.

- [ ] Terraform plan successful.

- [ ] Destructive-change check successful.

- [ ] Terraform apply successful.

- [ ] Docker image published.

- [ ] Azure VM deployment successful.

- [ ] Docker container running.

- [ ] Application accessible through public IP.

---

## 18. Project Outcome

This project demonstrates an automated cloud deployment workflow using:

- React for the frontend application.

- Docker for containerization.

- Docker Hub for image storage.

- Terraform for infrastructure provisioning.

- Microsoft Azure for cloud infrastructure.

- Azure Blob Storage for remote Terraform state.

- Microsoft Entra ID and OIDC for secure authentication.

- GitHub Actions for continuous integration and deployment.

The final result is a repeatable deployment process in which application changes pushed to GitHub can be tested, containerized, published, and deployed to Azure automatically.

**Deployment flow:**

```text

Developer → GitHub → GitHub Actions → Terraform → Azure VM → Docker → React Application

```
 
