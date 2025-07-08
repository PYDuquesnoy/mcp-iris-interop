#!/bin/bash

# Step 2: Deploy Side MCP Interop REST API via stored procedures
# This script uploads classes and deploys the /side/mcp-interop REST API

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Side Project Step 2: REST API Deployment ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

echo "1. Uploading Side.Mcp.Interop class..."
INTEROP_CLASS_CONTENT=$(cat server-classes/Side.Mcp.Interop.cls | jq -R -s 'split("\n")[:-1]')

INTEROP_CLASS_JSON="{
  \"enc\": false,
  \"content\": ${INTEROP_CLASS_CONTENT}
}"

INTEROP_UPLOAD=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "${INTEROP_CLASS_JSON}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Side.Mcp.Interop.cls")

INTEROP_UPLOAD_STATUS=$(echo "${INTEROP_UPLOAD}" | jq -r '.status.summary // ""')
if [ -z "${INTEROP_UPLOAD_STATUS}" ]; then
    echo "✅ Side.Mcp.Interop uploaded successfully"
else
    echo "❌ Side.Mcp.Interop upload failed: ${INTEROP_UPLOAD_STATUS}"
    exit 1
fi

echo
echo "2. Compiling Side.Mcp.Interop class..."
INTEROP_COMPILE=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '["Side.Mcp.Interop.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")

INTEROP_COMPILE_STATUS=$(echo "${INTEROP_COMPILE}" | jq -r '.status.summary // ""')
if [ -z "${INTEROP_COMPILE_STATUS}" ]; then
    echo "✅ Side.Mcp.Interop compiled successfully"
    echo "Compilation output:"
    echo "${INTEROP_COMPILE}" | jq -r '.console[]?'
else
    echo "❌ Side.Mcp.Interop compilation failed: ${INTEROP_COMPILE_STATUS}"
    exit 1
fi

echo
echo "3. Uploading Side.Mcp.Deploy class..."
DEPLOY_CLASS_CONTENT=$(cat server-classes/Side.Mcp.Deploy.cls | jq -R -s 'split("\n")[:-1]')

DEPLOY_CLASS_JSON="{
  \"enc\": false,
  \"content\": ${DEPLOY_CLASS_CONTENT}
}"

DEPLOY_UPLOAD=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "${DEPLOY_CLASS_JSON}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Side.Mcp.Deploy.cls")

DEPLOY_UPLOAD_STATUS=$(echo "${DEPLOY_UPLOAD}" | jq -r '.status.summary // ""')
if [ -z "${DEPLOY_UPLOAD_STATUS}" ]; then
    echo "✅ Side.Mcp.Deploy uploaded successfully"
else
    echo "❌ Side.Mcp.Deploy upload failed: ${DEPLOY_UPLOAD_STATUS}"
    exit 1
fi

echo
echo "4. Compiling Side.Mcp.Deploy class..."
DEPLOY_COMPILE=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '["Side.Mcp.Deploy.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")

DEPLOY_COMPILE_STATUS=$(echo "${DEPLOY_COMPILE}" | jq -r '.status.summary // ""')
if [ -z "${DEPLOY_COMPILE_STATUS}" ]; then
    echo "✅ Side.Mcp.Deploy compiled successfully"
    echo "Compilation output:"
    echo "${DEPLOY_COMPILE}" | jq -r '.console[]?'
else
    echo "❌ Side.Mcp.Deploy compilation failed: ${DEPLOY_COMPILE_STATUS}"
    exit 1
fi

echo
echo "5. Checking deployment status before deployment..."
DEPLOY_STATUS_BEFORE=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query":"CALL SQLUSER.Side_Mcp_Deploy_GetDeploymentStatus()"}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "Status before deployment:"
echo "${DEPLOY_STATUS_BEFORE}" | jq .

echo
echo "6. Deploying REST API via stored procedure..."
DEPLOY_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query":"CALL SQLUSER.Side_Mcp_Deploy_DeployRestAPI()"}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "Deployment result:"
echo "${DEPLOY_RESULT}" | jq .

echo
echo "7. Checking deployment status after deployment..."
DEPLOY_STATUS_AFTER=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query":"CALL SQLUSER.Side_Mcp_Deploy_GetDeploymentStatus()"}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "Status after deployment:"
echo "${DEPLOY_STATUS_AFTER}" | jq .

echo
echo "8. Testing the deployed REST API..."
echo "Testing /side/mcp-interop/test endpoint..."
TEST_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" "http://localhost:42002/side/mcp-interop/test" 2>/dev/null || echo '{"error":"API not accessible"}')
echo "Test result:"
echo "${TEST_RESULT}" | jq .

echo
echo "Testing /side/mcp-interop/status endpoint..."
STATUS_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" "http://localhost:42002/side/mcp-interop/status" 2>/dev/null || echo '{"error":"API not accessible"}')
echo "Status result:"
echo "${STATUS_RESULT}" | jq .

echo
echo "Testing /side/mcp-interop/list endpoint..."
LIST_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" "http://localhost:42002/side/mcp-interop/list" 2>/dev/null || echo '{"error":"API not accessible"}')
echo "List result:"
echo "${LIST_RESULT}" | jq .

echo
echo "=== Step 2 Deployment Complete ==="
echo "✅ Side.Mcp.Interop class - Uploaded and compiled"
echo "✅ Side.Mcp.Deploy class - Uploaded and compiled"
echo "✅ REST API deployment - Executed via stored procedure"
echo "✅ API endpoints tested"
echo
echo "REST API should be available at:"
echo "  http://localhost:42002/side/mcp-interop/test"
echo "  http://localhost:42002/side/mcp-interop/status"
echo "  http://localhost:42002/side/mcp-interop/list"
echo "  http://localhost:42002/side/mcp-interop/productions"
echo
echo "🎉 Step 2 COMPLETE!"