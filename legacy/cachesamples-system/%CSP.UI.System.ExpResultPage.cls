/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Final processing of actions for Explorer's compile, export, etc.
Class %CSP.UI.System.ExpResultPage Extends %CSP.Page [ System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

ClassMethod OnPage() As %Status
{
	Set tMode = $G(%request.Data("Mode",1))
	Set tNamespace = $G(%request.Data("Namespace",1))  // import
	If tNamespace = "" Set tNamespace = $G(%request.Data("$ID1",1))
	If tNamespace = "" Set tNamespace = $G(%request.Data("$NAMESPACE",1))
	// Note: 
	// When Deleting errors $ID1 is Namespace that contains the error to be deleted
	Set cbState = $G(%request.Data("cbState",1))
	If $E(cbState) = "," Set cbState = $E(cbState,2,$L(cbState))
	Do ##class(%CSP.UI.System.ExpResultPane).LocalizePage(.msgPage)
	Set header = $G(msgPage(tMode),"UNKNOWN")

	&html<<html #($$$HTMLLangAttr)#>
	<head>
	<title>#($$$TextHTML("Final Result"))#</title>
	<link rel="stylesheet" type="text/css" href='#(..Link("/csp/sys/intersystems.css"))#'>
	>
	&html<
	<style>
pre {
	border: 1px black solid;
	background: white;
	padding: 10px;
}	
	</style>
	<script language="javascript">
	function closerefresh()
	{
		// refresh the opener then close self
		// YSD1696 for Safari, you need to close the parent and refresh the parent's parent.
		var refreshpage = document.getElementById("refreshpage").value;
		if (opener) {
			if (opener != null) {
				if (refreshpage.length > 0) {
					if (opener.opener != null) {
						opener.opener.document.location.href = refreshpage;
						opener.close();
					} else {
						opener.document.location.href = refreshpage;
						window.close();
					}
				}
			}
		} else {
			var Mode = document.getElementById("Mode").value;
			if ((Mode == "EnableEnsNamespace")||(Mode == "CopyMapsFrom")) {
				var url = encodeURI(refreshpage);
				document.location.href = url;
			} else {
				window.close();
			}
		}
	}
	</script>
	>

	&html<</head>
	<body onLoad="self.focus();" bgcolor="#FFFFFF" text="#000000" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">>
	Do ##class(%CSP.Util.AutoPage).DrawAutoLogout()
	Set tSub = ""
	Set msgDatabase = $$$TextHTML("Database")
	Set msgNamespace = $$$TextHTML("Namespace")
	Set msgUser = $$$TextHTML("User")
	Set msgBegin = $$$TextHTML("Begin at")
	If tMode'["Integrity" Set tSub = $S(tMode["Compact":msgDatabase,tMode'["Integrity":msgNamespace,1:"")_": "_$zconvert(tNamespace,"O","HTML")_"&nbsp;&nbsp;&nbsp;&nbsp;"
	//Set refreshpage = $G(%request.Data("refreshpage",1))
	set refreshpage = ##class(%CSP.Portal.Utils).GetValidatedLink($G(%request.Data("refreshpage",1)))
	If refreshpage = "" {
		If tMode["Integrity" {
			Set refreshpage = ..Link("/csp/sys/op/UtilSysOpDatabases.csp",,1)_"Recent=1"
		} Else {
			If ((tMode [ "EnableEnsNamespace") || (tMode [ "CopyMapsFrom")) {
				Set refreshpage = ..Link("%CSP.UI.Portal.Namespaces.zen",,1)_"Recent=1"	
			} Else {
				If tSub'="" {
					Set refreshpage = ..Link("/csp/sys/op/%CSP.UI.Portal.OpDatabases.zen?FreespacesOn=1")
				} Else {
					Set refreshpage = ..Link("%CSP.Portal.Home.zen")	
				}
			}
		}
	}
	//&html<<h1>#(header)#</h1>
	Do ##class(%CSP.Util.AutoPage).DrawTitle(header)	
	&html<<form style="padding-left:10px;">
	<input type="hidden" name="Mode" id="Mode" value="#(..EscapeHTML(tMode))#">
	<input type="hidden" name="refreshpage" id="refreshpage" value="#(..EscapeHTML(refreshpage))#">
	<br><div class="Text">#(tSub)##(msgUser)#: #(%session.Username)# &nbsp;&nbsp;&nbsp;&nbsp;#(msgBegin)#&nbsp;#($zdt($h,3))#</div>
	>
		//Set %response.TraceDump=1
	//Do ..DrawCloseButton(1)
	&html<<hr>>
	Do %response.Flush()

	If (tMode [ "DeleteError") {

		&html<<pre>>
		Do ..DeleteError(tNamespace,cbState,tMode)
		&html<</pre>>	
		
	} ElseIf (tMode [ "EnableEnsNamespace") {
		&html<<pre>>
		Do ..EnableEnsNamespace(tNamespace,$G(%request.Data("CopyMapsFrom",1)))
		&html<</pre>>
	} ElseIf (tMode [ "CopyMapsFrom") {
		&html<<pre>>
		Do ..CopyMapsFrom(tNamespace,$G(%request.Data("CopyMapsFrom",1)))
		&html<</pre>>
	}
	&html<<div class="Text">#($$$TextHTML("End at"))# #($zdt($h,3))#</div>>
	&html<<hr>>
	Do ..DrawCloseButton(2)
	&html<</form><br>
<script language="javascript">
	self.focus();
</script>

	</body>
	</html>>
	Quit $$$OK
}

ClassMethod DeleteError(namespace, cbState, tMode)
{
	Set $ZT = "Trap"
	Set io = $$$GETIO
	$$$SETIO("HTML")
	Do {			
		If tMode["ODBC",namespace'="",$namespace '= namespace ZN namespace
		Set tRow = 1
		Set tName = $P(cbState,",",1)
		Set date = $G(%request.Data("$ID2",1))
		While tName '= "" {
			Set tSC = 1
			If tMode [ "ByNamespace" {
				Write !,$$$FormatText($$$Text("Deleting errors in %1"),$zconvert(tName,"O","HTML"))
				If tMode = "DeleteErrorODBCByNamespace" {
					ZN tName
					do KillLastErrorAll^%SYS.SQLSRV(tName)
				} Else {
					Set tSC = ##class(SYS.ApplicationError).DeleteByNamespace(tName)
				}
			} ElseIf tMode [ "ByDate" {
				Write !,$$$FormatText($$$Text("Deleting errors in %1 %2"),$zconvert(namespace,"O","HTML"),$zconvert(tName,"O","HTML"))
				Set tSC = ##class(SYS.ApplicationError).DeleteByDate(namespace,tName)
			} ElseIf tMode [ "ByError" {
				If tMode = "DeleteErrorODBCByError" {
					Write !,$$$FormatText($$$Text("Deleting errors in %1 %2"),$zconvert(namespace,"O","HTML"),$zconvert(tName,"O","HTML"))
					do KillLastErrorOne^%SYS.SQLSRV(tName)
				} Else {
					Write !,$$$FormatText($$$Text("Deleting errors in %1 %2 %3"),$zconvert(namespace,"O","HTML"),$zconvert(date,"O","HTML"),$zconvert(tName,"O","HTML"))
					Set tSC =  ##class(SYS.ApplicationError).DeleteByError(namespace,date,tName)
				}
			}		
			Do ..DoneMsg(tSC)
			Set tRow = tRow + 1
			Set tName = $P(cbState,",",tRow)
		} 
		Do %response.Flush()
	} While(0)
Done
	$$$SETIO(io)
	Quit	
Trap
	Set $ZT=""	
	Write $ZE,!
	Goto Done
}

/// Method to enable production-enabled namespace when adding a new namespace.
ClassMethod EnableEnsNamespace(pNamespace As %String, pCopyMapsFrom As %String)
{
	Do ..InitializeNamespace(pNamespace, pCopyMapsFrom, 1)
}

/// Method to copy mappings for a InterSystems IRIS instance when adding a new namespace.
ClassMethod CopyMapsFrom(pNamespace As %String, pCopyMapsFrom As %String)
{
	Do ..InitializeNamespace(pNamespace, pCopyMapsFrom, 0)
}

/// Method to copy mappings and optionally enable it for productions
/// for a InterSystems IRIS instance when adding a new namespace.
ClassMethod InitializeNamespace(pNamespace As %String, pCopyMapsFrom As %String, pEnsembleEnable As %Boolean) [ Internal ]
{
	Try {
		Set tSC = $$$OK
		Set tStatus = ##class(%CSP.Portal.SourceControl.IO).Redirect(.tIO)
		//thing to capture here
		If (pEnsembleEnable) {
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			Set tSC = ##class(%Library.EnsembleMgr).EnableNamespace(pNamespace,1)
			Kill EscapeObj
		}
		If ($$$ISERR(tSC)) {
			Write !,..EscapeHTML($System.Status.GetErrorText(tSC))
		}
		Else {
			If (pCopyMapsFrom '= "") {
				Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
				Set tSC = ##class(Config.Namespaces).CopyMaps(pCopyMapsFrom,pNamespace)
				Kill EscapeObj
			}
			If ($$$ISERR(tSC)) {
				 Write !,..EscapeHTML($System.Status.GetErrorText(tSC))
			}
			Else {
				Write !,$$$Text("Done")
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
		Kill EscapeObj
	}
	If $IsObject($get(tIO)) {
		Try {
			Set tStatus = tIO.StopRedirect()
			// NOW OUTPUT AS HTML TEXT...
			Set tStatus = tIO.GetData(.tStream)
		  	While (tStream.AtEnd=0) {
		  		Set line = tStream.ReadLine()
		  		//output is already escaped Write ..EscapeHTML(line),!
		  		Write line,!
  			} 
		}
		Catch ex {
			Write ..EscapeHTML($ZE),!
		}
	}	
	Quit
}

/// Write common message after action is commited.
ClassMethod DoneMsg(tSC)
{
	Write " "
	If tSC = 1 Write $$$TextHTML("Done")
	Else  Write ..EscapeHTML($System.Status.GetErrorText(tSC))
}

ClassMethod DrawCloseButton(Index As %Integer)
{
	Set tId = "btn_Close"_Index
	&html<
		<input type="button" value='#($$$Text("Close"))#' name="#(tId)#" id="#(tId)#" onclick="closerefresh();">
		>
}

/// Write out error log
ClassMethod DrawErrorLog(err)
{
	If $G(err) > 0 {
		Write !,"Error Log: "
		Set errcnt = $o(err(""))
		While errcnt '= "" {
			Write !,errcnt,?10,$g(err(errcnt))
			Set errname = ""
			For  Set errname = $O(err(errcnt,errname)) Quit:errname=""  Write !,?5,..EscapeHTML(errname),?25,..EscapeHTML($G(err(errcnt,errname)))
			Set errcnt = $o(err(errcnt))	
		}
		Write !
	}
}

ClassMethod HelpTextCancel()
{
	If $G(%request.Data("OK",1)) = "" &html<<div class="div">Click the <b>OK</b> button to proceed, or click the <b>Close</b> button to close this window.</div>>
}

/// Ensure the user has either %Admin_Operate:USE or %Admin_Manage:USE.
/// Extend response timeout to allow the requested task to complete.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '($system.Security.Check($$$AdminManageResourceName,"USE") || $system.Security.Check($$$AdminOperateResourceName,"USE")) Quit 0
	// Allow one hour for whatever it is doing to prevent time out
	Set %response.Timeout = 3600
	Quit 1
}

}
