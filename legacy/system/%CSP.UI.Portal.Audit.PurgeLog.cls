/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Purge Audit Log
Class %CSP.UI.Portal.Audit.PurgeLog Extends %CSP.UI.Portal.Audit.ActionTemplate [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Purge Audit Log";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.PurgeLog.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Purge Audit Log";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property Action As %String [ InitialExpression = "Purge" ];

XData formPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" hidden="true">
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("To purge items from the audit log, fill out the following form and press [ OK ]:")
	
	Set ..%GetComponentById("DaysOption").displayList = $$$TextHTML("Purge all items")_","_$$$TextHTML("Purge all items older than this many days:")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Purge Audit Log")
}

}
