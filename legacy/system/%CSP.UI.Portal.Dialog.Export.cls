/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Export dialog for Management Portal.
/// <p><b>Please do not modify any part of this dialog without COMPLETELY testing all cases!!!<br/>
/// This dialog is used by Classes/Routines/Globals for both Namespaces and Databases.<br/>
/// Please be extremely careful!!! </b></p>
Class %CSP.UI.Portal.Dialog.Export Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.Export.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Export";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Type from where we get the selected items from: Class or Routine.
Property FILETYPE As %ZEN.Datatype.string(ZENURL = "FILETYPE");

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property EXPORTALL As %ZEN.Datatype.string(ZENURL = "EXPORTALL");

Property EXPORTFORMAT As %ZEN.Datatype.string [ InitialExpression = "XML" ];

Property FILEFLAG As %ZEN.Datatype.string;

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

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Export" onclick="zenPage.doExport();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" value=""/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<radioSet id="ExportTo" name="ExportTo" label="Export the file to the" displayList="server,browser" valueList="SERVER,BROWSER"
onclick="zenPage.doLocationChange(zenThis.getValue());" value="SERVER"/>
<hgroup id="serverFile" label="" labelClass="normal" cellVAlign="bottom" >
<text id="FileName" label="Enter the path and name of the export file" size="68"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.xml');"/>
</hgroup>
<hgroup id="browserFile" label="" labelClass="normal" cellVAlign="bottom" hidden="true" >
<text id="DocName" label="Enter the name of the export file" size="40"/>
</hgroup>
<vgroup labelPosition="left">
<select id="Charset" label="Character set" showEmpty="false"/>
<select id="OutputFormat" label="Output format" hidden="true" valueList="7,5" displayList="Block format (recommended for speed),Sequential file" value="7" showEmpty="false"
hint="(Block format ignores mapped globals and mapped global subscripts.)"/>
<select id="RecordFormat" label="Record format" hidden="true" valueList="V,S" displayList="Variable Length Records,Stream Data" value="V" showEmpty="false"/>
</vgroup>
<checkbox id="chkExportOBJ" caption="Check here for exporting OBJ code in XML format" captionClass="zenLabel" hidden="true" onclick="zenPage.exportOBJ(zenThis);"/>
<html><hr size="1"/></html>
<checkbox id="chkBackground" caption="Run export in the background" captionClass="zenLabel" hint=" (Highly recommended for exporting many or large files.)"/>
<iframe id="output"/>
</pane>
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard),'FileSelect','resizable,width=680,height=750');
}

/// Check if file is empty.
ClientMethod validateFile(fileName) [ Language = javascript ]
{
	if (fileName == "") {
		alert($$$Text("File name is empty. Please enter a file name for the export."));
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
	}
}

Method GetTempFileName(pDocName) As %String [ ZenMethod ]
{
	Set ext = $P(pDocName,".",*)
	Set:(ext="") ext = "tmp"
	Quit ##class(%Library.File).TempFilename(ext)
}

/// User clicked the Export or Export in Background button. 
ClientMethod doExport() [ Language = javascript ]
{
	this.resetMsg();
	var exportTo = zen('ExportTo').getValue();
	if (exportTo == "SERVER") {
		var filename = zen("FileName").getValue();
		if (this.validateFile(filename) == false) return;
		if (zen("chkExportOBJ").getValue() == true) {
			/// in case user purposely tampered with the filename, change it back to xml
			this.checkExpObj();
			filename = zen("FileName").getValue();
		}
	} else {
		var docName = zen("DocName").getValue();
		if (docName == "") {
			alert($$$Text("File name is empty. Please enter a file name for the export."));
			zen("DocName").focus();
			return false;
		}
		if (zen("chkExportOBJ").getValue() == true) {
			// in case user purposely tampered with the filename, change it back to xml
			this.checkExpObj();
			docName = zen("DocName").getValue();
		}
		var filename = zenPage.GetTempFileName(docName);
	}
	var charset = zen("Charset").getValue();
	if (charset == "EBCDIC") {
		// EBCDIC cannot be used when exporting to XML
		var from = filename.length - 4;
		var fileext = filename.substring(from);
		if (fileext.toLowerCase() == ".xml") {
			this.showMsg($$$Text("Character set 'EBCDIC' cannot be used when exporting to XML."),1);			
			zen("Charset").focus();
			return;
		}	
	}

	if (exportTo == "SERVER") {
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
		/// save the final filename for the output to pickup.
		this.SaveLastFile(filename,this.FILETYPE);
	}
	var background = ((zen("chkBackground").getValue()==true)&&(exportTo == "SERVER")) ? 1 : 0;
	var namespace = encodeURIComponent(this.NAMESPACE);
	var params = 'FILETYPE=' + encodeURIComponent(this.FILETYPE) + '&FILENAME=' + encodeURIComponent(filename) + '&CHARSET=' + encodeURIComponent(charset) + '&NAMESPACE=' + namespace + '&EXPORTALL=' + encodeURIComponent(this.EXPORTALL) + '&EXPORTFORMAT=' + encodeURIComponent(this.EXPORTFORMAT) + '&RUNBACKGROUND=' + background;
	if (this.FILETYPE == "Global") {
		params = params + "&OutputFormat="+encodeURIComponent(zen("OutputFormat").getValue()) + "&RecordFormat="+encodeURIComponent(zen("RecordFormat").getValue());	
	}
	if (exportTo == "BROWSER") {
		params = params + "&DOWNLOADNAME=" + encodeURIComponent(docName);
	}
	zen('output').setProperty('src',zenLink('_CSP.UI.Portal.Dialog.ExportOutput.zen?'+params));
	
	if (exportTo == "SERVER") {
		zen('btnCancel').setProperty('caption',$$$Text("Done"));
		zen('btnFinish').setProperty('disabled',true);
		zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
		zen('btnCancel').focus();
	} else {
		window._downloadTimer = window.setTimeout(function() {
		    zenPage.CheckFileStatus(filename);
		}, 5);
	}
}

