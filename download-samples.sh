#!/bin/bash

# Download all classes from SAMPLES namespace to legacy/cachesamples directory

# Set environment variables
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="SAMPLES"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Downloading All Classes from SAMPLES Namespace ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo "Output Directory: legacy/cachesamples/"
echo

# Create output directory
mkdir -p legacy/cachesamples

# Get list of all classes in SAMPLES namespace
echo "1. Getting list of all classes in SAMPLES namespace..."
ALL_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS")

# Check if request was successful
if [ $? -ne 0 ]; then
    echo "❌ Failed to get class list from SAMPLES namespace"
    exit 1
fi

# Extract class names from the response
CLASS_COUNT=$(echo "${ALL_CLASSES}" | jq -r '.result.content | length // 0')
echo "Found ${CLASS_COUNT} classes in SAMPLES namespace"

if [ "${CLASS_COUNT}" -eq 0 ]; then
    echo "⚠️  No classes found or error occurred"
    echo "Response: ${ALL_CLASSES}"
    exit 1
fi

echo
echo "2. Downloading classes (this may take a while)..."

# Counter for progress
downloaded=0
errors=0

# Download each class
echo "${ALL_CLASSES}" | jq -r '.result.content[].name' | while read -r className; do
    if [ -n "${className}" ]; then
        ((downloaded++))
        
        # Show progress every 50 classes
        if [ $((downloaded % 50)) -eq 0 ]; then
            echo "Progress: ${downloaded}/${CLASS_COUNT} classes downloaded..."
        fi
        
        # Download the class
        DOWNLOAD_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
          "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${className}" 2>/dev/null)
        
        if [ $? -eq 0 ] && echo "${DOWNLOAD_RESULT}" | jq -e '.result.content' > /dev/null 2>&1; then
            # Save class content to file
            echo "${DOWNLOAD_RESULT}" | jq -r '.result.content[]?' > "legacy/cachesamples/${className}"
            
            if [ -s "legacy/cachesamples/${className}" ]; then
                # File has content - success
                :
            else
                echo "⚠️  Warning: Downloaded empty file for ${className}"
                ((errors++))
            fi
        else
            echo "❌ Failed to download: ${className}"
            ((errors++))
        fi
    fi
done

echo
echo "3. Download Summary:"
echo "Total classes processed: ${CLASS_COUNT}"
echo "Successful downloads: $((CLASS_COUNT - errors))"
echo "Errors: ${errors}"

# List downloaded files
DOWNLOADED_FILES=$(ls -1 legacy/cachesamples/ 2>/dev/null | wc -l)
echo "Files in legacy/cachesamples/: ${DOWNLOADED_FILES}"

if [ "${DOWNLOADED_FILES}" -gt 0 ]; then
    echo "✅ Download completed successfully"
    echo "Sample files:"
    ls -la legacy/cachesamples/ | head -10
else
    echo "❌ No files were downloaded"
    exit 1
fi

echo
echo "=== SAMPLES Namespace Download Complete ==="