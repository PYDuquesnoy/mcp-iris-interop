/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
///  Main Query API for retrieving sources and related information.
Class %iKnow.Queries.SourceAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

///  <p>Retrieves the external ID for the source identified by <i>srcId</i>.</p>
///  <p>A negative srcId is considered to refer to a Virtual Source.</p>
ClassMethod GetExternalId(domainid As %Integer, srcId As %Integer, Output sc As %Status = {$$$OK}) As %String
{
	$$$IKCHECKPRIVREADR(sc,"")
	$$$CHECKDOMAINEXISTSR(domainid,sc,"")
	set vSrcId = $s(srcId<0:-srcId, 1:0), sc = $$$OK
	if (vSrcId) {
		set vSrcData = $g(^IRIS.IKV.SrcId(domainid, vSrcId))
		if (vSrcData="") { set sc = $$$ERROR($$$IKVirtualSourceNotFound, vSrcId)  quit "" }
		set composite = $lg(vSrcData,3)
	} else {
		set composite = $g(^IRIS.IK.SrcId(domainid, srcId))
	}
	if (composite="") { set sc = $$$ERROR($$$IKSourceDoesNotExist, srcId)  quit "" }
	quit:$$$SIMPLEEXTIDS(domainid) $lg(composite,3)
	quit ##class(%iKnow.Source.Lister).BuildExtId(domainid,$lg(composite),$lg(composite,2),$lg(composite,3),.sc)
}

///  <p>Retrieves the source ID for the source identified by <i>externalId</i>.</p>
ClassMethod GetSourceId(domainid As %Integer, externalId As %String, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	
	// Code for composite external IDs
	set listerId = 0, groupId = 0, localRef = externalId, sc = $$$OK
	if (externalId="") { set sc = $$$ERROR($$$IKSourceDoesNotExistE, externalId)  quit "" }
	
	// if this is a SimpleExtId domain, we can continue with the above starting values
	if '$$$SIMPLEEXTIDS(domainid) {
		set sc = ##class(%iKnow.Source.Lister).SplitExtId(domainid,externalId,.listerId,.groupId,.localRef)
		quit:$$$ISERR(sc) ""
	}
	
	// now that we have the localRef, find the matching srcId
	if ($length(localRef)'>$$$IKHASHSIZE) {
		set srcId = $g(^IRIS.IK.Ext.LocalRef(domainid, listerId, groupId, localRef))
	} else {
		// Have to hash it to find localRef
		Set srcId = "", hash = $ZCRC(localRef,7)
		For {
		    Set srcId=$order(^IRIS.IK.Ext.LocalRefHash(domainid, listerId, groupId, hash, srcId))
			Quit:srcId=""
			Quit:localRef=$lg($g(^IRIS.IK.SrcId(domainid, srcId)),3)
		}
	}
	if (srcId="") { set sc = $$$ERROR($$$IKSourceDoesNotExistE, externalId) }
	Quit srcId
}

///  <p>Retrieves the Full Reference for the source identified by <i>srcId</i>.</p>
///  <p>A negative srcId is considered to refer to a Virtual Source.</p>
ClassMethod GetFullReference(domainId As %Integer, srcId As %Integer, Output sc As %Status = {$$$OK}) As %String
{
	$$$IKCHECKPRIVREADR(sc,"")
	$$$CHECKDOMAINEXISTSR(domainId,sc,"")
	set vSrcId = $s(srcId<0:-srcId, 1:0), sc = $$$OK
	if (vSrcId) {
		set vSrcData = $g(^IRIS.IKV.SrcId(domainId, vSrcId))
		if (vSrcData="") { set sc = $$$ERROR($$$IKVirtualSourceNotFound, vSrcId)  quit "" }
		set composite = $lg(vSrcData,3)
	} else {
		set composite = $g(^IRIS.IK.SrcId(domainId, srcId))
	}
	if (composite="") { set sc = $$$ERROR($$$IKSourceDoesNotExist, srcId)  quit "" }
	quit:$$$SIMPLEEXTIDS(domainId) $lg(composite,3)
	quit ##class(%iKnow.Source.Lister).BuildFullRefFromComposite(domainId,composite,.sc)
}

Parameter GetSummaryForTextRT = "sentId:%Integer,sentenceValue:%String,sentenceIsTruncated:%Boolean";

///  <p>This method returns the most relevant sentences of the supplied text, in their original order.
///  The number of sentences returned is controlled by the <var>length</var> parameter.</p>
/// <p>Note: the value of <var>pDomainId</var> is ignored since 2013.2</p>
ClassMethod GetSummaryForText(ByRef pResult, pDomainId As %Integer = 0, pText As %String(MAXLEN=32000), pLength As %Integer = 5, pSummaryConfig As %String = "", pLanguage As %String = "en", pUserDict As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		set tLoader = ##class(%iKnow.Source.Loader).%New(0)
		set fullRef = "GetSummaryForText"
			
		set tSC = tLoader.BufferSource(fullRef, pText)
		quit:$$$ISERR(tSC)
		
		set tConfig = "GetSummaryForText:"_pLanguage_":"_$zcrc(pUserDict,7)
		if '##class(%iKnow.Configuration).Exists(tConfig){
			set tSC = ##class(%iKnow.Configuration).%New(tConfig,0,$lb(pLanguage), pUserDict).%Save() 
			quit:$$$ISERR(tSC)
		}
		set tSC = tLoader.ProcessVirtualBuffer(tConfig)
		quit:$$$ISERR(tSC)
		
		set tSrcId = $lg(tLoader.GetSourceIds())
			
	    set tSC = ..GetSummary(.pResult,0, -tSrcId, pLength , pSummaryConfig)
	    
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	do:$g(tSrcId) ##class(%iKnow.Source.Loader).DeleteVirtualSource(0, tSrcId)
	quit tSC
}

/// sentIdToScore(sentId) = summaryScore
ClassMethod GetSummaryHelper(ByRef sentIdToScore, domainId As %Integer, srcId As %Integer, ByRef wordFreqConfig) As %Status [ Internal ]
{
	kill sentIdWordCount
	kill srcDetail
	kill EntUniId
	kill entSrcDetail
	kill sentIdDomVal
	kill sentIdFreq
	
	set status = $$$OK
	
	try{
		
		set vSrcId = 0
		if srcId > 0{
			set srcDetail = ^IRIS.IK.SrcDetails(domainId, srcId)
			if $$$GETPARAM(domainId,$$$IKPSTEMMING,0) = 0{
				merge entSrcDetail = ^IRIS.IK.EntSrcDetails(domainId,srcId) 
				set tEntUniId = ""
				for {
					set tEntUniId = $order(entSrcDetail(tEntUniId))
					quit:tEntUniId=""
					set EntUniId(tEntUniId) = ^IRIS.IK.EntUniId(domainId,tEntUniId)
				}
			}
			else{
				merge entSrcDetail = ^IRIS.IK.StemSrcDetails(domainId,srcId)
				set tEntUniId = ""
				for {
					set tEntUniId = $order(entSrcDetail(tEntUniId))
					quit:tEntUniId=""
					set EntUniId(tEntUniId) = ^IRIS.IK.StemUniId(domainId,tEntUniId)
				}
			}
		}
		else{
			set vSrcId = -srcId
			set srcDetail = ^IRIS.IKV.SrcDetails(domainId, vSrcId)
			if $$$GETPARAM(domainId,$$$IKPSTEMMING,0) = 0{
				merge EntUniId = ^IRIS.IKV.EntUniId(domainId, vSrcId)
				merge entSrcDetail = ^IRIS.IKV.EntUniDetails(domainId, vSrcId) 
			}
			else{
				merge EntUniId = ^IRIS.IKV.StemUniId(domainId,vSrcId)
				merge entSrcDetail = ^IRIS.IKV.StemUniDetails(domainId,vSrcId)
			}
		}
		
		set sentStart = $list(srcDetail,1)
		set sentCount = $list(srcDetail,2)
		for i=1:1:sentCount{
			set sentId = sentStart + i
			set sentIdDomVal(sentId) = 0
			set sentIdFreq(sentId) = 0
			
			set sentValue = ##class(%iKnow.Queries.SentenceAPI).GetValue(domainId, sentId, .fullSentence, vSrcId)
			for j = 1:1:$length(sentValue," "){
				set word = $piece(sentValue," ",j)
				try{
					set score = wordFreqConfig(word)
					if (score = $$$IKMAXWORDSCORE){
						set sentIdDomVal(sentId) = $$$IKMAXWORDSCORE 
					}
					elseif score = $$$IKMINWORDSCORE{
						if sentIdDomVal(sentId) '= $$$IKMAXWORDSCORE{
							set sentIdDomVal(sentId) = $$$IKMINWORDSCORE 
						}
					}
					else{
						set sentIdFreq(sentId) = sentIdFreq(sentId) + score 
					}
				}
				catch
				{
				}
			}
		}
		
		set entOccBase = $list(srcDetail,3)
		set entOccCount = $list(srcDetail,4)
		
		for i=1:1:entOccCount
		{
			set entOccId = entOccBase + i
			if srcId > 0 { 
				set entDetail = ^IRIS.IK.EntOccId(domainId, entOccId)
			}
			else{
				set entDetail = ^IRIS.IKV.EntOccId(domainId,-srcId,entOccId)
			}
			
			if ($listget(entDetail,2,-1) = $$$ENTTYPECONCEPT) && ($listget(entDetail,8,0) '= 0) 
			{
				///^IRIS.IK.EntSrcDetails(domainId,srcId,entUniId)=$lb(conceptFreqInSrc,relationFreqInSrc,conceptSemDom,relationSemDom)
				///^IRIS.IK.StemSrcDetails(domainId,srcId,stemUniId)=$lb(conceptFreqInSrc,relationFreqInSrc,conceptSemDom,relationSemDom)   
				///^IRIS.IKV.EntUniDetails(domainId,vSrcId,vEntUniId) = $lb(conceptFreq, relationFreq, realEntUniId, conceptDominance, relationDominance)
				///^IRIS.IKV.StemUniDetails(domainId,vSrcId,vStemUniId) = $lb(conceptFreq, relationFreq, realStemUniId, conceptDominance, relationDominance)
	
				if $$$GETPARAM(domainId,$$$IKPSTEMMING,0) = 0{
					set words = EntUniId($list(entDetail,1))
					set entSrcDetailList = entSrcDetail($list(entDetail,1))
				}
				else{
					// stemEntUniId
					set words = EntUniId($list(entDetail,10))
					set entSrcDetailList = entSrcDetail($list(entDetail,10))
				}
				if $listlength(entSrcDetailList) = 4 {
					set conceptDom = $list(entSrcDetailList,3)
				}
				else{
					set conceptDom = $list(entSrcDetailList,4)
				} 
				if (sentIdDomVal($list(entDetail,3)) '= $$$IKMAXWORDSCORE) && (sentIdDomVal($list(entDetail,3)) '= $$$IKMINWORDSCORE){		
					set sentIdDomVal($list(entDetail,3)) = sentIdDomVal($list(entDetail,3)) + conceptDom	 
				}
			}		
		}
			
		for i=1:1:sentCount{
			set sentId = sentStart + i
			if (sentIdDomVal(sentId) '= $$$IKMAXWORDSCORE) && (sentIdDomVal(sentId) '= $$$IKMINWORDSCORE){
				if $get(sentIdFreq(sentId),1) '= 0{
					set sentIdDomVal(sentId) = (sentIdDomVal(sentId) * $get(sentIdFreq(sentId),1))
				} 
			}
		}
		
		merge sentIdToScore = sentIdDomVal
	
	}
	catch(ex)
	{
		set status = ex.AsStatus()
	}
	quit status
}

