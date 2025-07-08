/// Simple bootstrap class for executing code and installing REST API
Class Bootstrap.Simple Extends %RegisteredObject
{

/// Test function callable via SELECT
ClassMethod Test(input As %String) As %String [ SqlName = Test, SqlProc ]
{
    Quit "Echo: " _ input
}

/// Execute ObjectScript code and return result
ClassMethod Exec(code As %String) As %String [ SqlName = Exec, SqlProc ]
{
    Try {
        Set result = ""
        Set x = ""
        
        // Execute the code
        XECUTE code
        
        // Try to capture any variable that might have been set
        If $Data(x) Set result = $Get(x)
        If $Data(result) && (result '= "") Quit result
        
        Quit "OK"
    } Catch ex {
        Quit "ERROR: " _ ex.DisplayString()
    }
}

/// Create a simple REST API class
ClassMethod CreateRestClass() As %String [ SqlName = CreateRestClass, SqlProc ]
{
    Try {
        // Create class definition
        Set cdef = ##class(%Dictionary.ClassDefinition).%New()
        Set cdef.Name = "Side.MCPInterop"
        Set cdef.Super = "%CSP.REST"
        
        // Add parameter
        Set param = ##class(%Dictionary.ParameterDefinition).%New()
        Set param.Name = "CONTENTTYPE"
        Set param.Default = "application/json"
        Set param.parent = cdef
        
        // Add URL map
        Set xdata = ##class(%Dictionary.XDataDefinition).%New()
        Set xdata.Name = "UrlMap"
        Set xdata.parent = cdef
        Do xdata.Data.WriteLine("<Routes>")
        Do xdata.Data.WriteLine("<Route Url=""/test"" Method=""GET"" Call=""Test"" />")
        Do xdata.Data.WriteLine("<Route Url=""/list"" Method=""GET"" Call=""ListProductions"" />")
        Do xdata.Data.WriteLine("</Routes>")
        
        // Add test method
        Set method = ##class(%Dictionary.MethodDefinition).%New()
        Set method.Name = "Test"
        Set method.ClassMethod = 1
        Set method.ReturnType = "%Status"
        Set method.parent = cdef
        Do method.Implementation.WriteLine("    Write ""{""""status"""": """"ok""""}""")
        Do method.Implementation.WriteLine("    Quit $$$OK")
        
        // Add list productions method
        Set method2 = ##class(%Dictionary.MethodDefinition).%New()
        Set method2.Name = "ListProductions"
        Set method2.ClassMethod = 1
        Set method2.ReturnType = "%Status"
        Set method2.parent = cdef
        Do method2.Implementation.WriteLine("    Try {")
        Do method2.Implementation.WriteLine("        Set result = []")
        Do method2.Implementation.WriteLine("        Write result.%ToJSON()")
        Do method2.Implementation.WriteLine("    } Catch ex {")
        Do method2.Implementation.WriteLine("        Write ""{""""error"""": """""_ex.DisplayString()_"""""}"" ")
        Do method2.Implementation.WriteLine("    }")
        Do method2.Implementation.WriteLine("    Quit $$$OK")
        
        // Save and compile
        Set sc = cdef.%Save()
        If $$$ISERR(sc) Quit "ERROR: Save failed - " _ $System.Status.GetErrorText(sc)
        
        Set sc = $System.OBJ.Compile("Side.MCPInterop", "ck")
        If $$$ISERR(sc) Quit "ERROR: Compile failed - " _ $System.Status.GetErrorText(sc)
        
        Quit "Class created successfully"
        
    } Catch ex {
        Quit "ERROR: " _ ex.DisplayString()
    }
}

/// Deploy web application using SQL
ClassMethod DeployWebApp() As %String [ SqlName = DeployWebApp, SqlProc ]
{
    Try {
        // Use %SYS.REST utility to deploy
        Set namespace = $Namespace
        Set sc = ##class(%SYS.REST).DeployApplication(
            "Side.MCPInterop",     // Dispatch class
            namespace,             // Namespace
            "/side/mcp-interop",   // URL
            ,                      // Resource
            ,                      // Grant
            32                     // AuthType (password)
        )
        
        If $$$ISERR(sc) {
            Quit "ERROR: " _ $System.Status.GetErrorText(sc)
        }
        
        Quit "Web application deployed at /side/mcp-interop"
        
    } Catch ex {
        Quit "ERROR: " _ ex.DisplayString()
    }
}

}