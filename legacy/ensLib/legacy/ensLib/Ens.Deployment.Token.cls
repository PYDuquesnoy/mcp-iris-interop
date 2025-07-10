/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Before a deployment of changes to a production can be made 
/// the process must be able to open for Exclusive use this object
/// where the id is "DeployToken".
/// This is to limit one deployment per namespace.
Class Ens.Deployment.Token Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Parameter DEFAULTCONCURRENCY = 4;

Property InProgress As %Boolean [ InitialExpression = 0 ];

Property Username As %String(MAXLEN = 128);

Property ForcedClearUser As %String(MAXLEN = 128);

Property Job As %String(MAXLEN = 128);

Property OpenedTime As Ens.DataType.UTC;

Property StartTime As Ens.DataType.UTC;

Property EndTime As Ens.DataType.UTC;

Property SystemStart As %Integer;

Property SourceMachine As %String(MAXLEN = 128);

Property TargetMachine As %String(MAXLEN = 128);

Property SourceInstance As %String(MAXLEN = 128);

Property TargetInstance As %String(MAXLEN = 128);

Property SourceNamespace As %String(MAXLEN = 128);

Property TargetNamespace As %String(MAXLEN = 128);

Property SourceProduction As %String(MAXLEN = 128);

Property TargetProduction As %String(MAXLEN = 128);

Property InvocationId As %String;

Property IsARollback As %String [ InitialExpression = 0 ];

Index TargetID On Token [ IdKey ];

/// This is used to ensure that only one token object can exist.
Property Token As %String(VALUELIST = ",DeployToken") [ InitialExpression = "DeployToken" ];

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..%Concurrency = 4
	Quit $$$OK
}

Storage Default
{
<Data name="TokenDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>InProgress</Value>
</Value>
<Value name="3">
<Value>Username</Value>
</Value>
<Value name="4">
<Value>ForcedClearUser</Value>
</Value>
<Value name="5">
<Value>Job</Value>
</Value>
<Value name="6">
<Value>OpenedTime</Value>
</Value>
<Value name="7">
<Value>StartTime</Value>
</Value>
<Value name="8">
<Value>EndTime</Value>
</Value>
<Value name="9">
<Value>SystemStart</Value>
</Value>
<Value name="10">
<Value>SourceMachine</Value>
</Value>
<Value name="11">
<Value>TargetMachine</Value>
</Value>
<Value name="12">
<Value>SourceInstance</Value>
</Value>
<Value name="13">
<Value>TargetInstance</Value>
</Value>
<Value name="14">
<Value>SourceNamespace</Value>
</Value>
<Value name="15">
<Value>TargetNamespace</Value>
</Value>
<Value name="16">
<Value>SourceProduction</Value>
</Value>
<Value name="17">
<Value>TargetProduction</Value>
</Value>
<Value name="18">
<Value>InvocationId</Value>
</Value>
<Value name="19">
<Value>IsARollback</Value>
</Value>
</Data>
<DataLocation>^Ens.Deployment.TokenD</DataLocation>
<DefaultData>TokenDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Deployment.TokenD</IdLocation>
<IndexLocation>^Ens.Deployment.TokenI</IndexLocation>
<StreamLocation>^Ens.Deployment.TokenS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
