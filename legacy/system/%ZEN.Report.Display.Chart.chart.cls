/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.Chart.chart Extends (%ZEN.Report.Display.childrenNode, %ZEN.Report.Display.tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Default value for the plotToEdge property.
Parameter DEFAULTPLOTTOEDGE As BOOLEAN = 1;

/// Default value for the markersVisible property.
Parameter DEFAULTMARKERSVISIBLE As BOOLEAN = 0;

/// Do not worry about preserving the aspect ratio.
Parameter DEFAULTASPECT = "none";

/// Default viewBoxWidth of this component.
/// This is set to 100 to provide a fixed coordinate system for meters.
Parameter DEFAULTVIEWBOXWIDTH = 100;

/// Default viewBoxHeight of this component.
/// This is set to 100 to provide a fixed coordinate system for meters.
Parameter DEFAULTVIEWBOXHEIGHT = 100;

/// Optional: style used for chart background panel.
Property backgroundStyle As %ZEN.Datatype.style;

/// Optional: style used for chart plot area panel.
Property plotAreaStyle As %ZEN.Datatype.style;

/// Title to display for chart.
Property title As %ZEN.Datatype.caption;

/// Optional: style used for title text.
Property titleStyle As %ZEN.Datatype.style;

/// If this chart has a title, x-position (within the chart coordinate space) of the title.
Property titleX As %ZEN.Datatype.float [ InitialExpression = 50 ];

/// If this chart has a legend, y-position (within the chart coordinate space) of the title.
Property titleY As %ZEN.Datatype.float [ InitialExpression = 5 ];

/// Comma-delimited list of fields to acquire data from. If <property>dataGroup</property>
/// is provided, only the first data field is used.
Property dataFields As %ZEN.Datatype.csv;

/// Number of data series to display on this chart.<br>
/// If "", then this is computed automatically from the chart's data source.
Property seriesCount As %ZEN.Datatype.string;

/// Number of items within each data series to display on this chart.<br>
/// If "", then this is computed automatically from the chart's data source. 
Property seriesSize As %ZEN.Datatype.string;

/// Comma-delimited list of CSS color values used for data series. The colors can
/// be acquired dynamically by using the form "!fieldname".
Property seriesColors As %ZEN.Datatype.csv [ InitialExpression = "blue,red,green,yellow,orange,plum,purple" ];

/// Comma-delimited list of names used to label each data series in the legend box.  The
/// series names can be acquired dynamically by beginning them with a "!".  If 
/// <property>seriesGroup</property> is provided, only the first series name field is
/// considered.
Property seriesNames As %ZEN.Datatype.csv;

/// Specifies the group the group that corresponds to the list of series for the chart.
Property seriesGroup As %ZEN.Datatype.string;

/// Specifies the group the group that corresponds to the data elements for the chart.
Property dataGroup As %ZEN.Datatype.string;

/// Comma-delimited list of marker shapes used for data series markers.
/// Possible values are 'up','down','square','circle'.<br>
/// This only applies to charts that support markers.
Property markerShapes As %ZEN.Datatype.csv [ InitialExpression = "circle,up,down,square" ];

/// Scaling applied to chart markers:
/// A value of 1.0 (or '') will display markers with their default size.
/// This only applies to charts that support markers.
Property markerScale As %ZEN.Datatype.float [ InitialExpression = 1 ];

/// Optional: default style applied to all grid line elements for this chart.<br>
/// If defined, this style overrides any styles define in the CSS style
/// definition for the page, but is in turn overridden by any styles defined
/// by a specific axis element.
Property gridStyle As %ZEN.Datatype.style;

/// Height of the chart within the report.
Property height As %ZEN.Datatype.length;

/// Optional: default style applied to all grid label elements for this chart.
/// If defined, this style overrides any styles define in the CSS style
/// definition for the page, but is in turn overridden by any styles defined
/// by a specific axis element.
Property labelStyle As %ZEN.Datatype.style;

/// Optional: default style applied to axis titles for this chart.<br/>
/// This is applied <em>in addition</em> to the style supplied by <property>labelStyle</property>.
Property axisTitleStyle As %ZEN.Datatype.svgStyle;

/// If true, auto-position the legend
Property legendAutoPosition As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, display a legend for this chart.
Property legendVisible As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If this chart has a legend, x-position (within the chart coordinate space) of legend box.
Property legendX As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// If this chart has a legend, y-position (within the chart coordinate space) of legend box.
Property legendY As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// If this chart has a legend, width (within the chart coordinate space) of legend box.
/// If not specified a default width will be used.
Property legendWidth As %ZEN.Datatype.float;

/// If this chart has a legend, height (within the chart coordinate space) of legend box.
/// If not specified a default height (based on number of data series) will be used.
Property legendHeight As %ZEN.Datatype.float;

/// Optional: style used for background of the legend box.
Property legendStyle As %ZEN.Datatype.style;

/// Optional: style used for text within the legend box.
Property legendLabelStyle As %ZEN.Datatype.style;

/// Margin (within the chart coordinate space) from top edge of chart to top edge of grid (plot area).
Property marginTop As %ZEN.Datatype.float [ InitialExpression = 6 ];

/// Margin (within the chart coordinate space) from bottom edge of chart to bottom edge of grid (plot area).
Property marginBottom As %ZEN.Datatype.float [ InitialExpression = 10 ];

/// Margin (within the chart coordinate space) from left edge of chart to left edge of grid (plot area).
Property marginLeft As %ZEN.Datatype.float [ InitialExpression = 10 ];

/// Margin (within the chart coordinate space) from right edge of chart to right edge of grid (plot area).
Property marginRight As %ZEN.Datatype.float [ InitialExpression = 2 ];

/// Specifies whether markers should be displayed for the data
/// points within the line chart.<br>
/// This only appies to charts that display markers.
Property markersVisible As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTMARKERSVISIBLE} ];

/// Specifies how values should be plotted along a category axis.
/// If true, plot the first and last values on the edges of the plotArea
/// (as in a line chart). If false, plot values in the centers of each
/// unit (as in a bar chart).<br>
/// This is specified by subclasses.
Property plotToEdge As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTPLOTTOEDGE} ];

/// If defined, then a colored band (specified by <property>bandUpperStyle</property>)
/// is displayed on the plot area covering the range greater than this value;
Property bandUpper As %ZEN.Datatype.float;

/// If defined, then a colored band (specified by <property>bandLowerStyle</property>)
/// is displayed on the plot area covering the range lower than this value;
Property bandLower As %ZEN.Datatype.float;

/// Optional: style used for upper band on plot area.
Property bandUpperStyle As %ZEN.Datatype.style;

/// Optional: style used for upper band on plot area.
Property bandLowerStyle As %ZEN.Datatype.style;

/// ongetLabelX event handler:<br>
/// This event handler, if defined, is called by the chart
/// to get the text for a given label on the x axis.<br>
Property ongetLabelX As %ZEN.Datatype.eventHandler;

/// ongetLabelY event handler:<br>
/// This event handler, if defined, is called by the chart
/// to get the text for a given label on the y axis.<br>
Property ongetLabelY As %ZEN.Datatype.eventHandler;

/// Optional: default style applied to svg elements used for plotting
/// data by this chart (such as the line in a line chart).
Property plotStyle As %ZEN.Datatype.style;

/// Optional: style used for series markers.
Property markerStyle As %ZEN.Datatype.style;

