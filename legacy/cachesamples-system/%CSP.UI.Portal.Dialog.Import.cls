/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Import dialog for Management Portal
/// <p><b>Please do not modify any part of this dialog without COMPLETELY testing all cases!!!<br/>
/// This dialog is used by Classes/Routines/Globals for Namespaces and Classes/Routines for Databases.<br/>
/// Please be extremely careful!!! </b></p>
Class %CSP.UI.Portal.Dialog.Import Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.Import.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Import";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If greater than this size then show content will not be available.
Parameter CheckMaxSize = 10000000;

Property CHARSET As %String;

/// Type from where we get the selected items from: Class or Routine.
Property FILETYPE As %ZEN.Datatype.string(ZENURL = "FILETYPE");

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property FILEFLAG As %ZEN.Datatype.string;

Property INPUTTYPE As %ZEN.Datatype.string(ZENURL = "INPUTTYPE");

/// This is the temporary file name we saved on remote server, only saved when Input Type is LOCAL.
Property LOCALFILENAME As %ZEN.Datatype.string;

/// If this is 1 then file content will not be shown and entire file will be imported in the background.
Property IMPORTALL As %Boolean [ InitialExpression = "0" ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}
#htmlContent {
	width: 550px;	
}
/* Progress message style */
.progress { 
	color: green; 
	font-weight: bold;
}
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
/* style for import content table */
table.ContentTable	{ 
	font-family: Futura,Arial,sans-serif;
	border: 1px #cbcbcb solid;
}
table.ContentTable th { 
	font-size: 12px;
	font-weight: bold;		
	background:white; 
	color: #cbcbcb;
	text-align: center;
	padding: 0 2px 0 2px;
}
table.ContentTable tr.LiteRow { background: white; font-size: 11px;}
table.ContentTable tr.DarkRow { background: #F1F0E7; font-size: 11px;}
table.ContentTable td { padding-left:2px; padding-right:2px; font-size: 11px; }
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">

<html id="header" OnDrawContent="%DrawTitle" />
<form enctype="multipart/form-data" action="_CSP.UI.Portal.Dialog.Import.zen">
<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="98%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnBack" controlClass="commandButton" caption="Back" onclick="zenPage.previousPage();" hidden="true"/>
<spacer width="5" />
<button id="btnNext" controlClass="commandButton" caption="Next" onclick="zenPage.nextPage();"/>
<submit id="btnSubmit" controlClass="commandButtonDisabled" caption="Next" hidden="true" disabled="true"/>
<spacer width="15" />
<button id="btnFinish" controlClass="commandButtonDisabled" caption="Import" onclick="zenPage.doImport();" disabled="true"/>
<spacer width="5" />
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnDone" controlClass="commandButton" caption="Done" onclick="zenPage.dialogFinish();" hidden="true" />
</hgroup>
</hgroup>
</form>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" hidden="true"/>
<tabGroup id="tabGroup">

<!-- First Page -->
<tab id="tab1" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;">
 <html OnDrawContent="DrawPageTitle" seed="1"/>
 
 <radioSet id="InputType" name="InputType" label="The import file resides on" valueList="REMOTE,LOCAL" 
 onclick="zenPage.doLocationChange(zenThis.getValue());" value="REMOTE"/>
 
 <radioSet id="ImportType" label="Import from a File or a Directory:" labelClass="zenLabel" 
 valueList="FILE,DIR" displayList="File,Directory" value="FILE" 
 captionClass="normal"
 onchange="zenPage.changedImportType(zenThis);"/>
<hgroup id="idRemoteFile" cellVAlign="bottom" enclosingStyle="padding-top:10px;" >
<text id="FileName" size="68" label="Enter the path and name of the import file:"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName');"/>
</hgroup>
<fileUpload id="LocalFile" name="File" label="Select the path and name of the import file:" size="70" hidden="true" onchange="zenPage.selectLocalFile();"/>

<hgroup labelPosition="left">
<select id="Charset" label="Character set" showEmpty="false" hidden="true"/>
</hgroup>
<vgroup cellVAlign="bottom" enclosingStyle="padding-top:10px;">
<checkbox id="chkRecurse" caption="Include subdirectories" captionClass="zenLabel" value="1" hidden="true"/>
<hgroup id="idCompile" labelPosition="left">
<checkbox id="chkCompile" name="chkCompile" caption="Compile imported items" captionClass="zenLabel" value="1"/>
<text id="txtCompile" name="txtCompile" label=" -- Compile flags" labelClass="normal" value="cuk" />
</hgroup>
<checkbox id="chkBackground" name="chkBackground" caption="Run import in the background" captionClass="zenLabel" hint=" (Highly recommended for importing large files.)"/>
</vgroup>
</tab>

<tab id="tab2" enclosingStyle="padding-top:10px;" cellStyle="padding-bottom:10px;">
<html OnDrawContent="DrawPageTitle" seed="2"/>
<html id="htmlContent" OnDrawContent="DrawContent" seed="" onrefresh="zenPage.drawDone(2);"/>
<label id="idProgress2" label="Loading File Content..." labelClass="progress"/>
</tab>

<tab id="tab3">
<html OnDrawContent="DrawPageTitle" seed="3"/>
<iframe id="output"/>
</tab>
</tabGroup>
</pane>
}

