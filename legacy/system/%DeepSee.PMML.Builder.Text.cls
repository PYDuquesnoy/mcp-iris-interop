/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

Class %DeepSee.PMML.Builder.Text Extends %DeepSee.PMML.Builder.AbstractBuilder [ System = 4 ]
{

Parameter MODELCLASSNAME = "%DeepSee.PMML.Definition.Models.TextModel";

Property EntityCount As %String [ InitialExpression = 50 ];

Property InputLanguages As %String;

/// Whether the model should have separate DataFields for each term or a single containing the whole text
Property InputType As %String(VALUELIST = ",text,terms") [ InitialExpression = "text" ];

Property TermWeightsLocal As %String(VALUELIST = ",termFrequency,binary,logarithmic,augmentedNormalizedTermFrequency") [ InitialExpression = "termFrequency" ];

Property TermWeightsGlobal As %String(VALUELIST = ",inverseDocumentFrequency,none,GFIDF,normal,probabilisticInverse") [ InitialExpression = "inverseDocumentFrequency" ];

Property TermWeightsDocumentNormalization As %String(VALUELIST = ",none,cosine") [ InitialExpression = "none" ];

Property SimilarityType As %String(VALUELIST = ",euclidian,cosine") [ InitialExpression = "cosine" ];

Property TermSelectionMetric As %String(VALUELIST = ",NaiveBayes,BM25");

Method BuildModel(ByRef pModel As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		
		// define input mapping
		set tInput = ##class(%DeepSee.PMML.Definition.Extension.TextModelInput).%New()
		set tInput.inputType = ..InputType
		set tInput.Fields = ##class(%DeepSee.PMML.Definition.Util.Array).%New()
		set tInput.Fields.type = "string"
		set tFieldName = "", tTextFields="", tCount = 0
		for {
			set tFieldName = ..Dataset.Fields.Next(tFieldName)
			quit:tFieldName=""
			continue:tFieldName=..TargetField
			set tTextFields = tTextFields _ " " _ $$$QUOTE(tFieldName)
			set x = $i(tCount)
		}
		set tTextFields = $e(tTextFields, 2, *)
		if (..InputType = "text") {
			set tInput.Fields.Values = tTextFields
			set tInput.Fields.n = tCount
		}
		// if input mode is terms, we'll have to replace the DataField and MiningField entries
		elseif (..InputType = "terms") {
			// TODO
			set tSC = $$$ERROR($$$NotImplemented)
			quit:$$$ISERR(tSC)
		}
		set tExtension = ##class(%DeepSee.PMML.Definition.Extension).%New()
		do tExtension.iscExtensions.Insert(tInput)
		do pModel.Extension.Insert(tExtension)
		
		// append Normalization and Similarity nodes
		set tNormalization = ##class(%DeepSee.PMML.Definition.Models.Text.Normalization).%New()
		set tNormalization.documentNormalization = ..TermWeightsDocumentNormalization
		set tNormalization.globalTermWeights = ..TermWeightsGlobal
		set tNormalization.localTermWeights = ..TermWeightsLocal
		set pModel.Normalization = tNormalization
		
		set tSimilarity = ##class(%DeepSee.PMML.Definition.Models.Text.Similarity).%New()
		set tSimilarity.similarityType = ..SimilarityType
		set pModel.Similarity = tSimilarity
		
		
		// build Corpus
		set tCorpus = ##class(%DeepSee.PMML.Definition.Models.Text.Corpus).%New()
		set tSC = ..Dataset.Get1DDistribution(..TargetField, .tCategories)
		quit:$$$ISERR(tSC)
		set tDocumentCount = +$g(tCategories)
		set pModel.numberOfDocuments = tDocumentCount
		for i = 1:1:tDocumentCount {
			set tCategory = $li(tCategories(i),1)
			set tDocument = ##class(%DeepSee.PMML.Definition.Models.Text.Document).%New()
			set:tCategory="" tCategory = "[null]", $li(tCategories(i),1) = "[null]" // TODO
			set tDocument.name = tCategory
			set tDocument.id = tCategory // or i?
			do tCorpus.Documents.Insert(tDocument)
		}
		set pModel.Corpus = tCorpus
		
		
		// now load data into a temporary iKnow domain
		set tConfigName = $classname()_"#"_$job
		do:##class(%iKnow.Configuration).NameIndexExists(tConfigName) ##class(%iKnow.Configuration).%DeleteId(##class(%iKnow.Configuration).NameIndexOpen(tConfigName).Id)
		set tConfig = ##class(%iKnow.Configuration).%New(tConfigName, $l(..InputLanguages,",")>1, $s(..InputLanguages="":"en", 1:..InputLanguages),, 0)
		set tSC = tConfig.%Save()
		quit:$$$ISERR(tSC)
		set tDomainName = $classname()_"#"_$job
		do:##class(%iKnow.Domain).NameIndexExists(tDomainName) ##class(%iKnow.Domain).%DeleteId(##class(%iKnow.Domain).NameIndexOpen(tDomainName).Id)
		set tDomain = ##class(%iKnow.Domain).%New(tDomainName)
		set tSC = tDomain.%Save()
		quit:$$$ISERR(tSC)
		set tSC = tDomain.SetParameter($$$IKPIGNOREEMPTYBATCH, 1)
		quit:$$$ISERR(tSC)
		set tFieldId = ##class(%iKnow.Queries.MetadataAPI).AddField(tDomain.Id, "Category",,, $$$MDSTBITMAP,,,,, .tSC)
		quit:$$$ISERR(tSC)
		
		#dim tResultSet As %SQL.StatementResult
		set tSC = ..Dataset.GetAsResultSet($lfs($e(tTextFields,2,*-1),""" """)_$lb(..TargetField), .tResultSet)
		quit:$$$ISERR(tSC)
		kill ^IRIS.Temp.PMML.StageText(+$j)
		set tCount = 0, tFieldCount = $l(tTextFields,",")
		while tResultSet.%Next() {
			set x = $i(tCount), tHasData = 0
			for i = 1:1:tFieldCount {
				set tText = tResultSet.%GetData(i)
				continue:tText=""
				set tHasData = 1
				set ^IRIS.Temp.PMML.StageText(+$j, tCount, i) = tText
			}
			set:tHasData ^IRIS.Temp.PMML.StageText(+$j, tCount) = $lb(tResultSet.%GetData(tFieldCount+1))
		}
		quit:$$$ISERR(tSC)
		
		set tLister = ##class(%iKnow.Source.Global.Lister).%New(tDomain.Id)
		set tSC = tLister.SetConfig(tConfigName)
		quit:$$$ISERR(tSC)
		set tSC = tLister.SetProcessor(, $lb(2, $c(13,10,13,10), $lb("Category")))
		quit:$$$ISERR(tSC)
		set tSC = tLister.AddListToBatch("^IRIS.Temp.PMML.StageText("_+$j_")")
		quit:$$$ISERR(tSC)
		
		set tLoader = ##class(%iKnow.Source.Loader).%New(tDomain.Id)
		set tSC = tLoader.ProcessBatch()
		quit:$$$ISERR(tSC)
		
		set tFilters = tDocumentCount
		for i = 1:1:tDocumentCount {
			set tFilters(i) = ##class(%iKnow.Filters.SimpleMetadataFilter).%New(tDomain.Id, "Category", "=", $li(tCategories(i),1))
		}
		
		
		// now find the best overall indicators
		if (..TermSelectionMetric = "NaiveBayes") {
			set tSC = ..GetEntitiesByNBProb(tDomain.Id, .tFilters)
			quit:$$$ISERR(tSC)
		} elseif (..TermSelectionMetric = "BM25") {
			set tSC = ..GetEntitiesByBM25(tDomain.Id)
			quit:$$$ISERR(tSC)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Unsupported term selection metric: '"_..TermSelectionMetric_"'")
			quit
		}
		// TODO: implement alternative techniques
		
		
		kill tEntities
		set tScore="", tEntities=0
		for {
			set tScore = $order(^||%PMML.EntSorted(tScore))
			quit:tScore=""
			set tEntityId = ""
			for {
				set tEntityId = $order(^||%PMML.EntSorted(tScore, tEntityId))
				quit:tEntityId=""
				quit:$i(tEntities)>..EntityCount
				set tEntityIds(tEntities) = tEntityId
				set tEntities(tEntities) = ##class(%iKnow.Queries.EntityAPI).GetValue(tDomain.Id, tEntityId)
			}
			quit:tEntities>..EntityCount
		}
		set tEntityCount = tEntities-1
		kill ^||%PMML.EntSorted
		
		// build dictionary based on tEntities
		set pModel.numberOfTerms = tEntityCount
		set tDictionary = ##class(%DeepSee.PMML.Definition.Models.Text.Dictionary).%New()
		set tDictionary.Terms = ##class(%DeepSee.PMML.Definition.Util.Array).%New()
		set tDictionary.Terms.type = "string"
		set tDictionary.Terms.n = tEntityCount
		set tEntityValues = ""
		for i = 1:1:tEntityCount {
			set tEntityValues = tEntityValues _ " " _ $$$QUOTE(tEntities(i))
		}
		set tDictionary.Terms.Values = $e(tEntityValues, 2, *)
		set pModel.Dictionary = tDictionary
		
		
		// build documentTermMatrix based on tEntities and tFilters
		set tMatrix = ##class(%DeepSee.PMML.Definition.Util.Matrix).%New()
		set tMatrix.nbCols = tEntityCount
		set tMatrix.nbRows = tDocumentCount
		set tMatrix.diagDefault = 0
		set tMatrix.offDiagDefault = 0
		for i = 1:1:tEntityCount {
			set tEntUniId = tEntityIds(i)
			for j = 1:1:tDocumentCount {
				set tSpread = ##class(%iKnow.Queries.EntityAPI).GetSpread(tDomain.Id, tEntUniId,, tFilters(j), .tSC)
				quit:$$$ISERR(tSC)
				set tFreq = ##class(%iKnow.Queries.EntityAPI).GetFrequency(tDomain.Id, tEntUniId,,, tFilters(j), .tSC)
				quit:$$$ISERR(tSC)
				continue:'tFreq
				set tCell = ##class(%DeepSee.PMML.Definition.Util.MatCell).%New()
				set tCell.row = j, tCell.col = i
				set tCell.value = $fnumber(tFreq/tFilters(j).FilteredSourceCount,"",2)
				//set tCell.value = tSpread
				do tMatrix.Cells.Insert(tCell)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		set tDTMatrix = ##class(%DeepSee.PMML.Definition.Models.Text.DocumentTermMatrix).%New()
		set tDTMatrix.Matrix = tMatrix
		set pModel.DocumentTermMatrix = tDTMatrix
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// clean up temporary domain and config
	if $d(tDomainName) {
		set tDomain = ##class(%iKnow.Domain).NameIndexOpen(tDomainName)
		if $isobject(tDomain) {
			do tDomain.DropData(1,1,1)
			do tDomain.%DeleteId(tDomain.Id)
			set tDomain = ""
		}
	}
	if $d(tConfigName) {
		set tConfig = ##class(%iKnow.Configuration).NameIndexOpen(tConfigName)
		if $isobject(tConfig) {
			do tConfig.%DeleteId(tConfig.Id)
			set tConfig = ""
		}
	}
	kill ^IRIS.Temp.PMML.StageText(+$j)
	
	quit tSC
}

Method GetEntitiesByNBProb(pDomainId As %Integer, ByRef pFilters) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:pFilters {
			set tSC = ##class(%iKnow.Analytics.NaiveBayesClassifier).GetEntityProbabilities(pDomainId, pFilters(i), .tProbabilities, ..EntityCount\pFilters)
			quit:$$$ISERR(tSC)
			
			set tEntityId = ""
			for {
				set tEntityId = $order(tProbabilities(tEntityId), 1, tProb)
				quit:tEntityId=""
				set tScore = $s(tProb<0.5:1-tProb, 1:tProb)-0.5
				continue:tScore=0.5
				set tEntProbs(tEntityId, i) = tScore
				//set tSpread = ##class(%iKnow.Queries.EntityAPI).GetSpread(tDomain.Id, tEntityId)
				//set tScore = tScore * tSpread
				//set tEntProbs(tEntityId) = $g(tEntProbs(tEntityId)) + tScore
			}
		}
		quit:$$$ISERR(tSC)
		
		kill ^||%PMML.EntSorted
		set tEntityId = ""
		for {
			set tEntityId = $order(tEntProbs(tEntityId))
			quit:tEntityId=""
			set tTotal = 0
			for i = 1:1:pFilters {
				if '$d(tEntProbs(tEntityId,i),tScore) {
					set tProb = ##class(%iKnow.Analytics.NaiveBayesClassifier).GetEntityProbability(pDomainId, tEntityId, pFilters(i))
					set tScore = $s(tProb<0.5:1-tProb, 1:tProb)-0.5
					continue:tScore=0.5
					set tEntProbs(tEntityId,i) = tScore
				}
				set tTotal = tTotal+(tScore*tFilters(i).FilteredSourceCount)
			}
			set ^||%PMML.EntSorted(-tTotal, tEntityId) = ""
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetEntitiesByBM25(pDomainId As %Integer, pEntType As %Integer = {$$$ENTTYPECONCEPT}) As %Status
{
	set tSC = $$$OK
	try {
		/*
		b = 0.75 (smoothing)
		k1 = 1.6 (tuning)
		
		BM25(tf) = termFreq [* (k1 + 1)] / (k1 * ((1-b) + b * docLength / avgDocLength) + termFreq) * [RSJ|IDF]
		RSJ = log( (spreadFilter + 0.5) * (DCsample - DCfilter - spreadSample + spreadFilter + 0.5) / ( (spreadSample - spreadFilter + 0.5) * (DCfilter - spreadFilter + 0.5) ) )
		IDF = log( (DC - spread + 0.5) / (spread + 0.5) )
		*/
		
		set b = 0.75, k1 = 1.6
		set tDocCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId)
		set tEntOccCount = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountByDomain(pDomainId,, pEntType)
		set tAvgDocLength = tEntOccCount / tDocCount
		
		kill ^||%PMML.EntIDF
		set tEntUniId = ""
		for {
			set tEntUniId = $order(^ISC.IK.EntUniDetails(pDomainId, tEntUniId), 1, tDetails)
			quit:tEntUniId=""
			
			set tSpread = $lg(tDetails, $case(pEntType, $$$ENTTYPEANY:3, $$$ENTTYPECONCEPT:4, $$$ENTTYPERELATION:5))
			continue:tSpread<=1
			set ^||%PMML.EntIDF(tEntUniId) = $zlog((tDocCount - tSpread + 0.5) / (tSpread + 0.5))
		}
		
		if (pEntType = $$$ENTTYPEANY) {
			set tSrcId=""
			for {
				set tSrcId = $order(^ISC.IK.SrcDetails(pDomainId,tSrcId), 1, tDetails)
				quit:tSrcId=""
				
				set tDocLengths(tSrcId) = $lg(tDetails,4)
			}
		}
		
		kill ^||%PMML.EntBM25
		set tSrcId = ""
		for {
			set tSrcId = $order(^ISC.IK.EntSrcDetails(pDomainId, tSrcId))
			quit:tSrcId=""
			
			kill tSrcEnts
			merge tSrcEnts = ^ISC.IK.EntSrcDetails(pDomainId, tSrcId)
			
			if (pEntType=$$$ENTTYPEANY) {
				set tDocLength = tDocLengths(tSrcId)
			} else {
				set tDocLength = 0
				set tEntUniId = ""
				for {
					set tEntUniId = $order(tSrcEnts(tEntUniId), 1, tDetails)
					quit:tEntUniId=""
					
					set tFrequency = $case(pEntType, $$$ENTTYPEANY:$lg(tDetails,1)+$lg(tDetails,2), $$$ENTTYPECONCEPT:$lg(tDetails,1), $$$ENTTYPERELATION:$lg(tDetails,2))
					set x = $i(tDocLength, tFrequency)
				}
			}
			
			set tEntUniId = ""
			for {
				set tEntUniId = $order(tSrcEnts(tEntUniId), 1, tDetails)
				quit:tEntUniId=""
				
				set tFrequency = $case(pEntType, $$$ENTTYPEANY:$lg(tDetails,1)+$lg(tDetails,2), $$$ENTTYPECONCEPT:$lg(tDetails,1), $$$ENTTYPERELATION:$lg(tDetails,2))
				continue:'tFrequency
				
				set tBM25 = tFrequency / (k1 * ((1-b) + b * (tDocLength / tAvgDocLength)) + tFrequency)
				set x = $i(^||%PMML.EntBM25(tEntUniId), tBM25)
			}
		}
		
		kill ^||%PMML.EntSorted
		set tEntUniId = ""
		for {
			set tEntUniId = $order(^||%PMML.EntIDF(tEntUniId), 1, tIDF)
			quit:tEntUniId=""
			
			set ^||%PMML.EntSorted(-tIDF * ^||%PMML.EntBM25(tEntUniId), tEntUniId) = ""
		}

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%PMML.EntIDF, ^||%PMML.EntBM25
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
<Value>EntityCount</Value>
</Value>
<Value name="8">
<Value>TermWeightsLocal</Value>
</Value>
<Value name="9">
<Value>TermWeightsGlobal</Value>
</Value>
<Value name="10">
<Value>TermWeightsDocumentNormalization</Value>
</Value>
<Value name="11">
<Value>SimilarityType</Value>
</Value>
<Value name="12">
<Value>Mode</Value>
</Value>
<Value name="13">
<Value>InputLanguages</Value>
</Value>
<Value name="14">
<Value>InputType</Value>
</Value>
<Value name="15">
<Value>DataSources</Value>
</Value>
<Value name="16">
<Value>TermSelectionMetric</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
