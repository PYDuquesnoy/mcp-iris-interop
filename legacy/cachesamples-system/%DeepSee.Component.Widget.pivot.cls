/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a pivot table (either as a table or a chart).
Class %DeepSee.Component.Widget.pivot Extends (%DeepSee.Component.Widget.widget, %ZEN.Auxiliary.ChartContent, %DeepSee.Component.PivotContent) [ System = 4 ]
{

/// Hold onto the name of the saved pivot (or KPI) that drives this widget.
Property pivotName As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Remember the legend position.
Property legendPosition As %ZEN.Datatype.string(VALUELIST = "top,left,bottom,right,none", XMLPROJECTION = "none");

/// Remember if chart labels are visible.
/// When the widget is too small, we will hide these.
Property labelsVisible As %ZEN.Datatype.boolean(XMLPROJECTION = "none");

/// Remember the chartToggle state.
/// If "none", show either a chart or a table.
/// If "chart", show the current chart type initially and a button to toggle.
/// If "table", show the table initially and a button to toggle.
Property chartToggle As %ZEN.Datatype.string(VALUELIST = "table,chart,none", XMLPROJECTION = "none") [ InitialExpression = "none" ];

/// Indicates the current display of the widget: "pivot" or "listing".
Property viewType As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "pivot", Internal ];

/// When pivot is displayed, indicates how it should be displayed: "table" or "chart".
Property pivotView As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "table", Internal ];

/// When listing is displayed, indicates how it should be displayed: "table" or "map".
Property listingView As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "table", Internal ];

/// When true, there is a dimension tree on this widget.
Property hasDimTree As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 1, Internal ];

/// If there is a dimension tree, this indicates if it is visible.
Property showDimTree As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// List of chart properties that are saved to a theme.
Property themeChartProperties As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "backgroundStyle,plotAreaStyle,plotEdgeStyle,titleAlign,titleStyle,subtitleStyle,titleBoxStyle,borderStyle,stripesVisible,stripeStyle,seriesColorsOverride,seriesColorScheme,gridStyle,labelStyle,maxLabelLen,axisTitleStyle,valueLabelStyle,valueBoxStyle,plotStyle,lineStyle,markerStyle", Internal ];

/// Array of "data-based" colors keyed by name.
/// Loaded from termlist.
Property dataColors As array Of %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

Property hasDataColors As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ Internal ];

