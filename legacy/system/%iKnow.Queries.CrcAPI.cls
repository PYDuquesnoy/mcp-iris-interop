/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
///  This is the main Query API to retrieve Concept-Relation-Concept triples (CRCs).
///  In a CRC, the first concept is called the Head and the last the Tail, which are linked to 
///  one another through the Relation element.
Class %iKnow.Queries.CrcAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

Parameter GetValueRT = "head:%String,relation:%String,tail:%String";

///  <p>Returns the entity values this CRC is composed of.</p>
///  <p>When specifying a Virtual Source ID, it will treat the crcid as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetValue(domainid As %Integer, crcid As %Integer, vSrcId As %Integer = 0) As %List
{
	$$$IKCHECKPRIVREADR(sc,"")
	quit ..GetValueInternal(domainid, crcid, vSrcId)
}

/// Internal version of <method>GetValue</method>, skipping security checks.
ClassMethod GetValueInternal(domainid As %Integer, crcid As %Integer, vSrcId As %Integer = 0) As %List [ Internal ]
{
	if (vSrcId) {
		set vSrcId = $zabs(vSrcId)
		set crc = $get(^IRIS.IKV.CrcUniId(domainid, vSrcId, crcid))
	} else {
		set crc = $get(^IRIS.IK.CrcUniId(domainid, crcid))
	}
	
	quit:crc="" $lb("", "", "")
	
	quit $lb(##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, $list(crc, 1), vSrcId), 
				##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, $list(crc, 2), vSrcId), 
				##class(%iKnow.Queries.EntityAPI).GetValueInternal(domainid, $list(crc, 3), vSrcId))
}

///  <p>Returns, if any, the CRC ID for the combination of Head, Relation and Tail specified.</p>
///  <p>When specifying a Virtual Source ID, it will treat the head, relation and tails as virtual
///  entities, in the context of that vSrcId.</p>
ClassMethod GetId(domainid As %Integer, head As %String, relation As %String, tail As %String, vSrcId As %Integer = 0) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	quit ..GetIdInternal(domainid, .head, .relation, .tail, vSrcId, 0)
}

/// Internal version of <method>GetId</method>
ClassMethod GetIdInternal(domainid As %Integer, ByRef head As %String, ByRef relation As %String, ByRef tail As %String, vSrcId As %Integer = 0, stripPunctuation As %Boolean = 1) As %Integer [ Internal ]
{
	set vSrcId = $zabs(vSrcId)
	set headId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .head, vSrcId, stripPunctuation)
	quit:headId="" ""
	set relationId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .relation, vSrcId, stripPunctuation)
	quit:relationId="" ""
	set tailId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .tail, vSrcId, stripPunctuation)
	quit:tailId="" ""
	
	quit:vSrcId $get(^IRIS.IKV.CrcUni(domainid, vSrcId, headId, relationId, tailId))
	quit $get(^IRIS.IK.CrcUni(domainid, headId, relationId, tailId))
}

///  <p>Returns the frequency of the CRC corresponding to the supplied <var>crcUniId</var>.</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetFrequency(domainId As %Integer, crcUniId As %Integer, vSrcId As %Integer = 0, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	
	if (vSrcId) {
		set details = $g(^IRIS.IKV.CrcUniDetails(+domainId,+$zabs(vSrcId),+crcUniId))
	} elseif (filter'="") {
		$$$IKQFILTEROBJECTR(domainId,filter,sc,-1)
		quit:'$isobject(filter) -1
		quit filter.GetFilteredCrcFrequency(crcUniId)
	} else {
		$$$IKQBCHECKR(domainId,$$$IKBCRCUNIDET,sc,-1)
		set details = $g(^IRIS.IK.CrcUniDetails(+domainId,+crcUniId))
	}
	quit:details="" -1
	
	quit +$lg(details,1)
}

///  <p>Returns the spread of the CRC corresponding to the supplied <var>crcUniId</var>.</p>
ClassMethod GetSpread(domainId As %Integer, crcUniId As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}) As %Integer
{
	set sc = $$$OK
	$$$IKCHECKPRIVREADR(sc,-1)
	
	if (filter'="") {
		$$$IKQFILTEROBJECTR(domainId,filter,sc,-1)
		quit:'$isobject(filter) -1
		quit filter.GetFilteredCrcSpread(crcUniId)
	}
	
	$$$IKQBCHECKR(domainId,$$$IKBCRCUNIDET,sc,-1)
	set details = $g(^IRIS.IK.CrcUniDetails(+domainId,+crcUniId))
	quit:details="" -1
	
	quit +$lg(details,2)
}

Parameter GetByEntitiesRT = "crcId:%Integer,head:%String,relation:%String,tail:%String,frequency:%Integer,spread:%Integer";

///  <p>This method will return all CRC triples in which any of the entities supplied in the <var>entitylist</var>
///  participate, within the boundaries of the supplied domain.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Specifying a value for <var>positionstomatch</var> will limit the result to
///  those CRCs in which the supplied entities are in the Head (with <var>positionstomatch</var> = $$$USEPOSH),
///  Relation (with <var>positionstomatch</var> = $$$USEPOSR) or Tail (with <var>positionstomatch</var> = $$$USEPOST) role
///  of the CRC, or in any combination of these (with <var>positionstomatch</var> = $$$USEPOSHT, $$$USEPOSHR, 
///  $$$USEPOSRT, $$$USEPOSALL (the default)).</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, CRCs containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those CRCs containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(ByRef result, domainid As %Integer, entitylist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSALL}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entitylist="" $$$OK

	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)
	
	// unravel the entitylist into a clean %List
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .entIdList,,, tIncludeActuals)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByEntitiesInternal
	quit ..GetByEntitiesInternal(.result, domainid, .entIdList, page, pagesize, filter, filtermode, positionstomatch)
}

Parameter GetByEntityIdsRT = "crcId:%Integer,head:%String,relation:%String,tail:%String,frequency:%Integer,spread:%Integer";

///  <p>Returns the CRCs in this domain containing any or all of a list of entity IDs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(ByRef result, domainid As %Integer, entityidlist As %List, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSALL}, pActualFormOnly As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(result,"")
	$$$CHECKDOMAINEXISTS(domainid)
	quit:entityidlist="" $$$OK
	
	
	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)
	
	// clean the entIdList from duplicates or nonexistent ids
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanEntIdList,,, tIncludeActuals)
	quit:$$$ISERR(tSC) tSC
	
	// forward to GetByEntitiesInternal
	quit ..GetByEntitiesInternal(.result, domainid, .cleanEntIdList, page, pagesize, filter, filtermode, positionstomatch)
}