ClassMethod parseSummaryConfig(ByRef wordWeight, ByRef sentWeight, summaryConfig As %String = "", sentStart As %Integer, sentEnd As %Integer) [ Internal ]
{
		
	set tSC = $$$OK
	try{
		
		set length = $length(summaryConfig,"|")
		set i = 1
		while i < length
		{
			set target = $piece(summaryConfig,"|",i)
			set id = $piece(summaryConfig,"|",i+1)
			set score = $piece(summaryConfig,"|",i+2)
			set i = i + 3
			
			if target = "s"
			{
				if score = "true"
				{
					set score = $$$IKMAXSENTSCORE
				}
				elseif score = "false"
				{
					set score = $$$IKMINSENTSCORE
				}
			
				if id < 0
				{
					set id = sentEnd + id + 1
				}
				else 
				{
					set id = sentStart + id - 1
				}
				set sentWeight(id) = score
			}
			elseif target = "w"
			{
				if score = "true"
				{
					set score = $$$IKMAXWORDSCORE
				}
				elseif score = "false"
				{
					set score = $$$IKMINWORDSCORE
				}
				set wordWeight(id) = score
			} 
		}
	}
	catch(ex)
	{
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

Parameter GetSummaryRT = "sentId:%Integer,sentenceValue:%String,sentenceIsTruncated:%Boolean";

///  <p>This method returns the most relevant sentences of the requested source, in their original order.
///  The number of sentences returned is controlled by the <var>length</var> parameter.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetSummary(ByRef result, domainId As %Integer, srcId As %Integer, length As %Integer = 5, summaryConfig As %String = "") As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (srcId<0) && (domainId=0) {} else { $$$CHECKDOMAINEXISTSX(domainId,tSC) }
	$$$CHECKASRCIDEXISTSX(domainId,srcId,srcDetails,vSrcId,tSC)
	
		
		kill sentWeight
		kill wordWeight
		kill sentIdToScore
		kill scoreToSentId
			
		if summaryConfig '= ""
		{
			set sentStart = 0
			set sentEnd = 0
			if 'vSrcId{
				set sentStart = $list(^IRIS.IK.SrcDetails(domainId, srcId),1) + 1
				set sentEnd = sentStart + $list(^IRIS.IK.SrcDetails(domainId, srcId),2) - 1
			}
			else
			{
				set sentStart = $list(^IRIS.IKV.SrcDetails(domainId, vSrcId),1) + 1
				set sentEnd = sentStart + $list(^IRIS.IKV.SrcDetails(domainId, vSrcId),2) - 1
			}
			set tSC = ..parseSummaryConfig(.wordWeight,.sentWeight,summaryConfig,sentStart,sentEnd)
		}
				
		if tSC = $$$OK{
			set tSC = ..GetSummaryHelper(.sentIdToScore, domainId, srcId ,.wordWeight)
		}
		
		// sort the sentid based on the score
		set sentId = $order(sentIdToScore(""))
		
		while sentId '= ""
		{
			set factor = 1
			if $data(sentWeight(sentId))
			{
				set factor = sentWeight(sentId)
			}
			
			if factor = $$$IKMAXSENTSCORE{
				set newScore = $$$IKMAXSENTSCORE
			}
			elseif factor = $$$IKMINSENTSCORE{
				set newScore = $$$IKMINSENTSCORE
			}
			else{
				if (sentIdToScore(sentId) '= $$$IKMAXWORDSCORE) && (sentIdToScore(sentId) '= $$$IKMINWORDSCORE){  
					set newScore = sentIdToScore(sentId) * factor
				}
				else{
					set newScore = sentIdToScore(sentId)
				}
			} 
			set scoreToSentId(newScore,sentId) = ""
			set sentId = $order(sentIdToScore(sentId)) 
		}
		
		set count = 0
		set score = $order(scoreToSentId(""),-1)
		kill orderedSents
		
		while (score '= "") && (count < length)
		{
			set id = ""
			for {
				set id = $order(scoreToSentId(score,id))
				quit:id=""
				if score '= $$$IKMINSENTSCORE{
					set orderedSents(id) = ""
					set count = count + 1
				}
				if count = length{ quit }
			}
			set score = $order(scoreToSentId(score),-1)
		}
		
		// store in result variable
		set sentId = "", n=0
		for {
			set sentId = $order(orderedSents(sentId))
			quit:sentId=""
		
			set sentValue = ##class(%iKnow.Queries.SentenceAPI).GetValue(domainId, sentId, .fullSentence, vSrcId)
			$$$IKQADDRESULT(result,$i(n),$lb(sentId, sentValue, 1-fullSentence))
		}
		kill sents, orderedSents, sentId, i, n, rel, sentValue
		
	
	$$$IKQENDCATCH(result,"",tSC)
}

///  <p>This is a utility wrapper method around <method>GetSummary</method>, returning the summary
///  sentences as a single concatenated string.</p>
///  <p>The <i>isTruncated</i> output parameter indicates whether or not the
///  returned string is complete or was truncated to avoid MAXSTRING errors. This can happen when either
///  an individual sentence surpassed the maximum string length or when the concatenation of these
///  sentences surpassed it.</p>
ClassMethod GetSummaryDirect(domainId As %Integer, sourceId As %Integer, length As %Integer = 5, Output isTruncated As %Boolean = 0, Output sc As %Status = {$$$OK}, separator As %String = " ... ", summaryConfig As %String = "") As %String
{
	$$$IKQBEGINR("^||%IKQ.GetSummary",sc,"")
	set str = "", isTruncated = 0, maxLength = 32000
	set sc = ..GetSummary("^||%IKQ.GetSummary", domainId, sourceId, length, summaryConfig)
	quit:$$$ISERR(sc) ""
	
	set i = ""
	for { 
		set i = $order(^||%IKQ.GetSummary(i), 1, sentence)
		quit:i=""
		
		set str = str _ $s(str'="":separator, 1:"")
		
		set sentValue = $li(sentence,2)
		if ($length(str) + $length(sentValue) > maxLength) || $li(sentence,3) {
			set isTruncated = 1
			set str = str _ $e(sentValue, 1, maxLength-$length(str))
			quit
		}
		
		set str = str _ sentValue
	}
	$$$IKQEND("^||%IKQ.GetSummary",str)
}

Parameter GetByDomainRT = "srcId:%Integer,externalId:%String";

///  <p>Returns all sources within a domain, optionally filtered through
///  a <class>%iKnow.Filters.Filter</class> object passed in as <i>filter</i>.</p> 
ClassMethod GetByDomain(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", sortByField As %String = "") As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	
	// BDB332 - adding support for metadata-based sorting
	if (sortByField'="") {
		set tSC = ..GetByDomain(.tUnsorted, domainid, 0, 0, filter, "")
		quit:$$$ISERR(tSC)
		set tMetadataAPI = $$$GETPARAM(domainid,$$$IKPMETADATAAPI,$$$IKPDEFMETADATAAPI)
		set tSC = $classmethod(tMetadataAPI, "SortByField", .result, domainid, .tUnsorted, sortByField, page, pagesize)
		quit
	}
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	set srcOffset = ""
	for {
		set srcOffset = $order(^IRIS.IK.SrcExistsBit(domainid, srcOffset), -1, srcBits)
		quit:srcOffset=""
		
		if ($isobject(filter)) {
			set filterbits = filter.GetSourceFilter(srcOffset)
			set srcBits = $bitlogic(srcBits & filterbits)
		}
		
		set srcPos = 1
		for {
			set srcPos = $bitfind(srcBits, 1, srcPos-1, -1)
			quit:srcPos=0
			
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			$$$IKQADDRESULT(result,count,$lb(srcId, ..GetExternalId(domainid, srcId)))
			
			// we should end here as well, as we're walking backwards through mergedbits
			quit:srcPos=1
		}
		
		// also quit this loop if we're done
		$$$IKCHECKPAGING(usePaging,0,last,count)
	}
	$$$IKQENDCATCH(result,"",tSC)
}

///  <p>This method returns the total number of sources in the specified domain, optionally filtered
///  through a <class>%iKnow.Filters.Filter</class> object passed in as <i>filter</i>.</p> 
ClassMethod GetCountByDomain(domainid As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	
	quit:$isobject(filter) filter.FilteredSourceCount
	
	set srcOffset = "", total = 0
	for {
		set srcOffset = $order(^IRIS.IK.SrcExistsBit(domainid, srcOffset), 1, srcBits)
		quit:srcOffset=""
		
		set total = total + $bitcount(srcBits, 1)
	}
	
	quit total
}

Parameter GetLanguagesRT = "language:%String,totalConfidence:%Numeric,sentenceCount:%Integer";

///  <p>This method returns, for a given source, all languages the iKnow Automatic Language
///  Identification algorithm has identified for the sentences it contains. For each language, it will
///  list the sum of ALI confidence ratings when assigning the language to a sentence, plus the total
///  number of sentences the language was assigned to. If ALI was disabled when indexing this
///  source, confidence ratings will be set to 0.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetLanguages(ByRef result, domainid As %Integer, sourceid As %Integer) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (sourceid<0) && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	$$$CHECKASRCIDEXISTSX(domainid,sourceid,srcDetails,vSrcId,tSC)
	
	set sentBase = $list(srcDetails,1)
	set sentCount = $list(srcDetails,2)
	
	set sentDetailsGlo = $$$IKVGLOBNAME(domainid,"SentDetails",vSrcId)
	
	kill byLanguage
	set from=sentBase+1, to=sentBase+sentCount
	for i = from:1:to {
		set sentDetails = @sentDetailsGlo@(i)
		set conf = $lg($g(byLanguage($li(sentDetails,1))),1) + $li(sentDetails,2)
		set count = $lg($g(byLanguage($li(sentDetails,1))),2) + 1
		set byLanguage($li(sentDetails,1)) = $lb(conf, count)
	}
	
	kill byConfidence
	set lang = ""
	for {
		set lang = $o(byLanguage(lang),1,data)
		quit:lang=""
		
		set byConfidence($li(data,1), lang) = $li(data,2)
	}
	
	set i=0, conf=""
	for {
		set conf = $o(byConfidence(conf),-1)
		quit:conf=""
		
		set lang = ""
		for {
			set lang = $o(byConfidence(conf,lang),1,count)
			quit:lang=""
			
			$$$IKQADDRESULT(result,$i(i),$lb($li($$$IKLANGUAGES, lang), conf, count))
		}
	}
	$$$IKQENDCATCH(result,"",tSC)
}

