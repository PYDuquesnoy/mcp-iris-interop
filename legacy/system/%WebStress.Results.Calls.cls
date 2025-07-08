/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Results.Calls Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Owner = {%Developer}, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %String(TRUNCATE = 1);

Property Script As %String(TRUNCATE = 1);

Property Generator As %String(TRUNCATE = 1);

Property WebServer As %String(TRUNCATE = 1);

Property Process As %String(TRUNCATE = 1);

Property Session As %Integer;

Property Iteration As %Integer;

Property Verb As %String(TRUNCATE = 1);

Property Path As %String(TRUNCATE = 1);

Property CharactersSent As %Integer;

Property CharactersReceived As %Integer;

Property TimeToFirstCharacter As %Integer;

Property TimeToLastCharacter As %Integer;

Property HttpStatusCode As %Integer;

Property RecordedTime As %String(TRUNCATE = 1);

Property URL As %Integer;

Index Main On (TestID, RunID, Script, Generator, WebServer, Process, Session, Iteration, URL) [ IdKey, PrimaryKey, Unique ];

ClassMethod RecordedTimeLogicalToDisplay(time As %String) As %String
{
	set horolog=(time\86400)_","_(time#86400)
	quit $zdt(horolog,3)
}

ClassMethod RecordedTimeLogicalToOdbc(time As %String) As %String
{
	set horolog=(time\86400)_","_(time#86400)
	quit $zdt(horolog,3)
}

Query GetData(testID As %String, runID As %Integer) As %SQLQuery
{
SELECT Script,Generator,Process,Session,WebServer,Iteration,URL,Verb,Path,HttpStatusCode,CharactersSent,CharactersReceived,TimeToFirstCharacter,TimeToLastCharacter FROM %WebStress_Results.Calls
 WHERE (TestID = :testID AND RunID = :runID)
 ORDER BY Script,Generator,Process,Session,WebServer,Iteration,URL
}

Storage Default
{
<Data name="ResultsAllDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Verb</Value>
</Value>
<Value name="3">
<Value>Path</Value>
</Value>
<Value name="4">
<Value>CharactersSent</Value>
</Value>
<Value name="5">
<Value>CharactersReceived</Value>
</Value>
<Value name="6">
<Value>TimeToFirstCharacter</Value>
</Value>
<Value name="7">
<Value>TimeToLastCharacter</Value>
</Value>
<Value name="8">
<Value>HttpStatusCode</Value>
</Value>
<Value name="9">
<Value>RecordedTime</Value>
</Value>
</Data>
<DataLocation>^WebStress.Results.CallsD</DataLocation>
<DefaultData>ResultsAllDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.Results.CallsD</IdLocation>
<IndexLocation>^WebStress.Results.CallsI</IndexLocation>
<StreamLocation>^WebStress.Results.CallsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
