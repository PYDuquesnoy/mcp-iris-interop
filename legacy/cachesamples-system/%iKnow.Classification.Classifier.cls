/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This is the superclass for executable Text Categorization models. Upon compiling a subclass
/// of this class, the required internal code will be generated to support the class' main
/// methods <method>%Categorize</method> and <method>%CategorizeText</method>. To invoke a Text
/// Categorization model on free text:</p>
/// <blockquote><tt>set tClassifier = ##class(User.MyClassifier).%New()<br/>write
/// tClassifier.%CategorizeText(.tCategories, "The helicopter was not flying at a
/// sufficiently high altitude ...")<br/>zwrite tCategories</tt></blockquote>
/// <p>To invoke it on a source in an iKnow domain:</p>
/// <blockquote><tt>set tClassifier = ##class(User.MyClassifier).%New("iKnow", [domain name])<br/>
/// write tClassifier.%Categorize(.tCategories, tSourceId)<br/>zwrite tCategories</tt></blockquote>
Class %iKnow.Classification.Classifier Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

Projection ClassifierProjection As %iKnow.Classification.ClassifierProjection [ Internal ];

Property Mode As %String(VALUELIST = ",iKnow,iTables") [ Internal, Private ];

Property DomainId As %Integer [ Internal, Private ];

Property ITablesPackage As %String [ Internal, Private ];

Property CurrentConfig As %String [ Internal, Private ];

Property Indexer As %iKnow.Indexer [ Internal, Private ];

Property %Trace [ Internal, MultiDimensional, Private ];

/// Maps unique entity/CRC IDs to local term IDs with count="exactCount"
/// 		..ikTermIdMap([domainId], [type], [entUniId|crcUniId|coocID]) = $lb([termID], [negation])
/// 		..ikTermIdMap([domainId], -2, [entUniId], [coocID]) = $lb([negation], [position])
Property ikTermIdMap [ Internal, MultiDimensional, Private ];

/// The definition of this Text Categorization model.
XData Classifier [ XMLNamespace = "http://www.intersystems.com/iknow/classification" ]
{
}

/// Returns an array containing the terms specified in this classifier:
/// 		pTerms(n) = $lb(stringRepresentation, type, negationPolicy, countPolicy, displayName)
ClassMethod %GetTerms(Output pTerms) As %Status [ CodeMode = objectgenerator ]
{
	if %compiledclass.Abstract {
		do %code.WriteLine("	kill pTerms")
		do %code.WriteLine("	quit $$$OK")
		quit $$$OK
	}
	
	#dim tModel as %iKnow.Classification.Definition.Classifier
	#dim tTerm As %iKnow.Classification.Definition.Term
	do %code.WriteLine("	kill pTerms")
	set tSC =  ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(%class.Name, .tModel)
	quit:$$$ISERR(tSC) tSC
	for i = 1:1:tModel.TermDictionary.Terms.Count() {
		set tTerm = tModel.TermDictionary.Terms.GetAt(i)
		do %code.WriteLine("	set pTerms($i(pTerms)) = $lb("_tTerm.GetAsCode()_", "_$$$QUOTE(tTerm.type)_", "_$$$QUOTE(tTerm.negation)_", "_$$$QUOTE(tTerm.count)_", "_$$$QUOTE(tTerm.GetDisplayName(1))_")")
	}
	do %code.WriteLine("	quit $$$OK")
	set %classifierDefinition = tModel
	quit $$$OK
}

/// Returns an array containing the categories specified in this classifier:
/// 		pTerms(n) = $lb(name, description, recordCount, spec)
ClassMethod %GetCategories(Output pCategories) As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetTerms ]
{
	if %compiledclass.Abstract {
		do %code.WriteLine("	kill pCategories")
		do %code.WriteLine("	quit $$$OK")
		quit $$$OK
	}
	
	#dim tModel as %iKnow.Classification.Definition.Classifier = %classifierDefinition
	#dim tCat As %iKnow.Classification.Definition.Category
	do %code.WriteLine("	kill pCategories")
	for i = 1:1:tModel.Categories.Count() {
		set tCat = tModel.Categories.GetAt(i)
		do %code.WriteLine("	set pCategories($i(pCategories)) = $lb("_$$$QUOTE(tCat.name)_", "_$$$QUOTE(tCat.description)_", "_tCat.recordCount_", "_$$$QUOTE(tCat.spec)_")")
	}
	do %code.WriteLine("	quit $$$OK")
	quit $$$OK
}

