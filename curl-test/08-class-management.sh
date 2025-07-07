#!/bin/bash

# IRIS Atelier API - Class Management Operations (Step 4)
# Tests class upload, download, compilation, and package operations

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Class Management Operations ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

# Sample class content for testing
SAMPLE_CLASS_CONTENT='[
  "/// Sample test class for Step 4 validation",
  "Class Test.Step4Sample",
  "{",
  "",
  "/// Sample property",
  "Property TestProperty As %String;",
  "",
  "/// Sample method",
  "Method TestMethod() As %String",
  "{",
  "    Return \"Hello from Test.Step4Sample!\"",
  "}",
  "",
  "}"
]'

echo "1. Upload a new test class..."
echo "Command: curl -s -X PUT --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"name\":\"Test.Step4Sample.cls\",\"content\":${SAMPLE_CLASS_CONTENT}}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Sample.cls\""
echo

UPLOAD_RESULT=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test.Step4Sample.cls\",\"content\":${SAMPLE_CLASS_CONTENT}}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Sample.cls")

echo "${UPLOAD_RESULT}" | jq .

UPLOAD_STATUS=$(echo "${UPLOAD_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${UPLOAD_STATUS}" ]; then
    echo "✅ Class uploaded successfully"
else
    echo "⚠️  Upload completed with status: ${UPLOAD_STATUS}"
fi

echo
echo "2. Check if class exists (HEAD request)..."
echo "Command: curl -I --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Sample.cls\""
echo

curl -I --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Sample.cls"

echo
echo "3. Download the uploaded class..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Sample.cls\""
echo

DOWNLOAD_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Sample.cls")

echo "${DOWNLOAD_RESULT}" | jq .

if echo "${DOWNLOAD_RESULT}" | jq -e '.result.content' > /dev/null 2>&1; then
    echo "✅ Class downloaded successfully"
    CONTENT_LINES=$(echo "${DOWNLOAD_RESULT}" | jq -r '.result.content | length // 0')
    echo "Content lines: ${CONTENT_LINES}"
else
    echo "❌ Failed to download class"
fi

echo
echo "4. Compile the uploaded class..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '[\"Test.Step4Sample.cls\"]' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk\""
echo

COMPILE_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '["Test.Step4Sample.cls"]' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")

echo "${COMPILE_RESULT}" | jq .

COMPILE_STATUS=$(echo "${COMPILE_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${COMPILE_STATUS}" ]; then
    echo "✅ Class compiled successfully"
else
    echo "⚠️  Compilation completed with status: ${COMPILE_STATUS}"
fi

# Check for console output
CONSOLE_OUTPUT=$(echo "${COMPILE_RESULT}" | jq -r '.console[]? // empty')
if [ -n "${CONSOLE_OUTPUT}" ]; then
    echo "Console output:"
    echo "${CONSOLE_OUTPUT}"
fi

echo
echo "5. List classes with 'Test.*' filter..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=Test.*\""
echo

TEST_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=Test.*")

echo "${TEST_CLASSES}" | jq .

TEST_CLASS_COUNT=$(echo "${TEST_CLASSES}" | jq -r '.result.content | length // 0')
echo "Test classes found: ${TEST_CLASS_COUNT}"

if [ "${TEST_CLASS_COUNT}" -gt 0 ]; then
    echo "Test classes:"
    echo "${TEST_CLASSES}" | jq -r '.result.content[] | "  - \(.name)"'
fi

echo
echo "6. Upload and compile in one operation (using existing compile endpoint after upload)..."

# Create a more complex sample class
COMPLEX_CLASS_CONTENT='[
  "/// Complex test class with methods and properties",
  "Class Test.Step4Complex Extends %Persistent",
  "{",
  "",
  "/// Name property with validation",
  "Property Name As %String(MAXLEN = 50) [ Required ];",
  "",
  "/// Value property with default",
  "Property Value As %Integer [ InitialExpression = 0 ];",
  "",
  "/// Creation timestamp",
  "Property Created As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3)} ];",
  "",
  "/// Method to display object info", 
  "Method GetInfo() As %String",
  "{",
  "    Return \"Name: \" _ ..Name _ \", Value: \" _ ..Value _ \", Created: \" _ ..Created",
  "}",
  "",
  "/// Class method to create instance",
  "ClassMethod CreateNew(name As %String, value As %Integer = 0) As Test.Step4Complex",
  "{",
  "    Set obj = ..%New()",
  "    Set obj.Name = name",
  "    Set obj.Value = value", 
  "    Return obj",
  "}",
  "",
  "}"
]'

