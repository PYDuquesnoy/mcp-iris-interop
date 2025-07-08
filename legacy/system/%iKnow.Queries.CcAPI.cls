/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// <p>This is the main Query API to get access to Concept-Concept pairs (CCs). 
/// CCs are an abstraction of CRCs, aggregating them across relationships to focus only on those
/// concepts that are in a direct relationship with one another, without caring about the actual
/// relationship linking the two.</p>
Class %iKnow.Queries.CcAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

///  <p>Returns the entity values this CC is composed of.</p>
///  <p>When specifying a Virtual Source ID, it will treat the ccid as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetValue(pDomainId As %Integer, pCcId As %Integer, vSrcId As %Integer = 0, Output pSC As %Status = {$$$OK}) As %List
{
	$$$IKCHECKPRIVREADR(pSC,"")
	quit ..GetValueInternal(pDomainId, pCcId, vSrcId, .pSC)
}

/// Internal version of <method>GetValue</method>, skipping security checks.
ClassMethod GetValueInternal(pDomainId As %Integer, pCcId As %Integer, vSrcId As %Integer = 0, Output pSC As %Status = {$$$OK}) As %List [ Internal ]
{
	if (vSrcId) {
		set vSrcId = $zabs(vSrcId)
		set tCC = $get(^IRIS.IKV.CcUniId(pDomainId, vSrcId, pCcId))
	} else {
		$$$IKQBCHECKR(pDomainId,$$$IKBCCUNIALL,pSC,"")
		set tCC = $get(^IRIS.IK.CcUniId(pDomainId, pCcId))
	}
	
	quit:tCC="" $lb("", "")
	
	quit $lb(##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, $list(tCC, 1), vSrcId), 
				##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, $list(tCC, 2), vSrcId))
}

///  <p>Returns, if any, the CC ID for the combination of head and tail specified.</p>
///  <p>When specifying a Virtual Source ID, it will treat the heads and tails as virtual
///  entities, in the context of that vSrcId.</p>
ClassMethod GetId(pDomainId As %Integer, pHead As %String, pTail As %String, vSrcId As %Integer = 0, Output pSC As %Status = {$$$OK}) As %Integer
{
	set pSC = $$$OK
	$$$IKCHECKPRIVREADR(pSC,-1)
	quit ..GetIdInternal(pDomainId, .pHead, .pTail, vSrcId, .pSC, 0)
}

/// Internal version of <method>GetId</method>
ClassMethod GetIdInternal(pDomainId As %Integer, ByRef pHead As %String, ByRef pTail As %String, vSrcId As %Integer = 0, Output pSC As %Status = {$$$OK}, pStripPunctuation As %Boolean = 1) As %Integer [ Internal ]
{
	set pSC = $$$OK
	set vSrcId = $zabs(vSrcId)
	set tHeadId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, .pHead, vSrcId, pStripPunctuation)
	quit:tHeadId="" ""
	
	set tTailId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, .pTail, vSrcId, pStripPunctuation)
	quit:tTailId="" ""
	
	quit:vSrcId $get(^IRIS.IKV.CcUni(pDomainId, vSrcId, tHeadId, tTailId))
	$$$IKQBCHECKR(pDomainId,$$$IKBCCUNIALL,pSC,-1)
	quit $get(^IRIS.IK.CcUni(pDomainId, tHeadId, tTailId))
}

/// Returns the "inverse" of a CC pair, which means the CC composed of the same
/// head and tail entity, but at inverted positions.
ClassMethod GetInverse(domainId As %Integer, ccUniId As %Integer, Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	$$$CHECKDOMAINEXISTSR(domainId,sc,-1)
	$$$IKCHECKVERSIONATLEASTR(domainId,$$$IKVERSION20122,sc,-1)
	$$$IKQBCHECKR(domainId,$$$IKBCCUNIALL,sc,-1)
	set ents = $g(^IRIS.IK.CcUniId(domainId, ccUniId))
	quit:ents="" ""
	set m = $li(ents,1), s = $li(ents,2)
	quit:m=s ccUniId
	quit $g(^IRIS.IK.CcUni(domainId, s, m))
}

///  <p>Returns the frequency of the CC corresponding to the supplied <var>crcUniId</var>.</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetFrequency(domainId As %Integer, ccUniId As %Integer, vSrcId As %Integer = 0, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	
	if (vSrcId) {
		set details = $g(^IRIS.IKV.CcUniDet(+domainId,+$zabs(vSrcId),+ccUniId))
	} elseif (filter'="") {
		$$$IKQFILTEROBJECTR(domainId,filter,sc,-1)
		quit:'$isobject(filter) -1
		quit filter.GetFilteredCcFrequency(ccUniId, $$$IKFCCUNI)
	} else {
		$$$IKQBCHECKR(domainId,$$$IKBCCUNIDET,sc,-1)
		set details = $g(^IRIS.IK.CcUniDet(+domainId,+ccUniId))
	}
	quit:details="" -1
	
	quit +$lg(details,1)
}