///  <p>This method returns the language of a given source, calculated as the one with the 
///  highest total confidence rating for the individual sentences in the source. This total 
///  confidence, as well as the number of sentences to which this language was assigned
///  is provided through output variables <i>totalConfidence</i> and <i>numberOfSentences</i>.</p>
///  <p>A <i>totalConfidence</i> of 0 indicates ALI was switched off when indexing this source.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetTopLanguage(domainid As %Integer, sourceid As %Integer, Output totalConfidence As %Numeric = "", Output numberOfSentences As %Integer = "", Output sc As %Status = {$$$OK}) As %String
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,"")
	if (sourceid<0) && (domainid=0) {} else { $$$CHECKDOMAINEXISTSR(domainid,sc,"") }
	$$$CHECKASRCIDEXISTSR(domainid,sourceid,srcDetails,vSrcId,sc,"")
	
	set sentBase = $list(srcDetails,1)
	set sentCount = $list(srcDetails,2)
	quit:sentCount=0 ""
	
	set sentDetailsGlo = $$$IKVGLOBNAME(domainid,"SentDetails",vSrcId)
	
	kill byLanguage
	set from=sentBase+1, to=sentBase+sentCount
	for i = from:1:to {
		set sentDetails = @sentDetailsGlo@(i)
		set conf = $lg($g(byLanguage($li(sentDetails,1))),1) + $li(sentDetails,2)
		set count = $lg($g(byLanguage($li(sentDetails,1))),2) + 1
		set byLanguage($li(sentDetails,1)) = $lb(conf, count)
	}
	
	kill byConfidence
	set lang = ""
	for {
		set lang = $o(byLanguage(lang),1,data)
		quit:lang=""
		
		set byConfidence($li(data,1), lang) = $li(data,2)
	}
	
	set totalConfidence = $o(byConfidence(""),-1)
	set language = $o(byConfidence(totalConfidence, ""), 1, numberOfSentences)
	quit $list($$$IKLANGUAGES, language)
}

Parameter GetByEntitiesRT = "srcId:%Integer,externalId:%String";

///  <p>This method will retrieve all sources containing any (if <var>setop</var> = $$$UNION) or all (if <var>setop</var> = 
///  $$$INTERSECT) of the entities supplied through <var>entitylist</var>.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class>
///  object for the <var>filter</var> parameter to restrict the result to those sources satisfying the
///  filter criteria.</p>
///  <p>By default, results are ordered by decreasing source id. You can override this by setting
///  <var>sortByField</var> to the name of a metadata field (optionally appended with " ASC" or " DESC"
/// for this domain to order by that field's value. </p>
/// <p>The <var>attributeFilter</var> argument can be used to filter the results to only those where
/// the requested entities (<var>entitylist</var>) appear in the context of a particular (set of)
/// attribute(s). By using the negative attribute ID, you can select only those occurrences NOT 
/// appearing in the context of that attribute. For example, passing in $lb($$$IKATTNEGATION) will restrict the result to only those
/// entities in a negative context and $lb(-$$$IKATTNEGATION) the ones in an affirmative context.
/// Note that the use of this argument may have a significant performance impact.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sources containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sources containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(ByRef result, domainid As %Integer, entitylist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, attributeFilter As %List = "", sortByField As %String = "", pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	$$$IKENSURELISTNUM(attributeFilter)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByEntitiesInternal
	quit ..GetByEntitiesInternal(.result, domainid, .entIdList, page, pagesize, filter, setop, attributeFilter, sortByField)
}

Parameter GetByEntityIdsRT = "srcId:%Integer,externalId:%String";

///  <p>Retrieves all sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(ByRef result, domainid As %Integer, entityidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, attributeFilter As %List = "", sortByField As %String = "", pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	$$$IKENSURELISTNUM(attributeFilter)
	
	// clean up the entityidlist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByEntitiesInternal
	quit ..GetByEntitiesInternal(.result, domainid, .cleanIdList, page, pagesize, filter, setop, attributeFilter, sortByField)
}

ClassMethod GetByEntitiesInternal(ByRef result, domainid As %Integer, ByRef entitylist, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, setop As %Integer, attributeFilter As %List = "", sortByField As %String = "") As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'entitylist
	
	if (attributeFilter'="") {
		$$$IKCHECKVERSIONATLEASTX(domainid,$$$IKVERSIONATTRIBUTES,tSC)
	}
	
	// BDB332 - adding support for metadata-based sorting
	if (sortByField'="") {
		set tSC = ..GetByEntitiesInternal(.tUnsorted, domainid, .entitylist, 0, 0, filter, setop, attributeFilter, "")
		quit:$$$ISERR(tSC)
		set tMetadataAPI = $$$GETPARAM(domainid,$$$IKPMETADATAAPI,$$$IKPDEFMETADATAAPI)
		set tSC = $classmethod(tMetadataAPI, "SortByField", .result, domainid, .tUnsorted, sortByField, page, pagesize)
		quit
	}
	
	$$$IKQBCHECKX(domainid,$$$IKBENTUNISRC,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// BDB522
	set t2Level = ($d(entitylist($order(entitylist(""))))>1)
	
	// define last source offset
	set tLastSrcId = $s($isobject(filter):filter.GetFirstFilteredSource(-1), 1:$order(^IRIS.IK.SrcId(domainid,""),-1))
	$$$IKBITOFFPOS(tLastSrcId,tLastSrcOffset,x)
	
	for tSrcOffset = tLastSrcOffset:-1:1 {
		set mergedbits = ""
		
		// first loop through the entities
		set entId = "", tIsFirstEntity = 1
		for {
			set entId = $order(entitylist(entId))
			quit:entId=""
			
			// based on the setop, we either AND or OR the bitstrings from ^IRIS.IK.EntUniToSrcBit
			if (setop = $$$UNION) {
				
				set mergedbits = $bitlogic(mergedbits | ^IRIS.IK.EntUniToSrcBit(domainid, entId, tSrcOffset))
				
			} else {
				
				if $d(entitylist(entId))>1 { 
				
					// BDB522: multi-level indicates the sub-level needs to be ORed before ANDing
					set tSubEntId = "", tTheseBits = ""
					for {
						set tSubEntId = $order(entitylist(entId,tSubEntId))
						quit:tSubEntId=""
						set tTheseBits = $bitlogic(tTheseBits | ^IRIS.IK.EntUniToSrcBit(domainid, tSubEntId, tSrcOffset))
					}
					
				} else {
					set tTheseBits = $get(^IRIS.IK.EntUniToSrcBit(domainid, entId, tSrcOffset))
				}
				
				if (tIsFirstEntity) {
					set mergedbits = tTheseBits
				} else {
					set mergedbits = $bitlogic(mergedbits & tTheseBits)
				}
				set tIsFirstEntity = 0
			}
				
		}
		
		// combine with the applicable filter, if any
		if ($isobject(filter)) {
			set filterBits = filter.GetSourceFilter(tSrcOffset)
			set mergedbits = $bitlogic(mergedbits & filterBits)
		}
		
		// now add the entries satisfying the resulting bitstring
		set srcPos = 1
		for {
			
			// find the next bit, backwards
			set srcPos = $bitfind(mergedbits, 1, srcPos-1, -1)
			quit:srcPos=0
			
			// calculcate srcId
			$$$IKGETIDOFFPOS(srcId,tSrcOffset,srcPos)
			
			// BDB322 - treat attribute filter (slow!)
			if (attributeFilter'="") {
				set srcDetails = ^IRIS.IK.SrcDetails(domainid,srcId)
				set tPartId=$li(srcDetails,3), tPartIdMax=tPartId+$li(srcDetails,4), ok=0
				for {
					set tPartId=$order(^IRIS.IK.EntOccId(domainid,tPartId),1,entOcc)
					quit:tPartId=""
					quit:tPartId>tPartIdMax
					
					// BDB577
					continue:$lg(entOcc,2)=$$$ENTTYPENONREL
					
					if (t2Level) {
						set i="",in=0,tEntUniId=$li(entOcc,1)
						for {
							set i = $order(entitylist(i))
							quit:i=""
							if $d(entitylist(i,tEntUniId)) {
								set in=1
								quit
							}
						}
						continue:'in
					} else {
						continue:'$d(entitylist($li(entOcc,1)))	
					}
					set ptr=0
					while $listnext(attributeFilter,ptr,att) {
						set isAttributed = ##class(%iKnow.Queries.EntityAPI).IsAttributedInternal(domainid,tPartId,$zabs(att),entOcc)
						set ok = ((att>0) && isAttributed) || ((att<0) && 'isAttributed)
						quit:ok
					}
					quit:ok
				}
				continue:'ok
			}
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// build src record to be added to ^||%IK.GetEntSrcesInternal
			$$$IKQADDRESULT(result,count,$lb(srcId, ..GetExternalId(domainid, srcId)))
			
			// we should end here as well, as we're walking backwards through mergedbits
			quit:srcPos=1
		}
		
		// also quit this loop if we're done
		$$$IKCHECKPAGING(usePaging,0,last,count) 
	}
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetByEquivalentsRT [ Deprecated, Internal ] = "srcId:%Integer,externalId:%String";

/// Deprecated
ClassMethod GetByEquivalents(ByRef result, domainid As %Integer, entitylist As %List, setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated, Internal ]
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList)
	quit:$$$ISERR(tSC) tSC
	
	quit ..GetByEquivalentsInternal(.result,domainid,.entIdList,setid,page,pagesize,filter)
}

