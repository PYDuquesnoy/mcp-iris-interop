#!/bin/bash

# Upload ExecProto classes to IRIS using the working pattern from curl-test
# This script follows the same pattern as the successful 09-step4-validation.sh

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Uploading ExecProto Classes ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

# Convert ExecProto.Simple.cls to JSON array format
echo "1. Converting ExecProto.Simple.cls to JSON format..."
SIMPLE_CLASS_CONTENT=$(cat server-classes/ExecProto.Simple.cls | jq -R -s 'split("\n")[:-1]')

SIMPLE_CLASS_JSON="{
  \"enc\": false,
  \"content\": ${SIMPLE_CLASS_CONTENT}
}"

echo "2. Uploading ExecProto.Simple class..."
SIMPLE_UPLOAD=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "${SIMPLE_CLASS_JSON}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/ExecProto.Simple.cls")

echo "${SIMPLE_UPLOAD}" | jq .status

SIMPLE_UPLOAD_STATUS=$(echo "${SIMPLE_UPLOAD}" | jq -r '.status.summary // ""')
if [ -z "${SIMPLE_UPLOAD_STATUS}" ]; then
    echo "✅ ExecProto.Simple uploaded successfully"
else
    echo "❌ ExecProto.Simple upload failed: ${SIMPLE_UPLOAD_STATUS}"
    exit 1
fi

echo
echo "3. Compiling ExecProto.Simple class..."
SIMPLE_COMPILE=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '["ExecProto.Simple.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")

echo "${SIMPLE_COMPILE}" | jq .status

SIMPLE_COMPILE_STATUS=$(echo "${SIMPLE_COMPILE}" | jq -r '.status.summary // ""')
if [ -z "${SIMPLE_COMPILE_STATUS}" ]; then
    echo "✅ ExecProto.Simple compiled successfully"
    echo "Compilation output:"
    echo "${SIMPLE_COMPILE}" | jq -r '.console[]?'
else
    echo "❌ ExecProto.Simple compilation failed: ${SIMPLE_COMPILE_STATUS}"
    exit 1
fi

echo
echo "4. Converting ExecProto.ObjectScript.cls to JSON format..."
OBJECTSCRIPT_CLASS_CONTENT=$(cat server-classes/ExecProto.ObjectScript.cls | jq -R -s 'split("\n")[:-1]')

OBJECTSCRIPT_CLASS_JSON="{
  \"enc\": false,
  \"content\": ${OBJECTSCRIPT_CLASS_CONTENT}
}"

echo "5. Uploading ExecProto.ObjectScript class..."
OBJECTSCRIPT_UPLOAD=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "${OBJECTSCRIPT_CLASS_JSON}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/ExecProto.ObjectScript.cls")

echo "${OBJECTSCRIPT_UPLOAD}" | jq .status

OBJECTSCRIPT_UPLOAD_STATUS=$(echo "${OBJECTSCRIPT_UPLOAD}" | jq -r '.status.summary // ""')
if [ -z "${OBJECTSCRIPT_UPLOAD_STATUS}" ]; then
    echo "✅ ExecProto.ObjectScript uploaded successfully"
else
    echo "❌ ExecProto.ObjectScript upload failed: ${OBJECTSCRIPT_UPLOAD_STATUS}"
    exit 1
fi

echo
echo "6. Compiling ExecProto.ObjectScript class..."
OBJECTSCRIPT_COMPILE=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '["ExecProto.ObjectScript.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")

echo "${OBJECTSCRIPT_COMPILE}" | jq .status

OBJECTSCRIPT_COMPILE_STATUS=$(echo "${OBJECTSCRIPT_COMPILE}" | jq -r '.status.summary // ""')
if [ -z "${OBJECTSCRIPT_COMPILE_STATUS}" ]; then
    echo "✅ ExecProto.ObjectScript compiled successfully"
    echo "Compilation output:"
    echo "${OBJECTSCRIPT_COMPILE}" | jq -r '.console[]?'
else
    echo "❌ ExecProto.ObjectScript compilation failed: ${OBJECTSCRIPT_COMPILE_STATUS}"
    exit 1
fi

echo
echo "=== Classes Upload Complete ==="
echo "✅ ExecProto.Simple - Uploaded and compiled"
echo "✅ ExecProto.ObjectScript - Uploaded and compiled"
echo
echo "Classes are now available as stored procedures in IRIS namespace: ${IRIS_NS}"