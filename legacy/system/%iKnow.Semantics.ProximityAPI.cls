/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKInclude, %IKPublic)

/// <p>The InterSystems IRIS NLP iKnow technology is now deprecated. Please see the 
/// <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GIKNOW">product 
/// documentation</a> for more detail.</p>
/// Main class for retrieving proximity information sources.
Class %iKnow.Semantics.ProximityAPI Extends %iKnow.Queries.AbstractAPI [ Deprecated, System = 4 ]
{

Parameter GetProfileBySourceIdRT = "entUniId:%Integer,entity:%String,score:%Integer";

/// Returns the proximity profile for a given entity identified by <var>pEntUniId</var> in source <var>pSrcId</var>.
/// See also <method>GetProfile</method> for a broader set of options.
ClassMethod GetProfileBySourceId(ByRef pResult, pDomainId As %Integer, pEntUniId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10) As %Status
{
	$$$IKQBEGINTRY(pResult,"^||%IK.Prox",tSC)
	if (pSrcId<0) && (pDomainId=0) { } else { $$$CHECKDOMAINEXISTSX(pDomainId,tSC) }
	$$$CHECKASRCIDEXISTSX(pDomainId,pSrcId,tSrcDetails,vSrcId,tSC)
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	quit:'pEntUniId
	
	// note that SP data is only stored once, whith lowest entity first, so we'll need two passes
	set gSrcDist = $s(vSrcId:$name(^IRIS.IKV.SP.SrcDist(pDomainId,vSrcId)), 1:$name(^IRIS.IK.SP.SrcDist(pDomainId,pSrcId)))
	$$$IKSORTBEGIN(^||%IK.Prox)
	set tOtherEntUniId = ""
	for {
		set tOtherEntUniId = $order(@gSrcDist@(tOtherEntUniId))
		quit:tOtherEntUniId=""
		quit:tOtherEntUniId>=pEntUniId
		continue:'$d(@gSrcDist@(tOtherEntUniId,pEntUniId),tDistance)
		set ^||%IK.Prox(-tDistance,tOtherEntUniId)=""
	}
	set tOtherEntUniId=""
	for {
		set tOtherEntUniId = $order(@gSrcDist@(pEntUniId,tOtherEntUniId),1,tDistance)
		quit:tOtherEntUniId=""
		set ^||%IK.Prox(-tDistance,tOtherEntUniId)=""
	}
	set x = $sortend(^||%IK.Prox)
	
	// now resort
	set tDistance=""
	for {
		set tDistance = $order(^||%IK.Prox(tDistance))
		quit:tDistance=""
		set tOtherEntUniId=""
		for {
			set tOtherEntUniId = $order(^||%IK.Prox(tDistance,tOtherEntUniId))
			quit:tOtherEntUniId=""
			set tCount = tCount+1
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			$$$IKQADDRESULT(pResult,tCount,$lb(+tOtherEntUniId,##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId,tOtherEntUniId,vSrcId),-tDistance))
		}
		quit:tUsePaging&&(tCount>tLast)
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.Prox",tSC)
}

Parameter GetProfileBySourceRT = "entUniId:%Integer,entity:%String,score:%Integer";

/// Returns the proximity profile for a given entity <var>pEntity</var> in source <var>pExtId</var>.
/// See also <method>GetProfile</method> for a broader set of options.
ClassMethod GetProfileBySource(ByRef pResult, pDomainId As %Integer, pEntity As %String, pExternalId As %String, pPage As %Integer = 1, pPageSize As %Integer = 10) As %Status
{
	set tSrcId = ##class(%iKnow.Queries.SourceAPI).GetSourceId(pDomainId, pExternalId, .tSC)
	quit:$$$ISERR(tSC) tSC
	set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(pDomainId, pEntity,, 0)
	quit:'tEntUniId $$$OK
	quit ..GetProfileBySourceId(.pResult, pDomainId, tEntUniId, tSrcId, pPage, pPageSize)
}

Parameter GetProfileRT = "entUniId:%Integer,entity:%String,score:%Integer";

/// <p>Returns the proximity profile for the entity or list of entities supplied through
/// <var>pEntity</var>. This profile is calculated based on the aggregated distance to
/// <var>pEntity</var> entries in all paths in the domain (when <var>pFilter</var>=""),
/// optionally constrained to all paths in a specific set of sources (when <var>pFilter</var>!="").</p>
/// <p>When setting <var>pUseStems</var> to 1, for a domain that has stemming enabled, the scope of 
/// the profile will be expanded to include all actual forms of the supplied <var>pEntity</var>
/// (which has to be provided as a base form (stem)!), and their combined proximity profiles will be
/// grouped to the stem level again.</p> 
ClassMethod GetProfile(ByRef pResult, pDomainId As %Integer, pEntity As %String, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pSkipListIDs As %List = "", pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(pResult,"")
	$$$CHECKDOMAINEXISTS(pDomainId)
	quit:$g(pEntity)="" $$$OK
	
	if pUseStems && ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		quit $$$ERROR($$$IKStemmingNotEnabled)
	} 
	
	// BDB804 - unravel the entity list into a clean array
	$$$IKENSURELISTSTR(pEntity)
	kill tEntIdList
	if pUseStems {
		set ptr=0
		while $listnext(pEntity,ptr,tStem) {
			kill tArray
			set tStemId = ##class(%iKnow.Queries.EntityAPI).GetStemIdInternal(pDomainId, tStem)
			do ##class(%iKnow.Queries.EntityAPI).GetByStemArray(.tArray, pDomainId, tStemId)
			merge tEntIdList = tArray
		}
	} else {
		set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityList(pDomainId, pEntity, .tEntIdList)
		quit:$$$ISERR(tSC) tSC
	}
	
	if ($d(tEntIdList) <= 1) { quit $$$OK }
	
	quit ..GetProfileInternal(.pResult, pDomainId, .tEntIdList, pPage, pPageSize, pFilter, pSkipListIDs, pUseStems)
}

Parameter GetProfileByIdRT = "entUniId:%Integer,entity:%String,score:%Integer";

/// Returns the proximity profile for the entity represented by <var>pEntUniId</var>. See also <method>GetProfile</method>
/// When setting <var>pUseStems</var> to 1, the value of <var>pEntUniId</var> will be interpreted
/// as a stem ID.
ClassMethod GetProfileById(ByRef pResult, pDomainId As %Integer, pEntUniId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %iKnow.Filters.Filter = "", pSkipListIDs As %List = "", pUseStems As %Boolean = 0) As %Status
{
	$$$IKQBEGIN(pResult,"")
	$$$CHECKDOMAINEXISTS(pDomainId)
	
	if pUseStems && ($$$GETPARAM(pDomainId,$$$IKPSTEMMING,0)=0) {
		quit $$$ERROR($$$IKStemmingNotEnabled)
	} 
	
	// BDB804 - unravel the entity list into a clean array
	$$$IKENSURELISTNUM(pEntUniId)
	kill tEntIdList
	if pUseStems {
		set ptr=0
		while $listnext(pEntUniId,ptr,tStemId) {
			kill tArray
			do ##class(%iKnow.Queries.EntityAPI).GetByStemArray(.tArray, pDomainId, tStemId)
			merge tEntIdList = tArray
		}
	} else {
		set tSC = ##class(%iKnow.Queries.EntityAPI).TranslateEntityIdList(pDomainId, pEntUniId, .tEntIdList)
		quit:$$$ISERR(tSC) tSC
	}
	
	if ($d(tEntIdList) <= 1) { quit $$$OK }
	
	quit ..GetProfileInternal(.pResult, pDomainId, .tEntIdList, pPage, pPageSize, pFilter, pSkipListIDs, pUseStems)
}

/// Internal method supporting <method>GetProfile</method> and <method>GetProfileById</method>.
/// This method only accepts ENTITY IDs, no stems!
ClassMethod GetProfileInternal(ByRef pResult, pDomainId As %Integer, ByRef pEntIdList, pPage As %Integer, pPageSize As %Integer, pFilter As %iKnow.Filters.Filter, pSkipListIDs As %List, pUseStems As %Boolean = 0) As %Status [ Internal ]
{
	if ($d(pEntIdList) <= 1) { quit $$$OK }
	
	$$$IKQBEGINTRY(pResult,"^||%IK.Prox,^||%IK.ProxStems",tSC)
	$$$IKBUILDSKIPLIST(pDomainId,pSkipListIDs,0,0)
	
	// BDB804 - track if SkipLists still need to be checked
	set tCheckSkipLists = 1
	
	$$$IKBFLAGS(pDomainId,tFlags) // BDB805
	if (pFilter="") && '$o(pEntIdList($o(pEntIdList("")))) && ($a(tFlags,$$$IKBSPVALUE)>0) {
		set gAggregates = $name(^IRIS.IK.SP.Value(pDomainId,$o(pEntIdList(""))))
	} else {
		$$$IKQFILTEROBJECTX(pDomainId,pFilter,tSC)
		set:'$isobject(pFilter) pFilter = ##class(%iKnow.Filters.BitmapFilter).%New(pDomainId,"^IRIS.IK.SrcExistsBit("_pDomainId_")")
		set tJobN = +$job, gAggregates = $name(^IRIS.Temp.IK.Prox(tJobN)), tCheckSkipLists=0
		kill ^IRIS.Temp.IK.Prox(tJobN)
		if pFilter.FilteredSourceCount<1000 {
			set tOffset = ""
			for {
				set tOffset = pFilter.GetNextSourceFilterOffset(tOffset, .tBits)
				quit:tOffset=""
				do ..GetProfileByIdJob(pDomainId,.pEntIdList,tOffset,tBits,tJobN,pSkipListIDs)
			}
		} else {
			#dim tWorkMgr As %SYSTEM.WorkMgr
			set tWorkMgr = $system.WorkMgr.Initialize("", .tSC)
			quit:$$$ISERR(tSC)
			
			set tOffset = ""
			for {
				set tOffset = pFilter.GetNextSourceFilterOffset(tOffset, .tBits)
				quit:tOffset=""
				
				set tSC = tWorkMgr.Queue("##class(%iKnow.Semantics.ProximityAPI).GetProfileByIdJob",pDomainId,.pEntIdList,tOffset,tBits,tJobN,pSkipListIDs)
				quit:$$$ISERR(tSC)
			}
			
			set tSC = tWorkMgr.Sync()
			quit:$$$ISERR(tSC)
		}
	}
	
	// BDB804 - now fold entity targets back together into stem level
	if pUseStems {
		
		// make sure to capture stem-level SkipLists items
		$$$IKBUILDSKIPLIST(pDomainId,pSkipListIDs,0,1)
		
		set tTargetId = ""
		for {
			set tTargetId = $order(@gAggregates@(tTargetId),1,tValue)
			quit:tTargetId=""
			set tStemId = $o(^IRIS.IK.EntUniToStemUni(pDomainId,tTargetId,""))
			continue:$$$IKISSKIPLISTED(tStemId)
			set x=$i(^||%IK.ProxStems(tStemId),tValue)
		}
		set gAggregates = "^||%IK.ProxStems"
	}
	
	$$$IKSORTBEGIN(^||%IK.Prox)
	set tTargetId = ""
	for {
		set tTargetId = $order(@gAggregates@(tTargetId),1,tValue)
		quit:tTargetId=""
		continue:tCheckSkipLists&&$$$IKISSKIPLISTED(tTargetId)
		set ^||%IK.Prox(-tValue,tTargetId)=""
	}
	set x = $sortend(^||%IK.Prox)
	kill:$g(tJobN) ^IRIS.Temp.IK.Prox(tJobN)
	
	$$$IKSETPAGINGVARS(pPage,pPageSize,tUsePaging,tFirst,tLast,tCount)
	set tValue="", tCount=""
	for {
		set tValue = $order(^||%IK.Prox(tValue))
		quit:tValue=""
		set tTargetId=""
		for {
			set tTargetId = $order(^||%IK.Prox(tValue,tTargetId))
			quit:tTargetId=""
			set tCount = tCount+1
			$$$IKCHECKPAGING(tUsePaging,tFirst,tLast,tCount)
			
			$$$IKQADDRESULT(pResult,tCount,$lb(+tTargetId, ##class(%iKnow.Queries.EntityAPI).GetValueInternal(pDomainId, tTargetId,, pUseStems), -tValue))
			
			quit:tUsePaging&&(tCount>tLast)
		}
		quit:tUsePaging&&(tCount>tLast)
	}
	
	$$$IKQENDCATCH(pResult,"^||%IK.Prox,^IRIS.Temp.IK.Prox(+$g(tJobN)),^||%IK.ProxStems",tSC)
}

ClassMethod GetProfileByIdJob(pDomainId As %Integer, ByRef pEntUniIds, pOffset As %Integer, pBits As %RawString, pJobID As %Integer, pSkipListIDs As %List = "") As %Status [ Internal ]
{
	$$$IKBUILDSKIPLIST(pDomainId,pSkipListIDs,0,0)
	
	set tPos = 0
	for {
		set tPos = $bitfind(pBits,1,tPos+1)
		quit:'tPos
		$$$IKGETIDOFFPOS(tSrcId,pOffset,tPos)
		
		merge tProx = ^IRIS.IK.SP.SrcDist(pDomainId,tSrcId)
		
		set tEntUniId = ""
		for {
			set tEntUniId = $order(pEntUniIds(tEntUniId))
			quit:tEntUniId=""
		
			set tTargetId = ""
			for {
				set tTargetId = $order(tProx(tEntUniId,tTargetId),1,tValue)
				quit:tTargetId=""
				continue:$$$IKISSKIPLISTED(tTargetId)
				set x = $i(^IRIS.Temp.IK.Prox(pJobID,tTargetId),tValue)
			}
			
			// BDB805 - as this global only stores the ones where tTargetId>tOriginId, we need
			// to walk through the earlier bit separately
			set tTargetId = ""
			for {
				set tTargetId = $order(tProx(tTargetId))
				quit:tTargetId=""
				quit:tTargetId>tEntUniId
				if $d(tProx(tTargetId,tEntUniId),tValue) {
					continue:$$$IKISSKIPLISTED(tTargetId)
					set x = $i(^IRIS.Temp.IK.Prox(pJobID,tTargetId),tValue)
				}
			}
		}
		kill tProx
	}
	
	quit $$$OK
}

///  <p>Returned column summary for <method>GetClustersBySource</method>.</p>
Parameter GetClustersBySourceRT [ Deprecated, Internal ] = "entid:%Integer,entity:%String,score:%Numeric";

/// <p>Clusters a document to a set of proximity terms that best identify the documents content.</p>
ClassMethod GetClustersBySource(ByRef result, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Deprecated, Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.ProxSum,^||%IK.Topics",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$CHECKSRCIDEXISTSX(domainid,srcid,tSC)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)

	set offset=""
	for {
		set offset=$o(^IRIS.IK.SrcToEntUniBit(domainid,srcid,offset),1,bitstring)
		q:offset=""
		
		set pos=0
		for {
			set pos=$bitfind(bitstring,1,pos+1)
			q:pos=0
			
			$$$IKGETIDOFFPOS(uniId,offset,pos)
			set avgConRelSemDom = ($lg(^IRIS.IK.EntSrcDetails(domainid,srcid,uniId),3)+$lg(^IRIS.IK.EntSrcDetails(domainid,srcid,uniId),4))/2
			
			set topic=""
			for {
				set topic=$o(^IRIS.IK.SP.Value(domainid,uniId,topic),1,val)
				q:topic=""
				
				set ^||%IK.ProxSum(topic)=$get(^||%IK.ProxSum(topic),0)+avgConRelSemDom
			}
		}
	}
	
	k ^||%IK.Topics
	set topic=""
	for {
		set topic=$o(^||%IK.ProxSum(topic),1,val)
		q:topic=""
		
		set ^||%IK.Topics(-val)=$lb(topic,^IRIS.IK.EntUniId(domainid,topic),val)
	}
	k ^||%IK.ProxSum
	set val=""
	for {
		set val=$o(^||%IK.Topics(val),1,data)
		q:val=""
		
		set count=count+1
		$$$IKCHECKPAGING(usePaging,first,last,count)
		
		$$$IKQADDRESULT(result,count,data)
	}
	$$$IKQENDCATCH(result,"^||%IK.ProxSum,^||%IK.Topics",tSC)
}

///  <p>Returned column summary for <method>GetProfileForEntity</method>.</p>
Parameter GetProfileForEntityRT [ Deprecated, Internal ] = "entId:%Integer,entity:%String,proximity:%Numeric";

/// <p>Returns the proximity profile for a specified entity.</p>
/// <p>The proximity profile are those elements that most likely occur in close relationship to the provided entity within the sources in a domain.</p>
/// <p>Deprecated: See also <method>GetProfile</method> for a broader set of options.</p>
ClassMethod GetProfileForEntity(ByRef result, domainid As %Integer, entId As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Deprecated, Internal ]
{
	$$$IKQBEGINTRY(result,"^||%IK.Prof,^||%IK.ProfCnt,^||%IK.ProfOrd",tSC)
	$$$CHECKDOMAINEXISTSX(domainid,tSC)
	$$$IKSETPAGINGVARS(page,pagesize,usePaging,first,last,count)
	
	set target = ""
	for {
		set target=$o(^IRIS.IK.SP.Value(domainid,entId,target),1,dist)
		q:target=""
		
		set ^||%IK.Prof(target)=$g(^||%IK.Prof(target),0)+dist
		set ^||%IK.ProfCnt(target)=$g(^||%IK.ProfCnt(target),0)+1
	}
	
	k ^||%IK.ProfOrd
	set target=""
	for {
		set target=$o(^||%IK.Prof(target),1,dist)
		q:target=""
		
		set sum=^||%IK.ProfCnt(target)
		
		set ^||%IK.ProfOrd(-(dist/sum),target)=(dist/sum)
	}
	//k ^||%IK.Prof, ^||%IK.ProfCnt
	
	set ord=""
	for {
		set ord=$o(^||%IK.ProfOrd(ord))
		q:ord=""
		
		set target=""
		for {
			set target=$o(^||%IK.ProfOrd(ord,target),1,prox)
			q:target=""
			
			set count=count+1
			$$$IKCHECKPAGING(usePaging,first,last,count)
			
			$$$IKQADDRESULT(result,count,$lb(target,^IRIS.IK.EntUniId(domainid,target),prox))
		}
		$$$IKCHECKPAGING(usePaging,first,last,count)
	}
	$$$IKQENDCATCH(result,"^||%IK.Prof,^||%IK.ProfCnt,^||%IK.ProfOrd",tSC)
}

}
