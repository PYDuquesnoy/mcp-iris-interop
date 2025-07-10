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
├── README.MD              # This file - main project documentation
├── CLAUDE.md              # Project instructions and step definitions
├── WorkLog.MD             # Development log and progress tracking
├── Dev-Status.MD          # Step completion status and details
├── client-proto/          # TypeScript prototype (Steps 3-4)
│   ├── README.md          # Client prototype documentation
│   └── IRIS-Interoperability-API-Analysis.md  # Interoperability API analysis
├── curl-test/             # IRIS API validation scripts (Steps 3-4)
│   ├── README.md          # cURL test suite documentation
│   └── TEST-RESULTS.md    # Test execution results
├── exec-proto/            # ObjectScript execution prototype (Side Project)
│   ├── README.md          # Execution prototype documentation
│   └── DEPLOYMENT-NOTES.md # Critical deployment patterns and procedures
├── iris-samples/          # Sample IRIS classes for testing
│   └── README.md          # Sample classes documentation
├── legacy/                # Downloaded sample classes from IRIS
│   ├── README.md          # Legacy classes overview
│   ├── cacheensdemo/      # ENSDEMO namespace classes (203 interoperability samples)
│   │   └── README.md      # ENSDEMO classes documentation
│   ├── ensLib/            # Ens/EnsLib/EnsPortal classes from IRISAPP (1,276 classes, 14MB)
│   └── system/            # % system classes from SAMPLES namespace (3,458 classes)
├── intersystems-iris-dev-template/  # Docker development environment (Step 2)
│   ├── README.md          # Docker environment setup
│   └── dev.md             # Development instructions
├── vscode-objectscript/   # VSCode plugin source code (Step 3)
│   ├── README.md          # VSCode plugin documentation
│   └── CHANGELOG.md       # Plugin change history
└── Documentation Files:
    ├── InterSystems-VSCode-API-Inventory.md  # Complete API analysis (70+ endpoints)
    ├── Claude-SideProject.md                 # Side project specifications
    ├── Exec-Proto-Bootstrap-Success.md       # Bootstrap implementation success
    ├── Side-Project-Step2-Complete.md        # REST API deployment completion
    ├── Side-Project-Step2-Plan.md           # REST API deployment plan
    ├── SQL-StoredProcedure-Analysis.md      # SQL stored procedure analysis
    └── StoredProcedure-Examples.md          # Stored procedure examples
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

### TypeScript Prototype Usage (Preferred Method)

**⭐ IMPORTANT**: The `client-proto/` TypeScript client is the **preferred method** for interacting with the IRIS server. Always use client-proto instead of curl or other methods for IRIS API operations.

The prototype provides a comprehensive command-line interface to IRIS:

```bash
cd client-proto
npm install
npm run build

# Basic connectivity and server info
npm start test              # Test connectivity
npm start server-info       # Get server information  
npm start namespaces        # List namespaces
npm start docs [namespace]  # List documents

# Class management (Step 4)
npm start classes           # List classes in namespace
npm start packages          # List packages in namespace
npm start upload <class> <file>     # Upload class to IRIS
npm start download <class>  # Download class from IRIS
npm start compile <class>   # Compile class in IRIS
npm start upload-compile <class> <file>  # Upload and compile

# Production management (Step 5)
npm start prod-check        # Check production API availability
npm start prod-status       # Get production API status
npm start prod-list         # List all productions
npm start prod-test         # Test production API
```

**Configuration**: Edit `client-proto/config.json` to specify your IRIS connection details.

### Sample Classes (iris-samples/)

The `iris-samples/` directory contains ObjectScript classes for testing upload/download functionality:

- **`upload/`**: Sample classes ready for upload to IRIS
  - `Test.Sample.cls` - Basic ObjectScript class with properties and methods
  - `Test.REST.cls` - REST API class extending %CSP.REST  
  - `Test.Utility.cls` - Utility class with static methods

- **`download/`**: Downloaded classes from IRIS for verification

These samples are used by the TypeScript prototype and can be referenced by curl-test scripts for consistent testing.

## Documentation Index

### Project Management
- **[CLAUDE.md](CLAUDE.md)** - Complete project instructions and step definitions
- **[Dev-Status.MD](Dev-Status.MD)** - Detailed step completion status and progress tracking
- **[WorkLog.MD](WorkLog.MD)** - Development log with interaction history

