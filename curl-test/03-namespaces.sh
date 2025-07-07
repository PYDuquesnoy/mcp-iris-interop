#!/bin/bash

# IRIS Atelier API - Namespace Operations
# Tests namespace listing and information retrieval

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Namespace Operations ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Default Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

echo "1. List all available namespaces..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/\" | jq -r '.result.content.namespaces[]'"
echo

NAMESPACES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/" | jq -r '.result.content.namespaces[]')
echo "Available namespaces:"
echo "${NAMESPACES}" | while read -r ns; do
    echo "  - ${ns}"
done

echo
echo "2. Get information about default namespace: ${IRIS_NS}"
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}\" | jq ."
echo

NS_INFO=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}")
echo "${NS_INFO}" | jq .

echo
echo "3. Test each available namespace..."
echo "${NAMESPACES}" | while read -r ns; do
    if [ -n "${ns}" ]; then
        echo "Testing namespace: ${ns}"
        echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${ns}\""
        
        NS_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${ns}")
        STATUS=$(echo "${NS_RESULT}" | jq -r '.status.summary // "OK"')
        
        if [ "${STATUS}" = "OK" ] || [ "${STATUS}" = "" ]; then
            echo "  ✅ ${ns}: Accessible"
        else
            echo "  ❌ ${ns}: ${STATUS}"
        fi
        echo
    fi
done

echo "4. Get document count for each namespace..."
echo "${NAMESPACES}" | while read -r ns; do
    if [ -n "${ns}" ]; then
        echo "Checking document count for: ${ns}"
        echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${ns}/docnames/*/*\" | jq '.result.content | length'"
        
        DOC_COUNT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${ns}/docnames/*/*" 2>/dev/null | jq -r '.result.content | length // 0' 2>/dev/null)
        
        if [ "${DOC_COUNT}" != "null" ] && [ "${DOC_COUNT}" != "0" ]; then
            echo "  📄 ${ns}: ${DOC_COUNT} documents"
        else
            echo "  📄 ${ns}: No documents or access denied"
        fi
        echo
    fi
done

echo "5. Test namespace with invalid name (should fail)..."
echo "Command: curl -s -w \"%{http_code}\" --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/INVALIDNS\""
echo

HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/INVALIDNS")
echo "HTTP Status Code: ${HTTP_CODE}"

if [ "${HTTP_CODE}" = "404" ] || [ "${HTTP_CODE}" = "400" ]; then
    echo "✅ Correctly rejected invalid namespace"
else
    echo "⚠️  Unexpected status code for invalid namespace: ${HTTP_CODE}"
fi

echo
echo "6. Save namespace information..."
echo "${NAMESPACES}" > namespaces.txt
echo "${NS_INFO}" > "namespace-${IRIS_NS}.json"
echo "Namespace list saved to: namespaces.txt"
echo "Default namespace info saved to: namespace-${IRIS_NS}.json"

echo
echo "=== Namespace Operations Complete ==="