Parameter GetByEquivalentIdsRT [ Deprecated, Internal ] = "srcId:%Integer,externalId:%String";

/// Deprecated
ClassMethod GetByEquivalentIds(ByRef result, domainid As %Integer, entityidlist As %List, setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "") As %Status [ Deprecated, Internal ]
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// unravel the entitylist into a clean %List
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .entIdList)
	quit:$$$ISERR(tSC) tSC
	
	quit ..GetByEquivalentsInternal(.result,domainid,.entIdList,setid,page,pagesize,filter)
}

/// Deprecated
ClassMethod GetByEquivalentsInternal(ByRef result, domainid As %Integer, ByRef entitylist, setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "") As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.EquivSrcs",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'entitylist
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	set totSize=page*pagesize
	
	// start from the entities themselves
	set tSC = ..GetByEntitiesInternal(.src,domainid,.entitylist,1,totSize,filter,$$$UNION)
	quit:$$$ISERR(tSC)
	set y=""
	for {
		set y=$o(src(y),1,srcdata)
		q:y=""
		
		set ^||%IK.EquivSrcs(-$list(srcdata,1))=$list(srcdata,2)
	}
	
	// and now add those sources containing equivalent terms
	set entid = ""
	for {
		set entid = $order(entitylist(entid))
		quit:entid=""
		
		do ##class(%iKnow.Queries.EquivAPI).GetTerms(.equivs,domainid,setid,entid,0,0)
		
		kill eqIds
		set x=""
		for {
			set x=$o(equivs(x),1,data)
			q:x=""
		
			set eqIds($list(data)) = ""
		}
		
		do ..GetByEntitiesInternal(.src,domainid,.eqIds,1,totSize,filter,$$$UNION)
		set y=""
		for {
			set y=$o(src(y),1,srcdata)
			q:y=""
		
			set ^||%IK.EquivSrcs(-$list(srcdata,1))=$list(srcdata,2)
		}
		kill eqIds
	}
	
	set id=""
	for {
		set id=$o(^||%IK.EquivSrcs(id),1,extid)
		q:id=""
		
		set count=count+1
		$$$IKCHECKPAGING(usePaging,first,last,count)
		
		$$$IKQADDRESULT(result,count,$lb(-id,extid))
	}
	$$$IKQENDCATCH(result,"^||%IK.EquivSrcs",tSC)
}

///  <p>Retrieves the number of sources containing the given entities.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entitylist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByEntitiesInternal
	quit ..GetCountByEntitiesInternal(domainid, .entIdList, filter, setop, .sc)
}

///  <p>Retrieves the number of sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entityidlist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean up the entityidlist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByEntitiesInternal
	quit ..GetCountByEntitiesInternal(domainid, .cleanIdList, filter, setop, .sc)
}

ClassMethod GetCountByEntitiesInternal(domainid As %Integer, ByRef entitylist, filter As %iKnow.Filters.Filter, setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set sc = $$$OK
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'entitylist 0
	
	$$$IKQBCHECKR(domainid,$$$IKBENTUNISRC,sc,-1)
	
	// define last source offset
	set tLastSrcId = $s($isobject(filter):filter.GetFirstFilteredSource(-1), 1:$order(^IRIS.IK.SrcId(domainid,""),-1))
	$$$IKBITOFFPOS(tLastSrcId,tLastSrcOffset,x)
	
	set total = 0
	for tSrcOffset = 1:1:tLastSrcOffset {
		set mergedbits = ""
		
		// first loop through the entities
		set entId = "", tIsFirstEntity = 1
		for {
			set entId = $order(entitylist(entId))
			quit:entId=""
			
			// based on the setop, we either AND or OR the bitstrings from ^IRIS.IK.EntUniToSrcBit
			if (setop = $$$UNION) {
				
				set mergedbits = $bitlogic(mergedbits | ^IRIS.IK.EntUniToSrcBit(domainid, entId, tSrcOffset))
				
			} else {
				
				if $d(entitylist(entId))>1 { 
				
					// BDB522: multi-level indicates the sub-level needs to be ORed before ANDing
					set tSubEntId = "", tTheseBits = ""
					for {
						set tSubEntId = $order(entitylist(entId,tSubEntId))
						quit:tSubEntId=""
						set tTheseBits = $bitlogic(tTheseBits | ^IRIS.IK.EntUniToSrcBit(domainid, tSubEntId, tSrcOffset))
					}
					
				} else {
					set tTheseBits = $get(^IRIS.IK.EntUniToSrcBit(domainid, entId, tSrcOffset))
				}
				
				if (tIsFirstEntity) {
					set mergedbits = tTheseBits
				} else {
					set mergedbits = $bitlogic(mergedbits & tTheseBits)
				}
				set tIsFirstEntity = 0
			}
				
		}
		
		// combine with the applicable filter, if any
		if ($isobject(filter)) {
			set filterBits = filter.GetSourceFilter(tSrcOffset)
			set mergedbits = $bitlogic(mergedbits & filterBits)
		}
		
		// now add the number of entries satisfying the resulting bitstring
		set total = total + $bitcount(mergedbits, 1)
	}
		
	quit total
}

///  <p>Retrieves a bitstring array identifying all sources containing the given entities.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetBitsByEntities(ByRef result, domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", setop As %String = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetBitsByEntitiesInternal
	quit ..GetBitsByEntitiesInternal(.result, domainid, .entIdList, filter, setop)
}

///  <p>Retrieves a bitstring array identifying all sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetBitsByEntityIds(ByRef result, domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean up the entityidlist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList,,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetBitsByEntitiesInternal
	quit ..GetBitsByEntitiesInternal(.result, domainid, .cleanIdList, filter, setop)
}

ClassMethod GetBitsByEntitiesInternal(ByRef result, domainid As %Integer, ByRef entitylist, filter As %iKnow.Filters.Filter, setop As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.GetBitsRes,^||%IK.ANDBits",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'entitylist
	
	$$$IKQBCHECKX(domainid,$$$IKBENTUNISRC,tSC)
	
	set tempGlo = $s($g(result)="":"^||%IK.GetBitsRes", 1:result)
	set mergeMode = $s(setop=$$$UNION:"OR", 1:"AND")
	
	// just loop through the ^IRIS.IK.EntUniToSrc and combine results for the input EntUniIds
	set entId = "", first=1
	for {
		set entId = $order(entitylist(entId))
		quit:entId=""
		if (setop=$$$UNION) {
			$$$IKMERGEBITSOR(("^IRIS.IK.EntUniToSrcBit("_domainid_","_entId_")"),tempGlo)
		} else {
			// BDB522 - two-level entitylist means ORing the sub-level entities first
			if $d(entitylist(entId))>1 {
				kill ^||%IK.ANDBits
				set tSubEntId=""
				for {
					set tSubEntId = $order(entitylist(entId,tSubEntId))
					quit:tSubEntId=""
					set tToGlob = $s(first:tempGlo, 1:"^||%IK.ANDBits")
					$$$IKMERGEBITSOR("^IRIS.IK.EntUniToSrcBit("_domainid_","_tSubEntId_")",tToGlob)
				}
				if 'first {
					$$$IKMERGEBITSAND("^||%IK.ANDBits",tempGlo)
				}
			} else {
				if first {
					merge @tempGlo = ^IRIS.IK.EntUniToSrcBit(domainid,entId)
				} else {
					$$$IKMERGEBITSAND("^IRIS.IK.EntUniToSrcBit("_domainid_","_entId_")",tempGlo)
				}
			}
			set first=0
		}
	}
	
	// combine with filter if required
	if ($isobject(filter)) {
		set srcOffset = ""
		for {
			set srcOffset = $order(@tempGlo@(srcOffset), 1, srcBits)
			quit:srcOffset=""
			
			set filterBits = filter.GetSourceFilter(srcOffset)
			set @tempGlo@(srcOffset) = $bitlogic(srcBits & filterBits)
		}
	}
	
	merge:($g(result)="") result = ^||%IK.GetBitsRes
	
	$$$IKQENDCATCH(result,"^||%IK.GetBitsRes,^||%IK.ANDBits",tSC)
}

Parameter GetByCrcsRT = "srcId:%Integer,externalId:%String";

///  <p>Retrieves all sources containing the given CRCs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcs(ByRef result, domainid As %Integer, crclist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, sortByField As %String = "") As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:crclist="" $$$OK
	
	// clean the crclist into a %List without duplicates or inexistent crcIds
	set tSC = ##class(%iKnow.Queries.CrcAPI).TranslateCrcList(domainid, crclist, "^||%IK.CrcIds")
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetByCrcsInternal
	quit ..GetByCrcsInternal(.result, domainid, "^||%IK.CrcIds", page, pagesize, filter, setop, sortByField)
}

Parameter GetByCrcMaskRT = "srcId:%Integer,externalId:%String";

///  <p>Retrieves all sources containing a CRC satisfying the given CRC Mask.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcMask(ByRef result, domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", sortByField As %String = "", pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"^||%IK.TranslateMRSBits")
	$$$CHECKDOMAINEXISTS(domainid)
	
	// we have to translate the head, relation, tail parameters into a %List of
	// crcIds, so we can forward to GetCrcSrcesInternal. 
	// An alternative implementation might make sense if two out of these three parameters
	// would be wildcards or if the list of CRCs gets very long, in which case the bitstrings
	// could be used further down the algorithm
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.CrcAPI).TranslateMRSMaskToCrcIdList(domainid, head, relation, tail, "^||%IK.CrcIds",, tIncludeActuals)
	quit:$$$ISERR(tSC) tSC
	
	// now forward to ..GetByCrcsInternal (only $$$UNION makes sense here)
	quit ..GetByCrcsInternal(.result, domainid, "^||%IK.CrcIds", page, pagesize, filter, $$$UNION, sortByField)
}

Parameter GetByCrcIdsRT = "srcId:%Integer,externalId:%String";

///  <p>Retrieves all sources containing the given CRC ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcIds(ByRef result, domainid As %Integer, crcidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, sortByField As %String = "") As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:crcidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(crcidlist)
	
	// clean the crclist into a %List without duplicates or inexistent crcIds
	set tSC = ##class(%iKnow.Queries.CrcAPI).TranslateCrcIdList(domainid, crcidlist, "^||%IK.CrcIds")
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetByCrcsInternal
	quit ..GetByCrcsInternal(.result, domainid, "^||%IK.CrcIds", page, pagesize, filter, setop, sortByField)
}

