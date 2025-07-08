/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object and SQL projection of a UnitTest TestCase
Class %UnitTest.Result.TestCase Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {%Developer}, System = 4 ]
{

/// Name of the TestCase
Property Name As %String;

/// The status of the TestCase.
Property Status As %Integer(DISPLAYLIST = ",failed,passed,skipped", VALUELIST = ",0,1,2");

/// Duration of the execution of the TestCase, in seconds
Property Duration As %Numeric(SCALE = 6);

/// If the Status is failed, this is the action that logged the error
Property ErrorAction As %String;

/// If the Status is failed, this is the description of the error
Property ErrorDescription As %String;

/// The parent TestSuite containing this TestCase
Relationship TestSuite As %UnitTest.Result.TestSuite [ Cardinality = parent, Inverse = TestCases ];

/// List of TestMethods in this TestCase
Relationship TestMethods As %UnitTest.Result.TestMethod [ Cardinality = children, Inverse = TestCase ];

Index IdKeyIndex On Name [ IdKey ];

Index idxName On Name;

ClassMethod FileIndicesRecursive(id) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%FileIndices(id) Quit:$$$ISERR(tSC)
		set obj = ..%OpenId(id)
		for i=1:1:obj.TestMethods.Count() set tSC = ##class(%UnitTest.Result.TestMethod).FileIndicesRecursive(obj.TestMethods.GetObjectIdAt(i)) quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

Storage Default
{
<Data name="TestCaseData">
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
<DefaultData>TestCaseData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^UnitTest.Result.TestCaseCount</IdLocation>
<IndexLocation>^UnitTest.ResultI("TestCase")</IndexLocation>
<StreamLocation>^UnitTest.Result.TestCaseStream</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
