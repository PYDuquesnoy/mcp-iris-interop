/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created using the page template: Default
Class Ens.Enterprise.Portal.MonitorRoleList Extends (EnsPortal.Template.standardPage, Ens.Enterprise.Portal.base) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Enterprise Monitor Roles";

Parameter RESOURCE = "%Ens_MsgBank:READ";

Parameter EDITRESOURCE = "%Ens_MsgBankConfig:WRITE";

Property canViewEvents As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MsgBankEventLog).#RESOURCE)} ];

Property canViewMessages As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MsgBankViewer).#RESOURCE)} ];

Property canViewSearch As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.EnterpriseSearch).#RESOURCE)} ];

Property canViewMonitor As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MonitorStatus).#RESOURCE)} ];

Property NewRole As %Boolean [ InitialExpression = 0 ];

/// User needs READ permissions on the %Ens_MsgBank resource to view this page.
/// User needs WRITE permissions on the %Ens_MsgBankConfig resource to make changes on this page.
/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
   
/*fieldSet styles*/
.fieldset{
     background: #FFFFFF;
     border: solid 2px #ebf3ff;
     color: #000000;
     font-size: 1em;
     font-family: helvetica;

}

table.group td.msgBankLink {
	text-align: center;
	padding-left: 30px;
	padding-right: 30px;
}
</style>
}

/// This XML block defines the contents of this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<titleBox id="idTitle" title="" />
<hgroup width="100%">
<spacer width="1em"/>
<vgroup>
<spacer height="1em"/>
<hgroup>
<tableNavigator id="connectionsNav" tablePaneId="RolesTable"/>
<spacer width=".5em"/>
<button caption="New Role" id="openNewRoleForm" onclick="zenPage.openNewRoleForm()"/>
<spacer width="50em"/>
</hgroup>
<spacer height="1em"/>
<tablePane
    width="90%"
    id="MonitorRoleTable"
    queryClass="Ens.Enterprise.MonitorRole"
    queryName="EnumerateMonitorRoles"
    maxRows="1000" 
    pageSize="10" 
    useSnapshot="true"
    rowSelect="false"
    extraColumnWidth="5%"
    showZebra="true"
    caption="Client Systems">
<column colName="ID" hidden="true" width="4%"/>
<column header="Monitor Role" width="40%" colName="MonitorRole" filterType="text"/>
<column header="Viewable Categories" width="60%" colName="Categories" filterType="text"/>
<column header="" width="4%" linkCaption="edit" 
         link="javascript:zenPage.showRoleForm('#(%query.ID)#');"/>
<column header="" width="4%" linkCaption="delete" 
         link="javascript:zenPage.maybeDelete('#(%query.ID)#');"/>
</tablePane>
<spacer height="1em"/>
<html OnDrawContent="DrawMsgBankLinks" />
<spacer height="1em"/>
<fieldSet id="roleFormGroup" hidden="true" legend="Edit monitor role info">
<form id="roleForm" 
         controllerId="rolesData" 
         layout="vertical"
         cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
 
<text label="Role:" required="true" dataBinding="MonitorRole" id="MonitorRole" name="MonitorRole" size="40"/>
<!--<text label="Categories: " dataBinding="Categories" id="Categories" name="Categories" required="true"
           size="50" title="Please enter category names for this role, separated by commas"/>-->
<!--<selector label="Categories: " dataBinding="Categories" id="Categories" name="Categories"
	     title="Please enter categories names for this role, separated by commas" />-->
<!--<selector id="Categories" label="Categories" title="Monitor Categories. Select from the list below or enter your own" context="Ens/MonitorCategories" multiSelect="true" onchange="zenPage.selectCategories();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />-->
<selector id="Categories" label="Categories" title="Monitor Categories. Select from the list below or enter your own" context="Ens/MonitorCategories" dataBinding="Categories" multiSelect="true" onchange="zenPage.selectCategories();" />
<button caption="Save" id="save" onclick="zenPage.saveRoleInfo();" />
<spacer width=".5em"/>
<button caption="Hide Form" onclick="zenPage.hideRoleForm();" />  
</form>
</fieldSet>
<hgroup width="5px"/>
</vgroup>
</hgroup>
<dataController id="rolesData"  
    modelClass="Ens.Enterprise.MonitorRole" 
    modelId=""
/>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (zenPage.NewRole) {
		zenPage.openNewRoleForm();
	}
}

