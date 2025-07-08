/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Simple implementation of the <class>%iKnow.Filters.Filter</class> interface, building
/// a simple equality condition on External ID.</p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>domainId</b> As <class>%Integer</class></li>
/// 	<li><b>externalIds</b> As <class>%List</class> - List of the external IDs that should be included by this filter. Can also be supplied as an array, in which case the top node is ignored.</li>
/// </ol>
Class %iKnow.Filters.ExternalIdFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property ExternalIds [ MultiDimensional ];

/// <p>See also <method>BuildSourceFilter</method> in <class>%iKnow.Filters.Filter</class>.</p>
Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	// this filter always builds all offsets in one go
	merge tExternalIds = i%ExternalIds
	set tExtId = "", tDomainId = i%DomainId
	for {
		set tExtId = $order(tExternalIds(tExtId))
		quit:tExtId=""
		set tSrcId = ##class(%iKnow.Queries.SourceAPI).GetSourceId(tDomainId, tExtId)
		continue:tSrcId=""
		$$$IKBITOFFPOS(tSrcId,srcOffset,srcPos)
		set $bit(tBits(srcOffset),srcPos) = 1
	}
	
	set maxSrcOffset = $order(^IRIS.IK.SrcExistsBit(tDomainId, ""), -1)
	for i = 1:1:maxSrcOffset {
		do ..SetSourceBits(i, $bitlogic(tBits(i) & ^IRIS.IK.SrcExistsBit(tDomainId, i)))
	}
	quit $$$OK
}

Method %OnNew(domainId As %Integer, ByRef extIds As %List) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(domainId)
	set i%DomainId = domainId
	if ($d(extIds)>1) {
		merge i%ExternalIds = extIds
	} elseif $d(extIds) {
		set:'$listvalid(extIds) extIds = $lfs(extIds)
		set ptr = 0
		while $listnext(extIds,ptr,tExtId) {
			set:tExtId'="" i%ExternalIds(tExtId)=""
		}
	}
	quit ..Initialize()
}

Method ToString() As %String
{
	merge tExtIds = i%ExternalIds
	set tExtId = "", tString = ""
	for {
		set tExtId = $order(tExtIds(tExtId))
		quit:tExtId=""
		set tString = tString _ $s(tString="":"", 1:",") _ tExtId
	}
	quit ..%ClassName(1)_"|"_..DomainId_"|"_tString
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Internal, Private ]
{
	quit ..%New($piece(filterParams, "|", 1), $lfs($piece(filterParams, "|", 2), ","))
}

Method ExternalIdsSet(extIds As %List) As %Status [ Internal, ServerOnly = 1 ]
{
	kill i%ExternalIds
	if ($d(extIds)>1) {
		merge i%ExternalIds = extIds
	} else {
		set:'$listvalid(extIds) extIds = $lfs(extIds)
		set ptr = 0
		while $listnext(extIds,ptr,tExtId) {
			set:tExtId'="" i%ExternalIds(tExtId)=""
		}
	}
	quit ..ChangeParams()
}

}
