/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.SparseArray Extends AbstractArray [ Abstract, System = 3 ]
{

Property Indices As %String(MAXLEN = 32000, XMLPROJECTION = "ELEMENT");

Method ValuesAsArray(Output pArray) As %Status
{
	kill pArray
	set tSC = $$$OK
	try {
		
		set pArray = ..n
		set tIndices = $zstrip(..Indices,"<=>W")
		set tEntries = $zstrip(..Entries,"<=>W")
		
		set tIndicesLength = $l(tIndices," ")
		set tEntriesLength = $l(tEntries," ")
		
		if tIndicesLength '= tEntriesLength {
			set tSC = $$$ERROR($$$GeneralError, "SparseArray index count does not match entry count")
			quit
		}
		
		for i = 1:1:pArray {
			set pArray(i) = ..defaultValue
		}
		
		for i = 1:1:tIndicesLength {
			set pArray($p(tIndices," ",i)) = $p(tEntries," ",i)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit $$$OK
}

}
