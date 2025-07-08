#!/bin/bash

# Download non-percent classes from ENSDEMO namespace to legacy/cacheensdemo directory

# Set environment variables
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="ENSDEMO"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Downloading Non-Percent Classes from ENSDEMO Namespace ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo "Output Directory: legacy/cacheensdemo/"
echo

# Create output directory
mkdir -p legacy/cacheensdemo

# Change to client-proto directory for TypeScript client
cd /mnt/c/dev/2025/mcp3/client-proto

# Get list of all classes in ENSDEMO namespace
echo "1. Getting list of all classes in ENSDEMO namespace..."
ALL_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS")

# Check if request was successful
if [ $? -ne 0 ]; then
    echo "❌ Failed to get class list from ENSDEMO namespace"
    exit 1
fi

# Extract class names from the response and filter out % classes
CLASS_COUNT=$(echo "${ALL_CLASSES}" | jq -r '.result.content | length // 0')
echo "Found ${CLASS_COUNT} total classes in ENSDEMO namespace"

# Filter to get only non-percent classes
NON_PERCENT_CLASSES=$(echo "${ALL_CLASSES}" | jq -r '.result.content[].name' | grep -v '^%')
NON_PERCENT_COUNT=$(echo "${NON_PERCENT_CLASSES}" | wc -l)

echo "Filtered to ${NON_PERCENT_COUNT} non-percent classes"

if [ "${NON_PERCENT_COUNT}" -eq 0 ]; then
    echo "⚠️  No non-percent classes found"
    exit 1
fi

echo
echo "2. Downloading non-percent classes using TypeScript client..."

# Counter for progress
downloaded=0
errors=0
skipped=0

# Download each non-percent class using TypeScript client
echo "${NON_PERCENT_CLASSES}" | while read -r className; do
    if [ -n "${className}" ]; then
        ((downloaded++))
        
        # Show progress every 25 classes
        if [ $((downloaded % 25)) -eq 0 ]; then
            echo "Progress: ${downloaded}/${NON_PERCENT_COUNT} classes downloaded..."
        fi
        
        # Use TypeScript client to download (it properly handles % character URL encoding)
        if node dist/index.js download "${className}" --namespace ENSDEMO --output "../legacy/cacheensdemo/${className}" > /dev/null 2>&1; then
            # Successful download
            :
        else
            echo "❌ Failed to download: ${className}"
            ((errors++))
        fi
    fi
done

echo
echo "3. Download Summary:"
echo "Total non-percent classes: ${NON_PERCENT_COUNT}"
echo "Attempted downloads: ${downloaded}"
echo "Errors: ${errors}"

# List downloaded files
DOWNLOADED_FILES=$(ls -1 ../legacy/cacheensdemo/ 2>/dev/null | wc -l)
echo "Files in legacy/cacheensdemo/: ${DOWNLOADED_FILES}"

if [ "${DOWNLOADED_FILES}" -gt 0 ]; then
    echo "✅ Download completed successfully"
    echo
    echo "Sample downloaded files:"
    ls -la ../legacy/cacheensdemo/ | head -15
    
    # Show total size
    TOTAL_SIZE=$(du -sh ../legacy/cacheensdemo/ 2>/dev/null | cut -f1)
    echo
    echo "Total size: ${TOTAL_SIZE}"
    
    # Verify no % classes were downloaded
    PERCENT_FILES=$(ls -1 ../legacy/cacheensdemo/%*.cls 2>/dev/null | wc -l)
    if [ "${PERCENT_FILES}" -eq 0 ]; then
        echo "✅ Confirmed: No % classes downloaded"
    else
        echo "⚠️  Warning: ${PERCENT_FILES} % classes found (unexpected)"
    fi
else
    echo "❌ No files were downloaded"
    exit 1
fi

echo
echo "=== ENSDEMO Non-Percent Classes Download Complete ==="