///  <p>Returns the spread of the CC corresponding to the supplied <var>ccUniId</var>.</p>
ClassMethod GetSpread(domainId As %Integer, ccUniId As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	
	if (filter'="") {
		$$$IKQFILTEROBJECTR(domainId,filter,sc,-1)
		quit:'$isobject(filter) -1
		quit filter.GetFilteredCcSpread(ccUniId)
	}
	
	$$$IKQBCHECKR(domainId,$$$IKBCCUNIDET,sc,-1)
	set details = $g(^IRIS.IK.CcUniDet(+domainId,+ccUniId))
	quit:details="" -1
	
	quit +$lg(details,2)
}

Parameter GetByEntitiesRT = "HeadEntUniId:%Integer,HeadEntity:%String,TailEntUniId:%Integer,TailEntity:%String,frequency:%Integer,spread:%Integer,ccUniId:%Integer";

/// <p>This method will return all CC pairs in which any (if <i>setop</i> = $$$UNION) or all (if <i>setop</i> = $$$INTERSECT)
/// of the entities supplied in the <i>entitylist</i> participate, within the boundaries of the supplied domain.</p>
/// <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <i>filter</i>
/// parameter to restrict the result to those CCs occurring in any source satisfying the filter
/// criteria. When using a filter, the <i>filtermode</i> parameter will control whether or not the
/// frequency and spread of returned records should be recalculated and whether results should be
/// resorted along these recalculated numbers.</p>
/// <p>Specifying a value for <i>positionstomatch</i> will limit the result to
/// those CCs in which the supplied entities are on the Head (with <i>positionstomatch</i> = $$$USEPOSH) or
/// Tail (with <i>positionstomatch</i> = $$$USEPOST) side rather than either of the two (with 
/// <i>positionstomatch</i> = $$$USEPOSHT, default setting).</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, CCs containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those CCs containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(ByRef result, domainid As %Integer, entitylist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK
	
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, tIncludeActuals)
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetCCsInternal
	quit ..GetByEntitiesInternal(.result, domainid, .entIdList, page, pagesize, filter, filtermode, positionstomatch, sorttype)
}

Parameter GetByEntityIdsRT [ Internal ] = "HeadEntUniId:%Integer,HeadEntity:%String,TailEntUniId:%Integer,TailEntity:%String,frequency:%Integer,spread:%Integer,ccUniId:%Integer";

/// <p>This method looks up CCs based on a list of Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(ByRef result, domainid As %Integer, entityidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK

	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// unravel the entitylist into a clean %List
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .entIdList,,, tIncludeActuals)
	quit:$$$ISERR(tSC) tSC
	
	// forward to ..GetCCsInternal
	quit ..GetByEntitiesInternal(.result, domainid, .entIdList, page, pagesize, filter, filtermode, positionstomatch, sorttype)
}

