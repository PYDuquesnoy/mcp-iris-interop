/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Import SQL Statement dialog for Management Portal SQL.
/// <p><b>Please do not modify any part of this dialog without COMPLETELY testing all cases!!!<br/>
/// This dialog is used by SQL for importing single SQL statement or all statements per namespace.<br/>
/// </b></p>
Class %CSP.UI.Portal.SQL.ImportStatement Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.ImportStatement.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "ImportSQLStatement";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property FILETYPE As %ZEN.Datatype.string [ InitialExpression = "SQLSTATEMENT" ];

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property INPUTTYPE As %ZEN.Datatype.string(ZENURL = "INPUTTYPE");

/// This is the temporary file name we saved on remote server, only saved when Input Type is LOCAL.
Property LOCALFILENAME As %ZEN.Datatype.string(ZENURL = "LOCALFILENAME");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#output iframe {
	background: white;
	font-family: "courier new";
	overflow: auto;
}
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
<form enctype="multipart/form-data" action="_CSP.UI.Portal.SQL.ImportStatement.zen">
<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Import" onclick="zenPage.doImport();"/>
<spacer width="5" />
<submit id="btnSubmit" controlClass="commandButton" caption="Import Local" hidden="true"/>
</hgroup>
</hgroup>
</form>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" value=""/>
<html OnDrawContent="DrawPageTitle" seed=""/>

 <radioSet id="InputType" name="InputType" label="The import file resides on" valueList="REMOTE,LOCAL" 
 onclick="zenPage.doLocationChange(zenThis.getValue());" value="REMOTE"/>

<hgroup id="idRemoteFile" cellVAlign="bottom" enclosingStyle="padding-top:10px;" >
<text id="FileName" size="70" label="Enter the path and name of the import file:"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.xml');"/>
</hgroup>
<fileUpload id="LocalFile" name="File" label="Select the path and name of the import file:" size="70" hidden="true" onchange="zenPage.selectLocalFile();"/>
<label id="hintFile" value="File name is empty. Please select a local file to import." enclosingClass="rednote" hidden="true"/>
<html><hr size="1"/></html>
<checkbox id="chkBackground" name="chkBackground" caption="Run import in the background" captionClass="zenLabel" hint=" (Highly recommended for importing statements.)"/>
<iframe id="output"/>
</pane>
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

ClientMethod selectLocalFile() [ Language = javascript ]
{
	var filename = zen("LocalFile").getValue();
	/// save the final filename for the output to pickup.
	//this.SaveLastFile(filename,this.FILETYPE);
	zen("btnSubmit").setDisabled(filename=="");
	if (filename!="") {
		zen("btnSubmit").setProperty('controlClass','commandButton');
	} else {
		zen("btnSubmit").setProperty('controlClass','commandButtonDisabled');
	}
}

/// User changed to pick file between Remote and Local
ClientMethod doLocationChange(flag) [ Language = javascript ]
{
	if (flag == "LOCAL") {
		zen("idRemoteFile").setHidden(true);
		zen("LocalFile").setHidden(false);
		zen("btnFinish").setHidden(true);
		zen("btnSubmit").setHidden(false);
	} else {
		zen("idRemoteFile").setHidden(false);
		zen("LocalFile").setHidden(true);
		zen("btnFinish").setHidden(false);
		zen("btnSubmit").setHidden(true);
	}
}

/// Check if file is empty.
ClientMethod validateFile(filename) [ Language = javascript ]
{
	if (filename == "") {
		var hint = zen('hintFile');
		hint.setValue($$$Text("File name is empty. Please enter a file name for the import."));
		hint.setHidden(false);
		zen("FileName").focus();
		return false;	
	}
	return true;
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen("FileName").setValue(value);
		zenPage.updateState();
		if (value != '') {
			zen('hintFile').setHidden(true);
		}
	}
}

Method GetTempFileName(pDocName) As %String [ ZenMethod ]
{
	Set ext = $P(pDocName,".",*)
	Set:(ext="") ext = "tmp"
	Quit ##class(%Library.File).TempFilename(ext)
}

/// User clicked the Import. 
ClientMethod doImport() [ Language = javascript ]
{
	this.resetMsg();
	var inputtype = "REMOTE";
	if (this.LOCALFILENAME != "") {
		filename = this.LOCALFILENAME;
		inputtype = "LOCAL";
	}

	var filename = zen("FileName").getValue();
	if (this.validateFile(filename) == false) return;

	var exists = this.FileExists(filename);
	var hint = zen('hintFile');
	var hintText = '';
	if (exists == -1) {
		hintText = $$$Text("You have entered a directory without a file name.");
	}
	if (exists == 0) {		
		hintText = $$$Text("File does not exists. Please select a valid file.");
	}
	if (hintText != '') {
		hint.setValue(hintText);
		hint.setHidden(false);
		zen("FileName").focus();
		return;	
	}
	hint.setHidden(true);
	/// save the final filename for the output to pickup.
	this.SaveLastFile(filename,this.FILETYPE);
	this.completeImport(filename);
}

