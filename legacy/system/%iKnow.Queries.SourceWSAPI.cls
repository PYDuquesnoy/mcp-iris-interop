/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.SourceAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Queries.SourceAPI</class> for more information.</p>
Class %iKnow.Queries.SourceWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

/// <p>Returns all the attributes of the Entity Occurrences, Paths and Sentences enclosed in the
/// specified source, optionally filtered by level through <var>pLevel</var> and/or <var>pType</var>.</p>
/// <p>Please note the <i>startPos</i> and <i>span</i> result columns refer to positions within
/// the path for path-level attributes (level=$$$IKATTLVLPATH) and sentence positions for the
/// other attributes (level=$$$IKATTLVLSENT).</p>
ClassMethod GetAttributes(pDomainId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pTypes As %ListOfDataTypes = "", pLevel As %Integer = {$$$IKATTLVLANY}) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pLevel = $s($g(pLevel)="":$$$IKATTLVLANY, 1:pLevel)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetAttributes")
	set tSC = data.Execute(pDomainId, pSrcId, pPage, pPageSize, $lts(..ListToListBuild(pTypes)), pLevel)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves all sources containing the given CRC ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcIds(domainid As %Integer, crcidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, sortByField As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByCrcIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(crcidlist)), page, pagesize, filter, setop, sortByField)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves all sources containing a CRC satisfying the given CRC Mask.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcMask(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String = "", pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set head = $s($g(head)="":$$$WILDCARD, 1:head)
	set relation = $s($g(relation)="":$$$WILDCARD, 1:relation)
	set tail = $s($g(tail)="":$$$WILDCARD, 1:tail)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByCrcMask")
	set tSC = data.Execute(domainid, head, relation, tail, page, pagesize, filter, sortByField, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves all sources containing the given CRCs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcs(domainid As %Integer, crclist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, sortByField As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByCrcs")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(crclist)), page, pagesize, filter, setop, sortByField)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Returns all sources within a domain, optionally filtered through
///  a <class>%iKnow.Filters.Filter</class> object passed in as <i>filter</i>.</p> 
ClassMethod GetByDomain(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByDomain")
	set tSC = data.Execute(domainid, page, pagesize, filter, sortByField)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
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
ClassMethod GetByEntities(domainid As %Integer, entitylist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, attributeFilter As %ListOfDataTypes = "", sortByField As %String = "", pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByEntities")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entitylist)), page, pagesize, filter, setop, $lts(..ListToListBuild(attributeFilter)), sortByField, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves all sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(domainid As %Integer, entityidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, attributeFilter As %ListOfDataTypes = "", sortByField As %String = "", pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByEntityIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entityidlist)), page, pagesize, filter, setop, $lts(..ListToListBuild(attributeFilter)), sortByField, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Deprecated
ClassMethod GetByEquivalentIds(domainid As %Integer, entityidlist As %ListOfDataTypes, setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ Internal, WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByEquivalentIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entityidlist)), setid, page, pagesize, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Deprecated
ClassMethod GetByEquivalents(domainid As %Integer, entitylist As %ListOfDataTypes, setid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ Internal, WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByEquivalents")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entitylist)), setid, page, pagesize, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves all sources containing the given path ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByPathIds(domainid As %Integer, pathidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", sortByField As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetByPathIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(pathidlist)), page, pagesize, filter, sortByField)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves the number of sources containing the given CRC ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcIds(domainid As %Integer, crcidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcIds(domainid, ..ListToListBuild(crcidlist), filter, setop, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the number of sources containing a CRC satisfying the given CRC Mask.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcMask(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set head = $s($g(head)="":$$$WILDCARD, 1:head)
	set relation = $s($g(relation)="":$$$WILDCARD, 1:relation)
	set tail = $s($g(tail)="":$$$WILDCARD, 1:tail)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcMask(domainid, head, relation, tail, filter, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given CRCs.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcs(domainid As %Integer, crclist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByCrcs(domainid, ..ListToListBuild(crclist), filter, setop, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method returns the total number of sources in the specified domain, optionally filtered
///  through a <class>%iKnow.Filters.Filter</class> object passed in as <i>filter</i>.</p> 
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(domainid, filter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given entities.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByEntities(domainid, ..ListToListBuild(entitylist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given entity ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByEntityIds(domainid, ..ListToListBuild(entityidlist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the number of sources containing the given path ids.</p>
///  <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByPathIds(domainid As %Integer, pathidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetCountByPathIds(domainid, ..ListToListBuild(pathidlist), filter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the external ID for the source identified by <i>srcId</i>.</p>
///  <p>A negative srcId is considered to refer to a Virtual Source.</p>
ClassMethod GetExternalId(domainid As %Integer, srcId As %Integer) As %Library.String [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetExternalId(domainid, srcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>Retrieves the Full Reference for the source identified by <i>srcId</i>.</p>
///  <p>A negative srcId is considered to refer to a Virtual Source.</p>
ClassMethod GetFullReference(domainId As %Integer, srcId As %Integer) As %Library.String [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetFullReference(domainId, srcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method returns, for a given source, all languages the iKnow Automatic Language
///  Identification algorithm has identified for the sentences it contains. For each language, it will
///  list the sum of ALI confidence ratings when assigning the language to a sentence, plus the total
///  number of sentences the language was assigned to. If ALI was disabled when indexing this
///  source, confidence ratings will be set to 0.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetLanguages(domainid As %Integer, sourceid As %Integer) As %XML.DataSet [ WebMethod ]
{
	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetLanguages")
	set tSC = data.Execute(domainid, sourceid)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
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
ClassMethod GetSimilar(domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", algorithm As %String = {$$$SIMSRCSIMPLE}, algorithmParams As %ListOfDataTypes = "", skipListIds As %ListOfDataTypes = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set algorithm = $s($g(algorithm)="":$$$SIMSRCSIMPLE, 1:algorithm)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetSimilar")
	set tSC = data.Execute(domainid, sourceid, page, pagesize, filter, algorithm, $lts(..ListToListBuild(algorithmParams)), $lts(..ListToListBuild(skipListIds)))
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>Retrieves the source ID for the source identified by <i>externalId</i>.</p>
ClassMethod GetSourceId(domainid As %Integer, externalId As %String) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetSourceId(domainid, externalId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method returns the most relevant sentences of the requested source, in their original order.
///  The number of sentences returned is controlled by the <var>length</var> parameter.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetSummary(domainId As %Integer, srcId As %Integer, length As %Integer = 5, summaryConfig As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set length = $s($g(length)="":5, 1:length)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetSummary")
	set tSC = data.Execute(domainId, srcId, length, summaryConfig)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>This is a utility wrapper method around <method>GetSummary</method>, returning the summary
///  sentences as a single concatenated string.</p>
///  <p>The <i>isTruncated</i> output parameter indicates whether or not the
///  returned string is complete or was truncated to avoid MAXSTRING errors. This can happen when either
///  an individual sentence surpassed the maximum string length or when the concatenation of these
///  sentences surpassed it.</p>
ClassMethod GetSummaryDirect(domainId As %Integer, sourceId As %Integer, length As %Integer = 5, separator As %String = " ... ", summaryConfig As %String = "") As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set length = $s($g(length)="":5, 1:length)
	set isTruncated = $s($g(isTruncated)="":0, 1:isTruncated)
	set separator = $s($g(separator)="":" ... ", 1:separator)

	set retVal = ##class(%iKnow.Queries.SourceAPI).GetSummaryDirect(domainId, sourceId, length, .isTruncated, .sc, separator, summaryConfig)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

///  <p>This method returns the most relevant sentences of the supplied text, in their original order.
///  The number of sentences returned is controlled by the <var>length</var> parameter.</p>
/// <p>Note: the value of <var>pDomainId</var> is ignored since 2013.2</p>
ClassMethod GetSummaryForText(pDomainId As %Integer = 0, pText As %String(MAXLEN=32000), pLength As %Integer = 5, pSummaryConfig As %String = "", pLanguage As %String = "en", pUserDict As %String = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pDomainId = $s($g(pDomainId)="":0, 1:pDomainId)
	set pLength = $s($g(pLength)="":5, 1:pLength)
	set pLanguage = $s($g(pLanguage)="":"en", 1:pLanguage)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SourceQAPI:GetSummaryForText")
	set tSC = data.Execute(pDomainId, pText, pLength, pSummaryConfig, pLanguage, pUserDict)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

///  <p>This method returns the language of a given source, calculated as the one with the 
///  highest total confidence rating for the individual sentences in the source. This total 
///  confidence, as well as the number of sentences to which this language was assigned
///  is provided through output variables <i>totalConfidence</i> and <i>numberOfSentences</i>.</p>
///  <p>A <i>totalConfidence</i> of 0 indicates ALI was switched off when indexing this source.</p>
///  <p>A negative Source ID is interpreted as a Virtual Source.</p>
ClassMethod GetTopLanguage(domainid As %Integer, sourceid As %Integer) As %Library.String [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SourceAPI).GetTopLanguage(domainid, sourceid, .totalConfidence, .numberOfSentences, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Queries/SourceWSAPI";

Parameter SERVICENAME = "iKnow.Queries.SourceWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
