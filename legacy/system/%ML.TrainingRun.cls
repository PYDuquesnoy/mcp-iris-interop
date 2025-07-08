/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// A model training run
/// 
Class %ML.TrainingRun Extends %Persistent [ ClassType = persistent, System = 4 ]
{

/// Model we are training with
Property Model As %ML.Model [ Required ];

/// Training Run name, same as the name for the cooresponding Trained Model
Property Name As %String(MAXLEN = 275) [ Required, SqlComputeCode = {if {Name}="" { set {*}=##class(%ML.TrainingRun).GetTrainingRunName({Model}) }}, SqlComputed, SqlComputeOnChange = %%INSERT ];

/// ML Provider that did the training
Property Provider As %String(MAXLEN = 128) [ Required ];

/// Time started (UTC)
Property StartedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($ZTIMESTAMP,3,1,3)}, Required ];

/// Time completed (UTC)
Property CompletedAt As %TimeStamp;

/// Training duration (in seconds)
Property TrainingDuration As %Numeric [ SqlComputeCode = {Set {*}=##class({%%CLASSNAME}).GetInterval({StartedAt},{CompletedAt})}, SqlComputed, Transient ];

/// Training query
Property TrainingQuery As %String(MAXLEN = 32000);

/// Training status
Property RunStatus As %String(DISPLAYLIST = ",Training,Completed,Failed", VALUELIST = ",training,completed,failed") [ InitialExpression = "training" ];

/// Training error (if encountered)
Property StatusCode As %Status [ InitialExpression = {$$$OK} ];

/// Training log output
Property Log As %Stream.GlobalCharacter;

/// Settings for this training run
Property Settings As %Library.DynamicObject;

/// ML Configuration for this training run
Property Configuration As %SYS.ML.Configuration;

/// TrainingRunLocked 1 if we cannot acquire a locko on this training run, otherwise 0
Property TrainingRunLocked As %Boolean [ Calculated, Private, SqlComputeCode = { lock +^IRIS.ML.TrainingRun({%%ID}):0 if $test { set {*}=0 lock -^IRIS.ML.TrainingRun({%%ID}) } else { set {*}=1 }}, SqlComputed ];

/// IRIS Process ID that performed the training
Property PID As %String [ InitialExpression = {$job} ];

Index NameIndex On Name [ Unique ];

/// 
/// Compute the difference in seconds between two timestamps
/// 
ClassMethod GetInterval(start As %TimeStamp, end As %TimeStamp) As %Numeric
{
	If (start'="") && (end'="") {
		Set sh = $ZDTH(start,3)
		Set eh = $ZDTH(end,3)
		Set s = ((+eh-+sh)*86400)+($P(eh,",",2)-$P(sh,",",2))
		Quit s
	} Else {
		Quit ""
	}
}

/// 
/// Compute the default name for this training run
/// // Model is the Oid of a Model
ClassMethod GetTrainingRunName(Model As %BigInt) As %String(MAXLEN=275)
{
	
	&sql(select Name into :modelname from %ML.Model where %ID = :Model)
	RETURN:SQLCODE'=0 "" // report error?
	RETURN modelname_"_t"_$i(^IRIS.ML.TrainingRunC(Model))
}

/// 
/// Log a timestamped message to the training log
/// 
Method LogMsg(msg As %String) As %Status [ CodeMode = expression ]
{
..Log.WriteLine($ZDATETIME($NOW(),3,1,3)_" "_msg)
}

/// 
/// Helper method for debugging etc.
/// 
Method %Dump() As %Status
{
	#dim status As %Status = $$$OK
	Try {

		Set hrule = $TR($J("",80)," ","=")
	
		Write hrule,!
		Write "       StartedAt = ",..StartedAt,!
		Write "     CompletedAt = ",..CompletedAt,!
		Write "       RunStatus = ",..RunStatusLogicalToDisplay(..RunStatus),!
		Write "      StatusCode = ",$system.Status.GetErrorText(..StatusCode),!
		Write "        Provider = ",..Provider,!
		Write "TrainingDuration = ",..TrainingDuration,"s",!
		Write "   TrainingQuery = ",..TrainingQuery,!
		Write !
		Write "Training Log: ",..Log.Size," chars(s)",!
		Write hrule,!
		Do ..Log.Rewind()
		Do ..Log.OutputToDevice()
		Write hrule,!

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

Storage Default
{
<Data name="Settings">
<Attribute>Settings</Attribute>
<Structure>node</Structure>
<Subscript>"Settings"</Subscript>
</Data>
<Data name="TrainingRunDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Model</Value>
</Value>
<Value name="3">
<Value>Provider</Value>
</Value>
<Value name="4">
<Value>StartedAt</Value>
</Value>
<Value name="5">
<Value>CompletedAt</Value>
</Value>
<Value name="6">
<Value>TrainingDuration</Value>
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
<Value>TrainingQuery</Value>
</Value>
<Value name="11">
<Value>Name</Value>
</Value>
<Value name="13">
<Value>Configuration</Value>
</Value>
<Value name="15">
<Value>PID</Value>
</Value>
</Data>
<DataLocation>^IRIS.ML.TrainingRunD</DataLocation>
<DefaultData>TrainingRunDefaultData</DefaultData>
<IdLocation>^IRIS.ML.TrainingRunD</IdLocation>
<IndexLocation>^IRIS.ML.TrainingRunI</IndexLocation>
<StreamLocation>^IRIS.ML.TrainingRunS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
