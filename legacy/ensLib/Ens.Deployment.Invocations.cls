/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This records the details of a particular deployment of 
/// changes to a production.
Class Ens.Deployment.Invocations Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Record if a deployment is in progress
Property InProgress As %Boolean [ InitialExpression = 0, SqlColumnNumber = 2 ];

/// Record if deployment completed
Property Completed As %Boolean [ InitialExpression = 0, SqlColumnNumber = 3 ];

Property SingleFailure As %String(MAXLEN = 512) [ SqlColumnNumber = 4 ];

Property RequiresManualIntervention As %String(MAXLEN = 512) [ SqlColumnNumber = 5 ];

/// Whether this deployment failed and was reverted.
Property Reverted As %Boolean [ SqlColumnNumber = 6 ];

Property Username As %String(MAXLEN = 128) [ SqlColumnNumber = 7 ];

Property Job As %String(MAXLEN = 128) [ SqlColumnNumber = 8 ];

Property ForcedClearUser As %String(MAXLEN = 128) [ SqlColumnNumber = 9 ];

Property StartTime As Ens.DataType.UTC [ SqlColumnNumber = 10 ];

Property EndTime As Ens.DataType.UTC [ SqlColumnNumber = 11 ];

Property SourceMachine As %String(MAXLEN = 128) [ SqlColumnNumber = 12 ];

Property TargetMachine As %String(MAXLEN = 128) [ SqlColumnNumber = 13 ];

Property SourceInstance As %String(MAXLEN = 128) [ SqlColumnNumber = 14 ];

Property TargetInstance As %String(MAXLEN = 128) [ SqlColumnNumber = 15 ];

Property SourceNamespace As %String(MAXLEN = 128) [ SqlColumnNumber = 16 ];

Property TargetNamespace As %String(MAXLEN = 128) [ SqlColumnNumber = 17 ];

Property SourceProduction As %String(MAXLEN = 128) [ SqlColumnNumber = 18 ];

Property TargetProduction As %String(MAXLEN = 128) [ SqlColumnNumber = 19 ];

Property DeploymentFilename As %String(MAXLEN = "") [ SqlColumnNumber = 21 ];

Property DeploymentFileStream As %Stream.GlobalBinary [ SqlColumnNumber = 31 ];

Property DeploymentRollbackFilename As %String(MAXLEN = "") [ SqlColumnNumber = 22 ];

Property DeploymentRollbackFileStream As %Stream.GlobalBinary [ SqlColumnNumber = 32 ];

Property DeploymentLogFilename As %String(MAXLEN = "") [ SqlColumnNumber = 23 ];

Property DeploymentLogFileStream As %Stream.GlobalCharacter [ SqlColumnNumber = 33 ];

Property CalledWithAutoRevert As %Boolean [ SqlColumnNumber = 24 ];

/// ID of roll back file used if this deployment was rolledback after being successfully applied 
Property RolledbackById As %String [ SqlColumnNumber = 25 ];

/// Roll back filename used if this deployment was rolledback after being successfully applied 
Property RolledbackBy As %String(MAXLEN = 128) [ SqlColumnNumber = 26 ];

/// Target of the deployment this was used as a rollback after being successfully applied
Property RollbackFor As %String(MAXLEN = 128) [ SqlColumnNumber = 27 ];

/// Whether this deployment was used as a rollback after being successfully applied
Property RollbackForId As %String [ SqlColumnNumber = 28 ];

Property ThisIsARollback As %String [ SqlColumnNumber = 29 ];

Property LastStatus As %Status [ InitialExpression = {$$$OK}, SqlColumnNumber = 30 ];

Index DeploymentRollbackFilename On DeploymentRollbackFilename;

Storage Default
{
<Data name="InvocationsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>InProgress</Value>
</Value>
<Value name="3">
<Value>Completed</Value>
</Value>
<Value name="4">
<Value>SingleFailure</Value>
</Value>
<Value name="5">
<Value>RequiresManualIntervention</Value>
</Value>
<Value name="6">
<Value>Reverted</Value>
</Value>
<Value name="7">
<Value>Username</Value>
</Value>
<Value name="8">
<Value>Job</Value>
</Value>
<Value name="9">
<Value>ForcedClearUser</Value>
</Value>
<Value name="10">
<Value>StartTime</Value>
</Value>
<Value name="11">
<Value>EndTime</Value>
</Value>
<Value name="12">
<Value>SourceMachine</Value>
</Value>
<Value name="13">
<Value>TargetMachine</Value>
</Value>
<Value name="14">
<Value>SourceInstance</Value>
</Value>
<Value name="15">
<Value>TargetInstance</Value>
</Value>
<Value name="16">
<Value>SourceNamespace</Value>
</Value>
<Value name="17">
<Value>TargetNamespace</Value>
</Value>
<Value name="18">
<Value>SourceProduction</Value>
</Value>
<Value name="19">
<Value>TargetProduction</Value>
</Value>
<Value name="20">
<Value>DeploymentFilename</Value>
</Value>
<Value name="21">
<Value>DeploymentFileStream</Value>
</Value>
<Value name="22">
<Value>DeploymentRollbackFilename</Value>
</Value>
<Value name="23">
<Value>DeploymentRollbackFileStream</Value>
</Value>
<Value name="24">
<Value>DeploymentLogFilename</Value>
</Value>
<Value name="25">
<Value>DeploymentLogFileStream</Value>
</Value>
<Value name="26">
<Value>CalledWithAutoRevert</Value>
</Value>
<Value name="27">
<Value>RolledbackById</Value>
</Value>
<Value name="28">
<Value>RolledbackBy</Value>
</Value>
<Value name="29">
<Value>RollbackFor</Value>
</Value>
<Value name="30">
<Value>RollbackForId</Value>
</Value>
<Value name="31">
<Value>ThisIsARollback</Value>
</Value>
<Value name="32">
<Value>LastStatus</Value>
</Value>
</Data>
<DataLocation>^Ens.Deployment.InvocationsD</DataLocation>
<DefaultData>InvocationsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Deployment.InvocationsD</IdLocation>
<IndexLocation>^Ens.Deployment.InvocationsI</IndexLocation>
<StreamLocation>^Ens.Deployment.InvocationsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
