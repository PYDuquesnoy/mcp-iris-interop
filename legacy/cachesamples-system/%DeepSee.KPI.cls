/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occUtility, %DeepSee)

IncludeGenerator (%occUtility, %DeepSee)

/// Subclasses of this class are used to define KPIs (key performance indicators).
/// A KPI defines a set of related values that can be used to drive widgets on a DeepSee dashboard.<br/>
/// A KPI can define a set of actions that can be called from control buttons on a dashboard widget.<br/>
/// Each KPI class is also also a %CSP page; if you view it as a Web Page, you can view a test page
/// for the KPI (you must hold Developer privileges to do this).
Class %DeepSee.KPI Extends %DeepSee.AbstractKPI [ Abstract, System = 4 ]
{

/// This projection is used to keep track of when KPI classes are compiled or deleted.
Projection KPIProjection As %DeepSee.KPIProjection [ Internal ];

/// If true, then results for this KPI can be cached.
Parameter CACHEABLE As BOOL = 0;

/// If true, then this KPI can be executed asychronously.
Parameter ASYNC As BOOL = 0;

/// For MDX-based KPIs, use this character when concatenating labels for nested rows.
Parameter LABELCONCAT As STRING = "/";

/// Use this parameter to limit the number of losting rows displayed in pivot tables. 
/// This setting is ignored for exports.
Parameter MAXLISTINGROWS As INTEGER;

/// This XData definition defines the KPI.
XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
}

