/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the default CSP error page. When writing any error pages you should make this your superclass.
/// If an error occurs while running a hyperevent then the response is controled from the <METHOD>HyperEventError</METHOD>.
/// If it is an error on a standard page then you writing normal HTML output.<p>
/// This error page is designed to log the information to the %ETN system error log and display
/// a simple 'An error has occurred' to the user to avoid leaking any potentially sensitive information. If you
/// would like a more developer friendly error page change the error page to <class>%CSP.Error</class> which will display
/// this same information directly in the page response.<p>
/// Two particularly interesting errors are the session timeout and the decryption failure errors are both
/// of these can be the result of attempting to go to a page when the users session has timed out or been ended.
/// Commonly you would redirect them to the login page so they can re-enter the application for example in OnPreHTTP
/// method you can write:
/// <EXAMPLE>
/// Set errorcode=$get(%request.Data("Error:ErrorNumber",1))
/// If errorcode=$$$ERRORCODE($$$CSPSessionTimeout)||(errorcode=$$$ERRORCODE($$$InvalidDecrypt)) {
/// 	Set %response.Redirect="/application/login.csp"
/// 	Quit 1
/// }
/// </EXAMPLE>
/// When an error occurs several variables are set in the %request object because these may be overwritten in
/// generating the error page itself. These variables are all prefixed by 'Error:' and the list is:
/// <ul>
/// <li><b>Error:ErrorCode</b> - The <class>%Status</class> code for this error</li>
/// <li><b>Error:ErrorNumber</b> - The error number assocaited with the ErrorCode</li>
/// <li><b>Error:Namespace</b> - The namespace the page was running in when the error occurred</li>
/// <li><b>Error:URL</b> - The URL of the page in which the error occurred.</li>
/// <li><b>Error:PageName</b> - The name of the page in which the error occurred.</li>
/// <li><b>Error:ResponseContentType</b> - The %response.ContentType at the time of the error.</li>
/// <li><b>Error:ResponseStatus</b> - The %response.Status at the time of the error.</li>
/// </ul>
/// The error page will automatically set the %response.Status for some of the standard errors, such as
/// not being able to find the CSP page . If you wish to override this setting do so in the OnPreHTTP
/// method.
Class %CSP.ErrorLog Extends %CSP.Page [ System = 3 ]
{

/// Error pages should be private to avoid the chance the user can go to them
/// directly by just typing in the address.
Parameter PRIVATE = 1;

/// If the user with a new session goes to a page and CSP is unable to allocate a license we can not run the normal
/// error page as this requires a license. The default behavior is to report a 'HTTP/1.1 404 Page not found' HTTP
/// response as this does not require a license. You may change
/// this by setting the class parameter LICENSEERRORPAGE on the error page for this CSP application (or the default
/// error page in the case of the application not found error). The values are:<ul>
/// 
/// <li>"" - Return the 404 Page not found error (this is the default)</li>
/// <li>Path to a static HTML page - Will display this static page, for example '/csp/samples/static.html' will use the
/// stream server to serve up this static file. This does not require a license, but it will only work with static content.</li></ul>
Parameter LICENSEERRORPAGE As STRING;

/// If the user with a new session goes to a page that is not present then in order to display the standard error page
/// to report this error CSP would take out a license. To avoid this license use if the error is because the application
/// is not found, or the page is not found, or the class does not exist, or the page is private and the token is not
/// correct then the default behavior is to report a 'HTTP/1.1 404 Page not found' HTTP response. This does not require
/// a license and it is standard behavior if you goto a page that is not present on a normal web server. You may change
/// this by setting the class parameter PAGENOTFOUNDERRORPAGE on the error page for this CSP application (or the default
/// error page in the case of the application not found error). The values are:<ul>
/// 
/// <li>"" - Return the 404 Page not found error (this is the default)</li>
/// <li>1 - Will obtain a license and display the standard error page.</li>
/// <li>Path to a static HTML page - Will display this static page, for example '/csp/samples/static.html' will use the
/// stream server to serve up this static file. This does not require a license, but it will only work with static content.</li></ul>
Parameter PAGENOTFOUNDERRORPAGE As STRING;

/// If the user with a new session goes to a page that causes an error before a license is obtained then in order to
/// display the standard error page to report this error CSP would take out a license. To avoid this license use in
/// this case the default behavior is to report a 'HTTP/1.1 404 Page not found' HTTP response. This does not require
/// a license. You may change
/// this by setting the class parameter OTHERSTATICERRORPAGE on the error page for this CSP application (or the default
/// error page in the case of the application not found error). The values are:<ul>
/// 
/// <li>"" - Return the 404 Page not found error (this is the default)</li>
/// <li>1 - Will obtain a license and display the standard error page.</li>
/// <li>Path to a static HTML page - Will display this static page, for example '/csp/samples/static.html' will use the
/// stream server to serve up this static file. This does not require a license, but it will only work with static content.</li></ul>
Parameter OTHERSTATICERRORPAGE As STRING;

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
	New $etrap
	Do ..LogError()
	Set err=$get(%request.Data("Error:ErrorNumber",1))
	#; If session timed out report this in error message, 
	If err=$$$ERRORCODE($$$InvalidDecrypt)||(err=$$$ERRORCODE($$$CSPSessionTimeout)) {
		Set message=$zconvert(%response.GetText("","%CSP","Timeout","The session timed out"),"O","JS")_"\n"
		Set errormsg = $zconvert($$$Text("The session timed out","%Utility"),"O","JS")		
	} Else {
		Set message=$zconvert(%response.GetText("","%CSP","Error","An error occurred with the CSP application and has been logged to system error log (^ERRORS)"),"O","JS")_"\n"
		Set errormsg = $zconvert($$$Text("Internal Server Error","%Utility"),"O","JS")
	}
	Write "if (typeof cspHyperEventErrorHandler == 'function') {",!
	Write " var err = new cspHyperEventError(500,'",errormsg,"','",err,"','",message,"');",!
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
	&html<<html #($$$HTMLLangAttr)#>
	<head></head>
	<body bgcolor="#CCCCFF">
	<table style="background-color:#000088" cols="2" width="100%" border="1" cellpadding="3">
	<tr>
	<td width="50%">
	<nobr><font face="Verdana,Arial,Helvetica,sans-serif" color="white" size="+2">
	<b>>
	If ..ClassifyError($get(%request.Data("Error:ErrorNumber",1)))'="" {
		Write %response.GetText("","%CSP","ErrorExpect","Invalid action")
	} Else {
		Write %response.GetText("","%CSP","Error","An error occurred with the CSP application.")
		Write "<p>"
		Write %response.GetText("","%CSP","ErrorExtra","It has been logged to system error log (System Operation>System Logs>Application Error Log)")
		Do ..LogError()
	}
	&html<</b>
	</font></nobr>
	</td>
	</tr>
	</table>
	</body>
	</html>>
	Quit $$$OK
}

