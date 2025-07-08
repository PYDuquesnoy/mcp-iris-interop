/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Utility methods for DeepSee Dashboards.
Class %DeepSee.Dashboard.Utils Extends %RegisteredObject [ System = 4 ]
{

/// Open the dashboard definition with the given full name.
ClassMethod %OpenDashboard(pFullName As %String, Output pStatus As %Status) As Definition
{
	Set pStatus = $$$OK
	Set tDB = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pFullName,.pStatus)
	If ($IsObject(tDB) && 'tDB.%IsA("%DeepSee.Dashboard.Definition")) {
		Quit ""
	}
	Quit tDB
}

/// Check if a there is a dashboard definition with the given name.
/// Returns 0 if the item does not exist; returns 1 if it exists and is visible to the
/// current user; returns 2 if it exists but is not visible to the current user.<br/>
ClassMethod %DashboardExists(pFullName As %String, Output pID As %String) As %Integer
{
	Set pID = ""
	Set tExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pFullName,.pID)
	If (tExists && '##class(Definition).%ExistsId(pID)) {
		Set tExists = 0
		Set pID = ""
	}
	Quit tExists
}

/// Delete the dashboard definition with the given full name.
ClassMethod %DeleteDashboard(pFullName As %String) As %Boolean
{
	Set tSC = $$$OK
	If ((pFullName'="")&&(..%DashboardExists(pFullName,.tID))) {
		Set tSC = ##class(Definition).%DeleteId(tID)
	}
	Quit tSC
}

/// Return list of possible dashboard actions.
/// This takes the form:<br/>
/// pAction(n)=$LB(name,caption,tooltip,type)<br/>
/// <var>type</var> specifies the data associated with the action (if any).
/// This value is passed along as the <var>targetProperty</var> of the action.<br/>
/// "filter", the action controls the given filter.<br/>
/// "url", the action requires a url.<br/>
/// "dashboard", the action requires a dashboard.<br/>
/// <br/>
/// The control for each action is determined by the %CreateControls method in the DashboardViewer class.<br/>
/// The actions are dispatched to widget by the dashboardEventHandler method in the DashboardViewer class.<br/>
/// 
ClassMethod %GetDashboardActionList(Output pAction As %String, pDataSource As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pAction
		Set pAction($I(pAction)) = $LB("applyFilter",$$$Text("Apply Filter","%DeepSee"),$$$Text("Set the value of a filter and update the widget","%DeepSee"),"filter")
		Set pAction($I(pAction)) = $LB("setFilter",$$$Text("Set Filter","%DeepSee"),$$$Text("Set the value of a filter but do not update the widget","%DeepSee"),"filter")
		Set pAction($I(pAction)) = $LB("refresh",$$$Text("Refresh","%DeepSee"),$$$Text("Update the widget","%DeepSee"))
		Set pAction($I(pAction)) = $LB("reloadDashboard",$$$Text("Reload Dashboard","%DeepSee"),$$$Text("Reload the current saved version of the dashboard","%DeepSee"))
		Set pAction($I(pAction)) = $LB("showListing",$$$Text("Show Listing","%DeepSee"),$$$Text("Show a detail listing for the selected data","%DeepSee"))
		Set pAction($I(pAction)) = $LB("showGeoListing",$$$Text("Show Geo Listing","%DeepSee"),$$$Text("Show a detail listing by geographic location within a map","%DeepSee"))
		Set pAction($I(pAction)) = $LB("showBreakdown",$$$Text("Pivot analysis","%DeepSee"),$$$Text("Open the ad-hoc Analysis window for the selected facts","%DeepSee"))

		// JMD1139
		Set pAction($I(pAction)) = $LB("setDataSource",$$$Text("Set DataSource","%DeepSee"),$$$Text("Set a different data source for this widget","%DeepSee"))
		Set pAction($I(pAction)) = $LB("chooseDataSource",$$$Text("Choose DataSource","%DeepSee"),$$$Text("Select a different data source for this widget from a list","%DeepSee"))

		// JMD1276
		Set pAction($I(pAction)) = $LB("applyVariable",$$$Text("Apply Pivot Variable","%DeepSee"),$$$Text("Set the value for a pivot variable for this widget","%DeepSee"))

		// JMD
		Set pAction($I(pAction)) = $LB("setRowSpec",$$$Text("Set Row Spec","%DeepSee"),$$$Text("Display a different set of rows","%DeepSee"))
		Set pAction($I(pAction)) = $LB("chooseRowSpec",$$$Text("Choose Row Spec","%DeepSee"),$$$Text("Select a set of rows to display","%DeepSee"))
		Set pAction($I(pAction)) = $LB("setColumnSpec",$$$Text("Set Column Spec","%DeepSee"),$$$Text("Display a different set of columns","%DeepSee"))
		Set pAction($I(pAction)) = $LB("chooseColumnSpec",$$$Text("Choose Column Spec","%DeepSee"),$$$Text("Select a set of columns to display","%DeepSee"))

		Set pAction($I(pAction)) = $LB("viewDashboard",$$$Text("View Dashboard","%DeepSee"),$$$Text("Display a different dashboard","%DeepSee"),"dashboard")
		Set pAction($I(pAction)) = $LB("navigate",$$$Text("Navigate","%DeepSee"),$$$Text("Go to an arbitrary web page","%DeepSee"),"url")
		Set pAction($I(pAction)) = $LB("newWindow",$$$Text("New Window","%DeepSee"),$$$Text("Open a new browser window and display a web page","%DeepSee"),"url")

		#; pivot settings
		Set pAction($I(pAction)) = $LB("setRowCount",$$$Text("Row Count","%DeepSee"),$$$Text("Set the number of rows that are displayed","%DeepSee"))
		Set pAction($I(pAction)) = $LB("setRowSort",$$$Text("Row Sort","%DeepSee"),$$$Text("Specify how rows are sorted","%DeepSee"))

		Set pAction($I(pAction)) = $LB("setColumnCount",$$$Text("Column Count","%DeepSee"),$$$Text("Set the number of columns that are displayed","%DeepSee"))
		Set pAction($I(pAction)) = $LB("setColumnSort",$$$Text("Column Sort","%DeepSee"),$$$Text("Specify how columns are sorted","%DeepSee"))
		
		// + WAL083 -- Add setChartType and chooseChartType actions
		//             The "chartType" element in the $LB tells the control wizard to provide a way for the user to select a chart type or list of chart types
		Set pAction($I(pAction)) = $LB("setChartType",$$$Text("Set Chart Type","%DeepSee"),$$$Text("Set the Chart Type to be Displayed","%DeepSee"),"chartType")
		Set pAction($I(pAction)) = $LB("chooseChartType",$$$Text("Choose Chart Type","%DeepSee"),$$$Text("Choose the chart type to be Displayed","%DeepSee"),"chartType")
		// - WAL083
		
		// DTB251 - Add print widget control
		Set pAction($I(pAction)) = $LB("printWidget",$$$Text("Print Widget","%DeepSee"),$$$Text("Print the widget to PDF","%DeepSee"),"printWidget")

		#; see if datasource has additional actions
		If (pDataSource'="") {
			Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
			If (tExt = "kpi") {
				Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				If (tKPIClass'="") {
					Set tSC = $zobjclassmethod(tKPIClass,"%GetActionList",.pAction,pDataSource)
					If $$$ISERR(tSC) Quit
				}
			}
			ElseIf (tExt = "worksheet") {
				Set tKPIClass = "%DeepSee.KPIWorksheet"
				Set tSC = $zobjclassmethod(tKPIClass,"%GetActionList",.pAction,pDataSource)
				If $$$ISERR(tSC) Quit
			}
			ElseIf (tExt = "metric") {
				Set tKPIClass = "Ens.BusinessMetricKPI"
				Set tSC = $zobjclassmethod(tKPIClass,"%GetActionList",.pAction,pDataSource)
				If $$$ISERR(tSC) Quit
			}
			ElseIf (tExt = "pivot") {
				// see if cube has any actions
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit

				Set tCube = tPivot.%GetCubeName()
				Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(tCube)
				If (tCubeClass'="") {
					Set tSC = $zobjclassmethod(tCubeClass,"%GetActionList",.pAction)
					If $$$ISERR(tSC) Quit
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Lookup a filter caption for a KPI
ClassMethod %GetKpiFilterCaption(pKPIName, pSpec) As %String [ ZenMethod ]
{
	// Method added by DP-402897
	Set tCaption = pSpec
	Set tSpec = $$$UPPER(pSpec)
	Try {
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(pKPIName,.tFilters)
		If $$$ISERR(tSC) Quit
		
		Set tPosition = $O(tFilters(""),1,tFilterData)
		While tPosition'="" {
			If ($$$UPPER($LG(tFilterData,2))=tSpec) {
				Set tCaption = $LG(tFilterData,1)
				Quit
			}
			Set tPosition = $O(tFilters(tPosition),1,tFilterData)
		}
	}
	Catch ex {
		// Swallow any error, already returning default caption
	}
	Quit tCaption
}

/// Return list of possible filters for a given dashboard data source.
/// This takes the form:<br/>
/// pFilters(n)=$LB(caption,value,type)<br/>
/// type is the dimension type: "" (data),"year","month","day", etc.<br/>
/// <var>pVisited</var> is used to prevent cycles when visiting related cubes.<br/>
/// <var>pMaxDepth</var> is maximum depth of relations to follow. A value of 0 means there is no limit to the depth of relationships.
ClassMethod %GetFiltersForDataSource(pDataSource As %String, Output pFilters As %List, ByRef pVisited, pParent As %String = "", pSearchKey As %String = "", pMaxDepth As %Integer = 3, pLevel As %Integer = 1) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pFilters
		Set pSearchKey = $$$UPPER(pSearchKey)		// DTB419 - Always use upper-case comparisons to remove case sensitivity

		// what kind of data source is in play?
		If (pDataSource="") Quit
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(pDataSource,".",1,$L(pDataSource,".")-1))
			}
			If (tCubeName = "") Quit

			Set:pParent="" pVisited($$$UPPER(tCubeName)) = ""

			/// tInfo(DimNo,HierNo,LevelNo) = $LB(type,DimName,HierName,LevelName)
			/// JMD1278 respect useInFilters flag
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionList(tCubeName,.tInfo,1,1)
			If $$$ISERR(tSC) Quit

			// JMD1253 add named filter to list, if present
			If $D(^DeepSee.Filters($$$UPPER(tCubeName))) {
				Set pFilters($I(n)) = $LB($$$Text("Named Filters","%DeepSee"),"$NAMEDFILTER","$NAMEDFILTER")
			}

			Set tDim = $O(tInfo(""))
			While (tDim'="") {
				If $$$ISERR(tSC) Quit
				Set tRInfo = $G(tInfo(tDim,0,0))
				
				If ($LG(tRInfo,1)="r") {
					// relationship
					Set tRelName = $LG(tRInfo,2)
					
					// DTB289 - If the relationship name satisfies the searchKey, keep everything below it
					Set tSearchKey = $S($$$UPPER(tRelName)[$$$UPPER(pSearchKey):"",1:pSearchKey)
					
					Set tRCube = ##class(%DeepSee.Utils).%GetRelatedCube(tCubeName,tRelName)

					// get filters for related cube
					If (tRCube'="")&&(##class(%DeepSee.Utils).%CheckPrivilege(tRCube)) {		// DTB288 - Add check for privileges on the related cube
						Set tRCubeFull = tRCube _ ".cube"
						If ('pMaxDepth)||(pLevel < pMaxDepth) {							// DTB288 - Allow return of all filters using pMaxDepth=0
							If ('$D(pVisited($$$UPPER(pParent_":"_tRCube))) &&
								($$$UPPER(pParent)'=$$$UPPER(tRCube))&&					// DTB289 - Do not turn around and revisit the parent through a two-way relationship
								'$D(pVisited($$$UPPER(tRCube))) ) {
									
								Set pVisited($$$UPPER(pParent_":"_tRCube)) = ""
								Kill tRFilters
								Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(tRCubeFull,.tRFilters,.pVisited,tCubeName,tSearchKey,pMaxDepth,pLevel+1)
								If $$$ISERR(tSC) Quit
								Set fk = $O(tRFilters(""))
								While (fk'="") {
									// + WAL048 -- add related cube type info (year, month, etc.)
									Set pFilters($I(n)) = $LB(tRelName_"."_$LG(tRFilters(fk),1),"["_tRelName_"]."_$LG(tRFilters(fk),2),$LG(tRFilters(fk),3))
									// - WAL048
									Set fk = $O(tRFilters(fk))
								}
							}
						}
					}
				}
				Else {
					Set tHier = $O(tInfo(tDim,""))
					While (tHier'="") {
						If (tDim<0) {
							// calculated members
							Set tDimInfo = $G(tInfo(tDim,tHier,0))
							Set tDimName = $LG(tDimInfo,2)

							/// pFilters(n)=$LB(name,caption,value)<br/>
							Set tSpec = "["_tDimName_"]"
							If ((pSearchKey="")||($$$UPPER(tDimName)[pSearchKey)) {
								// JMD901: indicate calc members
								Set pFilters($I(n)) = $LB(tDimName,tSpec,"calc")
							}
						}
						Else {
							Set tLevel = $O(tInfo(tDim,tHier,""))
							While (tLevel'="") {
								Set tDimInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDim,tHier,tLevel))
								If ($LG(tDimInfo,1)="l") {
									Set tDimName = $LG(tDimInfo,2)
									Set tHierName = $LG(tDimInfo,3)
									Set tLevelName = $LG(tDimInfo,4)
									Set tClass = $LG(tDimInfo,6)
									
									// + WAL133
									Set tType = ##class(%DeepSee.Utils).%GetTimeLevelType(tClass)		// DTB188 - Use API
									// - WAL133

									/// pFilters(n)=$LB(caption,value,type)<br/>
									Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tCubeName,tDimName,tHierName,tLevelName,.tLevelCaption)
									If $$$ISERR(tSC) Quit
									
									Set tSpec = "["_tDimName_"].["_tHierName_"].["_tLevelName_"]"
									If ((pSearchKey="")||($$$UPPER(tSpec)[pSearchKey)) {
										Set pFilters($I(n)) = $LB(tLevelCaption,tSpec,tType)
									}
								}
								Set tLevel = $O(tInfo(tDim,tHier,tLevel))
							}
						}
						Set tHier = $O(tInfo(tDim,tHier))
					}
				}
				Set tDim = $O(tInfo(tDim))
			}
		}
		ElseIf (tExt = "kpi") {
			Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			If (tKPIClass'="") {
				Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterList",.tFilters,pDataSource)
				If $$$ISERR(tSC) Quit
				// display and value are reversed!
				Set k = $O(tFilters(""))
				While (k'="") {
					Set tType = $S($LG(tFilters(k),6)="day":"day",1:"")
					Set pFilters(k) = $LB($LG(tFilters(k),2),$LG(tFilters(k),1),tType)
					Set k = $O(tFilters(k))
				}
			}
		}
		ElseIf (tExt = "metric") {
			Set tKPIClass = "Ens.BusinessMetricKPI"
			Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterList",.tFilters,pDataSource)
			If $$$ISERR(tSC) Quit
				// display and value are reversed!
				Set k = $O(tFilters(""))
				While (k'="") {
					Set tType = $S($LG(tFilters(k),6)="day":"day",1:"")
					Set pFilters(k) = $LB($LG(tFilters(k),2),$LG(tFilters(k),1),tType)
					Set k = $O(tFilters(k))
				}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible pivot variables for a given dashboard data source.
/// This takes the form:<br/>
/// pVariables(n) = $LB(name,caption,defValue,context)<br/>
ClassMethod %GetPivotVariablesForDataSource(pDataSource As %String, Output pVariables As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pVariables

		// what kind of data source is in play?
		If (pDataSource="") Quit
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(pDataSource,".",1,$L(pDataSource,".")-1))
			}
			If (tCubeName = "") Quit

			Set tSC = ##class(%DeepSee.Utils).%GetPivotVariables(tCubeName,.pVariables)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tExt = "kpi") {
			Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			If (tKPIClass'="") {
				// not supported at this time
			}
		}
		ElseIf (tExt = "metric") {
			Set tKPIClass = "Ens.BusinessMetricKPI"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible data properties for a given dashboard data source.
/// This takes the form:<br/>
/// pProperties(n)=name<br/>
ClassMethod %GetPropertiesForDataSource(pDataSource As %String, Output pProperties As %List) As %Status
{
	Set tSC = $$$OK
	Try {
		// what kind of data source is in play?
		If (pDataSource="") Quit
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If (tExt = "pivot") {
			Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
			If '$IsObject(tPivot) Quit
			Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			If (tCubeName = "") Quit

			// create a tempory pivot table in order to reconstruct the MDX statement
			Set tPivotTable = ##class(%DeepSee.Component.pivotTable).%New()

			// copy information from the saved item to the graphical pivot
			Set tSC = tPivot.%CopyToComponent(tPivotTable)
			If $$$ISERR(tSC) Quit

			// DTB573 - Digest the filter information and prepare for %CreateResultSet
			Set tSC = tPivotTable.%GetFilterInfo(.tFilterInfo,.tAdvancedFilters)
			If $$$ISERR(tSC) Quit

			// Create a result set
			Set tRS = tPivotTable.%CreateResultSet(.tSC,.tParms,.tFilterInfo,.tAdvancedFilters,.tQueryText)
			If $$$ISERR(tSC) Quit

			Set tRS.%Recompute = 0
			Set tSC = tRS.%Execute()
			If $$$ISERR(tSC) Quit

			// values are columns names within the query
			For c=1:1:tRS.%GetAxisSize(1) {
				Do tRS.%GetOrdinalLabel(.tLabel,1,c)
				// + WAL210
				Set tPropertyName = ""
				Set tIdx = $O(tLabel(""))
				While (tIdx'="") {
					Set tPropertyName = tLabel(tIdx) _ $S(tPropertyName="":"",1:"/"_tPropertyName)
					Set tIdx = $O(tLabel(tIdx))	
				}
				Set:(tPropertyName'="") pProperties($I(n)) = tPropertyName
				// - WAL210
			}
		}
		ElseIf ((tExt = "kpi")||(tExt = "metric")||(tExt = "worksheet")) {
			If (tExt = "metric") {
				Set tKPIClass = "Ens.BusinessMetricKPI"
			}
			ElseIf (tExt = "worksheet") {
				Set tKPIClass = "%DeepSee.KPIWorksheet"
			}
			Else {
				Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			}
			If (tKPIClass'="") {
				Set tSC = $zobjclassmethod(tKPIClass,"%GetPropertyInfo",.tInfo,0,pDataSource)
				If $$$ISERR(tSC) Quit

				Set n = 0
				Set p = $O(tInfo(""))
				While (p'="") {
					If (p'["%") {
						Set pProperties($I(n))=p
					}
					Set p = $O(tInfo(p))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible listings for a given dashboard data source.
/// This takes the form:<br/>
/// pListings(n)=$LB(caption,value,type)<br/>
ClassMethod %GetListingsForDataSource(pDataSource As %String, Output pListings As %List, pType As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		// what kind of data source is in play?
		If (pDataSource="") Quit
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(pDataSource,".",1,$L(pDataSource,".")-1))
			}
			If (tCubeName = "") Quit

			Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(tCubeName,.tInfo, pType)
			If $$$ISERR(tSC) Quit

			Set k = $O(tInfo(""))
			While (k'="") {
				// JMD1164: return logical name of listing
				Set pListings($I(n)) = $LB($LG(tInfo(k),1),k,$LG(tInfo(k),4))
				Set k = $O(tInfo(k))
			}
		}
		ElseIf (tExt = "kpi") {
			// force listing option for KPI!!!
			If (pType = "table") {
				Set pListings($I(n)) = $LB($$$Text("Listing","%DeepSee"),"Listing","table")
			}
		}
		ElseIf (tExt = "metric") {
		}
		ElseIf (tExt = "worksheet") {
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the caption for the given target property within the given data source.
/// This is used to translate the logical name for a filter to its display value.
ClassMethod %GetCaptionForTargetProperty(pDataSource As %String, pTarget As %String, Output pCaption As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// what kind of data source is in play?
		If (pDataSource="") Quit
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If (tExt = "pivot") {
			Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
			If '$IsObject(tPivot) Quit
			Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			If (tCubeName = "") Quit

			Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeName, pTarget, .tDimNo, .tHierNo, .tLevelNo,,,.tSpecInfo)
			If $$$ISERR(tSC) Quit
			
			If (tDimNo < 0) {
				// calculated member
				Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tCubeName, $$$UPPER($G(tSpecInfo(1))), $$$UPPER($G(tSpecInfo(2))),, .pCaption)
				If $$$ISERR(tSC) Quit
				Quit
			}

			Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(tCubeName, tDimNo, tHierNo, tLevelNo, .pCaption)
			If $$$ISERR(tSC) Quit
		}
		ElseIf (tExt = "kpi") {
			Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			If (tKPIClass'="") {
				Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterList",.pFilters)
				If $$$ISERR(tSC) Quit
			}
			
			Set pCaption = pTarget
			Set n = $O(pFilters(""))
			While (n'="") {
				If (pTarget = $LG(pFilters(n),1)) {
					Set pCaption = $LG(pFilters(n),2)
					Quit
				}
				Set n = $O(pFilters(n))
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of possible filter member values for a given dashboard data source and filter.
/// This takes the form:<br/>
/// pMembers(n)=$LB(text,value,[description])<br/>
/// If <var>pSearchKey</var> is provided, then only return members that match the search key.
/// If <var>pRelatedFilters</var> is provided, it is an array of other filter values to use to
/// restrict the set of members. It takes the form:<br/>
/// pRelatedFilters(spec) = key<br/>
/// If <var>pCalcOnly</var> is true, then only return calculated members.<br/>
/// If <var>pRangeMode</var> is true, then only return members that are valid for range selection (used by searchBox).<br/>
/// If <var>pPreSelected</var> is a list of selected values; always display these items.<br/>
ClassMethod %GetMembersForFilter(pDataSource As %String, pFilter As %String, Output pMembers As %List, Output pDefaultValue As %String, pSearchKey As %String = "", ByRef pRelatedFilters, pCalcOnly As %Boolean = 0, pRangeMode As %Boolean = 0, ByRef pPreSelected As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pMembers
		Set pDefaultValue = ""
		Set pSearchKey = $$$UPPER(pSearchKey)

		// what kind of data source is in play?
		If (pDataSource="") Quit
		If (pDataSource'[".") {
  			Set pDataSource=pDataSource_".cube"
  		}
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))

		If (pRangeMode&&(tExt '= "pivot")&&(tExt'="cube")) {
			// range only works for cubes
			Quit
		}
		
		// DP-421530 - Fetch the type of the dimension
		Set tSC = ..%GetMemberDimensionType(pDataSource,pFilter,.tDimType)
		If $$$ISERR(tSC) Quit

		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(pDataSource,".",1,$L(pDataSource,".")-1))
			}

			If (tCubeName = "") Quit

			If ($$$UPPER(pFilter)="MEASURES") {
				If ('pRangeMode) {
					/// Return the measures within the given cube as an array of form:<br/>
					/// pMeasures(n) = $LB(name,caption,type)
					Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(tCubeName,.tMeasures)
					If $$$ISERR(tSC) Quit

					Set n = $O(tMeasures(""),1,tInfo)
					While (n'="") {
						Set pMembers($I(n)) = $LB($LG(tInfo,2),"["_$LG(tInfo,1)_"]")
						Set n = $O(tMeasures(n),1,tInfo)
					}
				}
			}
			ElseIf (pFilter="$NAMEDFILTER") {
				// JMD1253
				Set tSC = ##class(%DeepSee.Utils).%GetNamedFilters(tCubeName,.tNamedFilters)
				If $$$ISERR(tSC) {
					Set tSC = $$$OK
					Set pMembers($I(n)) = $LB($$$Text("Invalid named filter","%DeepSee"),"")
					Quit
				}
				Set k = $O(tNamedFilters(""))
				While (k'="") {
					Set tText = $LG(tNamedFilters(k),1)
					Set tSpec = $LG(tNamedFilters(k),3)
					If ((pSearchKey="")||($$$UPPER(tText)[pSearchKey)) {
						Set pMembers($I(n)) = $LB(tText,tSpec)
					}
					Set k = $O(tNamedFilters(k))
				}
			}
			ElseIf ($$$LOWER($E(pFilter,1,10))="$variable.") {
				// JMD1276
				Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableValues(tCubeName,$P(pFilter,".",2),.tVariableValues)
				If $$$ISERR(tSC) {
					Set tSC = $$$OK
					Set pMembers($I(n)) = $LB($$$Text("Invalid pivot variable","%DeepSee"),"")
					Quit
				}
				Set k = $O(tVariableValues(""))
				While (k'="") {
					Set tText = $LG(tVariableValues(k),1)
					Set tSpec = $LG(tVariableValues(k),2)
					If ((pSearchKey="")||($$$UPPER(tText)[pSearchKey)) {
						Set pMembers($I(n)) = $LB(tText,tSpec)
					}
					Set k = $O(tVariableValues(k))
				}
			}
			Else {
				// DP-421530 - Reduce number of members fetch to 100
				Set tMaxMembers = 100
				Set tContext = "filter"		// DTB599
				Set tMemberClass = ""
				Set tCalcMode = $S(pRangeMode:-1,pCalcOnly:1,1:0)
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionMembers(tCubeName,pFilter,tContext,.tList,tMaxMembers,.tMemberClass,.pRelatedFilters,tCalcMode,pSearchKey)
				If $$$ISERR(tSC) {
					// DP-421530 - Log this as a application error and reset the status to allow the client to proceed
					D ##class(%DeepSee.Utils).%WriteToLog("Filter",$system.Status.GetOneErrorText(tSC))

					Set tSC = $$$OK
					Set pMembers($I(n)) = $LB($$$Text("Invalid filter","%DeepSee"),"")
					Quit
				}
				
				// PFS102 - Make a copy so we can delete nodes later to keep track of what has been included
				Merge tPreSelected = pPreSelected

				// special searching for computed dimensions
				If (('pRangeMode)&&('pCalcOnly)&&(tMemberClass'="")&&($zobjclassmethod(tMemberClass,"%IsA","%DeepSee.ComputedDimension.Base"))) {
					// Get info on the specified dimension
					Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeName,pFilter,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec)
					If $$$ISERR(tSC) Quit

					// dispatch to dimension class
					Set tDimObj = $zobjclassmethod(tMemberClass,"%Create",tCubeName,"",tDimNo,tHierNo,tLevelNo)
					If '$IsObject(tDimObj) {
						Set tSC = $$$ERROR($$$GeneralError,"Unable to create computed dimension object: " _ tMemberClass)
						Quit
					}
					Set tSC = tDimObj.%MemberSearch(pSearchKey,.pMembers)
					If $$$ISERR(tSC) Quit
					Quit
				}

				// split key into phrases!
				Set pSearchKey = $TR(pSearchKey,",-:","   ")
				For p = 1:1:$L(pSearchKey," ") {
					Set ph = $P(pSearchKey," ",p)
					Set:ph'="" tPhrase(ph) = ""
				}

				/// tList(n) = $LB(value,name,memberId,memberKey,[desc])<br/>
				Set k = $O(tList(""),1,tInfo)
				While (k'="") {
					Set tText = $LG(tInfo,2)
					Set tKey = $LG(tInfo,4)
					Set tDesc = $LG(tInfo,5)
					Set:tKey'="" tKey = "&["_$$$dsEscapeIdent(tKey)_"]"

					Set tSkip = 1
					If (pSearchKey="") {
						Set tSkip = 0
					}
					ElseIf ((tKey'="")&&$D(pPreSelected(tKey))) {
						// JMD1133: always list items in the pre-selected list
						Set tSkip = 0
					}
					Else {
						// if there is a search key, look for matching phrases in the text value
						Set tTest = $$$UPPER(tText)
						Set tTest = $TR(tTest,",-:()","     ")
						Set tTestD = $$$UPPER(tDesc)
						Set tTestD = $TR(tTestD,",-:()","     ")
						Set tSkip = 0
						Set ph = $O(tPhrase(""))
						While (ph'="") {
							Set match = 0
							For p = 1:1:$L(tTest," ") {
								Set t = $P(tTest," ",p)
								// JMD960: remove exact numeric match
								// If ($S($IsValidNum(ph):+t=+ph,1:(t[ph)) ) {
								If (t[ph) {
									Set match = 1
									Quit
								}
							}
							// also look in description
							If ('match && (tTestD'="")) {
								For p = 1:1:$L(tTestD," ") {
									Set t = $P(tTestD," ",p)
									If (t[ph) {
										Set match = 1
										Quit
									}
								}
								}
							If ('match) {
								Set tSkip = 1
								Quit
							}
							Set ph = $O(tPhrase(ph))
						}
					}

					If ('tSkip) {
						Set pMembers($I(n)) = $LB(tText,tKey,tDesc)
						Kill tPreSelected(tKey)
					}
					Set k = $O(tList(k),1,tInfo)
				}
				
				// PFS102 - If all seleted members have not been included already, add them
				If $D(tPreSelected) && (pSearchKey="") {
					Set k = $O(tPreSelected(""))
					While k'="" {
						Set tSearch = k
						If $E(tSearch,1,2)="&[" {
							Set tSearch = $E(tSearch,3,*-1)	
						}
						Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(pDataSource,pFilter,.tMembers,.pDefaultValue,tSearch,.pRelatedFilters,pCalcOnly,pRangeMode)
						
						Set tMbr = $O(tMembers(""))
						While tMbr'="" {
							If $LG(tMembers(tMbr),2) = k {
								Set pMembers($I(n)) = tMembers(tMbr)
							}
							Set tMbr = $O(tMembers(tMbr))
						}
						Set k = $O(tPreSelected(k))
					}
				}

				If ((tDimType'="day")&&($G(n)>=tMaxMembers)) {
					// DP-421530 - Add a final item that is a message encouraging use of the search option
					Set pMembers($I(n)) = $LB($$$Text("More options exist","%DeepSee"),"$msg",$$$Text("Use Search to narrow results","%DeepSee"))
				}
			}
		}
		ElseIf (tExt = "kpi") {
			If ('pCalcOnly) {
				Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				If (tKPIClass'="") {
					// JMD900 pass along related filters
					Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterMembers",pFilter,.pMembers,.pDefaultValue,pSearchKey,pDataSource,.pRelatedFilters)
					If $$$ISERR(tSC) Quit
				}
			}
		}
		ElseIf (tExt = "worksheet") {
			If ('pCalcOnly) {
				Set tKPIClass = "%DeepSee.KPIWorksheet"
				Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterMembers",pFilter,.pMembers,.pDefaultValue,pSearchKey,pDataSource)
				If $$$ISERR(tSC) Quit
			}
		}
		ElseIf (tExt = "metric") {
			If ('pCalcOnly) {
				Set tKPIClass = "Ens.BusinessMetricKPI"
				Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterMembers",pFilter,.pMembers,.pDefaultValue,pSearchKey,pDataSource)
				If $$$ISERR(tSC) Quit
			}
		}
		Else {
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Tests if a given filter supports range selection (used by the searchBox control).
ClassMethod %DoesFilterSupportRange(pDataSource As %String, pFilter As %String, Output pSupportsRange As %Boolean) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pSupportsRange = 0

		// what kind of data source is in play?
		If (pDataSource="") Quit
		If (pDataSource'[".") {
  			Set pDataSource=pDataSource_".cube"
  		}
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If ((tExt '= "pivot")&&(tExt'="cube")) {
			// range only works for cubes
			Quit
		}

		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(pDataSource,".",1,$L(pDataSource,".")-1))
			}

			If (tCubeName = "") Quit

			// BDB380 - refine using filter spec
			do ..%GetMemberDimensionType(pDataSource, pFilter, .tType)
			Set pSupportsRange = $case($g(tType), "iknow":0, "mdx":0, :1)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the dimension type for a given dashboard data source and filter.
/// Also returns the member class.
ClassMethod %GetMemberDimensionType(pDataSource As %String, pFilter As %String, Output pType As %String, Output pMemberClass As %String, Output pOtherInfo As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pType = ""
		Set pMemberClass = ""

		// JMD1263 return additional info (such as date format)
		Kill pOtherInfo

		// JMD1253
		If (pFilter="$NAMEDFILTER") {
			Set pType = "$NAMEDFILTER"
			Quit
		}

		// JMD1276
		If ($$$LOWER($E(pFilter,1,10))="$variable.") {
			Set pType = "$PIVOTVARIABLE"
			Quit
		}

		If (pFilter="") {
			// JMD1276
			Set tSC = $$$ERROR($$$GeneralError, "No filter provided")
			Quit
		}

		// what kind of data source is in play?
		If (pDataSource="") Quit
		Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
		If ((tExt = "pivot")||(tExt = "cube")) {
			If (tExt = "pivot") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
				If '$IsObject(tPivot) Quit
				Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
			}
			Else {
				Set tCubeName = $$$UPPER($P(pDataSource,".",1,$L(pDataSource,".")-1))
			}

			If (tCubeName = "") Quit
			If ($$$UPPER($E(pFilter,1,$L("[MEASURES]")))="[MEASURES]") {
				// assume this is a searchable measure
				Set pType = "measure"
			}
			Else {
				// Get info on the specified dimension
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tCubeName,pFilter,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec)
				If $$$ISERR(tSC) Quit

				If (tRelationName'="") {
					// JMD939: recurse to get relation info
					Set tRelatedCube = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"relations",$$$UPPER(tRelationName),"relatedCube"))
					Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMemberDimensionType(tRelatedCube_".cube",tRelationSpec,.pType,.pMemberClass,.pOtherInfo)
					If $$$ISERR(tSC) Quit
					Quit
				}

				If (tDimNo="") {
					// JMD1276
					Set tSC = $$$ERROR($$$GeneralError, "Invalid Dimension: "_pFilter)
					Quit
				}

				Set tInfo = $G($$$DeepSeeMetaGLVN("cubes",tCubeName,"mbr#",tDimNo,tHierNo,tLevelNo))
				Set pMemberClass = $LG(tInfo,6)
				If (pMemberClass'="") {
					If $zobjclassmethod(pMemberClass,"%IsA","%DeepSee.Time.AbstractLevel") {
						Set pType = $zobjclassmethod(pMemberClass,"%GetDimType")
					}
					ElseIf $zobjclassmethod(pMemberClass,"%IsA","%DeepSee.ComputedDimension.Base") {
						Set pType = $zobjclassmethod(pMemberClass,"%GetDimType")
					}
					ElseIf $zobjclassmethod(pMemberClass,"%IsA","%DeepSee.DimensionTable") {
						// JMD1475 check for description
						Set tDescProp = $zobjclassmethod(pMemberClass,"%GetParameter","DESCRIPTIONPROPERTY")
						If (tDescProp'="") {
							Set pOtherInfo("descriptionProperty") = tDescProp
						}
					}

					If (pType="day") {
						Set pOtherInfo("dateFormat") = $LG(tInfo,14)
					}
					ElseIf (pType="month") {
						// DTB148 - Return date format for months
						Set pOtherInfo("dateFormat") = $LG(tInfo,14)
					}

					Quit
				}
			}
		}
		ElseIf (tExt = "kpi") {
			// JMD940: Find type of KPI filter from KPI
			Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			If (tKPIClass'="") {
				Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterList",.tFilters,pDataSource)
				If $$$ISERR(tSC) Quit
				Set k = $O(tFilters(""))
				While (k'="") {
					If (pFilter=$LG(tFilters(k),1)) {
						Set pType = $LG(tFilters(k),6)
						Quit
					}
					Set k = $O(tFilters(k))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of all available widget types
/// pInfo(n) = $LB(name,caption,class,icon)
ClassMethod %GetWidgetClasses(Output pInfo As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// find all subclasses of widget
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
		Set tSC = tRS.Execute("%DeepSee.Component.Widget.widget")
		If $$$ISERR(tSC) Quit
		While (tRS.Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tName = $G(tRS.Data("Name"))

			// make sure class is non-abstract and published
			Set tAbstract = +$$$comClassKeyGet(tName,$$$cCLASSabstract)
			Set tPublished = $zobjclassmethod(tName,"%GetParameter","PUBLISHED")
			If (('tAbstract) && tPublished) {
				Set tWidgetClasses(tName) = ""
			}
		}
		
		Set n = 0
		Set tClass = $O(tWidgetClasses(""))
		While (tClass'="") {
			Set n = n + 1
			Set tSC = $zobjclassmethod(tClass,"%GetCatalogInfo",.tCat)
			If $$$ISERR(tSC) Quit

			Set tInfo(n) = tCat
			Set tClass = $O(tWidgetClasses(tClass))
		}
		
		// sort according to ranking
		Set k = $O(tInfo(""))
		While(k'="") {
			Set tRanking = $LG(tInfo(k),5)
			Set:tRanking="" tRanking = 999
			Set tRankedList((tRanking*1000)+k) = tInfo(k)
			Set k = $O(tInfo(k))
		}

		Set n = 0
		Set k = $O(tRankedList(""))
		While(k'="") {
			Set pInfo($I(n)) = tRankedList(k)
			Set k = $O(tRankedList(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the class name for the given widget type.
ClassMethod %GetWidgetClass(pWidgetType As %String) As %String
{
	Set tClass = ""
	Set tSC = ..%GetWidgetClasses(.tInfo)
	If $$$ISERR(tSC) Quit ""

	Set n = $O(tInfo(""))
	While (n'="") {
		If (pWidgetType = $LG(tInfo(n),1)) {
			Set tClass = $LG(tInfo(n),3)
			Quit
		}
		Set n = $O(tInfo(n))
	}
	Quit tClass
}

/// Return an array of widget templates visible to the current user.
/// This list is in the form:<br/>
/// pList(n) = id
ClassMethod %GetWidgetTemplateList(Output pList As %String, Output pCount As %Integer, pMaxItems As %Integer = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)

		Set tTOP = ""
		Set:+pMaxItems>0 tTOP = " TOP "_+pMaxItems

		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare("SELECT"_tTOP_" ID FROM %DeepSee_Dashboard.WidgetTemplate ORDER BY name")
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.ID '="") {
				Set tItem = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tRS.ID)
				If ($IsObject(tItem)) {
					If (tItem.%CheckResource()) {
						Set n = n + 1
						Set pList(n) = tRS.ID
					}
				}
			}
		}
		Set pCount = n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Returns a list of filters for a data source.<br>
Query EnumerateFilters(pSearchKey As %String, pDataSource As %String = "") As %Query(ROWSPEC = "Value:%String,Caption:%String,Type:%String")
{
}

ClassMethod EnumerateFiltersExecute(ByRef qHandle As %Binary, pSearchKey As %String = "", pDataSource As %String = "") As %Status
{
	Set qHandle("key") = ""
	Set qHandle("dataSource") = pDataSource

	Set tSC  = ..%GetFiltersForDataSource(pDataSource, .tFilters,,,pSearchKey)
	Merge qHandle("data") = tFilters
	Quit tSC
}

ClassMethod EnumerateFiltersFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = EnumerateFiltersExecute ]
{
	Set tKey = $G(qHandle("key"))
	Set tKey = $O(qHandle("data",tKey))
	If (tKey'="") {
		Set tData = $G(qHandle("data",tKey))
		Set Row = $LB($LG(tData,2),$LG(tData,1),$LG(tData,3))
		Set AtEnd = 0
		Set qHandle("key") = tKey
	}
	Else {
		Set Row = ""
		Set AtEnd = 1
	}
	Quit $$$OK
}

ClassMethod EnumerateFiltersClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = EnumerateFiltersExecute ]
{
	Kill qHandle
	Set qHandle = ""
	Quit $$$OK
}

/// Return an array of saved themes visible to the current user.
/// This list is in the form:<br/>
/// pList(n) = $LG(id,fullName,name)
ClassMethod %GetThemeList(Output pList As %String, Output pCount As %Integer, pMaxItems As %Integer = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set tFlag = $zu(115,8,0)

		Set tTOP = ""
		Set:+pMaxItems>0 tTOP = " TOP "_+pMaxItems

		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tSC = tStatement.%Prepare("SELECT"_tTOP_" ID,fullName,name FROM %DeepSee_Dashboard.Theme ORDER BY name")
		If $$$ISERR(tSC) Quit

		Set n = 0
		Set tRS = tStatement.%Execute()
		While (tRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			If (tRS.ID '="") {
				Set tItem = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tRS.ID)
				If ($IsObject(tItem)) {
					If (tItem.%CheckResource()) {
						Set n = n + 1
						Set pList(n) = $LB(tRS.ID,tRS.fullName,tRS.name)
					}
				}
			}
		}
		Set pCount = n
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tFlag = $zu(115,8,tFlag)
	Quit tSC
}

/// Save a set of style overrides to the given "theme".
ClassMethod %SaveTheme(pThemeName As %String, pOverrides As %ZEN.proxyObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tExt = $P(pThemeName,".",$L(pThemeName,"."))
		If (tExt'="theme") {
			Set pThemeName = pThemeName_".theme"
		}

		If ('##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pThemeName)) {
			Set tTheme = ##class(%DeepSee.Dashboard.Theme).%New()
			Set tTheme.fullName = pThemeName
		}
		Else {
			Set tTheme = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pThemeName)
		}

		If ($IsObject(tTheme) && tTheme.%IsA("%DeepSee.Dashboard.Theme")) {
			Do pOverrides.%CopyToArray(.tList)
			Set k = $O(tList(""))
			While (k'="") {
				Do tTheme.overrides.SetAt($G(tList(k)),k)
				Set k = $O(tList(k))
			}
			Set tSC = tTheme.%Save()
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Theme not saved: " _ pThemeName)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete the given "theme".
ClassMethod %DeleteTheme(pThemeName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tExt = $P(pThemeName,".",$L(pThemeName,"."))
		If (tExt'="theme") {
			Set pThemeName = pThemeName_".theme"
		}

		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(pThemeName)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod %GetChartTypeInfo(pParentWidgetClass As %String, Output pList As %String)
{
	// + WAL083 (4) -- Added by WAL083
	Kill pList,tList
	Do $classmethod(pParentWidgetClass,"%GetCatalogInfo",,.tList)
	Set i = $O(tList(""))
	While (i '= "") {
		Set tInfo = tList(i)
		Set tName = $LG(tInfo,1)
		Set tDisplayName = $LG(tInfo,2)
		Set tClass = $LG(tInfo,3)
		Set tImage = $LG(tInfo,4)
		If (tName '= "") {
			Set pList(tName) = $LB(tDisplayName,tClass,tImage)	
		}
		Set i = $O(tList(i))
	}
	// - WAL083 (4)
}

}
