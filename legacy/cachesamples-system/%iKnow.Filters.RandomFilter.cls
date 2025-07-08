/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This filter randomly selects a percentage of the existing sources in the current domain, to be used
/// for analysis or query testing. </p>
/// 
/// <p><b>Filter parameters</b>:
/// <ol>
/// 	<li><b>pDomainId</b> As <class>%Integer</class></li>
/// 	<li><b>pDelect</b> As <class>%Numeric</class> - if this is a value between 0 and 1, it is
/// 			 interpreted as the desired selectivity of the filter or the share of the total number
/// 			 of sources to select. If this value is &gt;= 1, it is considered to be the desired number
/// 			 of sources to select (rounded down). If this value is larger than the total number
/// 				 of sources in this domain, all sources are selected.</li>
/// 		<li><b>pSelectFrom</b> As <class>%iKnow.Filters.Filter</class> - if set to a valid filter object
/// 				 or string representation, the randomly selected sources are selected from this set
/// 				 only. If <var>select</var> refers to a fraction, the fraction is calculated based
/// 				 on the total number of sources filtered by <var>selectFrom</var> as if it were
/// 				 "the full domain" to select from.
/// </ol>
Class %iKnow.Filters.RandomFilter Extends %iKnow.Filters.Filter [ Deprecated, System = 4 ]
{

Property ReqSelectivity As %Integer [ Private ];

Property SelectFrom As %iKnow.Filters.Filter [ Private ];

Method %OnNew(pDomainId As %Integer, pSelect As %Numeric = 0.1, pSelectFrom As %iKnow.Filters.Filter = "") As %Status [ Private, ServerOnly = 1 ]
{
	$$$CHECKDOMAINEXISTS(pDomainId)
	quit:pSelect<=0 $$$ERROR($$$InvalidArgument)
	
	$$$IKQFILTEROBJECT(pDomainId,pSelectFrom)
	
	set i%DomainId = pDomainId
	set i%ReqSelectivity = pSelect
	set i%SelectFrom = pSelectFrom
	
	quit ..Initialize()
}

/// <p>See also <method>BuildSourceFilter</method> in <class>%iKnow.Filters.Filter</class>.</p>
Method BuildSourceFilter(maxOffset As %Integer) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set selectivity = i%ReqSelectivity
		
		set maxSrcId = $order(^IRIS.IK.SrcId(i%DomainId,""),-1)
		set totSrcCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(i%DomainId, i%SelectFrom)
		if (selectivity < 1) {
			// if selectivity > 0.5, find (1-selectivity) and negate the bitstrings to save time
			set neg = (selectivity > 0.5)
			set:neg selectivity = 1-selectivity
			set targetCount = $normalize(selectivity*totSrcCount, 0)
		} else {
			set targetCount = selectivity \ 1, neg = 0
		}
		set filteredCount = 0
		
		kill ^||%IK.Bits
		set:'$isobject(i%SelectFrom) i%SelectFrom = ##class(%iKnow.Filters.BitmapFilter).%New(i%DomainId, $name(^IRIS.IK.SrcExistsBit(i%DomainId)))
		while (filteredCount < targetCount) && (filteredCount < totSrcCount) {
			set srcId = $random(maxSrcId)
			$$$IKBITOFFPOS(srcId,off,pos)
			set bits =  $g(^||%IK.Bits(off))
			
			// skip if already selected or nonexistent
			continue:$bit(bits,pos)
			continue:'i%SelectFrom.IsFiltered(srcId)
			
			// otherwise, add to selected set
			set $bit(bits,pos)=1, ^||%IK.Bits(off)=$bitlogic(bits), filteredCount=filteredCount+1
		}
		
		// now loop through ..SourceBits and negate if applicable
		set off = ""
		for {
			set off = i%SelectFrom.GetNextSourceFilterOffset(off,.bits)
			quit:off=""
			
			do ..SetSourceBits(off, $s(neg:$bitlogic(bits & ~^||%IK.Bits(off)), 1:$bitlogic(^||%IK.Bits(off))))
		}
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ToString() As %String
{
	quit ..%ClassName(1)_"|"_..DomainId_"|"_..ReqSelectivity_"|"_$s($isobject(..SelectFrom):..SelectFrom.ToString(), 1:"")
}

ClassMethod RestoreFilterFromStringInternal(filterParams As %String) As %iKnow.Filters.Filter [ Private ]
{
	set tDomainId = $piece(filterParams,"|",1)
	set tSelect = $piece(filterParams,"|",2)
	set tSelectFrom = $piece(filterParams,"|",3,*)
	quit ..%New(tDomainId, tSelect, tSelectFrom)
}

}