/// Return true if this KPI can interact with the cache.
ClassMethod %IsCacheable() As %String
{
	// JMD1390: if we are async, we have to act as cacheable
	// in order to return a result
	Quit (+..#CACHEABLE)||(+..#ASYNC)
}

/// Return true if this kpi can be computed asynchronously.
ClassMethod %IsAsync() As %Boolean
{
	Quit +..#ASYNC
}

ClassMethod %GetMaxListingRows() As %Integer
{
	// Method added by DTB924
	Quit ..#MAXLISTINGROWS
}

/// Process the xml definition for this KPI and generate meta data.
ClassMethod %Generate() As %Status [ CodeMode = objectgenerator, Final, Internal ]
{
	Do %code.WriteLine(" Quit $$$OK")

	Kill ^||%Cls(%compiledclass.Name)
	If (%class.Abstract || (%class.Name = "%DeepSee.KPI")) {
		Quit $$$OK
	}

	#; find XDATA block named KPI
	Set tIndex = %compiledclass.XDatas.FindObjectId(%class.Name_"||KPI")

	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = %compiledclass.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()

		If (tStream.Size > 0) {

			#; render the stream into cube meta-data object (with children)
			Set tReader = ##class(%XML.Reader).%New()

			Set tSC = tReader.OpenStream(tStream)
			If $$$ISERR(tSC) Quit tSC

			Do tReader.Correlate("kpi","%DeepSee.Model.KPI.kpi")

			#; there should only be one kpi defined
			Do tReader.Next(.tKPI,.tSC)
			If $$$ISERR(tSC) Quit tSC
			If '$IsObject(tKPI) Quit $$$ERROR($$$GeneralError,"No <kpi> element defined in KPI block.")

			#; is KPI disabled?
			If (tKPI.disabled) {
				Write !,$$$FormatText($$$Text("KPI '%1' is disabled","%DeepSee"),tKPI.name)
				Quit tSC
			}

			#; is this kpi name already used?
			Set tKPIName = tKPI.name
			If (tKPIName = "") {
				Quit $$$ERROR($$$GeneralError,"KPI must be given a name")
			}
			If ($E(%class.Name,1,16)'="%DeepSee.PlugIn.") {
				Set tRegClass = $G($$$DeepSeeMetaGLVN("kpis",$$$UPPER(tKPIName)))
				If ((tRegClass'="") && (tRegClass '= %class.Name)) {
					Quit $$$ERROR($$$GeneralError,"KPI with given name already exists: " _ tKPIName)
				}
			}
			Else {
				If (tKPIName'=("%DeepSee."_$P(%class.Name,".",$L(%class.Name,".")))) {
					Quit $$$ERROR($$$GeneralError,"Built-in KPI must be called %DeepSee.<classname>: " _ tKPIName)
				}
			}

			#; validate KPI
			Set tSC = tKPI.%Validate()
			If $$$ISERR(tSC) Quit tSC

			#; clear data cache for this KPI
			Kill $$$DeepSeeKPIGLVN($$$UPPER(%class.Name))

			#; 
			Set ^||%Cls(%compiledclass.Name,"name") = tKPIName
			Set ^||%Cls(%compiledclass.Name,"caption") = tKPI.caption
			Set ^||%Cls(%compiledclass.Name,"sourceType") = $S(tKPI.sourceType="":"manual",1:tKPI.sourceType)
			Set ^||%Cls(%compiledclass.Name,"rangeUpper") = tKPI.rangeUpper
			Set ^||%Cls(%compiledclass.Name,"rangeLower") = tKPI.rangeLower
			Set ^||%Cls(%compiledclass.Name,"thresholdUpper") = tKPI.thresholdUpper
			Set ^||%Cls(%compiledclass.Name,"thresholdLower") = tKPI.thresholdLower
			Set ^||%Cls(%compiledclass.Name,"sql") = tKPI.sql
			Set ^||%Cls(%compiledclass.Name,"mdx") = tKPI.mdx
			Set:tKPI.actionClass'="" ^||%Cls(%compiledclass.Name,"actionClass") = tKPI.actionClass

			#; process the KPI definition
			Set tPropNo = 0
			Set tPropCount = tKPI.properties.Count()
			For p = 1:1:tPropCount {
				Set tProp = tKPI.properties.GetAt(p)
				If (tProp.disabled) {
					Continue
				}
				Set tPropNo = tPropNo + 1
				Set ^||%Cls(%compiledclass.Name,"props",tPropNo) = tProp.name
				Set:(tProp.defaultValue'="") ^||%Cls(%compiledclass.Name,"props",tPropNo,"defaultValue") = tProp.defaultValue
				Set:(tProp.columnNo'="") ^||%Cls(%compiledclass.Name,"props",tPropNo,"columnNo") = tProp.columnNo
				Set:(tProp.displayName'="") ^||%Cls(%compiledclass.Name,"props",tPropNo,"displayName") = tProp.displayName
				// JMD921
				Set:(tProp.format'="") ^||%Cls(%compiledclass.Name,"props",tPropNo,"format") = tProp.format
				Set:(tProp.style'="") ^||%Cls(%compiledclass.Name,"props",tPropNo,"style") = tProp.style
				Set:(tProp.headerStyle'="") ^||%Cls(%compiledclass.Name,"props",tPropNo,"headerStyle") = tProp.headerStyle
			}

			Set tFilterNo = 0
			Set tFilterCount = tKPI.filters.Count()
			For f = 1:1:tFilterCount {
				Set tFilter = tKPI.filters.GetAt(f)
				If (tFilter.disabled) {
					Continue
				}
				Set tFilterNo = tFilterNo + 1
				Set ^||%Cls(%compiledclass.Name,"filters",tFilterNo) = tFilter.name
				Set:(tFilter.displayName'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"displayName") = tFilter.displayName
				Set:(tFilter.filterProperty'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"filterProperty") = tFilter.filterProperty
				Set:(tFilter.sql'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"sql") = tFilter.sql
				Set:(tFilter.valueList'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"valueList") = tFilter.valueList
				Set:(tFilter.displayList'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"displayList") = tFilter.displayList
				Set:(tFilter.defaultValue'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"defaultValue") = tFilter.defaultValue
				Set:('tFilter.multiSelect) ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"multiSelect") = 0
				Set:(tFilter.dependsOn'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"dependsOn") = tFilter.dependsOn
				Set:(tFilter.searchType'="") ^||%Cls(%compiledclass.Name,"filters",tFilterNo,"searchType") = tFilter.searchType
			}

			Set tActionNo = 0
			Set tActionCount = tKPI.actions.Count()
			For f = 1:1:tActionCount {
				Set tAction = tKPI.actions.GetAt(f)
				If (tAction.disabled) {
					Continue
				}
				Set tActionNo = tActionNo + 1
				Set ^||%Cls(%compiledclass.Name,"actions",tActionNo) = tAction.name
				Set:(tAction.displayName'="") ^||%Cls(%compiledclass.Name,"actions",tActionNo,"displayName") = tAction.displayName
			}

			#; time stamps (utc?)
			If ($E(%class.Name,1,16)'="%DeepSee.PlugIn.") {
				Set $$$DeepSeeMetaGLVN("kpis",$$$UPPER(tKPIName),"lastSchemaUpdate") = $H
			}
		}
		Else {
			Quit $$$ERROR($$$GeneralError,"No KPI definition in KPI class: " _ %class.Name)
		}
	}
	Quit $$$OK
}

/// Return the logical name for this KPI.
ClassMethod %GetKPIName(pName As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"name"))))
	Quit $$$OK
}

/// Return the caption as defined in the XML for this KPI.
ClassMethod %GetKPICaptionName(pName As %String = "") As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"caption"))))
	Quit $$$OK
}

/// This callback, if implemented, returns the text of an SQL query used to provide
/// a "detail listing" for this KPI.<br/>
/// <var>pFilters</var> is an array of current filter values: pFilters(name)=value.<br/>
/// <var>pSelection</var> is an array containing information about the current selected items in the pivot.
/// It contains several values:<br/>
/// pSelection("selectedRange") contains the current selected cells in the pivot as a string in the form
/// "startRow,startCol,endRow,endCol" (1-based). "" if no cells are selected.<br/>
/// pSelection("rowValues") contains a csv-list of "row" values for the selected rows in the pivot (similar
/// to the $$$VALUELIST value used for OpenWindow URLs. This may contain "\," for "," within the data values.<br/>
/// pSelection("sortColumn") is the number of the column to sort on (or 0 for no sort).<br/>
/// pSelection("sortDir") is the sort direction ("ASC" or "DESC").<br/>
/// <var>pListingName</var> is the name of the listing to display. This is reserved for future use.<br/>
/// This method is simply a convenient alternative to the <method>%OnGetListingResultSet</method> method.
/// It takes precedence over the <method>%OnGetListingResultSet</method> method.
ClassMethod %OnGetListingSQL(ByRef pFilters As %String, ByRef pSelection As %String, pListingName As %String = "") As %String
{
	Quit ""
}

/// This callback, if implemented, can prepare and execute
/// a listing query used to provide a "detail listing" for this KPI.
/// <var>pFilters</var> is an array of current filter values.<br/>
/// <var>pListingName</var> is the name of the listing to display. This is reserved for future use.<br/>
ClassMethod %OnGetListingResultSet(ByRef pFilters As %String, ByRef pSelection As %String, pListingName As %String = "", Output pRS As %SQL.StatementResult) As %Status
{
	Set pRS = ""
	Quit $$$OK
}

/// This method is used to get the "detail listing" result set for this KPI, if any.<br/>
/// <var>pSelection</var> is an array of values that can be used to control the listings:<br/>
/// pSelection("rowValues") contains a csv-list of selected row values.<br/>
/// 	pSelection("selectedRange") contains the selected range of cells in the pivot table: startRow,startCol,endRow,endCol (1-based).<br/>
/// 	pSelection("sortColumn") is the number of the column to sort by (or 0).<br/>
/// 	pSelection("sortDir") is the direction to sort in, "ASC" or "DESC".<br/>
ClassMethod %GetListingResultSet(ByRef pFilters As %String, ByRef pSelection As %String, pListingName As %String = "", Output pRS As %SQL.StatementResult) As %Status [ Final, Internal ]
{
	Set pRS = ""
	Set tSC = $$$OK

	Try {
		// first check for SQL text
		Set tSQL = ..%OnGetListingSQL(.pFilters,.pSelection,pListingName)
		If (tSQL'="") {
			Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
			Set tStatement.%SelectMode = 1 // odbc-mode

			Set tSC = tStatement.%Prepare(tSQL)
			If $$$ISERR(tSC) Quit
			Set pRS = tStatement.%Execute()
		}
		Else {
			// ask for result set 
			Set tSC = ..%OnGetListingResultSet(.pFilters,.pSelection,pListingName,.pRS)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set pRS = ""
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Return the sourceType for this KPI
ClassMethod %GetSourceType() As %String [ CodeMode = objectgenerator, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"sourceType"))))
	Quit $$$OK
}

/// Return the default SQL statement for this KPI.
ClassMethod %GetSQLText() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"sql"))))
	Quit $$$OK
}

/// Return the default MDX statement for this KPI.
ClassMethod %GetMDXText() As %String [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate ]
{
	Do %code.WriteLine(" Quit "_$$$quote($G(^||%Cls(%compiledclass.Name,"mdx"))))
	Quit $$$OK
}

/// Apply property defaults from the KPI model.
Method %ApplyDefaults() [ CodeMode = objectgenerator, GenerateAfter = %Generate, Internal ]
{
	Do %code.WriteLine(" Set ..%rangeUpper ="_$$$quote($G(^||%Cls(%compiledclass.Name,"rangeUpper"))))
	Do %code.WriteLine(" Set ..%rangeLower ="_$$$quote($G(^||%Cls(%compiledclass.Name,"rangeLower"))))
	Do %code.WriteLine(" Set ..%thresholdUpper ="_$$$quote($G(^||%Cls(%compiledclass.Name,"thresholdUpper"))))
	Do %code.WriteLine(" Set ..%thresholdLower ="_$$$quote($G(^||%Cls(%compiledclass.Name,"thresholdLower"))))
	Quit $$$OK
}

/// This callback method does the actual work of loading values from the source object.
Method %OnLoadModel(pSource As %RegisteredObject) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set ..%cacheKey = ""
		Set ..%fromCache = 0

		If ($IsObject($G(%dataController))&&$IsObject(%dataController.criteria)) {
			Set ..%filterValues = %dataController.criteria
		}
		Else {
			// point to empty object as a convenience
			Set ..%filterValues = ##class(%ZEN.proxyObject).%New()
		}
		Do ..%ApplyDefaults()

		// + WAL262 -- pass along any arguments from plugIn to the KPI
		Set tFilterName = $O(%dsPlugInArguments(""))
		While (tFilterName'="") {
			Set $property(..%filterValues,tFilterName) = %dsPlugInArguments(tFilterName)
			Set tFilterName = $O(%dsPlugInArguments(tFilterName))	
		}
		// - WAL262

		// pick up cell context if present
		Kill ..%cellContext
		Merge ..%cellContext = %dsCellContext

		// get data based on source type
		Set tIsCached = 0
		Set tSourceType = ..%GetSourceType()
		Set tSourceQuery = ""

		// execute async?
		// if we are in the background then async is false as *we* have to do the work!
		Set tAsync = ('$D(%dsBackground)) && ..%IsAsync()
		// JMD1046
		Set tIgnoreCache = 0
		If (+$G(%dsKPISync)) {
			Set tAsync = 0
			Set tIgnoreCache = 1
		}

		If (tSourceType="mdx") {
			Set tSC = ..%GetMDX(.tMDX)
			If $$$ISERR(tSC) Quit

			Set tSourceQuery = tMDX

			// compute a cache key (in %cacheKey)
			Set tSC = ..%ComputeKPICacheKey(tSourceType,tSourceQuery)
			If $$$ISERR(tSC) Quit

			// JMD1390 validate cache (clear if not up-to-date)
			Set tSC = ..%ValidateKPICache(tSourceType,tMDX)
			If $$$ISERR(tSC) Quit

			If ('tIgnoreCache) {
				// test cache
				Set tSC = ..%TestKPICache(.tIsCached,tSourceType,tMDX)
				If $$$ISERR(tSC) Quit
			}

			If ('tIsCached && 'tAsync) {
				Set tSC = ..%ExecuteMDX(tMDX)
				If $$$ISERR(tSC) Quit
			}
		}
		ElseIf (tSourceType="sql") {
			Set tSC = ..%GetSQL(.tSQL)
			If $$$ISERR(tSC) Quit

			Set tSourceQuery = tSQL

			// compute a cache key (in %cacheKey)
			Set tSC = ..%ComputeKPICacheKey(tSourceType,tSourceQuery)
			If $$$ISERR(tSC) Quit

			// JMD1390 validate cache (clear if not up-to-date)
			Set tSC = ..%ValidateKPICache(tSourceType,tSourceQuery)
			If $$$ISERR(tSC) Quit

			If ('tIgnoreCache) {
				// test cache
				Set tSC = ..%TestKPICache(.tIsCached,tSourceType,tSQL)
				If $$$ISERR(tSC) Quit
			}

			If ('tIsCached && 'tAsync) {
				Set tSC = ..%ExecuteSQL(tSQL)
				If $$$ISERR(tSC) Quit
			}
		}
		Else {
			// manual

			// compute a cache key (in %cacheKey)
			Set tSC = ..%ComputeKPICacheKey(tSourceType,"")
			If $$$ISERR(tSC) Quit

			// JMD1390 validate cache (clear if not up-to-date)
			Set tSC = ..%ValidateKPICache(tSourceType,"")
			If $$$ISERR(tSC) Quit

			If ('tIgnoreCache) {
				// test cache
				Set tSC = ..%TestKPICache(.tIsCached,tSourceType)
				If $$$ISERR(tSC) Quit
			}

			If ('tIsCached && 'tAsync) {
				Set tSC = ..%OnExecute()
				If $$$ISERR(tSC) Quit
			}
		}

		If (tIsCached && (..%cacheKey'="")) {
			Set tSC = ..%LoadKPIFromCache()
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tAsync && (..%cacheKey'="")) {
			// execute async
			Set tSC = ..%QueueKPI()
			If $$$ISERR(tSC) Quit
		}
		Else {
			// notify
			Set tSC = ..%OnLoadKPI()
			If $$$ISERR(tSC) Quit

			If (..%IsCacheable()&&(..%cacheKey'="")) {
				Set tSC = ..%SaveKPIToCache(tSourceType,tSourceQuery)
				If $$$ISERR(tSC) Quit
			}
		}
		
		// + WAL107
		Do ..%OnKPICleanup()
		// - WAL107
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tText = $System.Status.GetErrorText(tSC)
		Do ##class(%DeepSee.Utils).%WriteToLog("Query","Error in KPI %OnLoadModel: " _ tText)
		Set %dsKPIError = tSC
	}
	Quit tSC
}

/// Add a request to compute this KPI to the background agent queue.
Method %QueueKPI() As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		If (..%cacheKey="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing caching key for %QueueKPI")
			Quit
		}

		// write info to cache global so that agent can see it
		Set tClass = $$$UPPER(..%ClassName(1))
		Kill $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error")
		// JMD1103: first time, set pctComplete
		Set tPctComplete = $G($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete"))
		If (tPctComplete="") {
			Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete") = 0
		}

		Do ..%filterValues.%CopyToArray(.tFiltersD)
		// convert filter display values to logical
		// JMD1124 make sure %cube is passed along
		Set:$D(tFiltersD("%cube")) tFilterValues("%cube") = tFiltersD("%cube")

		Kill tFilters
		Set k = $O(tFiltersD(""))
		While (k'="") {
			// ignore data source name
			Set tFilters(k) = ..%GetFilterLogicalValue(k,tFiltersD(k),,.tFilterValues)
			Set k = $O(tFiltersD(k))
		}

		Kill $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"filters")
		Merge $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"filters") = tFilters

		Kill $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"cellContext")
		Merge $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"cellContext") = ..%cellContext

		// queue the task
		// DTB704 - This is now handled by the %DeepSee.WorkMgr, which enforces a task group
		Set tSC = ##class(%DeepSee.WorkMgr).%CreateTaskGroup(.tTaskGroupId,0,"KPI")
		If $$$ISERR(tSC) Quit
		
		Set tSC = ##class(%DeepSee.WorkMgr).%QueueTask(tTaskGroupId,"COMPUTEKPI",..%ClassName(1),..%cacheKey)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		If (($G(tClass)'="")&&(..%cacheKey'="")) {
			// mark as complete (with error)
			If ('$D($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error"))) {
				Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error") = tSC
			}
			Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete") = 100
		}
	}
	Quit tSC
}

