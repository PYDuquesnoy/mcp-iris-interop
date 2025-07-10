/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Dialog.WorkflowRoleRemoveUser Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_WorkflowConfig resource to view this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Remove a User From a Role";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property initialRole As %ZEN.Datatype.string(ZENURL = "ROLE");

Property retValue As %ZEN.Datatype.string;

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<dataCombo id="UserName" label="User Name" queryClass="EnsLib.Workflow.Engine" queryName="ListUsersForRole" 
            displayColumns="1,2" valueColumn="1" choiceColumn="1" size="40"
            title="Select a user from the list of workflow users for this role. Click OK to remove it from the role." >
<parameter value="#(%page.initialRole)#" />
</dataCombo>
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
	var userName = zen("UserName").getValue();

	var ret = zenPage.RemoveData(zenPage.initialRole,userName);
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

ClassMethod RemoveData(ourRole, userName) As %String [ ZenMethod ]
{
	Set tRole = ##class(EnsLib.Workflow.RoleDefinition).%OpenId(ourRole)
	if 'tRole {
		Quit "Error: unable to open role object on server"
	}
	
	Set tSC = tRole.RemoveUserFromRole(ourRole,userName)
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
	Quit $$$TextHTML("Remove User From This Role")
}

}
