/// Utility class for testing Step 4 functionality
Class Test.Utility
{

/// Class method to format a string with current timestamp
ClassMethod FormatWithTimestamp(input As %String) As %String
{
    Set timestamp = $ZDATETIME($HOROLOG, 3)
    Return "[" _ timestamp _ "] " _ input
}

/// Class method to calculate factorial
ClassMethod Factorial(n As %Integer) As %Integer
{
    If (n <= 1) {
        Return 1
    }
    Return n * ..Factorial(n - 1)
}

/// Class method to validate email format (simple validation)
ClassMethod IsValidEmail(email As %String) As %Boolean
{
    Return $MATCH(email, "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
}

/// Class method to get system information
ClassMethod GetSystemInfo() As %String
{
    Set info = ""
    Set info = info _ "Version: " _ $SYSTEM.Version.GetNumber() _ $CHAR(13,10)
    Set info = info _ "Namespace: " _ $NAMESPACE _ $CHAR(13,10)
    Set info = info _ "Current Time: " _ $ZDATETIME($HOROLOG, 3) _ $CHAR(13,10)
    Set info = info _ "User: " _ $USERNAME
    Return info
}

/// Class method to demonstrate error handling
ClassMethod TestErrorHandling(throwError As %Boolean = 0) As %Status
{
    Try {
        If throwError {
            Set sc = $$$ERROR($$$GeneralError, "This is a test error")
            Return sc
        }
        Write "No error thrown", !
        Return $$$OK
    } Catch ex {
        Write "Caught exception: ", ex.DisplayString(), !
        Return ex.AsStatus()
    }
}

}