#!/bin/bash
# Quick test script to verify IPAM API connectivity and functionality

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 IPAM API Test Script${NC}"
echo "========================="

# Check if password is set
if [ -z "$TF_VAR_ipam_password" ]; then
    echo -e "${RED}❌ TF_VAR_ipam_password not set${NC}"
    echo "Run: export TF_VAR_ipam_password='your-password'"
    exit 1
fi

IPAM_URL="http://10.4.5.66"
APP_ID="terraform"
USERNAME="admin"

# Test authentication
echo -e "${BLUE}🔑 Testing authentication...${NC}"
AUTH_RESPONSE=$(curl -s -u "$USERNAME:$TF_VAR_ipam_password" -X POST "$IPAM_URL/api/$APP_ID/user/")
TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✅ Authentication successful${NC}"
else
    echo -e "${RED}❌ Authentication failed${NC}"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

# Test subnet info
echo -e "${BLUE}📊 Getting subnet 7 information...${NC}"
SUBNET_RESPONSE=$(curl -s -H "token: $TOKEN" "$IPAM_URL/api/$APP_ID/subnets/7/")

if echo "$SUBNET_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Subnet info retrieved${NC}"
    if command -v jq &> /dev/null; then
        echo "Subnet: $(echo "$SUBNET_RESPONSE" | jq -r '.data.subnet + "/" + .data.mask')"
        echo "Description: $(echo "$SUBNET_RESPONSE" | jq -r '.data.description // "N/A"')"
    else
        echo "Raw response: $SUBNET_RESPONSE"
    fi
else
    echo -e "${RED}❌ Failed to get subnet info${NC}"
    echo "Response: $SUBNET_RESPONSE"
fi

# Test free IP lookup
echo -e "${BLUE}🔍 Finding free IP in subnet 7...${NC}"
FREE_IP_RESPONSE=$(curl -s -H "token: $TOKEN" "$IPAM_URL/api/$APP_ID/subnets/7/first_free/")

if echo "$FREE_IP_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ Free IP lookup successful${NC}"
    if command -v jq &> /dev/null; then
        FREE_IP=$(echo "$FREE_IP_RESPONSE" | jq -r '.data')
        echo "Next available IP: $FREE_IP"
    else
        echo "Raw response: $FREE_IP_RESPONSE"
    fi
else
    echo -e "${RED}❌ Failed to find free IP${NC}"
    echo "Response: $FREE_IP_RESPONSE"
fi

echo ""
echo -e "${GREEN}🎉 IPAM API test completed!${NC}"
echo -e "${BLUE}💡 You can now run: ./scripts/create-environment.sh${NC}"
