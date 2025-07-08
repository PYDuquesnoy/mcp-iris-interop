# DEPLOYMENT NOTES - CRITICAL REFERENCE

## How to Deploy a Stored Procedure and Execute it for Installing a REST API Class

### ⚠️ IMPORTANT: Read this EVERY time you open this project

This document contains the essential patterns for deploying REST APIs via stored procedures in InterSystems IRIS. This is the core methodology for this project.

---

## 🎯 Core Deployment Pattern

### Step 1: Create Stored Procedure for Web Application Deployment

**Working SQL Command:**
```sql
CREATE PROCEDURE Deploy_WebApp() RETURNS VARCHAR(500) LANGUAGE OBJECTSCRIPT { 
    New $NAMESPACE 
    Set $NAMESPACE = "%SYS" 
    Set Props("AutheEnabled") = 32 
    Set Props("NameSpace") = "IRISAPP" 
    Set Props("Enabled") = 1 
    Set Props("DispatchClass") = "Side.Mcp.Interop" 
    Set Props("MatchRoles") = ":%All" 
    Set Props("Description") = "Side MCP Interop API" 
    If ##class(Security.Applications).Exists("/side/mcp-interop") { 
        Do ##class(Security.Applications).Delete("/side/mcp-interop") 
    } 
    Set Status = ##class(Security.Applications).Create("/side/mcp-interop", .Props) 
    If $$$ISOK(Status) { 
        QUIT "SUCCESS: Web app created" 
    } Else { 
        QUIT "ERROR: " _ $SYSTEM.Status.GetErrorText(Status) 
    } 
}
```

**Execute via Atelier API:**
```bash
curl -s -X POST \
  --user "_SYSTEM:SYS" \
  -H "Content-Type: application/json" \
  -d '{"query": "CREATE PROCEDURE Deploy_WebApp() RETURNS VARCHAR(500) LANGUAGE OBJECTSCRIPT { New $NAMESPACE Set $NAMESPACE = \"%SYS\" Set Props(\"AutheEnabled\") = 32 Set Props(\"NameSpace\") = \"IRISAPP\" Set Props(\"Enabled\") = 1 Set Props(\"DispatchClass\") = \"Side.Mcp.Interop\" Set Props(\"MatchRoles\") = \":%All\" Set Props(\"Description\") = \"Side MCP Interop API\" If ##class(Security.Applications).Exists(\"/side/mcp-interop\") { Do ##class(Security.Applications).Delete(\"/side/mcp-interop\") } Set Status = ##class(Security.Applications).Create(\"/side/mcp-interop\", .Props) If $$$ISOK(Status) { QUIT \"SUCCESS: Web app created\" } Else { QUIT \"ERROR: \" _ $SYSTEM.Status.GetErrorText(Status) } }"}' \
  "http://localhost:42002/api/atelier/v1/IRISAPP/action/query"
```

### Step 2: Execute the Stored Procedure

**Working Execution Command:**
```bash
curl -s -X POST \
  --user "_SYSTEM:SYS" \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT Deploy_WebApp() AS Result"}' \
  "http://localhost:42002/api/atelier/v1/IRISAPP/action/query"
```

**Expected Success Response:**
```json
{
  "status": {"errors": [], "summary": ""},
  "console": [],
  "result": {
    "content": [{"Result": "SUCCESS: Web app created"}]
  }
}
```

---

## 🚀 Complete Deployment Workflow

### 1. Upload REST API Class First
- **NEVER** try to embed complex ObjectScript classes in SQL DDL
- **ALWAYS** upload the class file via Atelier API first
- **THEN** deploy the web application via stored procedure

```bash
# Upload class
curl -s -X PUT \
  --user "_SYSTEM:SYS" \
  -H "Content-Type: application/json" \
  -d @server-classes/Side.Mcp.Interop.cls \
  "http://localhost:42002/api/atelier/v1/IRISAPP/doc/Side.Mcp.Interop.cls"
```

### 2. Compile the Class
```bash
curl -s -X POST \
  --user "_SYSTEM:SYS" \
  -H "Content-Type: application/json" \
  -d '{"docs": ["Side.Mcp.Interop.cls"]}' \
  "http://localhost:42002/api/atelier/v1/IRISAPP/action/compile"
```

### 3. Deploy Web Application via Stored Procedure
(Use the pattern from Step 1 above)

### 4. Test the Endpoints
```bash
curl -s --user "_SYSTEM:SYS" \
  "http://localhost:42002/side/mcp-interop/test"
```

---

## 🔧 Critical Configuration Details

### Web Application Properties
- **AutheEnabled**: 32 (user/password authentication)
- **NameSpace**: "IRISAPP" 
- **Enabled**: 1
- **DispatchClass**: "Side.Mcp.Interop"
- **MatchRoles**: ":%All"
- **Path**: "/side/mcp-interop"

### Environment Variables
```bash
export IRIS_HOST="localhost"
export IRIS_PORT="42002"
export IRIS_USER="_SYSTEM"
export IRIS_PASS="SYS"
export IRIS_NS="IRISAPP"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"
```

---

## ⚡ Key Insights & Gotchas

### ✅ What Works
1. **Simple stored procedures** with basic ObjectScript logic
2. **SELECT function_name() AS Result** - returns results reliably
3. **%SYS.REST.DeployApplication()** - proper web app deployment method
4. **Security.Applications.Create()** - direct web app creation
5. **Separate upload and deployment** - upload class first, then deploy

### ❌ What Doesn't Work
1. **Complex ObjectScript in SQL DDL** - escaping becomes impossible
2. **CALL procedure_name()** - doesn't return results consistently
3. **Direct execution commands** - console output unreliable
4. **Inline class creation** - JSON escaping nightmare

### 🎯 Best Practices
1. **Always upload classes via Atelier API** - never embed in SQL
2. **Use stored procedures only for deployment** - not for class creation
3. **Test with SELECT syntax** - most reliable for getting results
4. **Verify class compilation** - always compile after upload
5. **Check web app exists** - use Security.Applications.Exists()

---

## 🔍 Debugging Commands

### Check if Class Exists
```bash
curl -s --user "_SYSTEM:SYS" \
  "http://localhost:42002/api/atelier/v1/IRISAPP/doc/Side.Mcp.Interop.cls"
```

### Check if Web Application Exists
```sql
SELECT Security.Applications.Exists("/side/mcp-interop") AS WebAppExists
```

### Test Endpoint Directly
```bash
curl -s -w "HTTP_STATUS:%{http_code}" \
  --user "_SYSTEM:SYS" \
  "http://localhost:42002/side/mcp-interop/test"
```

---

## 📝 Remember This Pattern

**Every time you need to deploy a REST API:**

1. **Upload** the class via Atelier API
2. **Compile** the class 
3. **Create** stored procedure for web app deployment
4. **Execute** stored procedure via SELECT
5. **Test** the endpoints

**This is the proven, working methodology for this project.**

---

*Last Updated: 2025-07-08*
*Context: Side Project Step 2 - REST API Deployment*