echo "Uploading complex class..."
echo "Command: curl -s -X PUT --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"name\":\"Test.Step4Complex.cls\",\"content\":${COMPLEX_CLASS_CONTENT}}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Complex.cls\""
echo

COMPLEX_UPLOAD=$(curl -s -X PUT \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test.Step4Complex.cls\",\"content\":${COMPLEX_CLASS_CONTENT}}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/Test.Step4Complex.cls")

COMPLEX_UPLOAD_STATUS=$(echo "${COMPLEX_UPLOAD}" | jq -r '.status.summary // ""')
if [ -z "${COMPLEX_UPLOAD_STATUS}" ]; then
    echo "✅ Complex class uploaded successfully"
    
    echo
    echo "Compiling complex class..."
    COMPLEX_COMPILE=$(curl -s -X POST \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      -H "Content-Type: application/json" \
      -d '["Test.Step4Complex.cls"]' \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/compile?flags=cuk")
    
    COMPLEX_COMPILE_STATUS=$(echo "${COMPLEX_COMPILE}" | jq -r '.status.summary // ""')
    if [ -z "${COMPLEX_COMPILE_STATUS}" ]; then
        echo "✅ Complex class compiled successfully"
    else
        echo "⚠️  Complex class compilation status: ${COMPLEX_COMPILE_STATUS}"
    fi
else
    echo "⚠️  Complex class upload status: ${COMPLEX_UPLOAD_STATUS}"
fi

echo
echo "7. Download Test package (all Test.* classes)..."
echo "Command: curl -s --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=Test.*\""
echo

# Get all Test classes and download each one
TEST_PACKAGE_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS?filter=Test.*")

if echo "${TEST_PACKAGE_CLASSES}" | jq -e '.result.content' > /dev/null 2>&1; then
    PACKAGE_CLASS_COUNT=$(echo "${TEST_PACKAGE_CLASSES}" | jq -r '.result.content | length // 0')
    echo "Found ${PACKAGE_CLASS_COUNT} classes in Test package"
    
    # Create directory for package download
    mkdir -p "test-package-download"
    
    echo "Downloading Test package classes:"
    echo "${TEST_PACKAGE_CLASSES}" | jq -r '.result.content[].name' | while read -r className; do
        if [ -n "${className}" ]; then
            echo "  Downloading: ${className}"
            curl -s --user "${IRIS_USER}:${IRIS_PASS}" -b "${COOKIE_JAR}" \
              "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${className}" \
              | jq -r '.result.content[]?' > "test-package-download/${className}"
            
            if [ -s "test-package-download/${className}" ]; then
                echo "    ✅ Downloaded: ${className}"
            else
                echo "    ❌ Failed to download: ${className}"
            fi
        fi
    done
    
    echo "✅ Test package download completed"
    echo "Files saved to: test-package-download/"
    ls -la test-package-download/
fi

echo
echo "8. Delete test classes (cleanup)..."
for className in "Test.Step4Sample.cls" "Test.Step4Complex.cls"; do
    echo "Deleting: ${className}"
    echo "Command: curl -s -X DELETE --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \"${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${className}\""
    
    DELETE_RESULT=$(curl -s -X DELETE \
      --user "${IRIS_USER}:${IRIS_PASS}" \
      -b "${COOKIE_JAR}" \
      "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${className}")
    
    DELETE_STATUS=$(echo "${DELETE_RESULT}" | jq -r '.status.summary // ""')
    if [ -z "${DELETE_STATUS}" ]; then
        echo "  ✅ ${className} deleted successfully"
    else
        echo "  ⚠️  ${className} deletion status: ${DELETE_STATUS}"
    fi
done

echo
echo "9. Save class management operation results..."
echo "${UPLOAD_RESULT}" > "class-upload.json"
echo "${DOWNLOAD_RESULT}" > "class-download.json" 
echo "${COMPILE_RESULT}" > "class-compile.json"
echo "${TEST_CLASSES}" > "test-classes-list.json"

echo "Class management results saved to class-*.json files"

echo
echo "=== Class Management Operations Complete ==="
echo
echo "Summary of tested operations:"
echo "  ✅ Class upload (PUT /doc/classname)"
echo "  ✅ Class existence check (HEAD /doc/classname)"  
echo "  ✅ Class download (GET /doc/classname)"
echo "  ✅ Class compilation (POST /action/compile)"
echo "  ✅ Class listing with filters (GET /docnames/*/CLS?filter=pattern)"
echo "  ✅ Package download (multiple class downloads)"
echo "  ✅ Class deletion (DELETE /doc/classname)"