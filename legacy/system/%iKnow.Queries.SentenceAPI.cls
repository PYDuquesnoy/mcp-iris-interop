/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// Main Query API class to retrieve sentence information.
Class %iKnow.Queries.SentenceAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

/// <p>This method rebuilds a sentence based on the literals and entities it is composed of.</p>
/// <p>The string returned is the first part, up to the maximum string length, whereas the 
/// output parameter <i>fullSentence</i> is an array containing all the parts in the right order, containing
/// a %Boolean value at the top level indicating whether the returned string is the full sentence (1)
/// or (if 0) the user should have to look into this array to learn the full sentence.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
ClassMethod GetValue(domainid As %Integer, sentenceid As %Integer, Output fullSentence As %Boolean = 1, vSrcId As %Integer = 0) As %String(MAXLEN=32767)
{
	$$$IKCHECKPRIVREADR(sc,"")
	if (vSrcId) {
		set vSrcId = $zabs(vSrcId)
		set ents = $g(^IRIS.IKV.SentId(domainid, vSrcId, sentenceid))
	} else {
		set ents = $g(^IRIS.IK.SentId(domainid, sentenceid))
	}
	quit:ents="" ""
	
	set entUniIdGlo = $$$IKVGLOBNAME(domainid, "EntUniId", vSrcId)
	set litUniIdGlo = $$$IKVGLOBNAME(domainid, "LitUniId", vSrcId)
	
	kill fullSentence
	set ptr = 0, part = 1, fullSentence = 1, fullSentence(1) = ""
	while ($listnext(ents, ptr, id)) {
		continue:id=0
		
		set prependSpace = (fullSentence(part)'="")
		if (id > 0) {
			set next = @entUniIdGlo@(id)
		} else {
			set next = @litUniIdGlo@(-id)
			
			// literals starting with a space indicate they should not be prepended with one
			if ($e(next,1)=" ") {
				set next = $e(next,2,*)
				set prependSpace = 0
			}
		}
		set:prependSpace next = " "_next
		
		if ($length(fullSentence(part)) + $length(next) + 1 > 32000) {
			set part = part+1, fullSentence = 0
		}
		set fullSentence(part) = $g(fullSentence(part)) _ next
	}
	
	quit fullSentence(1)
}

/// Returns the source ID in which the supplied sentence ID occurs
ClassMethod GetSourceId(domainId As %Integer, sentenceId As %Integer) As %Integer
{
	$$$IKCHECKPRIVREADR(sc,-1)
    set sentBase = $order(^IRIS.IK.SentToSrc(domainId, sentenceId),-1, sentDetails)
    quit:sentBase="" -1 // inexistent sentence
    quit:(sentBase+$lg(sentDetails,2))<sentenceId -1  // inexistent sentence (gap)
    quit +$lg(sentDetails,1)
}

/// Returns the position within the source this sentence occurs at (1-based).
ClassMethod GetPosition(domainId As %Integer, sentenceId As %Integer, vSrcId As %Integer = 0) As %Integer
{
	quit:vSrcId sentenceId
	$$$IKCHECKPRIVREADR(sc,-1)
	set sentBase = $order(^IRIS.IK.SentToSrc(domainId, sentenceId),-1)
    quit:$g(sentBase)="" -1
    quit sentenceId-sentBase
}

/// Returns the literal of the entity or nonrelevant at the specified position.
ClassMethod GetPartLiteral(domainId As %Integer, sentenceId As %Integer, position As %Integer, vSrcId As %Integer = 0) As %String
{
	$$$IKCHECKPRIVREADR(pSC,"")
	set litOrEntUniId = $lg($s(vSrcId:$g(^IRIS.IKV.SentId(+domainId,$zabs(vSrcId),+sentenceId)), 1:$g(^IRIS.IK.SentId(+domainId,+sentenceId))),+position)
	quit:'litOrEntUniId ""
	if (litOrEntUniId>0) {
		quit $s(vSrcId:$g(^IRIS.IKV.EntUniId(domainId, $zabs(vSrcId), litOrEntUniId)), 1:$g(^IRIS.IK.EntUniId(domainId, litOrEntUniId)))
	} else {
		quit $s(vSrcId:$g(^IRIS.IKV.LitUniId(domainId, $zabs(vSrcId), -litOrEntUniId)), 1:$g(^IRIS.IK.LitUniId(domainId, -litOrEntUniId)))
	}
}

/// <p>Retrieves the language of the given sentence, as derived by the Automatic Language Identification
/// algorithm or, if ALI was disabled, the language specified when indexing this sentence.</p>
/// <p>The confidence level is returned as well through an output parameter.
/// If the confidence level is 0, this means ALI was not used and the language was defined by the
/// user loading the source.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
ClassMethod GetLanguage(domainid As %Integer, sentenceid As %Integer, Output confidence As %Numeric = "", vSrcId As %Integer = 0) As %String
{
	$$$IKCHECKPRIVREADR(sc,"")
	set sentDetails = $g(@$$$IKVGLOBNAME(domainid,"SentDetails",vSrcId)@(sentenceid))
	if (sentDetails="") { set confidence = 0  quit "" }
	
	set confidence = $li(sentDetails,2)
	quit $li($$$IKLANGUAGES, $li(sentDetails,1))
}

Parameter GetPartsRT = "entOccId:%Integer,entUniId:%Integer,literal:%String,role:%Integer,stemUniId:%Integer";

/// <p>Returns the elements (concepts, relations and nonrelevants) that make up the sentence,
/// optional including markers for the beginning and end of any CRCs or Paths in the sentence. This
/// information can be used to display the sentence value (see also <method>GetValue</method>)
/// and/or highlight specific elements of interest.</p>
/// <blockquote>Output structure: 
/// <pre>result(pos) = $lb(entOccId, entUniId, entity, role)</pre>
/// when includeCRCMarkers = 1, adds 
/// <pre>result(pos, [CRCHEAD | CRCRELATION | CRCTAIL]) = $lb(crcOccId, crcUniId)</pre>
/// when includePathMarkers = 1, adds 
/// <pre>result(pos, [PATHBEGIN | PATHEND]) = $lb(pathId)</pre>
/// </blockquote>
/// <p>Note: the subscript levels for CRC and Path markers are not available in the QAPI and WSAPI
/// versions of this query.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
ClassMethod GetParts(ByRef result, domainid As %Integer, sentenceid As %Integer, includeCRCMarkers As %Boolean = 0, includePathMarkers As %Boolean = 0, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if vSrcId && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	quit:'+sentenceid
	
	// BDB577
	set tVersionTables = $$$IKVERSIONATLEAST(domainid,$$$IKVERSIONTABLES)
	
	set vSrcId = $zabs(vSrcId)
	set ents = $g(@$$$IKVGLOBNAME(domainid,"SentId",vSrcId)@(sentenceid))
	quit:ents=""
	
	set sentDetails = $g(@$$$IKVGLOBNAME(domainid,"SentDetails",vSrcId)@(sentenceid))
	set entOccBase = $lg(sentDetails, 4)
	set entOccId = entOccBase
	
	set nonRelBitGlo = $$$IKVGLOBNAME(domainid, "SentNonRelBit", vSrcId)
	set entUniIdGlo = $$$IKVGLOBNAME(domainid, "EntUniId", vSrcId)
	set litUniIdGlo = $$$IKVGLOBNAME(domainid, "LitUniId", vSrcId)
	set entOccIdGlo = $$$IKVGLOBNAME(domainid, "EntOccId", vSrcId)
	set crcOccIdGlo = $$$IKVGLOBNAME(domainid, "CrcOccId", vSrcId)
	
	set pos = 0, ptr = 0, prevPathId = 0, prevNonRelBitOffset = 0, nonRel = 0
	while ($listnext(ents, ptr, id)) {
		set pos = pos+1
		
		if ('tVersionTables) {
			set nonRelBitOffset = pos\64000+1
			if (nonRelBitOffset '= prevNonRelBitOffset) {
				set nonRelBits = $g(@nonRelBitGlo@(sentenceid, nonRelBitOffset))
				set prevNonRelBitOffset = nonRelBitOffset
			}
		}
		
		if (id = 0) {
			$$$IKQADDRESULT(result,pos,$lb(0, 0, "", $$$NONREL,))
			continue
		} elseif (id > 0) {
			set str = @entUniIdGlo@(id)
			set nonRel = 0
		} else {
			set str = $zstrip(@litUniIdGlo@(-id), "<W")
			set:'tVersionTables nonRel = $bit(nonRelBits, pos+1)
		}
		
		if ('tVersionTables && nonRel) {
			$$$IKQADDRESULT(result,pos,$lb(0, 0, str, $$$NONREL,))
		} else {
			set entOccId = entOccId+1
			set entOcc = @entOccIdGlo@(entOccId)
			set tRole = $lg(entOcc,2)
			
			if (tVersionTables && (tRole=$$$ENTTYPENONREL)) {
				$$$IKQADDRESULT(result,pos,$lb(entOccId, 0, str, $$$NONREL,))
				continue
			}
			
			set entUniId = +$lg(entOcc,1)
			set entOccPositions(entOccId) = pos
			
			$$$IKQADDRESULT(result,pos,$lb(entOccId, entUniId, str, tRole)_$s($ld(entOcc,10,stemUniId):$lb(stemUniId), 1:$lb()))
			
			if (includeCRCMarkers) {
				set crcOccId = $lg(entOcc,5,0)
				if (crcOccId) {
					$$$IKQADDRESULTSUB(result,pos,"CRCHEAD",$lb(crcOccId, $li(@crcOccIdGlo@(crcOccId),1)))
				}
				set crcOccId = $lg(entOcc,6,0)
				if (crcOccId) {
					$$$IKQADDRESULTSUB(result,pos,"CRCRELATION",$lb(crcOccId, $li(@crcOccIdGlo@(crcOccId),1)))
				}
				set crcOccId = $lg(entOcc,7,0)
				if (crcOccId) {
					$$$IKQADDRESULTSUB(result,pos,"CRCTAIL",$lb(crcOccId, $li(@crcOccIdGlo@(crcOccId),1)))
				}
			}
			
			if (includePathMarkers) {
				set pathId = $lg(entOcc,8,0)
				if (pathId '= prevPathId) {
					if (pathId) {
						$$$IKQADDRESULTSUB(result,pos,"PATHBEGIN",$lb(pathId))
					}
					if (prevPathId) {
						$$$IKQADDRESULTSUB(result,prevPosInPath,"PATHEND",$lb(prevPathId))
					}
				}
				set prevPathId = pathId
				set prevPosInPath = pos
			}
			
		}
	}
	if (includePathMarkers) {
		if (prevPathId) {
			$$$IKQADDRESULTSUB(result,prevPosInPath,"PATHEND",$lb(prevPathId))
		}
	}
	$$$IKQENDCATCH(result,"",tSC)
}

Parameter GetBySourceRT = "sentId:%Integer,sentenceValue:%String,sentenceIsTruncated:%Boolean";

/// Returns the sentences for the given source. A negative source ID is interpreted as a Virtual Source.
ClassMethod GetBySource(ByRef result, domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (sourceid<0) && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	$$$CHECKASRCIDEXISTSX(domainid,sourceid,sentInfo,vSrcId,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// loop through the sentences for this source
	set sentBase = $list(sentInfo, 1)
	set sentCount = $list(sentInfo, 2)
	for sentPos = 1:1:sentCount {
		set sentId = sentBase + sentPos
		
		set count = count + 1
		$$$IKCHECKPAGING(usePaging,first,last,count)
		
		set sentValue = ..GetValue(domainid, sentId, .fullSentence, vSrcId)
		$$$IKQADDRESULT(result,count,$lb(sentId, sentValue, 1-fullSentence))
	}
	$$$IKQENDCATCH(result,"",tSC)
}

/// <p>Returns the total number of sentences for a given domain, optionally filtered to those sources
/// satisfying a <class>%iKnow.Filters.Filter</class> object passed in through <i>filter</i>.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	set total = 0
	
	if ($isobject(filter)) {
		
		set srcOffset = ""
		for {
			set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
			quit:srcOffset=""
			
			set srcPos = 0
			for {
				set srcPos = $bitfind(srcBits, 1, srcPos + 1)
				quit:srcPos=0
				
				$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
				
				set total = total + $list(^IRIS.IK.SrcDetails(domainid, srcId), 2)
			}
		}
		
	} else {
		
		set sentId = ""
		for {
			set sentId = $order(^IRIS.IK.SentId(domainid, sentId))
			quit:sentId=""
			
			set total = total + 1
		}
	}
	
	quit total
}

/// <p>Returns the total number of sentences for the given sources. Negative Source IDs are
/// interpreted as referring to Virtual Sources.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %List, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	set total = 0, ptr = 0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:'+srcId
		$$$CHECKASRCIDEXISTSX(domainid,srcId,srcDetails,vSrcId,sc)
		set total = total + $lg(srcDetails,2)
	}
	quit:$$$ISERR(sc) -1
	
	quit total
}

