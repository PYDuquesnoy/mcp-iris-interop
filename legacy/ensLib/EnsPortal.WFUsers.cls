/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Workflow Users page of the ZEN application.
Class EnsPortal.WFUsers Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs READ permissions on the %Ens_WorkflowConfig resource to access this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:READ";

/// User needs WRITE permissions on the %Ens_WorkflowConfig resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_WorkflowConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Workflow Users";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	color: #404040;
	font-size: 10pt;
}

.expandoNode a {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
}

.tnbrTable {
	border: 1px solid #808080;
	background: #D0D0D0;
	background-image: none;
}

#tableGroup {
	overflow: hidden;
	border-right: 1px solid #F0F0F0;
	border-left: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#descriptionPanel {
	width: 200px;
	background: white;
	font-size: 11pt;
	color: #404040;
	padding: 8px;
	overflow: auto;
}

#detailGroup {
	width: 350px;
	background: #E0E0D0;
	overflow: auto;
	border-right: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#tableGroup {
	overflow: auto;
}

/* style for table pane */
table.tpTable {
	background: white;
}

table.tpTable th {
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
	background: #D0D0D0;
	background-image: none;
}

table.tpTable th.tpHdrSelected {
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
	background: #D0D0F0;
	background-image: none;
}

</style>
}

/// This XML block defines the contents of the main pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="pane" hidden="true">
<hgroup cellVAlign="top">
<html id="descriptionPanel" OnDrawContent="DrawDescription" />
<vgroup id="tableGroup">
<tablePane id="table" 
    cellSpacing="2"
	useSnapshot="true"
	maxRows="10000"
	pageSize="10000"
	queryClass="EnsLib.Workflow.Engine"
	queryName="ListUsers"
	showZebra="true"
	useKeys="true"
	valueColumn="Name"
	onrefresh=""
	onselectrow="zenPage.rowSelected(zenThis);"
	onunselectrow="zenPage.rowSelected(zenThis);"
	>
	<column header="Name" colName="Name" title="Workflow name for this user" />
	<column header="Full Name" colName="FullName" title="Full name for this user" />
	<column header="Active?" colName="IsActive" OnDrawCell="DrawYesNo" 
			title="Yes if the user is currently active, otherwise No" />
	<column header="Number of Roles" colName="Roles" title="Number of roles held by this user" style="text-align:left;"/>
</tablePane>
</vgroup>
<vgroup id="detailGroup">
<form id="bpForm" cellStyle="padding:3px;">
<hgroup>
<button controlClass="commandButton" id="btnSave" caption="Save" onclick="zenPage.save();"
title="Save the currently visible workflow user definition" />
<spacer width="5" />
<button controlClass="commandButtonRemove" id="btnRemove" caption="Remove" onclick="zenPage.deleteItem();" />
</hgroup>
<hidden name="ID" id="txtID"/>
<selector label="Name" name="Name" id="txtName" context="Ens.ContextSearch/ListEnsembleUsers" size="37" hint="Required. Must be an existing user name."  />
<text label="Full Name" name="FullName" id="txtFullName" size="40" hint="Full name of the user." />
<checkbox label="Active?" name="IsActive" id="chkIsActive" hint="Check to indicate that this user is currently active." value="0" />
<spacer height="10" />
<hgroup>
<button controlClass="commandButton" caption="Roles" onclick="zenPage.roleButton();" 
title="View a list of the workflow roles associated with this workflow user" />
<spacer width="5" />
<button controlClass="commandButton" caption="Tasks" onclick="zenPage.taskButton();" 
title="View a list of the workflow tasks associated with this workflow user" />
</hgroup>
</form>
</vgroup>
</hgroup>
</pane>
}

ClientMethod roleButton() [ Language = javascript ]
{
	var val = zen('table').getProperty('value');
	if (val.length > 0) zenPage.showRoles(val);
	else alert($$$Text("First choose a user from the table, then click Roles to see the workflow roles associated with that user."));
}

/// Show the roles held by this user
ClientMethod showRoles(name) [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.WorkflowUserRoles.zen?USER='+name),'','status,scrollbars,resizable=yes,width=400,height=400');
}

ClientMethod taskButton() [ Language = javascript ]
{
	var val = zen('table').getProperty('value');
	if (val.length > 0) zenPage.showTasks(val);
	else alert($$$Text("First choose a user from the table, then click Tasks to see the workflow tasks associated with that user."));
}

/// Show the tasks assigned to this user
ClientMethod showTasks(name) [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.WorkflowUserTasks.zen?USER='+name),'','status,scrollbars,resizable=yes,width=1100,height=400');
}

/// Draw the contents of the description panel.
Method DrawDescription(pSeed As %String) As %Status
{
	Write $$$Text("Workflow User Profiles define information about the workflow users that may connect to your system.")
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Workflow User Profiles")
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Workflow User Profiles")
}

/// User selected a row in the table
ClientMethod rowSelected(table) [ Language = javascript ]
{
	// update details pane using ID value from table
	var idx = table.selectedIndex
	if (idx >= 0) {
		var id = table.getProperty('value');
		this.UpdateDetails(id);
	} else {
		this.resetForm();
	}
}

