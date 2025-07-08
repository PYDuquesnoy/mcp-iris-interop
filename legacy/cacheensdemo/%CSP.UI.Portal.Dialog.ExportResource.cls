/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Export/Import Resources dialog for Management Portal.
Class %CSP.UI.Portal.Dialog.ExportResource Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.ExportResource.zen";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Displayed name of this page.
Parameter PAGENAME = "ExportResources";

Parameter AUTONS As BOOLEAN = 1;

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 1;

/// Type from where we get the selected items from: Class or Routine.
Property FILETYPE As %ZEN.Datatype.string(ZENURL = "FILETYPE");

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property EXPORTALL As %ZEN.Datatype.string(ZENURL = "EXPORTALL");

Property FILEFLAG As %ZEN.Datatype.string [ InitialExpression = "*.xml" ];

/// Action is either Export or Import.
Property ACTION As %ZEN.Datatype.string(ZENURL = "ACTION");

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
<button id="btnApply" controlClass="commandButton" caption="Export" onclick="zenPage.doExport();"/>
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Done" onclick="zenPage.dialogFinish();" hidden="true"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<label id="idRespond" controlClass="redText" value="" containerStyle="padding-left:10px;"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<hgroup label="" labelClass="normal" cellVAlign="bottom" >
<text id="FileName" label="Enter the path and name of the export file" size="70"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.xml');"/>
</hgroup>
<html><hr size="1"/></html>
<html id="output" OnDrawContent="DrawOutput" seed=""/>
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
		this.showMsg($$$Text("File name is empty. Please enter a file name for the export."));
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

/// Use clicked the Export or Export in Background button. 
ClientMethod doExport() [ Language = javascript ]
{
	this.resetMsg();	
	var filename = zen("FileName").getValue();
	if (this.validateFile(filename) == false) return;
	var exists = this.FileExists(filename);
	if (exists == -1) {
		this.showMsg($$$Text("You have entered a directory without a file name."));
		zen("FileName").focus();
		return;	
	}
	if (this.ACTION == "Export") {
		if (exists == 1) {
			if (!confirm($$$Text("File already exists. Overwrite the existing file?"))) {
				return;
			}
		}
		var numDone = this.ExportData(filename,this.EXPORTALL);
	} else {
		var numDone = this.ImportData(filename);
	}
	/// save the final filename for the output to pickup.
	if (isNaN(numDone)) {
		this.showMsg(numDone);
	} else {
		var output = zen("output");
		output.setProperty("seed",numDone);
		zen('btnCancel').setProperty('hidden',true);
		zen('btnFinish').setProperty('hidden',false);
		zen('btnApply').setProperty('hidden',true);
		zen('btnFinish').focus();
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.onresizeHandler();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
    zen("btnApply").focus();
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
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

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If ..ACTION = "Export" {
		If ..EXPORTALL = 1 Quit $$$TextHTML("Export All Resources")
		Quit $$$TextHTML("Export Resources")	
	} Else {
		Quit $$$TextHTML("Import Resources")
	}
	Quit "Unknown"
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
	
	Set LastSaveFile = $G($$$IRISTempMgt($Username,%page.FILETYPE,%page.ACTION,"LastFile"))
	If LastSaveFile = "" {
		Set LastSaveFile = ##class(%File).NormalizeFilename("ResourcesExport.xml")
	}
	Set ..%GetComponentById("FileName").value = LastSaveFile
	If ..ACTION = "Import" Set ..%GetComponentById("FileName").label=$$$TextHTML("Enter the path and name of the import file")
	If %page.ACTION = "Import" Set ..%GetComponentById("btnApply").caption = $$$TextHTML("Import")
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	
	If %page.EXPORTALL = 0 {		
		Set tTotal = +$G(%session.Data($Username,%page.FILETYPE,"TotalSelected"))
		If %page.ACTION="Export" {
			Set tTitle = $S(tTotal>1:$$$Text("Export %1 resources."),1:$$$Text("Export %1 resource."))
			Set tPageTitle = $$$FormatText(tTitle,tTotal)_"<br/>"
		} Else {
			Set tPageTitle = $$$TextHTML("Import resources from a file.")
		}	
	} Else {
		If %page.ACTION="Export" Set tPageTitle = $$$Text("Export all resources.")_"<br/>"
	}		
	&html<<div class="Description">#(tPageTitle)#</div>>
	&html<<hr size="1"/>>
	Quit 1
}

ClassMethod DrawOutput(numExported As %String) As %Status
{
	Quit:numExported="" 1
	If %page.ACTION = "Export" {
		Set tMsg = $S(numExported>1:$$$Text("%1 resources exported."),1:$$$Text("%1 resource exported."))
		Set tMsg = $$$FormatText(tMsg,numExported)
	} Else {
		Set tMsg = $S(numExported>1:$$$Text("%1 resources imported."),1:$$$Text("%1 resource imported."))
		Set tMsg = $$$FormatText(tMsg,numExported)
	}
	&html<<div>#(tMsg)#</div>
	>
	Quit 1
}

ClassMethod SaveLastFile(pFileName, pFileType) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,pFileType,%page.ACTION,"LastFile") = pFileName
}

/// Check to see if file exists
ClassMethod FileExists(filename) As %Integer [ ZenMethod ]
{
	If ##class(%File).DirectoryExists(filename) Quit -1
	If ##class(%File).Exists(filename) Quit 1
	Quit 0
}

ClassMethod ExportData(filename, exportall) As %String [ ZenMethod ]
{
	If '##class(%File).Exists(filename) {
		#; If directory doesn't exists, create it now
	    Set Dir = ##class(%File).GetDirectory(filename,1)
 		Set tSC = ##class(%File).CreateDirectoryChain(Dir)
		If tSC '= 1 {
			Set tMsg = Dir_": "_$$$Text("Could not create this directory. Please check the directory and try again.")
			Quit tMsg
		}
	}
	If exportall {
		Set resources ="*"
	} Else {
		Set resources = ""
		Set FILETYPE = "Resource"
		Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",""))
		While tRow '= "" {
			Set selectedRows = %session.Data($Username,FILETYPE,"selectedRows",tRow)		
			For n = 1:1:$L(selectedRows,",") Set tItem = $P(selectedRows,",",n) If tItem '= "" Set resources = resources_tItem_","
			Set tRow = $O(%session.Data($Username,FILETYPE,"selectedRows",tRow))
		}
	}
	Set tSC = ##class(Security.Resources).Export(filename, .NumExported, resources, -1, -1)
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit NumExported
}

ClassMethod ImportData(filename) As %String [ ZenMethod ]
{
	Set tSC = ##class(Security.Resources).Import(filename, .NumImported)
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit NumImported
}

}
