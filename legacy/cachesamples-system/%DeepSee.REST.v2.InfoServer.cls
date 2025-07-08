/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is responsible for creating the JSON response to the DeepSee REST 
/// informational services. For examples and a full list of available services see the documentation
/// for <class>%DeepSee.REST.v2<.class>.
Class %DeepSee.REST.v2.InfoServer Extends %DeepSee.REST.REST
{

XData UrlMap
{
<Routes>
	<!-- Get info about availible filters and their values -->
	<Route Url="/Filters/(.*)" Method="POST" Call="WriteFiltersForDataSource"/>
	<Route Url="/FilterMembers/(.*)" Method="POST" Call="WriteFilterMembers"/>

	<!-- Get info about FolderItems on the system -->
	<Route Url="/Pivots" Method="POST" Call="WritePivotList"/>
	<Route Url="/Dashboards" Method="POST" Call="WriteDashboardList"/>

	<!-- Get info about the available cubes on the system -->
	<Route Url="/Cubes" Method="POST" Call="WriteCubeList"/>
	<Route Url="/Listings/(.*)" Method="POST" Call="WriteListingsForCube"/>
	<Route Url="/Measures/(.*)" Method="POST" Call="WriteMeasuresForCube"/>
	<Route Url="/ListingFields/(.*)" Method="POST" Call="WriteListingFieldsForCube"/>
	<Route Url="/QualityMeasures/(.*)" Method="POST" Call="WriteQualityMeasuresForCube"/>
	<Route Url="/NamedFilters/(.*)" Method="POST" Call="WriteNamedFiltersForCube"/>
	<Route Url="/PivotVariables/(.*)" Method="POST" Call="WritePivotVariablesForCube"/>
	<Route Url="/PivotVariableDetails/(.*)" Method="POST" Call="WriteDetailsForPivotVariable"/>
	
	<!-- Get info about KPIs on the system -->
	<Route Url="/KPIs" Method="POST" Call="WriteKPIList"/>

	<!-- Test method-->
	<Route Url="/TestConnection" Method="GET" Call="Test"/>
   
 </Routes>
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
	    	Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No filters available for data source %1",pDataSource))
	    }
	   	
	   	// DTB240 - Refactor using constructor API
    	Set tSC = ..%ConstructResponseFromArray(.tFilters,$lb("caption","value","type"),"Filters",tFetchSC,.tFilterObj,.tProvider)

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
	    	Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No members available for filter '%1' in %2",tFilterSpec,tDataSource))
	    }
		
		// DTB282 - The status of this utility can indicate success when the tMembers array contains only "Invalid Filter".
    	// Convert this to a true error for the purposes of the REST services.
    	If $$$ISOK(tFetchSC)&&($$$UPPER($LG(tMembers(1),1))="INVALID FILTER") {
	    	Set tSC = $$$ERROR($$$GeneralError,$$$FormatText("Invalid filter '%1' provided for source %2",tFilterSpec,tDataSource))
	    	Quit
    	}
    
    	// DTB240 - Refactor using constructor API
    	Set tSC = ..%ConstructResponseFromArray(.tMembers,$lb("text","value","description"),"FilterMembers",tFetchSC,.tMemberObj,.tProvider)

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
	    	Set tFetchSC = $$$ERROR($$$GeneralError,"No cubes available")
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tCube = $O(tCubeList(""),1,tCubeData)
	    While tCube'="" {
		    Set $LI(tCubeList(tCube),3) = $ZDT($LG(tCubeData,3),3)
	 		Set tCube = $O(tCubeList(tCube),1,tCubeData)
	    }
	    
	    // DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tCubeList,$lb("name","displayName","lastModified","type"),"Cubes",tFetchSC,.tCubeListObj,.tProvider)
		
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

/// Retrieve the list of available KPIs
ClassMethod WriteKPIList(namespace As %String)
{
	// Method added by DTB234
	Set tSC = $$$OK
	Try {
		Set tFetchSC = ##class(%DeepSee.Utils).%GetKPIList(.tKPIList)
		If $$$ISOK(tFetchSC)&&'$D(tKPIList) {
	    	Set tFetchSC = $$$ERROR($$$GeneralError,"No kpis available")
	    }
	    
	   	// DTB269 - Convert $H timestamp to ODBC format
	    Set tKPI = $O(tKPIList(""),1,tKPIData)
	    While tKPI'="" {
		    Set $LI(tKPIList(tKPI),3) = $ZDT($LG(tKPIData,3),3)
	 		Set tKPI = $O(tKPIList(tKPI),1,tKPIData)
	    }
		
		// DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tKPIList,$lb("name","caption","lastModified","type"),"KPIs",tFetchSC,.tKPIListObj,.tProvider)
		
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

