# ObjectScript Stored Procedure Examples

These examples from legacy/cachesamples show different patterns for implementing stored procedures in InterSystems IRIS ObjectScript.

## 1. Simple Stored Procedure Returning Values

From `Sample.Person.cls`:

```objectscript
/// Returns a value and uses ByRef parameters
ClassMethod StoredProcTest(name As %String, ByRef response As %String) As %Integer [ SqlName = Stored_Procedure_Test, SqlProc ]
{
    // Set response to the concatenation of name
    Set response = name _ "||" _ name
    QUIT 29  // Return value
}
```

Key points:
- Use `SqlProc` keyword to mark method as stored procedure
- `SqlName` provides the SQL name
- `ByRef` parameters can return values to caller
- Method returns an integer value

## 2. Stored Procedure with SQL Operations

From `Sample.Person.cls`:

```objectscript
ClassMethod UpdateProcTest(zip As %String, city As %String, state As %String) As %Integer [ SqlProc ]
{
    New %ROWCOUNT,%ROWID
    
    &sql(UPDATE Sample.Person 
    SET Home_City = :city, Home_State = :state 
    WHERE Home_Zip = :zip)
    
    // Return context information to client via %SQLProcContext object
    If ($g(%sqlcontext)'=$$$NULLOREF) { 
        Set %sqlcontext.SQLCode = SQLCODE
        Set %sqlcontext.RowCount = %ROWCOUNT
    }
    QUIT 1
}
```

Key points:
- Uses embedded SQL (&sql)
- Access to SQLCODE and %ROWCOUNT system variables
- Uses `%sqlcontext` to return status information

## 3. Stored Procedure Returning Result Sets

From `Sample.ResultSets.cls`:

```objectscript
ClassMethod PersonSets(name As %String = "", state As %String = "MA") As %Integer [ ReturnResultsets, SqlName = PersonSets, SqlProc ]
{
    // %sqlcontext is automatically created for methods with SQLPROC
    set tStatement = ##class(%SQL.Statement).%New()
    try {
        // First result set
        do tStatement.prepare("select name,dob,spouse from sample.person where name %STARTSWITH ? order by 1")
        set tResult = tStatement.%Execute(name)
        do %sqlcontext.AddResultSet(tResult)
        
        // Second result set
        do tStatement.prepare("select name,age,home_city,home_state from sample.person where home_state = ? order by 4, 1")
        set tResult = tStatement.%Execute(state)
        do %sqlcontext.AddResultSet(tResult)
        
        set tReturn = 1
    }
    catch tException {
        set %sqlcontext.%SQLCODE = tException.AsSQLCODE()
        set %sqlcontext.%Message = tException.SQLMessageString()
        set tReturn = 0
    }
    quit tReturn
}
```

Key points:
- Use `ReturnResultsets` keyword to indicate procedure returns result sets
- Use `%sqlcontext.AddResultSet()` to add result sets
- Can return multiple result sets from one procedure
- Exception handling with proper error reporting

## 4. Query as Stored Procedure

From `Sample.Person.cls`:

```objectscript
Query ByName(name As %String = "") As %SQLQuery(CONTAINID = 1, SELECTMODE = "RUNTIME") [ SqlName = SP_Sample_By_Name, SqlProc ]
{
SELECT ID, Name, DOB, SSN
FROM Sample.Person
WHERE (Name %STARTSWITH :name)
ORDER BY Name
}
```

Key points:
- Class queries can be exposed as stored procedures
- Use `SqlProc` keyword on the query
- Parameters become stored procedure parameters

## 5. Custom Result Set with Stored Procedure

From `Sample.CustomResultSet.cls`:

```objectscript
ClassMethod CustomResult(pRowcount As %Integer = 100) As %Status [ ReturnResultsets, SqlName = CustomResult, SqlProc ]
{
    #dim %sqlcontext as %Library.ProcedureContext
    try {
        if '$Isobject($Get(%sqlcontext)) { 
            set %sqlcontext = ##class(%Library.ProcedureContext).%New() 
        }
        set tResult = ..%New(,pRowcount)
        do %sqlcontext.AddResultSet(tResult)
    }
    catch tException {
        if '$Isobject($Get(%sqlcontext)) { 
            set %sqlcontext = ##class(%Library.ProcedureContext).%New() 
        }
        // Error handling...
        set %sqlcontext.%SQLCODE = -400
        set %sqlcontext.%Message = "Exception: " _ tException.Name
    }
    quit $$$OK
}
```

Key points:
- Custom result sets extend `%SQL.CustomResultSet`
- Create procedure context if not already present
- Use exception handling with proper SQL error codes

## Important Context Objects

1. **%sqlcontext** - Available in SqlProc methods
   - `.%SQLCODE` - Set SQL error code
   - `.%Message` - Set error message
   - `.RowCount` - Number of rows affected
   - `.AddResultSet()` - Add result set to return
   - `.%Display()` - Display results (for testing)

2. **%SQL.Statement** - For dynamic SQL
   - `.%New()` - Create new statement
   - `.prepare()` - Prepare SQL statement
   - `.%Execute()` - Execute with parameters

## Calling Stored Procedures

From the command line:
```objectscript
// Direct method call
set return = ##class(Sample.ResultSets).PersonSets("D","NY")
do %sqlcontext.%Display()

// Using dynamic SQL
set result = ##class(%SQL.Statement).%ExecDirect(,"call Sample.PersonSets('D','NY')")
do result.%Display()
```

From SQL:
```sql
CALL Sample.PersonSets('A','NY')
```

From JDBC/ODBC:
```sql
{call Sample.PersonSets('A','NY')}
```