Parameter GetByEntitiesRT = "srcId:%Integer,externalId:%String,sentId:%Integer,sentenceValue:%String";

/// <p>This method will retrieve all sentences containing any (if <i>setop</i> = $$$UNION) or all
/// (if <i>setop</i> = $$$INTERSECT) of the entities supplied through <i>entitylist</i>, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sentences containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sentences containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(ByRef result, domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	if (domainid'=0) { $$$CHECKDOMAINEXISTS(domainid) }
	quit:entitylist="" $$$OK

	// accept single values and translate to a 1-member list
	if $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList, vSrcId,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByEntitiesInternal
	quit ..GetByEntitiesInternal(.result, domainid, .entIdList, filter, page, pagesize, setop)
}

Parameter GetByEntityIdsRT = "srcId:%Integer,externalId:%String,sentId:%Integer,sentenceValue:%String";

/// <p>Retrieves all sentences containing the given entity IDs., optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>entityidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(ByRef result, domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	if (domainid'=0) { $$$CHECKDOMAINEXISTS(domainid) }
	quit:entityidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean up the entityidlist into a clean %List
	if $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList, vSrcId,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByEntitiesInternal
	quit ..GetByEntitiesInternal(.result, domainid, .cleanIdList, filter, page, pagesize, setop)
}

ClassMethod GetByEntitiesInternal(ByRef result, domainid As %Integer, ByRef entitylist, filter As %iKnow.Filters.Filter, page As %Integer, pagesize As %Integer, setop As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.SentBits",tSC)
	quit:'entitylist
	
	// BDB522
	set t2LevelAND = ($d(entitylist($order(entitylist(""))))>1)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// special case to support virtual sources
	if $lv(filter) && ($lg(filter,1)<0) {
		set vSrcId = $zabs($lg(filter,1)), tSQL=""
		
		if (t2LevelAND) {
			set tEntUniId="", i=0
			for {
				set tEntUniId = $order(entitylist(tEntUniId))
				quit:tEntUniId=""
			
				// first aggregate actual forms underneath
				set tActUniId = "", tIDs=""
				for {
					set tActUniId = $order(entitylist(tEntUniId,tActUniId))
					quit:tActUniId=""
					set tIDs = tIDs_","_tActUniId
				}
				set tSQL = tSQL _ $s($i(i)=1:"", 1:" AND SentenceId IN (") _ "SELECT SentenceId FROM %iKnow_Objects.VirtualEntityOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND EntUniId IN ("_$e(tIDs,2,*)_")"_$s(i=1:"",1:")")
			}
		} elseif setop=$$$UNION {
			set tEntUniId = ""
			for {
				set tEntUniId = $order(entitylist(tEntUniId))
				quit:tEntUniId=""
			
				set tSQL = tSQL _ "," _ tEntUniId
			}
			set tSQL = "SELECT DISTINCT SentenceId FROM %iKnow_Objects.VirtualEntityOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND EntUniId IN ("_$e(tSQL,2,*)_")"
		} else {
			
			set tEntUniId = "", tEntUniCount=0
			for {
				set tEntUniId = $order(entitylist(tEntUniId))
				quit:tEntUniId=""
			
				set tSQL = tSQL _ "," _ tEntUniId, tEntUniCount=tEntUniCount+1
			}
			set tSQL = "SELECT SentenceId FROM (SELECT SentenceId, COUNT(DISTINCT EntUniId) cnt FROM %iKnow_Objects.VirtualEntityOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND EntUniId IN ("_$e(tSQL,2,*)_") GROUP BY SentenceId) WHERE cnt = "_tEntUniCount
		}
		set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
		while tResult.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			set tSentId = tResult.%GetData(1)
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
		
			// add the record to the list
			set tExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, -vSrcId)
			$$$IKQADDRESULT(result,count,$lb(-vSrcId, tExtId, tSentId, ..GetValue(domainid, tSentId,, vSrcId)))
		}
		quit
	}
	
	$$$IKQBCHECKX(domainid,$$$IKBENTUNIBIT,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	
	// first build bitmap index on sentences based on filter
	kill tFilterBits
	if $isobject(filter) {
		set tSrcId = ""
		for {
			set tSrcId = filter.GetNextSrcId(tSrcId)
			quit:tSrcId=""
			
			set tSrcDetails = $g(^IRIS.IK.SrcDetails(domainid,tSrcId))
			set tSentBase = $lg(tSrcDetails,1), tSentMax = tSentBase+$lg(tSrcDetails,2)
			for i = tSentBase+1:1:tSentMax {
				$$$IKBITOFFPOS(i,tOff,tPos)
				set $bit(tFilterBits(tOff),tPos)=1
			}
		}
	}
	
	// now combine with entity filters
	kill tSentBits
	merge:setop=$$$INTERSECT tSentBits = tFilterBits
	set tEntUniId="", tIsFirst=1
	for {
		set tEntUniId = $order(entitylist(tEntUniId))
		quit:tEntUniId=""
		
		kill tSentEntBits
		if (t2LevelAND) {
			// first aggregate actual forms underneath
			set tActUniId = ""
			for {
				set tActUniId = $order(entitylist(tEntUniId,tActUniId))
				quit:tActUniId=""
				
				set tOff=""
				for {
					if $isobject(filter) {
						set tOff = $order(tFilterBits(tOff))
						quit:tOff=""
						set tBits = $g(^IRIS.IK.EntUniToSentBit(domainid,tActUniId,tOff))
						continue:'$$$IKHASBIT(tBits)
					} else {
						set tOff = $order(^IRIS.IK.EntUniToSentBit(domainid,tActUniId,tOff), 1, tBits)
						quit:tOff=""
					}
					set tSentEntBits(tOff) = $bitlogic(tSentEntBits(tOff) | tBits)
				}
			}
		} else {
			merge tSentEntBits = ^IRIS.IK.EntUniToSentBit(domainid,tEntUniId)
		}
		
		// now merge tSentEntBits with current tSentBits
		if setop = $$$UNION {
			set tOff=""
			for {
				if $isobject(filter) {
					set tOff = $order(tFilterBits(tOff))
					quit:tOff=""
					set tBits = $g(tSentEntBits(tOff))
					continue:'$$$IKHASBIT(tBits)
				} else {
					set tOff = $order(tSentEntBits(tOff),1,tBits)
					quit:tOff=""
				}
				set tSentBits(tOff) = $bitlogic(tSentBits(tOff) | tBits)
			}
		} else {
			if tIsFirst && '$isobject(filter) {
				merge tSentBits = tSentEntBits
				set tIsFirst=0
			} else {
				set tOff=""
				for {
					set tOff = $order(tSentBits(tOff),1,tBits)
					quit:tOff=""
					set tSentBits(tOff) = $bitlogic(tSentEntBits(tOff) & tBits)
				}
			}
		}
	}
	
	// still have to enforce filter if $$$UNION
	if (setop=$$$UNION) && $isobject(filter) {
		set tOff = ""
		for {
			set tOff = $order(tSentBits(tOff),1,tBits)
			quit:tOff=""
			set tSentBits(tOff) = $bitlogic(tBits & tFilterBits(tOff))
		}
	}
	
		
	// now loop through the matching sentences
	set tOff = ""
	for {
		set tOff = $order(tSentBits(tOff),-1,tBits)
		quit:tOff=""
		
		set tPos=1
		for {
			set tPos = $bitfind(tBits,1,tPos-1,-1)
			quit:tPos=0
			
			$$$IKGETIDOFFPOS(tSentId,tOff,tPos)
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
		
			// add the record to the list
			set tSrcId = ..GetSourceId(domainid,tSentId)
			set tExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, tSrcId)
			$$$IKQADDRESULT(result,count,$lb(tSrcId, tExtId, tSentId, ..GetValue(domainid, tSentId)))
		}
	}
	
	$$$IKQENDCATCH(result,"^||%IK.SentBits",tSC)
}

/// <p>Retrieves the number of sentences containing the given entities, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:entitylist="" 0


	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList, vSrcId,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByEntitiesInternal
	quit ..GetCountByEntitiesInternal(domainid, .entIdList, filter, setop, .sc)
}

/// <p>Retrieves the nubmer of sentences containing the given entity ids.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>entityidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sources containing any actual
/// form of the entities in <var>entityidlist</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sources containing the actual forms in <var>entityidlist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:entityidlist="" 0


	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean up the entityidlist into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanIdList, vSrcId,, $s('tIncludeActuals:0, setop=$$$UNION:1, 1:2))
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByEntitiesInternal
	quit ..GetCountByEntitiesInternal(domainid, .cleanIdList, filter, setop, .sc)
}

