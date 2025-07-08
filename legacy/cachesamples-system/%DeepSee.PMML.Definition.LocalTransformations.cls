/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.LocalTransformations Extends extendableNode [ System = 3 ]
{

Property DerivedFields As list Of DerivedField(XMLNAME = "DerivedField", XMLPROJECTION = "ELEMENT");

Method %ValidateNames(ByRef pDictionary) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		
		// verify and append DerivedField entries
		for i = 1:1:..DerivedFields.Count() {
			#dim tField As DerivedField = ..DerivedFields.GetAt(i)
			
			if tField.name="" {
				set tSC = $$$ERROR($$$GeneralError, "Field name is required for DerivedField element")
				quit
			}
			
			if $d(pDictionary("fields", tField.name), tSource) {
				set tSC = $$$ERROR($$$GeneralError, "Field already defined: '"_tField.name_"' ("_tSource_")")
				quit
			}
			
			set tSC = tField.Expression.%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
			
			set pDictionary("fields", tField.name) = "Model"
			set:tField.dataType'="" pDictionary("fields", tField.name, "dataType") = tField.dataType
			set:tField.optype'="" pDictionary("fields", tField.name, "optype") = tField.optype
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
