#!/bin/bash

# Working upload test with correct format
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Testing Working Class Upload ==="

# Correct JSON format according to API spec
TEST_CONTENT='{
  "enc": false,
  "content": [
    "Class Test.WorkingUpload",
    "{",
    "",
    "/// Sample property",
    "Property Name As %String;",
    "",
    "/// Sample method",
    "ClassMethod Hello() As %String",
    "{",
    "    Return \"Hello from working upload!\"",
    "}",
    "",
    "}"
  ]
}'

echo "1. Upload class with correct format..."
echo "Payload structure:"
echo "${TEST_CONTENT}" | jq .

echo
echo "Upload command:"
UPLOAD_RESULT=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d "${TEST_CONTENT}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.WorkingUpload.cls")

echo "${UPLOAD_RESULT}" | jq .

echo
echo "2. Verify upload by downloading..."
DOWNLOAD_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.WorkingUpload.cls")

echo "${DOWNLOAD_RESULT}" | jq .result.name
CONTENT_LINES=$(echo "${DOWNLOAD_RESULT}" | jq -r '.result.content | length // 0')
echo "Content lines downloaded: ${CONTENT_LINES}"

if [ "${CONTENT_LINES}" -gt 0 ]; then
    echo "✅ Upload successful!"
    echo "First few lines:"
    echo "${DOWNLOAD_RESULT}" | jq -r '.result.content[0:3][]'
else
    echo "❌ Upload failed - no content found"
fi

echo
echo "3. Compile the uploaded class..."
COMPILE_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '["Test.WorkingUpload.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")

echo "${COMPILE_RESULT}" | jq .status

echo
echo "4. Cleanup - delete test class..."
DELETE_RESULT=$(curl -s -X DELETE \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.WorkingUpload.cls")

echo "${DELETE_RESULT}" | jq .status

echo
echo "=== Working Upload Test Complete ==="