/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This error page will display information that is designed to make debugging an application
/// easier, if you deploy a CSP application then you should use the <class>%CSP.ErrorLog</class>
/// error page that logs the information or your own error that displays an
/// error message suitable for an end user rather than providing them with a lot of debug information.<p>
Class %CSP.Error Extends %CSP.ErrorLog [ System = 3 ]
{

/// If an error occurs while processing a HyperEvent then this method is called.
/// This method will write out javascript code that will be executed on the browser.
/// Note that the variable 'CSPPage' refers to the 'self' of the page on which the
/// Hyperevent was called  as this may be different to the current 'self'.<p>
/// You could use this javascript to redirect the browser to another page:
/// <EXAMPLE>
/// Write "CSPPage.window.location='/csp/samples/menu.csp';",!
/// </EXAMPLE>
/// Or you could popup an alert box with the error message in it:
/// <EXAMPLE>
/// Write "alert('An error occurred');",!
/// </EXAMPLE>
ClassMethod HyperEventError()
{
	Do ..DecomposeError(%request.Get("Error:ErrorCode"),.ErrorInfo)
	Set message=""
	For i=1:1:ErrorInfo {
		Set message=message_$ZCVT(ErrorInfo(i,"Desc"),"O","JS")_"\n"
		If ErrorInfo(i,"ErrorNo")=$$$ERRORCODE($$$FailedToCreateClass) {
			Set j=$O(ErrorInfo(i,"Error",""))
			While (j'="") {
				Set message=message_$ZCVT("    * "_%response.GetText("","%CSP","ErrorRoutine","Routine")_": "_ErrorInfo(i,"Error",j,"Routine"),"O","JS")_"\n"
				Set message=message_$ZCVT("      "_%response.GetText("","%CSP","ErrorOffset","Offset")_": "_ErrorInfo(i,"Error",j,"Offset"),"O","JS")_"\n"
				Set message=message_$ZCVT("      "_%response.GetText("","%CSP","ErrorError","Error")_": "_ErrorInfo(i,"Error",j,"Error"),"O","JS")_"\n"
				Set message=message_$ZCVT("      "_%response.GetText("","%CSP","ErrorDescription","Description")_": "_ErrorInfo(i,"Error",j,"Desc"),"O","JS")_"\n"
				Set message=message_$ZCVT("      "_%response.GetText("","%CSP","ErrorLine","Line")_": "_ErrorInfo(i,"Error",j,"Line"),"O","JS")_"\n"
				Set j=$O(ErrorInfo(i,"Error",j))
			}
		} else {
			Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorError","Error")_": "_ErrorInfo(i,"Error"),"O","JS")_"\n"
		}
		Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorErrorNo","ErrorNo")_": "_ErrorInfo(i,"ErrorNo"),"O","JS")_"\n"
		Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorCSPPage","CSP Page")_": "_ErrorInfo(i,"URL"),"O","JS")_"\n"
		Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorNamespace","Namespace")_": "_ErrorInfo(i,"Namespace"),"O","JS")_"\n"
		Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorClass","Class")_": "_ErrorInfo(i,"Class"),"O","JS")_"\n"
		If $G(ErrorInfo(i,"Routine"))'="" {
			Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorRoutine","Routine")_": "_ErrorInfo(i,"Routine"),"O","JS")_"\n"
			Set message=message_$ZCVT("    "_%response.GetText("","%CSP","ErrorLocation","Location")_": "_ErrorInfo(i,"Location"),"O","JS")_"\n"
			If $G(ErrorInfo(i,"Line"))'="" Set message=message_$ZCVT("    Line: "_ErrorInfo(i,"Line"),"O","JS")_"\n"
		}
		Set message=message_"\n"
	}
	Set tErrorMsg = $zcvt($$$Text("Internal Server Error","%Utility"),"O","JS")
	Set tServerCode = $get(ErrorInfo(1,"ErrorNo"))
	Set tServerCode = $select(tServerCode = "": "null", tServerCode '= +tServerCode: "'"_$zcvt(tServerCode,"O","JS")_"'", 1: tServerCode)
	Write "if (typeof cspHyperEventErrorHandler == 'function') {",!
	Write " var err = new cspHyperEventError(500,'",tErrorMsg,"',",tServerCode,",'",message,"');",!
	Write " return cspHyperEventErrorHandler(err);",!
	Write "}",!
	Write "alert('",message,"');",!
}

/// Output the error page as HTML. This makes use of the ##class(%CSP.Utils).DisplayAllObjects()
/// call to display as much information as possible about the state of the %request, %response, %server
/// objects when the error occurred.
ClassMethod OnPage() As %Status
{
	New $etrap
	&html<<!-- Debug application error page .-->
	<html #($$$HTMLLangAttr)#>
	<head>
	</head>
	<body bgcolor="#CCCCFF">
	<table style="background-color:#000088" cols="2" width="100%" border="1" cellpadding="3">
	<tr>
	<td width="50%">
	<nobr><font face="Verdana,Arial,Helvetica,sans-serif" color="white" size="+3">
	<b>#(%response.GetText("","%CSP","CSPError","CSP Error"))#</b>
	</font></nobr>
	</td>
	</tr>
	</table>
	<br>>
	Do ..DecomposeError(%request.Get("Error:ErrorCode"),.ErrorInfo)
	Do ..DisplayError(.ErrorInfo)
	Write "<br>",!
	#; Call the inspector to display the objects assocaited with this request.
	#; Note this is done inside the <body></body> tags.
	Do ##class(%CSP.Utils).DisplayAllObjects()
	&html<</body>
	</html>>
	Quit $$$OK
}

/// Output in HTML the error information in <var>ErrorInfo</var> which is the array provided by
/// <method>DecomposeError</method>.
ClassMethod DisplayError(ByRef ErrorInfo As %String) As %Status
{
	&html<<font face="Verdana,Arial,Helvetica,sans-serif" color="#FF0000">>
	For i=1:1:ErrorInfo {
		Write "<b>",..EscapeHTML(ErrorInfo(i,"Desc")),"</b><p>",!
		Write "<ul>",!
		If ErrorInfo(i,"ErrorNo")=$$$ERRORCODE($$$FailedToCreateClass) {
			Write "Compile Errors:<ul>",!
			Set j=""
			For {
				Set j=$O(ErrorInfo(i,"Error",j)) Quit:j=""
				Write "<li>"_%response.GetText("","%CSP","ErrorRoutine","Routine")_": <b>",..EscapeHTML(ErrorInfo(i,"Error",j,"Routine")),"</b>",!
				Write " "_%response.GetText("","%CSP","ErrorOffset","Offset")_": <b>",ErrorInfo(i,"Error",j,"Offset"),"</b><br>",!
				Write %response.GetText("","%CSP","ErrorError","Error")_": <b>",..EscapeHTML(ErrorInfo(i,"Error",j,"Error")),"</b><br>",!
				Write %response.GetText("","%CSP","ErrorDescription","Description")_": <b>",..EscapeHTML(ErrorInfo(i,"Error",j,"Desc")),"</b><br>",!
				Write:$get(ErrorInfo(i,"Error",j,"Line"))'="" %response.GetText("","%CSP","ErrorLine","Line")_": <b>",..EscapeHTML(ErrorInfo(i,"Error",j,"Line")),"</b></li>",!
			}
			Write "</ul>",!
		} Else {
			Write %response.GetText("","%CSP","ErrorError","Error")_": <b>",..EscapeHTML(ErrorInfo(i,"Error"))
			Write "</b><br>",!
		}
		Write %response.GetText("","%CSP","ErrorErrorNo","ErrorNo")_": <b>",ErrorInfo(i,"ErrorNo"),"</b><br>",!
		Write %response.GetText("","%CSP","ErrorCSPPage","CSP Page")_": <b>",..EscapeHTML(ErrorInfo(i,"URL")),"</b><br>",!
		Write %response.GetText("","%CSP","ErrorNamespace","Namespace")_": <b>",..EscapeHTML(ErrorInfo(i,"Namespace")),"</b><br>",!
		Write %response.GetText("","%CSP","ErrorClass","Class")_": <b>",..EscapeHTML(ErrorInfo(i,"Class")),"</b><br>",!
		If $G(ErrorInfo(i,"Routine"))'="" {
			Write %response.GetText("","%CSP","ErrorRoutine","Routine")_": <b>",..EscapeHTML(ErrorInfo(i,"Routine")),"</b><br>",!
			Write %response.GetText("","%CSP","ErrorLocation","Location")_": <b>",..EscapeHTML(ErrorInfo(i,"Location")),"</b><br>",!
			If $G(ErrorInfo(i,"Line"))'="" Write %response.GetText("","%CSP","ErrorLine","Line")_": <b>",..EscapeHTML(ErrorInfo(i,"Line")),"</b><br>",!
		}
		Write "</ul><p>",!
	}
	Write "</font>",!
	Quit $$$OK
}

}