/// This is called by a task master background agent that wants to compute the value of this KPI.
ClassMethod %ComputeKPI(pCacheKey As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tClass = $$$UPPER(..%ClassName(1))

		// JMD1495 log if processing flag is set
		If +$G($$$DeepSeeKPIGLVN(tClass,pCacheKey,"zprocessingkpi")) {
			Do ##class(%DeepSee.Utils).%WriteToLog("Query","Unexpected set of zprocessingkpi flag: " _ tClass_":"_pCacheKey)
		}

		// JMD1390: set flag indicating that we are working on this KPI
		// and nobody else should!
		Set $$$DeepSeeKPIGLVN(tClass,pCacheKey,"zprocessingkpi") = 1

		Merge tFilters = $$$DeepSeeKPIGLVN(tClass,pCacheKey,"filters")
		Merge tCellContextArray = $$$DeepSeeKPIGLVN(tClass,pCacheKey,"cellContext")

		If (($G(tClass)'="")&&(pCacheKey'="")) {
			// clear error
			Kill $$$DeepSeeKPIGLVN(tClass,pCacheKey,"error")
		}

		Set tKPIName = ..%GetKPIName()
		Set tCellContext = ""

		// recombine cell context into 1 string
		Set k = $O(tCellContextArray(""))
		While (k'="") {
			Set tCellContext = tCellContext _ $S(tCellContext="":"",1:";") _ tCellContextArray(k)
			Set k = $O(tCellContextArray(k))
		}

		// set flag to indicate we are running in the background
		New %dsBackground
		Set %dsBackground = 1

		// create a data controller to drive the KPI
		Set tSC = ..%CreateKPIController(.tController,tKPIName,.tFilters,tCellContext)
		If $$$ISERR(tSC) Quit

		If '$IsObject($G(tController)) {
			Set tSC = $$$ERROR($$$GeneralError,"%ComputeKPI unable to create controller (1) " _ tKPIName _":" _ tCellContext)
			Quit
		}

		// acquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		If (($G(tClass)'="")&&(pCacheKey'="")) {
			// mark as complete (with error)
			If '$D($$$DeepSeeKPIGLVN(tClass,pCacheKey,"error")) {
				Set $$$DeepSeeKPIGLVN(tClass,pCacheKey,"error") = tSC
			}
			Set $$$DeepSeeKPIGLVN(tClass,pCacheKey,"pctComplete") = 100

			// log the error
			Set tText = $System.Status.GetErrorText(tSC)
			Do ##class(%DeepSee.Utils).%WriteToLog("Query","Error in background KPI %ComputeKPI: " _ tText)
			Set tSC = $$$OK
		}
	}

	// JMD1390 kill processing flag
	If (($G(tClass)'="")&&(pCacheKey'="")) {
		Kill $$$DeepSeeKPIGLVN(tClass,pCacheKey,"zprocessingkpi")
	}

	Quit tSC
}

