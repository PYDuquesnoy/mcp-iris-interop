/// MCP-IRIS-INTEROP REST API
/// Provides REST endpoints for InterSystems IRIS interoperability management
/// Package: Api.Mcp.Interop
/// Base Class: %CSP.REST
Class Api.Mcp.Interop Extends %CSP.REST
{

/// Specifies the default character set for the page
Parameter CHARSET = "utf-8";

/// Specifies if input values are converted from their original character set on input
Parameter CONVERTINPUTSTREAM = 1;

/// Specifies the default content type for the page
Parameter CONTENTTYPE = "application/json";

/// This parameter influences the CORS support
Parameter HandleCorsRequest = 1;

/// This parameter controls the CSP session support
Parameter UseSession As Integer = 1;

/// URL Map for REST endpoints
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>

<!-- Production Management -->
<Route Url="/productions" Method="GET" Call="ListProductions"/>
<Route Url="/productions/:production/start" Method="POST" Call="StartProduction"/>
<Route Url="/productions/current/stop" Method="POST" Call="StopProduction"/>
<Route Url="/productions/current/update" Method="POST" Call="UpdateProduction"/>
<Route Url="/productions/current/clean" Method="POST" Call="CleanProduction"/>
<Route Url="/productions/current/status" Method="GET" Call="GetProductionStatus"/>

<!-- Testing Service -->
<Route Url="/test/bp/:target" Method="POST" Call="TestBusinessProcess"/>
<Route Url="/test/bo/:target" Method="POST" Call="TestBusinessOperation"/>
<Route Url="/test/service/:target" Method="POST" Call="TestService"/>

<!-- Message Log Export -->
<Route Url="/messages/export" Method="GET" Call="ExportMessages"/>
<Route Url="/messages/export/:sessionId" Method="GET" Call="ExportMessagesBySession"/>

<!-- Event Log Export -->
<Route Url="/events/export" Method="GET" Call="ExportEvents"/>
<Route Url="/events/export/:sessionId" Method="GET" Call="ExportEventsBySession"/>

<!-- General Operations -->
<Route Url="/execute/:method" Method="POST" Call="ExecuteMethod"/>
<Route Url="/health" Method="GET" Call="HealthCheck"/>

</Routes>
}

/// Health check endpoint
/// GET /api/mcp-interop/health
ClassMethod HealthCheck() As %Status
{
    Set response = {
        "status": "healthy",
        "service": "MCP-IRIS-Interop API",
        "version": "1.0",
        "timestamp": ($ZDATETIME($HOROLOG, 3))
    }
    
    Quit ..RenderJSON(response)
}

