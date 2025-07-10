#!/bin/bash

# Download Ens, EnsLib, and EnsPortal classes from IRISAPP namespace
# These classes are accessible in IRISAPP where we have our production code

# Set environment variables
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="IRISAPP"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== Downloading Ens/EnsLib/EnsPortal Classes from IRISAPP Namespace ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo "Output Directory: legacy/ensLib/"
echo

# Create output directory
mkdir -p legacy/ensLib

# Get list of all classes in IRISAPP and filter for Ens/EnsLib/EnsPortal
echo "1. Getting list of Ens, EnsLib, and EnsPortal classes from IRISAPP namespace..."
RESPONSE=$(curl -s --user "${IRIS_USER}:${IRIS_PASS}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/docnames/*/CLS")

# Check if request was successful
if [ $? -ne 0 ]; then
    echo "❌ Failed to get class list from IRISAPP namespace"
    exit 1
fi

# Extract Ens/EnsLib/EnsPortal class names
ENS_CLASSES=$(echo "${RESPONSE}" | jq -r '.result.content[] | select(.name | test("^(Ens|EnsLib|EnsPortal)\\.")) | .name' 2>/dev/null || echo "")

# Count classes
CLASS_COUNT=$(echo "${ENS_CLASSES}" | grep -c "." || echo "0")
echo "Found ${CLASS_COUNT} Ens/EnsLib/EnsPortal classes"

# Count by prefix
ENS_COUNT=$(echo "${ENS_CLASSES}" | grep -c "^Ens\\." || echo "0")
ENSLIB_COUNT=$(echo "${ENS_CLASSES}" | grep -c "^EnsLib\\." || echo "0")
ENSPORTAL_COUNT=$(echo "${ENS_CLASSES}" | grep -c "^EnsPortal\\." || echo "0")
echo "  - Ens.* classes: ${ENS_COUNT}"
echo "  - EnsLib.* classes: ${ENSLIB_COUNT}"
echo "  - EnsPortal.* classes: ${ENSPORTAL_COUNT}"

if [ "${CLASS_COUNT}" -eq 0 ]; then
    echo "⚠️  No Ens/EnsLib/EnsPortal classes found"
    echo "Debug: Checking response..."
    echo "${RESPONSE}" | jq '.result.content[0:5]'
    exit 1
fi

echo
echo "2. Sample classes to download:"
echo "${ENS_CLASSES}" | head -10
if [ "${CLASS_COUNT}" -gt 10 ]; then
    echo "... and $((CLASS_COUNT - 10)) more"
fi

echo
echo "3. Downloading classes..."

# Counter for progress
downloaded=0
errors=0

# Key classes for Step 6.5
KEY_CLASSES=(
    "EnsLib.Testing.Service"
    "EnsLib.Testing.Request"
    "EnsPortal.TestingService"
)

# Download each class
echo "${ENS_CLASSES}" | while read -r className; do
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
            CLASS_CONTENT=$(echo "${DOWNLOAD_RESULT}" | jq -r '.result.content[]?' | tr -d '\r')
            
            if [ -n "${CLASS_CONTENT}" ]; then
                echo "${CLASS_CONTENT}" > "legacy/ensLib/${className}"
                
                # Show detailed progress for first few and key classes
                if [ ${downloaded} -le 5 ]; then
                    echo "  ✅ Downloaded: ${className}"
                fi
                
                # Check if this is a key class
                for keyClass in "${KEY_CLASSES[@]}"; do
                    if [ "${className}" = "${keyClass}" ]; then
                        echo "  ✅ Downloaded KEY class: ${className}"
                    fi
                done
            else
                echo "  ⚠️  Warning: Empty content for ${className}"
                ((errors++))
            fi
        else
            # Check if this is a key class that failed
            for keyClass in "${KEY_CLASSES[@]}"; do
                if [ "${className}" = "${keyClass}" ]; then
                    echo "  ❌ Failed to download KEY class: ${className}"
                fi
            done
            ((errors++))
        fi
    fi
done

echo
echo "4. Download Summary:"
echo "Total Ens/EnsLib/EnsPortal classes: ${CLASS_COUNT}"
echo "Successfully downloaded: $((downloaded - errors))"
echo "Errors: ${errors}"

# List downloaded files
DOWNLOADED_FILES=$(find legacy/ensLib/ -name "*.cls" 2>/dev/null | wc -l)
echo "Files in legacy/ensLib/: ${DOWNLOADED_FILES}"

if [ "${DOWNLOADED_FILES}" -gt 0 ]; then
    echo "✅ Download completed"
    echo
    echo "Sample downloaded files:"
    find legacy/ensLib/ -name "*.cls" | sort | head -15
    
    # Show total size
    TOTAL_SIZE=$(du -sh legacy/ensLib/ 2>/dev/null | cut -f1)
    echo
    echo "Total size: ${TOTAL_SIZE}"
    
    # Show breakdown by package
    echo
    echo "Breakdown by package:"
    echo "Ens.* classes: $(find legacy/ensLib/ -name "Ens.*.cls" | wc -l)"
    echo "EnsLib.* classes: $(find legacy/ensLib/ -name "EnsLib.*.cls" | wc -l)"
    echo "EnsPortal.* classes: $(find legacy/ensLib/ -name "EnsPortal.*.cls" | wc -l)"
    
    # Check for critical Step 6.5 classes
    echo
    echo "Critical classes for Step 6.5:"
    for class in "EnsLib.Testing.Service.cls" "EnsLib.Testing.Request.cls" "EnsPortal.TestingService.cls"; do
        if [ -f "legacy/ensLib/${class}" ]; then
            fileSize=$(stat -c%s "legacy/ensLib/${class}" 2>/dev/null || stat -f%z "legacy/ensLib/${class}" 2>/dev/null || echo "0")
            echo "  ✅ ${class} (${fileSize} bytes)"
        else
            echo "  ❌ ${class} (missing)"
        fi
    done
else
    echo "❌ No files were downloaded"
    exit 1
fi

echo
echo "=== Ens/EnsLib/EnsPortal Classes Download Complete ==="