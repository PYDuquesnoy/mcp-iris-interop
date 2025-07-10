#!/bin/bash

# Step 6.1 Execute Method Test: Test ObjectScript execution via REST API
# This tests the new execute endpoint functionality

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export API_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/mcp-interop"

echo "=== Step 6.1 Execute Method Test ==="
echo "Testing ObjectScript code execution via REST API"
echo "Target: ${API_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "1. Testing simple variable assignment..."
RESULT1=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"code":"Set x = 10 + 20"}' \
  "${API_BASE_URL}/execute")

echo "$RESULT1" | jq .
SUCCESS1=$(echo "$RESULT1" | jq -r '.success // 0')
if [ "$SUCCESS1" = "1" ]; then
    echo "✅ Simple variable assignment test passed"
else
    echo "❌ Simple variable assignment test failed"
fi

echo
echo "2. Testing system function call..."
RESULT2=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"code":"Set timestamp = $ZDATETIME($HOROLOG, 3)"}' \
  "${API_BASE_URL}/execute")

echo "$RESULT2" | jq .
SUCCESS2=$(echo "$RESULT2" | jq -r '.success // 0')
if [ "$SUCCESS2" = "1" ]; then
    echo "✅ System function call test passed"
else
    echo "❌ System function call test failed"
fi

echo
echo "3. Testing multiple statements..."
RESULT3=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"code":"Set a = 5 Set b = 10 Set c = a * b"}' \
  "${API_BASE_URL}/execute")

echo "$RESULT3" | jq .
SUCCESS3=$(echo "$RESULT3" | jq -r '.success // 0')
if [ "$SUCCESS3" = "1" ]; then
    echo "✅ Multiple statements test passed"
else
    echo "❌ Multiple statements test failed"
fi

echo
echo "4. Testing error handling (invalid syntax)..."
RESULT4=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"code":"This is not valid ObjectScript"}' \
  "${API_BASE_URL}/execute")

echo "$RESULT4" | jq .
SUCCESS4=$(echo "$RESULT4" | jq -r '.success // 0')
if [ "$SUCCESS4" = "0" ]; then
    echo "✅ Error handling test passed (correctly failed)"
else
    echo "❌ Error handling test failed (should have failed)"
fi

echo
echo "5. Testing empty code handling..."
RESULT5=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"code":""}' \
  "${API_BASE_URL}/execute")

echo "$RESULT5" | jq .
SUCCESS5=$(echo "$RESULT5" | jq -r '.success // 0')
if [ "$SUCCESS5" = "0" ]; then
    echo "✅ Empty code handling test passed (correctly failed)"
else
    echo "❌ Empty code handling test failed (should have failed)"
fi

echo
echo "=== Step 6.1 Test Summary ==="
TOTAL_TESTS=5
PASSED_TESTS=0

[ "$SUCCESS1" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS2" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS3" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS4" = "0" ] && ((PASSED_TESTS++))  # This should fail
[ "$SUCCESS5" = "0" ] && ((PASSED_TESTS++))  # This should fail

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ "$PASSED_TESTS" = "$TOTAL_TESTS" ]; then
    echo "🎉 All Step 6.1 Execute Method tests passed!"
    echo
    echo "✅ ObjectScript code execution via REST API is working"
    echo "✅ Error handling is implemented correctly"
    echo "✅ Input validation is working"
    echo
    echo "Step 6.1 Execute Method functionality is ready!"
else
    echo "❌ Some tests failed. Please check the implementation."
    exit 1
fi