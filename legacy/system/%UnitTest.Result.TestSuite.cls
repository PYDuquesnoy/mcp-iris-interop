/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object and SQL projection of a UnitTest TestSuite
Class %UnitTest.Result.TestSuite Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {%Developer}, System = 4 ]
{

/// Name of the TestSuite
Property Name As %String;

/// The status of the TestSuite.
Property Status As %Integer(DISPLAYLIST = ",failed,passed,skipped", VALUELIST = ",0,1,2");

/// Duration of the execution of the TestSuite, in seconds
Property Duration As %Numeric(SCALE = 6);

/// If the Status is failed, this is the action that logged the error
Property ErrorAction As %String;

/// If the Status is failed, this is the description of the error
Property ErrorDescription As %String;

/// The parent TestInstance containing this TestSuite
Relationship TestInstance As %UnitTest.Result.TestInstance [ Cardinality = parent, Inverse = TestSuites ];

/// List of TestCases in this TestSuite
Relationship TestCases As %UnitTest.Result.TestCase [ Cardinality = children, Inverse = TestSuite ];

Index IdKeyIndex On Name [ IdKey ];

Index idxName On Name;

ClassMethod FileIndicesRecursive(id) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%FileIndices(id) Quit:$$$ISERR(tSC)
		set obj = ..%OpenId(id)
		for i=1:1:obj.TestCases.Count() set tSC = ##class(%UnitTest.Result.TestCase).FileIndicesRecursive(obj.TestCases.GetObjectIdAt(i)) quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

Storage Default
{
<Data name="TestSuiteData">
<Value name="1">
<Value>Status</Value>
</Value>
<Value name="2">
<Value>Duration</Value>
</Value>
<Value name="3">
<Value>ErrorAction</Value>
</Value>
<Value name="4">
<Value>ErrorDescription</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}</DataLocation>
<DefaultData>TestSuiteData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^UnitTest.Result.TestSuiteCount</IdLocation>
<IndexLocation>^UnitTest.ResultI("TestSuite")</IndexLocation>
<StreamLocation>^UnitTest.Result.TestSuiteStream</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
