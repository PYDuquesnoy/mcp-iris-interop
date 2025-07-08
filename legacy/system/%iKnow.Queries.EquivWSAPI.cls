/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.EquivAPI</class>, exposed as WebMethod methods.</p><p>See the classdocs for <class>%iKnow.Queries.EquivAPI</class> for more information.</p>
Class %iKnow.Queries.EquivWSAPI Extends %iKnow.Queries.AbstractWSAPI [ Deprecated, System = 4 ]
{

ClassMethod CreateSet(domainid As %Integer, name As %Integer) As %Library.Integer [ WebMethod ]
{
	set retVal = ##class(%iKnow.Queries.EquivAPI).CreateSet(domainid, name, .sc)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit retVal
}

ClassMethod DefineTerms(domainid As %Integer, setId As %Integer, uniId1 As %Integer, uniId2 As %Integer, expand As %Integer = 0) As %Boolean [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set expand = $s($g(expand)="":0, 1:expand)

	set sc = ##class(%iKnow.Queries.EquivAPI).DefineTerms(domainid, setId, uniId1, uniId2, expand)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

ClassMethod DropSet(domainid As %Integer, setId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Queries.EquivAPI).DropSet(domainid, setId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

ClassMethod GetTerms(domainid As %Integer, setId As %Integer, uniId As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %XML.DataSet [ WebMethod ]
{
	// manually set WebMethod parameter defaults (prodlog 90598)
	set page = $s($g(page)="":1, 1:page)
	set pagesize = $s($g(pagesize)="":10, 1:pagesize)

	set data = ##class(%XML.DataSet).%New("%iKnow.Queries.EquivQAPI:GetTerms")
	set tSC = data.Execute(domainid, setId, uniId, page, pagesize)
	if $$$ISERR(tSC) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC)) }
	quit data
}

ClassMethod RemoveTerms(domainid As %Integer, setId As %Integer, uniId1 As %Integer, uniId2 As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Queries.EquivAPI).RemoveTerms(domainid, setId, uniId1, uniId2)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Queries/EquivWSAPI";

Parameter SERVICENAME = "iKnow.Queries.EquivWSAPI";

Parameter USECLASSNAMESPACES = 1;

}
