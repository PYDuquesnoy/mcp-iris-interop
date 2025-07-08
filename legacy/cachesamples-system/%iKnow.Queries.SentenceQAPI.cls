/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.SentenceAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Queries.SentenceAPI</class> for more information.</p>
Class %iKnow.Queries.SentenceQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

/// <p>Returns all attributes for a given sentence. By default, only entity-level attributes are
/// returned, with the <i>wordPositions</i> result column referring which words within the affected
/// entities are actually attributed. Using <var>pIncludePathAttributes</var>, also path-level
/// attributes (such as implied negation) can be returned, but these will have no values for the
/// <i>wordPositions</i> column. Also note that the <i>start</i> and <i>span</i> columns for
/// path-level results will refer to positions within those paths and not entity positions within
/// the sentence. See also <method>GetAttributes</method> in <class>%iKnow.Queries.PathAPI</class>
/// and <method>GetOccurrenceAttributes</method> in <class>%iKnow.Queries.EntityAPI</class>.</p>
/// <p>Any named attribute properties are also
/// included through sub-nodes (not available through SQL or SOAP): 
/// <blockquote>pResult(<i>rowNumber</i>, <i>propertyName</i>) = <i>propertyValue</i></blockquote></p>
/// <p>The returned <var>wordPositions</var> apply to the entities starting from <var>start</var>
/// up to <var>offset</var> and only extend to the last attributed word position (there might 
/// be more words within the entity).</p>
Query GetAttributes(pDomainId As %Integer, pSentId As %Integer, vSrcId As %Integer = 0, pIncludePathAttributes As %Boolean = 0) As %Library.Query(ROWSPEC = "attTypeId:%Integer,attType:%String(MAXLEN=32767),start:%Integer,span:%Integer,wordPositions:%String(MAXLEN=32767),properties:%String(MAXLEN=32767),level:%Integer") [ SqlProc ]
{
}

ClassMethod GetAttributesExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pSentId As %Integer, vSrcId As %Integer = 0, pIncludePathAttributes As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetAttributes("^||%IKQ.Result("_r_")", pDomainId, pSentId, vSrcId, pIncludePathAttributes)
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

/// <p>Retrieves all sentences containing the given CRC ids, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>crcidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByCrcIds(domainid As %Integer, crcidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767),sentId:%Integer,sentenceValue:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByCrcIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, crcidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetByCrcIds("^||%IKQ.Result("_r_")", domainid, $lfs(crcidlist), filter, page, pagesize, setop)
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

/// <p>Retrieves all sentences containing a CRC satisfying the given CRC Mask, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByCrcMask(domainid As %Integer, head As %String(MAXLEN=32767) = {$$$WILDCARD}, relation As %String(MAXLEN=32767) = {$$$WILDCARD}, tail As %String(MAXLEN=32767) = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767),sentId:%Integer,sentenceValue:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByCrcMaskExecute(ByRef qHandle As %Binary,  domainid As %Integer, head As %String(MAXLEN=32767) = {$$$WILDCARD}, relation As %String(MAXLEN=32767) = {$$$WILDCARD}, tail As %String(MAXLEN=32767) = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetByCrcMask("^||%IKQ.Result("_r_")", domainid, head, relation, tail, filter, page, pagesize, setop, pActualFormOnly)
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

/// <p>Retrieves all sentences containing the given CRCs, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByCrcs(domainid As %Integer, crclist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767),sentId:%Integer,sentenceValue:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByCrcsExecute(ByRef qHandle As %Binary,  domainid As %Integer, crclist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetByCrcs("^||%IKQ.Result("_r_")", domainid, $lfs(crclist), filter, page, pagesize, setop)
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

