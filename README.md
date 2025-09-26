# Terraform Deployment for Proxmox

A comprehensive Infrastructure as Code (IaC) solution for deploying and managing virtual machines on Proxmox Virtual Environment using Terraform. This repository provides a modular, environment-based approach to VM provisioning with automated workflows.

## 🎯 Purpose

This repository is designed to:
- **Automate VM deployment** on Proxmox VE using Terraform
- **Manage multiple environments** (lab, production, development, etc.) with consistent configurations
- **Provide reusable modules** for common VM deployment patterns
- **Streamline operations** with interactive task automation using Taskfile and Gum
- **Maintain infrastructure state** with proper Terraform state management

## 🏗️ Architecture

The solution follows a modular architecture:

```
terraform-deployment/
├── environments/          # Environment-specific configurations
│   ├── lab/              # Lab environment (multiple VMs)
│   ├── n8n/              # N8N automation platform
│   ├── ipam/             # IP Address Management
│   ├── management/       # Management tools
│   └── ...
├── modules/              # Reusable Terraform modules
│   └── proxmox-vm/       # Proxmox VM creation module
├── Taskfile*.yaml        # Task automation configurations
└── terraform.sh         # Interactive deployment script
```

### Key Components

- **Modular Design**: Reusable `proxmox-vm` module for consistent VM creation
- **Environment Separation**: Each environment maintains its own state and configuration
- **Interactive Workflows**: Gum-powered CLI for selecting environments and operations
- **Automation**: Taskfile-based task runners for common operations

## 🚀 Features

- ✅ **Multi-Environment Support**: Deploy to different environments (lab, production, etc.)
- ✅ **Batch VM Deployment**: Create multiple VMs with a single configuration
- ✅ **Static IP Configuration**: Automated network configuration with static IPs
- ✅ **Template-Based Deployment**: Clone from existing VM templates
- ✅ **Interactive CLI**: User-friendly interface for environment and operation selection
- ✅ **Resource Management**: Configurable CPU, memory, and disk resources
- ✅ **State Management**: Proper Terraform state handling per environment
- ✅ **IPAM Integration**: Automatic IP address registration/deregistration with phpIPAM
- ✅ **Centralized IPAM Config**: All phpIPAM settings defined in one place (`ipam-config.tf`)

## 📋 Prerequisites

### Required Tools
- **Terraform** (>= 1.0)
- **Proxmox VE** (with API access configured)
- **Git** (for repository management)

