#!/bin/bash

# Step 5 Complete Deployment and Testing Script
# Deploys Api.MCPInterop REST API and runs comprehensive tests

set -e

echo "=============================================="
echo "  STEP 5: Production Management API"
echo "  Complete Deployment and Testing"
echo "=============================================="
echo ""

# Configuration
IRIS_HOST="localhost"
IRIS_PORT="42002"
IRIS_USER="_SYSTEM"
IRIS_PASS="SYS"
IRIS_NS="IRISAPP"

echo "Configuration:"
echo "  IRIS Host: $IRIS_HOST:$IRIS_PORT"
echo "  Namespace: $IRIS_NS"
echo "  User: $IRIS_USER"
echo ""

# Step 1: Deploy the API
echo "🚀 Step 1: Deploying Api.MCPInterop REST API..."
cd iris-src
./deploy-api-mcp-interop.sh
cd ..
echo ""

# Step 2: Upload sample production class
echo "🚀 Step 2: Uploading sample production class..."
cd client-proto
npm run build > /dev/null 2>&1
node dist/index.js upload iris-samples/Sample.Production.Step5.cls -v
echo ""

# Step 3: Test client-proto production commands
echo "🚀 Step 3: Testing client-proto production commands..."

echo "Testing prod-check command..."
node dist/index.js prod-check -v
echo ""

echo "Testing prod-test command..."
node dist/index.js prod-test -v
echo ""

echo "Testing prod-status command..."
node dist/index.js prod-status -v
echo ""

echo "Testing prod-list command..."
node dist/index.js prod-list -v
echo ""

cd ..

# Step 4: Run curl tests
echo "🚀 Step 4: Running curl API tests..."
./curl-test/10-step5-production-api.sh
echo ""

# Step 5: Validation summary
echo "🚀 Step 5: Validation Summary..."

# Check if API is responding
API_URL="http://$IRIS_HOST:$IRIS_PORT/api/mcp-interop"
echo "Performing final API validation..."

# Test each endpoint
TEST_RESULT=$(curl -s --user "$IRIS_USER:$IRIS_PASS" "$API_URL/test" | jq -r '.success' 2>/dev/null || echo "0")
STATUS_RESULT=$(curl -s --user "$IRIS_USER:$IRIS_PASS" "$API_URL/status" | jq -r '.success' 2>/dev/null || echo "0")
LIST_RESULT=$(curl -s --user "$IRIS_USER:$IRIS_PASS" "$API_URL/list" | jq -r '.success' 2>/dev/null || echo "0")

echo ""
echo "=============================================="
echo "  STEP 5 DEPLOYMENT RESULTS"
echo "=============================================="
echo ""
echo "✅ Components Deployed:"
echo "   - Api.MCPInterop.cls (REST API class)"
echo "   - Api.MCPInterop.Deploy.cls (Deployment helper)"
echo "   - Web Application: /api/mcp-interop"
echo "   - Sample.Production.Step5.cls (Test production)"
echo ""

echo "✅ Client-Proto Extensions:"
echo "   - Production management types added"
echo "   - New IrisClient methods: testProductionApi(), getProductionApiStatus(), listProductions()"
echo "   - New CLI commands: prod-check, prod-test, prod-status, prod-list"
echo ""

echo "✅ API Endpoint Validation:"
if [ "$TEST_RESULT" = "1" ]; then
    echo "   - GET /api/mcp-interop/test: ✅ Working"
else
    echo "   - GET /api/mcp-interop/test: ❌ Failed"
fi

if [ "$STATUS_RESULT" = "1" ]; then
    echo "   - GET /api/mcp-interop/status: ✅ Working"
else
    echo "   - GET /api/mcp-interop/status: ❌ Failed"
fi

if [ "$LIST_RESULT" = "1" ]; then
    echo "   - GET /api/mcp-interop/list: ✅ Working"
else
    echo "   - GET /api/mcp-interop/list: ❌ Failed"
fi

echo ""
echo "✅ Test Commands Available:"
echo "   - cd client-proto && node dist/index.js prod-check"
echo "   - cd client-proto && node dist/index.js prod-test"
echo "   - cd client-proto && node dist/index.js prod-status"
echo "   - cd client-proto && node dist/index.js prod-list"
echo "   - ./curl-test/10-step5-production-api.sh"
echo ""

if [ "$TEST_RESULT" = "1" ] && [ "$STATUS_RESULT" = "1" ] && [ "$LIST_RESULT" = "1" ]; then
    echo "🎉 STEP 5 DEPLOYMENT SUCCESSFUL!"
    echo "   Api.MCPInterop REST API is fully functional"
    echo "   Production management capabilities added to client-proto"
    echo "   All endpoints validated and working"
else
    echo "⚠️  STEP 5 DEPLOYMENT COMPLETED WITH ISSUES"
    echo "   Some API endpoints may not be working correctly"
    echo "   Check the logs above for details"
fi

echo ""
echo "=============================================="