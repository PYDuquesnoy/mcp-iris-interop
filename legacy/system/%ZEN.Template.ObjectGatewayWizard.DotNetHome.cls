/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// Wizard to help you import a DLL assembly file from .NET and create a set of corresponding classes.
Class %ZEN.Template.ObjectGatewayWizard.DotNetHome Extends %ZEN.Template.ObjectGatewayWizard.Template [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = ".NET Gateway Wizard";

Parameter TEMPLATETITLE = ".NET Gateway Wizard";

Parameter TEMPLATEDESCRIPTION = "Import DLL assembly from .NET";

/// Display title of this page <title></title>
Parameter PAGETITLE = ".NET Gateway Wizard";

Parameter HELPID = "BGNT_makeproxies_wizard";

/// Tab number when Finish is clicked. This dictate which tab to return to when Back is clicked from the Done page.
Property lastTab As %ZEN.Datatype.string;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	overflow: hidden;
}
.helpText {
	color:gray;
	font-size:0.8em;	
}
.note {
	color: red;
	font-size: 1.0em;
	font-weight: bold;
	padding: 6px;
}
.normal {
	font-size: 0.8em;
	text-decoration: none;
	vertical-align: middle;
}
.caption {
	color: black;
	font-size: 1.0em;
	font-weight: normal;
}
#btnR1 input,#btnR2 input,#btnL1 input,#btnL2 input,#btnU1 input,#btnD1 input {
	width: 1.7em;
}

</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" cellStyle="padding-left:10px;">
<hidden id="firstFailed"/>
<label id="idRespond" label="Gateway did not respond!" labelClass="note" containerStyle="padding-top:10px;" hidden="true"/>
<tabGroup id="tabGroup">
<tab>
<vgroup labelPosition="top" containerStyle="padding:20px;" label="This wizard will help you import a DLL assembly file from .NET and create a set of corresponding classes." labelClass="caption"
 enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
<hgroup id="idFileName" label="Enter the path and name of a DLL assembly file:" labelClass="zenRequired" cellVAlign="top" >
 <text id="FileName" showLabel="false" size="80" required="true"
 value="" onchange="zenPage.updateState();"
 hint="Required." hintClass="helpText"
  />
  <button id="btnBrowse" caption="Browse" onclick="zenPage.doBrowse();"/>
</hgroup>
<text id="Host" label=".NET Gateway server name / IP address:" labelClass="zenRequired" required="true" size="20" value="127.0.0.1"
hint="Required." hintClass="helpText" onchange="zenPage.updateState();"
/>
<text id="Port" label=".NET Gateway server port:" labelClass="zenRequired" required="true" size="20" value="55000"
hint="Required." hintClass="helpText" onchange="zenPage.updateState();"
/>

<text id="Classpaths" label="Additional paths\assemblies to be used in finding dependent classes:" labelClass="normal" size="80"
hint="Specify a list of assembly .dll files or directories, separated by semi-colons." hintClass="helpText"
/>
<text id="Excludes" label="Exclude dependent classes matching the following prefixes:" labelClass="normal" size="80"
hint="Specify a list of namespaces and class name prefixes, separated by semi-colons." hintClass="helpText"
/>

</vgroup>
</tab>
<tab>
<vgroup id="idTable" labelPosition="top" containerStyle="padding:20px;" 
label="The .NET Gateway Wizard has determined that your file contains the following classes:" 
labelClass="caption">

<tablePane id="table" label="(Check the top checkbox to select/unselect all classes)"
queryClass="%Net.Remote.Utility"
queryName="GetAllClasses"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="5000"
multiSelect="true"
onmultiselect="zenPage.rowChecked(zenThis);"
showValueInTooltip="true"
showZebra="true"
valueColumn="Classname"
useSnapshot="false"
initialExecute="false"
>
<column colName="Classname" header="Classname"/>
 <parameter id="pfilename" value="" />
 <parameter id="pserver" value=""/>
 <parameter id="pport" value=""/>
 </tablePane>
 </vgroup>
</tab>
<tab>
<vgroup labelPosition="top" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
 <vgroup id="idProcessing" containerStyle="padding:20px;">
