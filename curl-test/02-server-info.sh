#!/bin/bash

# IRIS Atelier API - Server Information
# Gets server details and available namespaces

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Server Information ==="
echo "Target: ${IRIS_BASE_URL}"
echo

COOKIE_JAR="cookies.txt"

echo "1. Get complete server information..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/\" | jq ."
echo

SERVER_INFO=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/")
echo "${SERVER_INFO}" | jq .

echo
echo "2. Extract key server details..."

VERSION=$(echo "${SERVER_INFO}" | jq -r '.result.content.version // "Unknown"')
SERVER_ID=$(echo "${SERVER_INFO}" | jq -r '.result.content.id // "Unknown"')
API_VERSION=$(echo "${SERVER_INFO}" | jq -r '.result.content.api // 0')
NAMESPACES=$(echo "${SERVER_INFO}" | jq -r '.result.content.namespaces | join(", ")')
NAMESPACE_COUNT=$(echo "${SERVER_INFO}" | jq -r '.result.content.namespaces | length')

echo "Server Version: ${VERSION}"
echo "Server ID: ${SERVER_ID}"
echo "API Version: ${API_VERSION}"
echo "Namespace Count: ${NAMESPACE_COUNT}"
echo "Available Namespaces: ${NAMESPACES}"

echo
echo "3. Extract server features..."
echo "${SERVER_INFO}" | jq -r '.result.content.features[]? | "- \(.name): \(.enabled)"'

echo
echo "4. Check for specific namespaces..."
EXPECTED_NAMESPACES=("USER" "%SYS" "IRISAPP")

for ns in "${EXPECTED_NAMESPACES[@]}"; do
    if echo "${SERVER_INFO}" | jq -e --arg ns "$ns" '.result.content.namespaces | contains([$ns])' > /dev/null; then
        echo "✅ Namespace '${ns}' is available"
    else
        echo "❌ Namespace '${ns}' is not available"
    fi
done

echo
echo "5. Test API version compatibility..."
if [ "${API_VERSION}" -ge 8 ]; then
    echo "✅ Full API feature set available (v${API_VERSION})"
elif [ "${API_VERSION}" -ge 7 ]; then
    echo "✅ Advanced features available (v${API_VERSION}) - XML operations, terminal support"
elif [ "${API_VERSION}" -ge 2 ]; then
    echo "✅ Standard features available (v${API_VERSION}) - search, macros"
elif [ "${API_VERSION}" -ge 1 ]; then
    echo "⚠️  Basic features only (v${API_VERSION}) - core document operations"
else
    echo "❌ API version too low (v${API_VERSION})"
fi

echo
echo "6. Save server info for other scripts..."
echo "${SERVER_INFO}" > server-info.json
echo "Server information saved to: server-info.json"

echo
echo "=== Server Information Complete ==="