#!/bin/bash

# Deploy Api.MCPInterop REST API - Step 5 Main Project
# Based on proven DEPLOYMENT-NOTES.MD patterns

set -e

# Configuration
IRIS_HOST="localhost"
IRIS_PORT="42002"
IRIS_USER="_SYSTEM"
IRIS_PASS="SYS"
IRIS_NS="IRISAPP"
IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Deploy Api.MCPInterop REST API - Step 5 ==="
echo "Host: $IRIS_HOST:$IRIS_PORT"
echo "Namespace: $IRIS_NS"
echo "Web App Path: /api/mcp-interop"
echo ""

# Step 1: Upload Api.MCPInterop.cls
echo "Step 1: Uploading Api.MCPInterop.cls..."
curl -s -X PUT \
  --user "$IRIS_USER:$IRIS_PASS" \
  -H "Content-Type: application/json" \
  --data-binary @Api.MCPInterop.cls \
  "$IRIS_BASE_URL/v1/$IRIS_NS/doc/Api.MCPInterop.cls" > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Api.MCPInterop.cls uploaded successfully"
else
    echo "❌ Failed to upload Api.MCPInterop.cls"
    exit 1
fi

# Step 2: Upload Api.MCPInterop.Deploy.cls
echo "Step 2: Uploading Api.MCPInterop.Deploy.cls..."
curl -s -X PUT \
  --user "$IRIS_USER:$IRIS_PASS" \
  -H "Content-Type: application/json" \
  --data-binary @Api.MCPInterop.Deploy.cls \
  "$IRIS_BASE_URL/v1/$IRIS_NS/doc/Api.MCPInterop.Deploy.cls" > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Api.MCPInterop.Deploy.cls uploaded successfully"
else
    echo "❌ Failed to upload Api.MCPInterop.Deploy.cls"
    exit 1
fi

# Step 3: Compile the classes
echo "Step 3: Compiling classes..."
COMPILE_RESULT=$(curl -s -X POST \
  --user "$IRIS_USER:$IRIS_PASS" \
  -H "Content-Type: application/json" \
  -d '{"docs": ["Api.MCPInterop.cls", "Api.MCPInterop.Deploy.cls"]}' \
  "$IRIS_BASE_URL/v1/$IRIS_NS/action/compile")

echo "$COMPILE_RESULT" | grep -q '"errors":\[\]'
if [ $? -eq 0 ]; then
    echo "✅ Classes compiled successfully"
else
    echo "❌ Compilation failed"
    echo "$COMPILE_RESULT"
    exit 1
fi

# Step 4: Create and execute deployment stored procedure
echo "Step 4: Creating deployment stored procedure..."
DEPLOY_PROC_SQL='CREATE PROCEDURE Deploy_ApiMcpInterop() RETURNS VARCHAR(500) LANGUAGE OBJECTSCRIPT { New $NAMESPACE Set $NAMESPACE = "%SYS" Set Props("AutheEnabled") = 32 Set Props("NameSpace") = "IRISAPP" Set Props("Enabled") = 1 Set Props("DispatchClass") = "Api.MCPInterop" Set Props("MatchRoles") = ":%All" Set Props("Description") = "API MCP Interop - Main Project Step 5" If ##class(Security.Applications).Exists("/api/mcp-interop") { Do ##class(Security.Applications).Delete("/api/mcp-interop") } Set Status = ##class(Security.Applications).Create("/api/mcp-interop", .Props) If $$$ISOK(Status) { QUIT "SUCCESS: Web app /api/mcp-interop created" } Else { QUIT "ERROR: " _ $SYSTEM.Status.GetErrorText(Status) } }'

curl -s -X POST \
  --user "$IRIS_USER:$IRIS_PASS" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$DEPLOY_PROC_SQL\"}" \
  "$IRIS_BASE_URL/v1/$IRIS_NS/action/query" > /dev/null

if [ $? -eq 0 ]; then
    echo "✅ Deployment stored procedure created"
else
    echo "❌ Failed to create deployment stored procedure"
    exit 1
fi

# Step 5: Execute the deployment stored procedure
echo "Step 5: Executing deployment..."
DEPLOY_RESULT=$(curl -s -X POST \
  --user "$IRIS_USER:$IRIS_PASS" \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT Deploy_ApiMcpInterop() AS Result"}' \
  "$IRIS_BASE_URL/v1/$IRIS_NS/action/query")

echo "$DEPLOY_RESULT" | grep -q "SUCCESS: Web app /api/mcp-interop created"
if [ $? -eq 0 ]; then
    echo "✅ Web application deployed successfully"
else
    echo "❌ Deployment failed"
    echo "$DEPLOY_RESULT"
    exit 1
fi

# Step 6: Test the endpoints
echo "Step 6: Testing endpoints..."

# Test /test endpoint
echo "Testing /test endpoint..."
TEST_RESULT=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$IRIS_USER:$IRIS_PASS" \
  "http://$IRIS_HOST:$IRIS_PORT/api/mcp-interop/test")

echo "$TEST_RESULT" | grep -q "HTTP_STATUS:200"
if [ $? -eq 0 ]; then
    echo "✅ /test endpoint working"
else
    echo "❌ /test endpoint failed"
    echo "$TEST_RESULT"
fi

# Test /status endpoint
echo "Testing /status endpoint..."
STATUS_RESULT=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$IRIS_USER:$IRIS_PASS" \
  "http://$IRIS_HOST:$IRIS_PORT/api/mcp-interop/status")

echo "$STATUS_RESULT" | grep -q "HTTP_STATUS:200"
if [ $? -eq 0 ]; then
    echo "✅ /status endpoint working"
else
    echo "❌ /status endpoint failed"
    echo "$STATUS_RESULT"
fi

# Test /list endpoint
echo "Testing /list endpoint..."
LIST_RESULT=$(curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "$IRIS_USER:$IRIS_PASS" \
  "http://$IRIS_HOST:$IRIS_PORT/api/mcp-interop/list")

echo "$LIST_RESULT" | grep -q "HTTP_STATUS:200"
if [ $? -eq 0 ]; then
    echo "✅ /list endpoint working"
else
    echo "❌ /list endpoint failed"
    echo "$LIST_RESULT"
fi

echo ""
echo "=== Deployment Complete ==="
echo "API Base URL: http://$IRIS_HOST:$IRIS_PORT/api/mcp-interop"
echo "Available endpoints:"
echo "  - GET /api/mcp-interop/test"
echo "  - GET /api/mcp-interop/status" 
echo "  - GET /api/mcp-interop/list"
echo ""
echo "✅ Api.MCPInterop REST API deployed successfully for Step 5!"