/// Test if the data cached for this KPI is up-to-date.
/// If not, clear the cached data.
Method %ValidateKPICache(pSourceType As %String, pQueryText As %String = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		// JMD1390
		If (..%cacheKey'="") {
			Set tClass = $$$UPPER(..%ClassName(1))

			// is there data?
			If $D($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"data")) {
				// JMD1495 if we are not checking on pending results AND 
				// force compute is on, force the kill of the cache
				If ((..#FORCECOMPUTE=1)&&('$D(%dsKPIPending))) {
					Set tTimestamp = ""
				}
				ElseIf $D($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error"))&&('$D(%dsKPIPending)) {
					// DTB863 - Do not trust the cache if it produced an error last time.
					Set tTimestamp = ""
				}
				Else {
					// check the timestamp
					Set tSC = ..%ComputeKPITimestamp(.tTimestamp,pSourceType,pQueryText)
					If $$$ISERR(tSC) Quit
				}

				If ((tTimestamp="")||($G($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"timestamp"))'=tTimestamp)) {
					// not up-to-date
					Kill $$$DeepSeeKPIGLVN(tClass,..%cacheKey)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Test if this KPI has cached data.
Method %TestKPICache(Output pIsCached As %Boolean, pSourceType As %String, pQueryText As %String = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set pIsCached = 0

		If (..%cacheKey'="") {
			Set tClass = $$$UPPER(..%ClassName(1))

			// is there an error?
			If $D($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error")) {
				Set tSC = $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error")
				Quit
			}

			Set tPctComplete = $G($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete"))

			// see if someone else is computing this kpi
			// if so, treat it as cached
			If ('$D(%dsBackground)) {
				If ((tPctComplete'="")&&(tPctComplete<100)) {
					Set pIsCached = 1
					Quit
				}
			}

			// is there data?
			If $D($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"data")) {
				Set pIsCached = 1
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Compute the kpi cache key for the current KPI result.
/// Place the result in <property>%cacheKey</property>.
Method %ComputeKPICacheKey(pSourceType As %String, pQueryText As %String = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Set ..%cacheKey = ""

	If ((pSourceType="sql")||(pSourceType="mdx")) {
		// compute key based on query text
		If (pQueryText'="") {
			Set ..%cacheKey = $ZCRC(pQueryText,7)
		}
	}
	Else {
		Set tSC = ..%OnComputeKPICacheKey(.tCacheKey,pQueryText)
		If $$$ISOK(tSC) {
			Set ..%cacheKey = tCacheKey
		}
	}
	Quit tSC
}

/// Runs after the KPI loads and runs
Method %OnKPICleanup() As %Status [ Internal ]
{
	Quit $$$OK
}

/// Compute the kpi cache timestamp for the current KPI result.
/// Overridden by subclasses.
Method %OnComputeKPICacheKey(Output pCacheKey As %String, pQueryText As %String = "") As %Status [ Internal ]
{
	Set pCacheKey = ""
	Quit $$$OK
}

/// Compute the kpi cache timestamp for the current KPI result.
Method %ComputeKPITimestamp(Output pTimestamp As %String, pSourceType As %String, pQueryText As %String = "") As %String [ Final ]
{
	Set pTimestamp = ""

	// if this is an MDX source, we can test
	// JMD1085 If there is no query info, try and find it
	If (pSourceType="mdx") {
		Set tCubeName = ..%cubeName
		Set tQueryKey = ..%queryKey
		Set tMDX = pQueryText
		If (((tCubeName="")||(tQueryKey=""))&&(tMDX'="")) {
			Set tRS = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRS.%PrepareMDX(tMDX)
			If $$$ISERR(tSC) Quit

			// We need to execute to get a query key
			Set tSC = tRS.%ExecuteParameters()
			If $$$ISERR(tSC) Quit

			Set tCubeName = tRS.%GetCubeName()
			Set tQueryKey = tRS.%GetQueryKey()
		}
		If ((tCubeName'="")&&(tQueryKey'="")) {
			Set tCubeIndex = $$$DeepSeeIndex(tCubeName)
			Set pTimestamp = $$$DeepSeeResultsGLVN(tCubeIndex,tQueryKey,"timestamp")
		}
	}

	// dispatch to subclass
	Set tSC = ..%OnComputeKPITimestamp(.pTimestamp,pSourceType,pQueryText)

	If (pTimestamp="") {
		// default timestamp: hold result for one minute
		Set pTimestamp = $P($H,",",2)\60
	}
	Quit tSC
}

/// Compute and return the KPI cache timestamp for the current KPI result.
/// Typically this is the timestamp of the cube this KPI depends on.
Method %OnComputeKPITimestamp(ByRef pTimestamp As %String, pSourceType As %String, pQueryText As %String = "") As %Status
{
	Quit $$$OK
}

/// Load this KPI from cached data.
Method %LoadKPIFromCache() As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		If (..%cacheKey="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing caching key for %LoadKPIFromCache")
			Quit
		}

		Set tClass = $$$UPPER(..%ClassName(1))

		Kill ..%data
		Kill ..%seriesNames

		Merge ..%data = $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"data")
		Merge ..%seriesNames = $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"seriesNames")
		Set ..%seriesCount = $G($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"seriesCount"))

		Set ..%fromCache = 1

		Set tSC = ..%OnLoadKPIFromCache()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Notification that we are loading this KPI from cached data.
Method %OnLoadKPIFromCache() As %Status
{
	Quit $$$OK
}

/// For a KPI running in the background, set the percentage complete.
Method %SetPercentComplete(pPctComplete As %Integer, pErrorCode As %Status = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set:pPctComplete<0 pPctComplete = 0
		// JMD1228: cap % at 99.9; 
		// %SaveKPIToCache will set this 100 when the KPI is saved
		Set:pPctComplete>99.9 pPctComplete = 99.9

		If (..%IsCacheable()&&(..%cacheKey'="")) {
			Set tClass = $$$UPPER(..%ClassName(1))
			If ((pErrorCode'="")&&$$$ISERR(pErrorCode)) {
				Set pPctComplete = 100
				Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error") = pErrorCode
			}
			Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete") = pPctComplete
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Save this KPI to the KPI cache.
Method %SaveKPIToCache(pSourceType As %String, pQueryText As %String = "") As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		If (..%cacheKey="") {
			Set tSC = $$$ERROR($$$GeneralError,"Missing caching key for %SaveKPIToCache")
			Quit
		}

		Set tClass = $$$UPPER(..%ClassName(1))

		// Kill existing cache
		// remove index entry
		Set tOldIndex = $G($$$DeepSeeKPIGLVN(tClass,..%cacheKey,"index"))
		If (tOldIndex'="") {
			Kill $$$DeepSeeKPIGLVN("-index-",tOldIndex,tClass)
		}
		Kill $$$DeepSeeKPIGLVN(tClass,..%cacheKey)

		// JMD1228
		Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete") = 99.99

		// Copy data to cache
		Set tSC = ..%ComputeKPITimestamp(.tTimestamp,pSourceType,pQueryText)
		If $$$ISERR(tSC) Quit

		// first part of cache key is typically the source cube
		Set tIndex = $P(..%cacheKey,"~",1)
		Set:tIndex'="" $$$DeepSeeKPIGLVN("-index-",tIndex,tClass,..%cacheKey)=""

		If $D(..%data("$loadError")) {
			// DTB863 - Place the error in the cache at a parent subscript and remove it from
			// %data to prevent picking it up in the merge.
			Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"error") = ..%data("$loadError")
			Kill ..%data("$loadError")
		}

		Merge $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"type") = pSourceType
		Merge $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"query") = pQueryText
		Merge $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"data") = ..%data
		Merge $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"seriesNames") = ..%seriesNames
		Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"seriesCount") = ..%seriesCount

		Set tSC = ..%OnSaveKPIToCache()

		// JMD1228: set these last
		Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"timestamp") = tTimestamp
		Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"lastRun") = $ZDT($H,3)
		Set $$$DeepSeeKPIGLVN(tClass,..%cacheKey,"pctComplete") = 100
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Notification that we are saving this KPI to the cache.
Method %OnSaveKPIToCache() As %Status
{
	Quit $$$OK
}

/// Return information on properties defined in the KPI block.
/// This takes the form:<br/>
/// pList(n) = name<br/>
/// pList(n,"defaultValue") = value<br/>
/// pList(n,"columnNo") = #<br/>
ClassMethod %GetKPIPropertyInfo(Output pList As %String, pModelId As %String = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	#; figure out if this page should provide automatic localization
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
	}

	Set tLastPropNo = 1
	Set tPropNo = $O(^||%Cls(%compiledclass.Name,"props",""),1,tProp)
	While (tPropNo'="") {
		Do %code.WriteLine(" Set pList("_tPropNo_") = "_$$$quote(tProp))
		Set tDefVal = $G(^||%Cls(%compiledclass.Name,"props",tPropNo,"defaultValue"))
		If (tDefVal'="") {
			Do %code.WriteLine(" Set pList("_tPropNo_",""value"") = "_$$$quote(tDefVal))
		}
		Set tColumnNo = $G(^||%Cls(%compiledclass.Name,"props",tPropNo,"columnNo"))
		If (tColumnNo'="") {
			Do %code.WriteLine(" Set pList("_tPropNo_",""columnNo"") = "_+tColumnNo)
		}
		Set tCaption = $G(^||%Cls(%compiledclass.Name,"props",tPropNo,"displayName"))
		If (tCaption'="") {
			If (tLocalize) {
				Do %code.WriteLine(" Set pList("_tPropNo_",""caption"") = $$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_")")
			}
			Else {
				Do %code.WriteLine(" Set pList("_tPropNo_",""caption"") = "_$$$quote(tCaption))
			}
		}
		// JMD921: format and style
		Set tFormat = $G(^||%Cls(%compiledclass.Name,"props",tPropNo,"format"))
		If (tFormat'="") {
			Do %code.WriteLine(" Set pList("_tPropNo_",""format"") = "_$$$quote(tFormat))
		}
		Set tStyle = $G(^||%Cls(%compiledclass.Name,"props",tPropNo,"style"))
		If (tStyle'="") {
			Do %code.WriteLine(" Set pList("_tPropNo_",""style"") = "_$$$quote(tStyle))
		}
		Set tHeaderStyle = $G(^||%Cls(%compiledclass.Name,"props",tPropNo,"headerStyle"))
		If (tHeaderStyle'="") {
			Do %code.WriteLine(" Set pList("_tPropNo_",""headerStyle"") = "_$$$quote(tHeaderStyle))
		}

		Set tLastPropNo = tPropNo
		Set tPropNo = $O(^||%Cls(%compiledclass.Name,"props",tPropNo),1,tProp)
	}
	Do %code.WriteLine(" Set tPropNo = "_tLastPropNo)
	Do %code.WriteLine(" Quit ..%OnGetKPIPropertyInfo(.pList,tPropNo,pModelId)")
	Quit $$$OK
}

