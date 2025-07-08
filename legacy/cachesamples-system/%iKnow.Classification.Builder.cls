/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This is the framework class for building Text Categorization models, generating valid
/// <class>%iKnow.Classification.Classifier</class> subclasses.<br/>Here's an example
/// using the <class>%iKnow.Classification.IKnowBuilder</class>:</p>
/// <example>
/// // first initialize training and test sets 
/// set tDomainId = $system.iKnow.GetDomainId("Standalone Aviation demo") 
/// set tTrainingSet = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(tDomainId, "Year", "<", 2007) 
/// set tTestSet = ##class(%iKnow.Filters.GroupFilter).%New(tDomainId, "AND", 1) // NOT filter
/// do tTestSet.AddSubFilter(tTrainingSet) 
/// 
/// // Initialize Builder instance with domain name and test set
/// set tBuilder = ##class(%iKnow.Classification.IKnowBuilder).%New("Standalone Aviation demo", tTrainingSet)
/// 
/// // Configure it to use a Naive Bayes classifier
/// 	set tBuilder.ClassificationMethod = "naiveBayes" 
/// 
/// // Load category info from metadata field "AircraftCategory"
/// write tBuilder.%LoadMetadataCategories("AircraftCategory") 
///    
/// // manually add a few terms
/// write tBuilder.%AddEntity("ultralight vehicle")
/// set tData(1) = "helicopter", tData(2) = "helicopters"
/// write tBuilder.%AddEntity(.tData)
/// write tBuilder.%AddEntity("balloon",, "partialCount")
/// write tBuilder.%AddCooccurrence($lb("landed", "helicopter pad")) 
/// 
/// // or add them in bulk by letting the Builder instance decide
/// write tBuilder.%PopulateTerms(50) 
/// 
/// // after populating the term dictionary, let the Builder generate a classifier class
/// write tBuilder.%CreateClassifierClass("User.MyClassifier") 
/// </example>
Class %iKnow.Classification.Builder Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// The minimum number of records in the training set that should contain a term before it
/// can get selected by <method>%PopulateTerms</method>. (Can be bypassed for specific terms
/// by adding them through <method>%AddTerm</method>)
Property MinimumSpread As %Integer [ InitialExpression = 3 ];

/// The minimum fraction of records in the training set that should contain a term before it
/// can get selected by <method>%PopulateTerms</method>, EXCEPT if it occurs in more than 50%
/// of the records in at least one category. (Can be bypassed for specific terms by adding them
/// through <method>%AddTerm</method>)
Property MinimumSpreadPercent As %Double [ InitialExpression = 0.05 ];

/// Optional description for the Classifier
Property Description As %String;

/// Local Term Weights for the document vector to register in the ClassificationMethod element.
/// This might be overruled for some classification methods (ie Naive Bayes, which always uses "binary")
Property DocumentVectorLocalWeights As %String(VALUELIST = ",binary,linear,logarithmic") [ InitialExpression = "linear" ];

/// Document vector normalization method to register in the Classification element
/// This might be overruled for some classification methods (ie Naive Bayes, which always uses "none")
Property DocumentVectorNormalization As %String(VALUELIST = ",none,cosine") [ InitialExpression = "none" ];

Property Terms As list Of %iKnow.Classification.Definition.Term [ Internal ];

/// Categories.GetAt(i) = $lb("name", "spec", "description", "recordCount")
Property Categories As list Of %List [ Internal ];

/// The metric used for selecting terms for this classifier.
/// This is for information purposes only.
Property TermSelectionMetric As %String [ Internal ];

/// The general method used for classification:
/// <ul>
/// <li>"naiveBayes" uses a probability-based approach based on the Naive Bayes theorem,</li>
/// <li>"rules" runs through a set of straightforward decision rules based on boolean expressions, each
/// contributing to a single category's score if they fire. The category with the highest score wins.</li>
/// <li>"euclideanDistance" treats the per-category term weights as a vector in the same vector
/// space as the document term vector and calculates the euclidean distance between these vectors
/// and the query vector.</li>
/// <li>"cosineSimilarity" also treats the per-category term weights as a vector in the same vector
/// space as the document term vector and looks at the (cosine of) the angle between these vectors.</li>
/// <li>"linearRegression" considers the per-category term weights to be coefficients in a linear
/// regression formula for calculating a category score, with the highest value winning</li>
/// <li>"pmml" delegates the mathematical work to a predictive model defined in PMML. See also
/// <class>%iKnow.Classification.Methods.pmml</class></li>
/// </ul>
Property ClassificationMethod As %String(VALUELIST = ",naiveBayes,linearRegression,euclideanDistance,cosineSimilarity,pmml,rules") [ InitialExpression = "naiveBayes" ];

/// Used by some models to refine the terms selected and/or how their default score is calculated
Property EntityRole As %Integer [ InitialExpression = {$$$ENTTYPECONCEPT}, Internal ];

