/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// Wizard to help you import a class file or a jar file from Java and create a set of corresponding classes.
Class %ZEN.Template.ObjectGatewayWizard.JavaHome Extends %ZEN.Template.ObjectGatewayWizard.Template [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Java Gateway Wizard";

Parameter TEMPLATETITLE = "Java Gateway Wizard";

Parameter TEMPLATEDESCRIPTION = "Import a class file or a jar file from Java.";

/// Display title of this page <title></title>
Parameter PAGETITLE = "Java Gateway Wizard";

Parameter HELPID = "EJVG_instructions_wizard";

Property lblFile1 As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Enter the path and name of the Jar file:")} ];

Property lblFile2 As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Enter a fully qualified class name:")} ];

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
.rednote {
	color: #da4848;
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
<label id="idRespond" label="Gateway did not respond!" labelClass="rednote" containerStyle="padding-top:10px;" hidden="true"/>
<tabGroup id="tabGroup">
<tab>
<vgroup labelPosition="top" containerStyle="padding:20px;" label="This wizard will help you import a class file or a jar file from Java and create a set of corresponding classes." labelClass="caption"
 enclosingStyle="padding-top:20px;" cellStyle="padding-bottom:10px;">
<radioSet id="FileType" label="Select a .jar file or fully qualified class name:" labelClass="zenRequired" valueList="j,c" displayList="Jar File,Class Name" value="j" captionClass="normal"
containerStyle="padding-bottom:4px;"
 onchange="zenPage.changedFileType(zenThis);"/>
<hgroup id="idFileName" label="Enter the path and name of a Jar file:" labelClass="zenRequired" cellVAlign="top" >
 <text id="FileName" showLabel="false" size="80" required="true"
 value="" onchange="zenPage.updateState();"
 hint="Required." hintClass="helpText"
  />
  <button id="btnBrowse" caption="Browse" onclick="zenPage.doBrowse();"/>
</hgroup>
<text id="Host" label="Java Gateway server name / IP address:" labelClass="zenRequired" size="20" value="127.0.0.1"
hint="Required." hintClass="helpText" onchange="zenPage.updateState();" required="true"
/>
<text id="Port" label="Java Gateway server port:" labelClass="zenRequired" size="20" value="55555"
hint="Required." hintClass="helpText" onchange="zenPage.updateState();" required="true"
/>
<text id="Classpaths" label="Additional classpaths to be used in finding dependent classes:" labelClass="normal" size="80"
hint="Specify a list of jar files or directories, separated by semi-colons." hintClass="helpText"
/>
<text id="Excludes" label="Exclude dependent classes matching the following prefixes:" labelClass="normal" size="80"
hint="Specify a list of package and class name prefixes, separated by semi-colons." hintClass="helpText"
/>
</vgroup>
</tab>
<tab>
<vgroup id="idTable" labelPosition="top" containerStyle="padding:20px;" 
label="The Java Gateway Wizard has determined that your jar file contains the following Java classes:" 
labelClass="caption">

<tablePane id="table" label="(Check the top checkbox to select/unselect all classes)"
queryClass="%Net.Remote.Utility"
queryName="GetAllClasses"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="30000"
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

/// User changed file type. Change label.
ClientMethod changedFileType(thisObj) [ Language = javascript ]
{
	var idName;
	var type = thisObj.getValue();
	var flag = true;
	type == "j" ? idName = this.lblFile1 : idName = this.lblFile2;
	if (type == "j") flag = false;
	zenPage.getComponentById("idFileName").setProperty("label",idName);
	zenPage.getComponentById("btnNext").setDisabled(flag);
}

/// Launching a file selector window. 
ClientMethod doBrowse() [ Language = javascript ]
{
	var FileType = zenPage.getComponentById("FileType").getValue();
	var Dir = zenPage.getComponentById("FileName").getValue();
	var wildcard = "*.jar";
	if (FileType == "c") wildcard = "*.class";
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
	// Pending for a server method to check if a production is running. If not, give message.
	Set FileType = $G(%session.Data("JavaGatewayWizard","FileType"))
	If FileType '= "" {
		Set ..%GetComponentById("FileType").value = FileType
		Set ..%GetComponentById("FileName").value = $G(%session.Data("JavaGatewayWizard","FileName",FileType))
		Set ..%GetComponentById("Host").value = $G(%session.Data("JavaGatewayWizard","Host"))
		Set ..%GetComponentById("Port").value = $G(%session.Data("JavaGatewayWizard","Port"))
		Set ..%GetComponentById("Classpaths").value = $G(%session.Data("JavaGatewayWizard","Classpaths"))
		Set ..%GetComponentById("Excludes").value = $G(%session.Data("JavaGatewayWizard","Excludes"))
	}	
	Quit $$$OK
}

/// This method is called when the template is complete.
/// It adds classes to the project, allows classes to be added to source control, and cleans up some session data
Method %OnTemplateAction() As %Status
{
	Set cls = $O(%session.Data("JavaGatewayWizard","ClassList",""))
	While cls'="" {
		Do ..%AddToProject(cls _ ".cls")
		Do ..%AddToSourceControl(cls _ ".cls")
		Set cls = $O(%session.Data("JavaGatewayWizard","ClassList",cls))
	}
	Kill %session.Data("JavaGatewayWizard","ClassList")
	Kill %session.Data("JavaGatewayWizard","SelectedRows")
	Kill %session.Data("JavaGatewayWizard","NAMESPACE")
	
	Quit 1
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var FileType = zenPage.getComponentById("FileType").getValue();
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	//var proxy = this.getClassName();
	var flag = false;
	switch(tabNo) {
	case 1:
		if (FileType == "j") flag = true;
		if (!this.formValidationHandler()) {
			var id = zenPage.getComponentById("firstFailed").getValue();
			if (id != "") zenPage.getComponentById(id).focus();
			flag = false;
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
		var FileType = zenPage.getComponentById("FileType").getValue();
		var Classpaths = zenPage.getComponentById("Classpaths").getValue();
		var Excludes = zenPage.getComponentById("Excludes").getValue();
		var tabGroup = zenPage.getComponentById('tabGroup');
		var tabNo = tabGroup.getCurrTabNo();
		this.lastTab = tabNo;
		var table = zenPage.getComponentById('table');
		// if user clicked Finish on tab 1 then import the .jar file; ow import selected classes.
		var selectedRows = "";
		if (tabNo == 2) selectedRows = table.selectedRows;
		var ok = this.SetSelected(selectedRows,FileType,FileName,Host,Port,Classpaths,Excludes)
		var iframe = zenPage.getComponentById('iframe');
		zenPage.getComponentById('tabGroup').showTab(3);
		iframe.setProperty("src","%25ZEN.Template.ObjectGatewayWizard.JavaDone.cls");
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
			var table = zenPage.getComponentById('table');
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
Method SetSelected(selectedRows As %String, FileType As %String = "j", FileName As %String, Host As %String, Port As %String, Classpaths As %String, Excludes As %String) As %Boolean [ ZenMethod ]
{
	Set %session.Data("JavaGatewayWizard","SelectedRows") = selectedRows ///$LISTFROMSTRING(selectedRows,",")
	Set %session.Data("JavaGatewayWizard","FileType") = FileType
	Set %session.Data("JavaGatewayWizard","FileName",FileType) = FileName
	Set %session.Data("JavaGatewayWizard","Host") = Host
	Set %session.Data("JavaGatewayWizard","Port") = Port
	Set %session.Data("JavaGatewayWizard","Classpaths") = Classpaths
	Set %session.Data("JavaGatewayWizard","Excludes") = Excludes
	Set %session.Data("JavaGatewayWizard","NAMESPACE") = $namespace

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

/// Return false from this method to disable this template (for example based on the server platform)
ClassMethod IsEnabled() As %Boolean
{
	Quit ##class(%Library.EnsembleMgr).IsEnsembleInstalled()
}

}
