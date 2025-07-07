# InterSystems VSCode Plugin - REST API Inventory

**Date**: 2025-07-07  
**Source**: intersystems-community/vscode-objectscript plugin analysis  
**Purpose**: Comprehensive inventory of REST API calls for building IRIS client prototype

## Overview

The InterSystems VSCode plugin uses the **Atelier API** to communicate with IRIS servers. All API calls are made through HTTP/HTTPS requests to the `/api/atelier/` endpoint with version-specific paths.

## Base API Structure

### URL Pattern
```
{protocol}://{host}:{port}{pathPrefix}/api/atelier/v{apiVersion}/{endpoint}
```

### Authentication
- **Method**: Basic Auth (username:password) or session cookies
- **Header**: `Authorization: Basic {base64(username:password)}`
- **Session Management**: Automatic cookie handling for persistent sessions

### Common Headers
- `Accept: application/json`
- `Content-Type: application/json` (for POST/PUT)
- `Cache-Control: no-cache`
- `Cookie: {session-cookies}` (after authentication)

## Core API Endpoints

### 1. Server Information & Connection

#### GET `/` - Server Info
- **Purpose**: Get server information and available namespaces
- **API Version**: v0+ (no version prefix)
- **Method**: GET
- **Parameters**: None
- **Response**: 
  ```json
  {
    "result": {
      "content": {
        "version": "IRIS for UNIX (Ubuntu Server LTS for x86-64) 2021.1.0.215.0",
        "id": "IRIS",
        "api": 7,
        "features": [...],
        "namespaces": ["USER", "IRISAPP", "%SYS", ...]
      }
    }
  }
  ```

#### HEAD `/` - Authentication Check
- **Purpose**: Verify authentication and get session cookies
- **Method**: HEAD
- **Response**: Session cookies in headers

### 2. Namespace Operations

#### GET `/{namespace}` - Get Namespace Info
- **Purpose**: Get information about a specific namespace
- **API Version**: v1+
- **Path**: `v1/{namespace}`
- **Method**: GET
- **Example**: `v1/IRISAPP`

#### GET `/{namespace}/docnames/{category}/{type}` - List Documents
- **Purpose**: Get list of documents (classes, routines, etc.) in namespace
- **API Version**: v1+
- **Method**: GET
- **Parameters**:
  - `category`: "*" (all) or specific category
  - `type`: "*" (all), "CLS" (classes), "RTN" (routines), "CSP", "OTH"
  - `filter`: Optional name filter pattern
  - `generated`: Boolean (include generated items)
- **Example**: `v1/IRISAPP/docnames/*/CLS?filter=dc.sample*&generated=0`

### 3. Document Management

#### GET `/{namespace}/doc/{docname}` - Get Document Content
- **Purpose**: Retrieve source code of a class, routine, or other document
- **API Version**: v1+
- **Method**: GET
- **Headers**: 
  - `IF-NONE-MATCH: {timestamp}` (for caching)
- **Parameters**:
  - `format`: "udl-multiline" (for formatted class definitions)
- **Example**: `v1/IRISAPP/doc/dc.sample.ObjectScript.cls`

#### HEAD `/{namespace}/doc/{docname}` - Check Document
- **Purpose**: Check if document exists and get ETag
- **Method**: HEAD
- **Response**: ETag header with timestamp

#### PUT `/{namespace}/doc/{docname}` - Save Document
- **Purpose**: Save/update document content
- **API Version**: v1+
- **Method**: PUT
- **Headers**:
  - `IF-NONE-MATCH: {timestamp}` (conflict detection)
- **Body**:
  ```json
  {
    "enc": false,
    "content": ["line1", "line2", ...],
    "mtime": 1625123456789
  }
  ```
- **Parameters**:
  - `ignoreConflict`: Boolean

#### DELETE `/{namespace}/doc/{docname}` - Delete Document
- **Purpose**: Delete a single document
- **API Version**: v1+
- **Method**: DELETE

#### DELETE `/{namespace}/docs` - Delete Multiple Documents
- **Purpose**: Delete multiple documents
- **API Version**: v1+
- **Method**: DELETE
- **Body**: Array of document names

### 4. Compilation

#### POST `/{namespace}/action/compile` - Compile Documents
- **Purpose**: Compile classes, routines, or other documents
- **API Version**: v1+
- **Method**: POST
- **Body**: Array of document names
- **Parameters**:
  - `flags`: Compilation flags (e.g., "cuk" for compile, update, keep source)
  - `source`: Boolean (include source in compilation)
- **Example**: 
  ```json
  ["dc.sample.ObjectScript.cls", "dc.sample.PersistentClass.cls"]
  ```

#### POST `/{namespace}/work` - Async Compile Queue
- **Purpose**: Queue asynchronous compilation job
- **API Version**: v1+
- **Method**: POST
- **Body**:
  ```json
  {
    "request": "compile",
    "documents": ["doc1.cls", "doc2.cls"],
    "flags": "cuk",
    "source": false
  }
  ```
- **Response**: Location header with job ID

#### GET `/{namespace}/work/{jobId}` - Poll Async Job
- **Purpose**: Check status of asynchronous job
- **Method**: GET
- **Response**: Job result or Retry-After header

#### DELETE `/{namespace}/work/{jobId}` - Cancel Async Job
- **Purpose**: Cancel running asynchronous job
- **Method**: DELETE

### 5. Search Operations