ClientMethod selectLocalFile() [ Language = javascript ]
{
	var fileName = zen("LocalFile").getValue();
	zen("btnSubmit").setDisabled(fileName=="");
	if (fileName!="") {
		zen("btnSubmit").setProperty('controlClass','commandButton');
	} else {
		zen("btnSubmit").setProperty('controlClass','commandButtonDisabled');
	}
}

ClientMethod changedImportType(thisObj) [ Language = javascript ]
{
	this.resetMsg();
	var type = thisObj.getValue();
	var hasText = 0;
	if (type == "FILE") {
		var label = $$$Text("Enter the path and name of the import file:");
		zen("chkRecurse").setHidden(true);
		zen("btnFinish").setProperty('disabled',true);
		zen("btnFinish").setProperty('controlClass','commandButtonDisabled');
		zen("btnNext").setProperty('disabled',false);
		zen("btnNext").setProperty('controlClass','commandButton');                                                                                                                       
	} else {
		var label = $$$Text("Enter the directory where all XML files will be imported from:");
		zen("chkRecurse").setHidden(false);
		zen("chkBackground").setValue(1);
		//zen("chkBackground").setDisabled(true);
		zen("btnNext").setProperty('disabled',true);
		zen("btnNext").setProperty('controlClass','commandButtonDisabled');
		zen("btnFinish").setProperty('disabled',false);
		zen("btnFinish").setProperty('controlClass','commandButton');

	}
	zen("FileName").setProperty("label",label);
	zen("FileName").focus();
}

/// User changed to pick file between Remote and Local
ClientMethod doLocationChange(flag) [ Language = javascript ]
{
	if (flag == "LOCAL") {
		zen("idRemoteFile").setHidden(true);
		zen("LocalFile").setHidden(false);
		// for local we cannot allow for Directory
		zen("ImportType").setValue("FILE");
		zen("ImportType").setDisabled(true);
		// show Submit button
		zen("btnNext").setHidden(true);
		zen("btnSubmit").setHidden(false);
	} else {
		zen("idRemoteFile").setHidden(false);
		zen("LocalFile").setHidden(true);
		zen("ImportType").setDisabled(false);
		zen("btnNext").setHidden(false);
		zen("btnSubmit").setHidden(true);
		var FileName = zen("FileName").getValue()
		if (zen("FileName").getValue() != "") {
			zen("btnNext").setProperty('disabled',FileName=="");
			zen("btnNext").setProperty('controlClass', (FileName!="" ? 'commandButton' :'commandButtonDisabled'));			
		}
	}
}

