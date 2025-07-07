#!/bin/bash

# IRIS Atelier API - Compilation Operations
# Tests document compilation and build processes

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Compilation Operations ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

echo "1. Find sample classes to compile..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=dc.*\""
echo

SAMPLE_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=dc.*")
CLASS_COUNT=$(echo "${SAMPLE_CLASSES}" | jq -r '.result.content | length // 0')

echo "Sample classes found: ${CLASS_COUNT}"

if [ "${CLASS_COUNT}" -gt 0 ]; then
    echo "Available sample classes:"
    echo "${SAMPLE_CLASSES}" | jq -r '.result.content[] | "  - \(.name)"'
    
    # Get first few classes for compilation
    COMPILE_CLASSES=$(echo "${SAMPLE_CLASSES}" | jq -r '.result.content[0:2][] | .name' | tr '\n' ' ')
    FIRST_CLASS=$(echo "${SAMPLE_CLASSES}" | jq -r '.result.content[0].name // ""')
    
    echo "Selected for compilation: ${COMPILE_CLASSES}"
else
    echo "⚠️  No sample classes found, will try with any available class..."
    
    ALL_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS")
    FIRST_CLASS=$(echo "${ALL_CLASSES}" | jq -r '.result.content[0].name // ""')
    
    if [ -n "${FIRST_CLASS}" ]; then
        COMPILE_CLASSES="${FIRST_CLASS}"
        echo "Using available class: ${FIRST_CLASS}"
    else
        echo "❌ No classes available for compilation testing"
        exit 1
    fi
fi

echo
echo "2. Compile single document..."
if [ -n "${FIRST_CLASS}" ]; then
    echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '[\"${FIRST_CLASS}\"]' \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile\""
    echo
    
    COMPILE_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d "[\"${FIRST_CLASS}\"]" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile")
    
    echo "${COMPILE_RESULT}" | jq .
    
    # Check compilation status
    COMPILE_STATUS=$(echo "${COMPILE_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${COMPILE_STATUS}" ]; then
        echo "✅ Compilation completed successfully"
    else
        echo "⚠️  Compilation completed with status: ${COMPILE_STATUS}"
    fi
    
    # Check for console output
    CONSOLE_OUTPUT=$(echo "${COMPILE_RESULT}" | jq -r '.console[]? // empty')
    if [ -n "${CONSOLE_OUTPUT}" ]; then
        echo "Console output:"
        echo "${CONSOLE_OUTPUT}"
    fi
fi

echo
echo "3. Compile with specific flags (cuk = compile, update, keep source)..."
if [ -n "${FIRST_CLASS}" ]; then
    echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '[\"${FIRST_CLASS}\"]' \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk\""
    echo
    
    COMPILE_FLAGS_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d "[\"${FIRST_CLASS}\"]" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")
    
    echo "${COMPILE_FLAGS_RESULT}" | jq .
    
    COMPILE_FLAGS_STATUS=$(echo "${COMPILE_FLAGS_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${COMPILE_FLAGS_STATUS}" ]; then
        echo "✅ Compilation with flags completed successfully"
    else
        echo "⚠️  Compilation with flags completed with status: ${COMPILE_FLAGS_STATUS}"
    fi
fi

echo
echo "4. Compile multiple documents..."
if [ "${CLASS_COUNT}" -gt 1 ]; then
    MULTI_CLASSES=$(echo "${SAMPLE_CLASSES}" | jq -c '[.result.content[0:2][].name]')
    
    echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '${MULTI_CLASSES}' \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile\""
    echo
    
    MULTI_COMPILE_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d "${MULTI_CLASSES}" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile")
    
    echo "${MULTI_COMPILE_RESULT}" | jq .
    
    MULTI_COMPILE_STATUS=$(echo "${MULTI_COMPILE_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${MULTI_COMPILE_STATUS}" ]; then
        echo "✅ Multi-document compilation completed successfully"
    else
        echo "⚠️  Multi-document compilation completed with status: ${MULTI_COMPILE_STATUS}"
    fi
else
    echo "⚠️  Only one class available, skipping multi-document compilation"
fi

echo
echo "5. Test compilation with source flag..."
if [ -n "${FIRST_CLASS}" ]; then
    echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '[\"${FIRST_CLASS}\"]' \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?source=true\""
    echo
    
    SOURCE_COMPILE_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d "[\"${FIRST_CLASS}\"]" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?source=true")
    
    echo "${SOURCE_COMPILE_RESULT}" | jq .
    
    SOURCE_COMPILE_STATUS=$(echo "${SOURCE_COMPILE_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${SOURCE_COMPILE_STATUS}" ]; then
        echo "✅ Source compilation completed successfully"
    else
        echo "⚠️  Source compilation completed with status: ${SOURCE_COMPILE_STATUS}"
    fi
fi

echo
echo "6. Test compilation of non-existent document (should fail gracefully)..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '[\"NonExistent.Class.cls\"]' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile\""
echo

FAIL_COMPILE_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '["NonExistent.Class.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile")

echo "${FAIL_COMPILE_RESULT}" | jq .

FAIL_STATUS=$(echo "${FAIL_COMPILE_RESULT}" | jq -r '.status.summary // ""')
if [ -n "${FAIL_STATUS}" ]; then
    echo "✅ Correctly failed to compile non-existent document: ${FAIL_STATUS}"
else
    echo "⚠️  Unexpected success for non-existent document"
fi

echo
echo "7. Test async compilation (if API version >= 1)..."
if [ -n "${FIRST_CLASS}" ]; then
    echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"request\":\"compile\",\"documents\":[\"${FIRST_CLASS}\"],\"flags\":\"cuk\"}' \\"
    echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/work\""
    echo
    
    ASYNC_RESULT=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d "{\"request\":\"compile\",\"documents\":[\"${FIRST_CLASS}\"],\"flags\":\"cuk\"}" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/work")
    
    echo "${ASYNC_RESULT}" | jq .
    
    # Check if we got a job ID
    JOB_LOCATION=$(echo "${ASYNC_RESULT}" | jq -r '.result.location // ""')
    if [ -n "${JOB_LOCATION}" ]; then
        echo "✅ Async compilation queued, job ID: ${JOB_LOCATION}"
        
        echo
        echo "8. Poll async compilation result..."
        echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/work/${JOB_LOCATION}\""
        echo
        
        # Poll a few times
        for i in {1..3}; do
            sleep 1
            POLL_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/work/${JOB_LOCATION}")
            echo "Poll attempt ${i}:"
            echo "${POLL_RESULT}" | jq .
            
            # Check if job is complete
            RETRY_AFTER=$(echo "${POLL_RESULT}" | jq -r '.retryafter // ""')
            if [ -z "${RETRY_AFTER}" ]; then
                echo "✅ Async compilation completed"
                break
            else
                echo "⏳ Job still running, retry after: ${RETRY_AFTER}s"
            fi
        done
    else
        echo "⚠️  Async compilation not supported or failed to queue"
    fi
fi

echo
echo "9. Save compilation results..."
if [ -n "${COMPILE_RESULT}" ]; then
    echo "${COMPILE_RESULT}" > "compile-single.json"
fi
if [ -n "${MULTI_COMPILE_RESULT}" ]; then
    echo "${MULTI_COMPILE_RESULT}" > "compile-multi.json"
fi
if [ -n "${ASYNC_RESULT}" ]; then
    echo "${ASYNC_RESULT}" > "compile-async.json"
fi

echo "Compilation results saved to compile-*.json files"

echo
echo "=== Compilation Operations Complete ==="