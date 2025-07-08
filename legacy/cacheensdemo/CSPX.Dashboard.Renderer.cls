/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsUI, Ensemble)

/// Defines a set of meters that form a Dashboard
/// and generates the SVG framework needed to display
/// the Dashboard.<br>
/// Users should not work directly with this class. 
Class CSPX.Dashboard.Renderer Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", CompileAfter = CSPX.Dashboard.Group, Inheritance = right, ProcedureBlock, System = 3 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter XMLNAME = "Dashboard";

/// List of meters displayed by this dashboard.
Property Meters As list Of Meter(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Direction in which to layout meters within this dashboard.
Property Orientation As %String(MAXLEN = 10, VALUELIST = ",horizontal,vertical", XMLPROJECTION = "attribute") [ InitialExpression = "horizontal" ];

/// Refresh rate, in milliseconds, for the dashboard.
Property RefreshRate As %Integer(MINVAL = 0, XMLPROJECTION = "attribute") [ InitialExpression = 10000 ];

/// Desired width, in logical units, of this dashboard.
Property Width As %Integer(XMLPROJECTION = "attribute") [ InitialExpression = 500 ];

/// The label displayed for the dashboard.
Property Label As %String(MAXLEN = 250, XMLPROJECTION = "ATTRIBUTE");

/// Default Business Metric service (config name) for this dashboard.
Property Metric As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// If defined, the accompanying info pane will display a set of instances for the default Metric.<br>
/// The value of this property is used as the Instance Menu caption.
Property InstanceMenu As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Insert a meter into this dashboard
Method InsertMeter(pMeter As Meter)
{
	Do ..Meters.Insert(pMeter)
}

///   Render the SVG for the set of meters
Method RenderSVG()
{
	// make list of all meter objects (flattened)
	Set id = 1
	Set stackptr = 1
	Set tGroup(stackptr) = $this
	Set tNum(stackptr) = 1
	Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))

	While ((stackptr > 0) && $IsObject(tMeter)) {
		Set objects(id) = tMeter
		Set tMeter.MeterId = id
		Set objParent(id) = $S(tGroup(stackptr)=$this:"",1:tGroup(stackptr))
		Set id = id + 1
		
		// find next item
		If (tMeter.%IsA("CSPX.Dashboard.Group")) {
			// recurse
			Set stackptr = stackptr + 1
			Set tGroup(stackptr) = tMeter
			Set tNum(stackptr) = 1
			Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))
		}
		Else {
			Set tNum(stackptr) = tNum(stackptr) + 1
			Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))
		}
		
		// do we need to pop items off the stack
		While ((stackptr > 0) && '$IsObject(tMeter)) {
			Set stackptr = stackptr - 1
			If (stackptr > 0) {
				Set tNum(stackptr) = tNum(stackptr) + 1
				Set tMeter = tGroup(stackptr).Meters.GetAt(tNum(stackptr))
			}
		}
	}

	// make list of all meter classes
	Set id = $O(objects(""))
	While (id '= "") {
		Set meter = objects(id)
		Set classes(meter.%ClassName(1)) = ""
		Set id = $O(objects(id))
	}

	// height of dashboard title
	Set tTitleHeight = $S(..Label="":0,1:15)

	// default instance value
	Set tDefInstance = $G(%request.Data("$ID2",1))

	// get initial level of all meters
	Set id = $O(objects(""))
	While (id '= "") {
		Set meter = objects(id)
		If (meter.Metric '= "") {

			// pull apart metric and instance
			Set tSC = ..ParseMetric(meter.Metric, tDefInstance, .tMetric, .tInstance)
			If ($$$ISERR(tSC) || (tInstance = "")) Quit

			// if no def instance, get one
			If (tDefInstance = "") {
				Set tDefInstance = $O($$$EnsMetrics(tMetric,""))
			}
			
			If (tInstance = "{Instance}") {
				Set tInstance = tDefInstance
			}
			If (tInstance = "") Quit

			Set meter.IsRunning = $G($$$EnsMetrics(tMetric,tInstance,"%IsRunning"),0)

			// special label handling for charts and grids
			If (meter.%IsA("CSPX.Dashboard.Chart")) {
				Do ..ProcessChartLabels(meter,tMetric,tInstance)
			}
			ElseIf (meter.%IsA("CSPX.Dashboard.Grid")) {
				Do ..ProcessGridLabels(meter,tMetric,tInstance)
			}
			Else {
				If (meter.Property '= "") {
					Set meter.Level = $G($$$EnsMetrics(tMetric,tInstance,meter.Property))
				}
			}
		}
		Else {
			// no metric for this meter: disable it
			Set meter.IsRunning = 0
		}
		Set id = $O(objects(id))
	}

	Write "<?xml version=""1.0"" ?>",!
	&html<<svg id="svg" zoomAndPan="disable" onload="Initialize()" >>

	// "head" sections

	// standard include
	Write "<script type='text/ecmascript' xlink:href='enssvg.js'/>",!

	Set cls = $O(classes(""))
	While (cls '= "") {
		Do $zobjclassmethod(cls,"OnSVGHead")
		Set cls = $O(classes(cls))
	}

  	// find svg font from localization file
  	Set tFont = $$$LocalizeText("Ensemble","FontFamily","tahoma,verdana")

	// style: 1 per meter type
	Write "<style type=""text/css""><![CDATA[",!

	&html<
	/* Generic styles */