### Optional Tools
- **Taskfile** - For automated workflows ([Installation Guide](https://taskfile.dev/installation/))
- **Gum** - For interactive CLI experience (auto-installed via Taskfile)

### Proxmox Setup
1. Ensure you have a VM template created (referenced by `template_id` in configurations)
2. Configure API tokens for Terraform access
3. Verify network bridge configuration (default: `vmbr0`)

## ⚙️ Configuration

### Environment Variables

Add the following to your `~/.bashrc` or `~/.zshrc`:

```bash
# Proxmox Configuration
export TF_VAR_pm_api_url="https://your-proxmox-server:8006/api2/json"
export TF_VAR_pm_api_token_id="terraform@pve!terraform"
export TF_VAR_pm_api_token_secret="your-api-token-secret"

# IPAM Integration (optional) - settings in ipam-config.tf
export TF_VAR_ipam_password="your-phpipam-password"
export TF_VAR_global_enable_ipam=true
```

### Environment Configuration

Each environment in `environments/` contains:
- `main.tf` - Main Terraform configuration using the proxmox-vm module
- `variables.tf` - Environment-specific variables and VM definitions
- `provider.tf` - Proxmox provider configuration
- `provision.tf` - Optional post-deployment provisioning scripts

Example VM configuration in `variables.tf`:
```hcl
variable "vms" {
  default = [
    {
      name      = "lab01"
      cores     = 2
      memory    = 4096
      disk_size = 20
      static_ip = "10.4.5.31/24"
      gateway   = "10.4.5.1"
    }
  ]
}
```

## 🎮 Usage

### **🚀 Quick Start: Create New Environment**

Use the automated environment creator with IPAM integration:

```bash
# Set your IPAM password
export TF_VAR_ipam_password="your-actual-phpipam-password"

# Create a new environment (interactive)
./scripts/create-environment.sh
```

**Features:**
- 🔍 **Auto-suggests free IPs** from IPAM
- 📝 **Interactive prompts** with sensible defaults  
- 🔗 **Automatic symlink** to centralized IPAM config
- 📁 **Complete environment** setup (all .tf files)
- ✅ **Ready to deploy** with `terraform apply`
- 🛡️ **Validates subnet** and shows network information

### **IPAM Integration Usage**

**Option 1: Set environment variables directly:**
```bash
export TF_VAR_ipam_password="your-actual-phpipam-password"
```

**Option 2: Use the provided environment file:**
```bash
cp env-example.sh env.sh
nano env.sh  # Edit with your values
source env.sh
```

**Deploy with IPAM integration:**
```bash
cd environments/lab-with-ipam
terraform init
terraform apply  # VMs created + IPs registered in phpIPAM
terraform destroy  # VMs destroyed + IPs removed from phpIPAM
```

**Optional: Disable IPAM globally:**
```bash
export TF_VAR_global_enable_ipam=false
terraform apply  # VMs deployed without IPAM integration
```

**Test IPAM connectivity:**
```bash
./scripts/test-ipam-api.sh  # Test IPAM API connectivity and functionality
```

**Fix environments missing variables:**
```bash
./scripts/fix-environments.sh  # Add missing Proxmox provider variables to environments
```

**Note:** Replace `your-actual-phpipam-password` with your real phpIPAM admin password.

### Method 1: Interactive Mode (Recommended)

Using Taskfile for guided operations:
```bash
# Run the interactive menu
task

# Or directly access terraform operations
task terraform:init
task terraform:plan
task terraform:apply
task terraform:destroy
```

### Method 2: Direct Script

Using the interactive script:
```bash
# Initialize, plan, apply, or destroy
./terraform.sh init
./terraform.sh plan
./terraform.sh apply
./terraform.sh destroy
```

The script will:
1. Present available environments using Gum
2. Allow you to select the target environment
3. Execute the chosen Terraform operation
4. Display the deployed VM IP addresses

### Method 3: Manual Terraform

For direct Terraform operations:
```bash
cd environments/lab  # or any environment
terraform init
terraform plan
terraform apply
```

## 📁 Environment Examples

### Lab Environment
- **Purpose**: Development and testing
- **VMs**: Multiple lab instances (lab01, lab02, lab03)
- **Network**: 10.4.5.x/24 subnet

### Lab with IPAM Environment
- **Purpose**: Development and testing with automatic IP management
- **VMs**: Multiple lab instances with IPAM integration
- **Network**: 10.4.5.x/24 subnet
- **Features**: Uses the standard proxmox-vm module with `enable_ipam = true`

### N8N Environment
- **Purpose**: Workflow automation platform
- **VMs**: Single N8N instance
- **Network**: 10.4.5.150/24

### IPAM Environment
- **Purpose**: phpIPAM server for IP address management
- **VMs**: phpIPAM instance
- **Network**: 10.4.5.66/24

### Management Environment
- **Purpose**: Infrastructure management tools
- **VMs**: Management and monitoring services

## 🔧 Customization

### Adding New Environments

1. Create a new directory in `environments/`
2. Copy configuration files from an existing environment
3. Modify `variables.tf` with your VM specifications
4. Update network configurations as needed

### Modifying VM Specifications

Edit the `vms` variable in your environment's `variables.tf`:
```hcl
{
  name      = "my-vm"
  cores     = 4           # CPU cores
  memory    = 8192        # RAM in MB
  disk_size = 50          # Disk size in GB
  static_ip = "10.4.5.100/24"
  gateway   = "10.4.5.1"
}
```

## 🛠️ Maintenance

### Tool Updates

Update system tools using the built-in tasks:
```bash
task update:all    # Update all tools
task update:gum    # Update Gum CLI
task update:go     # Update Go language
task update:yq     # Update YQ processor
```

### State Management

- Each environment maintains its own `terraform.tfstate`
- State files are stored locally in each environment directory
- Consider implementing remote state backends for production use

## 🔍 Troubleshooting

### Common Issues

1. **Gum not found**: Run `task update:gum` to install
2. **API connection issues**: Verify Proxmox URL and credentials
3. **Template not found**: Ensure VM template exists with correct ID
4. **Network issues**: Verify bridge configuration and IP ranges

### Debugging

- Check Terraform logs: `TF_LOG=DEBUG terraform apply`
- Verify Proxmox API access: Test credentials in Proxmox web interface
- Review environment variables: `env | grep TF_VAR`

## 🤝 Contributing

1. Fork the repository
2. Create environment-specific branches
3. Test changes in isolated environments
4. Submit pull requests with detailed descriptions

## 🔗 Additional Documentation

- **[IPAM Integration Guide](IPAM_INTEGRATION.md)**: Detailed guide for phpIPAM integration
- **[phpIPAM Setup Guide](PHPIPAM_SETUP.md)**: Step-by-step phpIPAM API configuration
- **[Module Documentation](modules/)**: Technical documentation for Terraform modules

## 📄 License

This project is licensed under the terms specified in the LICENSE file.

---

**Note**: This solution is designed for Proxmox Virtual Environment and requires proper API access configuration. For IPAM integration, ensure phpIPAM is properly configured with API access. Ensure you have appropriate permissions and network access before deployment.