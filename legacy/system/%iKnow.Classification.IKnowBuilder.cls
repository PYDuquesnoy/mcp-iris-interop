/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Parent class for any iKnow-based <class>%iKnow.Classification.Builder</class> implementations,
/// providing common infrastructure abstracting a few iKnow API calls. 
/// IKnowBuilder implementations assume category specs are <class>%iKnow.Filters.Filter</class>
/// instances in their string representation.
Class %iKnow.Classification.IKnowBuilder Extends Builder [ Deprecated, System = 4 ]
{

/// The iKnow domain this categorization model is built from
Property DomainId As %Integer;

/// The sample set of the domain to be used for training this model
Property TrainingSet As %iKnow.Filters.Filter;

Property TestSet As %iKnow.Filters.Filter;

/// If set, this metadata field contains the actual category value for each source
Property MetadataField As %String;

Method %OnNew(pDomainName As %String = "", pTrainingSet As %iKnow.Filters.Filter = "", pMethod As %String = "naiveBayes") As %Status [ Internal, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$IKCHECKPRIVREADX(tSC)
	
		if (pDomainName'="") {
			set tDomainId = $system.iKnow.GetDomainId(pDomainName)
			if 'tDomainId {
				set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)
				quit
			}
			
			$$$IKQFILTEROBJECTX(tDomainId,pTrainingSet,tSC)
			
			set ..DomainId = tDomainId
			set ..TrainingSet = pTrainingSet
		}
		
		set ..ClassificationMethod = pMethod
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>Creates (appends) categories for each of the available values of a given metadata field
/// <var>pFieldName</var> in the full domain (thus ignoring <property>TrainingSet</property>).</p>
/// <p>Note: as category names are case sensitive, it is highly recommended to use a case-sensitive
/// metadata field.</p>
Method %LoadMetadataCategories(pFieldName As %String) As %Status
{
	set tSC = $$$OK
	try {
		set ..MetadataField = pFieldName
		set ..Description = "The categories for this classifier are based on the different values for the metadata property '"_pFieldName_"'"
		
		set tMetadataAPI = $$$IKMETADATAAPI(..DomainId)
		set tSC = $classmethod(tMetadataAPI, "GetUniqueValues", .tFieldValues, ..DomainId, pFieldName, 0, 0)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tFieldValues(i), 1, tData)
			quit:i=""
			set tFieldValue = $li(tData,1)
			set tFilter = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(..DomainId, pFieldName, "=", tFieldValue)
			set tSC = ..%AddCategory(tFieldValue, tFilter.ToString(), $li(tData,2))
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Builds an array of <class>%iKnow.Filters.Filter</class> objects for the categories registered
/// in this Builder instance.
Method %GetCategoryFilters(Output pFilters, pIntersectWithFilter As %iKnow.Filters.Filter = "", pCheckIfEmpty As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pFilters
		set tDomainId = ..DomainId
		$$$IKQFILTEROBJECTX(tDomainId,pIntersectWithFilter,tSC)
		set tTotalSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomainId, pIntersectWithFilter)
		
		set pFilters = ..Categories.Count()
		for i = 1:1:pFilters {
			
			set tCatFilter = $lg(..Categories.GetAt(i),2)
			$$$IKQFILTEROBJECTX(tDomainId,tCatFilter,tSC)
			
			if $isobject(pIntersectWithFilter) {
				set tFilter = ##class(%iKnow.Filters.GroupFilter).%New(tDomainId, $$$GROUPFILTERAND)
				do tFilter.AddSubFilter(tCatFilter)
				do tFilter.AddSubFilter(pIntersectWithFilter)
			} else {
				set tFilter = tCatFilter
			}
			
			if (pCheckIfEmpty) {
				set tFilteredSourceCount = tFilter.FilteredSourceCount
				set tNotFilteredSourceCount = tTotalSourceCount - tFilteredSourceCount
				if 'tNotFilteredSourceCount {
					set tSC = $$$ERROR($$$GeneralError, "Category "_i_" covers the whole dataset!")
					quit
				} elseif 'tFilteredSourceCount {
					set tSC = $$$ERROR($$$GeneralError, "Category "_i_" has no data!")
					quit
				}
			}
			
			set pFilters(i) = tFilter
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnReset() As %Status [ Private ]
{
	set (..TrainingSet, ..DomainId, ..MetadataField) = ""
	quit $$$OK
}