text, tspan {
	font-family: #(tFont)#;
}

.Meter-canvas {
	fill: darkblue;
	stroke : gray;
	stroke-width : 1;
}
text.Meter-label {
	pointer-events: none;
	font-size: 8;
	fill: black;
	stroke: none;
}
.Meter-rect {
	fill: white;
	stroke: black;
	stroke-width: 0.5px;
	stroke-linejoin: round;
	opacity: 0.8;
}
.Meter-group {
	display: none;
}
.Meter-groupSelected {
	fill: lightgreen;
	opacity: 0.5;
	stroke: red;
	stroke-width: 1px;
	stroke-linejoin: round;
}

.Meter-isStopped {
	fill: gray;
	stroke: none;
	stroke-width: 0.5px;
	opacity: 0.5;
}
.Meter-isRunning {
	display: none;
}

	>
	
	Set cls = $O(classes(""))
	While (cls '= "") {
		Write $C(9),"/* Style for: ",cls," */",!
		Do $zobjclassmethod(cls,"OnSVGStyle")
		Set cls = $O(classes(cls))
	}
	Write "]]></style>>",!
	
	// defs: 1 per meter type
	&html<
	<defs id="defs">
	
<!-- context menu -->
<menu id="CanvasMenu" xmlns="http://mynamespace.com/">
    <header>Dashboard Menu</header>
	<item enabled="no" id="menu_drilldown" onactivate="drillDown();">#($$$Text("Drill Down"))#</item>
    <separator/>
    <menu id="menu_zoom">
	 <header>#($$$Text("Zoom"))#</header>
	 <item id="menu_zoom_33" onactivate="setZoom(33);">33%</item>
	 <item id="menu_zoom_50" onactivate="setZoom(50);">50%</item>
	 <item id="menu_zoom_75" onactivate="setZoom(75);">75%</item>
	 <item id="menu_zoom_88" onactivate="setZoom(88);">88%</item>
	 <item checked="yes" id="menu_zoom_100" onactivate="setZoom(100);">100%</item>
	 <item id="menu_zoom_110" onactivate="setZoom(110);">110%</item>
	 <item id="menu_zoom_125" onactivate="setZoom(125);">125%</item>
	 <item id="menu_zoom_150" onactivate="setZoom(150);">150%</item>
	 <item id="menu_zoom_200" onactivate="setZoom(200);">200%</item>
	 <item id="menu_zoom_300" onactivate="setZoom(300);">300%</item>
	 <item id="menu_zoom_400" onactivate="setZoom(400);">400%</item>
    </menu>
    <separator/>
	<item enabled="no" id="menu_changescale" onactivate="changeScale();">#($$$Text("Change Chart Scale"))#</item>
    <separator/>
	<item action="Find" id="Find">#($$$Text("Find..."))#</item>
	<item action="FindAgain" id="FindAgain">#($$$Text("Find Again"))#</item>
    <separator/>
    <item action='ViewSource'>#($$$Text("View Source..."))#</item>
    <item action="About">#($$$Text("About SVG Viewer..."))#</item>
</menu>

	<!-- filters -->
	<filter id="dropShadow" x="-2%" y="-2%" height="120%" width="120%">
	<feGaussianBlur in="SourceAlpha" stdDeviation="3" />
	<feOffset dx="4px" dy="4px" result="offsetBlur" />
	<feMerge>
		<feMergeNode in="offsetBlur"/>
		<feMergeNode in="SourceGraphic"/>
	</feMerge>
	</filter>
	
	<linearGradient id="bodyGrad" x1="0%" y1="0%" x2="100%" y2="0%">
	<stop offset="10%" style="stop-color:#DDEEFF" />
	<stop offset="90%" style="stop-color:blue" />
	</linearGradient>
	>

	Set cls = $O(classes(""))
	While (cls '= "") {
		Write "<!-- defs for: ",cls," -->",!
		Do $zobjclassmethod(cls,"OnSVGDefs")
		Set cls = $O(classes(cls))
	}
	
	// object-specific clipping paths
	Set id = $O(objects(""))
	While (id '= "") {
		Set meter = objects(id)
		
		&html<
<clipPath id="#(id)#_clipPath_label">
	<rect x="3" y="#(meter.Height-12)#" width="#(meter.Width-6)#" height="10" rx="2" />
</clipPath>
		>		
		Set id = $O(objects(id))
	}


	&html<</defs>>

	// general script: 1 per meter type
	Write "<script language=""text/javascript""><![CDATA[",!
	
	&js<

// external API object and methods
var api = new Object();

// array of meter objects
var meterList = new Array();
var labelList = new Array();

var mouseScale = 50;
var canvasName = 'dashboard';