ClassMethod GetByCrcsInternal(ByRef result, domainid As %Integer, crcIdsGlob As %String, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, setop As %Integer, sortByField As %String = "") As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'$d(@crcIdsGlob)
	
	// BDB332 - adding support for metadata-based sorting
	if (sortByField'="") {
		set tSC = ..GetByCrcsInternal(.tUnsorted, domainid, crcIdsGlob, 0, 0, filter, setop, "")
		quit:$$$ISERR(tSC)
		set tMetadataAPI = $$$GETPARAM(domainid,$$$IKPMETADATAAPI,$$$IKPDEFMETADATAAPI)
		set tSC = $classmethod(tMetadataAPI, "SortByField", .result, domainid, .tUnsorted, sortByField, page, pagesize)
		quit
	}
	
	$$$IKQBCHECKX(domainid,$$$IKBCRCUNISRC,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// by default, returned sources are sorted in decreasing order, so we start by looking
	// for the crcId that occurs in the most recent doucment (highest srcId). When looking for
	// crcs that occur very frequently, it might be better to just start looking at the 
	// max srcId and don't bother looking at the crcs first, but in most cases crclist
	// will be quite short and the overhead will be minimal as compared to going through ALL
	// srcIds in a large dataset, so we're always checking if it makes sense to look at an offset
	set maxSrcOffset = ""
	for {
		
		// loop through the crc list to find the first offset that has src candidates
		// TODO: check whether this mechanism is worth the effort or just decreasing by 1 would do
		set nextSrcOffset = 0
		set crcId = ""
		for {
			set crcId = $order(@crcIdsGlob@(crcId))
			quit:crcId=""
			
			// now loop through the srces in which this crc occurs
			set crcSrcOffset =  $order(^IRIS.IK.CrcUniToSrcBit(domainid, crcId, maxSrcOffset), -1)
			continue:crcSrcOffset=""
			
			// recalculate the maximum nextSrcOffset
			set:(crcSrcOffset > nextSrcOffset) nextSrcOffset = crcSrcOffset
			
			// if we're just 1 short of the previous maxSrcOffset, we can't get any better
			quit:(nextSrcOffset = (maxSrcOffset - 1))
		}
		set maxSrcOffset = nextSrcOffset
		
		// quit alltogether if no valid next offset is found
		quit:maxSrcOffset=""
		quit:maxSrcOffset=0
	
		// now that we have the maximum offset we should start checking for, loop through the crc
		// list and reset the maxSrcOffset after finishing each offset
		set mergedbits = ""
		
		// first loop through the crcs
		set crcId = ""
		set i = 0
		for {
			set crcId = $order(@crcIdsGlob@(crcId))
			quit:crcId=""
			
			set i = i+1
			
			// based on the setop, we either AND or OR the bitstrings from ^IRIS.IK.CrcUniToSrcBit
			if (setop = $$$UNION) {
				
				// for $$$UNION, we don't care about the first entry
				set mergedbits = $bitlogic(mergedbits | ^IRIS.IK.CrcUniToSrcBit(domainid, crcId, maxSrcOffset))
				
			} elseif (setop = $$$INTERSECT) {
				
				// for $$$INTERSECT, the first bitstring should be taken as is (no ANDing)
				if (i = 1) {
					set mergedbits = $get(^IRIS.IK.CrcUniToSrcBit(domainid, crcId, maxSrcOffset), "")
				} else {
					set mergedbits = $bitlogic(mergedbits & ^IRIS.IK.CrcUniToSrcBit(domainid, crcId, maxSrcOffset))
				}
			}
				
		}
		
		// combine with the applicable filter, if any
		if ($isobject(filter)) {
			set filterBits = filter.GetSourceFilter(maxSrcOffset)
			set mergedbits = $bitlogic(mergedbits & filterBits)
		}
		
		// now add the entries satisfying the resulting bitstring
		set srcPos = 1
		for {
			
			// find the next bit, backwards
			set srcPos = $bitfind(mergedbits, 1, srcPos-1, -1)
			quit:srcPos=0
			
			// calculcate srcId
			$$$IKGETIDOFFPOS(srcId,maxSrcOffset,srcPos)
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// build src record
			$$$IKQADDRESULT(result,count,$lb(srcId,..GetExternalId(domainid, srcId)))
			
			// we should end here as well, as we're walking backwards through mergedbits
			quit:srcPos=1
		}
		
		// also quit this loop if we're done
		$$$IKCHECKPAGING(usePaging,0,last,count)
	}
	$$$IKQENDCATCH(result,"",tSC)
}

///  <p>Retrieves the number of sources containing the given CRCs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcs(domainid As %Integer, crclist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:crclist="" 0
	
	// unravel the crclist into a clean %List
	set sc = ##class(%iKnow.Queries.CrcAPI).TranslateCrcList(domainid, crclist, "^||%IK.CrcIds")
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByCrcsInternal
	quit ..GetCountByCrcsInternal(domainid, "^||%IK.CrcIds", filter, setop, .sc)
}

///  <p>Retrieves the number of sources containing a CRC satisfying the given CRC Mask.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcMask(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("^||%IK.TranslateMRSBits",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	
	// translate the MRS mask into a clean %List (see also remarks in GetCrcSrcesForMask)
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.CrcAPI).TranslateMRSMaskToCrcIdList(domainid, head, relation, tail, "^||%IK.CrcIds",, tIncludeActuals)
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByCrcsInternal
	quit ..GetCountByCrcsInternal(domainid, "^||%IK.CrcIds", filter, $$$UNION, .sc)
}

///  <p>Retrieves the number of sources containing the given CRC ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcIds(domainid As %Integer, crcidlist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:crcidlist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(crcidlist)
	
	// clean up the crcidlist into a clean %List
	set sc = ##class(%iKnow.Queries.CrcAPI).TranslateCrcIdList(domainid, crcidlist, "^||%IK.CrcIds")
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByCrcsInternal
	quit ..GetCountByCrcsInternal(domainid, "^||%IK.CrcIds", filter, setop, .sc)
}

ClassMethod GetCountByCrcsInternal(domainid As %Integer, crcIdsGlob As %String, filter As %iKnow.Filters.Filter, setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	set sc = $$$OK
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'$d(@crcIdsGlob) 0
	
	$$$IKQBCHECKR(domainid,$$$IKBCRCUNISRC,sc,-1)
	
	set total = 0
	
	// same algorithm as above, but no need to go in the reverse order as the Tot queries
	// return totals and no ordered results
	set minSrcOffset = ""
	for {
		
		// loop through the crc list to find the first offset that has src candidates
		// TODO: check whether this mechanism is worth the effort or just decreasing by 1 would do
		set nextSrcOffset = 0
		set crcId = ""
		for {
			set crcId = $order(@crcIdsGlob@(crcId))
			quit:crcId=""
			
			// now loop through the srces in which this crc occurs
			set crcSrcOffset =  $order(^IRIS.IK.CrcUniToSrcBit(domainid, crcId, minSrcOffset))
			continue:crcSrcOffset=""
			
			// recalculate the maximum nextSrcOffset
			set:'nextSrcOffset||(crcSrcOffset<nextSrcOffset) nextSrcOffset = crcSrcOffset
			
			// if we're just 1 further than the previous minSrcOffset, we can't get any better
			quit:(nextSrcOffset = (minSrcOffset + 1))
		}
		set minSrcOffset = nextSrcOffset
		
		// quit alltogether if no valid next offset is found
		quit:minSrcOffset=""
		quit:minSrcOffset=0
	
		// now that we have the minimum offset we should start checking for, loop through the crc
		// list and reset the minSrcOffset after finishing each offset
		set mergedbits = ""
		
		// first loop through the crcs
		set crcId = ""
		set i = 0
		for {
			set crcId = $order(@crcIdsGlob@(crcId))
			quit:crcId=""
			
			set i = i+1
			
			// based on the setop, we either AND or OR the bitstrings from ^IRIS.IK.CrcUniToSrcBit
			if (setop = $$$UNION) {
				
				// for $$$UNION, we don't care about the first entry
				set mergedbits = $bitlogic(mergedbits | ^IRIS.IK.CrcUniToSrcBit(domainid, crcId, minSrcOffset))
				
			} elseif (setop = $$$INTERSECT) {
				
				// for $$$INTERSECT, the first bitstring should be taken as is (no ANDing)
				if (i = 1) {
					set mergedbits = $get(^IRIS.IK.CrcUniToSrcBit(domainid, crcId, minSrcOffset), "")
				} else {
					set mergedbits = $bitlogic(mergedbits & ^IRIS.IK.CrcUniToSrcBit(domainid, crcId, minSrcOffset))
				}
			}
				
		}
		
		// combine with the applicable filter, if any
		if ($isobject(filter)) {
			set filterBits = filter.GetSourceFilter(minSrcOffset)
			set mergedbits = $bitlogic(mergedbits & filterBits)
		}
		
		// now add the number of entries satisfying the resulting bitstring
		set total = total + $bitcount(mergedbits, 1)
	}
		
	quit total
}

Parameter GetByPathIdsRT = "srcId:%Integer,externalId:%String";

///  <p>Retrieves all sources containing the given path ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByPathIds(ByRef result, domainid As %Integer, pathidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", sortByField As %String = "") As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:pathidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(pathidlist)
	
	// clean the pathidlist into a %List without duplicates or inexistent crcIds
	set tSC = ##class(%iKnow.Queries.PathAPI).TranslatePathIdList(domainid, pathidlist, .cleanIdList)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByPathsInternal
	quit ..GetByPathsInternal(.result, domainid, .cleanIdList, page, pagesize, filter, sortByField)
}

