/// Test class for MCP-IRIS-Interop REST API deployment
Class TestMcpInterop
{

/// Test method to deploy the REST API
ClassMethod DeployAPI() As %Status
{
    Set tSC = $$$OK
    
    Try {
        Write "=== MCP-IRIS-INTEROP REST API Deployment Test ===", !
        
        // Create the REST application object
        Set restApp = ##class(%REST.Application).%New()
        Set restApp.Name = "Api.Mcp.Interop"
        Set restApp.DispatchClass = "Api.Mcp.Interop"
        Set restApp.LegacyRouting = 0
        
        // Create the web application object
        Set webApp = ##class(%CSP.Application).%New()
        Set webApp.Name = "/api/mcp-interop"
        Set webApp.Description = "MCP-IRIS-Interop REST API"
        Set webApp.Namespace = "IRISAPP"
        Set webApp.AutheEnabled = 32  // User/password authentication
        Set webApp.UnauthenticatedEnabled = 0
        Set webApp.InboundWebServicesEnabled = 1
        
        // Deploy the application
        Write "Deploying REST application...", !
        Set tSC = ##class(%SYS.REST).DeployApplication(restApp, webApp, 32)
        
        If $$$ISOK(tSC) {
            Write "✅ REST API deployed successfully!", !
            Write "URL: http://localhost:42002/api/mcp-interop/", !
        } Else {
            Write "❌ Deployment failed: ", $SYSTEM.Status.GetErrorText(tSC), !
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Write "❌ Error during deployment: ", ex.DisplayString(), !
    }
    
    Quit tSC
}

/// Test method to verify the deployment
ClassMethod VerifyAPI() As %Status
{
    Set tSC = $$$OK
    
    Try {
        Write "=== MCP-IRIS-INTEROP REST API Verification ===", !
        
        // Check if the web application exists
        Set webapp = ##class(%SYS.REST).GetRESTApplication("/api/mcp-interop")
        If $IsObject(webapp) {
            Write "✅ Web application '/api/mcp-interop' exists", !
            Write "   Namespace: ", webapp.Namespace, !
            Write "   Authentication: ", webapp.AutheEnabled, !
        } Else {
            Write "❌ Web application '/api/mcp-interop' not found", !
        }
        
        // Check if the dispatch class exists
        If ##class(%Dictionary.ClassDefinition).%ExistsId("Api.Mcp.Interop") {
            Write "✅ Dispatch class 'Api.Mcp.Interop' exists", !
        } Else {
            Write "❌ Dispatch class 'Api.Mcp.Interop' not found", !
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Write "❌ Error during verification: ", ex.DisplayString(), !
    }
    
    Quit tSC
}

/// Simple test method
ClassMethod Test() As %String
{
    Quit "Hello from TestMcpInterop class!"
}

}