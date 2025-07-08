/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Results.Iterations Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %WebStress.Tests;

Property Script As %String(TRUNCATE = 1);

Property Generator As %String(TRUNCATE = 1);

Property Seconds As %Integer;

Property Processes As %Integer;

Property Sessions As %Integer;

Property Target As %Numeric(SCALE = 1);

Property TimeStart As %TimeStamp;

Property TimeStop As %TimeStamp;

Property RunDescription As %String(MAXLEN = 255, TRUNCATE = 1);

Property Minutes As %Numeric(SCALE = 1) [ Calculated, SqlComputeCode = {	new iID
	set iID = {ID}
	set {Minutes}=##class(%WebStress.Results.Iterations).%OpenId(iID,0).Minutes}, SqlComputed ];

Property Iterations As %Integer;

Property RatePerMinute As %Numeric(SCALE = 1) [ Calculated, SqlComputeCode = {	new iID
	set iID = {ID}
	set {RatePerMinute}=##class(%WebStress.Results.Iterations).%OpenId(iID,0).RatePerMinute}, SqlComputed ];

Property RatePerSecond As %Numeric(SCALE = 1) [ Calculated, SqlComputeCode = {	new iID
	set iID = {ID}
	set {RatePerSecond}=##class(%WebStress.Results.Iterations).%OpenId(iID,0).RatePerSecond}, SqlComputed ];

Index Main On (TestID, RunID, Script, Generator) [ IdKey, PrimaryKey, Unique ];

Method MinutesGet() As %Numeric
{
	quit $justify(..Seconds/60,0,1)
}

Method RatePerMinuteGet() As %Numeric
{
	quit $select(+(..Seconds)=0:0,1:$justify(..Iterations/(..Seconds/60),0,1))
}

Method RatePerSecondGet() As %Numeric
{
	quit $select(+(..Seconds)=0:0,1:$justify(..Iterations/..Seconds,0,1))
}

Query GetData() As %SQLQuery
{
SELECT TestID->Name,Script,Generator,Minutes,Processes,Sessions,Iterations,Target,RatePerMinute FROM Iterations
 ORDER BY Script, Generator
}

Storage Default
{
<Data name="ResultsIterationsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Iterations</Value>
</Value>
<Value name="3">
<Value>Seconds</Value>
</Value>
<Value name="4">
<Value>Processes</Value>
</Value>
<Value name="5">
<Value>Sessions</Value>
</Value>
<Value name="6">
<Value>Target</Value>
</Value>
<Value name="7">
<Value>Test</Value>
</Value>
<Value name="8">
<Value>TimeStart</Value>
</Value>
<Value name="9">
<Value>TimeStop</Value>
</Value>
<Value name="10">
<Value>RunDescription</Value>
</Value>
</Data>
<DataLocation>^WebStress.Results.IterationsD</DataLocation>
<DefaultData>ResultsIterationsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Results.IterationsD</IdLocation>
<IndexLocation>^WebStress.Results.IterationsI</IndexLocation>
<StreamLocation>^WebStress.Results.IterationsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
