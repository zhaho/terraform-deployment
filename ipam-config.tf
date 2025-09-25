# Centralized IPAM Configuration
# Define ALL phpIPAM settings in one place - CHANGE THESE TO MATCH YOUR SETUP

# IPAM password from environment variable
variable "ipam_password" {
  description = "phpIPAM password - set via TF_VAR_ipam_password environment variable"
  type        = string
  sensitive   = true
}

locals {
  # IPAM server configuration - ONLY PLACE TO DEFINE IPAM SETTINGS
  ipam_config = {
    url        = "http://10.4.5.66"         # phpIPAM server URL
    app_id     = "terraform"                # API application ID
    username   = "admin"                    # phpIPAM username
    password   = var.ipam_password          # phpIPAM password from environment variable
    subnet_id  = "7"                       # Default subnet ID for 10.4.5.x network
  }
}

# Global variable to enable/disable IPAM integration
variable "global_enable_ipam" {
  description = "Global setting to enable IPAM integration for all environments"
  type        = bool
  default     = true
}

# Outputs for environments to use
output "ipam_config" {
  description = "Centralized IPAM configuration - use this in your environments"
  value = {
    url        = local.ipam_config.url
    app_id     = local.ipam_config.app_id
    username   = local.ipam_config.username
    password   = local.ipam_config.password
    subnet_id  = local.ipam_config.subnet_id
    enabled    = var.global_enable_ipam
  }
  sensitive = true
}
