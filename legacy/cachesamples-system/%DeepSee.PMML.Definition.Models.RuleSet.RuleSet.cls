/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.RuleSet.RuleSet Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Property RuleSelectionMethod As list Of RuleSelectionMethod(XMLPROJECTION = "ELEMENT") [ Required ];

Property ScoreDistributions As %DeepSee.PMML.Definition.Models.Trees.ScoreDistribution(XMLNAME = "ScoreDistribution", XMLPROJECTION = "ELEMENT");

Property Rules As list Of Rule(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property recordCount As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property nbCorrect As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property defaultScore As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property defaultConfidence As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if '..RuleSelectionMethod.Count() {
			set tSC = $$$ERROR($$$GeneralError, "RuleSetModel requires a RuleSelectionMethod element")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
