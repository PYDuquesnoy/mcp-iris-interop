/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Page to define OAuth2 administration options
Class %CSP.UI.Portal.OAuth2.Administration Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "OAuth 2.0 Administration";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Administration.zen";

Parameter HELPADDRESS = "System Administration,Security,OAuth2,Administration";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_OAuth2_Registration";

/// If it's set to 1 then Save and Cancel buttons will show in top bar
Property IsEditForm As %Boolean [ InitialExpression = 0 ];

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.EditForm {
	background-image: none;	
}
</style>
}

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form autocomplete="false">
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="groupEdit" enclosingClass="EditForm" cellStyle="padding:5px;" labelPosition="left">
<spacer height="2"/>
<text id="Name" label="Revoke tokens for user:" size="60" maxlength="250" 
hint="All access tokens associated with the specified user will be deleted." onchange="zenPage.doModified();"/>
<button id="btnRevoke" caption="Revoke" onclick="zenPage.revokeUser();"/>
<spacer height="2"/>
</group>
</form>
</pane>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	/// Set focus to the Name field	
	zen("Name").focus();
}

ClientMethod revokeUser() [ Language = javascript ]
{
	var name = zen("Name").getValue();
	if (zenTrim(name) != "") {
		var result = this.RevokeTokenForUser(name);
		/// show message then clear username field	
		if (result.ok == 1) {
			this.setModified(false);
			if ((typeof(result.Message) != "undefined") && (result.Message != "")) {
				this.showMsg(result.Message,0);
				zen("Name").setValue('');
				zen("Name").focus();
			}
		} else {
			this.showMsg(result.ErrorMessage,1);
		}

	}
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("OAuth 2.0 Administration")
}

/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"))
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set titleEdit = $$$TextHTML("Use the form below to edit OAuth 2.0 administration options:")
	Set ..lblTitle = titleEdit
	Set ..ParentURL = ..Link("%25CSP.UI.Portal.Home.zen")
	Quit $$$OK
}

ClassMethod RevokeTokenForUser(pUserName) As %ZEN.proxyObject [ ZenMethod ]
{
	
	Set $ZT="Error"
	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set tSC = $$$OK
	Set tSC = ##class(OAuth2.Server.AccessToken).RevokeUser(pUserName)
	If $$$ISERR(tSC) {
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	} Else {
		Set tProxy.ok = 1
		Set tProxy.Message = $$$FormatText($$$Text("All access tokens associated with %1 have been deleted."),$zconvert(pUserName,"O","HTML"))
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
