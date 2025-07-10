/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, Ensemble)

/// Used to select a server side file name or specify a local filename for target of an export
/// <p>This class is used internally by InterSystems. You should not make direct use of it within your applications. 
Class EnsPortal.Dialog.fileSelect Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

Parameter DOMAIN = "Ensemble";

Parameter APPLYBUTTON = 0;

Parameter RESOURCE = "%Ens_Portal:USE";

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Property serverWildCard As %ZEN.Datatype.string(ZENURL = "SRVWILD") [ InitialExpression = "*.txt" ];

Property serverDir As %ZEN.Datatype.string(ZENURL = "SRVDIR") [ InitialExpression = {$$$FileNormalizeDirectory(##class(%Stream.FileBinary).DefaultStreamDir(1))} ];

Property localDefault As %ZEN.Datatype.string(ZENURL = "LCLDEFAULT") [ InitialExpression = "export.txt" ];

Property exportInfoText As %ZEN.Datatype.string(ZENURL = "EXPINFO") [ InitialExpression = {$$$TextHTML("Select the location and name for the export file")} ];

Property showCharSet As %ZEN.Datatype.boolean(ZENURL = "SHOWCHARSET") [ InitialExpression = 1 ];

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
<radioSet id="ExportTo" name="ExportTo" label="Export the file to the" displayList="server,browser" valueList="SERVER,BROWSER"
onclick="zenPage.doLocationChange(zenThis);" value="SERVER"/>
<hgroup id="serverFile" label="" labelClass="normal" cellVAlign="bottom" hidden="false">
<text id="FileName" label="Enter the path and name of the export file" size="70"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.csv');"/>
</hgroup>
<hgroup id="browserFile" label="" labelClass="normal" cellVAlign="bottom" hidden="true" >
<text id="DocName" label="Enter the name of the export file" size="40"/>
</hgroup>
<spacer height="20"/>
<select id="Charset" label="Character set" showEmpty="false"/>
</vgroup>
</hgroup>
</pane>
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Export File Selection")
}

Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select either a local or a server file name to be used by the particular export.")
}

/// User changed to export file between Server or Browser
ClientMethod doLocationChange(radioSet) [ Language = javascript ]
{
	var flag = radioSet.getValue();
	if (!zenPage.canViewFileSystem) {
		alert(this.msgNotPermitted);
		flag = "BROWSER";
		radioSet.setValue("BROWSER");
	}

	if (flag == "BROWSER") {
		var name = zen('FileName').getValue();
		var pos = name.lastIndexOf('\\');
		if (pos == -1) {
			pos=name.lastIndexOf('\/');;
		}
		zen('DocName').setValue(name.substring(pos+1));
		zen('serverFile').setHidden(true);
		zen('browserFile').setHidden(false);
	} else {
		var FileName = zen('FileName');
		var pathName = FileName.getValue();
		zen('browserFile').setHidden(true);
		zen('serverFile').setHidden(false);
	}
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var nameValue = zen(name).getValue();
	var directoryAndNameToUse = ((nameValue.lastIndexOf('\\')==-1)&&(nameValue.lastIndexOf('\/')==-1)) ? zenPage.serverDir  : nameValue;
	var fileName = ((nameValue.lastIndexOf('\\')==-1)&&(nameValue.lastIndexOf('\/')==-1)) ? nameValue  : '';
	var parms = {
		Dir:directoryAndNameToUse,
		wildcard: zenPage.serverWildCard,
		File: fileName
	}
	var url = zenLink('%ZEN.Dialog.fileSelect.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('serverFileSelect'),'resizable,width=600,height=700',parms);
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'serverFileSelect':
			if (action == "ok") {
				zen("FileName").setValue(value);
				zenPage.updateState();
			}
			break;
	}
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var radioSet = zen('ExportTo');
	var charset = '';
	if (this.showCharSet) charset = zen("Charset").getValue();
	var filename;
	if ((radioSet) && (radioSet.getValue()=='BROWSER')) {
		filename = zen('DocName').getValue();
		filename = 'BROWSER'+'\0'+filename;
	} else {
		filename = 'SERVER'+'\0'+zen('FileName').getValue();
	}
	return encodeURIComponent((filename+'\0'+charset));
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
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException

	Try {

	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

Method %OnAfterCreatePage() As %Status
{

	#; Populate exportInfo and default local default name
	Set ..%GetComponentById("exportInfo").value = ..exportInfoText

	Set ..%GetComponentById("DocName").value = ..localDefault
	Set ..%GetComponentById("FileName").value = ..serverDir_..localDefault

	If ..showCharSet {
		#; Set Charset
		#dim DefCharList,tc,tint,displayList
		#dim CharList = $$GetIONames^%SYS.NLS(.DefCharList,1)
		#dim valueList = ""
		For tc = 1:1:$L(CharList,",") Set tint = $P(CharList,",",tc) Quit:tint=""  Set valueList = valueList_","_tint
		Set displayList = valueList
		Set $P(displayList,",",1) = "<"_$$$Text("Device Default")_">"
		Set ..%GetComponentById("Charset").valueList = valueList
		Set ..%GetComponentById("Charset").displayList = displayList
	} Else {
		Set ..%GetComponentById("Charset").hidden = 1
	}

	If '..canViewFileSystem {
		Set ..%GetComponentById("serverFile").hidden = 1
		Set ..%GetComponentById("browserFile").hidden = 0
		Set ..%GetComponentById("ExportTo").value = "BROWSER"
	}

	Quit ##super()
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

}