/// Dump all information to local arrays and call %ETN to log this error
ClassMethod LogError() [ ProcedureBlock = 0 ]
{
	#; No need to log expected issues
	If ..ClassifyError($get(%request.Data("Error:ErrorNumber",1)))'="" RETURN
	New ISCRequest,ISCSession,ISCReponse,ISCErrorInfo
	Do ..DecomposeError($get(%request.Data("Error:ErrorCode",1)),.ISCErrorInfo)
	Do OrefToArray^%occRun(%request,.ISCRequest)
	Do OrefToArray^%occRun(%session,.ISCSession)
	Do OrefToArray^%occRun(%response,.ISCResponse)
	Do LOG^%ETN($get(ISCErrorInfo(1,"Error"),"Error displaying CSP page")_" : CSP Error")
}

/// This is called before the OnPreHTTP and will handle the HyperEvent errors and
/// setup the status line in the response for the standard errors.
ClassMethod OnErrorSetup(ByRef skipheader As %Boolean) As %Boolean [ ProcedureBlock = 1 ]
{
	$$$SysLog(2,"CSPError","Generating the error page for page",$get(%request.Data("Error:PageName",1)))
	
	#; If this is a hyperevent then leave the HTTP headers alone and call a custom method to output JavaScript
	If $get(%request.Data("Error:PageName",1))="%CSP.Broker.cls",$get(%request.Data("Error:ErrorNumber",1))'=$$$ERRORCODE($$$CSPBadBrokerRequest) {
		Do ##class(%CSP.Broker).InsertErrorHeader()
		Try {
			Do ..HyperEventError()
			Do ##class(%CSP.Broker).InsertErrorEnd()
			Set skipheader=1
		} Catch exception { ; Trap while generating hyperevent error
			Try {
				$$$SysLogError("CSPError","Error in Hyperevent Error code")
				Set $ze=$ze_" * Error in hyperevent error code"
				Do BACK^%ETN
				Do %response.Abort()
				If %response.InProgress=0 {
					Set %response.Expires=-1
					Do ##class(%CSP.Broker).InsertErrorHeader()
					Do DecomposeStatus^%apiOBJ($$$ERROR($$$CSPErrorWithErrorPage),.errorlist,"-d")
					Write "alert("_..QuoteJS(errorlist(1))_");",!
					Do ##class(%CSP.Broker).InsertErrorEnd()
				}
			} Catch exception {
				$$$SysLogError("CSPError","Error in error trap for Hyperevent code")
			}
		}
		Quit 0
	}

	#; If InProgress is zero then we have not sent any data to the browser so
	#; we can modify the HTTP headers that we will send.
	If %response.InProgress=0 {
		Set %response.ContentType="text/html",%response.Expires=-1
		Set err=$get(%request.Data("Error:ErrorNumber",1))
		Set tmp=..ClassifyError(err)
		If tmp'="" Set %response.Status=tmp
	} else {
		#; If we are half way through the response and it is not text format then
		#; the user will probably not see this page at all so do not send anything
		If $P(%response.ContentType,"/")'="text" {
			Quit 0
		}
	}
	Quit 1
}

