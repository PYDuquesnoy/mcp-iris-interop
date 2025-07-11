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
    <Route Url="/execute" Method="POST" Call="ExecuteCode" />
    <Route Url="/start" Method="POST" Call="StartProduction" />
    <Route Url="/update" Method="POST" Call="UpdateProduction" />
    <Route Url="/stop" Method="POST" Call="StopProduction" />
    <Route Url="/clean" Method="POST" Call="CleanProduction" />
    <Route Url="/test-service" Method="POST" Call="TestService" />
    <Route Url="/event-log" Method="POST" Call="ExportEventLog" />
    <Route Url="/message-trace" Method="POST" Call="ExportMessageTrace" />
    <Route Url="/message-body" Method="POST" Call="GetMessageBody" />
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

/// Execute ObjectScript code and return the result
/// Step 6.1 functionality - integrated from exec-proto patterns
ClassMethod ExecuteCode() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract code from request
        Set code = json.code
        Set timeout = json.timeout
        // Set returnValue = json.returnValue  // Simplified for now
        
        If (code = "") {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "No code provided"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Execute the ObjectScript code
        Set result = ""
        Set success = 1
        Set error = ""
        Set returnResult = ""
        
        Try {
            // Execute the ObjectScript code
            Xecute code
            Set result = "Code executed successfully"
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.1 - Execute Method"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.error = error
        Set response.code = code
        
        // If (returnResult '= "") {
        //     Set response.returnValue = returnResult
        // }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.1 - Execute Method"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Start a specific production or the default current one
/// Step 6.2 functionality - production start management
ClassMethod StartProduction() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract production name from request (optional)
        Set productionName = json.productionName
        Set timeout = json.timeout
        If (timeout = "") Set timeout = 30
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.2 - Start Production"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Check if a production is already running
        Set currentProd = ##class(Ens.Director).GetActiveProductionName()
        Set isRunning = ##class(Ens.Director).IsProductionRunning()
        
        If isRunning {
            If (productionName '= "") && (productionName '= currentProd) {
                // Different production requested - need to stop current first
                Set response = ##class(%DynamicObject).%New()
                Set response.success = 0
                Set response.api = "Api.MCPInterop"
                Set response.error = "Production '" _ currentProd _ "' is already running. Stop it first or omit productionName to use current."
                Set response.currentProduction = currentProd
                Set response.requestedProduction = productionName
                Set response.timestamp = $ZDATETIME($HOROLOG, 3)
                Set response.step = "Step 6.2 - Start Production"
                Write response.%ToJSON()
                Return $$$OK
            } Else {
                // Same production or no specific production requested
                Set response = ##class(%DynamicObject).%New()
                Set response.success = 1
                Set response.api = "Api.MCPInterop"
                Set response.result = "Production '" _ currentProd _ "' is already running"
                Set response.productionName = currentProd
                Set response.action = "already_running"
                Set response.timestamp = $ZDATETIME($HOROLOG, 3)
                Set response.step = "Step 6.2 - Start Production"
                Write response.%ToJSON()
                Return $$$OK
            }
        }
        
        // Start the production
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "started"
        
        Try {
            If (productionName = "") {
                // Start default/last production
                Set tSC = ##class(Ens.Director).StartProduction()
                Set result = "Started default production"
                Set action = "started_default"
            } Else {
                // Start specific production
                Set tSC = ##class(Ens.Director).StartProduction(productionName)
                Set result = "Started production: " _ productionName
                Set action = "started_specific"
            }
            
            If $$$ISERR(tSC) {
                Set success = 0
                Set error = $SYSTEM.Status.GetErrorText(tSC)
                Set action = "failed"
            } Else {
                // Get the actual production name that was started
                Set actualProdName = ##class(Ens.Director).GetActiveProductionName()
                If (actualProdName '= "") {
                    Set productionName = actualProdName
                    Set result = "Started production: " _ actualProdName
                }
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.2 - Start Production"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.productionName = productionName
        Set response.timeout = timeout
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.2 - Start Production"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Update the current production configuration
/// Step 6.3 functionality - used when Business Services, Processes, or Operations are added/changed
ClassMethod UpdateProduction() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set timeout = json.timeout
        Set force = json.force
        
        // Set defaults if not provided
        If (timeout = "") Set timeout = 10
        If (force = "") Set force = 0
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.3 - Update Production"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Check if a production is currently running
        Set currentProd = ##class(Ens.Director).GetActiveProductionName()
        Set isRunning = ##class(Ens.Director).IsProductionRunning()
        
        If 'isRunning {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "No production is currently running to update"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.3 - Update Production"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Update the production
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "updated"
        
        Try {
            // Call Ens.Director.UpdateProduction with timeout and force parameters
            Set tSC = ##class(Ens.Director).UpdateProduction(timeout, force)
            
            If $$$ISOK(tSC) {
                Set result = "Production '" _ currentProd _ "' updated successfully"
                Set action = "updated"
            } Else {
                Set success = 0
                Set error = $SYSTEM.Status.GetErrorText(tSC)
                Set action = "failed"
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.3 - Update Production"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.productionName = currentProd
        Set response.timeout = timeout
        Set response.force = force
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.3 - Update Production"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Stop the current production
/// Step 6.4 functionality - stop default current production
ClassMethod StopProduction() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set timeout = json.timeout
        Set force = json.force
        
        // Set defaults if not provided
        If (timeout = "") Set timeout = 10
        If (force = "") Set force = 0
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.4 - Stop Production"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Check if a production is currently running
        Set currentProd = ##class(Ens.Director).GetActiveProductionName()
        Set isRunning = ##class(Ens.Director).IsProductionRunning()
        
        If 'isRunning {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "No production is currently running to stop"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.4 - Stop Production"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Stop the production
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "stopped"
        
        Try {
            // Call Ens.Director.StopProduction with timeout and force parameters
            Set tSC = ##class(Ens.Director).StopProduction(timeout, force)
            
            If $$$ISOK(tSC) {
                Set result = "Production '" _ currentProd _ "' stopped successfully"
                Set action = "stopped"
            } Else {
                Set success = 0
                Set error = $SYSTEM.Status.GetErrorText(tSC)
                Set action = "failed"
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.4 - Stop Production"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.productionName = currentProd
        Set response.timeout = timeout
        Set response.force = force
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.4 - Stop Production"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Clean the current production
/// Step 6.4 functionality - clean current production state
ClassMethod CleanProduction() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set killAppDataToo = json.killAppDataToo
        
        // Set defaults if not provided
        If (killAppDataToo = "") Set killAppDataToo = 0
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.4 - Clean Production"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Clean the production
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "cleaned"
        
        Try {
            // Call Ens.Director.CleanProduction
            Set tSC = ##class(Ens.Director).CleanProduction(killAppDataToo)
            
            If $$$ISOK(tSC) {
                Set result = "Production cleaned successfully"
                Set action = "cleaned"
            } Else {
                Set success = 0
                Set error = $SYSTEM.Status.GetErrorText(tSC)
                Set action = "failed"
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.4 - Clean Production"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.killAppDataToo = killAppDataToo
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.4 - Clean Production"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Use the Testing Service to Call a BP or BO for testing
/// Step 6.5 functionality - testing service integration
ClassMethod TestService() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set target = json.target
        Set requestClass = json.requestClass
        Set requestData = json.requestData
        Set syncCall = json.syncCall
        If (syncCall = "") Set syncCall = 1
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.5 - Test Service"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Check if a production is currently running
        Set currentProd = ##class(Ens.Director).GetActiveProductionName()
        Set isRunning = ##class(Ens.Director).IsProductionRunning()
        
        If 'isRunning {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "No production is currently running. Start a production first."
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.5 - Test Service"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Check if testing is enabled for the production
        Set testingEnabled = ..GetIsTestingEnabled(currentProd)
        If 'testingEnabled {
            // Try to enable testing and update production
            Set tSC = ..EnableTestingOnProduction(currentProd)
            If $$$ISERR(tSC) {
                Set response = ##class(%DynamicObject).%New()
                Set response.success = 0
                Set response.api = "Api.MCPInterop"
                Set response.error = "Testing not enabled and failed to enable: " _ $SYSTEM.Status.GetErrorText(tSC)
                Set response.timestamp = $ZDATETIME($HOROLOG, 3)
                Set response.step = "Step 6.5 - Test Service"
                Write response.%ToJSON()
                Return $$$OK
            }
        }
        
        // Validate required parameters
        If (target = "") {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Target parameter is required (target Business Operation or Business Process)"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.5 - Test Service"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        If (requestClass = "") {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "RequestClass parameter is required (e.g., Ens.StringRequest)"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.5 - Test Service"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Create request object
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "tested"
        Set sessionId = ""
        Set responseData = ""
        
        Try {
            // Create the request object
            Set requestObj = $CLASSMETHOD(requestClass, "%New")
            If '$IsObject(requestObj) {
                Set success = 0
                Set error = "Failed to create request object of class: " _ requestClass
            } Else {
                // Set request data if provided
                If (requestData '= "") {
                    // For Ens.StringRequest, set StringValue property
                    If (requestClass = "Ens.StringRequest") {
                        Set requestObj.StringValue = requestData
                    }
                    // For other request types, you may need to add more handling here
                }
                
                // Call the testing service
                Set testingResponse = ""
                Set tSC = ##class(EnsLib.Testing.Service).SendTestRequest(target, requestObj, .testingResponse, .sessionId, syncCall)
                
                If $$$ISOK(tSC) {
                    Set result = "Test request sent successfully to target: " _ target
                    Set action = "tested"
                    
                    // If we got a response, capture it
                    If $IsObject(testingResponse) {
                        Set responseData = testingResponse.%ClassName(1)
                        // For Ens.StringResponse, capture the StringValue
                        If (testingResponse.%ClassName(1) = "Ens.StringResponse") {
                            Set responseData = responseData _ ": " _ testingResponse.StringValue
                        }
                    }
                } Else {
                    Set success = 0
                    Set error = $SYSTEM.Status.GetErrorText(tSC)
                    Set action = "failed"
                }
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.5 - Test Service"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.target = target
        Set response.requestClass = requestClass
        Set response.requestData = requestData
        Set response.syncCall = syncCall
        Set response.sessionId = sessionId
        Set response.productionName = currentProd
        Set response.testingEnabled = testingEnabled
        
        If (responseData '= "") {
            Set response.responseData = responseData
        }
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.5 - Test Service"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Check if testing is enabled for a production
ClassMethod GetIsTestingEnabled(pProduction As %String) As %Boolean
{
    Set tEnabled = 0
    
    Try {
        // Check if production is loaded in runtime
        If $Data($$$EnsRuntime) && ($G($$$EnsRuntime("Name")) = pProduction) {
            Set tEnabled = +$G($$$EnsRuntime("TestingEnabled"))
        } Else {
            // Check production definition
            &sql(SELECT TestingEnabled INTO :tEnabled
                FROM Ens_Config.Production
                WHERE Name = :pProduction)
            
            If (SQLCODE '= 0) {
                Set tEnabled = 0
            }
        }
        
    } Catch ex {
        Set tEnabled = 0
    }
    
    Quit +tEnabled
}

/// Enable testing on a production and update it
ClassMethod EnableTestingOnProduction(pProduction As %String) As %Status
{
    Set tSC = $$$OK
    
    Try {
        // Update the production definition to enable testing
        &sql(UPDATE Ens_Config.Production SET TestingEnabled = 1 WHERE Name = :pProduction)
        
        If (SQLCODE '= 0) {
            Set tSC = $$$ERROR($$$GeneralError, "Failed to enable testing on production: " _ pProduction)
        } Else {
            // Update the running production to apply the change
            Set tSC = ##class(Ens.Director).UpdateProduction(10, 0)
        }
        
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    
    Quit tSC
}

/// Export Event Log entries
/// Step 6.6 functionality - export event log for debugging
ClassMethod ExportEventLog() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set maxEntries = json.maxEntries
        Set sessionId = json.sessionId
        Set sinceTime = json.sinceTime
        
        // Set defaults if not provided
        If (maxEntries = "") Set maxEntries = 100
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.6 - Export Event Log"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Build SQL query based on parameters
        Set sql = "SELECT TOP ? ID, TimeLogged, Type, Job, SessionId, SourceClass, SourceMethod, Text FROM Ens_Util.Log"
        Set conditions = ""
        
        // Add conditions based on parameters
        If (sessionId '= "") {
            Set conditions = conditions _ " SessionId = ?"
        }
        
        If (sinceTime '= "") {
            If (conditions '= "") Set conditions = conditions _ " AND"
            Set conditions = conditions _ " TimeLogged >= ?"
        }
        
        If (conditions '= "") {
            Set sql = sql _ " WHERE" _ conditions
        }
        
        Set sql = sql _ " ORDER BY TimeLogged DESC"
        
        // Execute query and collect results
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "exported"
        Set logEntries = ##class(%DynamicArray).%New()
        Set entriesCount = 0
        
        Try {
            Set statement = ##class(%SQL.Statement).%New()
            Set tSC = statement.%Prepare(sql)
            If $$$ISERR(tSC) {
                Set success = 0
                Set error = "Failed to prepare SQL: " _ $SYSTEM.Status.GetErrorText(tSC)
            } Else {
                // Execute with proper parameters based on conditions
                If (sessionId '= "") && (sinceTime '= "") {
                    Set resultSet = statement.%Execute(maxEntries, sessionId, sinceTime)
                } ElseIf (sessionId '= "") {
                    Set resultSet = statement.%Execute(maxEntries, sessionId)
                } ElseIf (sinceTime '= "") {
                    Set resultSet = statement.%Execute(maxEntries, sinceTime)
                } Else {
                    Set resultSet = statement.%Execute(maxEntries)
                }
                
                While resultSet.%Next() {
                    Set entry = ##class(%DynamicObject).%New()
                    Set entry.ID = resultSet.%Get("ID")
                    Set entry.TimeLogged = resultSet.%Get("TimeLogged")
                    Set entry.Type = resultSet.%Get("Type")
                    Set entry.Job = resultSet.%Get("Job")
                    Set entry.SessionId = resultSet.%Get("SessionId")
                    Set entry.SourceClass = resultSet.%Get("SourceClass")
                    Set entry.SourceMethod = resultSet.%Get("SourceMethod")
                    Set entry.Text = resultSet.%Get("Text")
                    
                    Do logEntries.%Push(entry)
                    Set entriesCount = entriesCount + 1
                }
                
                Set result = "Successfully exported " _ entriesCount _ " event log entries"
                Set action = "exported"
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.6 - Export Event Log"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.maxEntries = maxEntries
        Set response.entriesCount = entriesCount
        Set response.logEntries = logEntries
        
        If (sessionId '= "") {
            Set response.sessionId = sessionId
        }
        
        If (sinceTime '= "") {
            Set response.sinceTime = sinceTime
        }
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.6 - Export Event Log"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Export Message Trace entries
/// Step 6.7 functionality - export message trace and log entries for debugging
ClassMethod ExportMessageTrace() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set maxEntries = json.maxEntries
        Set sessionId = json.sessionId
        Set sinceTime = json.sinceTime
        Set includeLogEntries = json.includeLogEntries
        
        // Set defaults if not provided
        If (maxEntries = "") Set maxEntries = 100
        If (includeLogEntries = "") Set includeLogEntries = 1
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Step 6.7 - Export Message Trace"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Export message headers and bodies
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "exported"
        Set messageEntries = ##class(%DynamicArray).%New()
        Set logEntries = ##class(%DynamicArray).%New()
        Set messageCount = 0
        Set logCount = 0
        
        Try {
            // Build SQL query for message headers
            Set sql = "SELECT TOP ? ID, TimeCreated, SessionId, MessageBodyClassname, MessageBodyId, SourceConfigName, TargetConfigName, Type, Status FROM Ens.MessageHeader"
            Set conditions = ""
            
            // Add conditions based on parameters
            If (sessionId '= "") {
                Set conditions = conditions _ " SessionId = ?"
            }
            
            If (sinceTime '= "") {
                If (conditions '= "") Set conditions = conditions _ " AND"
                Set conditions = conditions _ " TimeCreated >= ?"
            }
            
            If (conditions '= "") {
                Set sql = sql _ " WHERE" _ conditions
            }
            
            Set sql = sql _ " ORDER BY TimeCreated DESC"
            
            // Execute message headers query
            Set statement = ##class(%SQL.Statement).%New()
            Set tSC = statement.%Prepare(sql)
            If $$$ISERR(tSC) {
                Set success = 0
                Set error = "Failed to prepare message headers SQL: " _ $SYSTEM.Status.GetErrorText(tSC)
            } Else {
                // Execute with proper parameters based on conditions
                If (sessionId '= "") && (sinceTime '= "") {
                    Set resultSet = statement.%Execute(maxEntries, sessionId, sinceTime)
                } ElseIf (sessionId '= "") {
                    Set resultSet = statement.%Execute(maxEntries, sessionId)
                } ElseIf (sinceTime '= "") {
                    Set resultSet = statement.%Execute(maxEntries, sinceTime)
                } Else {
                    Set resultSet = statement.%Execute(maxEntries)
                }
                
                While resultSet.%Next() {
                    Set entry = ##class(%DynamicObject).%New()
                    Set entry.ID = resultSet.%Get("ID")
                    Set entry.TimeCreated = resultSet.%Get("TimeCreated")
                    Set entry.SessionId = resultSet.%Get("SessionId")
                    Set entry.MessageBodyClassname = resultSet.%Get("MessageBodyClassname")
                    Set entry.MessageBodyId = resultSet.%Get("MessageBodyId")
                    Set entry.SourceConfigName = resultSet.%Get("SourceConfigName")
                    Set entry.TargetConfigName = resultSet.%Get("TargetConfigName")
                    Set entry.Type = resultSet.%Get("Type")
                    Set entry.Status = resultSet.%Get("Status")
                    
                    // Try to get message body if available
                    Set bodyClass = resultSet.%Get("MessageBodyClassname")
                    Set bodyId = resultSet.%Get("MessageBodyId")
                    If (bodyClass '= "") && (bodyId '= "") {
                        Try {
                            Set bodyObj = $CLASSMETHOD(bodyClass, "%OpenId", bodyId)
                            If $IsObject(bodyObj) {
                                // Extract message content based on type
                                If $Method(bodyObj, "%IsA", "Ens.StringRequest") || $Method(bodyObj, "%IsA", "Ens.StringResponse") {
                                    // For string requests/responses, get the string value
                                    Set entry.MessageBody = bodyObj.StringValue
                                    Set entry.MessageBodyType = "string"
                                } ElseIf $Method(bodyObj, "%IsA", "Ens.StreamContainer") {
                                    // For stream containers, read the stream content
                                    Set stream = bodyObj.Stream
                                    If $IsObject(stream) {
                                        Do stream.Rewind()
                                        Set content = ""
                                        While 'stream.AtEnd {
                                            Set content = content _ stream.Read(32000)
                                        }
                                        Set entry.MessageBody = content
                                        Set entry.MessageBodyType = "stream"
                                    } Else {
                                        Set entry.MessageBody = "Stream not available"
                                        Set entry.MessageBodyType = "stream_error"
                                    }
                                } Else {
                                    // For other message types, use XML export (standard IRIS capability)
                                    Try {
                                        Set xmlString = ""
                                        Do bodyObj.%XMLExportToString(.xmlString)
                                        Set entry.MessageBody = xmlString
                                        Set entry.MessageBodyType = "xml"
                                    } Catch xmlEx {
                                        // If XML export fails, provide basic info
                                        Set entry.MessageBody = "Message body of class: " _ bodyClass _ " (ID: " _ bodyId _ ")"
                                        Set entry.MessageBodyType = "basic_info"
                                    }
                                }
                                
                                // Also include class and ID for reference
                                Set entry.MessageBodyClass = bodyClass
                                Set entry.MessageBodyId = bodyId
                            } Else {
                                Set entry.MessageBody = "Could not open message body object"
                                Set entry.MessageBodyType = "open_error"
                            }
                        } Catch bodyEx {
                            Set entry.MessageBody = "Error retrieving message body: " _ bodyEx.DisplayString()
                            Set entry.MessageBodyType = "retrieve_error"
                        }
                    } Else {
                        Set entry.MessageBodyType = "no_body"
                    }
                    
                    Do messageEntries.%Push(entry)
                    Set messageCount = messageCount + 1
                }
            }
            
            // If includeLogEntries is enabled, also get log entries for the same session/timeframe
            If includeLogEntries && $$$ISOK(tSC) {
                Set logSql = "SELECT TOP ? ID, TimeLogged, Type, Job, SessionId, SourceClass, SourceMethod, Text FROM Ens_Util.Log"
                Set logConditions = ""
                Set logParams = ""
                
                If (sessionId '= "") {
                    Set logConditions = logConditions _ " SessionId = ?"
                    Set logParams = $LB(maxEntries, sessionId)
                } Else {
                    Set logParams = $LB(maxEntries)
                }
                
                If (sinceTime '= "") {
                    If (logConditions '= "") Set logConditions = logConditions _ " AND"
                    Set logConditions = logConditions _ " TimeLogged >= ?"
                    If (sessionId '= "") {
                        Set logParams = $LB(maxEntries, sessionId, sinceTime)
                    } Else {
                        Set logParams = $LB(maxEntries, sinceTime)
                    }
                }
                
                If (logConditions '= "") {
                    Set logSql = logSql _ " WHERE" _ logConditions
                }
                
                Set logSql = logSql _ " ORDER BY TimeLogged DESC"
                
                Set logStatement = ##class(%SQL.Statement).%New()
                Set tSC = logStatement.%Prepare(logSql)
                If $$$ISOK(tSC) {
                    Set logResultSet = logStatement.%Execute(logParams...)
                    
                    While logResultSet.%Next() {
                        Set logEntry = ##class(%DynamicObject).%New()
                        Set logEntry.ID = logResultSet.%Get("ID")
                        Set logEntry.TimeLogged = logResultSet.%Get("TimeLogged")
                        Set logEntry.Type = logResultSet.%Get("Type")
                        Set logEntry.Job = logResultSet.%Get("Job")
                        Set logEntry.SessionId = logResultSet.%Get("SessionId")
                        Set logEntry.SourceClass = logResultSet.%Get("SourceClass")
                        Set logEntry.SourceMethod = logResultSet.%Get("SourceMethod")
                        Set logEntry.Text = logResultSet.%Get("Text")
                        
                        Do logEntries.%Push(logEntry)
                        Set logCount = logCount + 1
                    }
                }
            }
            
            Set result = "Successfully exported " _ messageCount _ " message entries"
            If includeLogEntries {
                Set result = result _ " and " _ logCount _ " log entries"
            }
            Set action = "exported"
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Step 6.7 - Export Message Trace"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.maxEntries = maxEntries
        Set response.messageCount = messageCount
        Set response.messageEntries = messageEntries
        
        If includeLogEntries {
            Set response.includeLogEntries = includeLogEntries
            Set response.logCount = logCount
            Set response.logEntries = logEntries
        }
        
        If (sessionId '= "") {
            Set response.sessionId = sessionId
        }
        
        If (sinceTime '= "") {
            Set response.sinceTime = sinceTime
        }
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Step 6.7 - Export Message Trace"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

/// Get individual message body content
/// Dedicated endpoint for downloading message bodies with full content
ClassMethod GetMessageBody() As %Status
{
    Try {
        // Get JSON body from the request
        Set body = %request.Content.Read()
        Set json = ##class(%DynamicObject).%FromJSON(body)
        
        // Extract parameters from request
        Set messageHeaderId = json.messageHeaderId
        Set bodyClass = json.bodyClass
        Set bodyId = json.bodyId
        Set format = json.format  // "json", "xml", "raw"
        
        // Set defaults
        If (format = "") Set format = "json"
        
        // Check if Ensemble/Interoperability is available
        Set ensembleAvailable = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        
        If 'ensembleAvailable {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Ensemble/Interoperability not available in this namespace"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Message Body Download"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Get message header info if messageHeaderId provided
        If (messageHeaderId '= "") {
            Set statement = ##class(%SQL.Statement).%New()
            Set tSC = statement.%Prepare("SELECT MessageBodyClassname, MessageBodyId, SourceConfigName, TargetConfigName, TimeCreated FROM Ens.MessageHeader WHERE ID = ?")
            If $$$ISOK(tSC) {
                Set resultSet = statement.%Execute(messageHeaderId)
                If resultSet.%Next() {
                    Set bodyClass = resultSet.%Get("MessageBodyClassname")
                    Set bodyId = resultSet.%Get("MessageBodyId")
                    Set sourceConfig = resultSet.%Get("SourceConfigName")
                    Set targetConfig = resultSet.%Get("TargetConfigName")
                    Set timeCreated = resultSet.%Get("TimeCreated")
                }
            }
        }
        
        // Validate required parameters
        If (bodyClass = "") || (bodyId = "") {
            Set response = ##class(%DynamicObject).%New()
            Set response.success = 0
            Set response.api = "Api.MCPInterop"
            Set response.error = "Both bodyClass and bodyId are required (or provide messageHeaderId)"
            Set response.timestamp = $ZDATETIME($HOROLOG, 3)
            Set response.step = "Message Body Download"
            Write response.%ToJSON()
            Return $$$OK
        }
        
        // Get the message body object
        Set result = ""
        Set success = 1
        Set error = ""
        Set action = "downloaded"
        Set messageContent = ""
        Set contentType = ""
        
        Try {
            Set bodyObj = $CLASSMETHOD(bodyClass, "%OpenId", bodyId)
            If $IsObject(bodyObj) {
                
                If $Method(bodyObj, "%IsA", "Ens.StringRequest") || $Method(bodyObj, "%IsA", "Ens.StringResponse") {
                    // For string requests/responses, get the string value
                    Set messageContent = bodyObj.StringValue
                    Set contentType = "text/plain"
                    
                } ElseIf $Method(bodyObj, "%IsA", "Ens.StreamContainer") {
                    // For stream containers, read the stream content
                    Set stream = bodyObj.Stream
                    If $IsObject(stream) {
                        Do stream.Rewind()
                        Set messageContent = ""
                        While 'stream.AtEnd {
                            Set messageContent = messageContent _ stream.Read(32000)
                        }
                        Set contentType = "text/plain"
                    } Else {
                        Set messageContent = "Stream not available"
                        Set contentType = "text/plain"
                    }
                    
                } ElseIf (format = "xml") || (format = "json") {
                    // For XML format (or JSON fallback), use XML export
                    Try {
                        Do bodyObj.%XMLExportToString(.messageContent)
                        Set contentType = "application/xml"
                    } Catch xmlEx {
                        Set messageContent = "XML export failed: " _ xmlEx.DisplayString()
                        Set contentType = "text/plain"
                    }
                    
                } Else {
                    // Raw format - provide basic object info
                    Set messageContent = "Message body object of class: " _ bodyClass
                    Set contentType = "text/plain"
                }
                
                Set result = "Message body downloaded successfully"
                Set action = "downloaded"
                
            } Else {
                Set success = 0
                Set error = "Could not open message body object with class: " _ bodyClass _ ", ID: " _ bodyId
                Set action = "failed"
            }
            
        } Catch ex {
            Set success = 0
            Set error = ex.DisplayString()
            Set action = "failed"
        }
        
        // Build response
        Set response = ##class(%DynamicObject).%New()
        Set response.success = success
        Set response.api = "Api.MCPInterop"
        Set response.step = "Message Body Download"
        Set response.timestamp = $ZDATETIME($HOROLOG, 3)
        Set response.namespace = $NAMESPACE
        Set response.result = result
        Set response.action = action
        Set response.bodyClass = bodyClass
        Set response.bodyId = bodyId
        Set response.format = format
        Set response.contentType = contentType
        
        If (messageContent '= "") {
            Set response.messageContent = messageContent
        }
        
        If $Data(sourceConfig) {
            Set response.sourceConfig = sourceConfig
            Set response.targetConfig = targetConfig
            Set response.timeCreated = timeCreated
        }
        
        If (error '= "") {
            Set response.error = error
        }
        
        Write response.%ToJSON()
        
    } Catch ex {
        Set error = ##class(%DynamicObject).%New()
        Set error.success = 0
        Set error.api = "Api.MCPInterop"
        Set error.error = ex.DisplayString()
        Set error.timestamp = $ZDATETIME($HOROLOG, 3)
        Set error.step = "Message Body Download"
        
        Write error.%ToJSON()
    }
    
    Quit $$$OK
}

}