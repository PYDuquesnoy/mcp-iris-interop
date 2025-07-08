/// This is the SnapGrid Demonstration page for the Zen demonstration application.
Class ZENDemo.SnapGridDemo Extends %ZEN.Component.page [ LegacyInstanceContext ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "SnapGrid Demo";

/// Domain used for localization.
Parameter DOMAIN = "ZENDEMO";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	font-size: 0.8em;
}

.svgFrame {
	border:0px solid black;
}

.dragChildren {
	overflow:hidden;
}

.dragGroup {
	border:0px solid black;
	margin:0px;
}

.snapGridWallpaper {
	background:#C0FFEE;
}

#snapGrid {
	border: 1px solid black;
	width: 90%;
	height: 550px;
	background: black;
}

#dgCalendar {
	background: #000000;
}

table.calendar {
	font-size: 10px;
}

table.calendarOutline {
	margin-left:auto;
	margin-right:auto;
}

</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" 
	title="Zen SnapGrid Demo">
<demo:demoTitle id="title" title="SnapGrid Demonstration"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="SnapGrid Demo" title="SnapGrid Demo" />
</locatorBar>

<hgroup valign="top">
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates Zen's snapGrid layout manager">
<demo:bullet text="A snapGrid is a specialized group that allows the user to drag and position its child dragGroup components within a fixed matrix of rows and columns."/>
<demo:bullet text="The snapGrid component supports interactive layout changes via mouse drag operations. DragGroups may be rearranged, resized or removed at will while in dynamic (edit) mode."/>
<demo:bullet text="The behavior of the snapGrid component is intended to create a tiled effect when in static mode.  DragGroups may overlap, but in static mode, the user has no way of revealing obscured window bits."/>
<demo:bullet text="The designer can specify up to two static layouts for the component, one for portrait and one for landscape presentation. If multiple layouts are specified the widget will select the one most apropos for the current geometry."/>
<demo:bullet text="The dragGroups are automatically restyled to reflect static versus dynamic mode for maximum use of screen real estate in static mode."/>
</demo:sidebar>
</vgroup>

<spacer width="20"/>
<vgroup cellVAlign="top" width="100%">
<hgroup>
<button caption="Update" onclick="zenPage.updateData();"/>
<button caption="Remove Headers" onclick="zenPage.removeHeaderStyles();"/>
<button caption="Restyle Headers" onclick="zenPage.restyleHeaderStyles();"/>
<button caption="Reset Headers" onclick="zenPage.resetHeaderStyles();"/>
<button caption="Add Column" onclick="zenPage.addColumn();"/>
<button caption="Remove Column" onclick="zenPage.removeColumn();"/>
<button caption="Add Row" onclick="zenPage.addRow();"/>
<button caption="Remove Row" onclick="zenPage.removeRow();"/>
<!--
<button caption="Force Narrow" onclick="zenPage.forceNarrow();"/>
-->
</hgroup>
<snapGrid id="snapGrid" cols="4" rows="4" >

<dragGroup id="dgCalendar" header="Calendar" onwindowgrab="zenPage.trackFocusWindow(zenThis);"
homeCol="0"  homeRow="0" colSpan="1" rowSpan="1" >
<calendar width="100%" height="100%" enclosingStyle="font-size:10px;"/>
</dragGroup>
<dragGroup id="dgChart" header="Chart" onresize="zenPage.resizeChart();"  onwindowgrab="zenPage.trackFocusWindow(zenThis);"
homeCol="1"  homeRow="0" colSpan="3" rowSpan="4" >
 <svgFrame id="svgChartFrame" 
	width="250px" 
	height="250px" 
	zoom="100"
	backgroundStyle="fill: black;"
	layout="horizontal">
