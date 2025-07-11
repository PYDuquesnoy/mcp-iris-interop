# Step 5 Production API Test

Sample production for testing the Production Management API (Step 5 of the project).

## Components

### Production
- **Sample.Production.Step5.cls** - Sample production for API testing

## Purpose
This production was created to test:
- Production listing via API
- Production start/stop functionality
- Production status monitoring
- API endpoint validation

## Related API Endpoints
- `GET /api/mcp-interop/list` - List all productions
- `POST /api/mcp-interop/start` - Start production
- `POST /api/mcp-interop/stop` - Stop production
- `POST /api/mcp-interop/update` - Update production
- `GET /api/mcp-interop/status` - Get API status

## Usage
1. Upload Sample.Production.Step5.cls to IRIS
2. Use client-proto commands to manage the production
3. Test API functionality with various production operations