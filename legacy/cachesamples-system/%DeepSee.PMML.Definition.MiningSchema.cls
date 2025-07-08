/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.MiningSchema Extends extendableNode [ System = 3 ]
{

Property MiningFields As list Of MiningField(XMLNAME = "MiningField", XMLPROJECTION = "ELEMENT");

Method %GetDictionary(ByRef pGlobalDictionary, Output pLocalDictionary) As %Status [ Final ]
{
	kill pLocalDictionary
	set tSC = $$$OK
	try {
		
		merge pLocalDictionary("functions") = pGlobalDictionary("functions")
		merge pLocalDictionary("taxonomies") = pGlobalDictionary("taxonomies")
		
		// verify MiningField entries
		for i = 1:1:..MiningFields.Count() {
			set tField = ..MiningFields.GetAt(i)
			
			if '$d(pGlobalDictionary("fields", tField.name)) {
				set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_tField.name_"'")
				quit
			}
			
			merge pLocalDictionary("fields", tField.name) = pGlobalDictionary("fields", tField.name)
			
			set pLocalDictionary("fields", tField.name) = "Model"
			set:tField.usageType'="" pLocalDictionary("fields", tField.name, "usageType") = tField.usageType
			set:tField.optype'="" pLocalDictionary("fields", tField.name, "optype") = tField.optype
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
