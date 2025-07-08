/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.EntityAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Queries.EntityAPI</class> for more information.</p>
Class %iKnow.Queries.EntityWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

///  <p>Returns all entities appearing in any source satisfying the supplied <var>filter</var> 
///  objects criteria, with their frequencies and spread recalculated to comply with the filter
///  depending on the value of <var>filtermode</var>, but the result is NOT re-sorted, regardless
///  of the value for <var>filtermode</var> (use <method>GetTop</method> if you want sorted results).</p>
///  <p>Depending on the value of <var>enttype</var> parameter, this method will only return concepts
///  ($$$ENTTYPECONCEPT, default), relations ($$$ENTTYPERELATION) or both ($$$ENTTYPEANY).</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetByFilter(domainid As %Integer, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, enttype As %Integer = {$$$ENTTYPECONCEPT}, skipListIds As %ListOfDataTypes = "", pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set filtermode = $s($g(filtermode)="":$$$FILTERONLY, 1:filtermode)
	set enttype = $s($g(enttype)="":$$$ENTTYPECONCEPT, 1:enttype)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetByFilter")
	set tSC = data.Execute(domainid, filter, filtermode, enttype, $lts(..ListToListBuild(skipListIds)), pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the unique entities appearing in the sources specified.</p>
///  <p>To get the unique entities of a virtual source, only a single virtual source can be supplied using
///  its negative ID value.</p>
ClassMethod GetBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, enttype As %Integer = {$$$ENTTYPEANY}, skipListIds As %ListOfDataTypes = "", pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set enttype = $s($g(enttype)="":$$$ENTTYPEANY, 1:enttype)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetBySource")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(sourceidlist)), page, pagesize, enttype, $lts(..ListToListBuild(skipListIds)), pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Retrieves all entities corresponding to a certain stem identified by <var>pStemUniId</var>.
ClassMethod GetByStem(pDomainId As %Integer, pStemUniId As %Integer, vSrcId As %Integer = 0, pLanguage As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetByStem")
	set tSC = data.Execute(pDomainId, pStemUniId, vSrcId, pLanguage)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the total number of distinct entities for this domain, optionally filtered to a set of
///  sources satisfying the <class>%iKnow.Filters.Filter</class> object supplied through <var>filter</var>.
///  Depending on the value of <var>includeZeroFrequency</var>, entities not appearing in any source (but
///  registered in the domain for other purposes) are included or excluded from the result.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "", skipListIds As %ListOfDataTypes = "", includeZeroFrequency As %Boolean = 0, pUseStems As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set includeZeroFrequency = $s($g(includeZeroFrequency)="":0, 1:includeZeroFrequency)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetCountByDomain(domainid, filter, .sc, ..ListToListBuild(skipListIds), includeZeroFrequency, pUseStems)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the total number of distinct entities for a given list of sources. The count returned either
///  represents the entities appearing in either (with <var>setop</var> $$$UNION) or all (with <var>setop</var>
///  $$$INTERSECT) of the supplied sources. Using <var>enttype</var>, the returned count is
///  filtered to just entities ($$$ENTTYPECONCEPT), relations ($$$ENTTYPERELATION). The default
///  is unfiltered ($$$ENTTYPEANY).</p>
///  <p>To get the unique entities of a virtual source, only a single virtual source can be supplied using
///  its negative ID value (otherwise, -1 is returned).</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes, setop As %Integer = {$$$UNION}, skipListIds As %ListOfDataTypes = "", enttype As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set enttype = $s($g(enttype)="":$$$ENTTYPEANY, 1:enttype)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetCountBySource(domainid, ..ListToListBuild(sourceidlist), setop, .sc, ..ListToListBuild(skipListIds), enttype, pUseStems)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the frequency of the entity corresponding to the supplied <var>entUniId</var>, occurring
///  in a concept role (if <var>enttype</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>enttype</var> = $$$ENTTYPERELATION) or both (<var>enttype</var> = $$$ENTTYPEANY).</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetFrequency(domainId As %Integer, entUniId As %Integer, enttype As %Integer = {$$$ENTTYPEANY}, vSrcId As %Integer = 0, filter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set enttype = $s($g(enttype)="":$$$ENTTYPEANY, 1:enttype)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetFrequency(domainId, entUniId, enttype, vSrcId, filter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the entity ID corresponding to the specified entity value, if any.</p>
///  <p>When specifying a Virtual Source ID, it will treat the entity as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetId(domainid As %Integer, entityvalue As %String, vSrcId As %Integer = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.EntityAPI).GetId(domainid, entityvalue, vSrcId)
}

/// <p>Returns the literal value for a particular <i>Part ID</i>, as it
/// occurred in the original text.</p>
ClassMethod GetLiteral(pDomainId As %Integer, pPartId As %Integer, vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.EntityAPI).GetLiteral(pDomainId, pPartId, vSrcId)
}