function Initialize()
{
	canvasScale = 2;
	
	// replace context menu
	var newMenuRoot = parseXML(printNode(document.getElementById('CanvasMenu')), contextMenu);
	contextMenu.replaceChild( newMenuRoot, contextMenu.firstChild );

	// associate API methods with loading div in html parent
	api.setMeterProperty = setMeterProperty;
	api.getMetricList = getMetricList;
	api.setDefaultInstance = setDefaultInstance;

	// find loading div in outer html
	var loadingDiv = self.document.getElementById("loading");

	loadingDiv.api = api;
	topGroup.arrangeMeters();
	topGroup.alignMeters();
	
	// set size and view box
	svg = document.getElementById("canvasSVG");
	svg.setAttribute("viewBox","0 0 " + topGroup.width + " " + (topGroup.height + #(tTitleHeight)#));

	setCanvasSize(topGroup.width,topGroup.height + #(tTitleHeight)#);
	setZoom(getCookie(canvasName,100));
	
	// Set dashboard label
	setTextNode('DashboardLabel',resolveValue(topGroup.label));
	
	// Update labels
	for (id in labelList){
		var label = labelList[id];
		setTextNode(id + '_label',resolveValue(label));
	}

	// initialize meter levels
	for (id in meterList){
		var meter = meterList[id];
		if (meter.seriesData) {
			for (var i = 0; i != meter.seriesData.length; i++) {
				var data = meter.seriesData[i];
				meter.seriesData[i] = null; // force initial update
				meter.setProperty('series',data,i);
			}
		}
		else {
			var level = meter.level;
			meter.level = null; // force initial update
			meter.setProperty('level',level);

			// !!!
			if (meter.propertyCount != 1) {
				meter.setProperty('level',0,1);
			}
		}
	}
	
	if (loadingDiv) {
		loadingDiv.style.display = 'none';
	}

	// tell container to start auto-refresh
	self.startAutoRefresh();
	
	// tell container default instance value
	self.initDefaultInstance(defaultInstance);
}

// set the value of the results element for the external system to read.
function canvas_setResultsDiv(value)
{
	// find results div
	var results = self.document.getElementById("results");

	// place value into results
	if (results) {
		results.innerHTML = value;
	}
}

// raise an event for the external system
function canvas_raiseEvent(type)
{
	self.raiseEvent(type);
}

// set a property for the specified meter
function setMeterProperty(id,property,value,idx)
{
	// dispatch to appropriate meter callback
	var meter = meterList[id];
	if (meter) {
		if (!meter.setProperty(property,value,idx)) {
			// invoke default method
			Meter_setProperty(meter,property,value,idx);
		}
		
		// update property sheet for current item
		if (meter.meterId == currMeterId) {
			switch (property) {
			case 'level':
				self.updatePropertyPane(meter.level,resolveValue(meter.metric));
				break;
			}
		}
	}
}

// Make list of metrics we are interested in id order
function getMetricList()
{
	var list = '';
	
	for (id in meterList){
		var meter = meterList[id];
		if (meter.seriesData) {
			// chart: update each series
			for (i = 0; i != meter.seriesProperty.length; i++) {
				// meter
				if (meter.metric != '' && meter.seriesProperty[i] != '') {
					if ('Grid' == meter.type) {
						list += '^' + id + ':' + resolveValue(meter.metric) + ':' + meter.seriesProperty[i] + ':' + i + ':S:' + meter.method + ':' + (meter.isRunning ? '1' : '0') + ':' + meter.defList + ':' + meter.seriesInstance[i] + ':Grid:' + meter.columns + ':' + meter.rows;
					}
					else {
						// chart
						list += '^' + id + ':' + resolveValue(meter.metric) + ':' + meter.seriesProperty[i] + ':' + i + ':S:' + meter.method + ':' + (meter.isRunning ? '1' : '0') + ':' + meter.defList + ':' + meter.seriesInstance[i] + ':' + meter.xDimension;
					}
				}
			}
		}
		else {
			// meter
			if (meter.metric != '' && meter.property != '') {
				list += '^' + id + ':' + resolveValue(meter.metric) + ':' + meter.property + ':0:L:' + meter.method + ':' + (meter.isRunning ? '1' : '0') + ':' + meter.defList + ':' + ':';
			}
			if (meter.propertyCount != 1) {
				// make more generic!!!
				if (meter.metric != '' && meter.odometerProperty != '') {
					list += '^' + id + ':' + resolveValue(meter.metric) + ':' + meter.odometerProperty + ':1:L:' + meter.method + ':' + (meter.isRunning ? '1' : '0') + ':' + meter.defList + ':' + ':';
				}
			}
		}
		
		// see if we need to evaluate labels !!!
		if (meter.labelSource && meter.labelSource != '') {
			list += '^' + id + ':' + resolveValue(meter.metric) + ':' + meter.labelSource + ':' + 'labels' + ':S:' + ':' + (meter.isRunning ? '1' : '0') + ':' + meter.defList + ':' + ':';
		}
	}

	return list;
}

// resolves any instance variable within a name
function resolveValue(name)
{
	return(name.replace(/{Instance}/g,defaultInstance));
}

var defaultInstance = '#(tDefInstance)#';
function setDefaultInstance(inst)
{
	if (defaultInstance != inst) {
		defaultInstance = inst;
		
		// update dashboard label
		setTextNode('DashboardLabel',resolveValue(topGroup.label));
		
		// Update labels
		for (id in labelList){
			var label = labelList[id];
			setTextNode(id + '_label',resolveValue(label));
		}

		// force info pane update
		canvas_raiseEvent("SELECT");
	}
}

// Group methods

// add a meter to this group
function Group_addMeter(meter)
{
	this.children[this.children.length] = meter;
	meter.parent = this;
}

// arrange all meters within a group;
// adjust the width and height of this group
function Group_arrangeMeters()
{
	var xpos = this.xPos;
	var ypos = this.yPos;
	
	// loop over all children (meters)
	for (var n = 0; n != this.children.length; n++) {
		var meter = this.children[n];
		moveMeter(meter.meterId,xpos,ypos);
		if (meter.type == 'Group') {
			// recurse
			meter.arrangeMeters();
		}
		
		// adjust size of this group
		if (greaterThanEq(xpos-this.xPos+meter.width,this.width)) {
			this.width = xpos-this.xPos+meter.width;
		}
		if (greaterThanEq(ypos-this.yPos+meter.height,this.height)) {
			this.height = ypos-this.yPos+meter.height;
		}

		// set placement for next item
		if (this.orientation == 'horizontal') {
			xpos = xpos + meter.width;
		}
		else {
			ypos = ypos + meter.height;
		}
	}
}

// align all meters within a group;
// assume that meters have been arranged first
function Group_alignMeters()
{
	return; // ignore
	
	if (this.children.length == 0) {
		return;
	}
	
	var xShift = 0;
	var yShift = 0;
	var meter = null;

	if (this.orientation == 'horizontal') {
		if (this.align == 'right') {
			meter = this.children[this.children.length - 1];
			xShift = this.width - (meter.xPos + meter.width);
		}
		else if (this.align == 'center') {
			meter = this.children[this.children.length - 1];
			xShift = (this.width - (meter.xPos + meter.width)) / 2;
		}
		else { // left
			xShift = 0;
		}
	
		// now shift the meters	
		for (var n = 0; n != this.children.length; n++) {
			meter = this.children[n];
			moveMeter(meter.meterId,meter.xPos + xShift,meter.yPos);
			if (meter.type == 'Group') {
				// recurse
				meter.alignMeters();
			}
		}
	}
	else {
		// now shift the meters	
		for (var n = 0; n != this.children.length; n++) {
			meter = this.children[n];
			//moveMeter(meter.meterId,meter.xPos + xShift,meter.yPos);
			if (meter.type == 'Group') {
				// recurse
				meter.alignMeters();
			}
		}
	}
}

// Go to the link associate with this meter
function drillDown()
{
	var meter = meterList[currMeterId];
	if (meter && meter.link != '') {
		self.gotoPage(resolveValue(meter.link) + (meter.link.indexOf('?') == -1 ? '?' : '&') + 'METRIC=' + escape(resolveValue(meter.metric)) + '&PROPERTY=' + escape(meter.property));
	}
}

// Change current scale for chart
function changeScale()
{
	var meter = meterList[currMeterId];
	if (meter && meter.chart) {
		meter.chart.toggleScale();
	}
}

// event handling

var currMeterId = null;
var currOperation = null;

function selectMeter(id)
{
	if (currMeterId == id) {
		return;
	}

	// unhighlight
	if (currMeterId) {
		var rect = document.getElementById(currMeterId + "_BoundingRect");
		rect.setAttribute("class","Meter-group");
	}
	
	currMeterId = id;
	// highlight
	if (currMeterId) {
		var rect = document.getElementById(currMeterId + "_BoundingRect");
		rect.setAttribute("class","Meter-groupSelected");
	}
	
	var drill = false;
	var scale = false;
	
	if (currMeterId) {
		// update info pane
		var meter = meterList[currMeterId];
		canvas_setResultsDiv(meter.getInfo());

		// enable drill menu?
		if (meter.link != '') {
			drill = true;
		}

		// enable scale menu?
		if (meter && meter.chart && meter.independentScale) {
			scale = true;
		}
	}
	else {
		canvas_setResultsDiv('');
	}

 	setMenuItemOption("enabled","menu_drilldown", "", drill);
 	setMenuItemOption("enabled","menu_changescale", "", scale);

	canvas_raiseEvent("SELECT");
}

function Meter_getInfo()
{
	var prop = this.property;
	if (this.seriesProperty) {
		prop = 'N/A';
	}
	
	var info = "Type:STRING:" + this.type + "\x01" + 
			"Label:STRING:" + resolveValue(this.label) + "\x01" + 
			"Status:STRING:" + (this.isRunning ? "Running" : "Stopped" ) + "\x01" + 
			"Description:STRING:" + this.description + "\x01" +
			"Metric:METRIC:" + resolveValue(this.metric) + "\x01" +
			"Property:STRING:" + prop + "\x01" +
			"Units:STRING:" + this.units + "\x01" +
			"Level:LEVEL:" + this.level + "\x01" +
			"RangeLower:NUMBER:" + this.rangeLower + "\x01" +
			"RangeUpper:NUMBER:" + this.rangeUpper + "\x01" +
			"ThresholdLower:NUMBER:" + this.thresholdLower + "\x01" +
			"ThresholdUpper:NUMBER:" + this.thresholdUpper + "\x01" +
			"ScaleFactor:NUMBER:" + this.scaleFactor + "\x01";
	
	// additional info for charts		
	if (this.seriesProperty && this.seriesLabel && this.seriesColor) {
		var series = 'Legend:LEGEND:';
		for (i = 0; i != this.seriesLabel.length; i++) {
			series += this.seriesLabel[i];
			series += "^" + this.seriesColor[i] + ";";
		} 
		info += series + "\x01";;
	}
			
	return info;
}

// enable/disable this meter
function Meter_enable(flag)
{
	if (flag != this.IsRunning) {
		this.isRunning = flag;
		var rect = document.getElementById(this.meterId + "_IsRunningRect");
		var style = flag ? "Running" : "Stopped";
		rect.setAttribute("class","Meter-is" + style);
	}
}

// default implementation of setProperty
function Meter_setProperty(meter,property,value,idx)
{
	switch (property) {
	case 'enabled':
		meter.enable(value);
		break;
	case 'rangeLower':
	case 'rangeUpper':
	case 'thresholdLower':
	case 'thresholdUpper':
	case 'link':
	case 'units':
		meter[property] = value;
		break;
	}
}

function moveMeter(id,xpos,ypos)
{
	var group = document.getElementById(id + "_Group");
	group.setAttribute("transform","translate(" + xpos + "," + ypos + ")");

	var meter = meterList[id];
	meter.xPos = xpos;
	meter.yPos = ypos;
}

// mouse events
function canvasMouseDown(evt)
{
	evt.stopPropagation();
	selectMeter(null);
}

function canvasMouseMove(evt)
{
	evt.stopPropagation();

	if (currMeterId && (currOperation == 'move')) {
		// move meter
		var coord = document.getElementById("canvasSVG");
		var xoff = coord.getAttribute("x") * 1;
		var yoff = coord.getAttribute("y") * 1;

		// update position of selected items
		var dx = ((evt.clientX * (mouseScale/currZoom)) + deltaX) - moveShape.xPos;
		var dy = ((evt.clientY * (mouseScale/currZoom)) + deltaY) - moveShape.yPos;

		moveMeter(currMeterId,(evt.clientX * (mouseScale/currZoom)) - xoff, (evt.clientY * (mouseScale/currZoom)) - yoff);
	}
}

function canvasMouseUp(evt)
{
	evt.stopPropagation();
	
	if (currMeterId && (currOperation == 'move')) {
		currOperation = null;
		moveShape = null;
	}	
}

function canvasMouseOver(evt)
{
	evt.stopPropagation();
}

var deltaX = 0;
var deltaY = 0;
var moveShape = null;

function meterMouseDown(evt,id)
{
	evt.stopPropagation();
	var el = evt.getTarget();
	selectMeter(id);
	var meter = meterList[id];
	
	return; // !!!
	
	// figure out offset of mouse from shape...
	deltaX = meter.xPos - (evt.clientX * (mouseScale/currZoom));
	deltaY = meter.yPos - (evt.clientY * (mouseScale/currZoom));
	moveShape = meter;
	
	currOperation = 'move';
}


// -------------------------------------------------------------------

// Utility methods:

// Set the contents of text element id to str
function setTextNode(id,str)
{
	var text = document.getElementById(id);
	if (!text) {
		return;
	}

	// show first line only
	
	// create next text node and replace the current one
	var oldNode = text.firstChild;
	if (oldNode) {
		text.removeChild(oldNode);
	}
	var txt = '';
	
	// make sure str is a string
	str = str + "";
	if (str) {
		var t = str.split('\n');
		txt = t[0];
	}
	var textNode;
	textNode = document.createTextNode(txt);
	text.appendChild(textNode);
}
>
	// !!! workaround functions
	Write "function lessThanEq(a,b) { return a <= b; }",!
	Write "function greaterThanEq(a,b) { return a >= b; }",!
	Write "function between(val,a,b) { return ((val >= a) && (val <= b)); }",!

	Write "// class specific scripts",!

	Set cls = $O(classes(""))
	While (cls '= "") {
		Write "// script for: ",cls,!
		Do $zobjclassmethod(cls,"OnSVGScript")
		Set cls = $O(classes(cls))
	}

	Write "// top level group",!
	&js<
var topGroup = new Object();
topGroup.children = new Array();
topGroup.type = 'Group';
topGroup.orientation = '#(..Orientation)#';
topGroup.width = 0;
topGroup.height = 0;
topGroup.xPos = 0;
topGroup.yPos = #(tTitleHeight)#;
topGroup.arrangeMeters = Group_arrangeMeters;
topGroup.alignMeters = Group_alignMeters;
topGroup.addMeter = Group_addMeter;
topGroup.label = '#(..Label)#';
	>

	Write "// construct meter objects",!

	// specific js code for each meter
	Set id = $O(objects(""))
	While (id '= "") {
		Set meter = objects(id)

		// create meter object & links to methods
		&js<

// -------------------------------		
// meter: #(id)#
var meter = new Object();
meterList[#(id)#] = meter;
meter.type = '#($ZCVT(meter.%ClassName(),"O","JS"))#';
meter.getInfo = Meter_getInfo;
meter.enable = Meter_enable;
>
		
		If (objParent(id) = "") {
			&js<
topGroup.addMeter(meter);
			>
		}
		Else {
			&js<
meterList[#(objParent(id).MeterId)#].addMeter(meter);
			>
		}

		If (meter.ShowLabel) {
			&js<labelList[#(id)#]='#($ZCVT(meter.Label,"O","JS"))#';>
		}

		// setProperty method: based on class name
		Write "meter.setProperty = ",meter.%ClassName(0),"_setProperty;",!

		// Initialize client properties
		Do meter.SetClientProperties()
		
		// callback to get user JS
		Do meter.OnSVGInitJS()

		Set id = $O(objects(id))
	}
	Write "]]></script>>"

	// canvas
	&html<
	<svg id="canvasSVG" x="0" y="0" width="100%" height="100%" >
	<g id="canvas" 
		onmousedown="canvasMouseDown(evt);"
		onmousemove="canvasMouseMove(evt);"
		onmouseup="canvasMouseUp(evt);"
		onmouseover="canvasMouseOver(evt);"
	>
	<rect class="Meter-canvas" x="0%" y="0%" width="100%" height="100%" />
	>
	
	// dashboard title
	If (..Label '= "") {
		&html<
			<rect class="Meter-rect" x="20%" y="2" height="#(tTitleHeight-4)#" width="60%" rx="2" />
			<text class="Meter-label" id="DashboardLabel" x="50%" y="#(tTitleHeight-4)#" text-anchor="middle"> </text>
		>
	}

	// meter bodies: 1 per object
	Set id = $O(objects(""))
	While (id '= "") {
		Set meter = objects(id)

		&html<<g id="#(id)#_Group" transform="translate(#(meter.XPos)#,#(meter.YPos)#)" onmousedown="meterMouseDown(evt,#(id)#);" >>
		&html<<rect id="#(id)#_BoundingRect" class="Meter-group" x="1" y="1" height="#(meter.Height-2)#" width="#(meter.Width-2)#" rx="3" />>
			
		Do meter.OnSVGBody()

		// common label for meters
		If (meter.ShowLabel) {
			&html<
				<rect class="Meter-rect" x="3" y="#(meter.Height-12)#" height="10" width="#(meter.Width-6)#" rx="2" />
				<text id="#(id)#_label" class="Meter-label" x="#(meter.Width/2)#" y="#(meter.Height-4)#" text-anchor="middle" style="clip-path:url(#("#"_id)#_clipPath_label);">#(meter.Label)#</text>
			>
		}

		// shroud for meters that are not running
		Set stopped = $S(meter.IsRunning:"Running",1:"Stopped")
		&html<<rect id="#(id)#_IsRunningRect" class="Meter-is#(stopped)#" x="0" y="0" height="#(meter.Height)#" width="#(meter.Width)#" />>

		&html<</g>>

		Set id = $O(objects(id))
	}
	&html<</g></svg></svg>>
	Quit $$$OK
}

/// Called by Dashboard class to generate code to
/// create an instance of this object.
/// The object instance is called <var>pDashboard</var>.
Method GenerateCode(pCode As %CharacterStream) As %Status
{
	Do:(..Label'="") pCode.WriteLine(" Set pDashboard.Label=""" _ ..Label _ """")
	Do:(..Metric'="") pCode.WriteLine(" Set pDashboard.Metric=""" _ ..Metric _ """")
	Do:(..Orientation'="") pCode.WriteLine(" Set pDashboard.Orientation= """ _ ..Orientation _ """")
	Do:(..Width'="") pCode.WriteLine(" Set pDashboard.Width= " _ ..Width)
	Do:(..RefreshRate'="") pCode.WriteLine(" Set pDashboard.RefreshRate= " _ ..RefreshRate)
	Do:(..InstanceMenu'="") pCode.WriteLine(" Set pDashboard.InstanceMenu= """ _ ..InstanceMenu _ """")
	Quit $$$OK
}

/// Pull apart a Metric value into metric name and instance name.
ClassMethod ParseMetric(pMetric As %String, pDefaultInstance As %String, Output pMetricName As %String, Output pInstance As %String) As %Status
{
	Set tSC = $$$OK

	// pull apart metric and instance
	Set pMetricName = $P(pMetric,"(",1)
	Set pInstance = $P($P(pMetric,"(",2),")",1)

	If (pInstance = "") {
		// find first instance for metric
		Set pInstance = $O($$$EnsMetrics(pMetricName,""))
	}
	Else {
		// see if instance is a {} variable
		If (($E(pInstance,1) = "{") && ($E(pInstance,$L(pInstance)) = "}")) {
			Set tVar = $E(pInstance,2,$L(pInstance)-1)
			If (tVar = "Instance") {
				// the client will resolve this
				Set pInstance = "{Instance}"
			}
			ElseIf $IsObject($G(%request)) {
				Set pInstance = $G(%request.Data(tVar,1))
			}
			Else {
				Set pInstance = ""
			}
		}
	}
	
	Quit tSC
}

/// Evaluate a metric name and return a form suitable for the client.
ClassMethod EvalMetric(pMetric As %String, pDefaultInstance As %String = "") As %String
{
	Set tMetric = ""
	If (pDefaultInstance = "") {
		If $IsObject($G(%request)) {
			Set pDefaultInstance = $G(%request.Data("$ID2",1))
		}
	}
	
	Set tSC = ..ParseMetric(pMetric,pDefaultInstance,.tMetric,.tInstance)
	If ($$$ISOK(tSC) && (pMetric [ "(") && (tInstance '= "")) {
		Quit tMetric _ "(" _ tInstance _ ")"
	}

	Quit tMetric
}

/// Special label and initial data processing for charts
Method ProcessChartLabels(meter As Meter, tMetric As %String, tInstance As %String)
{
	// see if we need labels
	If (meter.LabelSource '= "") {
		// evaluate label source property for labels
		Set labels = ""
		Set src = $O($$$EnsMetrics(tMetric,tInstance,meter.LabelSource,""))
		While (src '= "") {
			Set labels = labels _ $S(labels="":"",1:":") _ $G($$$EnsMetrics(tMetric,tInstance,meter.LabelSource,src),"none")
			Set src = $O($$$EnsMetrics(tMetric,tInstance,meter.LabelSource,src))
		}
		Set meter.XLabels = labels
	}

	If (meter.XDimension = "instances") {
		Set labels = ""
		Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
		While (tSeriesInstance '= "") {
			Set labels = labels _ $S(labels="":"",1:":") _ tSeriesInstance
			Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
		}
		Set meter.XLabels = labels
	}
	
	// loop over series definitions
	Set labels = ""
	For i=1:1:meter.SeriesList.Count() {
		Set tSeries = meter.SeriesList.GetAt(i)
		Set data = ""

		If (tSeries.Property '= "") {
			If (meter.XDimension = "instances") {
				// loop over instances
				Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
				While (tSeriesInstance '= "") {
					Set data = data _ $S(data="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property),0))
					Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
				}
			}
			Else {
				// default: loop over nodes for current instance
				Set tSeriesInstance = $S(tSeries.Instance="":tInstance,1:tSeries.Instance)
				Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,""))
				While (key '= "") {
					Set data = data _ $S(data="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key),0))
					Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key))
				}
				
				// pick up x labels
				Set labels = labels _  $S(labels="":"",1:":") _ tSeries.Label
			}
		}
		
		Set tSeries.Data = data
	}

	Set showXLabels = 0
	If (meter.XDimension = "instances") {
		// we already have labels
		Set showXLabels = 0
	}
	ElseIf (meter.LabelSource '= "") {
		// we already have labels
		Set showXLabels = 0
	}
	ElseIf (meter.XDimension [ "series") {
		// use series labels
		Set showXLabels = 1
	}
	Else {
		// test style
		Set showXLabels = (","_$ZCVT(meter.Style,"L")_",")["xlabels"
	}
	
	If ((showXLabels) && (labels '= "")) {
		Set meter.XLabels = labels
	}
}

/// Special label and initial data processing for grids
Method ProcessGridLabels(meter As Meter, tMetric As %String, tInstance As %String)
{
	// see if we need labels
	Set tColType = $S($IsObject(meter.Columns):meter.Columns.Source,1:"")
	Set tRowType = $S($IsObject(meter.Rows):meter.Rows.Source,1:"")
	Set tColSize = $S($IsObject(meter.Columns):meter.Columns.Size,1:"")
	Set tRowSize = $S($IsObject(meter.Rows):meter.Rows.Size,1:"")
	Set tColReverse = $S($IsObject(meter.Columns):meter.Columns.Reverse,1:0)
	Set tRowReverse = $S($IsObject(meter.Rows):meter.Rows.Reverse,1:0)

	If (tColType = "instances") {
		// get current set of instances
		Set labels = ""
		Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
		While (tSeriesInstance '= "") {
			Set labels = labels _ $S(labels="":"",1:":") _ tSeriesInstance
			Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
		}
		Set meter.ColLabels = labels
		Set meter.Unsupported = $Case(tRowType,"instances":1,:0)

		// loop over rows to get data
		If (tRowType = "series") {
			For i=1:1:meter.Rows.SeriesList.Count() {
				Set tSeries = meter.Rows.SeriesList.GetAt(i)
				Set data = ""

				If (tSeries.Property '= "") {
					// loop over instances
					Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
					While (tSeriesInstance '= "") {
						Set data = data _ $S(data="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property)))
						Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
					}
				}
				Set tSeries.Data = data
			}
		}
		ElseIf (tRowType = "history") {
			// get data
			Set tSeries = meter.Rows.SeriesList.GetAt(1)
			Set data = ""

			If ($IsObject(tSeries) && (tSeries.Property '= "")) {
				// loop over instances
				Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
				While (tSeriesInstance '= "") {
					// loop over history
					Set series = ""
					Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,""))
					While (key '= "") {
						Set series = series _ $S(series="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key)))
						Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key))
					}
					// assemble one list of all values
					Set data = data _ $S(data="":"",1:"^") _ series
					Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
				}
			}
			Set tSeries.Data = data
		} 
	}
	ElseIf (tColType = "series") {
		// default: loop over row series and get labels
		Set labels = ""
		For i=1:1:meter.Columns.SeriesList.Count() {
			Set tSeries = meter.Columns.SeriesList.GetAt(i)
			Set tSeriesInstance = $S(tSeries.Instance="":tInstance,1:tSeries.Instance)
			Set data = ""
			Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,""))
			While (key '= "") {
				Set data = data _ $S(data="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key)))
				Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key))
			}

			Set tSeries.Data = data

			// pick up labels
			Set labels = labels _  $S(labels="":"",1:":") _ tSeries.Label
		}
		Set meter.ColLabels = labels
		Set meter.Unsupported = $Case(tRowType,"series":1,:0)
	}
	ElseIf (tColType = "history") {
		Set sz = $S(tColSize="":5,1:tColSize)
		Set labels = ""
		For i=1:1:sz {
			Set labels = labels _  $S(labels="":"",1:":") _ i
		}
		Set meter.ColLabels = labels
		Set meter.Unsupported = $Case(tRowType,"history":1,:0)
	}
	ElseIf (tColType = "") {
		Set meter.ColLabels = meter.Property
		Set meter.Unsupported = $Case(tRowType,"":1,:0)
	}
	Else {
		Set meter.ColLabels = "N/A"
		Set meter.Unsupported = 1
	}

	If (tRowType = "instances") {
		// get current set of instances
		Set labels = ""
		Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
		While (tSeriesInstance '= "") {
			Set labels = labels _ $S(labels="":"",1:":") _ tSeriesInstance
			Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
		}
		Set meter.RowLabels = labels

		// loop over cols to get data
		If (tColType = "series") {
			For i=1:1:meter.Columns.SeriesList.Count() {
				Set tSeries = meter.Columns.SeriesList.GetAt(i)
				Set data = ""

				If (tSeries.Property '= "") {
					// loop over instances
					Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
					While (tSeriesInstance '= "") {
						Set data = data _ $S(data="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property)))
						Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
					}
				}
				Set tSeries.Data = data
			}
		}
		ElseIf (tColType = "history") {
			// get data (copy of Row=history, col=instance case)
			Set tSeries = meter.Columns.SeriesList.GetAt(1)
			Set data = ""

			If ($IsObject(tSeries) && (tSeries.Property '= "")) {
				// loop over instances
				Set tSeriesInstance = $O($$$EnsMetrics(tMetric,""))
				While (tSeriesInstance '= "") {
					// loop over history
					Set series = ""
					Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,""))
					While (key '= "") {
						Set series = series _ $S(series="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key)))
						Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key))
					}
					// assemble one list of all values
					Set data = data _ $S(data="":"",1:"^") _ series
					Set tSeriesInstance = $O($$$EnsMetrics(tMetric,tSeriesInstance))
				}
			}
			Set tSeries.Data = data
		}
	}
	ElseIf (tRowType = "series") {
		// default: loop over row series and get labels
		Set labels = ""
		For i=1:1:meter.Rows.SeriesList.Count() {
			Set tSeries = meter.Rows.SeriesList.GetAt(i)
			Set tSeriesInstance = $S(tSeries.Instance="":tInstance,1:tSeries.Instance)
			Set data = ""
			Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,""))
			While (key '= "") {
				Set data = data _ $S(data="":"",1:":") _ ($G($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key)))
				Set key = $O($$$EnsMetrics(tMetric,tSeriesInstance,tSeries.Property,key))
			}
			If (tColType '= "instances") {
				// for instances we already have data
				Set tSeries.Data = data
			}

			// pick up labels
			Set labels = labels _  $S(labels="":"",1:":") _ tSeries.Label
		}
		Set meter.RowLabels = labels
	}
	ElseIf (tRowType = "history") {
		Set sz = $Case(tRowSize,"":5,:tRowSize)
		Set off = 0
		Set labels = ""
		For i=(off+1):1:(sz+off) {
			Set labels = labels _  $S(labels="":"",1:":") _ i
		}
		Set meter.RowLabels = labels
	}
	ElseIf (tRowType = "") {
		Set meter.RowLabels = meter.Property
	}
	Else {
		Set meter.RowLabels = "N/A"
		Set meter.Unsupported = 1
	}
}

}
