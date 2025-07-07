#!/bin/bash

# IRIS Atelier API - Advanced Operations
# Tests advanced features like search, indexing, and system operations

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Advanced Operations ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

# Check API version for feature availability
echo "1. Check API version for advanced features..."
API_VERSION=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/" | jq -r '.result.content.api // 0')
echo "API Version: ${API_VERSION}"

if [ "${API_VERSION}" -ge 2 ]; then
    echo "✅ Advanced features available (API v${API_VERSION})"
    
    echo
    echo "2. Content search (API v2+)..."
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  \"${IRIS_BASE_URL}/v2/${IRIS_NS}/action/search?query=class&files=*.cls&max=5\""
    echo
    
    SEARCH_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
      "${IRIS_BASE_URL}/v2/${IRIS_NS}/action/search?query=class&files=*.cls&max=5")
    
    echo "${SEARCH_RESULT}" | jq .
    
    SEARCH_STATUS=$(echo "${SEARCH_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${SEARCH_STATUS}" ]; then
        echo "✅ Content search executed successfully"
        SEARCH_COUNT=$(echo "${SEARCH_RESULT}" | jq -r '.result.content | length // 0')
        echo "Search results found: ${SEARCH_COUNT}"
        
        if [ "${SEARCH_COUNT}" -gt 0 ]; then
            echo "Sample search results:"
            echo "${SEARCH_RESULT}" | jq -r '.result.content[0:3][] | "  - \(.doc): \(.matches | length) matches"'
        fi
    else
        echo "⚠️  Content search failed: ${SEARCH_STATUS}"
    fi
    
    echo
    echo "3. Search with regex pattern..."
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  \"${IRIS_BASE_URL}/v2/${IRIS_NS}/action/search?query=Method.*%5C%28&regex=true&files=*.cls&max=3\""
    echo
    
    REGEX_SEARCH_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
      "${IRIS_BASE_URL}/v2/${IRIS_NS}/action/search?query=Method.*%5C%28&regex=true&files=*.cls&max=3")
    
    echo "${REGEX_SEARCH_RESULT}" | jq .
    
    REGEX_SEARCH_STATUS=$(echo "${REGEX_SEARCH_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${REGEX_SEARCH_STATUS}" ]; then
        echo "✅ Regex search executed successfully"
    else
        echo "⚠️  Regex search failed: ${REGEX_SEARCH_STATUS}"
    fi
    
    echo
    echo "4. Case-sensitive search..."
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  \"${IRIS_BASE_URL}/v2/${IRIS_NS}/action/search?query=Class&case=true&files=*.cls&max=3\""
    echo
    
    CASE_SEARCH_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
      "${IRIS_BASE_URL}/v2/${IRIS_NS}/action/search?query=Class&case=true&files=*.cls&max=3")
    
    echo "${CASE_SEARCH_RESULT}" | jq .
    
    CASE_SEARCH_STATUS=$(echo "${CASE_SEARCH_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${CASE_SEARCH_STATUS}" ]; then
        echo "✅ Case-sensitive search executed successfully"
    else
        echo "⚠️  Case-sensitive search failed: ${CASE_SEARCH_STATUS}"
    fi
else
    echo "⚠️  Advanced search features not available (API v${API_VERSION} < 2)"
fi

echo
echo "5. Document indexing (API v1+)..."
# Get some documents to index
SAMPLE_DOCS=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS" | jq -c '[.result.content[0:2][].name]')

if [ "${SAMPLE_DOCS}" != "null" ] && [ "${SAMPLE_DOCS}" != "[]" ]; then
    echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '${SAMPLE_DOCS}' \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/index\""
    echo
    
    INDEX_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d "${SAMPLE_DOCS}" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/index")
    
    echo "${INDEX_RESULT}" | jq .
    
    INDEX_STATUS=$(echo "${INDEX_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${INDEX_STATUS}" ]; then
        echo "✅ Document indexing completed successfully"
    else
        echo "⚠️  Document indexing completed with status: ${INDEX_STATUS}"
    fi