/// Update contents of details pane.
ClassMethod UpdateDetails(id) [ ZenMethod ]
{
	// try to open the object
	Set tObj = ##class(EnsLib.Workflow.UserDefinition).%OpenId(id)
	If $IsObject(tObj) {
		// note: remember ID and Name seperately so that we can track name changes
		&js<
			zen('txtID').setValue('#($ZCVT(id,"O","JS"))#');
			zen('txtName').setValue('#($ZCVT(id,"O","JS"))#');
			zenPage.getComponentById('txtFullName').setValue('#($ZCVT(tObj.FullName,"O","JS"))#');
			zenPage.getComponentById('chkIsActive').setValue('#(tObj.IsActive)#');
		>
	}
	Else {
		&js<alert($$$Text("Cannot open object!"));>
	}
	Quit
}

/// Reset the form programmatically
ClientMethod resetForm() [ Language = javascript ]
{
	var form = zen('bpForm');
	form.reset();
}

/// User clicked Delete button.
ClientMethod deleteItem() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var id = zen('table').getProperty('value');
	if ((id!='') && confirm($$$Text('Are you sure you want to delete this item?'))) {
		var msg = this.DeleteID(id);
		if (''!=msg) {
			alert(msg);
		}
		else {
			//zen('table').executeQuery(); // causes page to hang several seconds
			window.location.reload(); // this works instead
		}
	}
}

/// Delete the given id.
ClassMethod DeleteID(id) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(EnsLib.Workflow.UserDefinition).%DeleteId(id)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = $$$Text("Workflow User Viewer")
	Quit $$$OK
}

/// Draw Yes or No in place of 1 or 0
Method DrawYesNo(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query(pName) { Write $$$Text("Yes") } 
	Else { Write $$$Text("No") } 
	Quit $$$OK
}

/// Save the contents of the form.
ClientMethod save() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	
	var id = zen('txtID').getValue();
	var name = zen('txtName').getValue();

	if (name == '') {
		alert($$$Text('Please provide a name for this item.'));
		return;
	}

	if ((id!='')&&(id!=name)) {
		if (!confirm($$$Text('Do you wish to rename this item? This will not rename references to this item.'))) {
			return;
		}
	}

	var form = zen('bpForm');
	var data = form.getValuesAsObject();
	var msg = this.SaveItem(data);
	if (msg != '') {
		alert(msg);
	}
	else {
		//zen('table').executeQuery(); // causes page to hang several seconds
		window.location.reload(); // this works instead
	}
}

ClassMethod SaveItem(pItem As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		// DP-405772 - Ensure every new workflow user bing saved is a defined system user. Normalize the name
		// to that of the security definition if the string entered differs only in case.
		Set tSC = $$$ParseUsername(pItem.Name,.tNormalizedID)
		If $$$ISERR(tSC) Quit
		Set pItem.Name = tNormalizedID
		Set pItem.ID = tNormalizedID
	
		// do some validation on the name
		Set name = pItem.Name
		If '..IsValidUser(name) {
			Set tMsg = $$$Text("This name is not a valid username")
			Quit
		}
		
		// test to see if we are replacing an old item, modifying an old item, or creating a new item
		Set id = pItem.ID
		If ((id'="")&&##class(EnsLib.Workflow.UserDefinition).%ExistsId(id)) {
			If (name'=id) {
				// rename: delete old item
				Set tSC = ##class(EnsLib.Workflow.UserDefinition).%DeleteId(id)
				Set tClsDef = ##class(EnsLib.Workflow.UserDefinition).%New()
			}
			Else {
				// modify old item
				Set tClsDef = ##class(EnsLib.Workflow.UserDefinition).%OpenId(name)
			}
		}
		Else {
			// should be new!
			If (##class(EnsLib.Workflow.UserDefinition).%ExistsId(name)) {
				Set tMsg = $$$Text("This name is already in use")
				Quit 
			}
			Set tClsDef = ##class(EnsLib.Workflow.UserDefinition).%New()
		}

		// populate object properties
		Set tClsDef.Name = pItem.Name
		Set tClsDef.FullName = pItem.FullName
		Set tClsDef.IsActive = pItem.IsActive	
		Set tSC = tClsDef.%Save()

		If $$$ISOK(tSC) {
			// return new id value
			&js<zen('txtID').setValue('#($ZCVT(tClsDef.%Id(),"O","JS"))#')>
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

ClassMethod IsValidUser(pName As %String) As %Boolean
{
	// see if it's a valid username
	Quit $SYSTEM.SQL.UserExists(pName)
}

/// This client event is fired when the page is resized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		if (this.inResizeLoop()) return;
		zen('pane').setHidden(false);

		var descDiv = zen('descriptionPanel').getEnclosingDiv();
		var tgDiv = zen('tableGroup').getEnclosingDiv();
		var tableDiv = zen('table').getEnclosingDiv();
		var detailDiv = zen('detailGroup').getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25;

		var tableHgt = hgt;
		var tableWid = winWidth - descDiv.offsetWidth - detailDiv.offsetWidth;

		descDiv.style.height = tableHgt + 'px';
		detailDiv.style.height = tableHgt + 'px';
		tgDiv.style.height = tableHgt + 'px';
		tgDiv.style.width = tableWid + 'px';
		tableDiv.style.width = tableWid + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"DeleteID": ..#EDITRESOURCE,
				"SaveItem": ..#EDITRESOURCE,
				: "")
}

}