<lineChart id="chart" 
	width="250" 
	height="250"
	title="Zen Chart"
	backgroundStyle="fill: black;"
	plotAreaStyle="fill: url(#glow-blueDiag);"
	plotStyle="stroke: black;"
	seriesColors="url(#glow-yellow)"
	seriesCount="1"
	seriesSize="12"
	marginRight="5"
	chartFilled="true"
	ongetData="return zenPage.getChartData(series);"
	ongetLabelX="return zenPage.getChartLabelX(value);"
	>
<yAxis id="yAxis"
	baseValue="0"
	minValue="-40" 
	maxValue="125" 
	majorUnits="25"
	minorUnits="5"
	title="Requests"
	minorGridLines="true"/>
</lineChart>
</svgFrame>
</dragGroup>

<dragGroup id="dgSpeed1" header="Speed1" onresize="zenPage.resizeMeter(1);"  onwindowgrab="zenPage.trackFocusWindow(zenThis);"
homeCol="0" homeRow="1" colSpan="1" rowSpan="1" >
 <svgFrame id="svgSpeed1Frame" 
	width="250px" 
	height="250px" 
	zoom="100"
	frameStyle="border-style:none;"
	backgroundStyle="fill: black;"
	layout="horizontal">
<speedometer id="speed1" 
	label="Important"
	animate="true"
	labelStyle="fill: yellow;"
	lowLampColor="url(#glow-green)"
	rangeUpper="100" width="250px" height="250px"/>
</svgFrame>
</dragGroup>

<dragGroup id="dgSpeed2" header="Speed2" onresize="zenPage.resizeMeter(2);" onwindowgrab="zenPage.trackFocusWindow(zenThis);"
homeCol="0" homeRow="2" colSpan="1" rowSpan="1" >
 <svgFrame id="svgSpeed2Frame" 
	width="250px" 
	height="250px" 
	zoom="100"
	frameStyle="border-style:none;"
	backgroundStyle="fill: black;"
	layout="horizontal">
<speedometer id="speed2" 
	label="Urgent"
	animate="true"
	labelStyle="fill: yellow;"
	lowLampColor="url(#glow-green)"
	rangeUpper="100" width="250" height="250"/>
</svgFrame>
</dragGroup>

<dragGroup id="dgSpeed3" header="Speed3" onresize="zenPage.resizeMeter(3);" onwindowgrab="zenPage.trackFocusWindow(zenThis);"
homeCol="0" homeRow="3" colSpan="1" rowSpan="1" >
 <svgFrame id="svgSpeed3Frame" 
	width="250px" 
	height="250px" 
	zoom="100"
	frameStyle="border-style:none;"
	backgroundStyle="fill: black;"
	layout="horizontal">
<speedometer id="speed3" 
	label="Overdue!"
	animate="true"
	labelStyle="fill: yellow;"
	lowLampColor="url(#glow-green)"
	rangeUpper="100" width="250" height="250"/>
</svgFrame>
</dragGroup>
</snapGrid>
</vgroup>
</hgroup>

</page>
}

/// Add a layout column to the abstract grid 
ClientMethod addColumn() [ Language = javascript ]
{
	zenPage.cols++;
	var g = zen("snapGrid");
	g.setProperty("cols",zenPage.cols);
	this.showCurrentGrid();
}

/// Remove a layout column to the abstract grid 
ClientMethod removeColumn() [ Language = javascript ]
{
	if (zenPage.cols<2) return;
	zenPage.cols--;
	var g = zen("snapGrid");
	g.setProperty("cols",zenPage.cols);
	this.showCurrentGrid();
}

/// Add a row to the underlying abstract grid
ClientMethod addRow() [ Language = javascript ]
{
	zenPage.rows++;
	var g = zen("snapGrid");
	g.setProperty("rows",zenPage.rows);
	this.showCurrentGrid();
}

/// Remove a row to the underlying abstract grid
ClientMethod removeRow() [ Language = javascript ]
{
	if (zenPage.rows<2) return;
	zenPage.rows--;
	var g = zen("snapGrid");
	g.setProperty("rows",zenPage.rows);
	this.showCurrentGrid();
}

