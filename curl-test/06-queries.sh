#!/bin/bash

# IRIS Atelier API - Query Operations
# Tests SQL query execution and data retrieval

# Set environment variables if not already set
export IRIS_HOST="${IRIS_HOST:-localhost}"
export IRIS_PORT="${IRIS_PORT:-42002}"
export IRIS_USER="${IRIS_USER:-_SYSTEM}"
export IRIS_PASS="${IRIS_PASS:-SYS}"
export IRIS_NS="${IRIS_NS:-IRISAPP}"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"

echo "=== IRIS Query Operations ==="
echo "Target: ${IRIS_BASE_URL}"
echo "Namespace: ${IRIS_NS}"
echo

COOKIE_JAR="cookies.txt"

echo "1. Simple SELECT query - List class definitions..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT TOP 5 Name FROM %Dictionary.ClassDefinition\",\"parameters\":[]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

QUERY1_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT TOP 5 Name FROM %Dictionary.ClassDefinition","parameters":[]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${QUERY1_RESULT}" | jq .

# Check query status
QUERY1_STATUS=$(echo "${QUERY1_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${QUERY1_STATUS}" ]; then
    echo "✅ Query executed successfully"
    ROW_COUNT=$(echo "${QUERY1_RESULT}" | jq -r '.result.content | length // 0')
    echo "Rows returned: ${ROW_COUNT}"
else
    echo "❌ Query failed: ${QUERY1_STATUS}"
fi

echo
echo "2. Parameterized query - Search classes with pattern..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT TOP 10 Name FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH ?\",\"parameters\":[\"%\"]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

QUERY2_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT TOP 10 Name FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH ?","parameters":["%"]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${QUERY2_RESULT}" | jq .

QUERY2_STATUS=$(echo "${QUERY2_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${QUERY2_STATUS}" ]; then
    echo "✅ Parameterized query executed successfully"
    ROW_COUNT2=$(echo "${QUERY2_RESULT}" | jq -r '.result.content | length // 0')
    echo "Rows returned: ${ROW_COUNT2}"
else
    echo "❌ Parameterized query failed: ${QUERY2_STATUS}"
fi

echo
echo "3. Query system information..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT \\\$SYSTEM.Version.GetNumber() AS Version, \\\$SYSTEM.Util.DatabaseSize() AS DBSize\",\"parameters\":[]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

QUERY3_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT $SYSTEM.Version.GetNumber() AS Version, $SYSTEM.Util.DatabaseSize() AS DBSize","parameters":[]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${QUERY3_RESULT}" | jq .

QUERY3_STATUS=$(echo "${QUERY3_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${QUERY3_STATUS}" ]; then
    echo "✅ System information query executed successfully"
else
    echo "❌ System information query failed: ${QUERY3_STATUS}"
fi

echo
echo "4. Query namespace tables..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT TOP 10 TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?\",\"parameters\":[\"${IRIS_NS}\"]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

QUERY4_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"SELECT TOP 10 TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?\",\"parameters\":[\"${IRIS_NS}\"]}" \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${QUERY4_RESULT}" | jq .

QUERY4_STATUS=$(echo "${QUERY4_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${QUERY4_STATUS}" ]; then
    echo "✅ Namespace tables query executed successfully"
    TABLE_COUNT=$(echo "${QUERY4_RESULT}" | jq -r '.result.content | length // 0')
    echo "Tables found: ${TABLE_COUNT}"
    
    if [ "${TABLE_COUNT}" -gt 0 ]; then
        echo "Sample tables:"
        echo "${QUERY4_RESULT}" | jq -r '.result.content[] | "  - \(.TABLE_NAME)"'
    fi
else
    echo "❌ Namespace tables query failed: ${QUERY4_STATUS}"
fi

echo
echo "5. Query with multiple parameters..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT Name, Super FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH ? AND Super IS NOT NULL ORDER BY Name\",\"parameters\":[\"dc\"]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

QUERY5_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT Name, Super FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH ? AND Super IS NOT NULL ORDER BY Name","parameters":["dc"]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${QUERY5_RESULT}" | jq .

QUERY5_STATUS=$(echo "${QUERY5_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${QUERY5_STATUS}" ]; then
    echo "✅ Multi-parameter query executed successfully"
    ROW_COUNT5=$(echo "${QUERY5_RESULT}" | jq -r '.result.content | length // 0')
    echo "Rows returned: ${ROW_COUNT5}"
else
    echo "❌ Multi-parameter query failed: ${QUERY5_STATUS}"
fi

echo
echo "6. Test invalid SQL (should fail gracefully)..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT INVALID SYNTAX FROM NOWHERE\",\"parameters\":[]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

INVALID_QUERY_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT INVALID SYNTAX FROM NOWHERE","parameters":[]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${INVALID_QUERY_RESULT}" | jq .