else
    echo "⚠️  No documents available for indexing"
fi

echo
echo "6. Get system jobs (API v1+)..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  \"${IRIS_BASE_URL}/v1/%25SYS/jobs?system=false\""
echo

JOBS_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
  "${IRIS_BASE_URL}/v1/%25SYS/jobs?system=false")

echo "${JOBS_RESULT}" | jq .

JOBS_STATUS=$(echo "${JOBS_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${JOBS_STATUS}" ]; then
    echo "✅ Jobs list retrieved successfully"
    JOB_COUNT=$(echo "${JOBS_RESULT}" | jq -r '.result.content | length // 0')
    echo "Jobs found: ${JOB_COUNT}"
    
    if [ "${JOB_COUNT}" -gt 0 ]; then
        echo "Sample jobs:"
        echo "${JOBS_RESULT}" | jq -r '.result.content[0:3][] | "  - PID: \(.pid), Namespace: \(.namespace), State: \(.state)"'
    fi
else
    echo "⚠️  Jobs list failed: ${JOBS_STATUS}"
fi

echo
echo "7. Get CSP applications (API v1+)..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  \"${IRIS_BASE_URL}/v1/%25SYS/cspapps/${IRIS_NS}?detail=1\""
echo

CSP_APPS_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
  "${IRIS_BASE_URL}/v1/%25SYS/cspapps/${IRIS_NS}?detail=1")

echo "${CSP_APPS_RESULT}" | jq .

CSP_APPS_STATUS=$(echo "${CSP_APPS_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${CSP_APPS_STATUS}" ]; then
    echo "✅ CSP applications list retrieved successfully"
    APP_COUNT=$(echo "${CSP_APPS_RESULT}" | jq -r '.result.content | length // 0')
    echo "CSP applications found: ${APP_COUNT}"
    
    if [ "${APP_COUNT}" -gt 0 ]; then
        echo "Sample applications:"
        echo "${CSP_APPS_RESULT}" | jq -r '.result.content[0:3][] | "  - \(.Name): \(.Path)"'
    fi
else
    echo "⚠️  CSP applications list failed: ${CSP_APPS_STATUS}"
fi

if [ "${API_VERSION}" -ge 2 ]; then
    echo
    echo "8. Get CSP debug ID (API v2+)..."
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  \"${IRIS_BASE_URL}/v2/%25SYS/cspdebugid\""
    echo
    
    DEBUG_ID_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
      "${IRIS_BASE_URL}/v2/%25SYS/cspdebugid")
    
    echo "${DEBUG_ID_RESULT}" | jq .
    
    DEBUG_ID_STATUS=$(echo "${DEBUG_ID_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${DEBUG_ID_STATUS}" ]; then
        echo "✅ CSP debug ID retrieved successfully"
        DEBUG_ID=$(echo "${DEBUG_ID_RESULT}" | jq -r '.result.content // ""')
        echo "Debug ID: ${DEBUG_ID}"
    else
        echo "⚠️  CSP debug ID failed: ${DEBUG_ID_STATUS}"
    fi
fi

