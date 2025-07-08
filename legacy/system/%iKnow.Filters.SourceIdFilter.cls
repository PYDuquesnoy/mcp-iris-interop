/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Simple implementation of the <class>%iKnow.Filters.Filter</class> interface, building
/// a simple equality condition on Source IDs.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>sourceIds</b> As <class>%List</class> - List of the source IDs that should be included by this filter. Can also be supplied as an array, in which case the top node is ignored.</li>
/// </ol>
Class %iKnow.Filters.SourceIdFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property SourceIds [ MultiDimensional ];

Method %OnNew(domainId As %Integer, ByRef srcIds As %List) As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(domainId)
	set i%DomainId = domainId
	if ($d(srcIds)>1) {
		merge i%SourceIds = srcIds
	} elseif $d(srcIds) {
		set:'$listvalid(srcIds) srcIds = $lfs($zstrip(srcIds,"*W"))
		set ptr = 0
		while $listnext(srcIds,ptr,tSrcId) {
			set:+tSrcId i%SourceIds(tSrcId)=""
		}
	}
	quit ..Initialize()
}

Method ToString() As %String
{
	merge tSrcIds = i%SourceIds
	set tSrcId = "", tString = ""
	for {
		set tSrcId = $order(tSrcIds(tSrcId))
		quit:tSrcId=""
		set tString = tString _ $s(tString="":"", 1:",") _ tSrcId
	}
	quit ..%ClassName(1)_"|"_..DomainId_"|"_tString
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Internal, Private ]
{
	quit ..%New($piece(filterParams, "|", 1), $lfs($piece(filterParams, "|", 2)))
}

/// <p>See also <method>BuildSourceFilter</method> in <class>%iKnow.Filters.Filter</class>.</p>
Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	// this filter always builds all offsets in one go
	merge tSrcIds = i%SourceIds
	set tSrcId = "", tPrevOffset = "", tBits = "", tDomainId = i%DomainId
	for {
		set tSrcId = $order(tSrcIds(tSrcId))
		quit:tSrcId=""
		
		$$$IKBITOFFPOS(tSrcId,tOffset,tPos)
		
		if (tPrevOffset'=tOffset) {
			do:tPrevOffset ..SetSourceBits(tPrevOffset, $bitlogic(tBits & ^IRIS.IK.SrcExistsBit(tDomainId, tPrevOffset)))
			set tPrevOffset = tOffset, tBits = ""
		}
		set $bit(tBits,tPos) = 1
	}
	do:tPrevOffset ..SetSourceBits(tPrevOffset, $bitlogic(tBits & ^IRIS.IK.SrcExistsBit(tDomainId, tPrevOffset)))
	
	quit $$$OK
}

Method SourceIdsSet(ByRef srcIds As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	kill i%SourceIds
	if ($d(srcIds)>1) {
		merge i%SourceIds = srcIds
	} else {
		set:'$listvalid(srcIds) srcIds = $lfs(srcIds)
		set ptr = 0
		while $listnext(srcIds,ptr,tSrcId) {
			set:+tSrcId i%SourceIds(tSrcId)=""
		}
	}
	quit ..ChangeParams()
}

}
