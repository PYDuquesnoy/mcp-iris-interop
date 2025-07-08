/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Results.General Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %String(TRUNCATE = 1);

Property Generator As %String(TRUNCATE = 1);

Property PrepareTime As %String(TRUNCATE = 1);

Property WarmUpTime As %String(TRUNCATE = 1);

Property RecordTime As %String(TRUNCATE = 1);

Property CoolDownTime As %String(TRUNCATE = 1);

Property StoppingTime As %String(TRUNCATE = 1);

Property StoppedTime As %String(TRUNCATE = 1);

Property RunDescription As %String(TRUNCATE = 1);

Index Main On (TestID, RunID, Generator) [ IdKey, PrimaryKey, Unique ];

Query GetGenerators(testID As %String, runID As %Integer) As %SQLQuery(CONTAINID = 0)
{
SELECT DISTINCT Generator,PrepareTime,WarmUpTime,RecordTime,CoolDownTime,StoppingTime,StoppedTime,RunDescription
FROM %WebStress_Results.General
WHERE TestID = :testID and RunID = :runID
ORDER BY Generator
}

Query GetTests() As %SQLQuery(CONTAINID = 1)
{
SELECT DISTINCT TestID,Tests.Name
FROM %WebStress_Results.General General, %WebStress.Tests Tests
WHERE General.TestID = Tests.ID
ORDER BY Tests.Name
}

Query GetRuns(testID As %String) As %SQLQuery(CONTAINID = 0)
{
SELECT DISTINCT RunID,Generator,PrepareTime,WarmUpTime,RecordTime,CoolDownTime,StoppingTime,StoppedTime,RunDescription
FROM %WebStress_Results.General
GROUP BY RunID
HAVING TestID = :testID
ORDER BY RunID DESC
}

Storage Default
{
<Data name="ResultsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PrepareTime</Value>
</Value>
<Value name="3">
<Value>WarmUpTime</Value>
</Value>
<Value name="4">
<Value>RecordTime</Value>
</Value>
<Value name="5">
<Value>CoolDownTime</Value>
</Value>
<Value name="6">
<Value>StoppingTime</Value>
</Value>
<Value name="7">
<Value>StoppedTime</Value>
</Value>
<Value name="8">
<Value>RunDescription</Value>
</Value>
<Value name="9">
<Value>Generator</Value>
</Value>
</Data>
<DataLocation>^WebStress.Results.GeneralD</DataLocation>
<DefaultData>ResultsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Results.GeneralD</IdLocation>
<IndexLocation>^WebStress.Results.GeneralI</IndexLocation>
<StreamLocation>^WebStress.Results.GeneralS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
