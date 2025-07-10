/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Import dialog.
/// <p>This class is used internally by InterSystems IRIS and not intended for application development.
/// There is no guarantee about the behavior or future operation of this class.
Class EnsPortal.Dialog.Import Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter JSINCLUDES = "zenCSLM.js";

Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter CANCELBUTTON As BOOLEAN = 0;

Parameter TYPE As COSEXPRESSION = "$G(%request.Data(""TYPE"",1))";

/// Security resources required.
Parameter RESOURCE As COSEXPRESSION = "$Case($G(%request.Data(""TYPE"",1)),""Lookup"":""%Ens_LookupTables:WRITE"",""HL7"":""?"",:""%All"")_"",%Ens_ViewFileSystem:USE""";

/// Currently we support the following types: "Lookup", "HL7".
Property Type As %ZEN.Datatype.string(ZENURL = "TYPE");

/// Document suffixes that can be imported.
Property documentSuffix As %String [ InitialExpression = {$Case($G(%request.Data("TYPE",1)),"Lookup":"LUT","HL7":"HL7",:"?")} ];

/// Default machine for file browsing is server (or remote).
/// If server is running on another machine we also allow import files that are local to the client machine.
Property locationType As %String(ZENURL = "LOCATIONTYPE") [ InitialExpression = "REMOTE" ];

Property remoteFileName As %String;

Property localFileName As %String(ZENURL = "LOCALFILENAME");

/// If locationType="LOCAL", this is the temporary file name that was saved on the remote server upon submit and upload.
Property localFileTemp As %String(ZENURL = "TEMPFILE");

Property matchingDocs As %Integer [ InitialExpression = 0 ];

