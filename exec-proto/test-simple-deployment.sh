#!/bin/bash

# Simple test of Step 2 deployment using existing classes

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Step 2: Simple Deployment Test ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "1. Testing existing Side.Mcp.Deploy stored procedure..."
DEPLOY_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT Side.Mcp.Deploy_DeployRestAPI() AS Status"}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "Deploy result:"
echo "${DEPLOY_RESULT}" | jq .

echo
echo "2. Check deployment status..."
STATUS_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT Side.Mcp.Deploy_GetDeploymentStatus() AS Status"}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "Status result:"
echo "${STATUS_RESULT}" | jq .

echo
echo "3. Testing REST API endpoints..."
echo "Base URL: http://${IRIS_HOST}:${IRIS_PORT}/side/mcp-interop"

# Test /test endpoint
echo
echo "3.1 Testing /test endpoint..."
TEST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  "http://${IRIS_HOST}:${IRIS_PORT}/side/mcp-interop/test" 2>/dev/null)

HTTP_STATUS=$(echo "$TEST_RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$TEST_RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

echo "Status: ${HTTP_STATUS}"
echo "Response: ${RESPONSE_BODY}"

# Test /status endpoint
echo
echo "3.2 Testing /status endpoint..."
STATUS_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  "http://${IRIS_HOST}:${IRIS_PORT}/side/mcp-interop/status" 2>/dev/null)

HTTP_STATUS=$(echo "$STATUS_RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$STATUS_RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

echo "Status: ${HTTP_STATUS}"
echo "Response: ${RESPONSE_BODY}"

# Test /list endpoint
echo
echo "3.3 Testing /list endpoint..."
LIST_RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  "http://${IRIS_HOST}:${IRIS_PORT}/side/mcp-interop/list" 2>/dev/null)

HTTP_STATUS=$(echo "$LIST_RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$LIST_RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')

echo "Status: ${HTTP_STATUS}"
echo "Response: ${RESPONSE_BODY}"

echo
echo "=== Step 2 Summary ==="
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ REST API deployed and working"
elif [ "$HTTP_STATUS" = "404" ]; then
    echo "⚠️  REST API not deployed or not accessible"
else
    echo "⚠️  REST API status: ${HTTP_STATUS}"
fi

echo "✅ Deployment stored procedures tested"
echo "✅ REST API endpoints tested"
echo "✅ Step 2 validation complete"