ClassMethod GetCountByEntitiesInternal(domainid As %Integer, ByRef entitylist, filter As %iKnow.Filters.Filter, setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("",sc,-1)
	quit:'entitylist 0
	
	// BDB522
	set t2LevelAND = ($d(entitylist($order(entitylist(""))))>1)
	
	// special case to support virtual sources
	if $lv(filter) && ($lg(filter,1)<0) {
		set vSrcId = $zabs($lg(filter,1)), tSQL=""
		
		if (t2LevelAND) {
			set tEntUniId="", i=0
			for {
				set tEntUniId = $order(entitylist(tEntUniId))
				quit:tEntUniId=""
			
				// first aggregate actual forms underneath
				set tActUniId = "", tIDs=""
				for {
					set tActUniId = $order(entitylist(tEntUniId,tActUniId))
					quit:tActUniId=""
					set tIDs = tIDs_","_tActUniId
				}
				set tSQL = tSQL _ $s($i(i)=1:"", 1:" AND SentenceId IN (") _ "SELECT SentenceId FROM %iKnow_Objects.VirtualEntityOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND EntUniId IN ("_$e(tIDs,2,*)_")"_$s(i=1:"",1:")")
			}
			set tSQL = "SELECT COUNT(*) FROM ("_tSQL_")"
		} elseif setop=$$$UNION {
			set tEntUniId = ""
			for {
				set tEntUniId = $order(entitylist(tEntUniId))
				quit:tEntUniId=""
			
				set tSQL = tSQL _ "," _ tEntUniId
			}
			set tSQL = "SELECT COUNT(DISTINCT SentenceId) FROM %iKnow_Objects.VirtualEntityOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND EntUniId IN ("_$e(tSQL,2,*)_")"
		} else {
			
			set tEntUniId = "", tEntUniCount=0
			for {
				set tEntUniId = $order(entitylist(tEntUniId))
				quit:tEntUniId=""
			
				set tSQL = tSQL _ "," _ tEntUniId, tEntUniCount=tEntUniCount+1
			}
			set tSQL = "SELECT COUNT(SentenceId) FROM (SELECT SentenceId, COUNT(DISTINCT EntUniId) cnt FROM %iKnow_Objects.VirtualEntityOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND EntUniId IN ("_$e(tSQL,2,*)_") GROUP BY SentenceId) WHERE cnt = "_tEntUniCount
		}
		
		set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
		set total = $s(tResult.%Next():tResult.%GetData(1), 1:0)
		
	} else {
		
			
		$$$IKQBCHECKX(domainid,$$$IKBENTUNIBIT,sc)
		$$$IKQFILTEROBJECTX(domainid,filter,sc)
		
		// first build bitmap index on sentences based on filter
		kill tFilterBits
		if $isobject(filter) {
			set tSrcId = ""
			for {
				set tSrcId = filter.GetNextSrcId(tSrcId)
				quit:tSrcId=""
				
				set tSrcDetails = $g(^IRIS.IK.SrcDetails(domainid,tSrcId))
				set tSentBase = $lg(tSrcDetails,1), tSentMax = tSentBase+$lg(tSrcDetails,2)
				for i = tSentBase+1:1:tSentMax {
					$$$IKBITOFFPOS(i,tOff,tPos)
					set $bit(tFilterBits(tOff),tPos)=1
				}
			}
		}
		
		// now combine with entity filters
		kill tSentBits
		merge:setop=$$$INTERSECT tSentBits = tFilterBits
		set tEntUniId="", tIsFirst=1
		for {
			set tEntUniId = $order(entitylist(tEntUniId))
			quit:tEntUniId=""
			
			kill tSentEntBits
			if (t2LevelAND) {
				// first aggregate actual forms underneath
				set tActUniId = ""
				for {
					set tActUniId = $order(entitylist(tEntUniId,tActUniId))
					quit:tActUniId=""
					
					set tOff=""
					for {
						if $isobject(filter) {
							set tOff = $order(tFilterBits(tOff))
							quit:tOff=""
							set tBits = $g(^IRIS.IK.EntUniToSentBit(domainid,tActUniId,tOff))
							continue:'$$$IKHASBIT(tBits)
						} else {
							set tOff = $order(^IRIS.IK.EntUniToSentBit(domainid,tActUniId,tOff), 1, tBits)
							quit:tOff=""
						}
						set tSentEntBits(tOff) = $bitlogic(tSentEntBits(tOff) | tBits)
					}
				}
			} else {
				merge tSentEntBits = ^IRIS.IK.EntUniToSentBit(domainid,tEntUniId)
			}
			
			// now merge tSentEntBits with current tSentBits
			if setop = $$$UNION {
				set tOff=""
				for {
					if $isobject(filter) {
						set tOff = $order(tFilterBits(tOff))
						quit:tOff=""
						set tBits = $g(tSentEntBits(tOff))
						continue:'$$$IKHASBIT(tBits)
					} else {
						set tOff = $order(tSentEntBits(tOff),1,tBits)
						quit:tOff=""
					}
					set tSentBits(tOff) = $bitlogic(tSentBits(tOff) | tBits)
				}
			} else {
				if tIsFirst && '$isobject(filter) {
					merge tSentBits = tSentEntBits
					set tIsFirst=0
				} else {
					set tOff=""
					for {
						set tOff = $order(tSentBits(tOff),1,tBits)
						quit:tOff=""
						set tSentBits(tOff) = $bitlogic(tSentEntBits(tOff) & tBits)
					}
				}
			}
		}
		
		// still have to enforce filter if $$$UNION
		if (setop=$$$UNION) && $isobject(filter) {
			set tOff = ""
			for {
				set tOff = $order(tSentBits(tOff),1,tBits)
				quit:tOff=""
				set tSentBits(tOff) = $bitlogic(tBits & tFilterBits(tOff))
			}
		}
		
			
		// now loop through the matching sentences
		set tOff = "", total=0
		for {
			set tOff = $order(tSentBits(tOff),-1,tBits)
			quit:tOff=""
			set total = total + $bitcount(tBits,1)
		}
		
	}
	 
	$$$IKQEND("",total)
}

Parameter GetByCrcsRT = "srcId:%Integer,externalId:%String,sentId:%Integer,sentenceValue:%String";

/// <p>Retrieves all sentences containing the given CRCs, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcs(ByRef result, domainid As %Integer, crclist As %List, filter As %iKnow.Filters.Filter = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:crclist="" $$$OK
	
	// unravel the crclist into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set tSC = ##class(%iKnow.Queries.CrcAPI).TranslateCrcList(domainid, crclist, "^||%IK.CrcIds", vSrcId)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByCrcsInternal
	quit ..GetByCrcsInternal(.result, domainid, "^||%IK.CrcIds", filter, page, pagesize, setop)
}

Parameter GetByCrcIdsRT = "srcId:%Integer,externalId:%String,sentId:%Integer,sentenceValue:%String";

/// <p>Retrieves all sentences containing the given CRC ids, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>crcidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcIds(ByRef result, domainid As %Integer, crcidlist As %List, filter As %iKnow.Filters.Filter = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:crcidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(crcidlist)
	
	// clean up the entityidlist into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set tSC = ##class(%iKnow.Queries.CrcAPI).TranslateCrcIdList(domainid, crcidlist, "^||%IK.CrcIds", vSrcId)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByCrcsInternal
	quit ..GetByCrcsInternal(.result, domainid, "^||%IK.CrcIds", filter, page, pagesize, setop)
}

Parameter GetByCrcMaskRT = "srcId:%Integer,externalId:%String,sentId:%Integer,sentenceValue:%String";

/// <p>Retrieves all sentences containing a CRC satisfying the given CRC Mask, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcMask(ByRef result, domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, filter As %iKnow.Filters.Filter = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"^||%IK.TranslateMRSBits")
	$$$CHECKDOMAINEXISTS(domainid)
	
	// unravel the MRS mask into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.CrcAPI).TranslateMRSMaskToCrcIdList(domainid, head, relation, tail, "^||%IK.CrcIds", vSrcId, tIncludeActuals)
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetCrcSentInternal
	quit ..GetByCrcsInternal(.result, domainid, "^||%IK.CrcIds", filter, page, pagesize, setop)
}

ClassMethod GetByCrcsInternal(ByRef result, domainid As %Integer, crcIdsGlob As %String, filter As %iKnow.Filters.Filter = "", page As %Integer, pagesize As %Integer, setop As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.Sents",tSC)
	quit:'$d(@crcIdsGlob)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	
	// special case to support virtual sources
	if $lv(filter) && ($lg(filter,1)<0) {
		set vSrcId = $zabs($lg(filter,1)), tSQL=""
		if setop=$$$UNION {
			set tCrcUniId = ""
			for {
				set tCrcUniId = $order(@crcIdsGlob@(tCrcUniId))
				quit:tCrcUniId=""
			
				set tSQL = tSQL _ "," _ tCrcUniId
			}
			set tSQL = "SELECT DISTINCT SentenceId FROM %iKnow_Objects.VirtualCrcOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND CrcUniId IN ("_$e(tSQL,2,*)_")"
		} else {
			
			set tCrcUniId = "", tCrcUniCount=0
			for {
				set tCrcUniId = $order(@crcIdsGlob@(tCrcUniId))
				quit:tCrcUniId=""
			
				set tSQL = tSQL _ "," _ tCrcUniId, tCrcUniCount=tCrcUniCount+1
			}
			set tSQL = "SELECT SentenceId FROM (SELECT SentenceId, COUNT(DISTINCT CrcUniId) cnt FROM %iKnow_Objects.VirtualCrcOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND CrcUniId IN ("_$e(tSQL,2,*)_") GROUP BY SentenceId) WHERE cnt = "_tCrcUniCount
		}
		set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
		while tResult.%Next(.tSC) {
			quit:$$$ISERR(tSC)
			set tSentId = tResult.%GetData(1)
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
		
			// add the record to the list
			set tExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, -vSrcId)
			$$$IKQADDRESULT(result,count,$lb(-vSrcId, tExtId, tSentId, ..GetValue(domainid, tSentId,, vSrcId)))
		}
		quit
	}
	
	// BDB522
	$$$IKQBCHECKX(domainid,$$$IKBCRCUNIBIT,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	
	set tCrcId = "", tCrcCount = 0
	for {
		set tCrcId = $order(@crcIdsGlob@(tCrcId))
		quit:tCrcId=""
		set tCrcCount = tCrcCount+1
		
		set tGloFrom = $name(^IRIS.IK.CrcUniToSentBit(domainid,tCrcId))
		if (tCrcCount=1) || (setop=$$$UNION) {
			$$$IKMERGEBITSOR(tGloFrom,"^||%IK.Sents")
		} else {
			$$$IKMERGEBITSAND(tGloFrom,"^||%IK.Sents")
		}
	}
	
	set tOff = ""
	for {
		set tOff = $order(^||%IK.Sents(tOff),-1,tBits)
		quit:tOff=""
		
		set tPos=1
		for {
			set tPos = $bitfind(tBits,1,tPos-1,-1)
			quit:tPos=0
			
			$$$IKGETIDOFFPOS(tSentId,tOff,tPos)
			
			set tSrcId = ..GetSourceId(domainid,tSentId)
			continue:$isobject(filter)&&'filter.IsFiltered(tSrcId)
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// add the record to the list
			set tExtId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, tSrcId)
			$$$IKQADDRESULT(result,count,$lb(tSrcId, tExtId, tSentId, ..GetValue(domainid, tSentId)))
			
			quit:usePaging&&(count>last)
		}
	}
	
	$$$IKQENDCATCH(result,"^||%IK.Sents",tSC)
}

/// <p>Retrieves the number of sentences containing the given CRCs, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcs(domainid As %Integer, crclist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:crclist="" 0
	
	// unravel the crclist into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set sc = ##class(%iKnow.Queries.CrcAPI).TranslateCrcList(domainid, crclist, "^||%IK.CrcIds", vSrcId)
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByCrcsInternal
	quit ..GetCountByCrcsInternal(domainid, "^||%IK.CrcIds", filter, setop, .sc)
}

/// <p>Retrieves the number of sentences containing the given CRC ids, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>crcidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcIds(domainid As %Integer, crcidlist As %List, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:crcidlist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(crcidlist)
	
	// clean up the entityidlist into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set sc = ##class(%iKnow.Queries.CrcAPI).TranslateCrcIdList(domainid, crcidlist, "^||%IK.CrcIds", vSrcId)
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByCrcsInternal
	quit ..GetCountByCrcsInternal(domainid, "^||%IK.CrcIds", filter, setop, .sc)
}

