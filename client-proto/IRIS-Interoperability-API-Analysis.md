# IRIS Interoperability Management API Analysis

**Date**: 2025-07-07  
**Purpose**: Comprehensive analysis of existing IRIS interoperability management methods and APIs  
**Scope**: Step 5-6 implementation planning for MCP-IRIS-Interop project

## Executive Summary

This analysis examines the existing IRIS interoperability capabilities to determine what methods are already available versus what needs to be custom implemented for the MCP-IRIS-Interop project. The analysis covers production management, testing services, message/event logging, and REST API capabilities.

## 1. Production Management (Ens.Director)

### ✅ **EXISTING METHODS** - Available in Ens.Director class

#### Production Control Methods
- **StartProduction(productionName)** - Start a specific production or default current one
- **StopProduction(timeout, force)** - Stop the current production  
- **UpdateProduction(timeout, force)** - Update the current production
- **RestartProduction(timeout, force)** - Restart the current production
- **CleanProduction(killAppDataToo)** - Clean the current production

#### Production Status Methods
- **GetProductionStatus()** - Get current production name and state
- **IsProductionRunning()** - Check if production is running
- **ProductionNeedsUpdate()** - Check if production needs update
- **GetActiveProductionName()** - Get active production name
- **GetProductionSummary()** - Get production summary information

#### Production Configuration Methods
- **EnableConfigItem(configItemName, enable, doUpdate)** - Enable/disable config items
- **TempStopConfigItem(configItemName, stop, doUpdate)** - Temporarily stop config items
- **IsItemEnabled(configItemName)** - Check if item is enabled

#### Production Settings Methods
- **GetCurrProductionSettings()** - Get current production settings
- **GetProductionSettings(prodName)** - Get specific production settings
- **GetHostSettings(configItemName)** - Get host-specific settings
- **GetAdapterSettings(configItemName)** - Get adapter-specific settings

### 🔧 **IMPLEMENTATION NEEDED** - Custom REST API Required

#### Production Management REST API
- **List Productions** - Need to implement listing all productions in a namespace
- **REST endpoint structure**: `/api/mcp-interop/productions`
- **Authentication**: User/password (value 32)
- **Base class**: %CSP.REST in package Api.Mcp.Interop.cls

## 2. Testing Service Functionality

### ✅ **EXISTING METHODS** - Available in EnsLib.Testing.Service

#### Core Testing Methods
- **EnsLib.Testing.Service.SendTestRequest(target, request, response, sessionId, getReply)** - Send test request to BP/BO
- **EnsPortal.TestingService.GetRunningProduction()** - Get current running production
- **EnsPortal.TestingService.GetIsTestingEnabled(production)** - Check if testing is enabled

### 🔧 **IMPLEMENTATION NEEDED** - Custom REST API Required

#### Enhanced Testing REST API
- **Execute method testing** - Call specific BP/BO methods with parameters
- **Test result parsing** - Extract and format test results
- **Session management** - Track test sessions and results
- **REST endpoints**: 
  - `/api/mcp-interop/test/bp/{businessProcess}` 
  - `/api/mcp-interop/test/bo/{businessOperation}`

## 3. Message and Event Log Export

### ✅ **EXISTING METHODS** - Available in Core Classes

#### Message Log Classes
- **Ens.MessageHeader** - Core message header with methods:
  - `NewRequestMessage()` - Create new request
  - `ResendMessage()` - Resend message
  - `ResubmitMessage()` - Resubmit message  
  - `Purge()` - Purge old messages
- **Ens.MessageBody** - Core message body storage

#### Event Log Classes
- **EnsPortal.EventLog** - Portal event log with methods:
  - `GetCount()` - Get event count
  - `DoPurge()` - Purge events
  - `MultiTypeExecute()` - Execute multi-type queries
  - `MultiTypeFetch()` - Fetch multi-type results

#### Log Utility Classes
- **Ens.Util.Log** - Base logging utilities
- **Ens.Util.IOLog** - I/O logging
- **Ens.Rule.Log** - Rule logging
- **Ens.Enterprise.MsgBank.Log** - Message bank logging

### 🔧 **IMPLEMENTATION NEEDED** - Custom REST API Required

#### Message/Event Log Export REST API
- **Export last N messages** - Extract recent message log entries
- **Export last N events** - Extract recent event log entries  
- **Export by session** - Export messages/events from specific session
- **Export by date range** - Export within time constraints
- **Format options** - JSON, CSV, XML export formats
- **REST endpoints**:
  - `/api/mcp-interop/messages/export?limit={N}&format={json|csv|xml}`
  - `/api/mcp-interop/events/export?limit={N}&format={json|csv|xml}`
  - `/api/mcp-interop/session/{sessionId}/messages`
  - `/api/mcp-interop/session/{sessionId}/events`

## 4. Web Application Deployment

### ✅ **EXISTING METHODS** - Available in %SYS.REST

