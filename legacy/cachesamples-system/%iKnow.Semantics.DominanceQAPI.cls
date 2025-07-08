/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Semantics.DominanceAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Semantics.DominanceAPI</class> for more information.</p>
Class %iKnow.Semantics.DominanceQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

/// <p>Calculates the overlapping overlap of two sets of documents. First the overlap within <var>set1</var> is calculated, then the overlap within
/// 	<var>set2</var>. Finally those are compared and the most overlapping elements within those 2 sets are returned.</p>
Query GetAggregateOverlaps(domainid As %Integer, type As %Integer, set1 As %String(MAXLEN=32767) = "", set2 As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "id:%Integer,overlapSet1:%Integer,pctSet1:%Numeric,overlapSet2:%Integer,pctSet2:%Numeric,aggPct:%Numeric") [ Deprecated, SqlProc ]
{
}

ClassMethod GetAggregateOverlapsExecute(ByRef qHandle As %Binary, domainid As %Integer, type As %Integer, set1 As %String(MAXLEN=32767) = "", set2 As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetAggregateOverlaps("^||%IKQ.Result("_r_")", domainid, type, set1, set2, page, pagesize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetAggregateOverlapsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetAggregateOverlapsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetAggregateOverlapsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetAggregateOverlapsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the list of most breaking sources in a domain. The <var>type</var> parameter defines on which type of element you want the
/// list of breaking documents to be based. This can be:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
Query GetBreakingSources(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcid:%Integer,extid:%String(MAXLEN=32767),uniqueness:%Numeric") [ Deprecated, SqlProc ]
{
}

ClassMethod GetBreakingSourcesExecute(ByRef qHandle As %Binary, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetBreakingSources("^||%IKQ.Result("_r_")", domainid, page, pagesize, type, filter)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetBreakingSourcesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetBreakingSourcesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetBreakingSourcesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetBreakingSourcesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// 	<p>Returns all dominant elements for a specific source. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The elements returned can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
Query GetBySource(domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Library.Query(ROWSPEC = "id:%Integer,values:%List,type:%Integer,dominance:%Numeric") [ SqlProc ]
{
}

ClassMethod GetBySourceExecute(ByRef qHandle As %Binary, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetBySource("^||%IKQ.Result("_r_")", domainid, srcid, page, pagesize, type, cutoff)
	quit:$$$ISERR(sc) sc
	// serialize %Lists in output
	set index = ""
	for {
		set index = $order(^||%IKQ.Result(r,index))
		quit:index=""
		set $list(^||%IKQ.Result(r,index), 2) = $lts($li(^||%IKQ.Result(r,index), 2))
	}
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetBySourceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetBySourceExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetBySourceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetBySourceExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the number of dominant terms found in a specific source. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The number of elements counted can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetCountBySource(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetCountBySource(domainid, srcid, type, cutoff, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

ClassMethod GetCountBySourceInternal(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, pUseProfile As %Boolean = 1, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetCountBySourceInternal(domainid, srcid, type, cutoff, pUseProfile, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the dominance value of an element within a specified domain. The <var>id</var> parameter takes either an entityId, crcId or pathId and the
/// <var>type parameter</var> defines of what type the <var>id</var> parameter is. Thus valid types are <var>$$$SDCONCEPT</var>, <var>$$$SDCRC</var> and
/// 	<var>$$$SDPATH</var>.</p>
ClassMethod GetDomainValue(domainid As %Integer, id As %Integer, type As %Integer = {$$$SDCONCEPT}, Output scText As %String = "") As %Library.Numeric [ SqlProc ]
{
	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue(domainid, id, type, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the most overlapping elements in a domain. This can be restricted by type by setting the <var>type</var> parameter to any of those values:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
Query GetOverlap(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "id:%Integer,values:%Integer,type:%Integer,overlap:%Integer") [ Deprecated, SqlProc ]
{
}

ClassMethod GetOverlapExecute(ByRef qHandle As %Binary, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetOverlap("^||%IKQ.Result("_r_")", domainid, page, pagesize, type, filter)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetOverlapFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetOverlapExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetOverlapClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetOverlapExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the overlap details of an element in a domain. The type of the element must be specified through the <var>type</var> parameter to any of those values:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
Query GetOverlapDetails(domainid As %Integer, id As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcid:%Integer,dominance:%Numeric,sentences:%List") [ Deprecated, SqlProc ]
{
}

ClassMethod GetOverlapDetailsExecute(ByRef qHandle As %Binary, domainid As %Integer, id As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetOverlapDetails("^||%IKQ.Result("_r_")", domainid, id, page, pagesize, type, filter)
	quit:$$$ISERR(sc) sc
	// serialize %Lists in output
	set index = ""
	for {
		set index = $order(^||%IKQ.Result(r,index))
		quit:index=""
		set $list(^||%IKQ.Result(r,index), 3) = $lts($li(^||%IKQ.Result(r,index), 3))
	}
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetOverlapDetailsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetOverlapDetailsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetOverlapDetailsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetOverlapDetailsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// 	<p>Returns the dominance profile for a complete domain. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and <var>$$$SDAGGREGATE</var>.</p>
Query GetProfileByDomain(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}) As %Library.Query(ROWSPEC = "id:%Integer,values:%List,type:%Integer,dominance:%Numeric") [ Deprecated, SqlProc ]
{
}

ClassMethod GetProfileByDomainExecute(ByRef qHandle As %Binary, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetProfileByDomain("^||%IKQ.Result("_r_")", domainid, page, pagesize, type)
	quit:$$$ISERR(sc) sc
	// serialize %Lists in output
	set index = ""
	for {
		set index = $order(^||%IKQ.Result(r,index))
		quit:index=""
		set $list(^||%IKQ.Result(r,index), 2) = $lts($li(^||%IKQ.Result(r,index), 2))
	}
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileByDomainFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileByDomainExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileByDomainClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileByDomainExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// 	<p>Returns the dominance profile for a specific source. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The elements returned can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
Query GetProfileBySource(domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Library.Query(ROWSPEC = "id:%Integer,values:%List,type:%Integer,dominance:%Numeric") [ Deprecated, SqlProc ]
{
}

ClassMethod GetProfileBySourceExecute(ByRef qHandle As %Binary, domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetProfileBySource("^||%IKQ.Result("_r_")", domainid, srcid, page, pagesize, type, cutoff)
	quit:$$$ISERR(sc) sc
	// serialize %Lists in output
	set index = ""
	for {
		set index = $order(^||%IKQ.Result(r,index))
		quit:index=""
		set $list(^||%IKQ.Result(r,index), 2) = $lts($li(^||%IKQ.Result(r,index), 2))
	}
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileBySourceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileBySourceExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileBySourceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileBySourceExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the number of dominant terms in the profile of a complete domain. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and <var>$$$SDAGGREGATE</var>.</p>
ClassMethod GetProfileCountByDomain(domainid As %Integer, type As %Integer = {$$$SDCONCEPT}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetProfileCountByDomain(domainid, type, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the number of dominant terms in the profile of a specific source. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The number of elements counted can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetProfileCountBySource(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetProfileCountBySource(domainid, srcid, type, cutoff, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the dominance value of an element within a specified source. The <var>id</var> parameter takes either an entityId, crcId or pathId and the
/// <var>type parameter</var> defines of what type the <var>id</var> parameter is. Thus valid types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATIONM</var>,
/// 	<var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and	<var>$$$SDPATH</var>.</p>
ClassMethod GetSourceValue(domainid As %Integer, srcid As %Integer, id As %Integer, type As %Integer = {$$$SDCONCEPT}, Output scText As %String = "") As %Library.Numeric [ SqlProc ]
{
	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetSourceValue(domainid, srcid, id, type, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns a set of documents wich correlate closely to the input set (<var>entids</var>) of entities based on the dominance values of those entities
/// within the documents.</p>
Query GetSourcesByCorrelation(domainid As %Integer, entids As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcid:%Integer,extid:%String(MAXLEN=32767),correlation:%Numeric") [ Deprecated, SqlProc ]
{
}

ClassMethod GetSourcesByCorrelationExecute(ByRef qHandle As %Binary, domainid As %Integer, entids As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetSourcesByCorrelation("^||%IKQ.Result("_r_")", domainid, $lfs(entids), page, pagesize, filter)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetSourcesByCorrelationFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetSourcesByCorrelationExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetSourcesByCorrelationClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetSourcesByCorrelationExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the top entities for this domain, sorted by their aggregated dominance values.
/// <p><var>pAggregation</var> defines how to aggregate the source-level values. Currently the only
/// supported value is "AVG", which just calculates a regular average as a fast approximation.
/// Future versions will offer more advanced aggregation modes (which may be slower to calculate). </p>
Query GetTop(pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pAggregation As %String(MAXLEN=32767) = "AVG", pEntRole As %Integer = {$$$SDCONCEPT}, pSkipLists As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767),score:%Numeric") [ SqlProc ]
{
}

ClassMethod GetTopExecute(ByRef qHandle As %Binary, pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pAggregation As %String(MAXLEN=32767) = "AVG", pEntRole As %Integer = {$$$SDCONCEPT}, pSkipLists As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetTop("^||%IKQ.Result("_r_")", pDomainId, pPage, pPageSize, pFilter, pAggregation, pEntRole, $lfs(pSkipLists))
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTopFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTopExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTopClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTopExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the list of most typical sources in a domain. The <var>type</var> parameter defines on which type of element you want the
/// list of typical documents to be based. This can be:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
Query GetTypicalSources(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcid:%Integer,extid:%String(MAXLEN=32767),coverage:%Numeric") [ Deprecated, SqlProc ]
{
}

ClassMethod GetTypicalSourcesExecute(ByRef qHandle As %Binary, domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.DominanceAPI).GetTypicalSources("^||%IKQ.Result("_r_")", domainid, page, pagesize, type, filter)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTypicalSourcesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTypicalSourcesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTypicalSourcesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTypicalSourcesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

}
