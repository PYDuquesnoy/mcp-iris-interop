/// Deployment class for Side MCP Interop REST API
/// Provides stored procedures to deploy web applications
Class Side.Mcp.Deploy Extends %RegisteredObject
{

/// Deploy the Side MCP Interop REST API
/// Creates web application /side/mcp-interop with security authentication
ClassMethod DeployRestAPI() As %String [ SqlProc ]
{
    Set status = "starting"
    Set webApp = "/side/mcp-interop"
    Set errorMsg = ""
    Set deployed = 0
    
    Try {
        // Check if web application already exists
        Set exists = ##class(Security.Applications).Exists(webApp)
        
        // Deploy the web application using %SYS.REST.DeployApplication
        Set spec = {}
        Set spec.Name = webApp
        Set spec.DispatchClass = "Side.Mcp.Interop"
        Set spec.NameSpace = $NAMESPACE
        Set spec.Enabled = 1
        Set spec.AutheEnabled = 32  // User/password authentication
        Set spec.MatchRoles = ":%All"
        Set spec.Description = "Side MCP Interoperability REST API"
        
        Set tSC = ##class(%SYS.REST).DeployApplication(webApp, spec)
        
        If $$$ISOK(tSC) {
            Set status = "success"
            Set deployed = 1
        } Else {
            Set status = "error"
            Set errorMsg = $SYSTEM.Status.GetErrorText(tSC)
        }
        
        // Verify deployment
        Set newExists = ##class(Security.Applications).Exists(webApp)
        
        Set json = "{"
        Set json = json_"""status"":"""_status_""","
        Set json = json_"""webApplication"":"""_webApp_""","
        Set json = json_"""dispatchClass"":""Side.Mcp.Interop"","
        Set json = json_"""namespace"":"""_$NAMESPACE_""","
        Set json = json_"""existedBefore"":"_exists_","
        Set json = json_"""deployed"":"_deployed_","
        Set json = json_"""existsAfter"":"_newExists_","
        Set json = json_"""timestamp"":"""_$ZDATETIME($HOROLOG, 3)_""""
        If errorMsg'="" Set json = json_",""error"":"""_errorMsg_""""
        Set json = json_"}"
        
    } Catch ex {
        Set json = "{"
        Set json = json_"""status"":""exception"","
        Set json = json_"""error"":"""_ex.DisplayString()_""","
        Set json = json_"""webApplication"":"""_webApp_""","
        Set json = json_"""timestamp"":"""_$ZDATETIME($HOROLOG, 3)_""""
        Set json = json_"}"
    }
    
    Quit json
}

/// Get deployment status
ClassMethod GetDeploymentStatus() As %String [ SqlProc ]
{
    Set webApp = "/side/mcp-interop"
    
    Try {
        // Check if web application exists
        Set exists = ##class(Security.Applications).Exists(webApp)
        
        Set json = "{"
        Set json = json_"""webApplication"":"""_webApp_""","
        Set json = json_"""exists"":"_exists_","
        Set json = json_"""namespace"":"""_$NAMESPACE_""","
        Set json = json_"""timestamp"":"""_$ZDATETIME($HOROLOG, 3)_""""
        
        If exists {
            Set json = json_",""status"":""deployed"""
            Set json = json_",""url"":""http://localhost:42002"_webApp_""""
            Set json = json_",""message"":""Web application is deployed"""
        } Else {
            Set json = json_",""status"":""not_deployed"""
            Set json = json_",""message"":""Web application not found"""
        }
        
        Set json = json_"}"
        
    } Catch ex {
        Set json = "{"
        Set json = json_"""status"":""error"","
        Set json = json_"""error"":"""_ex.DisplayString()_""","
        Set json = json_"""timestamp"":"""_$ZDATETIME($HOROLOG, 3)_""""
        Set json = json_"}"
    }
    
    Quit json
}

/// Undeploy the REST API (for cleanup)
ClassMethod UndeployRestAPI() As %String [ SqlProc ]
{
    Set webApp = "/side/mcp-interop"
    Set status = "starting"
    Set errorMsg = ""
    
    Try {
        // Check if exists before undeploying
        Set existsBefore = ##class(Security.Applications).Exists(webApp)
        
        If existsBefore {
            Set tSC = ##class(Security.Applications).Delete(webApp)
            If $$$ISOK(tSC) {
                Set status = "success"
            } Else {
                Set status = "error"
                Set errorMsg = $SYSTEM.Status.GetErrorText(tSC)
            }
        } Else {
            Set status = "not_found"
        }
        
        // Verify undeploy
        Set existsAfter = ##class(Security.Applications).Exists(webApp)
        
        Set json = "{"
        Set json = json_"""status"":"""_status_""","
        Set json = json_"""webApplication"":"""_webApp_""","
        Set json = json_"""existsBefore"":"_existsBefore_","
        Set json = json_"""existsAfter"":"_existsAfter_","
        Set json = json_"""timestamp"":"""_$ZDATETIME($HOROLOG, 3)_""""
        If errorMsg'="" Set json = json_",""error"":"""_errorMsg_""""
        Set json = json_"}"
        
    } Catch ex {
        Set json = "{"
        Set json = json_"""status"":""exception"","
        Set json = json_"""error"":"""_ex.DisplayString()_""","
        Set json = json_"""timestamp"":"""_$ZDATETIME($HOROLOG, 3)_""""
        Set json = json_"}"
    }
    
    Quit json
}

}