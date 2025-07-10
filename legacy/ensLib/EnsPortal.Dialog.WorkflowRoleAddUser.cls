/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.WorkflowRoleAddUser Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_WorkflowConfig resource to view this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Add a User to a Role";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property initialRole As %ZEN.Datatype.string(ZENURL = "ROLE");

Property retValue As %ZEN.Datatype.string;

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<dataCombo id="UserName" label="User Name" queryClass="EnsLib.Workflow.Engine" queryName="ListUsers" 
			displayColumns="1,2" valueColumn="1" choiceColumn="1" size="40" maxRows="0"
            title="Select a user from the list of workflow users. Click OK to add it to the role." >
</dataCombo>
<combobox id="Rank" label="Rank" valueList="1,2,3,4,5" displayList="1,2,3,4,5"  
            title="Select a rank for the user." />
<text id="Title" label="Title" 
            title="Select a priority for the task." />
</pane>
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zenPage.retValue;
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var userName = ""
	var rank = ""
	var title = ""
	var userName = zen("UserName").getValue();
	var rank = zen("Rank").getValue();
	var title = zen("Title").getValue();

	var ret = zenPage.SaveData(zenPage.initialRole,userName,rank,title);
	if (ret.match('Error')) {
		alert(ret);
		zenPage.retValue = 'Error';
		return false;
	}
	else {
		zenPage.retValue = 'Changed';
		return true;
	}
}

ClassMethod SaveData(ourRole, userName, userRank, userTitle) As %String [ ZenMethod ]
{
	Set tRole = ##class(EnsLib.Workflow.RoleDefinition).%OpenId(ourRole)
	if 'tRole {
		Quit "Error: unable to open role object on server"
	}
	
	Set dup = 0
	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "EnsLib.Workflow.RoleDefinition"
	Set tRS.QueryName = "UsersForRole"
	Set tSC = tRS.Execute(ourRole)
	If 'tSC Quit $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	
	While (tRS.Next()) {
		If $G(tRS.Data("UserName")) = userName {
			Set dup = 1
			Continue
		}
	}
	If dup { 
		Quit "Error: a user by this name is already a member of this role" 
	}
	
	Set tSC = tRole.AddUserToRole(ourRole,userName,userRank,userTitle)
	If 'tSC Quit $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	
	Quit ""
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $zconvert(..initialRole,"O","HTML")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Add User to this Role")
}

}
