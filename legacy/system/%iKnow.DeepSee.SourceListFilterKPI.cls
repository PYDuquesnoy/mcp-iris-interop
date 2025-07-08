/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Implements a DeepSee KPI that executes an iKnow query returning a list of iKnow Sources.
/// To use this class, create a subclass and override the <parameter>IKDOMAINID</parameter> class parameter to
/// point to the domain you want to query.<p>
/// <p>This iKnow-DeepSee KPI implementation offers the following services:
/// <ul>
///    <li>Displays all metadata fields for the registered domain as properties (columns in the KPI tab form), which can be configured at widget level. The Source ID and External ID are available as well.</li>
///    <li>Offers any relevant query parameters as filters so they can then be added to the widget (and controlled by the user) or fixed to a specific value. Through the GetParameterValues method in <class>%iKnow.Queries.Utils</class>, a list of allowed parameter values is also made available for most common parameters.</li>
///    <li>Exposes all the domains public metadata fields as filters (through <class>%iKnow.DeepSee.BaseKPI</class>) </li>
///    <li>Adds previous and next buttons to browse through the query results (through <class>%iKnow.DeepSee.BaseKPI</class>)</li>
/// </ul>
Class %iKnow.DeepSee.SourceListFilterKPI Extends %iKnow.DeepSee.BaseKPI [ Abstract, Deprecated, System = 4 ]
{

/// <p>Implementation of <method>%OnExecute</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
/// <p>Configures and fires the appropriate <class>%iKnow.Queries.SourceAPI</class> query given the active filter criteria.</p>
Method %OnExecute() As %Status
{
    set domainId = ..GetDomainId()
    quit:domainId="" $$$ERROR($$$IKDomainNotExists)
    
	Set tSC = $$$OK
	Try {
		kill filters
		do ..%filterValues.%CopyToArray(.filters)
		
		set pageSize = $g(filters("IK:QPARAM:PAGESIZE"))
		set:pageSize="" pageSize = ..#IKPAGESIZE
		
		set tCurrentFilter = ..BuildCurrentFilter(.tSC)
		quit:$$$ISERR(tSC)
		
		set concept = $g(filters("IK:QPARAM:CONCEPT"))
		if (concept'="") {
			if ($e(concept,1) = "{") {
				set conceptList = $lfs($e(concept,2,*-1))
			} else {
				set conceptList = $lb(concept)
			}
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByEntities(.result, domainId, conceptList, ..GetCurrentPage(domainId), pageSize, tCurrentFilter)
		} else {
			set tSC = ##class(%iKnow.Queries.SourceAPI).GetByDomain(.result, domainId, ..GetCurrentPage(domainId), pageSize, tCurrentFilter)
		}
		
		// find any %Date parameters and compile displayProps
		kill dataTypes, displayProps
		set displayProps("source ID") = 1
		set displayProps("external ID") = 2
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.mdfs, ..GetDomainIdStatic(), ..#IKINCLUDEHIDDENMETADATA)
		quit:tSC'=$$$OK 
		set i = "", k = 2
		for {
			set i = $order(mdfs(i), 1, md)
			quit:i=""
			set displayProps($list(md, 2)) = $i(k)
			set dataTypes($li(md,1)) = $li(md,4)
		}
		
		// now loop through the results and append metadata values
		set i = ""
		for {
			set i = $order(result(i),1,d)
			quit:i=""
			
			// append metadata values
		    set tSC = ##class(%iKnow.Queries.MetadataAPI).GetValuesById(.r, domainId, $list(d,1), ..#IKINCLUDEHIDDENMETADATA)
		    set j = ""
		    for {
			    set j = $order(r(j),1,md)
			    q:j=""
			   
			   	set value = $li(md,3)
			   	if (value '= "") && (dataTypes($li(md,1))=$$$MDDTDATE) {
				   	set value = $s(+$p(value,",",2):$zdatetime(value), 1:$zdate(value))
			   	}
			   	
			   	set d = d _ $lb(value)
		    }
		    set result(i) = d
		}
		
		set tSC = ..DisplayResult(.result, $g(filters("IK:PARAM:NAMECOLUMN"),0), .displayProps)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// <p>Implementation of <method>%OnGetFilterMembers</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
/// <p>Adds the values for the IK: system filters (concept filter, metadata-based filters and query parameters)</p>
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "") As %Status
{
	if (pFilter = "IK:QPARAM:CONCEPT") {
		if (pSearchKey '= "") {
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.result, ..GetDomainIdStatic(), pSearchKey, 1, ..#IKPAGESIZE)
		} else {
			set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.result, ..GetDomainIdStatic(), 1, ..#IKPAGESIZE)
		}
		kill pMembers
		set i = ""
		for {
			set i = $o(result(i),1,d)
			quit:i=""
			
			set pMembers($i(pMembers)) = $lb($list(d,2),$list(d,2))
		}
		quit tSC
		
	} elseif (pFilter="IK:PARAM:NAMECOLUMN") {
		
		kill pMembers
		set pMembers($i(pMembers)) = $lb("source ID",1)
		set pMembers($i(pMembers)) = $lb("external ID",2)
		
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.result, ..GetDomainIdStatic(), ..#IKINCLUDEHIDDENMETADATA)
		quit:tSC'=$$$OK tSC
	
		set j = "", k=2
		for {
			set j = $order(result(j), 1, md)
			quit:j=""
		
			set pMembers($i(pMembers)) = $lb($list(md,2),$i(k))
		}
		quit tSC
		
	} elseif ($e(pFilter,1,10)="IK:QPARAM:") {
		
		// try to find allowable parameter values
		kill pMembers
		set paramName = $piece(pFilter,":",3)
		if (##class(%iKnow.Queries.Utils).GetParameterValues(paramName, .values, "%iKnow.Queries.SourceAPI", "GetByEntities")) {
			for j=1:1:+$g(values) {
				set pMembers($i(pMembers)) = $lb($li(values(j),2), $li(values(j),1))
			}
		}
		
		quit $$$OK
		
	} else {
		quit ##super(pFilter, .pMembers, pSearchKey, pDataSourceName)
	}
}

/// <p>Implementation of <method>%OnGetKPIPropertyInfo</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
/// <p>This method will add all metadata fields supplied for this domain as columns for this KPI.</p>
ClassMethod %OnGetKPIPropertyInfo(ByRef pList As %String, pPropNo As %Integer, pModelId As %String = "") As %Status
{
	set pList($i(pPropNo)) = "source ID"
	set pList($i(pPropNo)) = "external ID"
	
	set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.result, ..GetDomainIdStatic(), ..#IKINCLUDEHIDDENMETADATA)
	quit:tSC'=$$$OK tSC
	
	set i = ""
	for {
		set i = $order(result(i), 1, md)
		quit:i=""
		
		set pList($i(pPropNo)) = $list(md, 2)
	}
	
	Quit tSC
}

/// <p>Implementation of <method>%OnGetFilterList</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
/// <p>Adds filters for concept, page size and set operation</p>
ClassMethod %OnGetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status
{
	set tSC = ##super(.pFilters, pDataSourceName)
	quit:$$$ISERR(tSC) tSC
	
	set pFilters($i(pFilters)) = $lb("IK:QPARAM:CONCEPT", "Contains concept",, 1)
	set pFilters($i(pFilters)) = $lb("IK:QPARAM:PAGESIZE", ##class(%iKnow.Queries.Utils).GetParameterDisplayName("pageSize"),, 1)
	set pFilters($i(pFilters)) = $lb("IK:QPARAM:SETOP", ##class(%iKnow.Queries.Utils).GetParameterDisplayName("setOp"),, 1)
	
	quit tSC
}

}
