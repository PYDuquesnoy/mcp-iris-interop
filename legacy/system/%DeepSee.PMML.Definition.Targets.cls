/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Targets Extends extendableNode [ System = 3 ]
{

Property Targets As list Of Target(XMLNAME = "Target", XMLPROJECTION = "ELEMENT");

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:..Targets.Count() {
			set tTarget = ..Targets.GetAt(i) 
			
			// BDB875 - Starting with PMML 4.3, the target field name is no longer mandatory
			// for Segmentation models, it can be the "implied" output for that segment
			
			if (tTarget.field'="") && '$d(pDictionary("fields", tTarget.field), tFieldInfo) {
				set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_tTarget.field_"'")
				quit
				
				set pDictionary("targets", tTarget.field) = "Target"
				set pDictionary("targets", tTarget.field, "optype") = tTarget.optype
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
