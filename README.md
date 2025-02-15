# Terraform Deployment
Repository for deployment with Terraform for Proxmox etc.

# Prerequisities
## Required
* Terraform
* Proxmox

## Optional
* Install Taskfile (https://taskfile.dev/installation/)

# Usage
## Setup Environment Variables

### Proxmox Variables
Add to your ~/.bashrc or ~/.zshrc

```bash
export TF_VAR_pm_api_url="https://<proxmox-url>/"
export TF_VAR_pm_api_token_id="<user>@<domain>"
export TF_VAR_pm_api_token_secret="<password>"
```

## Run Taskfile
```bash
task
```