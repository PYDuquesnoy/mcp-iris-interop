#!/bin/bash

# IRIS Atelier API - Document Operations
# Tests document listing, retrieval, and management

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Document Operations ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

echo "1. List all document types in namespace..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/*\""
echo

ALL_DOCS=$(curl -s --max-time 30 --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/*")
ALL_DOC_COUNT=$(echo "${ALL_DOCS}" | jq -r '.result.content | length // 0')
echo "Total documents found: ${ALL_DOC_COUNT}"

if [ "${ALL_DOC_COUNT}" -gt 0 ]; then
    echo "First 5 documents:"
    echo "${ALL_DOCS}" | jq -r '.result.content[0:5][] | "  - \(.name) (\(.cat))"'
fi

echo
echo "2. List only classes (CLS)..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS\""
echo

CLS_DOCS=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS")
CLS_COUNT=$(echo "${CLS_DOCS}" | jq -r '.result.content | length // 0')
echo "Classes found: ${CLS_COUNT}"

if [ "${CLS_COUNT}" -gt 0 ]; then
    echo "First 5 classes:"
    echo "${CLS_DOCS}" | jq -r '.result.content[0:5][] | "  - \(.name)"'
    
    # Get first class for detailed testing, URL encode it properly
    FIRST_CLASS=$(echo "${CLS_DOCS}" | jq -r '.result.content[0].name // ""')
    FIRST_CLASS_ENCODED=$(echo "${FIRST_CLASS}" | sed 's/%/%25/g')
    echo "Selected class for testing: ${FIRST_CLASS}"
fi

echo
echo "3. List routines (RTN)..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/RTN\""
echo

RTN_DOCS=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/RTN")
RTN_COUNT=$(echo "${RTN_DOCS}" | jq -r '.result.content | length // 0')
echo "Routines found: ${RTN_COUNT}"

if [ "${RTN_COUNT}" -gt 0 ]; then
    echo "First 3 routines:"
    echo "${RTN_DOCS}" | jq -r '.result.content[0:3][] | "  - \(.name)"'
fi

echo
echo "4. Filter documents with pattern..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=dc.*\""
echo

FILTERED_DOCS=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=dc.*")
FILTERED_COUNT=$(echo "${FILTERED_DOCS}" | jq -r '.result.content | length // 0')
echo "Classes matching 'dc.*': ${FILTERED_COUNT}"

if [ "${FILTERED_COUNT}" -gt 0 ]; then
    echo "${FILTERED_DOCS}" | jq -r '.result.content[] | "  - \(.name)"'
    
    # Use filtered class if available, otherwise use first class
    SAMPLE_CLASS=$(echo "${FILTERED_DOCS}" | jq -r '.result.content[0].name // ""')
    if [ -n "${SAMPLE_CLASS}" ]; then
        FIRST_CLASS="${SAMPLE_CLASS}"
        echo "Using sample class: ${FIRST_CLASS}"
    fi
fi

echo
echo "5. Check if specific document exists (HEAD request)..."
if [ -n "${FIRST_CLASS}" ]; then
    echo "Command: curl -I --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${FIRST_CLASS_ENCODED}\""
    echo
    
    curl -I --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${FIRST_CLASS_ENCODED}"
    
    echo
    echo "6. Retrieve document content..."
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${FIRST_CLASS_ENCODED}\""
    echo
    
    DOC_CONTENT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${FIRST_CLASS_ENCODED}")
    
    # Check if we got content
    if echo "${DOC_CONTENT}" | jq -e '.result.content' > /dev/null 2>&1; then
        echo "✅ Document retrieved successfully"
        
        DOC_NAME=$(echo "${DOC_CONTENT}" | jq -r '.result.name // "Unknown"')
        DOC_CAT=$(echo "${DOC_CONTENT}" | jq -r '.result.cat // "Unknown"')
        DOC_TS=$(echo "${DOC_CONTENT}" | jq -r '.result.ts // "Unknown"')
        CONTENT_LINES=$(echo "${DOC_CONTENT}" | jq -r '.result.content | length // 0')
        
        echo "Document Name: ${DOC_NAME}"
        echo "Category: ${DOC_CAT}"
        echo "Timestamp: ${DOC_TS}"
        echo "Content Lines: ${CONTENT_LINES}"
        
        if [ "${CONTENT_LINES}" -gt 0 ]; then
            echo "First 3 lines of content:"
            echo "${DOC_CONTENT}" | jq -r '.result.content[0:3][] | "  | \(.)"'
        fi
        
        # Save document for other tests
        echo "${DOC_CONTENT}" > "document-${FIRST_CLASS//\//-}.json"
        echo "Document saved to: document-${FIRST_CLASS//\//-}.json"
    else
        echo "❌ Failed to retrieve document content"
        echo "${DOC_CONTENT}" | jq .
    fi
else
    echo "⚠️  No suitable document found for content testing"
fi

echo
echo "7. Test document with UDL multiline format..."
if [ -n "${FIRST_CLASS}" ]; then
    echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${FIRST_CLASS_ENCODED}?format=udl-multiline\""
    echo
    
    UDL_CONTENT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${FIRST_CLASS_ENCODED}?format=udl-multiline")
    
    if echo "${UDL_CONTENT}" | jq -e '.result.content' > /dev/null 2>&1; then
        echo "✅ UDL multiline format retrieved successfully"
        UDL_LINES=$(echo "${UDL_CONTENT}" | jq -r '.result.content | length // 0')
        echo "UDL Content Lines: ${UDL_LINES}"
    else
        echo "❌ Failed to retrieve UDL format or not supported"
    fi
fi

echo
echo "8. Test non-existent document (should return 404)..."
echo "Command: curl -s -w \"%{http_code}\" --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/NonExistent.Class.cls\""
echo

HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/NonExistent.Class.cls")
echo "HTTP Status Code: ${HTTP_CODE}"

if [ "${HTTP_CODE}" = "404" ]; then
    echo "✅ Correctly returned 404 for non-existent document"
else
    echo "⚠️  Unexpected status code: ${HTTP_CODE}"
fi

echo
echo "9. Save document lists..."
echo "${ALL_DOCS}" > "documents-all.json"
echo "${CLS_DOCS}" > "documents-classes.json"
echo "${RTN_DOCS}" > "documents-routines.json"

echo "Document lists saved:"
echo "  - All documents: documents-all.json"
echo "  - Classes: documents-classes.json" 
echo "  - Routines: documents-routines.json"

echo
echo "=== Document Operations Complete ==="