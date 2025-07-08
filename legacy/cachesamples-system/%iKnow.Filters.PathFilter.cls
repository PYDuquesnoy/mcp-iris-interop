/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This implementation of the <class>%iKnow.Filters.Filter</class> interface selects all sources
/// containing at least one of the paths supplied to it.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pPathIds</b> As <class>%List</class> - List of the Path IDs whose containing
/// 			 sources are to be included. Can also be supplied as an array.</li>
/// </ol>
Class %iKnow.Filters.PathFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property PathIds [ MultiDimensional, Private ];

Method %OnNew(pDomainId As %Integer, ByRef pPathIds As %List) As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	set i%DomainId = pDomainId
	if ($d(pPathIds)>1) {
		merge i%PathIds = pPathIds
	} elseif $d(pPathIds) {
		set:'$listvalid(pPathIds) pPathIds = $lfs(pPathIds)
		set ptr = 0
		while $listnext(pPathIds,ptr,tPathId) {
			set:+tPathId i%PathIds(+tPathId)=""
		}
	}
	quit ..Initialize()
}

Method ToString() As %String
{
	merge tPathIds = i%PathIds
	set tPathId = "", tString = ""
	for {
		set tPathId = $order(tPathIds(tPathId))
		quit:tPathId=""
		set tString = tString _ $s(tString="":"", 1:",") _ tPathId
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
	merge tPathIds = i%PathIds
	kill ^||%IK.SrcIds
	set tPathId = "", tDomainId = i%DomainId
	for {
		set tPathId = $order(tPathIds(tPathId))
		quit:tPathId=""
		
		set tPathBase = $order(^IRIS.IK.PathToSrc(tDomainId, tPathId), -1, tPathInfo)
		continue:tPathBase="" // inexistent Path ID
		set tMaxPathId = tPathBase + $lg(tPathInfo,2)
		continue:tMaxPathId<tPathId // inexistent Path ID (gap)
		
		set tSrcId = $li(tPathInfo,1)
		$$$IKBITOFFPOS(tSrcId,tOffset,tPos)
		set $bit(^||%IK.SrcIds(tOffset),tPos) = 1
		
		// jump to end of source
		set tPathId = tMaxPathId
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
