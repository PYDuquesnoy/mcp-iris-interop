/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Errors Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, LegacyInstanceContext, Owner = {%Developer}, System = 4 ]
{

Property RunID As %Integer;

Property TestID As %Integer;

Property ScriptID As %Integer;

Property Process As %String(TRUNCATE = 1);

Property Session As %Integer;

Property ErrorNumber As %Integer;

Property ErrorStatus As %Integer(DISPLAYLIST = ",OK,Warning,Fatal", VALUELIST = ",0,1,2");

Property ErrorText As %String(MAXLEN = 255, TRUNCATE = 1);

Property URLNumber As %Integer;

Property URLVerb As %String(TRUNCATE = 1);

Property URLPath As %String(MAXLEN = 255, TRUNCATE = 1);

Property SystemIdentifier As %String(MAXLEN = 200);

Property ErrorTS As %TimeStamp [ InitialExpression = {$zdt($horolog,3)} ];

Index Main On (TestID, RunID, ScriptID, SystemIdentifier, ErrorStatus, ErrorNumber) [ IdKey, PrimaryKey, Unique ];

Query ShowAll() As %SQLQuery(CONTAINID = 1)
{
SELECT ID,ErrorStatus,ErrorText,Process,RunID,ScriptID,SystemIdentifier,TestID,URLNumber,URLPath,URLVerb,ErrorTS FROM Errors
}

Storage Default
{
<Data name="ErrorsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ErrorText</Value>
</Value>
<Value name="3">
<Value>Process</Value>
</Value>
<Value name="4">
<Value>Session</Value>
</Value>
<Value name="5">
<Value>URLNumber</Value>
</Value>
<Value name="6">
<Value>URLPath</Value>
</Value>
<Value name="7">
<Value>URLVerb</Value>
</Value>
<Value name="8">
<Value>ErrorTS</Value>
</Value>
</Data>
<DataLocation>^WebStress.ErrorsD</DataLocation>
<DefaultData>ErrorsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^WebStress.ErrorsD</IdLocation>
<IndexLocation>^WebStress.ErrorsI</IndexLocation>
<StreamLocation>^WebStress.ErrorsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
