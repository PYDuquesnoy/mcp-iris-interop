/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This Builder Method implementation generates category term weights as a vector per category that
/// exists in the same vector space as the document term vector. The similarity between the
/// document vector and each of the category vectors can then be calculated using euclidean distance
/// or cosine similarity (angle). Alternatively, these weights can be used for a linear regression
/// formula, calculating a score rather than a similarity/distance.</p>
/// <p>A combination of global term weights (across the corpus), local term weights (within each
/// category) and normalization (per category) is used to calculate these category vectors.</p>
Class %iKnow.Classification.Methods.VectorSpace Extends Base [ Abstract, Deprecated, System = 4 ]
{

Property CustomTermWeights [ MultiDimensional ];

/// The per-category term weight factor
Property CategoryLocalTermWeights As %String(VALUELIST = ",binary,linear,logarithmic") [ InitialExpression = "linear" ];

/// The metric to use for calculating the local term weights
Property CategoryLocalTermMetric As %String(VALUELIST = ",frequency,spread") [ InitialExpression = "spread" ];

/// The corpus-wide relevancy factor to take into account when calculating term weights
Property CategoryGlobalTermWeights As %String(VALUELIST = ",none,IDF") [ InitialExpression = "IDF" ];

/// Whether and how to normalize the category vectors
Property CategoryNormalization As %String(VALUELIST = ",none,cosine") [ InitialExpression = "none" ];

/// Sets a custom weight factor for the term at <var>pIndex</var> in <var>pCategory</var>.
Method %SetCustomWeight(pIndex As %Integer, pCategory As %String, pCustomWeight As %Double) As %Status
{
	set ..CustomTermWeights(pIndex, pCategory) = pCustomWeight
	quit $$$OK
}

Method %SetCustomWeights(pIndex As %Integer, ByRef pCustomWeights) As %Status
{
	merge ..CustomTermWeights(pIndex) = pCustomWeights
	quit $$$OK
}

/// Callback invoked whenever an entire term at an index has been removed
Method %OnRemoveTerm(pIndex As %Integer) As %Status
{
	set tSC = $$$OK
	try {
		kill ..CustomTermWeights(pIndex)
		
		// shift any weights at indices > pIndex
		set tIndex = pIndex
		for {
			set tIndex = $order(..CustomTermWeights(tIndex))
			quit:tIndex=""
			
			merge ..CustomTermWeights(tIndex-1) = ..CustomTermWeights(tIndex)
			kill ..CustomTermWeights(tIndex)
		}
		
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
		
		if (pIncludeBuilderParams) {
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "CategoryLocalTermWeights", tParam.value = ..CategoryLocalTermWeights
			do pClassifier.BuilderParameters.Insert(tParam)
			
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "CategoryLocalTermMetric", tParam.value = ..CategoryLocalTermMetric
			do pClassifier.BuilderParameters.Insert(tParam)
			
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "CategoryGlobalTermWeights", tParam.value = ..CategoryGlobalTermWeights
			do pClassifier.BuilderParameters.Insert(tParam)
			
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "CategoryNormalization", tParam.value = ..CategoryNormalization
			do pClassifier.BuilderParameters.Insert(tParam)
			
			if $d(..CustomTermWeights) {
				set tSC = ..Builder.%GetCategoryInfo(.tCats)
				quit:$$$ISERR(tSC)
				for i = 1:1:tCats { set tCatIndex($li(tCats(i),1)) = i }
				set tCustomWeights = "", tIndex=""
				for {
					set tIndex = $order(..CustomTermWeights(tIndex))
					quit:tIndex=""
					
					set tTermWeights = ""
					
					set tCat = ""
					for {
						set tCat = $order(..CustomTermWeights(tIndex, tCat), 1, tWeight)
						quit:tCat=""
						
						set tTermWeights = tTermWeights _ $s(tTermWeights="":"",1:",") _ tCatIndex(tCat)_":"_tWeight
					}
					
					set tCustomWeights = tCustomWeights _ $s(tCustomWeights="":"",1:";") _ tIndex_":["_tTermWeights_"]"
				}
				
				set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
				set tParam.name = "CustomTermWeights", tParam.value = tCustomWeights
				do pClassifier.BuilderParameters.Insert(tParam)
			}
		}
		
		// now build category term weight matrix, based on the Category* weight parameters
		set tWeightMatrix = ##class(%DeepSee.PMML.Definition.Util.Matrix).%New()
		set tTotalRecordCount = ..Builder.%GetRecordCount(.tSC)
		quit:$$$ISERR(tSC)
		if (tTotalRecordCount <= 0) {
			set tSC = $$$ERROR($$$GeneralError, "Unable to build a model: training set is empty")
			quit
		}		
		
		// fetch categories
		set tSC = ..Builder.%GetCategoryInfo(.tCategories)
		quit:$$$ISERR(tSC)
		if (tCategories <= 0) {
			set tSC = $$$ERROR($$$GeneralError, "Unable to build a model: no categories defined")
			quit
		}

		
		// first build global weights
		set tSC = ..Builder.%GetTermInfo(.tTermInfo, ..CategoryLocalTermMetric)
		quit:$$$ISERR(tSC)
		
		set tTermCount = ..Builder.Terms.Count()
		if (tTermCount <= 0) {
			//set tSC = $$$ERROR($$$GeneralError, "Unable to build a model: no terms defined")
			quit
		}
		
		for i = 1:1:tTermCount {
			
			if (..CategoryGlobalTermWeights = "none") {
				set tGlobalWeights(i) = 1
			} else {
				set tSpread = $g(tTermInfo(i, "spread"))
				if (..CategoryGlobalTermWeights = "IDF") {
					set tGlobalWeights(i) = $zlog((tTotalRecordCount - tSpread + 0.5) / (tSpread + 0.5))
					
				} else {
					set tSC = $$$ERROR($$$GeneralError, "unknown global term weight metric: '"_..CategoryGlobalTermWeights_"'")
					quit
				}
			}
		}
		quit:$$$ISERR(tSC)
		
		// then per-category weights
		for i = 1:1:tCategories {
			set tCatName = $li(tCategories(i),1)
			
			// build local weights and normalization
			kill tLocalWeights
			set tNorm = $case(..CategoryNormalization, "none":1, "cosine":0)
			for j = 1:1:tTermCount {
				continue:'$d(tTermInfo(j))
				
				set tFrequency = $g(tTermInfo(j, ..CategoryLocalTermMetric, i))
				set tLocalWeights(j) = $case(..CategoryLocalTermWeights, "linear":tFrequency, "binary":''tFrequency, "logarithmic":$zlog(1+tFrequency))
				
				if (..CategoryNormalization = "cosine") {
					set tNorm = tNorm + (tLocalWeights(j)**2)
				}
			}
			
			if (..CategoryNormalization = "cosine") {
				set tNorm = $s('tNorm:0, 1:1 / $zsqr(tNorm))
			}
			
			set tWeights = ""
			for j = 1:1:tTermCount {
				set tWeight = ($g(tGlobalWeights(j)) * $g(tLocalWeights(j)) * tNorm)
				
				// treat ..CustomWeights
				set:$d(..CustomTermWeights(j, tCatName), tCustomWeight) tWeight = tCustomWeight
				
				set tWeights = tWeights _ " " _ tWeight
			}
			
			set tWeightArray = ##class(%DeepSee.PMML.Definition.Util.Array).%New()
			set tWeightArray.Values = $e(tWeights,2,*)
			do tWeightMatrix.Arrays.InsertAt(tWeightArray,i)
		}
		
		set pClassifier.ClassificationMethod.CategoryTermWeights = tWeightMatrix
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %LoadFromModel(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:pDefinition.BuilderParameters.Count() {
			set tParam = pDefinition.BuilderParameters.GetAt(i)
			
			if (tParam.name="CategoryGlobalTermWeights") {
				set ..CategoryGlobalTermWeights = tParam.value
			} elseif (tParam.name="CategoryLocalTermMetric") {
				set ..CategoryLocalTermMetric = tParam.value
			} elseif (tParam.name="CategoryLocalTermWeights") {
				set ..CategoryLocalTermWeights = tParam.value
			} elseif (tParam.name="CategoryNormalization") {
				set ..CategoryNormalization = tParam.value
			} elseif (tParam.name="CustomTermWeights") {
				
				for j = 1:1:pDefinition.Categories.Count() {
					set tCats(j) = pDefinition.Categories.GetAt(j).name
				}
				set tTermCount = $length(tParam.value,";")
				for j = 1:1:tTermCount {
					set tTermWeights = $piece(tParam.value,";",j)
					set tTermIndex = $piece(tTermWeights,":[",1)
					set tTermWeights = $e($piece(tTermWeights,":[",2),1,*)
					set tWeightCount = $length(tTermWeights,",")
					for k = 1:1:tWeightCount {
						set tWeight = $piece(tTermWeights,",",k)
						set ..CustomTermWeights(tTermIndex, tCats($piece(tWeight,":",1))) = +$piece(tWeight,":",2)
					}
				}
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %LoadMethodBuilderProperties(pMethodBuilder As Base) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		quit:'pMethodBuilder.%IsA("%iKnow.Classification.Methods.VectorSpace")
		
		set ..CategoryGlobalTermWeights = pMethodBuilder.CategoryGlobalTermWeights
		set ..CategoryLocalTermMetric = pMethodBuilder.CategoryLocalTermMetric
		set ..CategoryLocalTermWeights = pMethodBuilder.CategoryLocalTermWeights
		set ..CategoryNormalization = pMethodBuilder.CategoryNormalization
		
		kill ..CustomTermWeights
		merge ..CustomTermWeights = pMethodBuilder.CustomTermWeights
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
