#!/bin/bash
# Test the IPAM destroy logic independently

IP_ADDRESS="10.4.5.177/24"
IPAM_URL="http://10.4.5.66"
APP_ID="terraform"
USERNAME="admin"

echo "🧪 Testing IPAM destroy logic for IP: $IP_ADDRESS"

# Check if password is set
if [ -z "$TF_VAR_ipam_password" ]; then
    echo "❌ TF_VAR_ipam_password not set"
    echo "Run: export TF_VAR_ipam_password='your-password'"
    exit 1
fi

# Replicate the exact destroy logic from Terraform
set -e
echo "IPAM: Starting IP deregistration for $IP_ADDRESS"

# Get auth token
echo "IPAM: Authenticating with $IPAM_URL"
AUTH_RESPONSE=$(curl -s -u "$USERNAME:$TF_VAR_ipam_password" -X POST "$IPAM_URL/api/$APP_ID/user/")
TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "IPAM: Failed to get authentication token"
  echo "IPAM: Auth response: $AUTH_RESPONSE"
  exit 1
fi

echo "IPAM: Got authentication token"

# Find and delete IP
IP_ONLY=$(echo "$IP_ADDRESS" | cut -d'/' -f1)
echo "IPAM: Searching for IP $IP_ONLY"

SEARCH_RESULT=$(curl -s -H "token: $TOKEN" "$IPAM_URL/api/$APP_ID/addresses/search/$IP_ONLY/")
echo "IPAM: Search result: $SEARCH_RESULT"

ADDRESS_ID=$(echo "$SEARCH_RESULT" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -n "$ADDRESS_ID" ]; then
  echo "IPAM: Found address ID: $ADDRESS_ID, deleting..."
  DELETE_RESULT=$(curl -s -X DELETE -H "token: $TOKEN" "$IPAM_URL/api/$APP_ID/addresses/$ADDRESS_ID/")
  echo "IPAM: Delete result: $DELETE_RESULT"
  
  if echo "$DELETE_RESULT" | grep -q '"success":true'; then
    echo "IPAM: Successfully removed IP $IP_ONLY from phpIPAM"
  else
    echo "IPAM: Failed to remove IP $IP_ONLY"
    echo "IPAM: Delete response: $DELETE_RESULT"
  fi
else
  echo "IPAM: No address ID found for IP $IP_ONLY - may already be deleted"
fi

echo "IPAM: IP deregistration completed"