ClassMethod GetByEntitiesInternal(ByRef result, domainid As %Integer, ByRef entIdList, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, filtermode As %Integer, positionstomatch As %Integer, sorttype As %Integer) As %Status [ Internal ]
{
	quit:$$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) ..GetByEntitiesInternal20121(.result, domainid, .entIdList, page, pagesize, filter, filtermode, positionstomatch, sorttype) 
	
	$$$IKQBEGINTRY(result,"^||%IK.CcSort,^||%IK.CcCandidates",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainid,sorttype,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),tSC)
	quit:'entIdList
	
	set:(sorttype=$$$SORTBYDOMAINDEFAULT) sorttype = $$$SORTFIELD(domainid)
	set tGlobs = $lb($s(sorttype=$$$SORTBYFREQUENCY:$$$IKBCCENTFREQ, 1:$$$IKBCCENTSPREAD), $$$IKBCCUNIDET)
	$$$IKQBCHECKX(domainid,tGlobs,tSC)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	set ccCombiSortGlo = "^IRIS.IK.CcEntCombi"_$s((sorttype=$$$SORTBYFREQUENCY):"Freq", 1:"Spread")_"("_domainid_")"
	set ccCandidateGlo = "^||%IK.CcCandidates"
	
	// first merge @ccCombiSort for all entities in entIdList
	set entId = ""
	for {
		set entId = $order(entIdList(entId))
		quit:entId=""
		
		if $$$CHECKPOSM(positionstomatch) && $$$CHECKPOSS(positionstomatch) {
			
			// TODO: maybe the loop below for page*pagesize is faster for large domains? (unfiltered)
			if (entIdList=1) {
				// if there's only one entity we're looking for, there's no need to merge
				set ccCandidateGlo = $name(@ccCombiSortGlo@(entId))
			} else {
				merge ^||%IK.CcCandidates = @ccCombiSortGlo@(entId)
			}
			
		} else {
			
			// if we're more picky about the position, we'll have to loop through the results
			set sort = ""
			for {
				set sort = $order(@ccCombiSortGlo@(entId,sort))
				quit:sort=""
				
				set ccId = ""
				for {
					set ccId = $order(@ccCombiSortGlo@(entId,sort,ccId),1,otherEntId)
					quit:ccId=""
					
					if (otherEntId=-entId) {}
					elseif (otherEntId>0) && $$$CHECKPOSM(positionstomatch) {}
					elseif (otherEntId<0) && $$$CHECKPOSS(positionstomatch) {}
					else { continue }
					
					set ^||%IK.CcCandidates(sort,ccId)=""
				}
			}
		}
	}
		
	// now simply loop through the candidates and populate the result
	// NOTE: as the global we started from is indexed by combined frequency, we'll ALWAYS resort
	set sort="", count=0, ewp=0
	for {
		set sort = $order(@ccCandidateGlo@(sort))
		quit:sort=""
		
		$$$IKQENTRIESWITHINPAGE(^||%IK.CcSort,sort,usePaging,last,ewp)
		
		set ccId=""
		for {
			set ccId = $order(@ccCandidateGlo@(sort,ccId))
			quit:ccId=""
			
			if $isobject(filter) {
				continue:'filter.IsFiltered(ccId,$$$IKFCCUNI)
			}
			
			set (freq,spread) = 0
			if $isobject(filter) {
				set:$$$CHECKFILTERFREQ(filter,filtermode) freq = filter.GetFilteredCcFrequency(ccId, $$$IKFCCUNI)
				set:$$$CHECKFILTERSPREAD(filter,filtermode) spread = filter.GetFilteredCcSpread(ccId, $$$IKFCCUNI)
			}
			
			set entIds = ^IRIS.IK.CcUniId(domainid, ccId)
			set m = $li(entIds,1), mString = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid,m)
			set s = $li(entIds,2), sString = ##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid,s)
			
			set:'(freq*spread) details = ^IRIS.IK.CcUniDet(domainid, ccId)
			set:'freq freq = $li(details,1)
			set:'spread spread = $li(details,2)
			
			set res = $lb(m,mString,s,sString,freq,spread,+ccId)
			
			set resort = -$s((sorttype=$$$SORTBYFREQUENCY):freq, 1:spread)
			$$$IKQADDRESULTSORT(^||%IK.CcSort,resort,res)
			if (resort<sort) { set ewp=ewp+1  quit:(ewp>last) }
		}
	}
	set tSC = ..CopyFromTempSortGlobal(.result,"^||%IK.CcSort",usePaging,first,last)
	$$$IKQENDCATCH(result,"^||%IK.CcSort,^||%IK.CcCandidates",tSC)
}