#### GET `/{namespace}/action/search` - Search Content
- **Purpose**: Search within document content
- **API Version**: v2+
- **Method**: GET
- **Parameters**:
  - `query`: Search query string
  - `files`: File pattern (e.g., "*.cls,*.mac")
  - `sys`: Include system files (boolean)
  - `gen`: Include generated files (boolean)
  - `max`: Maximum results
  - `regex`: Use regex (boolean)
  - `case`: Case sensitive (boolean)
  - `wild`: Use wildcards (boolean)
  - `word`: Whole word match (boolean)

#### POST `/{namespace}/action/index` - Index Documents
- **Purpose**: Index documents for search
- **API Version**: v1+
- **Method**: POST
- **Body**: Array of document names

### 6. Query Operations

#### POST `/{namespace}/action/query` - Execute SQL Query
- **Purpose**: Execute SQL queries against IRIS
- **API Version**: v1+
- **Method**: POST
- **Body**:
  ```json
  {
    "query": "SELECT * FROM dc_sample.PersistentClass",
    "parameters": []
  }
  ```

### 7. System Operations

#### GET `/%SYS/jobs` - Get System Jobs
- **Purpose**: List running IRIS jobs
- **API Version**: v1+
- **Method**: GET
- **Parameters**:
  - `system`: Include system jobs (boolean)

#### GET `/%SYS/cspapps/{namespace}` - Get CSP Applications
- **Purpose**: List CSP applications for namespace
- **API Version**: v1+
- **Method**: GET
- **Parameters**:
  - `detail`: Include detailed info (boolean)

#### GET `/%SYS/cspdebugid` - Get CSP Debug ID
- **Purpose**: Get debug session ID for CSP debugging
- **API Version**: v2+
- **Method**: GET

### 8. Interoperability Operations

#### GET `/{namespace}/ens/classes/{type}` - Get Ensemble Classes
- **Purpose**: Get list of interoperability classes by type
- **API Version**: v1+
- **Method**: GET
- **Parameters**:
  - `type`: Numeric type identifier for class category

### 9. Macro Operations

#### POST `/{namespace}/action/getmacrodefinition` - Get Macro Definition
- **Purpose**: Get macro definition for intellisense
- **API Version**: v2+
- **Method**: POST
- **Body**:
  ```json
  {
    "docname": "className.cls",
    "macroname": "MACRONAME",
    "includes": ["include1.inc", "include2.inc"]
  }
  ```

#### POST `/{namespace}/action/getmacrolocation` - Get Macro Location
- **Purpose**: Get source location of macro definition
- **API Version**: v2+
- **Method**: POST

#### POST `/{namespace}/action/getmacrolist` - Get Macro List
- **Purpose**: Get list of available macros
- **API Version**: v2+
- **Method**: POST

### 10. XML Operations

#### POST `/{namespace}/cvt/xml/doc` - Convert XML to UDL
- **Purpose**: Convert XML export format to UDL format
- **API Version**: v1+
- **Method**: POST
- **Headers**: `Content-Type: application/xml`
- **Body**: XML content as string

#### POST `/{namespace}/action/xml/export` - XML Export
- **Purpose**: Export documents in XML format
- **API Version**: v7+
- **Method**: POST
- **Body**: Array of document names

#### POST `/{namespace}/action/xml/load` - XML Load
- **Purpose**: Load documents from XML content
- **API Version**: v7+
- **Method**: POST
- **Body**:
  ```json
  [
    {
      "file": "filename.xml",
      "content": ["xml-line1", "xml-line2", ...],
      "selected": ["doc1.cls", "doc2.cls"]
    }
  ]
  ```

#### POST `/{namespace}/action/xml/list` - XML List
- **Purpose**: List documents in XML content
- **API Version**: v7+
- **Method**: POST

## WebSocket Endpoints

### Debug WebSocket
- **URL**: `{ws/wss}://{host}:{port}{pathPrefix}/api/atelier/v{apiVersion}/%25SYS/debug`
- **Purpose**: XDebug protocol debugging

### Terminal WebSocket
- **URL**: `{ws/wss}://{host}:{port}{pathPrefix}/api/atelier/v{apiVersion}/%25SYS/terminal`
- **Purpose**: Web terminal access (API v7+)

## Error Handling

### HTTP Status Codes
- **200**: Success
- **304**: Not Modified (with caching)
- **401**: Authentication required
- **404**: Document/namespace not found
- **500**: Server error
- **503**: Server unavailable (license issues)

### Error Response Format
```json
{
  "status": {
    "errors": ["Error message 1", "Error message 2"],
    "summary": "Overall error description"
  },
  "console": ["Console output lines"],
  "result": {
    "status": "Detailed error status"
  }
}
```

## Configuration Requirements

### Connection Parameters
- **serverName**: Name in intersystems.servers config
- **host**: IRIS server hostname/IP
- **port**: Web server port (usually 52773)
- **https**: Use HTTPS (boolean)
- **pathPrefix**: URL prefix (optional)
- **username**: IRIS username
- **password**: IRIS password
- **namespace**: Target namespace

### API Version Detection
- Server reports supported API version in server info response
- Client adapts requests based on server capabilities
- Minimum version requirements per endpoint documented above

## Usage Patterns for Client Prototype

### Basic Namespace Inventory
1. GET `/` - Get server info and namespace list
2. For each namespace: GET `/{namespace}` - Get namespace details

### Document Management Workflow
1. GET `/{namespace}/docnames/*/*` - List all documents
2. GET `/{namespace}/doc/{docname}` - Get document content
3. PUT `/{namespace}/doc/{docname}` - Save changes
4. POST `/{namespace}/action/compile` - Compile

### Authentication Flow
1. HEAD `/` - Initial auth check
2. Store returned cookies for subsequent requests
3. Handle 401 responses with re-authentication

This inventory provides the foundation for implementing the TypeScript prototype with comprehensive IRIS server interaction capabilities.