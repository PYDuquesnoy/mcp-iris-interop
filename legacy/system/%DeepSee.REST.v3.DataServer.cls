/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is responsible for creating the JSON response to the DeepSee REST 
/// data services. For examples and a full list of available services see the documentation
/// for <class>%DeepSee.REST.v3<.class>.
Class %DeepSee.REST.v3.DataServer Extends %DeepSee.REST.REST
{

XData UrlMap
{
<Routes>
   <!-- Send objects in this format: {"MDX":"QUERY"} HTTP method: POST -->
   <Route Url="/MDXExecute" Method="POST" Call="WriteJSONfromMDX"/>
   <Route Url="/PivotExecute" Method="POST" Call="WriteJSONfromPivot"/> 
   <Route Url="/KPIExecute" Method="POST" Call="WriteJSONfromKPI"/> 
   <Route Url="/MDXDrillthrough" Method="POST" Call="WriteJSONfromDrillthrough"/>
   <Route Url="/KPIDrillthrough" Method="POST" Call="WriteJSONfromKPIDrillthrough"/>
   
   <Route Url="/MDXCancelQuery/:queryID" Method="POST" Call="CancelMDXQuery"/>
   <Route Url="/MDXUpdateResults/:queryID" Method="POST" Call="UpdateQueryResults"/>

   <!-- FolderItem Handlers -->
   <Route Url="/GetPivot/(.*)" Method="GET" Call="WriteJSONPivotDef"/>
   <Route Url="/GetDashboard/(.*)" Method="GET" Call="WriteJSONDashboardDef"/>
   <Route Url="/GetTermList/(.*)" Method="GET" Call="WriteJSONTermList"/>
   <Route Url="/Favorites/(.*)" Method="PUT" Call="AddFavorite" />
   <Route Url="/Favorites/(.*)" Method="DELETE" Call="RemoveFavorite" />

   <!-- Get info about DSTIME logs -->
   <Route Url="/GetDSTIME/:sourceClass" Method="GET" Call="WriteDSTIMEForClass"/>

   <!-- Test method-->
   <Route Url="/TestConnection" Method="GET" Call="Test"/>
   <Route Url="/TestConnection" Method="POST" Call="Test"/>
   
 </Routes>
}

/// Perform specific validation for the service that will handle the request. This is used
/// as a callback in each service that extends %DeepSee.REST
ClassMethod %ValidateRequest(pUrl As %String, pMethod As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pMethod="POST") {
			// DTB696 - Validate content of a POST request
			// +DTB220 - Validate required parameters using information available from the OnPreDispatch callback
			Set tContentObj = %request.Content
			
			If (pUrl["/MDXExecute")||((pUrl["/MDXDrill")) {
				Set tMDX = tContentObj.MDX
				If $G(tMDX)="" {
					Set tSC = $$$ERROR($$$PropertyRequired,"MDX")
					Quit
				}
			}
			ElseIf (pUrl["/PivotExecute") {
				Set tPivot = tContentObj.PIVOT
				If $G(tPivot)="" {
					Set tSC = $$$ERROR($$$PropertyRequired,"PIVOT")
					Quit
				}
			}
			ElseIf (pUrl["/KPIExecute")||(pUrl["/KPIDrill") {
				Set tKPI = tContentObj.KPI
				If $G(tKPI)="" {
					Set tSC = $$$ERROR($$$PropertyRequired,"KPI")
					Quit
				}
			}
			// -DTB220
			
			If (pUrl["MDXDrill") {
				Set tReturnFields = %request.Content.RETURN
				Set tListing = %request.Content.LISTING
				If (tReturnFields'="")&&(tListing'="") {
					Set tSC = $$$ERROR($$$dsRESTDrillMethodSelect)
					Quit
				}
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Run any valid MDX (SELECT,DRILLTHROUGH,DRILLFACTS) query and returns the JSON resultset.
ClassMethod WriteJSONfromMDX(namespace As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
		Set tMDX = %request.Content.MDX

		// +DTB221 - Add filters to the MDX query
		Set tFilters = %request.Content.FILTERS
		If $IsObject(tFilters) {
			Set tRequestFilterSpec = ""
		   	For f=0:1:tFilters.%Size()-1 {
			   	Set tFilter = tFilters.%Get(f)
			   	
			   	Set tRequestFilterSpec = tRequestFilterSpec _ " %FILTER " _ tFilter
		   	}
			Set tMDX = tMDX _ tRequestFilterSpec
		}
		 
		Set tProvider.mdxQuery = tMDX
		// -DTB221
		
        // +DTB226 - Wait for results on the server
		// Assume the client wishes to wait for results if no value is specified
        Set tWait = %request.Content.WAIT
        Set:(tWait="") tWait = 1
        
		If +tWait {
			Set tTimeout = +%request.Content.TIMEOUT
			If (tTimeout<=0) {
				// Get the current session timeout
				Set tTimeout = %session.AppTimeout - $S(%session.AppTimeout>2:2,1:0)	// Send something back jst before the appTimeout is reached
			}
         	Set tSC = ..%WaitForProviderResults(tProvider,tTimeout)
		}
		If $$$ISERR(tSC) Quit
        // -DTB226
        
        Set tSC = tProvider.%DrawJSON('tWait)		// DTB767 - Do not re-execute the resultset in this context. %WaitForProviderResults took care of that!
    } Catch ex {
        Set tSC=ex.AsStatus()
    }

	// DTB220
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

    Quit tSC
}

/// Run a listing from either the source or the fact table. Specific 
/// listings or a list of fields may be POSTed to add to the query.
ClassMethod WriteJSONfromDrillthrough(namespace As %String)
{
	// Method added by DTB226
	Set tSC = $$$OK
	Try {
		Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
		Set tMDX = %request.Content.MDX

		// Add filters to the MDX query
		Set tFilters = %request.Content.FILTERS
		If $IsObject(tFilters) {
			Set tRequestFilterSpec = ""
		   	For f=0:1:tFilters.%Size()-1 {
			   	Set tFilter = tFilters.%Get(f)
			   	
			   	Set tRequestFilterSpec = tRequestFilterSpec _ " %FILTER " _ tFilter
		   	}
			Set tMDX = tMDX _ tRequestFilterSpec
		}
		Set tReturnFields = %request.Content.RETURN
		Set tListing = %request.Content.LISTING
		If tReturnFields'="" {
			Set tMDX = tMDX _ " RETURN " _ tReturnFields
		}
		If tListing'="" {
			// Listings need to have valid MDX IDs
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tListing,.tInfo)
			Set tListing = "[" _$$$dsEscapeIdent(tInfo(1))_ "]"
			Set tMDX = tMDX _ " %LISTING " _ tListing
		}
		
		Set tProvider.mdxQuery = tMDX
		
        // Wait for results on the server
		// Assume the client wishes to wait for results if no value is specified
        Set tWait = %request.Content.WAIT
        Set:(tWait="") tWait = 1
        
		If +tWait {
			Set tTimeout = +%request.Content.TIMEOUT
			If (tTimeout<=0) {
				// Get the current session timeout
				Set tTimeout = %session.AppTimeout - $S(%session.AppTimeout>2:2,1:0)	// Send something back jst before the appTimeout is reached
			}
         	Set tSC = ..%WaitForProviderResults(tProvider,tTimeout)
		}
		If $$$ISERR(tSC) Quit
        
        Set tSC = tProvider.%DrawJSON('tWait)		// DTB767 - Do not re-execute the resultset in this context. %WaitForProviderResults took care of that!
    } Catch ex {
        Set tSC=ex.AsStatus()
    }

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

    Quit tSC
}

/// Run any stored pivot table and return the associated JSON resultset.
ClassMethod WriteJSONfromPivot(namespace As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
		Set tPivotName = %request.Content.PIVOT
		
		// DTB239 - Normalize the pivot name and check for existence
		If $E($$$LOWER(tPivotName),*-5,*)=".pivot" {
			Set tPivotID = tPivotName
		}
		Else {
			Set tPivotID = tPivotName _ ".pivot"
		}
		If '##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tPivotID) {
			Set tSC = $$$ERROR($$$NoPivotTable,tPivotID)
			Quit
		}
		Set tProvider.pivotTable = tPivotName
		
		// DTB239 - Set variables into the provider
		Set tVariables = %request.Content.VARIABLES
		If $$$NULLOREF'=tVariables {
			For var=0:1:tVariables.%Size()-1 {
				Set tVariable = tVariables.%Get(var)
				Do tProvider.pivotVariables.SetAt(tVariable.value,$$$LOWER(tVariable.name))		// DTB919 - Normalize name with $$$LOWER
			}
		}

		// +DTB221 - Add filters to the provider (pivotTable component)
		Set tFilters = %request.Content.FILTERS
		If $IsObject(tFilters) {
			Set tRequestFilterSpec = ""
			For f=0:1:tFilters.%Size()-1 {
				Set tFilter = tFilters.%Get(f)

				Set tRequestFilterSpec = tRequestFilterSpec _ $S($L(tRequestFilterSpec):" ",1:"") _ "%FILTER " _ tFilter
			}
			Set tProvider.contextFilterSpec = tRequestFilterSpec
		}
		// -DTB221
         
        // +DTB226 - Decide whether to wait for results on the server or send partial 
        // results back immediately. Assume the client wishes to wait for results 
        // if nothing is specified.
        Set tWait = %request.Content.WAIT
        Set:(tWait="") tWait = 1
        
		If +tWait {
			Set tTimeout = +%request.Content.TIMEOUT
			If (tTimeout<=0) {
				// Get the current session timeout
				Set tTimeout = %session.AppTimeout - $S(%session.AppTimeout>2:2,1:0)	// Send something back jst before the appTimeout is reached
			}
         	Set tSC = ..%WaitForProviderResults(tProvider,tTimeout)
		}
		If $$$ISERR(tSC) Quit
        // -DTB226
        
        Set tSC = tProvider.%DrawJSON('tWait)		// DTB767 - Do not re-execute the resultset in this context. %WaitForProviderResults took care of that!
    } Catch ex {
        Set tSC=ex.AsStatus()
    }

	// DTB220
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

    Quit tSC
}

/// Run any compiled KPI and return the associated JSON resultset.
ClassMethod WriteJSONfromKPI(namespace As %String) As %Status
{
	// Method addded by DTB234
	Set tSC = $$$OK
	Try {
		Set tKpi = %request.Content.KPI
		
		Set tFilterObj = %request.Content.FILTERS
		Set tFilters = ""
		If $IsObject(tFilterObj) {
			For f=0:1:tFilterObj.%Size()-1 {
				Set tFilter = tFilterObj.%Get(f)
				Set tFilters(tFilter.name) = tFilter.value
			}
		}
		
		Set tKpiClassName = ##class(%DeepSee.Utils).%GetKPIClass(tKpi,.tSC)
		If $$$ISERR(tSC) Quit
		
		If (tKpiClassName'="") {
			Set tSC = $classmethod(tKpiClassName,"%GetKPIPropertyInfo",.tKpiProps)
			If $$$ISERR(tSC) Quit
		}
		
		Set tKpiPropIdx = $O(tKpiProps(""),1,tProperty)
		Set tKpiPropList = ""
		While (tKpiPropIdx'="") {
			Set tKpiPropList = tKpiPropList _ $LB(tProperty)
			Set tKpiPropArray(tKpiPropIdx) = $LB(tProperty,$G(tKpiProps(tKpiPropIdx,"caption")),$G(tKpiProps(tKpiPropIdx,"columnNo")))
			Set tKpiPropIdx = $O(tKpiProps(tKpiPropIdx),1,tProperty)
		}
		Set:'$LF(tKpiPropList, "%series") tKpiPropList = tKpiPropList _ $LB("%series"),tSeriesAppended=1		// DTB792 - Add series if it doesn't exist already

		Set tKpiSC = $classmethod(tKpiClassName,"%GetKPIValueArray",tKpi,.tKpiValues,.tKpiPropList,.tFilters)
		
		Set:+$G(tSeriesAppended) $LI(tKpiPropList,$LL(tKpiPropList)) = "seriesName"		// DTB792 - Rename series to remove % character and provide a more intuitive identifier
		Set tSC = ..%CreateObjectFromArray(.tKpiValues,tKpiPropList,.tValueObj)
		If $$$ISERR(tSC) Quit
		
		Set tSC = ..%CreateObjectFromArray(.tKpiPropArray,$LB("name","caption","columnNo"),.tPropObj)
    	If $$$ISERR(tSC)
    	
    	// Use consistent objects for normalized return
    	Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
    	Set tInfoObj = tProvider.%ConstructNewDynamicObject()
    	Set tResultObj = tProvider.%ConstructNewDynamicObject()
		
		Set:$IsObject(tPropObj.children) tResultObj.Properties = tPropObj.children
		Set:$IsObject(tValueObj.children) tResultObj.Series = tValueObj.children
		
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tKpiSC)
		Set tInfoObj.KpiName = tKpi
		
		Set tKpiObj = tProvider.%ConstructNewDynamicObject()
    	Set tKpiObj.Info = tInfoObj
    	Set tKpiObj.Result = tResultObj
    	
    	Set tSC = tProvider.%ObjectToJSON(tKpiObj)
    } Catch ex {
        Set tSC=ex.AsStatus()
    }

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

    Quit tSC
}

/// Run a listing from a KPI data source. A specific listing may be POSTed to access supported listings as defined by the source.
ClassMethod WriteJSONfromKPIDrillthrough(namespace As %String) As %Status
{
	// Method added by DP-428558
	Set tSC = $$$OK
	Try {
		Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()

		Set tKPIName = %request.Content.KPI
		Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tKPIName)
		If (tKPIClass="") {
			Set tSC = $$$ERROR($$$KPINameRequired,"KPIDrillthrough")
		}

		Set tKPI = $classmethod(tKPIClass,"%New")
		
		Set tSelection("selectedRange") = %request.Content.RANGE
		Set tSelection("rowValues") = %request.Content.ITEMS
		Set tSelection("sortColumn") = %request.Content.SORTCOL
		Set tSelection("sortDir") = %request.Content.SORTDIR 

		Set tListingName = %request.Content.LISTING

		Set tFilterObj = %request.Content.FILTERS
		Set tFilters = ""
		If $IsObject(tFilterObj) {
			For f=0:1:tFilterObj.%Size()-1 {
				Set tFilter = tFilterObj.%Get(f)
				Set tFilters(tFilter.name) = tFilter.value
			}
		}

		Set tSC = tKPI.%GetListingSQL(.tSQL,.tFilters,.tSelection,tListingName)
		If $$$ISERR(tSC) Quit
		
		Set tSQLProvider = ##class(%ZEN.Auxiliary.jsonSQLProvider).%New()
		Set tSQLProvider.sql = tSQL

		Set tSQLProvider.maxRows=0 // Display all query results
		Set tSC = tSQLProvider.%WriteJSONStreamFromSQL(.tJSONstream,tSQLProvider.sql,,,1,tSQLProvider)
		If $$$ISERR(tSC) Quit
			
		Set tSC = tProvider.%ConvertJSONToObject(.tJSONstream,"%DynamicAbstractObject",.tSQLListingObj)
		If $$$ISERR(tSC) Quit

		// Construct information about the request and  for communication back to the client
		Set tInfoObj = tProvider.%ConstructNewDynamicObject()
		Set tInfoObj.KPI = tKPIName
		Set tInfoObj.RANGE = %request.Content.RANGE
		Set tInfoObj.ITEMS = %request.Content.ITEMS
		Set tInfoObj.SORTCOL = %request.Content.SORTCOL
		Set tInfoObj.SORTDIR = %request.Content.SORTDIR 
		Set tInfoObj.LISTING = %request.Content.LISTING
		Set tInfoObj.FILTERS = %request.Content.FILTERS
		Set tInfoObj.TimeStamp = $ZDT($H,3)
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)
		
		Set tReturnObj = tProvider.%ConstructNewDynamicObject()
    	Set tReturnObj.Info = tInfoObj
    	Set tReturnObj.Result = tSQLListingObj

		Set tSC = tProvider.%ObjectToJSON(tReturnObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

    Quit tSC
}

/// Cancel a running query using the cubeKey and queryKey provided in a previously returned resultset with ResultsComplete=0.
ClassMethod CancelMDXQuery(namespace As %String, pQueryToken) As %Status
{
	// DTB223 - Call API to cancel
	Set pQueryToken = $ZCONVERT($ZCONVERT(pQueryToken,"I","URL") ,"I","UTF8")			// DTB210
	
	Set tCubeKey = $P(pQueryToken,"||",1)
	Set tQueryKey = $P(pQueryToken,"||",2)

	Set tSC = ##class(%DeepSee.ResultSet).%CancelQuery(tCubeKey,tQueryKey)
	Set tSC = ..%ErrorToJSON(tSC)
    
    Quit tSC
}

/// Try to obtain results from a previous query that returned incomplete results.
ClassMethod UpdateQueryResults(namespace As %String, pQueryToken) As %Status
{
	Set pQueryToken = $ZCONVERT($ZCONVERT(pQueryToken,"I","URL") ,"I","UTF8")			// DTB210
	Set tSC = $$$OK
	Try {
		
		Set tCubeKey = $P(pQueryToken,"||",1)
		Set tQueryKey = $P(pQueryToken,"||",2)
		
        Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
        Set tProvider.cubeKey = tCubeKey
        Set tProvider.queryKey = tQueryKey
        
        // DTB767 - Add the wait loop for update as well
        Set tWait = %request.Content.WAIT
        Set:(tWait="") tWait = 1
        
		If +tWait {
			Set tTimeout = +%request.Content.TIMEOUT
			If (tTimeout<=0) {
				// Get the current session timeout
				Set tTimeout = %session.AppTimeout - $S(%session.AppTimeout>2:2,1:0)	// Send something back just before the appTimeout is reached
			}
         	Set tSC = ..%WaitForProviderResults(tProvider,tTimeout)
		}
		If $$$ISERR(tSC) Quit
        
        Set tSC = tProvider.%DrawJSON('tWait)		// DTB767 - Do not re-execute the resultset in this context. %WaitForProviderResults took care of that!
    } Catch ex {
        Set tSC=ex.AsStatus()
    }

	// DTB220
	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}

    Quit tSC
}

/// Return the stored definition for <var>pDashboardName</var>.
ClassMethod WriteJSONDashboardDef(namespace As %String, pDashboardName) As %Status
{
	Set pDashboardName = $ZCONVERT($ZCONVERT(pDashboardName ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK

	Try {
		set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(pDashboardName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tSC = tDashboard.%CopyToDao(.tDashObj)
		If $$$ISERR(tSC) Quit

		// Use consistent objects for normalized return
    	Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
    	Set tInfoObj = tProvider.%ConstructNewDynamicObject()
    	Set tResultObj = tProvider.%ConstructNewDynamicObject()
		
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)
		Set tInfoObj.DashboardName = pDashboardName
		
		Set tReturnObj = tProvider.%ConstructNewDynamicObject()
    	Set tReturnObj.Info = tInfoObj
    	Set tReturnObj.Result = tDashObj
    	
    	Set tSC = tProvider.%ObjectToJSON(tReturnObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return the stored definition for <var>pPivotName</var>.
ClassMethod WriteJSONPivotDef(namespace As %String, pPivotName) As %Status
{
	Set pPivotName = $ZCONVERT($ZCONVERT(pPivotName ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK

	Try {
		set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pPivotName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tSC = tPivotDef.%CopyToDao(.tPivotObj)
		If $$$ISERR(tSC) Quit

		// Use consistent objects for normalized return
    	Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
    	Set tInfoObj = tProvider.%ConstructNewDynamicObject()
    	Set tResultObj = tProvider.%ConstructNewDynamicObject()
		
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)
		Set tInfoObj.PivotName = pPivotName
		
		Set tReturnObj = tProvider.%ConstructNewDynamicObject()
    	Set tReturnObj.Info = tInfoObj
    	Set tReturnObj.Result = tPivotObj
    	
    	Set tSC = tProvider.%ObjectToJSON(tReturnObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Return values stored in <var>pTermList</var>.
ClassMethod WriteJSONTermList(namespace As %String, pTermList As %String) As %Status
{
	Set pTermList = $ZCONVERT($ZCONVERT(pTermList ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK

	Try {
		Set tField = ""
		set tFetchSC = ##class(%DeepSee.TermList).%GetValueArray(pTermList,.tListValues,tField)
		If $$$ISERR(tSC) Quit

		// Use consistent objects for normalized return
    	Set tProvider = ##class(%ZEN.Auxiliary.jsonMDXProvider).%New()
    	Set tInfoObj = tProvider.%ConstructNewDynamicObject()
    	Set tResultObj = tProvider.%ConstructNewDynamicObject()
		
		Set tInfoObj.Error = tProvider.%StatusToDynamicObject(tSC)
		Set tInfoObj.TermList = pTermList

		For {
			Set tKey = $O(tListValues($G(tKey)),1,tValue)
			Quit:tKey=""

			Set $Property(tResultObj,tKey) = tValue
		}
		
		Set tReturnObj = tProvider.%ConstructNewDynamicObject()
    	Set tReturnObj.Info = tInfoObj
    	Set tReturnObj.Result = tResultObj
    	
    	Set tSC = tProvider.%ObjectToJSON(tReturnObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Retrieve the most recently processed ^OBJ.DSTIME stamp(s) for one or more classes from the ^DeepSee.Update global.
ClassMethod WriteDSTIMEForClass(namespace As %String, pClassName) As %Status
{
	// Method added by DTB503
	Set pClassName = $ZCONVERT($ZCONVERT(pClassName ,"I","URL") ,"I","UTF8")
	Set tSC = $$$OK
	Try {
		// Return a class does not exist error if the provided name is not a compiled class
		If '##class(%Dictionary.CompiledClass).%ExistsId(pClassName) {
			Set tSC = $$$ERROR($$$ClassDoesNotExist,pClassName)
			Quit
		}
		
		// Once it is verified the class exists on the server, check the update global to see
		// if the class has update data
		If '$D($$$DeepSeeUpdateQueue("classes",pClassName)) {
			Set tSC = $$$ERROR($$$SourceClassNoUpdate,pClassName)
			Quit
		}
		
		Set tTimeStamp = $G($$$DeepSeeUpdateQueue("classes",pClassName,"lastTimestamp"))
		If (tTimeStamp="") {
			// Look for the old dstime node. This should only be needed if DTB503 has
			// been backported to a version that does not use the $$$DeepSeeUpdateQueue.
			Set tTimeStamp = $G($$$DeepSeeMetaGLVN("classes",pClassName,"dstime"))	
		}
		If (tTimeStamp="") {
			// If no timestamp is found, return an error.
			Set tSC = $$$ERROR($$$SourceClassNoTimeStamp,pClassName)
			Quit
		}

		// Construct a container for JSON response
		Set tSC = ..%ConstructResponseFromArray(,,"DSTIME",1,.tReturnObj,.tProvider)
		If $$$ISERR(tSC) Quit		// DP-429151

		Set tReturnObj.Info.Class = pClassName		
		Set tReturnObj.Result.lastDSTIME = tTimeStamp
		
		Set tSC = tProvider.%ObjectToJSON(tReturnObj)
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		Set tSC = ..%ErrorToJSON(tSC)
	}
	Quit tSC
}

/// Store <var>pName</var> as a favorite for the current user.
ClassMethod AddFavorite(namespace As %String, pName As %String) As %Status
{
	Set pName = $ZCONVERT($ZCONVERT(pName ,"I","URL") ,"I","UTF8")
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%AddFavorite(pName)
	Set tSC = ..%ErrorToJSON(tSC)

	Quit tSC
}

/// Remove <var>pName</var> as a favorite for the current user.
ClassMethod RemoveFavorite(namespace As %String, pName As %String) As %Status
{
	Set pName = $ZCONVERT($ZCONVERT(pName ,"I","URL") ,"I","UTF8")
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RemoveFavorite(pName)
	Set tSC = ..%ErrorToJSON(tSC)

	Quit tSC
}

/// Test method to confirm connection in the service type
ClassMethod Test(namespace As %String) As %Status
{
    // DTB267 - Send back test status
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
