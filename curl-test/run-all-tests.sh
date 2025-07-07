#!/bin/bash

# IRIS Atelier API - Complete Test Suite Runner
# Runs all curl test scripts in sequence

echo "=== IRIS Atelier API Complete Test Suite ==="
echo "Target: ${IRIS_HOST:-localhost}:${IRIS_PORT:-42002}"
echo "Starting tests at $(date)"
echo

# List of test scripts in order
TESTS=(
    "01-test-connection.sh"
    "02-server-info.sh" 
    "03-namespaces.sh"
    "04-documents.sh"
    "05-compilation.sh"
    "06-queries.sh"
    "07-advanced.sh"
)

PASSED=0
FAILED=0

for script in "${TESTS[@]}"; do
    if [ -f "$script" ]; then
        echo "🧪 Running: $script"
        echo "----------------------------------------"
        
        # Run the script with timeout
        if timeout 120s ./"$script"; then
            echo "✅ $script: PASSED"
            ((PASSED++))
        else
            echo "❌ $script: FAILED or TIMEOUT"
            ((FAILED++))
        fi
        
        echo
        echo "========================================"
        echo
    else
        echo "⚠️  Script not found: $script"
        ((FAILED++))
    fi
done

echo "=== Test Suite Complete ==="
echo "Tests completed at $(date)"
echo "Results: $PASSED passed, $FAILED failed"
echo

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Check output above for details."
    exit 1
fi