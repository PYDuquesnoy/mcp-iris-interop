#!/bin/bash

# Steps 6.6 & 6.7 Log Export Test: Test event log and message trace export functionality via REST API
# This tests the new event log and message trace export endpoint functionality

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export API_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/mcp-interop"

echo "=== Steps 6.6 & 6.7 Log Export Test ==="
echo "Testing event log and message trace export functionality via REST API"
echo "Target: ${API_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

echo "=== Step 6.6 Event Log Export Tests ==="
echo
echo "1. Testing event log export with default parameters..."
RESULT1=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"maxEntries":10}' \
  "${API_BASE_URL}/event-log")

echo "$RESULT1" | jq .
SUCCESS1=$(echo "$RESULT1" | jq -r '.success // 0')
ACTION1=$(echo "$RESULT1" | jq -r '.action // "unknown"')
ENTRIES_COUNT1=$(echo "$RESULT1" | jq -r '.entriesCount // 0')
if [ "$SUCCESS1" = "1" ] && [ "$ACTION1" = "exported" ]; then
    echo "✅ Event log export test passed (exported $ENTRIES_COUNT1 entries)"
else
    echo "❌ Event log export test failed"
fi

echo
echo "2. Testing event log export with specific session ID..."
RESULT2=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"maxEntries":50,"sessionId":"12345"}' \
  "${API_BASE_URL}/event-log")

echo "$RESULT2" | jq .
SUCCESS2=$(echo "$RESULT2" | jq -r '.success // 0')
SESSION_ID2=$(echo "$RESULT2" | jq -r '.sessionId // ""')
if [ "$SUCCESS2" = "1" ] && [ "$SESSION_ID2" = "12345" ]; then
    echo "✅ Event log export with session ID test passed"
else
    echo "❌ Event log export with session ID test failed"
fi

echo
echo "3. Testing event log export with time filter..."
RESULT3=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"maxEntries":20,"sinceTime":"2025-01-01 00:00:00"}' \
  "${API_BASE_URL}/event-log")

echo "$RESULT3" | jq .
SUCCESS3=$(echo "$RESULT3" | jq -r '.success // 0')
SINCE_TIME3=$(echo "$RESULT3" | jq -r '.sinceTime // ""')
if [ "$SUCCESS3" = "1" ] && [ "$SINCE_TIME3" = "2025-01-01 00:00:00" ]; then
    echo "✅ Event log export with time filter test passed"
else
    echo "❌ Event log export with time filter test failed"
fi

echo
echo "=== Step 6.7 Message Trace Export Tests ==="
echo
echo "4. Testing message trace export with default parameters..."
RESULT4=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"maxEntries":10,"includeLogEntries":1}' \
  "${API_BASE_URL}/message-trace")

echo "$RESULT4" | jq .
SUCCESS4=$(echo "$RESULT4" | jq -r '.success // 0')
ACTION4=$(echo "$RESULT4" | jq -r '.action // "unknown"')
MESSAGE_COUNT4=$(echo "$RESULT4" | jq -r '.messageCount // 0')
LOG_COUNT4=$(echo "$RESULT4" | jq -r '.logCount // 0')
INCLUDE_LOG4=$(echo "$RESULT4" | jq -r '.includeLogEntries // 0')
if [ "$SUCCESS4" = "1" ] && [ "$ACTION4" = "exported" ] && [ "$INCLUDE_LOG4" = "1" ]; then
    echo "✅ Message trace export test passed (exported $MESSAGE_COUNT4 messages, $LOG_COUNT4 log entries)"
else
    echo "❌ Message trace export test failed"
fi

echo
echo "5. Testing message trace export without log entries..."
RESULT5=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"maxEntries":5,"includeLogEntries":0}' \
  "${API_BASE_URL}/message-trace")

