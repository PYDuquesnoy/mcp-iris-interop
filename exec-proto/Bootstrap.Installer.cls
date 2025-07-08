/// Bootstrap class for installing REST API via SQL stored procedure
Class Bootstrap.Installer Extends %RegisteredObject
{

/// Execute arbitrary ObjectScript code via SQL
/// Returns 1 on success, 0 on failure
/// Example: SELECT Bootstrap.Installer_ExecuteCode('SET x=1 WRITE x')
ClassMethod ExecuteCode(code As %String, Output result As %String) As %Integer [ SqlName = ExecuteCode, SqlProc ]
{
    Try {
        // Capture output
        Set io = $IO
        Set result = ""
        
        // Redirect output to a string
        Use $$$NULLDEVICE
        Set output = ""
        
        // Execute the code
        Set @("sc") = 1
        XECUTE code
        
        // Restore IO
        Use io
        
        Set result = "Success"
        Quit 1
    } Catch ex {
        Use io
        Set result = "Error: " _ ex.DisplayString()
        Quit 0
    }
}

/// Install REST API application
/// Returns status message
ClassMethod InstallRestAPI(namespace As %String = "IRISAPP") As %String [ SqlName = InstallRestAPI, SqlProc ]
{
    Try {
        Set result = ""
        
        // Create the REST API class content
        Set className = "Side.MCPInterop"
        Set classContent = ..GetRestAPIClassContent()
        
        // Save the class definition
        Set classDef = ##class(%Dictionary.ClassDefinition).%New()
        Set classDef.Name = className
        Set classDef.Super = "%CSP.REST"
        Set classDef.CompileAfter = "%CSP.REST"
        
        // Add XData block for URL map
        Set xdata = ##class(%Dictionary.XDataDefinition).%New()
        Set xdata.Name = "UrlMap"
        Set xdata.parent = classDef
        Do xdata.Data.WriteLine("<Routes>")
        Do xdata.Data.WriteLine("<Route Url=""/list"" Method=""GET"" Call=""ListProductions"" />")
        Do xdata.Data.WriteLine("<Route Url=""/execute"" Method=""POST"" Call=""ExecuteMethod"" />")
        Do xdata.Data.WriteLine("<Route Url=""/start"" Method=""POST"" Call=""StartProduction"" />")
        Do xdata.Data.WriteLine("<Route Url=""/stop"" Method=""POST"" Call=""StopProduction"" />")
        Do xdata.Data.WriteLine("</Routes>")
        
        // Add methods
        Set method1 = ##class(%Dictionary.MethodDefinition).%New()
        Set method1.Name = "ListProductions"
        Set method1.ClassMethod = 1
        Set method1.parent = classDef
        Do method1.Implementation.WriteLine("    Set result = []")
        Do method1.Implementation.WriteLine("    Try {")
        Do method1.Implementation.WriteLine("        Set rs = ##class(Ens.Director).GetProductionSummary()")
        Do method1.Implementation.WriteLine("        While rs.%Next() {")
        Do method1.Implementation.WriteLine("            Set prod = {}")
        Do method1.Implementation.WriteLine("            Set prod.Name = rs.Name")
        Do method1.Implementation.WriteLine("            Set prod.Status = rs.Status")
        Do method1.Implementation.WriteLine("            Do result.%Push(prod)")
        Do method1.Implementation.WriteLine("        }")
        Do method1.Implementation.WriteLine("        Write result.%ToJSON()")
        Do method1.Implementation.WriteLine("    } Catch ex {")
        Do method1.Implementation.WriteLine("        Set error = {""error"": (ex.DisplayString())}")
        Do method1.Implementation.WriteLine("        Write error.%ToJSON()")
        Do method1.Implementation.WriteLine("    }")
        Do method1.Implementation.WriteLine("    Quit $$$OK")
        
        // Save and compile the class
        Set sc = classDef.%Save()
        If $$$ISERR(sc) {
            Set result = result _ "Failed to save class: " _ $System.Status.GetErrorText(sc) _ "; "
            Quit result
        }
        
        Set sc = $System.OBJ.Compile(className, "ck")
        If $$$ISERR(sc) {
            Set result = result _ "Failed to compile class: " _ $System.Status.GetErrorText(sc) _ "; "
            Quit result
        }
        
        Set result = result _ "Class created and compiled; "
        
        // Deploy the web application
        Set sc = ..DeployWebApp(namespace)
        If $$$ISERR(sc) {
            Set result = result _ "Failed to deploy web app: " _ $System.Status.GetErrorText(sc)
        } Else {
            Set result = result _ "Web application deployed at /side/mcp-interop"
        }
        
        Quit result
        
    } Catch ex {
        Quit "Error: " _ ex.DisplayString()
    }
}

/// Deploy the web application
ClassMethod DeployWebApp(namespace As %String) As %Status [ Private ]
{
    Try {
        // Switch to %SYS namespace to configure web application
        New $Namespace
        Set $Namespace = "%SYS"
        
        // Check if application already exists
        If ##class(Security.Applications).Exists("/side/mcp-interop") {
            // Delete existing application
            Set sc = ##class(Security.Applications).Delete("/side/mcp-interop")
            If $$$ISERR(sc) Quit sc
        }
        
        // Create new web application
        Set props("Name") = "/side/mcp-interop"
        Set props("NameSpace") = namespace
        Set props("Enabled") = 1
        Set props("AutheEnabled") = 32  // Password authentication
        Set props("DispatchClass") = "Side.MCPInterop"
        Set props("Description") = "MCP Interoperability REST API"
        
        Set sc = ##class(Security.Applications).Create("/side/mcp-interop", .props)
        Quit sc
        
    } Catch ex {
        Quit $$$ERROR($$$GeneralError, ex.DisplayString())
    }
}

/// Get REST API class content
ClassMethod GetRestAPIClassContent() As %String [ Private ]
{
    Set content = ""
    Set content = content _ "Class Side.MCPInterop Extends %CSP.REST" _ $C(13,10)
    Set content = content _ "{" _ $C(13,10)
    Set content = content _ $C(13,10)
    Set content = content _ "Parameter CONTENTTYPE = ""application/json"";" _ $C(13,10)
    Set content = content _ $C(13,10)
    Set content = content _ "}" _ $C(13,10)
    Quit content
}

/// Simple test function that can be called via SELECT
ClassMethod TestFunction(input As %String) As %String [ SqlName = TestFunction, SqlProc ]
{
    Quit "Echo: " _ input
}

}