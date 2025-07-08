Class Web.SocketTest Extends %CSP.WebSocket
{

Method OnPreServer() As %Status
{
	Quit $$$OK
}

Method Server() As %Status
{
	Set $ZT="Error"
	Set timeout=10
	Set status=..Write("Welcome to Cache WebSocket. NameSpace: "_$NameSpace)
	For  {
		Set len=32656
		Set data=..Read(.len, .status, timeout)
		If $$$ISERR(status),$$$GETERRORCODE(status) = $$$CSPWebSocketClosed Quit
		If $$$ISERR(status),$$$GETERRORCODE(status) = $$$CSPWebSocketTimeout {
		   Set data="Timeout after "_timeout_" seconds"_" occurred on "_$ZDate(+$Horolog,2)_" at "_$ZTime($Piece($Horolog,",",2),3)
		   Set status=..Write(data)
		}
		else {
			If data="exit" Quit
			Set data="'"_data_"'"_" (length="_len_") recieved on "_$ZDate(+$Horolog,2)_" at "_$ZTime($Piece($Horolog,",",2),3)_" NameSpace="_$NameSpace
			Set status=..Write(data)
		}
	}
	Set status=..EndServer()
	Quit $$$OK
Error // Error
	Quit $$$OK
}

Method OnPostServer() As %Status
{
	Quit $$$OK
}

}

