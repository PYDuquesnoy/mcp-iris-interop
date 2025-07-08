/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Dataset.Base Extends (%Persistent, %DeepSee.PMML.Dataset) [ Abstract, System = 4 ]
{

Property BootstrapCount As %Integer;

ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Private, ServerOnly = 1 ]
{
	quit ..Clear()
}

Method GetBootstrapInfo(Output pSQL As %String, Output pFields As %ArrayOfObjects) As %Status [ Abstract, Internal, Private ]
{
}

Method GetBootstrap(pBootstrapId As %Integer, Output pBootstrap As %DeepSee.PMML.Dataset.Bootstrap) As %Status
{
	set tSC = $$$OK
	try {
		if '$d(^%DeepSee.PMML.DatasetD(+..%Id(), "bs", pBootstrapId)) {
			set tSC = $$$ERROR($$$GeneralError, "No bootstrap with ID "_pBootstrapId)
			quit
		}
		
		set tSC = ..GetBootstrapInfo(.tSQL, .tFields)
		quit:$$$ISERR(tSC)
		
		set pBootstrap = ##class(%DeepSee.PMML.Dataset.Bootstrap).%New(pBootstrapId, tSQL, $this)
		set:pBootstrap="" tSC = %objlasterror
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ClearBootstraps() As %Status
{
	set tSC = $$$OK
	try {
		quit:'..BootstrapCount
		quit:..%Id()=""
		
		kill ^%DeepSee.PMML.DatasetD(..%Id(), "bs")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GenerateBootstraps(pCount As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		if (..%Id()="") {
			set tSC = $$$ERROR($$$GeneralError, "Dataset should be saved before bootstraps can be generated")
			quit
		}
		
		set tSC = ..ClearBootstraps()
		quit:$$$ISERR(tSC)
		
		if '$isobject(..IdField) {
			set tSC = $$$ERROR($$$GeneralError, "Dataset should have an ID field registered to be able to generate bootstraps")
			quit
		}
		
		// round up the available record IDs
		set tSC = ..GetRecordIds(.tIDs)
		quit:$$$ISERR(tSC)
		set tRecordCount = tIDs
		
		// now build the random samples by selecting tRecordCount IDs from tIDs
		for tBootstrapId = 1:1:pCount {
			kill tSamples
			for i = 1:1:tRecordCount {
				set tRecordId = tIDs(1+$random(tRecordCount))
				set x = $i(tSamples(tRecordId))
			}
			merge ^%DeepSee.PMML.DatasetD(..%Id(), "bs", tBootstrapId) = tSamples
			
		}
		set ..BootstrapCount = pCount
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="DatasetBaseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>IdField</Value>
</Value>
<Value name="4">
<Value>Fields</Value>
</Value>
<Value name="5">
<Value>BootstrapCount</Value>
</Value>
</Data>
<DataLocation>^%DeepSee.PMML.DatasetD</DataLocation>
<DefaultData>DatasetBaseDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%DeepSee.PMML.DatasetD</IdLocation>
<IndexLocation>^%DeepSee.PMML.DatasetI</IndexLocation>
<StreamLocation>^%DeepSee.PMML.DatasetS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
