/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.RuleSetModel Extends AbstractModel [ System = 3 ]
{

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property RuleSet As %DeepSee.PMML.Definition.Models.RuleSet.RuleSet(XMLPROJECTION = "ELEMENT") [ Required ];

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if $isobject(..RuleSet) {
			set tRuleCount = ..RuleSet.Rules.Count()
			for i = 1:1:tRuleCount {
				set tSC = ..RuleSet.Rules.GetAt(i).%ValidateNames(.pDictionary)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if '$isobject(..RuleSet) {
			set tSC = $$$ERROR($$$GeneralError, "RuleSetModel should have a RuleSet element")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
