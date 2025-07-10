/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, Ensemble)

/// Used to specify a local filename for target of an export
/// <p>This class is used internally by InterSystems. You should not make direct use of it within your applications. 
Class EnsPortal.Dialog.BrowserExportSelect Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter APPLYBUTTON = 0;

Parameter RESOURCE = "%Ens_Portal:USE";

Property localDefault As %ZEN.Datatype.string(ZENURL = "LCLDEFAULT") [ InitialExpression = "export.txt" ];

Property exportInfoText As %ZEN.Datatype.string(ZENURL = "EXPINFO") [ InitialExpression = {$$$TextHTML("Select the name for the export file")} ];

XData Style
{
<style type="text/css">
body {
	background: white;	
}
#exportInfo {
	font-size: 12px;
	white-space: pre-line;
	padding-right: 8px;
}
.modalGroupCloseButton, .modalGroupCloseButtonHover {
	cursor: default;
}
</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<hgroup>
<spacer width="30"/>
<vgroup>
<spacer height="20"/>
<label id="exportInfo"/>
<spacer height="30"/>
<hgroup id="browserFile" label="" labelClass="normal" cellVAlign="bottom" >
<text id="DocName" label="Enter the name of the export file" size="40"/>
</hgroup>
<spacer height="30"/>
</vgroup>
</hgroup>
</pane>
}

Method %OnGetTitle() As %String
{
	Quit ""
}

Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var filename = zen('DocName').getValue();
	return encodeURIComponent((filename));
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
		return true;
}

/// Draw contents of description box.
Method DrawInfo(pSeed As %String) As %Status
{
	Quit $$$OK
}

Method %DrawTitle(pSeed As %String) As %Status
{
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; Populate exportInfo and default local default name
	Set ..%GetComponentById("exportInfo").value = ..exportInfoText
	Set ..%GetComponentById("DocName").value = ..localDefault

	Quit ##super()
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

}
