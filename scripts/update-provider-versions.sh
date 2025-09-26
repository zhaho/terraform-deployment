#!/bin/bash
# Script to update all environments to use consistent Proxmox provider version

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENTS_DIR="$REPO_ROOT/environments"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Updating Proxmox provider versions across all environments${NC}"
echo "================================================================="

TARGET_VERSION="~> 0.71.0"

# Function to update a single provider file
update_provider_file() {
    local provider_file="$1"
    local env_name="$2"
    
    # Create a temporary file for safe editing
    local temp_file=$(mktemp)
    
    # Read the file and update version lines
    while IFS= read -r line; do
        if echo "$line" | grep -q 'version.*=.*"[~]*.*0\.[0-9]*\.0"'; then
            # Replace the version line
            echo '      version = "~> 0.71.0"'
        else
            echo "$line"
        fi
    done < "$provider_file" > "$temp_file"
    
    # Replace the original file
    mv "$temp_file" "$provider_file"
}

# Find all provider.tf files in environments
find "$ENVIRONMENTS_DIR" -name "provider.tf" -type f | while read -r provider_file; do
    env_name=$(basename "$(dirname "$provider_file")")
    echo -e "${BLUE}📝 Checking environment: $env_name${NC}"
    
    # Check if it has old version patterns
    if grep -q 'version.*=.*"[~]*.*0\.[0-9]*\.0"' "$provider_file"; then
        # Check for specific old versions that need updating
        if grep -q 'version.*=.*"[~]*.*0\.6[0-9]\.0"' "$provider_file" || \
           grep -q 'version.*=.*"0\.7[0-1]\.0"' "$provider_file"; then
            
            echo -e "${YELLOW}  🔄 Updating version constraint${NC}"
            update_provider_file "$provider_file" "$env_name"
            
            # Check if provider configuration needs updating
            if grep -q 'username.*=.*var\.pm_api_token_id' "$provider_file"; then
                echo -e "${YELLOW}  ⚠️  Provider config format needs manual update${NC}"
                echo -e "${YELLOW}     Consider updating from username/password to api_token format${NC}"
            fi
            
            echo -e "${GREEN}  ✅ Updated $env_name${NC}"
        else
            echo -e "${GREEN}  ✅ $env_name already uses compatible version${NC}"
        fi
    else
        echo -e "${GREEN}  ✅ $env_name already up to date${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Provider version update completed!${NC}"
echo -e "${BLUE}💡 All environments now use Proxmox provider version: $TARGET_VERSION${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Run 'terraform init' in each updated environment"
echo "2. Check for any provider configuration format issues"
echo "3. Test deployments to ensure compatibility"