/// Start the Import
ClientMethod doImport() [ Language = javascript ]
{
	this.resetMsg();
	var filename = zen("FileName").getValue();
	var inputtype = "REMOTE"
	if (this.LOCALFILENAME != "") {
		filename = this.LOCALFILENAME;
		inputtype = "LOCAL";
	}
	var importtype = zen("ImportType").getValue();
	// check if user selected any item from Content if import type is File
	if (importtype == "FILE" && !this.IMPORTALL) {
		var selectedRows = this.getSelected();
		if (selectedRows == -1) return;
		var ok = this.PrepareAction(this.FILETYPE,selectedRows);
		if (ok == false) {
			this.showMsg($$$Text("There are no items selected for import."),1);
			return;
		}
	} else {
		var ok = this.ValidateFile(this.FILETYPE,importtype,filename);
		if (ok == 0) {
			this.showMsg($$$Text("Directory is empty."),1);	
			zen("FileName").focus();
			return;
		}
		if (ok == -1) {
			this.showMsg($$$Text("File cannot be imported."),1); 
			zen("FileName").focus();
			return;	
		}		
	}
	filename = encodeURIComponent(filename);
	var charset = zen("Charset").getValue();
	var background = (zen("chkBackground").getValue()==true) ? 1 : 0;
	var tabGroup = zen('tabGroup');
	tabGroup.showTab(3);
	var namespace = encodeURIComponent(this.NAMESPACE);
	var chkCompile = zen("chkCompile").getValue();
	if (chkCompile) {
		var compileflags = zen("txtCompile").getValue();
		if (compileflags == "") compileflags = "c";
	} else {
		var compileflags = "";
	}
	var chkRecurse = (zen("chkRecurse").getValue()) ? 1 : 0;
	var param = '_CSP.UI.Portal.Dialog.ImportOutput.zen?FILETYPE='+this.FILETYPE + '&FILENAME=' + filename 
	+ '&IMPORTTYPE=' + importtype + '&COMPILEFLAGS=' + compileflags + '&RECURSE=' + chkRecurse + '&IMPORTALL=' + this.IMPORTALL
	+ '&NAMESPACE=' + namespace + '&RUNBACKGROUND=' + background + '&INPUTTYPE=' + inputtype + '&CHARSET=' + charset;
	zen('output').setProperty('src',zenLink(param));
	zen("btnFinish").setProperty('disabled',true);
	zen("btnFinish").setProperty('controlClass','commandButtonDisabled');
	zen("btnCancel").setHidden(true);
	zen("btnDone").setHidden(false);
	zenPage.updateState();
}

/// Update the state of the template buttons.
/// Subclasses should call this method when they need to 
/// update the state of the footer buttons.
ClientMethod updateState() [ Language = javascript ]
{
	var btnBack = zen('btnBack');
	var btnNext = zen('btnNext');
	var btnFinish = zen('btnFinish');
	var btnHelp = zen('btnHelp');
	var btnSubmit = zen('btnSubmit');
	var multi = this.hasMultiplePages();

	if (btnBack) {
		btnBack.setProperty('hidden',!multi);
		btnBack.setProperty('disabled',!this.canGoBack());
		btnBack.setProperty('controlClass',	(this.canGoBack() ? 'commandButton' :'commandButtonDisabled'));
	}
	if (btnNext) {
		btnNext.setProperty('hidden',!multi);
		btnNext.setProperty('disabled',!this.canGoNext());
		btnNext.setProperty('controlClass',	(this.canGoNext() ? 'commandButton' :'commandButtonDisabled'));
	}
	// special for Import on this page. Hide regular Next and show Submit Next for LOCAL.
	if (zen("InputType").getValue()=="LOCAL") {
		btnSubmit.setProperty('disabled',true);
		btnSubmit.setProperty('controlClass', 'commandButtonDisabled');
		btnNext.setProperty('hidden',true);
	} else {
		btnNext.setProperty('hidden',false);
	}
	if (btnFinish) {
		btnFinish.setProperty('disabled',!this.canFinish());
		btnFinish.setProperty('controlClass', (this.canFinish() ? 'commandButton' :'commandButtonDisabled'));
		
	}
	if (btnHelp) {
		btnHelp.setProperty('disabled',(''==this.helpId));
		btnHelp.setProperty('controlClass',	(this.helpId != '' ? 'commandButton' :'commandButtonDisabled'));
	}
}