/// Typical children property for a <class>childrenNode</class>,
/// but every child must be an <class>axis</class>.
Property children As list Of %ZEN.Report.Display.Chart.axis(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Internal property used to keep track of plot information.
Property plot As %ZEN.Report.Display.Chart.plot(XMLPROJECTION = "none");

/// Internal property that references this charts <class>xaxis</class> object.
Property xAxis As %ZEN.Report.Display.Chart.axis(XMLPROJECTION = "none");

/// Internal property that references this charts <class>yaxis</class> object.
Property yAxis As %ZEN.Report.Display.Chart.axis(XMLPROJECTION = "none");

/// If true, display axis labels for this chart (or slice labels in the
/// case of a pie chart).
Property labelsVisible As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Placeholder for custom SVG styling
XData SVGStyle
{
}

/// Default styling for charts.  To add additional style, use the
/// <xdata>SVGStyle</xdata> XData block
XData SVGStyleDefault
{
<style type="text/css" xmlns="http://www.w3.org/2000/svg"><![CDATA[

/* background of chart */
.chart-background {
	fill: darkblue;
	stroke: black;
	stroke-width: 0.1px;
}

/* background of plot area of chart */
.chart-plotArea-background {
	fill: white;
	stroke: none;
}

/* border of plot area of chart */
.chart-plotArea-border {
	fill: none;
	stroke: black;
	stroke-width: 0.1px;
}

/* upper/lower band */
.chart-band {
	fill: #F0F0F0;
	stroke: none;
}

/* background of legend */
.chart-legend {
	fill: white;
	stroke: black;
	stroke-width: 0.1px;
}

/* grid lines */
.chart-majorGridLine { 
	stroke: black;
	stroke-width: 0.1px;
}

.chart-minorGridLine { 
	stroke: black;
	stroke-width: 0.1px;
	opacity: 0.5;
	stroke-dasharray: 0.1,0.1;
}

/* lines in line plots */
.chart-seriesLine {
	stroke-width: 0.25px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* bars in bar plots */
.chart-seriesBar {
	stroke-width: 0.25px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* tick marks */
.chart-majorTick { 
	stroke: black;
	stroke-width: 1px;
	opacity: 0.7;
	stroke-linecap: round;
}

.chart-minorTick { 
	stroke: black;
	stroke-width: 1px;
	opacity: 0.7;
	stroke-linecap: round;
}

/* labels */
.chart-title { 
	pointer-events: none;
	font-size: 4px;
	fill: yellow;
	stroke: none;
}

.chart-xLabel { 
	pointer-events: none;
	font-size: 3px;
	fill: yellow;
	stroke: none;
}
.chart-yLabel { 
	pointer-events: none;
	font-size: 3px;
	fill: yellow;
	stroke: none;
}

.chart-legendLabel {
	pointer-events: none;
	font-size: 2.5px;
	fill: black;
	stroke: none;
}
]]></style>
}

/// Default styling for charts.  To add additional style, use the
/// <xdata>SVGStyle</xdata> XData block
XData SVGStyleDefaultNoHTML5
{
<svg:style type="text/css"><![CDATA[

/* background of chart */
.chart-background {
	fill: darkblue;
	stroke: black;
	stroke-width: 0.1px;
}

/* background of plot area of chart */
.chart-plotArea-background {
	fill: white;
	stroke: none;
}

/* border of plot area of chart */
.chart-plotArea-border {
	fill: none;
	stroke: black;
	stroke-width: 0.1px;
}

/* upper/lower band */
.chart-band {
	fill: #F0F0F0;
	stroke: none;
}

/* background of legend */
.chart-legend {
	fill: white;
	stroke: black;
	stroke-width: 0.1px;
}

/* grid lines */
.chart-majorGridLine { 
	stroke: black;
	stroke-width: 0.1px;
}

.chart-minorGridLine { 
	stroke: black;
	stroke-width: 0.1px;
	opacity: 0.5;
	stroke-dasharray: 0.1,0.1;
}

/* lines in line plots */
.chart-seriesLine {
	stroke-width: 0.25px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* bars in bar plots */
.chart-seriesBar {
	stroke-width: 0.25px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* tick marks */
.chart-majorTick { 
	stroke: black;
	stroke-width: 1px;
	opacity: 0.7;
	stroke-linecap: round;
}

.chart-minorTick { 
	stroke: black;
	stroke-width: 1px;
	opacity: 0.7;
	stroke-linecap: round;
}

/* labels */
.chart-title { 
	pointer-events: none;
	font-size: 4px;
	fill: yellow;
	stroke: none;
}

.chart-xLabel { 
	pointer-events: none;
	font-size: 3px;
	fill: yellow;
	stroke: none;
}
.chart-yLabel { 
	pointer-events: none;
	font-size: 3px;
	fill: yellow;
	stroke: none;
}

.chart-legendLabel {
	pointer-events: none;
	font-size: 2.5px;
	fill: black;
	stroke: none;
}
]]></svg:style>
}

Method %DrawToHTML(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	$$$groupNumInc
	Set templatename = "chart"_$$$groupNum
	
	Set tHTML5=%report.isHTML5	
	Do XSL.WriteLine("<div>")
	Set style=""
	if 'tHTML5 {
		If ..width'="" Set style=style_"width:"_..width_";"
		If ..height'="" Set style=style_"height:"_..height_";"
	}
	Do:style'="" XSL.WriteLine("<xsl:attribute name='style'>"_style_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,style)
	Do XSL.WriteLine("<xsl:call-template name='"_templatename_"' />")
	Do XSL.WriteLine("</div>")
	
	Set delay2=##class(%GlobalCharacterStream).%New()
	Do delay.WriteLine("<xsl:template name='"_templatename_"'>")
	if ..%Extends("%ZEN.Report.Display.Chart.pieChart")||..%Extends("%ZEN.Report.Display.Chart.pieChartEx") {
		Set labelValues=##this.labelValues
	} else {
		Set labelValues=""
	}
	Set sc = ..render(.context,.delay,.delay2,labelValues)
	Do delay.WriteLine("</xsl:template>")
	Do delay.CopyFrom(delay2)
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	$$$groupNumInc
	Set templatename = "chart"_$$$groupNum
	
	Do XSL.WriteLine("<fo:block><fo:instream-foreign-object><"_..SvgPrefix()_"svg x='0' y='0'>")
	Do:..width'="" XSL.WriteLine("<xsl:attribute name='width'>"_..width_"</xsl:attribute>")
	Do:..height'="" XSL.WriteLine("<xsl:attribute name='height'>"_..height_"</xsl:attribute>")
	Do XSL.WriteLine("<xsl:call-template name='"_templatename_"' />")
	Do XSL.WriteLine("</"_..SvgPrefix()_"svg></fo:instream-foreign-object></fo:block>")
	
	Set delay2=##class(%GlobalCharacterStream).%New()
	Do delay.WriteLine("<xsl:template name='"_templatename_"'>")
	if ..%Extends("%ZEN.Report.Display.Chart.pieChart")||..%Extends("%ZEN.Report.Display.Chart.pieChartEx") {
		Set labelValues=##this.labelValues
	} else {
		Set labelValues=""
	}
	Set sc = ..render(.context,.delay,.delay2,labelValues)
	Do delay.WriteLine("</xsl:template>")
	Do delay.CopyFrom(delay2)
	d ..%EndDrawFo(.context,.XSL,.delay)
	Quit sc
}

Method render(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, labelValues As %String)
{
	;if ..seriesNames'="",..seriesNames["!",$L(..seriesNames,",")>1 Quit $$$ERROR($$$GeneralError,"A series name that contains an xpath cannot contain other xpaths or literals")
	Set ..seriesNames=$zstrip(..seriesNames,"<>W")
	Set ..dataFields=$zstrip(..dataFields,"<>W")
	Set chartid = "zenReportChart"_$$$groupNum
	Do XSL.WriteLine("<xsl:param name='id' select='concat("""_chartid_""",""_"",position())'/>")
	Do XSL.WriteLine("<"_..SvgPrefix()_"svg id='{$id}'>")
	Do:..width'="" XSL.WriteLine("<xsl:attribute name='width'>"_..width_"</xsl:attribute>")
	Do:..height'="" XSL.WriteLine("<xsl:attribute name='height'>"_..height_"</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='viewBox'>0 0 "_..#DEFAULTVIEWBOXWIDTH_" "_..#DEFAULTVIEWBOXHEIGHT_"</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='preserveAspectRatio'>"_..#DEFAULTASPECT_"</xsl:attribute>")
	
	// This was necessary when we were generating HTML, because the Firefox
	// XSLT parser would change the case of attributes in HTML mode.  Now, we
	// generate XHTML (w/ <xsl:output medthod='xml'>).
	//Do XSL.WriteLine("  <"_..SvgPrefix()_"script> ")
	//Do XSL.WriteLine("    var chart = this.document.getElementById('"_chartid_"');") 
	//Do XSL.WriteLine("    chart.setAttribute('viewBox','0 0 "_..#DEFAULTVIEWBOXWIDTH_" "_..#DEFAULTVIEWBOXHEIGHT_"');")
	//Do XSL.WriteLine("    chart.setAttribute('preserveAspectRatio','"_..#DEFAULTASPECT_"');")
	//Do XSL.WriteLine("   </"_..SvgPrefix()_"script>")
	
	Do XSL.WriteLine("<"_..SvgPrefix()_"defs>")
	
	// Add default style
	Set me = ##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1))
	if %report.isHTML5 {
		Set suffix=""
	} else {
		Set suffix="NoHTML5"
	}

	Set idx = me.XDatas.FindObjectId(..%ClassName(1)_"||SVGStyleDefault"_suffix)
	Set data = me.XDatas.GetAt(idx).Data
	Do data.Rewind()
	Do XSL.CopyFrom(data)
	
	//Add custom style
	if $D(%report),$isObject(%report) {
		Set me = ##class(%Dictionary.CompiledClass).%OpenId(%report.%ClassName(1))
		Set idx = me.XDatas.FindObjectId(%report.%ClassName(1)_"||SVGStyle")
		Set data = me.XDatas.GetAt(idx).Data
		Do data.Rewind()
		Do XSL.CopyFrom(data)
	}
	
	Do XSL.WriteLine("</"_..SvgPrefix()_"defs>")

	// init multidemnsional used to set attributes of svg elements
	// this is needed for embedded SVG in IE which doesn't understand CSS when embedded
	d ..OnSVGAttribution(.context)	
	/// draw background
	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-background",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-background",key)_"'"
	. s sep=" "
	Do XSL.Write("  <"_..SvgPrefix()_"rect class='chart-background' "_attribs_" x='0' y='0' width='100' height='100'")
	if ..backgroundStyle'="" Do XSL.Write("     style='"_..backgroundStyle_"'")
	Do XSL.WriteLine(">")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..backgroundStyle)
	Do XSL.WriteLine("</"_..SvgPrefix()_"rect>")

	// get data for chart	
	// this.acquireData();
	
	// caclulate width and height of legend
	Set sc = ..calcLegendArea(.context, .XSL, .delay)  Quit:$$$ISERR(sc) sc
	
	// calculate ranges & other values needed for plotting.
	Set ..yAxis=..getYAxis()
	Set ..xAxis=..getXAxis()
	Set ..plot = ##class(%ZEN.Report.Display.Chart.plot).%New()
	Set sc = ..plot.calculateRangeValues(.context,.XSL,.delay,##this)  Quit:$$$ISERR(sc) sc

	// add utilities
	Do ##class(chartUtil).renderUtils(.context,.delay,##this,..plot)

	// create grid (plot area)
	Set sc = ..renderPlotArea(.context, .XSL,.delay)  Quit:$$$ISERR(sc) sc

	// plot series data (via subclass)
	Set sc =..renderSeriesGroup(.context,.XSL,.delay)  Quit:$$$ISERR(sc) sc
	
	// render series group labels (via subclass)
	Set sc =..renderSeriesGroupLabels(.context,.XSL,.delay)  Quit:$$$ISERR(sc) sc

	// create legend
	Set sc = ..renderLegend(.context,.XSL,.delay,labelValues)   Quit:$$$ISERR(sc) sc

	// create title
	Set sc =..renderTitle(.context,.XSL) 
	
	Do XSL.WriteLine("</"_..SvgPrefix()_"svg>")

	Quit $$$OK
}

/// Calc Legend Area
Method calcLegendArea(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	// if no series group, loop over the series
	If ..seriesGroup="" {
		Set scount = $s(..seriesCount="":$l(..seriesNames,","),1:..seriesCount)
		Set width = $s(..legendWidth="":15,1:..legendWidth)
		Set height = $s(..legendHeight="":(scount*3)+2,1:..legendHeight)
		
		// legend items: 1 per series
		For s=1:1:scount {
	
			If $e(..seriesNames)="!" {
				Set seriesName = "<xsl:value-of select='"_$e(..seriesNames,2,$l(..seriesNames))_"' />"
			} Else {
				Set seriesName = $p(..seriesNames,",",s)
			}		
			
		
		}
		// TBD take max of ..seriesNames
		Set mode = "legend"_$$$groupNum
		Do delay.WriteLine("  <xsl:variable name='legendwidth"_mode_"' select='"_$s(..legendWidth="":15,1:..legendWidth)_"'/>")
		
	// if the series are given by a group, we create templates to match
	// the group tag.
	} Else {	
	
	
		Set scount = +..seriesCount
		Set mode = "legend"_$$$groupNum
		Set processSeriesLiterals=0
		if ('..legendAutoPosition) {	
			Do delay.WriteLine("  <xsl:variable name='legendwidth"_mode_"' select='"_$s(..legendWidth="":15,1:..legendWidth)_"'/>")
		} else {
			// if legendAutoPosition is true then we calculate the width from the width of the legend strings
			
			if ((..seriesNames'="") && ($e(..seriesNames)="!")) {
				Do delay.WriteLine("<xsl:template name='maxstringsize"_mode_"'>")
				Do delay.WriteLine("<xsl:param name='nodes' select='/..' />")
				Do delay.WriteLine("<xsl:param name='pos' select='1' />")
				Do delay.WriteLine("<xsl:param name='count' select='count($nodes)' />")
				Do delay.WriteLine("<xsl:param name='max' select='string-length($nodes[1])' />")
				Do delay.WriteLine("<xsl:choose>")
				Do delay.WriteLine("  <xsl:when test='$pos > $count'><xsl:value-of select='$max'/></xsl:when>")
				Do delay.WriteLine("<xsl:otherwise>")
	 			Do delay.WriteLine("  <xsl:choose>")
	 			Do delay.WriteLine("  <xsl:when test='$max &lt; string-length($nodes[$pos])'>")
	 			Do delay.WriteLine("  <xsl:call-template name='maxstringsize"_mode_"'>")
	 			Do delay.WriteLine("  <xsl:with-param name='nodes' select='$nodes'/>")
	 			Do delay.WriteLine("  <xsl:with-param name='count' select='$count'/>")
	 			Do delay.WriteLine("  <xsl:with-param name='max' select='string-length($nodes[$pos])'/>")
	 			Do delay.WriteLine("  <xsl:with-param name='pos' select='$pos+1'/>")
	 			Do delay.WriteLine("  </xsl:call-template>")
	 			Do delay.WriteLine("  </xsl:when>")
	 			Do delay.WriteLine("  <xsl:otherwise>")
	 			Do delay.WriteLine("  <xsl:call-template name='maxstringsize"_mode_"'>")
	 			Do delay.WriteLine("  <xsl:with-param name='nodes' select='$nodes'/>")
	 			Do delay.WriteLine("  <xsl:with-param name='count' select='$count'/>")
	 			Do delay.WriteLine("  <xsl:with-param name='max' select='$max'/>")
	 			Do delay.WriteLine("  <xsl:with-param name='pos' select='$pos+1'/>")
	 			Do delay.WriteLine("  </xsl:call-template>")
	 			Do delay.WriteLine("  </xsl:otherwise>")
	 			Do delay.WriteLine("  </xsl:choose>")
	 			Do delay.WriteLine("</xsl:otherwise>")
				Do delay.WriteLine("</xsl:choose>")
				Do delay.WriteLine("</xsl:template>")

				; calcuate max-number-of-letters in legend label

					Do delay.WriteLine("  <xsl:variable name='stringwidth"_mode_"'>")
					Do delay.WriteLine("  <xsl:call-template name='maxstringsize"_mode_"'>")
					Do delay.WriteLine("  <xsl:with-param name='nodes' select='"_..xpath_"/"_..qualify(..seriesGroup)_"/"_$e(..seriesNames,2,$L(..seriesNames))_"'/>")
					Do delay.WriteLine("  </xsl:call-template>")
					Do delay.WriteLine("  </xsl:variable>")
					Do delay.WriteLine("  <xsl:variable name='legendwidth"_mode_"' select='$stringwidth"_mode_"*1.3+4'/>")
					Set processSeriesLiterals=0
			} elseif ((..seriesNames'="") && ($e(..seriesNames)'="!")) {
				Set processSeriesLiterals=1
			} else {
				; automatic legend names
				Do delay.WriteLine("  <xsl:variable name='legendwidth"_mode_"' select='"_$s(..legendWidth="":15,1:..legendWidth)_"'/>")
				Set processSeriesLiterals=0

			}



			if (processSeriesLiterals) {
				// Create template that takes two variables and gives the maxium of them
				Do delay.WriteLine("<xsl:template name='max"_mode_"'>")
				Do delay.WriteLine("<xsl:param name='x'/>")
				Do delay.WriteLine("<xsl:param name='y'/>")
				Do delay.WriteLine("<xsl:choose>")
				Do delay.WriteLine("<xsl:when test='$x > $y'>")
				Do delay.WriteLine("<xsl:value-of select='$x'/>")
				Do delay.WriteLine("</xsl:when>")
				Do delay.WriteLine("<xsl:otherwise>")
				Do delay.WriteLine("<xsl:value-of select='$y'/>")
				Do delay.WriteLine("</xsl:otherwise>")
				Do delay.WriteLine("</xsl:choose>")
				Do delay.WriteLine("</xsl:template>")
				Set scount=$L(..seriesNames,",")
				If scount=1 {
					Set s=1
		
					if $e(..seriesNames)="!" {
						Set seriesName = "<xsl:value-of select='"_..xpath_"/"_..qualify(..seriesGroup)_"["_s_"]/"_$e(..seriesNames,2,$L(..seriesNames))_"' />"
					} else {
						Set seriesName = $p(..seriesNames,",",s)
					}
					Do delay.WriteLine("<xsl:variable name='string'>")
					Do delay.WriteLine(" "_seriesName)
					Do delay.WriteLine("</xsl:variable>")
					Do delay.WriteLine("<xsl:variable name='stringwidth"_mode_"'>")
					Do delay.WriteLine("<xsl:value-of select='string-length($string)'/>")
					Do delay.WriteLine("</xsl:variable>")
					Do delay.WriteLine("  <xsl:variable name='legendwidth"_mode_"' select='$stringwidth"_mode_"*1.3+4'/>")

				} else {
						; scount > 1 take max string length of all strings
						; max(x1,max(x2,max(x3,x4))))
						Do delay.WriteLine("<xsl:variable name='stringwidth"_mode_"'>")
						Do delay.WriteLine("<xsl:call-template name='max"_mode_"'>")
						For s=1:1:scount-1 {
								;if (s=(scount-1)) Do XSL.WriteLine("<xsl:call-template name='max"_mode_"'>")
								if $e(..seriesNames)="!" {
									Do delay.WriteLine("<xsl:with-param name='x' select='string-length("_..xpath_"/"_..qualify(..seriesGroup)_"["_s_"]/"_$e(..seriesNames,2,$L(..seriesNames))_")' />")
								} else {
								
									Do delay.WriteLine("<xsl:with-param name='x' select='string-length("""_$p(..seriesNames,",",s)_""")'/>")
								}
								if (s'=(scount-1)) Do delay.WriteLine("<xsl:with-param name='y'>")
								if (s'=(scount-1)) Do delay.WriteLine("<xsl:call-template name='max"_mode_"'>")
								if (s'=(scount-1)) {
								} else {
									; last name
									if $e(..seriesNames)="!" {
										Do delay.WriteLine("<xsl:with-param name='y' select='string-length("_..xpath_"/"_..qualify(..seriesGroup)_"["_(s+1)_"]/"_$e(..seriesNames,2,$L(..seriesNames))_")' />")
									} else {
										Do delay.WriteLine("<xsl:with-param name='y' select='string-length("""_$p(..seriesNames,",",(s+1))_""")'/>")
									}
									

								}
					
						}
		
		
						For s=1:1:scount-1 {
							if (s'=1) Do delay.WriteLine("</xsl:with-param>")
#if 0							
							if (s=(scount-1)) {
								Do XSL.WriteLine("</xsl:call-template>")
							}
#endif							
							Do delay.WriteLine("</xsl:call-template>")
						}
			
						;Do XSL.WriteLine("</xsl:call-template>")
						Do delay.WriteLine("</xsl:variable>")
						Do delay.WriteLine("<xsl:variable name='legendwidth"_mode_"' select='$stringwidth"_mode_"*1.3+4'/>")
				}
			}
		}
	}	
	Quit $$$OK
}

/// Draw the legend for the chart.
Method renderLegend(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, labelValues As %String)
{
	If '..legendVisible Quit $$$OK
	
	// if label values not null, loop over them (to support pieChartEx)
	If labelValues'="" {
		Set scount = $s(..seriesCount="":$l(labelValues,","),1:..seriesCount)
		Set width = $s(..legendWidth="":15,1:..legendWidth)
		Set height = $s(..legendHeight="":(scount*3)+2,1:..legendHeight)
		
		// legend group
		Do XSL.WriteLine("<"_..SvgPrefix()_"svg>")
		Do XSL.WriteLine("  <xsl:attribute name='x'>"_..legendX_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'>"_..legendY_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='width'>"_width_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='height'>"_height_"</xsl:attribute>")
		
		// background
		
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-legend",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legend",key)_"'"
		. s sep=" "
		Do XSL.WriteLine("  <"_..SvgPrefix()_"rect class='chart-legend'"_attribs_" x='0.5' y='0.5'>")
		Do XSL.WriteLine("    <xsl:attribute name='width'>"_(width-1)_"</xsl:attribute>")
		Do XSL.WriteLine("    <xsl:attribute name='height'>"_(height-1)_"</xsl:attribute>")
		if ..legendStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..legendStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..legendStyle)
		Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
		
		// legend items: 1 per series
		For s=1:1:scount {
	
			Set labelValue=$zstrip($P(labelValues,",",s),"<>W")
			If $e(labelValue)="!" {
				Set labelName = "<xsl:value-of select='"_$e(labelValue,2,$l(labelValue))_"' />"
			} Else {
				Set labelName = labelValue
			}		
			
			Do XSL.WriteLine("  <"_..SvgPrefix()_"rect x='1' width='2' height='2' stroke='black' stroke-width='0.1px'>")
			Do XSL.WriteLine("    <xsl:attribute name='y'>"_(s*3-2)_"</xsl:attribute>")
			Do XSL.WriteLine("    <xsl:attribute name='fill'>")
			Do XSL.WriteLine("      <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
			Do XSL.WriteLine("        <xsl:with-param name='series' select='"_s_"' />")
			Do XSL.WriteLine("      </xsl:call-template>")
			Do XSL.WriteLine("    </xsl:attribute>")
			Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
			
			s attribs=""
			s sep=""
			s key="" for  s key=$o(context("SVGATTRS","chart-legendLabel",key)) q:key=""  d
			. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legendLabel",key)_"'"
			. s sep=" "
			Do XSL.WriteLine("  <"_..SvgPrefix()_"text class='chart-legendLabel'"_attribs_" x='3.5'>")
			Do XSL.WriteLine("    <xsl:attribute name='y'>"_(s * 3)_"</xsl:attribute>") 
			if ..legendLabelStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..legendLabelStyle_"</xsl:attribute>")
			Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..legendLabelStyle)
			Do XSL.WriteLine("    "_labelName) 
			Do XSL.WriteLine("  </"_..SvgPrefix()_"text>")
			
		
		}
		Do XSL.WriteLine("</"_..SvgPrefix()_"svg>")
		
		Quit $$$OK
	}
	// if no series group, loop over the series
	If ..seriesGroup="" {
		Set scount = $s(..seriesCount="":$s(..seriesNames="":$l(..dataFields,","),1:$l(..seriesNames,",")),1:..seriesCount)
		Set width = $s(..legendWidth="":15,1:..legendWidth)
		Set height = $s(..legendHeight="":(scount*3)+2,1:..legendHeight)
		
		// legend group
		Do XSL.WriteLine("<"_..SvgPrefix()_"svg>")
		Do XSL.WriteLine("  <xsl:attribute name='x'>"_..legendX_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'>"_..legendY_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='width'>"_width_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='height'>"_height_"</xsl:attribute>")
		
		// background
		
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-legend",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legend",key)_"'"
		. s sep=" "
		Do XSL.WriteLine("  <"_..SvgPrefix()_"rect class='chart-legend'"_attribs_" x='0.5' y='0.5'>")
		Do XSL.WriteLine("    <xsl:attribute name='width'>"_(width-1)_"</xsl:attribute>")
		Do XSL.WriteLine("    <xsl:attribute name='height'>"_(height-1)_"</xsl:attribute>")
		if ..legendStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..legendStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..legendStyle)
		Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
		
		// legend items: 1 per series
		For s=1:1:scount {
	
			If $e($P(..seriesNames,",",s))="!" {
				Set seriesName = "<xsl:value-of select='"_$e($P(..seriesNames,",",s),2,$l(..seriesNames))_"' />"
			} Else {
				Set seriesName = $p(..seriesNames,",",s)
			}		
			
			Do XSL.WriteLine("  <"_..SvgPrefix()_"rect x='1' width='2' height='2' stroke='black' stroke-width='0.1px'>")
			Do XSL.WriteLine("    <xsl:attribute name='y'>"_(s*3-2)_"</xsl:attribute>")
			Do XSL.WriteLine("    <xsl:attribute name='fill'>")
			Do XSL.WriteLine("      <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
			Do XSL.WriteLine("        <xsl:with-param name='series' select='"_s_"' />")
			Do XSL.WriteLine("      </xsl:call-template>")
			Do XSL.WriteLine("    </xsl:attribute>")
			Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
			
			s attribs=""
			s sep=""
			s key="" for  s key=$o(context("SVGATTRS","chart-legendLabel",key)) q:key=""  d
			. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legendLabel",key)_"'"
			. s sep=" "
			Do XSL.WriteLine("  <"_..SvgPrefix()_"text class='chart-legendLabel'"_attribs_" x='3.5'>")
			Do XSL.WriteLine("    <xsl:attribute name='y'>"_(s * 3)_"</xsl:attribute>") 
			if ..legendLabelStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..legendLabelStyle_"</xsl:attribute>")
			Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..legendLabelStyle)
			Do XSL.WriteLine("    "_seriesName) 
			Do XSL.WriteLine("  </"_..SvgPrefix()_"text>")
			
		
		}
		Do XSL.WriteLine("</"_..SvgPrefix()_"svg>")
	// if the series are given by a group, we create templates to match
	// the group tag.
	} Else {	
	
	
		Set scount = +..seriesCount
		Set mode = "legend"_$$$groupNum

		// legend group
		Do XSL.WriteLine("<"_..SvgPrefix()_"svg>")
		
		// width variable
		Set width = $s(..legendWidth="":15,1:..legendWidth)
		if ('..legendAutoPosition) {	
			Do XSL.WriteLine("  <xsl:variable name='width' select='"_width_"' />")
		} else {
			// if legendAutoPosition is true then we calculate the width from the width of the legend strings
			
			Do XSL.WriteLine("  <xsl:variable name='width' select='$legendwidth"_mode_"'/>")
				
		}
		
		
		// height variable
		Set height = $s(..legendHeight="":"3 * $"_$$$seriescount_" + 2",1:..legendHeight)
		Do XSL.WriteLine("  <xsl:variable name='height' select='"_height_"' />")
		
		Do XSL.WriteLine("  <xsl:attribute name='x'>"_..legendX_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'>"_..legendY_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$width' /></xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='height'><xsl:value-of select='$height' /></xsl:attribute>")
		
		// background
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-legend",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legend",key)_"'"
		. s sep=" "
		Do XSL.WriteLine("  <"_..SvgPrefix()_"rect class='chart-legend'"_attribs_" x='0.5' y='0.5'>")
		Do XSL.WriteLine("    <xsl:attribute name='width'><xsl:value-of select='$width - 1' /></xsl:attribute>")
		Do XSL.WriteLine("    <xsl:attribute name='height'><xsl:value-of select='$height - 1' /></xsl:attribute>")
		if ..legendStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..legendStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..legendStyle)
		Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
		Set doseries=0
		if $e(..seriesNames)="!",scount=0 {
			Do XSL.WriteLine("  <xsl:apply-templates select='"_..qualify(..seriesGroup)_"' mode='"_mode_"' />")
			Set doseries=0
		} else {
			Set doseries=1
			if (scount=0) Set scount=$L(..seriesNames,",")
		}
		if (doseries=1) {
					// legend items: 1 per series
			if ..%Extends("%ZEN.Report.Display.Chart.xyChart") {
				Set init=2
			} else {
				Set init=1
			}
			Set init=1
			For s=init:1:scount {
		
				if $e(..seriesNames)="!" {
					Set seriesName = "<xsl:value-of select='"_..qualify(..seriesGroup)_"["_s_"]/"_$e(..seriesNames,2,$L(..seriesNames))_"' />"
				} else {
					Set seriesName = $p(..seriesNames,",",s)
				}
				
				Do XSL.WriteLine("  <"_..SvgPrefix()_"rect x='1' width='2' height='2' stroke='black' stroke-width='0.1px'>")
				
				Do XSL.WriteLine("    <xsl:attribute name='y'>"_(s*3-2)_"</xsl:attribute>")
				Do XSL.WriteLine("    <xsl:attribute name='fill'>")
				Do XSL.WriteLine("      <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
				Do XSL.WriteLine("        <xsl:with-param name='series' select='"_s_"' />")
				Do XSL.WriteLine("      </xsl:call-template>")
				Do XSL.WriteLine("    </xsl:attribute>")
				Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
				
				s attribs=""
				s sep=""
				s key="" for  s key=$o(context("SVGATTRS","chart-legendLabel",key)) q:key=""  d
				. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legendLabel",key)_"'"
				. s sep=" "
				Do XSL.WriteLine("  <"_..SvgPrefix()_"text class='chart-legendLabel'"_attribs_" x='3.5'>")
				Do XSL.WriteLine("    <xsl:attribute name='y'>"_(s * 3)_"</xsl:attribute>") 
				if ..legendLabelStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..legendLabelStyle_"</xsl:attribute>")
				Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..legendLabelStyle)
				Do XSL.WriteLine("    "_seriesName) 
				Do XSL.WriteLine("  </"_..SvgPrefix()_"text>")
		
			
			}

		}
		
		Do XSL.WriteLine("</"_..SvgPrefix()_"svg>")
		
		Do delay.WriteLine("<xsl:template match='"_..qualify(..seriesGroup)_"' mode='"_mode_"'>")
		Do delay.WriteLine("  <"_..SvgPrefix()_"rect x='1' width='2' height='2' stroke='black' stroke-width='0.1px'>")
		Do delay.WriteLine("    <xsl:attribute name='y'><xsl:value-of select='position() * 3 -2'/></xsl:attribute>")
		Do delay.WriteLine("    <xsl:attribute name='fill'>")
		Do delay.WriteLine("      <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("        <xsl:with-param name='series' select='position()' />")
		Do delay.WriteLine("      </xsl:call-template>")
		Do delay.WriteLine("    </xsl:attribute>")
		Do delay.WriteLine("  </"_..SvgPrefix()_"rect>")
		
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-legendLabel",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-legendLabel",key)_"'"
		. s sep=" "
		Do delay.WriteLine("  <"_..SvgPrefix()_"text class='chart-legendLabel'"_attribs_" x='3.5'>")
		Do delay.WriteLine("    <xsl:attribute name='y'><xsl:value-of select='position() * 3'/></xsl:attribute>") 
		if ..legendLabelStyle'="" Do delay.Write(    "    <xsl:attribute name='style'>"_..legendLabelStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..legendLabelStyle)
		i $e(..seriesNames)="!" i $e(..seriesNames,2,$l(..seriesNames))'="" Do delay.Write(    "    <xsl:value-of select='"_$e(..seriesNames,2,$l(..seriesNames))_"' />")
		Do delay.Write(    "  </"_..SvgPrefix()_"text>")
		Do delay.WriteLine("</xsl:template>")
	}

	Quit $$$OK
}

/// Return the CSS color that should be used for the given series.
Method getSeriesColor(series As %Integer) As %String
{
	Set len = $l(..seriesColors,",")
	Set color = $p(..seriesColors,",",(series-1#len)+1)
	Quit $s(color="":"black",1:color)
}

/// Return the number of colors provided.
Method getColorCount() As %Integer
{
	If ..seriesColors="" Quit 0
	Quit $l(..seriesColors,",")
}

/// Draw the title for the chart.
Method renderTitle(ByRef context As %String, ByRef XSL As %GlobalCharacterStream) As %Status
{
	If $e(..title)="!" {
		Set title="<xsl:value-of select='"_$e(..title,2,$l(..title))_"' />"
	} Else {
		Set title=..title
	}
	If ..title'="" {
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-title",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-title",key)_"'"
		. s sep=" "
		Do XSL.WriteLine("<"_..SvgPrefix()_"text class='chart-title'"_attribs_" text-anchor='middle'>")
		if ..titleStyle'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_..titleStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..titleStyle)
		Do XSL.WriteLine("  <xsl:attribute name='x'>"_..titleX_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'>"_..titleY_"</xsl:attribute>")
		Do XSL.WriteLine("  "_title)
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
	}
	
	Quit $$$OK
}

/// Draw the data series for this chart.
/// This method renders the container for the data series and
/// then invokes a sub-class specific <method>renderSeries</method> method.
Method renderSeriesGroup(ByRef context As %String, XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Do XSL.WriteLine("<"_..SvgPrefix()_"svg>")	
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='y'>"_..plot.plotTop_"</xsl:attribute>")
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='height'>"_..plot.plotHeight_"</xsl:attribute>")
	
	Set sc = ..renderSeries(.context,.XSL,.delay)
	
	Do XSL.WriteLine("</"_..SvgPrefix()_"svg>")
	
	Quit sc
	Quit $$$OK
}

/// Draw the data labels for this chart.
/// This method renders the container for the data series and
/// then invokes a sub-class specific <method>renderSeries</method> method.
Method renderSeriesGroupLabels(ByRef context As %String, XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Do XSL.WriteLine("<"_..SvgPrefix()_"svg>")	
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='y'>"_..plot.plotTop_"</xsl:attribute>")
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='height'>"_..plot.plotHeight_"</xsl:attribute>")
	
	Set sc = ..renderSeriesLabels(.context,.XSL,.delay)
	
	Do XSL.WriteLine("</"_..SvgPrefix()_"svg>")
	
	Quit sc
	Quit $$$OK
}

/// Draw data series for this chart.
/// This is implemented by subclasses.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<"_..SvgPrefix()_"text font-size='3pt' fill='red' text-anchor='start'>")
	Do XSL.WriteLine("  <xsl:attribute name='y'>"_(..plot.plotTop+(..plot.plotHeight/2))_"</xsl:attribute>")
	Do XSL.WriteLine("  Chart: renderSeries method is unimplemented.</"_..SvgPrefix()_"text>")
	Quit $$$OK
}

/// Draw data label series for this chart.
/// This is implemented by subclasses.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeriesLabels(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	Quit $$$OK
}

/// Return the x-axis definition for this chart.
Method getXAxis() As %ZEN.Report.Display.Chart.xaxis
{
	Set xAxis = ##class(%ZEN.Report.Display.Chart.xaxis).%New()
	Set key=..children.Next("")
	While (key'="") {
		Set child=..children.GetAt(key)
		d ..updateFromTemplate(.child)		
		If child.tag="xaxis" {
			Set %val=1
			if child.ifexpression'="" {
				X " s %val=("_child.ifexpression_")"
			}
			if %val=1 Set xAxis = child Quit
		}
		Set key=..children.Next(key)
	}
	
	Quit xAxis
}

/// Return the y-axis definition for this chart.
Method getYAxis() As %ZEN.Report.Display.Chart.yaxis
{
	Set yAxis = ##class(%ZEN.Report.Display.Chart.yaxis).%New()
	Set key=..children.Next("")
	While (key'="") {
		Set child=..children.GetAt(key)
		d ..updateFromTemplate(.child)
		If child.tag="yaxis" {
			Set %val=1
			if child.ifexpression'="" {
				X " s %val=("_child.ifexpression_")"
			}
			if %val=1 Set yAxis = child Quit
		}
		Set key=..children.Next(key)
	}
	
	Quit yAxis
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType()
{
	Quit "category"
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType()
{
	Quit "value"
}

/// Indicates that this chart has axes and associated grids
/// A subclass may override this to turn off axis display.
Method hasAxes()
{
	Quit 1
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
/// Typically a chart will return true if it is in "stacked" mode.
Method useSumForRange()
{
	Quit 0
}

/// Draw the plot area of the chart.
Method renderPlotArea(context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<"_..SvgPrefix()_"g>")
	Set mode = "legend"_$$$groupNum
	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-plotArea-background",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-plotArea-background",key)_"'"
	. s sep=" "
	if (..legendAutoPosition) {
		Do XSL.WriteLine("<xsl:variable name='marginLeft"_mode_"' select='$legendwidth"_mode_"'/>")
	} else {
		Do XSL.WriteLine("<xsl:variable name='marginLeft"_mode_"' select='"_..marginLeft_"'/>")
		
	}
	Do XSL.WriteLine("  <"_..SvgPrefix()_"rect"_attribs_">")
	Do XSL.WriteLine("    <xsl:attribute name='class'>chart-plotArea-background</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='x'>")
	Do XSL.WriteLine("       <xsl:value-of select='$marginLeft"_mode_"'/>")
	Do XSL.WriteLine("    </xsl:attribute>")

	Do XSL.WriteLine("    <xsl:attribute name='y'>"_..marginTop_"</xsl:attribute>")
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='height'>"_..plot.plotHeight_"</xsl:attribute>")
	if ..plotAreaStyle'="" Do XSL.WriteLine("    <xsl:attribute name='style'>"_..plotAreaStyle_"</xsl:attribute>")
	Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")

	// if we have axes, draw them
	// (some charts, like pie charts, do not have axes)
	if ..hasAxes() {
		// draw upper/lower bands
		Set sc = ..renderBands(.context, .XSL)  Quit:$$$ISERR(sc) sc

		// draw axes and grid lines
		Set sc =  ..renderAxes(.context,.XSL,.delay)  Quit:$$$ISERR(sc) sc
	}
	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-plotArea-border",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-plotArea-border",key)_"'"
	. s sep=" "
	Do XSL.WriteLine("  <"_..SvgPrefix()_"rect"_attribs_">")
	Do XSL.WriteLine("    <xsl:attribute name='class'>chart-plotArea-border</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='x'>")
	Do XSL.WriteLine("       <xsl:value-of select='$marginLeft"_mode_"'/>")
	Do XSL.WriteLine("    </xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='y'>"_..marginTop_"</xsl:attribute>")
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='height'>"_..plot.plotHeight_"</xsl:attribute>")
	Do XSL.WriteLine("  </"_..SvgPrefix()_"rect>")
	
	Do XSL.WriteLine("</"_..SvgPrefix()_"g>")
	
	If ..hasAxes(),..labelsVisible {
		Set sc = ..renderYLabels(.context, .XSL, .delay) Quit:$$$ISERR(sc) sc
		Set sc = ..renderXLabels(.context, .XSL, .delay)  Quit:$$$ISERR(sc) sc
	}
	
	Quit $$$OK
}

/// Draw the upper/lower bands for the chart.
Method renderBands(context As %String, XSL As %GlobalCharacterStream)
{
	// Upper Band
	Set hide=((..bandUpper=0)||(..bandUpper=""))

	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-band",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-band",key)_"'"
	. s sep=" "
	If 'hide {
		Do XSL.WriteLine("<"_..SvgPrefix()_"rect class='chart-band'"_attribs_">")
		Set mode = "legend"_$$$groupNum
		Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_"'/></xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'>"_..plot.plotTop_"</xsl:attribute>")
		Set mode = "legend"_$$$groupNum
		Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
		if ..bandUpperStyle'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_..bandUpperStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..bandUpperStyle)
		Do XSL.WriteLine("  <xsl:attribute name='height'>")
		Do XSL.WriteLine("    <xsl:variable name='h'>")
		Do XSL.WriteLine("      <xsl:variable name='hraw'>")
		Do XSL.WriteLine("        <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.XSL)
		Do XSL.WriteLine("          <xsl:with-param name='val' select='"_..bandUpper_"' />")
		Do XSL.WriteLine("        </xsl:call-template>")
		Do XSL.WriteLine("      </xsl:variable>")
		Do XSL.WriteLine("      <xsl:value-of select='$hraw - "_..plot.plotTop_"' />")
		Do XSL.WriteLine("    </xsl:variable>")
		Do XSL.WriteLine("    <xsl:choose><xsl:when test='$h &gt; "_..plot.plotHeight_"'>")
		Do XSL.WriteLine("      <xsl:value-of select='"_..plot.plotHeight_"' />")
		Do XSL.WriteLine("    </xsl:when>")
		Do XSL.WriteLine("    <xsl:when test='$h &lt; 0'>")
		Do XSL.WriteLine("      <xsl:value-of select='0' />")
		Do XSL.WriteLine("    </xsl:when>")
		Do XSL.WriteLine("    <xsl:otherwise>")
		Do XSL.WriteLine("      <xsl:value-of select='$h' />")
		Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")
		Do XSL.WriteLine("  </xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='display'>inherit</xsl:attribute>")
		Do XSL.WriteLine("</"_..SvgPrefix()_"rect>")
	}
	
	// Lower Band
	Set hide=((..bandLower=0)||(..bandLower=""))

	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-band",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-band",key)_"'"
	. s sep=" "
	If 'hide {		
		Do XSL.WriteLine("<"_..SvgPrefix()_"rect class='chart-band'"_attribs_">")
			Set mode = "legend"_$$$groupNum
		Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_"'/></xsl:attribute>")

		Set mode = "legend"_$$$groupNum
		Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
		if ..bandLowerStyle'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_..bandLowerStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..bandLowerStyle)

		Do XSL.WriteLine("  <xsl:variable name='h'>")
		Do XSL.WriteLine("    <xsl:variable name='hraw'>")
		Do XSL.WriteLine("      <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.XSL)
		Do XSL.WriteLine("        <xsl:with-param name='val' select='"_..bandLower_"' />")
		Do XSL.WriteLine("      </xsl:call-template>")
		Do XSL.WriteLine("    </xsl:variable>")
		Do XSL.WriteLine("    <xsl:choose><xsl:when test='$hraw &gt; "_(..plot.plotHeight + ..plot.plotTop)_"'>")
		Do XSL.WriteLine("      <xsl:value-of select='"_(..plot.plotHeight + ..plot.plotTop)_"' />")
		Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
		Do XSL.WriteLine("      <xsl:value-of select='$hraw' />")
		Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")
		Do XSL.WriteLine("  </xsl:variable>")
		Do XSL.WriteLine("  <xsl:attribute name='height'>")
		Do XSL.WriteLine("    <xsl:value-of select='"_(..plot.plotHeight + ..plot.plotTop)_" - $h' />")
		Do XSL.WriteLine("  </xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'><xsl:value-of select='$h' /></xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='display'>inherit</xsl:attribute>")
		Do XSL.WriteLine("</"_..SvgPrefix()_"rect>")
	}
	
	Quit $$$OK
}

/// Draw the labels for the x axis.
Method renderXLabels(context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	Do ..xAxis.IfCommon(.context,.XSL,.delay)
	Do XSL.Write("<"_..SvgPrefix()_"g>")
	
	// Axis Title
	If ..xAxis.title'="" {
		If $e(..xAxis.title)="!" {
			Set title = "<xsl:value-of select='"_$e(..xAxis.title,2,$l(..xAxis.title))_"' />"
		} Else {
			Set title = ..xAxis.title
		}
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-xLabel",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-xLabel",key)_"'"
		. s sep=" "

		Do XSL.WriteLine("<"_..SvgPrefix()_"text class='chart-xLabel'"_attribs_">")
		s tAtt=""
		if ..labelStyle'="" s tAtt=..labelStyle_";"
		if ..xAxis.labelStyle'="" s tAtt=tAtt_..xAxis.labelStyle_";"
		if ..axisTitleStyle'="" s tAtt=tAtt_..axisTitleStyle_";"
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)
		if tAtt'=""	Do XSL.WriteLine("  <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
		;Do XSL.WriteLine("  <xsl:attribute name='text-anchor'>"_..xAxis.textAnchor_"</xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='text-anchor'>"_"middle"_"</xsl:attribute>")
			Set mode = "legend"_$$$groupNum
		;Do XSL.WriteLine("  <xsl:attribute name='width'><xsl:value-of select='$plotWidth"_mode_"'/></xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_"+($plotWidth"_mode_" div 2)'/></xsl:attribute>")
		Do XSL.WriteLine("  <xsl:attribute name='y'>99</xsl:attribute>")
		Do XSL.WriteLine("  "_title)
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
	}
	
	// Axis Labels
	Do XSL.WriteLine("<xsl:if test='$"_$$$xLabelUnits_" &gt; 0'>")
	If ..plot.xGridType = "value" {
		Do XSL.WriteLine("  <xsl:call-template name='zenReportXValueLabels"_$$$groupNum_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("    <xsl:with-param name='start' select='ceiling($"_$$$xMin_" div $"_$$$xLabelUnits_") * $"_$$$xLabelUnits_"' />")
		Do XSL.WriteLine("    <xsl:with-param name='end' select='floor($"_$$$xMax_" div $"_$$$xLabelUnits_") * $"_$$$xLabelUnits_"' />")
		Do XSL.WriteLine("    <xsl:with-param name='unit' select='$"_$$$xLabelUnits_"' />")
		Do XSL.WriteLine("  </xsl:call-template>")
	} Else {
		If ..plotToEdge {
			Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_" - 1' />")
			Do XSL.WriteLine("  <xsl:if test='$items &gt;= 0'>")
			Do XSL.WriteLine("    <xsl:variable name='dx'>")
			Do XSL.WriteLine("      <xsl:choose><xsl:when test='$items = 0'>")
			Set mode = "legend"_$$$groupNum
			Do XSL.WriteLine("        <xsl:value-of select='$plotWidth"_mode_"' />")
			Do XSL.WriteLine("      </xsl:when><xsl:otherwise>")
			Do XSL.WriteLine("        <xsl:value-of select='$plotWidth"_mode_" div $items' />")
			Do XSL.WriteLine("      </xsl:otherwise></xsl:choose>")
			Do XSL.WriteLine("    </xsl:variable>")
			Do XSL.WriteLine("    <xsl:variable name='adj' select='$dx' />")
		} Else {
			Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
			Do XSL.WriteLine("  <xsl:if test='$items &gt; 0'>")
			Set mode = "legend"_$$$groupNum
			Do XSL.WriteLine("    <xsl:variable name='dx' select='$plotWidth"_mode_" div $items' />")
			Do XSL.WriteLine("    <xsl:variable name='adj' select='$dx div 2' />")
		}
		Do XSL.WriteLine("    <xsl:call-template name='zenReportXCategoryLabels"_$$$groupNum_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
		Do XSL.WriteLine("      <xsl:with-param name='dx' select='$dx' />")
		Do XSL.WriteLine("      <xsl:with-param name='adj' select='$adj' />")
		Do XSL.WriteLine("    </xsl:call-template>")
		Do XSL.WriteLine("  </xsl:if>")
	}
	Do XSL.WriteLine("</xsl:if>")
	
	Do XSL.Write("</"_..SvgPrefix()_"g>")
	Do ..xAxis.EndIfCommon(.context,.XSL,.delay)
	Quit $$$OK
}

/// Draw the labels for the y axis.
Method renderYLabels(context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	Do ..yAxis.IfCommon(.context,.XSL,.delay)
	Do XSL.Write("<"_..SvgPrefix()_"g>")
	
	// Axis Title
	If ..yAxis.title'="" {
		If $e(..yAxis.title)="!" {
			Set title = "<xsl:value-of select='"_$e(..yAxis.title,2,$l(..yAxis.title))_"' />"
		} Else {
			Set title = ..yAxis.title
		}
		
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-yLabel",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-yLabel",key)_"'"
		. s sep=" "
		Do XSL.Write("<"_..SvgPrefix()_"text class='chart-yLabel'"_attribs_">")
		s tAtt=""
		if ..labelStyle'="" s tAtt=..labelStyle_";"
		if ..yAxis.labelStyle'="" s tAtt=tAtt_..yAxis.labelStyle_";"
		if ..axisTitleStyle'="" s tAtt=tAtt_..axisTitleStyle_";"
		if tAtt'=""	Do XSL.Write("  <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)
		;Do XSL.Write("  <xsl:attribute name='text-anchor'>"_..yAxis.textAnchor_"</xsl:attribute>")
		Do XSL.Write("  <xsl:attribute name='text-anchor'>"_"middle"_"</xsl:attribute>")
		Do XSL.Write("  <xsl:attribute name='x'>3</xsl:attribute>")
		Do XSL.Write("  <xsl:attribute name='y'>"_(..plot.plotTop + (..plot.plotHeight/2))_"</xsl:attribute>")
		Do XSL.Write("  <xsl:attribute name='transform'>rotate(-90,3,"_(..plot.plotTop+(..plot.plotHeight/2))_")</xsl:attribute>")
		Do XSL.Write("  "_title)
		Do XSL.Write("</"_..SvgPrefix()_"text>")
	}
	
	// Axis Labels
	Do XSL.WriteLine("<xsl:if test='$"_$$$yLabelUnits_" &gt; 0'>")
	If ..plot.yGridType = "value" {
		Do XSL.WriteLine("  <xsl:call-template name='zenReportYValueLabels"_$$$groupNum_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("    <xsl:with-param name='start' select='ceiling($"_$$$yMin_" div $"_$$$yLabelUnits_") * $"_$$$yLabelUnits_"' />")
		Do XSL.WriteLine("    <xsl:with-param name='end' select='floor($"_$$$yMax_" div $"_$$$yLabelUnits_") * $"_$$$yLabelUnits_"' />")
		Do XSL.WriteLine("    <xsl:with-param name='unit' select='$"_$$$yLabelUnits_"' />")
		Do XSL.WriteLine("  </xsl:call-template>")
	} Else {
		If ..plotToEdge {
			Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_" - 1' />")
			Do XSL.WriteLine("  <xsl:if test='$items &gt;= 0'>")
			Do XSL.WriteLine("    <xsl:variable name='dy'>")
			Do XSL.WriteLine("      <xsl:choose><xsl:when test='$items = 0'>")
			Do XSL.WriteLine("        <xsl:value-of select='"_..plot.plotHeight_"' />")
			Do XSL.WriteLine("      </xsl:when><xsl:otherwise>")
			Do XSL.WriteLine("        <xsl:value-of select='"_..plot.plotHeight_" div $items' />")
			Do XSL.WriteLine("      </xsl:otherwise></xsl:choose>")
			Do XSL.WriteLine("    </xsl:variable>")
			Do XSL.WriteLine("    <xsl:variable name='adj' select='$dy' />")
		} Else {
			Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
			Do XSL.WriteLine("  <xsl:if test='$items &gt; 0'>")
			Do XSL.WriteLine("    <xsl:variable name='dy' select='"_..plot.plotHeight_" div $items' />")
			Do XSL.WriteLine("    <xsl:variable name='adj' select='$dy div 2' />")
		}
		Do XSL.WriteLine("    <xsl:call-template name='zenReportYCategoryLabels"_$$$groupNum_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
		Do XSL.WriteLine("      <xsl:with-param name='dy' select='$dy' />")
		Do XSL.WriteLine("      <xsl:with-param name='adj' select='$adj' />")
		Do XSL.WriteLine("    </xsl:call-template>")
		Do XSL.WriteLine("  </xsl:if>")
	}
	Do XSL.WriteLine("</xsl:if>")
	
	Do XSL.Write("</"_..SvgPrefix()_"g>")
	Do ..yAxis.EndIfCommon(.context,.XSL,.delay)
	Quit $$$OK
}

/// Draw the x and y axes and grid lines.
Method renderAxes(context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream)
{
	// create gridlines
	// find set of values that correspond with "unit" size
	// and fit within range
	Set yGridType = ..getYAxisType()
	Set xGridType = ..getXAxisType()

	// ***** Y MAJOR LINES ******
	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-majorGridLine",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-majorGridLine",key)_"'"
	. s sep=" "
	Do XSL.WriteLine("<"_..SvgPrefix()_"path class='chart-majorGridLine'"_attribs_">")
	s tAtt=""
	if ..gridStyle'="" s tAtt=..gridStyle_";"
	if ..yAxis.majorGridStyle'="" s tAtt=tAtt_..yAxis.majorGridStyle_";"
	if tAtt'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)	
	Do XSL.WriteLine("  <xsl:attribute name='d'>")
	
	If yGridType = "value" {
		If ..yAxis.majorGridLines {
			Do XSL.WriteLine("    <xsl:if test='$"_$$$yMajorUnits_" &gt; 0'>")
			Do XSL.WriteLine("      <xsl:call-template name='zenReportYValueLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("        <xsl:with-param name='start' select='ceiling($"_$$$yMin_" div $"_$$$yMajorUnits_") * $"_$$$yMajorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='end' select='floor($"_$$$yMax_" div $"_$$$yMajorUnits_") * $"_$$$yMajorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='unit' select='$"_$$$yMajorUnits_"' />")
			Do XSL.WriteLine("      </xsl:call-template>")
			Do XSL.WriteLine("    </xsl:if>")
		}
	// category axis
	} Else {
		If ..yAxis.majorGridLines {
			If ..plotToEdge {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_" - 1' />")
			} Else {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
			}
			Do XSL.WriteLine("  <xsl:if test='$items &gt; 0'>")
			Do XSL.WriteLine("    <xsl:call-template name='zenReportYCategoryLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
			Do XSL.WriteLine("      <xsl:with-param name='dy' select='"_..plot.plotHeight_" div $items' />")
			Do XSL.WriteLine("      <xsl:with-param name='majorLines' select='true()' />")
			Do XSL.WriteLine("    </xsl:call-template>")
			Do XSL.WriteLine("  </xsl:if>") 
		}
	}
	Do XSL.WriteLine("  </xsl:attribute>")
	Do XSL.WriteLine("</"_..SvgPrefix()_"path>")
	
	// ***** Y MINOR LINES ******
		s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-minorGridLine",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-minorGridLine",key)_"'"
	. s sep=" "
	Do XSL.WriteLine("<"_..SvgPrefix()_"path class='chart-minorGridLine'"_attribs_">")
	s tAtt=""
	if ..gridStyle'="" s tAtt=..gridStyle_";"
	if ..yAxis.minorGridStyle'="" s tAtt=tAtt_..yAxis.minorGridStyle_";"
	if tAtt'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)
	Do XSL.WriteLine("  <xsl:attribute name='d'>")
	
	If yGridType = "value" {
		If ..yAxis.minorGridLines {
			Do XSL.WriteLine("    <xsl:if test='$"_$$$yMinorUnits_" &gt; 0'>")
			Do XSL.WriteLine("      <xsl:call-template name='zenReportYValueLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("        <xsl:with-param name='start' select='ceiling($"_$$$yMin_" div $"_$$$yMinorUnits_") * $"_$$$yMinorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='end' select='floor($"_$$$yMax_" div $"_$$$yMinorUnits_") * $"_$$$yMinorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='unit' select='$"_$$$yMinorUnits_"' />")
			Do XSL.WriteLine("      </xsl:call-template>")
			Do XSL.WriteLine("    </xsl:if>")
		}
	// category axis
	} Else {
		If ..yAxis.minorGridLines {
			If ..plotToEdge {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_" - 1' />")
			} Else {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
			}
			Do XSL.WriteLine("  <xsl:if test='$items &gt; 0'>")
			Do XSL.WriteLine("    <xsl:call-template name='zenReportYCategoryLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
			Do XSL.WriteLine("      <xsl:with-param name='dy' select='"_..plot.plotHeight_" div $items' />")
			Do XSL.WriteLine("      <xsl:with-param name='majorLines' select='false()' />")
			Do XSL.WriteLine("    </xsl:call-template>")
			Do XSL.WriteLine("  </xsl:if>") 
		}
	}
	Do XSL.WriteLine("  </xsl:attribute>")
	Do XSL.WriteLine("</"_..SvgPrefix()_"path>")

	// ***** X MAJOR LINES ******
	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-majorGridLine",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-majorGridLine",key)_"'"
	. s sep=" "
	Do XSL.WriteLine("<"_..SvgPrefix()_"path class='chart-majorGridLine'"_attribs_">")
	s tAtt=""
	if ..gridStyle'="" s tAtt=..gridStyle_";"
	if ..xAxis.majorGridStyle'="" s tAtt=tAtt_..xAxis.majorGridStyle_";"
	if tAtt'=""	Do XSL.WriteLine("  <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)	
	Do XSL.WriteLine("  <xsl:attribute name='d'>")
	
	If xGridType = "value" {
		If ..xAxis.majorGridLines {
			Do XSL.WriteLine("    <xsl:if test='$"_$$$xMajorUnits_" &gt; 0'>")
			Do XSL.WriteLine("      <xsl:call-template name='zenReportXValueLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("        <xsl:with-param name='start' select='ceiling($"_$$$xMin_" div $"_$$$xMajorUnits_") * $"_$$$xMajorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='end' select='floor($"_$$$xMax_" div $"_$$$xMajorUnits_") * $"_$$$xMajorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='unit' select='$"_$$$xMajorUnits_"' />")
			Do XSL.WriteLine("      </xsl:call-template>")
			Do XSL.WriteLine("    </xsl:if>")
		}
	// category axis
	} Else {
		If ..xAxis.majorGridLines {
			If ..plotToEdge {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_" - 1' />")
			} Else {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
			}
			Do XSL.WriteLine("  <xsl:if test='$items &gt; 0'>")
			Do XSL.WriteLine("    <xsl:call-template name='zenReportXCategoryLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
			Set mode = "legend"_$$$groupNum
			Do XSL.WriteLine("      <xsl:with-param name='dx' select='$plotWidth"_mode_" div $items' />")
			Do XSL.WriteLine("      <xsl:with-param name='majorLines' select='true()' />")
			Do XSL.WriteLine("    </xsl:call-template>")
			Do XSL.WriteLine("  </xsl:if>") 
		}
	}
	Do XSL.WriteLine("  </xsl:attribute>")
	Do XSL.WriteLine("</"_..SvgPrefix()_"path>")
	
	// ***** X MINOR LINES ******
	s attribs=""
	s sep=""
	s key="" for  s key=$o(context("SVGATTRS","chart-minorGridLine",key)) q:key=""  d
	. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-minorGridLine",key)_"'"
	. s sep=" "
	Do XSL.WriteLine("<"_..SvgPrefix()_"path class='chart-minorGridLine'"_attribs_">")
	s tAtt=""
	if ..gridStyle'="" s tAtt=..gridStyle_";"
	if ..xAxis.minorGridStyle'="" s tAtt=tAtt_..xAxis.minorGridStyle_";"
	if tAtt'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)	
	Do XSL.WriteLine("  <xsl:attribute name='d'>")
	
	If xGridType = "value" {
		If ..xAxis.minorGridLines {
			Do XSL.WriteLine("    <xsl:if test='$"_$$$xMinorUnits_" &gt; 0'>")
			Do XSL.WriteLine("      <xsl:call-template name='zenReportXValueLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("        <xsl:with-param name='start' select='ceiling($"_$$$xMin_" div $"_$$$xMinorUnits_") * $"_$$$xMinorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='end' select='floor($"_$$$xMax_" div $"_$$$xMinorUnits_") * $"_$$$xMinorUnits_"' />")
			Do XSL.WriteLine("        <xsl:with-param name='unit' select='$"_$$$xMinorUnits_"' />")
			Do XSL.WriteLine("      </xsl:call-template>")
			Do XSL.WriteLine("    </xsl:if>")
		}
	// category axis
	} Else {
		If ..xAxis.minorGridLines {
			If ..plotToEdge {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_" - 1' />")
			} Else {
				Do XSL.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
			}
			
			Do XSL.WriteLine("  <xsl:if test='$items &gt; 0'>")
			
			Do XSL.WriteLine("    <xsl:call-template name='zenReportXCategoryLines"_$$$groupNum_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
						Set mode = "legend"_$$$groupNum
			Do XSL.WriteLine("      <xsl:with-param name='dx' select='$plotWidth"_mode_" div $items' />")
			Do XSL.WriteLine("      <xsl:with-param name='majorLines' select='false()' />")
			Do XSL.WriteLine("    </xsl:call-template>")
			Do XSL.WriteLine("  </xsl:if>") 
		}
	}
	Do XSL.WriteLine("  </xsl:attribute>")
	Do XSL.WriteLine("</"_..SvgPrefix()_"path>")

	Quit $$$OK
}

Method writeWithParams(ByRef XSL As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:with-param name='"_$$$seriescount_"' select='$"_$$$seriescount_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$seriessize_"' select='$"_$$$seriessize_"' />")
	
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMax_"' select='$"_$$$xMax_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMin_"' select='$"_$$$xMin_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xRange_"' select='$"_$$$xRange_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMinorUnits_"' select='$"_$$$xMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMajorUnits_"' select='$"_$$$xMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xLabelUnits_"' select='$"_$$$xLabelUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xBase_"' select='$"_$$$xBase_"' />")
	
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMax_"' select='$"_$$$yMax_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMin_"' select='$"_$$$yMin_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yRange_"' select='$"_$$$yRange_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMinorUnits_"' select='$"_$$$yMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMajorUnits_"' select='$"_$$$yMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yLabelUnits_"' select='$"_$$$yLabelUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yBase_"' select='$"_$$$yBase_"' />")
}

Method writeWithParamsNoBase(ByRef XSL As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:with-param name='"_$$$seriescount_"' select='$"_$$$seriescount_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$seriessize_"' select='$"_$$$seriessize_"' />")
	
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMax_"' select='$"_$$$xMax_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMin_"' select='$"_$$$xMin_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xRange_"' select='$"_$$$xRange_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMinorUnits_"' select='$"_$$$xMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xMajorUnits_"' select='$"_$$$xMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$xLabelUnits_"' select='$"_$$$xLabelUnits_"' />")
	;Do XSL.WriteLine("<xsl:with-param name='"_$$$xBase_"' select='$"_$$$xBase_"' />")
	
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMax_"' select='$"_$$$yMax_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMin_"' select='$"_$$$yMin_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yRange_"' select='$"_$$$yRange_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMinorUnits_"' select='$"_$$$yMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yMajorUnits_"' select='$"_$$$yMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:with-param name='"_$$$yLabelUnits_"' select='$"_$$$yLabelUnits_"' />")
	;Do XSL.WriteLine("<xsl:with-param name='"_$$$yBase_"' select='$"_$$$yBase_"' />")
}

Method writeLoadParams(ByRef XSL As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:param name='"_$$$seriescount_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$seriessize_"' />")
	
	Do XSL.WriteLine("<xsl:param name='"_$$$xMax_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xMin_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xRange_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xLabelUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xBase_"' />")
	
	Do XSL.WriteLine("<xsl:param name='"_$$$yMax_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yMin_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yRange_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yLabelUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yBase_"' />")
}

Method writeLoadParamsNoBase(ByRef XSL As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:param name='"_$$$seriescount_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$seriessize_"' />")
	
	Do XSL.WriteLine("<xsl:param name='"_$$$xMax_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xMin_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xRange_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$xLabelUnits_"' />")
	;Do XSL.WriteLine("<xsl:param name='"_$$$xBase_"' />")
	
	Do XSL.WriteLine("<xsl:param name='"_$$$yMax_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yMin_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yRange_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yMinorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yMajorUnits_"' />")
	Do XSL.WriteLine("<xsl:param name='"_$$$yLabelUnits_"' />")
	;Do XSL.WriteLine("<xsl:param name='"_$$$yBase_"' />")
}

ClassMethod OnSVGAttribution(ByRef context As %String)
{
	/* background of chart */
	s context("SVGATTRS","chart-background","fill") = "darkblue"
	s context("SVGATTRS","chart-background","stroke") = "black"
	s context("SVGATTRS","chart-background","stroke-width") = "0.1px"

	/* background of plot area of chart */
	s context("SVGATTRS","chart-plotArea-background","fill")="white"
	s context("SVGATTRS","chart-plotArea-background","stroke")="none"


	/* border of plot area of chart */
	s context("SVGATTRS","chart-plotArea-border","fill")="none"
	s context("SVGATTRS","chart-plotArea-border","stroke")="black"
	s context("SVGATTRS","chart-plotArea-border","stroke-width")="0.1px"


	/* upper/lower band */

	s context("SVGATTRS","chart-band","fill")="#F0F0F0"
	s context("SVGATTRS","chart-band","stroke")="none"


	/* background of legend */

	s context("SVGATTRS","chart-legend","fill")="white"
	s context("SVGATTRS","chart-legend","stroke")="black"
	s context("SVGATTRS","chart-legend","stroke-width")="0.1px"

	s context("SVGATTRS","chart-majorGridLine","stroke")="black"
	s context("SVGATTRS","chart-majorGridLine","stroke-width")="0.1px"

	s context("SVGATTRS","chart-minorGridLine","stroke")="black"
	s context("SVGATTRS","chart-minorGridLine","stroke-width")="0.1px"
	s context("SVGATTRS","chart-minorGridLine","opacity")="0.5"
	s context("SVGATTRS","chart-minorGridLine","stroke-dasharray")="0.1,0.1"

	/* "lines in line plots */
 
	s context("SVGATTRS","chart-seriesLine","stroke-width")="0.25px"
	s context("SVGATTRS","chart-seriesLine","stroke-linecap")="round"
	s context("SVGATTRS","chart-seriesLine","stroke-linejoin")="round"

	 /* bars in bar plots */
 
	s context("SVGATTRS","chart-seriesBar","stroke-width")="0.25px"
	s context("SVGATTRS","chart-seriesBar","stroke-linecap")="round"
	s context("SVGATTRS","chart-seriesBar","stroke-linejoin")="round"

	/* tick marks */
 
	s context("SVGATTRS","chart-majorTick","stroke")="black"
	s context("SVGATTRS","chart-majorTick","stroke-width")="1px"
	s context("SVGATTRS","chart-majorTick","opacity")="0.7"
	s context("SVGATTRS","chart-majorTick","stroke-linecap")="round"
 
	s context("SVGATTRS","chart-minorTick","stroke")="black"
	s context("SVGATTRS","chart-minorTick","stroke-width")="1px"
	s context("SVGATTRS","chart-minorTick","opacity")="0.7"
	s context("SVGATTRS","chart-minorTick","stroke-linecap")="round"

	/* labels */
 
	s context("SVGATTRS","chart-title","pointer-events")="none"
	s context("SVGATTRS","chart-title","font-size")="4px"
	s context("SVGATTRS","chart-title","fill")="yellow"
	s context("SVGATTRS","chart-title","stroke")="none"

 	s context("SVGATTRS","chart-xLabel","pointer-events")="none"
	s context("SVGATTRS","chart-xLabel","font-size")="3px"
	s context("SVGATTRS","chart-xLabel","fill")="yellow"
	s context("SVGATTRS","chart-xLabel","stroke")="none"

	s context("SVGATTRS","chart-yLabel","pointer-events")="none"
	s context("SVGATTRS","chart-yLabel","font-size")="3px"
	s context("SVGATTRS","chart-yLabel","fill")="yellow"
	s context("SVGATTRS","chart-yLabel","stroke")="none"

	s context("SVGATTRS","chart-legendLabel","pointer-events")="none"
	s context("SVGATTRS","chart-legendLabel","font-size")="2.5px"
	s context("SVGATTRS","chart-legendLabel","fill")="black"
	s context("SVGATTRS","chart-legendLabel","stroke")="none"
}

Method SvgPrefix()
{
	quit $s(%report.isHTML5:"",1:"svg:")
}

}