/// Add additional properties beyond those defined in the KPI block.
/// This takes the form:<br/>
/// pList(n) = name<br/>
/// pList(n,"defaultValue") = value<br/>
/// pList(n,"columnNo") = #<br/>
/// <var>pPropNo</var> is the number of next open slot in the list.
ClassMethod %OnGetKPIPropertyInfo(ByRef pList As %String, pPropNo As %Integer, pModelId As %String = "") As %Status
{
	Quit $$$OK
}

/// Return an MDX statement to provide the KPI data.
Method %GetMDX(Output pMDX As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Set pMDX = ""
	Try {
		Set pMDX = ..%GetMDXText()
		Set tSC = ..%OnGetMDX(.pMDX)
		If $$$ISERR(tSC) Quit

		// JMD1046: apply context filter
		Set:pMDX'="" pMDX = pMDX_..%GetMDXContextFilter()
	}
	Catch(ex) {
		Set pMDX = ""
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback, if implemented, lets a subclass provide an MDX statement to fetch data for this KPI. 
/// If there are filter values, they will be within the <var>%filterValues</var> property (an object).
Method %OnGetMDX(ByRef pMDX As %String) As %Status
{
	Quit $$$OK
}

/// Return a series of %FILTER clauses (as a single string) based on the "%CONTEXT"
/// of the %KPI or %MDX function that invoked this KPI.
/// This behavior is automatic; you can override this method and return "" if you do
/// not want this to happen.
Method %GetMDXContextFilter() As %String
{
	Set tFilters = ""

	// add context filters
	// these are set by the MDX query invoking this KPI
	Set k = $O(%dsCellContext(""))
	While (k'="") {
		Set tSpec = $G(%dsCellContext(k))
		If (tSpec'="") {
			Set tFilters = tFilters _ " %FILTER " _ tSpec
		}
		Set k = $O(%dsCellContext(k))
	}
	Quit tFilters
}

/// Execute an MDX statement and use the results to provide the KPI data.
Method %ExecuteMDX(pMDX As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// get list of defined properties
		Set tSC = ..%GetKPIPropertyInfo(.tKPIProps)
		If $$$ISERR(tSC) Quit

		// map columns to KPI properties
		Set p = $O(tKPIProps(""))
		While (p'="") {
			Set tColNo = +$G(tKPIProps(p,"columnNo"))
			If (tColNo>0) {
				Set tColumns(tColNo) = p
			}
			Else {
				Set tUnmapped(p) = ""
			}
			Set p = $O(tKPIProps(p))
		}


		// JMD1390: test for pivot variables
		Kill tVariables
		If ($$$LOWER(pMDX)["$variable.") {
			// find cube name
			Set tRSX = ##class(%DeepSee.ResultSet).%New()
			Set tSC = tRSX.%PrepareMDX(pMDX)
			If $$$ISERR(tSC) Quit

			Set tCubeName = tRSX.%GetCubeName()
			If (tCubeName'="") {
				Set tSC = ##class(%DeepSee.Utils).%GetPivotVariables(tCubeName,.tVariableList)
				If $$$ISERR(tSC) Quit

				Set vk = $O(tVariableList(""))
				While (vk'="") {
					Set tVName = $$$LOWER($LG(tVariableList(vk),1))
					Set tVDefValue = $LG(tVariableList(vk),3)
					Set tVariables(tVName) = tVDefValue
					Set vk = $O(tVariableList(vk))
				}
			}
		}

		Set ^DeepSee.LastQueryKPI = pMDX
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareMDX(pMDX,.tVariables,.tResolvedMDX)
		Set:$G(tResolvedMDX)'="" ^DeepSee.LastQueryKPI = tResolvedMDX
		If $$$ISERR(tSC) Quit

		// async ???
		Set tSC = tRS.%Execute(.tParmValues)
		If $$$ISERR(tSC) Quit

		// remember the query cube and key
		Set ..%cubeName = tRS.%GetCubeName()
		Set ..%queryKey = tRS.%GetQueryKey()

		Set tAxisCount = tRS.%GetAxisCount()
		If (tAxisCount = 0) {
			Set tValue = tRS.%GetValue()
		}
		Else {
			For a = 1:1:tAxisCount {
				Set tAxisSize(a) = tRS.%GetAxisSize(a)
			}
			Set tSeriesCount = 0
			Set tColCount = +$G(tAxisSize(1))
			Set tRowCount = +$G(tAxisSize(2))

			// JMD1086 Query may have no rows!
			Set tNoData = 0
			If (tRowCount = 0) {
				Set tNoData = 1
				Set tRowCount = 1
			}
			If (tColCount = 0) {
				Set tNoData = 1
				Set tColCount = 1
			}

			For r=1:1:tRowCount {
				// row labels are series
				If (tNoData) {
					Set tLabel(1) = $$$Text("No results","%DeepSee")
				}
				Else {
					Do tRS.%GetOrdinalLabel(.tLabel,2,r)
				}
				Set tSeriesCount = tSeriesCount + 1
				// JMD1019: concatenate nested labels
				Set tSeriesName = ""
				Set k = $O(tLabel(""),-1)
				While (k'="") {
					Set:$G(tLabel(k))'="" tSeriesName = tSeriesName _ $S(tSeriesName="":"",1:..#LABELCONCAT) _ $G(tLabel(k))
					Set k = $O(tLabel(k),-1)
				}
				Set ..%seriesNames(tSeriesCount) = tSeriesName

				// columns are properties
				Set c = $O(tColumns(""))
				While (c'="") {
					Set p = tColumns(c)
					Set tPropName = tKPIProps(p)
					If (c<=tColCount) {
						// pull data from column
						Set ..%data(tSeriesCount,tPropName) = $Case(tAxisCount,
															1:tRS.%GetOrdinalValue(c),
															:tRS.%GetOrdinalValue(c,r))
					}
					Else {
						// use default
						Set ..%data(tSeriesCount,tPropName) = $G(tKPIProps(p,"value"))
					}
					Set c = $O(tColumns(c))
				}
				// apply default to properties with no col #
				Set p = $O(tUnmapped(""))
				While (p'="") {
					Set tPropName = tKPIProps(p)
					Set ..%data(tSeriesCount,tPropName) = $G(tKPIProps(p,"value"))
					Set p = $O(tUnmapped(p))
				}
			}
			Set ..%seriesCount = tSeriesCount
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an SQL statement to provide the KPI data.
Method %GetSQL(Output pSQL As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Set pSQL = ""
	Try {
		Set pSQL = ..%GetSQLText()
		Set tSC = ..%OnGetSQL(.pSQL)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set pSQL = ""
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an SQL statement to provide the KPI's listing data.
Method %GetListingSQL(Output pSQL As %String, ByRef pFilters, ByRef pSelection, pListingName) As %Status [ Final, Internal ]
{
	// Method added by DP-428558
	Set tSC = $$$OK
	Set pSQL = ""
	Try {
		Set pSQL = ..%OnGetListingSQL(.pFilters,.pSelection,pListingName)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set pSQL = ""
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback, if implemented, lets a subclass provide an SQL statement to fetch data for this KPI. 
/// If there are filter values, they will be within the <var>%filterValues</var> property (an object).
Method %OnGetSQL(ByRef pSQL As %String) As %Status
{
	Quit $$$OK
}

/// Execute an SQL statement and use the results to provide the KPI data.
Method %ExecuteSQL(pSQL As %String) As %Status [ Final, Internal ]
{
	Set tSC = $$$OK
	Try {
		// get list of defined properties
		Set tSC = ..%GetKPIPropertyInfo(.tKPIProps)
		If $$$ISERR(tSC) Quit

		// map columns to KPI properties
		Set p = $O(tKPIProps(""))
		While (p'="") {
			Set tColNo = +$G(tKPIProps(p,"columnNo"))
			If (tColNo>0) {
				// n.b., column 1 is used for the series name
				// but user can also map a property to it
				Set tColumns(tColNo) = p
			}
			Else {
				Set tUnmapped(p) = ""
			}
			Set p = $O(tKPIProps(p))
		}

		Set ^DeepSee.LastQueryKPI = pSQL
		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare(pSQL)
		If $$$ISERR(tSC) {
			Quit
		}

		Set:..%cacheKey'="" tSC = ..%SetPercentComplete(10)
		If $$$ISERR(tSC) Quit

		Set tRS = tStatement.%Execute()

		Set:..%cacheKey'="" tSC = ..%SetPercentComplete(20)
		If $$$ISERR(tSC) Quit

		// columns define properties; column 1 is the series name
		// rows provide series

		Set tColumnMeta = tRS.%GetMetaData().columns
		Set tColumnCount = tColumnMeta.Count()

		// KPIs are limited to 1000 data series
		Set tMaxSeries = 1000
		Set tSeriesCount = 0
		Set tSeriesColumn = 1
		While (tRS.%Next(.tSC) && (tSeriesCount < tMaxSeries)) {
			If $$$ISERR(tSC) Quit
			Set tSeriesCount = tSeriesCount + 1

			If (..%cacheKey'="") {
				If (tSeriesCount>100) {
					Set tPct = 60 + ((tSeriesCount/1000)*40)
				}
				Else {
					Set tPct = 20 + ((tSeriesCount/100)*40)
				}
				Set:tPct>90 tPct=90
				Set tSC = ..%SetPercentComplete(tPct)
			}

			Set ..%seriesNames(tSeriesCount) = tRS.%GetData(tSeriesColumn)
			Set c = $O(tColumns(""))
			While (c'="") {
				Set p = tColumns(c)
				Set tPropName = tKPIProps(p)
				If (c<=tColumnCount) {
					// pull data from column
					Set ..%data(tSeriesCount,tPropName) = tRS.%GetData(c)
				}
				Else {
					// use default
					Set ..%data(tSeriesCount,tPropName) = $G(tKPIProps(p,"value"))
				}
				Set c = $O(tColumns(c))
			}
	
			// apply default to properties with no col #
			Set p = $O(tUnmapped(""))
			While (p'="") {
				Set tPropName = tKPIProps(p)
				Set ..%data(tSeriesCount,tPropName) = $G(tKPIProps(p,"value"))
				Set p = $O(tUnmapped(p))
			}
		}
		Set ..%seriesCount = tSeriesCount

		Do ..%SetPercentComplete(100)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tSC) {
		// mark query as complete
		Do ..%SetPercentComplete(100,tSC)
	}
	
	Quit tSC
}

/// Get data for this KPI manually.
/// This is implemented by subclasses that provide manual data.
Method %OnExecute() As %Status
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible filters for this KPI.
/// This drives the list of filter selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pFilters(n)=$LB(name,caption,filterProperty,multiSelect,dependsOn,searchType)<br/>
ClassMethod %GetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// JMD997: localize filter names
	#; figure out if this page should provide automatic localization
	Set tLocalize = 0
	Set DOMAIN = $G(%parameter("DOMAIN"))
	If (%class.System > 0) {
		Set tLocalize = (DOMAIN '= "")
	}
	Else {
		Set tLocalize = (DOMAIN '= "") && (DOMAIN '= "%DeepSee")
	}

	Do %code.WriteLine(" Kill pFilters")

	Set tFilterNo = $O(^||%Cls(%compiledclass.Name,"filters",""))
	While (tFilterNo'="") {
		Set tName = ^||%Cls(%compiledclass.Name,"filters",tFilterNo)
		Set tCaption = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"displayName"))
		Set:tCaption="" tCaption = tName
		Set tFilterProperty = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"filterProperty"))
		Set:tFilterProperty="" tFilterProperty = tName
		Set tMultiSelect = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"multiSelect"))
		Set:tMultiSelect="" tMultiSelect = 1
		Set tDependsOn = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"dependsOn"))
		Set tSearchType = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"searchType"))
		
		Set tDefaultValue = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"defaultValue")) // WAL189 

		// JMD997
		If (tLocalize) {
			Do %code.WriteLine(" Set pFilters($I(pFilters)) = $LB("_$$$quote(tName)_",$$$Text("_$$$quote(tCaption)_","_$$$quote(DOMAIN)_"),"_$$$quote(tFilterProperty)_","_$$$quote(tMultiSelect)_","_$$$quote(tDependsOn)_","_$$$quote(tSearchType)_","_$$$quote(tDefaultValue)_")") // WAL189
		}
		Else {
			Do %code.WriteLine(" Set pFilters($I(pFilters)) = $LB("_$$$quote(tName)_","_$$$quote(tCaption)_","_$$$quote(tFilterProperty)_","_$$$quote(tMultiSelect)_","_$$$quote(tDependsOn)_","_$$$quote(tSearchType)_","_$$$quote(tDefaultValue)_")") // WAL189
		}

		Set tFilterNo = $O(^||%Cls(%compiledclass.Name,"filters",tFilterNo))
	}
	Do %code.WriteLine(" Quit ..%OnGetFilterList(.pFilters,pDataSourceName)")
	Quit $$$OK
}