Property fileSelectedCount As %Integer [ InitialExpression = -99 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
a.radioSetCaption:hover {
	color: darkred;
}

iframe {
	border: none;
	border-top: 1px solid black;
	border-left: 1px solid black;
	background: white;
}

.separator {
	border-top: 1px solid black;
}

/* styles for file's table of contents */
table.ContentTable	{
	border: 1px solid lightgray;
}
table.ContentTable tr {
	line-height: 20px;
	font-size: 12px;
}
table.ContentTable th {
	font-size: 13px;
	font-weight: bold;
	background:white;
	color: #3b84bc;
	text-align: left;
	padding: 2px;
	padding-left: 4px;
}
table.ContentTable tr {
	background: white;
	font-size: 12px;
}
table.ContentTable td {
	padding: 1px; padding-left:4px;
	font-size: 12px;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" xmlns="http://www.intersystems.com/zen">
<form enctype="multipart/form-data" action="EnsPortal.Dialog.Import.zen" id="theForm">
<label id="idCheck" value="" hidden="true" enclosingStyle="padding: 20px;" />

<group id="grpAll" cellStyle="padding: 4px 10px 4px 10px">
<spacer height="10px" />
<radioSet id="locationType" label="The import file resides on" valueList="REMOTE,LOCAL" onclick="zenPage.doLocationChange(zenThis.getValue());" value="REMOTE" title="Choose between importing from a file located on the server machine, or on your local machine"/>

<hgroup id="idRemoteFile" cellVAlign="bottom" enclosingStyle="padding-top:0px;">
<text id="remoteFileName" size="70" label="Select a file" onchange="zenPage.selectRemoteFile();" />
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('remoteFileName');" />
</hgroup>
<fileUpload id="localFileName" name="localFileName" label="Select a local file" size="70" hidden="true" onchange="zenPage.selectLocalFile();" onclick="zenPage.resetLocalFile();" />

<hgroup labelPosition="left">
<select id="Charset" label="Character set" labelStyle="padding-right: 8px;" showEmpty="false" onchange="zenPage.selectCharset();" />
</hgroup>

<spacer height="5px" />
<hgroup>
<button id="btnOpenRemote" controlClass="commandButton" caption="Open" onclick="zenPage.btnOpen();" title="Open file to review contents and select which documents to import." />
<submit id="btnOpenLocal" controlClass="commandButtonDisabled" caption="Open" onclick="zenSetProp('lblOpening','hidden',false);" hidden="true" disabled="true" title="Open file to review contents and select which documents to import. The file will be uploaded to the InterSystems IRIS server." />
<spacer width="20px;" />
<label id="lblOpening" hidden="true" label="Opening file..." labelStyle="font-style: italic;" />
</hgroup>

<spacer height="15px"/>
<html id="sep1" hidden="false">
<div width="100%" class="separator"></div>
</html>
<label id="lblFileContents" label="File Contents" hidden="false" />

 <group id="grpFileContents" hidden="true">
 <hgroup>
<button id="btnImport" hidden="true" caption="Import" onclick="zenPage.btnImport();" controlClass="commandButton" title="Import selected documents." />
<spacer width="5px;" />
<label id="lblImporting" hidden="true" label="Importing..." labelStyle="font-style: italic;" />
</hgroup>
<spacer height="10px" />
<label id="lblContents" hidden="true" value="&amp;nbsp;" containerStyle="font-size:13px;" />
<spacer height="10px" />
<html id="fileContents" OnDrawContent="DrawFileContents" seed="#(%page.localFileTemp)#" />
</group>

<spacer height="20px" />
<html id="sep2" hidden="false">
<div width="100%" class="separator"></div>
</html>
<label id="lblImportResults" label="Import Results" hidden="false" />

<group id="grpResults">
<iframe id="frmResults" hidden="true" />
</group>
</group>
</form>
</pane>
}

ClientMethod selectRemoteFile() [ Language = javascript ]
{
	var remoteFileName = zen('remoteFileName').getValue();
	zenPage.remoteFileName = remoteFileName;
	zenPage.clearGroups();
	zenPage.fileSelectedCount = -99;
}

ClientMethod selectLocalFile() [ Language = javascript ]
{
	var localFileName = zen('localFileName').getValue();
	zenPage.localFileName = localFileName;
	zenPage.clearGroups();
	zenPage.SaveLocalInfoToSession(localFileName,zen('Charset').getValue());
	zenPage.fileSelectedCount = -99;
}

ClientMethod selectCharset() [ Language = javascript ]
{
	if (zenPage.locationType == 'LOCAL') {
		zenPage.SaveLocalInfoToSession(zen('localFileName').getValue(),zen('Charset').getValue());
	}
}

ClassMethod SaveLocalInfoToSession(LocalFileName As %String, CharSet As %String, Type As %String) [ ZenMethod ]
{
	Set %session.Data("ImportDocuments","LocalFileName") = LocalFileName
	Set %session.Data("ImportDocuments","CharSet") = CharSet
	Quit
}

/// User changed to pick file between remote and local.
ClientMethod doLocationChange(location) [ Language = javascript ]
{
	if (location == 'LOCAL') {
		zenPage.locationType = 'LOCAL';
		zen('idRemoteFile').setHidden(true);
		zen('localFileName').setHidden(false);
	}
	else {
		zenPage.locationType = 'REMOTE';
		zen('idRemoteFile').setHidden(false);
		zen('localFileName').setHidden(true);
	}
	zenPage.clearGroups();
}

/// Reset local file control appearance
ClientMethod resetLocalFile() [ Language = javascript ]
{
	zenSetProp('localFileName','label',$$$Text("Select a local file"));
	zenPage.clearGroups();
}

/// Remove file contents and import results from screen; show "Open" button for corresponding location type, hide other "Open" button.
ClientMethod clearGroups() [ Language = javascript ]
{
	if (zenPage.locationType == 'LOCAL') {
		var file = zenPage.localFileName;
		zenSetProp('btnOpenRemote','hidden',true);
		zenSetProp('btnOpenLocal','disabled',(file == ''));
		zenSetProp('btnOpenLocal','controlClass',(file == '' ? 'commandButtonDisabled' : 'commandButton'));
		zenSetProp('btnOpenLocal','hidden',false);
	}
	else {
		var file = zenPage.remoteFileName;
		zenSetProp('btnOpenLocal','hidden',true);
		zenSetProp('btnOpenRemote','disabled',(file == ''));
		zenSetProp('btnOpenRemote','controlClass',(file == '' ? 'commandButtonDisabled' : 'commandButton'));
		zenSetProp('btnOpenRemote','hidden',false);
	}
	zenSetProp('lblOpening','hidden',true);
	zenSetProp('grpFileContents','hidden',true);
	zenSetProp('grpResults','hidden',true);
	zenSetProp('frmResults','src','');
}

/// Open file on the remote server.
ClientMethod btnOpen() [ Language = javascript ]
{
	var remoteFileName = zen('remoteFileName').getValue();
	if (remoteFileName == '') {
		alert($$$Text("Please select a file to import"));
		return;
	}

	zenPage.clearGroups();
	zenSetProp('lblOpening','hidden',false);
	zenPage.remoteFileName = remoteFileName;
	var ok = this.ValidateFile(remoteFileName);
	if (ok == 0) {
		var msg = $$Text("File name is empty");
	}
	else if (ok == -1) {
		var msg = $$$Text("You have entered a directory path without a file name");
	}
	else if (ok == -2) {
		var msg = $$$Text("File does not exist");
	}
	if (ok < 1) {
		setTimeout(function() {
			zenSetProp('lblOpening','hidden',true);
			zenSetProp('btnOpenLocal','hidden',true);
			zenSetProp('btnOpenRemote','hidden',true);
			alert(msg);
		}, 0);
		zen('remoteFileName').focus();
		return;
	}

	zenSetProp('grpFileContents','hidden',false);
	zenSetProp('fileContents','hidden',false);
	var ctrl = zen('fileContents');
	ctrl.seed = remoteFileName;
	var sync = ctrl.refreshContents();
	setTimeout(function() {
		zenPage.updateContentsMsg(zenPage.fileSelectedCount);
		zenSetProp('lblOpening','hidden',true);
		zenSetProp('btnOpenLocal','hidden',true);
		zenSetProp('btnOpenRemote','hidden',true);
	}, 100);
}

/// Do the actual import of the selected documents from the file.
ClientMethod btnImport() [ Language = javascript ]
{
	//To do: If there is an open document and it is among imported documents, give a warning, and reload it afterwards.

	zenSetProp('btnOpenRemote','hidden',true);
	zenSetProp('btnOpenLocal','hidden',true);
	zenSetProp('btnImport','hidden',true);
	zenSetProp('lblImporting','hidden',false);
	zenSetProp('fileContents','hidden',true);

	// Store list of selected documents in the session
	var docs = new Array();
	for (var i = 1; i <= document.getElementById("tblContents").rows.length; i++) {
		var cb = document.getElementById("cb_"+i);
		if (cb && cb.checked) {
			docs.push(cb.value);
		}
	}
	if (docs.length == 0) {
		alert($$$Text("No documents were selected"));
		return;
	}
	var sync = zenPage.SaveListOfDocsToSession(docs);

	// Import and show results
	var filename = (zenPage.locationType == 'LOCAL' ? zenPage.localFileTemp : zenPage.remoteFileName);
	var charset = zen('Charset').getValue();
	var results = this.GetLink();
	results += (results.indexOf('?') > -1) ? '&' : '?';
	results += 'FILENAME=' + encodeURIComponent(filename) + '&CHARSET=' + encodeURIComponent(charset);
	setTimeout(function() {
		zenSetProp('frmResults','hidden',false);
		zenSetProp('grpResults','hidden',false);
		zenSetProp('frmResults','src',results);
		zenSetProp('lblImporting','hidden',true);
	}, 100);
}

ClassMethod SaveListOfDocsToSession(Docs As %ListOfDataTypes) [ ZenMethod ]
{
	Kill %session.Data("ImportDocuments","Docs")
	For i = 1:1:Docs.Count() {
		Set Name = Docs.GetAt(i)
		Set:Name'="" %session.Data("ImportDocuments","Docs",Name) = ""
	}
	Quit ""
}

/// User clicked the Browse button.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	var wildcard = '*.xml';
	var Dir = zen(name).getValue();
	var showdirectoryonly = 0;
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard+'&showdirectoryonly='+showdirectoryonly,'FileSelect','resizable,width=600,height=700');
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == 'ok') {
		zen('remoteFileName').setValue(value);
		zenPage.selectRemoteFile();
	}
}

