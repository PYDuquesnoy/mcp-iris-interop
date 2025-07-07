#!/bin/bash

# Test script to understand correct upload format
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

# Simple test class content as proper JSON array
TEST_CONTENT='{
  "name": "Test.SimpleUpload.cls",
  "content": [
    "Class Test.SimpleUpload",
    "{",
    "",
    "ClassMethod Hello() As %String",
    "{",
    "    Return \"Hello World!\"",
    "}",
    "",
    "}"
  ]
}'

echo "Testing upload with proper JSON format..."
echo "Payload:"
echo "${TEST_CONTENT}" | jq .

echo
echo "Upload command:"
UPLOAD_RESULT=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d "${TEST_CONTENT}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.SimpleUpload.cls")

echo "${UPLOAD_RESULT}" | jq .

echo
echo "Check if uploaded:"
curl -s --user "${IRIS_USER}:${IRIS_PASS}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.SimpleUpload.cls" | jq .result.name