/// Callback to get additional possible filters for this KPI.
/// This drives the list of filter selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pFilters($I(pFilters))=$LB(name,caption,value,multiSelect)<br/>
ClassMethod %OnGetFilterList(Output pFilters As %List, pDataSourceName As %String = "") As %Status
{
	Quit $$$OK
}

/// Return a list of possible filter values for a given filter.
/// This takes the form:<br/>
/// pMembers(n)=$LB(text,value)<br/>
ClassMethod %GetFilterMembers(pFilter As %String, Output pMembers As %List, Output pDefaultValue As %String, pSearchKey As %String = "", pDataSourceName As %String = "", ByRef pFilterValues As %String) As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	Do %code.WriteLine(" Set tSC = $$$OK")
	Do %code.WriteLine(" Kill pMembers")
	Do %code.WriteLine(" Set pDefaultValue = """"")

	Do %code.WriteLine(" Try {")

	Set tIfCount = 0
	Set tFilterNo = $O(^||%Cls(%compiledclass.Name,"filters",""))
	While (tFilterNo'="") {
		Set tName = ^||%Cls(%compiledclass.Name,"filters",tFilterNo)
		Set tSQL = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"sql"))
		Set tValueList = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"valueList"))
		Set tDisplayList = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"displayList"))
		Set tDefaultValue = $G(^||%Cls(%compiledclass.Name,"filters",tFilterNo,"defaultValue"))

		If ((tSQL'="")||(tValueList'="")) {
			Do %code.WriteLine("  "_$S(tIfCount:"Else",1:"")_"If ($$$UPPER(pFilter)=$$$UPPER("_$$$quote(tName)_")) {")
			Do %code.WriteLine("   Set pDefaultValue = " _ $$$quote(tDefaultValue))
			Set tIfCount = tIfCount + 1
			If (tValueList'="") {
				For p = 1:1:$L(tValueList,",") {
					Set tValue = $P(tValueList,",",p)
					If (tDisplayList="") {
						Set tDisp = tValue
					}
					Else {
						Set tDisp = $P(tDisplayList,",",p)
					}
					Do %code.WriteLine("   Set pMembers($I(pMembers)) = $LB("_$$$quote(tDisp)_","_$$$quote(tValue)_")")
				}
			}
			ElseIf (tSQL'="") {
				Do %code.WriteLine("   Set tSQL = " _ $$$quote(tSQL))
				Do %code.WriteLine("   Set tStatement = ##class(%SQL.Statement).%New(,""DEFAULT_SCHEMA"")")
				Do %code.WriteLine("   Set tSC = tStatement.%Prepare(tSQL)")

				Do %code.WriteLine("   If $$$ISERR(tSC) {")				// log the error
				Do %code.WriteLine("    Set tMsg = ""Error in %GetFilterMembers query: "_%class.Name_"""")
				Do %code.WriteLine("    Set tMsg = tMsg _ $C(13,10,9)_ tSQL")
				Do %code.WriteLine("    Set tMsg = tMsg _ $C(13,10,9)_ $System.Status.GetErrorText(tSC)")
				Do %code.WriteLine("    Do ##class(%DeepSee.Utils).%WriteToLog(""KPI"",tMsg)")
				Do %code.WriteLine("    Quit")
				Do %code.WriteLine("   }")

				Do %code.WriteLine("   Set tRS = tStatement.%Execute()")
				Do %code.WriteLine("   Set tRSMD = tRS.%GetMetadata()")
				Do %code.WriteLine("   Set tColumns = tRSMD.columns.Count()")

				Do %code.WriteLine("   While (tRS.%Next(.tSC)) {")

				Do %code.WriteLine("    Set tValue = tRS.%GetData(1)")
				Do %code.WriteLine("    Set tDisp = $S(tColumns>1:tRS.%GetData(2),1:tValue)")

				Do %code.WriteLine("    Set pMembers($I(pMembers)) = $LB(tDisp,tValue)")
				Do %code.WriteLine("    If $$$ISERR(tSC) Quit")
				Do %code.WriteLine("   }")
			}
			Do %code.WriteLine("  }")
		}
		Set tFilterNo = $O(^||%Cls(%compiledclass.Name,"filters",tFilterNo))
	}
	Do %code.WriteLine("  If $$$ISERR(tSC) Quit")
	Do %code.WriteLine("  Set tSC = ..%OnGetFilterMembers(pFilter,.pMembers,pSearchKey,pDataSourceName,.pFilterValues)")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Catch(ex) {")
	Do %code.WriteLine("  Set tSC = ex.AsStatus()")
	Do %code.WriteLine(" }")
	Do %code.WriteLine(" Quit tSC")
	Quit $$$OK
}

