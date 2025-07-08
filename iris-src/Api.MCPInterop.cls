/// API MCP Interoperability REST API for Main Project Step 5
/// Provides REST endpoints for interoperability production management
Class Api.MCPInterop Extends %CSP.REST
{

/// Content type for REST responses
Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "UTF-8";

/// URL routing configuration for main project
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/list" Method="GET" Call="ListProductions" />
    <Route Url="/status" Method="GET" Call="GetStatus" />
    <Route Url="/test" Method="GET" Call="Test" />
</Routes>
}

/// List all productions in the current namespace
/// Main functionality for Step 5 - use Ens.Director.GetProductionSummary()
ClassMethod ListProductions() As %Status
{
    Set result = ##class(%DynamicArray).%New()
    
    Try {
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If ensembleAvailable {
            // Use Ens.Director to get production summary
            Set productions = ##class(Ens.Director).GetProductionSummary()
            While productions.%Next() {
                Set prod = ##class(%DynamicObject).%New()
                Set prod.Name = productions.%Get("Name")
                Set prod.Status = productions.%Get("Status") 
                Set prod.LastStartTime = productions.%Get("LastStartTime")
                Set prod.LastStopTime = productions.%Get("LastStopTime")
                Set prod.State = productions.%Get("State")
                Set prod.AutoStart = productions.%Get("AutoStart")
                Do result.%Push(prod)
            }
        } Else {
            // Ensemble not available, return informational response
            Set prod = ##class(%DynamicObject).%New()
            Set prod.Name = "No productions available"
            Set prod.Status = "Ensemble not installed"
            Set prod.Note = "This namespace does not have Interoperability enabled"
            Do result.%Push(prod)
        }
        
        Set response = ##class(%DynamicObject).%New()
        Set response.success = 1
        Set response.api = "Api.MCPInterop"
        Set response.version = "1.0"
        Set response.namespace = $NAMESPACE
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.ensembleAvailable = ensembleAvailable
        Set response.productions = result
        Set response.count = result.%Size()
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.namespace = $NAMESPACE
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Get API status information for main project
ClassMethod GetStatus() As %Status
{
    Try {
        Set status = ##class(%DynamicObject).%New()
        Set status.api = "Api.MCPInterop"
        Set status.success = 1
        Set status.timestamp = $ZDATETIME($HOROLOG, 3)
        Set status.namespace = $NAMESPACE
        
        Write status.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Simple test endpoint for main project API
ClassMethod Test() As %Status
{
    Set response = ##class(%DynamicObject).%New()
    Set response.message = "Api.MCPInterop API is working"
    Set response.project = "MCP-IRIS-INTEROP Main Project"
    Set response.step = "Step 5 - Production Management API"
    Set response.api = "Api.MCPInterop"
    Set response.timestamp = $ZDATETIME($HOROLOG, 3)
    Set response.namespace = $NAMESPACE
    Set response.success = 1
    Set response.webAppPath = "/api/mcp-interop"
    
    Write response.%ToJSON()
    
    Quit $$$OK
}

}