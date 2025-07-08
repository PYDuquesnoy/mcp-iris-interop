/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog displays the current MDX query for the Analyzer.
Class %DeepSee.UI.Dialog.ShowQuery Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Cube name.
Property cubeName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Query text.
Property mdx As %ZEN.Datatype.string(ZENURL = "MDX");

Property nonce As %ZEN.Datatype.integer(ZENURL = "NONCE");

/// Query in manual mode?
Property manualMode As %ZEN.Datatype.boolean(ZENURL = "MANUAL");

/// Listing name.
Property listingName As %ZEN.Datatype.string(ZENURL = "LISTINGNAME");

XData Style
{
<style type="text/css">

.checkboxCaption {
	font-size: 12px;
	color: #404040;
}

#errorMsg {
	padding: 5px;
	color: red;
	background: white;
	border: #808080;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">

<textarea id="query" label="MDX Query" rows="12" cols="80" onchange="zen('manual').setValue(true);" />
<html id="errorMsg" hidden="true"/>
<checkbox id="manual" onchange="zenPage.setManual();" caption="Manual mode: Use this query for the pivot"/>
<spacer height="5"/>
<textarea id="sql" label="SQL Listing Query" rows="10" cols="80" readOnly="true" hidden="true"/>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("MDX Query")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("View query for Analyzer.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener ? this.getOpener() : window.opener;
		// JMD1031
		var table = main.zenPage.getPivot();
		if (table) {
			var manual = zen('manual').getValue();
			table.dataSource = manual ? 'manual' : 'automatic';
			if (manual) {
				table.userMDX = zen('query').getValue();
			}
			else {
				table.userMDX = '';
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('query').focus();
	}
	catch(ex) {
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ctrlQuery = ..%GetComponentById("query")
		Set sqlQuery = ..%GetComponentById("sql")
		Set ctrlManual = ..%GetComponentById("manual")
		Set tSQL = ""
		
		// + WAL075 -- Read from nonce
		// DTB957 - Use macro
		If (..nonce'="") {
			Set ..mdx = $G($$$DeepSeeQueryNonceGLVN(..nonce))
			Kill $$$DeepSeeQueryNonceGLVN(..nonce)	
		}
		// - WAL075

		Set ctrlManual.value = ..manualMode
		Set ctrlQuery.disabled = '..manualMode		// DTB883 - MDX text can only be edited if in manualMode
		Set ctrlQuery.value = ..mdx

		// see if this is a listing statement
		If (..mdx["DRILLTHROUGH") {
			Set tRS = ##class(%DeepSee.ResultSet).%New()

			Set tSC = tRS.%PrepareMDX(..mdx)
			If $$$ISOK(tSC) {
				// DP-406786 - Set listing following the %PrepareMDX
				Set tSC = tRS.%SetListing(..listingName)
				If $$$ISERR(tSC) Quit
				
				Do tRS.%Execute()
				If (tRS.%IsDrillThrough()) {
					Set tSQL = tRS.%GetListingSQL()
					Set sqlQuery.value = tSQL
					Set sqlQuery.hidden = 0
				}
			}
			Else {
				// show error
				Set div = ..%GetComponentById("errorMsg")
				Set div.content = $System.Status.GetErrorText(tSC)
				Set div.hidden = 0
				Set tSC = $$$OK
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);

	var body = zen('body');
	if (body) {
		var divBody = body.getEnclosingDiv();
		var queryCtrl = zen('query').findElement('control');
		queryCtrl.style.width = (divBody.offsetWidth-30) + 'px';

		var sqlCtrl = zen('sql').findElement('control');
		sqlCtrl.style.width = (divBody.offsetWidth-30) + 'px';
	}
}

/// Set the behavior of the interactive fields based on the setting of the 'manual' checkBox. Calling this funciton after
/// unchecking the box will regenerate the text from the current pivotTable definition using SynthesizeMDX.
ClientMethod setManual() [ Language = javascript ]
{
	// Method added by DTB883
	var main = this.getOpener ? this.getOpener() : window.opener;
	var manual = zen('manual').value;
	var table = main.zenPage.getPivot();
	
	zen('query').setDisabled(!manual);		// Set the ability to interact with the textBox content
	if (!manual) {
		table.userMDX = "";		// Clear the userMDX that might have been set by a previous manualMode commit. This will reset the query text.
		zen('query').setValue(table.SynthesizeMDX());
	}
}

}
