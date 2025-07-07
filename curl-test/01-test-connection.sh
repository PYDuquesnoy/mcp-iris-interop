#!/bin/bash

# IRIS Atelier API - Connection Test
# Tests basic connectivity and authentication

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Atelier API Connection Test ==="
echo "Target: ${IRIS_BASE_URL}"
echo "User: ${IRIS_USER}"
echo

# Create cookie jar for session management
COOKIE_JAR="cookies.txt"

echo "1. Testing basic connectivity with HEAD request..."
echo "Command: curl -i -I --max-time 10 --user \"${IRIS_USER}:${IRIS_PASS}\" -c \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/\""
echo

curl -i -I \
  --max-time 10 \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -c "${COOKIE_JAR}" \
  "${IRIS_BASE_URL}/"

echo
echo "2. Testing authentication with GET request..."
echo "Command: curl -s --max-time 10 --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/\" | jq ."
echo

curl -s \
  --max-time 10 \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  "${IRIS_BASE_URL}/" | jq .

echo
echo "3. Checking if server supports expected API version (should be >= 1)..."
API_VERSION=$(curl -s --max-time 10 --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/" | jq -r '.result.content.api // 0')
echo "Detected API Version: ${API_VERSION}"

if [ "${API_VERSION}" -ge 1 ]; then
    echo "✅ API version ${API_VERSION} is supported"
else
    echo "❌ API version ${API_VERSION} is too low (minimum: 1)"
    exit 1
fi

echo
echo "4. Testing connection with invalid credentials (should fail)..."
echo "Command: curl -s -w \"%{http_code}\" --user \"invalid:invalid\" \"${IRIS_BASE_URL}/\""
echo

HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null --user "invalid:invalid" "${IRIS_BASE_URL}/")
echo "HTTP Status Code: ${HTTP_CODE}"

if [ "${HTTP_CODE}" = "401" ]; then
    echo "✅ Authentication working correctly (401 for invalid credentials)"
else
    echo "❌ Unexpected status code: ${HTTP_CODE}"
fi

echo
echo "=== Connection Test Complete ==="
echo "Cookie jar saved as: ${COOKIE_JAR}"
echo "Use this cookie jar in subsequent requests for session persistence."