ClassMethod GetByEntitiesInternal(ByRef result, domainid As %Integer, ByRef entitylist, page As %Integer, pagesize As %Integer, filter As %iKnow.Filters.Filter, filtermode As %Integer, positionstomatch As %Integer) As %Status [ Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.GetCrcsIntSort,^||%IK.GetCrcsIntTrack,^||%IK.GetCrcsIntFSort",tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	quit:'entitylist
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// if filtering frequencies, calculate the CRC Occ Filters, which is quite a heavy
	// calculation but should only be executed once for the whole filter, which we hope is
	// quite selective. The alternative is to go from each retrieved crc to all of its 
	// occurrences, which is also quite hefty and probably worse when looking at the most 
	// frequent entries.
	
	// define which sorted global to use
	set sorttype = $$$SORTFIELD(domainid)
	
	set tGlobs = $lb($s(sorttype=$$$SORTBYFREQUENCY:$$$IKBCRCENTFREQ, 1:$$$IKBCRCENTSPREAD))
	set:'$isobject(filter)||'$$$CHECKFILTERFREQ(filter,filtermode)||'$$$CHECKFILTERSPREAD(filter,filtermode) tGlobs = tGlobs _ $lb($$$IKBCRCUNIDET)
	set:$$$CHECKFILTERSPREAD(filter,filtermode) tGlobs = tGlobs_$lb($$$IKBCRCUNISRC)
	$$$IKQBCHECKX(domainid,tGlobs,tSC)
	
	// find the highest sort order for each entity to start the algorithm
	set entId = ""
	set i = 0
	for {
		set entId = $order(entitylist(entId))
		quit:entId=""
		
		set i = i+1
		set sortOrder = $select(sorttype=$$$SORTBYFREQUENCY:$order(^IRIS.IK.CrcEntUniFreq(domainid, entId, "")), sorttype=$$$SORTBYSPREAD:$order(^IRIS.IK.CrcEntUniSpread(domainid, entId, "")))
		continue:'+sortOrder
		set ^||%IK.GetCrcsIntSort(sortOrder, entId) = ""
	}
	
	
	// now add CRCs for the highest scoring entity and update ^||%IK.GetCrcsInternal each time
	set entriesWithinPage = 0
	for {
		
		set maxSortOrder = $order(^||%IK.GetCrcsIntSort(""))
		quit:maxSortOrder=""
			
		// when the value for maxSortOrder changes, we have to verify how many entries
		// are certainly within the desired page boundary
		if (usePaging && $$$CHECKFILTERSORT(filter,filtermode)) {
			set entriesWithinPage = 0
			set sortCheck = ""
			for {
				set sortCheck = $order(^||%IK.GetCrcsIntFSort(sortCheck))
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
		
		set maxSortOrderEntId = $order(^||%IK.GetCrcsIntSort(maxSortOrder, ""))
		
		set crcId = ""
		for {
			if (sorttype=$$$SORTBYFREQUENCY) {
				set crcId = $order(^IRIS.IK.CrcEntUniFreq(domainid, maxSortOrderEntId, maxSortOrder, crcId), 1, position)
			} elseif (sorttype=$$$SORTBYSPREAD) {
				set crcId = $order(^IRIS.IK.CrcEntUniSpread(domainid, maxSortOrderEntId, maxSortOrder, crcId), 1, position)
			}
			quit:crcId=""
			
			// check if the position matches
			If '($$$CHECKPOSM(positionstomatch) && $$$CHECKPOSM(position)),
			   '($$$CHECKPOSR(positionstomatch) && $$$CHECKPOSR(position)),
			   '($$$CHECKPOSS(positionstomatch) && $$$CHECKPOSS(position)) {
			    Continue
			}
			
			// check if we've already returned this CRC
			Continue:$data(^||%IK.GetCrcsIntTrack(crcId))
			Set count = count + 1
			Set ^||%IK.GetCrcsIntTrack(crcId) = crcId
					
			// check if the CRC satisfies the filter
			set filteredSpread = 0
			set filteredFreq = 0
			set filterInclude = 0
			if ($isobject(filter)) {
				
				if ($$$CHECKFILTERONLY(filtermode) || $$$CHECKFILTERSPREAD(filter,filtermode)) {
					// loop through ^IRIS.IK.CrcUniToSrcBit until a document is found (if not filtering 
					// spread) this should be quite fast when retrieving a limited number of
					// CRCs.
					set srcOffset = ""
					for {
						set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
						quit:srcOffset=""
						
						// merge filter and ^IRIS.IK.CrcUniToSrcBit
						set srcBits = $bitlogic(srcBits & ^IRIS.IK.CrcUniToSrcBit(domainid, crcId, srcOffset))
								
						if ($$$CHECKFILTERONLY(filtermode)) {
							set firstOne = $bitfind(srcBits, 1)
							if (firstOne > 0) {
								set filterInclude = 1
								quit
							}
						}
						if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
							set filteredSpread = filteredSpread + $bitcount(srcBits,1)
						}
					}
				}
					
				if ($$$CHECKFILTERFREQ(filter,filtermode)) {
					
					// now recalculate frequency through CRC Occurrences
					set filteredFreq = 0
					
					// use CRC Occ filter bitstrings 
					set filterOccOffset = ""
					for {
						set filterOccOffset = filter.GetNextCRCOccurrenceFilterOffset(filterOccOffset, .filterOccBits)
						quit:filterOccOffset=""
						
						set filteredFreq = filteredFreq + $bitcount($bitlogic(filterOccBits & ^IRIS.IK.CrcUniToOccBit(domainid, crcId, filterOccOffset)), 1)
					}
				}
				
				// if the filter is not satisfied, decrease the count, which should be faster
				// then doing this filtering BEFORE the setop treatment
				if (filterInclude + filteredFreq + filteredSpread = 0) {
					set count = count - 1
					continue
				}
			}
			
			// check if we're in the paging window
			$$$IKCHECKPAGINGSORT(usePaging,first,last,count,filter,filtermode,entriesWithinPage)
			
			// add the CRC to the result set
			set crc = ^IRIS.IK.CrcUniId(domainid, crcId)
			set m = $list(crc, 1)
			set r = $list(crc, 2)
			set s = $list(crc, 3)
			set crcDetails = ^IRIS.IK.CrcUniDetails(domainid, crcId)
			if ($$$CHECKFILTERFREQ(filter,filtermode)) {
				set $list(crcDetails, 1) = filteredFreq
			}
			if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
				set $list(crcDetails, 2) = filteredSpread
			}
			set crcRecord = $lb(crcId,
								$s(m:^IRIS.IK.EntUniId(domainid, m), 1:""), // head
								$s(r:^IRIS.IK.EntUniId(domainid, r), 1:""), // relation
								$s(s:^IRIS.IK.EntUniId(domainid, s), 1:""), // tail
								$list(crcDetails, 1),				// frequency
								$list(crcDetails, 2)				// spread
								)
					
			// store the retrieved record, depending on whether re-sort is required			
			if ($$$CHECKFILTERSORT(filter,filtermode)) {
				
				// update entriesWithinPage if the current entry is certainly within
				// the end result page, which is the case if the filtered sort order
				// is already smaller then the best possible unfiltered sort order
				// we're looking at
				if (usePaging) {
					
					// derive sort attribute
					if (sorttype=$$$SORTBYFREQUENCY) {
						set sortOrder = -$list(crcRecord, 5)
					} elseif (sorttype = $$$SORTBYSPREAD) {
						set sortOrder = -$list(crcRecord, 6)
					}
					if (sortOrder < maxSortOrder) {
						set entriesWithinPage = entriesWithinPage + 1
					}
				}
					
				set ^||%IK.GetCrcsIntFSort(sortOrder, $i(^||%IK.GetCrcsIntFSort)) = crcRecord
			
			} else {
				
				$$$IKQADDRESULT(result,count,crcRecord)
				
			}
		}
		
		// after adding CRCs for this ent/order combination, remove the sortOrder 
		// entry just added and add the next one for this entId
		kill ^||%IK.GetCrcsIntSort(maxSortOrder, maxSortOrderEntId)
		
		if (sorttype=$$$SORTBYFREQUENCY) {
			set maxSortOrder = $order(^IRIS.IK.CrcEntUniFreq(domainid, maxSortOrderEntId, maxSortOrder))
		} elseif (sorttype=$$$SORTBYSPREAD) {
			set maxSortOrder = $order(^IRIS.IK.CrcEntUniSpread(domainid, maxSortOrderEntId, maxSortOrder))
		}
		
		if (+maxSortOrder) {
			set ^||%IK.GetCrcsIntSort(maxSortOrder, maxSortOrderEntId) = ""
		}
	}
	
	// if applicable, resort the results
	$$$IKQRESORTRESULT(filter,filtermode,result,"^||%IK.GetCrcsIntFSort",usePaging,first,last,tSC)
	
	$$$IKQENDCATCH(result,"^||%IK.GetCrcsIntSort,^||%IK.GetCrcsIntTrack,^||%IK.GetCrcsIntFSort",tSC)
}