#### Web Application Deployment Methods
- **%SYS.REST.DeployApplication(restApplication, webApplication, authenticationType)** - Deploy REST web application
- **%SYS.REST.GetRESTApplications()** - Get all REST applications
- **%SYS.REST.GetRESTApplication(webApplication)** - Get specific REST application
- **%SYS.REST.GetCurrentRESTApplications(requestNamespace)** - Get current namespace applications

### ✅ **IMPLEMENTATION AVAILABLE** - Ready to Use

#### Web Application Creation
- **Deployment method**: Use %SYS.REST.DeployApplication
- **Security**: User/password authentication (value 32)
- **Dynamic deployment**: Can be done programmatically
- **SQL deployment**: Can create SQL stored procedure for deployment

## 5. REST API Framework

### ✅ **EXISTING METHODS** - Available in %CSP.REST

#### REST Base Framework
- **%CSP.REST** - Base REST class with methods:
  - `DispatchRequest()` - Handle REST requests
  - `OnPreDispatch()` - Pre-dispatch processing
  - `AccessCheck()` - Authentication check
  - `ReportHttpStatusCode()` - HTTP status handling
  - `Http405()`, `Http500()` - Error handling

#### Existing Ensemble REST APIs
- **Ens.Activity.API.REST** - Activity API
- **EnsLib.REST.GenericOperation** - Generic REST operations
- **EnsLib.REST.GenericService** - Generic REST services
- **EnsLib.REST.Operation** - REST operation base class
- **EnsLib.REST.Service** - REST service base class

### 🔧 **IMPLEMENTATION NEEDED** - Custom REST API Development

#### Custom MCP-Interop REST API
- **Package**: Api.Mcp.Interop.cls
- **Namespace**: IRISAPP
- **Base class**: %CSP.REST
- **URL pattern**: `/api/mcp-interop/*`
- **Authentication**: User/password (value 32)

## 6. Implementation Strategy

### Phase 1: Core REST API Development
1. **Create Api.Mcp.Interop.cls** - Inherit from %CSP.REST
2. **Deploy web application** - Use %SYS.REST.DeployApplication
3. **Implement production listing** - Use Ens.Director.GetProductionSummary
4. **Test basic connectivity** - Verify REST API functionality

### Phase 2: Production Management Integration
1. **Integrate existing Ens.Director methods** - Wrap in REST endpoints
2. **Add production listing** - Custom SQL queries for production inventory
3. **Implement production control** - Start/stop/update/clean operations
4. **Add configuration management** - Item enable/disable functionality

### Phase 3: Testing Service Integration
1. **Wrap EnsLib.Testing.Service methods** - REST API interface
2. **Add enhanced testing** - Custom method execution
3. **Implement session tracking** - Test result management
4. **Add result formatting** - JSON response formatting

### Phase 4: Log Export Implementation
1. **Create message export methods** - Query Ens.MessageHeader
2. **Create event export methods** - Query event log tables
3. **Add filtering options** - Date, session, limit parameters
4. **Implement export formats** - JSON, CSV, XML options

## 7. Required vs Available Methods Summary

| Functionality | Existing Methods | Custom Implementation Needed |
|---|---|---|
| **Production Control** | ✅ Start/Stop/Update/Clean | 🔧 List Productions |
| **Production Status** | ✅ Full status checking | ✅ Ready to use |
| **Testing Service** | ✅ Basic test execution | 🔧 Enhanced testing API |
| **Message Log Export** | ✅ Core message classes | 🔧 Export REST API |
| **Event Log Export** | ✅ Core event classes | 🔧 Export REST API |
| **Web App Deployment** | ✅ Full deployment API | ✅ Ready to use |
| **REST Framework** | ✅ Complete framework | 🔧 Custom API class |

## 8. Database Tables for Direct Access

### Message Log Tables
- **Ens.MessageHeader** - Message header information
- **Ens.MessageBody** - Message body content
- **Ens_MessageHeader** - SQL accessible table

### Event Log Tables  
- **Ens.Event.Log** - Event log entries
- **Ens_Event_Log** - SQL accessible table

### Production Configuration Tables
- **Ens.Config.Production** - Production definitions
- **Ens.Config.Item** - Configuration items
- **Ens_Config_Production** - SQL accessible table

## 9. Next Steps

1. **Implement Api.Mcp.Interop.cls** - Create custom REST API class
2. **Deploy web application** - Use SQL procedure with %SYS.REST.DeployApplication
3. **Add production listing** - Custom SQL queries for production inventory
4. **Integrate existing methods** - Wrap Ens.Director methods in REST endpoints
5. **Implement log export** - Create message/event export functionality
6. **Add to client prototype** - Update TypeScript client with new endpoints
7. **Create test suite** - Validate all functionality
8. **Document API** - Create comprehensive API documentation

This analysis provides a clear roadmap for implementing the interoperability management functionality, leveraging existing IRIS capabilities while adding custom REST API endpoints for missing functionality.