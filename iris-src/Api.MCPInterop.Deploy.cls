/// Deployment class for Api.MCPInterop REST API
/// Based on proven DEPLOYMENT-NOTES.MD patterns from exec-proto
Class Api.MCPInterop.Deploy Extends %RegisteredObject
{

/// Deploy the Api.MCPInterop REST API web application
/// This method creates the stored procedure for web app deployment
ClassMethod CreateDeploymentStoredProcedure() As %Status
{
    Set sql = "CREATE PROCEDURE Deploy_ApiMcpInterop() RETURNS VARCHAR(500) LANGUAGE OBJECTSCRIPT { "_
              "New $NAMESPACE "_
              "Set $NAMESPACE = ""%SYS"" "_
              "Set Props(""AutheEnabled"") = 32 "_
              "Set Props(""NameSpace"") = ""IRISAPP"" "_
              "Set Props(""Enabled"") = 1 "_
              "Set Props(""DispatchClass"") = ""Api.MCPInterop"" "_
              "Set Props(""MatchRoles"") = "":%All"" "_
              "Set Props(""Description"") = ""API MCP Interop - Main Project Step 5"" "_
              "If ##class(Security.Applications).Exists(""/api/mcp-interop"") { "_
              "Do ##class(Security.Applications).Delete(""/api/mcp-interop"") "_
              "} "_
              "Set Status = ##class(Security.Applications).Create(""/api/mcp-interop"", .Props) "_
              "If $$$ISOK(Status) { "_
              "QUIT ""SUCCESS: Web app /api/mcp-interop created"" "_
              "} Else { "_
              "QUIT ""ERROR: "" _ $SYSTEM.Status.GetErrorText(Status) "_
              "} "_
              "}"
    
    Try {
        Set stmt = ##class(%SQL.Statement).%New()
        Set status = stmt.%Prepare(sql)
        If $$$ISERR(status) {
            Return status
        }
        
        Set result = stmt.%Execute()
        If $$$ISERR(result.%SQLCODE) {
            Return $$$ERROR($$$SQLError, result.%SQLCODE, result.%Message)
        }
        
        Return $$$OK
        
    } Catch ex {
        Return ex.AsStatus()
    }
}

/// Execute the deployment stored procedure
ClassMethod ExecuteDeployment() As %String
{
    Try {
        Set sql = "SELECT Deploy_ApiMcpInterop() AS Result"
        Set stmt = ##class(%SQL.Statement).%New()
        Set status = stmt.%Prepare(sql)
        If $$$ISERR(status) {
            Return "ERROR: Failed to prepare deployment query"
        }
        
        Set result = stmt.%Execute()
        If result.%Next() {
            Return result.%Get("Result")
        } Else {
            Return "ERROR: No result from deployment procedure"
        }
        
    } Catch ex {
        Return "ERROR: " _ ex.DisplayString()
    }
}

/// Complete deployment process: create procedure and execute it
ClassMethod DeployApiMcpInterop() As %String [ SqlProc ]
{
    // Step 1: Create the stored procedure
    Set status = ..CreateDeploymentStoredProcedure()
    If $$$ISERR(status) {
        Return "ERROR: Failed to create stored procedure - " _ $SYSTEM.Status.GetErrorText(status)
    }
    
    // Step 2: Execute the stored procedure
    Set result = ..ExecuteDeployment()
    
    Return result
}

/// Check if the web application already exists
ClassMethod CheckWebAppExists() As %Boolean
{
    Try {
        New $NAMESPACE
        Set $NAMESPACE = "%SYS"
        Set exists = ##class(Security.Applications).Exists("/api/mcp-interop")
        Return exists
    } Catch ex {
        Return 0
    }
}

/// Get deployment status information
ClassMethod GetDeploymentStatus() As %DynamicObject
{
    Set status = {}
    Set status.webAppPath = "/api/mcp-interop"
    Set status.dispatchClass = "Api.MCPInterop"
    Set status.namespace = "IRISAPP"
    Set status.exists = ..CheckWebAppExists()
    Set status.timestamp = $ZDATETIME($HOROLOG, 3)
    
    Return status
}

}