/// <p>Retrieves the number of sentences containing a CRC satisfying the given CRC Mask, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcMask(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, filter As %iKnow.Filters.Filter = "", setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("^||%IK.TranslateMRSBits",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	
	// unravel the MRS mask into a clean %List
	if $isvalidnum(filter) && (filter<0) {
		set vSrcId = $zabs(filter), filter = $lb(filter)
	} elseif $lv(filter) && ($lg(filter,1)<0) {
		if ($ll(filter)>1) {
			set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
			quit -1
		}
		set vSrcId = $zabs($li(filter,1))
	} else {
		set vSrcId = 0
	}
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.CrcAPI).TranslateMRSMaskToCrcIdList(domainid, head, relation, tail, "^||%IK.CrcIds", vSrcId, tIncludeActuals)
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByCrcsInternal
	quit ..GetCountByCrcsInternal(domainid, "^||%IK.CrcIds", filter, setop, .sc)
}

ClassMethod GetCountByCrcsInternal(domainid As %Integer, crcIdsGlob As %String, filter As %iKnow.Filters.Filter = "", setop As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("^||%IK.Sents",sc,-1)
	quit:'$d(@crcIdsGlob) 0
	
	
	// special case to support virtual sources
	if $lv(filter) && ($lg(filter,1)<0) {
		set vSrcId = $zabs($lg(filter,1)), tSQL=""
		if setop=$$$UNION {
			set tCrcUniId = ""
			for {
				set tCrcUniId = $order(@crcIdsGlob@(tCrcUniId))
				quit:tCrcUniId=""
			
				set tSQL = tSQL _ "," _ tCrcUniId
			}
			set tSQL = "SELECT COUNT(DISTINCT SentenceId) FROM %iKnow_Objects.VirtualCrcOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND CrcUniId IN ("_$e(tSQL,2,*)_")"
		} else {
			
			set tCrcUniId = "", tCrcUniCount=0
			for {
				set tCrcUniId = $order(@crcIdsGlob@(tCrcUniId))
				quit:tCrcUniId=""
			
				set tSQL = tSQL _ "," _ tCrcUniId, tCrcUniCount=tCrcUniCount+1
			}
			set tSQL = "SELECT COUNT(SentenceId) FROM (SELECT SentenceId, COUNT(DISTINCT CrcUniId) cnt FROM %iKnow_Objects.VirtualCrcOccurrence WHERE DomainId = "_domainid_" AND VirtualSourceId = "_vSrcId_" AND CrcUniId IN ("_$e(tSQL,2,*)_") GROUP BY SentenceId) WHERE cnt = "_tCrcUniCount
		}
		set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
		set tTotal = $s(tResult.%Next():tResult.%GetData(1), 1:0)
		
	} else {
		// BDB522
		$$$IKQBCHECKR(domainid,$$$IKBCRCUNIBIT,sc,-1)
		$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
		
		set tCrcId = "", tCrcCount = 0
		for {
			set tCrcId = $order(@crcIdsGlob@(tCrcId))
			quit:tCrcId=""
			set tCrcCount = tCrcCount+1
			
			set tGloFrom = $name(^IRIS.IK.CrcUniToSentBit(domainid,tCrcId))
			if (tCrcCount=1) || (setop=$$$UNION) {
				$$$IKMERGEBITSOR(tGloFrom,"^||%IK.Sents")
			} else {
				$$$IKMERGEBITSAND(tGloFrom,"^||%IK.Sents")
			}
		}
		
		set tOff = "", tTotal = 0
		for {
			set tOff = $order(^||%IK.Sents(tOff),-1,tBits)
			quit:tOff=""
			
			if $isobject(filter) {
				set tPos=1
				for {
					set tPos = $bitfind(tBits,1,tPos-1,-1)
					quit:tPos=0
					
					$$$IKGETIDOFFPOS(tSentId,tOff,tPos)
					
					set tSrcId = ..GetSourceId(domainid,tSentId)
					continue:'filter.IsFiltered(tSrcId)
					
					set tTotal = tTotal + 1
				}
			} else {
				set tTotal = tTotal + $bitcount(tBits, 1)
			}
		}
	}
	
	$$$IKQEND("^||%IK.Sents",tTotal)
}

Parameter GetByPathIdsRT = "srcId:%Integer,externalId:%String,sentId:%Integer,sentenceValue:%String";

/// <p>Retrieves all sentences containing the given path IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByPathIds(ByRef result, domainid As %Integer, pathidlist As %List, sourceidlist As %List, page As %Integer = 1, pagesize As %Integer = 10) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:pathidlist="" $$$OK
	quit:sourceidlist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(pathidlist)
	$$$IKENSURELISTNUM(sourceidlist)
	
	// clean the pathidlist into a %List without duplicates or inexistent crcIds
	set tSC = ##class(%iKnow.Queries.PathAPI).TranslatePathIdList(domainid, pathidlist, .cleanIdList)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByPathsInternal
	quit ..GetByPathsInternal(.result, domainid, .cleanIdList, sourceidlist, page, pagesize)
}

ClassMethod GetByPathsInternal(ByRef result, domainid As %Integer, ByRef pathlist, sourceidlist As %List, page As %Integer, pagesize As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.trackedSents",tSC)
	quit:'$d(pathlist)
	quit:sourceidlist=""
	
	$$$IKQBCHECKX(domainid,$$$IKBPATH,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// as a path can be in only one sentence, a simple loop over the pathlist and getting the
	// corresponding srcId from ^IRIS.IK.PathToSent will do, keeping track of the sentences already 
	// in the list
	set pathId = ""
	for {
		set pathId = $order(pathlist(pathId))
		quit:pathId=""
		
		set pathBase = $order(^IRIS.IK.PathToSent(domainid, pathId), -1, pathDetails)
		set sentId = $li(pathDetails, 1)
		
		set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(domainid, sentId)
		
		// check if the sentence occurs in the supplied sourceidlist
		if ((sourceidlist '= "") && ($listfind(sourceidlist, srcId) = 0)) {
			continue
		}
		
		// check if it's already in the result list
		if ('$data(^||%IK.trackedSents(sentId))) {
			
			// keep track of this one
			set ^||%IK.trackedSents(sentId) = ""
			
			// check if we're in the paging window
			set count = count + 1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			// build sent record to be added to ^||%IK.GetPathSentInternal
			set sentDetails = ..GetValue(domainid, sentId)
			set extId = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, srcId)
			$$$IKQADDRESULT(result,count,$lb(srcId, extId, sentId, sentDetails))
		}
	}
	$$$IKQENDCATCH(result,"^||%IK.trackedSents",tSC)
}

/// <p>Retrieves the number of sentences containing the given path IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByPathIds(domainid As %Integer, pathidlist As %List, sourceidlist As %List, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:pathidlist="" 0
	quit:sourceidlist="" 0

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(pathidlist)
	$$$IKENSURELISTNUM(sourceidlist)
	
	// clean the pathidlist into a %List without duplicates or inexistent crcIds
	set sc = ##class(%iKnow.Queries.PathAPI).TranslatePathIdList(domainid, pathidlist, .cleanIdList)
	quit:$$$ISERR(sc) -1
	
	// forward to GetCountByPathsInternal
	quit ..GetCountByPathsInternal(domainid, .cleanIdList, sourceidlist, .sc)
}

