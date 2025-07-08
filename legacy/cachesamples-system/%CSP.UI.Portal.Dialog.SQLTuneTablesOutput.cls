/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the tune tables output of the System Management Portal.
Class %CSP.UI.Portal.Dialog.SQLTuneTablesOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.SQLTuneTablesOutput.zen";

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
		Set RUNBACKGROUND = $G(%request.Data("RUNBACKGROUND",1))
		Set FileName = $G(%request.Data("FILENAME",1))
		If $E(FileName,$L(FileName)) = "." Set FileName = FileName_"txt"
		Set Schema = $G(%request.Data("SCHEMA",1))
		Set KeepClassUpToDate = +$G(%request.Data("KEEP",1))
		Set ClearValues = +$G(%request.Data("CLEAR",1))
		Set Display = +$G(%request.Data("DISPLAY",1))
		Set EventDesc = "SQL - Tune Tables"
		Set EventData = $$$FormatText("Tune ALL tables for schema %1 in namespace %2.",Schema,$namespace)
		$$$SMPAuditChange
		If RUNBACKGROUND = 1 {
			Set tParms("Schema") = Schema
			Set tParms("NAMESPACE") = Namespace
			Set tParms("KeepClassUpToDate") = KeepClassUpToDate
			Set tParms("ClearValues") = ClearValues
			Set tParms("LogFile") = FileName
			Set tParms("Display") = 0
			Set msg1 = $$$TextHTML("Tune Tables started in the background.")
			Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
			Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
	 		Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("TuneTables",tParms("NAMESPACE"),.tParms,.tJob)
			If $$$ISERR(status) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
			&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>
		} Else {
			Write $$$FormatText($$$Text("Tune ALL tables for schema %1 in namespace %2."),$zconvert(Schema,"O","HTML"),$zconvert($namespace,"O","HTML"))_"<br/>"
			Do %response.Flush()
			&html<<pre>>
			Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
			Do $System.SQL.TuneSchema(Schema,1,Display,.err,KeepClassUpToDate,ClearValues,FileName)
			Kill EscapeObj
			If $O(err("")) '="" Do ..DrawError(err)
			&html<</pre>>
			Do %response.Flush()
		}
		&html<</body>>
		&html<</html>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write $System.Status.GetErrorText(tSC)	
	}

	Quit $$$OK
}

ClassMethod DrawError(err)
{
	Set errno = ""
	For  Set errno = $O(err(errno)) Quit:errno=""  Write $ZCVT(err(errno),"O","HTML"),"<br/>"
}

}
