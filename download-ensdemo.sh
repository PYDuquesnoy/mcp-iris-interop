#!/bin/bash

# Download all classes from ENSDEMO namespace to legacy/cacheensdemo directory

# Set environment variables
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="ENSDEMO"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Downloading All Classes from ENSDEMO Namespace ==="
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

# Extract class names from the response
CLASS_COUNT=$(echo "${ALL_CLASSES}" | jq -r '.result.content | length // 0')
echo "Found ${CLASS_COUNT} classes in ENSDEMO namespace"

if [ "${CLASS_COUNT}" -eq 0 ]; then
    echo "⚠️  No classes found or error occurred"
    echo "Response: ${ALL_CLASSES}"
    exit 1
fi

echo
echo "2. Downloading classes using TypeScript client (handles URL encoding)..."

# Counter for progress
downloaded=0
errors=0

# Download each class using TypeScript client
echo "${ALL_CLASSES}" | jq -r '.result.content[].name' | while read -r className; do
    if [ -n "${className}" ]; then
        ((downloaded++))
        
        # Show progress every 100 classes
        if [ $((downloaded % 100)) -eq 0 ]; then
            echo "Progress: ${downloaded}/${CLASS_COUNT} classes downloaded..."
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
echo "Total classes processed: ${CLASS_COUNT}"
echo "Successful downloads: $((CLASS_COUNT - errors))"
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
    
    # Show breakdown of % vs non-% classes
    PERCENT_COUNT=$(ls -1 ../legacy/cacheensdemo/%*.cls 2>/dev/null | wc -l)
    NON_PERCENT_COUNT=$(ls -1 ../legacy/cacheensdemo/ 2>/dev/null | grep -v '^%' | wc -l)
    echo "% classes: ${PERCENT_COUNT}"
    echo "Non-% classes: ${NON_PERCENT_COUNT}"
else
    echo "❌ No files were downloaded"
    exit 1
fi

echo
echo "=== ENSDEMO Namespace Download Complete ==="