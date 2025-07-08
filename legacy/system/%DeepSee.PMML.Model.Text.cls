/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Model.Text Extends %DeepSee.PMML.Model.AbstractModel [ Abstract, System = 4 ]
{

Parameter DOCCOUNT As INTEGER;

Parameter TERMCOUNT As INTEGER;

Parameter TRACEWEIGHTTYPE = "add";

Parameter SIMILARITYMETRIC As STRING;

Property Indexer As %iKnow.Indexer [ Internal, Private ];

Property DocTermMatrix [ MultiDimensional ];

/// Returns a vector containing the weighed frequency values for the query terms,
/// using the information in this TextModel's Dictionary.
Method GetQueryVector(pInput As %DeepSee.PMML.ModelInput, Output pVector) As %Status [ Abstract, Internal ]
{
}

Method CreateOutput(pDoc As %Integer, pScore As %Double, Output pOutput As %DeepSee.PMML.ModelOutput) As %Status [ Abstract, Private ]
{
}

ClassMethod %CreateModelClass(pClass As %Dictionary.ClassDefinition, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel) As %Status [ Internal ]
{
	#define WriteLine(%m,%c) do %m.Implementation.WriteLine($c(9)_%c)
	#dim tDefinition As %DeepSee.PMML.Definition.Models.TextModel = pDefinition
	set tSC = $$$OK
	try {
		set tDocCount = tDefinition.numberOfDocuments
		set tTermCount = tDefinition.numberOfTerms
		
		set tSC = tDefinition.DocumentTermMatrix.Matrix.ValuesAsArray(.tMatrix)
		quit:$$$ISERR(tSC)
		set tSC = tDefinition.Dictionary.Terms.ValuesAsArray(.tTerms)
		quit:$$$ISERR(tSC)
		
		set tParam = ##class(%Dictionary.ParameterDefinition).%New()
		set tParam.Name = "DOCCOUNT"
		set tParam.Default = tDocCount
		set tParam.Internal = 1
		do pClass.Parameters.Insert(tParam)
		
		set tParam = ##class(%Dictionary.ParameterDefinition).%New()
		set tParam.Name = "TERMCOUNT"
		set tParam.Default = tTermCount
		set tParam.Internal = 1
		do pClass.Parameters.Insert(tParam)
		set tParam=""
		
		set tParam = ##class(%Dictionary.ParameterDefinition).%New()
		set tParam.Name = "SIMILARITYMETRIC"
		set tParam.Default = tDefinition.Similarity.similarityType
		set tParam.Internal = 1
		do pClass.Parameters.Insert(tParam)
		set tParam=""
		
		
		// generate GetTermValue() implementation
		set tGTValue = ##class(%Dictionary.MethodDefinition).%New()
		set tGTValue.Name = "GetTermValue"
		set tGTValue.FormalSpec = "pTermId:%Integer"
		set tGTValue.ReturnType = "%String"
		set tGTValue.Internal = 1
		set tGTValue.ClassMethod = 1
		for i = 1:1:tTermCount {
			do tGTValue.Implementation.WriteLine("	quit:pTermId="_i_" "_$$$QUOTE(tTerms(i)))
		}
		do tGTValue.Implementation.WriteLine("	quit """"")
		do pClass.Methods.Insert(tGTValue)
		
		
		// generate GetQueryVector() implementation
		set tGQVector = ##class(%Dictionary.MethodDefinition).%New()
		set tGQVector.Name = "GetQueryVector"
		set tGQVector.FormalSpec = "pInput:%DeepSee.PMML.ModelInput,*pVector,*pNorm:%Double"
		set tGQVector.ReturnType = "%Status"
		set tGQVector.Internal = 1
		do tGQVector.Implementation.WriteLine("	set tSC = $$$OK")
		do tGQVector.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tGQVector.Implementation.WriteLine($c(9,9)_%c)
		$$$WriteLine("kill tFrequency")
		
		set tInputMap = ""
		for i = 1:1:tDefinition.Extension.Count() {
			set tExtension = tDefinition.Extension.GetAt(i)
			for j = 1:1:tExtension.iscExtensions.Count() {
				set tExtensionElem = tExtension.iscExtensions.GetAt(j)
				if (tExtensionElem.%Extends("%DeepSee.PMML.Definition.Extension.TextModelInput")) {
					set tInputMap = tExtensionElem
					quit
				}
			}
			quit:$isobject(tInputMap)
		}
		if $isobject(tInputMap) {
			set tSC = tInputMap.Fields.ValuesAsArray(.tInputFields)
			quit:$$$ISERR(tSC)
			if (tInputMap.inputType="text") {
				
				// line up terms of interest
				for i = 1:1:tTermCount {
					$$$WriteLine("set tTerms("_i_") = "_$$$QUOTE(tTerms(i)))
				}
				$$$WriteLine("")
				
				// concatenate input fields and then get frequencies from text
				$$$WriteLine("set tText = """"")
				for i = 1:1:tInputFields {
					$$$WriteLine("set tText = tText _ $s(tText="""":"""", 1:$c(13,10,13,10)) _ pInput."_$$$PROPERTYNAME(tInputFields(i)))
				}
				$$$WriteLine("")
				
				$$$WriteLine("set tSC = ..GetTermsFromText(tText, .tTerms, .tFrequency, "_$$$QUOTE(tInputMap.languages)_")")
				$$$WriteLine("quit:$$$ISERR(tSC)")
				
			} else {
		
				// if inputType="terms", simply map to input fields
				for i = 1:1:tInputFields {
					$$$WriteLine("set tFrequency("_i_") = pInput."_$$$PROPERTYNAME(tInputFields(i)))
				}
				
			}
		} else {
			
			// if no explicit input map is in place, simply use all active mining fields
			// in that order
			set tCounter = 0
			for i = 1:1:tDefinition.MiningSchema.MiningFields.Count() {
				set tField = tDefinition.MiningSchema.MiningFields.GetAt(i)
				continue:tField.usageType'=$$$PMMLusageTypeActive
				set tCounter = tCounter+1
				$$$WriteLine("set tFrequency("_tCounter_") = pInput."_$$$PROPERTYNAME(tField.name))
			}
				
		}
		
		$$$WriteLine("")
		
		// prepare to apply weights
		if (tDefinition.Normalization.localTermWeights="augmentedNormalizedTermFrequency") {
			// find tMaxFreq
			$$$WriteLine("set tMaxFreq = 0")
			$$$WriteLine("for i = 1:1:"_tTermCount_" { set:'tMaxFreq||(tMaxFreq<tFrequency(i)) tMaxFreq = tFrequency(i) }")
		}
		
		for i = 1:1:tTermCount {
		
			if (tDefinition.Normalization.localTermWeights = "termFrequency") {
				set tLocal = "$g(tFrequency("_i_"),0)"
			} elseif (tDefinition.Normalization.localTermWeights = "binary") {
				set tLocal = "(''$g(tFrequency("_i_"),0))"
			} elseif (tDefinition.Normalization.localTermWeights = "logarithmic") {
				set tLocal = "$zlog($g(tFrequency("_i_"),0)+1)"
			} elseif (tDefinition.Normalization.localTermWeights = "augmentedNormalizedTermFrequency") {
				set tLocal = "(0.5*((''$g(tFrequency("_i_"),0)) + ($g(tFrequency("_i_"),0)/tMaxFreq)))"
			}
		
			if (tDefinition.Normalization.globalTermWeights = "none") {
				set tGlobal = tLocal
			} elseif (tDefinition.Normalization.globalTermWeights = "inverseDocumentFrequency") {
				set tSpread = 0
				for j = 1:1:tDocCount { 
					set:$g(tMatrix(j,i),0) tSpread = tSpread+1
				}
				set tGlobal = $s(tSpread:$zlog(tDocCount/tSpread)_" * "_tLocal, 1:0)
			} elseif (tDefinition.Normalization.globalTermWeights = "GFIDF") {
				set tSC = $$$ERROR($$$NotImplemented)  quit // TODO
			} elseif (tDefinition.Normalization.globalTermWeights = "normal") {
				set tSC = $$$ERROR($$$NotImplemented)  quit // TODO
			} elseif (tDefinition.Normalization.globalTermWeights = "probabilisticInverse") {
				set tSpread = 0
				for j = 1:1:tDocCount { 
					set:$g(tMatrix(j,i),0) tSpread = tSpread+1
				}
				set tGlobal = $s(tSpread:$zlog((tDocCount - tSpread)/tSpread)_" * "_tLocal, 1:0)
			}
			
			$$$WriteLine("set pVector("_i_") = "_tGlobal)
			
		}
		quit:$$$ISERR(tSC)
		
		if (tDefinition.Similarity.similarityType="cosine") {
			$$$WriteLine("")
			$$$WriteLine("set pNorm = 0")
			$$$WriteLine("for i = 1:1:"_tTermCount_" { set pNorm = pNorm + ($g(pVector(i))**2) }")
			$$$WriteLine("set pNorm = $zsqr(pNorm)")
		}
		
		do tGQVector.Implementation.WriteLine("	} catch (ex) {")
		do tGQVector.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tGQVector.Implementation.WriteLine("	}")
		do tGQVector.Implementation.WriteLine("	quit tSC")
		do pClass.Methods.Insert(tGQVector)
		set tGQVector=""
		
		
		// generate %OnNew() implementation, populating ..DocTermMatrix
		set tOnNew = ##class(%Dictionary.MethodDefinition).%New()
		set tOnNew.Name = "%OnNew"
		set tOnNew.ReturnType = "%Status"
		set tOnNew.Private = 1
		set tOnNew.ServerOnly = 1
		do tOnNew.Implementation.WriteLine("	set tSC = $$$OK")
		do tOnNew.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tOnNew.Implementation.WriteLine($c(9,9)_%c)
		
		if (tDefinition.Normalization.globalTermWeights = "inverseDocumentFrequency") || 
			(tDefinition.Normalization.globalTermWeights = "probabilisticInverse") {
			for i = 1:1:tDocCount {
				for j = 1:1:tTermCount {
					set tSpread(j) = $g(tSpread(j))+1
					set:$g(tMatrix(i,j)) x = tSpread(j)
				}
			}
		}
		
		for i = 1:1:tDocCount {
			
			if (tDefinition.Normalization.localTermWeights = "augmentedNormalizedTermFrequency") {
				set tMaxFreq = 0
				for j = 1:1:tTermCount {
					set:'tMaxFreq||(tMaxFreq<$g(tMatrix(i,j))) tMaxFreq = tMatrix(i,j)
				}
			}
			
			kill tWeight
			set tNormalize = 0
			for j = 1:1:tTermCount {
				
				// local term weight
				if (tDefinition.Normalization.localTermWeights = "termFrequency") {
					set tWeight(j) = $g(tMatrix(i,j),0)
				} elseif (tDefinition.Normalization.localTermWeights = "binary") {
					set tWeight(j) = ''$g(tMatrix(i,j),0)
				} elseif (tDefinition.Normalization.localTermWeights = "logarithmic") {
					set tWeight(j) = $zlog($g(tMatrix(i,j),0)+1)
				} elseif (tDefinition.Normalization.localTermWeights = "augmentedNormalizedTermFrequency") {
					set tWeight(j) = (0.5*((''$g(tMatrix(i,j),0)) + ($g(tMatrix(i,j),0)/tMaxFreq)))
				}
				continue:tWeight(j)=0
				
				// global term weight
				if (tDefinition.Normalization.globalTermWeights = "none") {
					// no extra weighting
				} elseif (tDefinition.Normalization.globalTermWeights = "inverseDocumentFrequency") {
					set tWeight(j) = tWeight(j) * $s($g(tSpread(j)):$zlog(tDocCount/tSpread(j)), 1:0)
				} elseif (tDefinition.Normalization.globalTermWeights = "GFIDF") {
					set tSC = $$$ERROR($$$NotImplemented)  quit // TODO
				} elseif (tDefinition.Normalization.globalTermWeights = "normal") {
					set tSC = $$$ERROR($$$NotImplemented)  quit // TODO
				} elseif (tDefinition.Normalization.globalTermWeights = "probabilisticInverse") {
					set tWeight(j) = tWeight(j) * $s($g(tSpread(j)):$zlog((tDocCount - tSpread(j))/tSpread(j)), 1:0)
				}
				
				// normalize
				set tNormalize = tNormalize + (tWeight(j)**2)
			}
			
			set tNormalize = $zsqr(tNormalize)
			$$$WriteLine("set i%DocTermMatrix("_i_") = "_tNormalize)
			
			for j = 1:1:tTermCount {
				set tWeight = tWeight(j)
				continue:'tWeight
				
				if (tDefinition.Normalization.documentNormalization = "cosine") {
					set tWeight = tWeight / tNormalize
				}
				
				$$$WriteLine("set i%DocTermMatrix("_i_","_j_") = "_tWeight)
			}
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		do tOnNew.Implementation.WriteLine("	} catch (ex) {")
		do tOnNew.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tOnNew.Implementation.WriteLine("	}")
		do tOnNew.Implementation.WriteLine("	quit tSC")
		do pClass.Methods.Insert(tOnNew)
		set tOnNew=""
		
		
		
		// generate CreateOutput() implementation
		set tCOut = ##class(%Dictionary.MethodDefinition).%New()
		set tCOut.Name = "CreateOutput"
		set tCOut.FormalSpec = "pDoc:%Integer,pScore:%Double,*pOutput:%DeepSee.PMML.ModelOutput"
		set tCOut.ReturnType = "%Status"
		set tCOut.Private = 1
		do tCOut.Implementation.WriteLine("	set tSC = $$$OK")
		do tCOut.Implementation.WriteLine("	try {")
		#define WriteLine(%c) do tCOut.Implementation.WriteLine($c(9,9)_%c)
		
		for i = 1:1:tDocCount {
			set tDoc = tDefinition.Corpus.Documents.GetAt(i)
			$$$WriteLine("set tDocs("_i_") = $lb("_$$$QUOTE(tDoc.id)_","_$$$QUOTE(tDoc.name)_","_$$$QUOTE(tDoc.file)_")")
		}
		$$$WriteLine("set tBestDoc = $s(pDoc="""":"""", 1:$li(tDocs(pDoc),1))")
		
		set tSC = ..%PopulateOutputObject(pDefinition, tCOut.Implementation, "tBestDoc")
		quit:$$$ISERR(tSC)
		
		do tCOut.Implementation.WriteLine("	} catch (ex) {")
		do tCOut.Implementation.WriteLine("		set tSC = ex.AsStatus()")
		do tCOut.Implementation.WriteLine("	}")
		do tCOut.Implementation.WriteLine("	quit tSC")
		do pClass.Methods.Insert(tCOut)
		set tCOut=""
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %ExecuteModelInternal(pInput As %DeepSee.PMML.ModelInput, Output pOutput As %DeepSee.PMML.ModelOutput) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		// get weighted query vector
		set tSC = ..GetQueryVector(pInput, .tQueryVector, .tQueryNorm)
		quit:$$$ISERR(tSC)
		
		set tTrace = ..Tracing
		
		// multiply with doc term matrix
		merge tDocTermMatrix = ..DocTermMatrix
		set tDoc = ""
		for {
			set tDoc = $order(tDocTermMatrix(tDoc), 1, tDocNorm)
			quit:tDoc=""
			
			set tTerm = "", tDocTotal = 0
			for {
				set tTerm = $order(tDocTermMatrix(tDoc,tTerm),1,tWeight)
				quit:tTerm=""
				
				if (..#SIMILARITYMETRIC = "cosine") {
					set tContribution = (tWeight * tQueryVector(tTerm))
				} else {
					set tContribution = (tWeight - tQueryVector(tTerm))**2
				}
				set tDocTotal = tDocTotal + tContribution
				
				set:tTrace&&tContribution tTrace=$g(tTrace)+1, tTrace(tDoc, -tContribution, tTrace) = $lb($lb(..GetTermValue(tTerm)), /* ? */, tContribution, "")
			}
			continue:'tDocTotal
			
			if (..#SIMILARITYMETRIC="cosine") {
				continue:'(tQueryNorm&&tDocNorm)
				set tSimilarity = tDocTotal / (tQueryNorm * tDocNorm)
			} else {
				// for euclidian distance, we're looking for the *lowest* number
				set tSimilarity = -$zsqr(tDocTotal)
			}
			
			set tScores(-tSimilarity, tDoc) = ""
		}
		
		set tScore = $order(tScores(""))
		set tBestDoc = $s(tScore="":"", 1:$order(tScores(tScore,"")))
		
		set tSC = ..CreateOutput(tBestDoc, $zabs(tScore), .pOutput)
		quit:$$$ISERR(tSC)
		
		if ..Tracing && (tBestDoc'="") {
			kill tWeights
			merge tWeights = tTrace(tBestDoc)
			set tSC = ..%PopulateTrace(.pOutput, .tWeights)
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method GetTermsFromText(pText As %String, ByRef pTerms, Output pFrequencies, pLanguages As %String = "en") As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		if '$isobject(..Indexer) {
			set ..Indexer = ##class(%iKnow.Indexer).%New()
			
			set tSC = ..Indexer.EnableMergeRelations()
			quit:$$$ISERR(tSC)
			set tSC = ..Indexer.DisableSummarizer()
			quit:$$$ISERR(tSC)
			
			set:pLanguages="" pLanguages = "en"
			set tLangCount = $length(pLanguages, ",")
			for i = 1:1:tLangCount {
				set tLang = $$$LOWER($zstrip($piece(pLanguages, ",", i),"<>W"))
				
		        set tSC = ..Indexer.LoadKnowledgebase(tLang, ##class(%iKnow.KB.Knowledgebase).GetByName(tLang))
		        quit:$$$ISERR(tSC)
		        
		        if (tLangCount > 1) {
			        set tSC = ..Indexer.LoadLanguagebase(tLang, ##class(%iKnow.LB.Languagebase).GetByName(tLang))
			        quit:$$$ISERR(tSC)
		        }
			}
			quit:$$$ISERR(tSC)
		}
		
		set tDirectInput = ##class(%DeepSee.PMML.Utils.iKnow.DirectInput).%New()
		
		set tSC = ..Indexer.BufferString(pText)
		quit:$$$ISERR(tSC)
		
		set tSC = ..Indexer.IndexBuffer(tDirectInput)
		quit:$$$ISERR(tSC)
		
		set tSC = ..Indexer.ClearBuffer()
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(pTerms(i), 1, tTerm)
			quit:i=""
			
			set pFrequencies(i) = tDirectInput.GetFrequency(tTerm)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod GetTermValue(pTermId As %Integer) As %String [ Abstract, Internal ]
{
	quit ""
}

ClassMethod %OnGetOutputFeature(pMethod As %Stream.Object, pDefinition As %DeepSee.PMML.Definition.Models.AbstractModel, pOutputField As %DeepSee.PMML.Definition.OutputField, ByRef pFeatureValueVar As %String, Output pSupported As %Boolean) As %Status [ Internal, Private ]
{
	set pSupported = 0
	
	if (pOutputField.feature="predictedDisplayValue") {
		set pSupported = 1
		do pMethod.WriteLine("		set tBestDocName = $s(pDoc="""":"""", 1:$li(tDocs(pDoc),2))")
		set pFeatureValueVar = "tBestDocName"
	}
	quit $$$OK
}

}