Parameter GetTopRT = "crcId:%Integer,head:%String,relation:%String,tail:%String,freq:%Integer,spread:%Integer";

///  <p>Returns the most frequently occurring CRCs for this domain, sorted by descending frequency
///  (with <var>sorttype</var> $$$SORTBYFREQUENCY), spread (with <var>sorttype</var> $$$SORTBYSPREAD) or the
///  domain default (with <var>sorttype</var> $$$SORTBYDOMAINDEFAULT).</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>If a Virtual Source ID is provided, only the entities in that virtual source will be considered,
///  filters are ignored and the sort type will always be $$$SORTBYFREQUENCY.</p>
ClassMethod GetTop(ByRef result, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, vSrcId As %Integer = 0) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.GetTopCrcsFSort,^||%IK.CrcUniSort",tSC)
	if vSrcId && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	$$$IKCHECKSORTTYPEX(domainid,sorttype,$lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),tSC)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// filtering options:
	// 	- crcUniFreq: loop through domain-wide CrcUniFreq global and check each entry against the filter
	//  - localCrcUniFreq: build a new CrcUniFreq for the filtered sources using the domain-wide freqs and loop through
	//  - flattenFirst: go through all CRCOs satisfying the filter and recalc freq/spread on the fly
	if $isobject(filter) {
		if (filter.Selectivity && usePaging) {
			// basic global reads from @crcUniFreq
			$$$IKCADD("crcUniFreq",page*pagesize*(1/filter.Selectivity)*$$$IKCSEQ("CrcUniFreq"))
			$$$IKCADD("localCrcUniFreq", page*pagesize)
			
			// localCrcUniFreq build
			$$$IKCADD("localCrcUniFreq", filter.FilteredSourceCount*..GetMaxOffset(domainid,$$$IKFCRCUNI)*$$$IKCSEQ("SrcToCrcUniBit"))
			
			// recalculation
			set crcsToRecalc = $s($$$CHECKFILTERSORT(filter,filtermode):page*pagesize, 1:pagesize)
			if $$$CHECKFILTERFREQ(filter,filtermode) { 
				$$$IKCADD("crcUniFreq", crcsToRecalc*$$$IKCFILTERFREQ(filtermode))
				$$$IKCADD("localCrcUniFreq", crcsToRecalc*$$$IKCFILTERFREQ(filtermode))
			}
			if $$$CHECKFILTERSPREAD(filter,filtermode) { 
				$$$IKCADD("crcUniFreq", crcsToRecalc*$$$IKCFILTERSPREAD(filtermode))
				$$$IKCADD("localCrcUniFreq", crcsToRecalc*$$$IKCFILTERSPREAD(filtermode)) 
			}
		}
		
		$$$IKCADD("flattenFirst", filter.FilteredSourceCount*$$$IKCSEQ("SrcDetails"))
		$$$IKCADD("flattenFirst", ..GetMaxId(domainid,$$$IKFCRCOCC)*filter.Selectivity*$$$IKCSEQ("EntOccId"))
	} else {
		$$$IKCADD("crcUniFreq",0)
	} 
	$$$IKCLOWEST(tLowestCostPath)
	
	if 'vSrcId {
		set tGlobs = $case(tLowestCostPath, "localCrcUniFreq":$lb($$$IKBCRCUNIDET), "crcUniFreq":$lb($s(sorttype=$$$SORTBYFREQUENCY:$$$IKBCRCUNIFREQ, 1:$$$IKBCRCUNISPREAD)), :"")
		set:'$isobject(filter)||'$$$CHECKFILTERFREQ(filter,filtermode)||'$$$CHECKFILTERSPREAD(filter,filtermode) tGlobs = tGlobs _ $lb($$$IKBCRCUNIDET)
		$$$IKQBCHECKX(domainid,tGlobs,tSC)
	}
	
	set crcUniDetailsGlo = $$$IKVGLOBNAME(domainid,"CrcUniDetails",vSrcId)
	
	if (tLowestCostPath = "flattenFirst") {
		
		// "flatten" first by gathering ALL entities for this filter
		if ($$$CHECKFILTERSORT(filter,filtermode)) {
			set tSC = ..GetByFilterInternal("^||%IK.GetTopCrcsFSort", domainid, filter, filtermode, sorttype)
		} else {
			set tSC = ..GetByFilterInternal(.result, domainid, filter, filtermode, -1)
		}
		
	} else {
		
		// for highly selective filters, build a shortlist of CRCs to look at
		if (tLowestCostPath="localCrcUniFreq") {
			$$$IKSORTBEGIN(^||%IK.CrcUniSort)
		
			// start building a shortlist by looping through the EUs satisfying the filter
			set offset = ""
			for {
				set offset = filter.GetNextCRCUniqueFilterOffset(offset, .crcUniBits)
				quit:offset=""
			
				set pos = 0
				for {
					set pos = $bitfind(crcUniBits, 1, pos+1)
					quit:'pos
				
					$$$IKGETIDOFFPOS(crcUniId,offset,pos)
				
					set details = @crcUniDetailsGlo@(crcUniId)
					set sortVal = $lg(@crcUniDetailsGlo@(crcUniId), $s(sorttype=$$$SORTBYFREQUENCY:1, 1:2))
					continue:'sortVal
				
					set ^||%IK.CrcUniSort(-sortVal, crcUniId) = ""
				}
			}
		
			set tSCx = $sortend(^||%IK.CrcUniSort)
			set crcUniSortGlo = "^||%IK.CrcUniSort"
		
		} else {
		
			// derive proper sorting global
			if (vSrcId) {
				$$$CHECKVSRCIDEXISTSX(domainid,vSrcId,tSC)
				set crcUniSortGlo = "^IRIS.IKV.CrcUniIdFreq("_domainid_","_vSrcId_")"
				set filter="", filtermode = 0, sorttype = $$$SORTBYFREQUENCY
			} else {
				if '$lf($lb($$$SORTBYFREQUENCY,$$$SORTBYSPREAD),sorttype) { set tSC = $$$ERROR($$$InvalidArgument, "sorttype")  quit }
				set crcUniSortGlo = "^IRIS.IK.CrcUniId"_$s(sorttype=$$$SORTBYFREQUENCY:"Freq", 1:"Spread")_"("_domainid_")"
			}
		}
			
		// for post-filter resorting, we have to track how many entries
		// are certainly inside the desired page
		set entriesWithinPage = 0
	
		// loop through the appropriate top sorted global
		set sortOrder = ""
		for {
			set sortOrder = $order(@crcUniSortGlo@(sortOrder))
			quit:sortOrder=""
		
				
			// when the value for sortOrder changes, we have to verify how many entries
			// are certainly within the desired page boundary
			if (usePaging && $$$CHECKFILTERSORT(filter,filtermode)) {
				set entriesWithinPage = 0
				set sortCheck = ""
				for {
					set sortCheck = $order(^||%IK.GetTopCrcsFSort(sortCheck))
					quit:sortCheck=""
				
					// TODO: theoretically, we'll have to dig one level deeper to get
					// 			exact results, as, there is a second level to the index
					//			as to deduplicate entries with the same sortOrder, but
					//			this will underestimate the actual entriesWithinPage and 
					//			therefor is not wrong, but just lazy
					// sort order is negative, so sortCheck < sortOrder means this entry
					// in the current result list is certainly in the final results as
					// sortOrder can only increase
					if (sortCheck < sortOrder) {
						set entriesWithinPage = entriesWithinPage + 1
					} else {
						quit
					}
				}
				if (entriesWithinPage > last) {
					quit
				}
			}
		
			// loop through the CRCs at this sortOrder
			set crcId = ""
			for {
				set crcId = $order(@crcUniSortGlo@(sortOrder, crcId))
				quit:crcId=""
			
				// check if the CRC satisfies the filter and recalc freq/spread if required
				set filteredSpread = 0
				set filteredFreq = 0
				if ($isobject(filter)) {
					
					if $$$CHECKFILTERFREQ(filter,filtermode) {
						//$$$IKQTIC("FilterFreq")
						set filteredFreq = filter.GetFilteredCrcFrequency(crcId)
						//$$$IKQTOC("FilterFreq")
						continue:'filteredFreq
					}
					if $$$CHECKFILTERSPREAD(filter,filtermode) {
						//$$$IKQTIC("FilterSpread")
						set filteredSpread = filter.GetFilteredCrcSpread(crcId)
						//$$$IKQTOC("FilterSpread")
						continue:'filteredSpread
					}
					if $$$CHECKFILTERONLY(filtermode) {
						continue:'filter.IsFiltered(crcId, $$$IKFCRCUNI)
					}
				}
			
				// this is a valid entry, so increase count
				set count = count + 1
			
				// check if we're in the paging window
				$$$IKCHECKPAGINGSORT(usePaging,first,last,count,filter,filtermode,entriesWithinPage)
						
				// retrieve and "correct" frequency info
				if (vSrcId) {
					set freq = $li(@crcUniDetailsGlo@(crcId),1)
					set spread = 1
				} else {
					set details = ""
					if ($$$CHECKFILTERFREQ(filter,filtermode)) {
						set freq = filteredFreq
					} else {
						set details = @crcUniDetailsGlo@(crcId)
						set freq = $list(details, 1)
					}
					if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
						set spread = filteredSpread
					} else {
						set:details="" details = @crcUniDetailsGlo@(crcId)
						set spread = $list(details, 2)
					}
				}
			
				// build the topCrc data 
				set crcParts = ..GetValueInternal(domainid, crcId, vSrcId)
				set topCrc =  $lb(+crcId) _ crcParts _ $lb(freq, spread)
									
				// store the topCrc in the appropriate global
				if ($$$CHECKFILTERSORT(filter,filtermode)) {
					
					// derive sort attribute
					if (sorttype=$$$SORTBYFREQUENCY) {
						set topSortOrder = -freq
					} elseif (sorttype = $$$SORTBYSPREAD) {
						set topSortOrder = -spread
					}
				
					// update entriesWithinPage if the current entry is certainly within
					// the end result page, which is the case if the filtered sort order
					// is already smaller then the best possible unfiltered sort order
					// we're looking at
					if (usePaging) {
						if (topSortOrder < sortOrder) {
							set entriesWithinPage = entriesWithinPage + 1
						}
					}
			
					// store topCrc in utility global
					set ^||%IK.GetTopCrcsFSort(topSortOrder, $i(^||%IK.GetTopCrcsFSort)) = topCrc
				
					$$$IKCHECKPAGING(usePaging,0,last,entriesWithinPage)
				
				} else {
				
					$$$IKQADDRESULT(result,count,topCrc)
				}
												
			}
			$$$IKCHECKPAGINGSORT(usePaging,0,last,count,filter,filtermode,entriesWithinPage)
		}
	}
	
	// if applicable, resort the results
	$$$IKQRESORTRESULT(filter,filtermode,result,"^||%IK.GetTopCrcsFSort",usePaging,first,last,tSC)
	
	$$$IKQENDCATCH(result,"^||%IK.GetTopCrcsFSort,^||%IK.CrcUniSort",tSC)
}

