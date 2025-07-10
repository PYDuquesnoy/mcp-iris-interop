/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to show the contents of header messages and their contents.
/// Note that changes to this class should be bubbled down to Ens.Enterprise.Portal.Dialog.MessageBodyDisplay.
Class EnsPortal.Dialog.MessageBodyDisplay Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MessageHeader:USE";

/// Displayed name of this page.
Parameter PAGENAME = "View Message Body Contents";

Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter OKBUTTON As BOOLEAN = 0;

Property showUser As %ZEN.Datatype.string(ZENURL = "SHOW");

Property initialID As %ZEN.Datatype.string(ZENURL = "ID");

XData Style
{
<style type="text/css">
body {
	background: white;
}

/* styles for message details */
table.AutoFormTable {
	color: #606060;
	background: white;
	border: 1px solid black;
	padding: 0px;
	font-size: 12px;	
}

table td.AutoFormTableCaption {
	font-weight: bold;
	border-bottom: 1px solid darkgray;
	border-right: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

table td.AutoFormTableValue {
	border-bottom: 1px solid darkgray;
	padding-left: 2px;
	padding-right: 2px;
}

</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" valign="top">
<spacer height="20" />
<hgroup valign="top">
<spacer width="20" />
<html id="detailsContent" OnDrawContent="DrawDetailsContent" hidden="false" />
<html id="bodyInfo" OnDrawContent="DrawBodyInfo" hidden="false"/>
</hgroup>
</pane>
}

/// Write out contents of details panel.
/// <var>pID</var> is the message id.
Method DrawDetailsContent(pID As %String) As %Status
{
	If ""=pID { 
		Quit $$$OK
	}
	Else {
		Quit ##class(EnsPortal.Utils).DrawItemDetails(pID)
	}
}

/// Write out contents of body details panel.
/// <var>pHeaderID</var> is the message id.
Method DrawBodyInfo(pHeaderID As %String) As %Status
{
	If ""=pHeaderID { 
		Quit $$$OK
	}
	Else {
		Quit ##class(EnsPortal.Utils).DrawBodyInfo(pHeaderID)
	}
}

/// This dialog does not return a value
ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("View Message Body Contents")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	Quit:'tSC tSC
	Set header = ..%GetComponentById("detailsContent")
	Set body = ..%GetComponentById("bodyInfo")
	If (..showUser = "header") {
		Set header.seed = ..initialID
		Set body.seed = ""
	}
	ElseIf (..showUser = "body") {
		Set header.seed = ""
		Set body.seed = ..initialID
	}
	Else { // This should never happen
		Set header.seed = ""
		Set body.seed = ""
	}
	Quit $$$OK
}

/// Update the details for a selected message.
ClientMethod showHeader(messageId) [ Language = javascript ]
{
	var header = zen('detailsContent');
	if (zenPage.showUser == "header") { 
		if ((messageId == -1) || (messageId == null)) header.seed = '';
		else header.seed = messageId;
	}
	else header.seed = '';
	header.refreshContents();
}

/// Update the details for a selected message.
ClientMethod showBody(messageId) [ Language = javascript ]
{
	var body = zen('bodyInfo');
	if (zenPage.showUser == "body") { 
		if ((messageId == -1) || (messageId == null)) body.seed = '';
		else body.seed = messageId;
	}
	else body.seed = '';
	body.refreshContents();
}

}
