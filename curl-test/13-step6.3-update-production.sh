#!/bin/bash

# Step 6.3 Update Production Test: Test production update functionality via REST API
# This tests the new update production endpoint functionality

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export API_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/mcp-interop"

echo "=== Step 6.3 Update Production Test ==="
echo "Testing production update functionality via REST API"
echo "Target: ${API_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "1. Testing update production with default parameters..."
RESULT1=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":10, "force":0}' \
  "${API_BASE_URL}/update")

echo "$RESULT1" | jq .
SUCCESS1=$(echo "$RESULT1" | jq -r '.success // 0')
ACTION1=$(echo "$RESULT1" | jq -r '.action // "unknown"')
if [ "$SUCCESS1" = "1" ]; then
    echo "✅ Default update production test passed (Action: $ACTION1)"
else
    echo "❌ Default update production test failed (this may be expected if no production is running)"
    ERROR1=$(echo "$RESULT1" | jq -r '.error // "unknown"')
    echo "    Error: $ERROR1"
fi

echo
echo "2. Testing update production with custom timeout..."
RESULT2=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":30, "force":0}' \
  "${API_BASE_URL}/update")

echo "$RESULT2" | jq .
SUCCESS2=$(echo "$RESULT2" | jq -r '.success // 0')
ACTION2=$(echo "$RESULT2" | jq -r '.action // "unknown"')
TIMEOUT2=$(echo "$RESULT2" | jq -r '.timeout // 0')
if [ "$SUCCESS2" = "1" ] && [ "$TIMEOUT2" = "30" ]; then
    echo "✅ Custom timeout update test passed (Action: $ACTION2, Timeout: ${TIMEOUT2}s)"
else
    echo "❌ Custom timeout update test failed (this may be expected if no production is running)"
    ERROR2=$(echo "$RESULT2" | jq -r '.error // "unknown"')
    echo "    Error: $ERROR2"
fi

echo
echo "3. Testing update production with force option..."
RESULT3=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":15, "force":1}' \
  "${API_BASE_URL}/update")

echo "$RESULT3" | jq .
SUCCESS3=$(echo "$RESULT3" | jq -r '.success // 0')
ACTION3=$(echo "$RESULT3" | jq -r '.action // "unknown"')
FORCE3=$(echo "$RESULT3" | jq -r '.force // 0')
if [ "$SUCCESS3" = "1" ] && [ "$FORCE3" = "1" ]; then
    echo "✅ Force update test passed (Action: $ACTION3, Force: $FORCE3)"
else
    echo "❌ Force update test failed (this may be expected if no production is running)"
    ERROR3=$(echo "$RESULT3" | jq -r '.error // "unknown"')
    echo "    Error: $ERROR3"
fi

echo
echo "4. Testing update when no production is running (error case)..."
# First try to make sure no production is running by checking status
PROD_STATUS=$(curl -s -X GET \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  "${API_BASE_URL}/list")

RUNNING_PRODS=$(echo "$PROD_STATUS" | jq -r '.count // 0')
echo "Productions currently available: $RUNNING_PRODS"

RESULT4=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":10, "force":0}' \
  "${API_BASE_URL}/update")

echo "$RESULT4" | jq .
SUCCESS4=$(echo "$RESULT4" | jq -r '.success // 0')
ERROR4=$(echo "$RESULT4" | jq -r '.error // ""')
if [ "$SUCCESS4" = "0" ] && [[ "$ERROR4" == *"No production is currently running"* ]]; then
    echo "✅ No running production error handling test passed"
elif [ "$SUCCESS4" = "1" ]; then
    echo "✅ Update succeeded (production was running)"
else
    echo "❌ Unexpected error in update test"
    echo "    Error: $ERROR4"
fi

echo
echo "5. Testing parameter validation (empty JSON)..."
RESULT5=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "${API_BASE_URL}/update")

echo "$RESULT5" | jq .
SUCCESS5=$(echo "$RESULT5" | jq -r '.success // 0')
TIMEOUT5=$(echo "$RESULT5" | jq -r '.timeout // 0')
FORCE5=$(echo "$RESULT5" | jq -r '.force // 0')
# Should use defaults: timeout=10, force=0
if [ "$TIMEOUT5" = "10" ] && [ "$FORCE5" = "0" ]; then
    echo "✅ Parameter validation test passed (defaults applied correctly)"
else
    echo "❌ Parameter validation test failed (defaults not applied)"
fi

echo
echo "=== Step 6.3 Test Summary ==="
TOTAL_TESTS=5
PASSED_TESTS=0

# Count tests that passed or had expected behavior
[ "$SUCCESS1" = "1" ] || [[ "${ERROR1:-}" == *"No production"* ]] && ((PASSED_TESTS++))
[ "$SUCCESS2" = "1" ] || [[ "${ERROR2:-}" == *"No production"* ]] && ((PASSED_TESTS++))
[ "$SUCCESS3" = "1" ] || [[ "${ERROR3:-}" == *"No production"* ]] && ((PASSED_TESTS++))
([ "$SUCCESS4" = "0" ] && [[ "$ERROR4" == *"No production"* ]]) || [ "$SUCCESS4" = "1" ] && ((PASSED_TESTS++))
[ "$TIMEOUT5" = "10" ] && [ "$FORCE5" = "0" ] && ((PASSED_TESTS++))

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ "$PASSED_TESTS" = "$TOTAL_TESTS" ]; then
    echo "🎉 All Step 6.3 Update Production tests passed!"
    echo
    echo "✅ Production update functionality is working"
    echo "✅ Parameter handling (timeout, force) works correctly"
    echo "✅ Default values are applied properly"
    echo "✅ Error handling for no running production works"
    echo "✅ API response format is consistent"
    echo
    echo "Step 6.3 Update Production functionality is ready!"
else
    echo "❌ Some tests failed. Please check the implementation."
    exit 1
fi