ClientMethod toggleOneCheckbox(cbState) [ Language = javascript ]
{
	if (cbState) {
		zenPage.fileSelectedCount++;
		if (zenPage.fileSelectedCount == zenPage.matchingDocs) {
			document.getElementById("cb_All").checked = true;
		}
	}
	else {
		zenPage.fileSelectedCount--;
		document.getElementById("cb_All").checked = false;
	}
	zenPage.updateContentsMsg(zenPage.fileSelectedCount);
}

ClientMethod toggleCheckboxes(cbState) [ Language = javascript ]
{
	if (cbState) {
		zenPage.fileSelectedCount = zenPage.matchingDocs;
	}
	else {
		zenPage.fileSelectedCount = 0;
	}
	for (var i = 1; i <= document.getElementById("tblContents").rows.length; i++) {
		var cb = document.getElementById("cb_"+i);
		if (cb) cb.checked = cbState;
	}
	zenPage.updateContentsMsg(zenPage.fileSelectedCount);
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

	// Check document type and block use of this dialog if type is not provided or is invalid/unsupported
	If ..#PAGENAME="Import" {
		Set ..%GetComponentById("idCheck").hidden = 0
		Set ..%GetComponentById("idCheck").value = $$$Text("Please provide a valid document type")
		Set ..%GetComponentById("grpAll").hidden = 1
	}

	If ..locationType="LOCAL" {
		Set ..%GetComponentById("locationType").value = "LOCAL"
		Set ..%GetComponentById("localFileName").value = ..localFileName
		Set ..%GetComponentById("localFileName").label = $$$FormatText($$$Text("Local file:"))_" "_##class(%Library.File).GetFilename(..localFileName)
		Set ..%GetComponentById("idRemoteFile").hidden = 1
		Set ..%GetComponentById("localFileName").hidden = 0
		Set ..%GetComponentById("btnOpenLocal").hidden = 1
		Set ..%GetComponentById("btnOpenRemote").hidden = 1
	}

	Set LastFile = ..GetDefaultRemoteFile()
	Set:LastFile'="" ..%GetComponentById("remoteFileName").value = LastFile, ..remoteFileName = LastFile

	// Set location type choices: remote server name or local machine
	Set ..%GetComponentById("locationType").displayList = $ZU(110)_","_$$$Text("Local machine")

	// Determine if user is on same machine as the server and if so, do not show control to select local import option
	Set tClient = $ZCVT($G(%request.CgiEnvs("REMOTE_ADDR")),"l")
	Set tPeer = $SYSTEM.TCPDevice.PeerAddr(0)
	Set tIsLocal = ((tClient="127.0.0.1")||(tClient="::1")) && ((tPeer="127.0.0.1")||(tPeer="::1"))
	//Set tIsLocal = 0 // *** Uncomment only for testing local import without a remote server
	If tIsLocal {
		Set ..%GetComponentById("locationType").hidden = 1
		Set ..%GetComponentById("localFileName").hidden = 1
	}

	If ..Type="Class" {
		Set ..%GetComponentById("Charset").hidden = 1
	}
	Else {
		// Populate Charset
		Set CharList = $$GetIONames^%SYS.NLS(.DefCharList,1)
		Set valueList = ""
		For tc = 1:1:$L(CharList,",") Set tint = $P(CharList,",",tc) Quit:tint=""  Set valueList = valueList_","_tint
		Set displayList = valueList
		Set $P(displayList,",",1) = "<"_$$$Text("Default")_">"
		Set ..%GetComponentById("Charset").valueList = valueList
		Set ..%GetComponentById("Charset").displayList = displayList
		Set ..%GetComponentById("Charset").value = $G(%request.Data("CHARSET",1))
	}

	If ..#TYPE'="" Set %session.Data("ImportDocuments","Type") = ..#TYPE
	If ..#RESOURCE'="" Set %session.Data("ImportDocuments","Resource") = ..#RESOURCE

	Quit $$$OK
}

