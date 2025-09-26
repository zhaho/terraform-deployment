#!/bin/bash
# Script to fix environments that are missing Proxmox provider variables

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS_DIR="$REPO_ROOT/environments"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing environments missing Proxmox provider variables${NC}"
echo "================================================================="

# Required variables that should be in every environment
REQUIRED_VARS=(
    "pm_api_url"
    "pm_api_token_id" 
    "pm_api_token_secret"
)

# Find all environments
find "$ENVIRONMENTS_DIR" -maxdepth 1 -type d ! -path "$ENVIRONMENTS_DIR" | while read -r env_dir; do
    env_name=$(basename "$env_dir")
    variables_file="$env_dir/variables.tf"
    
    if [ -f "$variables_file" ]; then
        echo -e "${BLUE}📝 Checking environment: $env_name${NC}"
        
        missing_vars=()
        for var in "${REQUIRED_VARS[@]}"; do
            if ! grep -q "variable \"$var\"" "$variables_file"; then
                missing_vars+=("$var")
            fi
        done
        
        if [ ${#missing_vars[@]} -gt 0 ]; then
            echo -e "${YELLOW}  ⚠️  Missing variables: ${missing_vars[*]}${NC}"
            echo -e "${BLUE}  🔄 Adding missing Proxmox provider variables...${NC}"
            
            # Create a backup
            cp "$variables_file" "$variables_file.backup"
            
            # Create temporary file with fixed content
            temp_file=$(mktemp)
            
            # Extract the environment name and date from existing file
            env_header=$(head -2 "$variables_file")
            
            # Write the fixed variables.tf
            cat > "$temp_file" << EOF
$env_header

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

EOF
            
            # Append the rest of the original file (skip first 3 lines if they're just headers)
            tail -n +3 "$variables_file" | grep -v "^# Environment:" | grep -v "^# Generated on:" >> "$temp_file"
            
            # Replace the original file
            mv "$temp_file" "$variables_file"
            
            echo -e "${GREEN}  ✅ Fixed $env_name${NC}"
        else
            echo -e "${GREEN}  ✅ $env_name already has all required variables${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  $env_name has no variables.tf file${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Environment fix completed!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Set your Proxmox credentials in each environment:"
echo "   cd environments/your-env"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "   nano terraform.tfvars  # Edit with your values"
echo ""
echo "2. Or use environment variables:"
echo "   export TF_VAR_pm_api_url='https://your-proxmox:8006/api2/json'"
echo "   export TF_VAR_pm_api_token_id='terraform@pve!terraform'"
echo "   export TF_VAR_pm_api_token_secret='your-token-secret'"