///  <p>Retrieves the significant entities in a list of sources supplied through <var>sourceidlist</var>,
///  as compared to the other sources in the domain (optionally filtered through a
///  <class>%iKnow.Filters.Filter</class> object specified through <var>filter</var>).</p>
///  <p>The following <var>algorithm</var> values are currently available:</p>
///  <ul>
///  		<li>$$$NEWENTSIMPLE - takes no parameters</li>
///  </ul>
///  <p>To get the significant entities of a virtual source compared to the non-virtual ones in the
///  domain, only a single virtual source can be supplied using its negative ID value.</p>
///  <p>Through the <var>enttype</var> parameter, the method can be instructed to return either concepts
///  ($$$ENTTYPECONCEPT) or relations ($$$ENTTYPERELATION).</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetNewBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", entType As %Integer = {$$$ENTTYPECONCEPT}, algorithm As %String = {$$$NEWENTSIMPLE}, algorithmParams As %ListOfDataTypes = "", skipListIds As %ListOfDataTypes = "", pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set entType = $s($g(entType)="":$$$ENTTYPECONCEPT, 1:entType)
	set algorithm = $s($g(algorithm)="":$$$NEWENTSIMPLE, 1:algorithm)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetNewBySource")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(sourceidlist)), page, pagesize, filter, entType, algorithm, $lts(..ListToListBuild(algorithmParams)), $lts(..ListToListBuild(skipListIds)), pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns all attributes for a given part. Any named attribute properties are also
