/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.ModelVerification Extends extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property Fields As %DeepSee.PMML.Definition.ModelVerificationFields(XMLNAME = "VerificationFields", XMLPROJECTION = "ELEMENT");

Property InlineTable As %DeepSee.PMML.Definition.Util.InlineTable(XMLPROJECTION = "ELEMENT");

Property recordCount As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

Property fieldCount As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if ..recordCount {
			set tSC = ..InlineTable.%GetRows(.tRows)
			quit:$$$ISERR(tSC)
			
			if ($g(tRows) '= ..recordCount) {
				set tSC = $$$ERROR($$$GeneralError, "ModelVerification.recordCount attribute does not match nested InlineTable row count")
				quit
			}
		}
		
		if ..fieldCount && (..fieldCount '= ..Fields.Fields.Count()) {
			set tSC = $$$ERROR($$$GeneralError, "ModelVerification.fieldCount attribute does not ModelVerificationField count")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