INVALID_STATUS=$(echo "${INVALID_QUERY_RESULT}" | jq -r '.status.summary // ""')
if [ -n "${INVALID_STATUS}" ]; then
    echo "✅ Correctly failed with invalid SQL: ${INVALID_STATUS}"
else
    echo "⚠️  Unexpected success with invalid SQL"
fi

echo
echo "7. Query with ObjectScript functions..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT \\\$HOROLOG AS HorologTime, \\\$NOW() AS CurrentTime, \\\$USERNAME AS CurrentUser\",\"parameters\":[]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

QUERY7_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT $HOROLOG AS HorologTime, $NOW() AS CurrentTime, $USERNAME AS CurrentUser","parameters":[]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${QUERY7_RESULT}" | jq .

QUERY7_STATUS=$(echo "${QUERY7_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${QUERY7_STATUS}" ]; then
    echo "✅ ObjectScript functions query executed successfully"
else
    echo "❌ ObjectScript functions query failed: ${QUERY7_STATUS}"
fi

echo
echo "8. Query for sample data (if any persistent classes exist)..."
echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"query\":\"SELECT Name FROM %Dictionary.ClassDefinition WHERE Super LIKE ?||?||?\",\"parameters\":[\"%\",\"Persistent\",\"%\"]}' \\"
echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
echo

PERSISTENT_QUERY_RESULT=$(curl -s -X POST \
  --user "${IRIS_USER}:${IRIS_PASS}" \
  -b "${COOKIE_JAR}" \
  -H "Content-Type: application/json" \
  -d '{"query":"SELECT Name FROM %Dictionary.ClassDefinition WHERE Super LIKE ?||?||?","parameters":["%","Persistent","%"]}' \
  "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")

echo "${PERSISTENT_QUERY_RESULT}" | jq .

PERSISTENT_STATUS=$(echo "${PERSISTENT_QUERY_RESULT}" | jq -r '.status.summary // ""')
if [ -z "${PERSISTENT_STATUS}" ]; then
    echo "✅ Persistent classes query executed successfully"
    PERSISTENT_COUNT=$(echo "${PERSISTENT_QUERY_RESULT}" | jq -r '.result.content | length // 0')
    echo "Persistent classes found: ${PERSISTENT_COUNT}"
    
    if [ "${PERSISTENT_COUNT}" -gt 0 ]; then
        SAMPLE_PERSISTENT=$(echo "${PERSISTENT_QUERY_RESULT}" | jq -r '.result.content[0].Name // ""')
        echo "Sample persistent class: ${SAMPLE_PERSISTENT}"
        
        if [ -n "${SAMPLE_PERSISTENT}" ]; then
            echo
            echo "9. Query sample data from persistent class..."
            SAMPLE_TABLE=$(echo "${SAMPLE_PERSISTENT}" | tr '.' '_')
            echo "Command: curl -s -X POST --user \"${IRIS_USER}:${IRIS_PASS}\" -b \"${COOKIE_JAR}\" \\"
            echo "  -H \"Content-Type: application/json\" \\"
            echo "  -d '{\"query\":\"SELECT TOP 3 * FROM ${SAMPLE_TABLE}\",\"parameters\":[]}' \\"
            echo "  \"${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query\""
            echo
            
            SAMPLE_DATA_RESULT=$(curl -s -X POST \
              --user "${IRIS_USER}:${IRIS_PASS}" \
              -b "${COOKIE_JAR}" \
              -H "Content-Type: application/json" \
              -d "{\"query\":\"SELECT TOP 3 * FROM ${SAMPLE_TABLE}\",\"parameters\":[]}" \
              "${IRIS_BASE_URL}/v1/${IRIS_NS}/action/query")
            
            echo "${SAMPLE_DATA_RESULT}" | jq .
            
            SAMPLE_DATA_STATUS=$(echo "${SAMPLE_DATA_RESULT}" | jq -r '.status.summary // ""')
            if [ -z "${SAMPLE_DATA_STATUS}" ]; then
                echo "✅ Sample data query executed successfully"
                SAMPLE_DATA_COUNT=$(echo "${SAMPLE_DATA_RESULT}" | jq -r '.result.content | length // 0')
                echo "Sample records found: ${SAMPLE_DATA_COUNT}"
            else
                echo "⚠️  Sample data query failed (table might be empty): ${SAMPLE_DATA_STATUS}"
            fi
        fi
    fi
else
    echo "❌ Persistent classes query failed: ${PERSISTENT_STATUS}"
fi

echo
echo "10. Save query results..."
echo "${QUERY1_RESULT}" > "query-classes.json"
echo "${QUERY2_RESULT}" > "query-parameterized.json"
echo "${QUERY3_RESULT}" > "query-system.json"
echo "${QUERY4_RESULT}" > "query-tables.json"

echo "Query results saved to query-*.json files"

echo
echo "=== Query Operations Complete ==="