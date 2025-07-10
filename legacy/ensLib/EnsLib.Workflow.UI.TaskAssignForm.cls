/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsWorkflow)

/// An autoform for gathering Message Filter info
Class EnsLib.Workflow.UI.TaskAssignForm Extends (%RegisteredObject, %CSP.Util.AutoForm) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// TaskId
Property TaskId As %Integer;

/// User to assign task to (could be from a different role).
Property Name As %CSP.Util.Choice(CAPTION = "@Ensemble:UserName@User Name", CAPTIONCOLUMN = "UserName", QUERYCLASS = "EnsLib.Workflow.Engine", QUERYNAME = "ListActiveUsers");

/// Task Priority
Property Priority As %Integer(VALUELIST = ",1,2,3,4,5");

/// Cancel this task
Property CancelTask As %Boolean;

ClassMethod CreateInstance(ByRef pID As %String) As %CSP.Util.AutoForm
{
	Set tObj = ..%New()
	Set tObj.TaskId = $G(%request.Data("$ID1",1))
	Set tObj.Name = $G(%request.Data("$ID2",1))
	Set tObj.Priority = $G(%request.Data("$ID3",1))
	Set tObj.CancelTask = 0
	Quit tObj
}

Method OnSubmit(ByRef pID As %String, pSubmit As %String) As %Status
{
	Set tSC = $$$OK
	
	Do {
		Set tTask = ##class(EnsLib.Workflow.TaskResponse).%OpenId(..TaskId,4,.tSC)
		If $$$ISERR(tSC) Quit
		
		If (..CancelTask) {
			// complete task, mark as cancelled
			Set tSC = ##class(EnsLib.Workflow.Engine).CompleteTask(tTask)
			Quit
		}

		If (..Priority '= "") {
			Set tTask.%Priority = ..Priority
		}

		// validate Name
		If (..Name = "") {
			// unassign
			Set tSC = ##class(EnsLib.Workflow.Engine).UnassignTask(tTask)
			If $$$ISERR(tSC) Quit
		}
		Else {
			// reassign task
			Set tSC = ##class(EnsLib.Workflow.Engine).AssignTask(tTask, ..Name)
			If $$$ISERR(tSC) Quit
		}
	} While(0)

	Quit tSC
}

/// define buttons
ClassMethod OnDefineButtons(ByRef pButtons As %CSP.Util.FormButton)
{
	Set pButtons(1) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(1).Name = "$AUTOFORM_SAVE"
	Set pButtons(1).Caption = $$$Text("OK")
	
	Set pButtons(2) = ##class(%CSP.Util.FormButton).%New()
	Set pButtons(2).Name = "$AUTOFORM_CANCEL"
	Set pButtons(2).Caption = $$$Text("Cancel")
}

}
