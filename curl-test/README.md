# IRIS Atelier API - Curl Test Commands

This directory contains curl commands to test each function of the InterSystems IRIS Atelier API directly, demonstrating the same endpoints used by the TypeScript prototype.

## Prerequisites

1. IRIS Docker container running (from Step 2)
2. Management portal accessible at http://localhost:42002
3. Default credentials: _SYSTEM / SYS

## Environment Variables

Set these variables for easier testing:

```bash
export IRIS_HOST="localhost"
export IRIS_PORT="42002"
export IRIS_USER="_SYSTEM"
export IRIS_PASS="SYS"
export IRIS_NS="IRISAPP"
export IRIS_BASE_URL="http://${IRIS_HOST}:${IRIS_PORT}/api/atelier"
```

## Test Order

Run the scripts in this order:
1. `01-test-connection.sh` - Basic connectivity test
2. `02-server-info.sh` - Get server information
3. `03-namespaces.sh` - List and explore namespaces
4. `04-documents.sh` - Document operations
5. `05-compilation.sh` - Compile documents
6. `06-queries.sh` - SQL query execution
7. `07-advanced.sh` - Advanced operations

## Authentication

All requests use HTTP Basic Authentication. Session cookies will be managed automatically by curl using the `-c` and `-b` flags.

## Response Format

All responses are in JSON format following the Atelier API specification:

```json
{
  "status": {
    "errors": [],
    "summary": ""
  },
  "console": [],
  "result": {
    // API-specific response data
  }
}
```

## Error Handling

- HTTP 200: Success
- HTTP 401: Authentication required
- HTTP 404: Resource not found
- HTTP 500: Server error

Check both HTTP status code and the `status.summary` field in the JSON response for detailed error information.