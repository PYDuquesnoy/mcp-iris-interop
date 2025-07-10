#!/bin/bash

# Test access to Ens/EnsLib classes via different methods

echo "=== Testing access to Ens/EnsLib classes ==="
echo

# Method 1: Direct SQL query to %Dictionary tables
echo "1. Checking via SQL query to %Dictionary.ClassDefinition..."
curl -s --user "_SYSTEM:SYS" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT Name FROM %Dictionary.ClassDefinition WHERE Name LIKE '"'"'Ens.%'"'"' ORDER BY Name"}' \
  "http://localhost:42002/api/atelier/v1/ENSDEMO/action/query" | jq -r '.result.content[].Name' 2>/dev/null | head -10

echo
echo "2. Checking EnsLib classes..."
curl -s --user "_SYSTEM:SYS" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT Name FROM %Dictionary.ClassDefinition WHERE Name LIKE '"'"'EnsLib.%'"'"' ORDER BY Name"}' \
  "http://localhost:42002/api/atelier/v1/ENSDEMO/action/query" | jq -r '.result.content[].Name' 2>/dev/null | head -10

# Method 2: Check if we can download a specific known Ens class
echo
echo "3. Testing download of specific Ens.Director class..."
RESPONSE=$(curl -s --user "_SYSTEM:SYS" \
  "http://localhost:42002/api/atelier/v1/ENSDEMO/doc/Ens.Director.cls")
  
if echo "$RESPONSE" | jq -e '.result.content' > /dev/null 2>&1; then
    echo "✅ Ens.Director.cls is accessible"
    echo "First 5 lines:"
    echo "$RESPONSE" | jq -r '.result.content[0]' | head -5
else
    echo "❌ Ens.Director.cls is NOT accessible"
    echo "$RESPONSE" | jq '.'
fi

# Method 3: Check ENSLIB namespace directly
echo
echo "4. Checking ENSLIB namespace directly..."
curl -s --user "_SYSTEM:SYS" \
  "http://localhost:42002/api/atelier/v1/ENSLIB/docnames/Ens.*/CLS" | jq '.result.content | length' 2>/dev/null || echo "Error accessing ENSLIB"