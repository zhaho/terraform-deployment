#!/bin/bash
# Quick script to check if an IP is still registered in IPAM

IP_TO_CHECK="10.4.5.177"
IPAM_URL="http://10.4.5.66"
APP_ID="terraform"
USERNAME="admin"

echo "🔍 Checking if IP $IP_TO_CHECK is still in IPAM..."

# Check if password is set
if [ -z "$TF_VAR_ipam_password" ]; then
    echo "❌ TF_VAR_ipam_password not set"
    echo "Run: export TF_VAR_ipam_password='your-password'"
    exit 1
fi

# Get auth token
echo "🔑 Authenticating..."
AUTH_RESPONSE=$(curl -s -u "$USERNAME:$TF_VAR_ipam_password" -X POST "$IPAM_URL/api/$APP_ID/user/")
TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get authentication token"
    echo "Auth response: $AUTH_RESPONSE"
    exit 1
fi

echo "✅ Got authentication token"

# Search for IP
echo "🔍 Searching for IP $IP_TO_CHECK..."
SEARCH_RESULT=$(curl -s -H "token: $TOKEN" "$IPAM_URL/api/$APP_ID/addresses/search/$IP_TO_CHECK/")

echo "📋 Search result:"
echo "$SEARCH_RESULT"

if echo "$SEARCH_RESULT" | grep -q '"success":false'; then
    echo ""
    echo "✅ IP $IP_TO_CHECK is NOT in IPAM (successfully removed)"
elif echo "$SEARCH_RESULT" | grep -q '"id"'; then
    echo ""
    echo "❌ IP $IP_TO_CHECK is STILL in IPAM (not removed properly)"
    
    # Show details
    ADDRESS_ID=$(echo "$SEARCH_RESULT" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    HOSTNAME=$(echo "$SEARCH_RESULT" | grep -o '"hostname":"[^"]*' | head -1 | cut -d'"' -f4)
    
    echo "   ID: $ADDRESS_ID"
    echo "   Hostname: $HOSTNAME"
    
    # Offer to delete it manually
    echo ""
    echo "🗑️  Would you like to delete it manually? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting IP $IP_TO_CHECK (ID: $ADDRESS_ID)..."
        DELETE_RESULT=$(curl -s -X DELETE -H "token: $TOKEN" "$IPAM_URL/api/$APP_ID/addresses/$ADDRESS_ID/")
        echo "Delete result: $DELETE_RESULT"
        
        if echo "$DELETE_RESULT" | grep -q '"success":true'; then
            echo "✅ Successfully deleted IP $IP_TO_CHECK from IPAM"
        else
            echo "❌ Failed to delete IP $IP_TO_CHECK"
        fi
    fi
else
    echo ""
    echo "❓ Unexpected response from IPAM"
fi
