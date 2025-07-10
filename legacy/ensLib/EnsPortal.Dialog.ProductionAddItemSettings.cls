/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This page allows the user to see certain possible default values for items being added by the add item wizards .
Class EnsPortal.Dialog.ProductionAddItemSettings Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to view this page.
/// Even though no writing is being done from here it is protected by same resource as caller.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Item Specific Settings";

Parameter APPLYBUTTON = 0;

Parameter OKBUTTON = 0;

Parameter CANCELBUTTON = 1;

/// Production Name
Property ProductionName As %String(ZENURL = "PRODUCTION");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.txtMessages {
	font-size: 10pt;
}

.headerMessage {
	font-size: 12pt;
	font-weight: bold;
}

.zenLabel {
	font-size: 10pt;
	padding-right: 5px;
	font-weight: normal;
	color: black;
}

.labelText {
	font-size: 10pt;
	font-weight: bold;
	color: black;
	padding: 0px;
	padding-right: 5px;
	border: 0px;
}

.boxedArea {
	font-size: 10pt;
	border: 1px solid #888888;
}

TABLE.DetailTable	{ 
	font-size: 10pt;
	border: 1px #222222 solid;
}

TABLE.DetailTable TH { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: left;
	padding: 2px;
}

TABLE.DetailTable TD { 
	text-align: left;
	padding: 2px;
}

TD.DetailValue A {
	width: 100%;
	padding-left: 3px;
	padding-right: 3px;
}

TD.DetailValue DIV {
	width: 100%;
}

TD.DetailLabel { 
	background: #EEDDFF;
	font-weight: bold;
}
</style>
}

/// This XML block defines the contents of this dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<spacer height="10" />
<html id="idHeader" OnDrawContent="DrawHeader" enclosingStyle="margin-left: 20px;"></html>
<spacer height="15" />
<html id="idDetails" enclosingStyle="margin-left: 20px;"></html>
<spacer height="10" />
<html id="idFooter" OnDrawContent="DrawFooter" enclosingStyle="margin-left: 20px;"></html>
</pane>
}

/// Draw messages at the top of the popup.
Method DrawHeader(pSeed As %String) As %Status
{
	#dim tMsg = $$$TextHTML("These are the settings that could be defaulted using the Add Item wizard.")
	#dim tMsg2 = $$$TextHTML("All the settings for an item will be shown in the Production Configuration page when the item has been added.")
	#dim tMsg3 = $$$TextHTML("If the item name has not been entered the possible Default might not be listed.")
	#dim tMsg4 = $$$TextHTML("If a Default value will be applied the value will be shown when the item is added to the production.")
	&html<<div class="txtMessages">#(tMsg)#<br/><br/>#(tMsg2)#<br/><br/>#(tMsg3)#<br/><br/>#(tMsg4)#</div>>
	Quit $$$OK
}

Method DrawFooter(pSeed As %String) As %Status
{
	Quit $$$OK
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Possible Default Values","Ensemble")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	#dim tTitle = $$$FormatText($$$Text("Possible Default Values for item being added"))
	Quit tTitle
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$FormatText($$$Text("Production %1"),%page.ProductionName)
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return true;
}

/// This callback is called when the user presses the OK button.
/// If this returns false, then the action is canceled.
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	return true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('btnCancel').setProperty('title',$$$Text("Close this window "));
}

ClientMethod ondialogStart() [ Language = javascript ]
{
	/* Obtain data from caller to populate table */
	var opener = this.getOpener();
	if ((opener) && (opener.zenPage)) {
		this.ProductionName = opener.zenPage.ProductionName;
		var details = zen('idDetails');
		if ((details)&&(opener.zenPage.defaultSettingsHTML)) {
			details.content=opener.zenPage.defaultSettingsHTML;
			details.refreshContents();
		}
	}
}

}
