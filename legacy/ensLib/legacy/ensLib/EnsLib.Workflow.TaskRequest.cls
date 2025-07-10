/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A task is a specialized request for a user action (it is used as part of a Workflow application).
Class EnsLib.Workflow.TaskRequest Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Default response class for TaskRequest is TaskResponse.
Parameter RESPONSECLASSNAME = "EnsLib.Workflow.TaskResponse";

/// (Optional) Comma-delimited list of Actions defined for this response.
/// This list defines what Action buttons are displayed when a User reviews a Task.
Property %Actions As %String(MAXLEN = 255);

/// (Optional) Short summary of this task.<br>
/// This is displayed in a User's Worklist.
Property %Subject As %String(MAXLEN = 255);

/// (Optional) Detailed message body for this task.<br>
/// This is displayed when a User views details for a Task.
Property %Message As %String(MAXLEN = 2000);

/// Priority of the requested Task: 1 is highest.
/// This is used to sort items within a User's Worklist.
Property %Priority As %Integer [ InitialExpression = 3 ];

/// (Optional) The name of the user that is preferred for handling this task.
/// Whether or not this user actually is assigned to the task depends
/// on how the distribution strategy used for this task.
Property %UserName As %String(MAXLEN = 128);

/// (Optional) The name of the title within the given that is preferred for handling this task.
/// Whether or not this user actually is assigned to the task depends
/// on how the distribution strategy used for this task.
Property %Title As %String(MAXLEN = 128);

/// (Optional) Name of response class (must be a subclass of EnsLib.Workflow.TaskResponse)
/// that is used to manage the distribution of this task.
/// It is also used as the response type for this request.
Property %TaskHandler As %String(MAXLEN = 128);

/// (Optional) Command string to be passed to the Task Handler.
/// Interpretation of this is up to the TaskHandler class used.
Property %Command As %String(MAXLEN = 255);

/// (Optional) Name of csp page that provides the form template for this task;
Property %FormTemplate As %String(MAXLEN = 255);

/// (Optional) Comma-separated list of fields that should appear in the form
/// associated with this Task.
Property %FormFields As %String(MAXLEN = 2000);

/// (Optional) Collection of values to display within the form displayed for this task.
Property %FormValues As array Of %String(MAXLEN = "") [ SqlFieldName = FormValues ];

/// This method is called when this message has timed out.
Method %OnTimeout() As %Status
{
	// caller is no longer interested in this task;
	// inform the Workflow Engine
	Set tSC = ##class(EnsLib.Workflow.Engine).%CancelRequest($this)
	Quit tSC
}

Storage Default
{
<Data name="%FormValues">
<Attribute>%FormValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"%FormValues"</Subscript>
</Data>
<Data name="TaskRequestDefaultData">
<Subscript>"TaskRequest"</Subscript>
<Value name="1">
<Value>%Actions</Value>
</Value>
<Value name="2">
<Value>%DistributionAgent</Value>
</Value>
<Value name="3">
<Value>%FieldList</Value>
</Value>
<Value name="4">
<Value>%Message</Value>
</Value>
<Value name="5">
<Value>%Priority</Value>
</Value>
<Value name="6">
<Value>%RequiredResponses</Value>
</Value>
<Value name="7">
<Value>%Subject</Value>
</Value>
<Value name="8">
<Value>%FormFields</Value>
</Value>
<Value name="9">
<Value>%FormURL</Value>
</Value>
<Value name="10">
<Value>%FormTemplate</Value>
</Value>
<Value name="11">
<Value>%Command</Value>
</Value>
<Value name="12">
<Value>%PreferredUser</Value>
</Value>
<Value name="13">
<Value>%UserName</Value>
</Value>
<Value name="14">
<Value>%TaskHandler</Value>
</Value>
<Value name="15">
<Value>%Title</Value>
</Value>
</Data>
<DefaultData>TaskRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
