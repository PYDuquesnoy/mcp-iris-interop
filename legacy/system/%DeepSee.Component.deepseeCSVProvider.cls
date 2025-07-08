/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This class is responsible for creating a CSV file from the contents of a DeepSee ResultSet
Class %DeepSee.Component.deepseeCSVProvider Extends %ZEN.Component.component [ System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js";

///  This is the XML namespace used for library components.
Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

Parameter DOMAIN = "%DeepSee";

/// This class does not project HTML into its containing document
Method %DrawHTML()
{
}

/// Return the temp directory for this system.
ClassMethod GetSystemTempDir() As %String
{
	Quit ##class(%SYS.System).TempDirectory()
}

/// Given a user specified file name clip it to ensure that it only refers to 
/// files in the mgr/temp space
ClassMethod ScopeFileName(rawName As %String) As %String [ ZenMethod ]
{
	Set tCSPSession = $IsObject($G(%session))
	
	// Get the list of temp files we've touched (or create one if this is the first)
	If tCSPSession&&$D(^IRIS.Temp.zenData(%session.SessionId,"dsCSVProvider","tempFiles")) {
 		Set activeNames = {}.%FromJSON(^IRIS.Temp.zenData(%session.SessionId,"dsCSVProvider","tempFiles"))
	} 
	Else {
		Set activeNames = {}
	}
	
	Set dir = ..GetSystemTempDir()
	Set name = ##class(%File).GetFilename(rawName)
	
	Set name=$Translate(name,"$<>:""/\|?*","")		// Sanitize the filename for cross-platform use
	
	Set csName = ##class(%File).NormalizeFilename(name,dir)

	If tCSPSession {
		// If this came from a CSP client, add the new name to the list of temp files we've 
		// created for the purposes of deleting them later.
		Do activeNames.%Set(csName,1)
		Set ^IRIS.Temp.zenData(%session.SessionId,"dsCSVProvider","tempFiles") = activeNames.%ToJSON()
	}

	Quit csName
}

/// Remove a temporary file used for this provider within this session from the mgr/Temp directory
ClassMethod RemoveFile(pFileName) As %Status
{
	Set tSC = $$$OK
	Try {
		// Get the list of temp files we've touched
		If $D(^IRIS.Temp.zenData(%session.SessionId,"dsCSVProvider","tempFile"),tTempFile) {
 			If (pFileName=tTempFile) {
				Set tFileName = ..ScopeFileName(pFileName)
				If ##class(%Library.File).Exists(tFileName) {
					Set tSC = ##class(%Library.File).Delete(tFileName)
				}
				
				Kill ^IRIS.Temp.zenData(%session.SessionId,"dsCSVProvider","tempFile")
			}
		} 
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Export the results of an MDX query to <var>pFileName<var>. Parameters can be passed from the client
/// in a serialized JSON string that will be deserialized into a DynamicObject
ClassMethod ExportCSV(pMDX = "", pFileName As %String = "", pParmsJSON As %String = "", Output pStatus As %Status) As %String [ ZenMethod ]
{
	// Method implemented by DP-402897
	Set tSC = $$$OK
	
	Try {
		// Deserialize the parameter string to an object for easy reference. Manually initialize
		// an empty object in the case of a null parameter string to avoid error in %FromJSON.	
		Set tParmsObj = $S((pParmsJSON'=""):{}.%FromJSON(pParmsJSON),1:{})
		
		// The fileName could come in as part of the parameters object, check for this in the 
		// case of a null pFileName. If there is still no fileName to use, throw an error.
		Set tFileName = $S(pFileName'="":pFileName,1:tParmsObj.fileName)
		If (tFileName="") {
			Set tSC = $$$ERROR($$$FileNameRequired)
			Quit
		}
		
		// For now this will test for an unused file name. There could be a
		// launch of the OS file browser for the user to set this file name that would
		// override this default behavior.
		Set tFileNum = 0
		If ($P(tFileName,".",*)="csv") {
			Set tFileNameRoot = $P(tFileName,".",*-1)
		}
		Else {
			Set tFileNameRoot = tFileName
		}
		
		// Create file names and continually test against previously saved files until
		// a unique file name is found.
		Do {
			Set tNewFileName = tFileNameRoot _ $S(tFileNum:" ("_tFileNum_")",1:"") _ ".csv"
			Set tSafeFileName = ..ScopeFileName(tNewFileName)
			Set tFileNum = tFileNum + 1
		} While (##class(%File).Exists(tSafeFileName))

		// At this point the ResultSet has successfully produced results, prepare the file. 
		Set tFileStream = ##class(%Stream.FileCharacter).%New()
		Set tSC = tFileStream.LinkToFile(tSafeFileName)
		If $$$ISERR(tSC) Quit
		Set tSC = tFileStream.TranslateTableSet("UTF8")		// DP-414415
		If $$$ISERR(tSC) Quit
		
		
		Set tHasHeaderLines = 0
		If '(tParmsObj.simple) {
			If (tParmsObj.title'="") {
				Do tFileStream.WriteLine($$$iscEscapeCSV(tParmsObj.title))
				Set tHasHeaderLines = 1
			}
			If (tParmsObj.subtitleOn="on")&&(tParmsObj.subtitle'="") {
				Do tFileStream.WriteLine($$$iscEscapeCSV(tParmsObj.subtitle))
				Set tHasHeaderLines = 1
			}
			If (tParmsObj.showUser="on") {
				Do tFileStream.WriteLine($$$iscEscapeCSV($USERNAME))
				Set tHasHeaderLines = 1
			}
			If (tParmsObj.showDate="on") {
				Do tFileStream.WriteLine($$$iscEscapeCSV($zdt($H,3)))
				Set tHasHeaderLines = 1
			}
			
			// Insert a blank line if any of the header data was inserted
			Do:tHasHeaderLines tFileStream.WriteLine("")
			
			If (tParmsObj.filterNames'="")&&(tParmsObj.showFilters'="off") {
				Set tSC = ..%EmitNameValueTable(tFileStream,tParmsObj.filterNames,tParmsObj.filterValues,"- FILTERS -",tParmsObj)
				If $$$ISERR(tSC) Quit
			}
			
			If (tParmsObj.pivotVarNames'="") {
				Set tSC = ..%EmitNameValueTable(tFileStream,tParmsObj.pivotVarNames,tParmsObj.pivotVarValues,"- PIVOT VARIABLES -",tParmsObj)
				If $$$ISERR(tSC) Quit
			}
		}


		
		// Emit the actual contents of the ResultSet into the file in CSV format. 
		// Execute the resultset and confirm success before writing to the file
		If (tParmsObj.kpi'="") {
			Set tSC = ..%EmitKpiResult(tParmsObj,tFileStream)
		}
		Else { 
			Set tRS = ..%CreateResultSet(pMDX,.tSC,tParmsObj)
			If $$$ISERR(tSC) Quit
			
			If tRS.%IsDrillThrough() {
				Set tSC = ..%EmitListingResultSet(tRS,tFileStream)
			}
			Else {
				Set tSC = ..%EmitResultSet(tRS,tFileStream)
			}
		}	
		If $$$ISERR(tSC) Quit
		

		Do tFileStream.%Save()
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) && $IsObject(tFileStream) {
		// If there is an error, delete the temporary file.
		Do ..RemoveFile(tFileStream.Filename)
		Kill tFileStream
		
		Set tNewFileName = ""
	}
	
	Set pStatus = tSC		// DP-406415
	Quit tNewFileName		// Return the new fileName to the caller
}

/// Create a resultset from MDX query text. Failure results in a null resultset being returned.
ClassMethod %CreateResultSet(pMDX = "", Output pStatus As %Status, ByRef pParmsObj = {{}}, ByRef pVars = "") As %DeepSee.ResultSet [ Internal ]
{
	// Method implemented by DP-402897
	Set pStatus = $$$OK
	Set tRS = ""
	
	Try {
		If (pMDX="") Quit
		// This is where the tParms would get constructed, to be used in the execution later.
		// Pivot tables do not use the execution parameters so it is set to null in this implementation.
		Set tParms = ""
		
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		
		Set tSC = tRS.%PrepareMDX(pMDX,.pVars)
		If $$$ISERR(tSC) Quit
		
		// Set the listing if defined prior to execution
		// Always set the MaxListingRows to 0 to remove row limit on the export
		If (pParmsObj.listing'="") {
			Set tSC = tRS.%SetListing(pParmsObj.listing)
			If $$$ISERR(tSC) Quit
		}
		Set tRS.%Query.%MaxListingRows = 0
		
		Set tSC = tRS.%ExecuteAsynch(pMDX,.tParms,1)
		If $$$ISERR(tSC) Quit
	}
	Catch ex {
		Set pStatus = ex.AsStatus()
		Set tRS=""
	}
	
	Quit tRS
}

/// Write a set of name-value pairs as stored in two arrays to a <var>pFileStream</var> in CSV format.
ClassMethod %EmitNameValueTable(pFileStream, pNames As %DynamicArray = {[]}, pValues As %DynamicArray = {[]}, pTableTitle = "", pParamsObj = {{}}) As %Status
{
	// Method implemented by DP-402897
	Set tSC = $$$OK
	
	Try {
		// Check to make sure actual data has been supplied to print in the first place! 
		Set tCount = pNames.%Size()
		Set tCubeKey = pParamsObj.cubeKey
		
		If tCount {
			// If a table title has been supplied, write it first
			Do:(pTableTitle'="") pFileStream.WriteLine($$$iscEscapeCSV(pTableTitle))
			For n=0:1:(tCount-1) {
				Set tName = pNames.%Get(n)
				Set tValue = pValues.%Get(n)
				
				If ($E($$$UPPER(tName),1,12)="CELL CONTEXT")&&(tCubeKey'="") {		
					// "Cell Context" indicates that this is a filter imposed by the cell selection while in listing mode
					// This MDX filter needs to be transformed before it can be displayed.
					Do ##class(%DeepSee.UserPortal.Utils).%ParseCellSelectionContext(tValue,tCubeKey,.tContextFilters)
					Set tName="" 
					Set tValue=""
					For f=1:1:tContextFilters {
						// PFS038 - Populate tSelectionFilters with values and display after full context is evaluated
						Set tName = tName _ $S($L(tName):" / ",1:"") _ $LG(tContextFilters(f),1)
						Set tValue = tValue _ $S($L(tValue):" / ",1:"") _ $LG(tContextFilters(f),2)
						If '$D(tContextFilters(f,"ch")) {
							// This node contains the end of a chain, add it to the output
							Set tCurrentVal = $G(tSelectionFilters(tName))
							Set tSelectionFilters(tName) = tCurrentVal _ $Select(tCurrentVal'="":"+ ",1:"") _ tValue
							Set tName = ""
							Set tValue = ""
						}
					}
				}
				Else {
					Do:($$$UPPER(tName)'[$$$UPPER($$$Text("Selected Cell Context"))) pFileStream.WriteLine($$$iscEscapeCSV(tName) _ "," _ $$$iscEscapeCSV(tValue))
				}
			}
			
			// Once the loop over the incoming filter table is complete, write out any parsed 
			// Cell Context filters in their own rows.
			If (pParamsObj.showListingFilters="on")&&$D(tSelectionFilters) {
				Do pFileStream.WriteLine("- " _ $$$Text("Selected Cell Context") _ " -")
				
				Set tName = $O(tSelectionFilters(""),1,tValue)
				While (tName'="") {
					Do pFileStream.WriteLine($$$iscEscapeCSV(tName) _ "," _ $$$iscEscapeCSV(tValue))
					Set tName = $O(tSelectionFilters(tName),1,tValue)
				}
			}
			
			// Include a spacer line following this  table entry
			Do pFileStream.WriteLine("")
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Write the contents of the active resultset into the open file stream.
ClassMethod %EmitResultSet(pRS As %DeepSee.ResultSet = {$$$NULLOREF}, pFileStream) As %Status [ Internal ]
{
	// Method implemented by DP-402897
	Set tSC = $$$OK
	
	Try {
		// Emit the actual contents of the ResultSet into the file in CSV format. 
		Set tRowOutArray = []
		Set tColCount = pRS.%GetColumnCount()
		Set tRowCount = pRS.%GetRowCount()
		Set (tMaxColHdrCount,tMaxRowHdrCount) = 1
		
		
		// Build the row headers and the data table first, keep track of the max depth encountered
		For r=1:1:tRowCount {
			Set tDataRowCSV = ""		// Reset the current line at the beginning of each row
			
			// Record the largest depth of nested row headers. This will be used to align the 
			// data table within the CSV.  
			Set tRowHdrCount = pRS.%GetOrdinalLabel(.tRowLabels,2,r)
			Set:(tRowHdrCount>tMaxRowHdrCount) tMaxRowHdrCount = tRowHdrCount
			
			For c=1:1:tColCount {
				// Store information about the column headers
				Set tColHdrCount = pRS.%GetOrdinalLabel(.tColLabels,1,c)
				Set:(tColHdrCount>tMaxColHdrCount) tMaxColHdrCount = tColHdrCount
				Set tColHeaders(c) = tColHdrCount
				Merge tColHeaders(c) = tColLabels
				
				
				Set tDataRowCSV = tDataRowCSV _ $S($G(tDataRowCSV)'="":",",1:"") _ $$$iscEscapeCSV(pRS.%GetOrdinalValue(c,r))
			}
			
			Do tRowOutArray.%Push(tDataRowCSV)
		}
		
		
		// Create rows to draw the column headers now that the rows have been processed. 
		// Each column header row in the CSV includes the "nub" columns equal to max
		// depth of the nested row headers to keep column headers aligned with their columns.
		Set tNubSpacer = ""
		For s=(tMaxRowHdrCount-1):-1:1 {Set tNubSpacer = tNubSpacer_","}
		
		For ch=tMaxColHdrCount:-1:1 {
			Set tHeaderRowStr = tNubSpacer	
			
			For c=1:1:tColCount {
				// Insert a null if this column doesn't have headers that extend the entire depth
				Set tHeaderRowStr = tHeaderRowStr _ "," _ $$$iscEscapeCSV($G(tColHeaders(c,ch)))
			}
			
			Do pFileStream.WriteLine(tHeaderRowStr)
		}
		
		
		// Create the rows once the column headers have been established 
		For r=1:1:(tRowOutArray.%Size()) {
			Set tRowHdrCount = pRS.%GetOrdinalLabel(.tRowLabels,2,r)
	
			// Build the next row using the data row built previously and prepend the headers
			Set tSpacer = ""
			For s=(tMaxRowHdrCount-1):-1:tRowHdrCount {Set tSpacer = tSpacer_","}
			
			Set tHeaders = tSpacer
			Set h = $O(tRowLabels(""),-1,tHeader)
			While (h'="") {
				Set tHeaders = tHeaders _ $$$iscEscapeCSV(tHeader) _ ","
				
				Set h = $O(tRowLabels(h),-1,tHeader)
			}
			
			// Write the row to the open CSV file 
			Do pFileStream.WriteLine(tHeaders _ tRowOutArray.%Get(r-1))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Emit the CSV for the content of a DRILLTROUGH query
ClassMethod %EmitListingResultSet(pRS = {$$$NULLOREF}, pFileStream) As %Status [ Internal ]
{
	// Method implemented by DP-402897
	Set tSC = $$$OK
	
	Try {
		// Determine which type of supported resultset this is and set 
		// the SQL resultset tRS
		If pRS.%IsA("%DeepSee.ResultSet") {
			Set tSC = pRS.%GetListingResultSet(.tRS,.tListingFields)
			If $$$ISERR(tSC) Quit
		}
		ElseIf pRS.%IsA("%SQL.StatementResult") {
			Set tListingFields = ""
			Set tRS = pRS
		}
		
		// Determine the number of actual columns that should be exported from this SQL resultset
		Set tColumnMeta = tRS.%GetMetaData().columns
		If (tListingFields="") {		
			Set tColCount = tColumnMeta.Count()
		}
		Else {
			Set tColCount = $LL(tListingFields)
		}
		Set tLine = ""
		
		// Create the list of column headers in CSV format. Write the header row to the
		// file stream.
		If (tListingFields="") {		
			For c = 1:1:tColCount {
				Set tColInfo = tColumnMeta.GetAt(c)
				Set tLine = tLine _ $S(c=1:"",1:",") _ $$$iscEscapeCSV(tColInfo.colName)		// DP-413146
			}
		}
		Else {
			For c = 1:1:tColCount {
				Set tLine = tLine _ $S(c=1:"",1:",") _ $$$iscEscapeCSV($LG(tListingFields,c))		// DP-413146
			}
		}
		Do pFileStream.WriteLine(tLine)

		// Work through the SQL resultset to produce the rows of data in CSV format. Write each
		// line to the file stream.
		Set n = 0
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			
			Set tLine = ""
			For c=1:1:tColCount {
				If (tListingFields="") {
					Set tValue = tRS.%GetData(c)
				}
				Else {
					Set tValue = tRS.%Get($LG(tListingFields,c))
				}
				Set tLine = tLine _ $S(c=1:"",1:",") _ $$$iscEscapeCSV(tValue)		// DP-413146
			}
			Do pFileStream.WriteLine(tLine)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Emit the CSV for the content of a KPI
ClassMethod %EmitKpiResult(pParamsObj = {{}}, pFileStream) As %Status
{
	// Method implemented by DP-402897
	Set tSC = $$$OK
	
	Try { 
		Set tFilterKeys = pParamsObj.filterKeys
		Set tFilterValues = pParamsObj.filterValues
		
		Set tKPIClass = pParamsObj.kpi
		
		Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
		Set tController.modelClass = tKPIClass
		Set tController.modelId = ""
		
		// The criteria array in this case contains the filters that need to be considered during execution
		Set tController.criteria = ##class(%ZEN.proxyObject).%New()
		Set tCriteria = tController.criteria
		If (tFilterKeys'="") {
			Set tFilterCount = tFilterKeys.%Size()
			For n=0:1:tFilterCount-1 {
				Set tFilter = tFilterKeys.%Get(n).spec
				Set tFilterKey = tFilterKeys.%Get(n).key
				Set $Property(tCriteria,tFilter) = tFilterKey
				Set tFilters(tFilter) = tFilterKey
			}
		}
		
		If (pParamsObj.isDrillThrough) {
			// KPI-based listing
			Set tListingName = pParamsObj.listing

			Set tSelection("selectedRange") = pParamsObj.selectedRange
			Set tSelection("rowValues") = pParamsObj.selectedItems
			Set tSelection("sortColumn") = pParamsObj.listingSortColumn
			Set tSelection("sortDir") = pParamsObj.listingSortDir 
			
			Set tSC = $classmethod(tKPIClass,"%GetListingResultSet",.tFilters,.tSelection,tListingName,.tListingRS)
			If $$$ISERR(tSC) Quit

			Set tSC = ..%EmitListingResultSet(tListingRS,pFileStream)
			If $$$ISERR(tSC) Quit
			Quit
		}

		// aquire data from KPI
		Set tSC = tController.%AcquireData()
		If $$$ISERR(tSC) Quit
		
		Set tModel = tController.%model
		
		If (tModel.%IsAsync()) {
			// Watch the cache to know when results are complete. Default is 5 seconds less than the gateway timeout.
			Set tClassU = $$$UPPER(tModel.%ClassName(1))
			Set tCacheKey = tModel.%cacheKey
			If ((tClassU'="")&&(tCacheKey'="")) {
				Set tSC = $G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"error"),$$$OK)
				If $$$ISERR(tSC) Quit
				
				Set tWaitTimeout = $S(((%request.GatewayTimeout-5)>5):(%request.GatewayTimeout-5),1:5)
				Set tPctComplete = +$G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"pctComplete"))
				While (tPctComplete<100)&&($G(tWait)<tWaitTimeout) {
					h 1
					Set x = $I(tWait)
					Set tPctComplete = +$G($$$DeepSeeKPIGLVN(tClassU,tCacheKey,"pctComplete"))
				}
				
				Set tSC = tController.%model.%LoadKPIFromCache()
				If $$$ISERR(tSC) Quit
				
				Set tSC = tController.%AcquireData()
				If $$$ISERR(tSC) Quit
			}
		}
		
		
		If (tController.modelError'="") {
			Set tSC = tController.modelError
			Quit
		}
		
		// compute size/shape of columns & rows
		Set tRowCount = tController.dataBag.seriesCount
		Set tColCount = 0
		
		
		Set tColumnList = pParamsObj.columnList
		Set tSC = ##class(%DeepSee.Component.pivotTable).%GetKPIColumns(tController,.tColCount,.tColProps,tColumnList)
		If $$$ISERR(tSC) Quit

		Set tRowCount = $S(tRowCount>=0:tRowCount,1:1)
		Set tColCount = $S(tColCount>0:tColCount,1:1)

		Set tRowLabelCount = 1
		Set tColLabelCount = 1

		Set tRowOffset = tColLabelCount + 2
		Set tColOffset = tRowLabelCount

		// Begin writing content to the file
		
		// column headers
		If (tColCount > 0) {
			Set tLine = ""
			For n=1:1:tRowLabelCount {
				Set tLine = tLine _ ","
			}
			For c = 1:1:tColCount {
				Set tName = $S($D(tColProps(c,"caption")):tColProps(c,"caption"),1:tColProps(c))
				Set tLine = tLine _ $$$iscEscapeCSV(tName) _ $S((c<tColCount):",",1:"")
			}
			
			Do pFileStream.WriteLine(tLine)
		}

		For r = 1:1:tRowCount {
			Set tName = $G(tModel.%seriesNames(r))
			Set tLine = $$$iscEscapeCSV(tName)

			For c = 1:1:tColCount {
				Set tValue = ""
				Set tProp = $G(tColProps(c))
				If (tProp'="") {
					Set tValue = tController.dataBag.%GetValue(tProp,r)
					Set:tValue=$$$ZENMISSING tValue = ""
				}

				Set tLine = tLine _ "," _ $$$iscEscapeCSV(tValue)
			}
			
			Do pFileStream.WriteLine(tLine)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Lookup a filter caption for a KPI
ClassMethod GetKpiFilterCaption(pKPIName, pSpec) As %String [ ZenMethod ]
{
	// Method implemented by DP-402897
	Quit ##class(%DeepSee.Dashboard.Utils).%GetKpiFilterCaption(pKPIName,pSpec)
}

/// Client-facing utility method to send an MDX query to the server to be exported as a CSV.
ClientMethod exportMDXToCSV(mdx, params, fileName) [ Language = javascript ]
{
	// Method implemented by DP-402897
	if (!fileName) {
		// If the fileName is not supplied, generate a random string of characters
		fileName = Math.random().toString(36).substring(2) + '.csv';
	}

	return this.ExportCSV(mdx,fileName,JSON.stringify(params));
}

/// Receive a pivotTable component and use its settings to produce a set of expected export
/// parameters consistent with usage in this provider.
ClientMethod prepareTableParms(table) [ Language = javascript ]
{
	// Method implemented by DP-402897
	var exportParams = {};
	if (!table) {
		return exportParams;
	}
	
	if (''!=table.kpi) {
		// If the table is using a KPI datasource then the current filters need to be manually set
		// into the export parameters
		var filterNames = [];
		var filterValues = [];
		var filterKeys = [];
		for (var n = 0; n < table.filters.length; n++) {
			var filter = table.filters[n];
			
			if (filter.text!='') {
				filterNames[filterNames.length] = this.GetKpiFilterCaption(table.dataSourceName,filter.spec);
				var val = filter.text.toString();
				// unquote
				if ('&'==val.charAt(0)) {
					val = val.substring(2,val.length-1);
				}
				filterValues[filterValues.length] = val;
				
				// For KPIs we need to send both the actual value for applying to the copy of the
				// data controller in the background
				filterKeys[filterKeys.length] = {spec:filter.spec,key:filter.key};
			}
		}
		
		exportParams.filterNames = filterNames;
		exportParams.filterValues = filterValues;
		exportParams.filterKeys = filterKeys;
		
		exportParams.kpi = table.kpi;
		exportParams.columnList = table.columnList;
		
		exportParams.isDrillThrough = table.isDrillThrough;
		exportParams.listing = table.listing;
		exportParams.selectedRange = table.selectedRange;
		exportParams.selectedItems = table.selectedRowValues;
		exportParams.listingSortColumn = table.sortColumn;
		exportParams.listingSortDir = table.sortDir;
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		var filterNames = [];
		var filterValues = [];
		table.getFilterInfo(filterNames, filterValues);

		if (table.cubeKey) {
			exportParams.cubeKey = table.cubeKey;	
		}
		if (table.rowTotals) {
			exportParams.rowTotals = 1;
		}
		if (table.columnTotals) {
			exportParams.columnTotals = 1;
		}
		if (''!=table.rowTotalAgg) {
			exportParams.rowTotalAgg = table.rowTotalAgg;
		}
		if (''!=table.columnTotalAgg) {
			exportParams.columnTotalAgg = table.columnTotalAgg;
		}
		if (''!=table.listing) {
			exportParams.listing = table.listing;
		}
		if (filterNames.length > 0) {
			exportParams.filterNames = filterNames;
			exportParams.filterValues = filterValues;
		}
		if (''!=table.cubeName) {
			exportParams.cubeName = table.cubeName;
		}	
		
		// Look to the printTitle first, then use the pivot name if that is absent. Ultimately 
		// the cube name is used if none of the more specific values are defined.
		var title = table.printTitle;
		if (title=='') {
			title = table.name;
			// remove extension
			if (title!='') {
				var s = title.toString().split('.');
				s.length = s.length-1;
				title = s.join('.');
			}
			else {
				// Default to the cube name if there is no other caption
				title = table.cubeName;
			}
		}
		exportParams.title = title;
		exportParams.subtitle = table.printSubtitle;
		exportParams.subtitleOn = table.printSubtitleOn;
		
		exportParams.showDate = table.showDate;
		exportParams.showUser = table.showUser;
		exportParams.showFilters = table.showFilters;
		exportParams.showListingFilters = table.showListingFilters;


		var pivotVarNames=[];
		var pivotVarValues=[];
		table.getPivotVariablesValues(pivotVarNames, pivotVarValues);
		if (pivotVarNames.length) {
			exportParams.pivotVarNames = pivotVarNames;
			exportParams.pivotVarValues = pivotVarValues;
		}
	}
	
	return exportParams;
}

/// Package the entire generation of the download stream into a single convenient call 
/// for client consumption.
ClientMethod downloadCSV(mdx, exportParams) [ Language = javascript ]
{
	// Method implemented by DP-402897
	window.open(zenLink('_DeepSee.UI.MDXCSV.zen?FILEROOT=' + 
				this.exportMDXToCSV(mdx,exportParams)),'csv','');
}

}