/// This method is fired up after onDrawContent is finished. Hide progress message and display error if exists.
ClientMethod drawDone(tab) [ Language = javascript ]
{
	var result = this.GetStatus(tab,this.FILETYPE);
	var id = "idProgress"+tab;
	this.IMPORTALL = 0;
	if (result.Status == "Done") {
		if (result.Error != "") {
			this.showMsg(result.Error);
			zen("btnFinish").setProperty('disabled',true);
			zen("btnFinish").setProperty('controlClass','commandButtonDisabled');
		}
	} else if (result.Status == "IMPORTALL") {
		zen("chkBackground").setValue(1);
		this.IMPORTALL = 1;
	} else {
		//var error = $$$Text("Unexpected error occurred. Loading did not finish as expected.");
		//this.showMsg(error);
		zen("btnNext").setProperty('disabled',true);
		zen("btnNext").setProperty('controlClass','commandButtonDisabled');
	}
	zen(id).setHidden(true);
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var importtype = zen("ImportType").getValue();	
	var flag = false;
	switch(tabNo) {
	case 1:
		if (importtype == "FILE") flag = true;
		if (this.INPUTTYPE == "LOCAL") flag = false;
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
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var importtype = zen("ImportType").getValue();	
	var flag = true;
	switch(tabNo) {
	case 1:
		flag = false;
		break;
	case 2:
		break;
	case 3:
		if (importtype == "DIR") {
			zen("btnBack").setProperty('hidden',false);
		}
		break;
	}	
	return flag
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
ClientMethod canFinish() [ Language = javascript ]
{
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var importtype = zen("ImportType").getValue();	
	var flag = false;
	switch(tabNo) {
	case 1:
		if (importtype == "DIR") flag = true;
		break;
	case 2:
		flag = true;
		break;
	case 3:
		break;
	case 4:
		break;
	}	
	//zen("btnCancel").setDisabled(false);	
	
	return flag;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	this.resetMsg();
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var ImportType = zen("ImportType").getValue();
	switch(tabNo) {
	case 1:
		var FileName = zen("FileName").getValue();
		var ok = this.ValidateFile(this.FILETYPE,ImportType,FileName);
		if (ok == 0) {
			this.showMsg($$$Text("File name is empty."),1);	
			zen("FileName").focus();
			break;
		}
		if (ok == -1) {
			// File does not exist or in restricted directory
			this.showMsg($$$Text("File cannot be imported."),1);
			zen("FileName").focus();
			break;		
		}
		if (ImportType == "FILE") {
			this.CHARSET = zen("Charset").getValue();
			var html = zen("htmlContent");
			html.setProperty('seed',FileName);
			tabGroup.showNextTab();
		} else {
			tabGroup.showTab(3);
		}
		break;
	case 2:
		tabGroup.showNextTab();
		break;
	case 3:
		break;
	}
	zenPage.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
	//this.resetMsg();	
	var tabGroup = zen('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		break;
	case 2:
		tabGroup.showPreviousTab();
		this.resetMsg();
		zenPage.updateState();
		if (zen("InputType").getValue()=="LOCAL") {
			zen('btnNext').setProperty('hidden',true);
		}
		break;
	case 3:
		if (zen("ImportType").getValue() == "FILE") tabGroup.showPreviousTab();
		else tabGroup.showTab(1);
		zenPage.updateState();
		break;
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

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.InvalidParam) {
		zen("btnNext").setHidden(true);	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("output");
	var wd = zenGetWindowWidth() - 80;
	var ht = zenGetWindowHeight() - 210;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// User clicked the Browse button.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	var wildcard = this.FILEFLAG;
	var Dir = zen(name).getValue();
	var showdirectoryonly = (zen("ImportType").getValue()=="DIR" ? 1 : 0);
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard+'&showdirectoryonly='+showdirectoryonly),'FileSelect','resizable,width=680,height=750');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("FileName").setValue(value);
		zenPage.updateState();	
	}
}

