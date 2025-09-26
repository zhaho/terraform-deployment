terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.71.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  username = var.pm_api_token_id
  password = var.pm_api_token_secret
  insecure = true
}
