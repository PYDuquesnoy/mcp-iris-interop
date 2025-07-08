# EXEC-PROTO: Execute ObjectScript Code via SQL Stored Procedures

This prototype demonstrates executing ObjectScript code on InterSystems IRIS via SQL stored procedures, fulfilling Step 1 of Claude-SideProject.md.

## Step 1 Complete ✅

**Objective**: Create a prototype that allows executing ObjectScript code on IRIS via SQL stored procedures.

### What We Achieved

1. **Created SQL Stored Procedures**: Successfully created stored procedures using SQL DDL that execute ObjectScript code
2. **Class Method Integration**: Demonstrated how class methods can be called from stored procedures
3. **Remote Execution**: Proved that ObjectScript can be executed remotely via REST API SQL calls
4. **Parameter Passing**: Showed parameterized stored procedure calls with return values

### Architecture

```
Client (curl/HTTP) → IRIS Atelier REST API → SQL Engine → Stored Procedure → ObjectScript → Results
```

### Working Examples

#### 1. Simple Test Procedure
```sql
CREATE PROCEDURE ExecProto_Test() 
RETURNS VARCHAR(255) 
LANGUAGE OBJECTSCRIPT { 
    QUIT "Hello from ExecProto.Simple!" 
}
```

**Call**: `CALL SQLUSER.ExecProto_Test()`

#### 2. Calculation Procedure
```sql
CREATE PROCEDURE ExecProto_Calculate(a INTEGER, b INTEGER) 
RETURNS INTEGER 
LANGUAGE OBJECTSCRIPT { 
    QUIT a + b 
}
```

**Call**: `CALL SQLUSER.ExecProto_Calculate(10, 20)`

#### 3. ObjectScript Execution Procedure
```sql
CREATE PROCEDURE ExecProto_ExecuteCode(code VARCHAR(500)) 
RETURNS VARCHAR(500) 
LANGUAGE OBJECTSCRIPT { 
    SET result = ""
    TRY { 
        XECUTE code 
        SET result = "Code executed successfully" 
    } CATCH ex { 
        SET result = "Error: " _ ex.DisplayString() 
    } 
    QUIT result 
}
```

**Call**: `CALL SQLUSER.ExecProto_ExecuteCode("SET x = 100")`

### Key Findings

1. **Schema Mapping**: SQL stored procedures without explicit schema go to `SQLUSER` schema → `User` package in IRIS
2. **REST API Integration**: IRIS Atelier REST API `/action/query` endpoint supports stored procedure calls
3. **ObjectScript Execution**: `XECUTE` command allows dynamic ObjectScript execution within stored procedures
4. **Error Handling**: `TRY/CATCH` blocks work in stored procedure ObjectScript code

### Files Created

- `test-stored-procedure.sh` - Initial testing script
- `step1-demo.sh` - Comprehensive demonstration
- `upload-class.sh` - Class upload utility
- `server-classes/ExecProto.Simple.cls` - Sample class with SqlProc methods
- `server-classes/ExecProto.ObjectScript.cls` - ObjectScript execution class

### Usage

1. **Start IRIS Docker container** (from previous steps)
2. **Run test script**:
   ```bash
   cd exec-proto
   chmod +x test-stored-procedure.sh
   ./test-stored-procedure.sh
   ```

### REST API Calls

Execute stored procedures via HTTP POST to:
```
http://localhost:42002/api/atelier/v1/IRISAPP/action/query
```

With JSON payload:
```json
{
  "query": "CALL SQLUSER.ProcedureName(param1, param2)"
}
```

### Next Steps (Step 2)

- Create REST API deployment via stored procedures
- Implement `/side/mcp-interop` endpoint
- Deploy web application using `%SYS.REST.DeployApplication`
- Integrate with Ensemble/Interoperability functions

## Success Criteria Met ✅

- ✅ Load ObjectScript class with methods callable as stored procedures
- ✅ Create stored procedures that call class methods
- ✅ Execute stored procedures via SQL
- ✅ Return results from ObjectScript execution
- ✅ Demonstrate remote code execution capability

**Step 1 of exec-proto is complete and functional!**