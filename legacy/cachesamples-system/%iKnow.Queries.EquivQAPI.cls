/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Queries.EquivAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Queries.EquivAPI</class> for more information.</p>
Class %iKnow.Queries.EquivQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

ClassMethod CreateSet(domainid As %Integer, name As %Integer, Output scText As %String = "") As %Library.Integer [ SqlProc ]
{
	set retVal = ##class(%iKnow.Queries.EquivAPI).CreateSet(domainid, name, .sc)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit retVal
}

ClassMethod DefineTerms(domainid As %Integer, setId As %Integer, uniId1 As %Integer, uniId2 As %Integer, expand As %Integer = 0) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.EquivAPI).DefineTerms(domainid, setId, uniId1, uniId2, expand)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

ClassMethod DropSet(domainid As %Integer, setId As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.EquivAPI).DropSet(domainid, setId)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

Query GetTerms(domainid As %Integer, setId As %Integer, uniId As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767),frequency:%Integer,spread:%Integer") [ SqlProc ]
{
}

ClassMethod GetTermsExecute(ByRef qHandle As %Binary,  domainid As %Integer, setId As %Integer, uniId As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Queries.EquivAPI).GetTerms("^||%IKQ.Result("_r_")", domainid, setId, uniId, page, pagesize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetTermsFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetTermsExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetTermsClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetTermsExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

ClassMethod RemoveTerms(domainid As %Integer, setId As %Integer, uniId1 As %Integer, uniId2 As %Integer) As %Boolean [ SqlProc ]
{
	set sc = ##class(%iKnow.Queries.EquivAPI).RemoveTerms(domainid, setId, uniId1, uniId2)
	if $$$ISERR(sc) { set scText = ##class(%SYSTEM.Status).GetErrorText(sc) }
	quit '$$$ISERR(sc)
}

}
