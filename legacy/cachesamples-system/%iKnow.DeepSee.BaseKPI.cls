/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IKInclude

///  <p>This is the base class for iKnow-based KPIs, offering a number of utility methods to fetch the
///  current filter and query result page settings.</p>
///  <p><i>For internal use only</i> - use <class>%iKnow.DeepSee.GenericKPI</class> or
///  <class>%iKnow.DeepSee.SourceListFilterKPI</class> instead.</p>
Class %iKnow.DeepSee.BaseKPI Extends %DeepSee.KPI [ Abstract, Deprecated, System = 4 ]
{

///  Override this parameter to specify the iKnow domain for the KPI's query to access.
Parameter IKDOMAINID As INTEGER = 1;

///  Override this parameter and <parameter>IKMEASURENAME</parameter> to specify the iKnow
///  domain linked to a particular iKnow measure for the KPI's query to access.
Parameter IKCUBENAME As STRING;

///  Override this parameter and <parameter>IKCUBENAME</parameter> to specify the iKnow
///  domain linked to a particular iKnow measure for the KPI's query to access.
Parameter IKMEASURENAME As STRING;

///  Override this parameter to specify the default page size for the KPI's query. 
///  This can be overridden per widget through a filter.
Parameter IKPAGESIZE As INTEGER = 10;

///  Override this parameter to include hidden metadata fields when displaying metadata-based filters for this KPI.
Parameter IKINCLUDEHIDDENMETADATA As BOOLEAN = 0;

///  Utility method to fill up %data and %seriesNames based on an iKnow query result
Method DisplayResult(ByRef result, nameIndex As %Integer, ByRef properties) As %Status [ Private ]
{
	set domainId = ..GetDomainId()
	quit:domainId="" $$$ERROR($$$IKDomainNotExists)
	
	kill ^IRIS.Temp.IK.DSCache("Displayed", domainId, ..%GetKPIName())
	
    set n = "", i = 0
    kill ..%seriesNames, ..%data
    for {
        set n = $order(result(n), 1, d)
        quit:n=""
        set i = i + 1
        set ..%seriesNames(i) = $s(nameIndex:$list(d,nameIndex), 1:n)
        
        set propName = ""
        for {
            set propName = $order(properties(propName), 1, index)
            quit:propName=""
            
            set ^IRIS.Temp.IK.DSCache("Displayed", domainId, ..%GetKPIName(), i, index) = $li(d, index)
            set ..%data(i, propName) = $list(d, index)
        }
    }
    set ..%seriesCount = i
    
    quit $$$OK
}

///  Retrieves the value of the column identified by <i>columnIndex</i> for the row currently selected in the KPI
ClassMethod GetSelectedColumnValue(pContext As %ZEN.proxyObject, columnIndex As %Integer) As %String
{
	quit ..GetDisplayedValue(pContext.currItemNo, columnIndex)
}

///  Retrieves the cell value currently displayed at a given row and column index.
ClassMethod GetDisplayedValue(rowIndex As %Integer, columnIndex As %Integer) As %String
{
	set domainId = ..GetDomainIdStatic()
	quit $g(^IRIS.Temp.IK.DSCache("Displayed", domainId, ..%GetKPIName(), rowIndex, columnIndex))
}

///  Shorthand to get the domain ID from an instance context
Method GetDomainId() As %Integer [ Final, Private ]
{
	if (..#IKCUBENAME'="") { 
		quit ##class(%iKnow.DeepSee.CubeUtils).GetDomainId(..#IKCUBENAME, ..#IKMEASURENAME) 
	}
    quit ..#IKDOMAINID
}

///  Shorthand to get the domain ID from a static context
ClassMethod GetDomainIdStatic(pContext As %ZEN.proxyObject = "") As %Integer [ Final, Private ]
{
	if (..#IKCUBENAME'="") { 
		quit ##class(%iKnow.DeepSee.CubeUtils).GetDomainId(..#IKCUBENAME, ..#IKMEASURENAME) 
	}
    quit ..#IKDOMAINID
}

///  <p>Utility method to build an <class>%iKnow.Filters.Filter</class> object based on the current DeepSee
///  dashboard-wide filter settings (fetched from <property>%filterValues</property>). This method will translate
///  all DeepSee filters for which there is a metadata field having the same name as the dimension
///  level referred to in <property>%filterValues</property>, eventually mapped through ^IRIS.IKD.DimFilterMapping</p>
Method BuildCurrentFilter(Output pSC As %Status) As %iKnow.Filters.Filter [ Final, Private ]
{
	kill arr
    do ..%filterValues.%CopyToArray(.arr)
	quit ..BuildCurrentFilterStatic(.arr, .pSC)
}

///  <p>Utility method to translate the array of DeepSee filter specs in <i>pFilters</i> into an
///  iKnow <class>%iKnow.Filters.Filter</class> object. For DeepSee-managed domains, this will
///  result in a <class>%iKnow.DeepSee.MDXFilter</class> object.</p>
ClassMethod BuildCurrentFilterStatic(ByRef pFilters, Output pSC As %Status) As %iKnow.Filters.Filter [ Final, Private ]
{
	set pSC = $$$OK, tGroupFilter = ""
	try {
		set tDomainId = ..GetDomainIdStatic()
		quit:tDomainId=""
		quit:'$d(pFilters)
		
		if $$$GETPARAMNODEF(tDomainId,$$$IKPDEEPSEEDOMAIN) {
			
			set member = "", tMDX = "", tMDXParts = 0
		    for {
		        set member = $o(pFilters(member),1,spec)
		        quit:member=""
		        continue:spec=""
		        
		        set spec = $zstrip(spec, "<>W")
		        set tNOT = ($e(spec,1,4)="%NOT")
		        set:tNOT spec = $zstrip($e(spec,5,*),"<W")
		        continue:$e(member,1,10)="IK:QPARAM:"
		        continue:$e(member,1,9)="IK:PARAM:" // BDB638
		        
		        if $e(spec)'="{" {
			        set spec = member_"."_spec
		        } else {
			        set spec = $e(spec,2,*-1), len=$length(spec,","), fspec=""
			        for i=1:1:len {
				        set fspec = fspec _ $lb(member_"."_$p(spec,",",i))
			        }
			        set spec = "{"_$lts(fspec)_"}"
		        }
		        
			    set:tNOT spec = "%NOT("_spec_")"
		        set tMDX = tMDX _ $lb(spec)
		        set tMDXParts = tMDXParts + 1
		    }
		    set tMDX = $lts(tMDX,",")
		    set:tMDXParts>1 tMDX = "NONEMPTYCROSSJOIN("_tMDX_")"
		    
		    set tGroupFilter = $s(tMDXParts:##class(%iKnow.DeepSee.MDXFilter).%New(tDomainId, tMDX), 1:"")
			
		} else {
		
		    set tGroupFilter = ##class(%iKnow.Filters.GroupFilter).%New(tDomainId, $$$GROUPFILTERAND)
		    set tFilterSpec = ""
		    for {
		        set tFilterSpec = $o(pFilters(tFilterSpec),1,tFilterValue)
		        quit:tFilterSpec=""
		        continue:tFilterValue=""
	        
	        	set tFilterName = tFilterSpec
		        continue:$e(tFilterName,1,10)="IK:QPARAM:"
		        continue:$e(tFilterName,1,9)="IK:PARAM:"
	        	set tUseMetadataFilter = ($e(tFilterName,1,11)="IK:MDFIELD:")
	        	set:tUseMetadataFilter tFilterName = $e(tFilterName,12,*)
	        	
	        	set tNegateFilter = ($e(tFilterValue,1,4)="%NOT")
	        	set:tNegateFilter tFilterValue = $zstrip($e(tFilterValue,5,*),"<W")
	        	set tFilter = ##class(%iKnow.Filters.GroupFilter).%New(tDomainId, $$$GROUPFILTEROR, tNegateFilter)
			      
			    set:tFilterValue="{" tFilterValue = $e(tFilterValue,2,*-1)
			    set tFilterCount = $length(tFilterValue,",")
			    for i = 1:1:tFilterCount {
				    set tFV = $piece(tFilterValue,",",i)
				    
			        if (tUseMetadataFilter) {
			        	do tFilter.AddSubFilter(##class(%iKnow.Filters.SimpleMetadataFilter).%New(tDomainId, tFilterName, "=", tFV))
			        } else {
				        do tFilter.AddSubFilter(##class(%iKnow.DeepSee.MDXFilter).%New(tDomainId, tFilterName_"."_tFV, ..#IKCUBENAME, ..#IKMEASURENAME))
			        }
		        }
		        do tGroupFilter.AddSubFilter(tFilter)
		    }
		    
		    if (tGroupFilter.GetSubFilterCount() = 0) {
		        set tGroupFilter = ""
		    }
		}
	} catch (ex) {
		set pSC = ex.AsStatus()
	}
	quit tGroupFilter
}

///  Returns the currently displayed result page (see iKnow query paging)
ClassMethod GetCurrentPage(domainId As %Integer) As %Integer [ Final, Private ]
{
	quit $g(^IRIS.Temp.IK.DSCache("KpiPage", domainId, ..%GetKPIName()), 1)
}

///  Resets the current page
ClassMethod ResetPage(domainId As %Integer) As %Status [ Final, Private ]
{
	set ^IRIS.Temp.IK.DSCache("KpiPage", domainId, ..%GetKPIName()) = ""
	quit $$$OK
}

///  Advances the current query page by 1
ClassMethod NextPage(pContext As %ZEN.proxyObject) As %Status [ Final, Private ]
{
	set domainId = ..GetDomainIdStatic(pContext)
	set ^IRIS.Temp.IK.DSCache("KpiPage", domainId, ..%GetKPIName()) = ..GetCurrentPage(domainId)+1
	set pContext.command = "refresh:"
	Quit $$$OK
}

///  Decreases the current query page by 1, with a minimum of 1 (first query result page)
ClassMethod PreviousPage(pContext As %ZEN.proxyObject) As %Status [ Final, Private ]
{
	set domainId = ..GetDomainIdStatic(pContext)
	set prevPage = ..GetCurrentPage(domainId)-1
	set ^IRIS.Temp.IK.DSCache("KpiPage", domainId, ..%GetKPIName()) = $s(prevPage<1:1, 1:prevPage)
	set pContext.command = "refresh:"
	Quit $$$OK
}

///  <p>Implementation of <method>%OnGetFilterList</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Unless this KPI is linked to a DeepSee-managed domain (through 
///  <parameter>IKCUBENAME</parameter> and <parameter>IKMEASURENAME</parameter>, 
///  adds all public metadata fields for this KPIs domain at the end of the <i>pFilters</i> list.
///  Also adds a Value and Name column to be controlled through dashboard filters.</p>
ClassMethod %OnGetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ##super(.pFilters, pDataSourceName)
		quit:$$$ISERR(tSC)
	
		set tDomainId = ..GetDomainIdStatic()
		quit:'tDomainId  // simply quit $$$OK here, as throwing an error here is quite noisy at the dashboard level
	
		if $$$GETPARAMNODEF(tDomainId,$$$IKPDEEPSEEDOMAIN) {
		
			// copy filters from DeepSee cube
			set tSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(..#IKCUBENAME_".cube",.tFilters)
			quit:$$$ISERR(tSC)
		
			set i = ""
			for {
				set i = $order(tFilters(i), 1, data)
				quit:i=""
			
				set pFilters($i(pFilters)) = $lb($lg(data,2), $lg(data,1),,1)
			}
		
		} else {
		
			// add iKnow-based metadata filters
			set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFields(.fields, tDomainId, ..#IKINCLUDEHIDDENMETADATA)
			quit:$$$ISERR(tSC)
	
			set j = ""
			for {
				set j = $order(fields(j),1,f)
				quit:j=""
		
				set mdfName = $li(f,2)
				set pFilters($i(pFilters)) = $lb("IK:MDFIELD:"_mdfName, mdfName,, 1)
			}
		}
	
		// add series name column
		set isInList = 0
		for j=1:1:+$g(pFilters) { if $lg(pFilters(j),1)="IK:PARAM:NAMECOLUMN" { set $li(pFilters(j),2) = "Series name column", isInList = 1  quit } }
		set:'isInList pFilters($i(pFilters)) = $lb("IK:PARAM:NAMECOLUMN", "Series name column", 1, 0)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

///  <p>Implementation of <method>%OnGetFilterMembers</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>When querying for an iKnow metadata-based filter (prefixed with "IK:MDFIELD:"), it will retrieve 
///  the available values for that metadata field in the current iKnow domain.</p>
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "") As %Status
{
	if ($e(pFilter,1,11)="IK:MDFIELD:") {
	
		set domainId = ..GetDomainIdStatic()
		
		set mdfName = $e(pFilter, 12, *)
		set mdfId = +##class(%iKnow.Queries.MetadataAPI).GetFieldId(domainId, mdfName, .tSC)
		quit:$$$ISERR(tSC) tSC
		quit:'mdfId tSC
		
		set mdfObj = ##class(%iKnow.Objects.MetadataField).PKINDEXOpen(domainId, mdfId)
		
		set tSC = ##class(%iKnow.Queries.MetadataAPI).GetFieldValuesById(.values, domainId, mdfId, 0, 0)
		quit:$$$ISERR(tSC) tSC
	
		set:pSearchKey'="" pSearchKey = $zconvert(pSearchKey,"U")
	
		kill pMembers
		set j = ""
		for {
			set j = $order(values(j),1,v)
			quit:j=""
		
			set (value, displayValue) = $li(v)
			if (pSearchKey'="") {
				continue:'$find($zconvert(value,"U"),pSearchKey)
			}
			
			if (value '= "") && (mdfObj.DataType = $$$MDDTDATE) {
				set displayValue = $s(+$p(value,",",2):$zdatetime(value), 1:$zdate(value))
			}
		
			set pMembers($i(pMembers)) = $lb(displayValue, value)
		}
		quit tSC
		
	} elseif (..#IKCUBENAME'="") && ($e(pFilter)="[") {
		
		set tMaxMembers = 100
		set tSC = ##class(%DeepSee.Utils).%GetDimensionMembers(..#IKCUBENAME, pFilter, "", .tValues, tMaxMembers, .tMemberClass)
		
		if $$$ISOK(tSC) {
		
			if (pSearchKey="") {
				
				set i = ""
				for {
					set i = $order(tValues(i),1,data)
					quit:i=""
					
					set pMembers($i(pMembers)) = $lb($li(data,2), $li(data,1))
				}
				
			} else {
				
				set pSearchKey = $$$LOWER(pSearchKey)
				
				// if we got all members, we can search directly
				if ($o(tValues(""),-1)<tMaxMembers) {
					
					set i = ""
					for {
						set i = $order(tValues(i),1,data)
						quit:i=""
						continue:($e($$$LOWER($li(data,2)),1,$l(pSearchKey))'=pSearchKey)
					
						set pMembers($i(pMembers)) = $lb($li(data,2), $li(data,1))
					}
					
				} else {
					
					// otherwise, we'll have to query the member class
					if (tMemberClass["%DeepSee") {
						
						// use %DeepSee.Time.AbstractLevel.%GetMembers() ?
						quit $$$ERROR($$$NotImplemented)
						
					} else {
						
						// normal data dimension: go through star table
						set tTable = ##class(%DeepSee.Utils).%GetSQLTableName(tMemberClass)
						set tTable = ##class(%iFind.Utils).QuoteDelimitedIdentifier(tTable)
						set tColumn = $g($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..#IKCUBENAME),"star",tMemberClass,"primary"))
					
						set tRS = ##class(%ResultSet).%New()
						set tSC = tRS.Prepare("SELECT ID, "_tColumn_" FROM "_tTable_" WHERE "_tColumn_" LIKE '"_pSearchKey_"%'")
						quit:$$$ISERR(tSC)
					
						set tSC = tRS.Execute()
						quit:$$$ISERR(tSC)
					
						while tRS.Next(.tSC) {
							quit:$$$ISERR(tSC)
							set tValue = tRS.Get(tColumn), tId = tRS.Get("ID")
							set pMembers($i(pMembers)) = $lb(tValue, "&["_tId_"]")
						}
					}
				}
			}
			
			quit tSC
		}
	}
	
	quit ##super(pFilter, .pMembers, pSearchKey, pDataSourceName)
}

///  <p>Implementation of <method>%OnDashboardAction</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Takes care of the nextPage and previousPage <i>pAction</i> values.</p>
ClassMethod %OnDashboardAction(pAction As %String, pContext As %ZEN.proxyObject, pDataSourceName As %String = "") As %Status
{
	if (pAction = "nextPage") {
		set tSC = ..NextPage(pContext)
	} elseif (pAction = "prevPage") {
		set tSC = ..PreviousPage(pContext)
    } else {
	    set tSC = ##super(pAction, pContext, pDataSourceName)
    }
	Quit tSC
}

///  <p>Implementation of <method>%OnGetFilterList</method> method, inherited from <class>%DeepSee.KPI</class>. Do not invoke directly.</p>
///  <p>Adds nextPage and prevPage actions.</p>
ClassMethod %OnGetActionList(ByRef pActions As %List, pDataSourceName As %String = "") As %Status
{
	set tSC = ##super(.pActions, pDataSourceName)
	quit:$$$ISERR(tSC) tSC
	
	set pActions($i(pActions)) = $lb("nextPage","Next page")
	set pActions($i(pActions)) = $lb("prevPage","Previous page")
	
	quit tSC
}

}
