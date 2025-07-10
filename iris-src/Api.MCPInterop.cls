/// API MCP Interoperability REST API for Main Project Step 5
/// Provides REST endpoints for interoperability production management

Include Ensemble

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
            // GetProductionSummary expects ByRef parameter and returns status
            Set tSC = ##class(Ens.Director).GetProductionSummary(.tInfo, $NAMESPACE)
            If $$$ISOK(tSC) {
                // tInfo contains production data as subscripted array
                // Format: tInfo(productionName) = $LB(status, lastStartTime, lastStopTime, autoStart)
                Set productionName = ""
                For {
                    Set productionName = $ORDER(tInfo(productionName))
                    Quit:productionName=""
                    
                    Set prod = ##class(%DynamicObject).%New()
                    Set prod.Name = productionName
                    Set productionData = tInfo(productionName)
                    Set prod.Status = $LIST(productionData, 1)
                    Set prod.LastStartTime = $LIST(productionData, 2)
                    Set prod.LastStopTime = $LIST(productionData, 3)
                    Set prod.AutoStart = $LIST(productionData, 4)
                    Do result.%Push(prod)
                }
            } Else {
                // Error getting production summary
                Set prod = ##class(%DynamicObject).%New()
                Set prod.Name = "Error retrieving productions"
                Set prod.Status = "Error: " _ $SYSTEM.Status.GetErrorText(tSC)
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