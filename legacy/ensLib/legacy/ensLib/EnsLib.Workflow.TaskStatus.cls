/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Holds Task Status details used by Workflow Engine to manage tasks.
Class EnsLib.Workflow.TaskStatus Extends (%SerialObject, %XML.Adaptor, %CSP.Util.AutoForm) [ ClassType = serial, Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Role to which this task was sent to.
Property Role As EnsLib.Workflow.RoleDefinition [ Required, SqlFieldName = RoleName ];

/// Name of the user that has currently has ownership of the associated task (if any).
Property AssignedTo As %String(COLLATION = "EXACT", MAXLEN = 128);

/// The timestamp when this task was created.
Property TimeCreated As Ens.DataType.UTC [ InitialExpression = {$$$timeUTC} ];

/// The timestamp when this task was completed.
Property TimeCompleted As Ens.DataType.UTC;

/// SessionId for session that created this task.
Property SessionId As %Integer;

/// Name of the host that sent the task.
Property Source As %String(MAXLEN = 128);

/// Token identifying where final response will go to.
Property ResponseToken As %String(MAXLEN = 128);

/// Has the associated task been completed?
Property IsComplete As %Boolean [ InitialExpression = 0 ];

/// Link to original Task Request.
Property Request As TaskRequest [ Required ];

Storage Default
{
<Data name="TaskStatusState">
<Subscript>"EnsLib.Workflow.TaskStatus"</Subscript>
<Value name="1">
<Value>AssignedTo</Value>
</Value>
<Value name="2">
<Value>IsComplete</Value>
</Value>
<Value name="3">
<Value>Request</Value>
</Value>
<Value name="4">
<Value>ResponseToken</Value>
</Value>
<Value name="5">
<Value>Role</Value>
</Value>
<Value name="6">
<Value>SessionId</Value>
</Value>
<Value name="7">
<Value>Source</Value>
</Value>
<Value name="8">
<Value>TimeCompleted</Value>
</Value>
<Value name="9">
<Value>TimeCreated</Value>
</Value>
</Data>
<State>TaskStatusState</State>
<StreamLocation>^EnsLib.W.TaskStatusS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
