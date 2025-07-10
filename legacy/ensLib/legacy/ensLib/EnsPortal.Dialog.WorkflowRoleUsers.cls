/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to show the workflow users belonging to a workflow role.
Class EnsPortal.Dialog.WorkflowRoleUsers Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs READ permissions on the %Ens_WorkflowConfig resource to view this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:READ";

/// Displayed name of this page.
Parameter PAGENAME = "View Users in a Role";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property initialRole As %ZEN.Datatype.string(ZENURL = "ROLE");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<tablePane id="table1" 
    cellSpacing="2"
	dataSource="columns"
	queryClass="EnsLib.Workflow.Engine"
	queryName="ListUsersForRole"
	useSnapshot="true"
	showZebra="true"
	showRowNumbers="false"
	valueColumn="Name"
	maxRows="10000"
	>
	<parameter value="#(%page.initialRole)#"/>
<column header="User" colName="UserName" />
<column header="Full Name" colName="FullName"  />
<column header="Rank" colName="Ranking" style="text-align:left;" />
<column header="Title" colName="Title" OnDrawCell="DrawBlankNone" />
<column header="Active?" colName="IsActive" OnDrawCell="DrawYesNo" />
</tablePane>
</pane>
}

/// Draw (none) in place of blank
Method DrawBlankNone(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If (%query(pName) '= "") { Write ..EscapeHTML(%query(pName)) } 
	Else { Write $$$Text("(none)") } 
	Quit $$$OK
}

/// Draw Yes or No in place of 1 or 0
Method DrawYesNo(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query(pName) { Write $$$Text("Yes") } 
	Else { Write $$$Text("No") } 
	Quit $$$OK
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
	Quit $$$TextHTML("Users in this Role")
}

}
