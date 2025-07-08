# SQL Stored Procedure Execution Analysis

## Summary

After testing the client-proto SQL API with various stored procedure syntaxes, here are the findings:

## What Works

1. **Basic SQL Queries**: The `/action/query` endpoint works well for standard SQL queries
   ```sql
   SELECT 1 AS One, 2 AS Two
   -- Returns: {"One": 1, "Two": 2}
   ```

2. **Built-in Functions**: Some IRIS built-in functions work in SELECT statements
   ```sql
   SELECT $LENGTH(?) AS Length
   -- With parameter ['Hello'] returns: {"Length": 5}
   
   SELECT $PIECE('A,B,C', ',', 2) AS Result  
   -- Returns: {"Result": "B"}
   ```

3. **Parameter Binding**: Question mark (?) parameters work correctly
   ```sql
   SELECT $LENGTH(?) AS StringLength
   -- With parameter ['Testing 123'] returns: {"StringLength": 11}
   ```

## What Doesn't Work

1. **CALL Syntax**: Traditional stored procedure CALL syntax is not supported
   ```sql
   CALL StoredProcedureName(?)
   -- Error: Stored Procedure not found
   ```

2. **JDBC/ODBC Syntax**: Curly brace syntax is not supported
   ```sql
   {call StoredProcedureName(?)}
   -- Error: SQL statement expected, { found
   ```

3. **Some Functions**: Not all built-in functions return results (e.g., $UPPER, $NOW)

## API Response Structure

The `/action/query` endpoint returns:
```json
{
  "status": {
    "errors": [],
    "summary": ""
  },
  "console": [],
  "result": {
    "content": [
      // Array of result rows
    ]
  }
}
```

## Limitations for Step 1

The current Atelier API's `/action/query` endpoint appears to be designed for SELECT queries rather than stored procedure execution. Key limitations:

1. **No CALL Support**: Cannot use CALL syntax to execute stored procedures
2. **No Output Parameters**: No way to retrieve output parameters from stored procedures
3. **Limited Result Sets**: Only works with queries that return result sets via SELECT

## Recommendations for Step 1

Given these limitations, for executing code on IRIS via SQL stored procedures, we have these options:

### Option 1: Use SELECT with Functions
Create stored procedures that can be called as functions in a SELECT statement:
```sql
SELECT MyPackage.MyFunction(?) AS Result
```

### Option 2: Create Custom REST API
Since the Atelier API has limitations, creating a custom REST endpoint (as planned in Step 2) that can properly execute stored procedures with:
- Support for CALL syntax
- Output parameter handling
- Multiple result set support
- Proper error handling

### Option 3: Use Different Atelier Endpoints
Explore other Atelier endpoints that might support code execution:
- `/action/compile` - for compiling code
- Direct class method execution endpoints (if available)

## Conclusion

The current client-proto implementation successfully executes SQL queries through the Atelier API, but has limitations for stored procedure execution. For the side project Step 1, we should either:

1. Design stored procedures that work within the SELECT statement limitations
2. Proceed directly to Step 2 and create a custom REST API with full stored procedure support
3. Investigate alternative Atelier endpoints for code execution

The most practical approach appears to be creating the custom REST API (Step 2) that will provide full control over stored procedure execution and result handling.