/// Return list of possible actions for this KPI.
/// This drives the list of action selections for widget connected to this KPI.
/// This takes the form:<br/>
/// pActions(n)=$LB(name,caption)<br/>
ClassMethod %GetActionList(ByRef pActions As %List, pDataSourceName As %String = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// n.b., pActions may already have items in it!

	// check for additional action class
	Set tActionClass = $G(^||%Cls(%compiledclass.Name,"actionClass"))
	If ((tActionClass'="")&&(tActionClass'=%compiledclass.Name)) {
		Do %code.WriteLine(" Set tSC = ##class("_tActionClass_").%GetActionList(.pActions)")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")
	}

	Set tActionNo = $O(^||%Cls(%compiledclass.Name,"actions",""))
	While (tActionNo'="") {
		Set tName = ^||%Cls(%compiledclass.Name,"actions",tActionNo)
		Set tCaption = $G(^||%Cls(%compiledclass.Name,"actions",tActionNo,"displayName"))
		Set:tCaption="" tCaption = tName

		Do %code.WriteLine(" Set pActions($I(pActions)) = $LB("_$$$quote(tName)_","_$$$quote(tCaption)_")")

		Set tActionNo = $O(^||%Cls(%compiledclass.Name,"actions",tActionNo))
	}
	Do %code.WriteLine(" Quit ..%OnGetActionList(.pActions,pDataSourceName)")
	Quit $$$OK
}

/// Internal method that gets invoked from a client dashboard and dispatches to a user callback.
ClassMethod %InvokeDashboardAction(pAction As %String, pContext As %ZEN.proxyObject, pDataSourceName As %String = "") As %Status [ CodeMode = objectgenerator, Final, GenerateAfter = %Generate, Internal ]
{
	// check for additional action class
	Set tActionClass = $G(^||%Cls(%compiledclass.Name,"actionClass"))
	// + WAL075 -- encrypt here so that developers' %OnDashboardAction code doesn't have to change due to WAL075
	//           after that change we now send unencrypted MDX back to the server
	//Do %code.WriteLine(" If ($D(pContext)&&($property(pContext,""mdx"")'="_ """""" _")) { Set pContext.mdx = $$$cspEncode(%session.Key,pContext.mdx) }") // + WAL147 -- don't encrypt
	// - WAL075
	If ((tActionClass'="")&&(tActionClass'=%compiledclass.Name)) {
		Do %code.WriteLine(" Set tSC = ##class("_tActionClass_").%InvokeDashboardAction(pAction,pContext,pDataSourceName)")
		Do %code.WriteLine(" If $$$ISERR(tSC) Quit tSC")
	}
	Do %code.WriteLine(" Quit ..%OnDashboardAction(pAction,pContext,pDataSourceName)")
	Quit $$$OK
}

