/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is the Business Processes list page of the ZEN Ensemble application.
Class EnsPortal.BusinessProcesses Extends (EnsPortal.Template.listPage, EnsPortal.Template.scUtils) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Business Process List";

/// User needs READ permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_BPL:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_BPL resource to modify Business Processes.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_BPL:WRITE";

Property msgSelectItemToExport As %String [ InitialExpression = "Please select a business process to export." ];

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
<!-- Find all subclasses of Ens.BusinessProcess (except Ens.BusinessProcessBPL) and list them by name -->
<tablePane id="table"
    cellSpacing="2"
	fixedHeaders="false"	
	queryClass="EnsPortal.BusinessProcesses"
	queryName="Enumerate"
	useSnapshot="true"
	showQuery="false"
	showZebra="true"
	showRowNumbers="false"
	maxRows="5000"
	valueColumn="Name"
	>
<parameter value="Ens.BusinessProcess" />
<parameter id="filter" value=""/>
<parameter id="queryMethod" value="EnumerateEditableSubclasses"/>
<parameter id="queryClass" value="EnsPortal.Utils"/>
<column id="colName" colName="Name" header="Business Process Class Name" OnDrawCell="ScreenBPL" />
<column id="colModified" colName="Modified" header="Last Modified" />
</tablePane>
</vgroup>
</hgroup>
</pane>
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(pSuperclass As %String, Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "Name:%String,Modified:%TimeStamp") [ SqlProc ]
{
}

/// Override this Method to pass more arguments to the class query 
ClassMethod EnumerateExecute(ByRef qHandle As %Binary, pSuperclass As %String, pFilter As %String = "", QueryMethod As %String, QueryClass As %String) As %Status
{
	Set tSC = $CLASSMETHOD(QueryClass, QueryMethod_"Execute", .qHandle, pSuperclass)
	Set qHandle("Filter") = pFilter
	Set qHandle("QueryClass") = QueryClass
	Set qHandle("QueryMethod") = QueryMethod
	Quit tSC
}

Method ScreenBPL(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tClassname = %query(pName)
	If (tClassname '= "Ens.BusinessProcessBPL" && $classmethod("EnsPortal.Utils","IsSubclass",tClassname,"Ens.BusinessProcessBPL")) {
		Write ("<span class=""aStyle"" ")
		Write (" ondblclick=""zenPage.gotoPage('EnsPortal.BPLEditor.zen?BP="_$ZCVT(tClassname,"O","HTML")_".bpl');"" ")
		Write (" title=""Double-click to edit the BPL definition of this business process, if it has a BPL definition."">")
		Write (..EscapeHTML(tClassname)_"</span>")
	}
	Else {
		Write (..EscapeHTML(tClassname))
	}
	If '##class(%Dictionary.CompiledClass).%ExistsId(tClassname) {
		Write (" "_$$$Text("(Not yet compiled)"))
	}
	Quit $$$OK
}

ClientMethod doInstance() [ Language = javascript ]
{
	var val = zen('table').getProperty('value');
	if (val.length > 0) zenPage.launchInstance(val);
	else alert($$$Text("First choose a business process from the table, then click Instances to view currently running instances of that business process."));
}

ClientMethod launchInstance(instId) [ Language = javascript ]
{
	zenPage.gotoPage("EnsPortal.BPInstances.zen?BP="+encodeURIComponent(instId));
}

/// Delete current id then refresh.
ClientMethod doDelete() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var tab = zen('table');
	var val = tab.getValue();
	if (val.length > 0) { // A business process was selected for delete
		if (confirm($$$Text("Are you sure you want to delete this business process?"))) {
			ret = zenPage.DeleteID(val);
			if (!this.processDeleteReturn(ret,val)) return false;   // Error 
			// Success: refresh the table
			tab.value = ''; // setProperty does not work here
			tab.executeQuery();		  
		}
	}
	else alert($$$Text("First choose a business process from the table, then click Delete to delete the business process."));
}

