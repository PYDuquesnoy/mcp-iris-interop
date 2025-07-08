/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Builder.NaiveBayes Extends %DeepSee.PMML.Builder.AbstractBuilder [ System = 4 ]
{

Parameter MODELCLASSNAME = "%DeepSee.PMML.Definition.Models.NaiveBayesModel";

Property Threshold As %Numeric [ InitialExpression = 0.0001 ];

Method BuildModel(ByRef pModel As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		// simple attributes
		set pModel.threshold = ..Threshold
		
		// <BayesOutput>
		set pModel.BayesOutput = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.BayesOutput).%New()
		set pModel.BayesOutput.fieldName = ..TargetField
		set pModel.BayesOutput.TargetValueCounts = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueCounts).%New()
		
		set tSC = ..Dataset.Get1DDistribution(..TargetField, .tDistribution)
		quit:$$$ISERR(tSC)
		
		for i = 1:1:$g(tDistribution) {
			set tMemberKey = $li(tDistribution(i),1), tCount = $li(tDistribution(i),2)
			continue:(tMemberKey="")||'tCount
			
			set tTVCount = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueCount).%New()
			set tTVCount.value = tMemberKey
			set tTVCount.count = tCount
			do pModel.BayesOutput.TargetValueCounts.Counts.Insert(tTVCount)
		}
		
		// <BayesInputs>
		set pModel.BayesInputs = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.BayesInputs).%New()
		set tFieldName = ""
		for {
			set tField = ..Dataset.Fields.GetNext(.tFieldName)
			quit:tFieldName=""
			continue:tFieldName=..TargetField
			
			set tBayesInput = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.BayesInput).%New()
			set tBayesInput.fieldName = tFieldName
			
			set tSC = ..Dataset.GetXDDistribution($lb(..TargetField, tFieldName), .tDistribution)
			quit:$$$ISERR(tSC)
			set tTargetValueCount = $g(tDistribution("value",1))
			set tFieldValueCount = $g(tDistribution("value",2))
			for j = 1:1:tFieldValueCount {
				set tFieldValue = tDistribution("value",2,j)
				continue:tFieldValue=""
				
				set tPairCounts = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.PairCounts).%New()
				set tPairCounts.value = tFieldValue
				set tPairCounts.TargetValueCounts = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueCounts).%New()
				
				for k = 1:1:tTargetValueCount {
					set tTargetValue = tDistribution("value",1,k)
					continue:tTargetValue=""
					
					set tResultCount = $g(tDistribution(k,j))
					continue:'tResultCount
					
					set tTVCount = ##class(%DeepSee.PMML.Definition.Models.NaiveBayes.TargetValueCount).%New()
					set tTVCount.value = tTargetValue
					set tTVCount.count = tResultCount
					do tPairCounts.TargetValueCounts.Counts.Insert(tTVCount)
				}
				do tBayesInput.PairCounts.Insert(tPairCounts)
			}
			
			do pModel.BayesInputs.BayesInput.Insert(tBayesInput)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Storage Default
{
<Data name="AbstractBuilderState">
<Value name="1">
<Value>TargetField</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>ModelName</Value>
</Value>
<Value name="4">
<Value>FunctionName</Value>
</Value>
<Value name="5">
<Value>AlgorithmName</Value>
</Value>
<Value name="6">
<Value>OutputProbability</Value>
</Value>
<Value name="7">
<Value>Threshold</Value>
</Value>
<Value name="8">
<Value>DataSources</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
