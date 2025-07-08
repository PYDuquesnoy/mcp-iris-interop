/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.CrcAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Queries.CrcAPI</class> for more information.</p>
Class %iKnow.Queries.CrcQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

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
Query GetByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSALL}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "crcId:%Integer,head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer") [ SqlProc ]
{
}

ClassMethod GetByEntitiesExecute(ByRef qHandle As %Binary,  domainid As %Integer, entitylist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSALL}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CrcAPI).GetByEntities("^||%IKQ.Result("_r_")", domainid, $lfs(entitylist), page, pagesize, filter, filtermode, positionstomatch, pActualFormOnly)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByEntitiesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByEntitiesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByEntitiesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByEntitiesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Returns the CRCs in this domain containing any or all of a list of entity IDs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSALL}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "crcId:%Integer,head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer") [ SqlProc ]
{
}

ClassMethod GetByEntityIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, entityidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSALL}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CrcAPI).GetByEntityIds("^||%IKQ.Result("_r_")", domainid, $lfs(entityidlist), page, pagesize, filter, filtermode, positionstomatch, pActualFormOnly)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByEntityIdsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByEntityIdsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByEntityIdsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByEntityIdsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Returns all CRCs appearing in any source satisfying the supplied <var>filter</var> 
///  objects criteria, with their frequencies and spread recalculated to comply with the filter
///  depending on the value of <var>filtermode</var>, but the result is NOT re-sorted, regardless
///  of the value for <var>filtermode</var> (use <method>GetTop</method> if you want sorted results).</p>
Query GetByFilter(domainid As %Integer, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}) As %Library.Query(ROWSPEC = "crcId:%Integer,head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer") [ SqlProc ]
{
}

ClassMethod GetByFilterExecute(ByRef qHandle As %Binary,  domainid As %Integer, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CrcAPI).GetByFilter("^||%IKQ.Result("_r_")", domainid, filter, filtermode)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByFilterFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByFilterExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByFilterClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByFilterExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Returns the unique CRCs appearring in the specified sources.</p>
///  <p>To get the unique CRCs of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
Query GetBySource(domainid As %Integer, sourceidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "crcId:%Integer,head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer") [ SqlProc ]
{
}

ClassMethod GetBySourceExecute(ByRef qHandle As %Binary,  domainid As %Integer, sourceidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CrcAPI).GetBySource("^||%IKQ.Result("_r_")", domainid, $lfs(sourceidlist), page, pagesize)
	quit:$$$ISERR(sc) sc
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

///  <p>Returns the total number of unique CRCs in a domain, optionally limited through supplying a
///  <class>%iKnow.Filters.Filter</class> object as the <var>filter</var> parameter to restrict the result to
///  those CRCs occurring in any source satisfying the filter criteria.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "", Output scText As %String = "", includeZeroFrequency As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetCountByDomain(domainid, filter, .sc, includeZeroFrequency)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the number of CRCs in this domain, based on a list of entities.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", positionstomatch As %Integer = {$$$USEPOSALL}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetCountByEntities(domainid, $lfs(entitylist), filter, positionstomatch, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the number of CRCs in this domain, based on a list of entity IDs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", positionstomatch As %Integer = {$$$USEPOSALL}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetCountByEntityIds(domainid, $lfs(entityidlist), filter, positionstomatch, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the total number of unique CRCs appearing in either (if <var>setop</var> = $$$UNION) or
///  all (if <var>setop</var> = $$$INTERSECT) of the sources specified by ID in <var>sourceidlist</var>.</p>
///  <p>To get the unique CRCs of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %String(MAXLEN=32767), setop As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetCountBySource(domainid, $lfs(sourceidlist), setop, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the frequency of the CRC corresponding to the supplied <var>crcUniId</var>.</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetFrequency(domainId As %Integer, crcUniId As %Integer, vSrcId As %Integer = 0, filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetFrequency(domainId, crcUniId, vSrcId, filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns, if any, the CRC ID for the combination of Head, Relation and Tail specified.</p>
///  <p>When specifying a Virtual Source ID, it will treat the head, relation and tails as virtual
///  entities, in the context of that vSrcId.</p>
ClassMethod GetId(domainid As %Integer, head As %String(MAXLEN=32767), relation As %String(MAXLEN=32767), tail As %String(MAXLEN=32767), vSrcId As %Integer = 0) As %Library.Integer [ SqlProc ]
{
	quit ##class(%iKnow.Queries.CrcAPI).GetId(domainid, head, relation, tail, vSrcId)
}

///  <p>Returns the total number of CRC occurrences in the specified sources.</p>
///  <p>Use negative source IDs to refer to virtual sources</p>
ClassMethod GetOccurrenceCountBySource(domainid As %Integer, sourceidlist As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetOccurrenceCountBySource(domainid, $lfs(sourceidlist), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the CRC occurrences for a given source, in the order in which they appear.</p>
Query GetOccurrencesBySource(domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "crcOccId:%Integer,crcUniId:%Integer,head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767),sentenceId:%Integer,posInSent:%Integer") [ SqlProc ]
{
}

ClassMethod GetOccurrencesBySourceExecute(ByRef qHandle As %Binary,  domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CrcAPI).GetOccurrencesBySource("^||%IKQ.Result("_r_")", domainid, srcid, page, pagesize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetOccurrencesBySourceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetOccurrencesBySourceExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetOccurrencesBySourceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetOccurrencesBySourceExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Returns the spread of the CRC corresponding to the supplied <var>crcUniId</var>.</p>
ClassMethod GetSpread(domainId As %Integer, crcUniId As %Integer, filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CrcAPI).GetSpread(domainId, crcUniId, filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

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
Query GetTop(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, vSrcId As %Integer = 0) As %Library.Query(ROWSPEC = "crcId:%Integer,head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767),freq:%Integer,spread:%Integer") [ SqlProc ]
{
}

ClassMethod GetTopExecute(ByRef qHandle As %Binary,  domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, vSrcId As %Integer = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CrcAPI).GetTop("^||%IKQ.Result("_r_")", domainid, page, pagesize, filter, filtermode, sorttype, vSrcId)
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

///  <p>Returns the entity values this CRC is composed of.</p>
///  <p>When specifying a Virtual Source ID, it will treat the crcid as a virtual one, 
///  in the context of that vSrcId.</p>
Query GetValue(domainid As %Integer, crcid As %Integer, vSrcId As %Integer = 0) As %Library.Query(ROWSPEC = "head:%String(MAXLEN=32767),relation:%String(MAXLEN=32767),tail:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetValueExecute(ByRef qHandle As %Binary,  domainid As %Integer, crcid As %Integer, vSrcId As %Integer = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set value = ##class(%iKnow.Queries.CrcAPI).GetValue(domainid, crcid, vSrcId)
	set:value'="" ^||%IKQ.Result(r,1) = value
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetValueFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetValueExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetValueClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetValueExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

}