/// Make a poor man's grid to show the drop zones and add it to the wallpaper
ClientMethod showCurrentGrid() [ Language = javascript ]
{
	var r = zenPage.rows;
	var c = zenPage.cols;
	var vPercent = 100/r;
	var hPercent = 100/c;
	var h = [];
	for (var i=1;i<r;i++) {
		h.push("<div style='width:100%;height:1px;position:absolute;top:"+(vPercent*i)+"%;left:0px;background:black;'></div>");
	}
	for (var i=1;i<c;i++) { 
		h.push("<div style='height:100%;width:1px;position:absolute;left:"+(hPercent*i)+"%;top:0px;background:black;'></div>");
	}
	var g = zen("snapGrid");
	var m = g.getGroupManager();
	var w = m.getWallpaperDiv();
	w.innerHTML = h.join(" ");
}

/// Method to get the SVG chart to scale accordingly each time its parent Drag Group is resized
ClientMethod resizeChart() [ Language = javascript ]
{
	var dragWin = zen("dgChart");
	if (dragWin.isResizeInProgress()) return; // wait for last event
	var h = dragWin.getWindowHeight()+1;
	if (h<2) return;
	var w = dragWin.getWindowWidth()+2;
	if (w<3) return;
	var svgWin = zen("svgChartFrame");
	svgWin.setProperty("width",w+"px");
	svgWin.setProperty("height",h+"px");
	var chart = zen("chart");
	chart.setProperty("width",w);
	chart.setProperty("height",h);
}

ClientMethod dumpObj(obj) [ Language = javascript ]
{
	ZLM.cerr(obj.id+":");
	ZLM.cerr("Home row: "+obj.homeRow);
	ZLM.cerr("Home column: "+obj.homeCol);
	ZLM.cerr("Row Span: "+obj.rowSpan);
	ZLM.cerr("Col Span: "+obj.colSpan);
}

/// Method to get the SVG meters to resize proportionally each time their parent Drag Group 
/// window is resized
ClientMethod resizeMeter(n) [ Language = javascript ]
{
	var dragWin = zen("dgSpeed"+n);
	if (dragWin.isResizeInProgress()) return; // wait for last event
	var h = dragWin.getWindowHeight()+1;
	if (h<2) return;
	var w = dragWin.getWindowWidth()+2;
	if (w<3) return;
	var svgWin = zen("svgSpeed"+n+"Frame");
	svgWin.setProperty("width",w+"px");
	svgWin.setProperty("height",h+"px");
	var meter = zen("speed"+n);
	meter.setProperty("width",w);
	meter.setProperty("height",h);
}

/// Use the snapGrid's broadcast capabilities to restyle all active drag groups to make
/// a more static, but zoom-able dashboard.  With the restyled headers the user can no longer
/// move windows around but can still elect to maximize individual windows by clicking on their
/// title bars
ClientMethod restyleHeaderStyles() [ Language = javascript ]
{
	var g = zen("snapGrid");
	g.broadcast("removeDragHeader");
	g.broadcast("disableResize");
	g.broadcast("enableHeaderMaxToggle");
	g.broadcast("setHeaderStyle","{'height':'16px','overflow':'hidden','borderBottom':'2px solid #ffff55','color':'#ffff55','background':'#000000','font':'bold 12px sans-serif' }");
	g.broadcast("setHeaderLayout","T");
	g.broadcast("resize");
	zenPage.headerMode = "simple";
}

/// Use the snapGrid's broadcast capabilities to remove the drag handles on all active drag groups 
/// to make a truly static-layout, read-only dashboard
ClientMethod removeHeaderStyles() [ Language = javascript ]
{
	var g = zen("snapGrid");
	g.broadcast("removeDragHeader");
	zenPage.headerMode = "none";
}

