/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Semantics.DominanceAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Semantics.DominanceAPI</class> for more information.</p>
Class %iKnow.Semantics.DominanceWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

/// <p>Calculates the overlapping overlap of two sets of documents. First the overlap within <var>set1</var> is calculated, then the overlap within
/// 	<var>set2</var>. Finally those are compared and the most overlapping elements within those 2 sets are returned.</p>
ClassMethod GetAggregateOverlaps(domainid As %Integer, type As %Integer, set1 As %String(MAXLEN=32767) = "", set2 As %String(MAXLEN=32767) = "", page As %Integer = 1, pagesize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetAggregateOverlaps")
	set tSC = data.Execute(domainid, type, set1, set2, page, pagesize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the list of most breaking sources in a domain. The <var>type</var> parameter defines on which type of element you want the
/// list of breaking documents to be based. This can be:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetBreakingSources(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetBreakingSources")
	set tSC = data.Execute(domainid, page, pagesize, type, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// 	<p>Returns all dominant elements for a specific source. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The elements returned can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetBySource(domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)
	set cutoff = $s($g(cutoff)="":$$$SDALL, 1:cutoff)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetBySource")
	set tSC = data.Execute(domainid, srcid, page, pagesize, type, cutoff)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the number of dominant terms found in a specific source. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The number of elements counted can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetCountBySource(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)
	set cutoff = $s($g(cutoff)="":$$$SDALL, 1:cutoff)

	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetCountBySource(domainid, srcid, type, cutoff, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

ClassMethod GetCountBySourceInternal(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}, pUseProfile As %Boolean = 1) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)
	set cutoff = $s($g(cutoff)="":$$$SDALL, 1:cutoff)
	set pUseProfile = $s($g(pUseProfile)="":1, 1:pUseProfile)

	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetCountBySourceInternal(domainid, srcid, type, cutoff, pUseProfile, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the dominance value of an element within a specified domain. The <var>id</var> parameter takes either an entityId, crcId or pathId and the
/// <var>type parameter</var> defines of what type the <var>id</var> parameter is. Thus valid types are <var>$$$SDCONCEPT</var>, <var>$$$SDCRC</var> and
/// 	<var>$$$SDPATH</var>.</p>
ClassMethod GetDomainValue(domainid As %Integer, id As %Integer, type As %Integer = {$$$SDCONCEPT}) As %Library.Numeric [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue(domainid, id, type, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the most overlapping elements in a domain. This can be restricted by type by setting the <var>type</var> parameter to any of those values:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetOverlap(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetOverlap")
	set tSC = data.Execute(domainid, page, pagesize, type, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the overlap details of an element in a domain. The type of the element must be specified through the <var>type</var> parameter to any of those values:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetOverlapDetails(domainid As %Integer, id As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetOverlapDetails")
	set tSC = data.Execute(domainid, id, page, pagesize, type, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// 	<p>Returns the dominance profile for a complete domain. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and <var>$$$SDAGGREGATE</var>.</p>
ClassMethod GetProfileByDomain(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetProfileByDomain")
	set tSC = data.Execute(domainid, page, pagesize, type)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// 	<p>Returns the dominance profile for a specific source. The type of elements returned can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The elements returned can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetProfileBySource(domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)
	set cutoff = $s($g(cutoff)="":$$$SDALL, 1:cutoff)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetProfileBySource")
	set tSC = data.Execute(domainid, srcid, page, pagesize, type, cutoff)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the number of dominant terms in the profile of a complete domain. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and <var>$$$SDAGGREGATE</var>.</p>
ClassMethod GetProfileCountByDomain(domainid As %Integer, type As %Integer = {$$$SDCONCEPT}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetProfileCountByDomain(domainid, type, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the number of dominant terms in the profile of a specific source. The type of elements counted can be set by the <var>type</var> parameter.
/// 	Available types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATION</var>, <var>$$$SDENTITY</var>, <var>$$$SDCRC</var>, <var>$$$SDPATH</var> and <var>$$$SDAGGREGATE</var>.</p>
/// 	<p>The number of elements counted can be limited to those with a dominance value above average by setting the <var>cutoff</var> parameter to <var>$$$SDABOVEAVERAGE</var>.</p>
ClassMethod GetProfileCountBySource(domainid As %Integer, srcid As %Integer, type As %Integer = {$$$SDCONCEPT}, cutoff As %Integer = {$$$SDALL}) As %Library.Integer [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)
	set cutoff = $s($g(cutoff)="":$$$SDALL, 1:cutoff)

	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetProfileCountBySource(domainid, srcid, type, cutoff, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns the dominance value of an element within a specified source. The <var>id</var> parameter takes either an entityId, crcId or pathId and the
/// <var>type parameter</var> defines of what type the <var>id</var> parameter is. Thus valid types are <var>$$$SDCONCEPT</var>, <var>$$$SDRELATIONM</var>,
/// 	<var>$$$SDENTITY</var>, <var>$$$SDCRC</var> and	<var>$$$SDPATH</var>.</p>
ClassMethod GetSourceValue(domainid As %Integer, srcid As %Integer, id As %Integer, type As %Integer = {$$$SDCONCEPT}) As %Library.Numeric [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set retVal = ##class(%iKnow.Semantics.DominanceAPI).GetSourceValue(domainid, srcid, id, type, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

/// <p>Returns a set of documents wich correlate closely to the input set (<var>entids</var>) of entities based on the dominance values of those entities
/// within the documents.</p>
ClassMethod GetSourcesByCorrelation(domainid As %Integer, entids As %ListOfDataTypes = "", page As %Integer = 1, pagesize As %Integer = 10, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetSourcesByCorrelation")
	set tSC = data.Execute(domainid, $lts(..ListToListBuild(entids)), page, pagesize, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the top entities for this domain, sorted by their aggregated dominance values.
/// <p><var>pAggregation</var> defines how to aggregate the source-level values. Currently the only
/// supported value is "AVG", which just calculates a regular average as a fast approximation.
/// Future versions will offer more advanced aggregation modes (which may be slower to calculate). </p>
ClassMethod GetTop(pDomainId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pAggregation As %String = "AVG", pEntRole As %Integer = {$$$SDCONCEPT}, pSkipLists As %ListOfDataTypes = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set pPage = $s($g(pPage)="":1, 1:pPage)
	set pPageSize = $s($g(pPageSize)="":10, 1:pPageSize)
	set pAggregation = $s($g(pAggregation)="":"AVG", 1:pAggregation)
	set pEntRole = $s($g(pEntRole)="":$$$SDCONCEPT, 1:pEntRole)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetTop")
	set tSC = data.Execute(pDomainId, pPage, pPageSize, pFilter, pAggregation, pEntRole, $lts(..ListToListBuild(pSkipLists)))
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

/// <p>Returns the list of most typical sources in a domain. The <var>type</var> parameter defines on which type of element you want the
/// list of typical documents to be based. This can be:
/// 	<ul>
/// 	<li>$$$SDCONCEPT</li>
/// 	<li>$$$SDRELATION</li>
/// 	<li>$$$SDENTITY</li>
/// 	<li>$$$SDCRC</li>
/// 	</ul>.</p>
ClassMethod GetTypicalSources(domainid As %Integer, page As %Integer = 1, pagesize As %Integer = 10, type As %Integer = {$$$SDCONCEPT}, filter As %String(MAXLEN=32767) = "") As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)
	set type = $s($g(type)="":$$$SDCONCEPT, 1:type)

	set data = ##class(%XML.DataSet).%New("%iKnow.Semantics.DominanceQAPI:GetTypicalSources")
	set tSC = data.Execute(domainid, page, pagesize, type, filter)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Semantics/DominanceWSAPI";

Parameter SERVICENAME = "iKnow.Semantics.DominanceWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
