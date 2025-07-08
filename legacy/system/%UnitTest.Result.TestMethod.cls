/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object and SQL projection of a UnitTest TestMethod
Class %UnitTest.Result.TestMethod Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {%Developer}, System = 4 ]
{

/// Name of the TestMethod
Property Name As %String;

/// The status of the TestMethod.
Property Status As %Integer(DISPLAYLIST = ",failed,passed,skipped", VALUELIST = ",0,1,2");

/// Duration of the execution of the TestMethod, in seconds
Property Duration As %Numeric(SCALE = 6);

/// If the Status is failed, this is the action that logged the error
Property ErrorAction As %String;

/// If the Status is failed, this is the description of the error
Property ErrorDescription As %String;

/// The parent TestCase containing this TestMethod
Relationship TestCase As %UnitTest.Result.TestCase [ Cardinality = parent, Inverse = TestMethods ];

/// List of TestAsserts in this TestMethod
Relationship TestAsserts As %UnitTest.Result.TestAssert [ Cardinality = children, Inverse = TestMethod ];

Index IdKeyIndex On Name [ IdKey ];

Index idxName On Name;

ClassMethod FileIndicesRecursive(id) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%FileIndices(id) Quit:$$$ISERR(tSC)
		set obj = ..%OpenId(id)
		for i=1:1:obj.TestAsserts.Count() set tSC = ##class(%UnitTest.Result.TestAssert).FileIndicesRecursive(obj.TestAsserts.GetObjectIdAt(i)) quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

Storage Default
{
<Data name="TestMethodData">
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
<DefaultData>TestMethodData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^UnitTest.Result.TestMethodCount</IdLocation>
<IndexLocation>^UnitTest.ResultI("TestMethod")</IndexLocation>
<StreamLocation>^UnitTest.Result.TMStream</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