/// Return a list of available pivots on the system.
ClassMethod WritePivotList(namespace As %String) As %Status
{
	// Method added by DTB224
	Set tSC = $$$OK
	Try {
		Set tBaseCube = %request.Content.BASECUBE
		
		Set tFetchSC = ##class(%DeepSee.Utils).%GetPivotList(.tPivotList,,tBaseCube)
		If $$$ISOK(tFetchSC)&&('$D(tPivotList)) {
	    	Set tFetchSC = $$$ERROR($$$GeneralError,"No pivots available")
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tPivot = $O(tPivotList(""),1,tPivotData)
	    While tPivot'="" {
		    Set $LI(tPivotList(tPivot),3) = $ZDT($LG(tPivotData,3),3)
	 		Set tPivot = $O(tPivotList(tPivot),1,tPivotData)
	    }
	    
	    // DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tPivotList,$lb("fullName","name","lastModified","itemType"),"Pivots",tFetchSC,.tPivotListObj,.tProvider)
		Set tPivotListObj.Info.BaseCube = tBaseCube
		
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

/// Return a list of available dashboards on the system.
ClassMethod WriteDashboardList(namespace As %String) As %Status
{
	// Method added by DTB224
	Set tSC = $$$OK
	Try {
		Set tFetchSC = ##class(%DeepSee.Utils).%GetDashboardList(.tDashboardList)
		If $$$ISOK(tFetchSC)&&('$D(tDashboardList)) {
	    	Set tFetchSC = $$$ERROR($$$GeneralError,"No dashboards available")
	    }
	    
	    // DTB269 - Convert $H timestamp to ODBC format
	    Set tDashboard = $O(tDashboardList(""),1,tDashData)
	    While tDashboard'="" {
		    Set $LI(tDashboardList(tDashboard),3) = $ZDT($LG(tDashData,3),3)
	 		Set tDashboard = $O(tDashboardList(tDashboard),1,tDashData)
	    }
	    
	    // DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tDashboardList,$lb("fullName","name","lastModified","itemType"),"Dashboards",tFetchSC,.tDashListObj,.tProvider)
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
	    	Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No listings available for cube %1",pDataSource))
		}
		
		// DTB240 - Refactor to use constructor API
	    Set tSC = ..%ConstructResponseFromArray(.tListings,$lb("name","fields","order","type","source","edit","caption"),"Listings",tFetchSC,.tListingObj,.tProvider)
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
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No measures available for %1",pCubeName))
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tMeasureArray,$lb("name","caption","type","hidden","factName"),"Measures",tFetchSC,.tMsrObj,.tProvider)
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
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No listing fields available for %1",pCubeName))
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tListingFieldArray,$lb("caption","expression","description"),"ListingFields",tFetchSC,.tListingFieldObj,.tProvider)
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
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No quality measures available for %1",pCubeName))
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
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No named filters available for %1",pCubeName))
		}
		
		Set tSC = ..%ConstructResponseFromArray(.tFilters,$lb("name","description","spec","cube"),"NamedFilters",tFetchSC,.tFilterObj,.tProvider)
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
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No pivot variables available for %1",pCubeName))
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
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("Pivot variable '%1' does not exist for cube %2",pVariableName,pCubeName))
		}
		Else {
			Set tFetchSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(tCubeName,tVariableName,.tVarInfo)
		}
		
		If $$$ISOK(tFetchSC)&&('$D(tVarInfo)) {
			Set tFetchSC = $$$ERROR($$$GeneralError,$$$FormatText("No details available for %1",tVariableName))
		}
		
		// DTB240 - The %GetPivotVariableInfo utility returns information in a slightly different format
		// than others. Use the constructor to get a template object and fill Results manually.
		Set tSC = ..%ConstructResponseFromArray(,,"PivotVariableDetails",tFetchSC,.tVarObj,.tProvider)		// DTB266
		
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
    Do tTestObj.%ToJSON()
             
    Quit $$$OK
}

}
