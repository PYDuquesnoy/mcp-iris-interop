/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.MiningModel Extends AbstractModel [ System = 3 ]
{

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property Segmentation As %DeepSee.PMML.Definition.Segmentation(XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

ClassMethod %GetModelClass() As %String [ Internal ]
{
	quit "%DeepSee.PMML.Model.Composite"
}

Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		quit:'$isobject(..Segmentation)
		set tSegmentCount = ..Segmentation.Segments.Count()
		set tMethod = ..Segmentation.multipleModelMethod
		
		if (tMethod'="modelChain") {
			// all models should have the same mining function
			for i = 1:1:tSegmentCount {
				if (..Segmentation.Segments.GetAt(i).Model.functionName'=..functionName) {
					set tSC = $$$ERROR($$$GeneralError, "All models in a Segmentation must have the same mining function")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		} else {
			if (..Segmentation.Segments.GetAt(tSegmentCount).Model.functionName'=..functionName) {
				set tSC = $$$ERROR($$$GeneralError, "If multipleModelMethod=""modelChain"", the last model in the chain should have the same mining function as the MiningModel")
				quit
			}
		}
		
		if ((..functionName="clustering") && '("majorityVote,weightedMajorityVote,selectFirst,selectAll,modelChain"[tMethod)) ||
		   ((..functionName="regression") && '("average,weightedAverage,median,sum,selectFirst,selectAll,modelChain"[tMethod)) ||
		   ((..functionName="classification") && (tMethod="sum")) {
			set tSC = $$$ERROR($$$GeneralError, "Invalid multipleModelMethod for function '"_..functionName_"'")
			quit
		}
		
		if (tMethod="selectAll") {
			set tSC = $$$ERROR($$$GeneralError, "multipleModelMethod=""selectAll"" is not supported")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		quit:'$isobject(..Segmentation)
		
		for i = 1:1:..Segmentation.Segments.Count() {
			set tSegment = ..Segmentation.Segments.GetAt(i)
			
			set tSC = tSegment.Predicate.%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
			
			set tSC = tSegment.Model.%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
			
			if (..Segmentation.multipleModelMethod="modelChain") && $isobject(tSegment.Model.Output) {
				for k = 1:1:tSegment.Model.Output.OutputFields.Count() {
					set tFieldName = tSegment.Model.Output.OutputFields.GetAt(k).name
					continue:$d(pDictionary("fields", tFieldName))
					set pDictionary("fields", tFieldName) = "PreviousModel"
				}
			}
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
