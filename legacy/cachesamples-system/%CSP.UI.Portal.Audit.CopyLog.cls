/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Copy Audit Log
Class %CSP.UI.Portal.Audit.CopyLog Extends %CSP.UI.Portal.Audit.ActionTemplate [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Copy Audit Log";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.CopyLog.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Copy Audit Log";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property Action As %String [ InitialExpression = "Copy" ];

XData formPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px" label="Copy to namespace">
<hgroup cellStyle="padding:4px;">
<select id="Namespace" showEmpty="true" hint="Required."/>
<checkbox id="AuditFlag" caption="Delete the audit items after they are copied?" captionClass="normal" valign="top"/>
</hgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("To copy items from the audit log, fill out the following form and press [ OK ]:")
	
	Set ..%GetComponentById("DaysOption").displayList = $$$TextHTML("Copy all items")_","_$$$TextHTML("Copy all items older than this many days:")
	
	Set tTotal = ##class(%CSP.Util.SMNavigatorPane).GetNamespaces(.Namespaces)
	Set valueList = ""
	For i=1:1:tTotal {
		If valueList '= "" Set valueList = valueList_","
		Set valueList = valueList_Namespaces(i)
	}
	Set (..%GetComponentById("Namespace").valueList,..%GetComponentById("Namespace").displayList) = valueList
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	 Quit $$$Text("Copy Audit Log")
}

}
