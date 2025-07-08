/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKPublic

/// <p>This class offers a Web Service access point to iKnow filters. Use the
/// <method>CreateAsString</method> and <method>CreateGroupAsString</method> Web Services to generate
/// the string representations of <class>%iKnow.Filters.Filter</class>
/// objects that can then be passed on to the iKnow Query Web Service APIs.</p>
Class %iKnow.Filters.FilterWSAPI Extends %SOAP.WebService [ Deprecated, LegacyInstanceContext, System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/iKnow/Filters/FilterWSAPI";

Parameter SERVICENAME = "iKnow.Filters.FilterWSAPI";

Parameter SECURITYRESOURCE = "%Development";

Parameter USECLASSNAMESPACES = 1;

/// <p>This WebMethod is an access point to generate the string representation (as specified in
/// <method>ToString</method>) for <class>%iKnow.Filters.Filter</class> classes, accessible from 
/// Web Service scenarios.</p>
/// <p>When calling this method, you should supply the <b>Filter Parameters</b> as if calling the
/// <method>%New</method> method of this particular Filter implementation.</p>
ClassMethod CreateAsString(filterName As %String, filterParams As %ListOfDataTypes) As %String [ WebMethod ]
{
	quit:filterParams="" ""
	
	if ($isobject(filterParams)) {
		set params = filterParams.Count()
		for i=1:1:params { set params(i) = filterParams.GetAt(i) }
	} elseif ($listvalid(filterParams)) {
		set params = $ll(filterParams)
		for i=1:1:params { set params(i) = $lg(filterParams, i) }
	} else {
		quit ""
	}
	try {
		set filterString = $classmethod(filterName, "CreateAsString", params...)
	} catch(ex) {
		do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ex.DisplayString(), ex.AsStatus()))
	}
	quit filterString
}

/// <p>This class enables Web Service users to create the string representation of a
/// <class>%iKnow.Filters.GroupFilter</class> composed of multiple subfilters passed in using their
/// respective string representations as the <i>filters...</i> parameter.</p>
ClassMethod CreateGroupAsString(domainId As %Integer, groupLogic As %Integer = {$$$GROUPFILTERAND}, negated As %Boolean = 0, filters As %ListOfDataTypes) As %String [ WebMethod ]
{
	quit:filters="" ""
	
	// manually set WebMethod parameter defaults (prodlog 90598)
	set groupLogic = $s($g(groupLogic)="":$$$GROUPFILTERAND, 1:groupLogic)
	set negated = $s($g(negated)="":0, 1:negated)
	
	set groupFilter = ##class(%iKnow.Filters.GroupFilter).%New(domainId, groupLogic, negated)
	quit:groupFilter="" ""
	
	set tSC = $$$OK
	if ($isobject(filters)) {
		for i=1:1:filters.Count() { 
			set tSC = groupFilter.AddSubFilterString(filters.GetAt(i)) 
			quit:$$$ISERR(tSC)
		}
	} elseif ($listvalid(filters)) {
		for i=1:1:$ll(filters) { 
			set tSC = groupFilter.AddSubFilterString($lg(filters, i)) 
			quit:$$$ISERR(tSC)
		}
	} else {
		quit ""
	}
	
	if $$$ISERR(tSC) {
		do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(tSC), tSC))
	}
	
	quit groupFilter.ToString()
}

/// <p>Clears all filters from the persistent filter cache.</p>
ClassMethod ClearCachedFilters(domainId As %Integer) As %Boolean [ WebMethod ]
{
	set sc = ##class(%iKnow.Filters.Filter).ClearCachedFilters(domainId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

/// <p>Clears a specific filter from the persistent filter cache, if it exists.</p>
ClassMethod ClearCachedFilter(domainId As %Integer, filterId As %Status) As %Status [ WebMethod ]
{
	set sc = ##class(%iKnow.Filters.Filter).ClearCachedFilter(domainId, filterId)
	if $$$ISERR(sc) { do ..ReturnFault(..MakeStatusFault($$$FAULTServer, ##class(%SYSTEM.Status).GetErrorText(sc), sc)) }
	quit '$$$ISERR(sc)
}

}
