/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Segmentation Extends extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property Segments As list Of Segment(XMLNAME = "Segment", XMLPROJECTION = "ELEMENT");

Property multipleModelMethod As %String(VALUELIST = ",majorityVote,weightedMajorityVote,average,weightedAverage,median,max,sum,selectFirst,selectAll,modelChain,x-weightedSum", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property missingPredictionTreatment As %String(VALUELIST = ",returnMissing,skipSegment,continue", XMLPROJECTION = "ATTRIBUTE");

/// Backwards compatibility with pre-4.4 PMML
Property "x-missingPredictionTreatment" As %String(VALUELIST = ",returnMissing,skipSegment,continue", XMLPROJECTION = "ATTRIBUTE") [ Deprecated, Internal ];

Property missingThreshold As %DeepSee.PMML.Datatype.ProbNumber(XMLPROJECTION = "ATTRIBUTE");

Method missingPredictionTreatmentGet() As %String [ Internal, ServerOnly = 1 ]
{
	quit $s(i%missingPredictionTreatment="":i%"x-missingPredictionTreatment", 1:i%missingPredictionTreatment)
}

}
