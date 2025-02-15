# Terraform Deployment
Repository for deployment with Terraform

# Usage
## Setup Environment Variables
```bash
export TF_VAR_pm_api_url="https://<proxmox-url>/"
export TF_VAR_pm_api_token_id="<user>@<domain>"
export TF_VAR_pm_api_token_secret="<password>"
```

## Run Taskfile
```bash
task
```