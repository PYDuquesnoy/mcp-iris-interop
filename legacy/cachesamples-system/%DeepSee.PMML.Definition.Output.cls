/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Output Extends extendableNode [ System = 3 ]
{

Property OutputFields As list Of OutputField(XMLNAME = "OutputField", XMLPROJECTION = "ELEMENT");

Method %ValidateNames(ByRef pDictionary) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:..OutputFields.Count() {
			set tField = ..OutputFields.GetAt(i)
			
			if $isobject(tField.Expression) && (tField.segmentId="") /* BDB881 */ {
				set tSC = tField.Expression.%ValidateNames(.pDictionary)
				quit:$$$ISERR(tSC)
			}
			
			if (tField.targetField'="") {
				if '$d(pDictionary("targets", tField.targetField)) &&
					 '$$$PMMLusageTypeIsTarget($g(pDictionary("fields", tField.targetField, "usageType"))) {
					set tSC = $$$ERROR($$$GeneralError, "Unkown output field: '"_tField.targetField_"'")
					quit
				}
			}
			
			// BDB790 - append field name to local dictionary
			// BDB798 - but only if they're not present already
			if '$d(pDictionary("fields", tField.name)) {
				set pDictionary("fields", tField.name) = "Output"
				set pDictionary("fields", tField.name, "dataType") = tField.dataType
				set pDictionary("fields", tField.name, "optype") = tField.optype
				set pDictionary("fields", tField.name, "usageType") = $$$PMMLusageTypePredicted_":"_tField.feature
			}
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