Parameter GetByFilterRT = "crcId:%Integer,head:%String,relation:%String,tail:%String,frequency:%Integer,spread:%Integer";

///  <p>Returns all CRCs appearing in any source satisfying the supplied <var>filter</var> 
///  objects criteria, with their frequencies and spread recalculated to comply with the filter
///  depending on the value of <var>filtermode</var>, but the result is NOT re-sorted, regardless
///  of the value for <var>filtermode</var> (use <method>GetTop</method> if you want sorted results).</p>
ClassMethod GetByFilter(ByRef result, domainid As %Integer, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKQFILTEROBJECTX(domainid,filter,tSC)
	
	set tSC = ..GetByFilterInternal(.result, domainid, filter, filtermode, -1)
	
	$$$IKQENDCATCH(result,"",tSC)
}

///  sortIndex = -1 means regular output, otherwise an additional first subscript will be introduced
///  to sort by frequency ($$$SORTBYFREQUENCY) or spread ($$$SORTBYSPREAD): result(-sort, entUniId)
///  WARNING: for internal use only, no input checking is performed!
ClassMethod GetByFilterInternal(ByRef result, domainid As %Integer, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, sortIndex As %Integer = -1) As %Status [ Internal ]
{
	$$$IKQCLEARPPGS("^||%IK.Crcs,^||%IK.CrcsSpread")
	quit:'$isobject(filter) $$$OK
	quit:$$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) ..GetByFilterInternal20121(.result, domainid, filter, filtermode, sortIndex)
	
	set tSC = $$$OK
	if ('$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode)) {
		$$$IKQBCHECKR(domainid,$$$IKBCRCUNIDET,tSC,tSC)
	}
	
	set srcOffset = ""
	for {
		set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
		quit:srcOffset=""
		
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits,1,srcPos+1)
			quit:srcPos=0
			
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			
			set crcUniId = ""
			for {
				set crcUniId = $order(^IRIS.IK.CrcSrcDetails(domainid, srcId, crcUniId),1,details)
				quit:crcUniId=""
			
				set:$$$CHECKFILTERONLY(filtermode) ^||%IK.Crcs(crcUniId) = ""
				set:$$$CHECKFILTERFREQ(filter,filtermode) x = $i(^||%IK.Crcs(crcUniId), $lg(details,1))
				set:$$$CHECKFILTERSPREAD(filter,filtermode) x = $i(^||%IK.CrcsSpread(crcUniId))
			}
		}
	}
		
	set crcUniId = "", i=0, globName = $s($$$CHECKFILTERFREQ(filter,filtermode)||$$$CHECKFILTERONLY(filtermode):"^||%IK.Crcs", 1:"^||%IK.CrcsSpread")
	for {
		set crcUniId = $order(@globName@(crcUniId),1,freq)
		quit:crcUniId=""
		
		if ('$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode)) {
			set details = ^IRIS.IK.CrcUniDetails(domainid, crcUniId)
		}
		
		if ($$$CHECKFILTERFREQ(filter,filtermode)) {
			do filter.SaveFilteredFrequency($$$IKFCRCUNI, crcUniId, freq)
		} else {
			set freq = $li(details,1)
		}
		if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
			set spread = ^||%IK.CrcsSpread(crcUniId)
			do filter.SaveFilteredSpread($$$IKFCRCUNI, crcUniId, spread)
		} else {
			set spread = $li(details,2)
		}
		
		set data = $lb(+crcUniId) _ ..GetValueInternal(domainid,crcUniId) _ $lb(freq,spread)
		if (sortIndex<0) {
			$$$IKQADDRESULT(result,$i(i),data)
		} else {
			set sort = $case(sortIndex, $$$SORTBYFREQUENCY:freq, $$$SORTBYSPREAD:spread)
			if ($g(result)="") {
				set result(-sort, crcUniId) = data
			} else {
				set @result@(-sort, crcUniId) = data
			}
		}
	}
	
	$$$IKQCLEARPPGS("^||%IK.Ents,^||%IK.EntsSpread")
	quit $$$OK
}