ClassMethod GetByPathsInternal(ByRef result, domainid As %Integer, ByRef pathlist, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, sortByField As %String) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.trackedSrcs",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'$d(pathlist)
	
	// BDB332 - adding support for metadata-based sorting
	if (sortByField'="") {
		set tSC = ..GetByPathsInternal(.tUnsorted, domainid, .pathlist, 0, 0, filter, "")
		quit:$$$ISERR(tSC)
		set tMetadataAPI = $$$GETPARAM(domainid,$$$IKPMETADATAAPI,$$$IKPDEFMETADATAAPI)
		set tSC = $classmethod(tMetadataAPI, "SortByField", .result, domainid, .tUnsorted, sortByField, page, pagesize)
		quit
	}
	
	$$$IKQBCHECKX(domainid,$$$IKBPATH,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// as a path can be in only one document, a simple loop over the pathlist and getting the
	// corresponding srcId from ^IRIS.IK.PathToSrc will do, keeping track of the sources already 
	// in the list
	kill trackedSrcs
	set pathId = ""
	for {
		set pathId = $order(pathlist(pathId))
		quit:pathId=""
		
		set pathBaseId = $order(^IRIS.IK.PathToSrc(domainid, pathId), -1, pathDetails)
		set srcId = $li(pathDetails, 1)
		
		// check if the srcId complies with the current filter
		if ($isobject(filter)) {
			$$$IKBITOFFPOS(srcId,srcOffset,srcPos)
			set filterBits = filter.GetSourceFilter(srcOffset)
			continue:'$bit(filterBits,srcPos)
		}
		
		// check if it's already in the result list
		if ('$data(^||%IK.trackedSrcs(srcId))) {
			
			// keep track of this one
			set ^||%IK.trackedSrcs(srcId) = ""
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// build src record
			$$$IKQADDRESULT(result,count,$lb(srcId, ..GetExternalId(domainid, srcId)))
		}
	}
	$$$IKQENDCATCH(result,"^||%IK.trackedSrcs",tSC)
}

///  <p>Retrieves the number of sources containing the given path ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByPathIds(domainid As %Integer, pathidlist As %List, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:pathidlist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(pathidlist)
	
	// clean the pathidlist into a %List without duplicates or inexistent crcIds
	set sc = ##class(%iKnow.Queries.PathAPI).TranslatePathIdList(domainid, pathidlist, .cleanIdList)
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByPathsInternal
	quit ..GetCountByPathsInternal(domainid, .cleanIdList, filter, .sc)
}

