/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This is the Productions page of the ZEN application.
Class EnsPortal.Productions Extends (EnsPortal.Template.listPage, EnsPortal.Template.scUtils) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Production Status";

/// User needs READ permissions on the %Ens_ProductionConfig resource to access this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_ProductionConfig:WRITE";

Property canDocument As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_ProductionDocumentation","USE")} ];

Property canExport As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_DeploymentPkg", "USE")} ];

/// OS platform ("Windows", "UNIX" or "VMS")
Property OS As %String [ InitialExpression = {$system.Version.GetBuildOS()} ];

/// This XML block defines the contents of the table pane.
XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<spacer height="20" />
<hgroup>
<spacer width="20" />
<vgroup>
<tablePane id="table" 
    cellSpacing="2"
	fixedHeaders="false"	
	useSnapshot="true"
	valueColumn="Production"
	maxRows="5000"
	queryClass="EnsPortal.Productions"
	queryName="Enumerate"
	showZebra="true"
	>
	<parameter id="filter" value=""/>
	<parameter id="queryMethod" value="ProductionStatus"/>
	<parameter id="queryClass" value="Ens.Config.Production"/>
<column colName="Production" header="Production Name" />
<column colName="Status" header="Status" />
<column colName="LastStartTime" header="Last Start Time" />
<column colName="LastStopTime" header="Last Stop Time" />
<column colName="LastModified" header="Last Modified" />
<column colName="StatusEnum" hidden="true" />
<condition colName="StatusEnum" predicate="EQ" value="4" rowStyle="background: plum;"/>
<condition colName="StatusEnum" predicate="EQ" value="-4" rowStyle="background: plum;"/>
<condition colName="StatusEnum" predicate="EQ" value="1" rowStyle="background: lightgreen; font-weight: bold;" />
<condition colName="StatusEnum" predicate="EQ" value="-1" rowStyle="background: lightgreen; font-weight: bold;" />

</tablePane>

<spacer height="10"/>
</vgroup>
<spacer width="20" />
</hgroup>
</pane>
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "Production:%String,Status:%String,LastStartTime:%String,LastStopTime:%String,StatusEnum:%String") [ SqlProc ]
{
}

/// Invoke the new production wizard just like in EnsPortal.ProductionConfig
ClientMethod doNew() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var parms = {};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ProductionWizard.zen'),this.addPopupSuffix('NewProductionWizard'),'status,scrollbars,resizable=yes,width=900,height=600',parms);
	return;
}

/// Correctly encode the URL for the production name before linking to the configuration page for a production. 
/// This is required to be able to configure productions with non-English Latin-1 characters in their names.
ClientMethod doConfigure() [ Language = javascript ]
{
	var id = zen('table').getValue();
	if (id.length <= 0) {
		alert($$$Text('First choose a production from the table, then click Open to configure the production.'+id));
		return;
	}
	if (zenPage.ProductionExists(id)) { // EnsPortal.ProductionConfig does not react well to a non-existent production 
		var page = zenLink('EnsPortal.ProductionConfig.zen?PRODUCTION=' + encodeURIComponent(id));
		self.document.location = page;
	}
	else {
		alert($$$FormatText($$$Text('Production %1 does not exist.'),id));
	}
	return;
}

ClassMethod ProductionExists(id) As %Boolean [ ZenMethod ]
{
	Quit ##class(Ens.Config.Production).%ExistsId(id)
}

/// Correctly encode the URL for the production name before linking to the documentation page for a production. 
/// This is required to be able to configure productions with non-English Latin-1 characters in their names.
ClientMethod doDocument() [ Language = javascript ]
{
	if (!this.canDocument) {
		alert(this.msgNotPermitted);
		return false;
	}
	if (this.OS == 'VMS') {
		alert($$$Text('Not available on VMS.'));
		return;
	}
	var id = zen('table').getProperty('value');
	if (id.length <= 0) {
		alert($$$Text("First choose a production from the table, then click Document to generate documentation for the production."));
		return;
	}
	var url = zenLink("EnsPortal.ProductionDocument.zen");
	url += (url.indexOf('?') > -1 ? '&' : '?') + 'PRODUCTION=' + encodeURIComponent(id);
	window.open(url);
}

ClientMethod doDelete() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var id = zen('table').getProperty('value');
	if (id.length <= 0) {
		alert($$$Text("First choose a production from the table, then click Delete to delete the production."));
		return;
	}
	if (confirm($$$Text("Are you sure you want to delete this production: "+id+"?"))) {
		ret = zenPage.DeleteID(id);
		if (!this.processDeleteReturn(ret,id)) return false;
		// unselect our previous selection and refresh the table
		var tab = zen('table');
		tab.value = ''; // setProperty does not work here
		tab.executeQuery();
	}
}

