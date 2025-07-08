/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Error page for the User Portal.<br/>
Class %DeepSee.UserPortal.ErrorPage Extends %DeepSee.UserPortal.standardPage [ System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "Error Page";

/// URL of home page (used in links).
Parameter HOMEPAGE = "_DeepSee.UserPortal.Home.zen";

Property errorName As %String(ZENURL = "ERROR");

XData Style
{
<style type="text/css">

#contentsLeft {
	width: 100px;
	background: none;
}

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
	font-size: 15px;
	color: #404040;
}

</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee" 
	title="#(%page.StdTitle)#"
	dropEnabled="true"
	dragAndDrop="true">
<hgroup width="100%" cellVAlign="bottom">
<spacer width="20px"/>
<pane paneName="menuPane" width="100px"/>
<html id="title" OnDrawContent="DrawTitle"/>
</hgroup>

<hgroup id="contentsOuter" cellVAlign="top">
<hgroup id="contentsInner" cellVAlign="top">
<vgroup id="contentsLeft">
</vgroup>

<vgroup id="contentsRight">
<html id="errorMsg" OnDrawContent="DrawError"/>
</vgroup>

</hgroup>
</hgroup>
</page>
}

/// This XML defines the menu for this page.
XData menuPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("DeepSee Portal")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Error Page")
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
	Set tHome = ##class(%DeepSee.UserPortal.Utils).%GetUserHomePageURL()

	&html<
	<div class="ErrorMsg">#($ZCVT(tMsg,"O","HTML"))#</div>
	<div class="ErrorMsg2">#($ZCVT(tMsg2,"O","HTML"))#</div>
	<div><a href="#(tHome)#">Click to return to Home Page<a></div>
	>
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Quit tSC
}

}
