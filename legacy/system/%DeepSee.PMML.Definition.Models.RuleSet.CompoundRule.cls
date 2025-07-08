/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.RuleSet.CompoundRule Extends Rule [ System = 3 ]
{

Property Rules As list Of Rule(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Method %OnValidateNames(ByRef pDictionary) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		set tRuleCount = ..Rules.Count() 
		for i = 1:1:tRuleCount {
			set tSC = ..Rules.GetAt(i).%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