/// Original value for chart title (before localization is applied).
Property origChartTitle As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Original value for chart subtitle (before localization is applied).
Property origChartSubtitle As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Original value for chart xAxis title (before localization is applied).
Property origChartXAxisTitle As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Original values for chart yAxis titles (before localization is applied).
Property origChartYAxisTitles As list Of %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon,ranking)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Pivots and Charts","%DeepSee"),..%ClassName(1),"deepsee/seo_48.gif",1)

	// $LB(name,caption)
	Set pSubtypeList($I(n)) = $LB("pivot",$$$Text("Table","%DeepSee"),,"deepsee/ds2_list_44.png")
	Set pSubtypeList($I(n)) = $LB("barChart",$$$Text("Bar Chart","%DeepSee"),,"deepsee/ds_chart_bar.png")
	Set pSubtypeList($I(n)) = $LB("barChartStacked",$$$Text("Stacked Bar Chart","%DeepSee"),,"deepsee/ds_chart_bar_stack.png")
	Set pSubtypeList($I(n)) = $LB("columnChart",$$$Text("Column Chart","%DeepSee"),,"deepsee/ds_chart_column.png")
	Set pSubtypeList($I(n)) = $LB("columnChart3D",$$$Text("3D Column Chart","%DeepSee"),,"deepsee/ds_chart_bar3d.png")
	Set pSubtypeList($I(n)) = $LB("columnChartStacked",$$$Text("Stacked Column Chart","%DeepSee"),,"deepsee/ds_chart_column_stack.png")

	Set pSubtypeList($I(n)) = $LB("comboChart",$$$Text("Combo Chart","%DeepSee"),,"deepsee/ds_chart_combo.png")

	Set pSubtypeList($I(n)) = $LB("lineChart",$$$Text("Line Chart","%DeepSee"),,"deepsee/ds_chart_line.png")
	Set pSubtypeList($I(n)) = $LB("lineChartMarkers",$$$Text("Line Chart + Markers","%DeepSee"),,"deepsee/ds_chart_marker.png")
	Set pSubtypeList($I(n)) = $LB("areaChart",$$$Text("Area Chart","%DeepSee"),,"deepsee/ds_chart_area.png")
	Set pSubtypeList($I(n)) = $LB("hilowChart",$$$Text("High-Low Chart","%DeepSee"),,"deepsee/ds_chart_hilow.png")
	Set pSubtypeList($I(n)) = $LB("bubbleChart",$$$Text("Bubble Chart","%DeepSee"),,"deepsee/ds_chart_bubble.png")
	Set pSubtypeList($I(n)) = $LB("xyChart",$$$Text("XY Chart","%DeepSee"),,"deepsee/ds_chart_xy.png")

	Set pSubtypeList($I(n)) = $LB("pieChart",$$$Text("Pie Chart","%DeepSee"),,"deepsee/ds_chart_pie.png")
	Set pSubtypeList($I(n)) = $LB("pieChart3D",$$$Text("3D Pie Chart","%DeepSee"),,"deepsee/ds_chart_pie3d.png")
	Set pSubtypeList($I(n)) = $LB("donutChart",$$$Text("Donut Chart","%DeepSee"),,"deepsee/ds_chart_donut.png")
	Set pSubtypeList($I(n)) = $LB("donutChart3D",$$$Text("3D Donut Chart","%DeepSee"),,"deepsee/ds_chart_donut3d.png")

	// JMD1202
	Set pSubtypeList($I(n)) = $LB("treeMapChart",$$$Text("Tree Map","%DeepSee"),,"deepsee/ds_chart_treemap.png")
	Set pSubtypeList($I(n)) = $LB("bullseyeChart",$$$Text("Bullseye Chart","%DeepSee"),,"deepsee/ds_chart_bullseye.png")
	Set pSubtypeList($I(n)) = $LB("timeChart",$$$Text("Time Chart","%DeepSee"),,"deepsee/ds_chart_time.png")

	// JSL4277	
	Set pSubtypeList($I(n)) = $LB("swirlChart",$$$Text("Swirl Chart","%DeepSee"),,"deepsee/ds_chart_swirl.png")

	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo
	// $LB(name,value,type,caption,title,hidden,displayList)

	Set tLabelsOn = '((pSubtype["pieChart")||(pSubtype["donutChart"))

	If (pSubtype["Chart") {
		Set pInfo($I(pInfo)) = $LB("title","","%String",$$$Text("Chart Title","%DeepSee"),$$$Text("Title to display within the chart","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("titleStyle","","Style",$$$Text("Title style","%DeepSee"),$$$Text("Style for chart title","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("XgridLines",0,"%Boolean",$$$Text("X Grid Lines","%DeepSee"),$$$Text("Turn on chart grid lines","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("YgridLines",0,"%Boolean",$$$Text("Y Grid Lines","%DeepSee"),$$$Text("Turn on chart grid lines","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("labels",tLabelsOn,"%Boolean",$$$Text("Show labels","%DeepSee"),$$$Text("Turn on chart labels","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("labelStyle","","Style",$$$Text("Label style","%DeepSee"),$$$Text("Style for chart labels","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("legendPos","right","ENUM^none,right,left,top,bottom",$$$Text("Legend","%DeepSee"),$$$Text("How to display legend for chart","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("valueLabels",0,"%Boolean",$$$Text("Show value labels","%DeepSee"),$$$Text("Turn on chart value labels for bar and column charts","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("hasZoom",1,"%Boolean",$$$Text("Show zoom in/out buttons","%DeepSee"),$$$Text("Show zoom in/out buttons","%DeepSee"),1)
	}

	If ((pSubtype["pieChart")||(pSubtype["donutChart")||(pSubtype["treeMapChart")) {
		Set pInfo($I(pInfo)) = $LB("showPercentage",0,"%Boolean",$$$Text("Show percentages","%DeepSee"),$$$Text("Show percentages within pie charts","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("showMultiples",1,"%Boolean",$$$Text("Show multiples","%DeepSee"),$$$Text("Show data series as multiple charts","%DeepSee"),1)
	}
	If ((pSubtype["lineChart")) {
		// Set pInfo($I(pInfo)) = $LB("showMultiples",0,"%Boolean",$$$Text("Show multiples","%DeepSee"),$$$Text("Show data series as multiple charts","%DeepSee"),1)
	}
	If (pSubtype="comboChart") {
		Set pInfo($I(pInfo)) = $LB("stacked",0,"%Boolean",$$$Text("Show stacked bars","%DeepSee"),$$$Text("Show percentages within pie charts","%DeepSee"),1)
	}
	If (pSubtype="bubbleChart") {
		Set pInfo($I(pInfo)) = $LB("showQuadrant",1,"%Boolean",$$$Text("Show quadrants","%DeepSee"),$$$Text("Show shaded quadrants in chart background","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("showRegression",0,"%Boolean",$$$Text("Show regression","%DeepSee"),$$$Text("Plot a linear regression line in the chart","%DeepSee"),1)
	}

	// JSL4277
	if (pSubtype="swirlChart") {
		Set pInfo($I(pInfo)) = $LB("invert",0,"%Boolean",$$$Text("invert labels","%DeepSee"),$$$Text("Put labels on inside of swirl or outside","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("separateSeriesScale",0,"%Boolean",$$$Text("Separate series scale","%DeepSee"),$$$Text("percentage denominator is max in chart or max in series","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("gap",30,"%Integer",$$$Text("Specify gap","%DeepSee"),$$$Text("space between first slice and last slice in degrees","%DeepSee"),1)
		Set pInfo($I(pInfo)) = $LB("plotBy","items","ENUM^,items,series",$$$Text("Specify plotBy","%DeepSee"),$$$Text("organize by series or by items","%DeepSee"),1)
	}
	// available to all
	Set pInfo($I(pInfo)) = $LB("chartToggle","none","ENUM^none,chart,table",$$$Text("Chart Toggle","%DeepSee"),$$$Text("Specify if user can toggle between chart and table and what the initial view should be","%DeepSee"),0,$$$Text("None,Chart,Table","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("drillDown",0,"%Boolean",$$$Text("Drill Down","%DeepSee"),$$$Text("Show drill in/out control","%DeepSee"),0)
	Set pInfo($I(pInfo)) = $LB("analyzer",0,"%Boolean",$$$Text("Analyzer","%DeepSee"),$$$Text("Enable Analyzer dialog for this pivot","%DeepSee"))

	Set:$$$comClassDefined("%DeepSee.UI.MDXPDF") pInfo($I(pInfo)) = $LB("print",0,"%Boolean",$$$Text("Print","%DeepSee"),$$$Text("Enable printing for this widget","%DeepSee"))		// DTB236
	Set:$$$comClassDefined("%DeepSee.UI.MDXExcel") pInfo($I(pInfo)) = $LB("excel",0,"%Boolean",$$$Text("Excel Export","%DeepSee"),$$$Text("Enable Excel export for this widget","%DeepSee"))
	Set:$$$comClassDefined("%DeepSee.UI.MDXCSV") pInfo($I(pInfo)) = $LB("csv",0,"%Boolean",$$$Text("CSV Export","%DeepSee"),$$$Text("Enable CSV export for this widget","%DeepSee"))		// DP-402897
	Set pInfo($I(pInfo)) = $LB("pivotSelect","","ENUM^,single,multi",$$$Text("Row selection","%DeepSee"),$$$Text("Allow selection of single or multiple rows in table (this only applies to KPI-based pivot tables)","%DeepSee"),0,$$$Text(",Single,Multi","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("showDimensions",0,"%Boolean",$$$Text("Show Dimensions","%DeepSee"),$$$Text("Display a list of dimensions that the user can select from","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("dimensionSource","","DataSource",$$$Text("Dimension Source","%DeepSee"),$$$Text("Provide a list of dimensions from a different data source (such as a worksheet)","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("initialExecute",1,"%Boolean",$$$Text("Initial Execute","%DeepSee"),$$$Text("If on, then execute the pivot query when the dashboard is displayed","%DeepSee"))
	Set pInfo($I(pInfo)) = $LB("contentPreview",0,"%Boolean",$$$Text("Pivot Preview"),$$$Text("If on, the pivot table will use preview mode to display partial results"))		// DP-408943
	
	Quit $$$OK
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	// get default values for widget properties
	Do ..%GetWidgetPropertyInfo(..subtype,.tList)
	Set n = $O(tList(""))
	While (n'="") {
		Set tName = $LG(tList(n),1)
		Set tPValue(tName) = ..%definition.properties.GetAt(tName)
		Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
		Set n = $O(tList(n))
	}

	Set ..chartToggle = "none"
	If ($G(tPValue("chartToggle"))'="") {
		Set ..chartToggle = tPValue("chartToggle")
	}

	// chart toggle
	If ($IsObject(..%definition) && ((..chartToggle="table")||(..chartToggle="chart"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.id = ..id _ "_chartToggle"
		If (..chartToggle="table") {
			Set tButton.src = "deepsee/ds2_linechart_44.png"
		}
		Else {
			Set tButton.src = "deepsee/ds2_list_44.png"
		}
		Set tButton.title = $$$Text("Toggle between chart and table view of data","%DeepSee")
		If (..previewMode) {
			// Set tButton.disabled = 1 - comment out JSL4543
			Set tButton.onclick = "zenPage.getComponent("_..index_").toggleChart();" // JSL4543
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").toggleChart();"
		}
		Do pGroup.%AddChild(tButton)
	}

	Set ..hasDimTree = 0
	If ($G(tPValue("showDimensions"))'="") {
		Set ..hasDimTree = +tPValue("showDimensions")
	}

	// dimension list
	If (..hasDimTree) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.id = ..id _ "_showDimensions"
		Set tButton.name = "showDimensions"
		If (..showDimTree) {
			Set tButton.src = "deepsee/ds2_orgchart_44.png"
		}
		Else {
			Set tButton.src = "deepsee/ds2_orgchart_44.png"
		}
		Set tButton.title = $$$Text("Show list of dimensions","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").showDimensions();"
		}
		Do pGroup.%AddChild(tButton)
	}

	// pdf export
	If (+$G(tPValue("print"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.src = "deepsee/ds2_printer_22.png"
		Set tButton.title = $$$Text("Create PDF from this pivot","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").exportPDF();"
		}
		Do pGroup.%AddChild(tButton)
	}

	// excel export
	If ( +$G(tPValue("excel")) || +$G(tPValue("csv")) ) {		// DP-406140 - Display an export button if either setting is on
		If (+$G(tPValue("csv"))) {
			// DP-402897 - This requires custom html to draw a dropdown menu
			Set tButton = ##class(%ZEN.Component.html).%New()
			Set tTitle = $$$Text("Export current results","%DeepSee")
			
			Set tOptions = []
			
			If +$G(tPValue("excel")) {
				// DP-406140 - If Excel is off, supress this choice in the menu
				Set tExcel = {"name":"Excel"}
				Set tExcel.click = "zenPage.getComponent("_..index_").exportExcel();"
				Set tExcel.hover = $$$Text("Microsoft Excel (.xls)")
				Do tOptions.%Push(tExcel)
			}
			
			Set tCSV = {"name":"CSV"}
			Set tCSV.click = "zenPage.getComponent("_..index_").exportCSV(true);"
			Set tCSV.hover = $$$Text("Comma delimited (.csv)")
			Do tOptions.%Push(tCSV)
			
			Set tCSVPlus = {}
			Set tCSVPlus.name = $$$Text("CSV with Headers")
			Set tCSVPlus.click = "zenPage.getComponent("_..index_").exportCSV();"
			Set tCSVPlus.hover = $$$Text("Comma delimited with headers and filters (.csv)")
			Do tOptions.%Push(tCSVPlus)		
			
			Set tContent = ..%CreateExportDropdown(..index,1,"deepsee/ds2_action_44.png",tTitle,tOptions)
			
			Set tButton.content = tContent
		}
		Else {
			Set tButton = ##class(%ZEN.Component.image).%New()
			Set tButton.src = "deepsee/ds2_action_44.png"
			Set tButton.title = $$$Text("Export table to Excel","%DeepSee")
			If (..previewMode) {
				Set tButton.disabled = 1
			}
			Else {
				Set tButton.onclick = "zenPage.getComponent("_..index_").exportExcel();"
			}
		}
		
		Do pGroup.%AddChild(tButton)
	}

	// drill down
	If (+$G(tPValue("drillDown"))) {
		Set tButton = ##class(%DeepSee.Component.drillIndicator).%New()
		Set tButton.pivotId = ..%MakeWidgetId("table")
		Set tButton.id = ..id _ "_drillDown"
		Set tButton.title = $$$Text("Drill into current item","%DeepSee")
		Set tButton.ondrilldown = "zenPage.getComponent("_..index_").executeDrillDown();"
		Set tButton.ondrillup = "zenPage.getComponent("_..index_").executeDrillUp();"
		Do pGroup.%AddChild(tButton)
	}

	Quit $$$OK
}

/// Get html to create an icon with an Excel/CSV dropdown menu.
Method %CreateExportDropdown(id, enabled, imgId, help, options) As %String
{
	// Method added by DP-402897
	Set html = ""
	
	Try {
		Set cls = $S(enabled:"dsptIconDropdown",1:"dsptIconDisabled")
		// no hover color for ie in quirks mode!
		Set imgUrl = "deepsee/ds2_action_44.png"

		Set style = "padding-right:4px;"
		if ($Find(imgId,"24")>=0) {
			Set style = style _ "height:22px;"
		}
		elseif ($Find(imgId,"16")>=0) {
			Set style = style _ "height:12px;"
		}

		if ($Find(imgId,"Swap")>=0) {
			Set style = style _ "width:22px;"
		}
		
		Set dropId = ..%MakeId("DropDown")
		Set html = ""
		
		// Create a div that has a permanently displayed button and a dropdown menu
		Set html = html _ "<div id=""" _ ..%MakeId("exportButton") _ """>"
		Set html = html _ "<img style=""" _ style _ """ class=""" _ cls _""" title=""" _ help _ """ onclick=""zenPage.getComponent("_..index_").toggleExportMenu('" _ dropId _ "');"" src=""" _ imgUrl _ """/>"
		
		Set html = html _ "<div id=""" _ dropId _ """ class=""dsptIconDropdownMenu"" style=""display:none;"">"
		
		// Add the menu options to the dropdown menu
		for n=0:1:(options.%Size()-1) {
			set optionDef = ""
			Set optionDef = optionDef _ "<a"
			Set:(options.%Get(n).click'="") optionDef = optionDef _ " onclick=""zenPage.getComponent("_..index_").toggleExportMenu('" _ dropId _ "');" _ options.%Get(n).click _ """"
			Set:(options.%Get(n).hover'="") optionDef = optionDef _ " title=""" _ options.%Get(n).hover _ """"
			Set optionDef = optionDef _ ">"
			Set optionDef = optionDef _ options.%Get(n).name
			Set optionDef = optionDef _ "</a>"
			
			Set html = html _ optionDef
		}

		Set html = html _ "</div>"		// Drop-down div
		Set html = html _ "</div>"		// Overall div
	}
	Catch ex {
		Set html = ""
	}

	Quit html
}

/// Toggle the state of the target Excel/CSV export menu dropdown. When causing the menu
/// to be displayed, the zenMouseTrap is also activated behind the menu to prevent other
/// interactions.
ClientMethod toggleExportMenu(menuId) [ Language = javascript ]
{
	// Method added by DP-402897
	var dropMenu = document.getElementById(menuId);
	var trap = document.getElementById("zenMouseTrap");
	var widgetHtml = document.getElementById(this.id);
	
	if ((dropMenu) && (dropMenu.style)) {
		var dropMenuIcon = dropMenu.previousElementSibling;
		
		if (dropMenu.style.display === "none") {
		    // This widget needs to have its z-index nullified so that it does not force the value on
		    // the DOM descendant which will be the dropMenu.
		    widgetHtml.style.zIndex = '';
		    
		    // Activate the transparent mouse trap around the menu to catch click events anywhere else 
		    // on the page.
			trap.style.zIndex = 100;
		    trap.style.display = "block";
		    trap.onmouseup = new Function("if (zenPage.closeModalPending) {zenPage.closeModalPending = 0; zenPage.getComponentById('"+this.id+"').closeExportMenu('"+menuId+"');}")
			trap.onmousedown = function() {zenPage.closeModalPending = 1;}
			trap.onmouseout = function() {zenPage.closeModalPending = 0;}
			trap.onmousemove = null;
			
		    dropMenu.style.zIndex = 101;
			dropMenu.style.display = "block";
 		    dropMenuIcon.setAttribute("class","dsptIconDropdownSelect");
		} else {
		    this.closeExportMenu(menuId);
		}
	}
}

/// Close the Excel/CSV export menu and remove the mouse trap.This does nothing if the target
/// menu is not open.
ClientMethod closeExportMenu(menuId) [ Language = javascript ]
{
	// Method added by DP-402897
	var dropMenu = document.getElementById(menuId);
	var trap = self.document.getElementById("zenMouseTrap");
	
	if ((dropMenu) && (dropMenu.style.display != "none")) {
		var dropMenuIcon = dropMenu.previousElementSibling;
		dropMenu.style.display = "none";
		dropMenuIcon.setAttribute("class","dsptIconDropdown");
		
		// Clear the trap callbacks and disable the mouse trap.
		trap.style.display = "none";
		trap.style.zIndex = "";
		trap.onmouseup = null;
		trap.onmousedown = null;
		trap.onmouseout = null;
	}
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..sessionCookie = %session.CSPSessionCookie

		// get default values for widget properties
		Do ..%GetWidgetPropertyInfo(..subtype,.tList)
		Set n = $O(tList(""))
		While (n'="") {
			Set tName = $LG(tList(n),1)
			//Set tPValue(tName) = ..%definition.properties.GetAt(tName)
			Set tPValue(tName) = $S(..%definition.properties.%IsA("%Collection.AbstractArray"):..%definition.properties.GetAt(tName),1:"")
			Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
			Set n = $O(tList(n))
		}

		// JMD1128 See if there are overrides (test for theme as well)

		// this is where chart override is stored
		Set tSubtypeClass = ..%definition.subtypeClass
		Set tThemeChart = ""
		Set tChartOverride = ""
		Set tLegendOverride = ""
		Set tPivotOverride = ""
		Set tThemeChartJSON = ""
		Set tChartJSON = ""
		Set tLegendJSON = ""
		Set tPivotJSON = ""

		// check for overrides from themes
		// JMD1201: chart overrides are generic and handled differently
		If (..%definition.themeOverrides.%IsA("%Collection.AbstractArray")) {
			Set tThemeChartJSON = ..%definition.themeOverrides.GetAt("chart")
			Set tLegendJSON = ..%definition.themeOverrides.GetAt("legend")
			Set tPivotJSON = ..%definition.themeOverrides.GetAt("pivot")
		}
		Else {
			// JSON provider
			Set tThemeChartJSON = $property(..%definition.themeOverrides,"chart")
			Set tLegendJSON = $property(..%definition.themeOverrides,"legend")
			Set tPivotJSON = $property(..%definition.themeOverrides,"pivot")
		}

		If ($IsObject(..%definition.overrides)) {
			If (..%definition.overrides.%IsA("%Collection.AbstractArray")) {
				If (tSubtypeClass'="") {
					Set:..%definition.overrides.GetAt(tSubtypeClass)'="" tChartJSON = ..%definition.overrides.GetAt(tSubtypeClass)
				}
				Set:..%definition.overrides.GetAt("legend")'="" tLegendJSON = ..%definition.overrides.GetAt("legend")
				Set:..%definition.overrides.GetAt("pivot")'="" tPivotJSON = ..%definition.overrides.GetAt("pivot")
			}
			Else {
				// JSON provider
				If (tSubtypeClass'="") {
					Set:$property(..%definition.overrides,tSubtypeClass)'="" tChartJSON = $property(..%definition.overrides,tSubtypeClass)
				}
				Set:$property(..%definition.overrides,"legend")'="" tLegendJSON = $property(..%definition.overrides,"legend")
				Set:$property(..%definition.overrides,"pivot")'="" tPivotJSON = $property(..%definition.overrides,"pivot")
			}
		}

		// instantiate a generic object based on the theme settings
		If (tThemeChartJSON'="") {
			Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tThemeChartJSON,,.tThemeChart)
			If $$$ISERR(tSC) Quit

			// ignore old saved themes!
			If ($IsObject(tThemeChart)&&('tThemeChart.%IsA("%ZEN.proxyObject"))) {
				Set tThemeChart = ""
			}
		}

		If (tChartJSON'="") {
			Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tChartJSON,,.tChartOverride)
			If $$$ISERR(tSC) Quit
		}
		If (tLegendJSON'="") {
			Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tLegendJSON,,.tLegendOverride)
			If $$$ISERR(tSC) Quit
		}
		If (tPivotJSON'="") {
			Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tPivotJSON,,.tPivotOverride)
			If $$$ISERR(tSC) Quit
		}

		If (..hasDimTree) {
			Set tTreeWrapper = ##class(%ZEN.Component.vgroup).%New()
			Set tTreeWrapper.id = ..%MakeWidgetId("dtreewrapper")
			Set tTreeWrapper.containerStyle = "border-bottom: solid #D0D0D0 1px; border-right: solid #D0D0D0 1px; overflow: hidden;"
			Set tSC = pGroup.%AddChild(tTreeWrapper)
			If $$$ISERR(tSC) Quit

			// JMD991: go back icon
			Set tButton = ##class(%ZEN.Component.image).%New()
			Set tButton.id = ..%MakeWidgetId("reset")
			Set tButton.title = $$$Text("Go back to previous view","%DeepSee")
			Set tButton.src = "deepsee/ds2_arrow_west_44.png"
			Set tButton.controlStyle = "width:16px;"
			Set tButton.enclosingStyle = "padding:2px;border-bottom:1px solid #D0D0D0;"
			If (..previewMode) {
				Set tButton.disabled = 1
			}
			Else {
				Set tButton.onclick = "zenPage.getComponent("_..index_").resetPivot();"
			}
			Set tSC = tTreeWrapper.%AddChild(tButton)
			If $$$ISERR(tSC) Quit

			// add dimensions tree to the widget
			Set tTree = ##class(%ZEN.Component.dynaTree).%New()
			Set tTree.id = ..%MakeWidgetId("dtree")
			Set tTree.imageContracted = "portal/disc_up_16.gif"
			Set tTree.imageExpanded = "portal/disc_down_16.gif"
			Set tTree.imageNode = "deepsee/ds2_brightness_44.png"
			Set tTree.showLines = 0
			Set tTree.dragEnabled = 1
			Set tTree.showFolders = 0
			Set tTree.OnGetTreeInfo = "GetDimensionInfo"
			Set tSC = tTreeWrapper.%AddChild(tTree)
			If $$$ISERR(tSC) Quit

			// connect dataSource to tree
			Set tParm = ##class(%ZEN.Auxiliary.parameter).%New()
			Set tParm.value = ..dataSource
			Do tTree.parameters.SetAt(tParm,"DataSource")
			Do %page.%AddComponent(tParm)

			// connect memberSource to tree, if present
			Set tMemberSource = $G(tPValue("dimensionSource"))
			If (tMemberSource'="") {
				Set tParm = ##class(%ZEN.Auxiliary.parameter).%New()
				Set tParm.value = tMemberSource
				Do tTree.parameters.SetAt(tParm,"MemberSource")
				Do %page.%AddComponent(tParm)
			}
		}

		// add invisible div to support style hacking
		// add pivot table to the widget
		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.id = ..%MakeWidgetId("test")
		Set tHTML.enclosingStyle = "display:none;"
		Set tSC = pGroup.%AddChild(tHTML)
		If $$$ISERR(tSC) Quit

		// add pivot table to the widget
		Set tPivot = ##class(%DeepSee.Component.pivotTable).%New()
		Set tPivot.id = ..%MakeWidgetId("table")
		Set tPivot.dataSourceName = ..dataSource
		
		Set tPivot.previewMode = tPValue("contentPreview")		// DP-408943
		Set tPivot.crossJoinRowLimit = $S(tPivot.previewMode:2000,1:0)		// DP-408943
		
		If ('..previewMode) {
			Set tPivot.oncellClick = "zenPage.getComponent("_..index_").cellClickHandler(pivot);"
			Set tPivot.onlistingSelect = "zenPage.getComponent("_..index_").listingSelectHandler(pivot);"
			Set tPivot.ondrill = "return zenPage.getComponent("_..index_").drillHandler(pivot);"
			Set tPivot.dropEnabled = 1
		}

		If ('+$G(tPValue("initialExecute"),0) || ..previewMode) {
			Set tPivot.initialExecute = 0
		}
		
		// PFS073 - If chartToggle="chart", do not apply pivotView="table"
		If (((..subtype="pivot")||(..subtype="")||(..chartToggle="table"))&&(..chartToggle'="chart")) {
			Set tPivot.hidden = 0
			Set ..pivotView = "table"
		}
		Else {
			Set tPivot.hidden = 1
			Set ..pivotView = "chart"
		}
		Set tSC = pGroup.%AddChild(tPivot)
		If $$$ISERR(tSC) Quit

		Set tPivotName = ..dataSource

		Set tSC = ..%LoadPivotInfo(tPivotName,tPivot)
		If $$$ISERR(tSC) Quit

		Set tPivot.pivotSelect = $G(tPValue("pivotSelect"))

		// JMD1063: status only shown if there are paging buttons
		Set tPivot.showStatus = 0
		Set tPivot.showPivotStats = 0
		Set tPivot.listingSelect = $Case($G(tPValue("pivotSelect")),"single":"single",:"multi")		// DP-413188

		// JMD1276
		// check for pivot variables passed in from URL
		If ($D(%dsPivotVariables)) {
			// wildcards
			Set k = $O(%dsPivotVariables("*",""))
			While (k'="") {
				Do tPivot.pivotVariables.SetAt(%dsPivotVariables("*",k),$$$LOWER(k))
				Set k = $O(%dsPivotVariables("*",k))
			}
			// specific
			Set tWName = ..name
			If (tWName'="") {
				Set k = $O(%dsPivotVariables(tWName,""))
				While (k'="") {
					Do tPivot.pivotVariables.SetAt(%dsPivotVariables(tWName,k),$$$LOWER(k))
					Set k = $O(%dsPivotVariables(tWName,k))
				}
			}
		}

		// see if there is a showGeoListing for this pivot
		// find default values for row and column counts
		Set tHasGeoListing = 0
		Set tCCount = ..%definition.controls.Count()
		For c=1:1:tCCount {
			Set tControlDef = ..%definition.controls.GetAt(c)
			If (tControlDef.action="showGeoListing") {
				Set tHasGeoListing = 1
			}
			ElseIf (tControlDef.action="setRowCount") {
				Set tDefRowCount = tControlDef.value
			}
			ElseIf (tControlDef.action="setColumnCount") {
				Set tDefColCount = tControlDef.value
			}
		}

		// see if there are data properties
		Set tColumnList = "" // used for KPI-based pivots
		Set tValueColumn = ""
		Set tDPCount = ..%definition.dataProperties.Count()
		For d=1:1:tDPCount {
			Set tDataPropertyDef = ..%definition.dataProperties.GetAt(d)
			If (tDataPropertyDef.display'="hidden") {
				If (tDataPropertyDef.dataValue'="") {
					// column list is csv list of prop:caption:format
					// escape "," with "\,"  
					// escape ":" with "\:"

					Set tColumnList = tColumnList _ $S(tColumnList="":"",1:",") _ tDataPropertyDef.dataValue
					If (tDataPropertyDef.label'="") {
						Set tColumnList = tColumnList _ ":" _ $$ESC(tDataPropertyDef.label)
					}
					If (tDataPropertyDef.format'="") {
						If (tDataPropertyDef.label="") {
							Set tColumnList = tColumnList _ ":"
						}
						Set tColumnList = tColumnList _ ":" _ $$ESC(tDataPropertyDef.format)
					}
				}
			}
			ElseIf ((tDPCount=1)&&(tDataPropertyDef.display="hidden")) {
				// DTB457 - Signal the pivot that it needs to display everything *except*
				// this column.
				Set tColumnList = tColumnList _ $S(tColumnList="":"",1:",") _ tDataPropertyDef.dataValue
				If (tDataPropertyDef.label'="") {
					Set tColumnList = tColumnList _ ":" _ $$ESC(tDataPropertyDef.label)
				}
				If (tDataPropertyDef.format'="") {
					If (tDataPropertyDef.label="") {
						Set tColumnList = tColumnList _ ":"
					}
					Set tColumnList = tColumnList _ ":" _ $$ESC(tDataPropertyDef.format)
				}
				
				Set tColumnList = "!" _ tColumnList
			}

			If (tDataPropertyDef.valueColumn) {
				Set tValueColumn = tDataPropertyDef.dataValue
			}
		}
		Set tPivot.columnList = tColumnList
		Set tPivot.valueColumn = tValueColumn

		// drill down on double click
		If (..%definition.drillDownDataSource'="") {
			Set tPivot.oncellDblClick = "zenPage.drillDown(zenPage.getComponent("_..index_"),'"_$ZCVT(..%definition.drillDownDataSource,"O","JS")_"');"
		}

		Set tRowCount = ..settings.GetAt("ROWCOUNT")
		Set:tRowCount="" tRowCount = $G(tDefRowCount)
		If (tRowCount'="") {
			Set tPivot.rowAxisOptions.headEnabled = 1
			Set tPivot.rowAxisOptions.headCount = tRowCount
		}
		Set tColCount = ..settings.GetAt("COLCOUNT")
		Set:tColCount="" tColCount = $G(tDefColCount)
		If (tColCount'="") {
			Set tPivot.columnAxisOptions.headEnabled = 1
			Set tPivot.columnAxisOptions.headCount = tColCount
		}

		Set tRowOrder = ..settings.GetAt("ROWORDER")
		If (tRowOrder'="") {
			Set tPivot.rowAxisOptions.orderEnabled = 1
			Set tPivot.rowAxisOptions.orderExpression = tRowOrder
			Set tPivot.rowAxisOptions.orderDirection = ..settings.GetAt("ROWDIR")
		}
		Set tColOrder = ..settings.GetAt("COLORDER")
		If (tColOrder'="") {
			Set tPivot.columnAxisOptions.orderEnabled = 1
			Set tPivot.columnAxisOptions.orderExpression = tColOrder
			Set tPivot.columnAxisOptions.orderDirection = ..settings.GetAt("COLDIR")
		}

		// if needed, add a map to the frame
		If (tHasGeoListing) {
			Set tMap = ##class(%DeepSee.Component.mapView).%New()
			Set tMap.id = ..%MakeWidgetId("map")
			Set tMap.controllerId = tPivot.id
			Set tMap.isListing = 1
			If ('..previewMode) {
				Set tMap.onclickmarker = "zenPage.getComponent("_..index_").markerClicked(marker);"
			}
			Set tMap.zoom = 4
			Set tSC = pGroup.%AddChild(tMap)
			If $$$ISERR(tSC) Quit
			// JMD1210
			Set tMap.hidden = 0
		}

		// now place chart within the frame
		Set tChartClass = ""
		Set tSubtype = ..%definition.subtype
		If ((tSubtype = "")&&((..chartToggle="table")||(..chartToggle="chart"))) {
			Set tSubtype = "barChart"
		}

		If (tSubtype = "pieChart")||
			(tSubtype = "pieChart3D")||
			(tSubtype = "donutChart")||
			(tSubtype = "donutChart3D") {
			Set tChartClass = "%ZEN.SVGComponent.pieChart"
		}
		ElseIf (tSubtype = "treeMapChart") {
			Set tChartClass = "%ZEN.SVGComponent.treeMapChart"
		}
		ElseIf (tSubtype = "bullseyeChart") {
			Set tChartClass = "%ZEN.SVGComponent.bullseyeChart"
		}
		ElseIf (tSubtype = "comboChart") {
			Set tChartClass = "%ZEN.SVGComponent.comboChart"
		}
		ElseIf (tSubtype = "bubbleChart") {
			Set tChartClass = "%ZEN.SVGComponent.bubbleChart"
		}
		ElseIf (tSubtype = "lineChart")||
			(tSubtype = "lineChartMarkers")||
			(tSubtype = "areaChart") {
			Set tChartClass = "%ZEN.SVGComponent.lineChart"
			Set tPivot.maxChartSize = 0		// DTB384 - Remove limit for the chart size
		}
		ElseIf (tSubtype = "hilowChart") {
			Set tChartClass = "%ZEN.SVGComponent.hilowChart"
		}
		ElseIf (tSubtype = "xyChart") {
			Set tChartClass = "%ZEN.SVGComponent.xyChart"
		}
		ElseIf (tSubtype = "barChart")||
			(tSubtype = "barChartStacked")||
			(tSubtype = "barChart3D")||
			(tSubtype = "columnChart3D")||
			(tSubtype = "columnChartStacked")||
			(tSubtype = "columnChart") {
			Set tChartClass = "%ZEN.SVGComponent.barChart"
		}
		ElseIf (tSubtype = "timeChart") {
			Set tChartClass = "%ZEN.SVGComponent.comboChart"
			Set tPivot.maxChartSize = 0		// DTB384 - Remove limit for the chart size
		}
		ElseIf (tSubtype = "swirlChart") {
			Set tChartClass = "%ZEN.SVGComponent.swirlChart"
		}

		// override
		If $IsObject(tChartOverride)&&(tChartOverride."_type"'="") {
			// Assume all charts are in ZEN package!
			Set tChartClass = "%ZEN.SVGComponent." _ tChartOverride."_type"
			Set tSubtype = "override"
		}

		// JMD1202: always have some kind of chart on the page to make sure js/css is loaded
		If (tChartClass="") {
			Set tChartClass = "%ZEN.SVGComponent.lineChart"
		}

		If (tChartClass'="") {
			// add an SVG frame to the widget
			Set tSVGFrame = ##class(%ZEN.SVGComponent.svgFrame).%New()
			Set tSVGFrame.id = ..%MakeWidgetId("svgFrame")
			Set tSVGFrame.layout = "vertical"
			// added below

			Set tChart = $classmethod(tChartClass,"%New")
			Set tChart.id = ..%MakeWidgetId("svgChart")
			Set tChart.controllerId = tPivot.id
			Set tChart.appearance = "2D"

			// JMD1128: don't set selected style
			// Set tChart.selectedItemStyle = "fill: #FFEEAA;stroke:darkblue;stroke-width:0.1;stroke-opacity:0.5;"
			Set tChart.legendVisible = "false"

			// see if there are data series definitions
			Set tYAxisList = ""
			Set tMaxYAxis = 0	// max yAxis referred to
			Set tSeriesTypeList = ""
			Set tSeriesColors = ""
			Set tMarkers = "circle,up,down,square"
			Set tDSCount = ..%definition.dataSeries.Count()
			For d=1:1:tDSCount {
				Set tDataSeriesDef = ..%definition.dataSeries.GetAt(d)
				Set tSeriesTypeList = tSeriesTypeList _ $S(d>1:",",1:"") _ tDataSeriesDef.type
				Set tSeriesColors = tSeriesColors _ $S(d>1:",",1:"") _ tDataSeriesDef.color
				Set:tDataSeriesDef.markerShape'="" $P(tMarkers,",",d) = tDataSeriesDef.markerShape
				Set $P(tYAxisList,",",d) = +tDataSeriesDef.yAxisIndex
				Set tMaxYAxis = $S(tMaxYAxis>+tDataSeriesDef.yAxisIndex:tMaxYAxis,1:+tDataSeriesDef.yAxisIndex)
			}

			Set tChart.seriesColorsOverride = tSeriesColors
			If (tMarkers '= "circle,up,down,square") {
				Set tChart.markerShapes = tMarkers
				Set tChart.markersVisible = 1
				Set tChart.plotToEdge=0 // JSL4486
			}

			// modify appearance based on type
			If (tSubtype = "pieChart") {
			}
			ElseIf(tSubtype = "override") {
				// override is handled further on
			}
			ElseIf (tSubtype = "treeMapChart") {
				Set tHasTitle = ($G(tPValue("title"))'="")||(+$G(tPValue("showMultiples"),0))
			}
			ElseIf(tSubtype = "pieChart3D") {
				Set tChart.appearance = "3D"
			}
			ElseIf(tSubtype = "donutChart") {
				Set tChart.holeSize = 0.25
			}
			ElseIf(tSubtype = "donutChart3D") {
				Set tChart.appearance = "3D"
				Set tChart.holeSize = 0.25
			}
			ElseIf(tSubtype = "lineChart") {
				Set tChart.selectedItemStyle = "fill: none;stroke: red;"
			}
			ElseIf(tSubtype = "timeChart") {
				Set tChart.timeBased = 1
			}
			ElseIf(tSubtype = "bubbleChart") {
				If ('$G(tPValue("showQuadrant"),0)) {
					Set tChart.showQuadrant = 0
				}
				If ($G(tPValue("showRegression"),0)) {
					Set tChart.showRegression = 1
				}
			}
			ElseIf(tSubtype = "comboChart") {
				Set tChart.markerStyle = "fill: white;"
				Set tChart.seriesTypes = tSeriesTypeList

				If ($G(tPValue("stacked"),0)) {
					Set tChart.chartStacked = 1
				}
				If (tMaxYAxis>0) {
					Set tChart.seriesYAxes = tYAxisList
					// insert additional y-axes
					While (tChart.yAxisList.Count() <= tMaxYAxis) {
						Set tAxis = ##class(%ZEN.Auxiliary.axis).%New()
						Do:$IsObject($G(%page)) %page.%AddComponent(tAxis)
						Do tChart.yAxisList.Insert(tAxis)
					}
				}
			}
			ElseIf(tSubtype = "lineChartMarkers") {
				Set tChart.markersVisible = 1
				Set tChart.plotToEdge = 0 // JSL4486
				Set tChart.selectedItemStyle = "fill: none;stroke: red;stroke-width:0.1;"
			}
			ElseIf(tSubtype = "areaChart") {
				Set tChart.chartFilled = 1
				// JMD1063
				Set tChart.chartStacked = 1
				Set tChart.selectedItemStyle = "fill-opacity:0.5;stroke: red;stroke-width:0.1;"
			}
			ElseIf(tSubtype = "hilowChart") {
				Set tChart.selectedItemStyle = "fill: none;stroke: red;stroke-width:0.1;"
			}
			ElseIf(tSubtype = "xyChart") {
				Set tChart.selectedItemStyle = "fill: none;stroke: red;stroke-width:0.1;"
			}
			ElseIf(tSubtype = "barChart") {
				Set tChart.chartPivot = 1
			}
			ElseIf(tSubtype = "barChartStacked") {
				Set tChart.chartPivot = 1
				Set tChart.chartStacked = 1
			}
			ElseIf(tSubtype = "columnChart3D") {
				Set tChart.appearance = "3D"
			}
			ElseIf(tSubtype = "columnChartStacked") {
				Set tChart.chartStacked = 1
			}
			ElseIf(tSubtype = "columnChart") {
			}

			// apply additional widget properties
			Set tChart.title = $G(tPValue("title"))
			Set tChart.titleStyle = $G(tPValue("titleStyle"))

			If '$IsObject(tChart.xAxis) {
				Set tChart.xAxis = ##class(%ZEN.Auxiliary.axis).%New()
				Do:$IsObject($G(%page)) %page.%AddComponent(tChart.xAxis)
			}
			If ($G(tPValue("XgridLines"),0)) {
				Set tChart.xAxis.majorGridLines = 1
				Set tChart.xAxis.minorGridLines = 1
				Set tChart.plotAreaStyle = "stroke:black;fill:none;"

			}
			If (""'=$G(tPValue("labelStyle"))) {
				Set tChart.xAxis.labelStyle = ..%definition.properties.GetAt("labelStyle")
			}

			If (tChart.yAxisList.Count() = 0) {
				Set tAxis = ##class(%ZEN.Auxiliary.axis).%New()
				Do:$IsObject($G(%page)) %page.%AddComponent(tAxis)
				Do tChart.yAxisList.Insert(tAxis)
			}
			Set tAxis = tChart.yAxisList.GetAt(1)

			If ($G(tPValue("YgridLines"),0)) {
				Set tAxis.majorGridLines = 1
				Set tAxis.minorGridLines = 1
				Set tChart.plotAreaStyle = "stroke:black;fill:none;"
			}
			If (""'=$G(tPValue("labelStyle"))) {
				Set tAxis.labelStyle = ..%definition.properties.GetAt("labelStyle")
			}
			If ('$G(tPValue("hasZoom"),1)) {
				Set tChart.hasZoom = 0
			}
			If ('$G(tPValue("labels"),1)) {
				Set tChart.labelsVisible = 0
			}
			If (+$G(tPValue("valueLabels"),0)) {
				Set tChart.valueLabelsVisible = 1
			}
			If (+$G(tPValue("showPercentage"),0)) {
				If (tChart.%IsA("%ZEN.SVGComponent.pieChart")) {
					Set tChart.showPercentage = 1
				}
			}
			Set tChart.showMultiples = 0
			If (+$G(tPValue("showMultiples"),0)) {
				Set tChart.showMultiples = 1
			}

			Set ..legendPosition = "right"
			If ($G(tPValue("legendPos"))'="") {
				Set ..legendPosition = tPValue("legendPos")
				
			}

			// JSL4277
			If (tSubtype = "swirlChart") {
				
				Set tChart.separateSeriesScale=0
				If ($G(tPValue("separateSeriesScale"),0)) {
					Set tChart.separateSeriesScale = 1
				}
				
				Set tChart.invert=0
				If ($G(tPValue("invert"),0)) {
					Set tChart.invert = 1
				}
				Set tChart.gap=30
				If ($G(tPValue("gap"))'="") {
					Set tChart.gap = tPValue("gap")
				}

				Set tChart.plotBy="items"
				If ($G(tPValue("plotBy"))'="") {
					Set tChart.plotBy = tPValue("plotBy")
				}

			}
			
			// JMD1063: if no labels, make pie bigger!
			If ('..labelsVisible && tChart.%IsA("%ZEN.SVGComponent.pieChart")) {
				Set tChart.pieScale = 1.5
			}
			
			// JSL4272 - special case for swirlChart
			If (tChart.%IsA("%ZEN.SVGComponent.swirlChart")) {
				Set tChart.ongetLabelX = "return zenPage.getComponentById('"_..%MakeWidgetId("svgChart")_"').seriesNames.split(',')[value]"
				Set tChart.animate="none"
			}

			// JMD1201 apply theme properties
			If ($IsObject(tThemeChart)) {
				For p = 1:1:$L(..themeChartProperties,",") {
					Set tProp = $P(..themeChartProperties,",",p)
					Set tVal = $Property(tThemeChart,tProp)
					Set:tVal'="" $Property(tChart,tProp) = tVal
				}
			}
			
			// JMD1128 apply chart overrides
			If (tSubtype = "override") {
				// apply override properties
				Kill tOverArray
				Do tChartOverride.%CopyToArray(.tOverArray)
				Set p = $O(tOverArray(""))
				While (p'="") {
					If ($IsObject(tOverArray(p))) {
						If (p="xAxis") {
							If $IsObject(tChart.xAxis) {
								Set tAxis = tChart.xAxis
							}
							Else {
								Set tAxis = ##class(%ZEN.Auxiliary.axis).%New()
								Set tChart.xAxis = tAxis
							}

							Kill tAxisArray
							Do tOverArray(p).%CopyToArray(.tAxisArray)
							Set ap = $O(tAxisArray(""))
							While (ap'="") {
								If ($E(ap)'="_") {
									Set $Property(tAxis,ap) = tAxisArray(ap)
								}
								Set ap = $O(tAxisArray(ap))
							}
						}
						ElseIf (p="yAxisList") {
							Set tYaList = tOverArray(p)
							Do tChart.yAxisList.Clear()
							For ya=1:1:tYaList.Count() {
								Set tAxis = ##class(%ZEN.Auxiliary.axis).%New()
								Do:$IsObject($G(%page)) %page.%AddComponent(tAxis)
								Do tChart.yAxisList.Insert(tAxis)

								Kill tAxisArray
								Do tYaList.GetAt(ya).%CopyToArray(.tAxisArray)
								Set ap = $O(tAxisArray(""))
								While (ap'="") {
									If ($E(ap)'="_") {
										Set $Property(tAxis,ap) = tAxisArray(ap)
									}
									Set ap = $O(tAxisArray(ap))
								}
							}
						}
					}
					ElseIf ($E(p)'="_") {
						Set $Property(tChart,p) = tOverArray(p)
					}
					Set p = $O(tOverArray(p))
				}
			}

			Set ..labelsVisible = tChart.labelsVisible
			If (tChart.%IsA("%ZEN.SVGComponent.pieChart")) {
				// Set ..labelsVisible = 0
			}

			Set tChart.onelementClick = "zenPage.getComponent("_..index_").chartClickHandler(chart);"

			// JMD1128 (2) notification
			Set tChart.onrenderData = "zenPage.getComponent("_..index_").chartRenderHandler();"

			Do tSVGFrame.%AddChild(tChart)
			/// JMD1128 start chart hidden to speed up load
			Set tSVGFrame.hidden = 1
			Set tChart.hidden = 1

			// add time range controller
			Set tRange = ##class(%ZEN.SVGComponent.timeRangeControl).%New()
			Set tRange.id = ..%MakeWidgetId("rangeControl")
			Set tRange.hidden = 1
			Set tRange.width = tChart.width
			Set tRange.height = 40
			Set tRange.timeScale = "years"
			Set tRange.onchange = "zenPage.getComponent("_..index_").chartRangeChange(final);"
			Do tSVGFrame.%AddChild(tRange)

			// add an HTML chart legend
			Set tLegend = ""

			// JMD1128 - always add legend and set its position with client logic
			Set tLegend = ##class(%DeepSee.Component.chartLegend).%New()
			Set tLegend.id = ..%MakeWidgetId("chartLegend")
			Set tLegend.controllerId = tPivot.id
			Set tLegend.chartId = tChart.id
			If ((..legendPosition="top")||(..legendPosition="bottom")) {
				Set tLegend.orientation = "horizontal"
			}
			Set tLegend.legendPosition = ..legendPosition // JSL4144, will need to get legendPosition later	

			// legend overrides
			If $IsObject(tLegendOverride) {
				Kill tOverArray
				Do tLegendOverride.%CopyToArray(.tOverArray)
				Set p = $O(tOverArray(""))
				While (p'="") {
					If ($IsObject(tOverArray(p))) {
					}
					ElseIf ($E(p)'="_") {
						Set $Property(tLegend,p) = tOverArray(p)
					}
					Set p = $O(tOverArray(p))
				}
			}

			// pivot overrides
			If $IsObject(tPivotOverride) {
				Kill tOverArray
				Do tPivotOverride.%CopyToArray(.tOverArray)
				Set p = $O(tOverArray(""))
				While (p'="") {
					If ($IsObject(tOverArray(p))) {
					}
					ElseIf ($E(p)'="_") {
						Set $Property(tPivot,p) = tOverArray(p)
					}
					Set p = $O(tOverArray(p))
				}
			}

			//+JSL4486
			if tChart.markersVisible = 1 {
				Set tChart.plotToEdge = 0
			}
			//-JSL4486

			// JMD1259 check for termlist containing "data colors"
			// these map a data label to a color
			Set tHasDataColors = 0
			Set tTermList = ..%definition.dataColorList
			If (tTermList'="") {
				Set tTermList = $P(tTermList,".",1)
				Set tSC = ##class(%DeepSee.TermList).%GetValueArray(tTermList,.tArray)
				If $$$ISERR(tSC) Quit
				
				Set k = $O(tArray(""))
				While (k'="") {
					Set tHasDataColors = 1
					Do ..dataColors.SetAt(tArray(k),$$$LOWER(k))
					Set k = $O(tArray(k))
				}
			}

			If (tHasDataColors) {
				// JMD1259 use this to adjust series colors 
				Set tChart.ongetSeriesColor = "return zenPage.getComponent("_..index_").chartGetSeriesColor(series);"
			}

			Set ..hasDataColors = tHasDataColors
			
			// JMD1308 remember non-localized values
			Set ..origChartTitle = tChart.title
			Set ..origChartSubtitle = tChart.subtitle

			// JMD1118
			// JMD1270 (move to after overloads are processed, add more calls)
			Set tChart.title = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tChart.title)
			Set tChart.subtitle = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tChart.subtitle)
			If $IsObject(tChart.xAxis) {
				Set ..origChartXAxisTitle = tChart.xAxis.title
				Set tChart.xAxis.title = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tChart.xAxis.title)
			}
			For ya=1:1:tChart.yAxisList.Count() {
				Set tYAxis = tChart.yAxisList.GetAt(ya)
				If $IsObject(tYAxis) {
					Do ..origChartYAxisTitles.SetAt(tYAxis.title,ya)
					Set tYAxis.title = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tYAxis.title)
				}
			}
			
			If (tPivot.cubeName'="")&&'##class(%DeepSee.Utils).%IsCubeAvailable(tPivot.cubeName) {
				// DTB897 - Perform one last check to see if the user can see the cube data
				// If the cube is unavailable toggle back to the table to show the pivot's error message
				Set tPivot.hidden = 0
				Set ..pivotView = "table"
			}
			
			// add non-layout group to hold components and place components in it
			Set tGroup = ##class(%ZEN.Component.group).%New()
			Set tGroup.enclosingStyle = "position:relative;"
			Set tSC = pGroup.%AddChild(tGroup)
			If $$$ISERR(tSC) Quit

			Set tSC = tGroup.%AddChild(tSVGFrame)
			If $$$ISERR(tSC) Quit

			Set tSC = tGroup.%AddChild(tLegend)
			If $$$ISERR(tSC) Quit
			
			If ((..chartToggle="table")&&$IsObject(tLegend)) {
				Set tLegend.hidden = 1
			}
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
ESC(x)
	Set x = $Replace(x,",","\,")
	Set x = $Replace(x,":","\:")
	Quit x
}

/// Load the saved pivot information into the pivot table.
Method %LoadPivotInfo(pPivotName As %String, pPivotTable As %DeepSee.Component.pivotTable, pOverrideString As %String = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		
		// +DTB457 - get default values for widget properties
		Do ..%GetWidgetPropertyInfo(..subtype,.tList)
		Set n = $O(tList(""))
		While (n'="") {
			Set tName = $LG(tList(n),1)
			//Set tPValue(tName) = ..%definition.properties.GetAt(tName)
			Set tPValue(tName) = $S(..%definition.properties.%IsA("%Collection.AbstractArray"):..%definition.properties.GetAt(tName),1:"")
			Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
			Set n = $O(tList(n))
		}
		// -DTB457
		
		Set ..pivotName = pPivotName
		// JMD1139 reset
		Set pPivotTable.kpi = ""
		// JMD: prevent invalid OREF error!
		Do pPivotTable.formatRules.Clear()

		// open saved pivot
		Set tPivot = ""
		Set tKPIClass = ""
		If (pPivotName'="") {
			Set tExt = $P(pPivotName,".",$L(pPivotName,"."))
			If (tExt = "kpi") {
				Set tName = $P(pPivotName,".",1,$L(pPivotName,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			}
			ElseIf (tExt = "metric") {
				Set tKPIClass = "Ens.BusinessMetricKPI"
			}
			ElseIf (tExt = "worksheet") {
				Set tKPIClass = "%DeepSee.KPIWorksheet"
			}
			Else {
				Set tPivot = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pPivotName)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pPivotName,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If '$IsObject(tPivot) {
					// JMD1413: show this error in the pivot
					Set pPivotTable.%message = $$$FormatText($$$Text("Unable to find saved pivot '%1'","%DeepSee"),pPivotName)
				}
			}
		}

		If $IsObject(tPivot) {
			// copy information from the saved item to the graphical pivot
			Set tSC = tPivot.%CopyToComponent(pPivotTable)
			If $$$ISERR(tSC) Quit
			
			// +DTB218 - Apply overrides if they were provided
			If pOverrideString'="" {
				Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ConvertJSONToObject(pOverrideString,,.tOverrideOBJ)
				Do tOverrideOBJ.%CopyToArray(.tOverrides)
				
				Set tOverrideProp = $O(tOverrides(""),1,tOverride)
				While tOverrideProp'="" {
					If $IsObject(tOverride) {
					} ElseIf (tOverrideProp'["_") {
						Set $Property(pPivotTable,tOverrideProp) = tOverride
					}
					Set tOverrideProp = $O(tOverrides(tOverrideProp),1,tOverride)
				}
			}
			// -DTB218

			// JMD1025
			If (pPivotTable.autoExecute=0) {
				// JMD1202: revert
				// Set pPivotTable.initialExecute = 0
			}
		}
		ElseIf (tKPIClass'="") {
			Set pPivotTable.kpi = tKPIClass
			Set pPivotTable.pivotSelect = $G(tPValue("pivotSelect"))		// DTB457
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
	var svg = this.findComponent('svgFrame');
	var chart = this.findComponent('svgChart');
	var rangeControl = this.findComponent('rangeControl');
	var legend = this.findComponent('chartLegend');
	var pivot = this.findComponent('table');
	var map = this.findComponent('map');
	var dtree = this.findComponent('dtree');
	var resetIcon = this.findComponent('reset');
	var dtreeWrap = this.findComponent('dtreewrapper');
	
	if (svg) {
		var svgParentDiv = svg.parent.getEnclosingDiv();
	}
	
	var pwidth = width;
	if (this.pivotView == 'table') { // JSL4531 - check for chart
		if (svgParentDiv) {
			svgParentDiv.style.width = '0px';	
			svgParentDiv.style.height = '0px';	
		}
		this.setProperty('backgroundColor', this.backgroundColor); // JSL4483
		this.setProperty('opacity',this.opacity); // JSL4483
	} else if (this.pivotView == 'chart') { // JSL4531
		if (chart) {
			// DTB171 - Make sure the div containing the svgFrame and legend knows
			// the size of the content space!
			if (svgParentDiv) {
				svgParentDiv.style.width = width + 'px';	
				svgParentDiv.style.height = height + 'px';	
			}
			
			var attrs = chart.parseStyleSVG(chart.backgroundStyle); // JSL4531
			if (zenGet(attrs['opacity']) == '') {                 // JSL4531
				attrs['opacity'] = 1.0;                           // JSL4531
			}                                                     // JSL4531
			chart.setSeeThrough(attrs['opacity']);                 // JSL4531
		}
	}

	// adjust chart colors
	if (chart) {
		if (zenPage.chartSeriesScheme && zenPage.chartSeriesScheme!=='') {
			chart.seriesColorScheme = zenPage.chartSeriesScheme;
			chart.seriesColors = '';
		}
		if (zenPage.chartSeriesColors && zenPage.chartSeriesColors!=='') {
			chart.seriesColors = zenPage.chartSeriesColors;
		}
	}
	
	// make sure initial viewType is correct
	if (load && pivot.isDrillThrough) {
		this.viewType = 'listing';
	}

	// set sizes and visibility according to view type
	if (this.viewType == 'listing') {
		if (svg && svg.getEnclosingDiv()) {
			svg.setHidden(true);
		}
		if (chart) {
			chart.setProperty('hidden',true);
		}
		if (rangeControl) {
			rangeControl.setProperty('hidden',true);
		}
		if (legend && legend.getEnclosingDiv()) {
			legend.setHidden(true);
		}
		if (dtree && dtree.getEnclosingDiv()) {
			dtree.setHidden(true);
		}
		if (resetIcon && resetIcon.getEnclosingDiv()) {
			resetIcon.setHidden(true);
		}

		if (this.listingView == 'map') {
			pivot.listingType = 'map';
			pivot.setHidden(true);
			if (map) {
				var mapDiv = map.getEnclosingDiv();
				mapDiv.style.display = 'block';
				mapDiv.style.width = width-10 + 'px';
				mapDiv.style.height = height + 'px';
				map.adjustContentSize(load, width, height);
			}
		}
		else {
			// table
			if (pivot) {
				var pivotDiv = pivot.getEnclosingDiv();
				if (pivotDiv) {
					// JMD1021
					if (dtree && dtree.getEnclosingDiv() && this.showDimTree) {
						pwidth = width - dtree.getEnclosingDiv().offsetWidth;
					}
					pwidth = (pwidth<3) ? 3 : pwidth;
					pivotDiv.style.width = (pwidth-3) + 'px';
					pivotDiv.style.height = height + 'px';
					pivot.adjustTableLayout();
					if (dtreeWrap) {
						dtreeWrap.getEnclosingDiv().style.height = height + 'px';
						dtreeWrap.getEnclosingDiv().style.overflow = 'auto';
					}
				}
				pivot.listingType = 'table';
				pivot.setHidden(false);
			}

			// hide map
			if (map) {
				var mapDiv = map.getEnclosingDiv();
				if (mapDiv) {
					mapDiv.style.display = 'none';
				}
			}
		}
	}
	else {
		// viewType: pivot
		// hide map
		if (map) {
			var mapDiv = map.getEnclosingDiv();
			if (mapDiv) {
				mapDiv.style.display = 'none';
			}
		}

		if (this.pivotView == 'table') {
			if (svg && svg.getEnclosingDiv()) {
				svg.setHidden(true);
			}
			if (chart) {
				chart.setProperty('hidden',true);
			}
			if (rangeControl) {
				rangeControl.setProperty('hidden',true);
			}
			if (legend && legend.getEnclosingDiv()) {
				legend.setHidden(true);
			}
			if (dtree && dtree.getEnclosingDiv()) {
				dtree.setHidden(this.showDimTree ? false : true);
			}
			if (resetIcon && resetIcon.getEnclosingDiv()) {
				resetIcon.setHidden(this.showDimTree ? false : true);
			}
			if (pivot) {
				pivot.listingType = 'table';
				pivot.setHidden(false);
				var pivotDiv = pivot.getEnclosingDiv();
				if (pivotDiv) {
					// JMD1021
					if (dtree && dtree.getEnclosingDiv() && this.showDimTree) {
						pwidth = width - dtree.getEnclosingDiv().offsetWidth;
					}
					pwidth = (pwidth<3) ? 3 : pwidth;
					pivotDiv.style.width = (pwidth-3) + 'px';
					pivotDiv.style.height = height + 'px';
					pivot.adjustTableLayout();
					if (dtreeWrap) {
						dtreeWrap.getEnclosingDiv().style.height = height + 'px';
						dtreeWrap.getEnclosingDiv().style.overflow = 'auto';
					}
				}
			}
		}
		else {
			// chart
			if (pivot) {
				pivot.listingType = 'table';
				pivot.setHidden(true);
			}
			if (dtree && dtree.getEnclosingDiv()) {
				dtree.setHidden(true);
			}
			if (resetIcon && resetIcon.getEnclosingDiv()) {
				resetIcon.setHidden(true);
			}

			if (svg) {
				var legwid = 0;
				var leghgt = 0;
				if (legend) {
					var legendDiv = legend.getEnclosingDiv();
					if (legendDiv) {
						// DTB171 - Position the legend and use knowledge of the border to properly size it.
						// If height or width is not defined, default to 20%
						var legendAttrs = legend.parseStyleSVG(legend.legendStyle);
						legendDiv.style.position = 'absolute';
						legend.setHidden(this.legendPosition=='none' || this.legendPosition=='');
						switch(this.legendPosition) {
						case 'top':
							var borderWidth = parseInt(legendDiv.style.borderBottomWidth,10) + parseInt(legendDiv.style.borderTopWidth,10);
							borderWidth = !isNaN(borderWidth) ? borderWidth : 2;
							legendDiv.style.height = (legendAttrs['height']) ? legendAttrs['height'] : '20%';
							leghgt = legendDiv.offsetHeight;
							legendDiv.style.top = 0 + 'px';
							legendDiv.style.left = 0 + 'px';
							legendDiv.style.width = ((width>borderWidth)?(width - borderWidth):0) + 'px';
							break;
						case 'bottom':
							var borderWidth = parseInt(legendDiv.style.borderBottomWidth,10) + parseInt(legendDiv.style.borderTopWidth,10);
							borderWidth = !isNaN(borderWidth) ? borderWidth : 2;
							legendDiv.style.height = (legendAttrs['height']) ? legendAttrs['height'] : '20%';
							leghgt = legendDiv.offsetHeight;
							legendDiv.style.top = ((height>leghgt)?(height-leghgt):0) + 'px';
							legendDiv.style.left = 0 + 'px';
							legendDiv.style.width = ((width>borderWidth)?(width - borderWidth):0) + 'px';
							break;
						case 'left':
							var borderHeight = parseInt(legendDiv.style.borderBottomWidth,10) + parseInt(legendDiv.style.borderTopWidth,10);
							borderHeight = !isNaN(borderHeight) ? borderHeight : 2;
							legendDiv.style.width = (legendAttrs['width']) ? legendAttrs['width'] : '20%';
							legwid = legendDiv.offsetWidth;
							legendDiv.style.top = 0 + 'px';
							legendDiv.style.left = 0 + 'px';
							legendDiv.style.height = ((height>borderHeight)?(height-borderHeight):0) + 'px';
							break;
						case 'right':
							var borderHeight = parseInt(legendDiv.style.borderBottomWidth,10) + parseInt(legendDiv.style.borderTopWidth,10);
							borderHeight = !isNaN(borderHeight) ? borderHeight : 2;
							legendDiv.style.width = (legendAttrs['width']) ? legendAttrs['width'] : '20%';
							legendDiv.style.top = 0 + 'px';
							legwid = legendDiv.offsetWidth;
							legendDiv.style.left = ((width>legwid)?(width-legwid):0) + 'px';
							legendDiv.style.height = ((height>borderHeight)?(height-borderHeight):0) + 'px';
							break;
						}
					}
				}

				// adjust size of svg frame
				//var svgWid = width - legwid - 4;
				//var svgHgt = height - leghgt - 2;
				var svgWid = width - legwid;
				var svgHgt = height - leghgt;
				svgWid = (svgWid < 1) ? 1 : svgWid;
				svgHgt = (svgHgt < 1) ? 1 : svgHgt;
				var svgDiv = svg.getEnclosingDiv();
				if (svgDiv) {
					svgDiv.style.position = 'absolute';
					switch(this.legendPosition) {
					case 'top':
						svgDiv.style.top = leghgt + 'px';
						svgDiv.style.left = 0 + 'px';
						break;
					case 'left':
						svgDiv.style.top = 0 + 'px';
						svgDiv.style.left = legwid + 'px';
						break;
					case 'bottom':
					case 'right':
					default:
						svgDiv.style.top = 0 + 'px';
						svgDiv.style.left = 0 + 'px';
						break;
					}

					// JMD1206
					// show chart before showing svgFrame
					if (chart && chart.hidden) {
						chart.setProperty('hidden',false);
					}

					if (svg.hidden) {
						svg.setHidden(false);
					}
					if (svgWid != svg.width) {
						svg.setProperty("width",svgWid+'px');
					}
					if (svgHgt != svg.height) {
						svg.setProperty("height",svgHgt+'px');
					}
				}

				// adjust chart & rangeControl
				if (chart) {
					var timeBased = chart.isTimeBased()
					if (rangeControl) {
						if (svgWid != rangeControl.width) {
							rangeControl.setProperty("width",svgWid);
							rangeControl.render();
						}
						if (rangeControl.hidden != !timeBased) {
							rangeControl.setProperty('hidden',!timeBased);
						}
					}

					var rangeHeight = timeBased ? (rangeControl?parseInt(rangeControl.height):0) : 0;
					var chartHgt = svgHgt - rangeHeight;
					if (svgWid != chart.width || chartHgt != chart.height) {
						// consolidate calls
						// JMD1261 (be more careful about this)
						if (svgWid != chart.width) {
							chart.height = chartHgt;
							chart.setProperty("width",svgWid);
						}
						else {
							chart.setProperty("height",svgHgt);
						}
					}
					if (chart.hidden) {
						chart.setProperty('hidden',false);
					}

					// jmd: if chart is too small, supress labels
					if ((svgWid < 150 || chartHgt < 150)) {
						chart.setProperty('labelsVisible',false);
					}
					else {
						chart.setProperty('labelsVisible',this.labelsVisible);
					}
				}
			}
		}
	}
}

/// Perform a showListing action, if supported.
ClientMethod showListing(listing) [ Language = javascript ]
{
	var pivot = this.getDataController();
	if (!pivot) {
		return;
	}

	if (this.viewType == 'listing' && this.listingView == 'table') {
		// turn off listing
		pivot.setListing(listing,'table');
		if (pivot.setDrillThrough(false)) {
			this.viewType = 'table';
		}
	}
	else {
		// show listing
		if (!pivot.canDrillThrough()) {
			alert($$$Text('This pivot does not support listings.','%DeepSee'));
			return;
		}

		pivot.setListing(listing,'table');
		if (pivot.setDrillThrough(true, true)) {
			this.viewType = 'listing'
		}
		this.listingView = 'table';
	}

	this.adjustSizes(false);
	// JMD1484 force chart update for IE!
	if (zenIsIE && (this.pivotView=='chart')) {
		var chart = this.findComponent('svgChart');
		if (chart) {
			chart.renderContents();
		}
	}
	
	// DTB813 - introduce a timer to disable the listing control briefly and prevent
	// a double-click issuing two different queries/reloads  
	for (var n = 0; n < this.controlIndices.length; n++) {
		var control = zenPage.getComponent(this.controlIndices[n]);
		if ((control && ('showListing'==control.name))&&(setTimeout)) {
			control.setDisabled(true);
			setTimeout(this.componentSetDisabled, 500, control.id, false);		//  DTB841 - Call the new clientMethod
		}
	}
	
	this.updateControlState();
}

/// Perform a showGeoListing action.
ClientMethod showGeoListing(listing) [ Language = javascript ]
{
	var pivot = this.getDataController();
	if (!pivot) {
		return;
	}

	if (this.viewType == 'listing' && this.listingView == 'map') {
		// turn off listing
		pivot.setListing(listing,'table');
		if (pivot.setDrillThrough(false)) {
			this.viewType = 'table'
		}
	}
	else {
		// show listing
		if (!pivot.canDrillThrough()) {
			alert($$$Text('This pivot does not support listings.','%DeepSee'));
			return;
		}

		pivot.setListing(listing,'map');
		if (pivot.setDrillThrough(true,true)) {
			this.viewType = 'listing'
		}
		this.listingView = 'map';
	}

	this.adjustSizes(false);
	this.updateControlState();
}

/// Perform a showDimensions action, if supported. This toggles the visibility
/// of the dimensions tree control
ClientMethod showDimensions() [ Language = javascript ]
{
	if (!this.hasDimTree) {
		return;
	}
	var pivot = this.getDataController();
	if (!pivot) {
		return;
	}

	if (this.viewType == 'listing' && this.listingView == 'table') {
		// turn off listing
		pivot.setListing('','table');
		if (pivot.setDrillThrough(false)) {
			this.viewType = 'table'
		}
	}

	this.showDimTree = !this.showDimTree;
	this.adjustSizes(false);
	this.updateControlState();
}

/// Launch the pivot analysis dialog.
ClientMethod showBreakdown(analysisClass) [ Language = javascript ]
{
	var pivot = this.getDataController();
	if ('' == pivot.selectedRange) {
		alert($$$Text('Please select a cell to display a breakdown for.','%DeepSee'));
		return false;
	}

	// get WITH clause for local calc members
	var tWITH = '';
	for (var n = 0; n < pivot.calculatedMembers.length; n++) {
		var mbr = pivot.calculatedMembers[n];
		if (mbr.dimension!='' && mbr.memberName!='') {
			var dim = mbr.dimension.toString();
			var name = mbr.memberName.toString();
			dim = (dim.charAt(0)=='[') ? dim.substr(1,dim.length-2) : dim;
			name = (name.charAt(0)=='[') ? name.substr(1,name.length-2) : name;
			tWITH += " MEMBER ["+dim+"].["+name+"] AS \'" + mbr.valueExpression + "\'";
		}
	}

	var msr = '';
	if (pivot.measures.length > 0) {
		msr = pivot.measures[0].spec;
	}

	var parms = {
			CUBE:pivot.cubeName,
			KEY:pivot.queryKey,
			WITH:tWITH,
			MEASURE:msr,
			RANGE:pivot.selectedRange
			};

	if ((analysisClass == null) || (analysisClass == '')) {
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotAnalysis.zen','BreakDown','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
	else {
		zenLaunchPopupWindow(analysisClass,'BreakDown','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
}

/// If this widget contains a data controller, return it.
ClientMethod getDataController() [ Language = javascript ]
{
	return this.findComponent('table');
}

/// If this widget contains a data controller, return it.
Method %GetDataController() As %ZEN.Auxiliary.abstractController
{
	Quit ..%FindComponent("table")
}

/// Select element handler for pivot chart.
ClientMethod chartClickHandler(chart) [ Language = javascript ]
{
	var controller = this.getDataController();
	var series = chart.getSelectedSeries();
	var item = chart.getSelectedItem();

	// find the filters that correspond to this item
	// DTB653 - Only if there is a selection!
	if ((series>(-1)) && (item>(-1))) {
		this.currFilterSpec = controller.getFilterForCells(item+1,series+1);
	}
	else {
		this.currFilterSpec = "";
	}

	this.currItemNo = parseInt(item) + 1;
	this.currSeriesNo = parseInt(series) + 1;

	// find value of the item
	// value
	this.currValueName = 'Value';
	this.currValue = '';
	if (controller && controller.getValueName) {
		this.currValueName = controller.getValueName();
	}
	var data = chart.getSeriesData(series);
	if (data && null != data[item]) {
		this.currValue = data[item];
	}

	// select corresponding cells in pivot
	if (controller && controller.selectCellRange) {
		controller.selectCellRange(this.currItemNo,this.currSeriesNo,this.currItemNo,this.currSeriesNo);
	}

	this.updateControlState();
	this.raiseEventHandler('click');
}

/// Drill state change handler for pivot table.
ClientMethod drillHandler(pivot) [ Language = javascript ]
{
	// notify slaves
	if (zenPage.getSlaveList) {
		var slaves = zenPage.getSlaveList(this);
		for (var n = 0; n < slaves.length; n++) {
			slaves[n].syncSlave(this,true);
		}
	}
	// JMD1032: re-execute so that any filters are reapplied
	var table = this.getDataController();
	if (!table) return false;
	
	var div = this.getEnclosingDiv();

	// JMD1268-remove excess updates
	this.applyFilters(false);
	table.executeQuery(true);

	this.updateControlState();
	return true;
}

/// Listing select handler for pivot table.
ClientMethod listingSelectHandler(pivot) [ Language = javascript ]
{
	this.updateControlState();
}

/// Cell click handler for pivot table.
ClientMethod cellClickHandler(pivot) [ Language = javascript ]
{
	// reset curr values
	this.currItemNo = '';
	this.currSeriesNo = '';
	this.currFilterSpec = '';

	// set wait state and invoke actual logic
	this._targetPivot = pivot;
	window.setTimeout('zenPage.getComponent('+this.index+').realCellClickHandler();',1);
	pivot.showMessage($$$Text('Working...'),'');
}

/// Cell click handler for pivot table.
ClientMethod realCellClickHandler() [ Language = javascript ]
{
	var pivot = this._targetPivot;
	pivot.hideMessage();

	// reset curr values
	this.currItemNo = '';
	this.currSeriesNo = '';
	this.currFilterSpec = '';

	var controller = this.getDataController();
	if (pivot.selectedRange && '' !== pivot.selectedRange) {
		var p = pivot.selectedRange.toString().split(',');
		this.currItemNo = (null!=p[0]) ? parseInt(p[0]) : '';
		this.currSeriesNo = (null!=p[1]) ? parseInt(p[1]) : '';

		// find the filters that correspond to this range
		this.currFilterSpec = controller.getFilterForCells(p[0],p[1],p[2],p[3],zenGet(p[4]),zenGet(p[5]));
	}

	// find value of the item
	// value
	this.currValueName = 'Value';
	this.currValue = '';
	if (p && controller && controller.getValueName) {
		this.currValueName = controller.getValueName();
		var data = controller.getDataAsArrays();
		if (data && null != data[p[1]-1]) {
			this.currValue = data[p[1]-1][p[0]-1];
		}
	}
	this.updateControlState();
	this.raiseEventHandler('click');
}

/// Update the display current controls for this widget.
ClientMethod updateControlState() [ Internal, Language = javascript ]
{
	var pivot = this.getDataController();

	// set state of listing button(s)
	for (var n = 0; n < this.controlIndices.length; n++) {
		var control = zenPage.getComponent(this.controlIndices[n]);
		if (zenPage.activeWhenArray && control && control.aux && zenPage.activeWhenArray[control.aux]) {
			var activeWhen = zenPage.activeWhenArray[control.aux];
			switch (activeWhen) {
			case 'itemSelected':
				var isPivot = true;
				if (this.viewType != 'pivot' && this.viewType != 'table') {
					isPivot = false;
				}
				control.setDisabled(!isPivot || !pivot.getSelectedRange());
				break;
			case 'listingSelected':
				var isListing = true;

				if (this.viewType != 'listing') {
					isListing = false;
				}
				control.setDisabled(!isListing || pivot.getSelectedItems().length==0);
				break;
			case 'listingSelected1':
				var isListing = true;

				if (this.viewType != 'listing') {
					isListing = false;
				}
				control.setDisabled(!isListing || pivot.getSelectedItems().length!=1);
				break;
			default:
				control.setDisabled(false);
				break;
			}

			// update style
			if (control.disabled && control.controlClass == 'dsActionButton') {
				control.setProperty('controlClass','dsActionButtonDisabled');
			}
			else if (!control.disabled && control.controlClass == 'dsActionButtonDisabled') {
				control.setProperty('controlClass','dsActionButton');
			}
		}

		if (control && ('showListing'==control.name)) {
			var msgShow = $$$Text('Show detail listing','%DeepSee');
			var msgHide = $$$Text('Hide detail listing','%DeepSee');

			if ((this.viewType == 'listing') && (this.listingView == 'table')) {
				setTimeout(this.componentSetDisabled,500, control.id, false);		// DTB841 - Call the new clientMethod
				if (control.src=='deepsee/ds2_binoculars_44.png') {
					control.setProperty('src','deepsee/ds2_dialpad_44.png');
				}
				// if user has overridden string don't change tooltip
				if (!control.title || control.title == msgShow || control.title == msgHide) {
					control.setProperty('title',msgHide);
				}
			}
			else {
				if (control.src=='deepsee/ds2_dialpad_44.png') {
					control.setProperty('src','deepsee/ds2_binoculars_44.png');
				}
				if (!control.title || control.title == msgShow || control.title == msgHide) {
					control.setProperty('title',msgShow);
				}
			}
		}
		else if (control && control.name == 'showGeoListing') {
			var msgShow = $$$Text('Show map listing','%DeepSee');
			var msgHide = $$$Text('Hide map listing','%DeepSee');
			if (this.viewType == 'listing' && this.listingView == 'map') {
				control.setProperty('src','deepsee/ds2_dialpad_44.png');
				if (!control.title || control.title == msgShow || control.title == msgHide) {
					control.setProperty('title',msgHide);
				}
			}
			else {
				control.setProperty('src','deepsee/ds2_planet_44.png');
				if (!control.title || control.title == msgShow || control.title == msgHide) {
					control.setProperty('title',msgShow);
				}
			}
		}
	}

	// set state of chart toggle, if present
	var toggle = zen(this.id + '_chartToggle');
	if (toggle) {
		if (this.pivotView == 'chart') {
			toggle.setProperty('src','deepsee/ds2_list_44.png');
		}
		else {
			toggle.setProperty('src','deepsee/ds2_linechart_44.png');
		}
	}

	// set state of dimension toggle, if present
	var toggle = zen(this.id + '_showDimensions');
	if (toggle) {
		// JMD gray out in chart mode
		if (this.pivotView == 'chart') {
			toggle.setProperty('controlStyle','opacity:0.5;');
		}
		else {
			toggle.setProperty('controlStyle','');
		}
	}

	// refresh drill down control, if present
	var dd = zen(this.id + '_drillDown');
	if (dd) {
		dd.render();
	}
}

/// Toggle between chart and table view.
ClientMethod toggleChart() [ Internal, Language = javascript ]
{
	var pivot = this.getDataController();
	var svg = this.findComponent('svgFrame');
	var chart = this.findComponent('svgChart');
	var legend = this.findComponent('chartLegend');

	if (this.pivotView == 'chart') {
		// show table
		this.pivotView = 'table';
		this.viewType = 'pivot';		// DTB113
		pivot.listingType = 'table';	// DTB113
		
		// DTB113 - turn off listing when toggling 
		pivot.setDrillThrough(false, true);
	}
	else {
		// show chart
		this.pivotView = 'chart';
		this.viewType = 'pivot';
		pivot.listingType = 'table';

		// turn off listing when chart is shown
		pivot.setDrillThrough(false, true);

		if (chart) {
			// make selection in chart match pivot
			var range = pivot.selectedRange;
			if ('' == range) {
				chart.selectElement(-1,-1);
			}
			else {
				var r = range.toString().split(',');
				chart.selectElement(parseInt(r[1])-1,parseInt(r[0])-1);
			}
		}
		if (legend) {
			// give chart time to render!
			self.setTimeout("zenPage.getComponent("+legend.index+").renderContents()",10);
		}
	}
	this.adjustSizes(false);
	this.updateControlState();
}

/// Export current query to excel
ClientMethod exportExcel() [ Language = javascript ]
{
	var table = this.getDataController();
	var widgetDef = this.getDefinition();
	
	if (table && widgetDef) { // JSL4455 - use dashboard filter label name if available
		for (m=0; m < widgetDef.controls.length; m++) {
			var control = widgetDef.controls[m];
			if (control.action == 'applyFilter')  { // at filter control
				for (var n = 0; n < table.filters.length; n++) { // walk filters look for a match
					var filter = table.filters[n];
					if (control.label && control.targetProperty == filter.baseSpec) {
						filter._label = control.label;
					}
				}		
			}
		}
	}

	if (''!==table.kpi) {
		// get filter values
		var filterNames = [];
		var filterValues = [];
		var filterLabels = []; // JSL4455

		var fq = '';
		for (var n = 0; n < table.filters.length; n++) {
			var filter = table.filters[n];
			// + DTB796 - Shorten each of these by using a nonce
			var pnonce = zenPage.CreateParameterNonce(filter.spec+':'+filter.value);
			if (pnonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(pnonce);
				return;
			}
			fq += '&FILTER='+pnonce;
			// - DTB796
			if (filter.text!='') {
				filterNames[filterNames.length] = this.GetKpiFilterCaption(this.dataSource,filter.spec);		// DTB367
				var val = filter.text.toString();
				// unquote
				if ('&'==val.charAt(0)) {
					val = val.substring(2,val.length-1);
				}
				filterValues[filterValues.length] = val;
				filterLabels[filterLabels.length] = filter._label; // JSL4455
			}
		}
		
		table.getPivotVariableInfo(filterNames,filterValues);		// DTB489 - Use common API to fill in pivot variable info
		
		var cl = '';
		if (table.columnList!=='') {
			cl = '&COLUMNLIST=' + encodeURIComponent(table.columnList);
		}

		var url = zenLink('_DeepSee.UI.MDXExcel.zen?KPI=' + encodeURIComponent(table.kpi) + '&SOURCE='+ encodeURIComponent(table.dataSourceName) + fq + cl);
		if (filterNames.length > 0) {
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce(filterNames.join('\n'));		// DTB916
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce(filterValues.join('\n'));		// DTB797
			url += '&FILTERLABELS='+zenPage.CreateParameterNonce(filterLabels.join('\n')); // JSL4455	// DTB916
		}
		// + WAL239
		url += '&ROWCAPTIONS='+encodeURIComponent(table.getRowCaptions().join('\n'));
		// - WAL239
		// + WAL175
		if (table.hiddenMeasureText && table.hiddenMeasureText.length > 0) {
			url += '&HIDDENMEASURES='+encodeURIComponent(table.hiddenMeasureText.join('\n'));
		}
		if (table.measureLocation) {
			url += '&MEASURELOCATION='+encodeURIComponent(table.measureLocation);
		}
		// - WAL175

		// + DTB830 - Set defaults from the original table, then override with the current widget settings if they exist
		// DP-414476 - If print properties are not defined to set the export title, use the widget's title as the default.
		var title = (widgetDef.title ? widgetDef.title : table.printTitle);
		var subtitle = table.printSubtitle;
		var showDate = table.showDate;
		if (widgetDef && widgetDef.properties) {
			if (widgetDef.properties.printTitle) {
				title = widgetDef.properties.printTitle;
			}
			if (widgetDef.properties.printSubtitle) {
				subtitle = widgetDef.properties.printSubtitle;
			}
			if (widgetDef.properties.printSubtitle) {
				showDate = widgetDef.properties.showDate;
			}
		}
		// - DTB830
		
		url += '&TITLE='+encodeURIComponent(title);
		url += '&SUBTITLE='+encodeURIComponent(subtitle);
		url += '&SHOWDATE='+encodeURIComponent(showDate);	// DTB830

		// test for listing
		if (table.isDrillThrough) {
			url += '&LISTING=1';

			// JMD1332: preserve selection information
			url += '&SELECTEDRANGE='+encodeURIComponent(table.getSelectedRange()); 
			url += '&SELECTEDITEMS='+zenPage.CreateParameterNonce(table.getSelectedItems().toString());		// DTB916
			url += '&LISTINGSORTCOLUMN='+encodeURIComponent(table.listingSortColumn);
			url += '&LISTINGSORTDIR='+encodeURIComponent(table.listingSortDir);
		}
		
		window.open(url,'excel','');
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		var filterNames = [];
		var filterValues = [];
		var filterLabels = []; // JSL4455
		table.getFilterInfo(filterNames, filterValues, filterLabels);		// DTB551 - Retrieve labels through the method
		table.getPivotVariableInfo(filterNames,filterValues);		// DTB489 - Use common API to fill in pivot variable info

		var nonce = '';
		// WAL023 -- use resolved text
		var mdx = table.GetCurrentQueryText("resolved");  // WAL075 -- use getter method
		if (mdx.toString().length > 500) {
			// avoid long urls for IE!
			nonce = zenPage.CreateQueryNonce(mdx);
			if (nonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(nonce);
				return;
			}
		}
		if (nonce) {
			var url = '_DeepSee.UI.MDXExcel.zen?NONCE=' + encodeURIComponent(nonce);
		}
		else {
			var url = '_DeepSee.UI.MDXExcel.zen?MDX=' + encodeURIComponent(mdx);
		}

		if (table.listing!='') {
			url += '&LISTINGNAME='+encodeURIComponent(table.listing);
		}

		// JMD1029
		if (table.rowTotals) {
			url += '&ROWTOTALS=1';
		}
		if (table.columnTotals) {
			url += '&COLUMNTOTALS=1';
		}
		if (table.rowTotalAgg!='') {
			url += '&ROWTOTALAGG=' + table.rowTotalAgg;
		}
		if (table.columnTotalAgg!='') {
			url += '&COLUMNTOTALAGG=' + table.columnTotalAgg;
		}

		if (filterNames.length > 0) {
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce(filterNames.join('\n'));		// DTB916
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce(filterValues.join('\n'));		// DTB797
			url += '&FILTERLABELS='+zenPage.CreateParameterNonce(filterLabels.join('\n')); // JSL4455	// DTB916
		}
		// + WAL239 -- include row captions
		url += '&ROWCAPTIONS='+encodeURIComponent(table.getRowCaptions().join('\n'));
		// - WAL239
		// + DTB784
		if (table.hiddenMeasureText && table.hiddenMeasureText.length > 0) {
			url += '&HIDDENMEASURES='+encodeURIComponent(table.hiddenMeasureText.join('\n'));
		}
		if (table.measureLocation) {
			url += '&MEASURELOCATION='+encodeURIComponent(table.measureLocation);
		}
		// - DTB784

		// + DTB830 - Set defaults from the original table, then override with the current widget settings if they exist
		// DP-414476 - If print properties are not defined to set the export title, use the widget's title as the default.
		var title = (widgetDef.title ? widgetDef.title : table.printTitle);
		var subtitle = table.printSubtitle;
		var showDate = table.showDate;
		if (widgetDef && widgetDef.properties) {
			if (widgetDef.properties.printTitle) {
				title = widgetDef.properties.printTitle;
			}
			if (widgetDef.properties.printSubtitle) {
				subtitle = widgetDef.properties.printSubtitle;
			}
			if (widgetDef.properties.printSubtitle) {
				showDate = widgetDef.properties.showDate;
			}
		}
		// - DTB830

		url += '&TITLE='+encodeURIComponent(title);
		url += '&SUBTITLE='+encodeURIComponent(subtitle);
		url += '&SHOWDATE='+encodeURIComponent(showDate);		// DTB830

		window.open(url,'excel','');
	}
}

/// Export current query to a CSV file
ClientMethod exportCSV(simple) [ Language = javascript ]
{
	// Method implemented by DP-402897
	var table = this.getDataController();
	
	if (table) {
		var csvUtil = zenPage.getComponentById('csvUtil');
		var mdx = table.GetCurrentQueryText('export');
		var exportParams = csvUtil.prepareTableParms(table);
		
		// At this moment we only have the saved pivot table print settings
		// in the exportParams. This is where the specific *widget* print settings need 
		// to be set.
		// Filters (including drillthrough) have been processed by this point.
		var widgetDef = this.getDefinition();

		if (widgetDef) {
			// DP-414476 - If print properties are not defined to set the export title, use the widget's title
			// as the default.
			if (widgetDef.title) {
				exportParams.title = widgetDef.title;
			}
			if (widgetDef.properties) {
				if (widgetDef.properties.printTitle) {
					exportParams.title = widgetDef.properties.printTitle;
				}
				if (widgetDef.properties.printSubtitle) {
					exportParams.subtitle = widgetDef.properties.printSubtitle;
				}
				if (widgetDef.properties.printSubtitleOn) {
					exportParams.subtitleOn = widgetDef.properties.printSubtitleOn;
				}
				if (widgetDef.properties.showUser) {
					exportParams.showUser = widgetDef.properties.showUser;
				}
				if (widgetDef.properties.showDate) {
					exportParams.showDate = widgetDef.properties.showDate;
				}
				if (widgetDef.properties.showFilters) {
					exportParams.showFilters = widgetDef.properties.showFilters;
				}
				if (widgetDef.properties.showListingFilters) {
					exportParams.showListingFilters = widgetDef.properties.showListingFilters;
				}
			}
		}
		exportParams.simple = (simple ? 1 : 0)
		
		csvUtil.downloadCSV(mdx,exportParams);
	}
}

/// Export current query to pdf.
/// If we are in chart mode, export the chart.
ClientMethod exportPDF(printMultiple, preserveTempFiles, filename) [ Language = javascript ]
{
	var url = '';
	var parms = {};
	var filters = [];
	var isMasterWidget = this.isMasterWidget(this.id);	// DTB252 - check to see if the page settings are expected from this widget
	printMultiple = (printMultiple) ? printMultiple : false;				// DTB251 - For multi-tab browser display
	preserveTempFiles = (((preserveTempFiles) ? preserveTempFiles : false)||zenPage.pdfPreserveTempFiles);	// DTB251 - For merging into a single PDF		// DTB810 - Read the current temp file preserve setting
	
	var table = this.getDataController();
	// pull print settings from widgetDef.properties;
	var widgetDef = this.getDefinition();
	
	// +DTB551 - Add JS4455 preparation logic to PDF export
	if (table && widgetDef) {
		for (m=0; m < widgetDef.controls.length; m++) {
			var control = widgetDef.controls[m];
			if (control.action == 'applyFilter')  { // at filter control
				for (var n = 0; n < table.filters.length; n++) { // walk filters look for a match
					var filter = table.filters[n];
					if (control.label && control.targetProperty == filter.baseSpec) {
						filter._label = control.label;
					}
				}		
			}
		}
	}
	// -DTB551

	if (''!==table.kpi) {
		// get filter values
		var filterNames = [];
		var filterValues = [];
		var kpi_filter_string="";

		for (var n = 0; n < table.filters.length; n++) {
			var filter = table.filters[n];
			if (filter.value==""){
				continue;
			}
			kpi_filter_string += "&FILTER="+ zenPage.CreateParameterNonce(encodeURIComponent(this.GetKpiFilterCaption(this.dataSource,filter.spec))+":"+encodeURIComponent(filter.spec)+":"+filter.value);

			if (filter.text!='') {
				filterNames[filterNames.length] = this.GetKpiFilterCaption(this.dataSource,filter.spec);		// DTB386
				var val = filter.text.toString();
				// unquote
				if ('&'==val.charAt(0)) {
					val = val.substring(2,val.length-1);
				}
				filterValues[filterValues.length] = val;
			}
		}
		for (prop in table.pivotVariables) { // JSL4376
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}

		if (table.columnList!=='') {
			parms.COLUMNLIST = table.columnList;
		}

		url = '_DeepSee.UI.MDXPDF.zen'
		parms.KPI = table.kpi;
		parms.SOURCE = table.dataSourceName;

		// test for listing
		if (table.isDrillThrough) {
			url += '?LISTING=1';
		}
	}
	else {
		// get filter values - JSL4182 //APV103 - Move this section up into the 'else' case
		var filterNames = [];
		var filterValues = [];
		table.getFilterInfo(filterNames,filterValues);
		for (prop in table.pivotVariables) { // JSL4376
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}

		// WAL023 -- use resolved text
		var mdx = table.GetCurrentQueryText("resolved");  // WAL075 -- use getter method

		var nonce = '';
		if (mdx.toString().length > 10) {
			// avoid long urls for IE!
			nonce = zenPage.CreateQueryNonce(mdx); // JSL4500
			if (nonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(nonce);
				return;
			}
		}
		if (nonce) {
			parms.NONCE = nonce;
		}
		else {
			parms.MDX = mdx;
		}

		url = '_DeepSee.UI.MDXPDF.zen';
		if (table.rowTotals) {
			parms.ROWTOTALS = 1;
			parms.ROWTOTALAGG = table.columnTotalAgg;
		}
		if (table.columnTotals) {
			parms.COLUMNTOTALS = 1;
			parms.COLUMNTOTALAGG = table.rowTotalAgg;
		}
		if (table.listing!='') {
			parms.LISTINGNAME = table.listing;
		}

		// find background-color
		var div = this.findComponent('test').getEnclosingDiv();

		var style = table.columnHeaderStyle;
		if (style!='') {
			div.style.cssText = style;
			var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
			parms.COLUMNSTYLE = zenPage.CreateParameterNonce(style + bg);		// DTB916
		}
		var style = table.rowHeaderStyle;
		if (style!='') {
			div.style.cssText = style;
			var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
			parms.ROWSTYLE = zenPage.CreateParameterNonce(style + bg);		// DTB916
		}
		var style = table.cellStyle;
		if (style!='') {
			div.style.cssText = style;
			var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
			parms.CELLSTYLE = zenPage.CreateParameterNonce(style + bg);
		}
		
	}

	// if we are showing a chart, print a chart
	if (this.pivotView=='chart' && !table.isDrillThrough) {
		url = '_DeepSee.UI.ChartPDF.zen';
		var directSVG = true;		// DTB464 - Note that the chart plans to directly print its SVG content

		// send serialized chart along for printing
		var chart = this.findComponent('svgChart');
		var xml = '';
		if (chart) {
			// JSL4146 - pass along chart series names
			chart.controller = table; // JSL4146
			
			if (directSVG) {
				// DTB464 - If the chart is printing directly to SVG, this can be passed without a nonce
				parms.SERIESNAMES = chart.getSeriesNames();
			}
			else {
				var pnonce = '';
				pnonce = zenPage.CreateParameterNonce(""+chart.getSeriesNames()); // JSL4146 JSL4171
				if (pnonce.toString().indexOf('ERROR:')>=0) {
					// error
					alert(pnonce);
					return;
				}
				parms.SERIESNAMES = pnonce; // JSL4171
			}
			
			if (this.hasDataColors) {
				parms.DATADRIVENSERIESCOLORS = this.chartGetSeriesColorsAsString(chart); // JSL4232 data-driven series colors
			}
			
			// pass along the *actual* axis titles
			var oldXTitle = false;
			if (chart.xAxis && ''==chart.xAxis.title) {
				chart.xAxis.title = chart.getXAxisTitle();
				oldXTitle = true;
			}
			var oldYAxisTitle = [];
			var hasLeft = false;
			var hasRight = false;
			for (var ya = 0; ya < chart.yAxisList.length; ya++) {
				var yAxis = chart.yAxisList[ya];
				if (yAxis && ''==yAxis.title) {
					var which = yAxis.labelPosition=='right'?'right':'left';
					if (yAxis.labelPosition=='right') {
						if (!hasRight) {
							chart.yAxisList[ya].title = chart.getYAxisTitle('right');
							oldYAxisTitle[ya] = true;
							hasRight = true;
						}
					}
					else {
						if (!hasLeft) {
							chart.yAxisList[ya].title = chart.getYAxisTitle('left');
							oldYAxisTitle[ya] = true;
							hasLeft = true;
						}
					}
				}
			}

			var add = {xAxis:'object', yAxisList:'list'};
			
			// DTB147 - call method to obtain skip list
			var skip = this.getOverrideSkipList('chart');
			
			var xml = chart.objectToXML(chart,chart._type,add,skip);
			// restore axis titles
			if (oldXTitle) {
				chart.xAxis.title = '';
			}
			for (var ya = 0; ya < chart.yAxisList.length; ya++) {
				if (oldYAxisTitle[ya]) {
					chart.yAxisList[ya].title = '';
				}
			}
		}
		// use nonce for XML
		var xnonce = '';
		if (xml.toString().length > 10) { // PDF export involves a lot of param and avoiding long URLs is more of a problem
			// avoid long urls for IE!
			xnonce = zenPage.CreateQueryNonce(xml,'XML'); 
			if (xnonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(xnonce);
				return;
			}
		}
		if (xnonce) {
			parms.XNONCE = xnonce;
		}
		else {
			parms.XML = xml;
		}
		
		//+ JSL4144 - set parm corresponding to chartLegend
		var legend = this.findComponent('chartLegend');
		if (legend) {
			parms.LEGENDPOSITION = this.legendPosition; // JSL4163
			parms.LEGENDLABELS = legend.legendLabels;
			parms.LEGENDTITLE = legend.legendTitle;
			var legendLabelArray=parms.LEGENDLABELS.split(",");
			parms.LEGENDCOLORS = '';
			var sep = "";
			for (var i=0; i < legendLabelArray.length; i++) {
				parms.LEGENDCOLORS += sep + chart.getSeriesColor(i);
				sep = ";"
			}

			if (directSVG) {
				// DTB464 - If the chart is printing directly to SVG, this can be passed without a nonce
				parms.LEGENDSTYLE = legend.legendStyle
			}
			else {
				var pnonce = '';
				pnonce = zenPage.CreateParameterNonce(""+legend.legendStyle);     // JSL4171
				if (pnonce.toString().indexOf('ERROR:')>=0) {
					// error
					alert(pnonce);
					return;
				}
				
				parms.LEGENDSTYLE = pnonce; // JSL4171
			}
		}
		//- JSL4144
		
		parms.WIDGETTITLE = widgetDef.title // JSL4146

	} else {
		if (table.isDrillThrough) {
			/* JSL4250 */
			var listingFilters=table.listingFilters.join(",")
			var lfArray = [];
			for (var n = 0; n < table.listingFilters.length; n++) {
				var listingFilter = table.listingFilters[n];
				lfArray[lfArray.length] = listingFilter.spec;
			}
		}
		
	}

	// general parms
	parms.TITLE = this.dataSource;		// DP-416074 - Initialize title to datasource

	if (table) {
		if (table.printTitle) {
			parms.TITLE = table.printTitle;
		}
		if (table.printSubtitle) {
			parms.SUBTITLE = table.printSubtitle;
		}
		
		// + WAL239 -- get row Captions
		parms.ROWCAPTIONS = table.getRowCaptions().join('\n');
		// - WAL239

		if (table.showZebra) {
			parms.ZEBRA = 1;
		}
		parms.EVENROWSTYLE = zenPage.CreateParameterNonce(table.evenRowStyle); // JSL4280	// DTB916
		parms.LABELWIDTH = table.printLabelWidth;
		parms.CELLWIDTH = table.printCellWidth;
		parms.ROWCAPTION = table.rowCaptionText;

		if (table.printPageSize) {
			parms.PAGESIZE = table.printPageSize;
		}
		if (table.printOrientation) {
			parms.ORIENTATION = table.printOrientation;
		}
		// JSL4302
		if (typeof table.printSubtitleOn) {
			parms.SUBTITLEON = table.printSubtitleOn;	// DTB228 - Use parameter name MDXPDF expects
		}
		// JSL4320
		if (table.showUser) {
			parms.SHOWUSER = table.showUser
		}
	
		// JSL4219
		if (table.maxRows) {
			parms.MAXROWS = table.maxRows;
		}
		// JSL4218
		if (table.borderLeftCell) {
			parms.BORDERLEFTCELL = table.borderLeftCell;
		}
		if (table.borderRightCell) {
			parms.BORDERRIGHTCELL = table.borderRightCell;
		}
		if (table.borderTopCell) {
			parms.BORDERTOPCELL = table.borderTopCell;
		}
		if (table.borderBottomCell) {
			parms.BORDERBOTTOMCELL = table.borderBottomCell;
		}
		// + WAL100
		if (table.fontFamilyCell!='') {
			parms.FONTFAMILYCELL = table.fontFamilyCell;
		}
		if (table.fontSizeCell!='') {
			parms.FONTSIZECELL = table.fontSizeCell;
		}
		// - WAL100
		if (table.borderLeftCol) {
			parms.BORDERLEFTCOL = table.borderLeftCol;
		}
		if (table.borderRightCol) {
			parms.BORDERRIGHTCOL = table.borderRightCol;
		}
		if (table.borderTopCol) {
			parms.BORDERTOPCOL = table.borderTopCol;
		}
		if (table.borderBottomCol) {
			parms.BORDERBOTTOMCOL = table.borderBottomCol;
		}
		// + WAL100
		if (table.fontFamilyCol!='') {
			parms.FONTFAMILYCOL = table.fontFamilyCol;
		}
		if (table.fontSizeCol!='') {
			parms.FONTSIZECOL = table.fontSizeCol;
		}
		// - WAL100
		if (table.borderLeftRow) {
			parms.BORDERLEFTROW = table.borderLeftRow;
		}
		if (table.borderRightRow) {
			parms.BORDERRIGHTROW = table.borderRightRow;
		}
		if (table.borderTopRow) {
			parms.BORDERTOPROW = table.borderTopRow;
		}
		if (table.borderBottomRow) {
			parms.BORDERBOTTOMROW = table.borderBottomRow;
		}
		// + WAL100
		if (table.fontFamilyRow!='') {
			parms.FONTFAMILYROW = table.fontFamilyRow;
		}
		if (table.fontSizeRow!='') {
			parms.FONTSIZEROW = table.fontSizeRow;
		}
		// - WAL100
		if (table.showFilters) {
			parms.SHOWFILTERS = table.showFilters;
		}

		if (table.showListingFilters) { // JSL4250
			parms.SHOWLISTINGFILTERS = table.showListingFilters;
		}

		if (table.listingFontSize) { // JSL4279
			parms.LISTINGFONTSIZE = table.listingFontSize;
		}

		if (table.showZebraStripes) { // JSL4256
			parms.SHOWZEBRASTRIPES = table.showZebraStripes;
		}

		if (table.showDate) { // JSL4250
			parms.SHOWDATE = table.showDate;
		}

		if (table.printMarginTop) {
			parms.MARGINTOP = table.printMarginTop;
		}
		if (table.printMarginBottom) {
			parms.MARGINBOTTOM = table.printMarginBottom;
		}
		if (table.printMarginLeft) {
			parms.MARGINLEFT = table.printMarginLeft;
		}
		if (table.printMarginRight) {
			parms.MARGINRIGHT = table.printMarginRight;
		}
	}
	
	// JMD1207
	if (widgetDef && widgetDef.properties) {
		// DP-416074 - Check titles for printing
		if (widgetDef.properties.printTitle) {
			parms.TITLE = widgetDef.properties.printTitle;
		}
		else if (widgetDef.title) {
			parms.TITLE = widgetDef.title;
 		}
		if (widgetDef.properties.printSubtitle) {
			parms.SUBTITLE = widgetDef.properties.printSubtitle;
		}

		if (widgetDef.properties.printPageSize) {
			parms.PAGESIZE = widgetDef.properties.printPageSize;
		}
		if (widgetDef.properties.printOrientation) {
			parms.ORIENTATION = widgetDef.properties.printOrientation;
		}
		if (widgetDef.properties.printSubtitleOn) {
			parms.SUBTITLEON = widgetDef.properties.printSubtitleOn;	// DTB228 - Use parameter name MDXPDF expects
		}
		if (widgetDef.properties.showUser) { // JSL4320
			parms.SHOWUSER = widgetDef.properties.showUser;
		}
		if (widgetDef.properties.printMarginTop) {
			parms.MARGINTOP = widgetDef.properties.printMarginTop;
		}
		if (widgetDef.properties.printMarginBottom) {
			parms.MARGINBOTTOM = widgetDef.properties.printMarginBottom;
		}
		if (widgetDef.properties.printMarginLeft) {
			parms.MARGINLEFT = widgetDef.properties.printMarginLeft;
		}
		if (widgetDef.properties.printMarginRight) {
			parms.MARGINRIGHT = widgetDef.properties.printMarginRight;
		}
		// JSL419
		if (widgetDef.properties.maxRows) {
			parms.MAXROWS = widgetDef.properties.maxRows;
		}
		// JSL4218
		if (widgetDef.properties.borderLeftCell) {
			parms.BORDERLEFTCELL = widgetDef.properties.borderLeftCell;
		}
		if (widgetDef.properties.borderRightCell) {
			parms.BORDERRIGHTCELL = widgetDef.properties.borderRightCell;
		}
		if (widgetDef.properties.borderTopCell) {
			parms.BORDERTOPCELL = widgetDef.properties.borderTopCell;
		}
		if (widgetDef.properties.borderBottomCell) {
			parms.BORDERBOTTOMCELL = widgetDef.properties.borderBottomCell;
		}
		// + WAL100
		if (widgetDef.properties.fontFamilyCell) {
			parms.FONTFAMILYCELL = widgetDef.properties.fontFamilyCell;
		}
		if (widgetDef.properties.fontSizeCell) {
			parms.FONTSIZECELL = widgetDef.properties.fontSizeCell;
		}
		// - WAL100
		if (widgetDef.properties.borderLeftCol) {
			parms.BORDERLEFTCOL = widgetDef.properties.borderLeftCol;
		}
		if (widgetDef.properties.borderRightCol) {
			parms.BORDERRIGHTCOL = widgetDef.properties.borderRightCol;
		}
		if (widgetDef.properties.borderTopCol) {
			parms.BORDERTOPCOL = widgetDef.properties.borderTopCol;
		}
		if (widgetDef.properties.borderBottomCol) {
			parms.BORDERBOTTOMCOL = widgetDef.properties.borderBottomCol;
		}
		// + WAL100
		if (widgetDef.properties.fontFamilyCol) {
			parms.FONTFAMILYCOL = widgetDef.properties.fontFamilyCol;
		}
		if (widgetDef.properties.fontSizeCol) {
			parms.FONTSIZECOL = widgetDef.properties.fontSizeCol;
		}
		// - WAL100
		if (widgetDef.properties.borderLeftRow) {
			parms.BORDERLEFTROW = widgetDef.properties.borderLeftRow;
		}
		if (widgetDef.properties.borderRightRow) {
			parms.BORDERRIGHTROW = widgetDef.properties.borderRightRow;
		}
		if (widgetDef.properties.borderTopRow) {
			parms.BORDERTOPROW = widgetDef.properties.borderTopRow;
		}
		if (widgetDef.properties.borderBottomRow) {
			parms.BORDERBOTTOMROW = widgetDef.properties.borderBottomRow;
		}
		// + WAL100
		if (widgetDef.properties.fontFamilyRow) {
			parms.FONTFAMILYROW = widgetDef.properties.fontFamilyRow;
		}
		if (widgetDef.properties.fontSizeRow) {
			parms.FONTSIZEROW = widgetDef.properties.fontSizeRow;
		}
		// - WAL100
		// JSL4184
		if (widgetDef.properties.showFilters) {
			parms.SHOWFILTERS = widgetDef.properties.showFilters;
		}
		if (widgetDef.properties.showListingFilters) { // JSL4520
			parms.SHOWLISTINGFILTERS = widgetDef.properties.showListingFilters;
		}
		if (widgetDef.properties.showDate) { // JSL4520
			parms.SHOWDATE = widgetDef.properties.showDate;
		}
		if (widgetDef.properties.listingFontSize) { // JSL4279
			parms.LISTINGFONTSIZE = widgetDef.properties.listingFontSize;
		}
		if (widgetDef.properties.showZebraStripes) { // JSL4526
			parms.SHOWZEBRASTRIPES = widgetDef.properties.showZebraStripes;
		}
		
		if (widgetDef.properties.filterTableStyle) {
			parms.FILTERTABLESTYLE = zenPage.CreateParameterNonce(widgetDef.properties.filterTableStyle);		// DTB916
		}
		if (widgetDef.properties.filterTableCaptionStyle) {
			parms.FILTERTABLECAPTIONSTYLE = zenPage.CreateParameterNonce(widgetDef.properties.filterTableCaptionStyle);		// DTB916
		}
		if (widgetDef.properties.filterTableItemStyle) {
			parms.FILTERTABLEITEMSTYLE = zenPage.CreateParameterNonce(widgetDef.properties.filterTableItemStyle);		// DTB916
		}
		if (widgetDef.properties.nowDisplayFormat) {
			parms.NOWDISPLAYFORMAT = widgetDef.properties.nowDisplayFormat;
		}
	}

	// JMD1332
	if (table.getSelectedRange()) {
		parms.SELECTEDRANGE = table.getSelectedRange();
	}
	if (table.getSelectedItems()) {
		parms.SELECTEDITEMS = zenPage.CreateParameterNonce(table.getSelectedItems().toString());		// DTB916
	}
	if (table.listingSortColumn) {
		parms.LISTINGSORTCOLUMN = table.listingSortColumn;
	}
	if (table.listingSortDir) {
		parms.LISTINGSORTDIR = table.listingSortDir;
	}
	
	if (preserveTempFiles) {
		// DTB251 - Option to preserve temp files for multi-widget printing
		parms.$NODELETE = 1
		parms.preserveTempFiles = preserveTempFiles;		// DTB345
	}
	
	if (printMultiple) {
		// DTB252 - Reconcile the current settings with the common settings for multi-print
		if (isMasterWidget) {
			// DTB279. If the user has not set page setup settings in the master widget, use the defaults 
			// for common settings across all widgets
			if (parms.PAGESIZE) {
				zenPage.printPageSize = parms.PAGESIZE;
			}
			else {
				parms.PAGESIZE = zenPage.printPageSize;
			}

			if (parms.ORIENTATION) {
				zenPage.printPageOrientation = parms.ORIENTATION;
			}
			else {
				parms.ORIENTATION = zenPage.printPageOrientation;
			}

			if (parms.MARGINTOP) {
				zenPage.printMarginTop = parseFloat(parms.MARGINTOP)+'in';
			}
			else {
				parms.MARGINTOP = parseFloat(zenPage.printMarginTop);
			}

			if (parms.MARGINBOTTOM) {
				zenPage.printMarginBottom = parseFloat(parms.MARGINBOTTOM)+'in';
			}
			else {
				parms.MARGINBOTTOM = parseFloat(zenPage.printMarginBottom);
			}

			if (parms.MARGINLEFT) {
				zenPage.printMarginLeft = parseFloat(parms.MARGINLEFT)+'in';
			}
			else {
				parms.MARGINLEFT = parseFloat(zenPage.printMarginLeft);
			}
			
			if (parms.MARGINRIGHT) {
				zenPage.printMarginRight = parseFloat(parms.MARGINRIGHT)+'in';
			}
			else {
				parms.MARGINRIGHT = parseFloat(zenPage.printMarginRight);
			}
		}
		else {
			if (zenPage.printPageSize) {
				parms.PAGESIZE = zenPage.printPageSize;
			}
			if (zenPage.printPageOrientation) {
				parms.ORIENTATION = zenPage.printPageOrientation;
			}
			if (zenPage.printMarginTop) {
				parms.MARGINTOP = parseFloat(zenPage.printMarginTop) + 0.5;
			}
			if (zenPage.printMarginBottom) {
				parms.MARGINBOTTOM = parseFloat(zenPage.printMarginBottom);
			}
			if (zenPage.printMarginLeft) {
				parms.MARGINLEFT = parseFloat(zenPage.printMarginLeft);
			}
			if (zenPage.printMarginRight) {
				parms.MARGINRIGHT = parseFloat(zenPage.printMarginRight);
			}
		}
	}
	
	// open window to generate PDF
	if (url) {
		url = zenLink(url);
		var count = 0;
		var questionflag = url.indexOf('?') >= 0;
		for (var p in parms) {
			if (parms[p]!=='') {
				url += (count || questionflag ?'&':'?') + p + '=' + encodeURIComponent(parms[p]);
			count++;
			}
		}
		
		// JSL4196 comment out
		// DTB198 - Add back in for kpis!
		if (''!==table.kpi) {
			url += kpi_filter_string
		}
		if (filterNames.length > 0) { // JSL4182
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce(filterNames.join('\n'));		// DTB916
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce(filterValues.join('\n'));		// DTB916
		}
		if (lfArray) {
			if (lfArray.length > 0) {
				url += '&LISTINGFILTERS='+zenPage.CreateParameterNonce(lfArray.join('\n'));		// DTB916
			}
		}
		
		parms.filterTable = this.getFilterTableForPrinting(parms);		// DTB346	// DTB405 - Pass parameters
		parms.printMultiple = (printMultiple) ? true : false;		// DTB346 - Force boolean value
		parms.title = '';		// DP-416074 - Clear out the overall report title
		this.prepareSvgPrintParameters(parms);						// DTB367 - Normalize the printing parameters

		if ((this.pivotView=='chart') && !table.isDrillThrough) {
			// DTB341 - Print SVG chart
			if ((!this.legendPosition)||('none'==this.legendPosition)) {
				// Print the svgFrame by ID, no pre-processing necessary
				this.printSVGContent(this.id + '/svgFrame',parms,'',filename);		// DTB684 - Add filename
			}
			else {
				// DTB345 - Add the legend SVG to the chart document for printing.
				var svgUtil = zen('svgUtil');
				var chartDocument = svgUtil.getSVGDOMRoot(this.id + '/svgFrame');
				var legendSVG = svgUtil.createSVGTableFromZenComponent(this.id + '/chartLegend');
				var legendId = legendSVG.childNodes[0].id;
				
				// This will cause the added svg legend become visible in the browser,
				// it will need to be removed.
				svgUtil.addSVGLegendToChart(chartDocument,legendSVG,this.legendPosition);
				
				// Call print while the legend is temporarily added.
				this.printSVGContent(this.id + '/svgFrame',parms,chartDocument,filename);		// DTB684 - Add filename
				
				// Remove the svg legend to restore the correct presentation in the UI
				svgUtil.removeSVGLegendFromChart(chartDocument,legendId,this.legendPosition);		// DTB356 - Add legend position to call
			}
		}
		else {
			// Print Table
			if ((table.isDrillThrough)||(table.rowCount>table.pageSize)) {
				// Print using the original MDXPDF.
				if (printMultiple) {
					var printMode = ((this.pivotView=='chart') && !table.isDrillThrough) ? this.pivotView : 'table';
					this.GenerateXSLFO(this.id,url,printMode,filename);		// DTB684 - Add filename
				}
				else {
					if (!filename) {
						window.open(url,'pdf','');
					}
					else {
						// DTB684 - File name is supplied
						window.open(url+'&$REPORTNAME='+filename+'&$NODELETE=1','pdf','');	
					}
				}
			}
			else {
				// DTB341 - Print SVG Table
				var svgUtil = zen('svgUtil');
				var tableId = this.id + '/table';
				
				// DTB405 - Set parms for table conversion
				svgUtil.setPrintParameters(parms);
				
				// DTB345 - Wrap the raw table content in a container for printing
				var svgTable = svgUtil.createSVGTableFromZenComponent(tableId);
				var svgTableDiv = document.createElement('div');
				svgTableDiv.appendChild(svgTable);
				
				if (svgTable) {
					// DTB350 - Record the original width to prevent massive upward scaling
					parms.imageWidth = svgTable.getAttribute('width');
					
					// DTB350 - Do a final test to revert back to the original printing if the
					// manufactured svgTable is too tall
					var maxHeight = svgUtil.calculateMaxImageHeight(parms);
					maxHeight = svgUtil.convertSizeToPoint(maxHeight);
					if (svgTable.getAttribute('height') > maxHeight.value) {
						if (printMultiple) {
							var printMode = ((this.pivotView=='chart') && !table.isDrillThrough) ? this.pivotView : 'table';
							this.GenerateXSLFO(this.id,url,printMode,filename);		// DTB684 - Add filename
						}
						else {
							if (!filename) {		// DTB734
								window.open(url,'pdf','');
							}
							else {
								// DTB684 - File name is supplied
								window.open(url+'&$REPORTNAME='+filename+'&$NODELETE=1','pdf','');
							}
						}
					}
					else {
						this.printSVGContent(tableId,parms,svgTableDiv,filename);		// DTB345 - Simplify with modified printSVGContent		// DTB684 - Add filename
					}
				}
			}
		}
	}
}

/// Create an XSLFO file used for merging many exports into a single report.
Method GenerateXSLFO(pWidgetID, pUrl, pMode, pFileName = "") As %Status [ ZenMethod ]
{
	// Method added by DTB252
	Set tSC = $$$OK
	Set:($G(pMode)="") pMode = "table"
	Try {
		New %request
		Set %request = ##class(%CSP.Request).%New()
		
		Set tParameterString = $P(pUrl,"?",2)
		For k=1:1:$L(tParameterString,"&") {
			Set tSetting = $P(tParameterString,"&",k)
			// This is the last chance to translate back into a readable string!
			Set %request.Data($P(tSetting,"=",1),1) = $ZCVT($P(tSetting,"=",2),"I","URL")
		}

		Set %request.Data("$MODE",1) = "xslfo"

		// open the file
		If (pFileName'="") {
			// DTB684 - Custom filename
			Set tFile = ##class(%ZEN.ComponentEx.svgImageProvider).ScopeFileName(pFileName_".xsl")
		}
		Else {
			Set tFile = ##class(%ZEN.ComponentEx.svgImageProvider).ScopeFileName(pWidgetID_"-print"_%page.tempFileToken_".xsl")		// DTB347
		}

		
		Set io = $io
		If ($G(tFile)'="") {
			Open tFile:"WNU":0 Else  Set tSC = $$$ERROR($$$GeneralError,"Unable to open file: "_tFile) Quit
			Use tFile
		}
		
		// Use the appropriate report provider
		If (pMode="table") {
			Set pTempReport = ##class(%DeepSee.UI.MDXPDF).%New()
		}
		ElseIf (pMode="chart") {
			Set pTempReport = ##class(%DeepSee.UI.ChartPDF).%New()
		}
		Set tSC = pTempReport.OnPage()
		
		If ($G(tFile)'="") {
			Use io
			Close tFile
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
		If ($G(tFile)'="")&&($G(io)'="") {
			Use io
			Close tFile
		}
	}
	Quit tSC
}

/// Apply the given setting value to this widget.
ClientMethod applySetting(action, value) [ Internal, Language = javascript ]
{
	var table = this.getDataController();
	if (!table) return;

	switch(action) {
	case 'setRowCount':
		if (''===value) {
			table.rowAxisOptions.headEnabled = false;
		}
		else {
			table.rowAxisOptions.headEnabled = true;
			table.rowAxisOptions.headCount = value;
		}
		table.executeQuery(true);
		break;

	case 'setRowSort':
		if (''!==value) {
			table.rowAxisOptions.orderEnabled = true;
			table.rowAxisOptions.orderDirection = value;
		}
		table.executeQuery(true);
		break;

	case 'setColumnCount':
		if (''===value) {
			table.columnAxisOptions.headEnabled = false;
		}
		else {
			table.columnAxisOptions.headEnabled = true;
			table.columnAxisOptions.headCount = value;
		}
		table.executeQuery(true);
		break;
	case 'setColumnSort':
		if (''!==value) {
			table.columnAxisOptions.orderEnabled = true;
			table.columnAxisOptions.orderDirection = value;
		}
		table.executeQuery(true);
		break;
	}
}

ClientMethod changeChartType(value) [ Internal, Language = javascript ]
{
	// + WAL083 (2) -- if we are looking at a table, toggle it to a chart
	var pivot = this.getDataController();
	if ((this.pivotView == 'table')&&(value!='')) {
		// show chart
		this.toggleChart();
	}
	if (value == 'table') {
		// switch to table
		this.toggleChart();		// DTB113 - use toggleChart
		this.adjustSizes(false);
		this.updateControlState();
		return;	
	}
	// - WAL083 (2)
	// + WAL083 -- taken from widget.pivot navDataChange
	//             Implements the chart type change for "setChartType" and "chooseChartType" actions
	var svg = this.findComponent('svgFrame');
	var chart = this.findComponent('svgChart');
	var timeBased = chart.isTimeBased();
	// WAL259 -- use counter to determine if we need to unregister the chart
	//           if the new chart and old chart are the same zen type we don't need to unregister
	var registeredItems = pivot._registeredCounter;
	this.chartDataChange(zenPage.getNavigator(),svg,chart,'chart-ChartType',value,1);
	if (pivot._registeredCounter > registeredItems) {
		pivot.unregister(chart); // WAL083 (5) -- unregister the old chart so the pivot table doesn't try to update it
	}
	if (!timeBased) {
		this.adjustSizes(false);
	}
	// - WAL083
	this.updateControlState(); // WAL083 (2)
}

/// Find the value of the given parameter value.
ClientMethod getParameterValue(parm) [ Internal, Language = javascript ]
{
	var pivot = this.getDataController();
	var value = '';
	switch(parm) {
	case 'CURRVALUE':
		value=this.getProperty('currValue'); // WAL188 && Sascha Kisser
		break;

	case 'VALUELIST':
		// list of values for selected rows
		var list = pivot.getSelectedItems();
		if (list) {
			for (var n = 0; n < list.length; n++) {
				if (list[n] && list[n]!='' && 'string'==typeof list[n]) {
					list[n] = list[n].replace(/\,/g,'\\,');
				}
			} 
		}
		value = list ? list.join(',') : '';
		break;
	case 'ROWSPEC':
		// MDX spec for current pivot row
		var range = pivot.getSelectedRange();
		if (range) {
			var itemInfo = new zenProxy();
			var ok = pivot.GetItemSpec(itemInfo,pivot.cubeName,pivot.queryKey,pivot.sortDir, pivot.sortColumn,'row',range[0]);
			if (!ok) {
				if (itemInfo.error) {
					alert(itemInfo.error);
				}
				return;
			}
			value = itemInfo.spec;
		}
		break;
	case 'COLUMNSPEC':
		// MDX spec for current pivot column
		var range = pivot.getSelectedRange();
		if (range) {
			var itemInfo = new zenProxy();
			var ok = pivot.GetItemSpec(itemInfo,pivot.cubeName,pivot.queryKey,pivot.sortDir, pivot.sortColumn,'col',range[1]);
			if (!ok) {
				if (itemInfo.error) {
					alert(itemInfo.error);
				}
				return;
			}
			value = itemInfo.spec;
		}
		break;
	// + WAL162 -- handle pivot variables
	case 'VARIABLES':
		value = this.getPivotVariableState();
		break;
	// - WAL162
	default:
		value = this.invokeSuper('getParameterValue',arguments);
		break;
	}
	return value;
}

/// Return the current state of filters for this widget as one serialized string.
ClientMethod getPivotVariableState(delim1, delim2) [ Internal, Language = javascript ]
{
	var table = this.getDataController();
	if (table) {
		// use tab and cr as default delims!
		delim1 = ('undefined'==typeof delim1) ? '\t' : delim1;
		delim2 = ('undefined'==typeof delim2) ? '\n' : delim2;

		var pivotVariables = table.pivotVariables;

		var state = '';
		for (var p in pivotVariables) {
			var value = pivotVariables[p];
			state += p + delim1 + value + delim2;
		}
		return state;
	}
}

/// Called when user clicks on a marker in a geolisting.
ClientMethod markerClicked(marker) [ Internal, Language = javascript ]
{
	var table = this.getDataController();
	if (!table) return;

	var map = this.findComponent('map');
	if (map) {
		var index = marker._id;
		// find item in listing data
		var data = table.getContent();
		if (data && data.listingRows && data.listingRows[index]) {
			var row = data.listingRows[index];
			var content = [];
			for (var prop in row) {
				if (prop!='Latitude' && prop!='Longitude') {
					// replace _ with space
					var propName = prop.replace(/_/g,' ');
					content[content.length] = '<div style="color:#606080; font-size:8pt;">'+zenEscapeXML(propName)+'</div>';
					content[content.length] = '<div style="color:#404040; font-size:10pt;padding-bottom:2px;">'+zenEscapeXML(row[prop])+'</div>';
				}
			}
			map.createInfoWindow(marker,content.join(''));
		}
	}
}

/// Notification to subclasses that filter has changed.
ClientMethod onApplyFilters(refresh) [ Internal, Language = javascript ]
{
	if (('chart'==this.pivotView)&&(''!=this.getPivot().error)) {
		// DTB150 - Report the pivot error to the user by toggling to the table view
		this.toggleChart();
	}
	else if (this.subtypeIsChart(this.subtype) &&
			(!this.getPivot().error) &&
			('table'==this.pivotView) &&
			('none'==this.chartToggle)) {
		// DTB150 - Do not leave purely chart widgets in table mode!
		this.toggleChart();
	}

	// make sure we are not in listing mode
	/* JMD1210
	if (this.viewType != 'pivot') {
		this.viewType = 'pivot';
	}
	*/
	// always adjust as filter controls can change size
	this.adjustSizes(false);
}

/// Go back to the previous pivot state.
ClientMethod resetPivot() [ Language = javascript ]
{
	var pivot = this.findComponent('table');
	if (pivot) {
		pivot.popState();
	}
}

/// Return an object describing what to display for this level within the navigator.
/// Invoked from dashboard viewer.
ClientMethod navGetContentForLevel(level, key, value) [ Internal, Language = javascript ]
{
	var content = { title: $$$Text('Settings','%DeepSee'), items:[] };
	var navigator = zenPage.getNavigator();
	var title = '';

	// key may take the form key:no
	var ckey = key; // local copy
	var keyNo = '';
	if (ckey.toString().indexOf(':')>0) {
		var t = ckey.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	switch (ckey) {
	case 'WidgetSettings':
		// get common content
		content = this.invokeSuper('navGetContentForLevel',arguments);

		content.items[content.items.length] = {display:'section', caption:$$$Text('Chart and Pivot','%DeepSee') };
		content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_list_44.png', caption:$$$Text('Table Settings','%DeepSee'), action:'drill', key:'widget-pivot-PivotSettings'};
		content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_bar_chart_44.png', caption:$$$Text('Chart Settings','%DeepSee'), action:'drill', key:'widget-chart-ChartSettings'};
		content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_cards_44.png', caption:$$$Text('Chart Legend','%DeepSee'), action:'drill', key:'widget-legend-ChartLegend'};
		content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/ds2_printer_44.png', caption:$$$Text('Print Setup','%DeepSee'), action:'select', key:'widget-print-setup'};
		break;

	case 'widget-legend-ChartLegend':
		content.title = $$$Text('Chart Legend','%DeepSee');
		var legend = this.findComponent('chartLegend');
		var which = 'widget-legend';
		var idx = '';

		// content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%DeepSee'), edit:'string', value:this.header,	key:'widget-header'};

		// position
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Position','%DeepSee'), edit:'choice', value:this.legendPosition, key:which+'-legendPosition', valueList:'none,top,bottom,left,right', displayList:'&#248,&#9650;,&#9660;,&#9664;,&#9654;'};

		// style

		var info = navigator.parseStyle(legend.legendStyle);
		var color = info.color;
		var background = info.backgroundColor;
		var fontFamily = info.fontFamily;
		var fontSize = info.fontSize;
		var opacity = info.opacity;
		var align = zenGet(info.textAlign);
		
		var fs = [];
		if (info.bold) { fs[fs.length] = 'bold'; }
		if (info.underline) { fs[fs.length] = 'underline'; }
		if (info.italic) { fs[fs.length] = 'italic'; }
		if (info.shadow) { fs[fs.length] = 'shadow'; }
		var fontStyle = fs.join(',');
		var opacity = zenGet(info.opacity);
		opacity = opacity === '' ? 1.0 : opacity;
		var radius = zenGet(info.radius);
		
		var showBoxShadow = (''==legend.legendBoxStyle);		// DTB170 - Read style to decide whether to display the shadow on the series box
		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%DeepSee'), edit:'string', value:zenGet(legend.legendTitle),key:which+'-title'+idx};  // + WAL098 -- allow legend title to be specified
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Title','%DeepSee'), edit:'switch', value:zenGet(legend.showLegendTitle),key:which+'-showTitle'+idx };  // + WAL098 -- allow legend title to be toggled on/off
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border','%DeepSee'), action:'drill', value:'',	key:which+'-border'+idx};					// DTB169 - Add legend border drill control
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:'',	key:which+'-background'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider', value:opacity,	key:which+'-opacity'+idx, minValue:0, maxValue:1 };		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:which+'-font-family'+idx, valueStyle:'font-size:13px;font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:which+'-font-size'+idx, minValue:2, maxValue:75, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Color','%DeepSee'), action:'drill', value:'',	key:which+'-color'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+color+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:which+'-textStyle'+idx, valueList:'bold,italic,underline,shadow', displayList:'B,I,U,S', valueStyle:'font-size:12px;font-family:times new roman;',  choiceStyles:'font-weight:900;^font-style:italic;^text-decoration:underline;^text-shadow:1px 1px 2px #F0F0F0;'};
		//JMD1292 content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Align','%DeepSee'), edit:'choice', value:align,	key:which+'-text-align'+idx, valueList:'left,center,right', displayList:'&#9664;,&#9632;,&#9654;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Padding','%DeepSee'), edit:'slider-toggle', value:zenGet(info.padding),	key:which+'-padding'+idx, minValue:0, maxValue:25};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%DeepSee'), edit:'slider-toggle', value:zenGet(info.width),	key:which+'-width'+idx, minValue:0, maxValue:1200};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height','%DeepSee'), edit:'slider-toggle', value:zenGet(info.height),	key:which+'-height'+idx, minValue:0, maxValue:250};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Show Box Shadow','%DeepSee'), edit:'switch', value:showBoxShadow,key:which+'-legendBoxShadow'+idx };		// DTB170
		break;

	case 'widget-legend-color':
		// choose a color
		content.title = $$$Text('Legend Text Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(ckey,value,'html');
		break;

	case 'widget-legend-background':
		// choose a color
		content.title = $$$Text('Legend Background Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(ckey,value,'html');
		break;
		
	case 'widget-legend-border-stroke':
		// choose a color
		content.title = $$$Text('Legend Border Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(ckey,value,'html');
		break;
	
	case 'widget-legend-border':
		// DTB169 - set border style
		var legend = this.findComponent('chartLegend');
		if (legend) {
			content.title = $$$Text('Legend Border Style','%DeepSee');
			
			// pull apart border style for the current control values
			var info = navigator.parseStyleSVG(legend.legendBorderStyle);

			var opacity = zenGet(info['opacity']);		// DTB171 - Add opacity
			var stroke = zenGet(info['border-color']);
			var strokeWidth = zenGet(info['border-width']);
			var strokeDashArray = (''!=zenGet(info['border-style'])) ? info['border-style'] : 'solid';
			
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee'), edit:'slider-toggle', value:opacity,	key:ckey+'-opacity', minValue:0, maxValue:1 };		
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line','%ZEN'), action:'drill', value:'',	key:ckey+'-stroke', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+stroke+';'};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Width','%ZEN'), edit:'slider-toggle', value:strokeWidth,	key:ckey+'-stroke-width', minValue:0, maxValue:25, stepSize:0.25};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Line Style','%ZEN'), edit:'choice', value:strokeDashArray,	key:ckey+'-stroke-dasharray', valueList:'solid,dashed,dotted', displayList:$$$Text('solid,dashed,dotted','%ZEN')};
		}
		break;

	case 'widget-legend-font-family':
		content.title = $$$Text('Legend Font','%DeepSee');

		// choose a font
		content.html = navigator.getFontChooserHTML(which+'-font-family',value);
		break;

	default:
		// pull key apart; dispatch on second piece
		var kt = ckey.toString().split('-');
		switch(kt[1]) {
		case 'common':
			// dispatch to super class
			content = this.invokeSuper('navGetContentForLevel',arguments);
			break;
		case 'pivot':
			// dispatch
			var pivot = this.getPivot();
			// pull 'widget-' off of key
			var kt = ckey.toString().split('-');
			kt.splice(0,1);
			var k2 = kt.join('-');
			k2 = (keyNo==='') ? k2 : (k2 + ':' + keyNo);
			content = this.pivotTableGetContentForLevel(zenPage.getNavigator(),pivot,level,k2,'');

			// add prefix to the returned keys
			if (content.items) {
				for (var n = 0; n < content.items.length; n++) {
					var k = content.items[n].key;
					if (k) {
						content.items[n].key = 'widget-' + k;
					}
				}
			}
			break;
		case 'chart':
			// dispatch to content class
			var chart = this.findComponent('svgChart');
			if (chart) {
				// pull 'widget-' off of key
				var kt = ckey.toString().split('-');
				kt.splice(0,1);
				var k2 = kt.join('-');
				k2 = (keyNo==='') ? k2 : (k2 + ':' + keyNo);
				content = this.chartGetContentForLevel(zenPage.getNavigator(),chart,level,k2,value);

				// JMD1259 insert data-driven color setting
				if (k2=='chart-ChartColors') {
					var widgetDef = this.getDefinition();
					content.items.push({display:'section', caption:$$$Text('Data-driven Colors','%DeepSee')});
					content.items.push({display:'caption-value-hz', caption:$$$Text('Termlist','%DeepSee'), edit:'string', value:zenGet(widgetDef.dataColorList),  key:'chart-dataColorList', title:$$$Text('Name of the termlist containing the list of values and colors','%DeepSee'),action:'popup',url:'_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists'});
				}

				// add "widget-" prefix to the returned keys
				if (content.items) {
					for (var n = 0; n < content.items.length; n++) {
						var k = content.items[n].key;
						if (k) {
							content.items[n].key = 'widget-' + k;
						}
					}
				}
			}
			break;
		}
		break;
	}

	return content;
}

/// Click on header button in navigator.
ClientMethod navHeaderButtonClick(key) [ Language = javascript ]
{
	var ckey = key;
	var kt = ckey.toString().split('-');
	var target = kt[0];

	switch(target) {
	case 'chart':
		var chart = this.findComponent('svgChart');
		this.chartHeaderButtonClick(zenPage.getNavigator(),chart,ckey);
		break;
	default:
		// send to super
		this.invokeSuper('navHeaderButtonClick',arguments);
		break;
	}
}

/// Click on close button in navigator.
ClientMethod navCloseButtonClick(key) [ Language = javascript ]
{
	// pull 'widget-' off of key
	var ckey = key;
	var kt = ckey.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');
	var target = kt[0];

	switch(target) {
	case 'chart':
		var chart = this.findComponent('svgChart');
		var k3 = k2.split(':')[0];
		if (k3=='chart-yAxis') {
			var yc = chart.yAxisList.length;
		}
		this.chartCloseButtonClick(zenPage.getNavigator(),chart,k2);
		if (k3=='chart-yAxis' && yc != chart.yAxisList.length) {
			// axis removed: reuse change logic
			zenPage.setModified(true);
			this.navDataChange('widget-chart-yAxisRemove','',true);
		}
		break;
	default:
		// send to super
		this.invokeSuper('navCloseButtonClick',arguments);
		break;
	}
}

/// Popup action in navigator.
ClientMethod navPopupAction(key, value) [ Language = javascript ]
{
	// key may take the form key:no
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		var controlKey = t[0];  // WAL059 -- Don't change the arguments before passing them to super class
		keyNo = parseInt(t[1]);
	}
	
	switch(controlKey) {
	case 'widget-chart-dataColorList':
		// JMD1443
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		if (widgetDef && widgetDef.dataColorList != value) {
			widgetDef.dataColorList = value;
			zenPage.setModified(true);
			zenPage.recreateWidget(zenPage.currWidgetKey);
		}
		break;
	default:
		this.invokeSuper('navPopupAction',arguments);
		break;
	}
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
	var navigator = zenPage.getNavigator();
	var legend = this.findComponent('chartLegend');
	
	// pull 'widget-' off of key
	var ckey = key;
	var kt = ckey.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');
	var target = kt[0];

	// now test 2nd piece of key
	switch (target) {
	case 'common':
		this.invokeSuper('navDataChange',arguments);
		break;

	case 'chart':
		if (this.pivotView == 'table') {
			break; // don't process a data change to chart if we are viewing a table JSL4165
		}

		if (ckey == 'widget-chart-dataColorList') {
			// JMD1259
			if (final) {
				var widgetDef = this.getDefinition();
				if (widgetDef && widgetDef.dataColorList!=value) {
					widgetDef.dataColorList = value; 
					zenPage.recreateWidget(zenPage.currWidgetKey);
				}
			}
			break;
		}

		if (ckey == 'widget-chart-ChartType') {
			// cache old chart type so that we can restore it
			if (!zenPage._oldChartType) {
				var widgetDef = this.getDefinition();
				if (widgetDef && widgetDef.subtype) {
					zenPage._oldChartType = widgetDef.subtype;
				}
			}
		}

		// dispatch to chart controller
		var svg = this.findComponent('svgFrame');
		var chart = this.findComponent('svgChart');
		var timeBased = chart.isTimeBased();
		if (k2!='chart-yAxisRemove') {
			this.chartDataChange(zenPage.getNavigator(),svg,chart,k2,value,final);
		}
		if (k2=='chart-ChartType' && (timeBased!=chart.isTimeBased())) {
			// resize
			this.adjustSizes(false);
		}
		else if (k2=='chart-labelsVisible') {
			// reset local default
			this.labelsVisible = value;
		}

		// update chart overrides
		if (final) {
			var widgetDef = this.getDefinition();
			if (widgetDef) {
				if (ckey == 'widget-chart-ChartType') {
					delete zenPage._oldChartType;
					widgetDef.subtype = value;
				}

				// DTB147 - call new method to obtain skip list
				var skip = this.getOverrideSkipList('chart');

				// JMD1201
				// test properties against theme; skip any that are same as the theme
				if (widgetDef.themeOverrides['chart']) {
					var themeObj = ZLM.jsonParse(widgetDef.themeOverrides['chart']);
					if (themeObj) {
						for (var p in themeObj) {
							if (chart[p]==themeObj[p]) {
								skip[p] = true;
							}
						}
					}
				}

				// save by class
				var jsonOver = this.componentToJSON(chart,0,skip);
				widgetDef.overrides[chart._type] = jsonOver;
			}
		}
		break;

	case 'pivot':
		// dispatch to pivot controller
		var pivot = this.getPivot();
		this.pivotTableDataChange(zenPage.getNavigator(),pivot,k2,value,final);

		// update pivot overrides
		if (final) {
			var widgetDef = this.getDefinition();
			if (widgetDef) {
				// DTB147 - call method to obtain skip list
				var skip = this.getOverrideSkipList('pivot');		

				var jsonOver = this.componentToJSON(pivot,0,skip);
				if (zenGet(widgetDef.themeOverrides['pivot'])!=jsonOver) {
					widgetDef.overrides['pivot'] = jsonOver;
				}
				else {
					delete widgetDef.overrides['pivot'];
				}
			}
		}
		break;

	case 'legend':
	
		switch(k2) {
		case 'legend-legendPosition':
			this.legendPosition = value;
			if (legend) {
				switch(this.legendPosition) {
				case 'top':
				case 'bottom':
					legend.setProperty('orientation','horizontal');
					break;
				case 'left':
				case 'right':
					legend.setProperty('orientation','vertical');
					break;
				}
			}
			this.adjustSizes(false);
			// save to widget def
			if (final) {
				var widgetDef = this.getDefinition();
				widgetDef.properties['legendPos'] = this.legendPosition;
				zenPage.setModified(true);
			}
			break;

		case 'legend-textStyle':
			var styleValues = {};
			var cv = value.toString().split(',');
			for (var n = 0; n < cv.length; n++) {
				styleValues[cv[n]] = true;
			}
			var list = ['bold','underline','italic','shadow'];
			if (legend) {
				var style = zenGet(legend.legendStyle);

				// pull 'legend-' off of key
				var kt = k2.toString().split('-');
				kt.splice(0,1);
				var k3 = kt.join('-');
				for (var n = 0; n < list.length; n++) {
					style = navigator.setStyleIntoCSS(zenGet(style),list[n],styleValues[list[n]]?true:false);
				}
				legend.setProperty('legendStyle',style);
				this.adjustSizes(false);
			}
			break;

		case 'legend-color':
		case 'legend-background':
		case 'legend-font-family':
		case 'legend-opacity':
			if (legend) {
				// pull 'legend-' off of key
				var kt = k2.toString().split('-');
				kt.splice(0,1);
				var k3 = kt.join('-');
				var style = zenGet(legend.legendStyle);
				style = navigator.setStyleIntoCSS(style,k3,value);
				legend.setProperty('legendStyle',style);
				this.adjustSizes(false);
				/* comment out JSL4483
				if (k2 == 'legend-opacity') {
					var legendDiv = document.getElementById(this.id+'/chartLegend');
					if (legendDiv != null) {
						legendDiv.style.background = 'transparent';
					}
				}
				*/
			}
			break;

		case 'legend-border-opacity':		// DTB171 - Add opacity
		case 'legend-border-stroke-width':
			value = isNaN(value) ? 0 : value;		// DTB215 - Do not allow NaN to get saved
		case 'legend-border-stroke':
		case 'legend-border-stroke-dasharray':
			if (legend) {
				// DTB169 - Border legend styling
				// pull 'legend-border' off of key
				var kt = k2.toString().split('-');
				kt.splice(0,2);
				var borderKey = kt.join('-');
				
				legend.setBorderStyle(borderKey,value);
				this.adjustSizes(false);		// DTB171 - Cause legend to respond to sliders
			}
			break;
			
		case 'legend-border-radius':
		case 'legend-font-size':
		case 'legend-padding':
		case 'legend-margin':
		case 'legend-top':
		case 'legend-left':
		case 'legend-height':
		case 'legend-width':
			value = value!=='' ? value+'px' : value;
			if (legend) {
				// pull 'legend-' off of key
				var kt = k2.toString().split('-');
				kt.splice(0,1);
				var k3 = kt.join('-');
				var style = zenGet(legend.legendStyle);
				style = navigator.setStyleIntoCSS(style,k3,value);
				legend.setProperty('legendStyle',style);
				this.adjustSizes(false);		// DTB171
			}
			break;
			
		// + WAL098
		case 'legend-title':
			if (legend) {
				legend.setProperty('legendTitle',value);
				this.adjustSizes(false);
			}
			break;
		case 'legend-showTitle':
			if (legend) {
				legend.setProperty('showLegendTitle',value);
				this.adjustSizes(false);
			}
			break;
		// - WAL098
		
		case 'legend-legendBoxShadow':
			// DTB170 - Toggle the box shadow using styling. No override means it is displayed via css class, 
			// an override sets it to zero, turning it off.
			if (legend) {
				if (value) {
					legend.setProperty('legendBoxStyle','');
				}
				else {
					legend.setProperty('legendBoxStyle','box-shadow:0px 0px;');
				}
			}
			break;
		}
	
		// update legend overrides
		if (final) {
			var widgetDef = this.getDefinition();
			if (widgetDef) {
				// DTB147 - call new method to obtain skip list
				var skip = this.getOverrideSkipList('legend');
				
				var jsonOver = this.componentToJSON(legend,0,skip);
				if (zenGet(widgetDef.themeOverrides['legend'])!=jsonOver) {
					widgetDef.overrides['legend'] = jsonOver;
				}
				else {
					delete widgetDef.overrides['legend'];
				}
			}
		}
		break;
	default:
		break;
	}
}

/// Test if there are any style overrides for this widget.
ClientMethod hasOverrides() [ Language = javascript ]
{
	var def = this.getDefinition();
	var cls = this.getSubtypeClass();
	return (def&&((cls&&def.overrides[cls])||def.overrides['legend']||def.overrides['pivot'])) ? true : false;
}

/// Reset any style overrides for this widget.
ClientMethod resetOverrides(themeOnly, recreate) [ Language = javascript ]
{
	themeOnly = zenGet(themeOnly,false);
	recreate = zenGet(recreate,true);
	var def = this.getDefinition();
	if (def && def.overrides) {
		for (var p in def.overrides) {
			delete def.overrides[p];
		}

		if (themeOnly) {
			// recreate non-theme properties in override
			var chart = this.findComponent('svgChart');
			var cls = this.getSubtypeClass();
			if (chart && cls!='') {
				var widgetDef = def;

				// copy save logic
				// DTB147 - call method to obtain skip list
				var skip = this.getOverrideSkipList('chart');
				

				// JMD1201
				// test properties against theme; skip any that are same as the theme
				if (widgetDef.themeOverrides['chart']) {
					var themeObj = ZLM.jsonParse(widgetDef.themeOverrides['chart']);
					if (themeObj) {
						for (var p in themeObj) {
							if (chart[p]==themeObj[p]) {
								skip[p] = true;
							}
						}
					}
				}

				var jsonOver = this.componentToJSON(chart,0,skip);
				widgetDef.overrides[cls] = jsonOver;
			}
		}

		if (recreate && zenPage.recreateWidget) {
			zenPage.recreateWidget(this.widgetKey);
		}
	}
}

/// Return an array of current style overrides for this widget.
/// Used to save to a theme.
ClientMethod getOverrides() [ Language = javascript ]
{
	var overrides = {};
	var def = this.getDefinition();
	if (def) {
		if (def.themeOverrides['pivot']) {
			overrides['pivot'] = def.themeOverrides['pivot'];
		}
		if (def.overrides['pivot']) {
			overrides['pivot'] = def.overrides['pivot'];
		}
		if (def.themeOverrides['legend']) {
			overrides['legend'] = def.themeOverrides['legend'];
		}
		if (def.overrides['legend']) {
			overrides['legend'] = def.overrides['legend'];
		}

		// JMD1201
		// theme settings are generic and saved under "chart"
		var chart = this.findComponent('svgChart');
		if (def.themeOverrides['chart']) {
			overrides['chart'] = def.themeOverrides['chart'];
		}
		if (chart) {
			var newTheme = {};
			var props = this.themeChartProperties.toString().split(',');
			for (var n = 0; n < props.length; n++) {
				var prop = props[n];
				newTheme[prop] = chart[prop];
			}
			var json = ZLM.jsonStringify(newTheme);
			if (json=='{}') {
				delete overrides['chart'];
			}
			else {
				overrides['chart'] = json;
			}
		}
	}

	return overrides;
}

/// Return the actual type used for a widget subtype (such as "barChart").
ClientMethod getSubtypeClass() [ Language = javascript ]
{
	var type = '';
	var chart = this.findComponent('svgChart');
	if (chart) {
		type = chart._type;
	}
	return type;
}

/// Change of time range selector control.
ClientMethod chartRangeChange(final) [ Language = javascript ]
{
	if (final) {
		var chart = this.findComponent('svgChart');
		var rangeControl = this.findComponent('rangeControl');
		chart.setTimeRange(rangeControl.startRange,rangeControl.endRange,final);
	}
}

/// Find the pivot table within this widget.
ClientMethod getPivot() [ Language = javascript ]
{
	return this.findComponent('table');
}

/// ongetSeriesColor handler for pivot chart.
ClientMethod chartGetSeriesColor(series) [ Internal, Language = javascript ]
{
	// JMD1259
	var b = 120 + (series*15);
	b = b>255?255:b;
	var color = 'rgb(160,160,'+b+')';

	// JMD1443 be a little smarter about pie chart colors
	// if there are items and only one series, use the items to drive colors
	var dim = 2;
	var controller = this.findComponent('table');
	var chart = this.findComponent('svgChart');
	
	// JMD1443 xyCharts handle series differently; we *should* encapsulate this
	// within the chart, but for now handle it here.
	if (chart && chart._type=='xyChart') {
		series = parseInt(series,10) + 1;
	}

	if (chart && !chart.hasAxes() && controller.getDimSize(2)==1) {
		dim = 1;
	}
	var name = controller.getLabel(series,dim);
	// + WAL119 -- remove measure labels from name if we are hiding measures
	if (name && controller.hideMeasures && (controller.hiddenMeasureText.length>=1)) {
		var nameText = name.split('/');
		for (var i = 0; i < nameText.length; ++i) {
			for (var j = 0; j < controller.hiddenMeasureText.length; ++j) {
				if (nameText[i] == controller.hiddenMeasureText[j]) {
					nameText.splice(i,1);	
					break;
				}
			}
		}
		name = nameText.join('/');
	}
	// - WAL119
	if (typeof name != 'undefined') {
		name = name.toString().toLowerCase();
	}
	if (name && this.dataColors[name]) {
		color = this.dataColors[name];
	}
	return color;
}

/// ongetSeriesColor handler for pivot chart.
ClientMethod chartGetSeriesColorsAsString(chart) [ Internal, Language = javascript ]
{
	// JSL4332
	var colors=[];
	for (var series=0; series < chart.getSeriesCount(); series++) {
		var color = this.chartGetSeriesColor(series);
		colors[series] = color;
	}
	return colors.join('~');
}

/// RenderData handler for pivot chart.
ClientMethod chartRenderHandler() [ Language = javascript ]
{
	var chart = this.findComponent('svgChart');
	var timeBased = chart.isTimeBased();
	if (timeBased && !chart.currMultiple && !chart._oldXMax) {
		// if chart has multiples; only process first one
		var rangeControl = this.findComponent('rangeControl');

		// set range of controller
		if (isNaN(parseInt(chart._xMinValue,10))) {
			rangeControl.setProperty('startRange','2012-01-01');
		}
		else {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(chart._xMinValue*1000);
			rangeControl.setProperty('startRange',zenDateToString(dt));
			rangeControl.setProperty('startTime',parseInt(zenDateToString(dt).substr(0,4))-1);		// DTB501 - Set a resaonable start point
		}
		if (isNaN(parseInt(chart._xMaxValue,10))) {
			rangeControl.setProperty('endRange','2012-12-31');
		}
		else {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(chart._xMaxValue*1000);
			rangeControl.setProperty('endRange',zenDateToString(dt));
			rangeControl.setProperty('endTime',parseInt(zenDateToString(dt).substr(0,4))+1);		// DTB501 - Set a resaonable end point
		}
	}
}

/// Perform a local drill down for a target widget.
ClientMethod executeDrillDown(dataSource) [ Internal, Language = javascript ]
{
	var pivot = this.getDataController();
	if (!pivot) {
		return;
	}

	if (!pivot.canDrillDown) {
		alert($$$Text('This pivot does not support drill down.','%DeepSee'));
		return;
	}

	if (this.pivotView == 'chart') {
		var chart = this.findComponent('svgChart');
		if (chart && !isNaN(parseInt(chart.selectedItem,10))) {
			// JMD1265: reset selected item
			var idx = parseInt(chart.selectedItem,10);
			chart.selectedItem = -1;
			pivot.rowDblClickHandler(null,1,idx+1);
			this.updateControlState();
		}
	}
	else {
		var select = pivot.getSelectedRange();
		if (select) {
			pivot.rowDblClickHandler(null,1,parseInt(select[0]));
			this.updateControlState();
		}
	}
}

/// Perform a local drill up for a target widget.
ClientMethod executeDrillUp() [ Internal, Language = javascript ]
{
	var pivot = this.getDataController();
	if (!pivot) {
		return;
	}
	if (this.pivotView == 'chart') {
		var chart = this.findComponent('svgChart');
		if (chart) {
			// JMD1265: reset selected item
			chart.selectedItem = -1;
		}
	}

	// DTB118 - replace goBack with removeDrillLevel so pivot can drill up after being loaded from a saved state	
	var prevDrillLevel = pivot.getDrillLevel()-1;
	pivot.removeDrillLevel(prevDrillLevel);
	
	this.updateControlState();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (('chart'==this.pivotView)&&(''!=this.getPivot().error)) {
		// DTB150 - Report the pivot error to the user by toggling to the table view
		this.toggleChart();
	}
	
	//+ begin JSL4419
	// DTB581 - Moved pivotVariable control handling to superclass
	//this.setBkgOpacity(this.opacity); // JSL4483
	return this.invokeSuper('onloadHandler',arguments); // JSL4419
	//+ end JSL4419
}

ClientMethod setBkgOpacity(opacity) [ Language = javascript ]
{
	//+ JSL4483 add this method
	if (typeof(opacity) == 'undefined') {
		opacity = 1.0;
	}
	var dragGroup = document.getElementById(this.id);
	if (dragGroup) {
		var backgroundColor = this.backgroundColor; // JSL4483
		if (backgroundColor) {
			var rgba = ZLM.convertColorToRGBA(backgroundColor,opacity);
			dragGroup.style.backgroundColor = 'rgba('+rgba+')';

		} else {
			dragGroup.style.backgroundColor = 'rgba(255,255,255,'+opacity+')';
		}
		
	}
	//var pivotDiv = document.getElementById(this.id+'/table');
	
	//- JSL4483
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	// This method added by JSL4483
	var widgetDef = this.getDefinition(); // JSL4483
	//if (property == 'opacity' || property == 'backgroundColor') {
	//	alert('setProperty property='+property+ ' value='+value);
	//}
	if (this.pivotView != 'table') {
		return this.invokeSuper('setProperty',arguments); // not a pivot table but a chart, use widget setProperty
	} else {
	}
	switch(property) {
	case 'opacity':
		//this.opacity = value; // JSL4483 for meters
		if (widgetDef) {
			widgetDef.opacity = value; // JSL4483
		}
		this.opacity = value // JSL4483 for pivots
		this.setBkgOpacity(value);	// JSL4483
		break;
	case 'backgroundColor':
		if (widgetDef) {
			widgetDef.backgroundColor = value; // JSL4483
		}
		this.backgroundColor = value; // JSL4483
		this.setBkgOpacity(this.opacity);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Test if this pivot widget is a chart
ClientMethod subtypeIsChart(subtype) [ Language = javascript ]
{
	// Method added by DTB150
	var chartTypes = {
		'areaChart':true,
		'barChart':true,
		'barChartStacked':true,
		'bubbleChart':true,
		'bullseyeChart':true,
		'columnChart':true,
		'columnChart3D':true,
		'columnChartStacked':true,
		'comboChart':true,
		'donutChart':true,
		'donutChart3D':true,
		'hilowChart':true,
		'lineChart':true,
		'lineChartMarkers':true,
		'pieChart':true,
		'pieChart3D':true,
		'swirlChart':true,
		'timeChart':true,
		'treeMapChart':true,
		'xyChart':true
	}
	
	if (chartTypes[subtype]) {
		return true;
	} else {
		return false;
	}
}

/// This is an API that can be called from a timer to perform a delayed disable/enable
/// of a prticular component. The target component is referenced by <var>componentId</var>
/// and if that component exists in the DOM, the method will call its<br>
/// setDisabled(flag)
ClientMethod componentSetDisabled(componentId, flag) [ Language = javascript ]
{
	// Method added by DTB841
	var component = zenPage.getComponentById(componentId);
	if (component && component.setDisabled) {
		component.setDisabled(flag);
	}
}

}
