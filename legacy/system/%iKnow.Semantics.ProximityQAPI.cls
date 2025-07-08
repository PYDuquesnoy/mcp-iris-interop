/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This is an automatically generated class, offering a functionally equivalent set of methods and queries as <class>%iKnow.Semantics.ProximityAPI</class>, exposed as SqlProc methods.</p><p>See the classdocs for <class>%iKnow.Semantics.ProximityAPI</class> for more information.</p>
Class %iKnow.Semantics.ProximityQAPI Extends %iKnow.Queries.AbstractQAPI [ Deprecated, System = 4 ]
{

/// <p>Clusters a document to a set of proximity terms that best identify the documents content.</p>
Query GetClustersBySource(domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "entid:%Integer,entity:%String(MAXLEN=32767),score:%Numeric") [ Deprecated, Internal, SqlProc ]
{
}

ClassMethod GetClustersBySourceExecute(ByRef qHandle As %Binary,  domainid As %Integer, srcid As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.ProximityAPI).GetClustersBySource("^||%IKQ.Result("_r_")", domainid, srcid, page, pagesize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetClustersBySourceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetClustersBySourceExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetClustersBySourceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetClustersBySourceExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the proximity profile for the entity or list of entities supplied through
/// <var>pEntity</var>. This profile is calculated based on the aggregated distance to
/// <var>pEntity</var> entries in all paths in the domain (when <var>pFilter</var>=""),
/// optionally constrained to all paths in a specific set of sources (when <var>pFilter</var>!="").</p>
/// <p>When setting <var>pUseStems</var> to 1, for a domain that has stemming enabled, the scope of 
/// the profile will be expanded to include all actual forms of the supplied <var>pEntity</var>
/// (which has to be provided as a base form (stem)!), and their combined proximity profiles will be
/// grouped to the stem level again.</p> 
Query GetProfile(pDomainId As %Integer, pEntity As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSkipListIDs As %String(MAXLEN=32767) = "", pUseStems As %Boolean = 0) As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767),score:%Integer") [ SqlProc ]
{
}

ClassMethod GetProfileExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pEntity As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSkipListIDs As %String(MAXLEN=32767) = "", pUseStems As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.ProximityAPI).GetProfile("^||%IKQ.Result("_r_")", pDomainId, pEntity, pPage, pPageSize, pFilter, $lfs(pSkipListIDs), pUseStems)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns the proximity profile for the entity represented by <var>pEntUniId</var>. See also <method>GetProfile</method>
/// When setting <var>pUseStems</var> to 1, the value of <var>pEntUniId</var> will be interpreted
/// as a stem ID.
Query GetProfileById(pDomainId As %Integer, pEntUniId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSkipListIDs As %String(MAXLEN=32767) = "", pUseStems As %Boolean = 0) As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767),score:%Integer") [ SqlProc ]
{
}

ClassMethod GetProfileByIdExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pEntUniId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10, pFilter As %String(MAXLEN=32767) = "", pSkipListIDs As %String(MAXLEN=32767) = "", pUseStems As %Boolean = 0) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.ProximityAPI).GetProfileById("^||%IKQ.Result("_r_")", pDomainId, pEntUniId, pPage, pPageSize, pFilter, $lfs(pSkipListIDs), pUseStems)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileByIdFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileByIdExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileByIdClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileByIdExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns the proximity profile for a given entity <var>pEntity</var> in source <var>pExtId</var>.
/// See also <method>GetProfile</method> for a broader set of options.
Query GetProfileBySource(pDomainId As %Integer, pEntity As %String(MAXLEN=32767), pExternalId As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10) As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767),score:%Integer") [ SqlProc ]
{
}

ClassMethod GetProfileBySourceExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pEntity As %String(MAXLEN=32767), pExternalId As %String(MAXLEN=32767), pPage As %Integer = 1, pPageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.ProximityAPI).GetProfileBySource("^||%IKQ.Result("_r_")", pDomainId, pEntity, pExternalId, pPage, pPageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileBySourceFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileBySourceExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileBySourceClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileBySourceExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// Returns the proximity profile for a given entity identified by <var>pEntUniId</var> in source <var>pSrcId</var>.
/// See also <method>GetProfile</method> for a broader set of options.
Query GetProfileBySourceId(pDomainId As %Integer, pEntUniId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10) As %Library.Query(ROWSPEC = "entUniId:%Integer,entity:%String(MAXLEN=32767),score:%Integer") [ SqlProc ]
{
}

ClassMethod GetProfileBySourceIdExecute(ByRef qHandle As %Binary,  pDomainId As %Integer, pEntUniId As %Integer, pSrcId As %Integer, pPage As %Integer = 1, pPageSize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.ProximityAPI).GetProfileBySourceId("^||%IKQ.Result("_r_")", pDomainId, pEntUniId, pSrcId, pPage, pPageSize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileBySourceIdFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileBySourceIdExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileBySourceIdClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileBySourceIdExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

/// <p>Returns the proximity profile for a specified entity.</p>
/// <p>The proximity profile are those elements that most likely occur in close relationship to the provided entity within the sources in a domain.</p>
/// <p>Deprecated: See also <method>GetProfile</method> for a broader set of options.</p>
Query GetProfileForEntity(domainid As %Integer, entId As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Library.Query(ROWSPEC = "entId:%Integer,entity:%String(MAXLEN=32767),proximity:%Numeric") [ Deprecated, Internal, SqlProc ]
{
}

ClassMethod GetProfileForEntityExecute(ByRef qHandle As %Binary,  domainid As %Integer, entId As %Integer, page As %Integer = 1, pagesize As %Integer = 10) As %Status [ Internal ]
{
	set r = $random(999999)
	set sc = ##class(%iKnow.Semantics.ProximityAPI).GetProfileForEntity("^||%IKQ.Result("_r_")", domainid, entId, page, pagesize)
	quit:$$$ISERR(sc) sc
	set qHandle = $lb("",r)
	quit $$$OK
}

ClassMethod GetProfileForEntityFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = GetProfileForEntityExecute ]
{
	quit ..GenericFetch(.qHandle, .Row, .AtEnd)
}

ClassMethod GetProfileForEntityClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = GetProfileForEntityExecute ]
{
	kill ^||%IKQ.Result(+$lg(qHandle,2))
	quit $$$OK
}

}
