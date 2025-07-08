/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.TreeModel Extends AbstractModel [ System = 3 ]
{

Property missingValueStrategy As %DeepSee.PMML.Datatype.String(VALUELIST = ",lastPrediction,nullPrediction,defaultChild,weightedConfidence,aggregateNodes,none", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "none" ];

Property missingValuePenalty As %DeepSee.PMML.Datatype.ProbNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1.0 ];

Property noTrueChildStrategy As %DeepSee.PMML.Datatype.String(VALUELIST = ",returnNullPrediction,returnLastPrediction", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "returnNullPrediction" ];

Property splitCharacteristic As %DeepSee.PMML.Datatype.String(VALUELIST = ",binarySplit,multiSplit", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "multiSplit" ];

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property Node As %DeepSee.PMML.Definition.Models.Trees.TreeNode(XMLPROJECTION = "ELEMENT") [ Required ];

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		// TODO: if splitCharacteristic = binarySplit, verify all nodes have exactly 2 subnodes
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if $isobject(..Node) {
			set tSC = ..Node.%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
