/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the compile output of the System Management Portal.
Class %CSP.UI.Portal.Dialog.CompileOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.CompileOutput.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// generate the content of a csp page.
ClassMethod OnPage() As %Status [ ServerOnly = 1 ]
{
	Set tSC = $$$OK
	Try {
		&html<<html><head></head>>
		&html<<body>>

		Set Namespace = $G(%request.Data("NAMESPACE",1))
		If Namespace '= "",Namespace '= $namespace Set $Namespace = Namespace
		Set COMPILEALL = +$G(%request.Data("COMPILEALL",1))
		Set RUNBACKGROUND = $G(%request.Data("RUNBACKGROUND",1))
		Set FILETYPE = $G(%request.Data("FILETYPE",1))
		Set Flags = $G(%request.Data("FLAGS",1))
		Set EventDesc = " Compile "_FILETYPE
		#; Build items in selectedRows into tItem array
		Kill tItems
		Set tTotal = 0
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)
			For n = 1:1:$L(selectedRows,",") Set tItem = $P(selectedRows,",",n) If tItem '= "" Set tExt=$ZCVT($E(tItem,$L(tItem)-2,$L(tItem)),"L") If tExt'="obj",tExt'="inc" Set tItems(tItem) = "",tTotal = tTotal + 1
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
		Set EventData = "Compile Flags: " _ Flags _ $$$CRLF
		If COMPILEALL = 1 {
			Set EventData = EventData _ $$$CRLF _$$$FormatText("Compile All items in %1",$namespace)_$$$CRLF_"Flags: "_Flags
		} Else {
			Do $$$PatEventRows(.EventData,.tItems)	
		}
		Set EventData = EventData _ $$$CRLF _ "Run in background: "_ RUNBACKGROUND		
		$$$SMPAuditChange
		If RUNBACKGROUND = 1 {
			Set tParms("TotalColumns") = tTotal
			Set tParms("Flags") = Flags
			Set tParms("CompileAll") = COMPILEALL
			Set tParms("CompileClass") = (FILETYPE [ "Class")
			Set msg1 = $$$TextHTML("This task will be run in the background.")
			Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
			Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
		 	If COMPILEALL!('COMPILEALL&&(tTotal>0)) {
			 	Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("Compile",$namespace,.tParms,.tItems,.tJob)
				If $$$ISERR(status) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
			 	&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>
		 	}				
		} Else {
			If COMPILEALL = 1 Write $$$FormatText($$$Text("Compiling All items in %1"),$zconvert($namespace,"O","HTML")),"<br/>"
			Else  Write $$$FormatText($$$Text("Compiling Selected items in %1"),$zconvert($namespace,"O","HTML")),"<br/>"
			Do %response.Flush()
			&html<<pre>>
	
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			If COMPILEALL = 1 {
				Do $System.OBJ.CompileAll(Flags,.err)
			} Else {
				Do $System.OBJ.CompileList(.tItems,Flags,.err)
			}
			Kill EscapeObj ; To remove the oref and turn off redirection.
			If $O(err("")) '="" {
				Set errno = ""
				For  Set errno = $O(err(errno)) Quit:errno=""  Write $ZCVT(err(errno),"O","HTML"),"<br/>"
			}
			&html<</pre>>
			Do %response.Flush()
		}
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		&html<<pre>>
		Write tSC
		&html<</pre>>
		
	}

	Quit $$$OK
}

}
