/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsWorkflow)

/// Response from a Workflow Task request.<br>
/// The Workflow Engine creates an instance of TaskResponse object
/// as soon it receives a TaskRequest. This object is used to maintain the
/// status of the task while it is under the control of the Workflow
/// Engine. It also serves as the final response returned by the
/// Workflow Engine when the task is complete.
Class EnsLib.Workflow.TaskResponse Extends Ens.Response [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Index RoleIdx On %TaskStatus.Role As Exact [ Type = bitmap ];

Index RequestIdx On %TaskStatus.Request;

/// The user action for this task.
/// This value is set when the task is completed.
Property %Action As %String(MAXLEN = 128);

/// Priority of the requested Task: 1 is highest;
/// This is a copy of the value provided from the initial request 
/// for this task.
Property %Priority As %Integer;

/// The name of the user that (last) handled this task.
/// This value is set when the task is completed.
Property %UserName As %String(MAXLEN = 128);

/// Title associated with User that (last) handled this task
/// (if the user has a role-assigned title).
Property %UserTitle As %String(MAXLEN = 128);

/// Ranking associated with User that (last) handled this task
/// (if the user has a role-assigned ranking).
Property %UserRanking As %Integer;

/// The name of the role that handled this task.
/// This value is set when the task is created.
Property %RoleName As %String(MAXLEN = 128);

/// (Optional) Short summary of this task.
/// This is a copy of the value provided from the initial request 
/// for this task.
Property %Subject As %String(MAXLEN = 255);

/// (Optional) Detailed message body for this task
/// This is a copy of the value provided from the initial request 
/// for this task.
Property %Message As %String(MAXLEN = 2000);

/// (Optional) Comma-delimited list of Actions defined for this response.
/// This is a copy of the value provided from the initial request 
/// for this task.
Property %Actions As %String(MAXLEN = 255);

/// (Optional) Name of csp page that provides the form template for this task.<br>
/// This is a copy of the value provided from the initial request 
/// for this task.
Property %FormTemplate As %String(MAXLEN = 255);

/// (Optional) comma-separated list of fields that should appear in the form
/// associated with this Task.<br>
/// This is a copy of the value provided from
/// the initial request for this task.
Property %FormFields As %String(MAXLEN = 2000);

/// Collection of values from the form associated with this task (if any).
Property %FormValues As array Of %String(MAXLEN = "") [ SqlFieldName = FormValues ];

/// The external Status of this task.
/// Used to query the current status of a task.
Property %Status As %String(MAXLEN = 50);

/// The internal Status of this task. Used by the Workflow Engine to manage this task.
/// User-code should not modify the contents of this object.
Property %TaskStatus As EnsLib.Workflow.TaskStatus [ SqlFieldName = TaskStatus ];

/// This method is called when a new Task is received by the Workflow Engine.
/// Default implementation does the following:<br>
/// If the request includes a valid, active UserName, assign task to that user.
/// Otherwise, make task available to all members of the current Role.
Method OnNewTask(pRequest As EnsLib.Workflow.TaskRequest) As %Status
{
	Do {
		Set tCount = 0

		// If there is a preferred user, directly assign task
		If (pRequest.%UserName '= "") {
			// try to assign to this user
			Set tSC = ..AssignTask(pRequest.%UserName,.tCount)
			If $$$ISERR(tSC) Quit

			If (tCount>0) Quit  // assigned 
		}

		// If there is a preferred title, send task to users with that title
		If (pRequest.%Title '= "") {
			// send task to requested Title within Role
			Set tSC = ..SendTaskToTitle(pRequest.%Title,.tCount)
			If $$$ISERR(tSC) Quit
			If (tCount>0) Quit  // if sent, quit
		}

		// !!! interpret %Command
	
		// send to everyone within the role
		Set tSC = ..SendTaskToAll(.tCount)
		If $$$ISERR(tSC) Quit
		
		// If there are no users, return error.
		If (tCount = 0) {
			Set tSC = $$$EnsError($$$EnsWfErrNoUsersFound)
			Quit
		}
	} While (0)

	Quit tSC
}

/// This method is called by the Workflow Engine when a user wishes 
/// to take ownership of the related task.<br>
/// Default implementation performs the assignment.
Method OnAssign(pUser As %String) As %Status
{
	// Assign this task to the request user
	Set tSC = ..AssignTask(pUser)
	Quit tSC
}

/// This method is called by the Workflow Engine when a user wishes 
/// to relinquish ownership of the related task.<br>
/// Default implementation unassigns the task.
Method OnRelinquish(pUser As %String) As %Status
{
	// Give up ownership of this task
	Set tSC = ..UnassignTask(pUser)
	Quit:$$$ISERR(tSC) tSC

	// now make it available to all users in the role
	Set tCount = 0
	Set tSC = ..SendTaskToAll(.tCount)
	Quit tSC
}

/// This method is called when a user takes an action on a Task.<br>
/// Default implementation completes the task.
Method OnAction(pAction As %String) As %Status
{
	// Complete this task, return the Action value to the initial requestor
	Set tSC = ..CompleteTask(pAction)
	Quit tSC
}

/// This method is called by the Workflow Engine when
/// a Task is cancelled.<br>
/// This happens when the original request times out.<br>
/// This method is called after all the Worklist items for this
/// task have been deleted and before this Task is deleted.
Method OnCancel() As %Status
{
	Quit $$$OK
}

/// This method is called by the Workflow Engine when
/// a User or Role definition associated with this task is
/// modified.<br>
/// <var>pName</var> is the User or Role name.<br>
/// <var>pOwned</var> is true if this user was the owner of this task.<br>
/// <var>pReason</var> describes the change and is one of the following:
/// <ul>
/// <li>$$$WfUserDeleted</li>
/// <li>$$$$$$WfUserInactivated</li>
/// <li>$$$WfRoleDeleted</li>
/// </ul>
Method OnRoleChange(pName As %String, pReason As %String, pOwned As %Boolean = 0) As %Status
{
	Quit $$$OK
}

/// This callback is invoked when the form associated with this task is submitted.
Method OnFormSubmit() As %Status
{
	Quit $$$OK
}

/* Workflow API methods */
/// This Workflow API method assigns a Task to a specific User.
Method AssignTask(pUser As %String, ByRef pCount As %Integer) As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).AssignTask($this,pUser,.pCount)
}

