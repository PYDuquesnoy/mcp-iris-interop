/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This implementation of the <class>%iKnow.Filters.Filter</class> interface selects all sources
/// containing at least one of the sentences supplied to it.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pSentenceIds</b> As <class>%List</class> - List of the sentence IDs whose containing
/// 			 sources are to be included. Can also be supplied as an array.</li>
/// </ol>
Class %iKnow.Filters.SentenceFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property SentIds [ MultiDimensional, Private ];

Method %OnNew(pDomainId As %Integer, ByRef pSentenceIds As %List) As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	set i%DomainId = pDomainId
	if ($d(pSentenceIds)>1) {
		merge i%SentIds = pSentenceIds
	} elseif $d(pSentenceIds) {
		set:'$listvalid(pSentenceIds) pSentenceIds = $lfs(pSentenceIds)
		set ptr = 0
		while $listnext(pSentenceIds,ptr,tSentId) {
			set:+tSentId i%SentIds(+tSentId)=""
		}
	}
	quit ..Initialize()
}

Method ToString() As %String
{
	merge tSentIds = i%SentIds
	set tSentId = "", tString = ""
	for {
		set tSentId = $order(tSentIds(tSentId))
		quit:tSentId=""
		set tString = tString _ $s(tString="":"", 1:",") _ tSentId
	}
	quit $classname()_"|"_..DomainId_"|"_tString
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Internal, Private ]
{
	quit ..%New($piece(filterParams, "|", 1), $lfs($piece(filterParams, "|", 2)))
}

/// <p>See also <method>BuildSourceFilter</method> in <class>%iKnow.Filters.Filter</class>.</p>
Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	// this filter always builds all offsets in one go
	merge tSentIds = i%SentIds
	kill ^||%IK.SrcIds
	set tSentId = "", tDomainId = i%DomainId
	for {
		set tSentId = $order(tSentIds(tSentId))
		quit:tSentId=""
		
		set tSentBase = $order(^IRIS.IK.SentToSrc(tDomainId, tSentId), -1, tSentInfo)
		continue:tSentBase="" // inexistent sentence ID
		set tMaxSentId = tSentBase + $lg(tSentInfo,2)
		continue:tMaxSentId<tSentId // inexistent sentence ID (gap)
		
		set tSrcId = $li(tSentInfo,1)
		$$$IKBITOFFPOS(tSrcId,tOffset,tPos)
		set $bit(^||%IK.SrcIds(tOffset),tPos) = 1
		
		// jump to end of source
		set tSentId = tMaxSentId
	}
	
	set tOffset = ""
	for {
		set tOffset = $order(^||%IK.SrcIds(tOffset), 1, tBits)
		quit:tOffset=""
		
		do ..SetSourceBits(tOffset, $bitlogic(tBits & ^IRIS.IK.SrcExistsBit(tDomainId, tOffset)))
	}
	kill ^||%IK.SrcIds
	quit $$$OK
}

}