### Technical Documentation
- **[InterSystems-VSCode-API-Inventory.md](InterSystems-VSCode-API-Inventory.md)** - Comprehensive analysis of 70+ IRIS Atelier REST API endpoints
- **[exec-proto/DEPLOYMENT-NOTES.md](exec-proto/DEPLOYMENT-NOTES.md)** - ⭐ **CRITICAL**: Deployment patterns for REST APIs via stored procedures
- **[SQL-StoredProcedure-Analysis.md](SQL-StoredProcedure-Analysis.md)** - Analysis of SQL stored procedure capabilities in IRIS
- **[StoredProcedure-Examples.md](StoredProcedure-Examples.md)** - Working examples of stored procedure implementations

### Side Project Documentation
- **[Claude-SideProject.md](Claude-SideProject.md)** - Side project specifications and requirements
- **[Exec-Proto-Bootstrap-Success.md](Exec-Proto-Bootstrap-Success.md)** - Bootstrap implementation success report
- **[Side-Project-Step2-Complete.md](Side-Project-Step2-Complete.md)** - REST API deployment completion report
- **[Side-Project-Step2-Plan.md](Side-Project-Step2-Plan.md)** - REST API deployment implementation plan

### Component Documentation
- **[client-proto/README.md](client-proto/README.md)** - TypeScript IRIS API client documentation
- **[client-proto/IRIS-Interoperability-API-Analysis.md](client-proto/IRIS-Interoperability-API-Analysis.md)** - Interoperability-specific API analysis
- **[curl-test/README.md](curl-test/README.md)** - cURL test suite documentation and usage
- **[curl-test/TEST-RESULTS.md](curl-test/TEST-RESULTS.md)** - Test execution results and validation
- **[exec-proto/README.md](exec-proto/README.md)** - ObjectScript execution prototype documentation
- **[iris-samples/README.md](iris-samples/README.md)** - Sample classes documentation and testing guide

### Sample Collections
- **[legacy/README.md](legacy/README.md)** - Overview of downloaded IRIS sample classes
- **[legacy/cacheensdemo/README.md](legacy/cacheensdemo/README.md)** - ENSDEMO interoperability samples (203 classes)
- **[legacy/ensLib/](legacy/ensLib/)** - Complete Ens/EnsLib/EnsPortal framework (1,276 classes) with Testing Service classes

### External Components
- **[intersystems-iris-dev-template/README.md](intersystems-iris-dev-template/README.md)** - Docker development environment setup
- **[vscode-objectscript/README.md](vscode-objectscript/README.md)** - VSCode plugin documentation

## Sample Collections Summary

This repository includes comprehensive sample class collections from InterSystems IRIS:

- **SAMPLES Namespace**: 406 non-% classes (3.0MB) + 3,458 % system classes (47MB)
- **ENSDEMO Namespace**: 203 non-% interoperability classes (1.2MB)
- **IRISAPP Namespace**: 1,276 Ens/EnsLib/EnsPortal classes (14MB) - **Complete Interoperability Framework**
- **Custom Samples**: Upload/download test classes in `iris-samples/`

These collections provide extensive examples for:
- InterSystems IRIS interoperability development
- Business Services, Processes, and Operations
- Data transformations and message routing
- Web services and REST API implementations
- Dashboard and UI components (CSPX.Dashboard.*)

## Development Guidelines

### 🔧 IRIS Server Interaction

**⭐ ALWAYS use `client-proto/` for IRIS server interactions**:
- Client-proto is the standardized, tested method for all IRIS operations
- Use client-proto commands instead of curl, direct REST calls, or other methods
- Client-proto handles authentication, error handling, and response formatting consistently

### 📚 Legacy Directory Consultation Requirement

**⭐ BEFORE implementing new API functionality**:
1. **Search `legacy/ensLib/`** (1,276 classes) for existing Ens.Director, EnsLib.*, and Ens.* implementations
2. **Review `legacy/cacheensdemo/`** (203 classes) for working interoperability examples  
3. **Check `legacy/system/`** (3,458 classes) for system-level functionality
4. **Understand existing patterns** before writing new API endpoints

**Example**: Before implementing production management, check:
- `legacy/ensLib/Ens.Director.cls` - Production management methods
- `legacy/ensLib/EnsLib.Testing.Service.cls` - Testing service implementation
- `legacy/cacheensdemo/EnsPortal.TestingService.cls` - Testing service UI patterns

This ensures new APIs use proven InterSystems patterns and avoid reinventing existing functionality.

## Key Achievements

✅ **Functional REST API Deployment**: Complete workflow from SQL queries to deployed REST APIs  
✅ **Comprehensive API Analysis**: 70+ IRIS Atelier API endpoints documented  
✅ **Working Prototypes**: TypeScript client and ObjectScript execution systems  
✅ **Extensive Test Coverage**: cURL and TypeScript test suites for validation  
✅ **Sample Code Library**: 4,000+ InterSystems IRIS classes for reference  
✅ **Critical Documentation**: Deployment patterns preserved for future use