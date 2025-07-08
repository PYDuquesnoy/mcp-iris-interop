/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog lets the user change the properties of a DeepSee chart.
Class %DeepSee.UI.Dialog.ChartOptions Extends %DeepSee.UI.Dialog.standardDialog [ System = 4 ]
{

Parameter APPLYBUTTON = 1;

/// Current selected chart type.
Property chartType As %ZEN.Datatype.string(ZENURL = "TYPE");

/// Current selected grid line type.
Property gridLineType As %ZEN.Datatype.string(ZENURL = "GRID");

/// Current selected text size.
Property textSize As %ZEN.Datatype.string(ZENURL = "TEXTSIZE");

/// Chart title.
Property chartTitle As %ZEN.Datatype.string(ZENURL = "TITLE");

/// Minimum axis value.
Property minValue As %ZEN.Datatype.float(ZENURL = "MIN");

/// Maximum axis value.
Property maxValue As %ZEN.Datatype.float(ZENURL = "MAX");

XData Style
{
<style type="text/css">

#chartIconBox, #gridLineBox, #textSizeBox {
	width: 500px;
	height: 52px;
	border: 1px solid darkgray;
	background: #F0F0F0;
	overflow: auto;
}

#chartIconBox {
	height: 150px;
}

.Icon,.IconSelected {
	padding: 4px;
	display: block;
	text-decoration: none;
	color: black;
}

.IconSelected {
	padding: 1px;
	border: 2px solid darkred;
}

.Icon:hover, .IconSelected:hover {
	background: #FFEEAA;
}

.Icon img {
	border: none;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<text id="title" label="Title" hint="Leave empty for automatic" value="#(%page.chartTitle)#" size="40" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>

<html label="Chart Type" id="chartIconBox" OnDrawContent="DrawIcons"/>

<html label="Grid Lines" id="gridLineBox" OnDrawContent="DrawGridLines"/>

<html label="Text Size" id="textSizeBox" OnDrawContent="DrawTextSize"/>

<hgroup>
<text id="min" label="Minimum Axis Value" hint="Leave empty for automatic" value="#(%page.minValue)#" size="9" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
<spacer width="25"/>
<text id="max" label="Maximum Axis Value" hint="Leave empty for automatic" value="#(%page.maxValue)#" size="9" onkeydown="return zenPage.ctrlKeyDown(zenEvent);"/>
</hgroup>
</pane>
}

/// Draw contents of chart icon box.
Method DrawIcons(pSeed As %String) As %Status
{
	Set tInfo(1,1) = $LB("BarChart",$$$Text("Bar Chart"),"portal/chart_bar.png")
	Set tInfo(1,2) = $LB("BarChart3D",$$$Text("3D Bar Chart"),"portal/chart_bar_3d.png")
	Set tInfo(1,3) = $LB("ColumnChart",$$$Text("Column Chart"),"portal/chart_bar_pivot.png")
	Set tInfo(1,4) = $LB("StackedBarChart",$$$Text("Stacked Bar Chart"),"portal/chart_bar_stacked.png")
	Set tInfo(1,5) = $LB("StackedColumnChart",$$$Text("Stacked Column Chart"),"portal/chart_bar_pivot_stacked.png")

	Set tInfo(2,1) = $LB("LineChart",$$$Text("Line Chart"),"portal/chart_line.png")
	Set tInfo(2,2) = $LB("LineChartMarker",$$$Text("Line Chart with Markers"),"portal/chart_line_marker.png")
	Set tInfo(2,3) = $LB("AreaChart",$$$Text("Area Chart"),"portal/chart_area.png")
	Set tInfo(2,4) = $LB("HiLowChart",$$$Text("High-Low Chart"),"portal/chart_hilow.png")
	Set tInfo(2,5) = $LB("XYChart",$$$Text("X-Y Chart"),"portal/chart_xy.png")
	// Set tInfo(2,6) = $LB("ComboChart",$$$Text("Combo Chart"),"portal/chart_combo.png")

	Set tInfo(3,1) = $LB("PieChart",$$$Text("Pie Chart"),"portal/chart_pie.png")
	Set tInfo(3,2) = $LB("PieChart3D",$$$Text("3D Pie Chart"),"portal/chart_pie_3d.png")
	Set tInfo(3,3) = $LB("DonutChart",$$$Text("Donut Chart"),"portal/chart_donut.png")
	Set tInfo(3,4) = $LB("DonutChart3D",$$$Text("3D Donut Chart"),"portal/chart_donut_3d.png")
	Set tInfo(3,5) = $LB("SwirlChart",$$$Text("Swirl Chart"),"portal/chart_swirl.png") // JSL4277

	&html<<table border="0">>
	Set tRow = $O(tInfo(""))
	While (tRow'="") {
		&html<<tr valign="middle">>
		Set tItem = $O(tInfo(tRow,""))
		While (tItem'="") {
			Set tName = $LG(tInfo(tRow,tItem),1)
			Set tTitle = $LG(tInfo(tRow,tItem),2)
			Set tImage = $LG(tInfo(tRow,tItem),3)
			&html<<td><a id="icon_#(tName)#" class="#($S(tName=..chartType:"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectChartType('#(tName)#');return false;"><img src="#(tImage)#" title="#(tTitle)#"/></a></td>>
			Set tItem = $O(tInfo(tRow,tItem))
		}
		&html<</tr>>
		Set tRow = $O(tInfo(tRow))
	}
	&html<</table>>
	Quit $$$OK
}