/// Delete this id on the server 
Method DeleteID(pBPClass) As %String [ ZenMethod ]
{

	#dim tJSONMessage = ""

	/* Only delete a Business Process class.
		The class might not be compiled - hence use of this API
	*/

	If ('##class(EnsPortal.Utils).IsSubclass(pBPClass,"Ens.BusinessProcess")) {

		Set tJSONMessage = ..BadRequestMessage()

	} Else {

		Do ..DeleteDoc(pBPClass, ".CLS", .tJSONMessage)

		// Empty any user's "LastBP" setting if it is the same as the deleted  business process
		#dim user = ""
		For {
			Set user = $O(^EnsPortal.Settings(user))
			Quit:""=user
			If ($G(^EnsPortal.Settings(user,"LastBP")) = pBPClass) {
				Set ^EnsPortal.Settings(user,"LastBP") = ""
			}
		}
	}

	Return tJSONMessage
}

/// Edit current business process
ClientMethod doEdit() [ Language = javascript ]
{
	var val = zen('table').getProperty('value');
	if (val.length > 0) { // A business process was selected for edit
		if (zenPage.IsBPL(val)) {
			zenPage.gotoPage('EnsPortal.BPLEditor.zen?BP=' + encodeURIComponent(val) + ".bpl");
		}
		else {
			alert($$$Text("This business process is not a BPL business process; you must edit it in Studio."));
		}
	}
	else alert($$$Text("First choose a BPL business process from the table, then click Open to open and edit the business process in the BPL Editor."));
}

ClientMethod doNew() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var parms = {};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessProcessWizard.zen'),this.addPopupSuffix('BPListNew'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
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
					var ok = confirm($$$Text("The file does not appear to contain a business process; do you wish to continue the import operation?"));
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
					alert($$$Text("The file does not contain valid syntax for an exported business process"));
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
		case 'BPListNew':
			if (value!='') {
				zenPage.gotoPage(zenLink("EnsPortal.BPLEditor.zen" + '?BP=' + encodeURIComponent(value) + '&NEW=1'));
			}
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

ClientMethod finishExport(filename) [ Language = javascript ]
{
	var msgExportFailed = $$$Text("Unable to export business process:")
	var status = zenPage.Export(filename,zenPage.getComponentById("table").getValue());
	if (status == 1) {
		zenPage.SetDefaultDir(filename);
		setTimeout(function() {
			alert($$$Text("The business process was exported successfully"));
		}, 50);
	}
	else if (status.match("ERROR") == "ERROR") setTimeout(function() {
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
	if (status == 1) {
		zenPage.SetDefaultDir(filename);
		setTimeout(function() {
			alert($$$Text("The file was imported successfully"));
		}, 50);
		self.document.location.reload(); // redisplay list
	}
	else if (status.match("ERROR") == "ERROR") {
		if (status.match("#5030") == "#5030") {
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

ClassMethod IsBPL(pClassname As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(EnsPortal.Utils).IsSubclass(pClassname, "Ens.BusinessProcessBPL")
}

ClassMethod CheckValidImportFileExists(pFilename As %String) As %String [ ZenMethod ]
{
	Quit ##class(EnsPortal.Utils).ValidImportFileExists(pFilename, "Ens.BusinessProcess")
}

/// This client event, if present, is fired when the page is loaded. 
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
	Quit $$$Text("Business Process List","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("newButton",$$$Text("New"),$$$Text("Go to the BPL Editor to create a new business process."),"zenPage.doNew();")
	Set pCommands(2) = $LB("editButton",$$$Text("Open"),$$$Text("Edit the currently selected business process."),"zenPage.doEdit();")
	Set pCommands(3) = $LB("exportButton",$$$Text("Export"),$$$Text("Export the currently selected business process to an XML file."),"zenPage.doExport();")
	Set pCommands(4) = $LB("importButton",$$$Text("Import"),$$$Text("Import a business process that was previously exported to an XML file."),"zenPage.doImport();")
	Set pCommands(5) = $LB("deleteButton",$$$Text("Delete"),$$$Text("Delete the currently selected business process."),"zenPage.doDelete();")
	Set pCommands(6) = $LB("instanceButton",$$$Text("Instances"),$$$Text("View instances of this business process in the Business Process Log"),"zenPage.doInstance();")
	Set pCommands(7) = $LB("ruleButton",$$$Text("Rule Log"),$$$Text("View the Rule Log to see which business rules have fired"),"zenPage.gotoPage('EnsPortal.RuleLog.zen');")
	Quit $$$OK
}

/// Protect the import and delete methods on the server.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "Import": ..#EDITRESOURCE, 
						"DeleteID": ..#EDITRESOURCE,
						"AfterUserDeleteAction": ..#EDITRESOURCE,
						: "")
}

}
