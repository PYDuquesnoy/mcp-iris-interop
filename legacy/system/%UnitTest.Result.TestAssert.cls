/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object and SQL projection of a UnitTest TestAssert
Class %UnitTest.Result.TestAssert Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {%Developer}, System = 4 ]
{

/// The index of the TestAssert
Property Counter As %Integer;

/// The Status of the TestAssert
Property Status As %Integer(DISPLAYLIST = ",failed,passed,skipped", VALUELIST = ",0,1,2");

/// The name of the action of the TestAssert
Property Action As %String;

/// The description of the TestAssert
Property Description As %String;

/// The location of the TestAssert in the source document in label[+offset]^[|"ns"|]doc.ext format
Property Location As %String;

/// The parent TestMethod containing this TestAssert
Relationship TestMethod As %UnitTest.Result.TestMethod [ Cardinality = parent, Inverse = TestAsserts ];

Index IdKeyIndex On Counter [ IdKey ];

Index idxStatus On Status;

ClassMethod FileIndicesRecursive(id) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%FileIndices(id) Quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

Storage Default
{
<Data name="TestAssertData">
<Value name="1">
<Value>Status</Value>
</Value>
<Value name="2">
<Value>Action</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Location</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}</DataLocation>
<DefaultData>TestAssertData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^UnitTest.Result.TestAssertCount</IdLocation>
<IndexLocation>^UnitTest.ResultI("TestAssert")</IndexLocation>
<StreamLocation>^UnitTest.Result.TAStream</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
