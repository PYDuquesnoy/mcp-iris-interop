#!/bin/bash

# Full Production Lifecycle Test for Steps 6.4-6.7
# This demonstrates stop, load, start, update, test, and log export functionality

export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export API_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/mcp-interop"

echo "=== Full Production Lifecycle Test ==="
echo "Testing complete production management workflow"
echo "Target: ${API_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

# Function to wait for user confirmation
wait_for_user() {
    echo "Press Enter to continue to next step..."
    read
}

echo "=== STEP 1: Stop any running production ==="
echo "Stopping current production..."
RESULT1=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":30,"force":0}' \
  "${API_BASE_URL}/stop")

echo "$RESULT1" | jq .
SUCCESS1=$(echo "$RESULT1" | jq -r '.success // 0')
ACTION1=$(echo "$RESULT1" | jq -r '.action // "unknown"')
echo "Stop result: Success=$SUCCESS1, Action=$ACTION1"
echo
wait_for_user

echo "=== STEP 2: Load Testing Production Class ==="
echo "Uploading Testing.Production.cls..."
# First, let's upload the Testing Production class
UPLOAD_RESULT=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{
    "enc": false,
    "content": [
      "/// Testing Production for Step 6.5 with FileWriterOperation",
      "/// This production includes a Business Operation that writes to files for testing",
      "Class Testing.Production Extends Ens.Production",
      "{",
      "",
      "XData ProductionDefinition",
      "{",
      "<Production Name=\"Testing.Production\" TestingEnabled=\"true\" LogGeneralTraceEvents=\"false\">",
      "  <Description>Testing Production for File Output Testing</Description>",
      "  <ActorPoolSize>2</ActorPoolSize>",
      "  <Item Name=\"Testing.FileWriterOperation\" Category=\"\" ClassName=\"EnsLib.File.OutboundAdapter\" PoolSize=\"1\" Enabled=\"true\" Foreground=\"false\" Comment=\"File writer for testing\" LogTraceEvents=\"false\" Schedule=\"\">",
      "    <Setting Target=\"Adapter\" Name=\"FilePath\">/home/irisowner/dev/shared/out/</Setting>",
      "    <Setting Target=\"Adapter\" Name=\"Filename\">test-output-%f.txt</Setting>",
      "  </Item>",
      "</Production>",
      "}",
      "",
      "}"
    ]
  }' \
  "http://${IRIS_HOST}:${IRIS_PORT}/api/atelier/v1/${IRIS_NS}/doc/Testing.Production.cls")

echo "$UPLOAD_RESULT" | jq .
echo
wait_for_user

echo "=== STEP 3: Start the Testing Production ==="
echo "Starting Testing.Production..."
RESULT3=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"productionName":"Testing.Production","timeout":60}' \
  "${API_BASE_URL}/start")

echo "$RESULT3" | jq .
SUCCESS3=$(echo "$RESULT3" | jq -r '.success // 0')
PRODUCTION3=$(echo "$RESULT3" | jq -r '.productionName // "unknown"')
echo "Start result: Success=$SUCCESS3, Production=$PRODUCTION3"
echo
wait_for_user

echo "=== STEP 4: Update the Production ==="
echo "Updating production configuration..."
RESULT4=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":20,"force":0}' \
  "${API_BASE_URL}/update")

echo "$RESULT4" | jq .
SUCCESS4=$(echo "$RESULT4" | jq -r '.success // 0')
ACTION4=$(echo "$RESULT4" | jq -r '.action // "unknown"')
echo "Update result: Success=$SUCCESS4, Action=$ACTION4"
echo
wait_for_user

echo "=== STEP 5: Stop the Production ==="
echo "Stopping the production..."
RESULT5=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"timeout":30,"force":0}' \
  "${API_BASE_URL}/stop")

echo "$RESULT5" | jq .
SUCCESS5=$(echo "$RESULT5" | jq -r '.success // 0')
ACTION5=$(echo "$RESULT5" | jq -r '.action // "unknown"')
echo "Stop result: Success=$SUCCESS5, Action=$ACTION5"
echo
wait_for_user

echo "=== STEP 6: Restart the Production ==="
echo "Restarting Testing.Production..."
RESULT6=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"productionName":"Testing.Production","timeout":60}' \
  "${API_BASE_URL}/start")