<iframe id="iframe" width="650" height="380"/>
</vgroup>
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// Launching a file selector window. 
ClientMethod doBrowse() [ Language = javascript ]
{
	var Dir = zenPage.getComponentById("FileName").getValue();
	var wildcard = "*.dll";
	var url = "%ZEN.Dialog.fileSelect.cls?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard + "&showdirectoryonly=0&CSPCHD=" + this.CSPSessionCookie + "&CSPSHARE=1";
	zenLaunchPopupWindow(url,'FileSelection','status,scrollbars,resizable,width=600,height=700');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zenPage.getComponentById("FileName").setValue(value);
		zenPage.updateState();	
	}
}

Method %OnAfterCreatePage() As %Status
{
	Set FileName = $G(%session.Data("DotNetGatewayWizard","FileName"))
	If FileName '= "" {
		Set ..%GetComponentById("FileName").value = FileName
		Set ..%GetComponentById("Host").value = $G(%session.Data("DotNetGatewayWizard","Host"))
		Set ..%GetComponentById("Port").value = $G(%session.Data("DotNetGatewayWizard","Port"))
		Set ..%GetComponentById("Classpaths").value = $G(%session.Data("DotNetGatewayWizard","Classpaths"))
		Set ..%GetComponentById("Excludes").value = $G(%session.Data("DotNetGatewayWizard","Excludes"))
	}	
	Quit $$$OK
}

/// This method is called when the template is complete.
/// It adds classes to the project, allows classes to be added to source control, and cleans up some session data
Method %OnTemplateAction() As %Status
{
	Set cls = $O(%session.Data("DotNetGatewayWizard","ClassList",""))
	While cls'="" {
		Do ..%AddToProject(cls _ ".cls")
		Do ..%AddToSourceControl(cls _ ".cls")
		Set cls = $O(%session.Data("DotNetGatewayWizard","ClassList",cls))
	}
	Kill %session.Data("DotNetGatewayWizard","ClassList")
	Kill %session.Data("DotNetGatewayWizard","SelectedRows")
	Kill %session.Data("DotNetGatewayWizard","NAMESPACE")
	
	Quit 1
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		if (!this.formValidationHandler()) {
			var id = zenPage.getComponentById("firstFailed").getValue();
			if (id != "") zenPage.getComponentById(id).focus();
		} else {
			flag = true;
		}
		break;
	case 2:
		break;
	case 3:
		break;
	}
	return flag;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		flag = false;
		break;
	case 2:
		break;
	case 3:
		break;
	}	
	return flag
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		break;
	case 2:
		// enable Finish only if user selected at least one class
		flag = this.hasSelected();
		if (flag == true) {
			zenPage.getComponentById("btnFinish").setProperty("caption",this.lblFinish);
			this.isExit = 0;
		}
		break;
	case 3:
		break;
	}	
	zenPage.getComponentById("btnCancel").setDisabled(false);	
	
	return flag;
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	var pass = true;
	if (!this.validateRequired(zenPage.getComponentById("FileName"),pass,"S")) pass = false;
	if (!this.validateRequired(zenPage.getComponentById("Host"),pass,"S")) pass = false;
	if (!this.validateRequired(zenPage.getComponentById("Port"),pass,"S")) pass = false;
	return pass;
}

