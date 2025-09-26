#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENTS_DIR="$REPO_ROOT/environments"

echo -e "${BLUE}🚀 Terraform Environment Creator with IPAM Integration${NC}"
echo "================================================================="

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if IPAM password is set
    if [ -z "$TF_VAR_ipam_password" ]; then
        echo -e "${RED}❌ TF_VAR_ipam_password not set${NC}"
        echo "Please set your IPAM password first:"
        echo "export TF_VAR_ipam_password='your-password'"
        exit 1
    fi
    
    # Check if required tools are available
    for tool in curl jq; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}❌ $tool is not installed${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Get authentication token from IPAM
get_ipam_token() {
    local ipam_url="http://10.4.5.66"
    local app_id="terraform"
    local username="admin"
    
    echo -e "${BLUE}🔑 Authenticating with IPAM...${NC}" >&2
    
    local auth_response=$(curl -s -u "$username:$TF_VAR_ipam_password" -X POST "$ipam_url/api/$app_id/user/")
    local token=$(echo "$auth_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$token" ]; then
        echo -e "${RED}❌ Failed to authenticate with IPAM${NC}" >&2
        echo "Response: $auth_response" >&2
        exit 1
    fi
    
    echo "$token"
}

# Note: Using hardcoded subnet 7 info since we always use the same network

# Find free IPs in subnet - returns only the IP, no debug output
find_free_ips() {
    local token="$1"
    local subnet_id="$2"
    local ipam_url="http://10.4.5.66"
    local app_id="terraform"
    
    # Get first free IP from IPAM (silent)
    local free_ip_response=$(curl -s -H "token: $token" "$ipam_url/api/$app_id/subnets/$subnet_id/first_free/")
    
    if echo "$free_ip_response" | grep -q '"success":true'; then
        # Try jq first, fallback to grep
        local free_ip=""
        if command -v jq &> /dev/null; then
            free_ip=$(echo "$free_ip_response" | jq -r '.data' 2>/dev/null)
        fi
        
        # Fallback to grep if jq failed
        if [ -z "$free_ip" ] || [ "$free_ip" = "null" ]; then
            free_ip=$(echo "$free_ip_response" | grep -o '"data":"[^"]*' | cut -d'"' -f4)
        fi
        
        # Only return the IP if it's valid
        if [ -n "$free_ip" ] && [ "$free_ip" != "null" ]; then
            echo "$free_ip"
        fi
    fi
    # Return nothing if failed - caller will handle the error message
}

# Get user input with defaults
get_user_input() {
    local token="$1"
    
    echo ""
    echo -e "${BLUE}📝 Environment Configuration${NC}"
    echo "================================="
    
    # Environment name
    while true; do
        read -p "Environment name (e.g., 'dev', 'staging', 'lab-test', 'k3s-test'): " env_name
        if [ -n "$env_name" ]; then
            # Check if environment already exists
            if [ -d "$ENVIRONMENTS_DIR/$env_name" ]; then
                echo -e "${RED}❌ Environment '$env_name' already exists!${NC}"
                echo -e "${YELLOW}💡 Choose a different name:${NC}"
                echo -e "${YELLOW}   - k3s-test${NC}"
                echo -e "${YELLOW}   - dev-cluster${NC}"
                echo -e "${YELLOW}   - staging-k3s${NC}"
                echo -e "${YELLOW}   - k3s-prod${NC}"
                continue
            fi
            break
        fi
        echo -e "${YELLOW}⚠️  Environment name cannot be empty${NC}"
    done
    
    # VM name (default to environment name + 01)
    default_vm_name="${env_name}01"
    read -p "VM name [$default_vm_name]: " vm_name
    vm_name=${vm_name:-$default_vm_name}
    
    # Subnet ID (always use 7 for 10.4.5.x network)
    subnet_id="7"
    echo "IPAM Subnet ID: $subnet_id (10.4.5.x network)"
    
    # Use known subnet 7 information and find free IP
    echo -e "${GREEN}✅ Subnet $subnet_id: 10.4.5.0/24 (MGMT Network)${NC}"
    
    # Find free IP
    echo -e "${BLUE}🔍 Finding available IP...${NC}"
    local suggested_ip=$(find_free_ips "$token" "$subnet_id")
    if [ -n "$suggested_ip" ] && [ "$suggested_ip" != "null" ] && [ "$suggested_ip" != "" ]; then
        echo -e "${GREEN}💡 Suggested free IP: $suggested_ip${NC}"
        while true; do
            read -p "VM IP address [$suggested_ip/24]: " vm_ip
            vm_ip=${vm_ip:-"$suggested_ip/24"}
            if [ -n "$vm_ip" ]; then
                break
            fi
            echo -e "${YELLOW}⚠️  IP address cannot be empty${NC}"
        done
    else
        echo -e "${YELLOW}⚠️  Could not get free IP suggestion, please enter manually${NC}"
        while true; do
            read -p "VM IP address (e.g., 10.4.5.200/24): " vm_ip
            if [ -n "$vm_ip" ]; then
                break
            fi
            echo -e "${YELLOW}⚠️  IP address cannot be empty${NC}"
        done
    fi
    
    # Gateway (extract from IP and assume .1)
    if [[ "$vm_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
        local network_base=$(echo "$vm_ip" | cut -d'/' -f1 | cut -d'.' -f1-3)
        default_gateway="${network_base}.1"
    else
        default_gateway="10.4.5.1"  # fallback default
    fi
    read -p "Gateway [$default_gateway]: " gateway
    gateway=${gateway:-$default_gateway}
    
    # VM specifications
    read -p "VM Cores [2]: " cores
    cores=${cores:-2}
    
    read -p "VM Memory (MB) [4096]: " memory
    memory=${memory:-4096}
    
    read -p "VM Disk Size (GB) [20]: " disk_size
    disk_size=${disk_size:-20}
    
    # Proxmox node
    read -p "Proxmox node [proxmox]: " target_node
    target_node=${target_node:-proxmox}
    
    echo ""
    echo -e "${BLUE}📋 Configuration Summary:${NC}"
    echo "=========================="
    echo "Environment: $env_name"
    echo "VM Name: $vm_name"
    echo "IP Address: $vm_ip"
    echo "Gateway: $gateway"
    echo "Subnet ID: $subnet_id"
    echo "Cores: $cores"
    echo "Memory: ${memory}MB"
    echo "Disk: ${disk_size}GB"
    echo "Node: $target_node"
    echo ""
    
    read -p "Create this environment? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Environment creation cancelled${NC}"
        exit 0
    fi
}

# Create environment directory structure
create_environment() {
    local env_dir="$ENVIRONMENTS_DIR/$env_name"
    
    echo -e "${BLUE}📁 Creating environment directory...${NC}"
    mkdir -p "$env_dir"
    
    # Create symlink to ipam-config.tf
    echo -e "${BLUE}🔗 Creating IPAM config symlink...${NC}"
    ln -sf "../../ipam-config.tf" "$env_dir/ipam-config.tf"
    
    # Create variables.tf
    echo -e "${BLUE}📝 Creating variables.tf...${NC}"
    cat > "$env_dir/variables.tf" << EOF
# Environment: $env_name
# Generated on: $(date)

# Proxmox provider variables
variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "target_node" {
  description = "Proxmox node to deploy VMs on"
  type        = string
  default     = "$target_node"
}

variable "host_user" {
  description = "The SSH user for connecting to the remote host"
  type        = string
  default     = "zhaho"  # Change this if needed
}

variable "vm_network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

# Environment-specific IPAM override (null = use global setting)
variable "enable_ipam" {
  description = "Enable IPAM integration for this environment (overrides global setting)"
  type        = bool
  default     = null
}

# VM definitions
variable "vms" {
  description = "List of VMs to create"
  type = list(object({
    name      = string
    cores     = number
    memory    = number
    disk_size = number
    static_ip = string
    gateway   = string
    subnet_id = string  # IPAM subnet ID for this VM's network
  }))
  
  default = [
    {
      name      = "$vm_name"
      cores     = $cores
      memory    = $memory
      disk_size = $disk_size
      static_ip = "$vm_ip"
      gateway   = "$gateway"
      subnet_id = "$subnet_id"
    }
  ]
}
EOF

    # Create main.tf
    echo -e "${BLUE}📝 Creating main.tf...${NC}"
    cat > "$env_dir/main.tf" << 'EOF'
# IPAM configuration is loaded from the symlinked ipam-config.tf file
# All IPAM settings are defined in the root ipam-config.tf (symlinked here)

locals {
  # Use environment override or global setting  
  enable_ipam = var.enable_ipam != null ? var.enable_ipam : var.global_enable_ipam
}

module "vms" {
  source = "../../modules/proxmox-vm"

  for_each = { for vm in var.vms : vm.name => vm }

  # Proxmox VM configuration
  target_node       = var.target_node
  vm_name           = each.value.name
  vm_cores          = each.value.cores
  vm_memory         = each.value.memory
  vm_disk_size      = each.value.disk_size
  vm_network_bridge = var.vm_network_bridge
  vm_static_ip      = each.value.static_ip
  vm_gateway        = each.value.gateway
  vm_datastore      = "local-lvm"
  template_id       = 9200  # ID of the template VM

  # IPAM configuration - ALL FROM CENTRALIZED CONFIG (via symlinked file)
  enable_ipam      = local.enable_ipam
  ipam_url         = local.ipam_config.url
  ipam_app_id      = local.ipam_config.app_id
  ipam_username    = local.ipam_config.username
  ipam_password    = local.ipam_config.password
  ipam_subnet_id   = each.value.subnet_id
  ipam_description = "VM ${each.value.name} in ${basename(path.cwd)} environment - deployed by Terraform"
}
EOF

    # Create provider.tf
    echo -e "${BLUE}📝 Creating provider.tf...${NC}"
    cat > "$env_dir/provider.tf" << 'EOF'
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
EOF

    # Create provision.tf (same as lab-with-ipam)
    echo -e "${BLUE}📝 Creating provision.tf...${NC}"
    cat > "$env_dir/provision.tf" << 'EOF'
resource "null_resource" "remote_provision" {
  for_each = { for vm in var.vms : vm.name => vm }

  depends_on = [module.vms]

  connection {
    type        = "ssh"
    user        = var.host_user
    host        = split("/", each.value.static_ip)[0]
    private_key = file("~/.ssh/id_rsa")
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",  
      "ansible-pull -U https://github.com/zhaho/ansible-deployment.git -e host_user=zhaho zsh.yml -vvv"
    ]
  }
}
EOF

    # Note: Using environment variables instead of terraform.tfvars
    # Set these environment variables:
    # export TF_VAR_pm_api_url="https://your-proxmox-server:8006/api2/json"
    # export TF_VAR_pm_api_token_id="root@pam"  
    # export TF_VAR_pm_api_token_secret="your-password"
    # export TF_VAR_ipam_password="your-ipam-password"

    echo -e "${GREEN}✅ Environment '$env_name' created successfully!${NC}"
    echo ""
    echo -e "${BLUE}📍 Location: $env_dir${NC}"
    echo ""
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    echo "1. Ensure your environment variables are set:"
    echo "   export TF_VAR_pm_api_url=\"$TF_VAR_pm_api_url\""
    echo "   export TF_VAR_pm_api_token_id=\"$TF_VAR_pm_api_token_id\""
    echo "   export TF_VAR_pm_api_token_secret=\"[HIDDEN]\""
    echo "   export TF_VAR_ipam_password=\"[HIDDEN]\""
    echo ""
    echo "2. Deploy the environment:"
    echo "   cd $env_dir"
    echo "   terraform init"
    echo "   terraform apply"
    echo ""
    echo -e "${GREEN}💡 The IP $vm_ip will be automatically registered in IPAM!${NC}"
}

# Main execution
main() {
    check_prerequisites
    
    local token=$(get_ipam_token)
    echo -e "${GREEN}✅ IPAM authentication successful${NC}"
    
    get_user_input "$token"
    create_environment
    
    echo -e "${GREEN}🎉 Environment creation completed!${NC}"
}

# Run main function
main "$@"
