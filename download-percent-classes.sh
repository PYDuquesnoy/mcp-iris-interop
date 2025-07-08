#!/bin/bash

# Download % classes from SAMPLES namespace in the background
# This script uses the TypeScript client which properly handles URL encoding

echo "Starting background download of % classes from SAMPLES namespace..."

# Create output directory for % classes
mkdir -p legacy/cachesamples-system

# Change to client-proto directory
cd /mnt/c/dev/2025/mcp3/client-proto

# Get list of all % classes and download them one by one
echo "Getting list of % classes..."

# Use curl to get the class list, then filter for % classes
PERCENT_CLASSES=$(curl -s --user "_SYSTEM:SYS" \
  "http://localhost:42002/api/atelier/v1/SAMPLES/docnames/*/CLS" | \
  jq -r '.result.content[] | select(.name | startswith("%")) | .name')

CLASS_COUNT=$(echo "${PERCENT_CLASSES}" | wc -l)
echo "Found ${CLASS_COUNT} % classes to download"

# Log file for tracking progress
LOG_FILE="../legacy/download-percent-progress.log"
echo "$(date): Starting download of ${CLASS_COUNT} % classes" > "$LOG_FILE"

downloaded=0
errors=0

# Download each % class
echo "${PERCENT_CLASSES}" | while read -r className; do
    if [ -n "${className}" ]; then
        ((downloaded++))
        
        # Progress every 50 classes
        if [ $((downloaded % 50)) -eq 0 ]; then
            echo "$(date): Progress: ${downloaded}/${CLASS_COUNT} % classes downloaded..." >> "$LOG_FILE"
        fi
        
        # Use the TypeScript client to download (it handles URL encoding)
        if node dist/index.js download "${className}" --namespace SAMPLES --output "../legacy/cachesamples-system/${className}" > /dev/null 2>&1; then
            echo "$(date): ✅ Downloaded: ${className}" >> "$LOG_FILE"
        else
            echo "$(date): ❌ Failed: ${className}" >> "$LOG_FILE"
            ((errors++))
        fi
    fi
done

echo "$(date): Download completed. Total: ${CLASS_COUNT}, Errors: ${errors}" >> "$LOG_FILE"
echo "$(date): % classes download finished!" >> "$LOG_FILE"

# Final summary
FINAL_COUNT=$(ls -1 ../legacy/cachesamples-system/ 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh ../legacy/cachesamples-system/ 2>/dev/null | cut -f1)

echo "$(date): Final summary: ${FINAL_COUNT} files downloaded, total size: ${TOTAL_SIZE}" >> "$LOG_FILE"