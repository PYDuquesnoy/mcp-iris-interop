#!/bin/bash

# Upload the ObjectScript stored procedure class to IRIS
# This script uses the same pattern as the client-proto upload functionality

# Set environment variables
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Uploading ExecProto.ObjectScript Class ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

# Read the class content
CLASS_FILE="server-classes/ExecProto.ObjectScript.cls"
if [ ! -f "$CLASS_FILE" ]; then
    echo "❌ Class file not found: $CLASS_FILE"
    exit 1
fi

# Read the content and escape for JSON
CLASS_CONTENT=$(cat "$CLASS_FILE")

# Create the JSON payload with proper escaping
JSON_PAYLOAD=$(cat <<EOF
{
  "enc": false,
  "content": [
    {
      "name": "ExecProto.ObjectScript.cls",
      "content": $(echo "$CLASS_CONTENT" | jq -R -s .)
    }
  ]
}
EOF
)

# Upload the class
echo "1. Uploading class..."
UPLOAD_RESULT=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/ExecProto.ObjectScript.cls")

echo "$UPLOAD_RESULT" | jq .

# Check upload status
UPLOAD_STATUS=$(echo "$UPLOAD_RESULT" | jq -r '.status.summary // ""')
if [ -z "$UPLOAD_STATUS" ]; then
    echo "✅ Class uploaded successfully"
else
    echo "❌ Class upload failed: $UPLOAD_STATUS"
    exit 1
fi

echo
echo "2. Compiling class..."
COMPILE_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"docs": ["ExecProto.ObjectScript.cls"]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile")

echo "$COMPILE_RESULT" | jq .

# Check compile status
COMPILE_STATUS=$(echo "$COMPILE_RESULT" | jq -r '.status.summary // ""')
if [ -z "$COMPILE_STATUS" ]; then
    echo "✅ Class compiled successfully"
else
    echo "❌ Class compilation failed: $COMPILE_STATUS"
    exit 1
fi

echo
echo "3. Testing stored procedure..."
TEST_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"query":"CALL ExecProto.ObjectScript_Test()","parameters":[]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "$TEST_RESULT" | jq .

TEST_STATUS=$(echo "$TEST_RESULT" | jq -r '.status.summary // ""')
if [ -z "$TEST_STATUS" ]; then
    echo "✅ Stored procedure test executed successfully"
    TEST_CONTENT=$(echo "$TEST_RESULT" | jq -r '.result.content[0] // ""')
    echo "Test result: $TEST_CONTENT"
else
    echo "❌ Stored procedure test failed: $TEST_STATUS"
fi

echo
echo "=== Upload Complete ==="