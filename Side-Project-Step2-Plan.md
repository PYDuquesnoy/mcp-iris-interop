# Side Project Step 2: Implementation Plan

## Objective
Create a deployment system that uses SQL stored procedures to install a REST API (/side/mcp-interop) with interoperability functions.

## Requirements Analysis

Based on Claude-SideProject.md, Step 2 requires:

1. **REST API Specification**:
   - URL: `/side/mcp-interop`
   - Class: `Side.Mcp.Interop.cls` inheriting `%CSP.REST`
   - Namespace: `IRISAPP`
   - Security: User/password authentication (value 32)

2. **Deployment Method**:
   - Deploy via SQL stored procedure
   - Use `%SYS.REST.DeployApplication` utility
   - Must be executable through our existing exec-proto system

3. **API Functionality**:
   - Implement `list` endpoint to list Productions in namespace
   - Use `GetProductionSummary` from `Ens.Director` class

## Implementation Strategy

### Phase 1: Create REST API Class
Create `Side.Mcp.Interop.cls` with:
- URL routing for `/list` endpoint
- Production listing functionality
- Proper error handling and JSON responses

### Phase 2: Create Deployment Stored Procedure
Leverage existing `Side.Mcp.Deploy.cls`:
- Already contains `DeployRestAPI()` method with SqlProc
- Uses `%SYS.REST.DeployApplication`
- Returns JSON status information

### Phase 3: Create Client Integration
Extend exec-proto client to:
- Call deployment stored procedures via SQL
- Test REST API endpoints
- Validate deployment success

### Phase 4: End-to-End Testing
- Upload classes via existing upload mechanism
- Deploy REST API via stored procedure
- Test API endpoints
- Verify interoperability functions

## Technical Approach

### 1. REST API Class Structure
```objectscript
Class Side.Mcp.Interop Extends %CSP.REST
{
    Parameter CONTENTTYPE = "application/json";
    
    XData UrlMap
    {
        <Routes>
            <Route Url="/list" Method="GET" Call="ListProductions" />
        </Routes>
    }
    
    ClassMethod ListProductions() As %Status
    {
        // Implementation using Ens.Director.GetProductionSummary()
    }
}
```

### 2. Deployment via SQL
Use existing stored procedure approach:
```sql
SELECT Side.Mcp.Deploy_DeployRestAPI() AS Result
```

### 3. Client Testing
```typescript
// Upload REST API class
await client.uploadAndCompileClass('Side.Mcp.Interop', classContent);

// Deploy via stored procedure  
const deployResult = await client.executeQuery(
  "SELECT Side.Mcp.Deploy_DeployRestAPI() AS Status"
);

// Test REST API
const apiResponse = await axios.get('/side/mcp-interop/list');
```

## Expected Deliverables

1. **`Side.Mcp.Interop.cls`** - REST API implementation
2. **Updated deployment system** - Enhanced stored procedures
3. **Client test scripts** - End-to-end validation
4. **Demo scripts** - Step 2 demonstration
5. **Documentation** - Implementation and usage guide

## Success Criteria

- ✅ REST API class successfully created and compiled
- ✅ Web application deployed via stored procedure  
- ✅ `/side/mcp-interop/list` endpoint responding with JSON
- ✅ Productions list functionality working (even if no productions exist)
- ✅ Security authentication (user/password) enforced
- ✅ End-to-end test demonstrating full workflow

## Risk Mitigation

1. **Complex ObjectScript in SQL**: Use pre-uploaded classes instead of inline SQL
2. **Web Application Deployment**: Leverage existing `Side.Mcp.Deploy.cls` which already works
3. **Interoperability Dependencies**: Handle gracefully if Ensemble components not available
4. **Authentication Issues**: Test with known credentials (_SYSTEM/SYS)

## Next Steps

1. Create `Side.Mcp.Interop.cls` with production listing functionality
2. Test deployment using existing `Side.Mcp.Deploy.DeployRestAPI()` method
3. Create comprehensive test scripts for validation
4. Document and demonstrate complete workflow

This plan builds on the successful Step 1 foundation and uses proven patterns for Step 2 implementation.