Method DrawFileContents(pSeed) As %Status
{
	Set FileName = $G(pSeed)
	Quit:FileName="" $$$OK

	Set tSC = $$$OK
	Set Suffix = ..documentSuffix
	If FileName = "" {
		Set tErr = $$$TextHTML("File name is empty!")
		Quit tSC
	}
	If ##class(%File).DirectoryExists(FileName) || ##class(%File).Exists(FileName) = 0 {
		Quit tSC
	}

	Set MatchingDocs = 0
	Set tMsg = "&nbsp;"
	Set msgNo = $$$TextHTML("No")
	Set msgYes = $$$TextHTML("Yes")
	Set Column(0) = $$$TextHTML("Click to select or unselect all")
	Set Column(1) = $$$TextHTML("Document")
	Set Column(2) = $$$TextHTML("Exists")
	Set Column(3) = $$$TextHTML("Last Modified")
	Set Filesize = ##class(%File).GetFileSize(FileName)
	Set Charset = ""
	Set tRow = 0
	Set tRS = ##class(%ResultSet).%New("%RoutineMgr:ImportItemList")
	Set tSC = tRS.Execute(FileName,Charset,.Description)
	If $$$ISERR(tSC) {
		Set ..fileSelectedCount = -3
		Set tMsg = $$$Text("This is not a valid export file, please select another file.") //$$$Text("This is not a valid export file")_" "_$$$Text("ERROR:")_" "_$ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
	}
	Else {
		If $G(Description)'= "" &html<<div class="normal">#($$$TextHTML("Description:")_" ")##($ZCVT(Description,"O","HTML"))#</div>>
		While tRS.Next() {
			Set tRow = tRow + 1
			If tRow=1 {
				// Only show table header if there are documents
				&html<<table id="tblContents" class="ContentTable" border="1" cellpadding="2" cellspacing="0" bgcolor="#c4d6d6">>
				&html<<tr><th><input type="checkbox" id="cb_All" title="#(Column(0))#" checked onclick="javascript:zenPage.toggleCheckboxes(this.checked);"></th>
				<th nowrap>#(Column(1))#</th><th nowrap>#(Column(2))#</th><th nowrap>#(Column(3))#</th></tr>>
			}
			Set tId = "cb_"_tRow
			Set tName = tRS.GetData(1)
			Set tTime = tRS.GetData(2)
			If %page.Type = "Global", $E(tName)'="^" Set tName = "^"_tName
			Set tExist = $S(tTime=-1:msgNo,1:msgYes)
			If tTime = -1!(tTime="") Set tTime = "&nbsp;"
			&html<<tr class="#($S(tExist=msgNo:"LiteRow",1:"DarkRow"))#">>
			If $E(tName,*-2,*)=Suffix {
				&html<<td><input type="checkbox" id="#(tId)#" value='#($ZCVT(tName,"O","HTML"))#' checked onClick="javascript:zenPage.toggleOneCheckbox(this.checked);"></td>>
				Set MatchingDocs = MatchingDocs+1
			}
			Else {
				&html<<td>&nbsp;</td>>
			}
			&html<<td nowrap>#($ZCVT(tName,"O","HTML"))#</td>>
			&html<<td nowrap>#($ZCVT(tExist,"O","HTML"))#</td>>
			&html<<td nowrap>#(tTime)#</td></tr>>
		}
		if tRow>0 {
			&html<</table>>
		}
		&html<<input type="hidden" id="TotalRows" value="#(tRow)#"><br/>>
		If tRow = 0 {
			Set ..fileSelectedCount = -1
			Set tMsg = $$$Text("This file does not contain any documents.")
		}
		ElseIf 'MatchingDocs {
			Set ..fileSelectedCount = -2
			Set tMsg = $$$FormatText($$$Text("There are no documents with extension %1."),..documentSuffix)
		}
		Else {
			Set ..fileSelectedCount = MatchingDocs
			If MatchingDocs=1 {
				Set tMsg = $$$Text("1 document selected to be imported.")
			}
			ElseIf MatchingDocs>1 {
				Set tMsg = $$$FormatText($$$Text("%1 documents selected to be imported."),MatchingDocs)
			}
		}
	}
	Set ..matchingDocs = MatchingDocs

	Quit $$$OK
}