ClassMethod GetByEntitiesInternal20121(ByRef result, domainid As %Integer, ByRef entIdList, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, filtermode As %Integer, positionstomatch As %Integer, sorttype As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.GetCCsIntSort,^||%IK.GetCCsIntFSort,^||%IK.GetCCsIntTrack,^||%IK.GetCCsIntCrcOccMS,^||%IK.GetCCsIntCrcOccSM,^||%IK.GetCCsIntSrcMS,^||%IK.GetCCsIntSrcSM",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainid,sorttype,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),tSC)
	quit:'$d(entIdList)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// TODO: now that there's separate CC globals for combined and directional frequencies,
	//			check if the algorithm below cannot be simplified
	
	// define which sorted global to use
	if (sorttype="") || (sorttype = $$$SORTBYDOMAINDEFAULT) {
		set sorttype = $$$SORTFIELD(domainid)
	}
	
	// we'll keep track of the maximum sort order for each entry in the entitylist
	// first set starting orders in ^||%IK.GetCCsIntSort(sortOrder, entId)
	set entId = ""
	set i = 0
	for {
		set entId = $order(entIdList(entId))
		quit:entId=""
		
		set i = i+1
		
		if (sorttype = $$$SORTBYFREQUENCY) {
			set maxSortOrder = $order(^IRIS.IK.CcCombiFreq(domainid, entId, ""))
		} elseif (sorttype = $$$SORTBYSPREAD) {
			set maxSortOrder = $order(^IRIS.IK.CcCombiSpread(domainid, entId, ""))
		}
		continue:maxSortOrder=""
		
		set ^||%IK.GetCCsIntSort(maxSortOrder, entId) = ""
	}
	
	// now add the CCs starting with the maxSortOrder and kill and refresh its entry after use
	set maxSortOrder = ""
	for {
		// find the first entry in the sorted list
		set maxSortOrder = $order(^||%IK.GetCCsIntSort(""))
		quit:maxSortOrder=""
			
		// when the value for maxSortOrder changes, we have to verify how many entries
		// are certainly within the desired page boundary
		if (usePaging) {
			set entriesWithinPage = 0
			set sortCheck = ""
			for {
				set sortCheck = $order(^||%IK.GetCCsIntFSort(sortCheck))
				quit:sortCheck=""
				
				// sort order is negative, so sortCheck < maxSortOrder means this entry
				// in the current result list is certainly in the final results as
				// sort can only increase
				if (sortCheck < maxSortOrder) {
					set entriesWithinPage = entriesWithinPage + 1
				} else {
					quit
				}
			}
			if (entriesWithinPage > last) {
				quit
			}
		}
		
		set maxSortOrderEntId = $order(^||%IK.GetCCsIntSort(maxSortOrder, ""))
		
		// now loop through the results for this maxSortOrderEntId
		set otherEntId = ""
		for {
			if (sorttype = $$$SORTBYFREQUENCY) {
				set otherEntId = $order(^IRIS.IK.CcCombiFreq(domainid, maxSortOrderEntId, maxSortOrder, otherEntId))
			} elseif (sorttype = $$$SORTBYSPREAD) {
				set otherEntId = $order(^IRIS.IK.CcCombiSpread(domainid, maxSortOrderEntId, maxSortOrder, otherEntId))
			}
			quit:otherEntId=""
			continue:otherEntId=0
			
			// fetch the details for the MS and SM pairs
			set detailsMS = $lb(0,0)
			set detailsSM = $lb(0,0)
			if ($$$CHECKPOSM(positionstomatch)) {
				set detailsSM = $get(^IRIS.IK.CcUniDetails(domainid, maxSortOrderEntId, otherEntId), $lb(0, 0))
			}
			if ($$$CHECKPOSS(positionstomatch)) {
				set detailsMS = $get(^IRIS.IK.CcUniDetails(domainid, otherEntId, maxSortOrderEntId), $lb(0, 0))
			}
			
			// when filtering, apply filters and recalculate appropriate totals
			if ($isobject(filter)) {
				
				kill ^||%IK.GetCCsIntCrcOccMS, ^||%IK.GetCCsIntCrcOccSM
				kill ^||%IK.GetCCsIntSrcMS, ^||%IK.GetCCsIntSrcSM
				
				set filterIncludeMS = 0
				set filterIncludeSM = 0
				set filteredFreqMS = 0
				set filteredFreqSM = 0
				set filteredSpreadMS = 0
				set filteredSpreadSM = 0
				
				// we first have to find out which Crcs satisfy both the filter
				// and the CC requirements, based on CRC filters
				set crcOffset = ""
				for {
					set crcOffset = filter.GetNextCRCUniqueFilterOffset(crcOffset, .crcBits)
					quit:crcOffset=""
					
					// now merge with ^IRIS.IK.EntUniToCrcM and ^IRIS.IK.EntUniToCrcS to check
					// if there are any crcs satisfying the filter that correspond to
					// maxSortOrderEntId and otherEntId at their respective positions
					if ($$$CHECKPOSS(positionstomatch) && ($list(detailsMS, 1) > 0)) {
						set crcBitsMS = $bitlogic(crcBits & ^IRIS.IK.EntUniMToCrcUniBit(domainid, otherEntId, crcOffset))
						set crcBitsMS = $bitlogic(crcBitsMS & ^IRIS.IK.EntUniSToCrcUniBit(domainid, maxSortOrderEntId, crcOffset))
					
						//set ^||%IK.GetCCsIntCrcMS(crcOffset) = crcBitsMS
						
						// if we're only trying to satisfy the filter, just check for a 1
						if ($$$CHECKFILTERONLY(filtermode) && ($bitfind(crcBitsMS, 1) > 0)) {
							set filterIncludeMS = 1
						}
						
						// if we're recalculating spread, loop through these CRCs and merge
						// the sources in which it appears into ^||%IK.GetCCsIntSrcMS entries
						// if we're recalculating frequency, use the same loop to count the
						// occurrences for each CRC
						if ($$$CHECKFILTERSPREAD(filter,filtermode) || $$$CHECKFILTERFREQ(filter,filtermode)) {
							set crcPos = 0
							for {
								set crcPos = $bitfind(crcBitsMS, 1, crcPos + 1)
								quit:crcPos=0
								
								$$$IKGETIDOFFPOS(crcUniId,crcOffset,crcPos)
								
								// for spread recalc
								if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
									set srcOffset = ""
									for {
										set srcOffset = $order(^IRIS.IK.CrcUniToSrcBit(domainid, crcUniId, srcOffset), 1, srcBits)
										quit:srcOffset=""
										
										set ^||%IK.GetCCsIntSrcMS(srcOffset) = $bitlogic(srcBits | ^||%IK.GetCCsIntSrcMS(srcOffset))
									}
								}
									
								// for freq recalc
								if ($$$CHECKFILTERFREQ(filter,filtermode)) {
									set occOffset = ""
									for {
										set occOffset = $order(^IRIS.IK.CrcUniToOccBit(domainid, crcUniId, occOffset), 1, occBits)
										quit:occOffset=""
										
										set filterBits = filter.GetCRCOccurrenceFilter(occOffset)
										set mergedbits = $bitlogic(occBits & filterBits)
										set filteredFreqMS = filteredFreqMS + $bitcount(mergedbits, 1)
									}
								}
							}
						}
					}
					
					// now do the same for the Tail-Head pair
					if ($$$CHECKPOSM(positionstomatch) && ($list(detailsSM, 1) > 0)) {
						set crcBitsSM = $bitlogic(crcBits & ^IRIS.IK.EntUniMToCrcUniBit(domainid, maxSortOrderEntId, crcOffset))
						set crcBitsSM = $bitlogic(crcBitsSM & ^IRIS.IK.EntUniSToCrcUniBit(domainid, otherEntId, crcOffset))
						
						//set ^||%IK.GetCCsIntCrcSM(crcOffset) = crcBitsSM
						
						// if we're only trying to satisfy the filter, just check for a 1
						if ($$$CHECKFILTERONLY(filtermode) && ($bitfind(crcBitsSM, 1) > 0)) {
							set filterIncludeSM = 1
						}
						
						// now do the same for SM
						if ($$$CHECKFILTERSPREAD(filter,filtermode) || $$$CHECKFILTERFREQ(filter,filtermode)) {
							set crcPos = 0
							for {
								set crcPos = $bitfind(crcBitsSM, 1, crcPos + 1)
								quit:crcPos=0
								
								$$$IKGETIDOFFPOS(crcUniId,crcOffset,crcPos)
								
								// for spread recalc
								if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
									set srcOffset = ""
									for {
										set srcOffset = $order(^IRIS.IK.CrcUniToSrcBit(domainid, crcUniId, srcOffset), 1, srcBits)
										quit:srcOffset=""
										
										set ^||%IK.GetCCsIntSrcSM(srcOffset) = $bitlogic(srcBits | ^||%IK.GetCCsIntSrcSM(srcOffset))
									}
								}
									
								// for freq recalc
								if ($$$CHECKFILTERFREQ(filter,filtermode)) {
									set occOffset = ""
									for {
										set occOffset = $order(^IRIS.IK.CrcUniToOccBit(domainid, crcUniId, occOffset), 1, occBits)
										quit:occOffset=""
										
										set filterBits = filter.GetCRCOccurrenceFilter(occOffset)
										set mergedbits = $bitlogic(occBits & filterBits)
										set filteredFreqSM = filteredFreqSM + $bitcount(mergedbits, 1)
									}
								}
							}
						}
					}
					
					// if we're only filtering without recalc, we can quit if we know
					// both MS and SM satisfy the filter
					if ($$$CHECKFILTERONLY(filtermode) && (filterIncludeMS = 1) && (filterIncludeSM = 1)) {
						quit
					}
				}
				
				// now we can recalc spread based on ^||%IK.GetCCsIntSrcXX
				if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
					set srcOffset = ""
					for {
						set srcOffset = $order(^||%IK.GetCCsIntSrcMS(srcOffset), 1, srcBits)
						quit:srcOffset=""
						
						set filteredSpreadMS = filteredSpreadMS + $bitcount(srcBits, 1)
					}
					
					set srcOffset = ""
					for {
						set srcOffset = $order(^||%IK.GetCCsIntSrcSM(srcOffset), 1, srcBits)
						quit:srcOffset=""
						
						set filteredSpreadSM = filteredSpreadSM + $bitcount(srcBits, 1)
					}
				}
				
				// skip if nothing satisfies the filter
				If $$$CHECKFILTERONLY(filtermode),'(filterIncludeMS+filterIncludeSM) {
					Continue
				} ElseIf $$$CHECKFILTERSPREAD(filter,filtermode),'(filteredSpreadMS+filteredSpreadSM) {
					Continue
				} ElseIf $$$CHECKFILTERFREQ(filter,filtermode),'(filteredFreqMS+filteredFreqSM) {
					Continue
				}
				
				// clean up utility globals
				kill ^||%IK.GetCCsIntCrcOccMS, ^||%IK.GetCCsIntCrcOccSM
				kill ^||%IK.GetCCsIntSrcMS, ^||%IK.GetCCsIntSrcSM
				
				// store the filtered freq and spread
				if ($$$CHECKFILTERFREQ(filter,filtermode)) {
					set $list(detailsMS, 1) = filteredFreqMS
					set $list(detailsSM, 1) = filteredFreqSM
				}
				if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
					set $list(detailsMS, 2) = filteredSpreadMS
					set $list(detailsSM, 2) = filteredSpreadSM
				}
			}
			
			// now add the MS entry if it occurs
			// duplicate entries will overwrite themselves, so we don't bother
			if ($list(detailsMS, 1) > 0) {
				
				// build the entry and store in ^||%IK.GetCCsIntFSort
				if (sorttype = $$$SORTBYFREQUENCY) {
					set thisSortOrder = -$list(detailsMS, 1)
				} elseif (sorttype = $$$SORTBYSPREAD) {
					set thisSortOrder = -$list(detailsMS, 2)
				}
				
				set cc = $lb(
								otherEntId,
								$s(otherEntId:^IRIS.IK.EntUniId(domainid, otherEntId), 1:""), 
								maxSortOrderEntId,
								$s(maxSortOrderEntId:^IRIS.IK.EntUniId(domainid, maxSortOrderEntId), 1:""),
								$list(detailsMS, 1),
								$list(detailsMS, 2)
							)
				
				set ^||%IK.GetCCsIntFSort(thisSortOrder, $i(^||%IK.GetCCsIntFSort)) = cc
			}
			
			// and do the same for the SM entry
			if ($list(detailsSM, 1) > 0) {
				
				// build the entry and store in ^||%IK.GetCCsIntFSort
				if (sorttype = $$$SORTBYFREQUENCY) {
					set thisSortOrder = -$list(detailsSM, 1)
				} elseif (sorttype = $$$SORTBYSPREAD) {
					set thisSortOrder = -$list(detailsSM, 2)
				}
				
				set cc = $lb(
								maxSortOrderEntId,
								^IRIS.IK.EntUniId(domainid, maxSortOrderEntId),
								otherEntId,
								^IRIS.IK.EntUniId(domainid, otherEntId), 
								$list(detailsSM, 1),
								$list(detailsSM, 2)
							)
				
				// store in a sorted global
				set ^||%IK.GetCCsIntFSort(thisSortOrder, $i(^||%IK.GetCCsIntFSort)) = cc
			}
		}
		
		// kill the maxSortOrder entry
		kill ^||%IK.GetCCsIntSort(maxSortOrder, maxSortOrderEntId)
		
		// find a new entry for this maxSortOrderEntId and add it
		if (sorttype=$$$SORTBYFREQUENCY) {
			set maxSortOrder = $order(^IRIS.IK.CcCombiFreq(domainid, maxSortOrderEntId, maxSortOrder))
		} elseif (sorttype=$$$SORTBYSPREAD) {
			set maxSortOrder = $order(^IRIS.IK.CcCombiSpread(domainid, maxSortOrderEntId, maxSortOrder))
		}
		
		if (maxSortOrder '= "") {
			set ^||%IK.GetCCsIntSort(maxSortOrder, maxSortOrderEntId) = ""
		}
	}
	
	// finally, we'll have to re-sort the intermediate results in ^||%IK.GetCCsIntFSort as 
	// the sort order depends on positionstomatch and eventual filters
	set tSC = ..CopyFromTempSortGlobal(.result, "^||%IK.GetCCsIntFSort", usePaging, first, last)
	quit:$$$ISERR(tSC)
	
	$$$IKQENDCATCH(result,"^||%IK.GetCCsIntSort,^||%IK.GetCCsIntFSort,^||%IK.GetCCsIntTrack,^||%IK.GetCCsIntCrcOccMS,^||%IK.GetCCsIntCrcOccSM,^||%IK.GetCCsIntSrcMS,^||%IK.GetCCsIntSrcSM",tSC)
}

