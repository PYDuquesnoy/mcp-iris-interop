#!/bin/bash

echo "=== Simple Production Test ==="
echo

# 1. Check production status
echo "1. Current production status:"
curl -s -X GET --user "_SYSTEM:SYS" "http://localhost:42002/api/mcp-interop/list" | jq '.productions[] | select(.Name == "Demo.Production")'
echo

# 2. Update the production
echo "2. Updating production..."
curl -s -X POST --user "_SYSTEM:SYS" -H "Content-Type: application/json" -d '{"timeout":10,"force":0}' "http://localhost:42002/api/mcp-interop/update" | jq .
echo

# 3. Test with execute
echo "3. Testing with execute command..."
curl -s -X POST --user "_SYSTEM:SYS" -H "Content-Type: application/json" -d '{"code":"Set req = ##class(Ens.StringRequest).%New() Set req.StringValue = \"Test from execute\" Set sc = ##class(Ens.Director).CreateBusinessService(\"EnsLib.Testing.Service\",.service) Set sc = service.ProcessInput(req,.resp,\"Demo.FileOperation\") Write \"Success\""}' "http://localhost:42002/api/mcp-interop/execute" | jq .
echo

# 4. Stop the production  
echo "4. Stopping production..."
curl -s -X POST --user "_SYSTEM:SYS" -H "Content-Type: application/json" -d '{"timeout":10,"force":1}' "http://localhost:42002/api/mcp-interop/stop" | jq .
echo

# 5. Check final status
echo "5. Final production status:"
curl -s -X GET --user "_SYSTEM:SYS" "http://localhost:42002/api/mcp-interop/list" | jq '.productions[] | select(.Name == "Demo.Production")'
echo

echo "Test complete!"