/// This is called when the template is first displayed;
/// This provides a chance to load the last filetype, etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	this.changedImportType(zen("ImportType"));
	this.onresizeHandler();
	// if this is from the submit of the Local file, load the content of the file on tab 2.
	if (this.INPUTTYPE == "LOCAL") {
		// set the first tab for LOCAL correctly
		this.doLocationChange("LOCAL");		
		if (this.LOCALFILENAME != "") {
			var html = zen("htmlContent");
			html.setProperty('seed',this.LOCALFILENAME);
			var tabGroup = zen('tabGroup');
			var tabNo = tabGroup.getCurrTabNo();
			if (tabNo == 1) {
				tabGroup.showNextTab();
			}
			zenPage.updateState();
		} 
		zen("btnNext").setHidden(true);
	}
}

ClientMethod getSelected() [ Language = javascript ]
{
	var cb;
	if (!document.getElementById("TotalRows")) return -1;
	var TotalRows = document.getElementById("TotalRows").value;
	var selectedRows = "";
	var dim = ",";
	if (this.FILETYPE == "Global") dim = "";
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		if (cb.checked == true) {
			selectedRows = selectedRows + cb.value + dim;
		}
	}
	return selectedRows;
}

ClientMethod toggleCheckboxes(cbState) [ Language = javascript ]
{
	var cb;
	var TotalRows = document.getElementById("TotalRows").value;
	for (var i = 1; i <= TotalRows; i++) {
		cb = self.document.getElementById("cb_"+i);
		cb.checked = cbState;
	}
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If ..FILETYPE = "Class" {
		Quit $$$TextHTML("Import Classes")	
	} ElseIf ..FILETYPE = "Routine" {
		Quit $$$TextHTML("Import Routines")
	} ElseIf ..FILETYPE = "Global" {
		Quit $$$TextHTML("Import Globals")
	}
	Set ..InvalidParam = 1
	Quit $$$TextHTML("Undefined Type")
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
	
	// try and determine if user is on *same* machine as server
	// if so, do not provide local upload option
	Set tTCPAddr = $SYSTEM.TCPDevice.PeerAddr(0)
	Set tClientAddr = $G(%request.CgiEnvs("REMOTE_ADDR"))
	Set tIsLocal = ((tClientAddr = "127.0.0.1") ! (tClientAddr = "::1")) & ((tTCPAddr = "127.0.0.1") ! (tTCPAddr = "::1"))
	If tIsLocal {
		Set ..%GetComponentById("InputType").hidden = 1
		Set ..%GetComponentById("LocalFile").hidden = 1
	}
	Set ImportType = $G(%session.Data($Username,%page.FILETYPE,"Import"),"FILE")
	Set FileName = ""	
	Set %page.FILEFLAG = $Case(%page.FILETYPE,"Global":"*.go;*.gsa;*.gbl;*.gof","Routine":"*.ro;*.rsa;*.rtn;*.mac",:"*.xml")
	Set LastSaveFile = $ZCVT($ZCVT(%request.GetCookie("LastFile"_%page.FILETYPE),"I","URL"),"I","UTF8")
	If LastSaveFile = "" Set LastSaveFile = $G($$$IRISTempMgt($UserName,"LastFile",%page.FILETYPE,ImportType))
	#; If this is the first time use, default it to manager directory, without the file name, so that use will not get "File does not exit" error if they hit Import.
	If LastSaveFile = "",FileName = "" Set FileName = $zu(12)
	If LastSaveFile '= "",FileName = "" Set FileName = LastSaveFile
	Set ..%GetComponentById("ImportType").value = ImportType
	Set ..%GetComponentById("FileName").value = FileName
	Set ..%GetComponentById("Charset").value = ""
	#; Set for Remote input types choice: ServerName or local machine
	Set ..%GetComponentById("InputType").displayList = $zu(110)_","_$$$Text("My Local Machine")
	If %page.FILETYPE '= "Class" {
		#; Set Charset
		Set CharList = $$GetIONames^%SYS.NLS(.DefCharList,1)
		Set valueList = ""
		For tc = 1:1:$L(CharList,",") Set tint = $P(CharList,",",tc) Quit:tint=""  Set valueList = valueList_","_tint
		Set displayList = valueList
		Set $P(displayList,",",1) = "<"_$$$Text("Device Default")_">"
		Set ..%GetComponentById("Charset").valueList = valueList
		Set ..%GetComponentById("Charset").displayList = displayList
		Set ..%GetComponentById("Charset").hidden = 0
		Set ..%GetComponentById("ImportType").hidden = 1
		If %page.FILETYPE = "Global" Set ..%GetComponentById("idCompile").hidden = 1
	}
	If $G(%request.Data("INPUTTYPE",1)) = "LOCAL" {
		Set %page.LOCALFILENAME = $G(%session.Data($Username,%page.FILETYPE,"Import","LOCALFileName"))
		Set ..%GetComponentById("InputType").value = "LOCAL"
		set ..%GetComponentById("chkCompile").value = +$G(%request.Data("chkCompile",1))
		set ..%GetComponentById("txtCompile").value = $G(%request.Data("txtCompile",1))
		set ..%GetComponentById("chkBackground").value = +$G(%request.Data("chkBackground",1))
	}
	Set %session.Data($Username,"Import","LastFileType") = %page.FILETYPE
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set espNamespace = ..EscapeHTML(%page.NAMESPACE)
	Set tPageTitle = ""	
	If pSeed = 1 {
		If %page.FILETYPE = "Class" Set tPageTitle = $$$FormatText($$$Text("Import classes to namespace %1."),espNamespace)_"<br/>"
		Else  If %page.FILETYPE = "Routine" Set tPageTitle = $$$FormatText($$$Text("Import routines to namespace %1."),espNamespace)_"<br/>"
		Else  If %page.FILETYPE = "Global" Set tPageTitle = $$$FormatText($$$Text("Import globals to namespace %1."),espNamespace)_"<br/>"
	} ElseIf pSeed = 2 {
		Set tPageTitle = $$$TextHTML("Select items you wish to import.")
	} Else {
		Set tPageTitle = $$$TextHTML("Import result:")
	}
	&html<<div class="Description">#(tPageTitle)#
	</div><hr size="1"/>>
	Quit 1
}

