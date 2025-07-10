/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// API for Business Process milestones.<br>
/// This class is readonly and has its storage directly mapped
/// to the Ens.BPL.Milestone global.
Class Ens.Milestone Extends %Persistent [ ClassType = persistent, Final, ProcedureBlock, System = 4 ]
{

Parameter READONLY = 1;

Index IDKEY On (SessionId, ContextId) [ IdKey ];

/// Session id of milestone.
Property SessionId As %String(MAXLEN = 128);

/// Business process context id of milestone.
Property ContextId As %String(MAXLEN = 128);

/// Last saved value of milestone.
Property LastValue As %String(MAXLEN = 1000);

/// Time of last update to this milestone.
Property LastUpdate As Ens.DataType.UTC;

/// Return the set of all current Business Process milestones.
Query EnumerateMilestones() As %SQLQuery
{
SELECT SessionId,ContextId,LastUpdate,LastValue FROM Milestone
}

/// Return the set of sessions containing milestones.
Query EnumerateMilestonesForSession(pSessionId As %String = "") As %SQLQuery
{
SELECT ContextId,LastUpdate,LastValue FROM Milestone 
WHERE SessionId = :pSessionId
}

/// Return the set of sessions containing milestones.
Query EnumerateSessions() As %SQLQuery
{
SELECT DISTINCT SessionId FROM Milestone
}

Storage Default
{
<Data name="MilestoneDefaultData">
<Attribute>LastValue</Attribute>
<Value name="1">
<Value>LastUpdate</Value>
</Value>
<Value name="2">
<Value>LastValue</Value>
</Value>
</Data>
<Data name="MilestoneDefaultData1">
<Subscript>"1"</Subscript>
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^Ens.BPL.Milestone</DataLocation>
<DefaultData>MilestoneDefaultData1</DefaultData>
<IdLocation>^Ens.BPL.Milestone</IdLocation>
<IndexLocation>^Ens.MilestoneI</IndexLocation>
<StreamLocation>^Ens.MilestoneS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
