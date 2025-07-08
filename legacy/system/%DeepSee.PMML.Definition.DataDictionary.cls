/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.DataDictionary Extends extendableNode [ System = 3 ]
{

Property numberOfFields As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 1, XMLPROJECTION = "ATTRIBUTE");

Property DataFields As list Of DataField(XMLNAME = "DataField", XMLPROJECTION = "ELEMENT");

Property Taxonomies As list Of Taxonomy(XMLNAME = "Taxonomy", XMLPROJECTION = "ELEMENT");

Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if (..numberOfFields'="") && (..numberOfFields'=..DataFields.Count()) {
			set tSC = $$$ERROR($$$GeneralError, "value of numberOfFields attribute should match DataField element count")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetDictionary(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		set tSource = "DataDictionary"
		
		// append DataField entries
		for i = 1:1:..DataFields.Count() {
			set tField = ..DataFields.GetAt(i)
			
			if $d(pDictionary("fields", tField.name), tSrc) {
				set tSC = $$$ERROR($$$GeneralError, "Field already defined: '"_tField.name_"' ("_tSrc_")")
				quit
			}
			
			set pDictionary("fields", tField.name) = tSource
			set:tField.dataType'="" pDictionary("fields", tField.name, "dataType") = tField.dataType
			set:tField.optype'="" pDictionary("fields", tField.name, "optype") = tField.optype
		}
		
		// append Taxonomy entries
		for i = 1:1:..Taxonomies.Count() {
			set tTaxonomy = ..Taxonomies.GetAt(i)
			
			if $d(pDictionary("taxonomies", tTaxonomy.name), tSrc) {
				set tSC = $$$ERROR($$$GeneralError, "Taxonomy already defined: '"_tTaxonomy.name_"' ("_tSource_")")
				quit
			}
			
			set pDictionary("taxonomies", tTaxonomy.name) = tSource
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method AddField(pField As DataField) As %Status
{
	do ..DataFields.Insert(pField)
	set ..numberOfFields = ..numberOfFields+1
	quit $$$OK
}

}