if [ "${API_VERSION}" -ge 2 ]; then
    echo
    echo "9. Test macro operations (API v2+)..."
    # Get a sample class for macro testing
    SAMPLE_CLASS=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS" | jq -r '.result.content[0].name // ""')
    
    if [ -n "${SAMPLE_CLASS}" ]; then
        echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
        echo "  -H \"Content-Type: application/json\" \\"
        echo "  -d '{\"docname\":\"${SAMPLE_CLASS}\",\"includes\":[]}' \\"
        echo "  \"${IRIS_BASE_URL}/v2/${IRIS_NS}/action/getmacrolist\""
        echo
        
        MACRO_LIST_RESULT=$(curl -s -X POST \
          --user "${IRIS_USER}:${IRIS_PASS}" \
          -b "${COOKIE_JAR}" \
          -H "Content-Type: application/json" \
          -d "{\"docname\":\"${SAMPLE_CLASS}\",\"includes\":[]}" \
          "${IRIS_BASE_URL}/v2/${IRIS_NS}/action/getmacrolist")
        
        echo "${MACRO_LIST_RESULT}" | jq .
        
        MACRO_LIST_STATUS=$(echo "${MACRO_LIST_RESULT}" | jq -r '.status.summary // ""')
        if [ -z "${MACRO_LIST_STATUS}" ]; then
            echo "✅ Macro list retrieved successfully"
            MACRO_COUNT=$(echo "${MACRO_LIST_RESULT}" | jq -r '.result.content | length // 0')
            echo "Macros found: ${MACRO_COUNT}"
        else
            echo "⚠️  Macro list failed: ${MACRO_LIST_STATUS}"
        fi
    else
        echo "⚠️  No sample class available for macro testing"
    fi
fi

if [ "${API_VERSION}" -ge 1 ]; then
    echo
    echo "10. Get Ensemble classes (API v1+, if Ensemble/Interoperability enabled)..."
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/ens/classes/1\""
    echo
    
    ENS_CLASSES_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/ens/classes/1")
    
    echo "${ENS_CLASSES_RESULT}" | jq .
    
    ENS_CLASSES_STATUS=$(echo "${ENS_CLASSES_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${ENS_CLASSES_STATUS}" ]; then
        echo "✅ Ensemble classes retrieved successfully"
        ENS_COUNT=$(echo "${ENS_CLASSES_RESULT}" | jq -r '.result.content | length // 0')
        echo "Ensemble classes found: ${ENS_COUNT}"
        
        if [ "${ENS_COUNT}" -gt 0 ]; then
            echo "Sample Ensemble classes:"
            echo "${ENS_CLASSES_RESULT}" | jq -r '.result.content[0:3][] | "  - \(.)"'
        fi
    else
        echo "⚠️  Ensemble classes failed (may not be enabled): ${ENS_CLASSES_STATUS}"
    fi
fi

echo
echo "11. Test error handling with invalid endpoint..."
echo "Command: curl -s -w \"%{http_code}\" --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/invalid/endpoint\""
echo

HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/invalid/endpoint")

echo "HTTP Status Code: ${HTTP_CODE}"

if [ "${HTTP_CODE}" = "404" ]; then
    echo "✅ Correctly returned 404 for invalid endpoint"
else
    echo "⚠️  Unexpected status code: ${HTTP_CODE}"
fi

echo
echo "12. Save advanced operation results..."
if [ -n "${SEARCH_RESULT}" ]; then
    echo "${SEARCH_RESULT}" > "search-content.json"
fi
if [ -n "${JOBS_RESULT}" ]; then
    echo "${JOBS_RESULT}" > "system-jobs.json"
fi
if [ -n "${CSP_APPS_RESULT}" ]; then
    echo "${CSP_APPS_RESULT}" > "csp-apps.json"
fi
if [ -n "${ENS_CLASSES_RESULT}" ]; then
    echo "${ENS_CLASSES_RESULT}" > "ensemble-classes.json"
fi

echo "Advanced operation results saved to corresponding JSON files"

echo
echo "=== Advanced Operations Complete ==="
echo
echo "API Feature Summary:"
echo "  - Basic operations (v1+): ✅ Available"
if [ "${API_VERSION}" -ge 2 ]; then
    echo "  - Search operations (v2+): ✅ Available"
    echo "  - Macro operations (v2+): ✅ Available"
    echo "  - Debug operations (v2+): ✅ Available"
else
    echo "  - Advanced features (v2+): ❌ Not available (API v${API_VERSION})"
fi
if [ "${API_VERSION}" -ge 7 ]; then
    echo "  - XML operations (v7+): ✅ Available"
    echo "  - Terminal support (v7+): ✅ Available"
else
    echo "  - XML/Terminal features (v7+): ❌ Not available (API v${API_VERSION})"
fi