/// Adds an optional category named <var>pName</var> for the classifier being built by this class. 
/// The meaning of <var>pSpec</var> depends on the actual builder implementation, but should
/// allow the builder implementation to identify the records in the training set belonging to
/// this category.
Method %AddCategory(pName As %String, pSpec As %String, pRecordCount As %Integer = "", pDescription As %String = "") As %Status [ Final ]
{
	if ($zstrip(pName,"*C")'=pName) { quit $$$ERROR($$$GeneralError, "Illegal category name: '"_pName_"'") }
	if $isobject(pSpec) && $$IsDerivedFrom^%occLibrary(pSpec.%ClassName(1),"%iKnow.Filters.Filter") {
		set pSpec = pSpec.ToString()
	}
	quit ..Categories.Insert($lb(pName, pSpec, pDescription, pRecordCount))
}

/// Returns all categories added so far:
/// 		pCategories(n) = $lb([name], [record count])
Method %GetCategoryInfo(Output pCategories) As %Status [ Abstract ]
{
	kill pCategories
	quit $$$OK
}

Method %GetCategoryPosition(pName As %String) As %Integer [ Internal ]
{
	set tIndex = 0
	for i = 1:1:..Categories.Count() {
		if ($li(..Categories.GetAt(i),1)=pName) {
			set tIndex = i
			quit
		}
	}
	quit tIndex
}

/// Returns all terms added so far:
/// 		pTerms(n) = $lb([string value], [type], [negation policy], [count policy])
Method %GetTerms(Output pTerms) As %Status
{
	kill pTerms
	set pTerms=0
	#dim tTerm As %iKnow.Classification.Definition.Term
	for i = 1:1:..Terms.Count() {
		set tTerm = ..Terms.GetAt(i)
		set pTerms($i(pTerms)) = $lb(tTerm.GetValue(), tTerm.type, tTerm.negation, tTerm.count)
	}
	quit $$$OK
}

/// <p><b>Deprecated: use <method>%AddEntity</method>, <method>%AddCRC</method> or
/// <method>%AddCooccurrence</method> instead</b></p>
/// <p>Adds a term whose presence or frequency is to be considered for categorizing by the
/// classifier being built by this class.</p>
Method %AddTerm(pValue As %String, pType As %String = "entity", ByRef pCustomWeights, pNegation As %String = "undefined") As %Status [ Deprecated, Final, Internal ]
{
	if (pType="entity") || (pType="") {
		set tSC = ..%AddEntity(pValue, pNegation,, .tIndex)
	} elseif (pType="crc") {
		set tSC = ..%AddCRC($p(pValue,":",1), $p(pValue,":",2), $p(pValue,":",3), pNegation,, .tIndex)
	} elseif (pType="cooccurrence") {
		set tSC = ..%AddCooccurrence($lfs(pValue,":"), pNegation,, .tIndex)
	} else {
		set tSC = $$$ERROR($$$GeneralError, "Unknown type: '"_pType_"'")
	}
	quit:$$$ISERR(tSC) tSC
	if $d(pCustomWeights)>1 {
		if (..MethodBuilder.%IsA("%iKnow.Classification.Methods.VectorSpace")) {
			quit ..MethodBuilder.%SetCustomWeights(tIndex, .pCustomWeights)
		} else {
			quit $$$ERROR($$$GeneralError, "Custom weights are not supported for classification method '"_..ClassificationMethod_"'")
		}
	}
	quit tSC
}

/// <p>Adds one or more entities as a single term to the Text Categorization model's term dictionary.
/// The term is to be counted only if it appears in the negation context defined by <var>pNegation</var>.
/// If <var>pCount</var> = "exactCount", only exact occurrences of this entity will be counted to
/// calculate its base score to be fed into the categorization algorithm. If it is set to "partialCount",
/// both exact and partial matches will be considered and if set to "partialScore", the score of all
/// exact and partial matches will be summed as this term's base score.</p>
/// <p>Multiple entities can be supplied either as a one-dimensional array or as a %List</p>.
Method %AddEntity(ByRef pValue As %String, pNegation As %String = "undefined", pCount As %String = "exactCount", Output pIndex As %Integer) As %Status [ Final ]
{
		
	set tSC = $$$OK
	try {
		set:pNegation="" pNegation="undefined"
		set:pCount="" pCount="exactCount"
		
		set tTerm = ##class(%iKnow.Classification.Definition.TermEntity).%New()
		set tTerm.negation = pNegation
		set tTerm.count = pCount
		
		if $d(pValue)>1 {
			set i = ""
			for {
				set i = $order(pValue(i), 1, tValue)
				quit:i=""
				do tTerm.Entries.Insert(tValue)
			}
		} elseif $lv(pValue) {
			set ptr = 0
			while $listnext(pValue, ptr, tValue) {
				do tTerm.Entries.Insert(tValue)
			}
		} else {
			do tTerm.Entries.Insert(pValue)
		}
		
		set pIndex = ..%GetTermPosition(tTerm)
		quit:pIndex
		
		do ..Terms.Insert(tTerm)
		set pIndex = ..Terms.Count()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Adds one or more CRCs as a single term to the Text Categorization model's term dictionary.
/// The term is to be counted only if it appears in the negation context defined by <var>pNegation</var>.
/// If <var>pCount</var> = "exactCount", only exact occurrences of this CRC will be counted to
/// calculate its base score to be fed into the categorization algorithm. If it is set to "partialCount",
/// both exact and partial matches will be considered and if set to "partialScore", the score of all
/// exact and partial matches will be summed as this term's base score.</p>
/// <p>Multiple CRC can be supplied either as a one-dimensional array of 3-element-%Lists</p>.
Method %AddCRC(ByRef pCRC As %List, pNegation As %String = "undefined", pCount As %String = "exactCount", Output pIndex As %Integer) As %Status [ Final ]
{
		
	set tSC = $$$OK
	try {
		set:pNegation="" pNegation="undefined"
		set:pCount="" pCount="exactCount"
		
		set tTerm = ##class(%iKnow.Classification.Definition.TermCRC).%New()
		set tTerm.negation = pNegation
		set tTerm.count = pCount
		
		if $d(pCRC)>1 {
			set i = ""
			for {
				set i = $order(pCRC(i), 1, tValue)
				quit:i=""
				set tEntry = ##class(%iKnow.Classification.Definition.TermCRCEntry).%New()
				set tEntry.Master = $lg(tValue,1)
				set tEntry.Relation = $lg(tValue,2)
				set tEntry.Slave = $lg(tValue,3)
				do tTerm.Entries.Insert(tEntry)
			}
		} elseif $lv(pCRC) {
			set tEntry = ##class(%iKnow.Classification.Definition.TermCRCEntry).%New()
			set tEntry.Master = $lg(pCRC,1)
			set tEntry.Relation = $lg(pCRC,2)
			set tEntry.Slave = $lg(pCRC,3)
			do tTerm.Entries.Insert(tEntry)
		} elseif $l(pCRC,":")=3 {
			set tEntry = ##class(%iKnow.Classification.Definition.TermCRCEntry).%New()
			set tEntry.Master = $piece(pCRC,":",1)
			set tEntry.Relation = $piece(pCRC,":",2)
			set tEntry.Slave = $piece(pCRC,":",3)
			do tTerm.Entries.Insert(tEntry)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "CRC value should be supplied as a $listbuild or array")
			quit
		}
		
		set pIndex = ..%GetTermPosition(tTerm)
		quit:pIndex
		
		do ..Terms.Insert(tTerm)
		set pIndex = ..Terms.Count()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Adds one or more Cooccurrences as a single term to the Text Categorization model's term dictionary.
/// The term is to be counted only if it appears in the negation context defined by <var>pNegation</var>.
/// If <var>pCount</var> = "exactCount", only exact occurrences of this cooccurrence's entities will be counted to
/// calculate its base score to be fed into the categorization algorithm. If it is set to "partialCount",
/// both exact and partial matches will be considered and if set to "partialScore", the score of all
/// exact and partial matches will be summed as this term's base score.</p>
/// <p>A single cooccurrence can be supplied as a one-dimensional array of strings or a %List.
/// Multiple cooccurrences can be supplied either as a one-dimensional array of %Lists or as a
/// two-dimensional array of strings</p>.
Method %AddCooccurrence(ByRef pValue As %List, pNegation As %String = "undefined", pCount As %String = "exactCount", Output pIndex As %Integer) As %Status [ Final ]
{
		
	set tSC = $$$OK
	try {
		set:pNegation="" pNegation="undefined"
		set:pCount="" pCount="exactCount"
		
		set tTerm = ##class(%iKnow.Classification.Definition.TermCooccurrence).%New()
		set tTerm.negation = pNegation
		set tTerm.count = pCount
		
		if $d(pValue)>1 {
			set tTwoLevel = ($d(pValue($order(pValue(""),1,tFirstEntry)))>1)
			if (tTwoLevel) {
				set i = ""
				for {
					set i = $order(pValue(i), 1, tValue)
					quit:i=""
					set tEntry = ##class(%iKnow.Classification.Definition.TermCoocEntry).%New()
					set j = ""
					for {
						set j = $order(pValue(i,j),1,tValue2)
						quit:j=""
						do tEntry.Entities.Insert(tValue2)
					}
					do tTerm.Entries.Insert(tEntry)
				}
			} elseif $lv(tFirstEntry) {
				set i = ""
				for {
					set i = $order(pValue(i), 1, tValue)
					quit:i=""
					set tEntry = ##class(%iKnow.Classification.Definition.TermCoocEntry).%New()
					set j = 0
					while $listnext(tValue,j,tValue2) {
						do tEntry.Entities.Insert(tValue2)
					}
					do tTerm.Entries.Insert(tEntry)
				}
			} else {
				set tEntry = ##class(%iKnow.Classification.Definition.TermCoocEntry).%New()
				set i = ""
				for {
					set i = $order(pValue(i),1,tValue)
					quit:i=""
					do tEntry.Entities.Insert(tValue)
				}
				do tTerm.Entries.Insert(tEntry)
			}
		} elseif $lv(pValue) {
			set tEntry = ##class(%iKnow.Classification.Definition.TermCoocEntry).%New()
			set ptr = 0
			while $listnext(pValue, ptr, tValue) {
				do tEntry.Entities.Insert(tValue)
			}
			do tTerm.Entries.Insert(tEntry)
		} elseif $f(pValue,":") {
			set tEntry = ##class(%iKnow.Classification.Definition.TermCoocEntry).%New()
			set l = $l(pValue,":")
			for i = 1:1:l {
				do tEntry.Entities.Insert($piece(pValue,":",i))
			}
			do tTerm.Entries.Insert(tEntry)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Cooccurrence value should be supplied as a $listbuild or array")
			quit
		}
		
		set pIndex = ..%GetTermPosition(tTerm)
		quit:pIndex
		
		do ..Terms.Insert(tTerm)
		set pIndex = ..Terms.Count()
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Directly add a term object at the last index. (no existence checking!)
Method %AddTermInternal(pTerm As %iKnow.Classification.Definition.Term, Output pIndex As %Integer) As %Status [ Internal ]
{
	do ..Terms.Insert(pTerm)
	set pIndex = ..Terms.Count()
	quit $$$OK
}

Method %GetTermPosition(pTerm As %iKnow.Classification.Definition.Term) As %Integer [ Internal ]
{
	set tIndex = 0
	for i = 1:1:..Terms.Count() {
		if pTerm.%Equals(..Terms.GetAt(i)) {
			set tIndex = i
			quit
		}
	}
	quit tIndex
}

/// Removes the term at index <var>pIndex</var>. If the term at this position is a composite one,
/// all its entries are dropped along.
Method %RemoveTermAtIndex(pIndex As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		do ..Terms.RemoveAt(pIndex)
		
		set tSC = ..MethodBuilder.%OnRemoveTerm(pIndex)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Removes a specific entry <var>pValue</var> from the term at index <var>pIndex</var>.
Method %RemoveTermEntryAtIndex(pValue As %String, pIndex As %Integer, Output pRemovedTerm As %Boolean) As %Status
{
	set tSC = $$$OK, pRemovedTerm = 0
	try {
		set tTerm = ..Terms.GetAt(pIndex)
		quit:tTerm=""
		quit:'tTerm.ContainsEntry(pValue)
		
		set tSC = tTerm.RemoveEntry(pValue, .tEmpty)
		quit:$$$ISERR(tSC)
		
		quit:'tEmpty
		set tSC = ..%RemoveTermAtIndex(pIndex)
		quit:$$$ISERR(tSC)
		set pRemovedTerm = 1
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Removes <var>pValue</value> from the first term that contains it meeting the <var>pType</var>
/// <var>pNegation</var> and <var>pCount</var> criteria. If this is the last entry for that term,
/// remove the whole term.
Method %RemoveTerm(pValue As %String, pType As %String = "entity", pNegation As %String = "undefined", pCount As %String = "exactCount") As %Status
{
	set tSC = $$$OK
	try {
		set:pType="" pType = "entity"
		set:pNegation="" pNegation = "undefined"
		set:pCount="" pCount="exactCount"
		
		set tRemoveTerm = 0
		for i = 1:1:..Terms.Count() {
			set tTerm = ..Terms.GetAt(i)
			continue:pType'=tTerm.type
			continue:pNegation'=tTerm.negation
			continue:pCount'=tTerm.count
			
			continue:'tTerm.ContainsEntry(pValue)
			
			set tEntryCount = tTerm.EntryCount()
			
			if (tEntryCount>1) {
				set tSC = tTerm.RemoveEntry(pValue)
			} else {
				set tSC = ..%RemoveTermAtIndex(i)
			}
			quit
		}
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Adds <var>pCount</var> terms of type <var>pType</var> to this classifier's set of terms, 
/// selecting those terms that have a high relevance for the categorization task based on metric
/// <var>pMetric</var> and/or the specifics of this builder implementation.</p>
/// <p>If <var>pPerCategory</var> is 1, (<var>pCount</var> \ [number of categories]) terms are
/// selected using the specified metric as calculated within each category. This often gives
/// better results, but might not be supported for every metric or builder.</p>
/// <p>Builder implementations should ensure these terms meet the conditions set forward by 
/// <property>MinimumSpread</property> and <property>MinimumSpreadPercent</property>.
/// <property>MinimumSpreadPercent</property> can be ignored if <var>pPerCategory</var> = 1</p>
/// <p>This method implements a populate method for <var>pMetric</var> = "NaiveBayes", selecting terms
/// based on their highest average per-category probability. In this case, the value of
/// <var>pPerCategory</var> is ignored (automatically treated as 1). Implementations for other
/// metrics can be provided by subclasses.</p>
Method %PopulateTerms(pCount As %Integer = 100, pType As %String = "entity", pMetric As %String = "NaiveBayes", pPerCategory As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		if (pMetric'="NaiveBayes") || ((pType'="entity") && (pType'="crc")) {
			set tSC = $$$ERROR($$$NotImplemented)
			quit
		}
		
		// in this scenario, find the entities with the highest value for $zabs(0.5-prob), 
		// totaled over all categories
		set ..Builder.TermSelectionMetric = "Aggregated Naive Bayes probability"
		
		
		// first build all filter objects
		set tTotalRecordCount = ..Builder.%GetRecordCount(.tSC)
		quit:$$$ISERR(tSC)
		
		set tSC = ..Builder.%GetCategoryInfo(.tCatInfo)
		quit:$$$ISERR(tSC)
		
		set tSC = ..Builder.%GetCandidateTerms(pType)
		quit:$$$ISERR(tSC)
		
		
		kill ^||%IK.Sorted
		$$$IKSORTBEGIN(^||%IK.Sorted)
		set i = ""
		for {
			set i = $order(^||%IK.TermCandidates(i), 1, tTermInfo)
			quit:i=""
			
			set tTotalSpread = $li(tTermInfo,2), tScore = 0
			for j = 1:1:tCatInfo {
				set tCatSpread = $g(^||%IK.TermCandidates(i,j))
				set tInCatRC = $li(tCatInfo(j),2), tNotInCatRC = tTotalRecordCount-tInCatRC
				set tEntProb = (tCatSpread/tInCatRC) / ((tCatSpread/tInCatRC) + ((tTotalSpread-tCatSpread)/tNotInCatRC))
				set tScore = tScore + $zabs(0.5-tEntProb)
			}
			set ^||%IK.Sorted(-tScore, i) = $li(tTermInfo,1)
		}
		set x = $sortend(^||%IK.Sorted)
		
		
		set tCount = 0, tScore = ""
		for {
			set tScore = $order(^||%IK.Sorted(tScore))
			quit:tScore=""
			
			set tTermId = ""
			for {
				set tTermId = $order(^||%IK.Sorted(tScore, tTermId), 1, tTermValue)
				quit:tTermId=""
				quit:$i(tCount)>pCount
				
				if (pType="entity") {
					set tSC = ..Builder.%AddEntity(tTermValue)
				} elseif (pType="crc") {
					set tSC = ..Builder.%AddCRC($lfs(tTermValue, $c(0)))
				}
				quit:$$$ISERR(tSC)
			}
			quit:tCount>pCount
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	kill ^||%IK.Sorted, ^||%IK.TermCandidates
	
	quit tSC
}

/// Resets the term and category lists for this classifier
Method %Reset() As %Status [ Final ]
{
	do ..Terms.Clear()
	do ..Categories.Clear()
	set ..TermSelectionMetric = "", ..Terms=0
	quit ..%OnReset()
}

Method %OnReset() As %Status [ Private ]
{
	quit $$$OK
}

/// <p>Generates a <class>%iKnow.Classification.Definition.Classifier</class> XML tree based on the current
/// set of categories and terms, with the appropriate weights and parameters calculated by the builder 
/// implementation (see <method>%OnGenerateClassifier</method>).</p>
/// <p>Use <var>pIncludeBuilderInfo</var> to include specifications of how this classifier was built
/// so it can be "reloaded" from the classifier XML to retrain the model.</p>
Method %GenerateClassifier(Output pDefinition As %iKnow.Classification.Definition.Classifier, pIncludeBuilderInfo As %Boolean = 0, pVerbose As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		write:pVerbose !,"Generating classifier definition..."
		
		set pDefinition = ##class(%iKnow.Classification.Definition.Classifier).%New()
		set:pIncludeBuilderInfo pDefinition.builderClass = $classname()
		set pDefinition.description = ..Description
		
		for i = 1:1:..Categories.Count() {
			set tCatData = ..Categories.GetAt(i)
			
			set tCat = ##class(%iKnow.Classification.Definition.Category).%New()
			set tCat.name = $li(tCatData,1)
			set:pIncludeBuilderInfo tCat.spec = $li(tCatData,2)
			set tCat.description = $lg(tCatData, 3)
			set tCat.recordCount = $lg(tCatData, 4)
			do pDefinition.Categories.InsertAt(tCat,i)
		}
		
		set pDefinition.TermDictionary = ##class(%iKnow.Classification.Definition.TermDictionary).%New()
		set pDefinition.TermDictionary.termSelectionMethod = ..TermSelectionMetric
		for j = 1:1:..Terms.Count() {
			do pDefinition.TermDictionary.Terms.InsertAt(..Terms.GetAt(j),j)
		}
		
		set tSC = ..%OnGenerateClassifier(.pDefinition, pVerbose, pIncludeBuilderInfo)
		quit:$$$ISERR(tSC)
		
		write:pVerbose !,"Generating classifier implementation..."
		set tSC = ..MethodBuilder.%BuildClassificationMethod(.pDefinition, pVerbose, pIncludeBuilderInfo)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Appends the ClassificationMethod element for this type of classifier.
Method %OnGenerateClassifier(ByRef pDefinition As %iKnow.Classification.Definition.Classifier, pVerbose As %Boolean = 1, pIncludeBuilderInfo As %Boolean = 0) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		/* build category term weight matrix, based on ..CustomTermWeights, as if ..UseCustomWeights = "replace"
		set tWeightMatrix = ##class(%DeepSee.PMML.Definition.Util.Matrix).%New()
		set pDefinition.ClassificationMethod.CategoryTermWeights = tWeightMatrix
		
		set tCategoryCount = ..Categories.Count()
		for i = 1:1:tCategoryCount {
			set tWeights(i) = "", tCatNames(i) = ..Categories.GetAt(i).name
		}
		
		for i = 1:1:..Terms.Count() {
			for j = 1:1:tCategoryCount {
				set tWeights(j) = tWeights(j) _ " " _ $g(..CustomTermWeights(i, tCatNames(j)))
			}
		}
		
		for i = 1:1:tCategoryCount {
			set tArray = ##class(%DeepSee.PMML.Definition.Util.Array).%New()
			set tArray.Values = $e(tWeights(i),2,*)
			do tWeightMatrix.Arrays.InsertAt(tArray, i)
		}
		*/
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Generates a classifier definition and saves it to a <class>%iKnow.Classification.Classifier</class>
/// subclass named <var>pClassName</var>. This will overwrite any existing class with that name if <var>pOverwrite</var> is 1.
/// See also <method>%GenerateClassifier</method>.</p>
Method %CreateClassifierClass(pClassName As %String, pVerbose As %Boolean = 1, pIncludeBuilderInfo As %Boolean = 1, pOverwrite As %Boolean = 0, pCompile As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
	    set tSC = ..%GenerateClassifier(.tClassifier, pIncludeBuilderInfo, pVerbose)
	    quit:$$$ISERR(tSC)
	    
	    write:pVerbose !,$s(pCompile:"Compiling", 1:"Saving")_" classifier class..."
	    set tSC = tClassifier.%SaveToClass(pClassName, pOverwrite, 0, pCompile)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		write:pVerbose !,"Error occurred during classifier generation:",!,$system.Status.GetErrorText(tSC),!
	} else {
		write:pVerbose !,"Finished generating classifier class",!
	}
	quit tSC
}

/// Loads the categories and terms from an existing Classifier class <var>pClassName</var>.<br/>
/// Note: this does not load any (custom) weight information from the definition.
ClassMethod %LoadFromDefinition(pClassName As %String, Output pBuilder As %iKnow.Classification.Builder, pValidateFirst As %Boolean = 1) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		#dim tDefinition As %iKnow.Classification.Definition.Classifier
		set tSC = ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(pClassName, .tDefinition, pValidateFirst)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%LoadFromModel(tDefinition, .pBuilder)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %LoadFromModel(pDefinition As %iKnow.Classification.Definition.Classifier, Output pBuilder As %iKnow.Classification.Builder) As %Status [ Final, Internal ]
{
	set tSC = $$$OK
	try {
		if (pDefinition.builderClass="") {
			set tSC = $$$ERROR($$$GeneralError, "Classifier definition does not contain builder info")
			quit
		}
		
		set pBuilder = $classmethod(pDefinition.builderClass, "%New")
		set pBuilder.TermSelectionMetric = pDefinition.TermDictionary.termSelectionMethod
		
		// load parameters first
		for i = 1:1:pDefinition.BuilderParameters.Count() {
			set tParam = pDefinition.BuilderParameters.GetAt(i)
			
			// if this is a property of this very (sub)class, set it. If not, it will be picked up
			// by the Method builder class' %LoadFromModel()
			if ##class(%Dictionary.CompiledProperty).%ExistsId(pDefinition.builderClass_"||"_tParam.name) {
				set $property(pBuilder, tParam.name) = tParam.value
			}
		}
		
		// categories
		for i = 1:1:pDefinition.Categories.Count() {
			#dim tCat As %iKnow.Classification.Definition.Category = pDefinition.Categories.GetAt(i)
			set tSC = pBuilder.%AddCategory(tCat.name, tCat.spec, tCat.recordCount, tCat.description)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// terms
		set pBuilder.Terms = pDefinition.TermDictionary.Terms
		
		// flat properties
		set pBuilder.Description = pDefinition.description
		set pBuilder.DocumentVectorLocalWeights = pDefinition.ClassificationMethod.localTermWeights
		set pBuilder.DocumentVectorNormalization = pDefinition.ClassificationMethod.normalization
		
		// classification method
		set pBuilder.ClassificationMethod = pDefinition.ClassificationMethod.method
		set tSC = pBuilder.MethodBuilder.%LoadFromModel(pDefinition)
		quit:$$$ISERR(tSC)
		
		// callback for subclasses
		set tSC = pBuilder.%OnLoadFromDefinition(pDefinition)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnLoadFromDefinition(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status [ Internal ]
{
	quit $$$OK
}

/// Exports the data in the training set to a new table <var>pClassName</var>, with columns
/// containing the weighted score for each term.
Method %ExportDataTable(pClassName As %String, pOverwrite As %Boolean = 1, pVerbose As %Boolean = 1, pTracking As %Boolean = 0) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		
		write:pVerbose !,"Creating export data table..."
		if '$zname(pClassName,4) {
			set tSC = $$$ERROR($$$ClassNameInvalid, pClassName)
			quit
		} elseif $$$defClassDefined(pClassName) {
			if (pOverwrite) {
				set tSC = $$Delete^%apiOBJ(pClassName,"c-de")
				quit:$$$ISERR(tSC)
			} else {
				set tSC = $$$ERROR($$$ClassAlreadyExist, pClassName)
				quit
			}
		}
		
		set tClass = ##class(%Dictionary.ClassDefinition).%New()
		set tClass.Name = pClassName
		set tClass.Super = "%Persistent"
		
		set tProp = ##class(%Dictionary.PropertyDefinition).%New()
		set tProp.Name = "ID"
		set tProp.Type = "%String"
		do tClass.Properties.Insert(tProp)
		
		set tProp = ##class(%Dictionary.PropertyDefinition).%New()
		set tProp.Name = "Category"
		set tProp.Type = "%String"
		do tProp.Parameters.SetAt(200,"MAXLEN")
		do tClass.Properties.Insert(tProp)
		
		set tIndex = ##class(%Dictionary.IndexDefinition).%New()
		set tIndex.Name = "CategoryIdx"
		set tIndex.Properties = "Category"
		do tClass.Indices.Insert(tIndex)
		
		for i = 1:1:..Terms.Count() {
			set tProp = ##class(%Dictionary.PropertyDefinition).%New()
			set tProp.Name = ..GetColumnName(i)
			set tProp.Type = "%Double"
			set tProp.InitialExpression = 0
			set tProp.Description = "Term "_i_": " _ ..Terms.GetAt(i).GetDisplayName(2)
			do tClass.Properties.Insert(tProp)
		}
		
		set tSC = ..%OnCreateExportTable(tClass, pVerbose)
		quit:$$$ISERR(tSC)
		
		set tSC = tClass.%Save()
		quit:$$$ISERR(tSC)
		set tSC = $system.OBJ.Compile(pClassName, "c-d")
		quit:$$$ISERR(tSC)
		
		// ensure it's empty (if not deleted with -e flag)
		set tSC = $classmethod(pClassName,"%KillExtent")
		quit:$$$ISERR(tSC)
		
		write:pVerbose !,"Exporting data to table..."
		set tSC = ..%OnExportTable(pClassName, pVerbose, pTracking)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetColumnName(pTermId As %Integer) As %String [ Internal ]
{
	quit "T"_$translate($justify(pTermId,3)," ",0)
}

/// Callback invoked by <method>%ExportDataTable</method> when creating the export table definition.
Method %OnCreateExportTable(pClassDef As %Dictionary.ClassDefinition, pVerbose As %Boolean) As %Status [ Private ]
{
	quit $$$OK
}

/// Callback invoked by <method>%ExportDataTable</method> to load the data into export table <class>pClassName</class>.
Method %OnExportTable(pClassName As %String, pVerbose As %Boolean, pTracking As %Boolean) As %Status [ Abstract, Private ]
{
}

/// <p>Adds all terms selected by <var>pSQL</var> as <var>pType</var>, taking the string value from the
/// column named "term" with negation context <var>pNegationContext</var> and count policy <var>pCount</var>.
/// If there are columns named "type", "negation" or "count" selected by the query, any values in these
/// columns will be used instead of the defaults supplied through the respective parameters.</p>
/// <p>When adding CRC or Cooccurrence terms, use colons to separate the composing entities.</p>
Method %AddTermsFromSQL(pSQL As %String, pType As %String = "entity", pNegationContext As %String = "undefined", pCount As %String = "exactCount") As %Status
{
	set tSC = $$$OK
	try {
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(pSQL)
		quit:$$$ISERR(tSC)
		
		if (tStatement.%Metadata.statementType'=1) {
			set tSC = $$$ERROR($$$GeneralError, "Only SELECT statements allowed here")
			quit
		}
		
		#dim tResult As %SQL.StatementResult = tStatement.%Execute()
		set tTermCol = $s($d(tResult.%GetMetadata().columnIndex("TERM"),tTermColInfo):$lg(tTermColInfo,1), 1:1)
		set tTypeCol = $s($d(tResult.%GetMetadata().columnIndex("TYPE"),tTypeColInfo):$lg(tTypeColInfo,1), 1:0)
		set tNegationCol = $s($d(tResult.%GetMetadata().columnIndex("NEGATION"),tNegationColInfo):$lg(tNegationColInfo,1), 1:0)
		set tMatchCol = $s($d(tResult.%GetMetadata().columnIndex("MATCH"),tMatchColInfo):$lg(tMatchColInfo,1), 1:0)
		
		while tResult.%Next() {
			set tTerm = tResult.%GetData(tTermCol)
			set tType = $$$LOWER($s(tTypeCol:tResult.%GetData(tTypeCol), 1:pType))
			set tNegation = $s(tNegationCol:tResult.%GetData(tNegationCol), 1:pNegationContext)
			set tCount = $s(tMatchCol:tResult.%GetData(tMatchCol), 1:pCount)
			
			if (tType="entity") {
				set tSC = ..%AddEntity(tTerm, tNegation, tCount)
			} elseif (tType="crc") {
				set tSC = ..%AddCRC(tTerm, tNegation, tCount)
			} elseif (tType="cooccurrence") {
				set tSC = ..%AddCooccurrence(tTerm, tNegation, tCount)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetRecordCount(Output pSC As %Status) As %Integer [ Abstract ]
{
	quit ""
}

/// Returns an array for the current builder terms:
/// 		pTermInfo(i, "spread") = [spread in training set]
/// 		pTermInfo(i, "spread", j) = [spread in training set for category j]
/// 		pTermInfo(i, "frequency", j) = [freq in training set for category j]
Method %GetTermInfo(Output pTermInfo, pIncludeCategoryDetails As %String = "") As %Status [ Internal ]
{
	quit $$$ERROR($$$NotImplemented)
}

/// This object will deliver the actual implementation of the classification method
/// and is instantiated automatically through settting <property>ClassificationMethod</property>.
Property MethodBuilder As %iKnow.Classification.Methods.Base [ Internal, ReadOnly ];

Method ClassificationMethodSet(pMethod As %String) As %Status [ Internal, ServerOnly = 1 ]
{
	quit:(i%ClassificationMethod=pMethod)&&$isobject(i%MethodBuilder) $$$OK
	set i%ClassificationMethod = pMethod
	set tOldMethodBuilder = i%MethodBuilder
	set i%MethodBuilder = $classmethod("%iKnow.Classification.Methods."_..ClassificationMethod, "%New", $this)
	quit:'$isobject(..MethodBuilder) $g(%objlasterror)
	if ($isobject(tOldMethodBuilder)) {
		quit i%MethodBuilder.%LoadMethodBuilderProperties(tOldMethodBuilder)
	} else {
		quit $$$OK
	}
}

/// Dispatch unknown property setters to <property>MethodBuilder</property>
Method %DispatchSetProperty(Property As %String, Val) [ ServerOnly = 1 ]
{
	set $property(..MethodBuilder, Property) = Val
}

/// Dispatch unknown property getters to <property>MethodBuilder</property>
Method %DispatchGetProperty(Property As %String) [ ServerOnly = 1 ]
{
	quit $property(..MethodBuilder, Property)
}

/// Dispatch unknown method calls to <property>MethodBuilder</property>
Method %DispatchMethod(Method As %String, Args...) [ ServerOnly = 1 ]
{
	quit $method(..MethodBuilder, Method, Args...)
}

/// INTERNAL - DO NOT INVOKE
/// Used by MethodBuilder.%PopulateTerms() to provide:
/// 	^||%IK.TermCandidates(id) = $lb(value, spread)
/// 	^||%IK.TermCandidates(id, j) = [spread in category j]
Method %GetCandidateTerms(pType As %String = "entity") As %Status [ Internal ]
{
	quit $$$ERROR($$$NotImplemented)
}

/// <p>Utility method to batch-test the classifier against a test set <var>pTestSet</var>.
/// Per-record results are returned through <var>pResult</var>:<br/>
/// 			pResult(n) = $lb([record ID], [actual category], [predicted category])</p>
/// <p><var>pAccuracy</var> will contain the raw accuracy (# of records predicted correctly) of 
/// the current model. Use <class>%iKnow.Classificaton.Utils</class> for more advanced model testing.</p>
/// <p>If the current model's category options were added through <method>%AddCategory</method> without 
/// an appropriate category specification, use <var>pCategorySpec</var> to refer to the actual category
/// values to test against.</p>
Method %TestClassifier(pTestSet As %RawString, Output pResult, Output pAccuracy As %Double, pCategorySpec As %String = "", pVerbose As %Boolean = 0) As %Status [ Abstract ]
{
}

}
