/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Management Portal Error page.
/// 
Class %DeepSee.UI.ErrorPage Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Error Page";

Parameter DOCBOOKID = "D2GS_ch_intro";

Property errorName As %String(ZENURL = "ERROR");

/// No resource is needed to view the error page.
/// JMD1415
Parameter RESOURCE;

XData Style
{
<style type="text/css">
#errorMsg {
	padding: 20px;
	color: #404040;
}

div.errorMsg {
	padding-bottom: 20px;
	font-size: 20px;
	color: #F04040;
}

div.errorMsg2 {
	padding-bottom: 20px;
	font-size: 17px;
	color: #404040;
}

.errorBack a {
	padding: 2px;
	font-size: 17px;
	color: #404040;
	text-decoration: underline;
}

.errorBack a:hover {
	background: #FFEEAA;
}

</style>
}

/// This XML defines the contents of the contents pane for this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<html id="errorMsg" OnDrawContent="DrawError"/>
</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Error Page")
}

/// Get the name for the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("DeepSee Error Page")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 0
	Set pSearchBox = 0
	Quit $$$OK
}

/// Draw contents of error html component.
Method DrawError(pSeed As %String) As %Status
{
	If (..errorName="License") {
		Set tMsg = $$$Text("You are not licensed to view this page.")
	}
	ElseIf (..errorName="Privilege") {
		Set tMsg = $$$Text("You are not authorized to view this page.")
	}
	Else {
		Set tMsg = $$$Text("There is an error on this page.")
	}
	
	Set tMsg2 = $$$Text("Please contact your Analytics Administrator.")
	Set tMsgBack = $$$Text("Back")
	Set tArgs("$NAMESPACE") = $namespace
	Set tHome = ..Link("/csp/sys/%25CSP.Portal.Home.zen",.tArgs)

	&html<
	<div class="errorMsg">#($ZCVT(tMsg,"O","HTML"))#</div>
	<div class="errorMsg2">#($ZCVT(tMsg2,"O","HTML"))#</div>
	<div class="errorBack"><a onclick="window.history.back();">#($ZCVT(tMsgBack,"O","HTML"))#</a></div>
	>
	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = $$$Text("Error Page","%DeepSee")
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($classname(),"O","URL")_".zen?ERROR="_$ZCVT($G(%request.Data("ERROR")),"O","URL"))
	Quit $$$OK
}

}