/// Convenience method.
/// For a given DeepSee cube and filter spec, return a list of members in the form:<br/>
/// pMembers(n)=$LB(text,value)<br/>
/// This list contains both the display names (text) of the filter items 
/// and the logical names (value).<br/>
/// <var>pCube</var> is the logical name of the cube with .cube appended, 
/// for example: "holefoods.cube"<br/>
/// <var>pFilterSpec</var> is the COMPLETE name of a level within the cube:<br/>
/// "[DateOfSale].[Actual].[YearSold]"<br/>
/// <var>pSearchKey</var> is any search text entered by the user.
ClassMethod %GetMembersForFilter(pCube As %String, pFilterSpec As %String, Output pMembers, pSearchKey As %String = "") As %Status
{
	Quit ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(pCube,pFilterSpec,.pMembers,,pSearchKey)
}

/// Given a filter name, <var>pFilterName</var>, and an SQL field name, <var>pFieldName</var>, return an SQL expression
/// based on the filter value(s) that can be used within an SQL WHERE clause.
/// Returns "" if there is no filter value.<br/>
/// For example: if you have a SQL-based KPI class based on a table with a YearSold field, 
/// you can get an SQL expression for it:<br/>
/// 	Set tYearExpr = ..%GetSQLForFilter("YearSold","Year")<br/>
/// 	If tYearExpr is not "", then you can add it to your SQL WHERE clause to add the filtering:<br/>
/// 	Set tSQL = tSQL _ " WHERE " _ tYearExpr<br/>
/// 	or if your query already has a WHERE clause:<br/>
/// 	Set tSQL = tSQL _ " AND " _ tYearExpr<br/>
/// 
Method %GetSQLForFilter(pFieldName As %String, pFilterName As %String) As %String
{
	Set tExpr = ""
	Set tProxy = ..%filterValues
	If $IsObject(tProxy) {
		Set tValue = $zobjproperty(tProxy,pFilterName)
		Set tValue = $ZSTRIP(tValue,"<>W")
		Set tNOT = 0

		If ((pFieldName'="")&&(tValue'="")) {
			If ($E(tValue,1,5)="%NOT ") {
				Set tNOT = 1
				Set tValue = $E(tValue,6,$L(tValue))
			}

			// check for multiple values
			If ($E(tValue,1)="{") {
				// pull apart the list of values: {a,b}
				Set tValue = $E(tValue,2,$L(tValue)-1)
				Do ..%SplitList(tValue,.tList)
				Set tInList = ""
				Set k = $O(tList(""))
				While (k'="") {
					Set tItem = tList(k)

					// JMD1481: unquote
					If ($E(tItem,1,2)="&[") {
						Set tItem = $E(tItem,3,$L(tItem)-1)
					}
					Set tType = ""
					Set:tItem?4N1"-"2N1"-"2N tType="date"
					Set:tItem'="" tInList = tInList _ $S(tInList="":"",1:",") _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tItem,tType)
					Set k = $O(tList(k))
				}
				If (tNOT) {
					Set tExpr = pFieldName _ " NOT IN (" _ tInList _ ")"
				}
				Else {
					Set tExpr = pFieldName _ " IN (" _ tInList _ ")"
				}
			}
			ElseIf (($E(tValue,1,2)="&[")&&(tValue["]:&[")) {
				// JMD1481: range a:b
				// remove outer quotes
				Set tValue = $E(tValue,3,$L(tValue)-1)
				Set tVal1 = $P(tValue,"]:&[",1)
				Set tVal2 = $P(tValue,"]:&[",2)

				Set tType = ""
				Set:tVal1?4N1"-"2N1"-"2N tType="date"

				If (tNOT) {
					Set tExpr = pFieldName _ " NOT BETWEEN " _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tVal1,tType) _ " AND " _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tVal2,tType)
				}
				Else {
					Set tExpr = pFieldName _ " BETWEEN " _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tVal1,tType) _ " AND " _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tVal2,tType)
				}
			}
			Else {
				// JMD1481: unquote
				If ($E(tValue,1,2)="&[") {
					Set tValue = $E(tValue,3,$L(tValue)-1)
				}
				Set tType = ""
				Set:tValue?4N1"-"2N1"-"2N tType="date"

				If (tNOT) {
					Set tExpr = pFieldName _ " <> " _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tValue,tType)
				}
				Else {
					Set tExpr = pFieldName _ " = " _ ##class(%ZEN.Auxiliary.QueryInfo).QuoteSQL(tValue,tType)
				}
			}
		}
	}
	Quit tExpr
}

/// Given a filter name, <var>pFilterName</var>, and a level specification, <var>pLevelSpec</var>,
/// return an MDX expression
/// based on the filter value(s) that can be used within an MDX WHERE or %FILTER clause.<br/>
/// Returns "" if there is no filter value.<br/>
/// For example: if you have a MDX-based KPI class with a YearSold level within a 
/// DateOfSale dimension and a filter named Year, you can get an MDX filter expression for it:<br/>
/// 	Set tYearFilter = ..%GetMDXForFilter("[DateOfSale].[YearSold]","Year")<br/>
/// 	If tYearFilter is not "", then you can add it to your MDX query to add the filtering:<br/>
/// 	Set tMDX = tMDX _ " %FILTER " _ tYearFilter<br/>
/// 
Method %GetMDXForFilter(pLevelSpec As %String, pFilterName As %String) As %String
{
	Set tExpr = ""
	Set tProxy = ..%filterValues
	If $IsObject(tProxy) {
		Set tValue = $zobjproperty(tProxy,pFilterName)
		Set tValue = $ZSTRIP(tValue,"<>W")
		If ((pLevelSpec'="")&&(tValue'="")) {
			// check for multiple values
			If ($E(tValue,1)="{") {
				// pull apart the list of values: {&[],&[]}
				Set tValue = $E(tValue,2,$L(tValue)-1)
				Do ..%SplitList(tValue,.tList)
				Set k = $O(tList(""))
				While (k'="") {
					Set tItem = tList(k)
					Set:tItem'="" tExpr = tExpr _ $S(tExpr="":"",1:",") _ pLevelSpec_ "." _ tItem
					Set k = $O(tList(k))
				}
				Set tExpr = "{"_tExpr_"}"
			}
			Else {
				Set tExpr = pLevelSpec_ "." _ tValue
			}
		}
	}
	Quit tExpr
}

/// Given a value, test if it has multiple values and return a list of them.
/// For example, "Apple" returns "Apple" and a count of 1. "{[2001],[2002]}" returns 
/// "[2001]","[2002]", and count of 2. This method assumes that enclosing {} have already been removed.<br/>
/// Return number of items in the value.
ClassMethod %SplitList(pValue As %String, Output pList) As %Integer [ Internal ]
{
	Set tCount = 0
	Kill pList
	Set tState = 0
	Set tToken = ""
	For p=1:1:$L(pValue) {
		Set ch = $E(pValue,p)
		If (tState = 0) {
			If (ch = ",") {
				Set tCount = tCount + 1
				Set pList(tCount) = tToken
				Set tToken = ""
			}
			ElseIf (ch = "[") {
				Set tToken = tToken _ ch
				Set tState = 1
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
		ElseIf (tState = 1) {
			If (ch = "]") {
				Set tToken = tToken _ ch
				Set tState = 0
			}
			Else {
				Set tToken = tToken _ ch
			}
		}
	}

	If (tToken '= "") {
		Set tCount = tCount + 1
		Set pList(tCount) = tToken
	}
	Quit tCount
}

}
