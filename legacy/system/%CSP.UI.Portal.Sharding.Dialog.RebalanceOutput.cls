/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This pages shows the compile output of the System Management Portal.
Class %CSP.UI.Portal.Sharding.Dialog.RebalanceOutput Extends %CSP.Page [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Sharding.Dialog.RebalanceOutput.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check("%Admin_Manage","USE")
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
		Set TimeLimit = +$G(%request.Data("TimeLimit",1))
		Set ISNODELEVEL = +$G(%request.Data("ISNODELEVEL",1))
		Set EventDesc = " Rebalance "_$S(ISNODELEVEL=1:"node-level",1:"namespace-level")_" cluster"
		Set EventData = "Namespace: " _ Namespace _ $$$CRLF
		Set EventData = EventData _ $$$CRLF _ "Run in background "		
		$$$SMPAuditChange
		Set tParms("Namespace") = Namespace
		Set tParms("TimeLimit") = TimeLimit
		Set tParms("ISNODELEVEL") = ISNODELEVEL
		Set msg1 = $$$TextHTML("This job has been started in the background.")
		Set msg2 = $$$TextHTML("Click here for a quick view of the background tasks.")
		Set linkpage = ##class(%CSP.Page).Link("%25CSP.UI.Portal.BackgroundTasks.cls")
		Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("ShardRebalance",$namespace,.tParms,,.tJob)
		If $$$ISERR(status) Do ##class(%CSP.UI.Portal.Background.Utils).LogMsg($System.Status.GetErrorText(status))
		&html<<p>#(msg1)#<br/><a href="#(linkpage)#">#(msg2)#</a></p>>

		Do %response.Flush()

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