/// <p>Utility method to batch-test the classifier against a test set <var>pTestSet</var>, which can
/// be supplied as an <class>%iKnow.Filters.Filter</class> object or its serialized form.
/// Per-record results are returned through <var>pResult</var>:<br/>
/// 			pResult(n) = $lb([record ID], [actual category], [predicted category])</p>
/// <p><var>pAccuracy</var> will contain the raw accuracy (# of records predicted correctly) of 
/// the current model. Use <class>%iKnow.Classificaton.Utils</class> for more advanced model testing.</p>
/// <p>If the current model's category options were added through <method>%AddCategory</method> without
/// providing an appropriate category filter specification, rather
/// than through a call to <class>%LoadMetadataCategories</class> (which sets
/// <property>MetadataField</property>), supply a metadata field through <var>pCategorySpec</var>
/// where the actual category values to test against can be found.</p>
Method %TestClassifier(pTestSet As %RawString = "", Output pResult, Output pAccuracy As %Double, pCategorySpec As %String = "", pVerbose As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(pResult,"")
	set tSC = $$$OK, pAccuracy=""
	try {
		set tTempClassName = "Test.ClassifierTest"_$job_"x", tDeDup=0
		while $$$defClassDefined(tTempClassName_tDeDup) {
			set tDeDup = tDeDup+1
		}
		set tTempClassName = tTempClassName_tDeDup
		
		set tSC = ..%CreateClassifierClass(tTempClassName, pVerbose)
		quit:$$$ISERR(tSC)
		
		set tDomainId = $s($isobject(pTestSet):pTestSet.DomainId, 1:..DomainId)
		set tDomainName = ##class(%iKnow.Domain).%OpenId(tDomainId).Name
		set tMetadataFieldId = $s(pCategorySpec="":0, 1:##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomainId, pCategorySpec, .tSC))
		quit:$$$ISERR(tSC)
		
		#dim tClassifier As %iKnow.Classification.Classifier
		write:pVerbose !,"Setting up Classifier object..."
		set tClassifier = $classmethod(tTempClassName, "%New", "iKnow", tDomainName)
		
		// ensure pTestSet is a valid filter object
		$$$IKQFILTEROBJECTX(tDomainId,pTestSet,tSC)
		set:(pTestSet="") pTestSet = ..TestSet
		set:(pTestSet="") pTestSet = ##class(%iKnow.Filters.BitmapFilter).%New(tDomainId, "^IRIS.IK.SrcExistsBit("_tDomainId_")")
		set tTotalSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomainId, pTestSet)
		
		set tSC = ..%GetCategoryFilters(.tCatFiltersById, pTestSet, 0)
		quit:$$$ISERR(tSC)
		for i = 1:1:tCatFiltersById {
			set tCatName = $li(..Categories.GetAt(i),1)
			set tCatFilters(tCatName) = tCatFiltersById(i)
		}
		
		// now loop through all sources
		write:pVerbose !,"Testing all sources ("_tTotalSourceCount_") ..."
		set tTotalCount = 0, tRightCount = 0
		set tOffset = ""
		for {
			set tOffset = pTestSet.GetNextSourceFilterOffset(tOffset, .tBits)
			quit:tOffset=""
			
			set tPos = 0
			for {
				set tPos = $bitfind(tBits, 1, tPos+1)
				quit:'tPos
				
				$$$IKGETIDOFFPOS(tSrcId,tOffset,tPos)
				
				set tTotalCount = tTotalCount + 1
				
				if (tMetadataFieldId) {
					set tActualCats = $lb(##class(%iKnow.Queries.MetadataAPI).GetValueById(tDomainId, tMetadataFieldId, tSrcId))
				} else {
					set tActualCats = "", tCat = ""
					for {
						set tCat = $order(tCatFilters(tCat), 1, tFilter)
						quit:tCat=""
						set:tFilter.IsFiltered(tSrcId) tActualCats = tActualCats _ $lb(tCat)
					}
				}
				
				set tSC = tClassifier.%Categorize(.tCategories, tSrcId)
				quit:$$$ISERR(tSC)
				
				set tPredictedCat = $lg($g(tCategories(1)),1)
				
				// getting one right is considered enough
				set tIsRight = ($lf(tActualCats,tPredictedCat)>0)
				set:tIsRight tRightCount = tRightCount + 1
				
				$$$IKQADDRESULT(pResult,tTotalCount,$lb(tSrcId,$lts(tActualCats),tPredictedCat))
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		set pAccuracy = (tRightCount / tTotalCount)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// get rid of temp class
	if $$$defClassDefined(tTempClassName) {
		write:pVerbose !,"Dropping temporary classifier class..."
		set tSC2 = $$Delete^%apiOBJ(tTempClassName,"-d")
	}
		
	quit tSC
}

/// <p>This %PopulateTerms implementation accepts "BM25" and "TFIDF" as acceptable values for
/// <var>pMetric</var>.
/// See also the class reference for this method in <class>%iKnow.Classification.Builder</class>.</p>
Method %PopulateTerms(pCount As %Integer = 100, pType As %String = "entity", pMetric As %String = "BM25", pPerCategory As %Boolean = 0) As %Status
{
	set tSC = $$$OK
	try {
		// delegate to superclass if metric is not known
		if ((pMetric'="BM25") && (pMetric'="TFIDF")) || (pType'="entity") {
			set tSC = ##super(pCount, pType, pMetric, pPerCategory)
			quit
		}
		
		set tDomainId = ..DomainId
		set tTrainingFilter = ..TrainingSet
		$$$IKQFILTEROBJECTX(tDomainId,tTrainingFilter,tSC)
		if (tTrainingFilter.FilteredSourceCount <= 0) {
			set tSC = $$$ERROR($$$GeneralError, "Unable to populate terms: training set is empty")
			quit
		}
			
		do ..%GetCategoryFilters(.tFilters, tTrainingFilter)
		if ($g(tFilters) <= 0) {
			set tSC = $$$ERROR($$$GeneralError, "Unable to populate terms: no categories defined")
			quit
		}
		
		if (pPerCategory) {
			set tCountPerCategory = (pCount \ ..Categories.Count())
			
			// go through filters by increasing record count to ensure smaller ones get enough attention
			for i = 1:1:tFilters {
				set tRecordCounts(tFilters(i).FilteredSourceCount, i) = tFilters(i)
			}
			kill tFilters
			set cnt = ""
			for {
				set cnt = $order(tRecordCounts(cnt))
				quit:cnt=""
				set i = ""
				for {
					set i = $order(tRecordCounts(cnt, i), 1, tFilter)
					quit:i=""
					set tFilters($i(tFilters)) = tFilter
				}
			}
			
			kill tTermsAdded
			for i = 1:1:tFilters {
				if (pMetric="BM25") {
					set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopBM25(.tEntities, tDomainId, 1, pCount, tFilters(i), ..EntityRole)
				} elseif (pMetric="TFIDF") {
					set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopTFIDF(.tEntities, tDomainId, 1, pCount, tFilters(i), ..EntityRole)
				//} elseif (pMetric="dominance") {
				//	set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetProfileByDomain(.tEntities, tDomainId, 1, pCount, $$$SDCONCEPT)
				} else {
					set tSC = $$$ERROR($$$GeneralError, "Unknown metric: '"_pMetric_"'")
				}
				quit:$$$ISERR(tSC)
				
				set j = "", tCount = 0
				for {
					set j = $order(tEntities(j), 1, tEntityInfo)
					quit:j=""
					
					set tEntUniId = $li(tEntityInfo,1)
					set tEntityValue = $li(tEntityInfo,2)
					
					// enforce MinimumSpread
					continue:##class(%iKnow.Queries.EntityAPI).GetSpread(tDomainId, tEntUniId, ..EntityRole, tFilters(i))<..MinimumSpread
					
					// simple check if not added already for another category
					continue:$d(tTermsAdded(tEntityValue))
					set tTermsAdded(tEntityValue) = ""
					
					set tSC = ..%AddEntity(tEntityValue)
					quit:$$$ISERR(tSC)
					
					quit:$i(tCount)>=tCountPerCategory
				}
			}
			quit:$$$ISERR(tSC)
			
		} else {
			if (pMetric="BM25") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopBM25(.tEntities, tDomainId, 1, pCount, tTrainingFilter, ..EntityRole)
			} elseif (pMetric="TFIDF") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopTFIDF(.tEntities, tDomainId, 1, pCount, tTrainingFilter, ..EntityRole)
			//} elseif (pMetric="dominance") {
			//	set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetProfileByDomain(.tEntities, tDomainId, 1, pCount, $$$SDCONCEPT)
			} else {
				set tSC = $$$ERROR($$$GeneralError, "Unknown metric: '"_pMetric_"'")
			}
			quit:$$$ISERR(tSC)
			
			set i = ""
			for {
				set i = $order(tEntities(i), 1, tData)
				quit:i=""
				
				// enforce spread requirements
				set tSpread = ##class(%iKnow.Queries.EntityAPI).GetFrequency(..DomainId, $li(tData,1), ..EntityRole,, tTrainingFilter)
				continue:tSpread<..MinimumSpread
				if (tSpread < (..MinimumSpreadPercent * ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(..DomainId, tTrainingFilter))) {
					set tDontSkip = 0
					for j = 1:1:tFilters {
						set tFilteredSpread = ##class(%iKnow.Queries.EntityAPI).GetFrequency(..DomainId, $li(tData,1), ..EntityRole,, tFilters(j))
						if (tFilteredSpread > (0.5 * tFilters(j).FilteredSourceCount)) {
							set tDontSkip = 1
							quit
						}
					}
					continue:'tDontSkip
				}
				
				//if (pMetric="dominance") {
				//	set tEntityValue = $lg($lg(tData,2))
				//} else {
					set tEntityValue = $lg(tData,2)
				//}
				
				set tSC = ..%AddEntity(tEntityValue)
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
		set ..TermSelectionMetric = pMetric
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns an array for the current builder terms:
/// 			pTermInfo(i, "id", n) = entity ID / crc ID / cooc entity IDs / dictItemId
Method %GetTermIDs(Output pTermInfo, Output pDictId As %Integer, Output pDictMap) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pTermInfo, pDictMap, pAggregates
		set pConsidersNegation = 0
		set tDomainId = ..DomainId
		#dim tTrainingFilter as %iKnow.Filters.Filter = ..TrainingSet
		$$$IKQFILTEROBJECTX(tDomainId,tTrainingFilter,tSC)
		
		kill tDictTerms
		for i = 1:1:..Terms.Count() {
			#dim tTerm As %iKnow.Classification.Definition.Term = ..Terms.GetAt(i)
			if (tTerm.count'="exactCount") {
				set tDictTerms(i) = tTerm
				continue
			}
			
			
			if (tTerm.type="entity") {
				
				// backwards compatibilty:
				if (tTerm.value'="") {
					set tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, tTerm.value)
					continue:'tID
					set pTermInfo(i, "id", $i(pTermInfo(i, "id"))) = tID
				} else {
					for k = 1:1:tTerm.Entries.Count() {
						set tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, tTerm.Entries.GetAt(k))
						continue:'tID
						set pTermInfo(i, "id", $i(pTermInfo(i, "id"))) = tID
					}
				}
				
			} elseif (tTerm.type="crc") {
				
				// backwards compatibility
				if (tTerm.value'="") {
					set tID = ##class(%iKnow.Queries.CrcAPI).GetIdInternal(tDomainId, $p(tTerm.value,":",1), $p(tTerm.value,":",2), $p(tTerm.value,":",3))
					continue:'tID
					set pTermInfo(i, "id", $i(pTermInfo(i, "id"))) = tID
				} else {
					for k = 1:1:tTerm.Entries.Count() {
						set tCRC = tTerm.Entries.GetAt(k)
						set tID = ##class(%iKnow.Queries.CrcAPI).GetIdInternal(tDomainId, tCRC.Master, tCRC.Relation, tCRC.Slave)
						continue:'tID
						set pTermInfo(i, "id", $i(pTermInfo(i, "id"))) = tID
					}
				}
				
			} elseif (tTerm.type="cooccurrence") {
				
				// backwards compatibility
				if (tTerm.value'="") {
					set tIDs = ""
					for l = 1:1:$l(tTerm.value,":") {
						set tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, $p(tTerm.value,":",l))
						if 'tID {
							set tIDs = ""
							quit
						}
						set tIDs = tIDs _ $lb(tID)
					}
					continue:tIDs=""
					set pTermInfo(i, "id", $i(pTermInfo(i, "id"))) = tIDs
				} else {
					for k = 1:1:tTerm.Entries.Count() {
						set tCooc = tTerm.Entries.GetAt(k)
						set tIDs = ""
						for l = 1:1:tCooc.Entities.Count() {
							set tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, tCooc.Entities.GetAt(l))
							if 'tID {
								set tIDs = ""
								quit
							}
							set tIDs = tIDs _ $lb(tID)
						}
						continue:tIDs=""
						set pTermInfo(i, "id", $i(pTermInfo(i, "id"))) = tIDs
					}
				}
			}
		}
		
		// now go through the matching-based terms
		if '$d(tDictTerms) {
			set pDictId = 0
		} else {
			
			// first create a dictionary
			// unless this is a managed domain, create it inside the domain for performance reasons
			set tDictDomainId = $s($$$GETPARAMNODEF(tDomainId,$$$IKPMANAGEDBY)'="":0, 1:tDomainId)
			set tDictName = "@TC@"_$classname()_"@"_$job
			set pDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(tDictDomainId, tDictName)
			set:pDictId>0 tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(tDictDomainId, pDictId)
			quit:$$$ISERR(tSC)
			set tSC = ##class(%iKnow.Classification.Classifier).%GetMatchingProfileId(.tProfileId)
			quit:$$$ISERR(tSC)
			set pDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryInternal(tDictDomainId, tDictName,,, tProfileId, "%iKnow.Classification.IKnowBuilder", .tSC)
			quit:$$$ISERR(tSC)
			set tSC = ##class(%iKnow.Classification.Classifier).%UpdateIKnowDictionary(tDictDomainId, pDictId, .tDictTerms,, .pDictMap)
			quit:$$$ISERR(tSC)
			
			set tDictItemId = ""
			for {
				set tDictItemId = $order(pDictMap(tDictItemId), 1, tTermPos)
				quit:tDictItemId=""
				set pTermInfo(tTermPos, "id", $i(pTermInfo(tTermPos, "id"))) = tDictItemId
			}
			
			set:'tDictDomainId pDictId = -pDictId
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns an array for the current builder terms:
/// 		pTermInfo(i, "spread") = [spread in training set]
/// 		pTermInfo(i, "spread", j) = [spread in training set for category j]
/// 		pTermInfo(i, "frequency", j) = [freq in training set for category j]
Method %GetTermInfo(Output pTermInfo, pIncludeCategoryDetails As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tDomainId = ..DomainId
		#dim tTrainingFilter as %iKnow.Filters.Filter = ..TrainingSet
		$$$IKQFILTEROBJECTX(tDomainId,tTrainingFilter,tSC)
		$$$IKQNULLFILTER(tDomainId,tTrainingFilter)
		
		set tCatSpread = (pIncludeCategoryDetails["spread")
		set tCatFreq = (pIncludeCategoryDetails["frequency")
		if (tCatSpread+tCatFreq) {
			set tSC = ..%GetCategoryFilters(.tCatFilters, tTrainingFilter, 1)
			quit:$$$ISERR(tSC)
		}
		
		set tSC = ..%GetTermIDs(.pTermInfo, .tDictId, .tDictMap)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(pTermInfo(i))
			quit:i=""
			
			#dim tTerm As %iKnow.Classification.Definition.Term = ..Terms.GetAt(i)
			
			continue:(tTerm.count'="exactCount")
			
			if (tTerm.negation'="undefined") {
				set tSC = $$$ERROR($$$NotImplemented)
				quit // TODO!!
			}
					
			set j = ""
			for {
				set j = $order(pTermInfo(i, "id", j), 1, tID)
				quit:j=""
			
				if (tTerm.type="entity") {
			
					set x = $i(pTermInfo(i, "frequency"), ##class(%iKnow.Queries.EntityAPI).GetFrequency(tDomainId, tID,,, tTrainingFilter))
					set x = $i(pTermInfo(i, "spread"), ##class(%iKnow.Queries.EntityAPI).GetSpread(tDomainId, tID,, tTrainingFilter))
					
					if (pIncludeCategoryDetails'="") {
						for k = 1:1:tCatFilters {
							set:tCatFreq x = $i(pTermInfo(i, "frequency", k), ##class(%iKnow.Queries.EntityAPI).GetFrequency(tDomainId, tID,,, tCatFilters(k)))
							set:tCatSpread x = $i(pTermInfo(i, "spread", k), ##class(%iKnow.Queries.EntityAPI).GetSpread(tDomainId, tID,, tCatFilters(k)))
						}
					}
			
				} elseif (tTerm.type="crc") {
					
					set x = $i(pTermInfo(i, "frequency"), ##class(%iKnow.Queries.CrcAPI).GetFrequency(tDomainId, tID,, tTrainingFilter))
					set x = $i(pTermInfo(i, "spread"), ##class(%iKnow.Queries.CrcAPI).GetSpread(tDomainId, tID, tTrainingFilter))
					
					if (pIncludeCategoryDetails'="") {
						for k = 1:1:tCatFilters {
							set:tCatFreq x = $i(pTermInfo(i, "frequency", k), ##class(%iKnow.Queries.CrcAPI).GetFrequency(tDomainId, tID,, tCatFilters(k)))
							set:tCatSpread x = $i(pTermInfo(i, "spread", k), ##class(%iKnow.Queries.CrcAPI).GetSpread(tDomainId, tID, tCatFilters(k)))
						}
					}

				} elseif (tTerm.type="cooccurrence") {
					
					set x = $i(pTermInfo(i, "frequency"), ..GetCoocSpread(tDomainId, tID, tTrainingFilter, "freq"))
					set x = $i(pTermInfo(i, "spread"), ..GetCoocSpread(tDomainId, tID, tTrainingFilter, "spread"))
					
					if (pIncludeCategoryDetails'="") {
						for k = 1:1:tCatFilters {
							set:tCatFreq x = $i(pTermInfo(i, "frequency", k), ..GetCoocSpread(tDomainId, tID, tCatFilters(k), "spread"))
							set:tCatSpread x = $i(pTermInfo(i, "spread", k), ..GetCoocSpread(tDomainId, tID, tCatFilters(k), "spread"))
						}
					}
				}
			}
		} 
		
		// now go through the matching-based terms
		if tDictId {
			// match the dictionary
			set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tDomainId, tTrainingFilter, $lb(tDictId))
			quit:$$$ISERR(tSC)
			
			// now go through all training sources to compile the results
			set tSrcId = ""
			for {
				set tSrcId = tTrainingFilter.GetNextSrcId(tSrcId)
				quit:tSrcId=""
				
				set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchesBySourceId(.tMatches, tDomainId, tSrcId, $lb(tDictId), 0, 0)
				quit:$$$ISERR(tSC)
				
				set i = ""
				for {
					set i = $order(tMatches(i), 1, tMatchData)
					quit:i=""
					
					set tDictItemId = $zabs($li(tMatchData,3))
					set tTermId = tDictMap(tDictItemId)
					set tNegation = ..Terms.GetAt(tTermId).negation
					
					if (tNegation = "undefined") {}
					else {
						set tHasNegations = $lg(tMatchData,15,0)
						if 'tHasNegations {
							// the match does not contain any negations
							continue:(tNegation'="none")
						} elseif (tNegation="implied") {
							// implied covers all sorts of negations, so no need to dig deeper
						} else {
							// now we have to find out the negation type of the matched entities
							set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchElements(.tElements, tDomainId, $li(tMatchData,1))
							quit:$$$ISERR(tSC)
							
							set j = "", tOK = $s(tNegation="no-explicit":1, 1:0)
							for {
								set j = $order(tElements(j), 1, tElementData)
								quit:j=""
								set tPartId = $lg(tElementData,2)
								continue:'tPartId
								
								if (tNegation="explicit") {
									if ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(tDomainId, tPartId, $$$IKATTNEGATION,,, $$$IKATTLVLSENT) {
										set tOK = 1
										quit
									}
								} elseif (tNegation="no-explicit") {
									if ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(tDomainId, tPartId, $$$IKATTNEGATION,,, $$$IKATTLVLSENT) {
										set tOK = 0
										quit
									}
								}
							}
							continue:'tOK
						}
					}
					
					set tFreq = $s(..Terms.GetAt(tTermId).count="partialScore":$lg(tMatchData,8), 1:1)
					set x = $i(pTermInfo(tTermId, "spread"))
					set x = $i(pTermInfo(tTermId, "frequency"), tFreq)
					
					// now add to each category score as well
					if (tCatFreq+tCatSpread) {
						for j = 1:1:tCatFilters {
							continue:'tCatFilters(j).IsFiltered(tSrcId)
							set:tCatSpread x = $i(pTermInfo(tTermId, "spread", j))
							set:tCatFreq x = $i(pTermInfo(tTermId, "frequency", j), tFreq)
						}
					}
				}
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// clean up
	if $g(tDictId) && ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId($s(tDictId>0:tDomainId, 1:0), tDictId) {
		try { do ##class(%iKnow.Matching.DictionaryAPI).DropDictionary($s(tDictId>0:tDomainId, 1:0), tDictId) } catch (ex) {}
	}
	
	quit tSC
}

/// Helper method to retrieve the Cooccurrence spread for a set of sources defined by <var>pTrainingFilter</var>
Method GetCoocSpread(pDomainId As %Integer, pIDs As %List, pTrainingFilter As %iKnow.Filters.Filter = "", pMode As %String(VALUELIST=",spread,freq") = "spread", Output pSC As %Status) As %Integer [ Internal ]
{
	set pSC = $$$OK, tSpread = ""
	try {
		set pSC = ##class(%iKnow.Queries.SourceAPI).GetByEntityIds(.tSources, pDomainId, pIDs, 0, 0, pTrainingFilter, $$$INTERSECT)
		quit:$$$ISERR(pSC)
		
		// now go through each and check if they contain sentences where all pIDs cooccur
		set i = ""
		for {
			set i = $order(tSources(i), 1, tSrcData)
			quit:i=""
			
			set tSrcId = $li(tSrcData,1)
			
			set tCooccurrences = ##class(%iKnow.Queries.SentenceAPI).GetCountByEntityIds(pDomainId, pIDs, $lb(tSrcId), $$$INTERSECT, .pSC)
			quit:$$$ISERR(pSC)
			
			continue:'tCooccurrences
			set x = $i(tSpread, $case(pMode,"freq":tCooccurrences, "spread":1))
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tSpread
}

Method %OnCreateExportTable(pClassDef As %Dictionary.ClassDefinition, pVerbose As %Boolean) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		// update the ID property, turning it into an %Integer 
		for i = 1:1:pClassDef.Properties.Count() {
			set tProp = pClassDef.Properties.GetAt(i)
			continue:tProp.Name'="ID"
			set tProp.Type = "%Integer"
			do tProp.Parameters.SetAt(0, "MINVAL")
			set tProp.Description = "The Source ID of the iKnow source represented by this row"
			quit
		}
		
		// add an index on SourceID
		set tIndex = ##class(%Dictionary.IndexDefinition).%New()
		set tIndex.Name = "PKIdx"
		set tIndex.Properties = "ID"
		set tIndex.Unique = 1
		set tIndex.PrimaryKey = 1
		set tIndex.IdKey = 1
		do pClassDef.Indices.Insert(tIndex)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnExportTable(pClassName As %String, pVerbose As %Boolean, pTracking As %Boolean) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		kill:pTracking ^IRIS.Temp.TC.BgrTask($job, "track")
		
		set tTableName = ##class(%DeepSee.Utils).%GetSQLTableName(pClassName)
		set tDomainId = ..DomainId
		#dim tTrainingFilter as %iKnow.Filters.Filter = ..TrainingSet
		$$$IKQFILTEROBJECTX(tDomainId,tTrainingFilter,tSC)
		
		set ^IRIS.Temp.TC.BgrTask($job, "track", "total") = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(..DomainId, tTrainingFilter)
		
		set tMetaFieldId = ##class(%iKnow.Queries.MetadataAPI).GetFieldId(tDomainId, ..MetadataField)
		if (tMetaFieldId<=0) {
			set tSC = $$$ERROR($$$GeneralError, "Feature only supported for metadata-based categorization")
			quit
		}
		
		// gather IDs and build an inverse map
		set tSC = ..%GetTermIDs(.tTermInfo, .tDictId)
		quit:$$$ISERR(tSC)
		set tTermPos = ""
		for {
			set tTermPos = $order(tTermInfo(tTermPos))
			quit:tTermPos=""
			
			#dim tTerm As %iKnow.Classification.Definition.Term = ..Terms.GetAt(tTermPos)
			
			set i=""
			for {
				set i = $order(tTermInfo(tTermPos, "id", i), 1, tID)
				quit:i=""
				set:tTerm.negation'="undefined" tMap("negation")=1
			
				if (tTerm.count'="exactCount") { // partial matches
				
					set tMap(3, tID) = $lb(tTermPos, tTerm.negation, tTerm.count)
			
				} elseif (tTerm.type="entity") { // entities
				
					set tMap(0, tID) = $lb(tTermPos, tTerm.negation)
				
				} elseif (tTerm.type="crc") { // CRCs
					
					set tMap(1, tID) = $lb(tTermPos, tTerm.negation)
					
				} elseif (tTerm.type="cooccurrence") {
					
					set tCoocId = $i(tCoocId)
					set tMap(2, tCoocId) = $lb(tTermPos, tTerm.negation, tID)
					set ptr = 0
					while $listnext(tID, ptr, tEntUniId) {
						set tMap(-2, tEntUniId, tCoocId) = tTerm.negation
					}
				}
			}
		}
		
		// match dictionary if we need to
		set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSources(tDomainId, tTrainingFilter, $lb(tDictId))
		quit:$$$ISERR(tSC)
		
		set tSC = $classmethod(pClassName, "%SortBegin")
		quit:$$$ISERR(tSC)
		
		$$$IKQNULLFILTER(tDomainId,tTrainingFilter)
		set tSrcId = "", tRow = "", tSrcCount = 0
		for {
			set tSrcId = tTrainingFilter.GetNextSrcId(tSrcId)
			quit:'tSrcId
			
			if (tRow'="") {
				set tSC = tRow.%Save()
				quit:$$$ISERR(tSC)
				set x = $i(tSrcCount)
				
				if pTracking && '(tSrcCount#10) {
					set ^IRIS.Temp.TC.BgrTask($job, "track", "done") = tSrcCount
				}
			}
			
			set tRow = $classmethod(pClassName, "%New")
			set tRow.ID = tSrcId
			set tRow.Category = ##class(%iKnow.Queries.MetadataAPI).GetValueById(tDomainId, tMetaFieldId, tSrcId)
			
			set tSC = ##class(%iKnow.Classification.Classifier).%GetTermFreqsForSourceStatic(tDomainId, tSrcId, .tMap, tDictId, .tSrcFreqs)
			quit:$$$ISERR(tSC)
			
			// now convert tSrcFreqs into row values
			set tTermId = ""
			for {
				set tTermId = $order(tSrcFreqs(tTermId), 1, tFreq)
				quit:tTermId=""
				set $property(tRow, ..GetColumnName(tTermId)) = tFreq
			}
		}
		quit:$$$ISERR(tSC)
		
		if (tRow'="") {
			set tSC = tRow.%Save()
			quit:$$$ISERR(tSC)
			set x = $i(tSrcCount)
		}
		
		set tSC = $classmethod(pClassName, "%SortEnd")
		quit:$$$ISERR(tSC)
		
		set:pTracking ^IRIS.Temp.TC.BgrTask($job, "track", "done") = tSrcCount
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}

	// clean up
	if $g(tDictId)>0 {
		try { do ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(tDomainId, tDictId) }catch (ex) {}
	}
	
	quit tSC
}

Method %OnGenerateClassifier(ByRef pDefinition As %iKnow.Classification.Definition.Classifier, pVerbose As %Boolean = 1, pIncludeBuilderInfo As %Boolean = 0) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		quit:'pIncludeBuilderInfo
		
		set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
		set tParam.name = "DomainId", tParam.value = ..DomainId
		do pDefinition.BuilderParameters.Insert(tParam)
		
		if (..TrainingSet'="") {
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "TrainingSet", tParam.value = $s($isobject(..TrainingSet):..TrainingSet.ToString(), 1:..TrainingSet)
			do pDefinition.BuilderParameters.Insert(tParam)
		}
		
		if (..TestSet'="") {
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "TestSet", tParam.value = $s($isobject(..TestSet):..TestSet.ToString(), 1:..TestSet)
			do pDefinition.BuilderParameters.Insert(tParam)
		}
		
		if (..MetadataField'="") {
			set tParam = ##class(%iKnow.Classification.Definition.BuilderParameter).%New()
			set tParam.name = "MetadataField", tParam.value = ..MetadataField
			do pDefinition.BuilderParameters.Insert(tParam)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method TrainingSetSet(pFilter As %iKnow.Filters.Filter) As %Status [ Internal, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$IKQFILTEROBJECTX(i%DomainId,pFilter,tSC)
		set i%TrainingSet = pFilter
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method TestSetSet(pFilter As %iKnow.Filters.Filter) As %Status [ Internal, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		$$$IKQFILTEROBJECTX(i%DomainId,pFilter,tSC)
		set i%TestSet = pFilter
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns all categories added so far:
/// 		pCategories(n) = $lb([name], [record count])
Method %GetCategoryInfo(Output pCategories) As %Status
{
	kill pCategories
	set pCategories=0
	
	set tSC = ..%GetCategoryFilters(.tFilters, ..TrainingSet)
	quit:$$$ISERR(tSC) tSC
	
	for i = 1:1:tFilters {
		set tCatInfo = ..Categories.GetAt(i)
		set pCategories($i(pCategories)) = $lb($li(tCatInfo,1), tFilters(i).FilteredSourceCount)
	}
	
	quit $$$OK
}

Method %GetRecordCount(Output pSC As %Status) As %Integer
{
	quit ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(..DomainId, ..TrainingSet, .pSC)
}

/// 	^||%IK.TermCandidates(id) = $lb(value, spread)
/// 	^||%IK.TermCandidates(id, j) = [spread in category j]
Method %GetCandidateTerms(pType As %String = "entity") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		if (pType'="entity") && (pType'="crc") {
			set tSC = $$$ERROR($$$GeneralError, "Unsupported term type: '"_pType_"'")
			quit
		}
		
		set tSC = ..%GetCategoryFilters(.tCatFilters, ..TrainingSet, 1)
		quit:$$$ISERR(tSC)
		
		set tTrainingFilter = ..TrainingSet, tDomainId = ..DomainId
		$$$IKQFILTEROBJECTX(..DomainId,tTrainingFilter,tSC)
		set tTotalSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(tDomainId, tTrainingFilter, .tSC)
		quit:$$$ISERR(tSC)
		
		if $isobject(tTrainingFilter) {
			set tIsResult = 1, tSpreadPos = $case(pType, "entity":4, "crc":6), gResults = "^||%IKQ.Terms"
			if (pType="entity") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetByFilter("^||%IKQ.Terms", tDomainId, tTrainingFilter, $$$FILTERSPREAD, $$$ENTTYPEANY)
			} else {
				set tSC = ##class(%iKnow.Queries.CrcAPI).GetByFilter("^||%IKQ.Terms", tDomainId, tTrainingFilter, $$$FILTERSPREAD)
			}
			quit:$$$ISERR(tSC)
		} else {
			set tIsResult = 0, tSpreadPos = $case(pType, "entity":3, "crc":2)
			set gResults = $case(pType, "entity":"^IRIS.IK.EntUniDetails", "crc":"^IRIS.IK.CrcUniDetails")_"("_tDomainId_")"
		}
		
		// prepare list of terms to skip as they're already selected
		kill ^||%IK.TermsSelected
		for i = 1:1:..Terms.Count() {
			set tTerm = ..Terms.GetAt(i)
			continue:(tTerm.type'=pType)
			if (pType="entity") {
				if (tTerm.value'="") {
					set ^||%IK.TermsSelected(tTerm.value) = ""
				} else {
					for j = 1:1:tTerm.Entries.Count() {
						set ^||%IK.TermsSelected(tTerm.Entries.GetAt(j)) = ""
					}
				}
			} elseif (pType="crc") {
				if (tTerm.value'="") {
					set ^||%IK.TermsSelected($tr(tTerm.value,":",$c(0))) = ""
				} else {
					for j = 1:1:tTerm.Entries.Count() {
						set ^||%IK.TermsSelected(tTerm.Entries.GetAt(j).ToString()) = ""
					}
				}
			}
		}
		
		kill ^||%IK.TermCandidates
		set i = ""
		for {
			set i = $order(@gResults@(i), 1, tTermInfo)
			quit:i=""
			
			set tTermId = $s(tIsResult:$li(tTermInfo,1), 1:i)
			set tTotalSpread = $li(tTermInfo,tSpreadPos)
			continue:tTotalSpread<..MinimumSpread
			
			
			// first check if we already selected this term
			if tIsResult {
				set tTermValue = $case(pType, "entity":$li(tTermInfo,2), "crc":$lts($li(tTermInfo,2,4),$c(0)))
			} elseif (pType="entity") {
				set tTermValue = $g(^IRIS.IK.EntUniId(tDomainId, tTermId))
			} else {
				set tTermValue = $lts(##class(%iKnow.Queries.CrcAPI).GetValueInternal(tDomainId, tTermId), $c(0))
			}
			continue:$d(^||%IK.TermsSelected(tTermValue))
			
			
			// now fetch per-category spread info
			kill tCatSpread
			set tScore = 0, tCoversHalfACategory = 0
			for j = 1:1:tCatFilters {
				
				if (pType="entity") {
					set tCatSpread(j) = ##class(%iKnow.Queries.EntityAPI).GetSpread(tDomainId, tTermId,, tCatFilters(j))
				} else {
					set tCatSpread(j) = ##class(%iKnow.Queries.CrcAPI).GetSpread(tDomainId, tTermId, tCatFilters(j))
				}
				
				set tFilteredSourceCount = tCatFilters(j).FilteredSourceCount
				set tNotFilteredSourceCount = tTotalSourceCount - tFilteredSourceCount
				set:(tCatSpread(j)/tFilteredSourceCount)>0.5 tCoversHalfACategory = 1
			}
			continue:'tCoversHalfACategory&&((tTotalSpread/tTotalSourceCount)<..MinimumSpreadPercent)
			
			merge ^||%IK.TermCandidates(tTermId) = tCatSpread
			set ^||%IK.TermCandidates(tTermId) = $lb(tTermValue, tTotalSpread)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IK.TermsSelected
	quit tSC
}

ClassMethod %DropDictionary(pDictId) As %Status [ Internal ]
{
	quit ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(0,pDictId)
}

}
