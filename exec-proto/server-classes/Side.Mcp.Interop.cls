/// Side MCP Interoperability REST API
/// Provides REST endpoints for interoperability production management
Class Side.Mcp.Interop Extends %CSP.REST
{

/// Content type for REST responses
Parameter CONTENTTYPE = "application/json";

Parameter CHARSET = "UTF-8";

/// URL routing configuration
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/list" Method="GET" Call="ListProductions" />
    <Route Url="/status" Method="GET" Call="GetStatus" />
    <Route Url="/test" Method="GET" Call="Test" />
</Routes>
}

/// List all productions in the current namespace
ClassMethod ListProductions() As %Status
{
    Set result = []
    
    Try {
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If ensembleAvailable {
            // Use Ens.Director to get production summary
            Set productions = ##class(Ens.Director).GetProductionSummary()
            While productions.%Next() {
                Set prod = {}
                Set prod.Name = productions.%Get("Name")
                Set prod.Status = productions.%Get("Status") 
                Set prod.LastStartTime = productions.%Get("LastStartTime")
                Set prod.LastStopTime = productions.%Get("LastStopTime")
                Do result.%Push(prod)
            }
        } Else {
            // Ensemble not available, return informational response
            Set prod = {}
            Set prod.Name = "No productions available"
            Set prod.Status = "Ensemble not installed"
            Set prod.Note = "This namespace does not have Interoperability enabled"
            Do result.%Push(prod)
        }
        
        Set response = {}
        Set response.success = 1
        Set response.namespace = $NAMESPACE
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.ensembleAvailable = ensembleAvailable
        Set response.productions = result
        Set response.count = result.%Size()
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = {}
        Set error.success = 0
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.namespace = $NAMESPACE
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Get API status information
ClassMethod GetStatus() As %Status
{
    Try {
        Set status = {}
        Set status.api = "Side.Mcp.Interop"
        Set status.version = "1.0"
        Set status.namespace = $NAMESPACE
        Set status.timestamp = $ZDATETIME($HOROLOG, 3)
        Set status.server = $SYSTEM.Version.GetNumber()
        Set status.success = 1
        
        // Check Ensemble availability
        Set status.ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        // Check if any productions exist
        If status.ensembleAvailable {
            Set productions = ##class(Ens.Director).GetProductionSummary()
            Set status.productionCount = 0
            While productions.%Next() {
                Set status.productionCount = status.productionCount + 1
            }
        } Else {
            Set status.productionCount = "N/A"
        }
        
        Write status.%ToJSON()
        
    } Catch ex {
        Set error = {}
        Set error.success = 0
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Simple test endpoint
ClassMethod Test() As %Status
{
    Set response = {}
    Set response.message = "Side MCP Interop API is working"
    Set response.timestamp = $ZDATETIME($HOROLOG, 3)
    Set response.namespace = $NAMESPACE
    Set response.success = 1
    
    Write response.%ToJSON()
    
    Quit $$$OK
}