/// included through sub-nodes (not available through SQL or SOAP): 
/// <blockquote>pResult(<i>rowNumber</i>, <i>propertyName</i>) = <i>propertyValue</i></blockquote></p>
/// <p>The returned <var>wordPositions</var> only extend to the last attributed word position
/// (there might be more words within the entity).</p>
ClassMethod GetOccurrenceAttributes(pDomainId As %Integer, pPartId As %Integer, vSrcId As %Integer = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetOccurrenceAttributes")
	set tSC = data.Execute(pDomainId, pPartId, vSrcId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the total number of entity occurrences in a domain.</p>
ClassMethod GetOccurrenceCountByDomain(pDomainId As %Integer, pFilter As %String(MAXLEN=32767) = "", pEntType As %Integer = {$$$ENTTYPEANY}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pEntType = $s($g(pEntType)="":$$$ENTTYPEANY, 1:pEntType)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountByDomain(pDomainId, pFilter, pEntType, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the total number of entity occurrences for the given list of sources. Use negative source
///  IDs to refer to virtual sources.</p>
ClassMethod GetOccurrenceCountBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes, enttype As %Integer = {$$$ENTTYPEANY}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set enttype = $s($g(enttype)="":$$$ENTTYPEANY, 1:enttype)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetOccurrenceCountBySource(domainid, ..ListToListBuild(sourceidlist), .sc, enttype)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns all occurrences for any of the given unique entities in <var>pEntUniIds</var>,
/// including whether the attribute <var>pAttributeId</var> is applicable to this occurrence.</p>
/// <p>If this domain is configured for stemming using $$$IKPSTEMMING, any actual entities corresponding
/// to <var>pEntUniIds</var> elements will be returned.</p>
ClassMethod GetOccurrencesById(pDomainId As %Integer, pEntUniIds As %ListOfDataTypes, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pAttributeId As %Integer = {$$$IKATTNEGATION}, vSrcId As %Integer = 0, pIncludeActualForms As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pAttributeId = $s($g(pAttributeId)="":$$$IKATTNEGATION, 1:pAttributeId)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)
	set pIncludeActualForms = $s($g(pIncludeActualForms)="":0, 1:pIncludeActualForms)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetOccurrencesById")
	set tSC = data.Execute(pDomainId, $lts(..ListToListBuild(pEntUniIds)), pPage, pPageSize, pFilter, pAttributeId, vSrcId, pIncludeActualForms)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>This method will return all entities occurring in a direct relationship with at least on (if <var>setop</var> = $$$UNION)
///  or all (if <var>setop</var> = $$$INTERSECT) of the entities in the supplied <var>entitylist</var>, anywhere within
///  the supplied domain.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Through the <var>positionstomatch</var> parameter, the user can specify whether the entities returned should be
///  occurring on the Head side ($$$USEPOSH), the Tail side ($$$USEPOST) or either ($$$USEPOSHT, default) 
///  side of the relationship.</p>
///  <p>The <var>aggregationtype</var> parameter lets you choose how to aggregate the frequency and spread of results
///  related to multiple entries in the input <var>entitylist</var>.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
/// <p>Note: this method only returns entities that appear in direct relationships with the seed
/// entity. For the broader context of entities, including indirect relationships (still within
/// a single path), please refer to <class>%iKnow.Semantics.ProximityAPI</class>
ClassMethod GetRelated(domainid As %Integer, entitylist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, aggregationtype As %Integer = {$$$AGGSUM}, setop As %Integer = {$$$UNION}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, skipListIds As %ListOfDataTypes = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set filtermode = $s($g(filtermode)="":$$$FILTERONLY, 1:filtermode)
	set positionstomatch = $s($g(positionstomatch)="":$$$USEPOSHT, 1:positionstomatch)
	set aggregationtype = $s($g(aggregationtype)="":$$$AGGSUM, 1:aggregationtype)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set sorttype = $s($g(sorttype)="":$$$SORTBYDOMAINDEFAULT, 1:sorttype)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetRelated")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entitylist)), page, pagesize, filter, filtermode, positionstomatch, aggregationtype, setop, sorttype, $lts(..ListToListBuild(skipListIds)))
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the entities directly related to a supplied list of entity IDs.</p>
///  <p>See <method>GetRelated</method> for a description of the parameters.</p>
ClassMethod GetRelatedById(domainid As %Integer, entityidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, positionstomatch As %Integer = {$$$USEPOSHT}, aggregationtype As %Integer = {$$$AGGSUM}, setop As %Integer = {$$$UNION}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, skipListIds As %ListOfDataTypes = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set filtermode = $s($g(filtermode)="":$$$FILTERONLY, 1:filtermode)
	set positionstomatch = $s($g(positionstomatch)="":$$$USEPOSHT, 1:positionstomatch)
	set aggregationtype = $s($g(aggregationtype)="":$$$AGGSUM, 1:aggregationtype)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set sorttype = $s($g(sorttype)="":$$$SORTBYDOMAINDEFAULT, 1:sorttype)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetRelatedById")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entityidlist)), page, pagesize, filter, filtermode, positionstomatch, aggregationtype, setop, sorttype, $lts(..ListToListBuild(skipListIds)))
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the number of related entities for a given list of entities.</p>
///  <p>See <method>GetRelated</method> for a description of the parameters.</p>
ClassMethod GetRelatedCount(domainid As %Integer, entitylist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", positionstomatch As %Integer = {$$$USEPOSHT}, setop As %Integer = {$$$UNION}, pIncludeActualForms As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set positionstomatch = $s($g(positionstomatch)="":$$$USEPOSHT, 1:positionstomatch)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pIncludeActualForms = $s($g(pIncludeActualForms)="":0, 1:pIncludeActualForms)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetRelatedCount(domainid, ..ListToListBuild(entitylist), filter, positionstomatch, setop, .sc, pIncludeActualForms)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the number of related entities for a given list of entity ids.</p>
///  <p>See <method>GetRelated</method> for a description of the parameters.</p>
ClassMethod GetRelatedCountById(domainid As %Integer, entityidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", positionstomatch As %Integer = {$$$USEPOSHT}, setop As %Integer = {$$$UNION}, pIncludeActualForms As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set positionstomatch = $s($g(positionstomatch)="":$$$USEPOSHT, 1:positionstomatch)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pIncludeActualForms = $s($g(pIncludeActualForms)="":0, 1:pIncludeActualForms)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetRelatedCountById(domainid, ..ListToListBuild(entityidlist), filter, positionstomatch, setop, .sc, pIncludeActualForms)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method will return all entities in the specified domain that are "similar" to the 
///  supplied <var>part</var> string. Similarity is defined using the <var>mode</var> parameter. The default setting
///  ($$$USEPARTS), will retrieve all clusters containing at least one word starting with the supplied
///  string, whereas $$$USENGRAMS will search for any character sequence within the whole entity.
///  With mode = $$$USEWORDS, the behavior is the same as $$$USEPARTS but the supplied <var>part</var>
///  needs to occur as a whole word in the retrieved clusters.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetSimilar(domainid As %Integer, part As %String, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, mode As %Integer = {$$$USEDOMAINDEFAULT}, skipListIds As %ListOfDataTypes = "", pEntRole As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set filtermode = $s($g(filtermode)="":$$$FILTERONLY, 1:filtermode)
	set mode = $s($g(mode)="":$$$USEDOMAINDEFAULT, 1:mode)
	set pEntRole = $s($g(pEntRole)="":$$$ENTTYPEANY, 1:pEntRole)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetSimilar")
	set tSC = data.Execute(domainid, part, page, pagesize, filter, filtermode, mode, $lts(..ListToListBuild(skipListIds)), pEntRole, pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>This method returns aggregated details on the entities similar to a supplied text fragment <var>part</var>.
///  The returned list contains the total number of distinct entities similar to <var>part</var> appearing
///  in sources satisfying the supplied <var>filter</var> (if defined), their total aggregated frequency 
///  (with respect to <var>filter</var>, if defined) and the total number of sources containing at least one of 
///  these "similar" entities (again, respecting <var>filter</var>, if defined).</p>
///  <p>See also <method>GetSimilar</method> for a description of the other parameters.</p>
///  <p>Setting the <var>entType</var> parameter to $$$ENTTYPECONCEPT or $$$ENTTYPERELATION will
///  restrict the result to only include entity occurrences of the specified type in the returned
///  number of distinct entities and aggregated frequency. If an entity occurs as both a concept
///  and a relationship (typically in &lt;1% of cases), it contributes to the aggregated spread
///  regardless of <var>entType</var>.</p>
ClassMethod GetSimilarCounts(domainid As %Integer, part As %String, filter As %String(MAXLEN=32767) = "", mode As %Integer = {$$$USEDOMAINDEFAULT}, skipListIds As %ListOfDataTypes = "", entType As %Integer = {$$$ENTTYPEANY}, pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set mode = $s($g(mode)="":$$$USEDOMAINDEFAULT, 1:mode)
	set entType = $s($g(entType)="":$$$ENTTYPEANY, 1:entType)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetSimilarCounts")
	set tSC = data.Execute(domainid, part, filter, mode, $lts(..ListToListBuild(skipListIds)), .sc, entType, pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns the spread of the entity corresponding to the supplied <var>entUniId</var>, occurring
///  in a concept role (if <var>enttype</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>enttype</var> = $$$ENTTYPERELATION) or both (<var>enttype</var> = $$$ENTTYPEANY).</p>
ClassMethod GetSpread(domainId As %Integer, entUniId As %Integer, enttype As %Integer = {$$$ENTTYPEANY}, filter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set enttype = $s($g(enttype)="":$$$ENTTYPEANY, 1:enttype)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetSpread(domainId, entUniId, enttype, filter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns the stemmed form of the supplied string <var>pString</var>. 
/// If <var>pDomainId</var> is non-null, any domain-level configuration settings will be used
/// for the stemming operation.
ClassMethod GetStem(pDomainId As %Integer = "", pString As %String, pLanguage As %String = "") As %Library.String [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.EntityAPI).GetStem(pDomainId, pString, pLanguage, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the frequency of the stem corresponding to the supplied <var>pStemUniId</var>, occurring
///  in a concept role (if <var>pEntType</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>pEntType</var> = $$$ENTTYPERELATION) or both (<var>pEntType</var> = $$$ENTTYPEANY).</p>
///  <p>When specifying a Virtual Source ID, the frequency within the virtual source will be returned.</p>
ClassMethod GetStemFrequency(pDomainId As %Integer, pStemUniId As %Integer, pEntType As %Integer = {$$$ENTTYPEANY}, vSrcId As %Integer = 0, pFilter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pEntType = $s($g(pEntType)="":$$$ENTTYPEANY, 1:pEntType)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetStemFrequency(pDomainId, pStemUniId, pEntType, vSrcId, pFilter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the stem ID corresponding to the specified stem value, if any.</p>
///  <p>When specifying a Virtual Source ID, it will treat the stem as a virtual one, 
///  in the context of that vSrcId.</p>
ClassMethod GetStemId(pDomainId As %Integer, pStemValue As %String, vSrcId As %Integer = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.EntityAPI).GetStemId(pDomainId, pStemValue, vSrcId)
}

/// Returns the representation form for the given stem and language 
ClassMethod GetStemRepresentationForm(pDomainId As %Integer, pStemUniId As %Integer, pLanguage As %String = "en", vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pLanguage = $s($g(pLanguage)="":"en", 1:pLanguage)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetStemRepresentationForm(pDomainId, pStemUniId, pLanguage, vSrcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Returns the spread of the stem corresponding to the supplied <var>pStemUniId</var>, occurring
///  in a concept role (if <var>pEntType</var> = $$$ENTTYPECONCEPT), a relationship role (if
///  <var>pEntType</var> = $$$ENTTYPERELATION) or both (<var>pEntType</var> = $$$ENTTYPEANY).</p>
ClassMethod GetStemSpread(pDomainId As %Integer, pStemUniId As %Integer, pEntType As %Integer = {$$$ENTTYPEANY}, pFilter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pEntType = $s($g(pEntType)="":$$$ENTTYPEANY, 1:pEntType)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetStemSpread(pDomainId, pStemUniId, pEntType, pFilter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns the string value of the stem identified by <var>pStemUniId</var>
ClassMethod GetStemValue(pDomainId As %Integer, pStemUniId As %Integer, vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetStemValue(pDomainId, pStemUniId, vSrcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method returns the most frequently occurring entities in the specified domain.</p>
///  <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <var>filter</var>
///  parameter to restrict the result to those CRCs occurring in any source satisfying the filter
///  criteria. When using a filter, the <var>filtermode</var> parameter will control whether or not the
///  frequency and spread of returned records should be recalculated and whether results should be
///  resorted along these recalculated numbers.</p>
///  <p>Through the <var>enttype</var> parameter, the method can be instructed to return either concepts
///  ($$$ENTTYPECONCEPT) or relations ($$$ENTTYPERELATION). When looking for top concepts, those shorter
///  than 3 characters are skipped.</p>
///  <p>Returned values are either sorted by descending frequency (with <var>sorttype</var>
///  $$$SORTBYFREQUENCY), spread (with <var>sorttype</var> $$$SORTBYSPREAD) or the
///  domain default (with <var>sorttype</var> $$$SORTBYDOMAINDEFAULT).</p>
///  <p>If a Virtual Source ID is provided, only the entities in that virtual source will be considered,
///  filters are ignored and the sort type will always be $$$SORTBYFREQUENCY.</p>
///  <p>Through the <var>skipListIds</var> parameter, a user can supply one or more lists of (to the user)
///  insignificant terms that should be excluded from the result.</p>
ClassMethod GetTop(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", filtermode As %Integer = {$$$FILTERONLY}, sorttype As %Integer = {$$$SORTBYDOMAINDEFAULT}, enttype As %Integer = {$$$ENTTYPECONCEPT}, vSrcId As %Integer = 0, skipListIds As %ListOfDataTypes = "", pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set filtermode = $s($g(filtermode)="":$$$FILTERONLY, 1:filtermode)
	set sorttype = $s($g(sorttype)="":$$$SORTBYDOMAINDEFAULT, 1:sorttype)
	set enttype = $s($g(enttype)="":$$$ENTTYPECONCEPT, 1:enttype)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetTop")
	set tSC = data.Execute(domainid, page, pagesize, filter, filtermode, sorttype, enttype, vSrcId, $lts(..ListToListBuild(skipListIds)), pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns the top entities for a given domain (optionally filtered through <var>pFilter</var>)
/// calculated using a metric based on the Okapi BM25 standard, which combines an entity's frequency 
/// with its Inverse Document Frequency, taking into account document length.
ClassMethod GetTopBM25(pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pEntType As %Integer = {$$$ENTTYPECONCEPT}, pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pEntType = $s($g(pEntType)="":$$$ENTTYPECONCEPT, 1:pEntType)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetTopBM25")
	set tSC = data.Execute(pDomainId, pPage, pPageSize, pFilter, pEntType, pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

ClassMethod GetTopGroups(domainId As %Integer, page As %Integer = 1, pageSize As %Integer = 10, filter As %String(MAXLEN=32767) = "", skipListIds As %ListOfDataTypes = "", language As %String = "en", entType As %Integer = {$$$ENTTYPECONCEPT}, pUseStems As %Boolean = 0) As %XML.DataSet [ Internal, WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pageSize = $s($g(pageSize)="":10, 1:pageSize)
	set language = $s($g(language)="":"en", 1:language)
	set entType = $s($g(entType)="":$$$ENTTYPECONCEPT, 1:entType)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetTopGroups")
	set tSC = data.Execute(domainId, page, pageSize, filter, $lts(..ListToListBuild(skipListIds)), language, entType, pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns the top entities for a given domain (optionally filtered through <var>pFilter</var>)
/// by multiplying their Term Frequency with their Inverse Document Frequency:
/// IDF(e) = $zlog( [ SourceCount - spread(e) + 0.5 ] / [ spread(e) + 0.5 ] )
ClassMethod GetTopTFIDF(pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pEntType As %Integer = {$$$ENTTYPECONCEPT}, pUseStems As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pEntType = $s($g(pEntType)="":$$$ENTTYPECONCEPT, 1:pEntType)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EntityQAPI:GetTopTFIDF")
	set tSC = data.Execute(pDomainId, pPage, pPageSize, pFilter, pEntType, pUseStems)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the entity string value corresponding to the specified entity ID, if any.</p>
ClassMethod GetValue(domainid As %Integer, entityid As %Integer, vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.EntityAPI).GetValue(domainid, entityid, vSrcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Checks if a given entity occurrence has the requested attribute <var>pAttTypeId</var>. 
ClassMethod IsAttributed(pDomainId As %Integer, pEntOccId As %Integer, pAttTypeId As %Integer, vSrcId As %Integer = 0) As %Library.Boolean [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.EntityAPI).IsAttributed(pDomainId, pEntOccId, pAttTypeId, vSrcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Queries/EntityWSAPI";

Parameter SERVICENAME = "iKnow.Queries.EntityWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