ClientMethod updateContentsMsg(count) [ Language = javascript ]
{
	switch (count) {
		case -1:
			var msg = $$$Text("This file does not contain any documents.");
			break;
		case -2:
			var msg = $$$FormatText($$$Text("There are no documents with extension %1."),this.documentSuffix);
			break;
		case -3:
			var msg = $$$Text("This is not a valid export file, please select another file.");
			break;
		case -99:
			var msg = '&nbsp;';
			break;
		case 0:
			var msg = $$$Text("No documents selected to be imported.");
			break;
		case 1:
			var msg = $$$Text("1 document selected to be imported.");
			break;
		default:
			var msg = $$$FormatText($$$Text("%1 documents selected to be imported."),count)
	}

	zenSetProp('grpFileContents','hidden',false);
	zenSetProp('lblContents','value',msg);
	zenSetProp('lblContents','hidden',false);
	zenSetProp('lblContents','controlStyle',(count < 0 ? 'color:red; font-weight:bold; font-size:14px;' : ''));

	if (count > 0) {
		zenSetProp('btnImport','disabled',false);
		zenSetProp('btnImport','controlClass','commandButton');
		zenSetProp('btnImport','hidden',false);
	}
	else if (count == 0) {
		zenSetProp('btnImport','disabled',true);
		zenSetProp('btnImport','controlClass','commandButtonDisabled');
		zenSetProp('btnImport','hidden',false);
	}
	else {
		zenSetProp('btnOpenRemote','disabled',true);
		zenSetProp('btnOpenRemote','controlClass','commandButtonDisabled');
		zenSetProp('btnOpenLocal','disabled',true);
		zenSetProp('btnOpenLocal','controlClass','commandButtonDisabled');
		zenSetProp('btnImport','disabled',true);
		zenSetProp('btnImport','hidden',true);
	}
}

