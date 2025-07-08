#!/bin/bash

# Download sample classes (non-% classes) from SAMPLES namespace to legacy/cachesamples directory

# Set environment variables
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="SAMPLES"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Downloading Sample Classes from SAMPLES Namespace (excluding % classes) ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo "Output Directory: legacy/cachesamples/"
echo

# Create output directory
mkdir -p legacy/cachesamples

# Get list of all non-% classes in SAMPLES namespace
echo "1. Getting list of sample classes (excluding % classes)..."
NON_PERCENT_CLASSES=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS" | \
  jq -r '.result.content[] | select(.name | startswith("%") | not) | .name')

# Check if request was successful
if [ $? -ne 0 ]; then
    echo "❌ Failed to get class list from SAMPLES namespace"
    exit 1
fi

# Count classes
CLASS_COUNT=$(echo "${NON_PERCENT_CLASSES}" | wc -l)
echo "Found ${CLASS_COUNT} sample classes (excluding % classes)"

if [ "${CLASS_COUNT}" -eq 0 ]; then
    echo "⚠️  No sample classes found"
    exit 1
fi

echo
echo "2. Sample classes to download:"
echo "${NON_PERCENT_CLASSES}" | head -10
if [ "${CLASS_COUNT}" -gt 10 ]; then
    echo "... and $((CLASS_COUNT - 10)) more"
fi

echo
echo "3. Downloading classes..."

# Counter for progress
downloaded=0
errors=0

# Download each class
echo "${NON_PERCENT_CLASSES}" | while read -r className; do
    if [ -n "${className}" ]; then
        ((downloaded++))
        
        # Show progress every 10 classes
        if [ $((downloaded % 10)) -eq 0 ]; then
            echo "Progress: ${downloaded}/${CLASS_COUNT} classes downloaded..."
        fi
        
        # Download the class
        DOWNLOAD_RESULT=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
          "${IRIS_BASE_URL}/v1/${IRIS_NS}/doc/${className}" 2>/dev/null)
        
        if [ $? -eq 0 ] && echo "${DOWNLOAD_RESULT}" | jq -e '.result.content' > /dev/null 2>&1; then
            # Save class content to file
            echo "${DOWNLOAD_RESULT}" | jq -r '.result.content[]?' > "legacy/cachesamples/${className}"
            
            if [ -s "legacy/cachesamples/${className}" ]; then
                echo "  ✅ Downloaded: ${className}"
            else
                echo "  ⚠️  Warning: Downloaded empty file for ${className}"
                ((errors++))
            fi
        else
            echo "  ❌ Failed to download: ${className}"
            ((errors++))
        fi
    fi
done

echo
echo "4. Download Summary:"
echo "Total sample classes processed: ${CLASS_COUNT}"
echo "Successful downloads: $((CLASS_COUNT - errors))"
echo "Errors: ${errors}"

# List downloaded files
DOWNLOADED_FILES=$(ls -1 legacy/cachesamples/ 2>/dev/null | wc -l)
echo "Files in legacy/cachesamples/: ${DOWNLOADED_FILES}"

if [ "${DOWNLOADED_FILES}" -gt 0 ]; then
    echo "✅ Download completed successfully"
    echo
    echo "Sample downloaded files:"
    ls -la legacy/cachesamples/ | head -15
    
    # Show total size
    TOTAL_SIZE=$(du -sh legacy/cachesamples/ 2>/dev/null | cut -f1)
    echo
    echo "Total size: ${TOTAL_SIZE}"
else
    echo "❌ No files were downloaded"
    exit 1
fi

echo
echo "=== Sample Classes Download Complete ==="