/// Initializes this Classifier instance to access domain <var>pDomainSpec</var> by default,
/// when calling <method>%Categorize</method>
Method %OnNew(pMode As %String(VALUELIST=",iKnow,iTables") = "", pDomainSpec As %String = "") As %Status [ Internal, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		set tSC = ..%Initialize(pMode, pDomainSpec)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Initializes this Classifier instance to access domain <var>pDomainSpec</var> by default,
/// when calling <method>%Categorize</method>
Method %Initialize(pMode As %String, pDomainSpec As %String) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tSC = ..%Reset()
		quit:$$$ISERR(tSC)
		
		set ..Mode = pMode
		if (pMode="iKnow") {
			
			set tSC = ..%InitializeIKnow(pDomainSpec)
			quit:$$$ISERR(tSC)
			
		} elseif (pMode="iTables") {
			
			set tSC = ..%InitializeITables(pDomainSpec)
			quit:$$$ISERR(tSC)
			
		} elseif (pMode'="") {
			set tSC = $$$ERROR($$$GeneralError, "Unsupported mode: '"_pMode_"'")
			quit
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %InitializeIKnow(pDomainName As %String) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		set ..DomainId = $system.iKnow.GetDomainId(pDomainName)
		if '..DomainId {
			set tSC = $$$ERROR($$$IKDomainNotExists, pDomainName)
			quit
		}
		
		set tSC = ..%BuildIKTermMap(..DomainId)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %InitializeITables(pPackageName As %String) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		if '##class(%Dictionary.CompiledClass).%ExistsId(pPackageName_".Source") {
			set tSC = $$$ERROR($$$GeneralError, "Package '"_pPackageName_"' is not a valid iTables package")
			quit
		}
		set ..ITablesPackage = pPackageName
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Resets all internal data structures populated by <method>%Initialize</method>
Method %Reset() As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		
		set (..DomainId, ..ITablesPackage) = ""
		kill ..ikTermIdMap
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetDomainId(pDomainSpec As %String, Output pDomainId As %Integer) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		if (pDomainSpec="") {
			set pDomainId = +..DomainId
		} else {
			set pDomainId = $system.iKnow.GetDomainId(pDomainSpec)
			set:'pDomainId tSC = $$$ERROR($$$IKDomainNotExists, pDomainSpec)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %BuildIKTermMap(pDomainId As %Integer, Output pIkTermIdMap, vSrcId As %Integer = 0) As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetCategories, Internal ]
{
	set tSC = $$$OK
	try {
		if (%class.Abstract) {
			do %code.WriteLine("	quit $$$OK")
			quit
		}
		
		#dim tModel As %iKnow.Classification.Definition.Classifier = %classifierDefinition
		
		do %code.WriteLine("	set tSC = $$$OK")
		do %code.WriteLine("	try {")
		
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		$$$WriteLine("kill pIkTermIdMap")
		$$$WriteLine("if $d(..ikTermIdMap(pDomainId)) && 'vSrcId {")
		$$$WriteLine("	merge pIkTermIdMap = ..ikTermIdMap(pDomainId)")
		$$$WriteLine("	quit")
		$$$WriteLine("}")
		
		kill %classifierDictTerms
		set tTermCount = tModel.TermDictionary.Terms.Count()
		for i = 1:1:tTermCount {
			
			#dim tTerm As %iKnow.Classification.Definition.Term = tModel.TermDictionary.Terms.GetAt(i)
			if (tTerm.count'="exactCount") { // or won't we need this method anymore?
				set %classifierDictTerms(i) = tTerm
				continue
			}
			
			if (tTerm.type="entity") {
				
				// backwards compatibilty:
				if (tTerm.value'="") {
					$$$WriteLine("set tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, "_$$$QUOTE(tTerm.value)_", vSrcId)")
					$$$WriteLine("set:tID pIkTermIdMap(0, tID) = $lb("_i_", "_$$$QUOTE(tTerm.negation)_")")
					continue
				}
				
				for j = 1:1:tTerm.Entries.Count() {
					$$$WriteLine("set tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, "_$$$QUOTE(tTerm.Entries.GetAt(j))_", vSrcId)")
					$$$WriteLine("set:tID pIkTermIdMap(0, tID) = $lb("_i_", "_$$$QUOTE(tTerm.negation)_")")
				}
				
			} elseif (tTerm.type="crc") {
				
				// backwards compatibility
				if (tTerm.value'="") {
					$$$WriteLine("set tID = ##class(%iKnow.Queries.CrcAPI).GetIdInternal(pDomainId, "_$$$QUOTE($p(tTerm.value,":",1))_", "_$$$QUOTE($p(tTerm.value,":",2))_", "_$$$QUOTE($p(tTerm.value,":",3))_", vSrcId)")
					$$$WriteLine("set:tID pIkTermIdMap(1, tID) = $lb("_i_", "_$$$QUOTE(tTerm.negation)_")")
					continue
				}
				
				for j = 1:1:tTerm.Entries.Count() {
					set tCRC = tTerm.Entries.GetAt(j)
					$$$WriteLine("set tID = ##class(%iKnow.Queries.CrcAPI).GetIdInternal(pDomainId, "_$$$QUOTE(tCRC.Master)_", "_$$$QUOTE(tCRC.Relation)_", "_$$$QUOTE(tCRC.Slave)_", vSrcId)")
					$$$WriteLine("set:tID pIkTermIdMap(1, tID) = $lb("_i_", "_$$$QUOTE(tTerm.negation)_")")
				}
				
			} elseif (tTerm.type="cooccurrence") {
				
				// backwards compatibility
				if (tTerm.value'="") {
					set tCoocID = $i(tCoocID)
					$$$WriteLine("kill tCoocMap")
					$$$WriteLine("set tAllEntitiesExist = 1, tIDs = """"")
					for k = 1:1:$l(tTerm.value,":") {
						$$$WriteLine("set:tAllEntitiesExist tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, "_$$$QUOTE($p(tTerm.value,":",k))_", vSrcId)")
						$$$WriteLine("set:tAllEntitiesExist tAllEntitiesExist = ''tID")
						$$$WriteLine("set:tAllEntitiesExist tCoocMap(tID, "_tCoocID_") = "_$$$QUOTE(tTerm.negation)_", tIDs = tIDs_$lb(tID)")
					}
					$$$WriteLine("merge:tAllEntitiesExist pIkTermIdMap(-2) = tCoocMap")
					$$$WriteLine("set:tAllEntitiesExist pIkTermIdMap(2, "_tCoocID_") = $lb("_i_", "_$$$QUOTE(tTerm.negation)_", tIDs)")
					continue
				}
				
				for j = 1:1:tTerm.Entries.Count() {
					set tCooc = tTerm.Entries.GetAt(j)
					set tCoocID = $i(tCoocID)
					$$$WriteLine("kill tCoocMap")
					$$$WriteLine("set tAllEntitiesExist = 1, tIDs = """"")
					for k = 1:1:tCooc.Entities.Count() {
						$$$WriteLine("set:tAllEntitiesExist tID = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, "_$$$QUOTE(tCooc.Entities.GetAt(k))_", vSrcId)")
						$$$WriteLine("set:tAllEntitiesExist tAllEntitiesExist = ''tID")
						$$$WriteLine("set:tAllEntitiesExist tCoocMap(tID, "_tCoocID_") = "_$$$QUOTE(tTerm.negation)_", tIDs = tIDs_$lb(tID)")
					}
					$$$WriteLine("merge:tAllEntitiesExist pIkTermIdMap(-2) = tCoocMap")
					$$$WriteLine("set:tAllEntitiesExist pIkTermIdMap(2, "_tCoocID_") = $lb("_i_", "_$$$QUOTE(tTerm.negation)_", tIDs)")
				}
			} 
		}
		
		$$$WriteLine("merge:'vSrcId ..ikTermIdMap(pDomainId) = pIkTermIdMap")
		
		do %code.WriteLine("	} catch (ex) {")
		do %code.WriteLine("		set tSC = ex.AsStatus()")
		do %code.WriteLine("	}")
		do %code.WriteLine("	quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns trace information wrt the actual weights each term had. 
/// 		pTermWeights(tTermPos) = tWeight
/// Note: this might not be available for each classification method!
Method %GetTraceInfo(Output pTermWeights, pCatIndex As %Integer = 0) As %Status [ Internal ]
{
	kill pTermWeights
	merge pTermWeights = ..%Trace($s(pCatIndex:pCatIndex, 1:+..%Trace))
	quit $$$OK
}

ClassMethod %GetTraceWeightType() As %String [ CodeMode = objectgenerator, Internal ]
{
	if ('%class.Abstract) {
		set tSC =  ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(%class.Name, .tModel)
		quit:$$$ISERR(tSC) tSC
		set tMethod = tModel.ClassificationMethod.method
		do %code.WriteLine("	quit "_$$$QUOTE($case(tMethod, "naiveBayes":"probability", "linearRegression":"additive", :"none")))
	} else {
		do %code.WriteLine("	quit ""none""")
	}
	quit $$$OK
}

ClassMethod %GetScoreType() As %String [ CodeMode = objectgenerator, Internal ]
{
	if ('%class.Abstract) {
		set tSC =  ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(%class.Name, .tModel)
		quit:$$$ISERR(tSC) tSC
		set tMethod = tModel.ClassificationMethod.method
		do %code.WriteLine("	quit "_$$$QUOTE($case(tMethod, "naiveBayes":"probability", :"other")))
	} else {
		do %code.WriteLine("	quit ""other""")
	}
	quit $$$OK
}

/// Returns the term frequency array for a specific source ID
Method %GetTermFreqsForSource(Output pTermFreqs, pSourceId As %Integer, pMode As %String = "", pDomainSpec As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pTermFreqs
		set tMode = $s(pMode="":..Mode, 1:pMode)
		
		//if (tMode="iKnow") {
			set tSC = ..%GetDomainId(pDomainSpec, .tDomainId)
			quit:$$$ISERR(tSC)
			
			$$$CHECKASRCIDEXISTSX(tDomainId,pSourceId,tSrcDetails,vSrcId,tSC)
			
			// build an entity-to-term map
			do ..%GetTerms(.tTermArray)
			set tSC = ..%BuildIKTermMap(tDomainId, .tMap, vSrcId)
			quit:$$$ISERR(tSC)
			set tMap("negation") = ..%ConsidersNegation()
			
			// fetch info for partial matches
			set tSC = ..%GetIKnowDictionaryMapping(.tDictId, .tDictMap)
			quit:$$$ISERR(tSC)
			
			if tDictId {
				set tSC = ##class(%iKnow.Matching.MatchingAPI).MatchSource(tDomainId, pSourceId, $lb(-tDictId))
				quit:$$$ISERR(tSC)
				
				// append to tMap
				set tDictItemId=""
				for {
					set tDictItemId = $order(tDictMap(tDictItemId), 1, tTermPos)
					quit:tDictItemId=""
					set tMap(3, $zabs(tDictItemId)) = $lb(tTermPos)_$li(tTermArray(tTermPos),3,4)
				}
			}
			
			
			set tSC = ..%GetTermFreqsForSourceStatic(tDomainId, pSourceId, .tMap, -tDictId, .pTermFreqs)
			quit:$$$ISERR(tSC)
				
			
		/*} else {
			set tSC = $$$ERROR($$$NotImplemented)
			quit
		}*/
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// pTermInfo("negation") = [has negation]
/// pTermInfo(0, [ent uni id]) = $lb([term id], [negation])
/// pTermInfo(1, [crc uni id]) = $lb([term id], [negation])
/// pTermInfo(2, [cooc id]) = $lb([term id], [negation], $lb([ent uni ids..]))
/// pTermInfo(-2, [ent uni id], [cooc id]) = [negation]
/// pTermInfo(3, [dict item id]) = $lb([term id], [negation], [count])
ClassMethod %GetTermFreqsForSourceStatic(pDomainId As %Integer, pSourceId As %Integer, ByRef pTermInfo, pDictId As %Integer, Output pTermFreqs) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pTermFreqs
		set vSrcId = $s(pSourceId<0:$zabs(pSourceId), 1:0)
		
		// if we need to consider negation, go through the entity occurrences
		if $g(pTermInfo("negation")) {
			set gEntOccId = $$$IKVGLOBNAME(pDomainId,"EntOccId",vSrcId)
			set gCrcOccId = $$$IKVGLOBNAME(pDomainId,"CrcOccId",vSrcId)
			set tSrcDetails = $s(vSrcId:^IRIS.IKV.SrcDetails(pDomainId, vSrcId), 1:^IRIS.IK.SrcDetails(pDomainId, pSourceId))
			set tPartBase = $lg(tSrcDetails,3), tPartEnd = tPartBase+$lg(tSrcDetails,4)
			set tPartId = tPartBase
			for {
				set tPartId = $order(@gEntOccId@(tPartId), 1, tEntOcc)
				quit:tPartId=""
				quit:tPartId<tPartEnd
				
				// BDB577
				continue:$lg(tEntOcc,2)=$$$ENTTYPENONREL
				
				set tEntUniId = $lg(tEntOcc,1), tOK = 0
				if $d(pTermInfo(0, tEntUniId), tTermInfo) {
					set tNegation = $li(tTermInfo,2)
					if (tNegation = "undefined") { set tOK = 1 }
					elseif (tNegation = "none") { set tOK = '##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLANY) }
					elseif (tNegation = "explicit") { set tOK = ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLSENT) }
					elseif (tNegation = "no-explicit") { set tOK = '##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLSENT) }
					elseif (tNegation = "implied") { set tOK = ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLANY) }
					set:tOK x = $i(pTermFreqs($li(tTermInfo,1)))
				}
				
				for tCrcPos = 1:1:3 {
					set tCrcOccId = $lg(tEntOcc,4+tCrcPos)
					continue:tCrcOccId=""
					set tCrcUniId = @gCrcOccId@(tCrcOccId)
					continue:'$d(pTermInfo(1,tCrcUniId), tTermInfo)
					
					set tNegation = $li(tTermInfo,2)
					set tCurrentOK = $g(tCrcMap(tCrcUniId, tCrcOccId))
					if (tNegation = "undefined") { 
						set tOK = 1
					} elseif (tNegation = "none") {
						set:tCurrentOK="" tCurrentOK = 1
						set tOK = tCurrentOK && '##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLANY) 
					} elseif (tNegation = "explicit") { 
						set:tCurrentOK="" tCurrentOK = 0
						set tOK = tCurrentOK || ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLSENT) 
					} elseif (tNegation = "no-explicit") { 
						set:tCurrentOK="" tCurrentOK = 1
						set tOK = tCurrentOK && '##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLSENT) 
					} elseif (tNegation = "implied") { 
						set:tCurrentOK="" tCurrentOK = 0
						set tOK = tCurrentOK || ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLANY) 
					}
					set tCrcMap(tCrcUniId, tCrcOccId) = tOK
				}
				
				set tCoocId = ""
				for {
					set tCoocId = $order(pTermInfo(-2, tEntUniId, tCoocId), 1, tNegation)
					quit:tCoocId=""
					
					set tNegation = $li(tTermInfo,2), tSentId = $li(tEntOcc,3)
					if (tNegation = "undefined") { 
						set tOK = 1
					} elseif (tNegation = "none") {
						set tOK = $s(##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLANY):0, 1:1)
					} elseif (tNegation = "explicit") { 
						set tOK = $s(##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLSENT):1, 1:0)
					} elseif (tNegation = "no-explicit") { 
						set tOK = $s(##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLSENT):0, 1:1)
					} elseif (tNegation = "implied") {
						set tOK = $s(##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION, tEntOcc, vSrcId, $$$IKATTLVLANY):1, 1:0)
					}
					set tCurrentOK = $g(tCoocMap(tCoocId, tSentId, tEntUniId),-1)
					set:(tOK>tCurrentOK) tCoocMap(tCoocId, tSentId, tEntUniId) = tOK
				}
			}
			
			// now process CRCs
			set tCrcUniId = ""
			for {
				set tCrcUniId = $order(tCrcMap(tCrcUniId))
				quit:tCrcUniId=""
				
				set tCrcOccId = ""
				for {
					set tCrcOccId = $order(tCrcMap(tCrcUniId, tCrcOccId), 1, tOK)
					quit:tCrcOccId=""
					continue:'tOK
					set x = $i(pTermFreqs($li(tMap(1,tCrcUniId),1)))
				}
			}
			
			// and cooccurrences
			set tCoocId = ""
			for {
				set tCoocId = $order(tCoocMap(tCoocId))
				quit:tCoocId=""
				set tTermInfo = pTermInfo(2, tCoocId)
				set tNegation = $li(tTermInfo,2)
				set tCoocLength = $l(tCoocId,",")
				set tSentId = ""
				for {
					set tSentId = $order(tCoocMap(tCoocId,tSentId))
					quit:tSentId=""
					set tCount=0, tCoocOK = $s((tNegation="none")||(tNegation="no-explicit"):1, 1:0)
					set tEntUniId=""
					for {
						set tEntUniId = $order(tCoocMap(tCoocId,tSentId,tEntUniId),1,tOK)
						quit:tEntUniId=""
						set tCount=tCount+1
						set tCoocOK = $s((tNegation="none")||(tNegation="no-explicit"):tOK&&tCoocOK, 1:tOK||tCoocOK)
					}
					continue:tCount<tCoocLength
					set:tCoocOK x = $i(pTermFreqs($li(tTermInfo,1)))
				}
			}
			
			
		} else {
		
			// no negation, so we can look into dedicated globals!
			
			// entities first
			if (vSrcId) {
				merge tEntSrcDetails = ^IRIS.IKV.EntUniDetails(pDomainId, vSrcId)
			} else {
				merge tEntSrcDetails = ^IRIS.IK.EntSrcDetails(pDomainId, pSourceId)
			}
			set tEntUniId = ""
			for {
				set tEntUniId = $order(pTermInfo(0, tEntUniId), 1, tTermInfo)
				quit:tEntUniId=""
				set tTermId = $li(tTermInfo,1), tNegation = $li(tTermInfo,2)
				
				continue:'$d(tEntSrcDetails(tEntUniId), tEntDetails)
				set x = $i(pTermFreqs(tTermId), $lg(tEntDetails,1)+$lg(tEntDetails,2))
			}
			
			// then CRCs
			if (vSrcId) {
				merge tCrcSrcDetails = ^IRIS.IKV.CrcUniDetails(pDomainId, vSrcId)
			} else {
				merge tCrcSrcDetails = ^IRIS.IK.CrcSrcDetails(pDomainId, pSourceId)
			}
			set tCrcUniId = ""
			for {
				set tCrcUniId = $order(pTermInfo(1, tCrcUniId), 1, tTermInfo)
				quit:tCrcUniId=""
				set tTermId = $li(tTermInfo,1), tNegation = $li(tTermInfo,2)
				
				continue:'$d(tCrcSrcDetails(tCrcUniId), tCrcDetails)
				set x = $i(pTermFreqs(tTermId), $lg(tCrcDetails,1))
			}
			
			// and cooccurrences
			set tCoocId = ""
			for {
				set tCoocId = $order(pTermInfo(2, tCoocId), 1, tTermInfo)
				quit:tCoocId=""
				set tTermId = $li(tTermInfo,1), tIDs = $li(tTermInfo,3)
				
				set x = $i(pTermFreqs(tTermId), ##class(%iKnow.Queries.SentenceAPI).GetCountByEntityIds(pDomainId, tIDs, $lb(pSourceId), $$$INTERSECT, .tSC))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
		
		
		
		// add frequencies for partial matches
		if (pDictId) {
			// go through individual matches
			set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchesBySourceId(.tMatches, pDomainId, pSourceId, $lb(pDictId), 0, 0)
			quit:$$$ISERR(tSC)
			
			set i = ""
			for {
				set i = $order(tMatches(i), 1, tMatchData)
				quit:i=""
				
				set tDictItemId = $zabs($li(tMatchData,3))
				set tTermInfo = pTermInfo(3, tDictItemId)
				set tTermId = $li(tTermInfo,1)
				set tNegation = $li(tTermInfo,2)
				
				if (tNegation = "undefined") {}
				else {
					set tHasNegations = $lg(tMatchData,15,0)
					if 'tHasNegations {
						// the match does not contain any negations
						continue:(tNegation'="none")
					} elseif (tNegation="implied") {
						// implied covers all sorts of matches, so no need to dig deeper
					} else {
						// now we have to find out the negation type of the matched entities
						set tSC = ##class(%iKnow.Matching.MatchingAPI).GetMatchElements(.tElements, pDomainId, $li(tMatchData,1), vSrcId)
						quit:$$$ISERR(tSC)
						
						set j = "", tOK = $s(tNegation="no-explicit":1, 1:0)
						for {
							set j = $order(tElements(j), 1, tElementData)
							quit:j=""
							set tPartId = $lg(tElementData,2)
							continue:'tPartId
							
							if (tNegation="explicit") {
								if ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION,, vSrcId, $$$IKATTLVLSENT) {
									set tOK = 1
									quit
								}
							} elseif (tNegation="no-explicit") {
								if ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(pDomainId, tPartId, $$$IKATTNEGATION,, vSrcId, $$$IKATTLVLSENT) {
									set tOK = 0
									quit
								}
							}
						}
						continue:'tOK
					}
				}
				
				set x = $i(pTermFreqs(tTermId), $s($li(tTermInfo,3)="partialScore":$li(tMatchData,8), 1:1))
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns the term frequency array for a piece of free text <var>pText</var>, to be indexed using
/// configuration <var>pConfig</var>.
Method %GetTermFreqsForText(Output pTermFreqs, pText As %String, pConfig As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pTermFreqs
		
		if (pConfig = "") {
			set pConfig = $$$DEFAULTCONFIG
		}
		
		// if the configuration does not exist but is a valid language identifier, create it
		if '##class(%iKnow.Configuration).NameIndexExists(pConfig) && $lf($$$IKLANGUAGES, pConfig) {
			set tConfig = ##class(%iKnow.Configuration).%New(pConfig, 0, pConfig)
			set tSC = tConfig.%Save()
			quit:$$$ISERR(tSC)
		}
		
		// if the term frequencies are to be based on matching scores, 
		// add as a virtual source and forward to %GetTermFreqsForSource()
		do ..%GetIKnowDictionaryMapping(.tDictId)
		if tDictId || ..%ConsidersNegation() {
			
			set tDomainName = $s(..DomainId:##class(%iKnow.Domain).%OpenId(..DomainId).Name, 1:"")
			set tSC = $system.iKnow.IndexString(tDomainName, "CategorizationString", pText, pConfig, 1, .vSrcId)
			quit:$$$ISERR(tSC)
			
			set tSC = ..%GetTermFreqsForSource(.pTermFreqs, vSrcId)
			quit:$$$ISERR(tSC)
			
			set tSC = ##class(%iKnow.Source.Loader).DeleteVirtualSource(+..DomainId, vSrcId)
			quit:$$$ISERR(tSC)
			set vSrcId = 0
			
			quit
		}
		
		// initialize indexer object
		if '$isobject(..Indexer) {
			set ..Indexer = ##class(%iKnow.Indexer).%New()
			if '$isobject(..Indexer) {
				set tSC = $$$ERROR($$$IKFailedInitIndexer)
				quit
			}
		}
		
		
		// configure using the supplied configuration (if new)
		if (..CurrentConfig'=pConfig) {
			set tConfig = ##class(%iKnow.Configuration).Open(pConfig, .tSC)
			quit:$$$ISERR(tSC)
			if '$isobject(tConfig) {
				set tSC = $$$ERROR($$$IKConfigurationNotFound, pConfig)
				quit
			}
			
			set tSC = tConfig.ConfigureIndexer(..Indexer)
			quit:$$$ISERR(tSC)
			
			set ..CurrentConfig = pConfig
		}
		
		set tDirectInput = ##class(%DeepSee.PMML.Utils.iKnow.DirectInput).%New(0,0)
		
		set tSC = ..Indexer.ClearBuffer()
		quit:$$$ISERR(tSC)
		
		set tSC = ..Indexer.BufferString(pText)
		quit:$$$ISERR(tSC)
		
		set tSC = ..Indexer.IndexBuffer(tDirectInput)
		quit:$$$ISERR(tSC)
		
		
		// now get the frequencies for all requested terms
		set tSC = ..%GetTermFreqsForDirectInput(.pTermFreqs, tDirectInput)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	// clean up virtual source in case it survived because of an error
	do:$g(vSrcId) ##class(%iKnow.Source.Loader).DeleteVirtualSource(+..DomainId, vSrcId)
	
	quit tSC
}

/// Returns the term frequency array for the text that has been passed through an iKnow indexer
/// configure to return its results to <var>pDirectInput</var>.
Method %GetTermFreqsForDirectInput(Output pTermFreqs, pDirectInput As %DeepSee.PMML.Utils.iKnow.DirectInput) As %Status [ CodeMode = objectgenerator, GenerateAfter = %BuildScores, Internal, Private ]
{
	set tSC = $$$OK
	try {
		if (%class.Abstract) {
			do %code.WriteLine("	quit $$$OK")
			quit
		}
		
		#dim tModel As %iKnow.Classification.Definition.Classifier = %classifierDefinition
		
		do %code.WriteLine("	set tSC = $$$OK")
		do %code.WriteLine("	try {")
		
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		set tTermCount = tModel.TermDictionary.Terms.Count()
		for i = 1:1:tTermCount {
			
			#dim tTerm As %iKnow.Classification.Definition.Term = tModel.TermDictionary.Terms.GetAt(i)
			continue:(tTerm.count'="exactCount")
			
			if (tTerm.type="entity") {
				
				// backwards compatibilty:
				if (tTerm.value'="") {
					$$$WriteLine("set x = $i(pTermFreqs("_i_"), pDirectInput.GetFrequency("_$$$QUOTE(tTerm.value)_"))")
					continue
				}
				
				for j = 1:1:tTerm.Entries.Count() {
					$$$WriteLine("set x = $i(pTermFreqs("_i_"), pDirectInput.GetFrequency("_$$$QUOTE(tTerm.Entries.GetAt(j))_"))")
				}
				
			} elseif (tTerm.type="crc") {
				
				// backwards compatibility
				if (tTerm.value'="") {
					$$$WriteLine("set x = $i(pTermFreqs("_i_"), pDirectInput.GetCrcFrequency("_$$$QUOTE($p(tTerm.value,":",1))_", "_$$$QUOTE($p(tTerm.value,":",2))_", "_$$$QUOTE($p(tTerm.value,":",3))_"))")
					continue
				}
				
				for j = 1:1:tTerm.Entries.Count() {
					set tCRC = tTerm.Entries.GetAt(j)
					$$$WriteLine("set x = $i(pTermFreqs("_i_"), pDirectInput.GetCrcFrequency("_$$$QUOTE(tCRC.Master)_", "_$$$QUOTE(tCRC.Relation)_", "_$$$QUOTE(tCRC.Slave)_"))")
				}
				
			} elseif (tTerm.type="cooccurrence") {
				
				// backwards compatibility
				if (tTerm.value'="") {
					$$$WriteLine("set x = $i(pTermFreqs("_i_"), pDirectInput.GetCoocFrequency($lb("""_$lfs(tTerm.value,""",""")_""")))")
					continue
				}
				
				for j = 1:1:tTerm.Entries.Count() {
					set tCooc = tTerm.Entries.GetAt(j)
					set tValue = ""
					for k = 1:1:tCooc.Entities.Count() {
						set tValue = tValue _ $s(tValue="":"", 1:""", """) _ tCooc.Entities.GetAt(k)
					}
					$$$WriteLine("set x = $i(pTermFreqs("_i_"), pDirectInput.GetCoocFrequency($lb("""_tValue_""")))")
				}
			} 
		}
		
		do %code.WriteLine("	} catch (ex) {")
		do %code.WriteLine("		set tSC = ex.AsStatus()")
		do %code.WriteLine("	}")
		do %code.WriteLine("	quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Returns a vector representing the term weights for the document being categorized, based on
/// the specifications in <xdata>Classifier</xdata>, applying any weighting, negation and other policies.
/// The vector is indexed by the local term IDs as terms they appear in the TermDictionary.
Method %BuildDocumentVector(ByRef pTermFreqs, Output pDocumentVector) As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetTerms, Internal ]
{
	set tSC = $$$OK
	try {
		
		#define WriteLine(%s) do %code.WriteLine($c(9)_%s)
		if %class.Abstract {
			$$$WriteLine("quit $$$OK")
			quit
		}
		
		$$$WriteLine("set tSC = $$$OK")
		$$$WriteLine("try {")
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		$$$WriteLine("kill pDocumentVector")
		
		
		#dim tDefinition As %iKnow.Classification.Definition.Classifier
		set tSC = ##class(%iKnow.Classification.Definition.Classifier).%GetFromDefinition(%class.Name, .tDefinition)
		quit:$$$ISERR(tSC)
		
		set tLocalWeights = tDefinition.ClassificationMethod.localTermWeights
		set tNormalize = tDefinition.ClassificationMethod.normalization
		if $isobject(tDefinition.ClassificationMethod.GlobalTermWeights) {
			set tSC = tDefinition.ClassificationMethod.GlobalTermWeights.ValuesAsArray(.tGlobalWeights)
			quit:$$$ISERR(tSC)
		}
		
		$$$WriteLine("// transform term frequencies into weights.")
		$$$WriteLine("// local weights: "_tLocalWeights)
		for i = 1:1:tDefinition.TermDictionary.Terms.Count() {
			
			set tWeight = "$g(pTermFreqs("_i_"),0)"
			if (tLocalWeights = "binary") {
				set tWeight = "(''"_tWeight_")"
			} elseif (tLocalWeights = "logarithmic") {
				set tWeight = "$zlog(1+"_tWeight_")"
			}
			
			if $d(tGlobalWeights(i), tGlobalWeight) {
				set tWeight = tWeight _ " * " _ tGlobalWeight
			}
			
			if (tNormalize="none") {
				$$$WriteLine("set pDocumentVector("_i_") = "_tWeight)
			} else {
				$$$WriteLine("set pDocumentVector("_i_") = "_tWeight_", tNorm = tNorm + (("_tWeight_")**2)")
			}
		}
		
		$$$WriteLine("// normalize: "_tNormalize)
		if (tNormalize'="none") {
			$$$WriteLine("set i = """", tNorm = $zsqr(tNorm)")
			$$$WriteLine("for {")
			$$$WriteLine("	set i = $order(pDocumentVector(i),1,tWeight")
			$$$WriteLine("	quit:i=""""")
			$$$WriteLine("	set pDocumentVector(i) = tWeight / tNorm")
			$$$WriteLine("}")
			$$$WriteLine("")
		}
		
		// TODO: append metadata
		
		
		#define WriteLine(%s) do %code.WriteLine($c(9)_%s)
		$$$WriteLine("} catch (ex) {")
		$$$WriteLine("	set tSC = ex.AsStatus()")
		$$$WriteLine("}")
		$$$WriteLine("quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This method runs the Text Categorization model defined in <xdata>Classifier</xdata> against
/// the document identified by <var>pSourceId</var>. When this method returns, <var>pCategories</var>
/// will contain all candidate categories for this document, sorted by decreasing score:
/// 		pCategories(n) = $lb([category name], [score])
/// The entry with the highest score (pCategories(1)) is this model's best prediction.</p>
/// <p>If this Classifier instance has not been
/// initialized with a reference to an iKnow or other domain, supply <var>pMode</var>="iKnow" and
/// the domain name as <var>pDomainSpec</var> to point this classifier to the right location.</p>
Method %Categorize(Output pCategories, pSourceId As %Integer, pMode As %String = "", pDomainSpec As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		kill pCategories
		
		set tSC = ..%GetTermFreqsForSource(.tTermFreqs, pSourceId, pMode, pDomainSpec)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%BuildDocumentVector(.tTermFreqs, .tDocVector)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%BuildScores(.tDocVector, .tScores)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%BuildResult(.tScores, .pCategories)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// <p>This method runs the Text Categorization model defined in <xdata>Classifier</xdata> against
/// the free text <var>pText</var>. When this method returns, <var>pCategories</var>
/// will contain all candidate categories for this document, sorted by decreasing score:
/// 		pCategories(n) = $lb([category name], [score])
/// The entry with the highest score (pCategories(1)) is this model's best prediction.</p>
/// <p>Optionally a <class>%iKnow.Configuration</class>'s name can be passed in through 
/// <var>pConfig</var> to override the default configuration to use when indexing the text,
/// for example to use a language model other than the default English (or automatically detect
/// the right language to use).</p>
Method %CategorizeText(Output pCategories, pText As %String = "", pConfig As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		kill pCategories
		
		set tSC = ..%GetTermFreqsForText(.tTermFreqs, pText, pConfig)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%BuildDocumentVector(.tTermFreqs, .tDocVector)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%BuildScores(.tDocVector, .tScores)
		quit:$$$ISERR(tSC)
		
		set tSC = ..%BuildResult(.tScores, .pCategories)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Static method to categorize a text fragment, returning the most likely category the text belongs to.
/// See also <method>%CategorizeText</method>
ClassMethod %CategorizeSQL(pText As %String = "", pConfig As %String = "", Output pSC As %String = "") As %String [ SqlProc ]
{
	set tSC = $$$OK, tCategory = ""
	try {
		
		set tClassifier = ..%New()
		set tSC = tClassifier.%CategorizeText(.tCategories, pText, pConfig)
		quit:$$$ISERR(tSC)
		
		// select winning category name
		set tCategory = $lg($g(tCategories(1)),1)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set pSC = $system.Status.GetErrorText(tSC)
	quit tCategory
}

/// transforms the result of <method>%BuildScores</method> into the array returned by 
/// <method>%Categorize</method> and <method>%CategorizeText</method>
Method %BuildResult(ByRef pScores, Output pResult) As %Status [ Internal, Private ]
{
	set tSC = $$$OK
	try {
		kill pResult
		
		set tSC = ..%GetCategories(.tCats)
		quit:$$$ISERR(tSC)
		
		set tScore = "", tWinner=0
		for {
			set tScore = $order(pScores(tScore), -1)
			quit:tScore=""
			
			set tCatId = ""
			for {
				set tCatId = $order(pScores(tScore,tCatId))
				quit:tCatId=""
				
				set:'tWinner tWinner = tCatId
				set pResult($i(pResult)) = $lb($li(tCats(tCatId),1), +tScore)
			}
		}
		set ..%Trace = tWinner
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Builds a sorted array with the scores for each category (higher scores are better scores):
/// 			pScores([score], [categoryID]) = ""
Method %BuildScores(ByRef pDocumentVector, Output pScores) As %Status [ CodeMode = objectgenerator, GenerateAfter = %GetIKnowDictionaryMapping, Internal, Private ]
{
	set tSC = $$$OK
	try {
		
		#define WriteLine(%s) do %code.WriteLine($c(9)_%s)
		if %class.Abstract {
			$$$WriteLine("quit $$$OK")
			quit
		}
		
		$$$WriteLine("set tSC = $$$OK")
		$$$WriteLine("try {")
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		$$$WriteLine("kill pScores")
		
		
		#dim tDefinition As %iKnow.Classification.Definition.Classifier = %classifierDefinition
		set tMethod = tDefinition.ClassificationMethod.method
		if (tMethod="naiveBayes") {
			set tSC = ..%GenBuildScoresNaiveBayes(tDefinition)
		} elseif (tMethod="cosineSimilarity") || (tMethod="euclideanDistance") {
			set tSC = ..%GenBuildScoresVector(tDefinition)
		} elseif (tMethod="linearRegression") {
			set tSC = ..%GenBuildScoresRegression(tDefinition)
		} elseif (tMethod="pmml") {
			set tSC = ..%GenBuildScoresPMML(tDefinition)
		} elseif (tMethod="rules") {
			set tSC = ..%GenBuildScoresRules(tDefinition)
		} else {
			set tSC = $$$ERROR($$$NotImplemented)
		}
		quit:$$$ISERR(tSC)
		
		#define WriteLine(%s) do %code.WriteLine($c(9)_%s)
		$$$WriteLine("} catch (ex) {")
		$$$WriteLine("	set tSC = ex.AsStatus()")
		$$$WriteLine("}")
		$$$WriteLine("quit tSC")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GenBuildScoresPMML(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		// first create a PMML definition class based on the wrapped XML
		set tClassifierClassName = %class.Name
		set tPMMLClassName = tClassifierClassName_".PMML"
		set:$$$defClassDefined(tPMMLClassName) tSC = $$Delete^%apiOBJ(tPMMLClassName,"-d")
		set tPMMLClass = ##class(%Dictionary.ClassDefinition).%New()
		set tPMMLClass.Name = tPMMLClassName
		set tPMMLClass.Super = "%DeepSee.PMML.Definition"
		set tPMMLClass.GeneratedBy = tClassifierClassName
		set tXData = ##class(%Dictionary.XDataDefinition).%New()
		set tXData.Name = "PMML"
		set tXData.XMLNamespace = "http://www.intersystems.com/deepsee/pmml"
	    set tSC = pDefinition.ClassificationMethod.PMML.%ToString(.tString)
	    quit:$$$ISERR(tSC)
	    set tSC = tXData.Data.Write(tString)
	    quit:$$$ISERR(tSC)
		do tPMMLClass.XDatas.Insert(tXData)
		set tSC = tPMMLClass.%Save()
		quit:$$$ISERR(tSC)
        do QueueClass^%occCompile(tPMMLClassName)
		$$$comClassArraySet(tClassifierClassName,$$$cCLASSclasses,tPMMLClassName_".CLS","")
        $$$defClassKeySet(tPMMLClassName,$$$cCLASSgeneratedby,tClassifierClassName_".CLS")
		
		$$$WriteLine("// convert pDocumentVector into PMML input object")
		$$$WriteLine("kill tInput")
		$$$WriteLine("set i = """"")
		$$$WriteLine("for {") 
		$$$WriteLine("	set i = $order(pDocumentVector(i),1,tValue)")
		$$$WriteLine("	quit:i=""""")
		$$$WriteLine("	set tInput(##class(%iKnow.Classification.Builder).GetColumnName(i)) = tValue")
		$$$WriteLine("}")
		
		$$$WriteLine("")
		$$$WriteLine("// execute model")
		$$$WriteLine("set tSC = ##class("_tPMMLClassName_").%GetModelInstance("_$$$QUOTE(pDefinition.ClassificationMethod.PMML.Models.GetAt(1).modelName)_", .tModel)")
		$$$WriteLine("quit:$$$ISERR(tSC)")
		$$$WriteLine("set tSC = tModel.%ExecuteModel(.tInput, .tOutput)")
		$$$WriteLine("quit:$$$ISERR(tSC)")
		
		$$$WriteLine("")
		
		set tCase = "$case(tPredictedValue"
		for i = 1:1:pDefinition.Categories.Count() {
			set tCase = tCase _ ", "_$$$QUOTE(pDefinition.Categories.GetAt(i).name)_":"_i
		}
		
		// check if the model supports outputting probabilities
		if pDefinition.ClassificationMethod.PMML.Models.GetAt(1).%IsOutputFeatureSupported("probability","dummy") {
			$$$WriteLine("// convert PMML output into score list")
			for i = 1:1:pDefinition.Categories.Count() {
				$$$WriteLine("set:tOutput.Cat"_i_"Score'="""" pScores(tOutput.Cat"_i_"Score, "_i_") = """"")
			}
		} else {
			$$$WriteLine("// model only supports target value")
		}
		set tCase = tCase_")"
		$$$WriteLine("if '$d(pScores) {")
		$$$WriteLine("	set tPredictedValue = tOutput.%GetFeatureValue(""predictedValue"")")
		$$$WriteLine("	set:tPredictedValue'="""" pScores(1, "_tCase_") = """"")
		$$$WriteLine("}")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GenBuildScoresRules(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		#dim tRule As %iKnow.Classification.Definition.Rule
		#dim tRuleSet As %iKnow.Classification.Definition.ClassificationRules = pDefinition.ClassificationMethod.ClassificationRules
		
		for i = 1:1:pDefinition.Categories.Count() {
			set tCats(pDefinition.Categories.GetAt(i).name) = i
		}
		
		set tRuleCount = tRuleSet.Rules.Count()
		for i = 1:1:tRuleCount {
			set tRule = tRuleSet.Rules.GetAt(i)
			$$$WriteLine("")
			$$$WriteLine("// Rule #"_i_" >> "_tRule.category)
			if $isobject(tRule.Predicate) {
				$$$WriteLine("if "_tRule.Predicate.%GenerateCode()_" {")
			} else {
				$$$WriteLine("if 1 {")
			}
			
			$$$WriteLine("	set pScores("_tRule.score_", "_tCats(tRule.category)_") = """"")
			
			if (tRuleSet.ruleSelectionMethod="firstHit") {
				$$$WriteLine("quit")
			}
			
			$$$WriteLine("}")
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GenBuildScoresRegression(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		set tSC = pDefinition.ClassificationMethod.CategoryTermWeights.ValuesAsArray(.tMatrix)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(tMatrix(i))
			quit:i=""
			
			$$$WriteLine("// score for category "_i)
			$$$WriteLine("set tScore = 0")
			
			set j = ""
			for {
				set j = $order(tMatrix(i,j), 1, tCoefficient)
				quit:j=""
				continue:'tCoefficient
				$$$WriteLine("set tScore = tScore + ("_tCoefficient_" * $g(pDocumentVector("_j_"),0))")
			}
			
			$$$WriteLine("set pScores(tScore, "_i_") = """"")
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GenBuildScoresNaiveBayes(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		$$$WriteLine("kill ..%Trace")
		
		set tSC = pDefinition.ClassificationMethod.CategoryWeights.ValuesAsArray(.tCatWeights)
		quit:$$$ISERR(tSC)
		set tSC = pDefinition.ClassificationMethod.CategoryTermWeights.ValuesAsArray(.tMatrix)
		quit:$$$ISERR(tSC)
		
		set tVerySmall = 1E-6
		set tAlmost1 = 1-tVerySmall
		set tAlmost0 = tVerySmall
		
		set i = ""
		for {
			set i = $order(tMatrix(i))
			quit:i=""
			
			$$$WriteLine("// probability for category "_i)
			$$$WriteLine("set tEta = 0")
			
			set j = ""
			for {
				set j = $order(tMatrix(i,j), 1, tEntProb)
				quit:j=""
				set:tEntProb>tAlmost1 tEntProb = 1 - tVerySmall
				set:tEntProb<tAlmost0 tEntProb = tVerySmall
				set tContribution = $zln(1-tEntProb)-$zln(tEntProb)
				$$$WriteLine("set:$g(pDocumentVector("_j_"),0) tEta = tEta + "_tContribution_", ..%Trace("_i_","_j_") = "_tEntProb)
			}
			$$$WriteLine("set tScore = $s(tEta>335.6:0, 1:(1 / (1 + $zexp(tEta))) * "_tCatWeights(i)_")")
			
			$$$WriteLine("set pScores(tScore, "_i_") = """"")
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GenBuildScoresVector(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		#define WriteLine(%s) do %code.WriteLine($c(9,9)_%s)
		
		set tSC = pDefinition.ClassificationMethod.CategoryTermWeights.ValuesAsArray(.tMatrix)
		quit:$$$ISERR(tSC)
		
		set tSimilarity = pDefinition.ClassificationMethod.method
		
		if (tSimilarity="cosineSimilarity") {
			
			// first calculate the document norm if it hasn't already been normalized
			if (pDefinition.ClassificationMethod.normalization = "none") {
				$$$WriteLine("// document vector normalization")
				$$$WriteLine("set i = """", tDocNorm = 0")
				$$$WriteLine("for {")
				$$$WriteLine("	set i = $order(pDocumentVector(i), 1, tWeight)")
				$$$WriteLine("	quit:i=""""")
				$$$WriteLine("	set tDocNorm = tDocNorm + (tWeight**2)")
				$$$WriteLine("}")
				$$$WriteLine("set tDocNorm = $zsqr(tDocNorm)")
				$$$WriteLine("quit:'tDocNorm")
			} else {
				$$$WriteLine("// document vector is already normalized")
				$$$WriteLine("set tDocNorm = 1")
			}
		
			set i = ""
			for {
				set i = $order(tMatrix(i))
				quit:i=""
				
				$$$WriteLine("// score for category "_i)
				$$$WriteLine("set tDotProduct = 0, tCatNorm = 0")
				set j = ""
				for {
					set j = $order(tMatrix(i,j), 1, tCatValue)
					quit:j=""
					$$$WriteLine("set tDotProduct = tDotProduct + ("_tCatValue_" * $g(pDocumentVector("_j_"),0)), tCatNorm = tCatNorm + "_(tCatValue**2))
				}
				$$$WriteLine("set pScores(tDotProduct / ($zsqr(tCatNorm) * tDocNorm), "_i_") = """"")
			}
			
		} elseif (tSimilarity = "euclideanDistance") {
			
			set i = "", tTerms = $li(tMatrix,2)
			for {
				set i = $order(tMatrix(i))
				quit:i=""
				
				$$$WriteLine("// score for category "_i)
				$$$WriteLine("set tDistance = 0")
				for j = 1:1:tTerms {
					$$$WriteLine("set tDistance = tDistance + (("_$g(tMatrix(i,j),0)_" - $g(pDocumentVector("_j_"),0))**2)")
				}
				$$$WriteLine("set pScores(-$zsqr(tDistance), "_i_") = """"")
			}
			
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %ConsidersNegation() As %Boolean [ CodeMode = objectgenerator, ForceGenerate, GenerateAfter = %BuildIKTermMap, Internal ]
{
	set tConsidersNegation = 0
	if '%class.Abstract {
		#dim tDefinition As %iKnow.Classification.Definition.Classifier = %classifierDefinition
		
		if $isobject(tDefinition.TermDictionary) {
			for i = 1:1:tDefinition.TermDictionary.Terms.Count() {
				continue:tDefinition.TermDictionary.Terms.GetAt(i).negation="undefined"
				set tConsidersNegation = 1
				quit
			}
		}
	}
	do %code.WriteLine("	quit "_tConsidersNegation)
	quit $$$OK
}

ClassMethod %GetIKnowDictionaryMapping(Output pDictionaryId As %Integer, Output pDictionaryMap) As %Status [ CodeMode = objectgenerator, GenerateAfter = %ConsidersNegation, Internal ]
{
	set tSC = $$$OK
	try {
		
		do %code.WriteLine("	kill pDictionaryMap")
		
		if %class.Abstract {
			do %code.WriteLine("	quit $$$OK")
			quit
		}
		
		#dim tDefinition As %iKnow.Classification.Definition.Classifier = %classifierDefinition
		
		set tDictName = "@TC@"_%class.Name
		set tDictId = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryId(0, tDictName)
		if (tDictId<=0) {
			if $d(%classifierDictTerms) {
				set tSC = ..%GetMatchingProfileId(.tProfileId)
				quit:$$$ISERR(tSC)
				set tDefaultLanguage = tDefinition.TermDictionary.defaultLanguage
				set:tDefaultLanguage="" tDefaultLanguage = "en"
				set tDictId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryInternal(0, tDictName, "Categorization dictionary for classifier class "_$classname(), tDefaultLanguage, tProfileId, "%iKnow.Classification.Classifier", .tSC)
				quit:$$$ISERR(tSC)
			} else {
				set tDictId = 0
			}
		} elseif '$d(%classifierDictTerms) {
			// drop a dictionary generated for a previous incarnation of this class if no
			// new terms exist
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(0, tDictId)
			quit:$$$ISERR(tSC)
			set tDictId = 0
		}
		do %code.WriteLine("	set pDictionaryId = "_tDictId)
		
		// build a list of all existing items & terms
		set:tDictId tSC = ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemsAndTerms(.tItems, 0, tDictId, 0, 0)
		quit:$$$ISERR(tSC)
		set i = ""
		for {
			set i = $order(tItems(i), 1, tItemInfo)
			quit:i=""
			
			set tItemId = $li(tItemInfo,1), tClassifierIndex = +$p($li(tItemInfo,3),":",3)
			set tTermId = $li(tItemInfo,4), tTermValue = $li(tItemInfo,5)
			
			set tExisting(tClassifierIndex) = tItemId
			set tExisting(tClassifierIndex, tTermValue) = ""
			set x = $i(tExisting(tClassifierIndex, $c(0)))
		}
		
		kill tTerms
		merge tTerms = %classifierDictTerms
		set tSC = ..%UpdateIKnowDictionary(0, tDictId, .tTerms, .tExisting, .tMap)
		quit:$$$ISERR(tSC)
		
		set tItemId = ""
		for {
			set tItemId = $order(tMap(tItemId), 1, tTermPos)
			quit:tItemId=""
			do %code.WriteLine("	set pDictionaryMap("_tItemId_") = "_tTermPos)
		}
		
		do %code.WriteLine("	quit $$$OK")
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %UpdateIKnowDictionary(pDomainId As %Integer = 0, pDictId As %Integer, ByRef pTerms, ByRef pExisting, Output pMap) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill pMap
		
		#dim tTerm As %iKnow.Classification.Definition.Term
		
		set i = ""
		for {
			set i = $order(pTerms(i), 1, tTerm)
			quit:i=""
			
			// if the term exists, verify it's exactly the same
			set tNewTermCount = $s(tTerm.value'="":1, 1:tTerm.Entries.Count())
			set tIsSame = $d(pExisting(i, $c(0)), tExistingTermCount) && (tNewTermCount = tExistingTermCount)
			if tIsSame {
				if (tTerm.value'="") {
					if (tTerm.type="entity") {
						set tIsSame = $d(pExisting(i, tTerm.value))
					} elseif (tTerm.type="crc") {
						set tIsSame = $d(pExisting(i, $tr(tTerm.value,":"," ")))
					} elseif (tTerm.type="cooccurrence") {
						set tIsSame = $d(pExisting(i, $replace(tTerm.value,":",", ")))
					}
				} elseif (tTerm.type="entity") {
					for j = 1:1:tNewTermCount {
						set tIsSame = $d(pExisting(i, tTerm.Entries.GetAt(j)))
						quit:'tIsSame
					}
				} elseif (tTerm.type="crc") {
					for j = 1:1:tNewTermCount {
						set tCRC = tTerm.Entries.GetAt(j)
						set tIsSame = $d(pExisting(i, tCRC.Master_" "_tCRC.Relation_" "_tCRC.Slave))
						quit:'tIsSame
					}
				} elseif (tTerm.type="cooccurrence") {
					for j = 1:1:tNewTermCount {
						set tCooc = tTerm.Entries.GetAt(j)
						set tValue = ""
						for k = 1:1:tCooc.Entities.Count() { 
							set tValue = tValue _ $s(tValue="":"", 1:", ") _ tCooc.Entities.GetAt(k) 
						}
						set tIsSame = $d(pExisting(i, tValue))
						quit:'tIsSame
					}
				}
			}
			
			// if this was really the same as before, store mapping and continue
			if (tIsSame) {
				set pMap(pExisting(i)) = i
				continue
			}
			
			// otherwise drop and recreate
			set:$d(pExisting(i), tItemId) tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryItem(pDomainId, tItemId)
			quit:$$$ISERR(tSC)
			
			set tItemURI = ":"_pDictId_":"_i_":", x=tItemURI,y=""
			while ##class(%iKnow.Matching.DictionaryAPI).GetDictionaryItemIdByURI(pDomainId, tItemURI) {
				set tItemURI = x_$i(y)
			}
			set tItemId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryItem(pDomainId, pDictId, tItemURI, tItemURI,, .tSC)
			quit:$$$ISERR(tSC)
			
			if (tTerm.type="entity") {
				if (tTerm.value'="") {
					set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, tTerm.value,, .tSC)
					quit:$$$ISERR(tSC)
				} else {
					for j = 1:1:tNewTermCount {
						set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, tTerm.Entries.GetAt(j),, .tSC)
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
			} elseif (tTerm.type="crc") {
				if (tTerm.value'="") {
					set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, $replace(tTerm.value,":"," "),, .tSC)
					quit:$$$ISERR(tSC)
				} else {
					for j = 1:1:tNewTermCount {
						set tCRC = tTerm.Entries.GetAt(j)
						set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, tCRC.Master_" "_tCRC.Relation_" "_tCRC.Slave,, .tSC)
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
			} elseif (tTerm.type="cooccurrence") {
				if (tTerm.value'="") {
					set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, $replace(tTerm.value,":",", "),, .tSC)
					quit:$$$ISERR(tSC)
				} else {
					for j = 1:1:tNewTermCount {
						set tCooc = tTerm.Entries.GetAt(j)
						set tValue = ""
						for k = 1:1:tCooc.Entities.Count() { 
							set tValue = tValue _ $s(tValue="":"", 1:", ") _ tCooc.Entities.GetAt(k) 
						}
						set tTermId = ##class(%iKnow.Matching.DictionaryAPI).CreateDictionaryTerm(pDomainId, tItemId, tValue,, .tSC)
						quit:$$$ISERR(tSC)
					}
					quit:$$$ISERR(tSC)
				}
			}
			
			set pMap(tItemId) = i
		}
		
		// clean up remaining items
		set tNextIndex = $g(pTerms)
		for {
			set tNextIndex = $order(pExisting(tNextIndex), 1, tItemId)
			quit:tNextIndex=""
			
			set tSC = ##class(%iKnow.Matching.DictionaryAPI).DropDictionaryItem(pDomainId, tItemId)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %DropManagedDictionary(pDictionaryId As %Integer) As %Status [ Internal ]
{
	quit ##class(%iKnow.Matching.DictionaryAPI).DropDictionary(0, pDictionaryId)
}

ClassMethod %GetMatchingProfileId(Output pProfileId As %Integer) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tProfileName = "Term Categorization Profile - do not edit"
		set tProfile = ##class(%iKnow.Matching.MatchingProfile).GetProfileByName(0, tProfileName)
		set:'$isobject(tProfile) tProfile = ##class(%iKnow.Matching.MatchingProfile).%New(0, tProfileName)
		set tProfile.MinimalMatchScore = 0
		set tProfile.MinTermLengthForPath = 2
		set tProfile.MinTermLengthForSent = 2
		set tProfile.PathTotalMultiplier = 10
		set tProfile.SentTotalMultiplier = 10
		set tProfile.CrcTotalMultiplier = 10
		set tProfile.DisorderMultiplier = 1
		set tProfile.MinMatchedConceptFraction = 1
		set tSC = tProfile.%Save()
		quit:$$$ISERR(tSC)
		
		set pProfileId = tProfile.ProfileId
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
