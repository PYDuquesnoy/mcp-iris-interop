/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is the Record Maps page of the ZEN Ensemble application.
Class EnsPortal.RecordMaps Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Record Map List";

/// User needs READ permissions on either the %Ens_Code or the %Ens_RecordMap resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_RecordMap:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_RecordMap resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_RecordMap:WRITE";

Property msgSelectItemToExport As %String [ InitialExpression = "Please select a record map to export." ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.aStyle {
	color: #3b84bc;
	text-decoration: none;
}
</style>
}

/// This XML block defines the contents of the table pane.
XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup valign="top" >
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<tablePane id="table"
    cellSpacing="2"
	fixedHeaders="false"	
	queryClass="EnsPortal.RecordMaps"
	queryName="Enumerate"
	useSnapshot="true"
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	maxRows="5000"
	valueColumn="name"
	>
	<parameter id="filter" value=""/>
	<parameter id="queryMethod" value="List"/>
	<parameter id="queryClass" value="EnsLib.RecordMap.RecordMap"/>
<column colName="name" header="Record Map Name" OnDrawCell="AllMaps" />
<column colName="modified" header="Last Modified" />
<column colName="size" hidden="true"/>
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer") [ SqlProc ]
{
}

Method AllMaps(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write ("<span class=""aStyle"" ondblclick=""zenPage.doEdit('"_$ZCVT($ZCVT(%query(pName),"O","JS"),"O","HTML")_"');"" ")
	Write (" title=""Double-click to edit the definition of this record map."">")
	Write (..EscapeHTML(%query(pName))_"</span>")
	Quit $$$OK
}

/// Delete current id then refresh.
ClientMethod doDelete() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var tab = zen('table');
	var val = tab.getValue();
	if (val.length > 0) { // A record map was selected for delete
		var recordName = this.GetRecordName(val);
		var parms = {
			"RECORDMAP": val,
			"OBJECTNAME": recordName
		};
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.RecordMapDelete.zen'),this.addPopupSuffix('ListDeleteRecordMap'),'status,scrollbars,resizable=yes,width=500,height=400',parms);
	}
	else alert($$$Text("First choose a record map from the table, then click Delete to delete the record map."));
}

Method GetRecordName(RecordMap As %String) As %String [ ZenMethod ]
{
	Set tRecordMap = $$$NormalizeClassname(RecordMap)
	Set tObjectName = ""
	Try {
		Set tModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(tRecordMap,.tSC)
		If $$$ISOK(tSC) && $IsObject(tModel) {
			Set tObjectName = tModel.targetClassname
		}
		If tObjectName = "" {
			Set tObjectName = $$$comMemberKeyGet(tRecordMap,$$$cCLASSparameter,"OBJECTNAME",$$$cPARAMdefault)
		}
	}
	Catch ex {}
	Quit tObjectName
}

/// Edit current record map
ClientMethod doEdit(val) [ Language = javascript ]
{
	if (val == null) {
		val = zen('table').getProperty('value');
	}
	if (val.length > 0) { // A record map was selected for edit
		zenPage.gotoPage('EnsPortal.RecordMapper.zen?MAP=' + encodeURIComponent(val));
	}
	else alert($$$Text("First choose a record map from the table, then click Open to open and edit the record map."));
}

ClientMethod doNew() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	var nextName = zenPage.NextDefaultRecordMap();
	zenPage.gotoPage(zenLink("EnsPortal.RecordMapper.zen?MAP="+encodeURIComponent(nextName)+"&NEW=1"));
}

/// Get the next available "default" RecordMap name.
ClassMethod NextDefaultRecordMap() As %String [ Internal, ZenMethod ]
{
	Quit ##class(EnsPortal.RecordMapper).NextDefaultRecordMap()
}

/// Returning from file select dialog 
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'ExportFileSelection':
			var fileExists = zenPage.FileExists(value);
			if (fileExists == 0) {
				zenPage.finishExport(value);
			}
			else {
				var ok = confirm($$$Text("Are you sure you want to overwrite the existing file?"));
				if (ok) {
					zenPage.finishExport(value);
				}
			}
			break;
		case 'ImportFileSelection':
			var fileStatus = zenPage.CheckValidImportFileExists(value);
			switch (fileStatus) {
				case "Ok": 
					zenPage.finishImport(value);
					break;
				case "Invalid":
					var ok = confirm($$$Text("The file does not appear to contain a rule; do you wish to continue the import operation?"));
					if (ok) {
						zenPage.finishImport(value);
					}
					break;
				case "Duplicate":
					var ok = confirm($$$Text("This file will overwrite an existing class of the same name; do you wish to continue the import operation?"));
					if (ok) {
						zenPage.finishImport(value);
					}
					break;
				case "Syntax":
					alert($$$Text("The file does not contain valid syntax for an exported rule"));
					break;
				case "Open":
					alert($$$Text("Could not open file for import"));
					break;
				case "Read":
					alert($$$Text("Unable to read import file"));
					break;
				case "None":
					alert($$$Text("The file to import does not exist"));
					break;
				default: // this should never happen
					break;
			}
			break;
		case 'ListDeleteRecordMap':
			zen('table').executeQuery();
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

