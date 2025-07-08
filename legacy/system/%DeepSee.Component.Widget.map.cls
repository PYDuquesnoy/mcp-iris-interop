/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a google map.
Class %DeepSee.Component.Widget.map Extends %DeepSee.Component.Widget.widget [ System = 4 ]
{

/// Style for widget sections
XData Style
{
<style type="text/css">

.mapError {
	background: #f6f8f9;
	padding: 3px;
	color: darkred;
	border: 1px solid #808080;
	box-shadow: 2px 2px 2px #808080;
	position: absolute;
	font-family: arial;
	font-size: 12pt;
	z-index: 10;
}
</style>
}

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Map","%DeepSee"),..%ClassName(1),"deepsee/world_48.gif")
	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo
	// $LB(name,value,type,caption,title,hidden,displayList)

	Set tTypeList = "ENUM^"_$$$Text("Roadmap","%DeepSee")_":ROADMAP,"_
			$$$Text("Satellite","%DeepSee")_":SATELLITE,"_
			$$$Text("Hybrid","%DeepSee")_":HYBRID,"_
			$$$Text("Terrain","%DeepSee")_":TERRAIN"

	Set pInfo($I(pInfo)) = $LB("mapType","",tTypeList,$$$Text("Map Type","%DeepSee"),$$$Text("Initial display type for the map","%DeepSee"),1)
	Set pInfo($I(pInfo)) = $LB("zoom",12,"%Integer",$$$Text("Zoom","%DeepSee"),$$$Text("Initial zoom level for the map","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("latitude",42.36,"%Number",$$$Text("Starting latitude","%DeepSee"),$$$Text("Initial latitude for the map","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("longitude",288.92,"%Number",$$$Text("Starting longitude","%DeepSee"),$$$Text("Initial longitude for the map","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("markersdraggable",1,"%Boolean",$$$Text("Draggable markers","%DeepSee"),$$$Text("Enable marker drag and drop","%DeepSee"))
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB565 - required by excel/PDF export
		Set ..sessionCookie = %session.CSPSessionCookie
		
		// get default values for widget properties
		Do ..%GetWidgetPropertyInfo(..subtype,.tList)
		Set n = $O(tList(""))
		While (n'="") {
			Set tName = $LG(tList(n),1)
			Set tPValue(tName) = ..%definition.properties.GetAt(tName)
			Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
			Set n = $O(tList(n))
		}

		// see if we have a data source
		Set tMsg = ""
		Set tController = ""
		Set tKPIClass = ""
		Set tDataSource = ..dataSource
		Set tExt = $P(tDataSource,".",$L(tDataSource,"."))
		If (tExt = "kpi") {
			Set tName = $P(tDataSource,".",1,$L(tDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
		}
		ElseIf (tExt = "metric") {
			Set tKPIClass = "Ens.BusinessMetricKPI"
		}
		ElseIf (tExt = "worksheet") {
			Set tKPIClass = "%DeepSee.KPIWorksheet"
		}

		If (tKPIClass'="") {
			// add data controller to the widget
			Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
			Set tController.id = ..%MakeWidgetId("controller")
			Set tController.modelClass = tKPIClass
			If (tExt = "metric") {
				Set tController.modelId = ..dataSource
			}
			ElseIf (tExt = "worksheet") {
				Set tController.modelId = ..dataSource
			}
			Set tSC = pGroup.%AddChild(tController)
			If $$$ISERR(tSC) Quit
			Set tInvert = 0
		}
		ElseIf (tExt="pivot") {
			// saved pivot
			// create a hidden pivotTable and use it as the controller
			Set tPivotDef = ""
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dataSource)) {
				// DTB580 - Only set the folder item if we know it exists
				Set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dataSource,.tSC)
				If $$$ISERR(tSC) Quit
			}
			
			If '$IsObject(tPivotDef) {
				// Show error on widget
				Set tLabel = ##class(%ZEN.Component.label).%New()
				Set tLabel.value = $$$FormatText($$$Text("The data source '%1' is missing.","%DeepSee"),..dataSource)
				Set tLabel.enclosingClass = "mapError"
				Set tSC = pGroup.%AddChild(tLabel)
				If $$$ISERR(tSC) Quit
			}

			Set tPivotTable = ##class(%DeepSee.Component.pivotTable).%New()
			Set tPivotTable.id = ..%MakeWidgetId("controller")
			Set tPivotTable.hidden = 1
			Set tSC = pGroup.%AddChild(tPivotTable)
			If $$$ISERR(tSC) Quit

			// JMD: test for bad pivot
			If $IsObject(tPivotDef) {
				// copy information from the saved item to the graphical pivot
				Set tSC = tPivotDef.%CopyToComponent(tPivotTable)
				If $$$ISERR(tSC) Quit
			}
			
			Set tController = tPivotTable
			Set tInvert = 1
		}

		// add a map view to the widget
		Set tMap = ##class(%DeepSee.Component.mapView).%New()
		Set tMap.id = ..%MakeWidgetId("map")
		Set:$IsObject(tController) tMap.controllerId = tController.id
		Set tSC = pGroup.%AddChild(tMap)
		If $$$ISERR(tSC) Quit

		// copy settings into map component
		If (""'=$G(tPValue("mapType"))) {
			Set tMap.mapType = tPValue("mapType")
		}
		If (""'=$G(tPValue("zoom"))) {
			Set tMap.zoom = +tPValue("zoom")
		}
		If (""'=$G(tPValue("longitude"))) {
			Set tMap.longitude = +tPValue("longitude")
		}
		If (""'=$G(tPValue("latitude"))) {
			Set tMap.latitude = +tPValue("latitude")
		}

		// JMD950
		If (""'=tPValue("markersdraggable")) {
			Set tMap.markersDraggable=tPValue("markersdraggable")
		}

		// JMD950: if there are data properties, these define the contents of the info window.
		Set tPropCount = ..%definition.dataProperties.Count()

		For p=1:1:tPropCount {
			Set tDataPropertyDef = ..%definition.dataProperties.GetAt(p)

			// use the column structure;
			// not all of these properties are relevant
			Set tColumn = ##class(%DeepSee.Component.SVG.scoreCardColumn).%New()
			Set tColumn.label = tDataPropertyDef.label
			Set tColumn.format = tDataPropertyDef.format
			Set tColumn.style = tDataPropertyDef.style
			Set tColumn.display = tDataPropertyDef.display
			Set tColumn.showAs = tDataPropertyDef.showAs
			Set tColumn.summary = tDataPropertyDef.summary
			Set tColumn.summaryValue = tDataPropertyDef.summaryValue
			Set tColumn.valueColumn = tDataPropertyDef.valueColumn
			Set tColumn.dataValue = tDataPropertyDef.dataValue
			Set tColumn.targetValue = tDataPropertyDef.targetValue
			Set tColumn.rangeLower = tDataPropertyDef.rangeLower
			Set tColumn.rangeUpper = tDataPropertyDef.rangeUpper
			Set tColumn.baseValue = tDataPropertyDef.baseValue
			Set tColumn.thresholdLower = tDataPropertyDef.thresholdLower
			Set tColumn.thresholdUpper = tDataPropertyDef.thresholdUpper
			Set tColumn.width = tDataPropertyDef.width
			Set tColumn.align = tDataPropertyDef.align
			Do tMap.infoProperties.Insert(tColumn)
			Do:$IsObject($G(%page)) %page.%AddComponent(tColumn)
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var map = this.findComponent('map');
	if (map) {
		var mapDiv = map.getEnclosingDiv();
		width = width > 10 ? width : 0;
		mapDiv.style.width = width-10 + 'px';
		mapDiv.style.height = height + 'px';
	}
}

/// Apply the given filter to this widget.
ClientMethod applyFilter(name, value) [ Language = javascript ]
{
}

/// If this widget contains a data controller, return it.
/// This allows for generic capabilities in this base class.
ClientMethod getDataController() [ Language = javascript ]
{
	return this.findComponent('controller');
}

/// If this widget contains a data controller, return it.
Method %GetDataController() As %ZEN.Auxiliary.abstractController
{
	Quit ..%FindComponent("controller")
}

/// Test if this widget is ready to be resized.
ClientMethod isReady() [ Internal, Language = javascript ]
{
	var controller = this.getDataController();
	if (controller && controller.hasData) {
		return controller.hasData();
	}
	return true;
}

}