ClassMethod GetByFilterInternal20121(ByRef result, domainid As %Integer, filter As %iKnow.Filters.Filter = "", filtermode As %Integer = {$$$FILTERONLY}, sortIndex As %Integer = -1) As %Status [ Internal ]
{
	$$$IKQCLEARPPGS("^||%IK.Crcs,^||%IK.CrcRanges,^||%IK.CrcsForSrc,^||%IK.CrcsSpread")
	
	$$$IKSORTBEGIN(^||%IK.CrcRanges)
	set srcOffset = ""
	for {
		set srcOffset = filter.GetNextSourceFilterOffset(srcOffset, .srcBits)
		quit:srcOffset=""
		
		set srcPos = 0
		for {
			set srcPos = $bitfind(srcBits,1,srcPos+1)
			quit:srcPos=0
			
			$$$IKGETIDOFFPOS(srcId,srcOffset,srcPos)
			set srcDetails = $g(^IRIS.IK.SrcDetails(domainid,srcId))
			continue:srcDetails=""
			
			set crcoBase = $li(srcDetails,5)
			set crcoCount = $li(srcDetails,6)
			set crcoFrom = crcoBase+1, crcoTo = crcoBase+crcoCount
			set ^||%IK.CrcRanges(crcoFrom) = crcoTo
		}
	}
	set x = $sortend(^||%IK.CrcRanges)
	
	set crcoFrom = ""
	for {
		set crcoFrom = $order(^||%IK.CrcRanges(crcoFrom), 1, crcoTo)
		quit:crcoFrom=""
		
		kill ^||%IK.CrcsForSrc
		for crcOccId = crcoFrom:1:crcoTo {
			set crco = ^IRIS.IK.CrcOccId(domainid,crcOccId)
			set crcUniId = $li(crco,1)
			
			set:$$$CHECKFILTERONLY(filtermode) ^||%IK.Crcs(crcUniId) = ""
			set:$$$CHECKFILTERFREQ(filter,filtermode) x = $i(^||%IK.Crcs(crcUniId))
			set:$$$CHECKFILTERSPREAD(filter,filtermode) x = $i(^||%IK.CrcsForSrc(crcUniId))
		}
		
		if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
			set crcUniId = ""
			for {
				set crcUniId = $order(^||%IK.CrcsForSrc(crcUniId))
				quit:crcUniId=""
			
				set x = $i(^||%IK.CrcsSpread(crcUniId))
			}
		}
	}
		
	set crcUniId = "", i=0, globName = $s($$$CHECKFILTERFREQ(filter,filtermode)||$$$CHECKFILTERONLY(filtermode):"^||%IK.Crcs", 1:"^||%IK.CrcsSpread")
	for {
		set crcUniId = $order(@globName@(crcUniId),1,freq)
		quit:crcUniId=""
		
		if ('$$$CHECKFILTERFREQ(filter,filtermode) || '$$$CHECKFILTERSPREAD(filter,filtermode)) {
			set details = ^IRIS.IK.CrcUniDetails(domainid, crcUniId)
		}
		
		if ($$$CHECKFILTERFREQ(filter,filtermode)) {
			do filter.SaveFilteredFrequency($$$IKFCRCUNI, crcUniId, freq)
		} else {
			set freq = $li(details,1)
		}
		if ($$$CHECKFILTERSPREAD(filter,filtermode)) {
			set spread = ^||%IK.CrcsSpread(crcUniId)
			do filter.SaveFilteredSpread($$$IKFCRCUNI, crcUniId, spread)
		} else {
			set spread = $li(details,2)
		}
		
		set data = $lb(+crcUniId) _ ..GetValueInternal(domainid,crcUniId) _ $lb(freq,spread)
		if (sortIndex<0) {
			$$$IKQADDRESULT(result,$i(i),data)
		} else {
			set sort = $case(sortIndex, $$$SORTBYFREQUENCY:freq, $$$SORTBYSPREAD:spread)
			if ($g(result)="") {
				set result(-sort, crcUniId) = data
			} else {
				set @result@(-sort, crcUniId) = data
			}
		}
	}
	
	$$$IKQCLEARPPGS("^||%IK.Crcs,^||%IK.CrcRanges,^||%IK.CrcsForSrc,^||%IK.CrcsSpread")
	quit $$$OK
}

Parameter GetBySourceRT = "crcId:%Integer,head:%String,relation:%String,tail:%String,frequency:%Integer,spread:%Integer";

