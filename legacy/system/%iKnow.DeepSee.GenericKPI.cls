/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  <p>Implements a DeepSee KPI that executes an iKnow query.
///  To use this class, create a subclass and override the class parameters prefixed with "IK", which you use to specify
///  the iKnow domain (<parameter>IKDOMAINID</parameter>), query class (<parameter>IKQUERYCLASS</parameter>),
///  query (<parameter>IKQUERYNAME</parameter>), and default page size (<parameter>IKPAGESIZE</parameter>, optional).<p>
///  <p>This generic iKnow-DeepSee KPI implementation offers the following services:
///  <ul>
///     <li>Displays all query result columns as properties (columns in the KPI tab form), which can be configured at widget level. A "resultNumber" column is added as well, indicating the "rank" of the result.</li>
///     <li>Offers all query parameters as filters so they can then be added to the widget (and controlled by the user) or fixed to a specific value. Through the GetParameterValues method in <class>%iKnow.Queries.Utils</class>, a list of allowed parameter values is also made available for most common parameters.</li>
///  	<li>Adds a default Listing to this KPI, showing the iKnow sources containing the entities, CRCs or paths selected in the KPI result. (not available for every query)</li>
///     <li>Exposes all the domains public metadata fields as filters (through <class>%iKnow.DeepSee.BaseKPI</class>) </li>
///     <li>Adds previous and next buttons to browse through the query results (through <class>%iKnow.DeepSee.BaseKPI</class>)</li>
///  </ul>
Class %iKnow.DeepSee.GenericKPI Extends %iKnow.DeepSee.BaseKPI [ Abstract, Deprecated, System = 4 ]
{

///  Override this parameter to specify the iKnow ObjectScript API class that contains the query to use (primary API class, no *QAPI or *WSAPI class)
Parameter IKQUERYCLASS = "%iKnow.Queries.EntityAPI";

///  Override this parameter to specify the iKnow query to use in the class identified by <parameter>IKQUERYCLASS</parameter>.
Parameter IKQUERYNAME = "GetTop";

///  <p>Implementation of <method>%OnGetFilterList</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Adds a list of all valid query parameters for the query identified by <parameter>IKQUERYCLASS</parameter> and <parameter>IKQUERYNAME</parameter>.</p>
ClassMethod %OnGetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status
{
	set tSC = ##super(.pFilters, pDataSourceName)
	quit:$$$ISERR(tSC) tSC
	
	// add the parameters for this query as filters
	set qMethod = ##class(%Dictionary.CompiledMethod).%OpenId(..#IKQUERYCLASS _"||"_ ..#IKQUERYNAME)
	quit:qMethod="" $$$OK
	
	set skip = $lb("RESULT","DOMAINID","FILTER","FILTERMODE","PAGE","VSRCID","PRESULT","PDOMAINID","PFILTER","PFILTERMODE","PPAGE")
	set qParams = qMethod.FormalSpecParsed, ptr=0, pos=0
	while $listnext(qParams, ptr, p) {
		set name = $li(p,1)
		set type = $li(p,2)
		set mode = $li(p,3)
		set default = $li(p,4)
		set pos = $i(pos)
		
		// skip output parameters
		continue:mode="*"
		
		// skip domain ID and filters
		continue:$lf(skip,$zconvert(name,"U"))
		
		set displayName = ##class(%iKnow.Queries.Utils).GetParameterDisplayName(name)
		set pFilters($i(pFilters)) = $lb("IK:QPARAM:"_pos_":"_$zconvert(name,"U"), displayName, default, 0)
	}
	
	quit tSC
}

///  <p>Implementation of <method>%OnGetFilterMembers</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Adds the values for the IK: system filters (series name column, metadata-based filters and query parameters)</p>
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "") As %Status
{
	if (pFilter="IK:PARAM:NAMECOLUMN") {
		
		// overwrite any existing values that would have been added already
	    // by the subclass in the valueList (for overriding the defaultValue)
	    kill pMembers
		set pMembers($i(pMembers)) = $lb("rank",1)
		
	    set qRT = ##class(%Dictionary.CompiledParameter).%OpenId(..#IKQUERYCLASS _"||"_ ..#IKQUERYNAME_"RT")
	    quit:qRT="" $$$ERROR($$$ParameterDoesNotExist, ..#IKQUERYCLASS _"."_ ..#IKQUERYNAME_"RT")
    
	    set qRTcolumns = $lfs(qRT.Default,","), ptr=0, pos=1
	    while $listnext(qRTcolumns, ptr, col) {
	        set col = $piece(col,":",1)
	        set pos = $i(pos)
	        
		    set pMembers($i(pMembers)) = $lb(col,pos)
	    }
    	quit $$$OK
    	
	} elseif ($e(pFilter,1,10)="IK:QPARAM:") {
		
		// try to find allowable parameter values
		kill pMembers
		set paramName = $piece(pFilter,":",4)
		if (##class(%iKnow.Queries.Utils).GetParameterValues(paramName, .values, ..#IKQUERYCLASS, ..#IKQUERYNAME)) {
			for j=1:1:+$g(values) {
				set pMembers($i(pMembers)) = $lb($li(values(j),2), $li(values(j),1))
			}
		}
		
		quit $$$OK
	} else {
		quit ##super(pFilter, .pMembers, pSearchKey, pDataSourceName)
	}
}

///  <p>Implementation of <method>%OnGetKPIPropertyInfo</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Adds the returned columns for this KPIs query as properties if there aren't any configured
///  explicitly already, as well as a 'resultNumber' column</p>
ClassMethod %OnGetKPIPropertyInfo(ByRef pList As %String, pPropNo As %Integer, pModelId As %String = "") As %Status
{
	if (pPropNo<=1) {
	    // first add the result number
	    set pList($i(pPropNo)) = "resultNumber" 
	    set pList(pPropNo,"columnNo") = 1
	    
	    // then add all regular result columns
	    set qRT = ##class(%Dictionary.CompiledParameter).%OpenId(..#IKQUERYCLASS _"||"_ ..#IKQUERYNAME_"RT")
	    quit:qRT="" $$$ERROR($$$ParameterDoesNotExist, ..#IKQUERYCLASS _"."_ ..#IKQUERYNAME_"RT")
    
	    set qRTcolumns = $lfs(qRT.Default,","), ptr=0, pos=1
	    while $listnext(qRTcolumns, ptr, col) {
	        set col = $piece(col,":",1)
        
	        set pList($i(pPropNo)) = col
	        set pList(pPropNo,"columnNo") = $i(pos)
	    }
	}
	Quit ##super(.pList, pPropNo, pModelId)
}

///  <p>Implementation of <method>%OnExecute</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Configures and fires the query registered for this GenericKPI instance, given the active filter criteria.</p>
Method %OnExecute() As %Status
{
    set tSC = $$$OK
    try {
	    set domainId = ..GetDomainId()
	    quit:'+domainId
        
        kill filters
        do ..%filterValues.%CopyToArray(.filters)
        
        // now build the query call
		set qMethod = ##class(%Dictionary.CompiledMethod).%OpenId(..#IKQUERYCLASS _"||"_ ..#IKQUERYNAME)
		quit:qMethod=""
		
		kill tParams
		set tHasResultParam = 0
		set qParams = qMethod.FormalSpecParsed, ptr=0, pos=0
		while $listnext(qParams, ptr, p) {
			set name = $zconvert($li(p,1),"U")
			set type = $li(p,2)
			set mode = $li(p,3)
			set default = $li(p,4)
			set pos = $i(pos)
			
			if (name="RESULT") || (name="PRESULT") {
				set tHasResultParam = 1
				continue
			}
			
			// skip output parameters
			if (mode'="") {
				set x = $i(tParams)
				continue
			}
		
			if (name="DOMAINID") || (name="PDOMAINID") {
				set tParams($i(tParams)) = ..GetDomainId()
			} elseif (name="PAGE") || (name="PPAGE") {
				set tParams($i(tParams)) = ..GetCurrentPage(domainId)
			} elseif (name="PAGESIZE") || (name="PPAGESIZE") {
				set filterPageSize = $g(filters("IK:QPARAM:"_pos_":"_name))
				set tParams($i(tParams)) = $s(filterPageSize'="":filterPageSize, 1:..#IKPAGESIZE)
			} elseif (name="FILTER") || (name="PFILTER") {
        		set tParams($i(tParams)) = ..BuildCurrentFilter(.tSC)
			} elseif (name="FILTERMODE") || (name="PFILTERMODE") {
				set tParams($i(tParams)) = $$$FILTERALLANDSORT
			} else {
				set value = $g(filters("IK:QPARAM:"_pos_":"_name))
				if (value="") {
					set x = $i(tParams)
					continue
				}
				set tParams($i(tParams)) = $s(type["String":value, type["List":$lfs(value), 1:value)
			}
		}
		quit:$$$ISERR(tSC)
		
        if (tHasResultParam) {
	        set tSC = $classmethod(..#IKQUERYCLASS, ..#IKQUERYNAME, .result, tParams...)
        } else {
            set tSC = $classmethod(..#IKQUERYCLASS, ..#IKQUERYNAME, tParams...)
        }
        quit:$$$ISERR(tSC)
        
        // go through the results and prepend the resultNumber column
        set i=""
        for {
	        set i = $order(result(i),1,d)
	        quit:i=""
	        set result(i) = $lb(i)_d
        }
        
        // build displayProps
	    set qRT = ##class(%Dictionary.CompiledParameter).%OpenId(..#IKQUERYCLASS _"||"_ ..#IKQUERYNAME_"RT")
	    if (qRT="") { set tSC = $$$ERROR($$$ParameterDoesNotExist, ..#IKQUERYCLASS _"."_ ..#IKQUERYNAME_"RT")  quit }
        kill displayProps
        set displayProps("resultNumber") = 1
        set qRTcolumns = $lfs(qRT.Default,","), ptr=0, pos=1
        while $listnext(qRTcolumns, ptr, col) {
	        set col = $piece(col,":",1)
	        set pos = $i(pos)
	        set displayProps(col) = pos
        }
        
        set tSC = ..DisplayResult(.result, $g(filters("IK:PARAM:NAMECOLUMN"),1), .displayProps)
    } catch(ex) {
        set tSC = ex.AsStatus()
    }
    quit tSC
}

///  <p>Implementation of <method>%OnGetListingResultSet</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Triggers the applicable GetBy*** query from <class>%iKnow.Queries.SourceAPI</class>, taking into account the
///  selected values in the KPI and any active filters.</p>
ClassMethod %OnGetListingResultSet(ByRef pFilters As %String, ByRef pSelection As %String, pListingName As %String = "", Output pRS As %SQL.StatementResult) As %Status
{
	set domainId = ..GetDomainIdStatic()
	
	set pRS = ##class(%ResultSet).%New()
	set pRS.ClassName = "%iKnow.Queries.SourceQAPI"
	
	if (..#IKQUERYCLASS = "%iKnow.Queries.EntityAPI") {
		set pRS.QueryName = "GetByEntityIds"
		set idColumn = "entUniId"
	} elseif (..#IKQUERYCLASS = "%iKnow.Queries.CrcAPI") {
		set pRS.QueryName = "GetByCrcIds"
		set idColumn = "crcUniId"
	} elseif (..#IKQUERYCLASS = "%iKnow.Queries.PathAPI") {
		set pRS.QueryName = "GetByPathIds"
		set idColumn = "pathId"
	} else {
		quit $$$ERROR($$$GeneralError, "Cannot derive a Listing for this KPI")
	}
	
	// now find the ids corresponding to the idColumn
    set qRT = ##class(%Dictionary.CompiledParameter).%OpenId(..#IKQUERYCLASS _"||"_ ..#IKQUERYNAME_"RT")
    quit:qRT="" $$$ERROR($$$ParameterDoesNotExist, ..#IKQUERYCLASS _"."_ ..#IKQUERYNAME_"RT")
    set qRTcolumns = $lfs(qRT.Default,","), ptr=0, pos=1, idColumnIndex = 0
    while $listnext(qRTcolumns, ptr, col) {
        set col = $piece(col,":",1)
        set pos = $i(pos)
        if (col = idColumn) {
	        set idColumnIndex = pos
	        quit
        }
    }
    quit:'idColumnIndex $$$ERROR($$$GeneralError, "Failed to find id column for this query")
    
	// now find the actual id values based on the cached data
    set startRow = +$p(pSelection("selectedRange"),",",1), endRow = +$p(pSelection("selectedRange"),",",3), ids = ""
    for row=startRow:1:endRow {
	    set ids = ids _ $lb(..GetDisplayedValue(row, idColumnIndex))
    }
    
    // now derive filter for pFilters
    set filter = ..BuildCurrentFilterStatic(.pFilters, .tSC)
    quit:$$$ISERR(tSC) tSC
    set filterString = $s($isobject(filter):filter.ToString(), 1:"")
	
	set params = 6
	set params(1) = domainId
	set params(2) = $lts(ids)
	set params(3) = 0
	set params(4) = 0
	set params(5) = filterString
	set params(6) = $$$UNION
	
	set tSC = pRS.Execute(params...)
	Quit tSC
}

}
