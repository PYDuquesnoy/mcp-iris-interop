/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Methods.rules Extends Base [ Deprecated, System = 4 ]
{

Property ClassificationRules As %iKnow.Classification.Definition.ClassificationRules;

Method %OnNew(pBuilder As %iKnow.Classification.Builder) As %Status
{
	set tSC = ##super(pBuilder)
	set ..ClassificationRules = ##class(%iKnow.Classification.Definition.ClassificationRules).%New()
	quit tSC
}

Method %LoadFromModel(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status
{
	set tSC = $$$OK
	try {
		
		set ..ClassificationRules = pDefinition.ClassificationMethod.ClassificationRules
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %BuildClassificationMethod(ByRef pClassifier As %iKnow.Classification.Definition.Classifier, pVerbose As %Boolean = 1, pIncludeBuilderParams As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##super(.pClassifier, pVerbose, pIncludeBuilderParams)
		quit:$$$ISERR(tSC)
		
		set pClassifier.ClassificationMethod.ClassificationRules = ..Builder.ClassificationRules
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Generate a default rule set.
/// Note: this will be a simple, first set of draft rules, not an optimized set!
Method %GenerateRules() As %Status
{
	set tSC = $$$OK
	try {
		
		set tSC = ..Builder.%GetCategoryInfo(.tCats)
		quit:$$$ISERR(tSC)
		set tSC = ..Builder.%GetTermInfo(.tTerms,"frequency,spread")
		quit:$$$ISERR(tSC)
		
		// simplistic and tedious approach: for each term, look if there is a category in which it has
		// a higher or lower average frequency than all other categories. OR those conditions together
		// per category.
		for i = 1:1:tCats {
			set tOR(i) = ##class(%iKnow.Classification.Definition.PredicateOR).%New()
			set tTrivial($li(tCats(i),2)) = i
		}
		
		set i = ""
		for {
			set i = $order(tTerms(i))
			quit:i=""
			continue:'$g(tTerms(i,"spread"))
			
			kill tProbabilities
			
			for j = 1:1:tCats { 
				set tProb = $g(tTerms(i,"spread",j))/$g(tTerms(i,"spread"))
				set x = $i(tProbabilities(tProb)), tProbabilities(tProb, j) = ""
			}
			
			// check for unique minimum
			set tMinimum = $order(tProbabilities(""),1,tMinCount)
			if (tMinCount=1) {
				set tNext = $order(tProbabilities(tMinimum))
				if ((tNext-tMinimum)>0.2) {
					set tPredicate = ##class(%iKnow.Classification.Definition.Predicate).%New()
					set tPredicate.term = i, tPredicate.operator = "equal", tPredicate.value = 0
					do tOR($order(tProbabilities(tMinimum,""))).predicates.Insert(tPredicate)
				}
			}
			
			// check for unique maximum
			set tMaximum = $order(tProbabilities(""),-1,tMaxCount)
			if (tMaxCount=1) {
				set tNext = $order(tProbabilities(tMaximum),-1)
				if ((tMaximum-tNext)>0.2) || 'tNext {
					set tPredicate = ##class(%iKnow.Classification.Definition.Predicate).%New()
					set tPredicate.term = i, tPredicate.operator = "greaterOrEqual", tPredicate.value = 1
					do tOR($order(tProbabilities(tMaximum,""))).predicates.Insert(tPredicate)
				}
			}
			
		}
		
		for i = 1:1:tCats {
			continue:'tOR(i).predicates.Count()
			set tRule = ##class(%iKnow.Classification.Definition.Rule).%New()
			set tRule.Predicate = tOR(i)
			set tRule.category = $lg(tCats(i),1)
			do ..ClassificationRules.Rules.Insert(tRule)
		}
		
		// add fallback rule
		set tMaxRecordCount = $order(tTrivial(""),-1,tTrivialCat)
		set tRule = ##class(%iKnow.Classification.Definition.Rule).%New()
		set tRule.score = 0.1
		set tRule.category = $lg(tCats(tTrivialCat),1)
		do ..ClassificationRules.Rules.Insert(tRule)
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Callback invoked whenever an entire term at an index has been removed
Method %OnRemoveTerm(pIndex As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:..ClassificationRules.Rules.Count() {
			set tRule = ..ClassificationRules.Rules.GetAt(i)
			set tSC = ..UpdateTermReferences(tRule.Predicate, pIndex, tRule, -1)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method UpdateTermReferences(pPredicate As %iKnow.Classification.Definition.PredicateBase, pIndex As %Integer, pParent, pParentPosition As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tType = $piece($classname(pPredicate),".",*)
		if (tType="Predicate") {
			
			if (pPredicate.term=pIndex) {
				// remove term from parent
				if (pParentPosition < 0) { // this is the root predicate!
					set pParent.Predicate = ""
				/*} elseif (pParentPosition = 0) { // PredicateNOT
					set pParent.predicate = "" */
				} else {
					do pParent.predicates.RemoveAt(pParentPosition)
				}
			} elseif (pPredicate.term>pIndex) {
				set pPredicate.term = pPredicate.term-1
			}
			
		} elseif (tType="PredicateOR") || (tType="PredicateAND") {
			
			for i = 1:1:pPredicate.predicates.Count() {
				set tSC = ..UpdateTermReferences(pPredicate.predicates.GetAt(i), pIndex, pPredicate, i)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
			
		} elseif (tType="PredicateNOT") {
			
			set tSC = ..UpdateTermReferences(pPredicate.predicate, pIndex, pParent, pParentPosition)
			quit:$$$ISERR(tSC)
			
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Unknown predicate type '"_pPredicate_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
