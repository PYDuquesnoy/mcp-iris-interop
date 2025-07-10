# Development Guidelines for MCP-IRIS-INTEROP Project

## 🔧 IRIS Server Interaction Requirements

**⭐ MANDATORY**: Always use `client-proto/` for IRIS server interactions:
- Client-proto is the standardized, tested method for all IRIS operations
- Never use curl, direct REST calls, or other methods when client-proto commands are available
- Client-proto handles authentication, error handling, and response formatting consistently
- Update client-proto with new functionality before implementing new API endpoints

### Available Client-Proto Commands

```bash
cd client-proto && npm run build

# Basic connectivity and server info
node dist/index.js test              # Test connectivity
node dist/index.js server-info       # Get server information  
node dist/index.js namespaces        # List namespaces
node dist/index.js docs [namespace]  # List documents

# Class management (Step 4)
node dist/index.js classes           # List classes in namespace
node dist/index.js packages          # List packages in namespace
node dist/index.js upload <class> <file>     # Upload class to IRIS
node dist/index.js download <class>  # Download class from IRIS
node dist/index.js compile <class>   # Compile class in IRIS
node dist/index.js upload-compile <class> <file>  # Upload and compile

# Production management (Step 5)
node dist/index.js prod-check        # Check production API availability
node dist/index.js prod-status       # Get production API status
node dist/index.js prod-list         # List all productions
node dist/index.js prod-test         # Test production API
```

## 📚 Legacy Directory Consultation (CRITICAL)

**⭐ BEFORE implementing any new API functionality, you MUST**:

### 1. Search `legacy/ensLib/` (1,276 classes)
- **Ens.Director.*** - Production management and control
- **EnsLib.Testing.*** - Testing service framework  
- **EnsLib.*** - Core interoperability functionality
- **EnsPortal.*** - Web portal and UI patterns

### 2. Review `legacy/cacheensdemo/` (203 classes)
- **Demo.*** - Complete working interoperability examples
- **EnsPortal.TestingService.cls** - Testing service UI implementation
- Production samples and configurations

### 3. Check `legacy/system/` (3,458 classes)
- System-level functionality and patterns

### 4. Understand existing patterns and APIs before writing new endpoints

## Example Workflows

### Step 6.2: Start Production
1. **First**: Examine `legacy/ensLib/Ens.Director.cls` for StartProduction() method
2. **Understand**: Parameters, return values, error handling
3. **Implement**: REST API wrapper following existing patterns
4. **Test**: Using client-proto commands

### Step 6.5: Testing Service
1. **First**: Study `legacy/ensLib/EnsLib.Testing.Service.cls` implementation
2. **Review**: `legacy/cacheensdemo/EnsPortal.TestingService.cls` for UI patterns
3. **Examine**: `legacy/ensLib/EnsLib.Testing.Request.cls` for message wrapping
4. **Implement**: Testing API endpoints based on proven patterns
5. **Test**: Using client-proto testing commands

### Step 6.6: Message/Event Logs
1. **Search**: `legacy/ensLib/` for Ens.MessageHeader, Ens.EventLog classes
2. **Study**: Export and query patterns
3. **Implement**: Log export functionality
4. **Test**: Using client-proto commands

## Key Benefits

This approach ensures:
- ✅ **No reinvention** of existing functionality
- ✅ **Proven patterns** from InterSystems best practices
- ✅ **Consistent APIs** following established conventions
- ✅ **Reliable implementation** based on tested code
- ✅ **Comprehensive understanding** of available functionality

## Repository Structure for Legacy Classes

```
legacy/
├── ensLib/           # Complete Ens/EnsLib/EnsPortal framework (1,276 classes, 14MB)
│   ├── Ens.Director.cls              # Production management
│   ├── EnsLib.Testing.Service.cls    # Testing service implementation
│   ├── EnsLib.Testing.Request.cls    # Testing message wrapper
│   └── ...
├── cacheensdemo/     # Working interoperability examples (203 classes)
│   ├── EnsPortal.TestingService.cls  # Testing service UI
│   ├── Demo.*.cls                    # Complete working examples
│   └── ...
└── system/           # System classes (3,458 classes)
    └── ...
```

These guidelines prevent reinventing existing functionality and ensure new APIs use proven InterSystems patterns.