/// Draw contents of grid line icon box.
Method DrawGridLines(pSeed As %String) As %Status
{
	Set tInfo(1) = $LB("NoGrid",$$$Text("No Grid Lines"),"portal/view_box.png")
	Set tInfo(2) = $LB("YMajor",$$$Text("Y Axis Major Lines"),"portal/grid_ymajor.png")
	Set tInfo(3) = $LB("YMinor",$$$Text("Y Axis Minor Lines"),"portal/grid_ymajor_yminor.png")
	Set tInfo(4) = $LB("YMajorXMajor",$$$Text("X and Y Axis Major Lines"),"portal/grid_ymajor_xmajor.png")
	Set tInfo(5) = $LB("YMinorXMajor",$$$Text("X Axis Major and Y Axis Minor Lines"),"portal/grid_yminor_xmajor.png")

	&html<<table border="0"><tr valign="middle">>
	Set tItem = $O(tInfo(""))
	While (tItem'="") {
		Set tName = $LG(tInfo(tItem),1)
		Set tTitle = $LG(tInfo(tItem),2)
		Set tImage = $LG(tInfo(tItem),3)
		&html<<td><a id="grid_#(tName)#" class="#($S(tName=..gridLineType:"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectGridLineType('#(tName)#');return false;"><img src="#(tImage)#" title="#(tTitle)#"/></a></td>>
		Set tItem = $O(tInfo(tItem))
	}
	&html<</tr></table>>
	Quit $$$OK
}

/// Draw contents of text size box.
Method DrawTextSize(pSeed As %String) As %Status
{
	Set tInfo(1) = $LB("small",$$$Text("Small Text"),"10pt")
	Set tInfo(2) = $LB("medium",$$$Text("Medium Text"),"15pt")
	Set tInfo(3) = $LB("large",$$$Text("Large Text"),"20pt")

	&html<<table border="0"><tr valign="middle">>
	Set tItem = $O(tInfo(""))
	While (tItem'="") {
		Set tName = $LG(tInfo(tItem),1)
		Set tTitle = $LG(tInfo(tItem),2)
		Set tSize = $LG(tInfo(tItem),3)
		&html<<td><a id="text_#(tName)#" class="#($S(tName=..textSize:"IconSelected",1:"Icon"))#" href="#" onclick="zenPage.selectTextSize('#(tName)#');return false;" style="font-size:#(tSize)#;">Aa</a></td>>
		Set tItem = $O(tInfo(tItem))
	}
	&html<</tr></table>>
	Quit $$$OK
}

/// Zen page notification of an HTTP request.
ClassMethod %OnPreHTTP() As %Boolean [ Internal, ServerOnly = 1 ]
{
	Quit 1
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Chart Options")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Change the chart appearance.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	try {
		zen('title').focus();
		zen('title').select();
	}
	catch(ex) {
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		var main = this.getOpener();
		var chart = main.zenPage.getCurrentChart();
		var title = zen('title').getValue();
		var min = zen('min').getValue();
		var max = zen('max').getValue();

		if (chart) {
			main.zenPage.setChartOptions(this.chartType,this.gridLineType,this.textSize,title,min,max);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// Click on a new chart type.
ClientMethod selectChartType(type) [ Language = javascript ]
{
	if (this.chartType != type) {
		var a = self.document.getElementById('icon_' + this.chartType);
		if (a) {
			a.className = 'Icon';
		}

		this.chartType = type;
		var a = self.document.getElementById('icon_' + this.chartType);
		if (a) {
			a.className = 'IconSelected';
		}
	}
}

/// Click on a new grid line type.
ClientMethod selectGridLineType(type) [ Language = javascript ]
{
	if (this.gridLineType != type) {
		var a = self.document.getElementById('grid_' + this.gridLineType);
		if (a) {
			a.className = 'Icon';
		}

		this.gridLineType = type;
		var a = self.document.getElementById('grid_' + this.gridLineType);
		if (a) {
			a.className = 'IconSelected';
		}
	}
}

/// Click on a new text size.
ClientMethod selectTextSize(size) [ Language = javascript ]
{
	if (this.textSize != size) {
		var a = self.document.getElementById('text_' + this.textSize);
		if (a) {
			a.className = 'Icon';
		}

		this.textSize = size;
		var a = self.document.getElementById('text_' + this.textSize);
		if (a) {
			a.className = 'IconSelected';
		}
	}
}

}
