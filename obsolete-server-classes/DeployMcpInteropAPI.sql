-- MCP-IRIS-INTEROP REST API Deployment Script
-- This script deploys the Api.Mcp.Interop REST API to IRIS
-- 
-- Usage:
-- 1. Connect to IRIS SQL interface
-- 2. Switch to IRISAPP namespace: USE IRISAPP
-- 3. Execute this script
--
-- Security: User/password authentication (value 32)
-- URL: /api/mcp-interop/*

-- Create the deployment procedure
CREATE OR REPLACE PROCEDURE DeployMcpInteropAPI()
LANGUAGE OBJECTSCRIPT
{
    TRY {
        WRITE "=== MCP-IRIS-INTEROP REST API Deployment ===", !
        
        // Define the REST application configuration
        SET restApp = ##class(%REST.Application).%New()
        SET restApp.Name = "Api.Mcp.Interop"
        SET restApp.DispatchClass = "Api.Mcp.Interop"
        SET restApp.LegacyRouting = 0
        SET restApp.UnauthenticatedEnabled = 0
        SET restApp.CORSOrigins = "*"
        
        // Define the web application configuration
        SET webApp = ##class(%CSP.Application).%New()
        SET webApp.Name = "/api/mcp-interop"
        SET webApp.Description = "MCP-IRIS-Interop REST API"
        SET webApp.Namespace = "IRISAPP"
        SET webApp.CSPZENEnabled = 1
        SET webApp.AutheEnabled = 32  // User/password authentication
        SET webApp.UnauthenticatedEnabled = 0
        SET webApp.CORSOrigins = "*"
        SET webApp.InboundWebServicesEnabled = 1
        SET webApp.Path = ##class(%File).NormalizeDirectory($SYSTEM.Util.InstallDirectory() _ "CSP/mcp-interop/")
        
        // Deploy the application
        WRITE "Deploying REST application...", !
        SET status = ##class(%SYS.REST).DeployApplication(restApp, webApp)
        
        IF $$$ISOK(status) {
            WRITE "✅ REST API deployed successfully!", !
            WRITE "URL: http://localhost:42002/api/mcp-interop/", !
            WRITE "Authentication: User/password required", !
            WRITE "Available endpoints:", !
            WRITE "  - GET  /api/mcp-interop/health", !
            WRITE "  - GET  /api/mcp-interop/productions", !
            WRITE "  - POST /api/mcp-interop/productions/{name}/start", !
            WRITE "  - POST /api/mcp-interop/productions/current/stop", !
            WRITE "  - POST /api/mcp-interop/productions/current/update", !
            WRITE "  - POST /api/mcp-interop/productions/current/clean", !
            WRITE "  - GET  /api/mcp-interop/productions/current/status", !
            WRITE "  - POST /api/mcp-interop/test/bp/{target}", !
            WRITE "  - POST /api/mcp-interop/test/bo/{target}", !
            WRITE "  - POST /api/mcp-interop/test/service/{target}", !
            WRITE "  - GET  /api/mcp-interop/messages/export", !
            WRITE "  - GET  /api/mcp-interop/messages/export/{sessionId}", !
            WRITE "  - GET  /api/mcp-interop/events/export", !
            WRITE "  - GET  /api/mcp-interop/events/export/{sessionId}", !
            WRITE "  - POST /api/mcp-interop/execute/{method}", !
        } ELSE {
            WRITE "❌ Deployment failed: ", $SYSTEM.Status.GetErrorText(status), !
        }
        
    } CATCH ex {
        WRITE "❌ Error during deployment: ", ex.DisplayString(), !
    }
}

-- Create a simple verification procedure
CREATE OR REPLACE PROCEDURE VerifyMcpInteropAPI()
LANGUAGE OBJECTSCRIPT
{
    TRY {
        WRITE "=== MCP-IRIS-INTEROP REST API Verification ===", !
        
        // Check if the web application exists
        SET webapp = ##class(%SYS.REST).GetRESTApplication("/api/mcp-interop")
        IF $ISOBJECT(webapp) {
            WRITE "✅ Web application '/api/mcp-interop' exists", !
            WRITE "   Namespace: ", webapp.Namespace, !
            WRITE "   Authentication: ", webapp.AutheEnabled, !
        } ELSE {
            WRITE "❌ Web application '/api/mcp-interop' not found", !
        }
        
        // Check if the dispatch class exists
        IF ##class(%Dictionary.ClassDefinition).%ExistsId("Api.Mcp.Interop") {
            WRITE "✅ Dispatch class 'Api.Mcp.Interop' exists", !
        } ELSE {
            WRITE "❌ Dispatch class 'Api.Mcp.Interop' not found", !
        }
        
        // List all REST applications for reference
        WRITE !, "Current REST applications:", !
        SET apps = ##class(%SYS.REST).GetRESTApplications()
        SET key = ""
        FOR {
            SET key = apps.Next(key)
            QUIT:key=""
            SET app = apps.GetAt(key)
            WRITE "  - ", key, " -> ", app.Name, !
        }
        
    } CATCH ex {
        WRITE "❌ Error during verification: ", ex.DisplayString(), !
    }
}

-- Instructions for manual execution
/*
=== MANUAL DEPLOYMENT INSTRUCTIONS ===

1. Connect to IRIS Management Portal:
   http://localhost:42002/csp/sys/UtilHome.csp
   Username: _SYSTEM
   Password: SYS

2. Navigate to System Explorer > SQL
   
3. Change namespace to IRISAPP:
   USE IRISAPP
   
4. Upload and compile the Api.Mcp.Interop class first:
   (Use the Atelier API or Studio to upload the .cls file)
   
5. Execute deployment:
   CALL DeployMcpInteropAPI()
   
6. Verify deployment:
   CALL VerifyMcpInteropAPI()
   
7. Test the API:
   curl -u "_SYSTEM:SYS" http://localhost:42002/api/mcp-interop/health

=== ALTERNATIVE: Using SQL Interface ===

If the procedures don't work, you can execute the ObjectScript directly:

DO ##class(%SYS.REST).DeployApplication(restApp, webApp)

Where restApp and webApp are configured as shown in the procedure above.
*/