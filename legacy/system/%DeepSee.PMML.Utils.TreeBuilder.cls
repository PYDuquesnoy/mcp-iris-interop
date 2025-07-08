/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Utility class to build Tree models for a <class>%DeepSee.PMML.Dataset</class> object.
Class %DeepSee.PMML.Utils.TreeBuilder Extends %RegisteredObject [ System = 4 ]
{

/// The dataset to mine.
Property Dataset As %DeepSee.PMML.Dataset;

/// The target field whose value is to be derived through this tree. 
/// This field should be part of <property>Dataset</property>.
Property TargetField As %String;

/// ..Tree = $i
/// ..Tree(NodeId) = $lb(parent, targetValue, confidence, count, isLeaf)
/// ..Tree(NodeId, "condition") = [AND|OR|$lb(field, operator, value)]
/// ..Tree(NodeId, "ch", ChildNode) = ""
/// ..Tree(NodeId, "distribution", value) = count
Property Tree As %Integer [ MultiDimensional ];

/// Default (maximum) number of branches per node
Property SplitsPerNode As %Integer [ InitialExpression = 2 ];

/// Minimal % of the total number of records represented by a node that should be covered by a 
/// branch. If a branch covers fewer records than this value, it is ignored
Property MinimalSplitCoverage As %Numeric [ InitialExpression = 0.05 ];

/// Whether or not to track distribution information for tree nodes
Property TrackDistributions As %Boolean [ InitialExpression = 1 ];

/// Whether or not to consider null (missing) values for split criteria
Property ConsiderNullValues As %Boolean [ InitialExpression = 0 ];

/// Which metric to use to judge split quality. This metric is returned as the split "score"
/// by <method>FindSplits</method>
Property SplitScoringAlgorithm As %String(VALUELIST = ",Confidence,GiniImpurity,InformationGain") [ InitialExpression = "GiniImpurity" ];

Method %OnNew(pDataset As %DeepSee.PMML.Dataset, pTargetField As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		quit:'pDataset.HasField(pTargetField, .tSC)
		set ..Dataset = pDataset
		set ..TargetField = pTargetField
		set ..Tree = 0
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// After changing building parameters, run this method to erase the current tree structure so
/// <method>Build</method> can be run again. 
Method Reset() As %Status
{
	kill ..Tree
	set ..Tree = 0
	quit $$$OK
}

/// <p>Builds a tree structure with a maximum depth of <var>pMaxDepth</var>.</p>
/// <p>If a tree structure was already built, this method silently exits. Use <method>Reset</method>
/// to erase an existing tree structure.</p>
Method Build(pMaxDepth As %Integer = 3)
{
	set tSC = $$$OK
	try {
		quit:$d(..Tree(0))
		
		set tSC = ..SplitNode(0)
		quit:$$$ISERR(tSC)
		
		merge tChildrenForLevel(0) = ..Tree(0,"ch")
		for tLevel = 1:1:pMaxDepth {
			set tNode = ""
			for {
				set tNode = $order(tChildrenForLevel(tLevel-1, tNode))
				quit:tNode=""
				
				set tSC = ..SplitNode(tNode)
				quit:$$$ISERR(tSC)
				
				merge tChildrenForLevel(tLevel) = ..Tree(tNode,"ch")
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// append distribution, targetvalue and isLeaf for root node
		set tSC = ..Dataset.Get1DDistribution(..TargetField, .tDistribution)
		quit:$$$ISERR(tSC)
		set tIsLeaf = ($g(tDistribution)=1), tTargetValue = "", tBestCount = ""
		for i = 1:1:$g(tDistribution) {
			set tCount = $li(tDistribution(i),2)
			set tValue = $li(tDistribution(i),1)
			set:tCount>tBestCount tBestCount = tCount, tTargetValue = tValue
			set:..TrackDistributions ..Tree(0,"distribution",$s(tValue="":$c(0), 1:tValue)) = tCount
		}
		set tTotal = tDistribution("total")
		set ..Tree(0) = $lb(,tTargetValue,$s(tTotal:tBestCount/tTotal, 1:0), tTotal, tIsLeaf)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the inverse of <var>pFilter</var>, equivalent to a boolean NOT of the entire <var>pFilter</var>.
Method GetInvertedFilter(ByRef pFilter, Output pInverted) As %Status
{
	set tSC = $$$OK
	try {
		kill pInverted
		quit:$g(pFilter)=""
		
		// if pFilter is a single predicate, just invert the operator
		if $listvalid(pFilter) {
			set pInverted = pFilter
			set $li(pInverted,2) = $case($li(pFilter,2), "=":"!=", "!=":"=", ">":"<=", "<":">=", "<=":">", ">=":"<")
			quit
		}
		
		// for composite filters, use Bayes' theorem
		set pInverted = $case($$$UPPER(pFilter), "AND":"OR", "OR":"AND")
		set i = ""
		for {
			set i = $order(pFilter(i))
			quit:i=""
			
			kill tSubFilter, tSubInverted
			merge tSubFilter = pFilter(i)
			set tSC = ..GetInvertedFilter(.tSubFilter, .tSubInverted)
			quit:$$$ISERR(tSC)
			
			merge pInverted(i) = tSubInverted
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Appends <var>pOtherFilter</var> to <var>pFilter</var> using <var>pLogic</var> logic
Method MergeFilters(ByRef pFilter, ByRef pOtherFilter, pLogic As %String = "AND") As %Status
{
	set tSC = $$$OK
	try {
		// if pOtherFilter is empty, just exit
		quit:$g(pOtherFilter)=""
		
		// if pFilter is empty, just start with pLogic
		if $g(pFilter)="" {
			set pFilter = pLogic
		}
		
		// if pFilter is a leaf condition, start with pLogic
		elseif $listvalid(pFilter) {
			set pFilter(1) = pFilter
			set pFilter = pLogic
		}
		
		set tFilterIndex = $o(pFilter(""),-1)
		
		// if pOtherFilter is a leaf condition, append it
		if $listvalid(pOtherFilter) {
			set pFilter($i(tFilterIndex)) = pOtherFilter
		}
		
		// if pOtherFilter has the same logic, append its children
		elseif $g(pOtherFilter) = pLogic {
			set i = ""
			for {
				set i = $order(pOtherFilter(i))
				quit:i=""
				
				merge pFilter($i(tFilterIndex)) = pOtherFilter(i)
			}
		}
		
		// if pOtherFilter has different logic, append it as a separate node
		else {
			merge pFilter($i(tFilterIndex)) = pOtherFilter
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the combination of filter conditions (<var>pFilters</var>) a record should satisfy
/// to end up in node <var>pNode</var>. This is a combination of the node's own condition, 
/// its full ancestry and any prior siblings' conditions.
Method GetNodeFilters(pNode As %Integer, Output pFilters) As %Status
{
	set tSC = $$$OK
	try {
		kill pFilters
		quit:'pNode
		quit:'$d(..Tree(pNode), tDetails)
		
		// check if node condition is not simply "true"
		if $d(..Tree(pNode,"condition")) {
			merge pFilters = ..Tree(pNode,"condition")
		}
		
		// append parent filters
		set tParentNode = $li(tDetails,1)
		if (tParentNode) {
			set tSC = ..GetNodeFilters(tParentNode, .tParentFilters)
			quit:$$$ISERR(tSC)
			
			set tSC = ..MergeFilters(.pFilters, .tParentFilters)
			quit:$$$ISERR(tSC)
		}
		
		// append inverse of *preceding* sibling filters
		set tSiblingNode = pNode
		for {
			set tSiblingNode = $order(..Tree(tParentNode, "ch", tSiblingNode), -1)
			quit:tSiblingNode=""
			
			continue:'$d(..Tree(tSiblingNode, "condition"))
			
			// invert sibling condition
			kill tSiblingCondition, tInvertedCondition
			merge tSiblingCondition = ..Tree(tSiblingNode, "condition")
			set tSC = ..GetInvertedFilter(.tSiblingCondition, .tInvertedCondition)
			quit:$$$ISERR(tSC)
			
			set tSC = ..MergeFilters(.pFilters, .tInvertedCondition)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Splits node <var>pNode</var> in <property>SplitsPerNode</property> sub-nodes (or fewer, if
/// not enough candidate splits satisfy coverage and other selection criteria).
Method SplitNode(pNode As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		// don't bother about leaf nodes
		quit:pNode&&$lg(..Tree(pNode),5)
		
		
		// find candidate splits
		set tSC = ..FindSplits(pNode, .tSplits)
		quit:$$$ISERR(tSC)
		
		
		// select splits with highest "score" and add as child node
		kill tSortedSplits
		for i = 1:1:$g(tSplits) {
			quit:i=""
			if ..MinimalSplitCoverage {
				set tCoverage = $lg(tSplits(i),2)
				continue:(tCoverage<..MinimalSplitCoverage)
				continue:(tCoverage>(1-..MinimalSplitCoverage))
			}
			set tSortedSplits(-$lg(tSplits(i),1), i) = tSplits(i)
		}
		
		kill tGroupCondition
		set tSort = "", tNodesAdded = 0
		for {
			set tSort = $order(tSortedSplits(tSort))
			quit:tSort=""
			
			set i = ""
			for {
				set i = $order(tSortedSplits(tSort, i), 1, tSplit)
				quit:i=""
				
				set tNewNode = $i(..Tree)
				set ..Tree(tNewNode) = $lb(pNode) _ $li(tSplit,3,5)
				merge ..Tree(tNewNode, "condition") = tSplits(i,"condition")
				set ..Tree(pNode,"ch",tNewNode) = ""
				set x = $i(tNodesAdded)
				
				set tGroupCondition($i(tGroupCondition)) = tSplits(i,"condition")
				
				merge:..TrackDistributions ..Tree(tNewNode, "distribution") = tSplits(i,"distribution")
				
				// theoretically, the information gain and other score values for subsequent
				// splits might change because of the preceding split conditions for that node.
				// as we usually look for binary trees, we currently ignore this.
				quit:tNodesAdded>=(..SplitsPerNode-1)
			}
			quit:tNodesAdded>=(..SplitsPerNode-1)
		}
		
		// add <true> node to catch remaining cases
		if tNodesAdded && ($g(tSplits)>(..SplitsPerNode-1)) {
			
			// store node to enable ..GetNodeFilters()
			set tNewNode = $i(..Tree)
			set ..Tree(tNewNode) = $lb(pNode,,,,) // placeholder to be overwritten later!
			set ..Tree(pNode,"ch",tNewNode) = ""
			
			// derive distributions, targetValue and isLeaf
			set tSC = ..GetNodeFilters(tNewNode, .tFilters)
			quit:$$$ISERR(tSC)
			set tSC = ..Dataset.Get1DDistribution(..TargetField, .tDistribution, .tFilters)
			quit:$$$ISERR(tSC)
			set tIsLeaf = ($g(tDistribution)=1), tTargetValue = "", tBestCount = ""
			for i = 1:1:$g(tDistribution) {
				set tCount = $li(tDistribution(i),2)
				set tValue = $li(tDistribution(i),1)
				set:tCount>tBestCount tBestCount = tCount, tTargetValue = tValue
				set:..TrackDistributions ..Tree(tNewNode,"distribution",$s(tValue="":$c(0), 1:tValue)) = tCount
			}
			set tTotal = tDistribution("total")
			
			// if no records left in this <true> node, erase
			if 'tTotal {
				kill ..Tree(tNewNode), ..Tree(pNode,"ch",tNewNode)
			} else {
				
				if $g(tGroupCondition)=1 {
					set tGroupCondition = tGroupCondition(1)
				} else {
					set tGroupCondition = "OR"
				}
				do ..GetInvertedFilter(.tGroupCondition, .tInverse)
				merge ..Tree(tNewNode,"condition") = tInverse
				
				set ..Tree(tNewNode) = $lb(pNode, tTargetValue, tBestCount/tTotal, tTotal, tIsLeaf)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns an unsorted array of candidate splits for node <var>pNode</var>:
/// 		pSplits(n) = $lb(score, coverage, targetValue, confidence, recordCount, isLeaf)
/// 		pSplits(n,"condition") = ...
Method FindSplits(pNode As %Integer, Output pSplits) As %Status
{
	set tSC = $$$OK
	try {
		kill pSplits
		set pSplits=0
		
		// build current node filters based on ancestry
		set tSC = ..GetNodeFilters(pNode, .tFilters)
		quit:$$$ISERR(tSC)
		
		kill tFields
		set tFieldName = ""
		for {
			set tField = ..Dataset.Fields.GetNext(.tFieldName)
			quit:tFieldName=""
			continue:tFieldName=..TargetField
			
			set tFields(tFieldName) = tField
		}
		
		// we'll skip fields with simple filter conditions and simple AND arrays
		// composite-filtered fields will eventually be weeded out by coverage criteria
		if ($g(tFilters)'="") && $listvalid($g(tFilters)) {
			
			set tFilterField = $li(tFilters,1)
			set tFilterOperator = $li(tFilters,2)
			if (tFilterOperator="=") || (tFilterOperator="!=") {
				
				// make sure the filtered value is excluded
				set tFilterValue = $li(tFilters,3)
				set tFilterValue = $s(tFilterValue="":$c(0), 1:tFilterValue)
				set tFields(tFilterField, "exclude", tFilterValue) = ""
			} else {
				kill tFields(tFilterField)
			}
			
		} elseif ($g(tFilters)="AND") {
			set i = ""
			for {
				set i = $order(tFilters(i), 1, tFilter)
				quit:i=""
				
				// skip composite subfilters
				continue:'$listvalid(tFilter)
				
				set tFilterField = $li(tFilter,1)
				set tFilterOperator = $li(tFilter,2)
				if (tFilterOperator="=") || (tFilterOperator="!=") {
					
					// make sure the filtered value is excluded
					set tFilterValue = $li(tFilter,3)
					set tFilterValue = $s(tFilterValue="":$c(0), 1:tFilterValue)
					set tFields(tFilterField, "exclude", tFilterValue) = ""
				} else {
					kill tFields(tFilterField)
				}
			}
		}
		
		// build candidate splits for each field
		set tFieldName = ""
		for {
			set tFieldName = $order(tFields(tFieldName), 1, tField)
			quit:tFieldName=""
			
			if (tField.OpType="categorical") {
				
				// now look at the distribution of this field against the target field
				set tSC = ..Dataset.GetXDDistribution($lb(tFieldName, ..TargetField), .tDistribution, .tFilters)
				quit:$$$ISERR(tSC)
				
				// calculate the information gain for each field value
				set i = "", tTotalCount = tDistribution("total")
				for {
					set i = $order(tDistribution(i))
					quit:i=""
					
					// skip "total" and "value" subscripts
					continue:'i 
					
					// skip values already filtered by parent nodes
					set tFieldValue = $g(tDistribution("value",1,i))
					continue:$d(tFields(tField,"exclude",$s(tFieldValue="":$c(0), 1:tFieldValue)))
					
					// skip null values if required
					continue:('..ConsiderNullValues)&&(tFieldValue="")
					
					kill tTrack
					set tRowTotal = $g(tDistribution("total",1,i))
					continue:'tRowTotal
					set tScore = $case(..SplitScoringAlgorithm, "GiniImpurity":1, :0)
					set j = "", tTargetValueCount = 0, tBestCount=0, tTargetValueId=""
					for {
						set j = $order(tDistribution(i,j),1,tCount)
						quit:j=""
						continue:'tCount
						
						set tFreq = tCount/tRowTotal
						if (..SplitScoringAlgorithm = "GiniImpurity") {
							set tScore = tScore - (tFreq**2)
						} elseif (..SplitScoringAlgorithm = "InformationGain") {
							set tScore = tScore - (tFreq * $zlog(tFreq)/$zlog(2))
						}
						set x = $i(tTargetValueCount)
						
						set:(tCount>tBestCount) tBestCount=tCount, tTargetValueId = j
						
						if (..TrackDistributions) {
							set tTrack(j) = tCount
						}
					}
					continue:'tTargetValueCount
					set tIsLeaf = (tTargetValueCount=1)
					set tConfidence = tBestCount/tRowTotal
					set tTargetValue = $g(tDistribution("value",2,+tTargetValueId))
					
					// optionally do some bootstrapping to adjust tScore and tConfidence/tCoverage (?)
					
					set:..SplitScoringAlgorithm="Confidence" tScore = tConfidence
					set pSplits($i(pSplits)) = $lb(tScore, tRowTotal/tTotalCount, tTargetValue, tConfidence, tRowTotal, tIsLeaf)
					set pSplits(pSplits, "condition") = $lb(tField.Name, "=", tFieldValue)
					
					if (..TrackDistributions) {
						set j = ""
						for {
							set j = $order(tTrack(j),1,tCount)
							quit:j=""
							continue:'tCount
							set tTargetValue = tDistribution("value",2,j)
							set tTargetValue = $s(tTargetValue="":$c(0), 1:tTargetValue)
							set pSplits(pSplits, "distribution", tTargetValue) = tCount
						}
					}
				}
				
			} else { // optype="continuous" or optype="ordinal"
				
				// simple implementation: find the average of each target category and then
				// look for the one which has the greatest distance between its average
				// and the weighted average of the other category averages. Then use the value
				// in the middle of these two numbers as the split point.
				set tSC = ..Dataset.GetAggregatesByCategory(tFieldName, ..TargetField, .tAggregates, .tFilters)
				quit:$$$ISERR(tSC)
				
				kill tAvgDistance
				set tTotalCount = 0
				for i = 1:1:tAggregates {
					
					set tAverage = $lg(tAggregates(i),3)
					set tTotalCount = tTotalCount + $lg(tAggregates(i),2)
					
					set tWeightedAverage = 0, tWeightedCount = 0
					for j = 1:1:tAggregates {
						continue:i=j
						set tWeightedAverage = tWeightedAverage + ($lg(tAggregates(j),3) * $lg(tAggregates(j),7))
						set tWeightedCount = tWeightedCount + $lg(tAggregates(j),7)
					}
					set tWeightedAverage = $s(tWeightedCount:tWeightedAverage / tWeightedCount, 1:0)
					
					set tAvgDistance(-$zabs(tAverage - tWeightedAverage), i) = $lb(tFieldName, $s(tAverage<tWeightedAverage:"<", 1:">"), (tAverage + tWeightedAverage) / 2)
				}
				
				set tBestDistance = $order(tAvgDistance(""))
				continue:tBestDistance=""
				set tBestCategoryId = $order(tAvgDistance(tBestDistance, ""), 1, tSplitCondition)
				set tTargetValue = $li(tAggregates(tBestCategoryId),1)
				set pSplits($i(pSplits), "condition") = tSplitCondition
				
				// now analyze the impact of this split
				kill tNewFilter
				merge tNewFilter = tFilters
				do ..MergeFilters(.tNewFilter, tSplitCondition)
				set tSC = ..Dataset.Get1DDistribution(..TargetField, .tDistribution, .tNewFilter)
				quit:$$$ISERR(tSC)
				set tRowTotal = tDistribution("total")
				set tIsLeaf = (tDistribution=1)
				set tScore = $case(..SplitScoringAlgorithm, "GiniImpurity":1, :0)
				for i = 1:1:tDistribution {
					set tValue = $li(tDistribution(i),1)
					set tCount = $li(tDistribution(i),2)
					set:(tValue=tTargetValue) tConfidence = tCount/tRowTotal
					
					set tFreq = tCount/tRowTotal
					if (..SplitScoringAlgorithm = "GiniImpurity") {
						set tScore = tScore - (tFreq**2)
					} elseif (..SplitScoringAlgorithm = "InformationGain") {
						set tScore = tScore - (tFreq * $zlog(tFreq)/$zlog(2))
					}
					
					if (..TrackDistributions) {
						set tValueIndex = $s(tValue="":$c(0), 1:tValue)
						set pSplits(pSplits, "distribution", tValueIndex) = tCount
					}
				}
				
				set:..SplitScoringAlgorithm="Confidence" tScore = tConfidence
				//pSplits(n) = $lb(score, coverage, targetValue, confidence, isLeaf)
				set pSplits(pSplits) = $lb(tScore, tRowTotal/tTotalCount, tTargetValue, tConfidence, tRowTotal, tIsLeaf)
				
			}
		}
	
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Prints the tree (starting with <var>pNode</var>) to the terminal.
Method Print(pNode As %Integer = 0, pLevel As %Integer = 0, pPrintDistribution As %Boolean = 0) As %Status
{
	// indent by level
	for i = 1:1:pLevel {
		write $c(9)
	}
	
	// derive condition string
	kill tConditionTree
	merge tConditionTree = ..Tree(pNode,"condition")
	set tCondition = ..GetCondition(.tConditionTree)
	kill tConditionTree
	
	// print node
	set tInfo = ..Tree(pNode)
	write $s(pNode:pNode_": "_tCondition, 1:"<Root node>")
	write " => [",$lg(tInfo,2),"] @ ",$normalize($lg(tInfo,3)*100,2),"% of ",+$lg(tInfo,4)
	write:$lg(tInfo,5) " (leaf)"
	write !
	
	// print distribution
	if (pPrintDistribution) && ($o(..Tree(pNode, "distribution", ""))'="") {
		for i = 1:1:pLevel { write $c(9) }
		write $s(pNode>99:"     ", pNode>9:"    ", 1:"   ")
		write "distribution:"
		set tTargetValue = ""
		for {
			set tTargetValue = $order(..Tree(pNode, "distribution", tTargetValue), 1, tCount)
			quit:tTargetValue=""
			write " [",$replace(tTargetValue,$c(0),""""""),": ",tCount,"]"
		}
		write !
	}
	
	// print child nodes
	set tChild = ""
	for {
		set tChild = $order(..Tree(pNode, "ch", tChild))
		quit:tChild=""
		do ..Print(tChild, pLevel+1, pPrintDistribution)
	}
	quit $$$OK
}

ClassMethod GetCondition(ByRef pArray) As %String [ Internal ]
{
	quit:'$d(pArray, tValue) "<True>"
	if $listvalid(tValue) {
		set tOperator = ##class(%DeepSee.PMML.Definition.Util.SimplePredicate).SymbolFromOperator($li(tValue,2))
		quit "("_$li(tValue,1)_" "_tOperator_" "_$$$QUOTE($li(tValue,3))_")"
	} else {
		set tCondition=""
		set i = ""
		for {
			set i = $order(pArray(i))
			quit:i=""
			kill tSubArray
			merge tSubArray = pArray(i)
			set tCondition = tCondition _ $lb(..GetCondition(.tSubArray))
		}
		set tCondition = "("_$lts(tCondition," "_tValue_" ")_")"
		quit tCondition
	}
}

ClassMethod GetFieldList(ByRef pArray) As %List [ Internal ]
{
	quit:'$d(pArray, tValue) ""
	if $listvalid(tValue) {
		quit $lb($li(tValue,1))
	} else {
		set tList=""
		set i = ""
		for {
			set i = $order(pArray(i))
			quit:i=""
			kill tSubArray
			merge tSubArray = pArray(i)
			set tSubList = ..GetFieldList(.tSubArray)
			for j = 1:1:$ll(tSubList) {
				set tItem = $li(tSubList,j)
				set:$lf(tList,tItem) tList = tList _ $lb(tItem)
			}
		}
		quit tList
	}
}

}