/// <p>This method returns the number of CC pairs based on a list of entities.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", positionstomatch As %Integer = {$$$USEPOSHT}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entitylist="" 0
	
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// translate & clean entity list
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .cleanEntIdList,,, tIncludeActuals)
	quit:$$$ISERR(sc) -1
	
	quit ..GetCountByEntitiesInternal(domainid, .cleanEntIdList, filter, positionstomatch, .sc)
}

/// <p>This method returns the number of CC pairs based on a list of entity ids.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", positionstomatch As %Integer = {$$$USEPOSHT}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entityidlist="" 0

	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// translate & clean entity list
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanEntIdList,,, tIncludeActuals)
	quit:$$$ISERR(sc) -1
	
	quit ..GetCountByEntitiesInternal(domainid, .cleanEntIdList, filter, positionstomatch, .sc)
}

ClassMethod GetCountByEntitiesInternal(domainid As %Integer, ByRef entityIdList, filter As %iKnow.Filters.Filter, positionstomatch As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	quit:$$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) ..GetCountByEntitiesInternal20121(domainid, .entityIdList, filter, positionstomatch, .sc) 
	
	$$$IKQBEGINR("^||%IK.CcCount",sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'$d(entityIdList) 0
	
	$$$IKQBCHECKR(domainid,$lb($$$IKBCCUNIMAP),sc,-1)
	
	set entId=""
	for {
		set entId = $order(entityIdList(entId))
		quit:entId=""
		
		for pos = "M","S" {
			
			continue:'$$$CHECKPOSM(positionstomatch)&&(pos="M")
			continue:'$$$CHECKPOSS(positionstomatch)&&(pos="S")
			
			$$$IKMERGEBITSOR("^IRIS.IK.EntUni"_pos_"ToCcUniBit("_domainid_","_entId_")","^||%IK.CcCount")
		}
	}
	
	set total = 0, off=0
	for {
		set off = $order(^||%IK.CcCount(off),1,bits)
		quit:off=""
		
		if $isobject(filter) {
			set filterBits = filter.GetCcUniqueFilter(off)
			set bits = $bitlogic(bits & filterBits)
		}
		
		set total = total + $bitcount(bits,1)
	}
	
	$$$IKQEND("^||%IK.CcCount",total)
}

