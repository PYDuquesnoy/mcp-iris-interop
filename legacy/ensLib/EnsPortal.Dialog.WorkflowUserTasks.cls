/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to show the workflow tasks assigned to a workflow user.
Class EnsPortal.Dialog.WorkflowUserTasks Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs READ permissions on the %Ens_WorkflowConfig resource to view this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:READ";

/// Displayed name of this page.
Parameter PAGENAME = "View Tasks for a User";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property initialUser As %ZEN.Datatype.string(ZENURL = "USER");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<tablePane id="table2" 
    cellSpacing="2"
	dataSource="columns"
	queryClass="EnsLib.Workflow.Engine"
	queryName="ListTasksForUser"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="Name"
	maxRows="10000"
	>
	<parameter value="#(%page.initialUser)#"/>
<column header="ID" colName="ID" style="text-align:left;"/>
<column header="New" colName="New" />
<column header="Priority" colName="Priority" />
<column header="Time Created" colName="TimeCreated"  />
<column header="Age" colName="Age" />
<column header="Role Name" colName="RoleName" />
<column header="Assigned To" colName="AssignedTo" />
<column header="User Name" colName="UserName" />
<column header="Subject" colName="Subject" />
<column header="Message" colName="Message" />

<condition colName="New" predicate="EQ" value="New" rowStyle="font-weight: bold;"/>
<condition colName="AssignedTo" predicate="EQ" value="{UserName}" rowStyle="background: #AAAAFF;"/>
<condition colName="AssignedTo" predicate="NEQ" value="{UserName}" rowStyle="background: yellow;;"/>

</tablePane>
</pane>
}

/// This dialog does not return a value
ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $zconvert(..initialUser,"O","HTML")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Tasks for this User")
}

}