///  <p>Returns the unique CRCs appearring in the specified sources.</p>
///  <p>To get the unique CRCs of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetBySource(ByRef result, domainid As %Integer, sourceidlist As %List, page As %Integer = 1, pagesize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(result,"^||%IK.GetCrcsForSrcBits,^||%IK.CrcFreq,^||%IK.CrcSpread",tSC)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	quit:sourceidlist=""
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	// check if looking for a virtual source
	if ($li(sourceidlist,1)<0) && ($ll(sourceidlist)=1) {
		set vSrcId = -$li(sourceidlist,1)
		$$$CHECKVSRCIDEXISTSX(domainid,vSrcId,tSC)
		
		set crcUniId = ""
		for {
			set crcUniId = $order(^IRIS.IKV.CrcUniDetails(domainid, vSrcId, crcUniId), 1, details)
			quit:crcUniId=""
			
			set count=$i(count)
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			$$$IKQADDRESULT(result,count,$lb(+crcUniId) _ ..GetValueInternal(domainid,crcUniId,vSrcId) _ $lb($li(details,1), 1))
		}
		
		quit
	}
	
	set ptr=0, srcId=0
	while $listnext(sourceidlist,ptr,srcId) {
		continue:'+srcId
		quit:srcId<0
		
		if $$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) {
			set crcOffset = ""
			for { 
				set crcOffset = $order(^IRIS.IK.SrcToCrcUniBit(domainid, srcId, crcOffset), 1, crcBits)
				quit:crcOffset=""
			
				set ^||%IK.GetCrcsForSrcBits(crcOffset) = $bitlogic(crcBits | ^||%IK.GetCrcsForSrcBits(crcOffset))
			}
		} else {
			set crcUniId = ""
			for {
				set crcUniId = $order(^IRIS.IK.CrcSrcDetails(domainid,srcId,crcUniId),1,details)
				quit:crcUniId=""
				set x = $i(^||%IK.CrcFreq(crcUniId),$li(details,1))
				set x = $i(^||%IK.CrcSpread(crcUniId))
			}
		}
	}
	
	// if we ran into a negative srcId, return error
	if (srcId<0) { set tSC = $$$ERROR($$$IKOnlyOneVSrcSupported)  quit }
	
	if $$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) {
		set crcOffset = ""
		for {
			set crcOffset = $order(^||%IK.GetCrcsForSrcBits(crcOffset), 1, crcBits)
			quit:crcOffset=""
		
			set crcPos = 0
			for {
				set crcPos = $bitfind(crcBits, 1, crcPos + 1)
				quit:crcPos=0
			
				// check if we're ok with the page
				set count = count + 1
				$$$IKCHECKPAGING(usePaging,first,last,count)
			
				$$$IKGETIDOFFPOS(crcId,crcOffset,crcPos)
			
				set crc = ..GetValueInternal(domainid, crcId)
			
				set crcFreq = 0
				set crcSpread = 0
			
				// recalculate frequency by going through the occurrences
				for i = 1:1:$listlength(sourceidlist) {
				
					set srcId = $list(sourceidlist, i)
					set crcInSrc = 0
				
					set srcDetails = ^IRIS.IK.SrcDetails(domainid, srcId)
					set crcOccFrom = $li(srcDetails,5)+1
					set crcOccTo = crcOccFrom + $li(srcDetails,6)-1
				
					$$$IKBITOFFPOS(crcOccFrom,crcOccFromO,crcOccFromP)
					$$$IKBITOFFPOS(crcOccTo,crcOccToO,crcOccToP)
				
					set crcOccO = crcOccFromO-1
					for {
						set crcOccO = $order(^IRIS.IK.CrcUniToOccBit(domainid, crcId, crcOccO), 1, occBits)
						quit:crcOccO=""
						quit:crcOccO>crcOccToO
					
						if (crcOccO = crcOccFromO) {
							for j = 1:1:crcOccFromP-1 {
								set $bit(occBits,j) = 0
							}
						}
						if (crcOccO = crcOccToO) {
							set end = $bitcount(occBits)
							for j = crcOccToP+1:1:end {
								set $bit(occBits,j) = 0
							}
						}
					
						if ($bitfind(occBits, 1) > 0) {
							set crcInSrc = 1
						}
					
						set crcFreq = crcFreq + $bitcount(occBits, 1)
					}
				
					set crcSpread = crcSpread + crcInSrc
				}
			
				// now compile result entry and add to result list
				set crcEntry = $lb(crcId, $list(crc, 1), $list(crc, 2), $list(crc, 3), crcFreq, crcSpread)
				$$$IKQADDRESULT(result,count,crcEntry)
			}
		}
		
	} else {
		
		set crcUniId = ""
		for {
			set crcUniId = $order(^||%IK.CrcFreq(crcUniId),1,freq)
			quit:crcUniId=""
			
			set x = $i(count)
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			set crcEntry = $lb(+crcUniId)_..GetValueInternal(domainid,crcUniId)_$lb(freq,^||%IK.CrcSpread(crcUniId))
			$$$IKQADDRESULT(result,count,crcEntry)
		}
	}
	
	$$$IKQENDCATCH(result,"^||%IK.GetCrcsForSrcBits,^||%IK.CrcFreq,^||%IK.CrcSpread",tSC)
}

///  <p>Returns the total number of unique CRCs in a domain, optionally limited through supplying a
///  <class>%iKnow.Filters.Filter</class> object as the <var>filter</var> parameter to restrict the result to
///  those CRCs occurring in any source satisfying the filter criteria.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %iKnow.Filters.Filter = "", Output sc As %Status = {$$$OK}, includeZeroFrequency As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	set total = 0
	
	if ($isobject(filter)) {
		
		quit filter.GetFilteredCrcUniqueCount()
		
	} elseif (includeZeroFrequency) {
		
		set crcId = ""
		for {
			set crcId = $order(^IRIS.IK.CrcUniId(domainid, crcId))
			quit:crcId=""
			
			set x = $i(total)
		}
		
	} elseif $$$IKVERSIONBEFORE(domainid,$$$IKVERSION20122) {
		
		set crcId = ""
		for {
			set crcId = $order(^IRIS.IK.CrcUniDetails(domainid, crcId),1,details)
			quit:crcId=""
			
			// exclude zero-frequency
			set:($li(details,1)) x = $i(total)
		}
		
	} else {
		
		set crcOff = ""
		for {
			set crcOff = $order(^IRIS.IK.CrcUniExistsBit(domainid, crcOff), 1, crcBits)
			quit:crcOff=""
			
			set x = $i(total, $bitcount(crcBits,1))
		}
	}
	
	$$$IKQEND("",total)
}

///  <p>Returns the total number of unique CRCs appearing in either (if <var>setop</var> = $$$UNION) or
///  all (if <var>setop</var> = $$$INTERSECT) of the sources specified by ID in <var>sourceidlist</var>.</p>
///  <p>To get the unique CRCs of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %List, setop As %Integer = {$$$UNION}, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("^||%IK.GetTotCrcsBit",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	// simple implementation if we're looking at a virtual source
	if ($li(sourceidlist,1)<0) && ($ll(sourceidlist)=1) {
		set vSrcId = -$li(sourceidlist,1)
		$$$CHECKVSRCIDEXISTSR(domainid,vSrcId,sc,-1)
		quit $o(^IRIS.IKV.CrcUniId(domainid, vSrcId, ""),-1)
	}
	
	$$$IKQBCHECKX(domainid,$lb($$$IKBSRCCRCUNI),sc)
	
	// join ^IRIS.IK.SrcToCrcUniBit entries for the sources in the list
	for i = 1:1:$listlength(sourceidlist) {
		
		set srcId = $list(sourceidlist, i)
		continue:'+srcId
		quit:srcId<0
		
		set crcOffset = ""
		for  {
			set crcOffset = $order(^IRIS.IK.SrcToCrcUniBit(domainid, srcId, crcOffset), 1, crcBits)
			quit:crcOffset=""
			
			// merge with ^||%IK.GetTotCrcsBit contents
			if (i = 1) {
				set ^||%IK.GetTotCrcsBit(crcOffset) = crcBits
			} else {
				if (setop = $$$UNION) {
					set ^||%IK.GetTotCrcsBit(crcOffset) = $bitlogic(crcBits | ^||%IK.GetTotCrcsBit(crcOffset))
				} elseif (setop = $$$INTERSECT) {
					set ^||%IK.GetTotCrcsBit(crcOffset) = $bitlogic(crcBits & ^||%IK.GetTotCrcsBit(crcOffset))
				}
			}
		}
	}
	
	// if we ran into a negative srcId, return error
	if (srcId<0) {
		set sc = $$$ERROR($$$IKOnlyOneVSrcSupported)
		quit -1
	}
	
	// now count the remaining 1s
	set total = 0
	set crcOffset = ""
	for {
		set crcOffset = $order(^||%IK.GetTotCrcsBit(crcOffset), 1, crcBits)
		quit:crcOffset=""
		
		set total = total + $bitcount(crcBits, 1)
	}
	
	$$$IKQEND("^||%IK.GetTotCrcsBit",total)
}

///  <p>Returns the total number of CRC occurrences in the specified sources.</p>
///  <p>Use negative source IDs to refer to virtual sources</p>
ClassMethod GetOccurrenceCountBySource(domainid As %Integer, sourceidlist As %List, Output sc As %Status = {$$$OK}) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	if (domainid'=0) { $$$CHECKDOMAINEXISTSR(domainid,sc,-1) }
	quit:sourceidlist="" 0
	
	// accepting single source IDs (non-list) as well
	$$$IKENSURELISTNUM(sourceidlist)
	
	set total = 0, ptr = 0
	while $listnext(sourceidlist, ptr, srcId) {
		continue:'+srcId
		$$$CHECKASRCIDEXISTSX(domainid,srcId,srcDetails,vSrcId,sc)
		set total = total + $lg(srcDetails,6)
	}
	quit:$$$ISERR(sc) -1
	
	quit total
}

