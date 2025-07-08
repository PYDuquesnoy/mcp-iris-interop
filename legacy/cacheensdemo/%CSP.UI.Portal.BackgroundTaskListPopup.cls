/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - Background Tasks (version w/o header)
Class %CSP.UI.Portal.BackgroundTaskListPopup Extends %CSP.UI.Portal.BackgroundTaskList [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/%CSP.UI.Portal.BackgroundTaskListPopup.zen";

Property ErrorPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.BackgroundTaskErrorPopup.zen",,1)} ];

/// Contents block with header removed
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	title="#(%page.StdTitle)#">
<html id="toolRibbon" OnDrawContent="DrawRibbon"/>

<vgroup width="100%" valign="top">
<pane paneName="contentPane" width="100%"/>
</vgroup>

</page>
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ""

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnClose",$$$Text("Close Window"),$$$Text("Close this window."),"javascript:window.close();")

	Quit $$$OK
}

}
