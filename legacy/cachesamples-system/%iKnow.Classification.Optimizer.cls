/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>This class automates selecting "appropriate" terms for a <class>%iKnow.Classification.Builder</class>.
/// After pointing an Optimizer instance to the Builder object that needs optimization, use the
/// <method>LoadTermsArray</method> and <method>LoadTermsSQL</method> methods to queue a large
/// number of potentially interesting terms the Optimizer should test. Then invoke its
/// <method>Optimize</method> method to let the Optimizer loop through the list of suggested terms 
/// automatically and add those terms having the highest positive impact on model accuracy (as
/// measured according to <property>ScoreMetric</property>), removing terms that were already
/// added to the model but turn out to have no significant positive impact on the model's accuracy.</p>
/// <p>See the individual property descriptions of their impact on the optimization process.</p>
Class %iKnow.Classification.Optimizer Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property TaskId As %Integer [ Internal, ReadOnly ];

Property Debug As %String [ Internal ];

Property IsMaster As %Boolean [ InitialExpression = 1, Internal ];

/// If set to a boolean value, defines whether or not to write output to the current device during
/// the <method>Optimize</method> method. If set to a string, it is treated as a global reference
/// to which output needs to be written.
Property Verbose As %String [ InitialExpression = 0 ];

/// The test set to validate model accuracy increases/decreases against.
Property TestSet As %iKnow.Filters.Filter;

/// The metadata field containing the actual category values to compare predictions against.
/// This assumes the value of the Builder's MetadataField property when registering an IKnowBuilder
/// instance as <property>Builder</property>, if not set explicitly.
Property MetadataField As %String;

/// The domain using which the categorization model is being trained and tested.
/// This assumes the value of the Builder's DomainId property when registering an IKnowBuilder
/// instance as <property>Builder</property>, if not set explicitly.
Property DomainId As %Integer;

/// The builder object to be optimized.
Property Builder As %iKnow.Classification.Builder;

/// The number of terms to test in each round. If left at 0, this defaults to the number of
/// cores the system has available, which should be most efficient. 
Property AddWindowSize As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// The number of terms to add during an <method>AddTerms</method> cycle. The top results according
/// to <method>RankScores</method> will be added, as selected from the <property>AddWindowSize</property>
/// terms tested in the cycle.
Property AddCount As %Integer(MINVAL = 1) [ InitialExpression = 1 ];

/// The minimal score increase % a term should ensure to be retained for further testing. If the
/// score does not increase by at least this figure, it will be discarded from the list of terms
/// to test. A value of 1 means the minimal score increase should be 1%
Property MinimalScoreIncrease As %Double(MAXVAL = 100, MINVAL = -100) [ InitialExpression = 0.1 ];

/// The default accuracy metric to use for evaluating test results, as used by <method>RankScores</method>.
/// If set to a 'Weighted*' value, the weights are retrieved from <property>CategoryWeights</property>.
Property ScoreMetric As %String(VALUELIST = ",MacroFmeasure,MacroPrecision,MacroRecall,MicroFmeasure,MicroPrecision,MicroRecall,WeightedPrecision,WeightedRecall,WeightedFmeasure") [ InitialExpression = "MacroFmeasure" ];

/// <p>The ratio of <method>RemoveTerms</method> cycles vs <method>AddTerms</method> cycles.
/// This should be a value between 0 and 1 (inclusive).</p>
/// <p>Note: Remove cycles take significantly longer than add cycles</p>
Property RemoveStepRatio As %Double(MAXVAL = 1, MINVAL = 0) [ InitialExpression = 0.1 ];

/// The number of terms to remove in a "remove" cycle. Setting this value > 1 assumes the terms
/// deemed irrelevant (and scheduled to be removed) don't influence one another much and removing
/// more in a single cycle will not worsen performance much more than the individual performance
/// changes of each term removal alone.
Property RemoveCount As %Integer(MINVAL = 1) [ InitialExpression = 3 ];

/// The maximal decrease in performance the optimizer should accept when trying to remove terms.
/// If removing a term would imply a decrease larger than this figure, it will not be removed.
/// A value of 1 means the maximal score decrease is 1%
Property MaximalScoreDecrease As %Double(MAXVAL = 100, MINVAL = -100) [ InitialExpression = 0.05 ];

/// The class name of the current "best" classifier.
/// This value is set during <method>Optimize</method>, or as part of the <method>AddTerms</method>
/// and <method>RemoveTerms</method> methods.
Property CurrentClassifier As %String [ ReadOnly ];

/// The score of the current classifier. This value is updated by <method>AddTerms</method>
/// and <method>RemoveTerms</method>.
Property CurrentScore As %Double [ ReadOnly ];