/// This Workflow API method unassign a Task associated with specific User.
/// Tests if <var>pUser</var> owns the task (if provided).
Method UnassignTask(pUser As %String = "") As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).UnassignTask($this,pUser)
}

/// This Workflow API method sends (but does not assign) a Task to a specific User.
/// <var>pUser</var> is the name of the user.
/// On return, <var>pCount</var> is number of users task was sent to.
Method SendTask(pUser As %String, Output pCount As %Integer) As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).SendTask($this,pUser,.pCount)
}

/// This Workflow API method sends (but does not assign) a Task to all Users within the current Role.
/// On return, <var>pCount</var> is number of users task was sent to.
Method SendTaskToAll(Output pCount As %Integer) As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).SendTaskToAll($this,.pCount)
}

/// This Workflow API method sends (but does not assign) a Task to all Users within the current Role
/// with title <var>pTitle</var>.
/// On return, <var>pCount</var> is number of users task was sent to.
Method SendTaskToTitle(pTitle As %String = "", Output pCount As %Integer) As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).SendTaskToTitle($this,pTitle,.pCount)
}

/// This Workflow API method sends (but does not assign) a Task to <var>pNum</var> top ranked
/// Users within the current Role.
/// On return, <var>pCount</var> is number of users task was sent to.
Method SendTaskToTop(pNum As %Integer = 1, Output pCount As %Integer) As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).SendTaskToTop($this,pNum,.pCount)
}

/// This Workflow API method marks a task as complete and 
/// returns a response to the original requestor.
Method CompleteTask(pAction As %String = "") As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).CompleteTask($this,pAction)
}

/// Find the name of the highest-ranked, active user within the given role that has the least
/// number of tasks (for any role) assigned to them.
/// On return <var>pCount</var> has current number of tasks for this user.
Method FindLeastBusyUser(Output pUserName As %String, Output pCount As %Integer) As %Status [ CodeMode = expression, Final ]
{
##class(EnsLib.Workflow.Engine).FindLeastBusyUser(..%RoleName,.pUserName,.pCount)
}

Method downloadLink() As %String [ Internal ]
{
	Quit ""
}

Storage Default
{
<Data name="%FormValues">
<Attribute>%FormValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"%FormValues"</Subscript>
</Data>
<Data name="TaskResponseDefaultData">
<Subscript>"TaskResponse"</Subscript>
<Value name="1">
<Value>%Action</Value>
</Value>
<Value name="2">
<Value>%Form</Value>
</Value>
<Value name="3">
<Value>%UserName</Value>
</Value>
<Value name="4">
<Value>%RoleName</Value>
</Value>
<Value name="5">
<Value>%TaskStatus</Value>
</Value>
<Value name="6">
<Value>%FormFields</Value>
</Value>
<Value name="7">
<Value>%FormTemplate</Value>
</Value>
<Value name="8">
<Value>%Actions</Value>
</Value>
<Value name="9">
<Value>%Message</Value>
</Value>
<Value name="10">
<Value>%Subject</Value>
</Value>
<Value name="11">
<Value>%Priority</Value>
</Value>
<Value name="12">
<Value>%Status</Value>
</Value>
<Value name="13">
<Value>%UserRanking</Value>
</Value>
<Value name="14">
<Value>%UserTitle</Value>
</Value>
</Data>
<DefaultData>TaskResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
