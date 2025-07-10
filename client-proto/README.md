# IRIS Client Prototype

A TypeScript prototype for connecting to InterSystems IRIS using the Atelier API.

## Features

- ✅ Connection management with authentication
- ✅ Server information retrieval
- ✅ Namespace inventory and operations
- ✅ Document listing and content retrieval
- ✅ SQL query execution
- ✅ Document compilation
- ✅ Command-line interface with verbose mode
- ✅ Comprehensive test suite

## Installation

```bash
cd client-proto
npm install
```

## Configuration

Edit `config.json` to match your IRIS server settings:

```json
{
  "server": "localhost",
  "port": 42002,
  "pathPrefix": "",
  "username": "_SYSTEM",
  "password": "SYS",
  "https": false,
  "namespace": "IRISAPP"
}
```

### Configuration Parameters

- **server**: IRIS server hostname or IP address
- **port**: Web server port (usually 52773, or 42002 for our Docker setup)
- **pathPrefix**: Optional URL prefix (usually empty)
- **username**: IRIS username
- **password**: IRIS password
- **https**: Use HTTPS connection (boolean)
- **namespace**: Default namespace to use

## Usage

### Build the project

```bash
npm run build
```

### Command Line Interface

#### Test Connection
```bash
npm run start test
npm run start test --verbose
```

#### Get Server Information
```bash
npm run start server-info
npm run start server-info --verbose
```

#### List All Namespaces
```bash
npm run start namespaces
npm run start namespaces --verbose
```

#### Get Namespace Information
```bash
npm run start namespace-info
npm run start namespace-info --namespace USER
```

#### List Documents
```bash
# List all documents
npm run start docs

# List only classes
npm run start docs --type CLS

# List with name filter
npm run start docs --type CLS --filter "dc.sample*"

# Include generated documents
npm run start docs --generated

# Verbose mode
npm run start docs --verbose
```

### Development Mode

```bash
# Run with ts-node (no build required)
npm run dev test
npm run dev namespaces --verbose
```

### Test Suite

Run the comprehensive test suite:

```bash
npm run test
```

The test suite includes:
1. Connection and authentication test
2. Server information retrieval
3. Namespace inventory
4. Namespace information
5. Document listing
6. Document content retrieval
7. SQL query execution

## Sample Classes

Sample ObjectScript classes for testing are available in `../iris-samples/`:
- `upload/Test.Sample.cls` - Basic ObjectScript class
- `upload/Test.REST.cls` - REST API class
- `upload/Test.Utility.cls` - Utility class

These can be used with the upload/download functionality.

## API Methods

### IrisClient Class

#### Connection Management
- `connect()`: Test connection and authenticate
- `isAuthenticated()`: Check authentication status
- `getConnectionInfo()`: Get connection info string

#### Server Operations
- `getServerInfo()`: Get server information and capabilities
- `getNamespaces()`: Get list of all available namespaces

#### Namespace Operations
- `getNamespaceInfo(namespace?)`: Get information about a namespace
- `getDocumentList(namespace?, category?, type?, filter?, includeGenerated?)`: List documents

#### Document Operations
- `getDocument(documentName, namespace?)`: Get document content
- `compileDocuments(documents[], namespace?, flags?)`: Compile documents

#### Query Operations
- `executeQuery(query, parameters[], namespace?)`: Execute SQL query

## Examples

### Basic Usage

```typescript
import { IrisClient } from './iris-client';
import { ConnectionConfig } from './types';

const config: ConnectionConfig = {
  server: 'localhost',
  port: 42002,
  username: '_SYSTEM',
  password: 'SYS',
  namespace: 'IRISAPP'
};

const client = new IrisClient(config);

// Test connection
const connected = await client.connect();
if (connected) {
  console.log('Connected successfully!');
  
  // Get namespaces
  const namespaces = await client.getNamespaces();
  console.log('Available namespaces:', namespaces);
  
  // List classes in IRISAPP namespace
  const docs = await client.getDocumentList('IRISAPP', '*', 'CLS');
  console.log('Classes found:', docs.result.content.length);
}
```

### Error Handling

The client includes comprehensive error handling for:
- Connection failures (ECONNREFUSED, ENOTFOUND)
- Authentication errors (401)
- Server unavailable (503)
- API errors with detailed messages

## API Endpoints Used

This prototype implements the following Atelier API endpoints:

- `GET /` - Server information
- `HEAD /` - Authentication
- `GET /v1/{namespace}` - Namespace information
- `GET /v1/{namespace}/docnames/{category}/{type}` - Document listing
- `GET /v1/{namespace}/doc/{name}` - Document content
- `POST /v1/{namespace}/action/compile` - Document compilation
- `POST /v1/{namespace}/action/query` - SQL queries

## Verbose Mode

Use the `--verbose` flag with any command to see:
- Detailed configuration information
- Full URL paths being accessed
- Complete server responses
- Additional debugging information

Example:
```bash
npm run start namespaces --verbose
```

## Testing

The prototype can be tested against the Docker IRIS instance from Step 2:

1. Ensure the IRIS Docker container is running
2. Verify connectivity: `curl http://localhost:42002/csp/sys/UtilHome.csp`
3. Run the test suite: `npm run test`

## Bootstrap Command

The bootstrap command automatically deploys the production management API:

```bash
# First-time setup - upload and deploy the API
npm start bootstrap-api
```

This command will:
1. Upload `Api.MCPInterop.cls` to IRIS
2. Upload `Api.MCPInterop.Deploy.cls` to IRIS
3. Create deployment stored procedure
4. Execute deployment to create `/api/mcp-interop` web application
5. Test the deployed API

After bootstrapping, all production management and execute commands will be available.

## Execute Command (Step 6.1)

The execute command allows remote ObjectScript code execution:

```bash
# Simple variable assignment
npm start execute 'Set x = 10 + 20'

# Using IRIS system variables (note single quotes to prevent shell expansion)
npm start execute 'Set ^MyGlobal = $HOROLOG'
npm start execute 'Set timestamp = $ZDATETIME($H, 3)'

# Multiple statements
npm start execute 'Set a = 5 Set b = 10 Set result = a * b'
```

### Important: Shell Quoting

When using IRIS system variables like `$H`, `$HOROLOG`, etc., use **single quotes** to prevent shell variable expansion:

❌ **Wrong**: `npm start execute "Set ^Test = $H"`  (shell will try to expand $H)
✅ **Correct**: `npm start execute 'Set ^Test = $H'` (passed literally to IRIS)

Alternative: Escape the dollar sign with double quotes:
✅ `npm start execute "Set ^Test = \$H"`

## Next Steps

This prototype provides the foundation for:
- Step 4: Extended class management operations
- Step 5: Interoperability REST API development
- Step 6: Production management functions
- Step 7: MCP server implementation

The client can be easily extended with additional Atelier API endpoints as needed.