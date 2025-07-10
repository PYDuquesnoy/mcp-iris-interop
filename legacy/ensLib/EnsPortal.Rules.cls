/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// This is the Rules page of the ZEN application.
Class EnsPortal.Rules Extends (EnsPortal.Template.listPage, EnsPortal.Template.scUtils, EnsPortal.Util.PageLinks) [ System = 4 ]
{

/// User needs READ permissions on one of the following resources to view this page:
/// %Ens_Code, %Ens_Rules, %Ens_RoutingRules or %Ens_BusinessRules.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ";

/// User needs WRITE permissions on one of the following resources to make changes on this page:
/// %Ens_Code, %Ens_Rules, %Ens_RoutingRules or %Ens_BusinessRules.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_Rules:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Business Rule List";

Property msgSelectItemToExport As %String [ InitialExpression = "Please select a business rule to export." ];

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
<hgroup valign="top">
<spacer width="20" />
<vgroup valign="top" >
<spacer height="20" />
<!-- Find all subclasses of Ens.Rule.Definition and list them by name -->
<tablePane id="table" 
    cellSpacing="2"
	fixedHeaders="false"	
	dataSource="columns"
	useSnapshot="true"
	queryClass="EnsPortal.Rules"
	queryName="Enumerate"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="Name"
	maxRows="5000"
	>
<parameter value="Ens.Rule.Definition" />
<parameter id="filter" value=""/>
<parameter id="queryMethod" value="EnumerateEditableSubclasses"/>
<parameter id="queryClass" value="EnsPortal.Utils"/>
<column id="colName" colName="Name" header="Business Rule Class Name" OnDrawCell="MakeLink" />
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

Method MakeLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write ("<span class=""aStyle"" ")
	Write (" ondblclick=""zenPage.doEdit('"_$ZCVT($ZCVT(%query(pName),"O","JS"),"O","HTML")_"');"" ")
	Write (" title=""Double-click to view the rule definition."">")
	Write (..EscapeHTML(%query(pName))_"</span>")
	Quit $$$OK
}

/// Delete current id then refresh.
ClientMethod doDelete() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }

	var tab = zen('table');
	var val = tab.getValue();
	if (val.length > 0) { // A rule was selected for delete
		if (confirm($$$Text("Are you sure you want to delete this rule?"))) {
			ret = zenPage.DeleteID(val);
			if (!this.processDeleteReturn(ret,val)) return false;   // Error 
			// Success: refresh the table
			tab.value = ''; // setProperty does not work here
			tab.executeQuery();
		}
	}
	else {
		alert($$$Text("First choose a rule from the table, then click Delete to delete the rule."));
	}
}

/// Delete this id on the server accounting for source control
Method DeleteID(pRuleClass) As %String [ Internal, ZenMethod ]
{

	#dim tJSONMessage = ""

	/*	Only delete a Rule class.
		The class might not be compiled - hence use of this API
	*/

	If ('##class(EnsPortal.Utils).IsSubclass(pRuleClass,"Ens.Rule.Definition")) {

		Set tJSONMessage = ..BadRequestMessage()

	} Else {

		Do ..DeleteDoc(pRuleClass, ".CLS", .tJSONMessage)

		// Empty any user's "LastRule" setting if it is the same as the deleted rule
		#dim user = ""
		For {
			Set user = $O(^EnsPortal.Settings(user))
			Quit:""=user
			If ($G(^EnsPortal.Settings(user,"LastRule")) = pRuleClass) {
				Set ^EnsPortal.Settings(user,"LastRule") = ""
			}
		}
	}

	Return tJSONMessage
}

/// Edit current id
ClientMethod doEdit(val) [ Language = javascript ]
{
	if (val == null) {
		val = zen('table').getProperty('value');
	}
	if (val.length > 0) { // A rule was selected for edit
		var ruleLink = zenLink(zenPage.ruleEditorBaseURL + '&rule=' + encodeURIComponent(val));
		zenPage.gotoPage(ruleLink);
	}
	else alert($$$Text("First choose a rule from the table, then click Open to open and edit the rule."));
}

ClientMethod doNew() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var parms = {RULE:''};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessRuleWizard.zen'),this.addPopupSuffix('newRule'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
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
		case 'newRule':
			if (value!='') {
				var ruleLink = zenLink(zenPage.ruleEditorBaseURL + '&rule=' + encodeURIComponent(value) + ' &NEW=1')
				zenPage.gotoPage(ruleLink);
			}
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

ClientMethod finishExport(filename) [ Language = javascript ]
{
	var msgExportFailed = $$$Text("Unable to export rule")
	var status = zenPage.Export(filename, zenPage.getComponentById("table").getValue());
	if (status == 1)  {
		zenPage.SetDefaultDir(filename);
		setTimeout(function() {
			alert($$$Text("The rule was exported successfully"));
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
	var msgImportSuccess = $$$Text("The rule was imported successfully")
	var msgImportFailed = $$$Text("Unable to import file")
	var status = zenPage.Import(filename);	
	if (status == 1)  {
		zenPage.SetDefaultDir(filename);
		setTimeout(function() {
			alert(msgImportSuccess);
		}, 50);
		self.document.location.reload();
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

ClassMethod CheckValidImportFileExists(pFilename As %String) As %String [ ZenMethod ]
{
	Quit ##class(EnsPortal.Utils).ValidImportFileExists(pFilename, "Ens.Rule.Definition")
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
	Quit $$$Text("Business Rule List","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("newButton",$$$Text("New"),$$$Text("Go to the Rule Editor to create a new rule."),"zenPage.doNew();")
	Set pCommands(2) = $LB("editButton",$$$Text("Open"),$$$Text("Edit the currently selected rule."),"zenPage.doEdit();")
	Set pCommands(3) = $LB("exportButton",$$$Text("Export"),$$$Text("Export the currently selected rule to an XML file."),"zenPage.doExport();")
	Set pCommands(4) = $LB("importButton",$$$Text("Import"),$$$Text("Import a rule that was previously exported to an XML file."),"zenPage.doImport();")
	Set pCommands(5) = $LB("deleteButton",$$$Text("Delete"),$$$Text("Delete the currently selected rule."),"zenPage.doDelete();")
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"Import": ..#EDITRESOURCE,
				"DeleteID": ..#EDITRESOURCE,
				"AfterUserDeleteAction": ..#EDITRESOURCE,
				: "")
}

}