echo "$RESULT6" | jq .
SUCCESS6=$(echo "$RESULT6" | jq -r '.success // 0')
PRODUCTION6=$(echo "$RESULT6" | jq -r '.productionName // "unknown"')
echo "Restart result: Success=$SUCCESS6, Production=$PRODUCTION6"
echo
wait_for_user

echo "=== STEP 7: Test the Production with Testing Service ==="
echo "Testing Business Operation with file output..."
RESULT7=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d '{"target":"Testing.FileWriterOperation","requestClass":"Ens.StringRequest","requestData":"Hello from Production Lifecycle Test - $(date)","syncCall":1}' \
  "${API_BASE_URL}/test-service")

echo "$RESULT7" | jq .
SUCCESS7=$(echo "$RESULT7" | jq -r '.success // 0')
TARGET7=$(echo "$RESULT7" | jq -r '.target // "unknown"')
SESSION_ID7=$(echo "$RESULT7" | jq -r '.sessionId // ""')
echo "Test result: Success=$SUCCESS7, Target=$TARGET7, SessionId=$SESSION_ID7"
echo
wait_for_user

echo "=== STEP 8: Export Event Log ==="
echo "Exporting event log for session $SESSION_ID7..."
RESULT8=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d "{\"maxEntries\":50,\"sessionId\":\"$SESSION_ID7\"}" \
  "${API_BASE_URL}/event-log")

echo "$RESULT8" | jq .
SUCCESS8=$(echo "$RESULT8" | jq -r '.success // 0')
ENTRIES_COUNT8=$(echo "$RESULT8" | jq -r '.entriesCount // 0')
echo "Event log export result: Success=$SUCCESS8, EntriesCount=$ENTRIES_COUNT8"
echo
wait_for_user

echo "=== STEP 9: Export Message Trace ==="
echo "Exporting message trace for session $SESSION_ID7..."
RESULT9=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -H "Content-Type: application/json" \
  -d "{\"maxEntries\":25,\"sessionId\":\"$SESSION_ID7\",\"includeLogEntries\":1}" \
  "${API_BASE_URL}/message-trace")

echo "$RESULT9" | jq .
SUCCESS9=$(echo "$RESULT9" | jq -r '.success // 0')
MESSAGE_COUNT9=$(echo "$RESULT9" | jq -r '.messageCount // 0')
LOG_COUNT9=$(echo "$RESULT9" | jq -r '.logCount // 0')
echo "Message trace export result: Success=$SUCCESS9, MessageCount=$MESSAGE_COUNT9, LogCount=$LOG_COUNT9"
echo

echo "=== STEP 10: Check shared output directory ==="
echo "Checking for test output files..."
if [ -d "/mnt/c/dev/2025/mcp3/intersystems-iris-dev-template/shared/out" ]; then
    echo "Files in shared/out directory:"
    ls -la "/mnt/c/dev/2025/mcp3/intersystems-iris-dev-template/shared/out/" | head -10
else
    echo "Shared output directory not found at expected location"
fi
echo

echo "=== PRODUCTION LIFECYCLE TEST SUMMARY ==="
TOTAL_TESTS=9
PASSED_TESTS=0

# Count successful tests
[ "$SUCCESS1" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 1: Stop production"
[ "$SUCCESS3" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 3: Start production"
[ "$SUCCESS4" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 4: Update production"
[ "$SUCCESS5" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 5: Stop production"
[ "$SUCCESS6" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 6: Restart production"
[ "$SUCCESS7" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 7: Test service"
[ "$SUCCESS8" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 8: Export event log"
[ "$SUCCESS9" = "1" ] && ((PASSED_TESTS++)) && echo "✅ Step 9: Export message trace"

echo
echo "Tests passed: $PASSED_TESTS/$TOTAL_TESTS"

if [ "$PASSED_TESTS" = "$TOTAL_TESTS" ]; then
    echo "🎉 All production lifecycle tests passed!"
    echo
    echo "✅ Production stop/start/update cycle working"
    echo "✅ Testing service functional"
    echo "✅ Event log export working"
    echo "✅ Message trace export working"
    echo "✅ File output validation available"
else
    echo "❌ Some tests failed. Please check the implementation."
    exit 1
fi