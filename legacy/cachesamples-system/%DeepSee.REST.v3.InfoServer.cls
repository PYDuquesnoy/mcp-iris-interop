/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is responsible for creating the JSON response to the DeepSee REST 
/// informational services. For examples and a full list of available services see the documentation
/// for <class>%DeepSee.REST.v3<.class>.
Class %DeepSee.REST.v3.InfoServer Extends %DeepSee.REST.REST
{

XData UrlMap
{
<Routes>
	<Route Url="/Config/(.*)" Method="GET" Call="GetConfig"/>
	<Route Url="/Config/(.*)" Method="POST" Call="PostConfig"/>
	<Route Url="/Config/(.*)" Method="DELETE" Call="DeleteConfig"/>

	<!-- Get info about availible filters and their values -->
	<Route Url="/Filters/(.*)" Method="GET" Call="WriteFiltersForDataSource"/>
	<Route Url="/Filters/(.*)" Method="POST" Call="WriteFiltersForDataSource"/>
	<Route Url="/FilterMembers/(.*)" Method="GET" Call="WriteFilterMembers"/>
	<Route Url="/FilterMembers/(.*)" Method="POST" Call="WriteFilterMembers"/>
	<Route Url="/TermLists" Method="GET" Call="WriteTermlistList"/> 

	<!-- Get info about FolderItems on the system -->
	<Route Url="/Dashboards" Method="GET" Call="WriteDashboardList"/>
	<Route Url="/Dashboards" Method="POST" Call="WriteDashboardList"/> 
    <Route Url="/Favorites" Method="GET" Call="WriteFavoritesList"/>

	<!-- Get info about the available cubes on the system -->
	<Route Url="/Cubes" Method="GET" Call="WriteCubeList"/>
	<Route Url="/Cubes" Method="POST" Call="WriteCubeList"/>
	<Route Url="/Listings/(.*)" Method="GET" Call="WriteListingsForCube"/>
	<Route Url="/Listings/(.*)" Method="POST" Call="WriteListingsForCube"/>
	<Route Url="/Measures/(.*)" Method="GET" Call="WriteMeasuresForCube"/>
	<Route Url="/Measures/(.*)" Method="POST" Call="WriteMeasuresForCube"/>
	<Route Url="/ListingFields/(.*)" Method="GET" Call="WriteListingFieldsForCube"/>
	<Route Url="/ListingFields/(.*)" Method="POST" Call="WriteListingFieldsForCube"/>
	<Route Url="/QualityMeasures/(.*)" Method="GET" Call="WriteQualityMeasuresForCube"/>
	<Route Url="/QualityMeasures/(.*)" Method="POST" Call="WriteQualityMeasuresForCube"/>
	<Route Url="/NamedFilters/(.*)" Method="GET" Call="WriteNamedFiltersForCube"/>
	<Route Url="/NamedFilters/(.*)" Method="POST" Call="WriteNamedFiltersForCube"/>
	<Route Url="/PivotVariables/(.*)" Method="GET" Call="WritePivotVariablesForCube"/>
	<Route Url="/PivotVariables/(.*)" Method="POST" Call="WritePivotVariablesForCube"/>
	<Route Url="/PivotVariableDetails/(.*)" Method="GET" Call="WriteDetailsForPivotVariable"/>
	<Route Url="/PivotVariableDetails/(.*)" Method="POST" Call="WriteDetailsForPivotVariable"/>
	
	<!-- Get info about DataSources on the system -->
	<Route Url="/DataSources/:sourceType" Method="GET" Call="WriteDataSourceList"/>
	<Route Url="/DataSources/:sourceType" Method="POST" Call="WriteDataSourceList"/>
	<Route Url="/Pivots" Method="GET" Call="WritePivotList"/>
	<Route Url="/Pivots" Method="POST" Call="WritePivotList"/>
	<Route Url="/KPIs" Method="GET" Call="WriteKPIList"/>
	<Route Url="/KPIs" Method="POST" Call="WriteKPIList"/>
	<Route Url="/Metrics" Method="GET" Call="WriteMetricList"/>

	<!-- Test method-->
	<Route Url="/TestConnection" Method="GET" Call="Test"/>
	<Route Url="/TestConnection" Method="POST" Call="Test"/>
   
 </Routes>
}

/// The POST action of on the /Info/Config entry point allows any user to set their own config for a
/// given <var>pApplication</var>. Optionally a user with admin privileges can POST a USER and ACTION 
/// to manage another user's configuration. An admin can also manage a publicly available configuration
/// default by assigning the configuration to the "_PUBLIC" user.
ClassMethod PostConfig(namespace, pApplication As %String = "") As %Status
{
	Set tSC = $$$OK

	Try {
		If $system.Security.CheckUserPermission($UserName,"%DeepSee_Admin","USE") {
			// An admin has the option of managing configuration for other users
			Set tAction = %request.Content.ACTION
			Set tUser = $$$UPPER($S(%request.Content.USER'="":%request.Content.USER,1:$UserName))

			If (tAction="GET") {
				// Dispatch to Fetch of an existing config
				Set tSC = ..GetConfig(namespace,pApplication,tUser)
			} 
			ElseIf (tAction="DELETE") {
				// Dispatch to Delete a configuration
				Set tSC = ..DeleteConfig(namespace,pApplication,tUser)
			}
			Else {
				// Assume a SET operation if no other action is defined so that it matches the end user option
 				Set tSC = ..SetConfig(namespace,pApplication,tUser)
			}
		}
		Else {
			// A regular user gets directed to the personal set option of this endpoint.
			Set tSC = ..SetConfig(namespace,pApplication)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Fetch custom configuration for <var>pApplication</var> if one is defined for the current user. If no custom
/// configuration is stored for the current user, this then attempts to fetch from the _PUBLIC user's configuration.<br>
/// A user with administrative privileges may retrieve the configuration information for any user by specifying the <var>pUser</var> parameter.
ClassMethod GetConfig(namespace, pApplication As %String = "", pUser = {$UserName}) As %Status
{
	Set tSC = $$$OK

	Try {
		// DP-436126 - If this was directly called by an underprivileged user, reset the requested user to the 
		// the current $UserName. If the user is an admin, allow for fetching an application for another user.
		Set:'$system.Security.CheckUserPermission($UserName,"%DeepSee_Admin","USE") pUser = $UserName
		
		Set tConfigStr = ""
		If (pApplication'="") {
			
			Set tConfigStr = $S($D($$$DeepSeePreferencesGLVN($$$UPPER(pUser),"config",pApplication),tSavedConfig):tSavedConfig,
								$D($$$DeepSeePreferencesGLVN("_PUBLIC","config",pApplication),tSavedConfig):tSavedConfig,
								1:"")
		}

		Set tResponseObj = ..%ConstructResponseObject(.tInfoObj,.tResultObj,.tProvider)
		Set tInfoObj.Application = pApplication
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)	
		Set tInfoObj.Action = "GET"

		Set tResponseObj.Result = {}.%FromJSON(tConfigStr)

		Set tSC = tProvider.%ObjectToJSON(tResponseObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

	Quit tSC
}

/// Store custom confguration information for the current user. One JSON document may be stored per user under
/// any given <var>pApplication</var>.<br> 
/// Users with administrative privileges may set configurations for other users by supplying the <var>pUser</var>
/// parameter. Configurations can be assigned to the _PUBLIC user and will be available to all users that do not
/// have their own configuration defined.
ClassMethod SetConfig(namespace, pApplication As %String = "", pUser = {$UserName}) As %Status
{
	Set tSC = $$$OK

	Try {
		// DP-436126 - If this was directly called by an underprivileged user, reset the requested user to the 
		// the current $UserName. If the user is an admin, allow for setting an application configuration
		// for another user.
		Set:'$system.Security.CheckUserPermission($UserName,"%DeepSee_Admin","USE") pUser = $UserName

		Set tConfig = %request.Content.CONFIG
		Set:(pApplication'="") $$$DeepSeePreferencesGLVN($$$UPPER(pUser),"config",pApplication) = $S($IsObject(tConfig):tConfig.%ToJSON(),1:"")

		Set tResponseObj = ..%ConstructResponseObject(.tInfoObj,.tResultObj,.tProvider)
		Set tInfoObj.Application = pApplication
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)
		Set tInfoObj.Action = "SET"

		Set tSC = tProvider.%ObjectToJSON(tResponseObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

	Quit tSC
}

/// Delete a custom confguration information for the current user. Users with administrative privileges can use 
/// <var>pUser</var> to remove configuration information for a specific user.
ClassMethod DeleteConfig(namespace, pApplication As %String = "", pUser = {$UserName}) As %Status
{
	Set tSC = $$$OK

	Try {
		// DP-436126 - If this was directly called by an underprivileged user, reset the requested user to the 
		// the current $UserName. If the user is an admin, allow for removing an application configuration
		// for another user.
		Set:'$system.Security.CheckUserPermission($UserName,"%DeepSee_Admin","USE") pUser = $UserName
		
		Kill:(pApplication'="") $$$DeepSeePreferencesGLVN($$$UPPER(pUser),"config",pApplication)

		Set tResponseObj = ..%ConstructResponseObject(.tInfoObj,.tResultObj,.tProvider)
		Set tInfoObj.Application = pApplication
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)
		Set tInfoObj.Action = "DELETE"

		Set tSC = tProvider.%ObjectToJSON(tResponseObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

	Quit tSC
}

/// Retrieve the list of available filters for a given <var>pCube</var>
ClassMethod WriteFiltersForDataSource(namespace As %String, pDataSource) As %Status
{
	// Method added by DTB210
	Set pDataSource = $ZCONVERT($ZCONVERT(pDataSource ,"I","URL") ,"I","UTF8")
	
	Try {
		// DTB234 - Add support for kpis as dataSource. If no extension is provided, 
		// assume the datasource is a cube.
		Set tDataSourceType = "cube"
		If $E($$$LOWER(pDataSource),*-4,*)=".cube" {
			Set tDataSourceType = "cube"
			Set pDataSource = $E(pDataSource,1,*-5)
			
			If '##class(%DeepSee.Utils).%CubeExists(pDataSource,.tSC) Quit		// DTB297
		}
		ElseIf $E($$$LOWER(pDataSource),*-3,*)=".kpi" {
			Set tDataSourceType = "kpi"
			Set pDataSource = $E(pDataSource,1,*-4)
			
			If '##class(%DeepSee.Utils).%KPIExists(pDataSource,.tSC) Quit		// DTB297
		}
		Else {
			// DTB297 - Default case, where there is no recognizable extension
			If '##class(%DeepSee.Utils).%CubeExists(pDataSource,.tSC) Quit
		}

		Set pDataSource = pDataSource _ "." _ tDataSourceType
	    Set tFetchSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(pDataSource,.tFilters)
	     
	    If $$$ISOK(tFetchSC)&&('$D(tFilters)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoFilters,pDataSource)
	    }
	   	
	   	// DTB240 - Refactor using constructor API
    	Set tSC = ..%ConstructResponseFromArray(.tFilters,$lb("caption","value","type"),"Filters",tFetchSC,.tFilterObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

    	Set tFilterObj.Info.DataSource = pDataSource
    	Set tFilterObj.Info.DataSourceType = tDataSourceType
    	Set tFilterObj.Info.Error = tProvider.%StatusToDynamicObject(tSC)
    	
    	Set tSC = tProvider.%ObjectToJSON(tFilterObj)
    	// -DTB212
   	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	// DTB220
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

	Quit tSC
}

/// Return the available members for a filter defined by <var>pSpec</var> within the context of <var>pCube</var>.
ClassMethod WriteFilterMembers(namespace As %String, pUrl) As %Status
{
	// Method added by DTB210
	Set tUrl = $ZCONVERT($ZCONVERT(pUrl ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		// DTB297 - Examine the incoming URL and attempt to determine if it has the form
		//   dataSource/filterSpec
		// Both dataSource and filterSpec support slashes
		Set tDataSource = ..%ExtractDatasourceName(tUrl,"cube,kpi",.tFilterSpec,.tSC)
		If $$$ISERR(tSC) Quit
		
		// DTB234 - Add support for kpis as dataSource. If no extension is provided, 
		// assume the datasource is a cube.
		Set tDataSourceType = "cube"
		If $E($$$LOWER(tDataSource),*-4,*)=".cube" {
			Set tDataSourceType = "cube"
			Set tDataSource = $E(tDataSource,1,*-5)
			
			If '##class(%DeepSee.Utils).%CubeExists(tDataSource,.tSC) Quit		// DTB297
		}
		ElseIf $E($$$LOWER(tDataSource),*-3,*)=".kpi" {
			Set tDataSourceType = "kpi"
			Set tDataSource = $E(tDataSource,1,*-4)
			
			If '##class(%DeepSee.Utils).%KPIExists(tDataSource,.tSC) Quit		// DTB297
		}
		Else {
			// DTB297 - Default case, where there is no recognizable extension
			If '##class(%DeepSee.Utils).%CubeExists(tDataSource,.tSC) Quit
		}

		Set tDataSource = tDataSource _ "." _ tDataSourceType 
		
		// +DTB226 - Add filters to the provider (pivotTable component)
		Set tFilters = %request.Content.RELATED
		If $IsObject(tFilters) {
			Set tRequestFilterSpec = ""
			For f=0:1:tFilters.%Size()-1 {
				Set tFilter = tFilters.%Get(f)
				Set tRelatedFilters(tFilter.spec) = tFilter.value
			}
		}
		
		Set tSearchKey = %request.Content.SEARCHKEY
		// -DTB226
		
		Set tFetchSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(tDataSource,tFilterSpec,.tMembers,.tDefaultFilterValue,tSearchKey,.tRelatedFilters,0,,.tSelectedValues)
		
		// PFS074 - Check if there is data in tMembers before checking for "INVALID FILTER"
    	If $$$ISOK(tFetchSC)&&('$D(tMembers)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoMembers,tFilterSpec,tDataSource)
	    }
		
		// DTB282 - The status of this utility can indicate success when the tMembers array contains only "Invalid Filter".
    	// Convert this to a true error for the purposes of the REST services.
    	If $$$ISOK(tFetchSC)&&($$$UPPER($LG(tMembers(1),1))="INVALID FILTER") {
	    	Set tSC = $$$ERROR($$$dsRESTInvalidFilter,tFilterSpec,tDataSource)
	    	Quit
    	}
    
    	// DTB240 - Refactor using constructor API
    	Set tSC = ..%ConstructResponseFromArray(.tMembers,$lb("text","value","description"),"FilterMembers",tFetchSC,.tMemberObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

    	Set tMemberObj.Info.DataSource = tDataSource
    	Set tMemberObj.Info.DataSourceType = tDataSourceType
    	Set tMemberObj.Info.Default = tDefaultFilterValue
    	Set tMemberObj.Info.Filter = tFilterSpec
    	
    	Set tSC = tProvider.%ObjectToJSON(tMemberObj)
    	// -DTB212
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	// DTB220
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	
	Quit tSC
}

/// Return a list of available cubes on the system.
ClassMethod WriteCubeList(namespace As %String) As %Status
{
	// Method added by DTB224
	Set tSC = $$$OK
	Try {
		Set tType = %request.Content.TYPE
		Set tType = $S((($$$LOWER(tType)="subjectareas")||($$$LOWER(tType)="cubes")):tType,1:"")
		Set tBaseCube = %request.Content.BASECUBE
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetCubeList(.tCubeList,tType,1,tBaseCube)
		If $$$ISOK(tFetchSC)&&'$D(tCubeList) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoCubes)
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tCube = $O(tCubeList(""),1,tCubeData)
	    While tCube'="" {
		    Set $LI(tCubeList(tCube),3) = $ZDT($LG(tCubeData,3),3)
	 		Set tCube = $O(tCubeList(tCube),1,tCubeData)
	    }
	    
	    // DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tCubeList,$lb("name","displayName","lastModified","type"),"Cubes",tFetchSC,.tCubeListObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151
		
		Set tCubeListObj.Info.Type = $S((tType'=""):tType,1:"all")
		Set tCubeListObj.Info.BaseCube = tBaseCube
		
		Set tSC = tProvider.%ObjectToJSON(tCubeListObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Get all data sources including "pivot", "kpi","metric"
ClassMethod WriteDataSourceList(namespace As %Status, pSource) As %Status
{
	Set pSource = $ZCONVERT($ZCONVERT(pSource ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Set tSourceLower = $$$LOWER(pSource)

	// Dispatch to the appropriate list production utility for the data source
	If (tSourceLower="pivot")
	{
		Set tSC = ..WritePivotList()
	}
	Elseif (tSourceLower="kpi")
	{
		Set tSC = ..WriteKPIList()
	}
	Elseif (tSourceLower="metric")
	{
		Set tSC = ..WriteMetricList()
	}
	Else {
		Set tSC = $$$ERROR($$$dsRESTUnknownSource)
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Retrieve the list of available KPIs.
ClassMethod WriteKPIList(namespace As %String)
{
	// Method added by DTB234
	Set tSC = $$$OK
	Try {
		Set tFetchSC = ##class(%DeepSee.Utils).%GetKPIList(.tKPIList)
		If $$$ISOK(tFetchSC)&&'$D(tKPIList) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoKPIs)
	    }
	    
	   	// DTB269 - Convert $H timestamp to ODBC format
	    Set tKPI = $O(tKPIList(""),1,tKPIData)
	    While tKPI'="" {
		    Set $LI(tKPIList(tKPI),3) = $ZDT($LG(tKPIData,3),3)
	 		Set tKPI = $O(tKPIList(tKPI),1,tKPIData)
	    }
		
		// DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tKPIList,$lb("name","caption","lastModified","type"),"KPIs",tFetchSC,.tKPIListObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tKPIListObj.Info.SourceType = "kpi"
		
		Set tSC = tProvider.%ObjectToJSON(tKPIListObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available pivots on the system. Optionally the request can control the contents of the list via POSTing the variables:<br>
/// - BASECUBE: Limit the list only to pivots that are based on this cube.<br>
/// - HIDDEN: If true, include pivots that have been stored as local copies or are currently in the trash.
ClassMethod WritePivotList(namespace As %String) As %Status
{
	// Method added by DTB224
	Set tSC = $$$OK
	Try {
		Set tBaseCube = %request.Content.BASECUBE
		Set tHidden = %request.Content.HIDDEN
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetPivotList(.tPivotList,,tBaseCube)
		If $$$ISOK(tFetchSC)&&('$D(tPivotList)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoPivots)
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tPivot = $O(tPivotList(""),1,tPivotData)
	    While tPivot'="" {
		    Set $LI(tPivotList(tPivot),3) = $ZDT($LG(tPivotData,3),3)
	 		Set tPivot = $O(tPivotList(tPivot),1,tPivotData)
	    }
	    
	    // DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tPivotList,$lb("fullName","name","lastModified","itemType"),"Pivots",tFetchSC,.tPivotListObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tPivotListObj.Info.BaseCube = tBaseCube
		Set tPivotListObj.Info.Hidden = tHidden
		Set tPivotListObj.Info.SourceType = "pivot"
		
		Set tSC = tProvider.%ObjectToJSON(tPivotListObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available metrics on the system.
ClassMethod WriteMetricList(namespace As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFetchSC = ##class(%DeepSee.Utils).%GetMetricList(.tMetricList)
		If $$$ISOK(tFetchSC)&&('$D(tMetricList)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoMetrics)
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tMetric = $O(tMetricList(""),1,tMetricData)
	    While tMetric'="" {
		    Set $LI(tMetricList(tMetric),3) = $ZDT($LG(tMetricData,3),3)
	 		Set tMetric = $O(tMetricList(tMetric),1,tMetricData)
	    }
	    
	    Set tSC = ..%ConstructResponseFromArray(.tMetricList,$lb("fullName","name","lastModified","itemType"),"Pivots",tFetchSC,.tMetricListObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tMetricListObj.Info.SourceType = "metric"
		
		Set tSC = tProvider.%ObjectToJSON(tMetricListObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available dashboards on the system.
ClassMethod WriteDashboardList(namespace As %String) As %Status
{
	// Method added by DTB224
	Set tSC = $$$OK
	Try {
		Set tFetchSC = ##class(%DeepSee.Utils).%GetDashboardList(.tDashboardList)
		If $$$ISOK(tFetchSC)&&('$D(tDashboardList)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoDashboards)
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tDashboard = $O(tDashboardList(""),1,tDashData)
	    While tDashboard'="" {
		    Set $LI(tDashboardList(tDashboard),3) = $ZDT($LG(tDashData,3),3)
	 		Set tDashboard = $O(tDashboardList(tDashboard),1,tDashData)
	    }
	    
	    // DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tDashboardList,$lb("fullName","name","lastModified","itemType"),"Dashboards",tFetchSC,.tDashListObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tSC = tProvider.%ObjectToJSON(tDashListObj)	
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available listings for <var>pDataSource</var>.
ClassMethod WriteListingsForCube(namespace As %String, pDataSource) As %Status
{
	// Method added by DTB226
	Set pDataSource = $ZCONVERT($ZCONVERT(pDataSource ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		Set tType = %request.Content.TYPE
		Set tType = $S((($$$LOWER(tType)="map")||($$$LOWER(tType)="table")):tType,1:"")
		
		If $E($$$LOWER(pDataSource),*-4,*)=".cube" {
			Set pDataSource = $E(pDataSource,1,*-5)
		}

		If '##class(%DeepSee.Utils).%CubeExists(pDataSource,.tSC) Quit
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetCubeListings(pDataSource,.tListings,tType)
		If $$$ISOK(tFetchSC)&&('$D(tListings)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoListings,pDataSource)
		}
		
		// DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tListings,$lb("name","fields","order","type","source","edit","caption"),"Listings",tFetchSC,.tListingObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tListingObj.Info.DataSource = pDataSource
		Set tListingObj.Info.Type = $S((tType'=""):tType,1:"all")
		
		Set tSC = tProvider.%ObjectToJSON(tListingObj)	
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available measures for <var>pCubeName</var>.
ClassMethod WriteMeasuresForCube(namespace As %String, pCubeName) As %Status
{
	// Method added by DTB240
	Set pCubeName = $ZCONVERT($ZCONVERT(pCubeName,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		If '##class(%DeepSee.Utils).%CubeExists(pCubeName,.tSC) Quit
		
		Set tSkipCalculated = +%request.Content.SKIPCALCULATED
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetCubeMeasures(pCubeName,.tMeasureArray,tSkipCalculated)
		
		If $$$ISOK(tFetchSC)&&('$D(tMeasureArray)) {
			Set tFetchSC = $$$ERROR($$$dsRESTNoMeasures,pCubeName)
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tMeasureArray,$lb("name","caption","type","hidden","factName"),"Measures",tFetchSC,.tMsrObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tMsrObj.Info.BaseCube = pCubeName
		Set tMsrObj.Info.SkipCalculated = tSkipCalculated
	
		Set tSC = tProvider.%ObjectToJSON(tMsrObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available listing fields for <var>pCubeName</var>.
ClassMethod WriteListingFieldsForCube(namespace As %String, pCubeName) As %Status
{
	// Method added by DTB240
	Set pCubeName = $ZCONVERT($ZCONVERT(pCubeName,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		If '##class(%DeepSee.Utils).%CubeExists(pCubeName,.tSC) Quit
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetCubeListingFields(pCubeName,.tListingFieldArray)
		
		If $$$ISOK(tFetchSC)&&('$D(tListingFieldArray)) {
			Set tFetchSC = $$$ERROR($$$dsRESTNoListingFields,pCubeName)
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tListingFieldArray,$lb("caption","expression","description"),"ListingFields",tFetchSC,.tListingFieldObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tListingFieldObj.Info.BaseCube = pCubeName
	
		Set tSC = tProvider.%ObjectToJSON(tListingFieldObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available quality measures for <var>pCubeName</var>.
ClassMethod WriteQualityMeasuresForCube(namespace As %String, pCubeName) As %Status
{
	// Method added by DTB240
	Set pCubeName = $ZCONVERT($ZCONVERT(pCubeName,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		If '##class(%DeepSee.Utils).%CubeExists(pCubeName,.tSC) Quit
		
		Set tFetchSC = ##class(%DeepSee.QualityMeasure.Utils).%GetQualityMeasuresForCube(.tQMsrList,pCubeName)
		
		If $$$ISOK(tFetchSC)&&('$D(tQMsrList)) {
			Set tFetchSC = $$$ERROR($$$dsRESTNoQualityMeasures,pCubeName)
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tQMsrList,$lb("name","caption","description"),"QualityMeasures",tFetchSC,.tQMsrObj,.tProvider)
		Set tQMsrObj.Info.BaseCube = pCubeName
	
		Set tSC = tProvider.%ObjectToJSON(tQMsrObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available named filters for <var>pCubeName</var>.
ClassMethod WriteNamedFiltersForCube(namespace As %String, pCubeName) As %Status
{
	// Method added by DTB240
	Set pCubeName = $ZCONVERT($ZCONVERT(pCubeName,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		If '##class(%DeepSee.Utils).%CubeExists(pCubeName,.tSC) Quit
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetNamedFilters(pCubeName,.tFilters)
		
		If $$$ISOK(tFetchSC)&&('$D(tFilters)) {
			Set tFetchSC = $$$ERROR($$$dsRESTNoNamedFilters,pCubeName)
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tFilters,$lb("name","description","spec","cube"),"NamedFilters",tFetchSC,.tFilterObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tFilterObj.Info.BaseCube = pCubeName
	
		Set tSC = tProvider.%ObjectToJSON(tFilterObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of available pivot variables for <var>pCubeName</var>.
ClassMethod WritePivotVariablesForCube(namespace As %String, pCubeName) As %Status
{
	// Method added by DTB240
	Set pCubeName = $ZCONVERT($ZCONVERT(pCubeName,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		If '##class(%DeepSee.Utils).%CubeExists(pCubeName,.tSC) Quit
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetPivotVariables(pCubeName,.tVariables)
		
		If $$$ISOK(tFetchSC)&&('$D(tVariables)) {
			Set tFetchSC = $$$ERROR($$$dsRESTNoPivotVars,pCubeName)
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tVariables,$lb("name","caption","defValue","context","desc"),"PivotVariables",tFetchSC,.tVarObj,.tProvider)
		Set tVarObj.Info.BaseCube = pCubeName
	
		Set tSC = tProvider.%ObjectToJSON(tVarObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return details for a given pivot variable with logical name <var>pVariableName</var>, available in <var>pCubeName</var>.
ClassMethod WriteDetailsForPivotVariable(namespace As %String, pUrl) As %Status
{
	// Method added by DTB240
	Set tUrl = $ZCONVERT($ZCONVERT(pUrl ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		// DTB297 - Examine the incoming URL and attempt to determine if it has the form
		//   cubeName/variable
		// Only cubeName supports slashes, variable does not
		Set tCubeName = ..%ExtractDatasourceName(tUrl,"cube",.tVariableName,.tSC)
		If $$$ISERR(tSC) Quit
		
		If '##class(%DeepSee.Utils).%CubeExists(tCubeName,.tSC) Quit
		
		If '$D(^DeepSee.Variables($$$UPPER(tCubeName),$$$UPPER(tVariableName))) {
			Set tFetchSC = $$$ERROR($$$dsRESTInvalidPivotVar,pVariableName,pCubeName)
		}
		Else {
			Set tFetchSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(tCubeName,tVariableName,.tVarInfo)
		}
		
		If $$$ISOK(tFetchSC)&&('$D(tVarInfo)) {
			Set tFetchSC = $$$ERROR($$$dsRESTNoPivotVarDetails,tVariableName)
		}
		
		// DTB240 - The %GetPivotVariableInfo utility returns information in a slightly different format
		// than others. Use the constructor to get a template object and fill Results manually.
		Set tSC = ..%ConstructResponseFromArray(,,"PivotVariableDetails",tFetchSC,.tVarObj,.tProvider)		// DTB266
		If $$$ISERR(tSC) Quit		// DP-429151
		
		Set tVarObj.Info.BaseCube = tCubeName
		Set tVarObj.Info.Variable = tVariableName
		
		Set tResultObj = tProvider.%ConstructNewDynamicObject()
		Set tResultObj.Details = tProvider.%ConstructNewDynamicObject()
		
		Set tVarProperty = $O(tVarInfo(""),1,tSetting)
		While (tVarProperty'="") {
			Set $Property(tResultObj.Details,tVarProperty) = tSetting
			Set tVarProperty = $O(tVarInfo(tVarProperty),1,tSetting)
		}
		
		Set tVarObj.Result = tResultObj

		Set tSC = tProvider.%ObjectToJSON(tVarObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of favorites for the current user.
ClassMethod WriteFavoritesList(namespace As %String) As %String
{
	Set tSC = $$$OK

	Try {
		set tFetchSC = ##class(%DeepSee.UserPortal.Utils).%GetFavoritesForUser(.tFavorites)
		Set tSC = ..%ConstructResponseFromArray(.tFavorites,$lb("fullName","shortName","folder","tip","type","icon","addDate","url"),"Favorites",tFetchSC,.tVarObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tVarObj.Info.User = $username
	
		Set tSC = tProvider.%ObjectToJSON(tVarObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return a list of term lists defined in the current namespace.
ClassMethod WriteTermlistList(namespace As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFetchSC = ##class(%DeepSee.TermList).%GetTermLists(.tTLList)
		If $$$ISOK(tFetchSC)&&('$D(tTLList)) {
	    	Set tFetchSC = $$$ERROR($$$dsRESTNoTermLists)
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tTL = $O(tTLList(""),1,tTLData)
	    While tTL'="" {
		    Set $LI(tTLList(tTL),3) = $ZDT($LG(tTLData,3),3)
	 		Set tTL = $O(tTLList(tTL),1,tTLData)
	    }
	    
	    Set tSC = ..%ConstructResponseFromArray(.tTLList,$LB("name","caption","modDate","type"),"TermLists",tFetchSC,.tTLListObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151
		
		Set tSC = tProvider.%ObjectToJSON(tTLListObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Test method to confirm connection in the service type
ClassMethod Test(namespace As %String) As %Status
{
	// DTB826 - Change to %DynamicObject method to make sure the response payload is delivered
	Set tTestObj = ##class(%DynamicObject).%New()
    Set tTestObj.Status = "OK"
    Set tTestObj.TimeStamp = $ZDT($H,3)		// DTB826
    Set tTestObj.DispatchClass = $ClassName()
    Set tTestObj.NameSpace = $NameSpace
    Set tTestObj.Version = $ZV		// DTB826
	Set:(%request.Method="POST") tTestObj.PostedContent = %request.Content.TEST
    Do tTestObj.%ToJSON()
             
    Quit $$$OK
}

}
