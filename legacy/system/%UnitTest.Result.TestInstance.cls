/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Object and SQL projection of a UnitTest TestInstance
Class %UnitTest.Result.TestInstance Extends (%Persistent, %XML.Adaptor) [ Final, Owner = {%Developer}, System = 4 ]
{

/// Index of the TestInstance
Property InstanceIndex As %Integer;

/// The time when the UnitTest TestInstance finished running
Property DateTime As %TimeStamp;

/// Total duration of execution of this TestInstance, in seconds
Property Duration As %Numeric(SCALE = 6);

/// Name of the machine on which this test was run
Property MachineName As %String(MAXLEN = "");

/// Name of the InterSystems IRIS configuration in which this test was run
Property ConfigurationName As %String(MAXLEN = "");

/// $zversion value of the InterSystems IRIS instance in which this test was run
Property Version As %String(MAXLEN = "");

/// Namespace in which this test was run
Property Namespace As %String(MAXLEN = "") [ Calculated, SqlComputeCode = { set {*} = $s({namespaceStored}'="":{namespaceStored},1:$namespace) }, SqlComputed ];

/// Private property for the internally stored namespace
Property namespaceStored As %String(MAXLEN = "") [ Private ];

/// Additional information passed in by uer at runtime
Property UserParam As %String(MAXLEN = "");

/// Additional information, like platform, product version, etc. for each TestInstance.
/// This information is indexed so users can query using this information.
Property UserFields As array Of %String(MAXLEN = "");

/// List of the TestSuites in this TestInstance
Relationship TestSuites As %UnitTest.Result.TestSuite [ Cardinality = children, Inverse = TestInstance ];

Index IdKeyIndex On InstanceIndex [ IdKey ];

Index Location On (MachineName, ConfigurationName, Namespace);

Index DateTime On DateTime;

Index Version On Version;

Index UserParam On UserParam;

Index UserFields On (UserFields(KEYS), UserFields(ELEMENTS));

ClassMethod FileIndicesRecursive(id) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..%FileIndices(id) Quit:$$$ISERR(tSC)
		set obj = ..%OpenId(id)
		for i=1:1:obj.TestSuites.Count() set tSC = ##class(%UnitTest.Result.TestSuite).FileIndicesRecursive(obj.TestSuites.GetObjectIdAt(i)) quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

ClassMethod BuildIndices() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##class(%UnitTest.Result.TestInstance).%BuildIndices() Quit:$$$ISERR(tSC)
		set tSC = ##class(%UnitTest.Result.TestSuite).%BuildIndices() Quit:$$$ISERR(tSC)
		set tSC = ##class(%UnitTest.Result.TestCase).%BuildIndices() Quit:$$$ISERR(tSC)
		set tSC = ##class(%UnitTest.Result.TestMethod).%BuildIndices() Quit:$$$ISERR(tSC)
		set tSC = ##class(%UnitTest.Result.TestAssert).%BuildIndices() Quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$ObjectScriptError,$ze)
	}
	quit tSC
}

Storage Default
{
<Data name="TestInstanceData">
<Value name="1">
<Value>DateTime</Value>
</Value>
<Value name="2">
<Value>Duration</Value>
</Value>
<Value name="3">
<Value>MachineName</Value>
</Value>
<Value name="4">
<Value>ConfigurationName</Value>
</Value>
<Value name="5">
<Value>Version</Value>
</Value>
<Value name="6">
<Value>namespaceStored</Value>
</Value>
<Value name="7">
<Value>UserParam</Value>
</Value>
<Value name="8">
<Value>UserFields</Value>
</Value>
</Data>
<DataLocation>^UnitTest.Result</DataLocation>
<DefaultData>TestInstanceData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^UnitTest.Result</IdLocation>
<IndexLocation>^UnitTest.ResultI("TestInstance")</IndexLocation>
<StreamLocation>^UnitTest.Result.TIStream</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