/// this method completes both remote import and local import
ClientMethod completeImport(filename, inputtype) [ Language = javascript ]
{
	var background = (zen("chkBackground").getValue()==true) ? 1 : 0;
	var namespace = encodeURIComponent(this.NAMESPACE);
	var params = 'FILETYPE=' + encodeURIComponent(this.FILETYPE) + '&FILENAME=' + encodeURIComponent(filename) + '&NAMESPACE=' + namespace + '&RUNBACKGROUND=' + background + '&INPUTTYPE=' + inputtype;

	zen('output').setProperty('src','_CSP.UI.Portal.SQL.ImportOutput.zen?'+params);
	
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnCancel').focus();
	var btn = (inputtype == 'REMOTE') ? zen('btnFinish') : zen('btnSubmit');
	btn.setProperty('disabled',true);
	btn.setProperty('controlClass','commandButtonDisabled');
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
	this.submitHandler();
}

/// check if input type is LOCAL, and handles import from local files if it is.
ClientMethod submitHandler() [ Language = javascript ]
{
	// if this is from the submit of the Local file, process import now.
	if (this.INPUTTYPE == "LOCAL") {	
		zen("btnFinish").setHidden(true);
		zen("btnSubmit").setHidden(false);
		zen("idRemoteFile").setHidden(true);
		if (this.LOCALFILENAME != "") {
			this.completeImport(this.LOCALFILENAME, 'LOCAL');
			zen('hintFile').setHidden(true);
		} else {
			zen('LocalFile').setHidden(false);
			zen('hintFile').setHidden(false);
		}
	} else {
		zen("btnFinish").setHidden(false);
    	zen("btnFinish").focus();
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	var frame = zen("output");
	var wd = zenGetWindowWidth() - 20;
	var ht = zenGetWindowHeight() - 375;
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	frame.setProperty("width",wd);
	frame.setProperty("height",ht);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If ..FILETYPE = "SQLSTATEMENT" {
		Quit $$$TextHTML("Import SQL Statements")	
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
	Set FileName = ""
	#; Set for Remote input types choice: ServerName or local machine
	Set ..%GetComponentById("InputType").displayList = $zu(110)_","_$$$Text("My Local Machine")	
	Set LastSaveFile = $G($$$IRISTempMgt($Username,%page.FILETYPE,"Import","LastFile"))
	#; If this is the first time use, default it to manager directory, without the file name
	If LastSaveFile = "",FileName = "" Set FileName = $zu(12)
	If LastSaveFile '= "",FileName = "" Set FileName = LastSaveFile
	Set ..%GetComponentById("FileName").value = FileName
	If $G(%request.Data("INPUTTYPE",1)) = "LOCAL" {
		Set %page.LOCALFILENAME = $G(%session.Data($Username,%page.FILETYPE,"Import","LOCALFILENAME"))
		Set ..%GetComponentById("InputType").value = "LOCAL"
		Set backgroundDefault = +$G(%request.Data("BACKGROUND",1))
	} Else {
		Set backgroundDefault = 1
	}
	Set ..%GetComponentById("chkBackground").value = backgroundDefault
	
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set espNamespace = ..EscapeHTML(%page.NAMESPACE)
	Set tPageTitle = $$$FormatText($$$Text("Import SQL statements to namespace %1."),espNamespace)
	&html<<div class="Description">#(tPageTitle_"<br/>")#</div>>
	&html<<hr size="1"/>>
	Quit 1
}

ClassMethod SaveLastFile(pFileName, pFileType) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,pFileType,"Import","LastFile") = pFileName
}

/// Check to see if file exists
ClassMethod FileExists(filename) As %Integer [ ZenMethod ]
{
	If ##class(%File).DirectoryExists(filename) Quit -1
	If ##class(%File).Exists(filename) Quit 1
	Quit 0
}

/// This method is invoked only when user selects to import from Local Machine.<br/>
/// The necessary parameters are passed in URL. The temp file name is saved in %session and to be used in loading content.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Set FILETYPE = "SQLSTATEMENT"
	Set tStream = pSubmit.%GetStream("File")
	Set tSC = $$$OK
	If tStream '= "" {
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
		If $$$ISOK(tSC) {		
			#; Copy the stream from local server
			Set tSC = file.CopyFrom(tStream)
			#; Save it to the file stream on the remote server
			If tSC Set tSC = file.%Save()
		}
		//  save the temp local file name to be used in later to load content
		Set %session.Data($Username,FILETYPE,"Import","LOCALFILENAME") = DirFileName
	} Else {
		Set %session.Data($Username,FILETYPE,"Import","LOCALFILENAME") = ""
	}
	Set %response.Context("FILETYPE") = FILETYPE
	Set %response.Context("$NAMESPACE") = $namespace
	Set %response.Context("INPUTTYPE") = "LOCAL"
	Set %response.Context("BACKGROUND") = pSubmit.%GetValue("chkBackground")
	//  remember popup info
	Set %response.Context("$ZEN_POPUP") = 1
	Set %response.Context("$ZEN_POPUPPARENT") = +$G(%request.Data("$ZEN_POPUPPARENT",1))
	Set %response.Context("$ZEN_SOFTMODAL") = ..%OnUseSoftModals()  
	Quit tSC
}

}