ClassMethod ValidateFile(File As %String) As %Integer [ ZenMethod ]
{
	Set File = $ZStrip(File,"<>W")
	If File="" Quit 0
	If ##class(%File).DirectoryExists(File) Quit -1 // Not a file, only a directory
	If '##class(%File).Exists(File) Quit -2 // File does not exist
	Do ..SetDefaultRemoteFile(File)
	Quit 1
}

/// This method is invoked only when user selects to import from Local Machine.<br/>
/// The necessary parameters are passed in URL. The temp file name is saved in %session and to be used in loading content.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Set tStream = pSubmit.%GetStream("localFileName")
	Set TempFile = ##class(%File).TempFilename()
	Set File = ##class(%Stream.FileBinary).%New()
	Set tSC = File.LinkToFile(TempFile)
	If $$$ISOK(tSC) && $IsObject(tStream) && $IsObject(File) {
		// Copy the stream uploaded from the local machine to the temporary file on the remote server
		Set tSC = File.CopyFrom(tStream)
		If $$$ISOK(tSC) Set tSC = File.%Save()
	}

	// Info for submit
	Set %response.Context("TYPE") = $G(%session.Data("ImportDocuments","Type"))
	Set %response.Context("$ZEN_POPUP") = 1
	Set %response.Context("$ZEN_SOFTMODAL") = ..%OnUseSoftModals()
	Set %response.Context("LOCATIONTYPE") = "LOCAL"
	Set %response.Context("LOCALFILENAME") = $G(%session.Data("ImportDocuments","LocalFileName"))
	Set %response.Context("CHARSET") = %session.Data("ImportDocuments","CharSet")
	Set %response.Context("TEMPFILE") = TempFile

	Quit tSC
}

ClassMethod GetDefaultRemoteFile() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME,"ImportExportFileName"))
}

ClassMethod SetDefaultRemoteFile(pFile As %String) [ ZenMethod ]
{
	Set:$G(pFile)'="" ^EnsPortal.Settings($USERNAME,"ImportExportFileName") = pFile
}

/// Adjust sizes of components on the page.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	this.adjustSizes();
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	var wd = zenGetWindowWidth() - 46;
	if (zenIsIE) wd = wd - 4;
	if (wd < 100) wd = 100;
	//var ht = zenGetWindowHeight() - 560;
	//if (ht < 100) ht = 100;
	zenSetProp('frmResults','width',wd);
	zenSetProp('sep1','width',wd);
	zenSetProp('sep2','width',wd);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);

	var btnOK = zen('btnOK');
	btnOK.setProperty('caption',$$$Text("Close"));
	if (zenPage.locationType == 'LOCAL') {
		zenPage.updateContentsMsg(zenPage.fileSelectedCount);
		zenPage.adjustSizes();
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $Case($G(%request.Data("TYPE",1)),"Lookup":$$$Text("Import Lookup Table"),"HL7":$$$Text("Import HL7"),:"Import")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $$$Text("Namespace")_" "_$Namespace
}

Method GetLink() As %String [ ZenMethod ]
{
	Quit ..Link("EnsPortal.Dialog.ImportResults.cls")
}

}