/// Classify if this is an expected error like a page not found and if so return the %response.Status information.
/// If the error is not an expected error it will return "".
ClassMethod ClassifyError(err) As %String
{
	#; Classify the basic error types and use this in the HTTP response status code.
	If (err=$$$ERRORCODE($$$CSPApplicationDoesNotExist))||(err=$$$ERRORCODE($$$CSPPageDoesNotExist))||(err=$$$ERRORCODE($$$ClassDoesNotExist))||(err=$$$ERRORCODE($$$MethodDoesNotExist))||(err=$$$ERRORCODE($$$FileDoesNotExist))||(err=$$$ERRORCODE($$$FileCanNotOpen))||(err=$$$ERRORCODE($$$ServiceNotEnabledForApplication))||(err=$$$ERRORCODE($$$CSPNamespaceDoesNotExist)) {
		RETURN "404 Page Not Found"
	} ElseIf err=$$$ERRORCODE($$$CSPIllegalRequest)||(err=$$$ERRORCODE($$$InvalidDecrypt))||(err=$$$ERRORCODE($$$CSPSessionTimeout)) {
		RETURN "403 Page Not Found"
	} ElseIf err=$$$ERRORCODE($$$CSPMethodNotSupported) {
		RETURN "501 HTTP Method not supported"
	}
	RETURN ""
}

