#!/bin/bash

# Step 5 Production Management API Tests
# Tests the Api.MCPInterop REST API endpoints

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$source_dir/../client-proto/config.json"

# Load configuration
if [ -f "$config_file" ]; then
    SERVER=$(grep '"server"' "$config_file" | cut -d'"' -f4)
    PORT=$(grep '"port"' "$config_file" | cut -d':' -f2 | tr -d ' ,')
    USERNAME=$(grep '"username"' "$config_file" | cut -d'"' -f4)
    PASSWORD=$(grep '"password"' "$config_file" | cut -d'"' -f4)
else
    # Default values for Docker instance
    SERVER="localhost"
    PORT="42002"
    USERNAME="_SYSTEM"
    PASSWORD="SYS"
fi

BASE_URL="http://$SERVER:$PORT"
API_URL="$BASE_URL/api/mcp-interop"

echo "=== Step 5 Production Management API Tests ==="
echo "Server: $SERVER:$PORT"
echo "API Base URL: $API_URL"
echo "User: $USERNAME"
echo ""

# Test 1: Test endpoint
echo "Test 1: Testing /test endpoint..."
RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$USERNAME:$PASSWORD" \
  "$API_URL/test")

HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ /test endpoint - HTTP $HTTP_STATUS"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
else
    echo "❌ /test endpoint failed - HTTP $HTTP_STATUS"
    echo "$BODY"
fi
echo ""

# Test 2: Status endpoint
echo "Test 2: Testing /status endpoint..."
RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$USERNAME:$PASSWORD" \
  "$API_URL/status")

HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ /status endpoint - HTTP $HTTP_STATUS"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
else
    echo "❌ /status endpoint failed - HTTP $HTTP_STATUS"
    echo "$BODY"
fi
echo ""

# Test 3: List productions endpoint
echo "Test 3: Testing /list endpoint..."
RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$USERNAME:$PASSWORD" \
  "$API_URL/list")

HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ /list endpoint - HTTP $HTTP_STATUS"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
    
    # Extract production count for validation
    PROD_COUNT=$(echo "$BODY" | jq -r '.count' 2>/dev/null || echo "0")
    echo "   Production count: $PROD_COUNT"
else
    echo "❌ /list endpoint failed - HTTP $HTTP_STATUS"
    echo "$BODY"
fi
echo ""

# Test 4: Invalid endpoint (should return 404)
echo "Test 4: Testing invalid endpoint /invalid..."
RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$USERNAME:$PASSWORD" \
  "$API_URL/invalid")

HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

if [ "$HTTP_STATUS" -eq 404 ]; then
    echo "✅ Invalid endpoint correctly returns HTTP $HTTP_STATUS"
else
    echo "⚠️  Invalid endpoint returned HTTP $HTTP_STATUS (expected 404)"
    echo "$BODY"
fi
echo ""

# Summary
echo "=== Step 5 API Test Summary ==="
echo "API Base URL: $API_URL"
echo "Available endpoints:"
echo "  - GET $API_URL/test"
echo "  - GET $API_URL/status"
echo "  - GET $API_URL/list"
echo ""
echo "✅ Step 5 Production Management API tests completed!"