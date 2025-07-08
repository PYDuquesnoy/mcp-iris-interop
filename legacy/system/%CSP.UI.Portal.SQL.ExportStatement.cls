/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Export SQL Statement dialog for Management Portal SQL.
/// <p><b>Please do not modify any part of this dialog without COMPLETELY testing all cases!!!<br/>
/// This dialog is used by SQL for exporting single SQL statement or all statements per namespace.<br/>
/// </b></p>
Class %CSP.UI.Portal.SQL.ExportStatement Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.ExportStatement.zen";

Parameter RESOURCE = "%Development:USE";

/// Displayed name of this page.
Parameter PAGENAME = "ExportSQLStatement";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If export individual statement, HASH is not null
Property HASH As %ZEN.Datatype.string(ZENURL = "HASH");

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

/// 1 = Export All; 0 = Export individual statement where HASH should be defined.
Property EXPORTALL As %ZEN.Datatype.string(ZENURL = "EXPORTALL");

Property FILETYPE As %ZEN.Datatype.string [ InitialExpression = "SQLSTATEMENT" ];

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
<radioSet id="ExportTo" name="ExportTo" label="Export to the" displayList="Server,Browser" valueList="SERVER,BROWSER"
onclick="zenPage.doLocationChange(zenThis.getValue());" value="SERVER"/>
<hgroup id="serverFile" label="" labelClass="normal" cellVAlign="bottom" >
<text id="FileName" label="Enter the path and name of the export file" size="70"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.xml');"/>
</hgroup>
<hgroup id="browserFile" label="" labelClass="normal" cellVAlign="bottom" hidden="true" >
<text id="DocName" label="Enter the name of the export file" size="40"/>
</hgroup>
<label id="hintFile" value="Please enter the file name for export." enclosingClass="rednote" hidden="true"/>
<html><hr size="1"/></html>
<checkbox id="chkBackground" caption="Run export in the background" captionClass="zenLabel" hint=" (Highly recommended for exporting all statements.)"/>
<iframe id="output"/>
</pane>
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

/// Check if file is empty.
ClientMethod validateFile(fileName) [ Language = javascript ]
{
	if (fileName == "") {
		var hint = zen('hintFile');
		hint.setValue($$$Text("File name is empty. Please enter a file name for the export."));
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

/// User clicked the Export or Export in Background button. 
ClientMethod doExport() [ Language = javascript ]
{
	this.resetMsg();
	var exportTo = zen('ExportTo').getValue();
	var hint = zen('hintFile');
	if (exportTo == "SERVER") {
		var filename = zen("FileName").getValue();
		if (this.validateFile(filename) == false) return;
	} else {
		var docName = zen("DocName").getValue();
		if (docName == "") {
			hint.setValue($$$Text("File name is empty. Please enter a file name for the export."));
			hint.setHidden(false);
			zen("DocName").focus();
			return false;
		}
		var filename = zenPage.GetTempFileName(docName);
	}

	if (exportTo == "SERVER") {
		var exists = this.FileExists(filename);
		if (exists == -1) {
			hint.setValue($$$Text("You have entered a directory without a file name."));
			hint.setHidden(false);
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
	hint.setHidden(true);
	var background = ((zen("chkBackground").getValue()==true)&&(exportTo == "SERVER")) ? 1 : 0;
	var namespace = encodeURIComponent(this.NAMESPACE);
	var params = 'FILETYPE=' + encodeURIComponent(this.FILETYPE) + '&FILENAME=' + encodeURIComponent(filename) + '&HASH='+ encodeURIComponent(this.HASH) + '&NAMESPACE=' + namespace + '&EXPORTALL=' + encodeURIComponent(this.EXPORTALL) + '&RUNBACKGROUND=' + background;
	if (exportTo == "BROWSER") {
		params = params + "&DOWNLOADNAME=" + encodeURIComponent(docName);
	}

	zen('output').setProperty('src','_CSP.UI.Portal.SQL.ExportOutput.zen?'+params);
	
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
	zenPage.DownloadStream(filename,docName);
	
	zen('btnCancel').setProperty('caption',$$$Text("Done"));
	zen('btnFinish').setProperty('disabled',true);
	zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
	zen('btnCancel').focus();
}

ClassMethod DownloadStream(pFilename As %String, pDocName As %String) [ ZenMethod ]
{
	Set tStream = ##class(%FileBinaryStream).%New()
	Set tSC = tStream.LinkToFile(pFilename)
	Do tStream.SetAttribute("ContentDisposition","attachment; filename="_pDocName)
	Set tSC = tStream.%Save()
	Set Oid = tStream.%Oid()
	&js<window.location="#url(%25CSP.StreamServer.cls?STREAMOID=#(..Encrypt(Oid))#)#";>
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
	If ..FILETYPE = "SQLSTATEMENT" {
		If ..EXPORTALL = 1 Quit $$$TextHTML("Export All SQL Statements")
		Quit $$$TextHTML("Export SQL Statement")	
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
	If LastSaveFile = "" {
		Set LastSaveFile = ##class(%File).NormalizeFilename("statementexport.xml")
	}
	Set ..%GetComponentById("FileName").value = LastSaveFile
	
	If %page.EXPORTALL = 1 {
		Set ..%GetComponentById("chkBackground").value = 1
	}
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set espNamespace = ..EscapeHTML(%page.NAMESPACE)
	Set tPageTitle = ""	
	If %page.EXPORTALL = 0 {
		If %page.HASH '= "" {
			Set tName = $O(^rINDEXSQL("sqlidx",1,%page.HASH,"rtn",""))
			If tName '= "" {
				Set tPageTitle = $$$FormatText($$$Text("Statement defined for: '%1'"),tName)
			} Else {
				Set tPageTitle = $$$FormatTextHTML($$$Text("Statement hash: '%1'"),%page.HASH)
			}
		}
	} Else {
		Set tPageTitle = $$$FormatText($$$Text("Export all SQL statements in namespace %1."),espNamespace)
	}
	&html<<div class="Description">#(tPageTitle_"<br/>")#</div>>
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