Parameter GetOccurrencesBySourceRT = "crcOccId:%Integer,crcUniId:%Integer,head:%String,relation:%String,tail:%String,sentenceId:%Integer,posInSent:%Integer";

///  <p>Returns the CRC occurrences for a given source, in the order in which they appear.</p>
ClassMethod GetOccurrencesBySource(ByRef result, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(result,"",tSC)
	if (srcid<0) && (domainid=0) {} else { $$$CHECKDOMAINEXISTSX(domainid,tSC) }
	$$$CHECKASRCIDEXISTSX(domainid,srcid,srcDetails,vSrcId,tSC)
	
	set crcOccGlo = $$$IKVGLOBNAME(domainid,"CrcOccId",vSrcId)
	
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	set crcOccId = +$lg(srcDetails,5)
	for {
		set crcOccId = $order(@crcOccGlo@(crcOccId),1,occData)
		quit:crcOccId=""
		
		set count = count+1
		$$$IKCHECKPAGING(usePaging,first,last,count)
		quit:count>+$lg(srcDetails,6)
		
		set crcUniId = $li(occData,1)
		$$$IKQADDRESULT(result,count,$lb(+crcOccId, crcUniId) _ ..GetValueInternal(domainid, crcUniId, vSrcId) _ $li(occData,5,6))
	}
	$$$IKQENDCATCH(result,"",tSC)
}

///  <p>Returns the number of CRCs in this domain, based on a list of entities.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %List, filter As %iKnow.Filters.Filter = "", positionstomatch As %Integer = {$$$USEPOSALL}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entitylist="" 0
	
	// accept single values and translate to a 1-member list
	$$$IKENSURELISTSTR(entitylist)

	// translate & clean entity list
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid, entitylist, .cleanEntIdList,,, tIncludeActuals)
	quit:$$$ISERR(sc) -1
	
	quit ..GetCountByEntitiesInternal(domainid, .cleanEntIdList, filter, positionstomatch, .sc)
}