ClassMethod GetCountByEntitiesInternal20121(domainid As %Integer, ByRef entityIdList, filter As %iKnow.Filters.Filter, positionstomatch As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("^||%IK.GetTotCCsTrack",sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'$d(entityIdList) 0
	
	set total = 0
	
	// if the input list is empty, return 0
	if ($order(entityIdList("")) = "") {
		quit 0
	}
	
	// loop through the supplied entities
	set entId = ""
	set i = 0
	for {
		set entId = $order(entityIdList(entId))
		quit:entId=""
		
		set i = i+1
		
		// loop through ^IRIS.IK.EntUniMToEntUniS and check the resulting EntUniId bitstrings
		if ($$$CHECKPOSM(positionstomatch)) {
			set relEntOffset = ""
			for {
				set relEntOffset = $order(^IRIS.IK.EntUniMToEntUniSBit(domainid, entId, relEntOffset), 1, relEntBits)
				quit:relEntOffset=""
				
				// if we're not filtering, every 1 in this bitstring means a valid CC
				// to add to the totals
				if ('$isobject(filter)) {
					
					set total = total + $bitcount(relEntBits, 1)
					
				} else {
					
					// when filtering, we have to loop through these relEntBits and check
					// for every corresponding CC pair whether it occurs as a CRC in a source 
					// satisfying the filter
					set relEntPos = 0
					for {
						set relEntPos = $bitfind(relEntBits, 1, relEntPos + 1)
						quit:relEntPos=0
						
						$$$IKGETIDOFFPOS(relEntId,relEntOffset,relEntPos)
						
						// now find the CRCs corresponding to this CC using the ^IRIS.IK.EntUniToCrcX
						set crcOffset = ""
						for {
							set crcOffset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, entId, crcOffset), 1, crcBits)
							quit:crcOffset=""
							
							// combine with the other half of the CC
							set crcBits = $bitlogic(crcBits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, relEntId, crcOffset))
							
							// combine with the CRC filter
							set filterBits = filter.GetCRCUniqueFilter(crcOffset)
							set crcBits = $bitlogic(crcBits & filterBits)
							
							// if we have a hit, increment the total and exit this loop
							if ($bitfind(crcBits, 1) > 0) {
								set total = total + 1
								
								// to make sure we don't add duplicates in the Tail-based run,
								// track which entry was counted
								set ^||%IK.GetTotCCsTrack(entId, relEntId) = ""
								
								quit
							}
						}
					}
				}
			}
		}
		
		// now do the same for the other way around, Tail-based
		if ($$$CHECKPOSS(positionstomatch)) {
			set relEntOffset = ""
			for {
				set relEntOffset = $order(^IRIS.IK.EntUniSToEntUniMBit(domainid, entId, relEntOffset), 1, relEntBits)
				quit:relEntOffset=""
				
				// if we're not filtering, every 1 in this bitstring means a valid CC
				// to add to the totals
				if ('$isobject(filter)) {
					
					// if we're checking both directions, we should make sure not to count
					// twice those CCs that contain two entities from the input list
					if ($$$CHECKPOSM(positionstomatch)) {
						set checkEntId = ""
						for {
							set checkEntId = $order(entityIdList(checkEntId))
							quit:checkEntId=""
							
							// if the checkEntId falls within this relEntOffset, cancel out
							// the bit corresponding to this CC, as it has already been
							// counted in the first (Head-based) run
							if ((checkEntId\64000)+1 = relEntOffset) {
								set $bit(relEntBits, (checkEntId#64000)+1) = 0
							}
						}
					}
					
					// add the remaining CCs to the total
					set total = total + $bitcount(relEntBits, 1)
					
				} else {
					
					// when filtering, we have to loop through these relEntBits and check
					// for every corresponding CC pair whether it occurs as a CRC in a source 
					// satisfying the filter
					set relEntPos = 0
					for {
						set relEntPos = $bitfind(relEntBits, 1, relEntPos + 1)
						quit:relEntPos=0
						
						$$$IKGETIDOFFPOS(relEntId,relEntOffset,relEntPos)
						
						// first check if this entry has not yet been added to the list
						// in a previous run, based on overlap with the supplied entity list
						if ($data(^||%IK.GetTotCCsTrack(relEntId, entId)) = 0) {
							continue
						}
						
						// now find the CRCs corresponding to this CC using the ^IRIS.IK.EntUniToCrcX
						set crcOffset = ""
						for {
							set crcOffset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, relEntId, crcOffset), 1, crcBits)
							quit:crcOffset=""
							
							// combine with the other half of the CC
							set crcBits = $bitlogic(crcBits & ^IRIS.IK.EntUniSToCrcUniBit(domainid, entId, crcOffset))
							
							// combine with the CRC filter
							set filterBits = filter.GetCRCUniqueFilter(crcOffset)
							set crcBits = $bitlogic(crcBits & filterBits)
							
							// if we have a hit, increment the total and exit this loop
							if ($bitfind(crcBits, 1) > 0) {
								set total = total+1
								quit
							}
						}
					}
				}
			}
		}
	}
	
	$$$IKQEND("^||%IK.GetTotCCsTrack",total)
}

