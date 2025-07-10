/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Represents a worklist item associated with a User within a Workflow application.
Class EnsLib.Workflow.Worklist Extends %Persistent [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Identity Index
Index ID On (Task, User) [ IdKey ];

/// User cross-index
Index UserIdx On User As Exact;

/// Link to Task (TaskResponse) that created this item.
Property Task As EnsLib.Workflow.TaskResponse [ Required ];

/// The User this item is associated with.
Property User As UserDefinition [ Required, SqlFieldName = UserName ];

/// The Role this item is associated with.
Property Role As RoleDefinition [ Required, SqlFieldName = RoleName ];

/// The timestamp when this Item was placed into the worklist.
Property TimeCreated As Ens.DataType.UTC [ InitialExpression = {$$$timeUTC} ];

/// Has the user seen this item yet?
Property IsNew As %Boolean [ InitialExpression = 1 ];

/// Calculated Age of this item.
Property Age As %String [ Calculated, SqlComputeCode = { Set {Age}=##class(EnsLib.Workflow.Worklist).CurrentAge({TimeCreated})
}, SqlComputed, SqlComputeOnChange = TimeCreated ];

/// Overridden accessor method for the calculated <property>Age</property> property.
Method AgeGet() As %String [ CodeMode = expression ]
{
..CurrentAge(..TimeCreated)
}

/// This class method calculate the current age of this item.
ClassMethod CurrentAge(ts As Ens.DataType.UTC = "") As %String
{
	If (ts="") Quit ""

	Set tSecs = $System.SQL.DATEDIFF("ss",ts,$$$timeUTC)
	Set tWeeks = tSecs \ (86400*7)
	Set tSecs = tSecs - (tWeeks*86400*7)
	Set tDays = tSecs \ 86400
	Set tSecs = tSecs - (tDays*86400)
	Set tHours = tSecs \ 3600
	Set tSecs = tSecs - (tHours*3600)
	Set tMins = tSecs \ 60
	Set tSecs = tSecs - (tMins*60) \ 1
	
	Quit $TR(($J(tWeeks,2) _ "wx" _ $J(tDays,1) _ "dx" _ $J(tHours,2) _ "hx" _ $J(tMins,2) _ "mx" _ $J(tSecs,2) _ "s")," x","0 ")
}

Storage Default
{
<Data name="WorklistDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>IsNew</Value>
</Value>
<Value name="3">
<Value>Role</Value>
</Value>
<Value name="4">
<Value>TimeCreated</Value>
</Value>
</Data>
<DataLocation>^EnsLib.W.WorklistD</DataLocation>
<DefaultData>WorklistDefaultData</DefaultData>
<IdLocation>^EnsLib.W.WorklistD</IdLocation>
<IndexLocation>^EnsLib.W.WorklistI</IndexLocation>
<StreamLocation>^EnsLib.W.WorklistS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
