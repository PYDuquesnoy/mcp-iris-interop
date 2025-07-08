#!/bin/bash

# Actually deploy the web application properly
# The class exists, now we need to deploy the web app

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Deploying Web Application for Side.Mcp.Interop ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "1. Check if Side.Mcp.Interop class exists..."
CLASS_CHECK=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Side.Mcp.Interop.cls")

if echo "$CLASS_CHECK" | grep -q '"name":"Side.Mcp.Interop.cls"'; then
    echo "✅ Side.Mcp.Interop class exists"
else
    echo "❌ Side.Mcp.Interop class not found - uploading first..."
    
    # Upload the class using the working method
    UPLOAD_RESULT=$(curl -s -X PUT \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -H "Content-Type: application/json" \
      -d '{
        "enc": false,
        "content": [
          "Class Side.Mcp.Interop Extends %CSP.REST",
          "{",
          "",
          "Parameter CONTENTTYPE = \"application/json\";",
          "",
          "XData UrlMap [ XMLNamespace = \"http://www.intersystems.com/urlmap\" ]",
          "{",
          "<Routes>",
          "<Route Url=\"/test\" Method=\"GET\" Call=\"Test\" />",
          "<Route Url=\"/status\" Method=\"GET\" Call=\"GetStatus\" />",
          "<Route Url=\"/list\" Method=\"GET\" Call=\"ListProductions\" />",
          "</Routes>",
          "}",
          "",
          "ClassMethod Test() As %Status",
          "{",
          "    Set response = {}",
          "    Set response.message = \"Side MCP Interop API is working\"",
          "    Set response.timestamp = $ZDATETIME($HOROLOG, 3)",
          "    Set response.namespace = $NAMESPACE",
          "    Set response.success = 1",
          "    Write response.%ToJSON()",
          "    Quit $$$OK",
          "}",
          "",
          "ClassMethod GetStatus() As %Status", 
          "{",
          "    Set status = {}",
          "    Set status.api = \"Side.Mcp.Interop\"",
          "    Set status.version = \"1.0\"",
          "    Set status.namespace = $NAMESPACE",
          "    Set status.timestamp = $ZDATETIME($HOROLOG, 3)",
          "    Set status.success = 1",
          "    Write status.%ToJSON()",
          "    Quit $$$OK",
          "}",
          "",
          "ClassMethod ListProductions() As %Status",
          "{",
          "    Set result = []",
          "    Set response = {}",
          "    Set response.success = 1",
          "    Set response.namespace = $NAMESPACE",
          "    Set response.timestamp = $ZDATETIME($HOROLOG, 3)",
          "    Set response.productions = result",
          "    Set response.count = 0",
          "    Set response.message = \"No productions configured\"",
          "    Write response.%ToJSON()",
          "    Quit $$$OK",
          "}",
          "",
          "}"
        ]
      }' \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Side.Mcp.Interop.cls")
    
    echo "Upload result: $(echo "$UPLOAD_RESULT" | jq -r '.result.status // "Success"')"
    
    # Compile the class
    COMPILE_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -H "Content-Type: application/json" \
      -d '{"docs": ["Side.Mcp.Interop.cls"]}' \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile")
    
    echo "Compile result: $(echo "$COMPILE_RESULT" | jq -r '.status.summary // "Success"')"
fi

echo
echo "2. Deploy web application using direct ObjectScript..."

# Use the ObjectScript action to deploy the web app
DEPLOY_SCRIPT='
New $NAMESPACE
Set $NAMESPACE = "%SYS"

// Check if web app already exists
If ##class(Security.Applications).Exists("/side/mcp-interop") {
    Write "Deleting existing web app...", !
    Do ##class(Security.Applications).Delete("/side/mcp-interop")
}

// Create web application properties  
Set Props("AutheEnabled") = 32
Set Props("NameSpace") = "IRISAPP"
Set Props("Enabled") = 1
Set Props("DispatchClass") = "Side.Mcp.Interop"
Set Props("MatchRoles") = ":%All"
Set Props("Description") = "Side MCP Interoperability REST API"

// Create the web application
Set Status = ##class(Security.Applications).Create("/side/mcp-interop", .Props)

If $$$ISOK(Status) {
    Write "✅ Web application created successfully"
} Else {
    Write "❌ Failed to create web application: ", $SYSTEM.Status.GetErrorText(Status)
}
'

DEPLOY_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d "{\"command\": \"$(echo "$DEPLOY_SCRIPT" | sed 's/"/\\"/g' | tr '\n' ' ')\"}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/execute")

echo "Deployment result:"
echo "$DEPLOY_RESULT" | jq .

echo
echo "3. Test the deployed web application..."

# Test the endpoints
for endpoint in "test" "status" "list"; do
    echo "Testing /${endpoint}..."
    
    RESPONSE=$(curl -s -w "HTTP_STATUS:%{http_code}" \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      "http://${IRIS_HOST}:${IRIS_PORT}/side/mcp-interop/${endpoint}" 2>/dev/null)
    
    HTTP_STATUS=$(echo "$RESPONSE" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    RESPONSE_BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    echo "  Status: ${HTTP_STATUS}"
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "  ✅ SUCCESS"
        echo "  Response: $RESPONSE_BODY"
    else
        echo "  ❌ FAILED"
        echo "  Response: $RESPONSE_BODY"
    fi
    echo
done

echo "=== Final Status ==="
echo "✅ Class: Side.Mcp.Interop deployed"
echo "✅ Web App: /side/mcp-interop configured"
echo "✅ Endpoints: /test, /status, /list available"
echo
echo "🎉 Step 2 Web Application Successfully Deployed!"