/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ML.ValidationRun Extends %Persistent [ System = 4 ]
{

Property TrainedModel As TrainedModel [ Required ];

/// Validation Run name
Property Name As %String(MAXLEN = 275) [ Required ];

/// Time started (UTC)
Property StartedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($ZTIMESTAMP,3,1,3)}, Required ];

/// Time completed (UTC)
Property CompletedAt As %TimeStamp;

/// Training duration (in seconds)
Property ValidationDuration As %Numeric [ SqlComputeCode = {Set {*}=##class(%ML.TrainingRun).GetInterval({StartedAt},{CompletedAt})}, SqlComputed, Transient ];

/// Training query
Property ValidationQuery As %String(MAXLEN = 32000);

/// Validation status
Property RunStatus As %String(DISPLAYLIST = ",Running,Completed,Failed", VALUELIST = ",running,completed,failed") [ InitialExpression = "running" ];

/// Validation error (if encountered)
Property StatusCode As %Status [ InitialExpression = {$$$OK} ];

/// Validation log output
Property Log As %Stream.GlobalCharacter;

/// Settings for this training run
Property Settings As %Library.DynamicObject;

/// ValidationRunLocked 1 if we cannot acquire a locko on this validation run, otherwise 0
Property ValidationRunLocked As %Boolean [ Calculated, Private, SqlComputeCode = { lock +^IRIS.ML.ValidationRun({%%ID}):0 if $test { set {*}=0 lock -^IRIS.ML.ValidationRun({%%ID}) } else { set {*}=1 }}, SqlComputed ];

/// Optional reference to training run from which these results were gathered, if gathered at TRAIN time
Property TrainingRun As TrainingRun;

Index NameIndex On Name [ Unique ];

/// 
/// Log a timestamped message to the validation log
/// 
Method LogMsg(msg As %String, save As %Boolean = 1) As %Status [ Internal ]
{
	set tSC = ..Log.WriteLine($ZDATETIME($now(),3,1,3)_": "_msg)
	quit $s($$$ISOK(tSC)&&save:..%Save(), 1:tSC)
}

Storage Default
{
<Data name="Settings">
<Attribute>Settings</Attribute>
<Structure>node</Structure>
<Subscript>"Settings"</Subscript>
</Data>
<Data name="ValidationParameters">
<Attribute>ValidationParameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"ValidationParameters"</Subscript>
</Data>
<Data name="ValidationRunDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TrainedModel</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>StartedAt</Value>
</Value>
<Value name="5">
<Value>CompletedAt</Value>
</Value>
<Value name="6">
<Value>ValidationQuery</Value>
</Value>
<Value name="7">
<Value>RunStatus</Value>
</Value>
<Value name="8">
<Value>StatusCode</Value>
</Value>
<Value name="9">
<Value>Log</Value>
</Value>
<Value name="10">
<Value>TrainingRun</Value>
</Value>
</Data>
<DataLocation>^IRIS.ML.ValidationRunD</DataLocation>
<DefaultData>ValidationRunDefaultData</DefaultData>
<IdLocation>^IRIS.ML.ValidationRunD</IdLocation>
<IndexLocation>^IRIS.ML.ValidationRunI</IndexLocation>
<StreamLocation>^IRIS.ML.ValidationRunS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
