/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

Class %CSP.UI.Portal.Applications.Utils [ Abstract, System = 4 ]
{

Parameter DOMAIN = "%Utility";

Property msgConfirm As %String [ InitialExpression = {$$$TextJS("Are you sure you want to delete application '%1'?")} ];

/// Delete selected application.
ClientMethod doDelete(application) [ Language = javascript ]
{
	var ok = this.Delete(application);
	if (ok != "") alert(ok);
	zen("table").executeQuery(0);
}

ClientMethod doEdit(name) [ Language = javascript ]
{
	var url = this.EditPage+"PID="+encodeURIComponent(name);
	document.location = url;
}

/// Needed to ensure that ApplicationType is an integer
Method ExecuteApplicationList(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSC = pRS.Execute("*",+%page.ApplicationType,"")
	Quit tSC
}

/// Delete selected application now.
ClassMethod Delete(application As %String) As %String [ ZenMethod ]
{
	Set tResult = ""
	Set tSC = ##Class(Security.Applications).Delete(application)
	If $$$ISERR(tSC) Set tResult = ##class(%CSP.Page).QuoteJS($System.Status.GetErrorText(tSC))
	Quit tResult
}

}
