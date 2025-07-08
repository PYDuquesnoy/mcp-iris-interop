/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.TransformationDictionary Extends extendableNode [ System = 3 ]
{

Property DefineFunctions As list Of DefineFunction(XMLNAME = "DefineFunction", XMLPROJECTION = "ELEMENT");

Property DerivedFields As list Of DerivedField(XMLNAME = "DerivedField", XMLPROJECTION = "ELEMENT");

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		set tSource = "TransformationDictionary"
		
		// verify and append DefineFunction entries
		for i = 1:1:..DefineFunctions.Count() {
			#dim tFunction As DefineFunction = ..DefineFunctions.GetAt(i)
			
			if $d(pDictionary("functions", tFunction.name), tSrc) {
				set tSC = $$$ERROR($$$GeneralError, "Function already defined: '"_tFunction.name_"' ("_tSrc_")")
				quit
			}
			
			set tSC = tFunction.Expression.%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
			
			set pDictionary("functions", tFunction.name) = tSource
			set:tFunction.dataType'="" pDictionary("functions", tFunction.name, "dataType") = tFunction.dataType
			set:tFunction.optype'="" pDictionary("functions", tFunction.name, "optype") = tFunction.optype
		}
		quit:$$$ISERR(tSC)
		
		// verify and append DerivedField entries
		for i = 1:1:..DerivedFields.Count() {
			#dim tField As DerivedField = ..DerivedFields.GetAt(i)
			
			if tField.name="" {
				set tSC = $$$ERROR($$$GeneralError, "Field name is required for DerivedField element")
				quit
			}
			
			if $d(pDictionary("fields", tField.name), tSrc) {
				set tSC = $$$ERROR($$$GeneralError, "Field already defined: '"_tField.name_"' ("_tSrc_")")
				quit
			}
			
			set tSC = tField.Expression.%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
			
			set pDictionary("fields", tField.name) = tSource
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