/// Return an array of information in <var>ErrorInfo</var> about the error suitable for display with a
/// bit of formatting. You pass in the <var>sc</var> which is the status code of the error. It assumes
/// you are dealing with CSP related errors.
ClassMethod DecomposeError(sc As %Status, ByRef ErrorInfo As %String) As %Status
{
	Do DecomposeStatus^%apiOBJ(sc,.errorlist,"-d")
	#; Decode SOAP errors as the information is in %objlasterror
	If $get(errorlist(1,"code"))=$$$ERRORCODE($$$ObjectScriptError),sc["<ZSOAP>"||(sc["<ZACTX>"),$get(%objlasterror)'="" {
		Kill errorlist
		Do DecomposeStatus^%apiOBJ(%objlasterror,.errorlist,"-d")
	}
	
	Set errorNamespace = $S($G(%request)="":"<Unknown>",1:%request.Get("Error:Namespace",$namespace))
	New $namespace
	Try {
		Set $namespace = errorNamespace
	} Catch {}
	
	For i=1:1:errorlist {
		Set errorlist(i,"code")=$G(errorlist(i,"code"),0)
		Set ErrorInfo(i,"ErrorNo")=errorlist(i,"code")
		Set ErrorInfo(i,"Namespace")=errorNamespace
		If errorlist(i,"code")=$$$ERRORCODE($$$ObjectScriptError) {
			Set ErrorInfo(i,"Desc")=%response.GetText("","%CSP","ErrorDesc","A run-time error occurred while executing the page")
			Set ErrorInfo(i,"Error")=errorlist(i,"param",1)
			Set ErrorInfo(i,"URL")=$S($G(%request)="":"<Unknown>",1:%request.Get("Error:URL",%request.URL))
			Set routine=$P($P(errorlist(i,"param",1),"^",2,*)," ")
			Set cls=##class(%RoutineMgr).GetOther(routine,"INT",-1)
			If $piece(cls,".",*)="CLS" {
				Set ErrorInfo(i,"Class")=$piece(cls,".",1,*-1)
			} Else {
				Set ErrorInfo(i,"Class")=$S($G(%request)="":"<Unknown>",1:%request.Get("Error:Class","<Unknown>"))
			}
			Set ErrorInfo(i,"Routine")=$P($P(errorlist(i,"param",1),"^",2,*)," ")
			Set ErrorInfo(i,"Location")=$P($P(errorlist(i,"param",1),">",2,*),"^")
			If ErrorInfo(i,"Namespace")'="<Unknown>" {
				Try {
					Set ErrorInfo(i,"Line")=$TEXT(@(ErrorInfo(i,"Location")_"^"_ErrorInfo(i,"Routine")))
				} Catch {}
			}
		} ElseIf errorlist(i,"code")=$$$ERRORCODE($$$FailedToCreateClass) {
			Set ErrorInfo(i,"Class")=$G(errorlist(i,"param",1))
			Set ErrorInfo(i,"URL")=$S($G(%request)="":"<Unknown>",1:%request.Get("Error:URL",%request.URL))
			Set ErrorInfo(i,"Error")=$P($P($G(errorlist(i,"param",2)),"Errors:"),": ",2,*)
			If ErrorInfo(i,"Error")="" Set ErrorInfo(i,"Error")=$G(errorlist(i,"param",2)) Continue
			Set ErrorInfo(i,"Desc")=ErrorInfo(i,"Error")
			If $length(errorlist(i,"param",2),$char(13,10))=1 {
				Set line=errorlist(i,"param",2)
				Set ErrorInfo(i,"Error",1,"Error")=$piece(line,":",5)
				Set ErrorInfo(i,"Error",1,"Desc")=$piece($piece(line,":",2,3),"Errors:")
				Set ErrorInfo(i,"Error",1,"Line")=$piece($piece(line,":",6,*),": Error Number")
				Set ErrorInfo(i,"Error",1,"Routine")=$piece($piece(line,":",4),"(")
				Set ErrorInfo(i,"Error",1,"Offset")=$piece($piece($piece(line,":",4),"(",2),")")
			} Else {
				For j=2:1:$L(errorlist(i,"param",2),$C(13,10)) {
					Set line=$P(errorlist(i,"param",2),$C(13,10),j)
					If j#2 {
						Set ErrorInfo(i,"Error",j\2,"Line")=$P(line,"TEXT:",2,*)
					} Else {
						Set ErrorInfo(i,"Error",j\2,"Routine")=$ZSTRIP($P(line,"("),"<>W")
						Set ErrorInfo(i,"Error",j\2,"Offset")=$P($P(line,"(",2),")")
						Set ErrorInfo(i,"Error",j\2,"Error")=$ZSTRIP($P(line,":",2),"<>W")
						Set ErrorInfo(i,"Error",j\2,"Desc")=$P(line,":",3,*)
					}
				}
			}
		} Else {
			Set ErrorInfo(i,"Desc")=%response.GetText("","%CSP","CSPErrorDesc","CSP error occurred")
			Set ErrorInfo(i,"Error")=$P(errorlist(i),": ",2,*)
			Set ErrorInfo(i,"URL")=$S($G(%request)="":"<Unknown>",1:%request.Get("Error:URL",%request.URL))
			Set ErrorInfo(i,"Class")=$S($G(%request)="":"<Unknown>",1:%request.Get("Error:Class","<Unknown>"))
		}
	}
	Set ErrorInfo=errorlist
	Quit $$$OK
}

}