ClientMethod finishExport(filename) [ Language = javascript ]
{
	var msgExportFailed = $$$Text("Unable to export record map")
	var status = zenPage.Export(filename,zenPage.getComponentById("table").getValue());
	if (status == 1) {
		zenPage.SetDefaultDir(filename);
		setTimeout(function() {
			alert($$$Text("The record map was exported successfully"));
		}, 50);
	}
	else if (status.match("ERROR")) setTimeout(function() {
		alert(msgExportFailed + " " + status);
	}, 50);
	else setTimeout(function() {
		alert(msgExportFailed);
	}, 50);
}

ClientMethod finishImport(filename) [ Language = javascript ]
{
	var msgImportFailed = $$$Text("Unable to import file")
	var status = zenPage.Import(filename);	
	if (status == 1)  {
		zenPage.SetDefaultDir(filename);
		setTimeout(function() {
			alert($$$Text("The record map was imported successfully"));
		}, 50);
		self.document.location.reload();
	}
	else if (status.match("ERROR")) {
		if (status.match("#5030")) {
			setTimeout(function() {
				alert($$$Text("The file was imported, but an attempt to compile it failed"));
			}, 50);
			self.document.location.reload(); // redisplay list
		}
		else setTimeout(function() {
			alert(msgImportFailed + ": " + status);
		}, 50);
	}
	else setTimeout(function() {
		alert(msgImportFailed);
	}, 50);
}

/// Override this in order to use a different naming scheme for default filename 
ClientMethod GetDefaultFile(table) As %String [ Language = javascript ]
{
	return table.replace(/[.]/g, '_')
}

ClassMethod CheckValidImportFileExists(pFilename As %String) As %String [ ZenMethod ]
{
	Quit ##class(EnsPortal.Utils).ValidImportFileExists(pFilename, "EnsLib.RecordMap.RecordMap")
}

ClassMethod Import(Filename As %String) As %String [ ZenMethod ]
{
	Set tSC = $system.OBJ.Load(Filename,"/compile/nodisplay")
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Else {
		Set tMsg = "1"
	}
	Quit tMsg
}

/// This client event, if present, is fired when the page is loaded. &&&
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	this.startKeepAlive();
	
	var doc = self.document;
	var newButton = doc.getElementById('command_newButton');
	var editButton = doc.getElementById('command_editButton');
	var exportButton = doc.getElementById('command_exportButton');
	var importButton = doc.getElementById('command_importButton');
	var deleteButton = doc.getElementById('command_deleteButton');
	
	editButton.className = 'commandButton';
	exportButton.className = this.canViewFileSystem ? 'commandButton' : 'commandButtonDisabled';
	if (this.canEdit) {
		newButton.className = 'commandButton';
		deleteButton.className = 'commandButton';
		if (this.canViewFileSystem) {
			importButton.className = 'commandButton';
		}
		else {
			importButton.className = 'commandButtonDisabled';
		}
	}
	else {
		newButton.className = 'commandButtonDisabled';
		deleteButton.className = 'commandButtonDisabled';
		importButton.className = 'commandButtonDisabled';
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Record Map List","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("newButton",$$$Text("New"),$$$Text("Create a new record map."),"zenPage.doNew();")
	Set pCommands(2) = $LB("editButton",$$$Text("Open"),$$$Text("Edit the currently selected record map."),"zenPage.doEdit();")
	Set pCommands(3) = $LB("exportButton",$$$Text("Export"),$$$Text("Export the currently selected record map to an XML file."),"zenPage.doExport();")
	Set pCommands(4) = $LB("importButton",$$$Text("Import"),$$$Text("Import a record map that was previously exported to an XML file."),"zenPage.doImport();")
	Set pCommands(5) = $LB("deleteButton",$$$Text("Delete"),$$$Text("Delete the currently selected record map."),"zenPage.doDelete();")

	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"GetRecordName": ..#EDITRESOURCE,
				"Import": ..#EDITRESOURCE,
				: "")
}

}