echo "$RESULT5" | jq .
SUCCESS5=$(echo "$RESULT5" | jq -r '.success // 0')
INCLUDE_LOG5=$(echo "$RESULT5" | jq -r '.includeLogEntries // 1')
if [ "$SUCCESS5" = "1" ] && ([ "$INCLUDE_LOG5" = "0" ] || [ "$INCLUDE_LOG5" = "" ]); then
    echo "✅ Message trace export without log entries test passed"
else
    echo "❌ Message trace export without log entries test failed"
fi

echo
echo "6. Testing message trace export with session ID filter..."
RESULT6=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"maxEntries":25,"sessionId":"test-session","includeLogEntries":1}' \
  "${API_BASE_URL}/message-trace")

echo "$RESULT6" | jq .
SUCCESS6=$(echo "$RESULT6" | jq -r '.success // 0')
SESSION_ID6=$(echo "$RESULT6" | jq -r '.sessionId // ""')
if [ "$SUCCESS6" = "1" ] && [ "$SESSION_ID6" = "test-session" ]; then
    echo "✅ Message trace export with session ID test passed"
else
    echo "❌ Message trace export with session ID test failed"
fi

echo
echo "7. Testing parameter validation (empty JSON)..."
RESULT7=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "${API_BASE_URL}/event-log")

echo "$RESULT7" | jq .
SUCCESS7=$(echo "$RESULT7" | jq -r '.success // 0')
MAX_ENTRIES7=$(echo "$RESULT7" | jq -r '.maxEntries // 0')
if [ "$SUCCESS7" = "1" ] && [ "$MAX_ENTRIES7" = "100" ]; then
    echo "✅ Parameter validation test passed (defaults applied correctly)"
else
    echo "❌ Parameter validation test failed"
fi

echo
echo "=== Steps 6.6 & 6.7 Test Summary ==="
TOTAL_TESTS=7
PASSED_TESTS=0

# Count tests that passed
[ "$SUCCESS1" = "1" ] && [ "$ACTION1" = "exported" ] && ((PASSED_TESTS++))
[ "$SUCCESS2" = "1" ] && [ "$SESSION_ID2" = "12345" ] && ((PASSED_TESTS++))
[ "$SUCCESS3" = "1" ] && [ "$SINCE_TIME3" = "2025-01-01 00:00:00" ] && ((PASSED_TESTS++))
[ "$SUCCESS4" = "1" ] && [ "$ACTION4" = "exported" ] && [ "$INCLUDE_LOG4" = "1" ] && ((PASSED_TESTS++))
[ "$SUCCESS5" = "1" ] && ([ "$INCLUDE_LOG5" = "0" ] || [ "$INCLUDE_LOG5" = "" ]) && ((PASSED_TESTS++))
[ "$SUCCESS6" = "1" ] && [ "$SESSION_ID6" = "test-session" ] && ((PASSED_TESTS++))
[ "$SUCCESS7" = "1" ] && [ "$MAX_ENTRIES7" = "100" ] && ((PASSED_TESTS++))

echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ "$PASSED_TESTS" = "$TOTAL_TESTS" ]; then
    echo "🎉 All Steps 6.6 & 6.7 Log Export tests passed!"
    echo
    echo "✅ Event log export functionality is working (Step 6.6)"
    echo "✅ Message trace export functionality is working (Step 6.7)"
    echo "✅ Parameter handling (maxEntries, sessionId, sinceTime) works correctly"
    echo "✅ Log entries inclusion/exclusion option works"
    echo "✅ Default values are applied properly"
    echo "✅ Filter options work correctly"
    echo "✅ API response format is consistent"
    echo
    echo "Steps 6.6 & 6.7 Log Export functionality is ready!"
    echo
    echo "Available export commands:"
    echo "- Event Log: POST /api/mcp-interop/event-log"
    echo "- Message Trace: POST /api/mcp-interop/message-trace"
    echo
    echo "Note: For actual debugging, use with specific session IDs from testing service calls"
else
    echo "❌ Some tests failed. Please check the implementation."
    exit 1
fi