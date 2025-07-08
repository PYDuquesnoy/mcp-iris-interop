/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// Subclasses of this class are used to implement analytic "plug-ins" for DeepSee.
Class %DeepSee.KPIPlugIn Extends %DeepSee.KPI [ Abstract, System = 4 ]
{

Parameter CACHEABLE = 1;

Parameter ASYNC = 1;

/// By default, plug-ins are not visible to dashboards.
Parameter PUBLIC = 0;

/// Cube that this plug-in is based on.
/// This determines which cubes (or subject areas based on this cube) can see this plug-in.
/// This can be a comma-delimited list. The cube name(s) should not be enclosed with [].
Parameter BASECUBE As STRING;

/// Specifies the type of this plug-in. This indicates the context in which this plug-in is used.<br/>
/// "Pivot" -- the plug-in is visible within the Analyzer dimension tree.<br/>
/// "Aggregate" -- the plug-in is not visible within the Analyzer dimension tree.<br/>
Parameter PLUGINTYPE As STRING [ Constraint = ",Pivot,Aggregate", Flags = ENUM ] = "Pivot";

/// Specifies the source of the listing data used by this plugin: "SourceTable" - the data source
/// supplies the listing values; "FactTable" - the fact table supplies the listing values.
Parameter LISTINGSOURCE As STRING [ Constraint = ",SourceTable,FactTable", Flags = ENUM ] = "SourceTable";

/// If defined, this the field list (RETURN clause) of the listing used to supply data for this
/// plug-in.
Parameter LISTINGFIELDS As STRING;

/// Iterator for SQL results that will drive the computation of this plugin.
Property %sqlResultSet As %SQL.StatementResult;

/// Number of facts in the "listing" that is driving this KPI.
Property %factCount As %Integer;

Property %plugInListingKey As %String;

/// Return the type of this plug in.
ClassMethod %GetPlugInType() As %String
{
	Quit ..#PLUGINTYPE
}

/// Return the cube(s) this KPI is based on.
ClassMethod %GetBaseCube() As %String
{
	Quit ..#BASECUBE
}

/// This callback defines the default MDX query used for analysis. It also checks for the current values
/// in the filters.<br/>
/// By default, select all facts from the first base cube.<br/>
/// This may be overridden by subclasses.
Method %OnGetMDX(ByRef pMDX As %String) As %Status
{
	Set pMDX = ""
	Set tBaseCube = ..%GetBaseCube()
	// JMD1124 test for *
	If ((tBaseCube'="")&&(tBaseCube'="*")) {
		Set pMDX = "SELECT FROM ["_$P(tBaseCube,",",1)_"]"
	}
	Quit $$$OK
}

/// Return an <class>%SQL.StatementResult</class> object that will iterate over the facts used for analysis.
Method %OnGetAnalysisResultSet(Output pRS As %SQL.StatementResult, pSQL As %String) As %Status
{
	Quit $$$OK
}

/// Returns the source of the listing data used by this plugin: "SourceTable" - the data source
/// supplies the listing values; "FactTable" - the fact table supplies the listing values.
Method %OnGetListingSource() As %String
{
	Quit ..#LISTINGSOURCE
}

/// Returns the field list (RETURN clause) of the listing used to supply data for this plug-in.
Method %OnGetListingFields() As %String
{
	Quit ..#LISTINGFIELDS
}

/// Returns the MDX %ORDER BY clause for the drillthrough query used to supply data for this plug-in.
Method %OnGetListingOrderBy() As %String
{
	Quit ""
}

/// Returns the MDX MAXROWS clause for the drillthrough query used to supply data for this plug-in.
Method %OnGetListingMaxRows() As %String
{
	Quit ""
}

/// Return an <class>%SQL.StatementResult</class> object that will iterate over the 
/// facts used for analysis.<br/>
/// <var>pCubeName</var> is the cube name for the underlying MDX query.<br/>
/// <var>pQueryKey</var> is the query key for the underlying MDX query.<br/>
Method %GetAnalysisResultSet(Output pRS As %SQL.StatementResult, Output pCubeName As %String, Output pQueryKey As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {

		Set tLock = 0  // WAL087
		
		Set pRS = ""
		Set pCubeName = ""
		Set pQueryKey = ""
		
		// DP-406916 - Fetch the complete plugin MDX query prepared with the intention of producing
		// the SQL resultset that will ultimately be the subject of analysis
		Set tMDXQuery = ..%GetPluginMDX(.tSC)
		If $$$ISERR(tSC) Quit
		
		
		If (tMDXQuery'="") {
			// Log the query that will actually be executed
			Set ^DeepSee.LastQuery.PlugIn = tMDXQuery
			
			// + WAL087 -- lock for entire process of getting result set
			Set tHash = $ZCRC(tMDXQuery,7)
			Set tMaxLoops = 10
			While ('tLock && ($i(tLoops)<=tMaxLoops)) {
				Lock +^DeepSee.PluginResultSet(tHash):10
				If ($Test) {
					Set tLock = 1
					Quit
				}
				Hang 1
			}
			If ('tLock) {
				Set tSC = $$$ERROR($$$GeneralError,"Unable to get lock to create plugin Result Set")	
				Quit
			}
			// - WAL087
			
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tMDXQuery)
			If $$$ISERR(tSC) Quit
			
			// override maxrows for listing query
			// unless %OnGetListingMaxRows is present
			Set tQuery = tRS.%GetQuery()
			
			Set tBigNumber = 100000000
			Set tMaxRows = ..%OnGetListingMaxRows()
			If (+tMaxRows>0) {
				Set tBigNumber = +tMaxRows
			}
			Set tQuery.%MaxListingRows = tBigNumber
			Set tRS.listingPageSize = tBigNumber

			// + WAL107
			Set tRS.%IsPlugIn = 1
			// - WAL107

			// + WAL203 -- pass parent query key so we can resolve reserved axes
			//             (related to WAL071)
			Set tRS.%Query.parentQueryKey = $G(%parentQueryKey)
			// - WAL203

			// !!!
			// don't exec if we are async !!!
			// test if query is up-to-date !!!

			// asynch?
			Set tSC = tRS.%Execute(.tParmValues)
			If $$$ISERR(tSC) Quit

			Set pCubeName = tRS.%GetCubeName()
			Set pQueryKey = tRS.%GetQueryKey()
			Set ..%plugInListingKey = tRS.%PlugInListingKey // + WAL107

			If (tRS.%IsDrillThrough()) {
				Set tSQL = tRS.%GetListingSQL()
			}

			// Get number of rows in the in listing
			Set ..%factCount = tRS.listingRows
			If (..%factCount = tBigNumber) {
				// get actual # of facts from cube
				Set tFactClass = ##class(%DeepSee.Utils).%GetCubeFactClass(pCubeName)
				If (tFactClass'="") {
					Set ..%factCount = $classmethod(tFactClass,"%Count")
				}
			}

			// invoke callback
			Set pRS = ""
			Set tSC = ..%OnGetAnalysisResultSet(.pRS,tSQL)
			If $$$ISERR(tSC) Quit

			// if callback did nothing, create result set here
			If (pRS = "") {
				// prepare query
				Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
				Set tStatement.%SelectMode = 0 // odbc-mode

				Set tSC = tStatement.%Prepare(tSQL)
				If $$$ISERR(tSC) Quit

				// execute to get iterator
				Set pRS = tStatement.%Execute()
			}
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	// + WAL087
	If (tLock) {
		Lock -^DeepSee.PluginResultSet(tHash)
	}
	// - WAL087
	Quit tSC
}

/// Compute and return the KPI cache timestamp for the current KPI result.
Method %OnComputeKPITimestamp(ByRef pTimestamp As %String, pSourceType As %String, pQueryText As %String = "") As %Status
{
	If (..%cacheKey'="") {
		// find timestamp of underlying cube
		Set tCube = $P(..%cacheKey,"~",1)
		Set tQueryKey = $P(..%cacheKey,"~",2)
		If ((tCube'="")&&(tQueryKey'="")) {
			Set tCubeIndex = $$$DeepSeeIndex(tCube)
			Set pTimestamp = ##class(%DeepSee.Utils).%GetCubeDSTime(tCubeIndex)		// DTB838 - Fetch the common timestamp
		}
	}
	Quit $$$OK
}

/// Compute the kpi cache key for the current KPI result.
/// Also creates the context for executing this KPI.
Method %OnComputeKPICacheKey(Output pCacheKey As %String, pQueryText As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pCacheKey = ""
	Try {
		// DP-406916 - Computation of the cache key does not require any actual execution of
		// resultset. This method only needs to fetch the query key and the cube name which
		// the MDX resultset is capable of providing once the prepare phase is complete.
		Set tMDXQuery = ..%GetPluginMDX(.tSC)
		If $$$ISERR(tSC) Quit
		
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareMDX(tMDXQuery)
		If $$$ISERR(tSC) Quit
		
		Set tCubeName = tRS.%GetCubeName()
		Set tQueryKey = tRS.%GetQueryKey()
		Set tFilterKey = ..%GetFilterKey()

		// create caching key (including cubename, query, and filters)
		// JMD1124: use upper case cube name
		Set pCacheKey = $$$UPPER(tCubeName)_"~"_tQueryKey
		Set:tFilterKey'="" pCacheKey = pCacheKey_"~"_tFilterKey
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Compute value(s) for this plug-in.<br/>
/// <var>pSQLRS</var> is an SQL result set (<class>%SQL.StatementResult</class>) that 
/// will iterate over a set of facts and provide
/// the base data for the calculations.<br/>
/// <var>pFactCount</var> Is the number of facts in the set.<br/>
/// Plug-in classes should implement this method to perform their calculations.
Method %OnCompute(pSQLRS As %SQL.StatementResult, Output pFactCount As %Integer) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

/// Notification that this KPI is being executed.<br/>
/// In this case, we compute the value of this plug-in by setting up the context
/// and invoking the <method>%OnCompute</method> method.<br/>
/// Plug-in classes should implement the <method>%OnCompute</method> method.
Method %OnLoadKPI() As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set tRS = ..%sqlResultSet
		
		// DP-406916 - If the resultset has not yet been materialized, create it.
		If '$IsObject(tRS) {
			Set tSC = ..%GetAnalysisResultSet(.tRS)
			If $$$ISERR(tSC) Quit
			
			// Remember the SQL resultset to skip any further need to re-execute the original MDX
			Set ..%sqlResultSet = tRS
		}
		
		// Test that the resultset was produced before proceeding to computation
		If '($IsObject(tRS) && tRS.%IsA("%SQL.StatementResult")) {
			Set tSC = $$$ERROR($$$GeneralError,"Missing or invalid Analysis SQL Result Set for plug-in (1)")
			Quit
		}

		Do ..%SetPercentComplete(0)
		Set tSC = ..%OnCompute(tRS,..%factCount)
		Do ..%SetPercentComplete(100)

		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	// log error, return error value, and then swallow it
	If $$$ISERR(tSC) {
		Set tText = $System.Status.GetErrorText(tSC)
		Do ##class(%DeepSee.Utils).%WriteToLog("Query","Error in Plugin %OnCompute: " _ tText)

		// get list of defined properties
		Do ..%GetKPIPropertyInfo(.tKPIProps)

		Set ..%seriesCount = 1
		Set ..%seriesNames(1) = "Error"

		Set p = $O(tKPIProps(""))
		While (p'="") {
			Set:$G(tKPIProps(p))'="" ..%data(1,tKPIProps(p)) = tText
			Set p = $O(tKPIProps(p))
		}
		
		Set ..%data("$loadError") = tSC		// DTB863 - Return the error in the databag for further processing
		Set %dsKPIError = tSC				// DP-406916 - Also return the error via environment variable
		
		Set tSC = $$$OK
	}

	Quit tSC
}

/// Callback to get additional members for a KPI filter.
/// This takes the form:<br/>
/// pMembers($I(pMembers))=$LB(text,value)<br/>
/// In this case, return members for certain "built-in" filters such as
/// "%cube" and "%measure".
ClassMethod %OnGetFilterMembers(pFilter As %String, Output pMembers As %List, pSearchKey As %String = "", pDataSourceName As %String = "", ByRef pFilterValues As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pFilter = "%cube") {
			Set tSC = ##class(%DeepSee.Utils).%GetCubeList(.tList,,1)
			If $$$ISERR(tSC) Quit

			Set k = $O(tList(""))
			While (k'="") {
				Set pMembers($I(pMembers)) = $LB($LG(tList(k),2),"["_$LG(tList(k),1)_"]")
				Set k = $O(tList(k))
			}
		}
		ElseIf ($E(pFilter,1,8) = "%measure") {

			// n.b. %measure and %measureN are valid names!
			// JMD1124 -- find logical name, not fact name, for each measure
			Set tBaseCube = $P(..%GetBaseCube(),",",1)
			Set tCube = $G(pFilterValues("%cube"),tBaseCube)

			If (tCube '= "") {
				// remove []
				Set:$E(tCube)="[" tCube = $E(tCube,2,*-1)

				// list of measures
				Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(tCube,.tMeasures)
				If $$$ISERR(tSC) Quit

				Set tCountName = $$$UPPER(##class(%DeepSee.Utils).%GetCountName(tCube,.tSC))
				If $$$ISERR(tSC) Quit
				Set m = $O(tMeasures(""))
				While (m'="") {
					Set tName = $LG(tMeasures(m),1)
					Set tCaption = $LG(tMeasures(m),2)
					Set tType = $LG(tMeasures(m),3)
					Set tFactName = $LG(tMeasures(m),5)
					If ((tFactName'="")&&((tType="number")||(tType="integer"))&&($$$UPPER(tName)'=tCountName)) {
						// JMD1124
						// Set pMembers($I(pMembers)) = $LB(tCaption,tFactName)
						Set pMembers($I(pMembers)) = $LB(tCaption,"["_tName_"]")
					}
					Set m = $O(tMeasures(m))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Plugins have a context-specific DRILLTHROUGH/DRILLFACTS MDX query that is executed
/// to ultimately produce the SQL resultset containing the target records for analysis. This
/// method decorates the base query with the MDX resultset cell context and directs the drill
/// to the proper source.
Method %GetPluginMDX(Output pStatus As %Status) As %String
{
	// Method added by DP-406916
	Set pStatus = $$$OK
	Set tMDXQuery = ""
	
	Try {
		// Start with default query
		Set pStatus = ..%GetMDX(.tMDX)
		If $$$ISERR(pStatus) Quit
		
		If (tMDX'="") {
			// The MDX query returned by %GetMDX will contain the cell context filters. At this
			// point convert this to the appropriate drillthrough/drillfacts which will produce
			// the SQL resultset that the plugin needs for computation.
			
			Set tListingSource = ..%OnGetListingSource()
			If (tListingSource = "FactTable") {
				Set tPrefix = "DRILLFACTS "
			}
			Else {
				Set tPrefix = "DRILLTHROUGH "
			}

			Set tReturn = ""
			Set tListingFields = ..%OnGetListingFields()
			If (tListingFields '= "") {
				Set tReturn = " RETURN "_tListingFields
			}

			Set tListingOrder = ..%OnGetListingOrderBy()
			If (tListingOrder '= "") {
				Set tReturn = tReturn_" %ORDER BY "_tListingOrder
			}

			Set tMDXQuery = tPrefix_tMDX_tReturn
		}
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
	}
	
	Quit tMDXQuery
}

/// Return the sourceType for this KPI.
/// Always "custom" for plugins.
ClassMethod %GetSourceType() As %String
{
	Quit "custom"
}

Method %OnKPICleanup() As %Status [ Internal ]
{
	// + WAL107 -- cleanup plugin listing table
	//             which was created in %DeepSee.ResultSet::%ExecuteListing()
	Set tCubeName = $P(..%cacheKey,"~",1)
	If ((tCubeName'="") && (..%plugInListingKey '= "")) {
		Kill $$$DeepSeeListingGLVN(tCubeName,..%plugInListingKey)
		Kill $$$DeepSeeListingBitGLVN(tCubeName,..%plugInListingKey)
	}
	// - WAL107
	Quit $$$OK
}

}
