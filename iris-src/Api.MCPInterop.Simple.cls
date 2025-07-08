/// Simple test version of Api.MCPInterop to verify basic functionality
Class Api.MCPInterop Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";
Parameter CHARSET = "UTF-8";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/test" Method="GET" Call="Test" />
    <Route Url="/status" Method="GET" Call="GetStatus" />
    <Route Url="/list" Method="GET" Call="ListProductions" />
</Routes>
}

ClassMethod Test() As %Status
{
    Write "{""success"":1,""message"":""API is working"",""api"":""Api.MCPInterop""}"
    Quit $$$OK
}

ClassMethod GetStatus() As %Status
{
    Write "{""success"":1,""api"":""Api.MCPInterop"",""namespace"":"""_$NAMESPACE_"""}"
    Quit $$$OK
}

ClassMethod ListProductions() As %Status
{
    Try {
        Set hasEns = ##class(%Dictionary.ClassDefinition).%ExistsId("Ens.Director")
        If hasEns {
            Write "{""success"":1,""ensembleAvailable"":true,""productions"":[],""count"":0}"
        } Else {
            Write "{""success"":1,""ensembleAvailable"":false,""productions"":[],""count"":0}"
        }
    } Catch ex {
        Write "{""success"":0,""error"":"""_$ZCVT(ex.DisplayString(),"O","JS")_"""}"
    }
    Quit $$$OK
}

}