/// The key to <class>%DeepSee.PMML.Utils.TempResult</class> for the test results of
/// <property>CurrentClassifier</property>.
Property CurrentTestId As %Integer [ ReadOnly ];

/// <p>If <property>ScoreMetric</property> is set to a 'Weighted*' value, the weights for each category
/// are retrieved from this array, indexed by category name. If no category weight is set, it is
/// assumed to be 0.</p>
/// <p>Note: Weights don't need to add up to 1.</p>
Property CategoryWeights [ MultiDimensional ];

Method BuilderSet(pBuilder As %iKnow.Classification.Builder) As %Status [ Internal, ServerOnly = 1 ]
{
	set i%Builder = pBuilder
	if $isobject($g(pBuilder)) && pBuilder.%IsA("%iKnow.Classification.IKnowBuilder") {
		set:'..DomainId ..DomainId = pBuilder.DomainId
		set:(..MetadataField="") ..MetadataField = pBuilder.MetadataField
		set:(..TestSet="") ..TestSet = pBuilder.TestSet
	}
	quit $$$OK
}

Method %OnNew(pTaskId As %Integer = 0, pMasterObject As %Boolean = 1) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		set i%TaskId = $s(pTaskId:pTaskId, 1:$i(^IRIS.Temp.IK.Optimizer))
		set i%IsMaster = pMasterObject
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Loads a list of candidate terms based on a SQL query. The query should return a column named
/// "term" containing the term's value and may return columns named "type", "negation" and "match"
/// to configure the type, negation and count policy for each term being retrieved, respectively.
Method LoadTermsSQL(pSQL As %String) As %Status
{
	set tSC = $$$OK
	try {
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(pSQL)
		quit:$$$ISERR(tSC)
		
		#dim tResult As %SQL.StatementResult = tStatement.%Execute()
		set tTermCol = $s($d(tResult.%GetMetadata().columnIndex("TERM"),tTermColInfo):$lg(tTermColInfo,1), 1:1)
		set tTypeCol = $s($d(tResult.%GetMetadata().columnIndex("TYPE"),tTypeColInfo):$lg(tTypeColInfo,1), 1:0)
		set tNegationCol = $s($d(tResult.%GetMetadata().columnIndex("NEGATION"),tNegationColInfo):$lg(tNegationColInfo,1), 1:0)
		set tMatchCol = $s($d(tResult.%GetMetadata().columnIndex("MATCH"),tMatchColInfo):$lg(tMatchColInfo,1), 1:0)
		
		while tResult.%Next() {
			kill tTerm
			set tTerm = tResult.%GetData(tTermCol)
			set:tTypeCol tTerm("type") = tResult.%GetData(tTypeCol)
			set:tNegationCol tTerm("negation") = tResult.%GetData(tNegationCol)
			set:tMatchCol tTerm("match") = tResult.%GetData(tMatchCol)
			
			set n = $i(^IRIS.Temp.IK.Optimizer(..TaskId, "terms"))
			merge ^IRIS.Temp.IK.Optimizer(..TaskId, "terms", n) = tTerm
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Loads all terms from the supplied array.
/// If <var>pListIndex</var> is non-zero, the term info is read from that index at each array position.
/// If the term info itself is a list structure as well, it is interpreted as follows:
/// 		pTerms(n) = $lb(term, type, negationpolicy, matchpolicy)
Method LoadTermsArray(ByRef pTerms, pListIndex As %Integer = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		set i = ""
		for {
			set i = $order(pTerms(i), 1, tTermInfo)
			quit:i=""
			
			set:pListIndex tTermInfo = $lg(tTermInfo,pListIndex)
			continue:tTermInfo=""
			
			kill tTerm
			if $lv(tTermInfo) {
				set tTerm = $lg(tTermInfo,1)
				continue:tTerm=""
				set:$ld(tTermInfo,2) tTerm("type") = $lg(tTermInfo,2)
				set:$ld(tTermInfo,3) tTerm("negation") = $lg(tTermInfo,3)
				set:$ld(tTermInfo,4) tTerm("match") = $lg(tTermInfo,4)
			} else {
				set tTerm = tTermInfo
			}
			
			set n = $i(^IRIS.Temp.IK.Optimizer(..TaskId, "terms"))
			merge ^IRIS.Temp.IK.Optimizer(..TaskId, "terms", n) = tTerm
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Initializes this Optimizer instance.
/// This method is called automatically as part of <method>Optimize</method>
Method Initialize() As %Status
{
	set tSC = $$$OK
	try {
		// skip if already initialized
		quit:i%CurrentScore
		
		set tSC = ..RunTest(.tTestId, .tInitialScores, .tClassName, 0, 0)
		quit:$$$ISERR(tSC)
		set i%CurrentClassifier = tClassName, i%CurrentTestId = tTestId
		set i%CurrentScore = ..GetScore(.tInitialScores, tTestId)
		
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "Initialize()")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>In at most <var>pMaxSteps</var> steps, the current <property>Builder</property> will be optimized by
/// testing, one at a time, the terms added through <method>LoadTermsSQL</method> and
/// <method>LoadTermsArray</method>, judging which term works best for each test window by the
/// results of <method>RankScores</method> (see also <method>AddTerms</method>). Every (1/<property>RemoveStepRatio</propery>) rounds,
/// all terms in the dictionary so far will be tested for their contribution to the current model
/// score and the lowest <property>RemoveCount</property> terms will be removed (see also <method>RemoveTerms</method>).</p>
/// <p>At the end of the optimization process, in addition to <property>Builder</property> being
/// updated, <property>CurrentClassifier</property> will contain the class name of the last
/// test class used to achieve the best result and <var>pTestId</var> will point to the test
/// results for that class.</p>
Method Optimize(pMaxSteps As %Integer = 20) As %Status
{
	set tSC = $$$OK
	try {
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "Optimize("_pMaxSteps_")")
		
		// establish baseline score
		do ..Log("Establishing baseline score: ")
		set tSC = ..Initialize()
		quit:$$$ISERR(tSC)
		do ..Log($fnumber(..CurrentScore,"",4), 0)
		set tBaseline = ..CurrentScore
		
		set tSteps = 0, tAddSteps = 0, tStart = $zh, tAtEnd = 0
		while 'pMaxSteps || ($i(tSteps) <= pMaxSteps) {
			
			set tStepStart = $zh
			if ((tSteps * (1-..RemoveStepRatio)) > tAddSteps) {
				set tSC = ..AddTerms(..AddCount, .tAtEnd)
				quit:$$$ISERR(tSC)
				set tAddSteps = tAddSteps + 1
			} else {
				set tSC = ..RemoveTerms(..RemoveCount)
				quit:$$$ISERR(tSC)
				set tAtEnd = 0
			}
			
			do ..Log("Score after "_tSteps_" steps ("_tAddSteps_" add, "_(tSteps-tAddSteps)_" remove): "_$fnumber(..CurrentScore,"",4))
			
			set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "Optimize() - step "_tSteps, $zh-tStepStart, ..CurrentScore)
			
			// quit if we've gone through all candidate terms
			quit:tAtEnd
			quit:tSteps=pMaxSteps
		}
		quit:$$$ISERR(tSC)
		
		do ..Log("Optimization process ended after "_tSteps_" steps"_$s(tAtEnd:" (no more entities to test)", 1:""), 2)
		if (..CurrentScore>tBaseline) {
			do ..Log("Target metric improved by "_$fnumber(..CurrentScore-tBaseline,"",4)_"%")
		} else /*if (..CurrentScore=tBaseline)*/ {
			do ..Log("No significant improvements achieved using suggested terms")
		}
		
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "Optimize()", $zh-tStart)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Test the impact of removing each term in the current model's TermDictionary individually. 
/// The <var>pCount</var> terms for which, after removing it, <method>RankScores</method>
/// still returns the best score (which supposedly implies its contribution was minimial), will
/// be removed from the TermDictionary, unless the decrease in performance surpasses
/// <property>MaximalScoreDecrease</property>.</var></p>
/// <p>If <var>pCount</var> &lt; 0, it defaults to <property>RemoveCount</property>.</p>
Method RemoveTerms(pCount As %Integer = -1) As %Status
{
	set tSC = $$$OK
	try {
		set:pCount<0 pCount = ..RemoveCount
		
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "RemoveTerms("_pCount_")")
		
		#dim tQueue As %SYSTEM.WorkMgr
		set tQueue = $system.WorkMgr.Initialize(, .tSC)
		quit:$$$ISERR(tSC)
		
		set tBasicInfo("testid") = ..CurrentTestId
		set tBasicInfo("classname") = ..CurrentClassifier
		set tBasicInfo("domainid") = ..DomainId
		set tBasicInfo("testset") = $s($isobject(..TestSet):..TestSet.ToString(), 1:"")
		set tBasicInfo("metadatafield") = ..MetadataField
		merge ^IRIS.Temp.IK.Optimizer(..TaskId) = tBasicInfo
		
		set tStartTime = $zh
		do ..Builder.%GetTerms(.tTerms)
		
		for tTermPos = 1:1:tTerms {
			kill ^IRIS.Temp.IK.Optimizer(..TaskId, tTermPos) 
			set tTermInfo = $li(tTerms(tTermPos),1)
			set:$ld(tTerms(tTermPos),2) tTermInfo("type") = $li(tTerms(tTermPos),2)
			set:$ld(tTerms(tTermPos),3) tTermInfo("negation") = $li(tTerms(tTermPos),3)
			merge ^IRIS.Temp.IK.Optimizer(..TaskId, tTermPos, "term") = tTermInfo
			set ^IRIS.Temp.IK.Optimizer(..TaskId, tTermPos, "operation") = "remove"
			
			set tSC = tQueue.Queue("##class("_$classname()_").TestTermAsync", ..TaskId, tTermPos, ..Debug)
			quit:$$$ISERR(tSC)
			
			set tJobs(tTermPos) = ""
		}
		quit:$$$ISERR(tSC)
		
		set tSC = tQueue.Sync()
		quit:$$$ISERR(tSC)
		
		do ..Log("RemoveTerms() tests took "_($zh-tStartTime)_"s",2)
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "RemoveTerms() - jobs finished", $zh-tStartTime)
		
		// evaluate results
		kill tJobInfo
		set i = ""
		for {
			set i = $order(tJobs(i))
			quit:i=""
			merge tJobInfo(i) = ^IRIS.Temp.IK.Optimizer(..TaskId, i)
		}
		set tSC = ..RankScores(.tJobInfo, .tRanked)
		quit:$$$ISERR(tSC)
		
		// now select those <pCount> results that get the lowest score
		set tThreshold = (..CurrentScore-..MaximalScoreDecrease), tRejected=""
		for i = 1:1:$s(pCount<tRanked:pCount, 1:tRanked) {
			set tScore = $li(tRanked(i),2)
			quit:tScore>tThreshold
			
			set tTermInfo = tTerms($li(tRanked(i),1))
			set tSC = ..Builder.%RemoveTerm($li(tTermInfo,1),$lg(tTermInfo,2),$lg(tTermInfo,3))
			quit:$$$ISERR(tSC)
			set tRejected = tRejected _ ", " _ $$$QUOTE($li(tTermInfo,1))
		}
		
		do:tRejected'="" ..Log("Removing terms: "_$e(tRejected,3,*))
		do:tRejected="" ..Log("No terms were removed")
		
		// if we didn't reject anything, we can keep ..CurrentClassifier, ..CurrentTestId and ..CurrentScore
		quit:'$d(tReject)
		
		// if we removed just one term, we can recycle its results
		if $o(tReject("")) = $o(tReject(""),-1) {
			set tKeep = $o(tReject(""))
			set tNewClassifier = $g(^IRIS.Temp.IK.Optimizer(..TaskId, tKeep, "classname"))
			set tNewTestId = $g(^IRIS.Temp.IK.Optimizer(..TaskId, tKeep, "testid"))
			set tNewScore = $g(^IRIS.Temp.IK.Optimizer(..TaskId, tKeep, "scores", ..ScoreMetric))
		}
		
		// if we removed more, we'll have to run a new test
		else { 
			set tSC = ..RunTest(.tNewTestId, .tScores, .tNewClassName, 0, 0)
			quit:$$$ISERR(tSC)
			set tNewScore = $g(tScores(..ScoreMetric))
		}
		
		// drop previous "best" class and test results if we've got a better score now
		if (tNewClassName'=..CurrentClassifier) {
			set tSC = $$Delete^%apiOBJ(..CurrentClassifier, "-d")
			quit:$$$ISERR(tSC)
		}
		if (tNewTestId'=..CurrentTestId) {
			set tSC = ##class(%DeepSee.PMML.Utils).%DropResults(..CurrentTestId)
			quit:$$$ISERR(tSC)
		}
		set i%CurrentClassifier = tNewClassName, i%CurrentTestId = tNewTestId, i%CurrentScore = tNewScore
		
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "RemoveTerms() - results processed", $zh-tStartTime)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
		
	// clean up
	for i = 1:1:$g(tTerms) {
		set tSC2 = ..ClearTestInfo(i, (i'=$g(tKeep)), (i'=$g(tKeep)))
		set:$$$ISOK(tSC) tSC = tSC2
	}
	
	quit tSC
}

/// <p>This method does one round of processing, testing <property>AddWindowSize</property> candidate
/// terms and selecting the best <var>pCount</var> terms according to <method>RankScores</method>,
/// unless it wouldn't meet the <property>MinimalScoreIncreas</property> threshold.</p>
/// <p>If <var>pCount</var> &lt; 0, it defaults to <property>RemoveCount</property>.</p>
Method AddTerms(pCount As %Integer = -1, Output pAtEnd As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		set:pCount<0 pCount = ..AddCount
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "AddTerms("_pCount_")")
		
		#dim tQueue As %SYSTEM.WorkMgr
		set tQueue = $system.WorkMgr.Initialize(, .tSC)
		quit:$$$ISERR(tSC)
		
		set tBasicInfo("testid") = ..CurrentTestId
		set tBasicInfo("classname") = ..CurrentClassifier
		set tBasicInfo("domainid") = ..DomainId
		set tBasicInfo("testset") = $s($isobject(..TestSet):..TestSet.ToString(), 1:"")
		set tBasicInfo("metadatafield") = ..MetadataField
		merge ^IRIS.Temp.IK.Optimizer(..TaskId) = tBasicInfo
		
		set tCurrentTerm = "", tStartTime = $zh
		set tWindowSize = $s(..AddWindowSize:..AddWindowSize, 1:$system.CPU.%New().nThreads)
		for tJobNumber = 1:1:tWindowSize {
			
			// find the next term to test
			for {
				set tCurrentTerm = $order(^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tCurrentTerm), 1, tTermValue)
				quit:tCurrentTerm="" // no more terms to test!
				set tTermType = $g(^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tCurrentTerm, "type"))
				set tTermNegation = $g(^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tCurrentTerm, "negation"))
				set tTermMatch = $g(^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tCurrentTerm, "match"))
				set tTermObj = ##class(%iKnow.Classification.Definition.Term).%New()
				set tTermObj.type=tTermType, tTermObj.negation=tTermNegation, tTermObj.count=tTermMatch, tTermObj.value = tTermValue
				quit:'..Builder.%GetTermPosition(tTermObj)
			}
			quit:tCurrentTerm=""
			
			kill ^IRIS.Temp.IK.Optimizer(..TaskId, tJobNumber) 
			set ^IRIS.Temp.IK.Optimizer(..TaskId, tJobNumber, "term") = tCurrentTerm
			set ^IRIS.Temp.IK.Optimizer(..TaskId, tJobNumber, "operation") = "add"
			
			set tSC = tQueue.Queue("##class("_$classname()_").TestTermAsync", ..TaskId, tJobNumber, ..Debug)
			quit:$$$ISERR(tSC)
			
			set tJobs(tJobNumber) = ""
		}
		quit:$$$ISERR(tSC)
		set pAtEnd = (tCurrentTerm="")
		
		set tSC = tQueue.Sync()
		quit:$$$ISERR(tSC)
		
		do ..Log("AddTerms() test took "_($zh-tStartTime)_"s",2)
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "AddTerms() - jobs finished", $zh-tStartTime)
		
		// evaluate results
		kill tJobInfo, tReject
		set i = ""
		for {
			set i = $order(tJobs(i))
			quit:i=""
			merge tJobInfo(i) = ^IRIS.Temp.IK.Optimizer(..TaskId, i)
		}
		set tSC = ..RankScores(.tJobInfo, .tRanked, .tReject)
		quit:$$$ISERR(tSC)
		
		// process tRanked terms
		kill tAdded
		set tThreshold = ..CurrentScore + ..MinimalScoreIncrease, tAdded = 0, tAddedTerms = ""
		for i = 1:1:tRanked {
			set tJobID = $lg(tRanked(i),1), tScore = +$lg(tRanked(i),2)
			
			if (tScore < tThreshold) {
				set tReject(tJobID) = ""
				continue
			}
			
			continue:i<(tRanked-pCount+1)
			
			set tTermId = $g(tJobInfo(tJobID,"term"))
			continue:'tTermId
			merge tTermInfo = ^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tTermId)
			set tAddedTerms = tAddedTerms _ ", " _ $$$QUOTE(tTermInfo)
			set tTermType = $g(tTermInfo("type"), "entity")
			if (tTermType = "entity") {
				set tSC = ..Builder.%AddEntity(tTermInfo, $g(tTermInfo("negation"),"undefined"), $g(tTermInfo("match"), "exactCount"))
			} elseif (tTermType = "crc") {
				set tSC = ..Builder.%AddCRC($lfs(tTermInfo,":"), $g(tTermInfo("negation"),"undefined"), $g(tTermInfo("match"), "exactCount"))
			} elseif (tTermType = "cooccurrence") {
				set tSC = ..Builder.%AddCooccurrence($lfs(tTermInfo,":"), $g(tTermInfo("negation"),"undefined"), $g(tTermInfo("match"), "exactCount"))
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Unknown term type '"_tTermType_"')")
			}
			quit:$$$ISERR(tSC)
			kill ^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tTermId)
			set tAdded($i(tAdded)) = $lb(tJobID, tScore)
		}
		do:tAdded ..Log("Adding term"_$s(tAdded=1:"", 1:"s")_": "_$e(tAddedTerms, 3, *))
		
		
		// process reject list
		set tJobNumber = "", tRejected = ""
		for {
			set tJobNumber = $order(tReject(tJobNumber), 1, tRemark)
			quit:tJobNumber=""
			set tTermId = $g(tJobInfo(tJobNumber,"term"))
			continue:'tTermId
			set tRejected = tRejected _ ", " _ $$$QUOTE(^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tTermId))_tRemark
			kill ^IRIS.Temp.IK.Optimizer(..TaskId, "terms", tTermId)
		}
		do:tRejected'="" ..Log("Rejecting terms: "_$e(tRejected,3,*))
		
		
		// drop previous "best" class and test results if we've got a better score now
		quit:'tAdded
		
		// if we added just one term, we can recycle its results
		if (tAdded=1) {
			set tKeep = $li(tAdded(1),1)
			set tNewClassName = $g(^IRIS.Temp.IK.Optimizer(..TaskId, tKeep, "classname"))
			set tNewTestId = $g(^IRIS.Temp.IK.Optimizer(..TaskId, tKeep, "testid"))
			set tNewScore = $li(tAdded(1),2)
		}
		
		// if we added more, we'll have to run a new test
		else { 
			set tSC = ..RunTest(.tNewTestId, .tScores, .tNewClassName, 0, 0)
			quit:$$$ISERR(tSC)
			set tNewScore = ..GetScore(.tScores, tNewTestId)
		}
		
		// drop previous "best" class and test results if we've got a better score now
		if (tNewClassName'=..CurrentClassifier) {
			set tSC = $$Delete^%apiOBJ(..CurrentClassifier, "-d")
			quit:$$$ISERR(tSC)
		}
		if (tNewTestId'=..CurrentTestId) {
			set tSC = ##class(%DeepSee.PMML.Utils).%DropResults(..CurrentTestId)
			quit:$$$ISERR(tSC)
		}
		set i%CurrentClassifier = tNewClassName, i%CurrentTestId = tNewTestId, i%CurrentScore = tNewScore
		
		set:..Debug'="" @..Debug@($i(@..Debug)) = $lb($job, "AddTerms() - results processed", $zh-tStartTime)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
		
	// clean up
	for i = 1:1:$g(tWindowSize) {
		set tSC2 = ..ClearTestInfo(i, (i'=$g(tKeep)), (i'=$g(tKeep)))
		set:$$$ISOK(tSC) tSC = tSC2
	}
	
	quit tSC
}