/// List all productions in the current namespace
/// GET /api/mcp-interop/productions
ClassMethod ListProductions() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set response.productions = []
        
        // Query all production classes in the namespace
        Set sql = "SELECT Name FROM %Dictionary.ClassDefinition WHERE Super [ 'Ens.Production' AND Name NOT LIKE '%template%'"
        Set statement = ##class(%SQL.Statement).%New()
        Set tSC = statement.%Prepare(sql)
        If $$$ISERR(tSC) Quit
        
        Set result = statement.%Execute()
        While result.%Next() {
            Set productionName = result.%Get("Name")
            Set productionInfo = {
                "name": (productionName),
                "isRunning": (##class(Ens.Director).IsProductionRunning() && (##class(Ens.Director).GetActiveProductionName() = productionName)),
                "isActive": (##class(Ens.Director).GetActiveProductionName() = productionName)
            }
            Do response.productions.%Push(productionInfo)
        }
        
        Set response.count = response.productions.%Size()
        Set response.currentProduction = ##class(Ens.Director).GetActiveProductionName()
        Set response.isRunning = ##class(Ens.Director).IsProductionRunning()
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Start a specific production
/// POST /api/mcp-interop/productions/{production}/start
ClassMethod StartProduction(production As %String) As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        // Start the specified production
        Set tSC = ##class(Ens.Director).StartProduction(production)
        
        If $$$ISOK(tSC) {
            Set response.success = $$$YES
            Set response.message = "Production started successfully"
            Set response.production = production
            Set response.isRunning = ##class(Ens.Director).IsProductionRunning()
        } Else {
            Set response.success = $$$NO
            Set response.error = $SYSTEM.Status.GetErrorText(tSC)
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.success = $$$NO
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Stop the current production
/// POST /api/mcp-interop/productions/current/stop
ClassMethod StopProduction() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set currentProduction = ##class(Ens.Director).GetActiveProductionName()
        
        // Stop the current production
        Set tSC = ##class(Ens.Director).StopProduction(10, 1)  // 10 second timeout, force stop
        
        If $$$ISOK(tSC) {
            Set response.success = $$$YES
            Set response.message = "Production stopped successfully"
            Set response.production = currentProduction
            Set response.isRunning = ##class(Ens.Director).IsProductionRunning()
        } Else {
            Set response.success = $$$NO
            Set response.error = $SYSTEM.Status.GetErrorText(tSC)
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.success = $$$NO
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Update the current production
/// POST /api/mcp-interop/productions/current/update
ClassMethod UpdateProduction() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set currentProduction = ##class(Ens.Director).GetActiveProductionName()
        
        // Update the current production
        Set tSC = ##class(Ens.Director).UpdateProduction(10, 1)  // 10 second timeout, force update
        
        If $$$ISOK(tSC) {
            Set response.success = $$$YES
            Set response.message = "Production updated successfully"
            Set response.production = currentProduction
            Set response.isRunning = ##class(Ens.Director).IsProductionRunning()
        } Else {
            Set response.success = $$$NO
            Set response.error = $SYSTEM.Status.GetErrorText(tSC)
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.success = $$$NO
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Clean the current production
/// POST /api/mcp-interop/productions/current/clean
ClassMethod CleanProduction() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set currentProduction = ##class(Ens.Director).GetActiveProductionName()
        
        // Clean the current production (don't kill app data by default)
        Set tSC = ##class(Ens.Director).CleanProduction(0)
        
        If $$$ISOK(tSC) {
            Set response.success = $$$YES
            Set response.message = "Production cleaned successfully"
            Set response.production = currentProduction
        } Else {
            Set response.success = $$$NO
            Set response.error = $SYSTEM.Status.GetErrorText(tSC)
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.success = $$$NO
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Get current production status
/// GET /api/mcp-interop/productions/current/status
ClassMethod GetProductionStatus() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set response.production = ##class(Ens.Director).GetActiveProductionName()
        Set response.isRunning = ##class(Ens.Director).IsProductionRunning()
        Set response.needsUpdate = ##class(Ens.Director).ProductionNeedsUpdate()
        
        // Get production summary if available
        If response.production '= "" {
            Set summary = ##class(Ens.Director).GetProductionSummary()
            Set response.summary = summary
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Test a Business Process
/// POST /api/mcp-interop/test/bp/{target}
ClassMethod TestBusinessProcess(target As %String) As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        // Get request body
        Set requestBody = %request.Content.Read()
        Set request = ##class(%DynamicObject).%FromJSON(requestBody)
        
        // Create test message based on request
        Set testMessage = ##class(%Persistent).%New()
        If request.%IsDefined("message") {
            // Handle different message types
            Set message = request.message
        } Else {
            Set message = request
        }
        
        // Send test request via Testing Service
        Set tSC = ##class(EnsLib.Testing.Service).SendTestRequest(target, message, .responseObj, "", 1)
        
        If $$$ISOK(tSC) {
            Set response.success = $$$YES
            Set response.target = target
            Set response.message = "Test request sent successfully"
            If $IsObject(responseObj) {
                Set response.response = responseObj
            }
        } Else {
            Set response.success = $$$NO
            Set response.error = $SYSTEM.Status.GetErrorText(tSC)
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.success = $$$NO
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Test a Business Operation
/// POST /api/mcp-interop/test/bo/{target}
ClassMethod TestBusinessOperation(target As %String) As %Status
{
    // Same implementation as TestBusinessProcess for now
    Quit ..TestBusinessProcess(target)
}

/// Test a Service
/// POST /api/mcp-interop/test/service/{target}
ClassMethod TestService(target As %String) As %Status
{
    // Same implementation as TestBusinessProcess for now
    Quit ..TestBusinessProcess(target)
}

/// Export recent messages
/// GET /api/mcp-interop/messages/export?limit={N}&format={json|csv}
ClassMethod ExportMessages() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        // Get query parameters
        Set limit = $GET(%request.Data("limit", 1), 100)
        Set format = $GET(%request.Data("format", 1), "json")
        
        Set response.messages = []
        
        // Query recent messages
        Set sql = "SELECT TOP ? ID, TimeCreated, SessionId, SourceConfigName, TargetConfigName, MessageBodyClassName, Status FROM Ens.MessageHeader ORDER BY TimeCreated DESC"
        Set statement = ##class(%SQL.Statement).%New()
        Set tSC = statement.%Prepare(sql)
        If $$$ISERR(tSC) Quit
        
        Set result = statement.%Execute(limit)
        While result.%Next() {
            Set messageInfo = {
                "id": (result.%Get("ID")),
                "timeCreated": (result.%Get("TimeCreated")),
                "sessionId": (result.%Get("SessionId")),
                "source": (result.%Get("SourceConfigName")),
                "target": (result.%Get("TargetConfigName")),
                "bodyClass": (result.%Get("MessageBodyClassName")),
                "status": (result.%Get("Status"))
            }
            Do response.messages.%Push(messageInfo)
        }
        
        Set response.count = response.messages.%Size()
        Set response.limit = limit
        Set response.format = format
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Export messages by session
/// GET /api/mcp-interop/messages/export/{sessionId}
ClassMethod ExportMessagesBySession(sessionId As %String) As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set response.messages = []
        Set response.sessionId = sessionId
        
        // Query messages for specific session
        Set sql = "SELECT ID, TimeCreated, SourceConfigName, TargetConfigName, MessageBodyClassName, Status FROM Ens.MessageHeader WHERE SessionId = ? ORDER BY TimeCreated DESC"
        Set statement = ##class(%SQL.Statement).%New()
        Set tSC = statement.%Prepare(sql)
        If $$$ISERR(tSC) Quit
        
        Set result = statement.%Execute(sessionId)
        While result.%Next() {
            Set messageInfo = {
                "id": (result.%Get("ID")),
                "timeCreated": (result.%Get("TimeCreated")),
                "source": (result.%Get("SourceConfigName")),
                "target": (result.%Get("TargetConfigName")),
                "bodyClass": (result.%Get("MessageBodyClassName")),
                "status": (result.%Get("Status"))
            }
            Do response.messages.%Push(messageInfo)
        }
        
        Set response.count = response.messages.%Size()
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Export recent events
/// GET /api/mcp-interop/events/export?limit={N}&format={json|csv}
ClassMethod ExportEvents() As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        // Get query parameters
        Set limit = $GET(%request.Data("limit", 1), 100)
        Set format = $GET(%request.Data("format", 1), "json")
        
        Set response.events = []
        
        // Query recent events
        Set sql = "SELECT TOP ? TimeLogged, Type, Name, SessionId, Job, Event FROM Ens.Util.Log ORDER BY TimeLogged DESC"
        Set statement = ##class(%SQL.Statement).%New()
        Set tSC = statement.%Prepare(sql)
        If $$$ISERR(tSC) Quit
        
        Set result = statement.%Execute(limit)
        While result.%Next() {
            Set eventInfo = {
                "timeLogged": (result.%Get("TimeLogged")),
                "type": (result.%Get("Type")),
                "name": (result.%Get("Name")),
                "sessionId": (result.%Get("SessionId")),
                "job": (result.%Get("Job")),
                "event": (result.%Get("Event"))
            }
            Do response.events.%Push(eventInfo)
        }
        
        Set response.count = response.events.%Size()
        Set response.limit = limit
        Set response.format = format
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Export events by session
/// GET /api/mcp-interop/events/export/{sessionId}
ClassMethod ExportEventsBySession(sessionId As %String) As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        Set response.events = []
        Set response.sessionId = sessionId
        
        // Query events for specific session
        Set sql = "SELECT TimeLogged, Type, Name, Job, Event FROM Ens.Util.Log WHERE SessionId = ? ORDER BY TimeLogged DESC"
        Set statement = ##class(%SQL.Statement).%New()
        Set tSC = statement.%Prepare(sql)
        If $$$ISERR(tSC) Quit
        
        Set result = statement.%Execute(sessionId)
        While result.%Next() {
            Set eventInfo = {
                "timeLogged": (result.%Get("TimeLogged")),
                "type": (result.%Get("Type")),
                "name": (result.%Get("Name")),
                "job": (result.%Get("Job")),
                "event": (result.%Get("Event"))
            }
            Do response.events.%Push(eventInfo)
        }
        
        Set response.count = response.events.%Size()
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Execute a general method
/// POST /api/mcp-interop/execute/{method}
ClassMethod ExecuteMethod(method As %String) As %Status
{
    Set tSC = $$$OK
    Set response = {}
    
    Try {
        // Get request body
        Set requestBody = %request.Content.Read()
        Set request = ##class(%DynamicObject).%FromJSON(requestBody)
        
        // This is a placeholder for method execution
        // In a real implementation, you would need proper security and validation
        Set response.method = method
        Set response.message = "Method execution not implemented for security reasons"
        Set response.request = request
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set response.error = ex.DisplayString()
    }
    
    Quit ..RenderJSON(response, tSC)
}

/// Utility method to render JSON response
ClassMethod RenderJSON(data As %DynamicObject, status As %Status = {$$$OK}) As %Status
{
    Set response = {
        "status": {
            "success": ($$$ISOK(status)),
            "code": ($SYSTEM.Status.GetErrorCodes(status)),
            "text": ($SYSTEM.Status.GetErrorText(status))
        },
        "timestamp": ($ZDATETIME($HOROLOG, 3)),
        "result": (data)
    }
    
    Write response.%ToJSON()
    Quit $$$OK
}

}