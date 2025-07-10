/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to show the workflow tasks assigned to a workflow role.
Class EnsPortal.Dialog.WorkflowRoleTasks Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs READ permissions on the %Ens_WorkflowConfig resource to view this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:READ";

/// Displayed name of this page.
Parameter PAGENAME = "View Tasks for a Role";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter OKBUTTON As BOOLEAN = 0;

Property initialRole As %ZEN.Datatype.string(ZENURL = "ROLE");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<tablePane id="table2" 
    cellSpacing="2"
	dataSource="columns"
	queryClass="EnsLib.Workflow.Engine"
	queryName="ListTasksForRole"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="TaskId"
	maxRows="10000"
	>
	<parameter value="#(%page.initialRole)#"/>
<column header="Task ID" colName="TaskId" />
<column header="Role Name" colName="RoleName" />
<column header="Complete?" colName="IsComplete" hidden="true" />
<column header="Status" colName="Status" />
<column header="Priority" colName="Priority" />
<column header="Source" colName="Source" />
<column header="Assigned To" colName="AssignedTo" />
<column header="Subject" colName="Subject" />
<column header="Time Created" colName="TimeCreated" />
<column header="Time Completed" colName="TimeCompleted" />

<condition colName="Status" predicate="EQ" value="Unassigned" cellStyle="background: yellow;"/>
<condition colName="Status" predicate="EQ" value="Assigned" cellStyle="background: #AAAAFF;"/>
<condition colName="Status" predicate="EQ" value="Discarded" cellStyle="background: #FFA0A0; color: #808080;"/>
<condition colName="Status" predicate="EQ" value="Cancelled" cellStyle="background: orange; color: #808080;"/>
<condition colName="Status" predicate="EQ" value="Completed" cellStyle="background: #D0D0D0; color: #808080;"/>
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
	Quit $zconvert(..initialRole,"O","HTML")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Tasks for this Role")
}

}
