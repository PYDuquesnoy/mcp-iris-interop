/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.SourceAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Queries.SourceAPI</class> for more information.</p>
Class %iKnow.Queries.SourceQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

/// <p>Returns all the attributes of the Entity Occurrences, Paths and Sentences enclosed in the
/// specified source, optionally filtered by level through <var>pLevel</var> and/or <var>pType</var>.</p>
/// <p>Please note the <i>startPos</i> and <i>span</i> result columns refer to positions within
/// the path for path-level attributes (level=$$$IKATTLVLPATH) and sentence positions for the
/// other attributes (level=$$$IKATTLVLSENT).</p>
Query GetAttributes(pDomainId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pTypes As %String(MAXLEN=32767) = "", pLevel As %Integer = {$$$IKATTLVLANY}) As %Library.Query(ROWSPEC = "attTypeId:%Integer,attType:%String(MAXLEN=32767),level:%Integer,targetId:%Integer,startPos:%Integer,span:%Integer,properties:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetAttributesExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pTypes As %String(MAXLEN=32767) = "", pLevel As %Integer = {$$$IKATTLVLANY}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetAttributes("^||%IKQ.Result("_r_")", pDomainId, pSrcId, pPage, pPageSize, $lfs(pTypes), pLevel)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetAttributesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetAttributesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetAttributesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetAttributesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves all sources containing the given CRC ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByCrcIds(domainid As %Integer, crcidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, sortByField As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByCrcIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, crcidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, sortByField As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByCrcIds("^||%IKQ.Result("_r_")", domainid, $lfs(crcidlist), page, pagesize, filter, setop, sortByField)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByCrcIdsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByCrcIdsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByCrcIdsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByCrcIdsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves all sources containing a CRC satisfying the given CRC Mask.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByCrcMask(domainid As %Integer, head As %String(MAXLEN=32767) = {$$$WILDCARD}, relation As %String(MAXLEN=32767) = {$$$WILDCARD}, tail As %String(MAXLEN=32767) = {$$$WILDCARD}, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByCrcMaskExecute(ByRef qHandle As %Binary,  domainid As %Integer, head As %String(MAXLEN=32767) = {$$$WILDCARD}, relation As %String(MAXLEN=32767) = {$$$WILDCARD}, tail As %String(MAXLEN=32767) = {$$$WILDCARD}, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByCrcMask("^||%IKQ.Result("_r_")", domainid, head, relation, tail, page, pagesize, filter, sortByField, pActualFormOnly)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByCrcMaskFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByCrcMaskExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByCrcMaskClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByCrcMaskExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves all sources containing the given CRCs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByCrcs(domainid As %Integer, crclist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, sortByField As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByCrcsExecute(ByRef qHandle As %Binary,  domainid As %Integer, crclist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, sortByField As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByCrcs("^||%IKQ.Result("_r_")", domainid, $lfs(crclist), page, pagesize, filter, setop, sortByField)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByCrcsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByCrcsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByCrcsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByCrcsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Returns all sources within a domain, optionally filtered through
///  a <class>%iKnow.Filters.Filter</class> object passed in as <i>filter</i>.</p> 
Query GetByDomain(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByDomainExecute(ByRef qHandle As %Binary,  domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByDomain("^||%IKQ.Result("_r_")", domainid, page, pagesize, filter, sortByField)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByDomainFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByDomainExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByDomainClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByDomainExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>This method will retrieve all sources containing any (if <var>setop</var> = $$$UNION) or all (if <var>setop</var> = 
///  $$$INTERSECT) of the entities supplied through <var>entitylist</var>.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class>
///  object for the <var>filter</var> parameter to restrict the result to those sources satisfying the
///  filter criteria.</p>
///  <p>By default, results are ordered by decreasing source id. You can override this by setting
///  <var>sortByField</var> to the name of a metadata field (optionally appended with " ASC" or " DESC"
/// for this domain to order by that field's value. </p>
/// <p>The <var>attributeFilter</var> argument can be used to filter the results to only those where
/// the requested entities (<var>entitylist</var>) appear in the context of a particular (set of)
/// attribute(s). By using the negative attribute ID, you can select only those occurrences NOT 
/// appearing in the context of that attribute. For example, passing in $lb($$$IKATTNEGATION) will restrict the result to only those
/// entities in a negative context and $lb(-$$$IKATTNEGATION) the ones in an affirmative context.
/// Note that the use of this argument may have a significant performance impact.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sources containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sources containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
Query GetByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, attributeFilter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByEntitiesExecute(ByRef qHandle As %Binary,  domainid As %Integer, entitylist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, attributeFilter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByEntities("^||%IKQ.Result("_r_")", domainid, $lfs(entitylist), page, pagesize, filter, setop, $lfs(attributeFilter), sortByField, pActualFormOnly)
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

///  <p>Retrieves all sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, attributeFilter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByEntityIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, entityidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, attributeFilter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByEntityIds("^||%IKQ.Result("_r_")", domainid, $lfs(entityidlist), page, pagesize, filter, setop, $lfs(attributeFilter), sortByField, pActualFormOnly)
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

/// Deprecated
Query GetByEquivalentIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ Deprecated, Internal, SqlProc ]
{
}

ClassMethod GetByEquivalentIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, entityidlist As %String(MAXLEN=32767), setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByEquivalentIds("^||%IKQ.Result("_r_")", domainid, $lfs(entityidlist), setid, page, pagesize, filter)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByEquivalentIdsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByEquivalentIdsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByEquivalentIdsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByEquivalentIdsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Deprecated
Query GetByEquivalents(domainid As %Integer, entitylist As %String(MAXLEN=32767), setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ Deprecated, Internal, SqlProc ]
{
}

ClassMethod GetByEquivalentsExecute(ByRef qHandle As %Binary,  domainid As %Integer, entitylist As %String(MAXLEN=32767), setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByEquivalents("^||%IKQ.Result("_r_")", domainid, $lfs(entitylist), setid, page, pagesize, filter)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByEquivalentsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByEquivalentsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByEquivalentsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByEquivalentsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves all sources containing the given path ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByPathIds(domainid As %Integer, pathidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByPathIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, pathidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetByPathIds("^||%IKQ.Result("_r_")", domainid, $lfs(pathidlist), page, pagesize, filter, sortByField)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetByPathIdsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetByPathIdsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetByPathIdsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetByPathIdsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves the number of sources containing the given CRC ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcIds(domainid As %Integer, crcidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcIds(domainid, $lfs(crcidlist), filter, setop, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the number of sources containing a CRC satisfying the given CRC Mask.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcMask(domainid As %Integer, head As %String(MAXLEN=32767) = {$$$WILDCARD}, relation As %String(MAXLEN=32767) = {$$$WILDCARD}, tail As %String(MAXLEN=32767) = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcMask(domainid, head, relation, tail, filter, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given CRCs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcs(domainid As %Integer, crclist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcs(domainid, $lfs(crclist), filter, setop, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>This method returns the total number of sources in the specified domain, optionally filtered
///  through a <class>%iKnow.Filters.Filter</class> object passed in as <i>filter</i>.</p> 
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(domainid, filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given entities.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByEntities(domainid, $lfs(entitylist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByEntityIds(domainid, $lfs(entityidlist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given path ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByPathIds(domainid As %Integer, pathidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByPathIds(domainid, $lfs(pathidlist), filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the external ID for the source identified by <i>srcId</i>.</p>
///  <p>A negative srcId is considered to refer to a Virtual Source.</p>
ClassMethod GetExternalId(domainid As %Integer, srcId As %Integer, Output scText As %String = "") As %Library.String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, srcId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>Retrieves the Full Reference for the source identified by <i>srcId</i>.</p>
///  <p>A negative srcId is considered to refer to a Virtual Source.</p>
ClassMethod GetFullReference(domainId As %Integer, srcId As %Integer, Output scText As %String = "") As %Library.String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetFullReference(domainId, srcId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>This method returns, for a given source, all languages the iKnow Automatic Language
///  Identification algorithm has identified for the sentences it contains. For each language, it will
///  list the sum of ALI confidence ratings when assigning the language to a sentence, plus the total
///  number of sentences the language was assigned to. If ALI was disabled when indexing this
///  source, confidence ratings will be set to 0.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
Query GetLanguages(domainid As %Integer, sourceid As %Integer) As %Library.Query(ROWSPEC = "language:%String(MAXLEN=32767),totalConfidence:%Numeric,sentenceCount:%Integer") [ SqlProc ]
{
}

ClassMethod GetLanguagesExecute(ByRef qHandle As %Binary,  domainid As %Integer, sourceid As %Integer) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetLanguages("^||%IKQ.Result("_r_")", domainid, sourceid)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetLanguagesFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetLanguagesExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetLanguagesClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetLanguagesExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves those sources that have similar content to the one specified
///  through the <i>sourceId</i> parameter. Similarity is expressed by the (approximated)
///  ratio between the length of the source and the overlap with the starting source, based on the
///  chosen <i>algorithm</i> (according to the algorithm-specific <i>algorithmParams</i>).</p>
///  <p><b>Note:</b> whenever possible, use a filter object to limit the search space for this query to perform
///  adequately.</p>
///  <p>If the supplied Source ID is negative, it is treated as a Virtual Source. While this allows
///  looking for sources similar to a Virtual Source, the query will not verify against other 
///  Virtual Sources and they will therefore not appear in the results of this query.</p>
///  <p>The <i>skipListIds</i> parameter allows a user to select one or more SkipLists of which the elements 
///  should be completely ignored in the similarity algorithm. Skiplisted elements will be ignored
///  both for selecting similar candidates AND the calculation of their similarity score.</p>
/// 
///  <p>The following algorithms are currently available:</p>
///  <ul>
///  	<li>$$$SIMSRCSIMPLE: basic algorithm simply looking at entities (or CRCs or CCs) 
/// 				present in the reference source.<br/>Parameters:<ol>
///  			<li>targetType As %String - either "ent", "crc" or "cc" (case insensitive,
/// 				defaults to "ent"). Please note this implies the result columns will
/// 					represent the corresponding targets, despite being named "nbOf<i>Ent</i>***"</li>
/// 				</ol></li>
///  	<!--li>$$$SIMSRCEQUIVS: similar to $$$SIMSRCSIMPLE, but also taking into account equivalent terms.
///  			<br/>Parameters:<ol>
///  			<li>equivSetId As %Integer - equivalency set ID</li>
///  			</ol></li-->
///  	<li>$$$SIMSRCDOMENTS starts looking for similar sources based on dominant terms
///  			in the reference source.<br/>Parameters:<ol>
///  			<li>strict As %Boolean - whether or not to select only sources for which at least one of
///  			the reference source's dominant concepts are also dominant in a similar source. (defaults to 1)</li>
///  			</ol></li>
///  </ul>
Query GetSimilar(domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", algorithm As %String(MAXLEN=32767) = {$$$SIMSRCSIMPLE}, algorithmParams As %String(MAXLEN=32767) = "", skipListIds As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "srcId:%Integer,extId:%String(MAXLEN=32767),percentageMatched:%Numeric,percentageNew:%Numeric,nbOfEntsInRefSrc:%Integer,nbOfEntsInCommon:%Integer,nbOfEntsInSimSrc:%Integer,score:%Numeric") [ SqlProc ]
{
}

ClassMethod GetSimilarExecute(ByRef qHandle As %Binary,  domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", algorithm As %String(MAXLEN=32767) = {$$$SIMSRCSIMPLE}, algorithmParams As %String(MAXLEN=32767) = "", skipListIds As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetSimilar("^||%IKQ.Result("_r_")", domainid, sourceid, page, pagesize, filter, algorithm, $lfs(algorithmParams), $lfs(skipListIds))
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetSimilarFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetSimilarExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetSimilarClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetSimilarExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>Retrieves the source ID for the source identified by <i>externalId</i>.</p>
ClassMethod GetSourceId(domainid As %Integer, externalId As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetSourceId(domainid, externalId, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>This method returns the most relevant sentences of the requested source, in their original order.
///  The number of sentences returned is controlled by the <var>length</var> parameter.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
Query GetSummary(domainId As %Integer, srcId As %Integer, length As %Integer = 5, summaryConfig As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "sentId:%Integer,sentenceValue:%String(MAXLEN=32767),sentenceIsTruncated:%Boolean") [ SqlProc ]
{
}

ClassMethod GetSummaryExecute(ByRef qHandle As %Binary,  domainId As %Integer, srcId As %Integer, length As %Integer = 5, summaryConfig As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetSummary("^||%IKQ.Result("_r_")", domainId, srcId, length, summaryConfig)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetSummaryFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetSummaryExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetSummaryClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetSummaryExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>This is a utility wrapper method around <method>GetSummary</method>, returning the summary
///  sentences as a single concatenated string.</p>
///  <p>The <i>isTruncated</i> output parameter indicates whether or not the
///  returned string is complete or was truncated to avoid MAXSTRING errors. This can happen when either
///  an individual sentence surpassed the maximum string length or when the concatenation of these
///  sentences surpassed it.</p>
ClassMethod GetSummaryDirect(domainId As %Integer, sourceId As %Integer, length As %Integer = 5, Output isTruncated As %Boolean = 0, Output scText As %String = "", separator As %String(MAXLEN=32767) = " ... ", summaryConfig As %String(MAXLEN=32767) = "") As %Library.String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetSummaryDirect(domainId, sourceId, length, .isTruncated, .sc, separator, summaryConfig)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

///  <p>This method returns the most relevant sentences of the supplied text, in their original order.
///  The number of sentences returned is controlled by the <var>length</var> parameter.</p>
/// <p>Note: the value of <var>pDomainId</var> is ignored since 2013.2</p>
Query GetSummaryForText(pDomainId As %Integer = 0, pText As %String(MAXLEN=32000), pLength As %Integer = 5, pSummaryConfig As %String(MAXLEN=32767) = "", pLanguage As %String(MAXLEN=32767) = "en", pUserDict As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "sentId:%Integer,sentenceValue:%String(MAXLEN=32767),sentenceIsTruncated:%Boolean") [ SqlProc ]
{
}

ClassMethod GetSummaryForTextExecute(ByRef qHandle As %Binary,  pDomainId As %Integer = 0, pText As %String(MAXLEN=32000), pLength As %Integer = 5, pSummaryConfig As %String(MAXLEN=32767) = "", pLanguage As %String(MAXLEN=32767) = "en", pUserDict As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SourceAPI).GetSummaryForText("^||%IKQ.Result("_r_")", pDomainId, pText, pLength, pSummaryConfig, pLanguage, pUserDict)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetSummaryForTextFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetSummaryForTextExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetSummaryForTextClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetSummaryForTextExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

///  <p>This method returns the language of a given source, calculated as the one with the 
///  highest total confidence rating for the individual sentences in the source. This total 
///  confidence, as well as the number of sentences to which this language was assigned
///  is provided through output variables <i>totalConfidence</i> and <i>numberOfSentences</i>.</p>
///  <p>A <i>totalConfidence</i> of 0 indicates ALI was switched off when indexing this source.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetTopLanguage(domainid As %Integer, sourceid As %Integer, Output totalConfidence As %Numeric = "", Output numberOfSentences As %Integer = "", Output scText As %String = "") As %Library.String [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetTopLanguage(domainid, sourceid, .totalConfidence, .numberOfSentences, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

}