ClientMethod hideRoleForm() [ Language = javascript ]
{
	var roleFormGroup=zenPage.getComponentById("roleFormGroup");
	roleFormGroup.setProperty('hidden',true);
}

ClientMethod openNewRoleForm() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('rolesData');
	controller.createNewObject();
	var roleFormGroup = zen("roleFormGroup");
	roleFormGroup.setProperty('legend', $$$Text('Info for new monitor role'));
	roleFormGroup.setProperty('hidden',false);
	var roleControl = zen('MonitorRole');
	roleControl.setProperty('readOnly',false);
	roleControl.setProperty('disabled',false);
}

ClientMethod showRoleForm(id) [ Language = javascript ]
{
	var controller = zen('rolesData');
	controller.setProperty('modelId',id);
	var roleFormGroup = zen("roleFormGroup");
	roleFormGroup.setProperty('legend', $$$Text('Edit monitor roles'));
	var roleControl = zen('MonitorRole');
	var disableRoleControl = (roleControl.getValue() != '');
	var roleTitle = (disableRoleControl ? $$$Text('To change the role name you must delete and recreate this entry.') : '');
	roleControl.setProperty('title',roleTitle);
	roleControl.setProperty('readOnly',disableRoleControl);
	roleControl.setProperty('disabled',disableRoleControl);
	//var table=zenPage.getComponentById('MonitorRoleTable');
	var roleCategories = zen('Categories');
	roleCategories.setProperty('valueList',roleCategories.getValue());
	roleCategories.setProperty('displayList',roleCategories.getValue());
	roleFormGroup.setProperty('hidden',false);
}

/// save connections model to database
ClientMethod saveRoleInfo() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	// validate and save form
	var form = zenPage.getComponentById('roleForm');
	form.save();
	var table=zenPage.getComponentById('MonitorRoleTable');
	//refresh data in connections table
	table.executeQuery();
}

/// Delete current item from database- after confirming
ClientMethod maybeDelete(id) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	var controller = zenPage.getComponentById('rolesData');

	if ('' == id) {
		alert('Nothing selected to delete.');
	}
	else if (confirm('Do you wish to delete this item?')) {
		controller.deleteId(id);

		var table = zenPage.getComponentById('MonitorRoleTable');
		table.executeQuery();
		//controller.update();
	}
}

/// Apply changes from role/category form.
ClientMethod selectCategories() [ Language = javascript ]
{
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Set ..%GetComponentById("idTitle").title = $$$FormatText($$$Text("View and edit participating monitor roles"))

	// Set data controller to be readOnly if the user can't edit
	Set tController = ..%GetComponentById("rolesData")
	Set tController.readOnly = '..canEdit
	
	// Open New role form is specified in request
	Set ..NewRole = +$G(%request.Data("NEWROLE",1))

	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit $$$Text("Enterprise Monitor Roles")
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Enterprise Monitor Roles")
}

Method DrawMsgBankLinks(pSeed) As %Status
{
	Set tDisabledAttr = "onclick=""return false;"" class=""msgBankLink disabledMsgBankLink"" title="""_..msgNotPermitted_""""
	&html<<table class="group" cellpadding="0" cellspacing="0" border="0" style="font-size: 0.9em;">
	<tr>>
	If ..canViewMonitor {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.MonitorStatus.zen"))#">#($$$TextHTML("Enterprise Monitor"))#</a></td>>
	} else {
		&html<<td class="msgBankLink">#($$$TextHTML("Enterprise Monitor"))#</td>>
	}
	
	If ..canViewSearch {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.EnterpriseSearch.zen"))#">#($$$TextHTML("Enterprise Message Viewer"))#</a></td>>
	} else {
		&html<<td class="msgBankLink">#($$$TextHTML("Enterprise Message Viewer"))#</td>>
	}
	
	If ..canViewMessages {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.MsgBankViewer.zen"))#">#($$$TextHTML("Message Bank Viewer"))#</a></td>>
	} else {
		&html<<td class="msgBankLink">#($$$TextHTML("Message Bank Viewer"))#</td>>
	}
	
	If ..canViewEvents {
		&html<<td class="msgBankLink"><a href="#(..%Link("Ens.Enterprise.Portal.MsgBankEventLog.zen"))#">#($$$TextHTML("Message Bank Event Log"))#</a></td>>
	} else {
		&html<<td class="msgBankLink">#($$$TextHTML("Message Bank Event Log"))#</td>>
	}
	
	&html<</tr>
	</table>>
	Quit $$$OK
}

}