ClassMethod GetCountByPathsInternal(domainid As %Integer, ByRef pathlist, sourceidlist As %List, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("^||%IK.trackedSents",sc,-1)
	quit:'$d(pathlist)="" 0
	quit:sourceidlist="" 0
	
	$$$IKQBCHECKR(domainid,$$$IKBPATH,sc,-1)
		
	set total = 0
	set pathId = ""
	for {
		set pathId = $order(pathlist(pathId))
		quit:pathId=""
		
		set pathBase = $order(^IRIS.IK.PathToSent(domainid, pathId), -1, pathDetails)
		set sentId = $li(pathDetails, 1)
		
		set srcId = ##class(%iKnow.Queries.SentenceAPI).GetSourceId(domainid, sentId)
		
		// check if the sentence occurs in the supplied sourceidlist
		if ((sourceidlist '= "") && ($listfind(sourceidlist, srcId) = 0)) {
			continue
		}
		
		// check if it's already in the result list
		if ('$data(^||%IK.trackedSents(sentId))) {
			
			// keep track of this one
			set ^||%IK.trackedSents(sentId) = ""
			
			set total = total+1
		}
	}
	$$$IKQEND("^||%IK.trackedSents",total)
}

Parameter GetNewBySourceRT = "sentId:%Integer,sentenceValue:%String,score:%Numeric";

/// <p>Retrieves the sentences with the most significant concepts compared to the rest of the domain
/// (or optionally a subset thereof as filtered through <i>filter</i>). This array of sentences is
/// based on results of the GetNewBySource query in <class>%iKnow.Queries.EntityAPI</class>, using
/// the supplied algorithm and parameter values. The scores of the first [<i>newEntitiesWindow</i>]
/// concepts are aggregated across sentences to produce the result of this query.</p>
/// <p>Please refer to the documentation of the GetNewBySource query in
/// <class>%iKnow.Queries.EntityAPI</class> for more details on the parameters and available algorithms.</p>
ClassMethod GetNewBySource(ByRef result, domainid As %Integer, sourceid As %Integer, length As %Integer = 5, filter As %iKnow.Filters.Filter = "", algorithm As %String = {$$$NEWENTSIMPLE}, algorithmParams As %List = "", newEntitiesWindow As %Integer = 100, skipListIds As %List = "") As %Status
{
	$$$IKQBEGINTRY(result,"^||%IKQ.NewEntsRes,^||%IK.NewSentEnts,^||%IK.NewSents,^||%IK.NewSentsSort",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$CHECKASRCIDEXISTSX(domainid,sourceid,srcDetails,vSrcId,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	
	// get the results of EntityAPI.GetNewBySource()
	set tSC = ##class(%iKnow.Queries.EntityAPI).GetNewBySource("^||%IKQ.NewEntsRes", domainid, $lb(sourceid), 1, newEntitiesWindow, filter, $$$ENTTYPECONCEPT, algorithm, algorithmParams, skipListIds)
	quit:$$$ISERR(tSC)
	
	// store the relevance per entity in ^||%IKQ.NewEntsRes
	set i=""
	for {
		set i = $order(^||%IKQ.NewEntsRes(i),1,data)
		quit:i=""
		set ^||%IK.NewSentEnts($li(data,1)) = $li(data,5)-$li(data,6)
	}
	kill ^||%IK.NewEntsRes
	
	// now aggregate the scores per sentence
	kill ^||%IK.NewSents
	set gSentDetails = $$$IKVGLOBNAME(domainid,"SentDetails",vSrcId)
	set gEntOccId = $$$IKVGLOBNAME(domainid,"EntOccId",vSrcId)
	set sentFrom = $li(srcDetails,1)+1
	set sentTo = $li(srcDetails,1)+$li(srcDetails,2)
	for sentId = sentFrom:1:sentTo {
		set tSentInfo = @gSentDetails@(sentId)
		set ptr=0, sentScore=0
		set tEOFrom = $lg(tSentInfo,4)+1, tEOTo = $lg(tSentInfo,5)+tEOFrom-1
		for tEntOccId = tEOFrom:1:tEOTo {
			set tEntOcc = $g(@gEntOccId@(tEntOccId))
			continue:$lg(tEntOcc,2)=$$$ENTTYPENONREL
			set tEntUniId = $lg(tEntOcc,1)
			set sentScore = sentScore + $g(^||%IK.NewSentEnts(tEntUniId))
		}
		continue:sentScore<=0
		// TODO: normalize score wrt sentence length?
		set ^||%IK.NewSents(-sentScore,sentId) = ""
	}
	
	// now select the top <length> and resort in ^||%IK.NewSentsSort
	set count=0, score=""
	for {
		set score = $order(^||%IK.NewSents(score))
		quit:score=""
		
		set sentId=""
		for {
			set sentId = $order(^||%IK.NewSents(score,sentId))
			quit:sentId=""
			
			set count = count+1
			quit:count>length
			set ^||%IK.NewSentsSort(sentId) = -score
		}
	}
	
	// finally, build the result
	set sentId="", count=0
	for {
		set sentId = $order(^||%IK.NewSentsSort(sentId),1,score)
		quit:sentId=""
		
		$$$IKQADDRESULT(result,$i(count),$lb(+sentId, ..GetValue(domainid,sentId,vSrcId), score))
	}
	
	$$$IKQENDCATCH(result,"^||%IKQ.NewEntsRes,^||%IK.NewSentEnts,^||%IK.NewSents,^||%IK.NewSentsSort",tSC)
}

Parameter GetHighlightedEXP [ Internal ] = 0;

/// <h2>Highlighting</h2>
/// <p>This is a flexible method to highlight specific elements within a sentence using
/// user-supplied markup passed in through the <var>pHighlight</var> argument (by reference) in a
/// multidimensional form: 
/// <example language="COS"> set pHighlight("FLAG") = "markup"
///  set pHighlight("FLAG", id) = "markup"
/// </example>
/// <p>The first option will highlight any element
/// of the type identified by "FLAG", the second option allows refining this to a particular instance,
/// identified by <i>id</i>, overriding any eventual definitions at the generic "FLAG" level.</p>
/// <p>Note: unless explicitly stated otherwise, all highlighting is based on the entity level.</p>
/// <h3>Markup options</h3>
/// <p>Any single (opening) HTML tag can be specified on the value side of <var>pHighlight</var> and will
/// automatically be wrapped around every entity. The closing tag will be automatically derived from the
/// opening tag supplied through <var>pHighlight</var>
/// <p>HTML markup supplied this way supports a basic means of annotating with metadata about the
/// particular thing being highlighted. Any occurrences of "$$$ID" in the HTML tag will be substituted
/// with the relevant identifier of what's being highlighted, such as entity IDs for entity markup,
/// CRC IDs for CRC markup or match IDs for dictionary matching markup. Most entity-level markup also
/// supports the $$$LITERAL tag to replace with the original text string for that entity.<br/>
/// For example, the following highlight spec would add links to an info page that takes entity IDs as a URL parameter:</p>
/// <example language="COS"> set tHighlight("ROLE", "concept") = "<a href=""Example.MyEntityViewer.cls?entity=$$$ID"">"</example>
/// <p>Note that in some cases, such as dictionary matches, ther may be multiple IDs associated with
/// the same highlighted entity. These will be provided as a comma-separated list replacing the $$$ID 
/// placeholder.</p>
/// <p>As an alternative to HTML markup, you can also supply two-character strings that will be used 
/// to wrap entities that need highlighting. For example, this array will put square brackets around
/// all concepts and curly braces around relationships:</p>
/// <example language="COS"> set tHighlight("ROLE", "concept") = "[]"
///  set tHighlight("ROLE", "relation") = "{}"</example>
/// <h3>Highlighting specific entities, CRCs and paths</h3>
/// <p>To highlight all occurrences of a particular entity, stem, CRC, CC or path, use the corresponding flag.
/// For entities, you can also supply the string value (except when the string value is an integer number itself).
/// <example language="COS"> set tHighlight("ENTITY", 123) = "<b>"
///  set tHighlight("ENTITY", "snow storm") = "<b>"
///  set tHighlight("STEM", 234) = "<strong title=""$$$LITERAL"">"
///  set tHighlight("CRC", 345) = "<u>"
///  set tHighlight("PATH", 456) = "<span style='border: 1px solid blue;'>"</example>
/// <h3>Highlighting based on role</h3>
/// <p>The "ROLE" flag can be used to mark concepts, relations and non-relevants, either by using
/// the corresponding integer code (i.e. $$$ENTTYPECONCEPT) or a simple string value. Note that
/// in some cases, some words inside a relationship entity may be marked as non-relevant. These will be
/// highlighted at the word level (only if there is a specific highlighting spec for non-relevants)
/// and are an exception to the general rule that all highlighting happens at the entity level.</p>
/// <example language="COS"> set tHighlight("ROLE", "concept") = "<c>"
///  set tHighlight("ROLE", "relation") = "<r>"
///  set tHighlight("ROLE", "non-relevant") = "()"
///  set tString = "The newspaper published the article and it sold very well."
///  write $system.iKnow.Highlight(tString, .tHighlight)</example>
/// <p>The above example would print: </p>
/// <blockquote><pre>(The) &lt;c&gt;newspaper&lt;/c&gt; &lt;r&gt;published&lt;/r&gt; (the) &lt;c&gt;article&lt;/c&gt; &lt;r&gt;and (it) sold very well&lt;/r&gt;.</pre></blockquote>
/// <h3>Highlighting based on attributes</h3>
/// <p>Attributes can be highlighted at two levels. Using the regular "ATTRIBUTE" flag will highlight
/// all entities affected by the attribute specified by attribute ID (such as $$$IKATTNEGATION). 
/// However, some attributes support more fine-grained annotation at the word level, marking those
/// words that actually caused the attribute to apply to an entity or part of a path. These can be
/// highlighted individually through the "ATTRIBUTEWORDS" flag and are an exception to the general
/// rule that highlighting happens per-entity.</p>
/// <example language="COS"> set tHighlight("ATTRIBUTE", $$$IKATTNEGATION) = "<span style='color: red;'>"
///  set tHighlight("ATTRIBUTEWORDS", $$$IKATTNEGATION) = "<u>"
///  set tString = "The landlord doesn't accept late payments, but makes exceptions for students."
///  write $system.iKnow.Highlight(tString, .tHighlight)</example>
/// <p>The above example would display as: </p>
/// <blockquote>The <span style='color: red;'>landlord</span> <span style='color: red;'><u>doesn&#39;t</u> accept</span> <span style='color: red;'>late payments</span>, but makes exceptions for students.</blockquote>
/// <p>For some attributes, such as certain expressions of measurements, the engine is able to extract
/// additional data elements which are exposed as "measurement properties". You can include these properties
/// in your highlighted text by including the $$$PROPERTIES placeholder. Note that these are typically
/// identified for the word level.</p>
/// <h3>Highlighting based on matching results</h3>
/// <p>Dictionary matches can be highlighted using the "MATCH" flag, optionally restricted to a particular
/// dictionary ID. To refine to a particular dictionary item, use the "MATCHITEM" flag. Highlighting can
/// further be refined to distinguish based on full or partial matches using the "FULL" and "PARTIAL"
/// flags as an additional subscript. Please note this is a refinement and the parent node (ID-specific or
/// generic) should contain a value:</p>
/// <p>Additional information about the matches themselves is available through the metadata rewrite
/// mechanism: $$$TERM, $$$TERMID, $$$ITEM, $$$ITEMID, $$$ITEMURI, $$$DICT, $$$DICTID. Note that 
/// the regular $$$ID markers will be replaced with dictionary match IDs, not the IDs of the Dictionary or Dictionary Items.</p>
/// <example language="COS"> set tHighlight("MATCH") = "<a href=""Example.MoreInfo.zen?uri=$$$ITEMURI"" style='border: 1px solid Tomato;' >"
///  set tHighlight("MATCH", "FULL") = "<a href=""Example.MoreInfo.zen?uri=$$$ITEMURI""style='background-color: Tomato'>"
///  set tHighlight("MATCHITEM", 123) = "<a href=""Example.MoreInfo.zen?uri=$$$ITEMURI"" style='border: 1px solid Lime;'>"</example>
/// <h3>Highlighting based on character position</h3>
/// <p>If external tooling provided annotations based on character positions, use the "CHARS" flag to 
/// highlight those annotations by providing the start and end positions as second and third subscripts
/// of the highlight spec array. This will highlight the entities "covering" these start and end
/// positions, starting with the entity which includes the character at the designated start position
/// and ending with the entity including the character at the designated end position.</p>
/// <example language="COS"> set tHighlight("CHARS", 13, 21) = "<a href=""www.imdb.com/title/tt1636826/"">"
///  set tHighlight("CHARS", 71, 75) = "<a href=""http://www.haren.nl/"">"
///  set tString = "The instant Project X party was not well-received by the cummunity of Haren in the Netherlands."
///  write $system.iKnow.Highlight(tString, .tHighlight)
/// </example>
/// <p>The above example will annotate the entire entities "instant Project X party" and "Haren".</p>
/// <p>Note that the iKnow indexing engine in certain cases may modify input text while processing text
/// and therefore, character position based informations from external sources that based themselves
/// on the original text, may no longer point to the expected positions. The two most important cases
/// where this can happen is when User Dictionaries are used to rewrite the input explicitly or when
/// duplicate whitespace is normalized by the engine. To work around this issue, present the output of
/// the iKnow engine (as retrieved through <method>GetValue</method> to these external tools to be sure
/// the same normalizations are applied.</p>
/// <p>In cases where the externally provided character positions span more than a single sentence, 
/// you can pass an offset as the data element of the main "CHARS" node to mark the character position
/// that corresponds the start of this sentence. This should be easier than recalculating all character
/// positions and allows you to reuse the entire array for successive calls to <method>GetHighlighted</method>.
/// <h3>Style precedence</h3>
/// <p>For the purpose of HTML styling precedence, this is the order in which tags are
/// wrapped around entities, from innermost to outermost:
/// <ol>
/// 		<li>ATTRIBUTEWORDS (wrapped around individual words)</li>
/// 		<li>ATTRIBUTE - ID-specific (attribute type ID)</li>
/// 		<li>ATTRIBUTE - generic</li>
/// 		<li>ENTITY - ID-specific</li>
/// 		<li>STEM - ID-specific</li>
/// 		<li>CRC - ID-specific</li>
/// 		<li>CC - ID-specific</li>
/// 		<li>MATCHITEM - ID-specific (dictionary item ID)</li>
/// 		<li>MATCH - ID-specific (dictionary ID)</li>
/// 		<li>MATCHITEM - generic</li>
/// 		<li>MATCH - generic</li>
/// 		<li>PATH - ID-specific</li>
/// 		<li>ROLE - ID-specific (role)</li>
/// 		<li>CHARS</li>
/// </ol></p> 
/// 
ClassMethod GetHighlighted(pDomainId As %Integer, pSentenceId As %Integer, ByRef pHighlight = "", vSrcId As %Integer = 0, Output pFullSentence = "", Output pSC As %Status = {$$$OK}, pEscapeHTML As %Boolean = 1) As %String
{
#define STARTTAG(%t) $s($l(%t)=2:$e(%t,1), 1:%t)
#define ENDTAG(%t) $s($l(%t)=2:$e(%t,2), 1:$e(%t,1)_"/"_$p($e(%t,2,*-1)," ",1)_$e(%t,*))
#define WRAPTAG(%s,%t,%id,%v) set %s = $s($l(%t)=2:$e(%t,1)_%s_$e(%t,2), 1:$replace($replace(%t,"$$$LITERAL",$zcvt(%v,"O","HTML")),"$$$ID",%id)_%s_$$$ENDTAG(%t))

	set pSC = $$$OK
	try {
		kill pFullSentence, tHighlightDef
		$$$IKCHECKPRIVREADX(pSC)
		if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,pSC) }
		
		merge tHighlightDef = pHighlight
		
		// BDB577
		set tVersionTables = $$$IKVERSIONATLEAST(pDomainId,$$$IKVERSIONTABLES)
		
		if $d(tHighlightDef("CC"))  {
			$$$IKQBCHECKX(pDomainId,$$$IKBCCUNIALL,pSC)
		}
		
		if (vSrcId) {
			set vSrcId = $zabs(vSrcId)
			set tEntities = $g(^IRIS.IKV.SentId(pDomainId, vSrcId, pSentenceId))
		} else {
			set tEntities = $g(^IRIS.IK.SentId(pDomainId, pSentenceId))
		}
		quit:tEntities="" 
		
		
		// convert any ENTITY values into their IDs
		set tEnt = ""
		for {
			set tEnt = $order(tHighlightDef("ENTITY",tEnt), 1, tTag)
			quit:tEnt=""
			continue:(tEnt=(+tEnt\1)) // this won't work to highlight numbers explicitly
			kill tHighlightDef("ENTITY",tEnt)
			set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId,.tEnt,vSrcId,0)
			set:tEntUniId tHighlightDef("ENTITY",$s(vSrcId:-tEntUniId, 1:tEntUniId)) = tTag
		}
		
		// BDB552 - accept string values for ROLE descriptors
		set tRole=""
		for {
			set tRole = $order(tHighlightDef("ROLE",tRole),1,tTag)
			quit:tRole=""
			if $$$UPPER($zstrip(tRole,"*WPC"))="CONCEPT" {
				set tHighlightDef("ROLE",$$$ENTTYPECONCEPT) = tTag
				kill tHighlightDef("ROLE",tRole)
			}
			if $$$UPPER($zstrip(tRole,"*WPC"))="RELATION" {
				set tHighlightDef("ROLE",$$$ENTTYPERELATION) = tTag
				kill tHighlightDef("ROLE",tRole)
			}
			if $$$UPPER($zstrip(tRole,"*WPC"))="NONRELEVANT" {
				set tHighlightDef("ROLE",$$$ENTTYPENONREL) = tTag
				kill tHighlightDef("ROLE",tRole)
			}
			if $$$UPPER($zstrip(tRole,"*WPC"))="PATHRELEVANT" {
				set tHighlightDef("ROLE",$$$ENTTYPEPATHREL) = tTag
				kill tHighlightDef("ROLE",tRole)
			}
		}
			
		// BDB552 - extract FULL/PARTIAL annotations into separate array
		set tHasAnyMatchInfo = $d(tHighlightDef("MATCH"))+$d(tHighlightDef("MATCHITEM"))
		#define ExFPAnnot(%1,%2) if $d(tHighlightDef(%1,%2),tHDFP) { s tHighlightDefFP(%1,%2) = tHDFP  kill tHighlightDef(%1,%2) }
		$$$ExFPAnnot("MATCH","FULL")
		$$$ExFPAnnot("MATCH","PARTIAL")
		$$$ExFPAnnot("MATCHITEM","FULL")
		$$$ExFPAnnot("MATCHITEM","PARTIAL")
		
		set tSentDetails = $g(@$$$IKVGLOBNAME(pDomainId,"SentDetails",vSrcId)@(pSentenceId))
		set tEntOccBase = $lg(tSentDetails, 4), tEntOccId = tEntOccBase
		set tLanguage = $lg($$$IKLANGUAGES,$lg(tSentDetails,1))
		set tIsJapanese = (tLanguage="ja")
		
		set gEntOccId = $$$IKVGLOBNAME(pDomainId,"EntOccId",vSrcId)
		set gCrcOccId = $$$IKVGLOBNAME(pDomainId,"CrcOccId",vSrcId)
		set gEntUniId = $$$IKVGLOBNAME(pDomainId,"EntUniId",vSrcId)
		set gStemUniId = $$$IKVGLOBNAME(pDomainId,"StemUniId",vSrcId)
		set gCrcUniId = $$$IKVGLOBNAME(pDomainId,"CrcUniId",vSrcId)
		set gCcUni = $$$IKVGLOBNAME(pDomainId,"CcUni",vSrcId)
		set gLitUniId = $$$IKVGLOBNAME(pDomainId,"LitUniId",vSrcId)
		set gNonRelBit = $$$IKVGLOBNAME(pDomainId,"SentNonRelBit",vSrcId)
		set gEntOccToMatch = $$$IKVGLOBNAME(pDomainId,"Mat.EntOccToMatch",vSrcId)
		set gMatchId = $$$IKVGLOBNAME(pDomainId,"Mat.MatchId",vSrcId)
		
		// BDB552 - initialize character position at eventual offset
		set tCharPos=1 + $g(tHighlightDef("CHARS"))
		
		set pFullSentence=1, pFullSentence(1)=""
		set ptr=0, tPart=1, tPrevNonRelOffset=0, tPos=0
		set tPrevPathId=0, tSentAttStart=0, tSentAttEnd=0
		while ($listnext(tEntities, ptr, tLitOrEntId)) {
			set x = $i(tPos)
			
			set tPrependSpace = (pFullSentence(tPart)'="")
			if (tLitOrEntId > 0) {
				set tString = @gEntUniId@(tLitOrEntId), tCharLength=$l(tString)
			} else {
				set tString = @gLitUniId@(-tLitOrEntId), tCharLength=$l(tString)
				
				// literals starting with a space indicate they should not be prepended with one
				if ($e(tString,1)=" ") {
					set tString = $e(tString,2,*)
					set tPrependSpace = 0, tCharLength=tCharLength-1
				}
			}
			
			set tOriginalValue = $zconvert(tString,"O","JS")
			
			// BDB552 - extract punctuation
			#define PUNCTUATION ",.;:/?![]{}()'""<>"_$c(171,187)
			set tPunctuationLess = $zstrip(tString,">",$$$PUNCTUATION)
			set tPunctuationAfter = $e(tString,$l(tPunctuationLess)+1,*)
			set tString = tPunctuationLess
			set tPunctuationLess = $zstrip(tString,"<",$$$PUNCTUATION)
			set tPunctuationBefore = $e(tString,1,*-$l(tPunctuationLess))
			set tString = tPunctuationLess
			
			// BDB776 - for Japanese, normalization should happen on the entire tUnEscaped
			// to accommodate character-width normalizations that "condense" the string
			set:tIsJapanese tString = $system.iKnow.Normalize(tString, pDomainId,, "ja",, 0)
				
			// BDB478 - escape HTML characters
			set tUnEscaped = tString
			if pEscapeHTML {
				set tString = $zconvert(tString,"O","HTML")
				set tPunctuationBefore = $zconvert(tPunctuationBefore,"O","HTML")
				set tPunctuationAfter = $zconvert(tPunctuationAfter,"O","HTML")
			}
			
			// now highlight entities according to tHighlightDef
			if ('tVersionTables) {
				$$$IKBITOFFPOS(tPos,tNonRelOffset,tNonRelPos)
				if (tNonRelOffset '= tPrevNonRelOffset) {
					set tNonRelBits = $g(@gNonRelBit@(pSentenceId, tNonRelOffset))
					set tPrevNonRelOffset = tNonRelOffset
				}
				if '$bit(tNonRelBits,tNonRelPos) {
					set x = $i(tEntOccId), tEntOcc = @gEntOccId@(tEntOccId)
				} else {
					set tBaseForm = "", tEntOcc=""
				}
			} else {
				set tEntOccId = tEntOccId+1, tEntOcc = @gEntOccId@(tEntOccId)
			}
			
			set tEntUniId = +$lg(tEntOcc,1), tRole = $lg(tEntOcc,2,$$$ENTTYPENONREL)
				
			// BDB522
			set tStemUniId = +$lg(tEntOcc,10)
			set tStemValue = $s(tStemUniId:@gStemUniId@(tStemUniId), 1:"$$$STEM")
			
			
			// "ATTRIBUTE" and "ATTRIBUTEWORDS" and NONRELEVANT inside RELATION
			set tTag="", tTagWords=""
			set tHasData = $d(tHighlightDef("ATTRIBUTE"), tTag)
			if tHasData || $d(tHighlightDef("ATTRIBUTEWORDS")) || ($d(tHighlightDef("ROLE",$$$ENTTYPENONREL)) && (tRole=$$$ENTTYPERELATION)) {
				
				if (tVersionTables || (tRole'=$$$ENTTYPENONREL)) {
					set pSC = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceAttributes(.tAtts, pDomainId, tEntOccId, vSrcId)
					quit:$$$ISERR(pSC)
					kill tAttMap
					set i="", tAttMap=""
					for {
						set i = $order(tAtts(i),1,tAtt)
						quit:i=""
						set tAttTypeId = $li(tAtt,1), tAttMap(tAttTypeId) = $lg(tAtt,4)
						set tAttMap = tAttMap _ $s(tAttMap="":"", 1:",") _ tAttTypeId
						
						// BDB845 - track attribute properties
						set tAttProp = ""
						for {
							set tAttProp = $order(tAtts(i,tAttProp),-1,tAttValue)
							quit:tAttProp=""
							set tAttMap(tAttTypeId,"props") = $s($d(tAttMap(tAttTypeId,"props"),s):s_", ", 1:"")_tAttProp_": "_tAttValue
						}
					}
				} else {
					// no need to fetch word-level attributes for nonrelevant in older domains
					// as there are no such attributes in corresponding language models
				}
				
				// ATTRIBUTEWORDS needs to be applied first
				kill tWordMap
				set tAttId = "", tOpen="", tClose="", tOverlap=""
				for {
					set tAttId = $order(tHighlightDef("ATTRIBUTEWORDS", tAttId), 1, tIdTag)
					quit:tAttId=""
					continue:'$d(tAttMap(tAttId),tWords)
					
					// BDB845 - attribute properties
					set tIdTag = $replace(tIdTag,"$$$PROPERTIES",$g(tAttMap(tAttId,"props")))
					
					for i = 1:1:$l(tWords) {
						continue:'$e(tWords,i)
						if $d(tWordMap(i)) {
							set tOverlap=1 // in case of overlap, we will not try to join the consecutive symbols in Japanese
							set tWordMap(i,"ID") = tWordMap(i,"ID")_","_tAttId
							set tWordMap(i,"O") = tWordMap(i,"O")_$$$STARTTAG(tIdTag)
							set tWordMap(i,"C") = tWordMap(i,"C")_$$$ENDTAG(tIdTag)
						} else {
							set tWordMap(i,"ID") = tAttId
							set tWordMap(i,"O") = $$$STARTTAG(tIdTag)
							set tWordMap(i,"C") = $$$ENDTAG(tIdTag)
						}
					}
				}
				
				// fold in the appropriate ATTRIBUTEWORDS tags
				if tIsJapanese {
					set tStrLen = $l(tString), tStrList=""
					for p=1:1:tStrLen { set tStrList=tStrList_$lb($e(tString,p)) }
					set tString = tStrList
					if tOverlap'=1 { // join the consecutive symbols
						set tPosition="", tCursor=""
						for {
							set tPosition = $order(tWordMap(tPosition))
							quit:tPosition=""
							set tCursor=tPosition+1, tCurrentO=$g(tWordMap(tPosition,"O"))
							while $data(tWordMap(tCursor)) && ($g(tWordMap(tCursor,"O"))=tCurrentO) { // consecutive symbols
								set tWordMap(tCursor-1,"C")=""
								set tWordMap(tCursor,"O")=""
								set tCursor=tCursor+1
							}
							set tPosition=tCursor-1
						}
					}
				} else {
					set tString = $lfs(tString," ")
				}
				
				// BDB552 - mark nonrelevants inside relationships
				if $d(tHighlightDef("ROLE",$$$ENTTYPENONREL),tNonRelStyle) && (tRole=$$$ENTTYPERELATION) {
					set tPosInEntity = 1
					set tEntityValue = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tEntUniId, vSrcId)
				} else { set tPosInEntity = 0 }
				for tPosInLiteral=1:1:$ll(tString) {
					set tWord = $li(tString,tPosInLiteral)
					// NONRELEVANTS
					if tPosInEntity {
						if tIsJapanese {
							set tStr1 = $e(tUnEscaped, tPosInLiteral)
							set tStr2 = $e(tEntityValue, tPosInEntity)
						} else {
							set tStr1 = $zstrip($piece(tUnEscaped," ",tPosInLiteral),"<>P")
							set tStr2 = $zstrip($piece(tEntityValue," ",tPosInEntity),"<>P")
						
							// BDB776 - apply full engine normalization (incl preprocessors) to unescaped literal
							set tStr1 = $tr($system.iKnow.Normalize(tStr1,pDomainId,,tLanguage,,0)," ")
						}
						
						if (tStr1=tStr2) {
							set tPosInEntity = tPosInEntity+1
						} elseif $tr(tStr1,"-'")=tStr1 {  // BDB752: extend BDB552 to include apostrophes
							$$$WRAPTAG(tWord,tNonRelStyle,0,tWord)
						} else {
							// BDB552: a word with a hyphen MAY contain a non-relevant suffix
							// and needs to be torn apart. 
							// Note: this supposes no other tags have been added before!
							set tStr2Len = $l(tStr2) 
							if $e(tStr1,1,tStr2Len)=tStr2 {
								set tWordPart1 = $e(tStr1,1,tStr2Len+1), tWordPart2 = $e(tStr1,tStr2Len+2,*)
								// peek at next word to verify it wasn't split off
								if ($piece(tEntityValue," ",tPosInEntity+1)=tWordPart2) { 
									set tPosInEntity = tPosInEntity+1
								// BDB855 - also try to recombine with the next word for apostophe'd cases
								} elseif ($tr($piece(tEntityValue," ",tPosInEntity,tPosInEntity+1)," ")=tStr1) {
									set tPosInEntity = tPosInEntity+1
								} else {
									$$$WRAPTAG(tWordPart2,tNonRelStyle,0,tWord)
									set tWord = tWordPart1_tWordPart2
								}
								set tPosInEntity = tPosInEntity+1
							} else {
								// otherwise, assume this is indeed a nonrelevant
								$$$WRAPTAG(tWord,tNonRelStyle,0,tWord)
							}
						}
					}
					
					// ATTRIBUTEWORDS
					if $d(tWordMap(tPosInLiteral)) {
						set tWord = $replace(tWordMap(tPosInLiteral,"O"),"$$$ID",tWordMap(tPosInLiteral,"ID"))_tWord_tWordMap(tPosInLiteral,"C")
					}
					
					set $li(tString,tPosInLiteral) = tWord
				}
				// DP-405449 - go through closing ones if string was normalized to anything shorter
				set tExtraClosing=tPosInLiteral
				for {
					set tExtraClosing = $order(tWordMap(tExtraClosing))
					quit:tExtraClosing=""
					if $d(tWordMap(tExtraClosing,"C"),tExtraClosingTag) {
						set $li(tString,tPosInLiteral) = $li(tString,tPosInLiteral)_tExtraClosingTag
					}
				}
				set tString = $s(tIsJapanese:$lts(tString,""), 1:$lts(tString," "))
				
				// now find out if there's any ATTRIBUTE highlighting
				set tAttId = ""
				for {
					set tAttId = $order(tHighlightDef("ATTRIBUTE", tAttId), 1, tIdTag)
					quit:tAttId=""
					continue:'$d(tAttMap(tAttId))
					
					// BDB845 - attribute properties
					set tIdTag = $replace(tIdTag,"$$$PROPERTIES",$g(tAttMap(tAttId,"props")))
					
					$$$WRAPTAG(tString,tIdTag,tAttId,tOriginalValue)
					set tHasData=0
				}
				if (tHasData#10) && (tAttMap'="") {
					$$$WRAPTAG(tString,tTag,tAttMap,tOriginalValue)
				}
			}
			
			// BDB522: STEM highlighting
			if tStemUniId {
				if $d(tHighlightDef("STEM", $s(vSrcId:-tStemUniId, 1:tStemUniId)), tTag) {
					$$$WRAPTAG(tString,tTag,tStemUniId,tOriginalValue)
				} elseif vSrcId {
					set tRealStemUniId = $lg($g(^IRIS.IKV.EntUniDetails(pDomainId,vSrcId,tStemUniId)),3)
					if tRealStemUniId && $d(tHighlightDef("STEM", tRealStemUniId), tTag) {
						$$$WRAPTAG(tString,tTag,tRealStemUniId,tOriginalValue)
					}
				}
			}
			
			
			// ENTITY highlighting
			if $d(tHighlightDef("ENTITY", $s(vSrcId:-tEntUniId, 1:tEntUniId)), tTag) {
				$$$WRAPTAG(tString,tTag,tEntUniId,tOriginalValue)
			} elseif vSrcId {
				set tRealEntUniId = $lg($g(^IRIS.IKV.EntUniDetails(pDomainId,vSrcId,tEntUniId)),3)
				if tRealEntUniId && $d(tHighlightDef("ENTITY", tRealEntUniId), tTag) {
					$$$WRAPTAG(tString,tTag,tRealEntUniId,tOriginalValue) 
				}
			}
			
			
			// CRC highlighting
			set tHasCrcs = $d(tHighlightDef("CRC"),tTag), tCRCs=""
			set tHasCcs = $d(tHighlightDef("CC"),tTagCC), tCCs=""
			if tHasCrcs || tHasCcs {
				for tCrcPos = 1:1:3 {
					set tCrcOccId = $lg(tEntOcc,4+tCrcPos)
					continue:'tCrcOccId
					set tCrcOcc = @gCrcOccId@(tCrcOccId)
					
					set tCrcId = $lg(tCrcOcc,1)
					set:vSrcId tRealCrcId = $lg($g(^IRIS.IKV.CrcUniDetails(pDomainId, vSrcId, tCrcId)),2), tCrcId=-tCrcId
					if $d(tHighlightDef("CRC", tCrcId), tIdTag) {
						$$$WRAPTAG(tString,tIdTag,tCrcId,tOriginalValue)
						set tHasCrcs = 0
					} elseif vSrcId && tRealCrcId && $d(tHighlightDef("CRC", tRealCrcId), tIdTag) {
						$$$WRAPTAG(tString,tIdTag,tRealCrcId,tOriginalValue)
						set tHasCrcs = 0
					}
					set tCRCs = tCRCs _ $s(tCRCs="":"", 1:",") _ tCrcId
					
					continue:'tHasCcs||(tCrcPos=2)
					set tCrc = @gCrcUniId@($zabs(tCrcId))
					set tHead = $li(tCrc,1), tTail = $li(tCrc,3)
					if tHead && tTail {
						set tCcId = $g(@gCcUni@(tHead,tTail))
						set:vSrcId tRealCcId = $lg($g(^IRIS.IKV.CcUniDet(pDomainId, vSrcId, tCcId)),2), tCcId = -tCcId
						if tCcId && $d(tHighlightDef("CC", tCcId), tIdTag) {
							$$$WRAPTAG(tString,tIdTag,tCcId,tOriginalValue)
							set tHasCcs=0
						} elseif vSrcId && tRealCcId && $d(tHighlightDef("CC", tRealCcId), tIdTag) {
							$$$WRAPTAG(tString,tIdTag,tRealCcId,tOriginalValue)
							set tHasCcs=0
						}
						set tCCs = tCCs _ $s(tCCs="":"", 1:",") _ tCcId
					}
				}
			}
			if (tHasCrcs#10) && (tCRCs'="") { $$$WRAPTAG(tString,tTag,tCRCs,tOriginalValue) }
			if (tHasCcs#10) && (tCCs'="") { $$$WRAPTAG(tString,tTagCC,tCCs,tOriginalValue) }
			
			
			// MATCH & MATCHITEM highlighting
			set tHasMatch = $d(tHighlightDef("MATCH"),tTag)
			set tHasMatchItem = $d(tHighlightDef("MATCHITEM"),tTagItem)
			if tHasAnyMatchInfo && (tVersionTables || (tRole'=$$$ENTTYPENONREL)) {
				
				#define META(%m,%id) $lg(@("^IRIS.IK.Mat."_$case($e(%m,4,7),"TERM":"DictTermId","ITEM":"DictItemId","DICT":"DictId"))@(tDictDomId,$zabs(%id)),$case($e(%m,4,*),"DICT":1,"ITEM":2,"ITEMURI":3,"TERM":3))
				#define GETMETA(%m,%id,%v) set:'$d(tMeta(%m,%id),%v) %v=$$$META(%m,%id), tMeta(%m,%id)=%v
				#define DOMETA(%t,%m,%id) if $find(%t,%m) { $$$GETMETA(%m,%id,v)  set %t = $replace(%t,%m,v) }
				
				kill tMatches, tMetaValues
				merge tMatches = @gEntOccToMatch@(tEntOccId)
				set tMatchId = "", tIDs="", tMaxEntScore=""
				for {
					set tMatchId = $order(tMatches(tMatchId))
					quit:tMatchId=""
					
					set tMatch = @gMatchId@(tMatchId)
					set tDictId = $li(tMatch,1), tDictItemId = $li(tMatch,2)
					set tDictTermId = $li(tMatch,3), tScore = $li(tMatch,6)
					set tDictDomId = $s(tDictId>0:pDomainId, 1:0)
					
					set tDE="", tEntScore=""
					for {
						set tDE = $order(tMatches(tMatchId, tDE), 1, tDEScore)
						quit:tDE=""
						set:tEntScore<tDEScore tEntScore = tDEScore
					}
					set:(tMaxEntScore<tEntScore) tMaxEntScore = tEntScore
					
					// prefetch metadata if any non-ID-level tags require it
					for m = "$$$TERM","$$$ITEM","$$$ITEMURI","$$$DICT" {
						// BDB552 - check against all possible tag definitions for non-ID-level matches
						if $find($g(tTag)_$g(tTagItem)_$g(tHighlightDefFP("MATCH","PARTIAL"))_$g(tHighlightDefFP("MATCH","FULL"))_$g(tHighlightDefFP("MATCHITEM","PARTIAL"))_$g(tHighlightDefFP("MATCHITEM","FULL")),m) {
							set tId = $case($e(m,4,7),"TERM":tDictTermId,"DICT":tDictId,:tDictItemId)
							$$$GETMETA(m,tId,tMetaValue)
							set tMetaValues(m) = $g(tMetaValues(m))_","_tMetaValue
						}
					}
					set tMetaValues("$$$TERMID") = $g(tMetaValues("$$$TERMID"))_","_tDictTermId
					set tMetaValues("$$$ITEMID") = $g(tMetaValues("$$$ITEMID"))_","_tDictItemId
					set tMetaValues("$$$DICTID") = $g(tMetaValues("$$$DICTID"))_","_tDictId
					set tMetaValues("$$$SCORE") = $g(tMetaValues("$$$SCORE"))_","_tScore
					set tMeta("$$$TERMID",tDictTermId)=tDictTermId
					set tMeta("$$$ITEMID",tDictItemId)=tDictItemId
					set tMeta("$$$DICTID",tDictId)=tDictId
					
					set tIDs = tIDs _ $s(tIDs="":"", 1:",") _ tMatchId
					if $d(tHighlightDef("MATCHITEM",tDictItemId)) {
						if '$d(tHighlightDef("MATCHITEM",tDictItemId,$case(tEntScore,1:"FULL",:"PARTIAL")),tIdTag) {
							continue:'($d(tHighlightDef("MATCHITEM",tDictItemId),tIdTag)#10)
						}
						for m = "$$$TERMID","$$$TERM","$$$ITEMID","$$$ITEMURI","$$$ITEM","$$$DICTID","$$$DICT" {
							set tId = $case($e(m,4,7),"TERM":tDictTermId,"DICT":tDictId,:tDictItemId)
							$$$DOMETA(tIdTag,m,tId)
						}
						set tIdTag = $replace(tIdTag,"$$$SCORE",tScore)
						$$$WRAPTAG(tString,tIdTag,tMatchId,tOriginalValue)
						set tHasMatchItem=0
					}
					if $d(tHighlightDef("MATCH",tDictId)) {
						if '$d(tHighlightDef("MATCH",tDictId,$case(tEntScore,1:"FULL",:"PARTIAL")),tIdTag) {
							continue:'($d(tHighlightDef("MATCH",tDictId),tIdTag)#10)
						}
						for m = "$$$TERMID","$$$TERM","$$$ITEMID","$$$ITEMURI","$$$ITEM","$$$DICTID","$$$DICT" {
							set tId = $case($e(m,4,7),"TERM":tDictTermId,"DICT":tDictId,:tDictItemId)
							$$$DOMETA(tIdTag,m,tId)
						}
						set tIdTag = $replace(tIdTag,"$$$SCORE",tScore)
						$$$WRAPTAG(tString,tIdTag,tMatchId,tOriginalValue)
						set tHasMatch=0
					}
				}
			}
			if ((tHasMatchItem#10) || $d(tHighlightDefFP("MATCHITEM"))) && (tIDs'="") { 
				set:$d(tHighlightDefFP("MATCHITEM",$case(tMaxEntScore,1:"FULL",:"PARTIAL")),tMatchTypeTag) tTagItem = tMatchTypeTag
				for m = "$$$TERMID","$$$TERM","$$$ITEMID","$$$ITEMURI","$$$ITEM","$$$DICTID","$$$DICT","$$$SCORE" {
					set tTagItem = $replace($g(tTagItem), m, $e($g(tMetaValues(m)),2,*))
				}
				$$$WRAPTAG(tString,tTagItem,tIDs,tOriginalValue)
			}
			if ((tHasMatch#10) || $d(tHighlightDefFP("MATCH"))) && (tIDs'="") { 
				set:$d(tHighlightDefFP("MATCH",$case(tMaxEntScore,1:"FULL",:"PARTIAL")),tMatchTypeTag) tTag = tMatchTypeTag
				for m = "$$$TERMID","$$$TERM","$$$ITEMID","$$$ITEMURI","$$$ITEM","$$$DICTID","$$$DICT","$$$SCORE" {
					set tTag = $replace($g(tTag), m, $e($g(tMetaValues(m)),2,*))
				}
				$$$WRAPTAG(tString,tTag,tIDs,tOriginalValue)
			}
			kill tMetaValues
			
			
			// PATH highlighting
			if $ld(tEntOcc,8,tPathId) {
				if $d(tHighlightDef("PATH",tPathId),tTag) {
					$$$WRAPTAG(tString,tTag,tPathId,tOriginalValue)
				} elseif ($d(tHighlightDef("PATH"),tTag)=1) && tPathId {
					$$$WRAPTAG(tString,tTag,tPathId,tOriginalValue)
				}
			}
			
			
			// ROLE highlighting
			if $d(tHighlightDef("ROLE",tRole),tTag) {
				$$$WRAPTAG(tString,tTag,tRole,tOriginalValue)
			}
			
			// BDB552 - treat positional highlighting
			if $d(tHighlightDef("CHARS")) {
				set tPositionalTagBefore="", tPositionalTagAfter=""
				set:tPrependSpace tCharPos = tCharPos+1
				set tCheckPos=tCharPos-1-tPrependSpace, tCharPos=tCharPos+tCharLength
				for {
					set tCheckPos = $order(tHighlightDef("CHARS",tCheckPos))
					quit:tCheckPos=""
					quit:tCheckPos>=tCharPos
					
					set tEndPos=""
					for {
						set tEndPos = $order(tHighlightDef("CHARS",tCheckPos,tEndPos),1,tTag)
						quit:tEndPos=""
						
						set tTag = $replace(tTag,"$$$ID",tCheckPos)
						set tPositionalTagBefore = $$$STARTTAG(tTag)_tPositionalTagBefore
						set tCharsEnd(tEndPos) = $g(tCharsEnd(tEndPos))_$$$ENDTAG(tTag)
					}
				}
				set tCheckPos=""
				for {
					set tCheckPos = $order(tCharsEnd(tCheckPos),1,tTag)
					quit:tCheckPos=""
					quit:tCheckPos>=tCharPos
					
					set tPositionalTagAfter = tPositionalTagAfter_tTag
					kill tCharsEnd(tCheckPos)
				}
				set tString = tPositionalTagBefore_tString_tPositionalTagAfter
			}
			
			// BDB552 - restore punctuation
			set tString = tPunctuationBefore_tString_tPunctuationAfter
			
			// append to the sentence
			set:tPrependSpace tString = " "_tString
			if ($length(pFullSentence(tPart)) + $length(tString) + 1 > 32000) {
				set x = $i(tPart), pFullSentence = 0
			}
			set pFullSentence(tPart) = $g(pFullSentence(tPart)) _ tString
		}
		
		// BDB552 - append any remaining positional end tags
		set tCheckPos=""
		for {
			set tCheckPos = $order(tCharsEnd(tCheckPos),1,tTag)
			quit:tCheckPos=""
			
			if ($length(pFullSentence(tPart)) + $length(tTag) + 1 > 32000) {
				set x = $i(tPart), pFullSentence = 0
			}
			set pFullSentence(tPart) = $g(pFullSentence(tPart)) _ tTag
		}
		
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit $g(pFullSentence(1))
}

Parameter GetAttributesRT = "attTypeId:%Integer,attType:%String,start:%Integer,span:%Integer,wordPositions:%String,properties:%String,level:%Integer";

/// <p>Returns all attributes for a given sentence. By default, only entity-level attributes are
/// returned, with the <i>wordPositions</i> result column referring which words within the affected
/// entities are actually attributed. Using <var>pIncludePathAttributes</var>, also path-level
/// attributes (such as implied negation) can be returned, but these will have no values for the
/// <i>wordPositions</i> column. Also note that the <i>start</i> and <i>span</i> columns for
/// path-level results will refer to positions within those paths and not entity positions within
/// the sentence. See also <method>GetAttributes</method> in <class>%iKnow.Queries.PathAPI</class>
/// and <method>GetOccurrenceAttributes</method> in <class>%iKnow.Queries.EntityAPI</class>.</p>
/// <p>Any named attribute properties are also
/// included through sub-nodes (not available through SQL or SOAP): 
/// <blockquote>pResult(<i>rowNumber</i>, <i>propertyName</i>) = <i>propertyValue</i></blockquote></p>
/// <p>The returned <var>wordPositions</var> apply to the entities starting from <var>start</var>
/// up to <var>offset</var> and only extend to the last attributed word position (there might 
/// be more words within the entity).</p>
ClassMethod GetAttributes(ByRef pResult, pDomainId As %Integer, pSentId As %Integer, vSrcId As %Integer = 0, pIncludePathAttributes As %Boolean = 0) As %Status
{
	$$$IKQBEGINTRY(pResult,"",tSC)
	if vSrcId && (pDomainId=0) {} else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	$$$IKCHECKVERSIONATLEASTX(pDomainId,$$$IKVERSIONATTRIBUTES,tSC)
	if (vSrcId) { $$$CHECKVSRCIDEXISTSX(pDomainId,vSrcId,tSC) }
	
	set gAttSent = $$$IKVGLOBNAME(pDomainId,"Att.Sent",vSrcId)
	
	set tAttTypeId = ""
	for {
		set tAttTypeId = $order(@gAttSent@(pSentId, tAttTypeId))
		quit:tAttTypeId=""
		
		set tStartPos=""
		for {
			set tStartPos = $order(@gAttSent@(pSentId, tAttTypeId, tStartPos), -1, tAtt)
			quit:tStartPos=""
			
			set tAttName = $$$IKATTTYPENAME(tAttTypeId)
			set tSpan = +$lg(tAtt,1), tWordPosAll=""
			for i=2:1:tSpan+1 {
				$$$IKATTWORDPOS($lg(tAtt,i),tWordPos)
				set tWordPosAll = tWordPosAll _ $s(tWordPosAll="":"", 1:" ") _ tWordPos
			}
			set tProps = $li(tAtt,tSpan+2,*)
			$$$IKQADDRESULT(pResult,$i(tCount),$lb(+tAttTypeId,tAttName,+tStartPos,tSpan,tWordPosAll,$lts(tProps,,1),$$$IKATTLVLSENT))
			
			set tSC = ##class(%iKnow.Queries.EntityAPI).BuildAttributePropArray(tAttTypeId,tProps,.tPropArray)
			quit:$$$ISERR(tSC)
			$$$IKQMERGERESULT(pResult,tCount,tPropArray)
		}
		quit:$$$ISERR(tSC)
	}
	
	if (pIncludePathAttributes) {
		set gAttPath = $$$IKVGLOBNAME(pDomainId,"Att.Path",vSrcId)
		set gSentDetails = $$$IKVGLOBNAME(pDomainId,"SentDetails",vSrcId)
		set tSentDetails = $g(@gSentDetails@(pSentId))
		
		set tPathId = $lg(tSentDetails,8), tLastPathId = tPathId + $lg(tSentDetails,9)
		for {
			set tPathId = $order(@gAttPath@(tPathId))
			quit:tPathId=""
			quit:tPathId>tLastPathId
			
			set tAttTypeId = ""
			for {
				set tAttTypeId = $order(@gAttPath@(tPathId, tAttTypeId))
				quit:tAttTypeId=""
				
				set tStartPos=""
				for {
					set tStartPos = $order(@gAttPath@(tPathId, tAttTypeId, tStartPos), -1, tAtt)
					quit:tStartPos=""
					
					set tAttName = $$$IKATTTYPENAME(tAttTypeId)
					set tSpan = +$lg(tAtt,1), tProps = $li(tAtt,2,*)
					$$$IKQADDRESULT(pResult,$i(tCount),$lb(+tAttTypeId,tAttName,+tStartPos,tSpan,,$lts(tProps,,1),$$$IKATTLVLPATH))
					
					set tSC = ##class(%iKnow.Queries.EntityAPI).BuildAttributePropArray(tAttTypeId,tProps,.tPropArray)
					quit:$$$ISERR(tSC)
					$$$IKQMERGERESULT(pResult,tCount,tPropArray)
				}
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
	}
	
	$$$IKQENDCATCH(pResult,"",tSC)
}

}
