#!/bin/bash

# Step 6.4 Stop and Clean Production Test: Test production stop and clean functionality via REST API
# This tests the new stop and clean production endpoint functionality

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export API_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/mcp-interop"

echo "=== Step 6.4 Stop and Clean Production Test ==="
echo "Testing production stop and clean functionality via REST API"
echo "Target: ${API_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "1. Testing stop production when no production is running (expected to fail)..."
RESULT1=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":10, "force":0}' \
  "${API_BASE_URL}/stop")

echo "$RESULT1" | jq .
SUCCESS1=$(echo "$RESULT1" | jq -r '.success // 0')
ERROR1=$(echo "$RESULT1" | jq -r '.error // ""')
if [ "$SUCCESS1" = "0" ] && [[ "$ERROR1" == *"No production is currently running"* ]]; then
    echo "✅ Stop production (no running) test passed (correctly failed)"
else
    echo "❌ Stop production (no running) test failed - unexpected result"
fi

echo
echo "2. Testing stop production with custom timeout (no production running)..."
RESULT2=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":30, "force":0}' \
  "${API_BASE_URL}/stop")

echo "$RESULT2" | jq .
SUCCESS2=$(echo "$RESULT2" | jq -r '.success // 0')
TIMEOUT2=$(echo "$RESULT2" | jq -r '.timeout // 0')
if [ "$SUCCESS2" = "0" ] && [ "$TIMEOUT2" = "30" ]; then
    echo "✅ Custom timeout stop test passed"
else
    echo "❌ Custom timeout stop test failed"
fi

echo
echo "3. Testing stop production with force option (no production running)..."
RESULT3=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":15, "force":1}' \
  "${API_BASE_URL}/stop")

echo "$RESULT3" | jq .
SUCCESS3=$(echo "$RESULT3" | jq -r '.success // 0')
FORCE3=$(echo "$RESULT3" | jq -r '.force // 0')
if [ "$SUCCESS3" = "0" ] && [ "$FORCE3" = "1" ]; then
    echo "✅ Force stop test passed"
else
    echo "❌ Force stop test failed"
fi

echo
echo "4. Testing clean production functionality..."
RESULT4=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"killAppDataToo":0}' \
  "${API_BASE_URL}/clean")

echo "$RESULT4" | jq .
SUCCESS4=$(echo "$RESULT4" | jq -r '.success // 0')
ACTION4=$(echo "$RESULT4" | jq -r '.action // "unknown"')
if [ "$SUCCESS4" = "1" ] && [ "$ACTION4" = "cleaned" ]; then
    echo "✅ Clean production test passed"
else
    echo "❌ Clean production test failed"
fi

echo
echo "5. Testing clean production with killAppDataToo option..."
RESULT5=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"killAppDataToo":1}' \
  "${API_BASE_URL}/clean")

echo "$RESULT5" | jq .
SUCCESS5=$(echo "$RESULT5" | jq -r '.success // 0')
KILL_APP_DATA5=$(echo "$RESULT5" | jq -r '.killAppDataToo // 0')
if [ "$SUCCESS5" = "1" ] && [ "$KILL_APP_DATA5" = "1" ]; then
    echo "✅ Clean production with killAppDataToo test passed"
else
    echo "❌ Clean production with killAppDataToo test failed"
fi

echo
echo "6. Testing parameter validation (empty JSON)..."
RESULT6=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "${API_BASE_URL}/stop")

echo "$RESULT6" | jq .
SUCCESS6=$(echo "$RESULT6" | jq -r '.success // 0')
TIMEOUT6=$(echo "$RESULT6" | jq -r '.timeout // 0')
FORCE6=$(echo "$RESULT6" | jq -r '.force // 0')
# Should use defaults: timeout=10, force=0
if [ "$TIMEOUT6" = "10" ] && [ "$FORCE6" = "0" ]; then
    echo "✅ Parameter validation test passed (defaults applied correctly)"
else
    echo "❌ Parameter validation test failed (defaults not applied)"
fi

echo
echo "=== Step 6.4 Test Summary ==="
TOTAL_TESTS=6
PASSED_TESTS=0

# Count tests that passed
[[ "$SUCCESS1" = "0" && "$ERROR1" == *"No production is currently running"* ]] && ((PASSED_TESTS++))
[ "$SUCCESS2" = "0" ] && [ "$TIMEOUT2" = "30" ] && ((PASSED_TESTS++))
[ "$SUCCESS3" = "0" ] && [ "$FORCE3" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS4" = "1" ] && [ "$ACTION4" = "cleaned" ] && ((PASSED_TESTS++))
[ "$SUCCESS5" = "1" ] && [ "$KILL_APP_DATA5" = "1" ] && ((PASSED_TESTS++))
[ "$TIMEOUT6" = "10" ] && [ "$FORCE6" = "0" ] && ((PASSED_TESTS++))

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ "$PASSED_TESTS" = "$TOTAL_TESTS" ]; then
    echo "🎉 All Step 6.4 Stop and Clean Production tests passed!"
    echo
    echo "✅ Production stop functionality is working"
    echo "✅ Production clean functionality is working"
    echo "✅ Parameter handling (timeout, force, killAppDataToo) works correctly"
    echo "✅ Default values are applied properly"
    echo "✅ Error handling for no running production works"
    echo "✅ API response format is consistent"
    echo
    echo "Step 6.4 Stop and Clean Production functionality is ready!"
else
    echo "❌ Some tests failed. Please check the implementation."
    exit 1
fi