/// <p>This method will retrieve all sentences containing any (if <i>setop</i> = $$$UNION) or all
/// (if <i>setop</i> = $$$INTERSECT) of the entities supplied through <i>entitylist</i>, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sentences containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sentences containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
Query GetByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767),sentId:%Integer,sentenceValue:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByEntitiesExecute(ByRef qHandle As %Binary,  domainid As %Integer, entitylist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetByEntities("^||%IKQ.Result("_r_")", domainid, $lfs(entitylist), filter, page, pagesize, setop, pActualFormOnly)
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

/// <p>Retrieves all sentences containing the given entity IDs., optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>entityidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767),sentId:%Integer,sentenceValue:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByEntityIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, entityidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetByEntityIds("^||%IKQ.Result("_r_")", domainid, $lfs(entityidlist), filter, page, pagesize, setop, pActualFormOnly)
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

/// <p>Retrieves all sentences containing the given path IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
Query GetByPathIds(domainid As %Integer, pathidlist As %String(MAXLEN=32767), sourceidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "srcId:%Integer,externalId:%String(MAXLEN=32767),sentId:%Integer,sentenceValue:%String(MAXLEN=32767)") [ SqlProc ]
{
}

ClassMethod GetByPathIdsExecute(ByRef qHandle As %Binary,  domainid As %Integer, pathidlist As %String(MAXLEN=32767), sourceidlist As %String(MAXLEN=32767), page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetByPathIds("^||%IKQ.Result("_r_")", domainid, $lfs(pathidlist), $lfs(sourceidlist), page, pagesize)
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

/// Returns the sentences for the given source. A negative source ID is interpreted as a Virtual Source.
Query GetBySource(domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "sentId:%Integer,sentenceValue:%String(MAXLEN=32767),sentenceIsTruncated:%Boolean") [ SqlProc ]
{
}

ClassMethod GetBySourceExecute(ByRef qHandle As %Binary,  domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetBySource("^||%IKQ.Result("_r_")", domainid, sourceid, page, pagesize)
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

/// <p>Retrieves the number of sentences containing the given CRC ids, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>crcidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcIds(domainid As %Integer, crcidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByCrcIds(domainid, $lfs(crcidlist), filter, setop, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing a CRC satisfying the given CRC Mask, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcMask(domainid As %Integer, head As %String(MAXLEN=32767) = {$$$WILDCARD}, relation As %String(MAXLEN=32767) = {$$$WILDCARD}, tail As %String(MAXLEN=32767) = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByCrcMask(domainid, head, relation, tail, filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing the given CRCs, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcs(domainid As %Integer, crclist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByCrcs(domainid, $lfs(crclist), filter, setop, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the total number of sentences for a given domain, optionally filtered to those sources
/// satisfying a <class>%iKnow.Filters.Filter</class> object passed in through <i>filter</i>.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "", Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByDomain(domainid, filter, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing the given entities, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByEntities(domainid, $lfs(entitylist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Retrieves the nubmer of sentences containing the given entity ids.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>entityidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sources containing any actual
/// form of the entities in <var>entityidlist</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sources containing the actual forms in <var>entityidlist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %String(MAXLEN=32767), filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, Output scText As %String = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByEntityIds(domainid, $lfs(entityidlist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing the given path IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByPathIds(domainid As %Integer, pathidlist As %String(MAXLEN=32767), sourceidlist As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByPathIds(domainid, $lfs(pathidlist), $lfs(sourceidlist), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Returns the total number of sentences for the given sources. Negative Source IDs are
/// interpreted as referring to Virtual Sources.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %String(MAXLEN=32767), Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountBySource(domainid, $lfs(sourceidlist), .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

/// <p>Retrieves the language of the given sentence, as derived by the Automatic Language Identification
/// algorithm or, if ALI was disabled, the language specified when indexing this sentence.</p>
/// <p>The confidence level is returned as well through an output parameter.
/// If the confidence level is 0, this means ALI was not used and the language was defined by the
/// user loading the source.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
ClassMethod GetLanguage(domainid As %Integer, sentenceid As %Integer, Output confidence As %Numeric = "", vSrcId As %Integer = 0) As %Library.String [ SqlProc ]
{
	quit ##class(%iKnow.Queries.SentenceAPI).GetLanguage(domainid, sentenceid, .confidence, vSrcId)
}

/// <p>Retrieves the sentences with the most significant concepts compared to the rest of the domain
/// (or optionally a subset thereof as filtered through <i>filter</i>). This array of sentences is
/// based on results of the GetNewBySource query in <class>%iKnow.Queries.EntityAPI</class>, using
/// the supplied algorithm and parameter values. The scores of the first [<i>newEntitiesWindow</i>]
/// concepts are aggregated across sentences to produce the result of this query.</p>
/// <p>Please refer to the documentation of the GetNewBySource query in
/// <class>%iKnow.Queries.EntityAPI</class> for more details on the parameters and available algorithms.</p>
Query GetNewBySource(domainid As %Integer, sourceid As %Integer, length As %Integer = 5, filter As %String(MAXLEN=32767) = "", algorithm As %String(MAXLEN=32767) = {$$$NEWENTSIMPLE}, algorithmParams As %String(MAXLEN=32767) = "", newEntitiesWindow As %Integer = 100, skipListIds As %String(MAXLEN=32767) = "") As %Library.Query(ROWSPEC = "sentId:%Integer,sentenceValue:%String(MAXLEN=32767),score:%Numeric") [ SqlProc ]
{
}

ClassMethod GetNewBySourceExecute(ByRef qHandle As %Binary,  domainid As %Integer, sourceid As %Integer, length As %Integer = 5, filter As %String(MAXLEN=32767) = "", algorithm As %String(MAXLEN=32767) = {$$$NEWENTSIMPLE}, algorithmParams As %String(MAXLEN=32767) = "", newEntitiesWindow As %Integer = 100, skipListIds As %String(MAXLEN=32767) = "") As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetNewBySource("^||%IKQ.Result("_r_")", domainid, sourceid, length, filter, algorithm, $lfs(algorithmParams), newEntitiesWindow, $lfs(skipListIds))
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetNewBySourceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetNewBySourceExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetNewBySourceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetNewBySourceExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns the literal of the entity or nonrelevant at the specified position.
ClassMethod GetPartLiteral(domainId As %Integer, sentenceId As %Integer, position As %Integer, vSrcId As %Integer = 0) As %Library.String [ SqlProc ]
{
	quit ##class(%iKnow.Queries.SentenceAPI).GetPartLiteral(domainId, sentenceId, position, vSrcId)
}

/// <p>Returns the elements (concepts, relations and nonrelevants) that make up the sentence,
/// optional including markers for the beginning and end of any CRCs or Paths in the sentence. This
/// information can be used to display the sentence value (see also <method>GetValue</method>)
/// and/or highlight specific elements of interest.</p>
/// <blockquote>Output structure: 
/// <pre>result(pos) = $lb(entOccId, entUniId, entity, role)</pre>
/// when includeCRCMarkers = 1, adds 
/// <pre>result(pos, [CRCHEAD | CRCRELATION | CRCTAIL]) = $lb(crcOccId, crcUniId)</pre>
/// when includePathMarkers = 1, adds 
/// <pre>result(pos, [PATHBEGIN | PATHEND]) = $lb(pathId)</pre>
/// </blockquote>
/// <p>Note: the subscript levels for CRC and Path markers are not available in the QAPI and WSAPI
/// versions of this query.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
Query GetParts(domainid As %Integer, sentenceid As %Integer, includeCRCMarkers As %Boolean = 0, includePathMarkers As %Boolean = 0, vSrcId As %Integer = 0) As %Library.Query(ROWSPEC = "entOccId:%Integer,entUniId:%Integer,literal:%String(MAXLEN=32767),role:%Integer,stemUniId:%Integer") [ SqlProc ]
{
}

ClassMethod GetPartsExecute(ByRef qHandle As %Binary,  domainid As %Integer, sentenceid As %Integer, includeCRCMarkers As %Boolean = 0, includePathMarkers As %Boolean = 0, vSrcId As %Integer = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.SentenceAPI).GetParts("^||%IKQ.Result("_r_")", domainid, sentenceid, includeCRCMarkers, includePathMarkers, vSrcId)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetPartsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetPartsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetPartsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetPartsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns the position within the source this sentence occurs at (1-based).
ClassMethod GetPosition(domainId As %Integer, sentenceId As %Integer, vSrcId As %Integer = 0) As %Library.Integer [ SqlProc ]
{
	quit ##class(%iKnow.Queries.SentenceAPI).GetPosition(domainId, sentenceId, vSrcId)
}

/// Returns the source ID in which the supplied sentence ID occurs
ClassMethod GetSourceId(domainId As %Integer, sentenceId As %Integer) As %Library.Integer [ SqlProc ]
{
	quit ##class(%iKnow.Queries.SentenceAPI).GetSourceId(domainId, sentenceId)
}

/// <p>This method rebuilds a sentence based on the literals and entities it is composed of.</p>
/// <p>The string returned is the first part, up to the maximum string length, whereas the 
/// output parameter <i>fullSentence</i> is an array containing all the parts in the right order, containing
/// a %Boolean value at the top level indicating whether the returned string is the full sentence (1)
/// or (if 0) the user should have to look into this array to learn the full sentence.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
ClassMethod GetValue(domainid As %Integer, sentenceid As %Integer, Output fullSentence As %Boolean = 1, vSrcId As %Integer = 0) As %Library.String [ SqlProc ]
{
	quit ##class(%iKnow.Queries.SentenceAPI).GetValue(domainid, sentenceid, .fullSentence, vSrcId)
}

}
