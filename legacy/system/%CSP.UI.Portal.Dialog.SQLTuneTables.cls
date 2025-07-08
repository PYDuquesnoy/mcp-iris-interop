/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Tune All Tables for a Schema in a Namespace for Management Portal
Class %CSP.UI.Portal.Dialog.SQLTuneTables Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.SQLTuneTables.zen";

/// Displayed name of this page.
Parameter PAGENAME = "SQLTuneTables";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Development";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// Schema name, may or may not be available.
Property SCHEMA As %ZEN.Datatype.string(ZENURL = "SCHEMA");

Property BackgroundPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%CSP.UI.SQL.QueryBuilderWindow.zen",,1)} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Finish" onclick="zenPage.doFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<group labelPosition="left">
<dataCombo id="cmbSchema" label="Schema:"  
	queryClass="%SQL.Manager.Catalog" 
	queryName="Schemas"
	editable="false"
	maxRows="100000"
	multiColumn="false"
	choiceColumn="1"
	valueColumn="1"
	size="70"
	searchKeyLen="3"
	showEmpty="true"
	OnExecuteResultSet="ListSchemas"
 >
 </dataCombo>
  </group>

 <checkbox id="chkKeep" caption="Keep class up to date" captionClass="zenLabel" title="If checked, the class definition will be
 updated with the new EXTENTSIZE and SELECTIVITY values, but the class definition will be kept as up-to-date. "/>
 <checkbox id="chkClear" caption="Clear values" captionClass="zenLabel" title="If checked, the SELECTIVITY and EXTENTSIZE settings 
 will be cleared from the class and table definition."/>
 <group>
<checkbox id="chkBackground" caption="Run tune table in the background" captionClass="zenLabel" value="1" onclick="zenPage.toggleFile(zenThis.value);"/>
<hgroup id="idFileName" cellVAlign="middle" labelPosition="left" >
<text id="FileName" label="Log file" labelClass="normal" labelStyle="padding-left:20px;" size="70" title="Optional name of a file to log the output of the TuneTable utility to."/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.txt');"/>
</hgroup>
<checkbox id="chkDisplay" caption="Display progress details" captionClass="normal" containerStyle="padding-left:20px;" hidden="true"/>
</group>
<spacer height="2"/>
<iframe id="output"/>

</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("output");
	var wd = zenGetWindowWidth() - 60;
	var ht = zenGetWindowHeight() - 380;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("FileName").setValue(value);
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return "";
}

/// Use clicked the Export or Export in Background button. 
ClientMethod doFinish() [ Language = javascript ]
{
	var namespace = encodeURIComponent(this.NAMESPACE);
	var schema = zen("cmbSchema").getValue();
	if (schema == "") {
		alert($$$Text("Please select a schema."));
		zen("cmbSchema").focus();
		return;	
	}
	var keep = (zen("chkKeep").getValue()==true) ? 1 : 0;
	var clear = (zen("chkClear").getValue()==true) ? 1 : 0;
	var display = (zen("chkDisplay").getValue()==true) ? 1 : 0;
	var background = (zen("chkBackground").getValue()==true) ? 1 : 0;
	var filename = zen("FileName").getValue();
	if (filename != "") {
		var exists = this.FileExists(filename);
		if (exists == -1) {
			alert($$$Text("You have entered a directory without a file name."));
			zen("FileName").focus();
			return;	
		}
		if (exists == 1) {
			if (!confirm($$$Text("File already exists. Overwrite the existing file?"))) {
				return;
			}
		}
	}
	var params = 'NAMESPACE=' + namespace + '&SCHEMA=' + encodeURIComponent(schema) + '&KEEP=' + keep + '&CLEAR=' + clear + '&DISPLAY=' + display + '&RUNBACKGROUND=' + background + '&FILENAME=' + encodeURIComponent(filename);
	zen('output').setProperty('src','_CSP.UI.Portal.Dialog.SQLTuneTablesOutput.zen?'+params);
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnFinish').setProperty('disabled',true);
	zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
}

ClientMethod toggleFile(bkChecked) [ Language = javascript ]
{
	zen("idFileName").setHidden(!bkChecked);
	zen("chkDisplay").setHidden(bkChecked);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Tune Tables")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
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
	If $$$ISERR(tSC) Quit tSC
	
	Set ..%GetComponentById("cmbSchema").value = %page.SCHEMA	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set tPageTitle = $$$FormatText($$$Text("Tune ALL tables for a selected schema in namespace %1."),$namespace)_"<br/><br/>" _
	$$$TextHTML("The EXTENTSIZE and SELECTIVITY for each table will be calculated and the new tuned values will be saved in the table and class definitions.")
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit 1
}

/// Method for executing the schemas query.
Method ListSchemas(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set NAMESPACE = %page.NAMESPACE
	If NAMESPACE '= $namespace Set $Namespace = NAMESPACE
	Set tSC = pRS.Execute()
	Quit tSC
}

/// Check to see if file exists
ClassMethod FileExists(filename) As %Integer [ ZenMethod ]
{
	If ##class(%File).DirectoryExists(filename) Quit -1
	If ##class(%File).Exists(filename) Quit 1
	Quit 0
}

}
