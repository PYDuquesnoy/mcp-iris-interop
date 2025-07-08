/// ObjectScript execution class for exec-proto
Class ExecProto.ObjectScript Extends %RegisteredObject
{

/// Execute ObjectScript code and return the result
ClassMethod Execute(code As %String) As %String [ SqlProc ]
{
    Set result = ""
    Set success = 1
    Set error = ""
    
    Try {
        Xecute code
        Set result = "Code executed successfully"
        
    } Catch ex {
        Set success = 0
        Set error = ex.DisplayString()
    }
    
    Set json = "{"
    Set json = json_"""success"":"_success_","
    Set json = json_"""result"":"""_result_""","
    Set json = json_"""error"":"""_error_""""
    Set json = json_"}"
    
    Quit json
}

/// Simple test method
ClassMethod Test() As %String [ SqlProc ]
{
    Quit "Test successful"
}

}