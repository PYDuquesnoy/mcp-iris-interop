# MCP-IRIS-INTEROP Project

Sucking all the juice out of Claude Code with InterSystems IRIS

## Description

This is a multi-step project where we maximize the benefits of using Claude Code with InterSystems IRIS for developing integrations in an Interoperability Production.

## Project Status

- ✅ **Step 1**: GitHub repository created
- ✅ **Step 2**: InterSystems IRIS development environment setup complete
- ✅ **Step 3**: VSCode plugin analysis and TypeScript prototype complete
- ✅ **Step 4**: Extended prototype with class management functionality
- ✅ **Side Project Step 1**: ObjectScript execution via SQL stored procedures
- ✅ **Side Project Step 2**: REST API deployment via stored procedures
- ⏳ **Step 5**: REST API for interoperability
- ⏳ **Step 6**: Production management functions
- ⏳ **Step 7**: MCP server implementation
- ⏳ **Step 8**: Skipped (manual step)
- ⏳ **Step 9**: Source code analysis
- ⏳ **Step 10**: ICUMED circuit implementation

## Getting Started

This project uses InterSystems IRIS with Docker containers for development. Follow the steps below to get started:

### Prerequisites

- Docker Desktop
- Node.js and npm
- Git
- GitHub CLI (gh)
- VSCode with InterSystems ObjectScript Extension Pack

### Initial Setup

1. Clone this repository
2. Follow the setup instructions for each step as documented

## Repository Structure

```
mcp-iris-interop/
├── README.MD              # This file
├── CLAUDE.md              # Project instructions
├── WorkLog.MD             # Development log
├── Dev-Status.MD          # Step completion status
├── client-proto/          # TypeScript prototype (Step 3-4)
├── curl-test/             # IRIS API validation scripts (Step 3-4)
├── exec-proto/            # ObjectScript execution prototype (Side Project Step 1)
├── iris-samples/          # Sample IRIS classes for upload/download testing
│   ├── upload/           # Classes ready for upload to IRIS
│   └── download/         # Downloaded classes from IRIS
├── legacy/                # Downloaded sample classes from IRIS
├── intersystems-iris-dev-template/  # Docker development environment (Step 2)
└── vscode-objectscript/   # VSCode plugin source code
├── obsolete-server-classes/  # Non-functional classes from incomplete steps
└── InterSystems-VSCode-API-Inventory.md  # API documentation
```

### Side Project: exec-proto

The `exec-proto/` directory contains a separate prototype that demonstrates executing ObjectScript code via SQL stored procedures:

- **Purpose**: Bootstrap system for remote ObjectScript execution
- **Key Features**:
  - Creates stored procedures dynamically via SQL DDL
  - Executes arbitrary ObjectScript code via CALL statements
  - Provides foundation for REST API installation
- **Key Files**:
  - `Bootstrap.Simple.cls` - Simple bootstrap class with SqlProc methods
  - `server-classes/Side.Mcp.Deploy.cls` - REST API deployment class
  - `step1-demo.sh` - Working demonstration script
  - `test-stored-procedure.sh` - Comprehensive test suite

## Current Status

**Step 1 Complete**: GitHub repository `mcp-iris-interop` has been successfully created and initialized.

**Step 2 Complete**: InterSystems IRIS development environment is now running with Docker containers using fixed ports in the 42000 range.

**Step 3 Complete**: VSCode plugin analyzed, comprehensive API documentation created, TypeScript prototype built and tested, and complete curl test suite implemented for API validation.

### Step 3 Deliverables

1. **API Documentation**: `InterSystems-VSCode-API-Inventory.md` - Complete analysis of 70+ REST API endpoints
2. **TypeScript Prototype**: `client-proto/` - Full IRIS Atelier API client with CLI interface  
3. **API Test Suite**: `curl-test/` - 7 comprehensive test scripts validating all major endpoints
4. **Connectivity Validation**: All APIs tested against running IRIS Docker instance

### Connectivity Test Instructions

To validate the IRIS environment is working correctly:

1. **System Management Portal**: http://localhost:42002/csp/sys/UtilHome.csp
   - Default username: `_SYSTEM`
   - Default password: `SYS`

2. **Interoperability Portal**: http://localhost:42002/csp/irisapp/EnsPortal.ProductionConfig.zen
   - Access the IRISAPP namespace interoperability features

3. **Command Line Test**:
   ```bash
   # Test system management portal
   curl -s -o /dev/null -w "%{http_code}" http://localhost:42002/csp/sys/UtilHome.csp
   # Should return: 200
   
   # Test interoperability portal
   curl -s -o /dev/null -w "%{http_code}" http://localhost:42002/csp/irisapp/EnsPortal.ProductionConfig.zen
   # Should return: 200
   ```

4. **Port Mapping**:
   - Port 42001: IRIS SuperServer (1972)
   - Port 42002: IRIS Web Server (52773)
   - Port 42003: IRIS Mirror Server (53773)

### API Test Suite Usage

The curl test suite provides comprehensive validation of all IRIS Atelier API endpoints:

```bash
# Run individual tests
cd curl-test
./01-test-connection.sh
./02-server-info.sh
# ... etc

# Run complete test suite
./run-all-tests.sh
```

**Environment Variables**:
- `IRIS_HOST` (default: localhost)
- `IRIS_PORT` (default: 42002)  
- `IRIS_USER` (default: _SYSTEM)
- `IRIS_PASS` (default: SYS)
- `IRIS_NS` (default: IRISAPP)

### TypeScript Prototype Usage

The prototype provides a command-line interface to IRIS:

```bash
cd client-proto
npm install
npm run build

# Available commands
npm start test              # Test connectivity
npm start server-info       # Get server information  
npm start namespaces        # List namespaces
npm start docs [namespace]  # List documents
```

### Sample Classes (iris-samples/)

The `iris-samples/` directory contains ObjectScript classes for testing upload/download functionality:

- **`upload/`**: Sample classes ready for upload to IRIS
  - `Test.Sample.cls` - Basic ObjectScript class with properties and methods
  - `Test.REST.cls` - REST API class extending %CSP.REST  
  - `Test.Utility.cls` - Utility class with static methods

- **`download/`**: Downloaded classes from IRIS for verification

These samples are used by the TypeScript prototype and can be referenced by curl-test scripts for consistent testing.

Next: Extending prototype with class management functionality (Step 4).