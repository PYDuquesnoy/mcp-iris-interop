/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.CcAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Queries.CcAPI</class> for more information.</p>
Class %iKnow.Queries.CcQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

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
Query GetByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "HeadEntUniId:%Integer,HeadEntity:%String(MAXLEN=32767),TailEntUniId:%Integer,TailEntity:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer,ccUniId:%Integer") [ SqlProc ]
{
}

ClassMethod GetByEntitiesExecute(ByRef qHandle As %Binary,  domainid As %Integer, entitylist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CcAPI).GetByEntities("^||%IKQ.Result("_r_")", domainid, $lfs(entitylist), page, pagesize, filter, filtermode, positionstomatch, sorttype, pActualFormOnly)
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

/// <p>This method looks up CCs based on a list of Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "HeadEntUniId:%Integer,HeadEntity:%String(MAXLEN=32767),TailEntUniId:%Integer,TailEntity:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer,ccUniId:%Integer") [ SqlProc ]
{
}

ClassMethod GetByEntityIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, entityidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.CcAPI).GetByEntityIds("^||%IKQ.Result("_r_")", domainid, $lfs(entityidlist), page, pagesize, filter, filtermode, positionstomatch, sorttype, pActualFormOnly)
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

/// <p>This method returns the number of CC pairs based on a list of entities.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", positionstomatch As %Integer = {$$$USEPOSHT}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetCountByEntities(domainid, $lfs(entitylist), filter, positionstomatch, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>This method returns the number of CC pairs based on a list of entity ids.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", positionstomatch As %Integer = {$$$USEPOSHT}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetCountByEntityIds(domainid, $lfs(entityidlist), filter, positionstomatch, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the total number of unique CCs appearing in either (if <var>setop</var> = $$$UNION) or
///  all (if <var>setop</var> = $$$INTERSECT) of the sources specified by ID in <var>sourceidlist</var>.</p>
///  <p>To get the unique CCs of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %String(MAXLEN=32767), setop As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetCountBySource(domainid, $lfs(sourceidlist), setop, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the frequency of the CC corresponding to the supplied <var>crcUniId</var>.</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetFrequency(domainId As %Integer, ccUniId As %Integer, vSrcId As %Integer = 0, filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetFrequency(domainId, ccUniId, vSrcId, filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns, if any, the CC ID for the combination of head and tail specified.</p>
///  <p>When specifying a Virtual Source ID, it will treat the heads and tails as virtual
///  entities, in the context of that vSrcId.</p>
ClassMethod GetId(pDomainId As %Integer, pHead As %String(MAXLEN=32767), pTail As %String(MAXLEN=32767), vSrcId As %Integer = 0, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetId(pDomainId, pHead, pTail, vSrcId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// Returns the "inverse" of a CC pair, which means the CC composed of the same
/// head and tail entity, but at inverted positions.
ClassMethod GetInverse(domainId As %Integer, ccUniId As %Integer, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetInverse(domainId, ccUniId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the spread of the CC corresponding to the supplied <var>ccUniId</var>.</p>
ClassMethod GetSpread(domainId As %Integer, ccUniId As %Integer, filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetSpread(domainId, ccUniId, filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Returns the entity values this CC is composed of.</p>
///  <p>When specifying a Virtual Source ID, it will treat the ccid as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetValue(pDomainId As %Integer, pCcId As %Integer, vSrcId As %Integer = 0, Output scText As %String = "") As %String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.CcAPI).GetValue(pDomainId, pCcId, vSrcId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

}