///  <p>Returns the total number of unique CCs appearing in either (if <var>setop</var> = $$$UNION) or
///  all (if <var>setop</var> = $$$INTERSECT) of the sources specified by ID in <var>sourceidlist</var>.</p>
///  <p>To get the unique CCs of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %List, setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("^||%IK.GetTotCcsBit",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	// simple implementation if we're looking at a virtual source
	if ($li(sourceidlist,1)<0) && ($ll(sourceidlist)=1) {
		set vSrcId = -$li(sourceidlist,1)
		$$$CHECKVSRCIDEXISTSR(domainid,vSrcId,sc,-1)
		quit $o(^IRIS.IKV.CcUniId(domainid, vSrcId, ""),-1)
	}
	
	$$$IKQBCHECKR(domainid,$lb($$$IKBCCUNIALL),sc,-1)
	
	// join ^IRIS.IK.SrcToCcUniBit entries for the sources in the list
	for i = 1:1:$listlength(sourceidlist) {
		
		set srcId = $list(sourceidlist, i)
		continue:'+srcId
		quit:srcId<0
		
		set gFrom = $name(^IRIS.IK.SrcToCcUniBit(domainid, srcId))
		if (setop = $$$UNION) || (i=1) {
			$$$IKMERGEBITSOR(gFrom,"^||%IK.GetTotCcsBit")
		} else {
			$$$IKMERGEBITSAND(gFrom,"^||%IK.GetTotCcsBit")
		}
	}
	
	// if we ran into a negative srcId, return error
	if (srcId<0) {
		set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
		quit -1
	}
	
	// now count the remaining 1s
	set total = 0
	set ccOffset = ""
	for {
		set ccOffset = $order(^||%IK.GetTotCcsBit(ccOffset), 1, ccBits)
		quit:ccOffset=""
		
		set total = total + $bitcount(ccBits, 1)
	}
	
	$$$IKQEND("^||%IK.GetTotCcsBit",total)
}

}
