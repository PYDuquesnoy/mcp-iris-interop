/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to assign or reassign workflow tasks to workflow users.
Class EnsPortal.Dialog.WorkflowTaskAssign Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_WorkflowConfig resource to view this page.
Parameter RESOURCE = "%Ens_WorkflowConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Assign or Reassign Task";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property initialTask As %ZEN.Datatype.string(ZENURL = "TASK");

Property retValue As %ZEN.Datatype.string;

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup>
<spacer height="5"/>
<dataCombo id="TaskId" label="Task ID" 
          queryClass="EnsLib.Workflow.Engine" queryName="Tasklist" 
          valueColumn="1" choiceColumn="1" displayColumns="1,4,8" width="350"
          onchange="zenPage.onTaskChange(zenThis);"
            title="This is the task whose information is displayed in the form. Select another task and the information will change." />
<dataCombo id="UserName" label="User Name" queryClass="EnsLib.Workflow.Engine" queryName="ListActiveUsers" 
            title="Select a user from the list of active workflow users. This assigns the user to the task."/>
<combobox id="Priority" label="Priority" valueList="1,2,3,4,5" displayList="1,2,3,4,5" value="5" 
            title="Select a priority for the task." />
<checkbox id="CancelTask" label="Cancel?" value="0" 
            title="Select this field to cancel the task. The production must be running to cancel a task."/>
<spacer height="15" />
<text id="Subject" label="Subject" size="55" readOnly="true" 
		title="For information only. This field identifies the subject of the task."/>
</vgroup>
</pane>
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return zenPage.retValue;
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Assign or Reassign Task")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod onTaskChange(taskField) [ Language = javascript ]
{
	var taskId = taskField.getValue();
	var text = zenPage.GetFieldValues(taskId);
	var value = text.split(',');
	zen("UserName").setValue(value[0]);
	zen("Priority").setValue(value[1]);
	zen("Subject").setValue(value[2]);
	zen("CancelTask").setValue(false);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.
ClientMethod ondialogFinish(action) [ Language = javascript ]
{
	var taskId = zen("TaskId").getValue();
	var userName = zen("UserName").getValue();
	var priority = zen("Priority").getValue();
	var cancelTask = zen("CancelTask").getValue();
	
	var ret = zenPage.SaveData(taskId,userName,priority,cancelTask);
	if (ret != '') {
		alert(ret);
		zenPage.retValue = 'Error';
		return false;
	}
	else {
		zenPage.retValue = 'Changed';
		return true;
	}
}

/// The "task" that we are working with is the task response message. Get it and send it to 
/// workflow engine methods to change its status in response to the user's selections in the form.
ClassMethod SaveData(taskId, userName As %String = "", priority As %Integer = "", cancelTask As %Boolean) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(taskId,4,.tSC)
		If $$$ISERR(tSC) Quit

		If (cancelTask) { // complete task, mark as cancelled, quit
			Set tSC = ##class(EnsLib.Workflow.Engine).CompleteTask(tTask)
			Quit
		}
		
		If (priority '= "") { // set task priority to new value
			Set tTask.%Priority = priority
		}

		If (userName = "") { // unassign task, then SendToAll to have it appear in worklists
			Set tSC = ##class(EnsLib.Workflow.Engine).UnassignTask(tTask)
			If $$$ISERR(tSC) Quit
			Set tSC = ##class(EnsLib.Workflow.Engine).SendTaskToAll(tTask)
			If $$$ISERR(tSC) Quit
		}
		Else { // reassign task
			Set tSC = ##class(EnsLib.Workflow.Engine).AssignTask(tTask, userName)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) Quit $system.Status.GetErrorText(tSC)
	Quit ""
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	Quit:'tSC tSC
	
	Set task = ..%GetComponentById("TaskId")
	Set task.value = ..initialTask
	Set values = ..GetFieldValues(..initialTask)
	Set user = ..%GetComponentById("UserName")
	Set user.value = $P(values,",",1)
	Set prior = ..%GetComponentById("Priority")
	Set prior.value = $P(values,",",2)
	Set sub = ..%GetComponentById("Subject")
	Set sub.value = $P(values,",",3)
  	
	Quit $$$OK
}

/// Method called from %OnAfterCreatePage to get initial field values for the form
Method GetFieldValues(taskId As %String) As %String [ ZenMethod ]
{
	Set (user, prior, sub, time) = ""
	Set qSQL = "SELECT %ID As TaskId,%Priority As Priority,TaskStatus_AssignedTo As AssignedTo,%Subject As Subject FROM EnsLib_Workflow.TaskResponse Where %ID = "_taskId
	Set tRS = ##class(%ResultSet).%New()
	Set:tRS pSC = tRS.Prepare(qSQL)
	Set:pSC pSC = tRS.Execute()
  	While (pSC && tRS.Next(.pSC)) {
		Set user = tRS.Data("AssignedTo")
		Set prior = tRS.Data("Priority")
		Set sub = tRS.Data("Subject")
  	}
	Quit user_","_prior_","_sub
}

}