/// Delete this production (identified by id) then refresh.
/// Accounting for Source Control if applicable.
Method DeleteID(pProdName) As %String [ ZenMethod ]
{
	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tJSONMessage = ""

	Try {

		If ('##class(EnsPortal.Utils).IsSubclass(pProdName,"Ens.Production")) {
			Set tJSONMessage = ..BadRequestMessage()
			Quit
		} 

		#; Handle here if Production class in SourceControl
		Try {
			#; Populate docSCStatus object in order to identify if production covered by Source Control
			Do ..GetStatusExtension(pProdName, ".CLS")
		} Catch {}

		#dim tHandleDeleteHere = ..docSCStatus.inSourceControl

		// delete the specified Production Definition
		Set tStatus = ##class(Ens.Director).DeleteProduction(pProdName,tHandleDeleteHere)

		If $$$ISOK(tStatus) && tHandleDeleteHere {

			Do ..DeleteDoc(pProdName, ".CLS", .tJSONMessage)

		}
	} Catch ex {
		Set tStatus = $$$SystemError
	}

	If $$$ISERR(tStatus) || 'tHandleDeleteHere {
		#; processDeleteReturn will present this in an alert or accept tRetVal as empty string as OK
		#dim tRetVal = ""
		If $$$ISERR(tStatus) Set tRetVal = $zcvt($System.Status.GetErrorText(tStatus), "O", "HTML")
		Return tRetVal
	}

	Return tJSONMessage
}

ClientMethod doExport() [ Language = javascript ]
{
	if (!this.canExport)  { 
		alert(this.msgNotPermitted);
		return false; 
	}
	
	var id = zen('table').getProperty('value');
	if (id.length <= 0) {
		alert($$$Text("First choose a production from the table, then click Export to export the production."));
		return;
	}
	
	var parms = {
		PRODUCTION: id,
		HOSTID:     '',
		HOSTNAME:   ''
		};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ExportFromItem.zen'),'','status,scrollbars,resizable=yes,width=900,height=600',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'NewProductionWizard': 
			self.document.location = zenLink('EnsPortal.ProductionConfig.zen?PRODUCTION=' + encodeURIComponent(value));
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
		default: break;
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production List","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("New"),$$$Text("Start the Production Wizard to create a new Production."),"zenPage.doNew();")
	Set pCommands(2) = $LB("btnConfig",$$$Text("Open"),$$$Text("Configure the currently selected Production."),"zenPage.doConfigure();")
	Set pCommands(3) = $LB("btnExport",$$$Text("Export"),$$$Text("Export the currently selected Production."),"zenPage.doExport();")
	/* There is no import button yet
	Set pCommands(4) = $LB("btnImport",$$$Text("Import"),$$$Text("Import a Production."),"zenPage.doImport();")
	*/
	Set pCommands(5) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete the currently selected Production from the namespace."),"zenPage.doDelete();")
	Set pCommands(6) = $LB("btnDocument",$$$Text("Document"),$$$Text("Document the currently selected Production."),"zenPage.doDocument();")
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod, "DeleteID": ..#EDITRESOURCE,
						"AfterUserDeleteAction": ..#EDITRESOURCE,
						: "")
}

/// This client event, if present, is fired when the page is loaded. 
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	this.startKeepAlive();
	
	var doc = self.document;
	var newButton = doc.getElementById('command_btnNew');
	var editButton = doc.getElementById('command_btnConfig');
	var exportButton = doc.getElementById('command_btnExport');
	/* There is no import button yet
	var importButton = doc.getElementById('command_btnImport');
	*/
	var deleteButton = doc.getElementById('command_btnDelete');
	var docButton = doc.getElementById('command_btnDocument');
	
	editButton.className = 'commandButton';
	exportButton.className = zenPage.canExport ? 'commandButton' : 'commandButtonDisabled';
	docButton.className = (zenPage.canDocument ? 'commandButton' : 'commandButtonDisabled'); 
	if (this.canEdit) {
		newButton.className = 'commandButton';
		deleteButton.className = 'commandButton';
		/* There is no import button yet
		if (this.canViewFileSystem) {
			importButton.className = 'commandButton';
		}
		else {
			importButton.className = 'commandButtonDisabled';
		}
		*/
	}
	else {
		newButton.className = 'commandButtonDisabled';
		deleteButton.className = 'commandButtonDisabled';
		/* There is no import button yet
		importButton.className = 'commandButtonDisabled';
		*/
	}
	if (this.OS == 'VMS') {
		self.document.getElementById('command_btnDocument').className = 'commandButtonDisabled';
		self.document.getElementById('command_btnDocument').disabled = true;
	}
}

}