///  <p>Returns the number of CRCs in this domain, based on a list of entity IDs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %List, filter As %iKnow.Filters.Filter = "", positionstomatch As %Integer = {$$$USEPOSALL}, Output sc As %Status = {$$$OK}, pActualFormOnly As %Boolean = 0) As %Integer
{
	$$$IKQBEGINR("",sc,-1)
	$$$CHECKDOMAINEXISTSR(domainid,sc,-1)
	quit:entityidlist="" 0
	
	// accept single values and translate to a 1-member list
	$$$IKENSURELISTNUM(entityidlist)

	// translate & clean entity list
	set tIncludeActuals = ($$$GETPARAM(domainid,$$$IKPSTEMMING,0)'=0) && 'pActualFormOnly
	set sc = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(domainid, entityidlist, .cleanEntIdList,,, tIncludeActuals)
	quit:$$$ISERR(sc) -1
	
	quit ..GetCountByEntitiesInternal(domainid, .cleanEntIdList, filter, positionstomatch, .sc)
}

ClassMethod GetCountByEntitiesInternal(domainid As %Integer, ByRef entityIdList, filter As %iKnow.Filters.Filter, positionstomatch As %Integer, Output sc As %Status = {$$$OK}) As %Integer [ Internal ]
{
	$$$IKQBEGINR("^||%IK.GetTotCrcsBit",sc,-1)
	$$$IKQFILTEROBJECTR(domainid,filter,sc,-1)
	quit:'$d(entityIdList) 0
	
	// if empty, return 0
	if ($order(entityIdList("")) = "") {
		quit 0
	}
	
	$$$IKQBCHECKR(domainid,$$$IKBCRCUNIMAP,sc,-1)
	
	// loop through the supplied entities
	set entId = ""
	set i = 0
	for {
		set entId = $order(entityIdList(entId))
		quit:entId=""
		
		set i = i+1
		
		// loop through ^IRIS.IK.EntUniMToCrcUniBit and merge resulting CRC bitstrings
		if ($$$CHECKPOSM(positionstomatch)) {
			set offset = ""
			for {
				set offset = $order(^IRIS.IK.EntUniMToCrcUniBit(domainid, entId, offset), 1, crcbits)
				quit:offset=""
				
				// retrieve what's already out there and merge
				set mergedbits = $bitlogic(^||%IK.GetTotCrcsBit(offset, "M") | crcbits)
				set ^||%IK.GetTotCrcsBit(offset, "M") = mergedbits
			}
		}
		
		// loop through ^IRIS.IK.EntUniRToCrcUniBit and merge resulting CRC bitstrings
		if ($$$CHECKPOSR(positionstomatch)) {
			set offset = ""
			for {
				set offset = $order(^IRIS.IK.EntUniRToCrcUniBit(domainid, entId, offset), 1, crcbits)
				quit:offset=""
				
				// retrieve what's already out there and merge
				set mergedbits = $bitlogic(^||%IK.GetTotCrcsBit(offset, "R") | crcbits)
				set ^||%IK.GetTotCrcsBit(offset, "R") = mergedbits
			}
		}
		
		// loop through ^IRIS.IK.EntUniSToCrcUniBit and merge resulting CRC bitstrings
		if ($$$CHECKPOSS(positionstomatch)) {
			set offset = ""
			for {
				set offset = $order(^IRIS.IK.EntUniSToCrcUniBit(domainid, entId, offset), 1, crcbits)
				quit:offset=""
				
				// retrieve what's already out there and merge
				set mergedbits = $bitlogic(^||%IK.GetTotCrcsBit(offset, "S") | crcbits)
				set ^||%IK.GetTotCrcsBit(offset, "S") = mergedbits
			}
		}
	} 
	
	// now loop through the generated bitstrings and count 1s after merging MRS
	set total = 0
	set offset = 0
	for {
		set offset = $order(^||%IK.GetTotCrcsBit(offset))
		quit:offset=""
		
		set mergedbits = $bitlogic(^||%IK.GetTotCrcsBit(offset, "M") | ^||%IK.GetTotCrcsBit(offset, "R") | ^||%IK.GetTotCrcsBit(offset, "S"))
		
		if ($isobject(filter)) {
			set filterBits = filter.GetCRCUniqueFilter(offset)
			set mergedbits = $bitlogic(mergedbits & filterBits)
		}
		
		set total = total + $bitcount(mergedbits, 1)
	}
	
	$$$IKQEND("^||%IK.GetTotCrcsBit",total)
}

///  translate a list of CRCs in their full-text $lb representation to CrcUniIds, 
///  removing inexistent crcs and duplicates
ClassMethod TranslateCrcList(domainid As %Integer, crclist As %List, globName As %String = "^||%IK.CrcIds", vSrcId As %Integer = 0, Output unMatchedCount As %Integer) As %Status [ Internal ]
{
	kill @globName
	
	set unMatchedCount = 0
	set:'$listvalid(crclist) crclist = $lfs(crclist)
	
	if ('$listvalid($lg(crclist,1)))||($lg(crclist,1)="") { // single CRC!
		set crcId = ..GetIdInternal(domainid, $lg(crclist, 1), $lg(crclist, 2), $lg(crclist, 3), vSrcId)
		if crcId { set @globName@(crcId) = "" } else { set unMatchedCount = 1 }
		quit $$$OK
	}
	
	set ptr = 0
	while $listnext(crclist, ptr, crc) {
		continue:crc=""
		set crcId = ..GetIdInternal(domainid, $lg(crc, 1), $lg(crc, 2), $lg(crc, 3), vSrcId)
		if crcId="" { set unMatchedCount = unMatchedCount + 1  continue }
		set @globName@(crcId) = ""
	}
	quit $$$OK
}

///  clean a list of CrcUniIds from duplicates and inexistent ids
ClassMethod TranslateCrcIdList(domainid As %Integer, crcIdList As %List, globName As %String = "^||%IK.CrcIds", vSrcId As %Integer = 0, Output unMatchedCount As %Integer) As %Status [ Internal ]
{
	kill @globName
	
	set unMatchedCount = 0
	set crcUniIdGlo = $$$IKVGLOBNAME(domainid,"CrcUniId",vSrcId)
	
	set ptr=0
	while $listnext(crcIdList, ptr, crcId) {
		continue:crcId=""
		if $data(@crcUniIdGlo@(crcId)) { set @globName@(crcId) = "" }
		else { set unMatchedCount = unMatchedCount + 1 }
	}
	quit $$$OK
}

ClassMethod TranslateMRSMaskToCrcIdList(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, globName As %String = "^||%IK.CrcIds", vSrcId As %Integer = 0, pIncludeAllForms As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		kill ^||%IK.TranslateMRSBits, @globName
	
		set vSrcId = $zabs(vSrcId)
	
		if 'vSrcId {
			$$$IKQBCHECKX(domainid,$$$IKBCRCUNIMAP,tSC)
		}
	
		set headToCrcGlo = $s(vSrcId:"^IRIS.IKV.EntUniMToCrcUni("_domainid_","_vSrcId_")", 1:"^IRIS.IK.EntUniMToCrcUniBit("_domainid_")")
		set relationToCrcGlo = $s(vSrcId:"^IRIS.IKV.EntUniRToCrcUni("_domainid_","_vSrcId_")", 1:"^IRIS.IK.EntUniRToCrcUniBit("_domainid_")")
		set tailToCrcGlo = $s(vSrcId:"^IRIS.IKV.EntUniSToCrcUni("_domainid_","_vSrcId_")", 1:"^IRIS.IK.EntUniSToCrcUniBit("_domainid_")")
		
		set isFirstFilter = 1, maxCrcId = $o(^IRIS.IK.CrcUniId(domainid,""),-1)
		$$$IKBITOFFPOS(maxCrcId,maxCrcOffset,maxCrcPos)
		
		// check head filters
		if (head '= $$$WILDCARD) {
			
			if (head="") {
				set tHeads(0) = ""
			} elseif pIncludeAllForms {
				set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid,$lb(head),.tHeads,vSrcId,,1)
				quit:$$$ISERR(tSC)
			} else {
				set tHeadId = +##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .head, vSrcId, 0)
				set:tHeadId tHeads(tHeadId)=""
			}
			if '$d(tHeads) { kill @globName  quit }
				
			// loop through ^IRIS.IK.EntUniMToCrcUniBit
			set tHeadId = ""
			for {
				set tHeadId = $order(tHeads(tHeadId))
				quit:tHeadId=""
				
				if (vSrcId) {
					merge @globName = @headToCrcGlo@(tHeadId)
				} else {
					set glo = $name(@headToCrcGlo@(tHeadId))
					$$$IKMERGEBITSOR(glo,"^||%IK.TranslateMRSBits")
				}
			}
			
			// note that the first filter is set, because we neet to AND them
			set isFirstFilter = 0
			kill tHeads
		}
		
		// check relation filters
		if (relation '= $$$WILDCARD) {
			
			if pIncludeAllForms {
				set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid,$lb(relation),.tRelations,vSrcId,,1)
				quit:$$$ISERR(tSC)
			} else {
				set tRelationId = +##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .relation, vSrcId, 0)
				set:tRelationId tRelations(tRelationId)=""
			}
			if '$d(tRelations) { kill @globName  quit }
				
			
			if (vSrcId) {
				set tRelationId=""
				for {
					set tRelationId = $order(tRelations(tRelationId))
					quit:tRelationId=""
					merge tRelCRCs = @relationToCrcGlo@(tRelationId)
				}
					
				if (isFirstFilter) {
					merge @globName = tRelCRCs
				} else {
					set crcId = ""
					for {
						set crcId = $order(@globName@(crcId))
						quit:crcId=""
						kill:'$d(tRelCRCs(crcId)) @globName@(crcId)
					}
				}
			} else {
				
				set tRelationId=""
				for {
					set tRelationId = $order(tRelations(tRelationId))
					quit:tRelationId=""
					set glo = $name(@relationToCrcGlo@(tRelationId))
					$$$IKMERGEBITSOR(glo,"tRelCRCs")
				}
				
				if (isFirstFilter) {
					$$$IKMERGEBITSOR("tRelCRCs","^||%IK.TranslateMRSBits")
				} else {
					$$$IKMERGEBITSAND("tRelCRCs","^||%IK.TranslateMRSBits")
				}
				
			}
			set isFirstFilter = 0
			kill tRelations, tRelCRCs
		}
		
		// check tail filters
		if (tail '= $$$WILDCARD) {
			
			if tail="" {
				set tTails(0)=""
			} elseif pIncludeAllForms {
				set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(domainid,$lb(tail),.tTails,vSrcId,,1)
				quit:$$$ISERR(tSC)
			} else {
				set tTailId = +##class(%iKnow.Queries.EntityAPI).GetIdInternal(domainid, .tail, vSrcId, 0)
				set:tTailId tTails(tTailId)=""
			}
			if '$d(tTails) { kill @globName  quit }
				
			
			if (vSrcId) {
				set tTailId=""
				for {
					set tTailId = $order(tTails(tTailId))
					quit:tTailId=""
					merge tTailCRCs = @tailToCrcGlo@(tTailId)
				}
					
				if (isFirstFilter) {
					merge @globName = tTailCRCs
				} else {
					set crcId = ""
					for {
						set crcId = $order(@globName@(crcId))
						quit:crcId=""
						kill:'$d(tTailCRCs(crcId)) @globName@(crcId)
					}
				}
			} else {
				
				set tTailId=""
				for {
					set tTailId = $order(tTails(tTailId))
					quit:tTailId=""
					set glo = $name(@tailToCrcGlo@(tTailId))
					$$$IKMERGEBITSOR(glo,"tTailCRCs")
				}
				
				if (isFirstFilter) {
					$$$IKMERGEBITSOR("tTailCRCs","^||%IK.TranslateMRSBits")
				} else {
					$$$IKMERGEBITSAND("tTailCRCs","^||%IK.TranslateMRSBits")
				}
				
			}
			set isFirstFilter = 0
		}
		
		// now turn the bitstrings into a list of crcIds
		if ('vSrcId) {
			set crcOffset = ""
			for {
				set crcOffset = $order(^||%IK.TranslateMRSBits(crcOffset), 1, bits)
				quit:crcOffset=""
			
				// loop over the 1s in the bitstring
				set crcPos = 0
				for {
					set crcPos = $bitfind(bits, 1, crcPos+1)
					quit:crcPos=0
				
					// recompose the crcId and add to the list
					$$$IKGETIDOFFPOS(crcId,crcOffset,crcPos)
					set @globName@(crcId) = ""
				}
			}
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	// BDB745
	kill @"tRelCRCs", @"tTailCRCs"
	quit tSC
}

}