/// FILTTYPE=Class/Routine/Global, ImportType=FILE/DIR
ClassMethod SaveSelection(FILETYPE, ImportType, FileName) [ ZenMethod ]
{
	Set %session.Data($Username,FILETYPE,"Import") = ImportType
	Set $$$IRISTempMgt($UserName,"LastFile",FILETYPE,ImportType) = FileName
}

/// Draw content of the import file for user to select from.
/// For Global, check size and type. Do not show file content for Sequential file larger than 10MB.
ClassMethod DrawContent(pSeed) As %Status
{
	Set tSC = $$$OK
	Quit:pSeed="" tSC
	Set FileName = pSeed
	Set %session.Data($Username,%page.FILETYPE,"Import","ContentStatus") = ""
	Set %session.Data($Username,%page.FILETYPE,"Import","ContentError") = ""
	Set Filesize = ##class(%File).GetFileSize(FileName)
	If FileName = "" {
		Set tErr = $$$TextHTML("File name is empty!")
		Set %session.Data($Username,%page.FILETYPE,"Import","ContentError") = tErr
		Set %session.Data($Username,%page.FILETYPE,"Import","ContentStatus") = "Done"
		Quit tSC
	}
	#; If user did not put in file but a directory, return error message
	If ##class(%File).DirectoryExists(FileName) || ##class(%File).Exists(FileName) = 0 {
		Set %session.Data($Username,%page.FILETYPE,"Import","ContentError") = $$$Text("File does not exist!")
		Set %session.Data($Username,%page.FILETYPE,"Import","ContentStatus") = "Done"
		Quit tSC
	}
	If %page.FILETYPE = "Global" {
		// Find out if this is GO or GOF format file
		Set format = $$filefmt^%SYS.Wgr(FileName)
		If Filesize > ..#CheckMaxSize {
			&html<
				<div class="zenLabel">#($$$TextHTML("The content list is not available for file size greater than 10MB."))#</div><br/>
				<div class="normal">#($$$FormatText($$$Text("Import will be run in the background for file %1."),..EscapeHTML(FileName)))#</div>
			>
			Set %session.Data($Username,%page.FILETYPE,"Import","ContentStatus") = "IMPORTALL"
			Quit $$$OK
		}
	}
	Set msgNothing = $$$TextHTML("Nothing found.")
	Set msgNo = $$$TextHTML("No")
	Set msgYes = $$$TextHTML("Yes")
	Set Column(0) = $$$TextHTML("Click to select or unselect all")
	Set Column(1) = $$$TextHTML("Item")
	Set Column(2) = $$$TextHTML("Exists")
	Set Column(3) = $$$TextHTML("Last Modified")
	Set Charset = %page.CHARSET
	Set tRow = 0
	Set tRS = ##class(%ResultSet).%New("%RoutineMgr:ImportItemList")
	Set tSC = tRS.Execute(FileName,Charset,.Description)
	If $$$ISERR(tSC) Set msgNothing = $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	If $G(Description) '= "" &html<<div class="normal">#($$$TextHTML("Description: "))##($ZCVT(Description,"O","HTML"))#</div>>
	&html<<table class="ContentTable" border="1" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">>
	&html<<tr><th><input type="checkbox" id="chkAll" title="#(Column(0))#" checked onclick="javascript:zenPage.toggleCheckboxes(this.checked);"></th>
	<th nowrap>#(Column(1))#</th><th nowrap>#(Column(2))#</th><th nowrap>#(Column(3))#</th></tr>>
	While tRS.Next() {
		Set tRow = tRow + 1
		Set tId = "cb_"_tRow
		Set tName = tRS.GetData(1)
		Set tTime = tRS.GetData(2)
		If %page.FILETYPE = "Global",$E(tName)'="^" Set tName = "^"_tName
		Set tExist = $S(tTime=-1:msgNo,1:msgYes)
		If tTime = -1!(tTime="") Set tTime = "&nbsp;"
		&html<<tr class="#($S(tExist=msgNo:"LiteRow",1:"DarkRow"))#">
		<td><input type="checkbox" name="#(tId)#" id="#(tId)#" value='#($ZCVT(tName,"O","HTML"))#' checked/>
		<td nowrap>#($ZCVT(tName,"O","HTML"))#</td>>
		&html<<td nowrap>#($ZCVT(tExist,"O","HTML"))#</td>>
		&html<<td nowrap>#(tTime)#</td></tr>>
	}
	If tRow = 0 &html<<tr><td colspan="4">#(msgNothing)#</td></tr>>
	Else  &html<<tr><td colspan="4">#($$$FormatText($$$Text("Total: %1"),tRow))#</td></tr>>
	&html<</table><input type="hidden" id="TotalRows" value="#(tRow)#">>
	Set %session.Data($Username,%page.FILETYPE,"Import","ContentStatus") = "Done"
	Quit tSC
}

