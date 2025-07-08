/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.PathAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Queries.PathAPI</class> for more information.</p>
Class %iKnow.Queries.PathWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

/// <p>Returns all attributes for a given path. Any named attribute properties are also
/// included through sub-nodes (not available through SQL or SOAP): 
/// <blockquote>pResult(<i>rowNumber</i>, <i>propertyName</i>) = <i>propertyValue</i></blockquote></p>
/// <p>Please note this query only returns path-level attributes and not those attributes applying
/// to individual entities or words within entities. To retrieve these, use <method>GetOccurrenceAttributes</method>
/// in <class>%iKnow.Queries.EntityAPI</class>.</p>
ClassMethod GetAttributes(pDomainId As %Integer, pPathId As %Integer, vSrcId As %Integer = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.PathQAPI:GetAttributes")
	set tSC = data.Execute(pDomainId, pPathId, vSrcId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>This method will return all Paths containing any (if <i>setop</i> = $$$UNION) or all 
/// (if <i>setop</i> = $$$INTERSECT) of the entities in the supplied <i>entitylist</i>.</p>
/// <p>The scope of this query can be limited through supplying a <class>%iKnow.Filters.Filter</class> object for the <i>filter</i>
/// parameter to restrict the result to those Paths occurring in any source satisfying the filter
/// criteria.</p>
/// <p>Results are sorted by decreasing path ID.</p>
/// <p>If stemming is enabled for this domain through $$$IKPSTEMMING, paths containing any actual
/// form of the entities in <var>entitylist</var> will be returned. Use <var>pActualFormOnly</var>=1
/// to retrieve only those paths containing the actual forms in <var>entitylist</var>. This
/// argument is ignored if stemming is not enabled.</p>
ClassMethod GetByEntities(domainid As %Integer, entitylist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.PathQAPI:GetByEntities")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entitylist)), page, pagesize, filter, setop, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves paths based on entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetByEntityIds(domainid As %Integer, entityidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.PathQAPI:GetByEntityIds")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entityidlist)), page, pagesize, filter, setop, pActualFormOnly)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Retrieves the paths appearing in any of the sources supplied through <i>sourceidlist</i>.</p>
/// <p>To get the paths of a virtual source, only a single virtual source can be supplied using
/// its negative ID value (otherwise, -1 is returned).</p>
ClassMethod GetBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes, page As %Integer = 1, pagesize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.PathQAPI:GetBySource")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(sourceidlist)), page, pagesize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the number of paths in a domain, optionally restricted to those appearing in a source
/// satisfying the <class>%iKnow.Filters.Filter</class> object supplied through <i>filter</i>.</p>
ClassMethod GetCountByDomain(domainid As %Integer, filter As %String(MAXLEN=32767) = "") As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.PathAPI).GetCountByDomain(domainid, filter, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the number of paths containing the specified entities.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntities(domainid As %Integer, entitylist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.PathAPI).GetCountByEntities(domainid, ..ListToListBuild(entitylist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Retrieves the number of paths containing the specified entity IDs.</p>
/// <p>See also <method>GetByEntities</method> for a description of the parameters.</p>
ClassMethod GetCountByEntityIds(domainid As %Integer, entityidlist As %ListOfDataTypes, filter As %String(MAXLEN=32767) = "", setop As %Integer = {$$$UNION}, pActualFormOnly As %Boolean = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set setop = $s($g(setop)="":$$$UNION, 1:setop)
	set pActualFormOnly = $s($g(pActualFormOnly)="":0, 1:pActualFormOnly)

	set retVal = ##class(%iKnow.Queries.PathAPI).GetCountByEntityIds(domainid, ..ListToListBuild(entityidlist), filter, setop, .sc, pActualFormOnly)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the total number of paths in the sources specified through <i>sourceidlist</i>.
/// Use negative source IDs to refer to virtual sources.</p>
ClassMethod GetCountBySource(domainid As %Integer, sourceidlist As %ListOfDataTypes) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.PathAPI).GetCountBySource(domainid, ..ListToListBuild(sourceidlist), .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns a detailed overview of the entities <var>pathId</var> consists of, including their
/// unique and occurrence IDs, positions, roles and literal value.</p>
/// <p>The last two columns will only contain data if stemming is enabled for this domain through
///  the $$$IKPSTEMMING domain parameter.</p>
ClassMethod GetEntities(domainId As %Integer, pathId As %Integer, vSrcId As %Integer = 0) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.PathQAPI:GetEntities")
	set tSC = data.Execute(domainId, pathId, vSrcId)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>This method will try to find a path corresponding to the supplied list of entities in the
/// specified order. If no path is found, "" is returned.</p>
/// <p>When specifying a Virtual Source ID, it will treat the path as a virtual one, 
/// in the context of that vSrcId.</p>
ClassMethod GetId(domainid As %Integer, entityList As %ListOfDataTypes, vSrcId As %Integer = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.PathAPI).GetId(domainid, ..ListToListBuild(entityList), vSrcId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Left in for backwards compatibility. Use <method>GetId</method> instead.
ClassMethod GetPathId(domainid As %Integer, entityList As %ListOfDataTypes, vSrcId As %Integer = 0) As %Library.Integer [ Internal, WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	quit ##class(%iKnow.Queries.PathAPI).GetPathId(domainid, ..ListToListBuild(entityList), vSrcId)
}

/// Returns the sentence ID in which the supplied path ID occurs
ClassMethod GetSentenceId(domainId As %Integer, pathId As %Integer, vSrcId As %Integer = 0) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)

	set retVal = ##class(%iKnow.Queries.PathAPI).GetSentenceId(domainId, pathId, .sc, vSrcId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// Returns the source ID in which the supplied path ID occurs
ClassMethod GetSourceId(domainId As %Integer, pathId As %Integer) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.PathAPI).GetSourceId(domainId, pathId, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the sequence of entity values corresponding to the specified path as a
/// <class>%List</class>.</p>
/// <p>When specifying a Virtual Source ID, it will treat the pathId as a virtual one, 
/// in the context of that vSrcId.</p>
/// <p>If stemming is enabled for this domain through the $$$IKPSTEMMING domain parameter, you can
/// use <var>pUseStems</var>=1 to get the stems rather than the entities for this path.</p>
ClassMethod GetValue(domainid As %Integer, pathid As %Integer, vSrcId As %Integer = 0, pUseStems As %Boolean = 0) As %Library.List [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set vSrcId = $s($g(vSrcId)="":0, 1:vSrcId)
	set pUseStems = $s($g(pUseStems)="":0, 1:pUseStems)

	set retVal = ##class(%iKnow.Queries.PathAPI).GetValue(domainid, pathid, vSrcId, .sc, pUseStems)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Queries/PathWSAPI";

Parameter SERVICENAME = "iKnow.Queries.PathWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