Method CheckFileStatus(pFilename) [ ZenMethod ]
{
	#; try open
	Try {
	    Set tF = ##class(%File).%New(pFilename)
	    Set tSC = tF.Open("W")
	    Kill tF ; We were just testing...
	    If $$$ISOK(tSC) {
	        &js<
	        	if (window._downloadTimer) {
	            	window.clearInterval(window._downloadTimer);
	            	window._downloadTimer = null;
	            	zenPage.doDownload(#(..QuoteJS(pFilename))#);
	        	}
	        >
	    }
	} Catch {
	}
}

ClientMethod doDownload(filename) [ Language = javascript ]
{
	var docName = zen("DocName").getValue();
	var charset = zen("Charset").getValue();
	zenPage.DownloadStream(filename,docName,charset);
	
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnFinish').setProperty('disabled',true);
	zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
	zen('btnCancel').focus();
}

ClassMethod DownloadStream(pFilename As %String, pDocName As %String, pCharSet As %String) [ ZenMethod ]
{
	Set tStream = ##class(%FileBinaryStream).%New()
	Set tSC = tStream.LinkToFile(pFilename)
	Do tStream.SetAttribute("ContentDisposition","attachment; filename="_pDocName)
	Do tStream.SetAttribute("CharSet",pCharSet)
	Set tSC = tStream.%Save()
	Set Oid = tStream.%Oid()
	&js<window.location="#url(%25CSP.StreamServer.cls?STREAMOID=#(..Encrypt(Oid))#)#";>
}

/// If exportOBJ checkbox is checked, then make sure the file has xml extension and background is checked and disabled.
ClientMethod exportOBJ(thisObj) [ Language = javascript ]
{
	try {	
		if (thisObj.getValue() == true) {
			this.EXPORTFORMAT = "XML";
			zen("chkBackground").setValue(true);
			zen("chkBackground").setDisabled(true);
			var fileName = zen("FileName").getValue();
			// first make sure there is a export file name
			if (this.validateFile(fileName) == false) return;
			// then check to see if it has .xml as extension. If not, add it.
			this.checkExpObj();
		} else {
			this.EXPORTFORMAT = "RO";
			zen("chkBackground").setDisabled(false);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in exportOBJ');
	}
}

/// make sure that if export OBJ is checked then the file name contains .xml
ClientMethod checkExpObj() [ Language = javascript ]
{
	var exportTo = zen("ExportTo").getValue();
	var fileName = (exportTo == "SERVER") ? zen("FileName").getValue() : zen("DocName").getValue();	
	var newFile = "";
	if (fileName.indexOf('.ro') > -1) {
		// if filename's extension is .ro then replace it with .xml
		newFile = fileName.replace('.ro','.xml');
	} else {
		// if filename's last character is "." then add "xml"
		if (fileName.substring(fileName.length-1,fileName.length) == ".") newFile = fileName + "xml";
		// if filename does not contain .xml then add it
		else if (fileName.indexOf('.xml') == -1) newFile = fileName + ".xml";
	}
	if (newFile != "") {
		if (exportTo == "SERVER") {
			zen("FileName").setValue(newFile);
		} else {
			zen("DocName").setValue(newFile);
		}
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
}

/// User changed to export file between Server or Browser
ClientMethod doLocationChange(flag) [ Language = javascript ]
{
	if (flag == "BROWSER") {
		var name = zen('FileName').getValue();
		var pos = name.lastIndexOf('\\');
		if (pos == -1) pos=0;
		zen('DocName').setValue(name.substring(pos+1));
		zen('serverFile').setHidden(true);
		zen('browserFile').setHidden(false);
		zen("chkBackground").setHidden(true);
	} else {
		var FileName = zen('FileName');
		var pathName = FileName.getValue();
		var pos = pathName.lastIndexOf('\\');
		if (pos == -1) pos=0;
		var docName = zen('DocName').getValue();
		FileName.setValue(pathName.substring(0,pos+1)+docName);
		zen('browserFile').setHidden(true);
		zen('serverFile').setHidden(false);
		zen("chkBackground").setHidden(false);
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
    zen("btnFinish").focus();
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
	If ..FILETYPE = "Class" {
		If ..EXPORTALL = 1 Quit $$$TextHTML("Export All Classes")
		Quit $$$TextHTML("Export Classes")	
	} ElseIf ..FILETYPE = "Routine" {
		Quit $$$TextHTML("Export Routines")
	} ElseIf ..FILETYPE = "Global" {
		Quit $$$TextHTML("Export Globals")
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
	
	Set LastSaveFile = $G($$$IRISTempMgt($Username,%page.FILETYPE,"Export","LastFile"))
	If %page.FILETYPE = "Routine" {
		Set %page.FILEFLAG = "*.ro"
		Set %page.EXPORTFORMAT = "RO"
		Set ..%GetComponentById("chkExportOBJ").hidden = 0
	} ElseIf %page.FILETYPE = "Global" {
		Set %page.FILEFLAG = "*.gof"
		Set %page.EXPORTFORMAT = "GO"
		Set ..%GetComponentById("OutputFormat").hidden = 0
		Set ..%GetComponentById("RecordFormat").hidden = 0
	} Else {
		Set %page.FILEFLAG = "*.xml"
		Set %page.EXPORTFORMAT = "XML"
	}
	If LastSaveFile = "" {
		Set LastSaveFile = ##class(%File).NormalizeFilename("export"_$P(%page.FILEFLAG,"*",2))
	}
	Set ..%GetComponentById("FileName").value = LastSaveFile
	Set ServerName = $zu(110)
	#; Set Charset
	Set CharList = $$GetIONames^%SYS.NLS(.DefCharList,1)
	Set valueList = ""
	For tc = 1:1:$L(CharList,",") Set tint = $P(CharList,",",tc) Quit:tint=""  Set valueList = valueList_","_tint
	Set displayList = valueList
	Set $P(displayList,",",1) = "<"_$$$Text("Device Default")_">"
	Set ..%GetComponentById("Charset").valueList = valueList
	Set ..%GetComponentById("Charset").displayList = displayList
    #; Make UTF8 the default if it's present
    If (valueList_",")[",UTF8," Set ..%GetComponentById("Charset").value = "UTF8"
	If %page.EXPORTALL=1 || (+$G(%session.Data($Username,%page.FILETYPE,"selectedRows")) > 1) {
		Set ..%GetComponentById("chkBackground").value = 1
		//Set ..%GetComponentById("lblRecommend").value = $$$TextHTML("A large number of files will be exported. This Export will be run in the background.")
	}
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set espNamespace = ..EscapeHTML(%page.NAMESPACE)
	Set tPageTitle = ""	
	If %page.EXPORTALL = 0 {		
		Set tTotal = +$G(%session.Data($Username,%page.FILETYPE,"TotalSelected"))
		Set:%page.FILETYPE="Class" tTitle = $S(tTotal>1:$$$Text("Export %1 classes from namespace %2."),1:$$$Text("Export %1 class from namespace %2"))
		Set:%page.FILETYPE="Routine" tTitle = $S(tTotal>1:$$$Text("Export %1 routines from namespace %2."),1:$$$Text("Export %1 routine from namespace %2"))
		Set:%page.FILETYPE="Global" tTitle = $S(tTotal>1:$$$Text("Export %1 globals from namespace %2."),1:$$$Text("Export %1 global from namespace %2"))
		Set tPageTitle = $$$FormatText(tTitle,tTotal,espNamespace)_"<br/>"
	} Else {
		If %page.FILETYPE="Class" Set tPageTitle = $$$FormatText($$$Text("Export all classes in namespace %1."),espNamespace)_"<br/>"
	}		
	&html<<div class="Description">#(tPageTitle)#</div>>
	&html<<hr size="1"/>>
	Quit 1
}

ClassMethod SaveLastFile(pFileName, pFileType) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,pFileType,"Export","LastFile") = pFileName
}

/// Check to see if file exists
ClassMethod FileExists(filename) As %Integer [ ZenMethod ]
{
	If ##class(%File).DirectoryExists(filename) Quit -1
	If ##class(%File).Exists(filename) Quit 1
	Quit 0
}

}