/// Clears internal and generated artifacts for one particular test.
Method ClearTestInfo(pJobNumber As %Integer, pDropTestResults As %Boolean = 1, pDropTestClass As %Boolean = 1) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		if (pDropTestClass) {
			set tClassName = $g(^IRIS.Temp.IK.Optimizer(..TaskId, pJobNumber, "classname"))
			set:(tClassName'="") tSC = $$Delete^%apiOBJ(tClassName,"-d")
			quit:$$$ISERR(tSC)
		}
		
		if (pDropTestResults) {
			set tTestId = $g(^IRIS.Temp.IK.Optimizer(..TaskId, pJobNumber, "testid"))
			set:tTestId tSC = ##class(%DeepSee.PMML.Utils).%DropResults(tTestId)
			quit:$$$ISERR(tSC)
		}
		
		kill ^IRIS.Temp.IK.Optimizer(..TaskId, pJobNumber)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This method ranks the test results in <var>pJobInfo</var> according to the desired "score".
/// By default, it will just look at the value of the metric identified by 
/// <property>ScoreMetric</property>, but this method can be overridden to calculate in more detail.
/// When this method returns, <var>pRanked</var> is an ordered array containing the job IDs and score in
/// ASCENDING order (pRanked(1) is the worst job):</p>
/// <blockquote>pRanked([position]) = $lb([jobID], [score])</blockquote>
/// 
/// <p><var>pJobInfo</var> should contain the following information:<br/>
/// 		pJobInfo([jobID], "scores", [metric]) = [value]<br/>
/// 		pJobInfo([jobID], "testid") = [test ID]  (key for <class>%DeepSee.PMML.Utils.TempResults</class>)<br/>
/// 		pJobInfo([jobID], "term") = [term ID] (not for initial evaluation)</p>
/// <p>See also <method>GetScore</method></p>
Method RankScores(ByRef pJobInfo, Output pRanked, Output pNoScore) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		kill tSorted, pRanked, pNoScore
		set tJobNumber = "", pRanked = 0
		for {
			set tJobNumber = $order(pJobInfo(tJobNumber))
			quit:tJobNumber=""
			
			kill tScores
			merge tScores = pJobInfo(tJobNumber, "scores")
			set tScore = ..GetScore(.tScores, $g(pJobInfo(tJobNumber,"testid")))
			if (tScore="") {
				set pNoScore(tJobNumber) = ""
				continue
			}
			set tSorted(tScore, tJobNumber) = ""
		}
		
		set tScore = ""
		for {
			set tScore = $order(tSorted(tScore))
			quit:tScore=""
			set tJobNumber=""
			for {
				set tJobNumber = $order(tSorted(tScore, tJobNumber))
				quit:tJobNumber=""
				
				set pRanked($i(pRanked)) = $lb(tJobNumber, tScore)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>See also <method>RankScores</method></p>
Method GetScore(ByRef pScores, pTestId As %Integer = "") As %Double [ Internal ]
{
	quit pScores(..ScoreMetric)
}

/// Runs one test for the current state of <property>Builder</property> and returns its test scores.
Method RunTest(Output pTestId As %Integer, Output pScores, Output pTestClassName As %String, pDropTestClass As %Boolean = 1, pTracking As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK, pTestClassName = ""
	try {
		kill pScores
		
		// derive unique class name for test class
		set pTestClassName = "Temp.ClassifierTest.Test"_(+$job), i="", base=pTestClassName
		while $$$defClassDefined(pTestClassName) {
			set pTestClassName = base _"x"_ $i(i)
		}
		
		set tSC = ..Builder.%CreateClassifierClass(pTestClassName, 0, 1)
		quit:$$$ISERR(tSC)
		
		set tSC = ##class(%iKnow.Classification.Utils).%RunModelFromDomain(.pTestId, pTestClassName, ..DomainId, ..MetadataField, ..TestSet,, pTracking)
		quit:$$$ISERR(tSC)
		
		// now get scores
		set tSC = ##class(%DeepSee.PMML.Utils.TempResult).GetAggregatePrecisionMetrics(pTestId, .tMacroP, .tMicroP, .tMacroR, .tMicroR, .tMacroF, .tMicroF)
		quit:$$$ISERR(tSC)
		set pScores("MacroPrecision") = tMacroP, pScores("MicroPrecision") = tMicroP
		set pScores("MacroRecall") = tMacroR, pScores("MicroRecall") = tMicroR
		set pScores("MacroFmeasure") = tMacroF, pScores("MicroFmeasure") = tMicroF
		
		if $d(..CategoryWeights)>1 {
			set tSC = ..Builder.%GetCategoryInfo(.tCategories)
			quit:$$$ISERR(tSC)
			set (tTotalWeight, tTotalPrecision, tTotalRecall, tTotalFmeasure) = 0
			for i = 1:1:tCategories {
				set tCategory = $li(tCategories, 1)
				set tWeight = $g(..CategoryWeights(tCategory), 1)
				set tTotalWeight = tTotalWeight + tWeight
				set tSC = ##class(%DeepSee.PMML.Utils.TempResult).GetCategoryPrecisionMetrics(pTestId, tCategory, .tPrecision, .tRecall, .tFmeasure)
				set tTotalPrecision = tTotalPrecision + tPrecision
				set tTotalRecall = tTotalRecall + tRecall
				set tTotalFmeasure = tTotalFmeasure + tFmeasure
			}
			set:'tTotalWeight tTotalWeight = 1 // avoid zero divide
			set pScores("WeightedPrecision") = tTotalPrecision / tTotalWeight
			set pScores("WeightedRecall") = tTotalRecall / tTotalWeight
			set pScores("WeightedFmeasure") = tTotalFmeasure / tTotalWeight
		} else {
			set pScores("WeightedPrecision") = tMacroP
			set pScores("WeightedRecall") = tMacroR
			set pScores("WeightedFmeasure") = tMacroF
		}
			
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if (pTestClassName'="") && pDropTestClass {
	    set tSC2 = $$Delete^%apiOBJ(pTestClassName,"-d")
	    set:$$$ISOK(tSC) tSC = tSC2
	}
	quit tSC
}

/// Tests the effect of adding/removing a single term and stores the test results in a temporary global.
ClassMethod TestTermAsync(pTaskID As %Integer, pJobNumber As %Integer, pDebug As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set:pDebug'="" @pDebug@($i(@pDebug)) = $lb($job, "TestTermAsync("_pJobNumber_")"), tStartTime=$zh
		
		merge tTaskInfo = ^IRIS.Temp.IK.Optimizer(pTaskID, pJobNumber)
		if (tTaskInfo("operation")="add") {
			merge tTermInfo = ^IRIS.Temp.IK.Optimizer(pTaskID, "terms", tTaskInfo("term"))
		} else {
			merge tTermInfo = tTaskInfo("term")
		}
		
		#dim tBuilder As %iKnow.Classification.Builder
		set tBuilderClass = ^IRIS.Temp.IK.Optimizer(pTaskID, "classname")
		set tSC = ##class(%iKnow.Classification.Builder).%LoadFromDefinition(tBuilderClass, .tBuilder)
		quit:$$$ISERR(tSC)
		
		set tDomainId = ^IRIS.Temp.IK.Optimizer(pTaskID, "domainid")
		set tFilter = $g(^IRIS.Temp.IK.Optimizer(pTaskID, "testset"))
		$$$IKQFILTEROBJECTX(tDomainId,tFilter,tSC)
		
		set tOptimizer = ..%New(pTaskID, 0)
		set tOptimizer.Builder = tBuilder
		set tOptimizer.Verbose = 0
		set tOptimizer.DomainId = tDomainId
		set tOptimizer.TestSet = tFilter
		set tOptimizer.MetadataField = $g(^IRIS.Temp.IK.Optimizer(pTaskID, "metadatafield"))
		
		if (tTaskInfo("operation")="add") {
			set tSC = tBuilder.%AddTerm(tTermInfo, $g(tTermInfo("type")),, $g(tTermInfo("negation")))
		} else {
			set tSC = tBuilder.%RemoveTerm(tTermInfo, $g(tTermInfo("type")), $g(tTermInfo("negation")))
		}
		quit:$$$ISERR(tSC)
		
		set tSC = tOptimizer.RunTest(.tTestId, .tScores, .tTestClassName, 0, 0)
		quit:$$$ISERR(tSC)
		
		merge ^IRIS.Temp.IK.Optimizer(pTaskID, pJobNumber, "scores") = tScores
		set ^IRIS.Temp.IK.Optimizer(pTaskID, pJobNumber, "testid") = tTestId
		set ^IRIS.Temp.IK.Optimizer(pTaskID, pJobNumber, "classname") = tTestClassName
		
		set:pDebug'="" @pDebug@($i(@pDebug)) = $lb($job, "TestTermAsync("_pJobNumber_")", $zh-tStartTime)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.IK.Optimizer(pTaskID, pJobNumber, "status") = tSC
	quit tSC
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	quit ..Cleanup()
}

/// This method clears the temporary artifacts the optimizer has created while optimizing,
/// such as the <property>CurrentClassifier</property> class and <property>CurrentTestId</property>
/// test results.
Method Cleanup() As %Status
{
	set tSC = $$$OK
	try {
		kill:..IsMaster ^IRIS.Temp.IK.Optimizer(+..TaskId)
		
		if (..CurrentClassifier'="") && $$$defClassDefined(..CurrentClassifier) {
			set tSC = $$Delete^%apiOBJ(..CurrentClassifier, "-d")
			quit:$$$ISERR(tSC)
		}
		set i%CurrentClassifier=""
		
		set:..CurrentTestId tSC = ##class(%DeepSee.PMML.Utils).%DropResults(..CurrentTestId)
		quit:$$$ISERR(tSC)
		set i%CurrentTestId = ""
		
		set i%CurrentScore = ""
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Saves the <property>CurrentClassifier</property> class to the desired <var>pClassName</var>, 
/// so it will not be removed after this Optimizer instance is dropped. If <property>CurrentClassifier</property>
/// is not set or if the class no longer exists for other reasons, the current builder object will
/// create a classifier class based on its current state.
Method SaveClassifier(pClassName As %String, pOverwrite As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..CurrentClassifier'="") && $$$defClassDefined(..CurrentClassifier) {
			
			set tSC = ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(..CurrentClassifier,.tDefinition)
			quit:$$$ISERR(tSC)
			set tSC = tDefinition.%SaveToClass(pClassName, pOverwrite, ..Verbose)
			quit:$$$ISERR(tSC)
			
		} elseif $isobject(..Builder) {
			
			set tSC = ..Builder.%CreateClassifierClass(pClassName, ..Verbose, 1, pOverwrite)
			quit:$$$ISERR(tSC)
			
		} else {
			set tSC = $$$ERROR($$$GeneralError, "No current classifier or builder object")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method Log(pMessage As %String, pNewLines = 1) [ Private ]
{
	set tVerbose = i%Verbose
	if $isvalidnum(tVerbose) {
		quit:'tVerbose
		for i = 1:1:pNewLines { write ! }
		write pMessage
	} else { // ..Verbose points to a global
		if 'pNewLines {
			set @tVerbose@(+$g(@tVerbose)) = $g(@tVerbose@(+$g(@tVerbose)))_pMessage
		} else {
			for i = 2:1:pNewLines { set @tVerbose@($i(@tVerbose)) = "" }
			set @tVerbose@($i(@tVerbose)) = pMessage
		}
	}
}

}
