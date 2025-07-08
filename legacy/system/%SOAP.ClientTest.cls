/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// HTTP page that tests a SOAP client class.
Class %SOAP.ClientTest Extends %CSP.StudioTemplateSuper [ System = 3 ]
{

ClassMethod OnPreHTTP() As %Boolean
{
	If '$system.Security.Check("%Development","USE") Quit 0
	Set tInvoke = $G(%request.Data("INVOKE",1))
	
	If (tInvoke '= "") {
		Set %response.ContentType = "text/xml"
	}

	Quit 1
}

ClassMethod OnPage() As %Status
{
	// get url parameters
	Set tMethod = $G(%request.Data("METHOD",1))
	Set tCls = $G(%request.Data("CLASS",1))
	Set tInvoke = $G(%request.Data("INVOKE",1))
	Set tNamespace = $G(%request.Data("NAMESPACE",1))
	Set tType = $G(%request.Data("TYPE",1))

	Set tMethodResults = $G(%request.Data("METHODRESULTS",1))
	
	If (tNamespace '= "") {
		Set tOldNS = $namespace
		//ZN tNamespace
	}
	
	If (tInvoke '= "") {
		// invoke method
		Quit ..InvokeMethod(tCls,tMethod)
	}

	&html<<html>
	<head>
	<style>
	
	BODY			{ background: #DDEEFF; font-size: 12pt; margin: 0px; 
						font-face: Arial; }

	H1				{ background: blue; color: white;
						font-size: 18pt; 
						padding-top: 3px;
						padding-bottom: 3px;
						padding-right: 3px;
						padding-left: 10px;
						border-bottom: 1x solid black;
						}

	DIV.Main		{ margin-left: 40px; }

	TABLE.ArgList	{ border: 1x solid black; padding: 5px; background: #EEDDFF; }

	TABLE.ArgList TD	{ border-bottom: 1x solid gray; }
	TD.ArgName		{ font-weight: bold; }
	
	TABLE.MethodList	{ border: 1x solid black; padding: 5px; background: white; }

	TABLE.MethodList TH	{ border-bottom: 1x solid black; 
							background: blue; color: white;
							font-size: 14pt;
						}

	TABLE.MethodList TD	{ border-bottom: 1x solid gray; }
	TABLE.MethodList TR.Highlight	{ background: #EEDDFF; }
	TD.MethodName		{ font-weight: bold; border-right: 1x solid gray; }
	TD.MethodDesc		{ font-weight: normal; color: blue; }

	DIV.Description		{	font-size: 12pt; margin-bottom: 10px; }
	DIV.Description1	{	font-size: 12pt; margin-bottom: 10px; }
	
	DIV.Description1:first-letter	{	font-size: 14pt; }
	
	SPAN.guibutton { color: green; font-weight: bold; }

	</style>
	</head>
	<body>
	<H1>SOAP Client Test Page</H1>
	<DIV CLASS="Main">
	<FORM NAME="theForm" METHOD="POST">
	>
		
	Set tBackBtn = 0
	Set tInvokeBtn = 0
	
	If (tMethodResults '= "") {
		// Method Results page

		&html<<DIV CLASS="Description1">The results of calling the <B>#(tMethod)#</B> 
		method of the <B>#(tCls)#</B> Web Service <B>#(tType)#</B> class are displayed below.</DIV>
		<HR>
		>
		Set tURL = "%25SOAP.ClientTest.cls?INVOKE=1&CLASS=" _ ..EscapeURL(tCls) _
					"&METHOD="_ ..EscapeURL(tMethod) _
					"&NAMESPACE="_ ..EscapeURL(tNamespace) _
					"&TYPE="_ ..EscapeURL(tType)
		
		// get args for invoke
		Set tArg = $O(%request.Data("Arg_"))
		While ($E(tArg,1,4) = "Arg_") {
			Set tURL = tURL _ "&" _ ..EscapeURL(tArg) _ "=" _ ..EscapeURL($G(%request.Data(tArg,1)))
			Set tArg = $O(%request.Data(tArg))
		}
		
		&html<<IFRAME SRC="#(tURL)#" WIDTH="90%" HEIGHT="75%"></IFRAME>>

		Set tBackBtn = 1
	}
	ElseIf ((tCls '= "") && (tMethod '= "")) {
		// test for a specific method

		&html<<DIV CLASS="Description1">This page lets you invoke the <B>#(tMethod)#</B> 
		method of the <B>#(tCls)#</B> Web Service <B>#(tType)#</B> class.</DIV>
		<DIV CLASS="Description">Fill in the argument values (if any) and press the 
		<SPAN CLASS="guibutton">Invoke</SPAN> button to invoke the Web Service method.
		</DIV>>
		
		&html<<INPUT TYPE="hidden" NAME="CLASS" VALUE="#(..EscapeHTML(tCls))#">>
		&html<<INPUT TYPE="hidden" NAME="METHOD" VALUE="#(..EscapeHTML(tMethod))#">>
		&html<<INPUT TYPE="hidden" NAME="NAMESPACE" VALUE="#(..EscapeHTML(tNamespace))#">>
		&html<<INPUT TYPE="hidden" NAME="TYPE" VALUE="#(..EscapeHTML(tType))#">>
		
		Do ..ShowMethodDetails(tCls,tMethod)
		Set tBackBtn = 1
		Set tInvokeBtn = 1
	}
	ElseIf (tCls '= "") {
		// methods for class
		
		&html<<DIV CLASS="Description1">This page displays the available Web Methods 
		of the <B>#(tCls)#</B> Web Service <B>#(tType)#</B> class.</DIV>
		<DIV CLASS="Description">Click on a method to display its test page.</DIV>>

		&html<<INPUT TYPE="hidden" NAME="NAMESPACE" VALUE="#(..EscapeHTML(tNamespace))#">>

		Do ..ShowMethods(tCls,tType)
		Set tBackBtn = 1
	}
	Else {
		// show all the available web service classes
		
		&html<<DIV CLASS="Description1">
		The Web Service Test Page lets you interactively test the Web Service 
		client and server classes within your namespace.</DIV>		
		<DIV CLASS=Description>The available SOAP Client and Server
		classes in this namespace are listed below.
		Click on a method to display a list of its methods.</DIV>
		>

		Do ..ShowClasses()
	}
	
	&html<</DIV>>
	
	&html<<HR><DIV ALIGN="right">>
	
	If (tInvokeBtn) {
		&html<<INPUT TYPE="submit" NAME="METHODRESULTS" VALUE="Invoke">&nbsp;>
	}

	If (tBackBtn) {
		&html<<INPUT TYPE="BUTTON" VALUE="Back" ONCLICK="self.history.back();">&nbsp;>
	}

	// goto TemplateInsert page to force window to close...
	&html<<INPUT TYPE="BUTTON" VALUE="Close" ONCLICK="self.document.location='%25CSP.StudioTemplateInsert.cls';">&nbsp;>
	
	&html<</DIV></FORM></body>
	</html>>

	If (tNamespace '= "") {
		ZN tOldNS
	}

	Quit $$$OK
}

/// Invoke a SOAP client method
ClassMethod InvokeMethod(pCls As %String, pMethod As %String) As %Status [ PublicList = (tExec, tArgs, tResp) ]
{
	Set $ZT = "Trap"
	Kill %objlasterror
	Set tClose = ""
	
	&html<<?xml version="1.0" ?>>
	&html<<SOAPClientTest>>
	&html<<ClientClass>#(pCls)#</ClientClass>
		<ClientMethod>#(pMethod)#</ClientMethod>>
	
	Do {
		// get input arguments
		Do ..BuildInputArgs(pCls,pMethod,.tArgs,.tHasReturn)
		
		// show the inputs
		&html<<Inputs>>
		Set tClose = "</Inputs>"
		For a = 1:1:tArgs {
			&html<<Arg n="#(a)#">>
			If $IsObject(tArgs(a)) {
				Do tArgs(a).XMLExport()
			}
			Else {
				Write ..EscapeHTML(tArgs(a))
			}
			&html<</Arg>>
		}

		&html<</Inputs>>
		Set tClose = ""
		
		// now execute the method
		Set tSent = $ZDT($ZU(188),3,,3)
		
		// build a string to execute
		Set tExec = "##class("_pCls_")."_pMethod_"("
		For i = 1:1:tArgs {
			Set tExec = tExec _ $S(i>1:",",1:"") _ "tArgs(" _ i _ ")"
		}
		Set tExec = tExec _ ")"
		
		If (tHasReturn) {
			Set tExec = "Set tResp = " _ tExec
		}
		Else {
			Set tExec = "Do " _ tExec
		}
		
		Set tResp = ""
		X tExec
		
		Set tRcv = $ZDT($ZU(188),3,,3)

		If (tHasReturn) {
			If ($IsObject($G(tResp))) {
				// some objects do have XML Export!
				If (tResp.%IsA("%ListOfDataTypes")) {
					&html<<Response>>
					Set tClose = "</Response>"
					For i=1:1:tResp.Count() {
						Write "<item>",tResp.GetAt(i),"</item>"
					}
					&html<</Response>>
					Set tClose = ""
				}
				ElseIf (tResp.%IsA("%ListOfObjects")) {
					&html<<Response>>
					Set tClose = "</Response>"
					For i=1:1:tResp.Count() {
						Do tResp.GetAt(i).XMLExport("Item")
					}
					&html<</Response>>
					Set tClose = ""
				}
				Else {
					Do tResp.XMLExport("Response")
				}
			}
			Else {
				&html<<Response>>
				Write ..EscapeHTML($G(tResp))
				&html<</Response>>
			}
		}
		Else {
			&html<<VoidResponse/>>
		}
	
		Set tClose = ""
		&html<<TimeSent>#(tSent)#</TimeSent>
		  	  <TimeRcvd>#(tRcv)#</TimeRcvd>>
	} While (0)



Exit
	&html<</SOAPClientTest>>
	Quit $$$OK
Trap
	Set $ZT=""
	Write tClose
	Write "<ERROR><LOCATION>",..EscapeHTML($ZE),"</LOCATION>",!
	If ($D(%objlasterror)) {
		Do $System.Status.DecomposeStatus(%objlasterror,.err)
		Write "<DETAILS>",..EscapeHTML(err(1)),"</DETAILS>",!
	}
	Write "</ERROR>",!
	Goto Exit
}

/// Get list of input arguments for the given method
ClassMethod BuildInputArgs(pCls As %String, pMethod As %String, ByRef pArgs, ByRef pHasReturn)
{
	Set tErr = ""
	Set $ZT = "Trap"

	Kill pArgs	
	Set pArgs = 0
	Set pHasReturn = 1

	Do {
		// first get method info
		Set tMdef = ##class(%Dictionary.CompiledMethod).%OpenId(pCls _ "||" _ pMethod)
		If ('$IsObject(tMdef)) {
			Set tErr = "Unable to open method definition for: " _ pCls _ ":" _ pMethod
			Quit
		}

		// test return type
		If (tMdef.ReturnType = "") {
			Set pHasReturn = 0
		}

		// find arguments
		Set tSpec = tMdef.FormalSpec
		If (tSpec = "") {
			Quit
		}
		
		For a = 1:1:$L(tSpec,",") {
			Set pArgs = pArgs + 1
			Set tArg = $P(tSpec,",",a)
			Set tArgName = $P(tArg,":",1)
			
			// test for parameters in Type
			If (tArg [ "(") {
				Set tArgType = $P($P(tArg,":",2),"(",1)
			}
			Else {
				Set tArgType = $P($P(tArg,":",2),"=",1)
			}

			Do ..GetArgValue(.tValue,tArgName,tArgType)
			Set pArgs(a) = tValue
		}
	} While (0)

Exit
	If (tErr '= "") {
		&html<<B>Error:</B> #(tErr)#>
	}
	Quit
Trap
	Set $ZT = ""
	Set tErr = ..EscapeHTML($ZE)
	Set pArgs = 0
	Goto Exit
}

/// find the value for this argument (from the %request parms)
ClassMethod GetArgValue(Output pValue As %String, pName As %String, pType As %String, pOwner As %String = "") As %String
{
	Set pValue = ""
	
	If (pOwner '= "") {
		Set tPfx = pOwner _ "."
	}
	Else {
		Set tPfx = ""
	}

	Do {
		Set pType = ##class(%Dictionary.ClassDefinition).NormalizeClassname(pType)
		
		// get type info
		Set tCdef = ##class(%Dictionary.CompiledClass).%OpenId(pType)
		If ('$IsObject(tCdef)) {
			Quit
		}
		
		If (tCdef.ClassType = "datatype") {
			// literal
			Set pValue = $G(%request.Data("Arg_" _ tPfx _ pName,1))
		}
		Else {
			// object: create an instance of the object and fill it in...
			
			Set pValue = $zobjclassmethod(pType,"%New")
			
			For i = 1:1:tCdef.Properties.Count() {
				Set tPdef = tCdef.Properties.GetAt(i)
				If (tPdef.Private || (tPdef.Name [ "%")) {
					Continue
				}

				// get value for this property
				Do ..GetArgValue(.tValue,tPdef.Name,tPdef.Type,tPfx _ pName)

				If (tValue '= "") {
					If (tPdef.Collection = "array") {
						// get key value
						Set tKey = $G(%request.Data("Arg_" _ tPfx _ pName _ "." _ tPdef.Name _ "_KEY",1))
						If (tKey '= "") {
							Do $method($zobjproperty(pValue,tPdef.Name),"SetAt",tValue,tKey)
						}
					}
					ElseIf (tPdef.Collection = "list") {
						Do $method($zobjproperty(pValue,tPdef.Name),"Insert",tValue)
					}
					ElseIf (tPdef.Collection = "characterstream") {
						Do $method($zobjproperty(pValue,tPdef.Name),"Write",tValue)
					}
					ElseIf (tPdef.Collection = "binarystream") {
						Do $method($zobjproperty(pValue,tPdef.Name),"Write",tValue)
					}
					Else {
						Set $zobjproperty(pValue,tPdef.Name) = tValue
					}
				}
			}
		}

	} While (0)
}

/// Display the WebMethods of a SOAP client class
ClassMethod ShowMethods(pCls As %String, pType As %String)
{
	Set tErr = ""
	
	Do {
		Set tCdef = ##class(%Dictionary.CompiledClass).%OpenId(pCls)
		If ('$IsObject(tCdef)) {
			Set tErr = "Unable to open class definition for: " _ pCls
			Quit
		}
		
		If (tCdef.Methods.Count() = 0) {
			Quit
		}
		
		&html<<TABLE CLASS="MethodList" BORDER="0" CELLPADDING="0" CELLSPACING="0">>
		&html<<TR><TH COLSPAN="2">Web Methods for <B>#(pCls)#</B></TH></TR>>

		// find web methods
		For i = 1:1:tCdef.Methods.Count() {
			Set tMdef = tCdef.Methods.GetAt(i)
			If (tMdef.WebMethod = 1) {
				Set tDesc = tMdef.Description
				Set tDesc = $P(tDesc,$C(10)) // show first line of desc.
				&html<<TR onmouseover="this.className='Highlight';" onmouseout="this.className='';">
				<TD CLASS="MethodName"><A HREF="%SOAP.ClientTest.cls?CLASS=#(..EscapeURL(pCls))#&METHOD=#(..EscapeURL(tMdef.Name))#&TYPE=#(pType)#&NAMESPACE=#(..EscapeURL($namespace))#">#(tMdef.Name)#</A></TD>
				<TD CLASS="MethodDesc">#(tDesc)#&nbsp;</TD>
				</TR>>
			}
		}
		
		&html<</TABLE>>
	} While (0)
	
	If (tErr '= "") {
		&html<<B>Error:</B> #(tErr)#>
	}
}

/// Display the details page for a specific Web Method
ClassMethod ShowMethodDetails(pCls As %String, pMethod As %String)
{
	Set tErr = ""

	Do {
		Set tMdef = ##class(%Dictionary.CompiledMethod).%OpenId(pCls _ "||" _ pMethod)
		If ('$IsObject(tMdef)) {
			Set tErr = "Unable to open method definition for: " _ pCls _ ":" _ pMethod
			Quit
		}
		
		// find arguments
		Set tSpec = tMdef.FormalSpec
		If (tSpec = "") {
			Quit
		}
		
		&html<<TABLE CLASS="ArgList" BORDER="0" CELLPADDING="0" CELLSPACING="0">>
		
		For a = 1:1:$L(tSpec,",") {
			Set tArg = $P(tSpec,",",a)
			Set tArgName = $P(tArg,":",1)
			
			// test for parameters in Type
			If (tArg [ "(") {
				Set tArgType = $P($P(tArg,":",2),"(",1)
				Set tArgDef = $P($P(tArg,")",2),"=",2)
			}
			Else {
				Set tArgType = $P($P(tArg,":",2),"=",1)
				Set tArgDef = $P($P(tArg,":",2),"=",2)
			}

			
			Do ..ShowArgument(tArgName,tArgType,tArgDef)
		}

		&html<</TABLE>>
		
	} While (0)

	If (tErr '= "") {
		&html<<B>Error:</B> #(tErr)#>
	}
}

ClassMethod ShowArgument(pName As %String, pType As %String, pValue As %String, pOwner As %String = "")
{
	&html<<TR><TD CLASS="ArgName">#(pName)#</TD><TD>>
	
	If (pOwner '= "") {
		Set tPfx = pOwner _ "."
	}
	Else {
		Set tPfx = ""
	}
	
	Do {
		Set pType = ##class(%Dictionary.ClassDefinition).NormalizeClassname(pType)
		
		// get type info
		Set tCdef = ##class(%Dictionary.CompiledClass).%OpenId(pType)
		If ('$IsObject(tCdef)) {
			// no type info: treat as a string?
			&html<<INPUT TYPE="text" NAME="Arg_#(tPfx _ pName)#" SIZE="40" VALUE="#(..EscapeHTML(pValue))#">>
			Quit
		}
		
		If (tCdef.ClassType = "datatype") {
			// literal
			If (tCdef.OdbcType = "VARCHAR") {
				Set tSize = 40
			}
			Else {
				Set tSize = 15
			}
			&html<<INPUT TYPE="text" NAME="Arg_#(tPfx _ pName)#" SIZE="#(tSize)#" VALUE="#(..EscapeHTML(pValue))#">>
		}
		Else {
			// object
			&html<<TABLE CLASS="ArgList" BORDER="0" CELLPADDING="0" CELLSPACING="0">>
			
			
			For i = 1:1:tCdef.Properties.Count() {
				Set tPdef = tCdef.Properties.GetAt(i)
				If (tPdef.Private || (tPdef.Name [ "%")) {
					Continue
				}
				
				If (tPdef.Collection = "array") {
					&html<<TR><TD CLASS="ArgName">#(tPdef.Name)# Key</TD><TD>>
					&html<<INPUT TYPE="text" NAME='Arg_#(tPfx _ pName _ "." _ tPdef.Name)#_KEY' SIZE="30" VALUE="">>
					&html<</TD></TR>>
					Do ..ShowArgument(tPdef.Name,tPdef.Type,"",tPfx _ pName)
				}
				ElseIf (tPdef.Collection = "list") {
					Do ..ShowArgument(tPdef.Name,tPdef.Type,"",tPfx _ pName)
				}
				ElseIf ((tPdef.Collection = "characterstream") || (tPdef.Collection = "binarystream")) {
					&html<<TR><TD CLASS="ArgName">#(tPdef.Name)#</TD><TD>
					<TEXTAREA NAME='Arg_#(tPfx _ pName _ "." _ tPdef.Name)#' ROWS="3" COLS="40">#(..EscapeHTML(pValue))#</TEXTAREA>
					</TD></TR>>
				}
				Else {
					// evaluate default expression!!!
					Set x = "Set %val = " _ tPdef.InitialExpression
					x x
					Do ..ShowArgument(tPdef.Name,tPdef.Type,%val,tPfx _ pName)
				}
			}
			
			&html<</TABLE>>
		}
		

	} While (0)
	
	&html<</TD></TR>>
}

/// Display the list of SOAP client classes
ClassMethod ShowClasses()
{
	Set tErr = ""
	
	Do {
		// get list of client classes
		Set tResult = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Do tResult.Execute("%SOAP.WebClient")

		// get list of classes derived from %SOAP.WebClient
		While (tResult.Next()) {
			Set tName = tResult.Data("Name")
			If (tName [ "%") {
				Continue
			}
			Set tClient(tName) = ""
		}
		
		// now get classes derived from %SOAP.WebService and 
		// remove them from the client list and add to the server list
		Do tResult.Execute("%SOAP.WebService")
		While (tResult.Next()) {
			Set tName = tResult.Data("Name")
			If (tName [ "%") {
				Continue
			}
			Kill tClient(tName)
			Set tServer(tName) = ""
		}

		// now show 'em

		&html<<TABLE BORDER="0" CELLPADDING="0" CELLSPACING="10"><TR VALIGN="TOP">>
		
		
		// clients
		&html<<TD>>
		&html<<TABLE CLASS="MethodList" BORDER="0" CELLPADDING="0" CELLSPACING="0">>
		&html<<TR><TH ALIGN="LEFT" COLSPAN="2">Web Service CLIENT Classes</TH></TR>>

		Set tName = $O(tClient(""))
		While (tName '= "") {
			Set tDesc = ##class(%Dictionary.ClassDefinition).%OpenId(tName).Description
			Set tDesc = $P(tDesc,$C(10)) // show first line of desc.
			&html<<TR onmouseover="this.className='Highlight';" onmouseout="this.className='';">
			<TD CLASS="MethodName"><A HREF="%SOAP.ClientTest.cls?CLASS=#(..EscapeURL(tName))#&TYPE=Client&NAMESPACE=#(..EscapeURL($namespace))#">#(tName)#</A></TD>
			<TD CLASS="MethodDesc">#(tDesc)#&nbsp;</TD>
			</TR>>
			Set tName = $O(tClient(tName))
		}
		
		&html<</TABLE>>

		&html<</TD><TD>&nbsp;</TD><TD>>

		// servers
		&html<<TABLE CLASS="MethodList" BORDER="0" CELLPADDING="0" CELLSPACING="0">>
		&html<<TR><TH ALIGN="LEFT" COLSPAN="2">Web Service SERVER Classes</TH></TR>>

		Set tName = $O(tServer(""))
		While (tName '= "") {
			Set tDesc = ##class(%Dictionary.ClassDefinition).%OpenId(tName).Description
			Set tDesc = $P(tDesc,$C(10)) // show first line of desc.
			&html<<TR onmouseover="this.className='Highlight';" onmouseout="this.className='';">
			<TD CLASS="MethodName"><A HREF="%SOAP.ClientTest.cls?CLASS=#(..EscapeURL(tName))#&TYPE=Server&NAMESPACE=#(..EscapeURL($namespace))#">#(tName)#</A></TD>
			<TD CLASS="MethodDesc">#(tDesc)#&nbsp;</TD>
			</TR>>
			Set tName = $O(tServer(tName))
		}
		
		&html<</TABLE>>

		&html<</TD></TR></TABLE>>

	} While (0)
	
	If (tErr '= "") {
		&html<<B>Error:</B> #(tErr)#>
	}
}

}
