-- MCP-IRIS-INTEROP REST API Deployment Stored Procedure
-- Creates and deploys the REST API web application

CREATE OR REPLACE PROCEDURE DeployMcpInteropAPI()
RETURNS VARCHAR(1000)
LANGUAGE OBJECTSCRIPT
AS
BEGIN
    DECLARE result VARCHAR(1000) DEFAULT '';
    
    TRY {
        -- Check if the dispatch class exists
        IF ('##class(%Dictionary.ClassDefinition).%ExistsId("Api.Mcp.Interop")) {
            
            -- Create web application using %SYS.REST.DeployApplication
            SET status = ##class(%SYS.REST).DeployApplication(
                "Api.Mcp.Interop",           -- REST Application Name
                "/api/mcp-interop",          -- Web Application Path
                32                           -- Authentication Type (User/Password)
            )
            
            IF ($$$ISOK(status)) {
                SET result = 'SUCCESS: REST API deployed at /api/mcp-interop'
            } ELSE {
                SET result = 'ERROR: ' _ $SYSTEM.Status.GetErrorText(status)
            }
            
        } ELSE {
            SET result = 'ERROR: Api.Mcp.Interop class not found. Upload and compile it first.'
        }
        
    } CATCH ex {
        SET result = 'ERROR: ' _ ex.DisplayString()
    }
    
    RETURN result
END

-- Alternative simple deployment procedure
CREATE OR REPLACE PROCEDURE SimpleDeploy()
RETURNS VARCHAR(500)  
LANGUAGE OBJECTSCRIPT
AS
BEGIN
    DECLARE result VARCHAR(500) DEFAULT '';
    
    TRY {
        SET status = $SYSTEM.CSP.CreateApplication("/api/mcp-interop", "", "Api.Mcp.Interop", "", "", 32, "", "", "", "", "IRISAPP")
        
        IF (status = 1) {
            SET result = 'SUCCESS: Web application created'
        } ELSE {
            SET result = 'ERROR: Failed to create web application'
        }
        
    } CATCH ex {
        SET result = 'ERROR: ' _ ex.DisplayString()
    }
    
    RETURN result
END