/// tab = 2: Content - when DrawContent is finished, Status is "Done".
ClassMethod GetStatus(tab, FILETYPE) As %ZEN.proxyObject [ ZenMethod ]
{
	Set proxy = ##class(%ZEN.proxyObject).%New()
	Set proxy.Status = $G(%session.Data($Username,FILETYPE,"Import","ContentStatus"))
	Set proxy.Error = $G(%session.Data($Username,FILETYPE,"Import","ContentError"))
	Quit proxy
}

/// Validate file name. If ImportType is DIR then check if directory exists.
ClassMethod ValidateFile(FILETYPE, ImportType, FILE) As %Integer [ ZenMethod ]
{
	If $ZStrip(FILE,"<>W") = "" Quit 0
	If ImportType = "DIR" {
		#; Directory does not exist!
		If '##class(%File).DirectoryExists(FILE) Quit -1
		#; Directory is restricted and not allowed
		If '##class(%CSP.Portal.Utils).IsDirectoryAllowed(FILE) Quit -1
	} Else {
		#; Entered directory only!
		If ##class(%File).DirectoryExists(FILE) Quit -1
		#; File does not exist!"
		If '##class(%File).Exists(FILE) Quit -1
		#; File in a restricted directory and not allowed
		Set dir = ##class(%File).GetDirectory(FILE)
		If '##class(%CSP.Portal.Utils).IsDirectoryAllowed(dir) Quit -1
	}
	Do ..SaveSelection(FILETYPE, ImportType, FILE)
	Quit 1
}

