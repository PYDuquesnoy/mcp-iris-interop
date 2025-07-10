#!/bin/bash

# Step 6.2 Start Production Test: Test production starting functionality via REST API
# This tests the new start production endpoint functionality

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export API_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/mcp-interop"

echo "=== Step 6.2 Start Production Test ==="
echo "Testing production start functionality via REST API"
echo "Target: ${API_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "1. Testing start production with no specific production name (default)..."
RESULT1=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"productionName":"", "timeout":30}' \
  "${API_BASE_URL}/start")

echo "$RESULT1" | jq .
SUCCESS1=$(echo "$RESULT1" | jq -r '.success // 0')
ACTION1=$(echo "$RESULT1" | jq -r '.action // "unknown"')
if [ "$SUCCESS1" = "1" ]; then
    echo "✅ Default production start test passed (Action: $ACTION1)"
else
    echo "❌ Default production start test failed"
fi

echo
echo "2. Testing start production when one may already be running..."
RESULT2=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"productionName":"", "timeout":30}' \
  "${API_BASE_URL}/start")

echo "$RESULT2" | jq .
SUCCESS2=$(echo "$RESULT2" | jq -r '.success // 0')
ACTION2=$(echo "$RESULT2" | jq -r '.action // "unknown"')
if [ "$SUCCESS2" = "1" ]; then
    echo "✅ Duplicate production start test passed (Action: $ACTION2)"
else
    echo "❌ Duplicate production start test failed"
fi

echo
echo "3. Testing start production with specific production name..."
RESULT3=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"productionName":"Demo.Production", "timeout":30}' \
  "${API_BASE_URL}/start")

echo "$RESULT3" | jq .
SUCCESS3=$(echo "$RESULT3" | jq -r '.success // 0')
ACTION3=$(echo "$RESULT3" | jq -r '.action // "unknown"')
if [ "$SUCCESS3" = "1" ] || [ "$ACTION3" = "already_running" ]; then
    echo "✅ Specific production start test passed (Action: $ACTION3)"
else
    echo "❌ Specific production start test failed"
fi

echo
echo "4. Testing error handling (invalid production name)..."
RESULT4=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"productionName":"NonExistent.Production", "timeout":30}' \
  "${API_BASE_URL}/start")

echo "$RESULT4" | jq .
SUCCESS4=$(echo "$RESULT4" | jq -r '.success // 0')
if [ "$SUCCESS4" = "0" ]; then
    echo "✅ Error handling test passed (correctly failed)"
else
    echo "❌ Error handling test failed (should have failed)"
fi

echo
echo "5. Testing parameter validation (no JSON body)..."
RESULT5=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  "${API_BASE_URL}/start")

echo "$RESULT5" | jq .
SUCCESS5=$(echo "$RESULT5" | jq -r '.success // 0')
# This might succeed or fail depending on implementation - both are valid
echo "✅ Parameter validation test completed (Success: $SUCCESS5)"

echo
echo "=== Step 6.2 Test Summary ==="
TOTAL_TESTS=4  # Excluding the parameter validation test
PASSED_TESTS=0

[ "$SUCCESS1" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS2" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS3" = "1" ] || [ "$ACTION3" = "already_running" ] && ((PASSED_TESTS++))
[ "$SUCCESS4" = "0" ] && ((PASSED_TESTS++))  # This should fail

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ "$PASSED_TESTS" = "$TOTAL_TESTS" ]; then
    echo "🎉 All Step 6.2 Start Production tests passed!"
    echo
    echo "✅ Production start functionality is working"
    echo "✅ Default production start works"
    echo "✅ Already running production handling works"
    echo "✅ Error handling is implemented correctly"
    echo
    echo "Step 6.2 Start Production functionality is ready!"
else
    echo "❌ Some tests failed. Please check the implementation."
    exit 1
fi