/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.SentenceAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Queries.SentenceAPI</class> for more information.</p>
Class %iKnow.Queries.SentenceWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
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
ClassMethod GetAttributes(pDomainId As %Integer, pSentId As %Integer, vSrcId As %Integer = 0, pIncludePathAttributes As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)
	set pIncludePathAttributes = $s($g(pIncludePathAttributes)="":0, 1:pIncludePathAttributes)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetAttributes")
	set tSC = data.Execute(pDomainId, pSentId, vSrcId, pIncludePathAttributes)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves all sentences containing the given CRC ids, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>crcidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcIds(domainid As %Integer, crcidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetByCrcIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(crcidlist)), filter, page, pagesize, setop)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves all sentences containing a CRC satisfying the given CRC Mask, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcMask(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set head = $s($g(head)="":$$$WILDCARD, 1:head)
	set relation = $s($g(relation)="":$$$WILDCARD, 1:relation)
	set tail = $s($g(tail)="":$$$WILDCARD, 1:tail)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetByCrcMask")
	set tSC = data.Execute(domainid, head, relation, tail, filter, page, pagesize, setop, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves all sentences containing the given CRCs, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByCrcs(domainid As %Integer, crclist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetByCrcs")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(crclist)), filter, page, pagesize, setop)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>This method will retrieve all sentences containing any (if <i>setop</i> = $$$UNION) or all
/// (if <i>setop</i> = $$$INTERSECT) of the entities supplied through <i>entitylist</i>, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, sentences containing any actual
/// form of the entities in <var>entityList</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those sentences containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(domainid As %Integer, entitylist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetByEntities")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entitylist)), filter, page, pagesize, setop, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves all sentences containing the given entity IDs., optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>entityidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(domainid As %Integer, entityidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10, setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetByEntityIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entityidlist)), filter, page, pagesize, setop, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves all sentences containing the given path IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByPathIds(domainid As %Integer, pathidlist As %ListOfDataTypes, sourceidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetByPathIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(pathidlist)), $lts(..ListToListBuild(sourceidlist)), page, pagesize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns the sentences for the given source. A negative source ID is interpreted as a Virtual Source.
ClassMethod GetBySource(domainid As %Integer, sourceid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetBySource")
	set tSC = data.Execute(domainid, sourceid, page, pagesize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves the number of sentences containing the given CRC ids, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.
/// In this case, <var>crcidlist</var> is expected to contain virtual Entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcIds(domainid As %Integer, crcidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByCrcIds(domainid, ..ListToListBuild(crcidlist), filter, setop, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing a CRC satisfying the given CRC Mask, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcMask(domainid As %Integer, head As %String = {$$$WILDCARD}, relation As %String = {$$$WILDCARD}, tail As %String = {$$$WILDCARD}, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set head = $s($g(head)="":$$$WILDCARD, 1:head)
	set relation = $s($g(relation)="":$$$WILDCARD, 1:relation)
	set tail = $s($g(tail)="":$$$WILDCARD, 1:tail)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByCrcMask(domainid, head, relation, tail, filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing the given CRCs, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByCrcs(domainid As %Integer, crclist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)

	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByCrcs(domainid, ..ListToListBuild(crclist), filter, setop, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the total number of sentences for a given domain, optionally filtered to those sources
/// satisfying a <class>%iKnow.Filters.Filter</class> object passed in through <i>filter</i>.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByDomain(domainid, filter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing the given entities, optionally limited to
/// all sentences in records satisfying <var>filter</var>.
/// For querying Virtual Sources, set <var>filter</var> to a single, negative integer.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByEntities(domainid, ..ListToListBuild(entitylist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
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
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByEntityIds(domainid, ..ListToListBuild(entityidlist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the number of sentences containing the given path IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByPathIds(domainid As %Integer, pathidlist As %ListOfDataTypes, sourceidlist As %ListOfDataTypes) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountByPathIds(domainid, ..ListToListBuild(pathidlist), ..ListToListBuild(sourceidlist), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the total number of sentences for the given sources. Negative Source IDs are
/// interpreted as referring to Virtual Sources.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.SentenceAPI).GetCountBySource(domainid, ..ListToListBuild(sourceidlist), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the language of the given sentence, as derived by the Automatic Language Identification
/// algorithm or, if ALI was disabled, the language specified when indexing this sentence.</p>
/// <p>The confidence level is returned as well through an output parameter.
/// If the confidence level is 0, this means ALI was not used and the language was defined by the
/// user loading the source.</p>
/// <p>If a Virtual Source ID is specified, the sentence ID is treated as a virtual one, in the
/// context of the supplied vSrcId.</p>
ClassMethod GetLanguage(domainid As %Integer, sentenceid As %Integer, vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.SentenceAPI).GetLanguage(domainid, sentenceid, .confidence, vSrcId)
}

/// <p>Retrieves the sentences with the most significant concepts compared to the rest of the domain
/// (or optionally a subset thereof as filtered through <i>filter</i>). This array of sentences is
/// based on results of the GetNewBySource query in <class>%iKnow.Queries.EntityAPI</class>, using
/// the supplied algorithm and parameter values. The scores of the first [<i>newEntitiesWindow</i>]
/// concepts are aggregated across sentences to produce the result of this query.</p>
/// <p>Please refer to the documentation of the GetNewBySource query in
/// <class>%iKnow.Queries.EntityAPI</class> for more details on the parameters and available algorithms.</p>
ClassMethod GetNewBySource(domainid As %Integer, sourceid As %Integer, length As %Integer = 5, filter As %String(MAXLEN=32767) = "", algorithm As %String = {$$$NEWENTSIMPLE}, algorithmParams As %ListOfDataTypes = "", newEntitiesWindow As %Integer = 100, skipListIds As %ListOfDataTypes = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set length = $s($g(length)="":5, 1:length)
	set algorithm = $s($g(algorithm)="":$$$NEWENTSIMPLE, 1:algorithm)
	set newEntitiesWindow = $s($g(newEntitiesWindow)="":100, 1:newEntitiesWindow)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetNewBySource")
	set tSC = data.Execute(domainid, sourceid, length, filter, algorithm, $lts(..ListToListBuild(algorithmParams)), newEntitiesWindow, $lts(..ListToListBuild(skipListIds)))
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns the literal of the entity or nonrelevant at the specified position.
ClassMethod GetPartLiteral(domainId As %Integer, sentenceId As %Integer, position As %Integer, vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

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
ClassMethod GetParts(domainid As %Integer, sentenceid As %Integer, includeCRCMarkers As %Boolean = 0, includePathMarkers As %Boolean = 0, vSrcId As %Integer = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set includeCRCMarkers = $s($g(includeCRCMarkers)="":0, 1:includeCRCMarkers)
	set includePathMarkers = $s($g(includePathMarkers)="":0, 1:includePathMarkers)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.SentenceQAPI:GetParts")
	set tSC = data.Execute(domainid, sentenceid, includeCRCMarkers, includePathMarkers, vSrcId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// Returns the position within the source this sentence occurs at (1-based).
ClassMethod GetPosition(domainId As %Integer, sentenceId As %Integer, vSrcId As %Integer = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.SentenceAPI).GetPosition(domainId, sentenceId, vSrcId)
}

/// Returns the source ID in which the supplied sentence ID occurs
ClassMethod GetSourceId(domainId As %Integer, sentenceId As %Integer) As %Library.Integer [ WebMethod ]
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
ClassMethod GetValue(domainid As %Integer, sentenceid As %Integer, vSrcId As %Integer = 0) As %Library.String [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set fullSentence = $s($g(fullSentence)="":1, 1:fullSentence)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.SentenceAPI).GetValue(domainid, sentenceid, .fullSentence, vSrcId)
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Queries/SentenceWSAPI";

Parameter SERVICENAME = "iKnow.Queries.SentenceWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