/// User clicked the Finish button. Start Import.
ClientMethod finishTemplate() [ Language = javascript ]
{
	if (this.isExit == 1) {
		this.invokeSuper('finishTemplate');
		return;
	}
	try {	
		if (!this.formValidationHandler()) {
			var id = zenPage.getComponentById("firstFailed").getValue();
			if (id != "") zenPage.getComponentById(id).focus();
			return;
		}
		var FileName = zenPage.getComponentById("FileName").getValue();
		var idRespond = zenPage.getComponentById("idRespond");
		if (this.FileExists(FileName) == false) {
			idRespond.setProperty("label",this.lblNotExist);
			idRespond.setHidden(false);
			return;
		} else {
			idRespond.setProperty("label",this.lblNoRespond);
		}
		var Host = zenPage.getComponentById("Host").getValue();
		var Port = zenPage.getComponentById("Port").getValue();
		var idRespond = zenPage.getComponentById("idRespond");
		if (!this.CheckGateway(Host,Port)) {
			idRespond.setHidden(false);
			return;	
		} else {
			idRespond.setHidden(true);
		}
		var Classpaths = zenPage.getComponentById("Classpaths").getValue();
		var Excludes = zenPage.getComponentById("Excludes").getValue();
		var tabGroup = zenPage.getComponentById('tabGroup');
		var tabNo = tabGroup.getCurrTabNo();
		this.lastTab = tabNo;
		var table = zenPage.getComponentById('table');
		// if user clicked Finish on tab 1 then import the .dll file; otherwise import selected classes.
		var selectedRows = "";
		if (tabNo == 2) selectedRows = table.selectedRows;
		var ok = this.SetSelected(selectedRows,FileName,Host,Port,Classpaths,Excludes)
		var iframe = zenPage.getComponentById('iframe');
		zenPage.getComponentById('tabGroup').showTab(3);
		iframe.setProperty("src","%25ZEN.Template.ObjectGatewayWizard.DotNetDone.cls");
		zenPage.getComponentById('btnFinish').setProperty("caption",this.lblExit);
		this.isExit = 1;	
		zenPage.updateState();
		zenPage.getComponentById("btnCancel").setDisabled(true);

	} catch (ex) {
		alert("Error: " + ex);
	}
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		var FileName = zenPage.getComponentById("FileName").getValue();
		var idRespond = zenPage.getComponentById("idRespond");
		if (this.FileExists(FileName) == false) {
			idRespond.setProperty("label",this.lblNotExist);
			idRespond.setHidden(false);
			flag = false;
			break;
		} else {
			idRespond.setProperty("label",this.lblNoRespond);
		}
		var Host = zenPage.getComponentById("Host").getValue();
		var Port = zenPage.getComponentById("Port").getValue();
		if (!this.CheckGateway(Host,Port)) {
			idRespond.setHidden(false);
			flag = false;
		} else {
			idRespond.setHidden(true);
			var ok = this.loadTable();
			tabGroup.showNextTab();
		}
		break;
	case 2:
		break;
	case 3:
		break;
	}
	zenPage.updateState();
}

/// If file exists, load table based on the jar file entered.
ClientMethod loadTable() As %Boolean [ Language = javascript ]
{
	var FileName = zenPage.getComponentById("FileName").getValue();
	var Host = zenPage.getComponentById("Host").getValue();
	var Port = zenPage.getComponentById("Port").getValue();
	var table = zenPage.getComponentById('table');
	table.parameters[0].value = FileName;
	table.parameters[1].value = Host;
	table.parameters[2].value = Port;
	table.executeQuery();
	return 1
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		break;
	case 2:
		tabGroup.showPreviousTab();
		zenPage.getComponentById("btnFinish").setProperty("caption",this.lblFinish);
		this.isExit = 0;
		break;
	case 3:
		tabGroup.showTab(this.lastTab);
		zenPage.getComponentById("btnFinish").setProperty("caption",this.lblFinish);
		this.isExit = 0;
		break;
	}
	zenPage.updateState();
}

/// Return true if at least one selection is made.
ClientMethod hasSelected() [ Language = javascript ]
{
	var selectedRows = this.getComponentById("table").selectedRows;
	var sel = selectedRows.split(",");
	var i;
	var found = false;
	for (i=0;i<sel.length;i++) {
		if (sel[i] != "") {
			found = true;
			break;
		}
	}
	return found
}

/// User checked a checkbox in a row in the table. Show the location and update Finish button.
ClientMethod rowChecked(table) [ Language = javascript ]
{
	zenPage.updateState();
}

/// Set the selected rows into %session data for the result page
/// Save all relevant values.
Method SetSelected(selectedRows As %String, FileName As %String, Host As %String, Port As %String, Classpaths As %String, Excludes As %String) As %Boolean [ ZenMethod ]
{
	Set %session.Data("DotNetGatewayWizard","SelectedRows") = selectedRows ///$LISTFROMSTRING(selectedRows,",")
	Set %session.Data("DotNetGatewayWizard","FileName") = FileName
	Set %session.Data("DotNetGatewayWizard","Host") = Host
	Set %session.Data("DotNetGatewayWizard","Port") = Port
	Set %session.Data("DotNetGatewayWizard","Classpaths") = Classpaths
	Set %session.Data("DotNetGatewayWizard","Excludes") = Excludes
	Set %session.Data("DotNetGatewayWizard","NAMESPACE") = $namespace
	Quit 1
}

/// Check if file user entered exists.
ClassMethod FileExists(filename) As %Boolean [ ZenMethod ]
{
	Quit ##class(%File).Exists(filename)
}

/// Check if server and port is running and responsive
ClassMethod CheckGateway(pServer, pPort) As %Boolean [ ZenMethod ]
{
	Quit ##class(%Net.Remote.Utility).CheckGateway(pServer,pPort)
}

}