ClassMethod GetCountByPathsInternal(domainid As %Integer, ByRef pathlist, filter As %iKnow.Filters.Filter, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("^||%IK.trackedSrcs",sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'$d(pathlist) 0
	
	$$$IKQBCHECKR(domainid,$$$IKBPATH,sc,-1)
	
	set total = 0
	// as a path can be in only one document, a simple loop over the pathlist and getting the
	// corresponding srcId from ^IRIS.IK.PathToSrc will do, keeping track of the sources already 
	// in the list
	set pathId = ""
	for {
		set pathId = $order(pathlist(pathId))
		quit:pathId=""
		
		set pathBaseId = $order(^IRIS.IK.PathToSrc(domainid, pathId), -1, pathDetails)
		set srcId = $li(pathDetails, 1)
		
		// check if the srcId complies with the current filter
		if ($isobject(filter)) {
			$$$IKBITOFFPOS(srcId,srcOffset,srcPos)
			set filterBits = filter.GetSourceFilter(srcOffset)
			continue:'$bit(filterBits,srcPos)
		}
		
		// check if it's already in the result list
		if ('$data(^||%IK.trackedSrcs(srcId))) {
			
			// keep track of this one
			set ^||%IK.trackedSrcs(srcId) = ""
			
			set total = total+1
		}
	}
	$$$IKQEND("^||%IK.trackedSrcs",total)
}

Parameter GetSimilarRT = "srcId:%Integer,extId:%String,percentageMatched:%Numeric,percentageNew:%Numeric,nbOfEntsInRefSrc:%Integer,nbOfEntsInCommon:%Integer,nbOfEntsInSimSrc:%Integer,score:%Numeric";

///  <p>Retrieves those sources that have similar content to the one specified
///  through the <i>sourceId</i> parameter. Similarity is expressed by the (approximated)
///  ratio between the length of the source and the overlap with the starting source, based on the
///  chosen <i>algorithm</i> (according to the algorithm-specific <i>algorithmParams</i>).</p>
///  <p><b>Note:</b> whenever possible, use a filter object to limit the search space for this query to perform
///  adequately.</p>
///  <p>If the supplied Source ID is negative, it is treated as a Virtual Source. While this allows
///  looking for sources similar to a Virtual Source, the query will not verify against other 
///  Virtual Sources and they will therefore not appear in the results of this query.</p>
///  <p>The <i>skipListIds</i> parameter allows a user to select one or more SkipLists of which the elements 
///  should be completely ignored in the similarity algorithm. Skiplisted elements will be ignored
///  both for selecting similar candidates AND the calculation of their similarity score.</p>
/// 
///  <p>The following algorithms are currently available:</p>
///  <ul>
///  	<li>$$$SIMSRCSIMPLE: basic algorithm simply looking at entities (or CRCs or CCs) 
/// 				present in the reference source.<br/>Parameters:<ol>
///  			<li>targetType As %String - either "ent", "crc" or "cc" (case insensitive,
/// 				defaults to "ent"). Please note this implies the result columns will
/// 					represent the corresponding targets, despite being named "nbOf<i>Ent</i>***"</li>
/// 				</ol></li>
///  	<!--li>$$$SIMSRCEQUIVS: similar to $$$SIMSRCSIMPLE, but also taking into account equivalent terms.
///  			<br/>Parameters:<ol>
///  			<li>equivSetId As %Integer - equivalency set ID</li>
///  			</ol></li-->
///  	<li>$$$SIMSRCDOMENTS starts looking for similar sources based on dominant terms
///  			in the reference source.<br/>Parameters:<ol>
///  			<li>strict As %Boolean - whether or not to select only sources for which at least one of
///  			the reference source's dominant concepts are also dominant in a similar source. (defaults to 1)</li>
///  			</ol></li>
///  </ul>
ClassMethod GetSimilar(ByRef result, domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", algorithm As %String = {$$$SIMSRCSIMPLE}, algorithmParams As %List = "", skipListIds As %List = "") As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.GetSimSrcTgts,^||%IK.GetSimSrcEntsDom,^||%IK.SrcToTgtUniBit,^||%IK.GetSimSrcCandidates,^||%IK.GetSimSrcCandSort,^||%IK.CandSrcToTgtUniBit,^||%IK.GetSimilarSrcesSort,^||%IK.UseTheseConcepts",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$CHECKASRCIDEXISTSX(domainid,sourceid,srcDetails,vSrcId,tSC)
	
	// forward to external implementation if algorithm supplied as "classname:methodname"
	if (algorithm'=$$$SIMSRCSIMPLE) && (algorithm'=$$$SIMSRCEQUIVS) && (algorithm'=$$$SIMSRCDOMENTS) {
		set tClassName = $piece(algorithm,":",1), tMethodName = $piece(algorithm,":",2)
		if (tClassName="")||(tMethodName="") {
			set tSC = $$$ERROR($$$InvalidArgument, algorithm)
		}
		set tSC = $classmethod(tClassName, tMethodName, .result, domainid, sourceid, page, pagesize, filter, algorithmParams, skipListIds)
		quit
	}
	
	if (algorithm=$$$SIMSRCSIMPLE) {
		set tGlobs = $case($$$UPPER($lg(algorithmParams,1,"ENT")), "CRC":$lb($$$IKBCRCUNISRC,$$$IKBCRCUNIDET,$$$IKBSRCCRCUNI), "CC":$lb($$$IKBCCUNISRC,$$$IKBCCUNIDET), :$lb($$$IKBENTUNIDET,$$$IKBENTUNISRC))
	} elseif (algorithm=$$$SIMSRCEQUIVS) {
		set tGlobs = $lb($$$IKBENTUNIDET,$$$IKBENTUNISRC)
	} else { // algorithm=$$$SIMSRCDOMENTS
		set tGlobs = $lb($$$IKBENTUNIDET,$$$IKBSDORD,$$$IKBENTUNISRC)
	}
	set tGlobs = tGlobs_$lb($$$IKBSRCENTUNI)
	$$$IKQBCHECKX(domainid,tGlobs,tSC)
	
	$$$IKBUILDSKIPLIST(domainid,skipListIds,vSrcId,0)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	if (algorithm'=$$$SIMSRCSIMPLE) { $$$IKCHECKVERSIONATLEASTX(domainid,$$$IKVERSION20122,tSC) }
	
	// MHE102 - don't use the filtered count as this will discard too many entities
	set nbOfSources = ..GetCountByDomain(domainid,, .tSC)
	quit:$$$ISERR(tSC)
	
	// for virtual sources, we'll have to calculate this separately later on, otherwise
	// it'll be calculated on the fly.
	set nbOfTgtsInRefSrc = 0
	
	// first derive target type from params
	if (algorithm = $$$SIMSRCSIMPLE) {
		$$$IKENSURELISTSTR(algorithmParams)
		set tTarget = $$$UPPER($lg(algorithmParams,1,"ENT"))
	} else {
		set tTarget = "ENT"
	}
	
	if (tTarget = "ENT") {
		set nbOfTgtsInRefSrc = ##class(%iKnow.Queries.EntityAPI).GetCountBySource(domainid,sourceid,,,skipListIds,$$$ENTTYPECONCEPT)
		set gSrcToTarget = "^IRIS.IK.SrcToEntUniBit", gTargetToSrc = "^IRIS.IK.EntUniToSrcBit"
		set gRSrcToTarget = $s(vSrcId:"^IRIS.IKV.SrcToEntUniBit("_domainid_","_vSrcId_")",
							 1:"^IRIS.IK.SrcToEntUniBit("_domainid_","_sourceid_")")
		
		// BDB925 - build concept list earlier
		if vSrcId {
			set vEntUniId = ""
			for {
				set vEntUniId = $order(^IRIS.IKV.EntUniDetails(domainid,vSrcId,vEntUniId),1,details)
				quit:vEntUniId=""
				continue:('$ld(details,1,f))||('f)||('$ld(details,3,id))||'id
				$$$IKBITOFFPOS(id,off,pos)
				set $bit(^||%IK.UseTheseConcepts(off), pos) = 1
			}
		} else {
			set entUniId = ""
			for {
				set entUniId = $order(^IRIS.IK.EntSrcDetails(domainid,sourceid,entUniId),1,details)
				quit:entUniId=""
				continue:('$ld(details,1,f))||('f)
				$$$IKBITOFFPOS(entUniId,off,pos)
				set $bit(^||%IK.UseTheseConcepts(off), pos) = 1
			}
		}
	} elseif (tTarget = "CRC") {
		set nbOfTgtsInRefSrc = ##class(%iKnow.Queries.CrcAPI).GetCountBySource(domainid,sourceid)
		set gSrcToTarget = "^IRIS.IK.SrcToCrcUniBit", gTargetToSrc = "^IRIS.IK.CrcUniToSrcBit"
		set gRSrcToTarget = $s(vSrcId:"^IRIS.IKV.SrcToCrcUniBit("_domainid_","_vSrcId_")",
							 1:"^IRIS.IK.SrcToCrcUniBit("_domainid_","_sourceid_")")
	} else { // tTarget = "CC"
		set nbOfTgtsInRefSrc = ##class(%iKnow.Queries.CcAPI).GetCountBySource(domainid,sourceid)
		set gSrcToTarget = "^IRIS.IK.SrcToCcUniBit", gTargetToSrc = "^IRIS.IK.CcUniToSrcBit"
		set gRSrcToTarget = $s(vSrcId:"^IRIS.IKV.SrcToCcUniBit("_domainid_","_vSrcId_")",
							 1:"^IRIS.IK.SrcToCcUniBit("_domainid_","_sourceid_")")
	}
	
	// BDB252 - ensure maxSpread is not prohibitive in very small domains
	set maxSpread = $s(nbOfSources<10:nbOfSources+1, 1:(nbOfSources/3))
	
	// step 1: select the most probably relevant terms in the source (top N)
	if (algorithm = $$$SIMSRCSIMPLE) {
		
		set tgtOffset = ""
		for {
			set tgtOffset = $order(@gRSrcToTarget@(tgtOffset), 1, tgtBits)
			quit:tgtOffset=""
			
			set:tTarget="ENT" tgtBits = $bitlogic(tgtBits & ~$$$IKSKIPLISTBITS(tgtOffset))
		
			set tgtPos = 0
			for {
				set tgtPos = $bitfind(tgtBits, 1, tgtPos + 1)
				quit:tgtPos=0
			
				$$$IKGETIDOFFPOS(tgtId,tgtOffset,tgtPos)
				
				if (tTarget = "ENT") {
					// for now, we just check if the spread is above 1 and below maxSpread
					// (defaults to 1/3 of the nbOfSources); and whether it occurs more often
					// as a concept than a relation
					set entDetails = ^IRIS.IK.EntUniDetails(domainid, tgtId), 
						$lb(freqCon, freqRel, spread) = $li(entDetails,1,3)
			
					if ((spread > (1-''vSrcId)) && (spread < maxSpread) && (freqCon > freqRel)) {
						set $bit(^||%IK.GetSimSrcTgts(tgtOffset), tgtPos) = 1
					}
				} elseif (tTarget = "CRC") {
					set:vSrcId||($lg(^IRIS.IK.CrcUniDetails(domainid,tgtId),1)>1) $bit(^||%IK.GetSimSrcTgts(tgtOffset), tgtPos) = 1
				} else { // if (tTarget = "CC") {
					set:vSrcId||($lg(^IRIS.IK.CcUniDet(domainid,tgtId),1)>1) $bit(^||%IK.GetSimSrcTgts(tgtOffset), tgtPos) = 1
				}
			}
		}
		
	} elseif (algorithm = $$$SIMSRCEQUIVS) {
		
		set tTarget="ENT", gSrcToTarget="^IRIS.IK.SrcToEntUniBit", gTargetToSrc = "^IRIS.IK.EntUniToSrcBit"
		set srcToEntUniGlo = "^||%IK.SrcToTgtUniBit("_sourceid_")"
		set equivSetId = +$lg(algorithmParams,1)
		kill @srcToEntUniGlo
		
		// expand with the equivalents
		if (vSrcId) {
			merge @srcToEntUniGlo = ^IRIS.IKV.SrcToEntUniBit(domainid,vSrcId)
		} else {
			merge @srcToEntUniGlo = ^IRIS.IK.SrcToEntUniBit(domainid,sourceid)
		}
		
		set entOffset=""
		for {
			if (vSrcId) {
				set entOffset = $o(^IRIS.IKV.SrcToEntUniBit(domainid,vSrcId,entOffset),1,entBits)
			} else {
				set entOffset = $o(^IRIS.IK.SrcToEntUniBit(domainid,sourceid,entOffset),1,entBits)
			}
			q:entOffset=""
			
			set entBits = $bitlogic(entBits & ~$$$IKSKIPLISTBITS(entOffset))
		
			set entPos=0
			for {
				set entPos=$bitfind(entBits,1,entPos+1)
				q:entPos=0
			
				$$$IKGETIDOFFPOS(entId,entOffset,entPos)
			
				k res
				do ##class(%iKnow.Queries.EquivAPI).GetTerms(.res,1,equivSetId,entId,0,0)
				set x=""
				for {
					set x=$o(res(x),1,equivData)
					q:x=""
				
					set equivId=$list(equivData,1)
					$$$IKBITOFFPOS(equivId,equivOff,equivPos)
					set $bit(@srcToEntUniGlo@(equivOff),equivPos)=1
				
					set entDetails = $g(^IRIS.IK.EntUniDetails(domainid, equivId))
			
					if (($lg(entDetails, 3) > (1-''vSrcId)) && ($lg(entDetails, 3) < maxSpread) 
							&& ($lg(entDetails, 1) > $lg(entDetails, 2))) {
						set $bit(^||%IK.GetSimSrcTgts(equivOff), equivPos) = 1
					}
				}
			
				set entDetails = $g(^IRIS.IK.EntUniDetails(domainid, entId))
			
				if (($lg(entDetails, 3) > (1-''vSrcId)) && ($lg(entDetails, 3) < maxSpread) 
						&& ($lg(entDetails, 1) > $lg(entDetails, 2))) {
					set $bit(^||%IK.GetSimSrcTgts(entOffset), entPos) = 1
				}
			}
			
		}
		
	} elseif (algorithm = $$$SIMSRCDOMENTS) {
		
		if (vSrcId) {
			set tSC = $$$ERROR($$$NotImplemented)
			quit
		}
		
		set tTarget="ENT", gSrcToTarget="^IRIS.IK.SrcToEntUniBit", gTargetToSrc = "^IRIS.IK.EntUniToSrcBit"
		
		set paramStrict = +$lg(algorithmParams,1,1)
		set srcToEntUniGlo = $s(vSrcId:"^IRIS.IKV.SrcToEntUniBit("_domainid_","_vSrcId_")",
								 1:"^IRIS.IK.SrcToEntUniBit("_domainid_","_sourceid_")")

		set tSC = ##class(%iKnow.Semantics.DominanceAPI).GetProfileBySource(.domEnts, domainid, sourceid, 0, 0, $$$SDCONCEPT)
		quit:$$$ISERR(tSC)
		
		set i = ""
		for {
			set i = $order(domEnts(i),1,d)
			quit:i=""
			
			set entUniId = $lg(d,1)
			continue:$$$IKISSKIPLISTED(entUniId)
			
			$$$IKBITOFFPOS(entUniId,entOffset,entPos)
			set $bit(^||%IK.GetSimSrcTgts(entOffset), entPos) = 1
			set ^||%IK.GetSimSrcTgtsDom(entUniId) = $lg(d,4)
		}
		kill domEnts
	}
	
	/* BDB522 - expand to all actual forms
	if (tTarget="ENT") && $$$GETPARAMNODEF(domainid,$$$IKPSTEMMING) {
		merge tBaseForms = ^||%IK.GetSimSrcTgts
		set tgtOffset = ""
		for {
			set tgtOffset = $order(tBaseForms(tgtOffset), 1, tgtBits)
			quit:tgtOffset=""
			
			set tgtPos = 0
			for {
				set tgtPos = $bitfind(tgtBits, 1, tgtPos + 1)
				quit:tgtPos=0
				$$$IKGETIDOFFPOS(tgtId,tgtOffset,tgtPos)
				
				kill tActualForms
				merge tActualForms = ^IRIS.IK.EntUniActual(domainid,tgtId)
				set tActualEntId = ""
				for {
					set tActualEntId = $order(tActualForms(tActualEntId))
					quit:tActualEntId=""
					$$$IKBITOFFPOS(tActualEntId,tActualOffset,tActualPos)
					set $bit(^||%IK.GetSimSrcTgts(tActualOffset),tActualPos)=1
				}
			}
		}
	}*/
	
	// step 2: select all sources containing at least one of these N target elements
	set tgtOffset = ""
	for {
		set tgtOffset = $order(^||%IK.GetSimSrcTgts(tgtOffset), 1, tgtBits)
		quit:tgtOffset=""
		
		set tgtPos = 0
		for {
			set tgtPos = $bitfind(tgtBits, 1, tgtPos + 1)
			quit:tgtPos=0
			
			$$$IKGETIDOFFPOS(tgtId,tgtOffset,tgtPos)
			$$$IKMERGEBITSOR(gTargetToSrc_"("_domainid_","_tgtId_")","^||%IK.GetSimSrcCandidates")
		}
	}
	
	// apply the filter
	if $isobject(filter) {
		set tSC = filter.MergeBits("^||%IK.GetSimSrcCandidates")
		quit:$$$ISERR(tSC)
	}
	
	// make sure the document itself is skipped
	if ('vSrcId) {
		$$$IKSETBITLOCAL(^||%IK.GetSimSrcCandidates,sourceid,0)
	}
	
	// step 3: sort these candidates by the number of target elements they share with the 
	//			reference documents (approximate score)
	set minimalMatches = $s(nbOfTgtsInRefSrc>30:(nbOfTgtsInRefSrc/10), 1:3) // BDB914
	set srcOffset = ""
	for {
		set srcOffset = $order(^||%IK.GetSimSrcCandidates(srcOffset), 1, srcBits)
		quit:srcOffset=""
		
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits, 1, srcPos+1)
			quit:srcPos=0
			
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			
			set matches = 0
			if (algorithm = $$$SIMSRCSIMPLE) {
				
				set tgtOffset = ""
				for {
					set tgtOffset = $order(^||%IK.GetSimSrcTgts(tgtOffset), 1, tgtBits)
					quit:tgtOffset=""
				
					set matches = matches + $bitcount($bitlogic(tgtBits & @gSrcToTarget@(domainid, srcId, tgtOffset)), 1)
				}
				
			} elseif (algorithm = $$$SIMSRCEQUIVS) {
				
				merge ^||%IK.CandSrcToTgtUniBit(srcId) = ^IRIS.IK.SrcToEntUniBit(domainid,srcId)
				set entOffset = ""
				for {
					set entOffset=$o(^IRIS.IK.SrcToEntUniBit(domainid, srcId, entOffset),1,entBits)
					q:entOffset=""
					
					set entPos=""
					for {
						set entPos=$bitfind(^IRIS.IK.SrcToEntUniBit(domainid, srcId, entOffset),1,entPos+1)
						q:entPos=0
						
						$$$IKGETIDOFFPOS(entId,entOffset,entPos)
						k res
						do ##class(%iKnow.Queries.EquivAPI).GetTerms(.res,1,equivSetId,entId,0,0)
						set x=""
						for {
							set x=$o(res(x),1,equivData)
							q:x=""
							
							set equivId=$list(equivData)
							$$$IKBITOFFPOS(equivId,equivOff,equivPos)
							set $bit(^||%IK.CandSrcToTgtUniBit(srcId,equivOff),equivPos)=1
						}
					}
				}
				
				set entOffset = ""
				for {
					set entOffset = $order(^||%IK.GetSimSrcTgts(entOffset), 1, entBits)
					quit:entOffset=""
				
					set matches = matches + $bitcount($bitlogic(entBits & ^||%IK.CandSrcToTgtUniBit(srcId, entOffset)), 1)
				}
				
			} elseif (algorithm = $$$SIMSRCDOMENTS) {
				
				if (paramStrict) {
					set domProfile = $g(^IRIS.IK.SD.Profile(domainid, srcId),$lb(0,0))
					set domFrom = -$li(domProfile,2), domTo = -$li(domProfile,1)
				}
				
				set entUniId=""
				for {
					set entUniId = $order(^||%IK.GetSimSrcTgtsDom(entUniId),1,refDomVal)
					quit:entUniId=""
					
					set domInfo = $g(^IRIS.IK.EntSrcDetails(domainid, srcId, entUniId))
					set domVal = $lg(domInfo,3) + $lg(domInfo,4)
					continue:paramStrict&&(domVal<domFrom)
					continue:paramStrict&&domTo&&(domVal>domTo)
					
					// TODO: refine paramStrict=0 case
					set matches = matches + $s(paramStrict:1, 1:domVal) 
				}
				
			}
			
			// add srcId as a deduplicator
			// TODO: adding the difference in src length might make sense here
			set:matches>=minimalMatches ^||%IK.GetSimSrcCandSort(-matches, srcId) = ""
		}
	}
	
	// step 4: of these sources, calculate the actual similarity score for the
	//			top M sources with the best approximate score
	set approxMatch = ""
	for {
		set approxMatch = $order(^||%IK.GetSimSrcCandSort(approxMatch))
		quit:approxMatch=""
		
		set srcId = ""
		for {
			set srcId = $order(^||%IK.GetSimSrcCandSort(approxMatch, srcId))
			quit:srcId=""
			
			if (tTarget = "ENT") {
				set nbOfTgtsInSimSrc = ##class(%iKnow.Queries.EntityAPI).GetCountBySource(domainid,srcId,,,skipListIds,$$$ENTTYPECONCEPT)
			} elseif (tTarget = "CRC") {
				set nbOfTgtsInSimSrc = ##class(%iKnow.Queries.CrcAPI).GetCountBySource(domainid,srcId)
			} else { // tTarget = "CC"
				set nbOfTgtsInSimSrc = ##class(%iKnow.Queries.CcAPI).GetCountBySource(domainid,srcId)
			}
			
			// now calculate the actual match score
			set nbOfTgtsInCommon = 0
			set tgtOffset = ""
			for {
				if (algorithm = $$$SIMSRCEQUIVS) {
					set tgtOffset = $order(^||%IK.CandSrcToTgtUniBit(srcId,tgtOffset), 1, tgtBits)
				} else {
					set tgtOffset = $order(@gSrcToTarget@(domainid, srcId, tgtOffset), 1, tgtBits)
				}
				quit:tgtOffset=""
				
				// exclude skiplists
				// BDB914 - only count concepts
				set:tTarget="ENT" tgtBits = $bitlogic(tgtBits & ~$$$IKSKIPLISTBITS(tgtOffset) & ^||%IK.UseTheseConcepts(tgtOffset))
				set nbOfTgtsInCommon = nbOfTgtsInCommon + $bitcount($bitlogic(tgtBits & @gRSrcToTarget@(tgtOffset)), 1)
			}
			set percentageMatched=0
			set percentageNew=0
			set:nbOfTgtsInRefSrc'=0 percentageMatched = nbOfTgtsInCommon / nbOfTgtsInRefSrc
			set:nbOfTgtsInSimSrc'=0 percentageNew = (nbOfTgtsInSimSrc - nbOfTgtsInCommon) / nbOfTgtsInSimSrc
			
			set matchScore = $case(algorithm, $$$SIMSRCDOMENTS:-approxMatch, :percentageMatched)
			
			// store the result in the sorted global
			set ^||%IK.GetSimilarSrcesSort(-matchScore, srcId) = $lb(+srcId, ..GetExternalId(domainid,srcId), +$justify(percentageMatched, 0, 4), +$justify(percentageNew, 0, 4), +nbOfTgtsInRefSrc, +nbOfTgtsInCommon, +nbOfTgtsInSimSrc, +$justify(matchScore,0,4))
			
			// check if we have enough results and can exit (paging window)
			// TODO
		}
	}
	
	// step 5: now store the page window in the final result PPG
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.GetSimilarSrcesSort",usePaging,first,last)

	$$$IKCLEANSKIPLIST
	$$$IKQENDCATCH(result,"^||%IK.GetSimSrcTgts,^||%IK.GetSimSrcTgtsDom,^||%IK.SrcToTgtUniBit,^||%IK.GetSimSrcCandidates,^||%IK.GetSimSrcCandSort,^||%IK.CandSrcToTgtUniBit,^||%IK.GetSimilarSrcesSort,^||%IK.UseTheseConcepts",tSC)
}

Parameter GetAttributesRT = "attTypeId:%Integer,attType:%String,level:%Integer,targetId:%Integer,startPos:%Integer,span:%Integer,properties:%String";

/// <p>Returns all the attributes of the Entity Occurrences, Paths and Sentences enclosed in the
/// specified source, optionally filtered by level through <var>pLevel</var> and/or <var>pType</var>.</p>
/// <p>Please note the <i>startPos</i> and <i>span</i> result columns refer to positions within
/// the path for path-level attributes (level=$$$IKATTLVLPATH) and sentence positions for the
/// other attributes (level=$$$IKATTLVLSENT).</p>
ClassMethod GetAttributes(ByRef pResult, pDomainId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pTypes As %List = "", pLevel As %Integer = {$$$IKATTLVLANY}) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	if (pSrcId<0) && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	$$$IKCHECKVERSIONATLEASTX(pDomainId,$$$IKVERSIONATTRIBUTES,tSC)
	$$$CHECKASRCIDEXISTSX(pDomainId,pSrcId,tSrcDetails,vSrcId,tSC)
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	
	set gAttPath = $$$IKVGLOBNAME(pDomainId,"Att.Path",vSrcId)
	set gAttSent = $$$IKVGLOBNAME(pDomainId,"Att.Sent",vSrcId)
	//set gAttEntOcc = $$$IKVGLOBNAME(pDomainId,"Att.EntOcc",vSrcId)
	
	/*if (pLevel = $$$IKATTLVLENTOCC) || (pLevel = $$$IKATTLVLANY) {
		set tEntOccId = $li(tSrcDetails,3), tMaxEntOccId = tEntOccId+$li(tSrcDetails,4)
		for {
			set tEntOccId = $order(@gAttEntOcc@(tEntOccId))
			quit:tEntOccId=""
			quit:tEntOccId>tMaxEntOccId
			
			set tAttTypeId = ""
			for {
				set tAttTypeId = $order(@gAttEntOcc@(tEntOccId, tAttTypeId),1,tAtt)
				quit:tAttTypeId=""
				continue:(pTypes'="")&&'$lf(pTypes,tAttTypeId)
				
				set x = $i(tCount)
				$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
				$$$IKQADDRESULT(pResult,tCount,$lb(+tAttTypeId,$$$IKATTTYPENAME(tAttTypeId),$$$IKATTLVLENTOCC,+tEntOccId,1,1,$lts($li(tAtt,2,$ll(tAtt)),,1)))
			}
		}
	}*/
	
	if (pLevel = $$$IKATTLVLPATH) || (pLevel = $$$IKATTLVLANY) {
		set tPathId = $li(tSrcDetails,7), tMaxPathId = tPathId+$li(tSrcDetails,8)
		for {
			set tPathId = $order(@gAttPath@(tPathId))
			quit:tPathId=""
			quit:tPathId>tMaxPathId
			
			set tAttTypeId = ""
			for {
				set tAttTypeId = $order(@gAttPath@(tPathId, tAttTypeId))
				quit:tAttTypeId=""
				continue:(pTypes'="")&&'$lf(pTypes,tAttTypeId)
				
				set tStartPos = ""
				for {
					set tStartPos = $order(@gAttPath@(tPathId, tAttTypeId, tStartPos), 1, tAtt)
					quit:tStartPos=""
					
					set x = $i(tCount)
					$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
					set tSpan = $li(tAtt,1), tProps = $li(tAtt,2,$ll(tAtt))
					$$$IKQADDRESULT(pResult,tCount,$lb(+tAttTypeId,$$$IKATTTYPENAME(tAttTypeId),$$$IKATTLVLPATH,+tPathId,+tStartPos,tSpan,$lts(tProps,,1)))
				}
			}
		}
	}
	
	if (pLevel = $$$IKATTLVLSENT) || (pLevel = $$$IKATTLVLANY) {
		set tSentId = $li(tSrcDetails,1), tMaxSentId = tSentId+$li(tSrcDetails,2)
		for {
			set tSentId = $order(@gAttSent@(tSentId))
			quit:tSentId=""
			quit:tSentId>tMaxSentId
			
			set tAttTypeId = ""
			for {
				set tAttTypeId = $order(@gAttSent@(tSentId, tAttTypeId))
				quit:tAttTypeId=""
				continue:(pTypes'="")&&'$lf(pTypes,tAttTypeId)
				
				set tStartPos = ""
				for {
					set tStartPos = $order(@gAttSent@(tSentId, tAttTypeId, tStartPos), 1, tAtt)
					quit:tStartPos=""
					
					set x = $i(tCount)
					$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
					set tSpan = $li(tAtt,1), tProps = $li(tAtt,tSpan+2,$ll(tAtt))
					$$$IKQADDRESULT(pResult,tCount,$lb(+tAttTypeId,$$$IKATTTYPENAME(tAttTypeId),$$$IKATTLVLSENT,+tSentId,+tStartPos,tSpan,$lts(tProps,,1)))
				}
			}
		}
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

}