/// Restore all drag group headers to factory settings, restoring dragging and resizing ability
/// as well.
ClientMethod resetHeaderStyles() [ Language = javascript ]
{
	var g = zen("snapGrid");
	g.broadcast("setHeaderLayout","CIFT");
	g.broadcast("disableHeaderMaxToggle");
	g.broadcast("setHeaderStyle","{'color':'','background':'url(\"images/grayDragHeader.png\") repeat-x scroll 0 0 #23242C','font':'bold 14px sans-serif'}");
	g.broadcast("restoreDragHeader");
	zenPage.focusWindow = null;
	zenPage.headerMode = "full";
}

/// Paint the last active drag window a slightly different color
ClientMethod styleFocusHeader(div) [ Language = javascript ]
{
	var h = div.zenObj.getHeaderDiv();
	h.style.backgroundImage = 'url("images/btngradient.png")';
}

/// Restore original coloring of the given drag window
ClientMethod styleNormalHeader(div) [ Language = javascript ]
{
	var h = div.zenObj.getHeaderDiv();
	h.style.background = "";
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

ClientMethod onresizeHandler() [ Language = javascript ]
{
	var sg = zen("snapGrid");
	sg.forceRefresh();
}

ClientMethod forceNarrow() [ Language = javascript ]
{
	var sg = zen("snapGrid");
	sg.setProperty("width","50%");
}

/// Initialize the display and set a few status variables for internal operations
ClientMethod onloadHandler() [ Language = javascript ]
{
	var div = document.getElementById("snapGrid");
	div.style.overflow="hidden";
	zenPage.resizeAll();
	zenPage.rows = 4;
	zenPage.cols = 4;
	zenPage.headerMode = "full";
	zenPage.focusWindow = null;

	var sg = zen("snapGrid");
	sg.forceRefresh();
}

/// Log which drag window was touched last and style the drag header accordingly
ClientMethod trackFocusWindow(who) [ Language = javascript ]
{
	var div = who.getEnclosingDiv();
	if (zenPage.focusWindow && zenPage.focusWindow.parentNode) zenPage.styleNormalHeader(zenPage.focusWindow);
	zenPage.focusWindow = div;
	zenPage.styleFocusHeader(div);
}

/// Use the snapGrid's broadcast feature to ensure that all drag groups are making optimum 
/// use of their available space.
ClientMethod resizeAll() [ Language = javascript ]
{
	var g = zen("snapGrid");
	g.broadcast("resize");
}

/// Update components to show new data
ClientMethod updateData() [ Language = javascript ]
{
	var chart = this.getComponentById("chart");
	zenASSERT(chart,"Unable to find chart",arguments);
	chart.updateChart();

	this.getComponentById("speed1").setValue(Math.random() * 100);
	this.getComponentById("speed2").setValue(Math.random() * 100);
	this.getComponentById("speed3").setValue(Math.random() * 100);
}

/// Server-side method to calculate new chart data
ClassMethod getNewChartData() [ ZenMethod ]
{
	Set pts = 12
	Set data = ""
	For n = 1:1:pts {
		Set data = data _ $S(data="":"",1:":") _ $R(1000)
	}

	&js<zenPage.updateChart('#(data)#');>
}

/// Callback to provide data for chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	// generate random data
	// cache it in a local property
	var chart = zenPage.getComponentById('chart');
	if (null == this._data) {
		this._data = new Array(chart.seriesSize);
	}

	// slide data over; generate new value at end
	var value = 50;
	for (var i = 0; i < chart.seriesSize; i++) {
		var x = this._data[i+1];
		if (null != x) {
			value = x;
		}
		else {
			// at end or first-time
			if (Math.random() > 0.9) {
				value += (Math.random() * 50) - 30;
			}
			else {
				value += (Math.random() * 20) - 9;
			}
		}
		this._data[i] = value;
	}

	return this._data;
}

/// Callback to provide labels for chart.
ClientMethod getChartLabelX(val) [ Language = javascript ]
{
	// convert val to time-of-day
	var hour = (parseInt(val) + 8) % 12;
	
	if (hour == 0) {
		return '12pm';
	}
	else if (hour >=8) {
		return hour + 'am';
	}

	return hour + 'pm';
}

}

