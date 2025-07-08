/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Builder.Tree Extends %DeepSee.PMML.Builder.AbstractBuilder [ System = 4 ]
{

Parameter MODELCLASSNAME = "%DeepSee.PMML.Definition.Models.TreeModel";

Property CustomTree [ MultiDimensional ];

Property MaxTreeDepth As %Integer [ InitialExpression = 3 ];

Property ScoringMetric As %String(VALUELIST = ",Confidence,GiniImpurity,InformationGain") [ InitialExpression = "GiniImpurity" ];

Property MissingValueStrategy As %String(VALUELIST = ",none,lastPrediction,nullPrediction,defaultChild,weightedConfidence,aggregateNodes") [ InitialExpression = "none" ];

Property MissingValuePenalty As %Double [ InitialExpression = 1.0 ];

Property NoTrueChildStrategy As %String(VALUELIST = ",returnNullPrediction,returnLastPrediction") [ InitialExpression = "returnNullPrediction" ];

Method BuildModel(ByRef pModel As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		if $d(..CustomTree) { 
			merge tTree = ..CustomTree
		} else {
			set tTreeBuilder = ##class(%DeepSee.PMML.Utils.TreeBuilder).%New(..Dataset, ..TargetField)
			if '$isobject(tTreeBuilder) { set tSC = %objlasterror  quit }
			set tTreeBuilder.TrackDistributions = 1
			set tTreeBuilder.SplitScoringAlgorithm = ..ScoringMetric
		
			set tSC = tTreeBuilder.Build(..MaxTreeDepth)
			quit:$$$ISERR(tSC)
			
			merge tTree = tTreeBuilder.Tree
		}
		
		// transform tree into <Node> elements
		set tSC = ..CreateNodeElement(.tTree, 0, .tNodeElement)
		quit:$$$ISERR(tSC)
		
		set pModel.Node = tNodeElement
		set pModel.splitCharacteristic = $s(tTreeBuilder.SplitsPerNode=2:"binarySplit", 1:"multiSplit")
		set pModel.noTrueChildStrategy = ..NoTrueChildStrategy
		set pModel.missingValueStrategy = ..MissingValueStrategy
		set pModel.missingValuePenalty = ..MissingValuePenalty
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method CreateNodeElement(ByRef pTree, pNodeId As %Integer, Output pNodeElement As %DeepSee.PMML.Definition.Models.Trees.TreeNode) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		if '$d(pTree(pNodeId), tDetails) {
			set tSC =$$$ERROR($$$GeneralError, "Node "_pNodeId_" not found in tree")
			quit
		}
		
		set pNodeElement = ##class(%DeepSee.PMML.Definition.Models.Trees.TreeNode).%New()
		set pNodeElement.id = pNodeId
		set pNodeElement.recordCount = $li(tDetails, 4)
		
		// create predicate for node split condition
		kill tCondition
		merge tCondition = pTree(pNodeId, "condition")
		set tSC = ..CreatePredicateElement(.tCondition, .tPredicate)
		quit:$$$ISERR(tSC)
		set pNodeElement.Predicate = tPredicate
		
		
		// append score distributions
		set tValue = ""
		for {
			set tValue = $order(pTree(pNodeId, "distribution", tValue), 1, tCount)
			quit:tValue=""
			continue:tValue=$c(0)
			continue:'tCount
			
			set tDistribution = ##class(%DeepSee.PMML.Definition.Models.Trees.ScoreDistribution).%New()
			set tDistribution.recordCount = tCount
			set tDistribution.value = $s(tValue=$c(0):"", 1:tValue)
			set tDistribution.probability = tCount / $li(tDetails, 4)
			do pNodeElement.ScoreDistributions.Insert(tDistribution)
		}
		
		
		// append child nodes
		set tChildNodeId = ""
		for {
			set tChildNodeId = $order(pTree(pNodeId,"ch",tChildNodeId))
			quit:tChildNodeId=""
			
			set tSC = ..CreateNodeElement(.pTree, tChildNodeId, .tChildNodeElement)
			quit:$$$ISERR(tSC)
			
			do pNodeElement.Subnodes.Insert(tChildNodeElement)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method CreatePredicateElement(ByRef pCondition, Output pPredicate As %DeepSee.PMML.Definition.Util.Predicate) As %Status [ Private ]
{
	set tSC = $$$OK, pPredicate=""
	try {
		if '$d(pCondition) {
			set pPredicate = ##class(%DeepSee.PMML.Definition.Util.True).%New()
			quit
		}
		
		if $listvalid(pCondition) {
			set pPredicate = ##class(%DeepSee.PMML.Definition.Util.SimplePredicate).%New()
			set pPredicate.field = $li(pCondition, 1)
			if ($li(pCondition,3)="") {
				set pPredicate.operator = $s($li(pCondition,2)="=":"isMissing", 1:"isNotMissing")
			} else {
				do pPredicate.SetOperatorSymbol($li(pCondition, 2))
				set pPredicate.value = $li(pCondition, 3)
			}
			quit
		}
		
		set pPredicate = ##class(%DeepSee.PMML.Definition.Util.CompoundPredicate).%New()
		set pPredicate.booleanOperator = $$$LOWER(pCondition)
		
		set i = ""
		for {
			set i = $order(pCondition(i))
			quit:i=""
			
			kill tSubCondition
			merge tSubCondition = pCondition(i)
			set tSC = ..CreatePredicateElement(.tSubCondition, .tSubPredicate)
			quit:$$$ISERR(tSC)
			
			do pPredicate.Predicates.Insert(tSubPredicate)
		}
		
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
<Value>ScoringMetric</Value>
</Value>
<Value name="8">
<Value>MaxTreeDepth</Value>
</Value>
<Value name="9">
<Value>MissingValueStrategy</Value>
</Value>
<Value name="10">
<Value>MissingValuePenalty</Value>
</Value>
<Value name="11">
<Value>NoTrueChildStrategy</Value>
</Value>
<Value name="12">
<Value>DataSources</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
