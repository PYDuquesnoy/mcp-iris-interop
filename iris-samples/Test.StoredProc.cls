Class Test.StoredProc Extends %RegisteredObject
{

/// Simple stored procedure that returns a value
ClassMethod SimpleTest(input As %String) As %Integer [ SqlName = SimpleTest, SqlProc ]
{
    Quit $Length(input)
}

/// Stored procedure with output parameter
ClassMethod TestWithOutput(input As %String, Output result As %String) As %Integer [ SqlName = TestWithOutput, SqlProc ]
{
    Set result = "Echo: " _ input
    Quit 1
}

/// Stored procedure that returns a result set
ClassMethod TestResultSet(pattern As %String = "%") As %Integer [ ReturnResultsets, SqlName = TestResultSet, SqlProc ]
{
    Set tStatement = ##class(%SQL.Statement).%New()
    Try {
        Do tStatement.prepare("SELECT TOP 5 Name, Super FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH ?")
        Set tResult = tStatement.%Execute(pattern)
        Do %sqlcontext.AddResultSet(tResult)
        Quit 1
    } Catch ex {
        Set %sqlcontext.%SQLCODE = ex.AsSQLCODE()
        Set %sqlcontext.%Message = ex.SQLMessageString()
        Quit 0
    }
}

/// Query as stored procedure
Query SimpleQuery(pattern As %String = "%") As %SQLQuery [ SqlName = SimpleQuery, SqlProc ]
{
    SELECT TOP 3 Name, Super 
    FROM %Dictionary.ClassDefinition 
    WHERE Name %STARTSWITH :pattern
    ORDER BY Name
}

}