ClassMethod PrepareAction(filetype, selectedRows) As %String [ ZenMethod ]
{
	Quit ##class(%CSP.UI.Template.List).PrepareAction(filetype,selectedRows)
}

/// This method is invoked only when user selects to import from Local Machine.<br/>
/// The necessary parameters are passed in URL. The temp file name is saved in %session and to be used in loading content.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Set FILETYPE = %session.Data($Username,"Import","LastFileType")
	Set tStream = pSubmit.%GetStream("File")
	Set dir = ##class(%File).SubDirectoryName($zu(12),"Temp")
	#; If temp directory does not exist, create it now
	If ##class(%File).DirectoryExists(dir) = 0 {
		Do ##class(%File).CreateDirectory(dir)
	}
	#; Get proper delimeter since SubDirectoryName does not include delimeter
	Set tDelim = "\"
	If $$$isUNIX Set tDelim = "/"
	If $$$isVMS Set tDelim = ""
	#; Give it a name so it won't be deleted automatically
	Set DirFileName = dir_tDelim_"importfromlocal.stream"
	Set file = ##class(%Stream.FileBinary).%New()
	Set tSC = file.LinkToFile(DirFileName)
	If tStream '= "" {
		#; Copy the stream from local server
		Set tSC = file.CopyFrom(tStream)
		#; Save it to the file stream on the remote server
		If tSC Set tSC = file.%Save()
	}
	Set %response.Context("FILETYPE") = FILETYPE
	Set %response.Context("$NAMESPACE") = $namespace
	Set %response.Context("INPUTTYPE") = "LOCAL"
	//  remember popup info
	Set %response.Context("$ZEN_POPUP") = 1
	Set %response.Context("$ZEN_POPUPPARENT") = +$G(%request.Data("$ZEN_POPUPPARENT",1))
	Set %response.Context("$ZEN_SOFTMODAL") = ..%OnUseSoftModals()
	
	Set %response.Context("chkCompile") = +$G(%request.Data("$V_chkCompile",1))
	Set %response.Context("txtCompile") = $G(%request.Data("$V_txtCompile",1))
	Set %response.Context("chkBackground") = +$G(%request.Data("$V_chkBackground",1))
	
	//  save the temp local file name to be used in later to load content
	Set %session.Data($Username,FILETYPE,"Import","LOCALFileName") = DirFileName

	Quit tSC
}

}
