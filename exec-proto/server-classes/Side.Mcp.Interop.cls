Class Side.Mcp.Interop Extends %CSP.REST
{

Parameter CHARSET = "UTF-8";

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/test" Method="GET" Call="Test" />
</Routes>
}

ClassMethod Test() As %Status
{
    Write "Hello from Side MCP Interop API"
    Quit $$$OK
}

}