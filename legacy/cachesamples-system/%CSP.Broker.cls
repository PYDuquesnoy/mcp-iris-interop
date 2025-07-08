/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.<p>
/// The <CLASS>%CSP.Broker</CLASS> object serves as an event handler for CSP requests.
Class %CSP.Broker Extends %CSP.Page [ Abstract, System = 3 ]
{

/// Default result to be written in UTF-8.
Parameter CHARSET [ Internal ] = "utf-8";

/// OnPreHTTP to setup response headers.
ClassMethod OnPreHTTP() As %Boolean [ Internal ]
{
	#; Make sure pageclass query parameter cannot be set in URL
	Kill %request.Data("pageclass",1),^||%CSP.Broker.output
	
	If $data(%request.Data("WJSEVENT",1),event) {
		Set %response.ContentType="text/html"
	} ElseIf $data(%request.Data("WEVENT",1),event) {
		Set %response.ContentType="application/x-csp-hyperevent"
	}
	If $data(%request.Data("WMOBILE",1)) {
		Do %response.SetHeader("Access-Control-Allow-Origin","null")
		Do %response.SetHeader("Access-Control-Allow-Credentials","true")
	}
	If $get(event)="" {
		Set %sc=$$$ERROR($$$CSPBadBrokerRequest)
	} Else {
		Set %sc=..GetEvent(event,.%class,.%method)
		Set pgcls=$get(%request.Data("pageclass",1))
		If pgcls'="" Quit ..callPreHyperEvent(pgcls,%class,%method)
	}
	Quit 1
}

ClassMethod callPreHyperEvent(class As %String, cls As %String, method As %String) [ Internal, Private, ProcedureBlock = 0 ]
{
	New return
	Use $io::("^"_$ZNAME)
	Do $zutil(82,12,1)
	Try {
		Set return=''$classmethod(class,"OnPreHyperEvent",cls,method)
	} Catch {
		#; Ignore error if this OnPreHyperEvent method does not exist
		If $zerror'["METHOD DOES NOT EXIST"||($zerror'["%CSP.Broker")||($zerror'["OnPreHyperEvent") Set %sc=$$$ERROR($$$ObjectScriptError,$zerror)
		Set return=1
	}
	Do $zutil(82,12,0)
	Quit return
rstr(sz,to) Quit
wchr(s) Do output($char(s)) Quit
wff() Do output($char(12)) Quit
wnl() Do output($char(13,10)) Quit
wstr(s) Do output(s) Quit
wtab(s) Do output($justify("",s-$x)) Quit
output(s) { Set ^||%CSP.Broker.output($increment(^||%CSP.Broker.output))=s }
}

/// Compute and serve the hyperevent response.
ClassMethod OnPage() As %Status [ Internal ]
{
	If $$$ISERR($get(%sc,1)) Quit %sc
	
	If $Data(%request.Data("WEVENT",1)) {
		Set ok=..CSPEvent(%class,%method)
	} Elseif $Data(%request.Data("WJSEVENT",1)) {
		Set ok=..CSPJSEvent(%class,%method)
	} Else {
		Set ok=$$$ERR($$$CSPBadBrokerRequest)
	}
	Kill ^||%CSP.Broker.output
	Quit ok
}

/// Signal trapped error
ClassMethod OnPostHTTP() [ Internal ]
{
	Set pgcls=$get(%request.Data("pageclass",1))
	If pgcls'="" {
		Set $ztrap="postTrap"
		Do $classmethod(pgcls,"OnPostHyperEvent",%class,%method)
	}
postTrap	Set $ztrap=""
	Quit
}

/// Parse the request event.
ClassMethod GetEvent(event As %String, ByRef cls As %String, ByRef member As %String) As %Status [ Internal, Private ]
{
	Set $ZT="GetEventErr"
	If $get(%request.Data("WMOBILE",1))'=1 {
		#; As the event is encrypted it will not work with a new session as the keys will not match.
		If %session.NewSession Quit $$$ERROR($$$CSPSessionTimeout)
		$$$cspDecodeBrokerCheck(event,%session.Key,event)
		Set event=$listget(event)
		If event="" Quit $$$ERR($$$CSPIllegalRequest)
	}
	Set find=$find(event,":")
	If find Set pageclass=$extract(event,find,*),event=$extract(event,1,find-2)
	Set cls=$Piece(event,".",1,*-1),member=$extract(event,$length(cls)+2,*)
	If cls=""||(cls[" ")||(cls[$char(9))||(cls[$char(160)) Quit $$$ERR($$$ClassNameRequired)
	Set cls=$$$NormalizeClassname(cls)
	If member=""||(member[" ")||(member[$char(9))||(member[$char(160)) Quit $$$ERR($$$InvalidDecrypt)
	Set %request.Data("pageclass",1)=$select($get(pageclass)'="":pageclass,1:cls)
	If $get(%request.Data("WMOBILE",1))=1 {
		Set sc=$$$OK
		Try {
			If '$classmethod(cls,"%IsA","%ZEN.Mojo.basePage") Set sc=$$$ERROR($$$CSPMobileCall,cls)
			If ($parameter(cls,"ALLOWMOBILE") '= 1) Set sc=$$$ERROR($$$CSPMobileCall,cls)
		} Catch {
			Set sc=$$$ERROR($$$CSPMobileCall,cls)
		}
		If member'="InvokeClassMethod",member'="InvokeInstanceMethod" Set sc=$$$ERROR($$$CSPMobileMethod,member)
		If $$$ISERR(sc) Quit sc
	}
	If member="" Quit $$$ERROR($$$MethodNameRequired)
	Quit $$$OK
GetEventErr	If $ZE["<ILLEGAL VALUE>" Quit $$$ERR($$$InvalidDecrypt)
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// String to execute to run the desired method.
ClassMethod XecuteStr(event, ByRef code As %String, wantreturnval As %Boolean) As %String [ Internal, Private ]
{
	Set newList="",setList=""
	
	#; Get class and method name from event assume if WARGC is not present it is 0
	Set count=$Get(%request.Data("WARGC",1),0)
	
	If wantreturnval {
		Set code="Set rs=$classmethod(%class,%method"
	} Else {
		Set code="Do $classmethod(%class,%method"
	}
	
	#; get arguments for method; 'null' values become undefined
	For i=1:1:count {
		Set code=code_","
		Set arg="WARG_"_i
		If $Data(%request.Data(arg,1)) {
			Set code=code_"%request.Data("""_arg_""",1)"
		} ElseIf $Data(%request.Data("WLIST"_i,1)) {
			Set var="W"_i
			Set code=code_"."_var
			Set newList=newList_$select(newList="":"new ",1:",")_var
			For j=1:1:%request.Data("WLIST"_i,1) {
				If $Data(%request.Data(var,j)) {
					Set setList=setList_" set "_var_"("_j_")=%request.Data("""_var_""","_j_") "
				}
			}
		}
	}
	Set code=newList_$select(newList="":"",1:" ")_setList_code_")"
	
	Quit $$$OK
}

/// Handles events generated by the Java CSPBroker.class. Input parameters can be found
/// in the %request object (an instance of <CLASS>%CSP.Request</CLASS>), as
/// follows:<p>
/// 
/// WEVENT          class.method    Invoke 'method' of 'class'<br>
/// WARGC           integer         Number of arguments<br>
/// WARG_1..WARG_n  value           Value of argument 'n'<br>
/// <br>
/// Output is written back to the [HTML/HTTP] stream, as follows:<p>
/// 
/// WEBCHD          Session handle<br>
/// #status         Status code (see below)<br>
/// [error msg]     Error message (if status contains 'E')<br>
/// javascript output   Zero or more lines of Javascript output<br>
/// ...<br>
/// [return value]      Return value of event function (if present)<br>
/// 
/// Valid status codes are:<p>
/// 
/// E           Error condidition follows<br>
/// R           Last line contains return value
ClassMethod CSPEvent(%class As %String, %method As %String) As %Status [ Internal, Private, PublicList = rs ]
{
	New rs
	Write %session.CSPSessionCookie,!
	
	Set ok=..XecuteStr($Get(%request.Data("WEVENT",1)),.code,1)
	If $$$ISERR(ok) Quit ok
	
	Set rs=""
	Write "#R"_$C(13,10)
	
	Set $ZT="CSPEventErr"
	
	#; Output anything written in the OnPreHyperEvent code
	For i=1:1:+$get(^||%CSP.Broker.output) Write ^||%CSP.Broker.output(i)
	#; invoke method
	$$$SysLogVar(3,"CSPBroker","[CSPEvent] Xecute code %class="_%class_" %method="_%method,code)
	Xecute code
	
CSPOk	Write !,"#OK",!
	Write rs,!
	
	Quit $$$OK
	
	#; If the error occured in the running of the xecute trap the common cases
CSPEventErr	If $ZE["CSP.Broker" {
		#; If the method does not return with a value just ignore this and set return value to ""
		If $ZE["<COMMAND>" Set rs="" Goto CSPOk
		#; Report that the method does not exist
		If $ZE["<METHOD DOES NOT EXIST>" Quit $$$ERROR($$$MethodDoesNotExist,%method)
		#; Report the class does not exist
		If $ZE["<CLASS DOES NOT EXIST>" Quit $$$ERROR($$$ClassDoesNotExist,%class)
	}
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Handles events generated by the JavaScript event IFrame method. Input parameters can be found
/// in the %request object (an instance of <CLASS>%CSP.Request</CLASS>), as
/// follows:<p>
/// 
/// WJSEVENT        class.method    Invoke 'method' of 'class'<br>
/// WARGC           integer         Number of arguments<br>
/// WARG_1..WARG_n  value           Value of argument 'n'<br>
/// <br>
/// Output is written back to the [HTML/HTTP] stream as a JavaScript document.
/// The variable CSPPage refers to the page that called this method.
ClassMethod CSPJSEvent(%class As %String, %method As %String) As %Status [ Internal, Private ]
{
	Set event=%request.Data("WJSEVENT",1)

	Set ok=..XecuteStr(event,.code,0)
	If $$$ISERR(ok) Quit ok
	
	Set $ZT="CSPJSEventErr"
	
	#; The <SCRIPT> tag approach does not need the page header
	If $data(%request.Data("WJSEVENT",1)) {
		Write "<html><head></head><body>"_$C(13,10)
		Write "<script language=JavaScript>"_$C(13,10)
		Write "var CSPPage = window.parent;"_$C(13,10)
	} Else {
		Write "var CSPPage = window;"_$C(13,10)
	}
	
	#; Output anything written in the OnPreHyperEvent code
	For i=1:1:+$get(^||%CSP.Broker.output) Write ^||%CSP.Broker.output(i)
	#; invoke method
	$$$SysLogVar(3,"CSPBroker","[CSPJSEvent] Xecute code %class="_%class_" %method="_%method,code)
	Xecute code
	
	If $data(%request.Data("WJSEVENT",1)) Write "</script></body></html>",!
	
	Quit $$$OK
	
CSPJSEventErr
	#; If the error occured in the running of the xecute trap the common cases
	If $ZE["CSP.Broker" {
		#; Report that the method does not exist
		If $ZE["<METHOD DOES NOT EXIST>" Quit $$$ERROR($$$MethodDoesNotExist,method)
		#; Report the class does not exist
		If $ZE["<CLASS DOES NOT EXIST>" Quit $$$ERROR($$$ClassDoesNotExist,cls)
	}
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Output the beginning of an error response
ClassMethod InsertErrorHeader() [ Internal ]
{
	If $Data(%request.Data("WJSEVENT")) {
		Set %response.ContentType="text/html"
		If '%response.InProgress {
			Do %response.WriteHTTPHeader()
			&html<<html><head></head><body>>
		}
		Write "<script language=JavaScript>"_$C(13,10)
	} Else {
		Set %response.ContentType="application/x-csp-hyperevent"
		If '%response.InProgress {
			Do %response.WriteHTTPHeader()
			Write %session.CSPSessionCookie,!
			Write "#V",!
		}
	}
	Quit
}

/// Output the end of an error response
ClassMethod InsertErrorEnd() [ Internal ]
{
	If $Data(%request.Data("WJSEVENT")) {
		&html<</script>
		</body>
		</html>>
	} Else {
		Write !,"#OK",!
	}
	Quit
}

}
