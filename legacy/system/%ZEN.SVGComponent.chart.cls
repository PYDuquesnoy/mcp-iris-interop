/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the abstract base class from which all SVG chart components are derived.<br/>
/// A chart provides a base on which to display a specific type
/// of chart (such as a <class>barChart</class>, <class>lineChart</class>, or <class>pieChart</class>).<br/>
/// This base class defines the data, grid (axes and scales), styles, and legend
/// used by charts.<br/>
/// All charts are plotted onto a virtual coordinate space that
/// measures 100 units by 100 units.<br/>
/// You can adjust the visual aspects of a chart by setting the various properties of this
/// class (plus any additional properties added by the specific chart subclass).<br/>
/// You can adjust the x and y axis settings (such as scaling and range) via the
/// <property>xAxis</property> and <property>yAxis</property> properties (which are objects of the type <class>%ZEN.Auxiliary.axis</class>).
Class %ZEN.SVGComponent.chart Extends (svgComponent, %ZEN.Component.dataView) [ Abstract, Deprecated, System = 3 ]
{

/// Parameter SYSMODULE = "chart";
/// Default value for the plotToEdge property.
Parameter DEFAULTPLOTTOEDGE As BOOLEAN = 1;

/// Default value for the markersVisible property.
Parameter DEFAULTMARKERSVISIBLE As BOOLEAN = 0;

/// Default value for the valueLabelsVisible property.
Parameter DEFAULTVALUELABELSVISIBLE As BOOLEAN = 0;

/// Do not worry about preserving the aspect ratio.
Parameter DEFAULTASPECT = "none";

/// Default viewBoxWidth of this component.
/// This is set to 100 to provide a fixed coordinate system for meters.
Parameter DEFAULTVIEWBOXWIDTH;

/// Default viewBoxHeight of this component.
/// This is set to 100 to provide a fixed coordinate system for meters.
Parameter DEFAULTVIEWBOXHEIGHT;

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "2D";

/// Default setting for autoscaling text as chart resizes
Parameter DEFAULTAUTOSCALETEXT As BOOLEAN = 1;

/// x axis specification for this chart.
Property xAxis As %ZEN.Auxiliary.axis(ZENSETTING = 0);

/// Deprecated. y axis specifications for this chart.
/// This is replaced by yAxisList. This property is kept here so that
/// applications that set yAxis directly will still function.
Property yAxis As %ZEN.Auxiliary.axis(XMLPROJECTION = "none", ZENSETTING = 0);

/// List of y axis specifications for this chart.
Property yAxisList As list Of %ZEN.Auxiliary.axis(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Optional: style used for chart background panel.
Property backgroundStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for chart plot area panel.
Property plotAreaStyle As %ZEN.Datatype.svgStyle;

/// Optional: for charts with a 3D look, this style is applied
/// to the edges on the left and bottom.
Property plotEdgeStyle As %ZEN.Datatype.svgStyle;

/// Title to display for chart.
Property title As %ZEN.Datatype.caption;

/// Subtitle to display for chart.
Property subtitle As %ZEN.Datatype.caption;

/// Title to display for legend box.
Property legendTitle As %ZEN.Datatype.caption;

/// Optional: alignment for title and subtitle.
Property titleAlign As %ZEN.Datatype.string(VALUELIST = ",center,left,right") [ InitialExpression = "center" ];

/// Optional: style used for title text.
Property titleStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for subtitle text.
Property subtitleStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for box underneath title text.
Property titleBoxStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for border line inset from outer edge of chart.
Property borderStyle As %ZEN.Datatype.svgStyle;

/// Optional: if true, draw stripes over value axis grid lines.
Property stripesVisible As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for grid stripes (when enabled).
Property stripeStyle As %ZEN.Datatype.svgStyle;

/// Optional: distance (in pixels) between the background rectangle and the border.
Property borderOffset As %ZEN.Datatype.integer [ InitialExpression = 8 ];

/// Optional: radius applied to the chart's background rectangle and border.
Property borderRadius As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// If this chart has a title, x-position (within the chart coordinate space) of the title.
/// If not specified, then a default value is calculated.
Property titleX As %ZEN.Datatype.length;

/// If this chart has a title, y-position (within the chart coordinate space) of the title.
/// If not specified, then a default value is calculated.
Property titleY As %ZEN.Datatype.length;

/// Number of data series to display on this chart.
/// If "", then this is computed automatically from the chart's data source when the
/// chart is connected to a dataController.
Property seriesCount As %ZEN.Datatype.integer(MINVAL = 0);

/// Number of items within each data series to display on this chart.
/// If "", then this is computed automatically from the chart's data source when the
/// chart is connected to a dataController.
Property seriesSize As %ZEN.Datatype.integer(MINVAL = 0);

/// Comma-delimited list of CSS color values used for data series.
/// This can be set to a list of SVG fill color values, e.g.,
/// "red,green,blue" or "url(#glow-red),url(#glow-green),url(#glow-blue)".<br/>
/// The first color is used by the first data series and so on. If there are
/// more data series than colors, the colors are repeated.<br/>
/// If this is not defined the colors defined by <property>seriesColorScheme</property>
/// are used.
Property seriesColors As %ZEN.Datatype.csv;

/// Additional Comma-delimited list of CSS color values used for data series.
/// If supplied, this is merged with the colors in the seriesColors list.
/// This makes it possible to override specific colors within a chart while preserving
/// the underlying default colors.
Property seriesColorsOverride As %ZEN.Datatype.csv;

/// This is the name of a built-in color scheme used to plot
/// data series for the chart.<br/>
/// If <property>seriesColors</property> is defined, then this
/// property is ignored.
Property seriesColorScheme As %ZEN.Datatype.string(VALUELIST = ",urban,tuscan,caribbean,rustbelt,bright,glow,gray,pastel,solid") [ InitialExpression = "tuscan" ];

/// Comma-delimited list of names used to label each data series in the legend box.<br/>
/// This is a localized value (the entire list is treated as one localized string).
Property seriesNames As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// Optional. If defined then the chart will only plot the specified data series (0-based) when connected
/// to a data controller. This is used by DeepSee in some cases.
Property seriesNumber As %ZEN.Datatype.integer(MINVAL = 0);

/// Optional. If defined, specifies which y-axis should be used for each data
/// series. This is a csv-list of y-axis numbers (0-based).
/// By default, the every data series uses y-axis 0.
Property seriesYAxes As %ZEN.Datatype.csv;

/// Specifies which yAxis definition is used to drive the chart yaxis (0 based).
Property currYAxis As %ZEN.Datatype.integer(MINVAL = 0) [ InitialExpression = 0 ];

/// Comma-delimited list of marker shapes used for data series markers.
/// Possible values are 'up','down','square','circle'.<br/>
/// This only applies to charts that support markers.
Property markerShapes As %ZEN.Datatype.csv [ InitialExpression = "circle,up,down,square" ];

/// Scaling applied to chart markers:
/// A value of 1.0 (or '') will display markers with their default size.
/// This only applies to charts that support markers.
Property markerScale As %ZEN.Datatype.float [ InitialExpression = 1 ];

/// Optional: default style applied to all grid line elements for this chart.
/// If defined, this style overrides any styles define in the CSS style
/// definition for the page, but is in turn overridden by any styles defined
/// by a specific axis element.
Property gridStyle As %ZEN.Datatype.svgStyle;

/// Optional: default style applied to all grid label elements for this chart.
/// If defined, this style overrides any styles define in the CSS style
/// definition for the page, but is in turn overridden by any styles defined
/// by a specific axis element.
Property labelStyle As %ZEN.Datatype.svgStyle;

/// Maximum number of characters to display for an axis label.
Property maxLabelLen As %ZEN.Datatype.integer [ InitialExpression = 20 ];

/// Optional: default style applied to axis titles for this chart.<br/>
/// This is applied <em>in addition</em> to the style supplied by <property>labelStyle</property>.
Property axisTitleStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "opacity:0.5;" ];

/// If true, display axis labels for this chart (or slice labels in the
/// case of a pie chart).
Property labelsVisible As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, display a legend for this chart.
/// If "auto" then the legend is displayed if there is more than one data series
/// for the chart.
Property legendVisible As %ZEN.Datatype.string(VALUELIST = ",auto,false,true") [ InitialExpression = "auto" ];

/// If this chart has a legend, x-position (within the chart coordinate space) of legend box.
/// If not specified a default position will be used.
Property legendX As %ZEN.Datatype.length;

/// If this chart has a legend, y-position (within the chart coordinate space) of legend box.
/// If not specified a default position will be used.
Property legendY As %ZEN.Datatype.length;

/// If this chart has a legend, width (within the chart coordinate space) of legend box.
/// If not specified a default width will be used.
Property legendWidth As %ZEN.Datatype.length;

/// If this chart has a legend, height (within the chart coordinate space) of legend box.
/// If not specified a default height (based on number of data series) will be used.
Property legendHeight As %ZEN.Datatype.length;

/// Optional: style used for background of the legend box.
Property legendStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for text within the legend box.
Property legendLabelStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for rectangle indicating the current legend within the legend box.
Property legendRectStyle As %ZEN.Datatype.svgStyle;

/// Margin (within the chart coordinate space) from top edge of chart to top edge of grid (plot area).
/// If not specified, then this value will be automatically calculated.
Property marginTop As %ZEN.Datatype.length;

/// Margin (within the chart coordinate space) from bottom edge of chart to bottom edge of grid (plot area).
/// If not specified, then this value will be automatically calculated.
Property marginBottom As %ZEN.Datatype.length;

/// Margin (within the chart coordinate space) from left edge of chart to left edge of grid (plot area).
/// If not specified, then this width will be automatically calculated.
Property marginLeft As %ZEN.Datatype.length;

/// Margin (within the chart coordinate space) from right edge of chart to right edge of grid (plot area).
/// If not specified, then this width will be automatically calculated.
Property marginRight As %ZEN.Datatype.length;

/// Specifies whether markers should be displayed for the data
/// points within the chart.<br/>
/// This only applies to charts that display markers.
Property markersVisible As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTMARKERSVISIBLE} ];

/// Specifies whether values should be displayed for elements within the chart.
/// This only applies to charts that display element values (such as bar charts).
Property valueLabelsVisible As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTVALUELABELSVISIBLE} ];

/// Optional: style used for value labels.
/// This only applies to charts that display element values (such as bar charts).
Property valueLabelStyle As %ZEN.Datatype.svgStyle;

/// Optional: numeric format applied to value labels.
/// This only applies to charts that display element values (such as bar charts).
Property valueLabelFormat As %ZEN.Datatype.string;

/// Optional: style used for boxes around value labels.
/// This only applies to charts that display element values (such as bar charts).
Property valueBoxStyle As %ZEN.Datatype.svgStyle;

/// Specifies how the text elements of a chart should be handled when a chart is
/// resized.  If True, the text scales in proportion to the chart itself and all
/// requested labels are rendered regardless of legibility.  If false, the size of 
/// the text elements is fixed with respect to the page and some lables may be 
/// omitted to avoid visual overlap if insufficient space is provided to render the
/// values should the chart be scaled down beyond certain thresholds
Property autoScaleText As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTAUTOSCALETEXT} ];

/// Specifies how values should be plotted along a category axis.
/// If true, plot the first and last values on the edges of the plotArea
/// (as in a line chart). If false, plot values in the centers of each
/// unit (as in a bar chart).<br/>
/// This is specified by subclasses.
Property plotToEdge As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTPLOTTOEDGE} ];

/// If defined, then a colored band (specified by <property>bandUpperStyle</property>)
/// is displayed on the plot area covering the range greater than this value;
Property bandUpper As %ZEN.Datatype.float;

/// If defined, then a colored band (specified by <property>bandLowerStyle</property>)
/// is displayed on the plot area covering the range lower than this value;
Property bandLower As %ZEN.Datatype.float;

/// Optional: style used for upper band on plot area.
Property bandUpperStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for upper band on plot area.
Property bandLowerStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to line drawn for x and y axes.
Property axisLineStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to base line.
Property baseLineStyle As %ZEN.Datatype.svgStyle;

/// Controls the appearance of this chart.<br/>
/// Set this to "2D" (the default) for a standard chart appearance.<br/>
/// Setting this to "3D" will give the chart a 3-D appearance; the
/// plot area will appear to be recessed. Certain chart types, such as
/// bar charts, will display items with a 3-D look.<br/>
/// For pie charts, setting this to "3D" will display a pie chart with
/// a 3-D appearance, but will not affect the plot area.
Property appearance As %ZEN.Datatype.string(VALUELIST = ",2D,3D") [ InitialExpression = {..#DEFAULTAPPEARANCE} ];

/// Optional: if "medium", use the default font sizes specified by the CSS for the chart.
/// if "small" or "large" adjust the size of any text in the chart that does not have an explicit
/// style set (via a property).
Property textSize As %ZEN.Datatype.string(VALUELIST = ",small,medium,large") [ InitialExpression = "medium" ];

/// Optional: if true, display zoom in/out buttons (for certain chart types).
Property hasZoom As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: If true, display chart as number of small multiple charts, one per data series.
/// This is only used by charts that support small multiples otherwise it is ignored.
Property showMultiples As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for title text within each "multiple" charts.
/// Used when <property>showMultiples</property> is enabled.
Property multipleTitleStyle As %ZEN.Datatype.svgStyle;

/// Internal property used to track which multiple is being rendered.
Property currMultiple As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// ongetData event handler:
/// This event handler, if defined, is called by the chart
/// to get an array of values to plot for a data series.
/// This provides an alternate way to provide display data for
/// a chart.<br/>
/// The event handler is passed an argument, <var>series</var>,
/// that contains the ordinal number (0-based) of the data series.
/// This event handler should return an array of numeric values for
/// the specified data series.<br/>
Property ongetData As %ZEN.Datatype.eventHandler;

/// ongetLabelX event handler:
/// This event handler, if defined, is called by the chart
/// to get the text for a given label on the x axis.<br/>
/// The event handler is passed an argument, <var>value</var>,
/// that contains the ordinal number (0-based) of the label.
Property ongetLabelX As %ZEN.Datatype.eventHandler;

/// ongetLabelY event handler:
/// This event handler, if defined, is called by the chart
/// to get the text for a given label on the y axis.<br/>
/// The event handler is passed an argument, <var>value</var>,
/// that contains the ordinal number (0-based) of the label.
Property ongetLabelY As %ZEN.Datatype.eventHandler;

/// onelementClick event handler:
/// This event handler is called by the chart
/// when the user clicks the mouse on a chart element 
/// (such as a line chart marker, or bar in a bar chart).<br/>
/// The event handler is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. You can then use the
/// <method>getSelectedItem</method> method to determine the
/// current selected element.
Property onelementClick As %ZEN.Datatype.eventHandler;

/// onrenderPlotArea event handler:
/// This event handler, if defined, is called by the chart
/// just after it displays its underlying plot area (and
/// bands) but before it display grid lines and data.
Property onrenderPlotArea As %ZEN.Datatype.eventHandler;

/// onrenderData event handler:
/// This event handler, if defined, is called by the chart
/// just after it is finished displaying grid lines and data.
/// The event handler is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. If it also passed <var>group</var>,
/// which is the SVG group to which any new svg content should be added.
Property onrenderData As %ZEN.Datatype.eventHandler;

/// onshowTooltip event handler:
/// This event handler, if defined, is called by the chart
/// just before it displays a tool tip.
Property onshowTooltip As %ZEN.Datatype.eventHandler;

/// Optional: default style applied to svg elements used for plotting
/// data by this chart (such as the bars within a bar chart).
/// Note: lines within line charts use the <property>lineStyle</property> property.
Property plotStyle As %ZEN.Datatype.svgStyle;

/// Optional: default style applied to svg line elements within line-style charts.
Property lineStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for series markers.
Property markerStyle As %ZEN.Datatype.svgStyle;

/// Specifies whether indicator lines should be displayed for the selected item
/// within the chart.<br/>
/// This only applies to charts that display indicator lines.
Property indicatorsVisible As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for indicators.
Property indicatorStyle As %ZEN.Datatype.svgStyle;

/// ongetTimeEvents event handler:
/// This event handler, if defined, is called by the chart
/// to get an array of "time events" to display for a time chart.<br/>
Property ongetTimeEvents As %ZEN.Datatype.eventHandler;

/// Optional: style used to indicate the current selected chart element.
Property selectedItemStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "stroke:darkgreen;stroke-width:3px;" ];

/// Optional: style used to indicate unselected chart elements.
/// This is used when there is a selected element.
Property unselectedItemStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "opacity:0.5;" ];

/// Optional: style applied to zoom and scroll buttons when visible.
Property scrollButtonStyle As %ZEN.Datatype.svgStyle;

/// Series number (0-based) of currently selected chart element, if any.
Property selectedSeries As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Item number (0-based) of currently selected chart element, if any.
Property selectedItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Internal horizontal zoom factor.
/// 0 is fully zoomed out; each increase of 1 doubles the number of visible items.
Property hzZoomStep As %ZEN.Datatype.float(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// Internal amount of horizontal scroll.
Property scrollLeft As %ZEN.Datatype.float(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0.0, Internal ];

/// Property set by things like bubble chart which don't support seriesYAxes.
Property tag As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Optional: If true, then the x-axis for this chart is a time line displaying date values
/// from <property>startTime</property> to <property>endTime</property>.
/// In this case, the series names for data are interpreted as time values (YYYY-MM-DD HH:MM:SS).
/// This setting only works in a few cases, namely non-pivotted line charts. For all other
/// cases this setting is ignored.
Property timeBased As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Earliest displayed time (as YYYY-MM-DD HH:MM:SS).
/// This is used for the x axis in a timeBased chart.
Property startTime As %ZEN.Datatype.string;

/// Latest displayed time (as YYYY-MM-DD HH:MM:SS).
/// This is used for the x axis in a timeBased chart.
Property endTime As %ZEN.Datatype.string;

/// Optional: URL of image to display within the title area.
Property titleImage As %ZEN.Datatype.uri;

/// Optional. Style for titleImage: left,top,width, and height.
Property titleImageStyle As %ZEN.Datatype.svgStyle;

/// ongetSeriesColor event handler:
/// This event handler, if defined, is called by the chart
/// to get the color for a given data series.<br/>
/// The event handler is passed an argument, <var>series</var>,
/// that contains the ordinal number (0-based) of the series.
Property ongetSeriesColor As %ZEN.Datatype.eventHandler;

/// if non-null used to set style for tool tip rectangle
Property tooltipRectStyle As %ZEN.Datatype.svgStyle;

/// Set to 1 to display a localized warning message if chart has no data
Property warnIfNoData As %ZEN.Datatype.boolean;

/// localized warning message if chart has no data
Property msgIfNoData As %ZEN.Datatype.caption [ InitialExpression = "No Data" ];

/// opacity of background rectangle for no data message
Property noDataOpacity As %ZEN.Datatype.float [ InitialExpression = "1.0" ];

/// color of background rectangle for no data message
Property noDataFill As %ZEN.Datatype.color [ InitialExpression = "red" ];

/// color of no data message
Property noDataStroke As %ZEN.Datatype.color [ InitialExpression = "white" ];

XData SVGStyle
{
<style type="text/css">

/* @doc="Background of chart." */
.chart-background {
	fill: silver;
	stroke: black;
	stroke-width: 1.0px;
}

/* @doc="Border line inset from edge of chart." */
.chart-border {
	fill: none;
	stroke: none;
	stroke-width: 0.3px;
}

/* @doc="Plot area of chart." */
.chart-plotArea {
	fill: url(#glow-silverDiag);
	stroke: black;
	stroke-width: 0.1px;
}

/* @doc="Line along x and y axis." */
.chart-axisLines {
	fill: none;
	stroke: none;
	stroke-width: 1px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Base line" */
.chart-baseLine {
	fill: none;
	stroke: #808080;
	stroke-width: 0.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Plot edge for 3D chart." */
.chart-plotEdge {
	fill: gray;
	stroke: black;
	stroke-width: 0.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Upper or lower band." */
.chart-band {
	fill: #D0D0F0;
	stroke: none;
}

/* @doc="Background of entire legend." */
.chart-legend {
	fill: #F8F8F8;
	stroke: black;
	stroke-width: 0.5px;
}

/* @doc="Rectangle for selected legend." */
.chart-legendRect {
	fill: #FFEEAA;
	stroke: none;
}

/* @doc="Major grid lines." */
.chart-majorGridLine { 
	stroke: black;
	stroke-width: 0.4px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Grid stripes." */
.chart-gridStripes { 
	stroke: none;
	fill: #F0F0F0;
}

/* @doc="Minor grid lines." */
.chart-minorGridLine { 
	stroke: #808080;
	stroke-width: 0.5px;
	opacity: 0.5;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Indicator lines." */
.chart-indicator { 
	stroke: orange;
	stroke-width: 1px;
	stroke-linecap: round;
	stroke-dasharray: 2,2;
}

/* @doc="Lines within line plots." */
.chart-seriesLine {
	stroke-width: 1.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Markers within line plots." */
.chart-seriesMarker {
	stroke-width: 1.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
	fill: white;
}

/* @doc="Bars within bar plots." */
.chart-seriesBar {
	stroke-width: 0.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
	stroke: #202020;
}

/* @doc="Target bars within combo plots." */
.chart-seriesTarget {
	stroke-width: 0.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
	stroke: none;
	opacity: 0.8;
}

/* @doc="Style for inverted bars: high is less than low." */
.chart-seriesBarInverted {
	fill: url(#zenHatch);
	stroke-width: 0.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
	stroke: #808080;
}

/* @doc="Major tick marks." */
.chart-majorTick { 
	stroke: #404040;
	stroke-width: 0.75px;
	stroke-linecap: round;
}

/* @doc="Minor tick marks." */
.chart-minorTick { 
	stroke: #606060;
	stroke-width: 1px;
	opacity: 0.7;
	stroke-linecap: round;
}

/* @doc="Chart title." */
.chart-title { 
	pointer-events: none;
	fill: #404040;
	stroke: none;
}

/* @doc="Chart subtitle." */
.chart-subtitle { 
	pointer-events: none;
	fill: #606060;
	stroke: none;
}

/* @doc="Box underneath chart title." */
.chart-titleBox { 
	fill: none;
	stroke: none;
}

/* @doc="Labels on x-axis." */
.chart-xLabel { 
	pointer-events: none;
	fill: #404040;
	stroke: none;
}

/* @doc="Title for x-axis." */
.chart-xAxisTitle { 
	pointer-events: none;
	fill: #404040;
	stroke: none;
}

/* @doc="Labels on y-axis." */
.chart-yLabel { 
	pointer-events: none;
	fill: #404040;
	stroke: none;
}

/* @doc="Title for y-axis." */
.chart-yAxisTitle { 
	pointer-events: none;
	fill: #404040;
	stroke: none;
}

/* @doc="Labels for PieChart slices." */
.chart-sliceLabel { 
	pointer-events: none;
	font-size: 11px;
	fill: #404040;
	stroke: none;
}

/* @doc="Line to labels for PieChart slices." */
.chart-sliceLine { 
	fill: none;
	opacity: 0.5; 
	stroke: black;
	stroke-width: 1.5px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* @doc="Labels within legend box." */
.chart-legendLabel {
	pointer-events: none;
	font-size: 12px;
	fill: #404040;
	stroke: none;
}

/* @doc="warning message if no data." */
.chart-warnifnodata {
	pointer-events: none;
	font-size: 12px;
	fill: none;
	stroke: none;
}

/* @doc="Scroll and zoom buttons." */
.chart-scrollButton {
	fill: #404080;
	stroke: #808080;
	stroke-width: 0.5px;
}

/* @doc="Text used for element value." */
.chart-valueLabel {
	font-size: 10px;
	pointer-events: none;
	fill: #404040;
	stroke: none;
}

/* @doc="Rectangle behind element value." */
.chart-valueLabelBox {
	fill: white;
	fill-opacity: 0.75;
	stroke: #808080;
	stroke-width: 1px;
}

/* @doc="Rectangle behind element label (e.g. bullseye)." */
.chart-labelBox {
	fill: white;
	fill-opacity: 0.1;
	stroke: #808080;
	stroke-width: 0.25px;
}

/* @doc="Rectangle for tool tip box." */
.chart-tooltipRect {
	fill: white;
	stroke:#404040;
	stroke-width: 0.5px;
	fill-opacity: 0.95;
}

/* @doc="Caption within tool tip box." */
.chart-tooltipCaption {
	pointer-events: none;
	fill: #606060;
	stroke: none;
}

/* @doc="Value displayed within tool tip box." */
.chart-tooltipValue {
	pointer-events: none;
	font-weight: bold;
	fill: #404040;
	stroke: none;
}

/* @doc="Time event rectangle." */
.chart-timeEvent {
	fill: white;
	stroke: #808080;
	stroke-width: 0.5px;
}

.chart-timeEventLine {
	fill: none;
	stroke: #808080;
	stroke-width: 0.5px;
}

.chart-timeEventLabel { 
	pointer-events: none;
	fill: #606060;
	font-weight:bold;
	stroke: none;
}

</style>
}

/// Call this method to update contents of this chart.
ClientMethod updateChart() [ Language = javascript ]
{
	this.selectedSeries = -1;  // Set back to initial value JSL4331
	this.render();
}

/// Client-side method to render control.
ClientMethod renderContents() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	if (this.hidden) return;

	// JMD1264
	if (this._timerId) {
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}
	if (this._tooltip) {
		this.hideToolTip();
	}

	// used for computations
	this._date1900 = new Date(1900,0,1,0,0,0,0);
	
	// track if we have computed an xmax (for time-based charts)
	var oldXMax = this._xMaxValue ? this._xMaxValue : null;

	// JMD1100
	// if view box is turned off; find scaling factors
	if (this.viewBoxWidth == '' && this.viewBoxHeight == '') {
		this._scaleX = parseInt(this.width,10)/100;
		this._scaleY = parseInt(this.height,10)/100;
	}
	else {
		this._scaleX = 1;
		this._scaleY = 1;
	}
	var scaleX = this._scaleX;
	var scaleY = this._scaleY;

	// JMD1125 do not render if too small
	if (parseInt(this.width) <= 1 || parseInt(this.height) <= 1) {
		return;
	}

	// error test
	var yaCount = this.getYAxisCount();
	if (this.currYAxis < 0 || this.currYAxis >= yaCount) {
		alert('currYAxis is out of range for chart, ' + this.currYAxis + ', in chart \'' + this.id + '\'');
		return;
	}

	// set up data series colors
	if (!zenIsMissing(this.seriesColors)) {
		// JMD1064-- we can't use split as there could be rgb(r,g,b) values in the list!
		var str = this.seriesColors.toString()+',';
		var inParen = false;
		var token = '';
		this._seriesColors = [];
		for (var n = 0; n < str.length; n++) {
			var ch = str.charAt(n);
			if (inParen) {
				token += ch;
				if (ch == ')') {
					inParen = false;
				}
			}
			else {
				if (ch == ',') {
					if (token!='') {
						this._seriesColors[this._seriesColors.length] = token;
					}
					token = '';
				}
				else if (ch == '(') {
					inParen = true;
					token += ch;
				}
				else {
					token += ch;
				}
			}
		}
	}
	else {
		this._seriesColors = this.getColorSchemeArray(this.seriesColorScheme);
	}

	// JMD995: do this first
	// get data for chart
	this.acquireData();

	// JMD1125: skip if nothing to do
	if (this.seriesSize<=0) {
		this.unrender();
		return;
	}

	// define mapping of data series to y-axis.
	this._yAxisForSeries = [];
	if (this.hasAxes() && !zenIsMissing(this.seriesYAxes)) {
		var t = this.seriesYAxes.toString().split(',');
		for (var s = 0; s < this.seriesCount; s++) {
			var ax = t[s] ? parseInt(t[s]) : 0;
			if (''===ax || isNaN(ax)) {
				alert('Illegal value in seriesYAxes, ' + t[s] + ', in chart \'' + this.id + '\'');
				return;
			}
			else if (ax < 0 || ax >= yaCount) {
				alert('Out-of-range value in seriesYAxes, ' + t[s] + ', in chart \'' + this.id + '\'');
				return;
			}
			this._yAxisForSeries[s] = ax;
		}
	}
	else {
		for (var s = 0; s < this.seriesCount; s++) {
			this._yAxisForSeries[s] = 0;
		}
	}

	// merge in override colors
	if (!zenIsMissing(this.seriesColorsOverride)) {
		// JMD831-- we can't use split as there could be rgb(r,g,b) values in the list!
		var str = this.seriesColorsOverride.toString()+',';
		var inParen = false;
		var token = '';
		var over = [];
		for (var n = 0; n < str.length; n++) {
			var ch = str.charAt(n);
			if (inParen) {
				token += ch;
				if (ch == ')') {
					inParen = false;
				}
			}
			else {
				if (ch == ',') {
					over[over.length] = token ? token : '';
					token = '';
				}
				else if (ch == '(') {
					inParen = true;
					token += ch;
				}
				else {
					token += ch;
				}
			}
		}
		
		var c = over.length > this._seriesColors.length ? over.length : this._seriesColors.length;
		for (var n = 0; n < c; n++) {
			if (over[n] && over[n]!=='') {
				this._seriesColors[n] = over[n];
			}
			else if (!this._seriesColors[n]) {
				this._seriesColors[n] = 'blue';
			}
		}
	}

	if (this.hasMultiples()) {
		// skip repaint optimizations
		this.unrender();
	}

	// create chart background panel
	var borderOffset = parseInt(this.borderOffset,10); // pixels
	borderOffset = (isNaN(borderOffset)||(borderOffset<0)) ? 0 : borderOffset;
	borderOffset = (borderOffset>(100*scaleY*2)) ? 0 : borderOffset;
	if (null == this.findSVGElement('background')) {
		var pane = this.document.createElementNS(SVGNS,"rect");
		pane.setAttribute("id",this.makeId('background'));
		pane.setAttribute("class","chart-background");
		pane.setAttribute("style",this.backgroundStyle);
		pane.setAttribute("rx",this.borderRadius);
		pane.setAttribute("x",0);
		pane.setAttribute("y",0);
		pane.setAttribute("width",100*scaleX);
		pane.setAttribute("height",100*scaleY);
		this.svgGroup.appendChild(pane);

		// default click handler: turn off selected item
		var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,null,null);');
		pane.addEventListener('click',f,false);

		// JMD1264: if mouse out does not fire; try to hide tooltip on move
		var f2 = new Function('evt','zenPage.getComponent('+this.index+').hideToolTip()');
		pane.addEventListener('mousemove',f2,false);

		// create chart border
		var border = this.document.createElementNS(SVGNS,"rect");
		border.setAttribute("id",this.makeId('border'));
		border.setAttribute("class","chart-border");
		border.setAttribute("style",this.borderStyle);
		border.setAttribute("rx",this.borderRadius);
		border.setAttribute("x",borderOffset);
		border.setAttribute("y",borderOffset);
		border.setAttribute("width",(100*scaleX)-(borderOffset*2));
		border.setAttribute("height",(100*scaleY)-(borderOffset*2));
		this.svgGroup.appendChild(border);
	}
	else {
		// update size of background and border
		var pane = this.findSVGElement('background');
		pane.setAttribute("style",this.backgroundStyle);
		pane.setAttribute("rx",this.borderRadius);
		pane.setAttribute("x",0);
		pane.setAttribute("y",0);
		pane.setAttribute("width",100*scaleX);
		pane.setAttribute("height",100*scaleY);

		var border = this.findSVGElement('border');
		border.setAttribute("style",this.borderStyle);
		border.setAttribute("rx",this.borderRadius);
		border.setAttribute("x",borderOffset);
		border.setAttribute("y",borderOffset);
		border.setAttribute("width",(100*scaleX)-(borderOffset*2));
		border.setAttribute("height",(100*scaleY)-(borderOffset*2));
	}

	// JMD1100
	this._controlBarH = 0;
	if (this.hasAxes() && this.hasZoom && !this.isTimeBased() && !this.chartPivot && (this.appearance=='2D')) {
		this._controlBarH = 18;
	}
 
 	var multiples = 1;
	var rowCount = 1;
	var colCount = 1;
	this.currMultiple = '';
	if (this.hasMultiples()) {
		multiples = this.getSeriesCount();
		this.currMultiple = 0;

		// find number of rows and columns needed to display multiples
		if (this.isTimeBased()) {
			rowCount = multiples;
			colCount = 1;
		}
		else {
			if (this.width <= this.height) {
				colCount = Math.floor(Math.sqrt(multiples));
				rowCount = Math.ceil(multiples/colCount);
			}
			else {
				// JMD1100: add 1 to force 3 items to use 2 rows
				rowCount = Math.floor(Math.sqrt(multiples+1));
				colCount = Math.ceil(multiples/rowCount);
			}
		}
	}

	// if multiples, then loop
	var oldGroup = this.svgGroup;
	for (var r = 0; r < rowCount; r++) {
		for (var c = 0; c < colCount; c++) {
			if (this.hasMultiples()) {
				// create frame for multiple
				var frame = this.document.createElementNS(SVGNS,"svg");
				// JMD1072
				// frame.setAttribute("preserveAspectRatio","none");
				var fh = 100 / rowCount;
				var fw = 100 / colCount;
				
				frame.setAttribute("x",c * fw * scaleX);
				frame.setAttribute("y",r * fh * scaleY);
				frame.setAttribute("width",fw * scaleX);
				frame.setAttribute("height",fh * scaleY);
				oldGroup.appendChild(frame);
				this.svgGroup = frame;

				// reset scaling for multiple
				this._scaleX = scaleX / colCount;
				this._scaleY = scaleY / rowCount;
			}

			// create title (and compute title height)
			var titleH = this.renderTitle();

			// create legend (and compute right margin)
			this.renderLegend();

			// calculate ranges & other values needed for plotting (such as margins)
			this.calculateRangeValues();
			
			// DTB197 - Check to see if the y-axis is only on one side, or if two axes are being used. 
			// If one, remove labels if they consume more than 50% of the space.
			// If two, remove labels at if the plot is given less than 33% of the space.
			if ( ((this._yLabelOnTheLeft&&this._yLabelOnTheRight)&&(this._plotWidth < 33)) ||
				((this._yLabelOnTheLeft)&&(this._plotLeftOut > 50)) ||
				((this._yLabelOnTheRight)&&(this._plotRight < 50)) ) {
				this.labelsVisible = false;
				this.calculateRangeValues();
			}

			// create grid (plot area)
			this.renderPlotArea();

			// final placement of title & legend
			this.adjustChartTitle();

			// plot series data (via subclass)
			this.renderSeriesGroup();

 			// test for user callback
			if ('' != this.onrenderData) {
				// pass old value along
				this._oldXMax = oldXMax;
				var group = this.findSVGElement('seriesGroup'+this.currMultiple);
				zenInvokeCallbackMethod(this.onrenderData,this,'onrenderData','chart',this,'group',group);
			}
			if (this.hasMultiples()) {
				this.currMultiple++;
				if (this.currMultiple>= multiples) break;
			}
		}
		if (this.hasMultiples() && this.currMultiple>= multiples) {
			break;
		}
	}

	// restore group
	this.svgGroup = oldGroup;
	this.currMultiple = '';
	this._scaleX = scaleX;
	this._scaleY = scaleY;

	// control bar (zoom buttons)
	if (this.hasAxes() && this.hasZoom && !this.isTimeBased() && !this.chartPivot && (this.appearance=='2D')) {
		this.renderControlBar();
	}

	// if there is an external chart legend connected to this chart
	// make sure it is refreshed
	var controller = this.getController();
	if (controller && controller.sendEventToViews) {
		controller.sendEventToViews('chartUpdate');
	}

	var done = false;									  // JSL4483
	var attrs = this.parseStyleSVG(this.backgroundStyle); // JSL4483
	//if (zenGet(attrs['opacity']) == '') {                 // JSL4483
	//	attrs['opacity'] = 1.0;                           // JSL4483
	//	done = true;
	//}                                                     // JSL4483
	this.setSeeThrough(attrs['opacity']);                 // JSL4483

	//var attrs = this.parseStyleSVG(this.plotAreaStyle);   // JSL4483
	//if (zenGet(attrs['opacity'] && !done) == '') {        // JSL4483
	//	attrs['opacity'] = 1.0;                           // JSL4483
	//}                                                     // JSL4483
	//this.setSeeThrough(attrs['opacity']);                 // JSL4483, JSL4531 - only call once
}

/// Set the x Axis definition for this chart.
/// Return the old axis if present.
ClientMethod setXAxis(axis) [ Language = javascript ]
{
	var old = this.xAxis;
	this.xAxis = axis;
	if (null!=axis) {
		axis.parent = this;
	}
	if (null!=old) {
		old.parent = null;
	}
	return old;
}

/// Set the current y Axis definition used for this chart.
/// <var>axisNo</var> is the index of the y-axis, 0-based.
ClientMethod setCurrYAxis(axisNo) [ Language = javascript ]
{
	this.setProperty('currYAxis',axisNo);
}

/// Get the current y Axis definition used for this chart.
/// <var>which</var> is "left" or "right".
ClientMethod getCurrYAxis(which) [ Language = javascript ]
{
	var axisNo = 0;

	// n.b. labelPosition can be ''
	which = ('undefined'==typeof which) ? 'left' : which;
	switch(which) {
	case 'right':
		if (this.yAxisList[this.currYAxis] && this.yAxisList[this.currYAxis].labelPosition!='right') {
			// find first right axis
			for (var n = 0; n < this.yAxisList.length; n++) {
				if (this.yAxisList[n] && this.yAxisList[n].labelPosition=='right') {
					axisNo = n;
					break;
				}
			}
		}
		else {
			axisNo = this.currYAxis;
		}
		break;
	case 'left':
	default:
		// JMD1208: for multiples, select y axis by multiple
		var mAxisNo = null;
		if (this.hasMultiples()) {
			var t = this.seriesYAxes.toString().split(',');
			mAxisNo = t[this.currMultiple];
		}
		if (mAxisNo!==null) {
			axisNo = mAxisNo;
		}
		else {
			if (this.yAxisList[this.currYAxis] && this.yAxisList[this.currYAxis].labelPosition=='right') {
				// find first left axis
				for (var n = 0; n < this.yAxisList.length; n++) {
					if (this.yAxisList[n] && this.yAxisList[n].labelPosition=='left') {
						axisNo = n;
						break;
					}
				}
			}
			else {
				axisNo = this.currYAxis;
			}
		}
		break;
	}
	return axisNo;
}

/// Set the y Axis definition for this chart.
/// Return the old axis if present.
ClientMethod setYAxis(axis) [ Language = javascript ]
{
	var old = this.yAxisList[this.currYAxis];
	this.yAxisList[this.currYAxis] = axis;
	if (null!=axis) {
		axis.parent = this;
	}
	if (null!=old) {
		old.parent = null;
	}
	return old;
}

/// Return the x Axis definition for this chart.
ClientMethod getXAxis() [ Language = javascript ]
{
	return this.xAxis;
}

/// Return the y Axis definition for this chart
/// (or null if not found).
ClientMethod getYAxis(index) [ Language = javascript ]
{
	if (this.yAxis) {
		// legacy behavior
		return this.yAxis;
	}
	index = 'undefined' == typeof index ? this.currYAxis : index;
	return this.yAxisList[index];
}

/// Return the number of y Axis definitions for this chart.
ClientMethod getYAxisCount() [ Language = javascript ]
{
	if (this.yAxis) {
		return 1;
	}
	return this.yAxisList&&this.yAxisList.length>0 ? this.yAxisList.length : 1;
}

/// Return the type of x axis (category or value) used by
/// this chart.
ClientMethod getXAxisType() [ Language = javascript ]
{
	return 'category';
}

/// Return the type of y axis (category or value) used by
/// this chart.
ClientMethod getYAxisType() [ Language = javascript ]
{
	return 'value';
}

/// Return the x axis title.
ClientMethod getXAxisTitle() [ Language = javascript ]
{
	var title = '';
	if (this.xAxis && ''!=this.xAxis.title) {
		title = this.xAxis.title;
	}
	else {
		// JMD1130: no default axis label for time chart
		if (!this.isTimeBased()) {
			var controller = this.getController();
			if (!this.chartPivot) {
				if (controller && controller.getDimName) {
					title = controller.getDimName(0);
				}
			}
			else {
				if (controller && controller.getValueName) {
					title = controller.getValueName();
				}
			}
		}
	}
	return title;
}

/// Return the y axis title.
ClientMethod getYAxisTitle(which) [ Language = javascript ]
{
	var title = '';
	var yAxis = this.getYAxis(this.getCurrYAxis(which));
	if (yAxis && ''!=yAxis.title) {
		title = yAxis.title;
	}
	else {
		var controller = this.getController();
		if (!this.chartPivot) {
			// JMD1208: for multiples, use series name
			if (this.hasMultiples()) {
				var snames = this.getSeriesNames();
				title = snames[this.currMultiple] ? snames[this.currMultiple] : '';
			}
			else if (controller && controller.getValueName) {
				var yaCount = this.getYAxisCount();
				title = controller.getValueName();
				if (yaCount>1) {
					var scount = this.getSeriesCount();
					// get title from current axis
					var legends = this.getLegendLabels();
					for (var s = 0; s < scount; s++) {
						if (this.getYAxisIndexForSeries(s)==this.getCurrYAxis(which)) {
							// find *last* series for the current y axis
							title = legends[s];
						}
					}
				}
			}
		}
		else {
			if (controller && controller.getDimName) {
				title = controller.getDimName(0);
			}
		}
	}
	return title;
}

/// Indicates whether this chart should be drawn with a 3-D
/// appearance.
ClientMethod is3D() [ Language = javascript ]
{
	return ('3D' == this.appearance);
}

/// Internal method: Set up range and other information.
ClientMethod calculateRangeValues() [ Internal, Language = javascript ]
{
	var is3D = this.is3D();
	var hasAxes = this.hasAxes();
	
	if (hasAxes) {
		this.initializeAxisProperties();
		this.calculateAxisConstraints();
	}

	// get corner points ("Out" is foreground for 3D)
	var adj = (is3D ? 5:0);

	// look at xlabels first!
	if (this._xLabelOnTheBottom) {
		var xAHtop = (10/this._scaleY);
		var xAHbot = (hasAxes) ? this.calculateXAxisHeight() : (10/this._scaleY);
	}
	else {
		var xAHtop = (hasAxes) ? this.calculateXAxisHeight() : (10/this._scaleY);
		var xAHbot = (10/this._scaleY);
	}

	// do we need to compute the size of the left margin?
	var computeLeft = false;

	if (this.marginLeft==='') {
		if (hasAxes && this._yLabelOnTheLeft) {
			// compute size of left margin
			this._marginLeft = this.calculateYAxisWidth('left');
		}
		else {
			// JMD1100 10pixels
			this._marginLeft = 10/this._scaleX;
		}

		// JMD1125- look at size of last x label
		if (this._firstXLabelWidth && this._marginLeft<this._firstXLabelWidth/2) {
			this._marginLeft = this._firstXLabelWidth/2;
		}
	}
	else {
		this._marginLeft = this.xToLogical(this.marginLeft);
	}

	// JMD1100 - test for size of right hand axis
	if (this.marginRight==='') {
		if (hasAxes && this._yLabelOnTheRight) {
			// compute size of right margin
			this._marginRight = this.calculateYAxisWidth('right') + (this._legendWidth?this._legendWidth:0);
		}
		else {
			// JMD1100
			this._marginRight = (this._legendWidth?this._legendWidth:(10/this._scaleX));
		}
		// JMD1125- look at size of last x label
		if (this._lastXLabelWidth && this._marginRight<(this._lastXLabelWidth*1.1)/2) {
			this._marginRight = (this._lastXLabelWidth*1.1)/2;
		}
	}
	else {
		this._marginRight = this.xToLogical(this.marginRight);
	}

	if ((this._marginLeft + this._marginRight) > 100) {
		this._marginRight = 100 - this._marginLeft;		// DTB197 - Keep marginLeft large, since it is the trigger to remove axes due to lack of space!
	}

	this._plotLeftOut = this._marginLeft;
	this._plotLeft = this._plotLeftOut + adj;
	this._rplotRight = 100 - this._marginRight;
	this._rplotRightOut = this._rplotRight - adj;
	this._rplotWidth = (100 - (this._marginLeft + this._marginRight + adj));

	if (hasAxes) {
		// width of virtual plot area (for scrolling) 
		var hzScale = 1.0;
		var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
		if (this.hzZoomStep > 0) {
			// convert zoom step to scale factor
			var itemsPerPage = items % 2 ? items+1 : items;
			var n = parseInt(this.hzZoomStep);
			this.hzZoomStep = 0;
			while (n > 0 && itemsPerPage >= 2) {
				this.hzZoomStep++;
				itemsPerPage = Math.floor(itemsPerPage/2);
				n--;
			}
			hzScale = items / itemsPerPage;
		}
		this._plotWidth = this._rplotWidth * hzScale;
		this._plotRight = this._plotLeft + this._plotWidth;

		// number of zoom steps
		this._hzMaxStep = Math.floor(Math.log(items)/Math.log(2));

		// scrolling range
		this._maxScrollLeft = this._plotWidth - this._rplotWidth;
		this.scrollLeft = (this.scrollLeft < 0) ? 0 : this.scrollLeft;
		this.scrollLeft = (this.scrollLeft > this._maxScrollLeft) ? this._maxScrollLeft : this.scrollLeft;
	}
	else {
		this._plotWidth = this._rplotWidth;
	}

	// set top margin
	if (''!==this.marginTop) {
		this._marginTop = this.yToLogical(this.marginTop);
	}
	else {
		this._marginTop = this._titleHeight + xAHtop;
		if (this._marginTop < 3) {
			// room for top of yAxis label!
			this._marginTop = 3;
		}
	}

	if (this.marginBottom==='') {
		this._marginBottom = xAHbot + (this._controlBarH/this._scaleY)	;
	}
	else {
		this._marginBottom = this.yToLogical(this.marginBottom) + (this._controlBarH/this._scaleY);
	}

	if ((this._marginBottom + this._marginTop) > 100) {
		this._marginBottom = 100 - this._marginTop;
	}

	// apply defaults for missing values
	this._plotTop = this._marginTop;
	this._plotTopOut = this._plotTop + adj;
	this._plotBottomOut = 100 - this._marginBottom;
	this._plotBottom = this._plotBottomOut - adj;
	this._plotHeight = (100 - (this._marginTop + this._marginBottom + adj));
}

ClientMethod initializeAxisProperties() [ Language = javascript ]
{
	// units & grids
	this._yMajorUnits = [];
	this._yMinorUnits = [];
	this._yLabelUnits = [];
	this._yLabelAngle = [];
	this._yLabelStyle = [];

	// JMD1100 Determine if there are left or right labels
	this._yLabelOnTheRight = false;
	this._yLabelOnTheLeft = false;
	this._xLabelOnTheTop = false;
	this._xLabelOnTheBottom = false;

	var yaCount = this.getYAxisCount();
	for (var yAxisNo = 0; yAxisNo < yaCount; yAxisNo++) {
		var yAxis = this.getYAxis(yAxisNo);
		if (yAxis && yAxis.labelPosition == 'right') {
			this._yLabelOnTheRight = true;
		}
		else {
			this._yLabelOnTheLeft = true;
		}
		this._yMajorUnits[yAxisNo] = yAxis ? yAxis.majorUnits : '';
		this._yMajorUnits[yAxisNo] = ('' == this._yMajorUnits[yAxisNo]) ? '' : this._yMajorUnits[yAxisNo];
		this._yMinorUnits[yAxisNo] = yAxis ? yAxis.minorUnits : '';
		this._yMinorUnits[yAxisNo] = ('' == this._yMinorUnits[yAxisNo]) ? '' : this._yMinorUnits[yAxisNo];
		this._yLabelUnits[yAxisNo] = yAxis ? yAxis.labelUnits : '';
		this._yLabelUnits[yAxisNo] = ('' == this._yLabelUnits[yAxisNo]) ? this._yMajorUnits[yAxisNo] : this._yLabelUnits[yAxisNo];

		this._yLabelAngle[yAxisNo] = yAxis ? yAxis.labelAngle : 0;
		this._yLabelStyle[yAxisNo] = yAxis ? yAxis.labelStyle : '';
	} // yAxisNo

	// left axis drives grid lines
	var yAxis = this.getYAxis(this.getCurrYAxis('left'));

	this._yMajorGrid = yAxis ? yAxis.majorGridLines : true;
	this._yMinorGrid = yAxis ? yAxis.minorGridLines : false;
	this._yMajorGridStyle = yAxis ? yAxis.majorGridStyle : '';
	this._yMinorGridStyle = yAxis ? yAxis.minorGridStyle : '';

	if (this.xAxis && this.xAxis.labelPosition=='top') {
		this._xLabelOnTheTop = true;
	}
	else {
		this._xLabelOnTheBottom = true;
	}

	this._xMajorUnits = this.xAxis ? this.xAxis.majorUnits : '';
	this._xMajorUnits = ('' == this._xMajorUnits) ? '' : this._xMajorUnits;
	this._xMinorUnits = this.xAxis ? this.xAxis.minorUnits : '';
	this._xMinorUnits = ('' == this._xMinorUnits) ? '' : this._xMinorUnits;
	this._xLabelUnits = this.xAxis ? this.xAxis.labelUnits : '';
	this._xLabelUnits = ('' == this._xLabelUnits) ? this._xMajorUnits : this._xLabelUnits;
	this._xLabelAngle = this.xAxis ? this.xAxis.labelAngle : 0;
	this._xLabelStyle = this.xAxis ? this.xAxis.labelStyle : '';

	this._xMajorGrid = this.xAxis ? this.xAxis.majorGridLines : false;
	this._xMinorGrid = this.xAxis ? this.xAxis.minorGridLines : false;
	this._xMajorGridStyle = this.xAxis ? this.xAxis.majorGridStyle : '';
	this._xMinorGridStyle = this.xAxis ? this.xAxis.minorGridStyle : '';

	// figure out type of axes (category or value)
	this._yGridType = this.getYAxisType();
	this._xGridType = this.getXAxisType();
}

/// If the plot has axes, pre-calculate the internal values that will be used
/// to govern how those axes are rendered
ClientMethod calculateAxisConstraints() [ Language = javascript ]
{
	delete this._xMinValue;
	delete this._xMaxValue;
	delete this._yMinValue;
	delete this._yMaxValue;

	// there can be multiple "scales" for y axis
	// we have to loop over these and compute them
	this._yMaxValue = [];
	this._yMinValue = [];
	this._yBaseValue = [];
	this._yRange = [];
	var range = [];
	var xOnly = false; 

	// JMD1130 - look at axis first!
	// x (if value axis)
	this._xBaseValue = this.xAxis ? this.xAxis.baseValue : '';
	this._xMinValue = this.xAxis ? this.xAxis.minValue : '';
	this._xMaxValue = (this.xAxis ? this.xAxis.maxValue : '');	

	var yaCount = this.getYAxisCount();
	if ('category'==this._yGridType && 'value'==this._xGridType) {
		// get range for xAxis
		range[0] = this.findDataRange(-1);
		xOnly = true;
	}
	else {
		for (var yAxisNo = 0; yAxisNo < yaCount; yAxisNo++) {
			// get data range(s) for chart
			range[yAxisNo] = this.findDataRange(yAxisNo);
		}
	}

	for (var yAxisNo = 0; yAxisNo < yaCount; yAxisNo++) {
		// JMD1271: get min/max from axis
		var yAxis = this.getYAxis(yAxisNo);
		this._yBaseValue[yAxisNo] = yAxis ? yAxis.baseValue : '';
		this._yMinValue[yAxisNo] = yAxis ? yAxis.minValue : '';
		this._yMaxValue[yAxisNo] = yAxis ? yAxis.maxValue : '';

		// units
		if ('value'==this._yGridType && isNaN(parseFloat(this._yMajorUnits[yAxisNo]))) {
			var max,min,scale;
			// figure out units automatically
			if (!this.usePercentForRange()) {
				max = isNaN(parseFloat(this._yMaxValue[yAxisNo])) ? parseFloat(range[yAxisNo].maxValue) : this._yMaxValue[yAxisNo];
				min = isNaN(parseFloat(this._yMinValue[yAxisNo])) ? parseFloat(range[yAxisNo].minValue) : this._yMinValue[yAxisNo];
				max = isNaN(max) ? 0 : max;
				min = isNaN(min) ? 0 : min;
				scale = this.findScaleUnits(max - min);
			} else {
				max = 100;
				min = 0;
				scale = 20;
			}

			this._yMajorUnits[yAxisNo] = scale;
			if (isNaN(parseFloat(this._yLabelUnits[yAxisNo]))) {
				this._yLabelUnits[yAxisNo] = this._yMajorUnits[yAxisNo];
			}

			if (isNaN(parseFloat(this._yMinorUnits[yAxisNo]))) {
				this._yMinorUnits[yAxisNo] = this._yMajorUnits[yAxisNo] / 5;
			}
		}
		else if ('category'==this._yGridType && isNaN(parseFloat(this._yMajorUnits[yAxisNo]))) {
			var scale = 1;
			var size = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			var f = (size%5==0) ? 5 : 2;
			while (size/scale > 10) {
				scale *= f;
			}
			this._yMajorUnits[yAxisNo] = scale;
			if (isNaN(parseFloat(this._yLabelUnits[yAxisNo]))) {
				this._yLabelUnits[yAxisNo] = 1;
			}
		}
	} // yAxisNo

	if ('value'==this._xGridType && isNaN(parseFloat(this._xMajorUnits))) {
		// figure out units automatically
		if ('value'==this._yGridType) {
			// x/y type chart
			var max = isNaN(parseFloat(this._xMaxValue)) ? parseFloat(range[0].maxValue2) : this._xMaxValue;
			var min = isNaN(parseFloat(this._xMinValue)) ? parseFloat(range[0].minValue2) : this._xMinValue;
		}
		else {
			var max = isNaN(parseFloat(this._xMaxValue)) ? parseFloat(range[0].maxValue) : this._xMaxValue;
			var min = isNaN(parseFloat(this._xMinValue)) ? parseFloat(range[0].minValue) : this._xMinValue;
		}
		if (!this.usePercentForRange()) {
			max = isNaN(max) ? 0 : max;
			min = isNaN(min) ? 0 : min;
			var scale = this.findScaleUnits(max - min);
		}
		else {
			max = 100;
			min = 0;
			scale = 20;
		}
		this._xMajorUnits = scale;
		if (isNaN(parseFloat(this._xLabelUnits))) {
			this._xLabelUnits = this._xMajorUnits;
		}

		if (isNaN(parseFloat(this._xMinorUnits))) {
			this._xMinorUnits = this._xMajorUnits / 5;
		}
	}
	else if ('category'==this._xGridType && isNaN(parseFloat(this._xMajorUnits))) {
		this._xMajorUnits = 1;
		this._xLabelUnits = 1;
	}

	// min/max values
	var	useSum = this.useSumForRange();

	if (!xOnly) {
		for (var yAxisNo = 0; yAxisNo < yaCount; yAxisNo++) {
			var yAxis = this.getYAxis(yAxisNo);
			this._yBaseValue[yAxisNo] = yAxis ? yAxis.baseValue : '';
			this._yMinValue[yAxisNo] = yAxis ? yAxis.minValue : '';
			this._yMaxValue[yAxisNo] = yAxis ? yAxis.maxValue : '';
			if ((useSum||(parseFloat(range[yAxisNo].minValue)<0)) && this._yBaseValue[yAxisNo]==='') {
				// JMD1125: for stacked chart, default base to 0
				// JMD1130: or if minvalue is negative
				this._yBaseValue[yAxisNo] = 0;
			}

			if (isNaN(parseFloat(this._yMinValue[yAxisNo]))) {
				// auto
				// round down to next major units (use base if present)
				var val = (false&&this.useSumForRange()) ? (isNaN(parseFloat(this._yBaseValue[yAxisNo])) ? range[yAxisNo].minValue : this._yBaseValue[yAxisNo]) : range[yAxisNo].minValue;
				if (0!=this._yMajorUnits[yAxisNo]) {
					val = Math.floor(val / this._yMajorUnits[yAxisNo]) * this._yMajorUnits[yAxisNo];
				}
				this._yMinValue[yAxisNo] = val;
			}
			if (isNaN(parseFloat(this._yMaxValue[yAxisNo]))) {
				// auto
				// round up to next major units
				var val = range[yAxisNo].maxValue;
				if (0!=this._yMajorUnits[yAxisNo]) {
					val = Math.ceil((val*1.01) / this._yMajorUnits[yAxisNo]) * this._yMajorUnits[yAxisNo];
				}
				this._yMaxValue[yAxisNo] = val;
			}

			this._yRange[yAxisNo] = (this._yMaxValue[yAxisNo] - this._yMinValue[yAxisNo]);
		} // yAxisNo
	}

	if ((useSum||(parseFloat(range[0].minValue)<0)) && this._xBaseValue==='') {
		// JMD1125: for stacked chart, default base to 0
		// JMD1130: or if minvalue is negative
		this._xBaseValue = 0;
	}

	if (this.isTimeBased()) {
		// JMD1130 find start/end times for x axis
		var items = this.getSeriesSize();
		for (var n = 0; n < items; n++) {
			var time = this.getXLabelText(n,1,true);
			var d = zenStringToDate(time);
			if (d) {
				// JMD1130(3) test for hours/minutes
				var hms = time.toString().split(' ')[1];
				if (hms) {
					var t = hms.split(':');
					if (t[0]) {	d.setHours(parseInt(t[0],10));}
					if (t[1]) {	d.setMinutes(parseInt(t[1],10));}
					if (t[2]) {	d.setSeconds(parseInt(t[2]),10);}
				}
				var val = d.getTime()/1000;
				this._xMinValue = (isNaN(parseFloat(this._xMinValue))) ? val : (val < this._xMinValue) ? val : this._xMinValue;
				this._xMaxValue = (isNaN(parseFloat(this._xMaxValue))) ? val : (val > this._xMaxValue) ? val : this._xMaxValue;
			}
		}
		this._xRange = (this._xMaxValue - this._xMinValue);
	}
	else {
		if (isNaN(parseFloat(this._xMinValue))) {
			// auto
			// round down to next major units (use base if present)
			if ('value'==this._yGridType) {
				var val = range[0].minValue2;
			}
			else {
				var val = (false&&this.useSumForRange()) ? (isNaN(parseFloat(this._xBaseValue)) ? range[0].minValue : this._xBaseValue) : range[0].minValue;
			}
			if (0!=this._xMajorUnits) {
				val = Math.floor(val / this._xMajorUnits) * this._xMajorUnits
			}
			this._xMinValue = val;
		}
		if (isNaN(parseFloat(this._xMaxValue))) {
			// auto
			// round up to next major units
			var val = ('value'==this._yGridType) ? range[0].maxValue2 : range[0].maxValue;
			if (0!=this._xMajorUnits) {
				val = Math.ceil(val / this._xMajorUnits) * this._xMajorUnits
			}
			this._xMaxValue = val;
		}
		if (this.chartPivot && this.valueLabelsVisible && this.usePercentForRange()) { // if we have horizontal value labels, and we are a percentage bar-chart, allow some room at right to place them
			this._xMaxValue *= 1.1;
		}
		this._xRange = (this._xMaxValue - this._xMinValue);
	}
}

/// Internal method: Find best scale units to use for given value.
ClientMethod findScaleUnits(val) [ Internal, Language = javascript ]
{
	var scale = 0;

	if (val > 0) {
		var log = Math.LOG10E * Math.log(val);
		var f = Math.floor(log);
		if ((log - f) > .65) {
			scale = Math.pow(10,f+1) / 5;
		}
		else if ((log - f) > .3) {
			scale = (Math.pow(10,f) * 5) / 10;
		}
		else {
			scale = (Math.pow(10,f) * 2) / 4;
		}
	}

	return scale;
}

/// Draw the plot area of the chart.
ClientMethod renderPlotArea() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;

	var rect,edgeLeft,edgeBottom,axisLines;
	var plotAreaGroup = this.findSVGElement('plotAreaGroup'+this.currMultiple);
	var is3D = this.is3D();

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	if (null == plotAreaGroup) {
		// create
		plotAreaGroup = this.document.createElementNS(SVGNS,"g");
		plotAreaGroup.setAttribute("id",this.makeId('plotAreaGroup'+this.currMultiple));
		this.svgGroup.appendChild(plotAreaGroup);

		rect = this.document.createElementNS(SVGNS,"rect");
		rect.setAttribute("id",this.makeId('plotArea'+this.currMultiple));
		plotAreaGroup.appendChild(rect);

		// default click handler for plotArea: turn off selected item
		var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,null,null);');
		rect.addEventListener('click',f,false);

		// edges (3D)
		edgeLeft = this.document.createElementNS(SVGNS,"path");
		edgeLeft.setAttribute("id",this.makeId('edgeLeft'+this.currMultiple));
		plotAreaGroup.appendChild(edgeLeft);

		edgeBottom = this.document.createElementNS(SVGNS,"path");
		edgeBottom.setAttribute("id",this.makeId('edgeBottom'+this.currMultiple));
		plotAreaGroup.appendChild(edgeBottom);
	}
	else {
		rect = this.findSVGElement('plotArea'+this.currMultiple);
		edgeLeft = this.findSVGElement('edgeLeft'+this.currMultiple);
		edgeBottom = this.findSVGElement('edgeBottom'+this.currMultiple);
	}

	zenASSERT(rect,'rect is not defined',arguments);

	rect.setAttribute("class","chart-plotArea");
	rect.setAttribute("style",this.plotAreaStyle);
	rect.setAttribute("x",this._plotLeft*scaleX);
	rect.setAttribute("y",this._plotTop*scaleY);
	rect.setAttribute("width",this._rplotWidth*scaleX);
	rect.setAttribute("height",this._plotHeight*scaleY);
	
	// edges (for 3D)
	if (!is3D) {
		edgeLeft.setAttribute("visibility","hidden");
		edgeBottom.setAttribute("visibility","hidden");
	}
	else {
		edgeLeft.setAttribute("class","chart-plotEdge");
		edgeLeft.setAttribute("style",'opacity: 0.5;' + this.plotEdgeStyle);
		edgeLeft.setAttribute("d",'M '+(this._plotLeftOut*scaleX)+' '+(this._plotTopOut*scaleY)+' L '+(this._plotLeft*scaleX)+' '+(this._plotTop*scaleY)+' '+(this._plotLeft*scaleX)+' '+(this._plotBottom*scaleY)+' '+(this._plotLeftOut*scaleX)+' '+(this._plotBottomOut*scaleY)+' z');
		edgeLeft.setAttribute("visibility","visible");

		edgeBottom.setAttribute("class","chart-plotEdge");
		edgeBottom.setAttribute("style",this.plotEdgeStyle);
		edgeBottom.setAttribute("d",'M '+(this._plotLeftOut*scaleX)+' '+(this._plotBottomOut*scaleY)+' L '+(this._plotLeft*scaleX)+' '+(this._plotBottom*scaleY)+' '+(this._rplotRight*scaleX)+' '+(this._plotBottom*scaleY)+' '+(this._rplotRightOut*scaleX)+' '+(this._plotBottomOut*scaleY)+' z');
		edgeBottom.setAttribute("visibility","visible");
	}

	var clipGroup = this.findSVGElement('clipGroup'+this.currMultiple);
	var clipLabelGroup = this.findSVGElement('clipLabelGroup'+this.currMultiple);
	var virtualGroup = this.findSVGElement('virtualGroup'+this.currMultiple);
	var virtualLabelGroup = this.findSVGElement('virtualLabelGroup'+this.currMultiple);
	if (clipGroup == null) {
		// svg group to clip items in virtual plot area
		// JMD1100: do not clip if 3D
		if ('3D' == this.appearance) {
			clipGroup = this.document.createElementNS(SVGNS,"g");
		}
		else {
			clipGroup = this.document.createElementNS(SVGNS,"svg");
		}
		clipGroup.setAttribute("id",this.makeId('clipGroup'+this.currMultiple));
		plotAreaGroup.appendChild(clipGroup);

		// group to hold items in virtual plot area
		virtualGroup = this.document.createElementNS(SVGNS,"g");
		virtualGroup.setAttribute("id",this.makeId('virtualGroup'+this.currMultiple));
		clipGroup.appendChild(virtualGroup);

		// clip group for x labels
		clipLabelGroup = this.document.createElementNS(SVGNS,"svg");
		clipLabelGroup.setAttribute("id",this.makeId('clipLabelGroup'+this.currMultiple));
		plotAreaGroup.appendChild(clipLabelGroup);

		// group to hold x axis labels
		virtualLabelGroup = this.document.createElementNS(SVGNS,"g");
		virtualLabelGroup.setAttribute("id",this.makeId('virtualLabelGroup'+this.currMultiple));
		clipLabelGroup.appendChild(virtualLabelGroup);
	}
	
	// provide extra space for x labels
	this._labelPadL = this.plotToEdge ? 5 : 4;
	this._labelPadR = this._labelPadL;
	if (this.isTimeBased()) {
		this._labelPadL = 0;	// JMD1130 pt2
		this._labelPadR = 0;
	}
	
	virtualGroup.setAttribute("transform",'translate('+ -(parseFloat(this.scrollLeft)*scaleX)+',0)');
	virtualLabelGroup.setAttribute("transform",'translate('+ -((parseFloat(this.scrollLeft)-this._labelPadL)*scaleX)+',0)');

	if ('3D' == this.appearance) {
		clipGroup.setAttribute("transform",'translate('+ (this._plotLeft*scaleX)+',0)');
	}
	else {
		clipGroup.setAttribute("x",this._plotLeft*scaleX);
		clipGroup.setAttribute("y",0);
		clipGroup.setAttribute("height",100*scaleY);
		clipGroup.setAttribute("width",this._rplotWidth*scaleX);
	}

	clipLabelGroup.setAttribute("x",(this._plotLeft - this._labelPadL)*scaleX);
	clipLabelGroup.setAttribute("y",0*scaleY);
	clipLabelGroup.setAttribute("height",100*scaleY);
	clipLabelGroup.setAttribute("width",(this._rplotWidth + (this._labelPadL+this._labelPadR))*scaleX);

	// if we have axes, draw them
	// (some charts, like pie charts, do not have axes)
	if (this.hasAxes()) {
		// draw upper/lower bands
		this.renderBands();

		// test for user callback
		if ('' != this.onrenderPlotArea) {
			zenInvokeCallbackMethod(this.onrenderPlotArea,this,'onrenderPlotArea','chart',this);
		}

		// draw axes and grid lines
		this.renderAxes();

		// labels
		// JMD1100 test for right/left labels
		if (this._yLabelOnTheLeft) {
			this.renderYLabels('left');
		}
		if (this._yLabelOnTheRight) {
			this.renderYLabels('right');
		}
		this.renderXLabels();
	}

	// axis lines
	var	axisLines = this.findSVGElement('axisLines'+this.currMultiple);
	if (null == axisLines) {
		axisLines = this.document.createElementNS(SVGNS,"path");
		axisLines.setAttribute("id",this.makeId('axisLines'+this.currMultiple));
		plotAreaGroup.appendChild(axisLines);
	}

	if (this.hasAxes()) {
		// axis lines
		axisLines.setAttribute("visibility","visible");
		axisLines.setAttribute("class","chart-axisLines");
		axisLines.setAttribute("style",this.axisLineStyle);
		axisLines.setAttribute("d",'M '+(this._plotLeftOut*scaleX)+' '+(this._plotTopOut*scaleY)+' L '+(this._plotLeftOut*scaleX)+' '+(this._plotBottomOut*scaleY)+' Z M '+(this._plotLeftOut*scaleX)+' '+(this._plotBottomOut*scaleY)+' L '+(this._rplotRightOut*scaleX)+' '+(this._plotBottomOut*scaleY));
	}
	else {
		axisLines.setAttribute("visibility","hidden");
	}

	// display warning message JSL4478
	//+ JSL4478
	if (this.warnIfNoData) { // JSL4478
		var arr = this._dataSeries[0];
		if (arr.length == 0 || ((this.seriesSize == 1)&&(arr.length==1)&&((arr[0]=="")||((typeof(arr[0])=="undefined"))))) {
			this.showNoDataMsg(this.msgIfNoData,plotAreaGroup,clipGroup);		// DTB150 - use new clientmethod
		}
		else {
			this.removeNoDataMsg(plotAreaGroup);								// DTB150 use new clientmethod
		}//-JSL4478
	}
}

/// Display the NoDataMsg. If the plotAreaGroup and clipGroup objects are known in the calling context, 
/// they may be passed in, otherwise the method will attempt to find them.
ClientMethod showNoDataMsg(msg, plotAreaGroup, clipGroup) [ Language = javascript ]
{
	// Method added by DTB150
	var debug= true;
	
	if (!plotAreaGroup) {
		var plotAreaGroup = this.findSVGElement('plotAreaGroup'+this.currMultiple);
	}
	
	var clipGroup = this.findSVGElement('clipGroup'+this.currMultiple);
	if (!clipGroup) {
		var clipGroup = this.document.createElementNS(SVGNS,"svg");
		
	}
	
	var text = this.findSVGElement('textIfNoData'+this.currMultiple);
	if (plotAreaGroup&&clipGroup) {
		if (!text) {
			text = this.document.createElementNS(SVGNS,'text');
			text.setAttribute("id",this.makeId('textIfNoData'+this.currMultiple));
			var textNode = this.document.createTextNode(this.msgIfNoData);
			text.appendChild(textNode);
			if (debug) {
				var debugrect=this.document.createElementNS(SVGNS,'rect')
				debugrect.setAttribute("id",this.makeId('rectIfNoData'+this.currMultiple));
				plotAreaGroup.appendChild(debugrect);			
			}
		} else {
			var debugrect = this.findSVGElement('rectIfNoData'+this.currMultiple);
			var textNode = text.childNodes[0];
			textNode.textContent = msg;			
		}
		plotAreaGroup.appendChild(text);			

		//text.setAttribute("class","chart-warnifnodata");
		//text.setAttribute("style","fill:white;font-size:12px");
		text.setAttribute("stroke",this.noDataStroke);
		text.setAttribute("fill","none");
		//text.setAttribute("font-size:12px");
		//text.setAttribute("text-anchor","center");
		var bbox = zenGetBBox(text);
		var xtext = parseFloat(clipGroup.getAttribute("x"));
		var ytext = parseFloat(clipGroup.getAttribute("y"));
		var width = parseFloat(clipGroup.getAttribute("width"))
		var height = parseFloat(clipGroup.getAttribute("height"));
		//alert("xtext="+xtext+" width="+width+" bbox.width="+bbox.width);
		text.setAttribute("x",xtext+(width/2)-(bbox.width/2));
		text.setAttribute("y",ytext+(height/2));
		if (debug) {
			debugrect.setAttribute("fill",this.noDataFill);
			debugrect.setAttribute("x",xtext+width/2-(bbox.width/2)-2);
			debugrect.setAttribute("y",ytext+(height/2) - bbox.height+2);
			debugrect.setAttribute("width",bbox.width+2);
			debugrect.setAttribute("height",bbox.height+2);
			debugrect.setAttribute("opacity", this.noDataOpacity);
		}
	}
}

/// Remove the NoDataMsg from the plot area. 
ClientMethod removeNoDataMsg(plotAreaGroup) [ Language = javascript ]
{
	// Method added by DTB150
	if (!plotAreaGroup) {
		var plotAreaGroup = this.findSVGElement('plotAreaGroup'+this.currMultiple);
	}
	var text = this.findSVGElement('textIfNoData'+this.currMultiple);
	if ((plotAreaGroup)&&(text)) {
		var debugrect = this.findSVGElement('rectIfNoData'+this.currMultiple);
		plotAreaGroup.removeChild(text);
		plotAreaGroup.removeChild(debugrect);
	}
}

/// Indicates that this chart has axes and associated grids
/// A subclass may override this to turn off axis display.
ClientMethod hasAxes() [ Language = javascript ]
{
	return true;
}

/// Test if a time-based x axis should be used.
/// This is overridden in subclasses.
ClientMethod isTimeBased() [ Language = javascript ]
{
	return false;
}

/// Draw the x and y axes and grid lines.
ClientMethod renderAxes() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	var is3D = this.is3D();

	var plotAreaGroup = this.findSVGElement('plotAreaGroup'+this.currMultiple);
	var virtualGroup = this.findSVGElement('virtualGroup'+this.currMultiple);
	zenASSERT(plotAreaGroup,'Unable to find plotAreaGroup',arguments);

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	// y grid stripes
	var ystripes = null;
	if (this.stripesVisible) {
		ystripes = this.findSVGElement('yGridStripes'+this.currMultiple);
		if (null == ystripes) {
			ystripes = this.document.createElementNS(SVGNS,"path");
			ystripes.setAttribute("class","chart-gridStripes");
			ystripes.setAttribute("id",this.makeId('yGridStripes'+this.currMultiple));
			virtualGroup.appendChild(ystripes);

			// click handler: turn off selected item
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,null,null);');
			ystripes.addEventListener('click',f,false);
		}
		ystripes.setAttribute("style",this.stripeStyle);
	}

	// x grid stripes
	var xstripes = null;
	if (this.stripesVisible) {
		xstripes = this.findSVGElement('xGridStripes'+this.currMultiple);
		if (null == xstripes) {
			xstripes = this.document.createElementNS(SVGNS,"path");
			xstripes.setAttribute("class","chart-gridStripes");
			xstripes.setAttribute("id",this.makeId('xGridStripes'+this.currMultiple));
			virtualGroup.appendChild(xstripes);

			// click handler: turn off selected item
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,null,null);');
			xstripes.addEventListener('click',f,false);
		}
		xstripes.setAttribute("style",this.stripeStyle);
	}

	// y major grid path
	var ygrid = this.findSVGElement('yGridLine'+this.currMultiple);
	if (null == ygrid) {
		ygrid = this.document.createElementNS(SVGNS,"path");
		ygrid.setAttribute("class","chart-majorGridLine");
		ygrid.setAttribute("id",this.makeId('yGridLine'+this.currMultiple));
		virtualGroup.appendChild(ygrid);
	}
	ygrid.setAttribute("style",this.gridStyle + this._yMajorGridStyle + 'fill:none;');

	// y minor grid path
	var ygridMinor = this.findSVGElement('yGridLineMinor'+this.currMultiple);
	if (null == ygridMinor) {
		ygridMinor = this.document.createElementNS(SVGNS,"path");
		ygridMinor.setAttribute("class","chart-minorGridLine");
		ygridMinor.setAttribute("id",this.makeId('yGridLineMinor'+this.currMultiple));
		virtualGroup.appendChild(ygridMinor);
	}
	ygridMinor.setAttribute("style",this.gridStyle + this._yMinorGridStyle + 'fill:none;');

	// x major grid path
	var xgrid = this.findSVGElement('xGridLine'+this.currMultiple);
	if (null == xgrid) {
		xgrid = this.document.createElementNS(SVGNS,"path");
		xgrid.setAttribute("class","chart-majorGridLine");
		xgrid.setAttribute("id",this.makeId('xGridLine'+this.currMultiple));
		virtualGroup.appendChild(xgrid);
	}
	xgrid.setAttribute("style",this.gridStyle + this._xMajorGridStyle + 'fill:none;');

	// x minor grid path
	var xgridMinor = this.findSVGElement('xGridLineMinor'+this.currMultiple);
	if (null == xgridMinor) {
		xgridMinor = this.document.createElementNS(SVGNS,"path");
		xgridMinor.setAttribute("class","chart-minorGridLine");
		xgridMinor.setAttribute("id",this.makeId('xGridLineMinor'+this.currMultiple));
		virtualGroup.appendChild(xgridMinor);
	}
	xgridMinor.setAttribute("style",this.gridStyle + this._xMinorGridStyle + 'fill:none;');

	// y axis
	// left axis drives grid
	var yAxisNo = this.getCurrYAxis('left');

	// create gridlines
	// find set of values that correspond with "unit" size
	// and fit within range
	if (this._yGridType == 'value') {
		// yMajor
		var start, end;
		var d = '';
		var sd = '';
		if (this._yMajorGrid && this._yMajorUnits[yAxisNo] > 0) {
			var start = Math.ceil(Math.abs(this._yMinValue[yAxisNo]/this._yMajorUnits[yAxisNo]))*this._yMajorUnits[yAxisNo]*(this._yMinValue[yAxisNo]>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._yMaxValue[yAxisNo]/this._yMajorUnits[yAxisNo]))*this._yMajorUnits[yAxisNo]*(this._yMaxValue[yAxisNo]>=0 ? 1 : -1);
			var limit = 0;
			var lastY = '';
			for (var v = start; v <= end && limit < 200; v += this._yMajorUnits[yAxisNo], limit++) {
				var y = this.getPlotY(v,yAxisNo);
				if (y < this._plotBottomOut) {
					if (is3D) {
						d += ' M ' + (-5*scaleX) + ' ' + ((y+5)*scaleY) + ' L ';
					}
					else {
						d += ' M ';
					}
					//d += 0 + ' ' + y*scaleY + ' L ' + ((this._plotRight-(is3D?6:0))*scaleX) + ' ' + y*scaleY;
					d += 0 + ' ' + y*scaleY + ' L ' + ((this._plotWidth)*scaleX) + ' ' + y*scaleY;
					if (lastY != '') {
						sd += ' M ';
						//sd += 0 + ' ' + lastY*scaleY + ' L ' + ((this._plotRight-(is3D?6:0))*scaleX) + ' ' + lastY*scaleY;
						//sd += ' ' + ((this._plotRight-(is3D?6:0))*scaleX) + ' ' + y*scaleY + ' L ' + 0 + ' ' + y*scaleY + ' z';
						sd += 0 + ' ' + lastY*scaleY + ' L ' + ((this._plotWidth)*scaleX) + ' ' + lastY*scaleY;
						sd += ' ' + ((this._plotWidth)*scaleX) + ' ' + y*scaleY + ' L ' + 0 + ' ' + y*scaleY + ' z';
						lastY = '';
					}
					else {
						lastY = y;
					}
				}
			}
		}
		if ('' != d) {
			ygrid.setAttribute("d",d);
			ygrid.setAttribute("visibility","visible");
		}
		else {
			ygrid.setAttribute("visibility","hidden");
		}
		ygrid.setAttribute("fill","none");

		if (ystripes && '' != sd) {
			ystripes.setAttribute("d",sd);
			ystripes.setAttribute("visibility","visible");
		}
	
		// yMinor
		var start, end;
		var d = '';
		if (this._yMinorGrid && this._yMinorUnits[yAxisNo] > 0) {
			var start = Math.ceil(Math.abs(this._yMinValue[yAxisNo]/this._yMinorUnits[yAxisNo]))*this._yMinorUnits[yAxisNo]*(this._yMinValue[yAxisNo]>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._yMaxValue[yAxisNo]/this._yMinorUnits[yAxisNo]))*this._yMinorUnits[yAxisNo]*(this._yMaxValue[yAxisNo]>=0 ? 1 : -1);
			var limit = 0;
			for (var v = start; v <= end && limit < 200; v += this._yMinorUnits[yAxisNo], limit++) {
				var y = this.getPlotY(v,yAxisNo);
				if (y < this._plotBottomOut) {
					d += ' M ' + 0 + ' ' + y*scaleY + ' L ' + (this._plotWidth)*scaleX + ' ' + y*scaleY;
				}
			}
		}
		if ('' != d) {
			ygridMinor.setAttribute("d",d);
			ygridMinor.setAttribute("visibility","visible");
		}
		else {
			ygridMinor.setAttribute("visibility","hidden");
		}
	}
	else {
		// y category axis
		// find # of items and split axis evenly
		var d = '';
		var dmin = '';
		var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
		items = this.plotToEdge ? items-1 : items;
		if (items > 0 && this._plotHeight>0) {
			var y = this._plotTop;
			var dy = this._plotHeight / items;
			for (var n = 1; n < items; n++) {
				y += dy;
				if (this._yMajorGrid && (this._yMajorUnits[yAxisNo]>0) && (n%this._yMajorUnits[yAxisNo] ==0)) {
					if (is3D) {
						d += ' M ' + (-1*this._plotLeftOut/2)*scaleX + ' ' + (y+5)*scaleY + ' L ';
					}
					else {
						d += ' M ';
					}
					d += 0 + ' ' + y*scaleY + ' L ' + this._plotRight*scaleX + ' ' + y*scaleY;
				}
				if (this._yMinorGrid && (this._yMinorUnits[yAxisNo]>0) && (n%this._yMinorUnits[yAxisNo] ==0)) {
					dmin += ' M ' + 0 + ' ' + y*scaleY + ' L ' + this._plotRight*scaleX + ' ' + y*scaleY;
				}
			}
		}

		if ('' != d) {
			ygrid.setAttribute("d",d);
			ygrid.setAttribute("visibility","visible");
		}
		else {
			ygrid.setAttribute("visibility","hidden");
		}
		ygrid.setAttribute("fill","none");
		if ('' != dmin) {
			ygridMinor.setAttribute("d",dmin);
			ygridMinor.setAttribute("visibility","visible");
		}
		else {
			ygridMinor.setAttribute("visibility","hidden");
		}
	}

	if (this.isTimeBased()) {
		// do nothing
	}
	else if (this._xGridType == 'value') {
		// xMajor
		var start, end;
		var d = '';
		var sd = '';
		if (this._xMajorGrid && this._xMajorUnits > 0) {
			var start = Math.ceil(Math.abs(this._xMinValue/this._xMajorUnits))*this._xMajorUnits*(this._xMinValue>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._xMaxValue/this._xMajorUnits))*this._xMajorUnits*(this._xMaxValue>=0 ? 1 : -1);
			var limit = 0;
			var lastX = '';
			for (var v = start; v <= end && limit < 200; v += this._xMajorUnits, limit++) {
				var x = this.getPlotX(v) - this._plotLeft;
				d += ' M ' + x*scaleX + ' ' + this._plotTop*scaleY + ' L ' + x*scaleX + ' ' + this._plotBottom*scaleY;
				if (is3D) {
					d += ' ' + (x-5)*scaleX + ' ' + this._plotBottomOut*scaleY;
				}

				if (lastX != '') {
					sd += ' M ';
					sd += lastX*scaleX + ' ' + this._plotTop*scaleY + ' L ' + lastX*scaleX + ' ' + this._plotBottom*scaleY;
					sd += ' ' + x*scaleX + ' ' + this._plotBottom*scaleY + ' L ' + x*scaleX + ' ' + this._plotTop*scaleY + ' z';
					lastX = '';
				}
				else {
					lastX = x;
				}
			}
		}
		if ('' != d) {
			xgrid.setAttribute("d",d);
			xgrid.setAttribute("visibility","visible");
		}
		else {
			xgrid.setAttribute("visibility","hidden");
		}
		xgrid.setAttribute("fill","none");

		if (xstripes && '' != sd) {
			xstripes.setAttribute("d",sd);
			xstripes.setAttribute("visibility","visible");
		}

		// xMinor
		var start, end;
		var d = '';
		if (this._xMinorGrid && this._xMinorUnits > 0) {
			var start = Math.ceil(Math.abs(this._xMinValue/this._xMinorUnits))*this._xMinorUnits*(this._xMinValue>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._xMaxValue/this._xMinorUnits))*this._xMinorUnits*(this._xMaxValue>=0 ? 1 : -1);
			var limit = 0;
			for (var v = start; v <= end && limit < 200; v += this._xMinorUnits, limit++) {
				var x = this.getPlotX(v) - this._plotLeft;;
				d += ' M ' + x*scaleX + ' ' + this._plotTop*scaleY + ' L ' + x*scaleX + ' ' + this._plotBottom*scaleY;
			}
		}
		if ('' != d) {
			xgridMinor.setAttribute("d",d);
			xgridMinor.setAttribute("visibility","visible");
		}
		else {
			xgridMinor.setAttribute("visibility","hidden");
		}
	}
	else {
		// x category axis
		// find # of items and split axis evenly
		var d = '';
		var dmin = '';
		var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
		items = this.plotToEdge ? items-1 : items;
		if (items > 0) {
			var x = 0;
			var dx = this._plotWidth / items;
			for (var n = 1; n < items; n++) {
				x += dx;
				if (this._xMajorGrid && (this._xMajorUnits>0) && (n%this._xMajorUnits ==0)) {
					d += ' M ' + x*scaleX + ' ' + this._plotTop*scaleY + ' L ' + x*scaleX + ' ' + this._plotBottom*scaleY;
					if (is3D) {
						d += ' ' + (x-5)*scaleX + ' ' + this._plotBottomOut*scaleY;
					}				
				}
				if (this._xMinorGrid && (this._xMinorUnits>0) && (n%this._xMinorUnits ==0)) {
					dmin += ' M ' + x*scaleX + ' ' + this._plotTop*scaleY + ' L ' + x*scaleX + ' ' + this._plotBottom*scaleY;
				}
			}
		}

		if ('' != d) {
			xgrid.setAttribute("d",d);
			xgrid.setAttribute("visibility","visible");
		}
		else {
			xgrid.setAttribute("visibility","hidden");
		}
		xgrid.setAttribute("fill","none");

		if ('' != dmin) {
			xgridMinor.setAttribute("d",dmin);
			xgridMinor.setAttribute("visibility","visible");
		}
		else {
			xgridMinor.setAttribute("visibility","hidden");
		}
	}
}

/// Prepare the axis group for population with axis information
ClientMethod prepareAxisGroup(idName, parentNode) [ Language = javascript ]
{
	var group = this.findSVGElement(idName+this.currMultiple);

	if (null == group) {
		// create group to hold labels
		group = this.document.createElementNS(SVGNS,"g");
		group.setAttribute("id",this.makeId(idName+this.currMultiple));
		if (parentNode != null) { // JSL4487 guard against null
			parentNode.appendChild(group);
		}
	}

	// clear out children of this group
	this.removeChildNodes(group);

	return(group);
}

ClientMethod createXLabelNode(index, fontSize, style, angle, group) [ Language = javascript ]
{
	var align="middle";
	if (angle==null) angle=0;
	if (isNaN(angle)) angle=-60;
	if (angle<-90) angle=-90;
	if (angle>0) angle=0;
	
	if (angle==-90) {
		align='start';
	}
	
	var lbl = this.getXLabelText(index);
	// JMD1182: apply style in function call
	var text = this.createSVGTextNode(lbl,fontSize,this.autoScaleText,align,angle,group,"chart-xLabel",style);
	//text.setAttribute("class","chart-xLabel");
	//this.embedStyle(text.firstChild,style);
	return(text);
}

ClientMethod calculateXAxisTitleHeight() [ Language = javascript ]
{
	// JMD1100 return height
	var hgt = 0;
	var xAxisTitle = this.getXAxisTitle();

	// height of x axis title
	if (xAxisTitle != '') {
		hgt = this.renderXAxisTitle(this.svgGroup);
		var xt = this.findSVGElement('xAxisTitle'+this.currMultiple);
		this.svgGroup.removeChild(xt);
	}
	return hgt;
}

ClientMethod calculateXAxisHeight() [ Language = javascript ]
{
	var idx=[];
	var lWidth=[];
	var maxWidth = 0;
	var maxHeight = 0;
	var dx = 0;

	this._firstXLabelWidth = null;
	this._lastXLabelWidth = null;

	// JMD1125: as side effect compute width of first and last labels
	// to help with margin computation

	// we might not know plot width yet!
	var plotWidth = this._plotWidth ? this._plotWidth : 100;

	if (this.isTimeBased()) {
		if (this.labelsVisible) {
			// JMD1368: only if labels are showing
			var maxHeight = 20/this._scaleY;
		}
	}
	else {
		// create new labels
		if (this.labelsVisible && this._xLabelUnits > 0) {
			var tStyle = this.computeStyle('chart-xLabel',null);
			if (this.labelStyle) this.integrateStyleSpec(tStyle,this.labelStyle);		
			if (this._xLabelStyle) this.integrateStyleSpec(tStyle,this._xLabelStyle);
			var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);

			var txtH = fSz;
			if (!this.autoScaleText) {
				txtH = fSz*this.getPelToPixelVRatio();
			}
			this._xAxisLabelH = txtH;

			var angle = 0;
			if (this._xLabelAngle) angle= -this._xLabelAngle;
			
			if (this._xGridType == 'value') {
				// value labels
				var start = Math.ceil(Math.abs(this._xMinValue/this._xLabelUnits))*this._xLabelUnits*(this._xMinValue>=0 ? 1 : -1);
				var end = Math.floor(Math.abs(this._xMaxValue/this._xLabelUnits))*this._xLabelUnits*(this._xMaxValue>=0 ? 1 : -1);
				dx = this.getPlotX(start + this._xLabelUnits) - this.getPlotX(start);
				var limit = 0;
				for (var v = start; v <= end && limit < 100; v += this._xLabelUnits, limit++) {
					idx[limit]=v;
					var text =this.createXLabelNode(v, fSz, tStyle, 0, this.svgGroup);
					lWidth[limit] = parseFloat(text.getAttribute("logicalWidth"));
					if (lWidth[limit]>maxWidth) maxWidth=lWidth[limit];
					this.svgGroup.removeChild(text);

					// JMD1125
					if (v==start) {
						this._firstXLabelWidth = parseFloat(text.getAttribute("logicalWidth"));
					}
					else if (v>=end) {
						this._lastXLabelWidth = parseFloat(text.getAttribute("logicalWidth"));
					}
				}
			}
			else {
				// category labels
				var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
				if (this.plotToEdge) {
					dx = (items<=1) ? (plotWidth/2) : (plotWidth / (items-1));
				}
				else {
					dx = (items<=1) ? (plotWidth/2) : (plotWidth / items);
				}
				var limit = 0;
				for (var n = 0; n < items; n++) {
					if (n%this._xLabelUnits ==0) {
						idx[limit]=n;
						var text =this.createXLabelNode(n, fSz, tStyle, 0, this.svgGroup); 
						lWidth[limit] = parseFloat(text.getAttribute("logicalWidth"));
						if (lWidth[limit]>maxWidth) maxWidth=lWidth[limit];
						this.svgGroup.removeChild(text);
						limit++;
					}
				}
			}
			
			if (dx<maxWidth) { // Houston, we have a problem...
				if (!this.autoScaleText || this._xGridType != 'value' ) {	
					var nDx = dx;	
					if (!this.autoScaleText) nDx = (dx*this._scaleX)/this.getPelToPixelHRatio();
					//angle = -Math.asin(fSz/nDx)*180/Math.PI;
					// always use right angle
					angle = -90;
				}
			}
			for (var n=0;n<idx.length;n++) {
				var text = this.createXLabelNode(idx[n], fSz, tStyle, angle, this.svgGroup); 
				var h = parseFloat(text.getAttribute("effectiveHeight"));
				
				// JMD1125
				if (this.plotToEdge) {
					if (n==0) {
						this._firstXLabelWidth = parseFloat(text.getAttribute("logicalWidth"));
					}
					else if (n>=idx.length-1) {
						this._lastXLabelWidth = parseFloat(text.getAttribute("logicalWidth"));
					}
				}

				if (h>maxHeight) maxHeight = h;
				this.svgGroup.removeChild(text);
			}
		}
	}
	var xAxisTitleH = this.calculateXAxisTitleHeight();
	
	this._maxXHeight = maxHeight;
	
	var tH = xAxisTitleH*1.1 + maxHeight*1.1 + 2*this.getPelToPixelVRatio();
	return(tH);
}

/// Draw the title section for the Y axis (if any) and
/// return the height reserved for the rendering
ClientMethod renderXAxisTitle(group) [ Language = javascript ]
{
	var titleAdj=0;
	var xt = this.findSVGElement('xAxisTitle'+this.currMultiple);
	if (xt) {
		this.svgGroup.removeChild(xt);
	}

	var xAxisTitle = this.getXAxisTitle();
	if ('' != xAxisTitle) {
		var tStyle = this.computeStyle('chart-xAxisTitle',null);
		//if (this._xLabelStyle) this.integrateStyleSpec(tStyle,this._xLabelStyle);
		//if (this.labelStyle) this.integrateStyleSpec(tStyle,this.labelStyle);
		if (this.axisTitleStyle) this.integrateStyleSpec(tStyle,this.axisTitleStyle);
		var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);
		
		// Create and add to yLabelGroup a new scaled text node
		var text = this.createSVGTextNode(xAxisTitle,fSz,this.autoScaleText,"middle",0,group);
		text.setAttribute("id",this.makeId('xAxisTitle'+this.currMultiple));
		text.setAttribute("class","chart-xAxisTitle");
		this.embedStyle(text.firstChild,tStyle);

		var tx = (this._plotLeftOut + this._rplotWidth/2);
		tx = isNaN(tx) ? 0 : tx;			// DTB197 - Prevent NaN error on chart load

		// JMD1100 (2) place label on top or bottom; place smarter
		if (this._xLabelOnTheTop) {
			var ty = this._plotTopOut - (this._maxXHeight ? this._maxXHeight : 2);
		}
		else {
			// 4 pixels from bottom
			var ty = 100 - (4/this._scaleY);
		}
		titleAdj = parseFloat(text.getAttribute("logicalHeight"))+2*this.getPelToPixelVRatio();
		text.setAttribute("transform","translate("+(tx*this._scaleX)+","+(ty*this._scaleY)+")");
	}
	return(titleAdj);
}

/// Draw the labels for the x axis.
ClientMethod renderXLabels() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	var is3D = this.is3D();

	var virtualLabelGroup = this.findSVGElement('virtualLabelGroup'+this.currMultiple);
	if (virtualLabelGroup == null) { // JSL4487
		return; // JSL4487 
	}
	var xLabelGroup = this.prepareAxisGroup('xLabelGroup',virtualLabelGroup);

	// axis title
	this.renderXAxisTitle(this.svgGroup);

	// create new labels
	if (!this.labelsVisible) {
		if (this.isTimeBased()) {
			// JMD1368: make sure time line is computed
			this.computeXAxisTimeLine();
		}
	}
	else if (this.labelsVisible && this._xLabelUnits > 0) {
		var tStyle = this.computeStyle('chart-xLabel',null);
		if (this.labelStyle) this.integrateStyleSpec(tStyle,this.labelStyle);		
		if (this._xLabelStyle) this.integrateStyleSpec(tStyle,this._xLabelStyle);
		var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);

		var th = fSz;
		if (!this.autoScaleText) {
			th = fSz*this.getPelToPixelVRatio();
		}

		var angle = 0;
		if (this._xLabelAngle) angle = -this._xLabelAngle;

		if (this._xLabelOnTheTop) {
			var y = this._plotTopOut;
		}
		else {
			var y = this._plotBottomOut;
		}
	
		var rotated = (this._xLabelAngle != '' && this._xLabelAngle != 0);

// DO this in two passes, the first figures out what we want to print and how big it is
// the second tries to fit it in the space available
		var idx=[];
		var lWidth=[];
		var maxWidth = 0;
		var dx = 0;
		var adj = 0;

		// JMD1100 dispatch for time axis
		if (this.isTimeBased()) {
			this.computeXAxisTimeLine();
			this.renderXAxisTimeLine(xLabelGroup,this._plotBottomOut);
		}
		else if (this._xGridType == 'value') {
			// value labels
			var start = Math.ceil(Math.abs(this._xMinValue/this._xLabelUnits))*this._xLabelUnits*(this._xMinValue>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._xMaxValue/this._xLabelUnits))*this._xLabelUnits*(this._xMaxValue>=0 ? 1 : -1);
			dx = this.getPlotX(start + this._xLabelUnits) - this.getPlotX(start);
			var limit = 0;
			for (var v = start; v <= end && limit < 100; v += this._xLabelUnits, limit++) {
				idx[limit]=v;
				var text =this.createXLabelNode(v, fSz, tStyle, 0, this.svgGroup);
				lWidth[limit] = parseFloat(text.getAttribute("LogicalWidth"));
				lWidth[limit] = parseFloat(text.getAttribute("logicalWidth"));
				if (lWidth[limit]>maxWidth) maxWidth=lWidth[limit];
				this.svgGroup.removeChild(text);
			}
		}
		else {
			// category labels
			var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			if (this.plotToEdge) {
				dx = (items<=1) ? (this._plotWidth/2) : (this._plotWidth / (items-1));
				adj = (items<=1) ? 0 : dx;
			}
			else {
				dx = (items<=1) ? (this._plotWidth/2) : (this._plotWidth / items);
				adj = (items<=1) ? 0 : (is3D?dx:dx/2);
			}
			var limit = 0;
			for (var n = 0; n < items; n++, limit++) {
				if (n%this._xLabelUnits ==0) {
					idx[limit]=n;
					var text =this.createXLabelNode(n, fSz, tStyle, 0, this.svgGroup); 
					lWidth[limit] = parseFloat(text.getAttribute("logicalWidth"));
					if (lWidth[limit]>maxWidth) maxWidth=lWidth[limit];
					this.svgGroup.removeChild(text);
				}
			}
		}
/// IF all went as expected, the idx array should have the indices of the labels we'd like
/// to print, the lWidth array should have the native widths of each label and maxWidth should
/// be the length of the longest label.	Now we need to print them.
		if (idx.length==0) return;

		var skip = 1;
		if (dx<maxWidth) { // Houston, we have a problem...
			if (!this.autoScaleText || this._xGridType != 'value' ) {
				var nDx = dx;	
				if (!this.autoScaleText) {
					nDx = (dx*this._scaleX)/this.getPelToPixelHRatio();
				}
				
				// angle = -Math.asin(fSz/nDx)*180/Math.PI;
				// JMD1125: only use right angle
				angle = -90;
				if (isNaN(angle)) {
					if (this._xGridType == 'value') {
						skip=Math.ceil(fSz/nDx);
					}
					else { // need to squish font
						fSz = nDx;
					}
				}
			}
			else {
				skip = Math.ceil(maxWidth/dx);
			}
		}
		if (skip>idx.length-1) skip = idx.length-1;

		var x=0;
		for (var n=0;n<idx.length;n++) {
			if (this._xGridType == 'value') {
				var x = this.getPlotX(idx[n])+ ((is3D&&this.chartPivot) ? -5:0) - this._plotLeft;
			}
			else {
				x += dx;
			}
			if (skip == 0) { // just one label JSL4141
				var nModSkip = 0;
			} else {
				var nModSkip = n % skip;
			}
			if (nModSkip==0) {
				var text =this.createXLabelNode(idx[n], fSz, tStyle, angle, xLabelGroup); 
				// JMD1100 turn off yAdj; use th correctly
				var yAdj = 0; // parseFloat(text.getAttribute("yOffset"))/this._scaleY;
				var th = parseFloat(text.getAttribute("effectiveHeight"));
				var ofs = 0;
				if (angle!=0) {
					//ofs = parseFloat(text.getAttribute("effectiveWidth"))+parseFloat(text.getAttribute("xOffset"));
					yAdj = -2;
					ofs = -2/this._scaleX;
				}
				else {
					// JMD1320: center 3d labels
					if (is3D && !this.plotToEdge) {
						ofs = -parseFloat(text.getAttribute("effectiveWidth"))/2;
					}
					
				}
				if (this._xLabelOnTheTop) {
					text.setAttribute("transform","translate("+((x-adj-ofs)*this._scaleX)+","+((y*this._scaleY)-1)+")");
				}
				else {
					text.setAttribute("transform","translate("+((x-adj-ofs)*this._scaleX)+","+((y+th-yAdj)*this._scaleY)+")");
				}
			}
		}
	}
}

/// This is the core of the vertical decimation algorithm.  Given a maximum number of label
/// to choose from an array,  pick a subset that will (hopefully) use the available
/// space effectively and keep things visually balanced.
ClientMethod pickVerticalSkips(flag, max) [ Language = javascript ]
{
	var fl = flag.length;
	if (max>=fl || fl<3) { //room to show everyone
		for (var i=1;i<fl;i++) flag[i]=1;
		return;
	}

	// The first and last flags should always be set so point at the middle
	flag[0] = 1;
	flag[fl-1] = 1;
	max -= 2;
	var sIdx=1;
	var eIdx=fl-2;

	// If we're skipping at all we need to do at least every other one
	// or we risk overlap.  This means the items next to the end points
	// do not display, the range gets smaller.
	flag[sIdx++]=0;
	flag[eIdx--]=0;

	// See what we've got left to choose from
	var seriesSpan = (eIdx-sIdx+1);

	// Get real max number of labels if we were to skip every other one
	var rMax = Math.ceil(seriesSpan/2);

	// If we asked for more labels than the practical max then clip it
	// to what we can show, we can't play with label spacing arbitrarily,
	// either the label's there or it isn't.
	if (max>rMax) {
		// Room to spare with skip one treatment.  Mark every other
		// label for printing.
		var show=1;
		for (var i=sIdx;i<=eIdx;i++) {
			flag[i] = show;
			show = 1-show;
		}
		return;
	}	
	else {
		// Okay printing every other label would still take too much 
		// room.  Time to pretend that we are clever...
		
		// Put back the two spaces we skipped earlier
		sIdx--;
		eIdx++;
		seriesSpan+=2;

		// Get the number of labels we're NOT printing
		var nSkip=seriesSpan-max;
		// Get the number of clusters of skipped labels
		var nSpans = max+1;
		// Get (roughly) the number of labels skipped in each cluster
		var skipGap = Math.floor(nSkip/nSpans);
		// Account for any uneven division
		var fill = nSkip-nSpans*skipGap;
		// And figure out where to put the excess fill back in
		var padIdx=Math.round(nSpans-fill)/2;
		var i=sIdx;
		var spanCount=0;
		while (i<=eIdx && max>0) {
			// First mark the skipped elements
			for (var j=0;j<skipGap;j++) {
				flag[i++] = 0;
			}
			// If there's filling to be done add it in
			if (fill>0 && spanCount>=padIdx) {
				flag[i++] = 0;
				fill--;
			}
			// Update skip index to next span
			spanCount++;			
			// Enable the next label
			flag[i++] = 1;
			// Count down the label left to go
			max--;
		}
	}
}

/// Internl method to calculate how much room should be reserved 
/// for the Y axis area.  This includes both the axis title and
/// the individual labels
ClientMethod calculateYAxisWidth(which) [ Language = javascript ]
{
	// scale group for left y Axis
	var yAxisNo = this.getCurrYAxis(which);
	var yAxisTitle = this.getYAxisTitle(which);

	var w=0;
	var wTitle = 0;		// DTB197
	if (zenIsMissing(this.document)) return(0);
	var is3D = this.is3D();
	var group = this.prepareAxisGroup('yLabelGroup'+which+this.currMultiple,this.svgGroup);

	if ('' != yAxisTitle) {
		var tStyle = this.computeStyle('chart-yAxisTitle',null);
		//if (this._yLabelStyle[yAxisNo]) this.integrateStyleSpec(tStyle,this._yLabelStyle[yAxisNo]);
		if (this.axisTitleStyle) this.integrateStyleSpec(tStyle,this.axisTitleStyle);
		var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);

		// Create and add to yLabelGroup a new scaled text node
		var text = this.createSVGTextNode(yAxisTitle,fSz,this.autoScaleText,"middle",-90,group);
		text.setAttribute("class","chart-yAxisTitle");
		this.embedStyle(text.firstChild,tStyle);

		w += parseFloat(text.getAttribute("effectiveWidth"))*1.1;
		wTitle = w;		// DTB197 - preserve the title-only width in case we need it later
	}

	var mW = 0;
	if (this.labelsVisible) {
		var tStyle = this.computeStyle('chart-yLabel',null);
		if (this.labelStyle) this.integrateStyleSpec(tStyle,this.labelStyle);
		if (this._yLabelStyle[yAxisNo]) this.integrateStyleSpec(tStyle,this._yLabelStyle[yAxisNo]);
		var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);
		var tw = 0;
		var rotate = (this._yLabelAngle[yAxisNo] != '' && this._yLabelAngle[yAxisNo] != 0);
		var angle = 0;
		if (this._yLabelAngle[yAxisNo]) angle= -this._yLabelAngle[yAxisNo];
		if (angle>0) angle = 0;
		if (angle<-60) angle = -60;

		if (this._yGridType == 'value') {
			var start = Math.ceil(Math.abs(this._yMinValue[yAxisNo]/this._yLabelUnits[yAxisNo]))*this._yLabelUnits[yAxisNo]*(this._yMinValue[yAxisNo]>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._yMaxValue[yAxisNo]/this._yLabelUnits[yAxisNo]))*this._yLabelUnits[yAxisNo]*(this._yMaxValue[yAxisNo]>=0 ? 1 : -1);
			var limit = 0;
			for (var v = start; v <= end && limit < 100; v += this._yLabelUnits[yAxisNo], limit++) {
				lbl = this.getYLabelText(v,yAxisNo);
				var text = this.createSVGTextNode(lbl,fSz,this.autoScaleText, "end", angle, group);
				text.setAttribute("class","chart-yLabel");
				this.embedStyle(text.firstChild,tStyle);
				tw = parseFloat(text.getAttribute("effectiveWidth"));
				mW = (mW < tw) ? tw : mW;
			}
		}
		else {
			// category labels
			var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			if (items > 0) {
				for (var n = 0; n < items; n++) {
					var lbl = this.getYLabelText(n,yAxisNo);
					var text = this.createSVGTextNode(lbl,fSz,this.autoScaleText, "end", angle, group);
					text.setAttribute("class","chart-yLabel");
					this.embedStyle(text.firstChild,tStyle);
					tw = parseFloat(text.getAttribute("effectiveWidth"));
					mW = (mW < tw) ? tw : mW;
				}
			}
		}
	}

	w += mW + (1.5/this._scaleX);
	this.prepareAxisGroup('yLabelGroup'+which+this.currMultiple);

	// DTB197 - Only force w<=50 if the text can be autosized to fit the space. 
	// Otherwise, honestly report the space expected to be consumed by the label
	if ((w>50)&&this.autoScaleText) {
		w = 50;
	} else {
		if (!this.labelsVisible) {
			w = wTitle + (10/this._scaleX);	
		}
	}

	return(w);
}

/// Draw the title section for the Y axis (if any) and
/// return the width reserved for the rendering
ClientMethod renderYAxisTitle(group, which, xpos) [ Language = javascript ]
{
	// +DTB197
	var yt = this.findSVGElement('yAxisTitle'+which+this.currMultiple);
	if (yt) {
		group.removeChild(yt);
	}
	// -DTB197
	
	var yAxisTitle = this.getYAxisTitle(which);
	if ('' != yAxisTitle) {
		var yAxisNo = this.getCurrYAxis(which);

		var tStyle = this.computeStyle('chart-yAxisTitle',null);
		//if (this.labelStyle) this.integrateStyleSpec(tStyle,this.labelStyle);
		//if (this._yLabelStyle[yAxisNo]) this.integrateStyleSpec(tStyle,this._yLabelStyle[yAxisNo]);
		if (this.axisTitleStyle) this.integrateStyleSpec(tStyle,this.axisTitleStyle);
		var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);
		
		// Create and add to yLabelGroup a new scaled text node
		var angle = (which=='right') ? 90 : -90;
		var text = this.createSVGTextNode(yAxisTitle,fSz,this.autoScaleText,"middle",angle,group);
		text.setAttribute("id",this.makeId('yAxisTitle'+which+this.currMultiple));
		text.setAttribute("class","chart-yAxisTitle");
		this.embedStyle(text.firstChild,tStyle);

		var tx = 0;
		var ty = this._plotTopOut + this._plotHeight/2;
		if (which=='right') {
			tx = 100 - parseFloat(text.getAttribute("effectiveWidth"))*1.1;
		}
		else {
			tx = parseFloat(text.getAttribute("effectiveWidth"))*1.1;
		}
		text.setAttribute("transform","translate("+(tx*this._scaleX)+","+(ty*this._scaleY)+")");
		return(tx);
	}
	return(0);
}

/// Draw the labels for the y axis.
ClientMethod renderYLabels(which) [ Language = javascript ]
{
	// JMD1100 -- remove *test* argument
	if (zenIsMissing(this.document)) return(0);
	var is3D = this.is3D();

	// JMD1100 which is 'left' or 'right'
	which = ('undefined' == typeof which) ? 'left' : which;

	var yLabelGroup = this.prepareAxisGroup('yLabelGroup'+which+this.currMultiple,this.svgGroup);
	// create new labels

	// scale group for y axis
	var yAxisNo = this.getCurrYAxis(which);
	
	// DTB197 - Render the title first and record the space needed to prevent label collision after translate()
	var titleWidth = this.renderYAxisTitle(yLabelGroup,which,this._rplotRightOut+(is3D?5:0));
	var xoffPix = 5/this._scaleX;	// pixel offset	used for padding
	var maxWidth = 0;

	if (this.labelsVisible && this._yLabelUnits[yAxisNo] > 0) {
		var tStyle = this.computeStyle('chart-yLabel',null);
		if (this.labelStyle) this.integrateStyleSpec(tStyle,this.labelStyle);
		if (this._yLabelStyle[yAxisNo]) this.integrateStyleSpec(tStyle,this._yLabelStyle[yAxisNo]);

		var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);

		var tx = which=='left' ? (this._plotLeftOut):(this._rplotRightOut+(is3D?5:0));
		var tw = 0;
	
		var rotate = (this._yLabelAngle[yAxisNo] != '' && this._yLabelAngle[yAxisNo] != 0);

		var angle = 0;
		if (this._yLabelAngle[yAxisNo]) angle= -this._yLabelAngle[yAxisNo];
		if (angle>0) angle = 0;
		if (angle<-60) angle = -60;

		if (this._yGridType == 'value') {
	
			var start = Math.ceil(Math.abs(this._yMinValue[yAxisNo]/this._yLabelUnits[yAxisNo]))*this._yLabelUnits[yAxisNo]*(this._yMinValue[yAxisNo]>=0 ? 1 : -1);
			var end = Math.floor(Math.abs(this._yMaxValue[yAxisNo]/this._yLabelUnits[yAxisNo]))*this._yLabelUnits[yAxisNo]*(this._yMaxValue[yAxisNo]>=0 ? 1 : -1);
	
			var lbl = [];
			var show = [];

			var limit = 0;
			for (var v = start; v <= end && limit < 100; v += this._yLabelUnits[yAxisNo], limit++) {
				lbl[limit] = this.getYLabelText(v,yAxisNo);
				if (this.autoScaleText) show[limit]=1;
				else show[limit]=0;
			}
			
			if (!this.autoScaleText) {			
				var vSpace = (fSz*this.getPelToPixelVRatio()*1.23);
				if (angle!=0) {
					var aRad = Math.PI * (angle/180);
					var cos = Math.cos(aRad);
					vSpace = vSpace/cos;
				}
				this.pickVerticalSkips(show,Math.floor((this._plotHeight*this._scaleY)/vSpace));
			}
			
			var limit = 0;
			for (var v = start; v <= end && limit < 100; v += this._yLabelUnits[yAxisNo], limit++) {
				if (show[limit]==1) {
					var y = this.getPlotY(v,yAxisNo) + ((is3D&&!this.chartPivot&&which=='left') ? 5:0);
					var text = this.createSVGTextNode(lbl[limit],fSz,this.autoScaleText, (which=='left'?"end":"start"), angle, yLabelGroup);
					text.setAttribute("class","chart-yLabel");
					this.embedStyle(text.firstChild,tStyle);
					var ty = y+1;
					text.setAttribute("transform","translate("+(( tx + (which=='left'?-xoffPix:xoffPix) )*this._scaleX)+","+((ty)*this._scaleY)+")");
				}
			}
		}
		else {
			// category labels must always show
			// if autoScaleText, just render and let user solve the problem by
			// fiddling with font size.
			// if not autoScaleText, and the area is too crunched, find a new font
			// size that will fit the available space.
			var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			if (items > 0 && this._plotHeight>0) {
				var dy,adj;
				if (this.plotToEdge) {
					dy = (items<=1) ? (this._plotHeight/2) : (this._plotHeight / (items-1));
					adj = (items<=1) ? 0 : dy;
				}
				else {
					dy = (items<=1) ? (this._plotHeight/2) : (this._plotHeight / items);
					adj = (items<=1) ? 0 : dy/2;
				}

				var y = this._plotTopOut;
				var lastY = y;
				var th = 0;

				if (!this.autoScaleText) {
					var mFZ = (dy*this._scaleY)/this.getPelToPixelVRatio()*1.23;
					if (fSz>mFZ) {
						fSz = mFZ/1.23;
					}
				}
			
				for (var n = 0; n < items; n++) {
					y += dy;
					var text = this.createSVGTextNode(this.getYLabelText(n,yAxisNo),fSz,this.autoScaleText, (which=='left'?"end":"start"), angle, yLabelGroup);
					text.setAttribute("class","chart-yLabel");
					this.embedStyle(text.firstChild,tStyle);

					if (angle==0) {
						lh = text.getAttribute("logicalHeight");
						//th = ((-0.25*lh)+(dy-lh)/5);
						// JMD1125 simplify
						th = lh/3;
					}
					var ty = y - adj + th;
					text.setAttribute("transform","translate("+(( tx + (which=='left'?-xoffPix:xoffPix) )*this._scaleX)+","+(ty*this._scaleY)+")");
					lastY = y;
				}
			}
		}
	}
	return tx;		// DTB197 - Return the logical space needed to render the labels with no collisions
}

/// Draw the data series for this chart.
/// This method renders the container for the data series and
/// then invokes a sub-class specific <method>renderSeries</method> method.
ClientMethod renderSeriesGroup() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	var is3D = this.is3D();

	var seriesGroup = this.findSVGElement('seriesGroup'+this.currMultiple);
	var virtualGroup = this.findSVGElement('virtualGroup'+this.currMultiple);

	if (null == seriesGroup) {
		// create group to hold series & clip
		// JMD1100: do not clip if 3D
		if ('3D' == this.appearance) {
			seriesGroup = this.document.createElementNS(SVGNS,"g");
		}
		else {
			seriesGroup = this.document.createElementNS(SVGNS,"svg");
		}
		seriesGroup.setAttribute("id",this.makeId('seriesGroup'+this.currMultiple));
		virtualGroup.appendChild(seriesGroup);
	}

	// clear out children of this group
	while(null != seriesGroup.firstChild) {
		seriesGroup.removeChild(seriesGroup.firstChild);
	}

	// make sure size of series group is ok
	var adj = is3D ? 5 : 0;
	// JMD1100
	if ('3D' == this.appearance) {
		seriesGroup.setAttribute("transform",'translate(0,'+this._plotTop*this._scaleY+')');
	}
	else {
		seriesGroup.setAttribute("y",this._plotTop*this._scaleY);
		seriesGroup.setAttribute("width",(this._plotWidth + adj)*this._scaleX);
		seriesGroup.setAttribute("height",(this._plotHeight + adj)*this._scaleY);
	}

	// JMD1314:
	this.renderTimeEvents(seriesGroup);
	this.updateIndicator();

	// create the actual series
	this.renderSeries(seriesGroup);
}

/// Draw data series for this chart.
/// This is implemented by subclasses.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	alert('Chart: renderSeries method is unimplemented.');
}

/// Draw the legend for the chart.
ClientMethod renderLegend() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	// determine is legend is visible
	var legends = this.getLegendLabels();
	this._legendVisible = false;
	if ('true' == this.legendVisible) {
		this._legendVisible = true;
	}
	else if ('auto' == this.legendVisible) {
		this._legendVisible = (legends.length > 1);
	}

	if (this.hasMultiples()) {
		// no legends for multiples
		this._legendVisible = false;
	}

	var svgLegendGroup = this.findSVGElement('legendGroup');
	if (svgLegendGroup) {
		// clear out children of this group
		while(null != svgLegendGroup.firstChild) {
			svgLegendGroup.removeChild(svgLegendGroup.firstChild);
		}
	}
	if (!this._legendVisible) {
		this._legendWidth = null;
		return;
	}

	if (null == svgLegendGroup) {
		// create
		svgLegendGroup = this.document.createElementNS(SVGNS,"svg");
		svgLegendGroup.setAttribute("id",this.makeId('legendGroup'));
		this.svgGroup.appendChild(svgLegendGroup);
	}

	// background
	var brect = this.document.createElementNS(SVGNS,"rect");
	brect.setAttribute("id",this.makeId('legendRect'));
	svgLegendGroup.appendChild(brect);

	var scount = legends.length;
	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber)) {
		scount = 1;
	}
	var x,y;
	if ('' === this.legendX) {
		x = zenGet(this._plotRight,0);
	}
	else {
		x = this.xToLogical(this.legendX);
	}
	if ('' === this.legendY) {
		y = zenGet(this._marginTop,0);
	}
	else {
		y = this.yToLogical(this.legendY);
	}
	var wid,hgt,autoWid,autoHgt;
	if (''===this.legendWidth) {
		wid = 10;
		autoWid = true;
	}
	else {
		wid = this.xToLogical(this.legendWidth);
		autoWid = false;
	}
	if (''===this.legendHeight) {
		hgt = ((scount*3)+2);
		autoHgt = true;
	}
	else {
		hgt = this.yToLogical(this.legendHeight);
		autoHgt = false;
	}
	
	// size of legend
	svgLegendGroup.setAttribute('x',(x*this._scaleX));
	svgLegendGroup.setAttribute('y',(y*this._scaleY));
	svgLegendGroup.setAttribute('width',(wid*this._scaleX));
	svgLegendGroup.setAttribute('height',(hgt*this._scaleY));

	// background rect
	brect.setAttribute("class","chart-legend");
	brect.setAttribute("x",0);
	brect.setAttribute("y",0);
	brect.setAttribute("rx",5);
	brect.setAttribute("width",(wid*this._scaleX));
	brect.setAttribute("height",(hgt*this._scaleY));
	brect.setAttribute("style",this.legendStyle);

	// legend items
	var legWid = 0;
	var legHgt = 2;
	var ty = legHgt;

	var legendTitle = this.legendTitle;
	if ('' == legendTitle) {
		var controller = this.getController();
		if (controller && controller.getDimName) {
			legendTitle = controller.getDimName(1);
		}
	}

	var start = ('' == legendTitle) ? 0 : -1;

	// backing rectangle for legend items
	// used when there are multiple y-axes in the chart
	var yaCount = this.getYAxisCount();
	var legRect = [];
	for (var s = start; s < this.getLegendsCount(legends); s++) {
		if (s >= 0) {
			if (!isNaN(seriesNumber)) {
				var sno = seriesNumber;
			}
			else {
				var sno = s;
			}
			var color = this.getSeriesColor(sno);
			var shape = this.getMarkerShape(sno);

			// special logic for comboCharts
			var plotType = this.getSeriesType(s);

			// backing rect for item in legend
			legRect[s] = null;
			if (!this.yAxis && yaCount>1 && this.tag != "bubbleChart" && this.tag != "xyChart") {
				legRect[s] = this.document.createElementNS(SVGNS,"rect");
				legRect[s].setAttribute("class",'chart-legendRect');
				legRect[s].setAttribute("style",this.legendRectStyle);
				svgLegendGroup.appendChild(legRect[s]);
			}

			if (this.markersVisible && (plotType=='line' || plotType=='')) {
				// show plain rect if no marker OR we are in a comboChart and not a line				
				var leg = this.createMarker(sno, 0, 2, ty, color, shape, true);				
				svgLegendGroup.appendChild(leg);
			}
			else {
				// size in pixels; position has to harmonize with marker position
				var leg = this.document.createElementNS(SVGNS,"rect");
				leg.setAttribute("x",-5);
				leg.setAttribute("y",-5);
				leg.setAttribute("width",10);
				leg.setAttribute("height",10);
				leg.setAttribute("fill",color);
				leg.setAttribute("stroke",'#808080');
				leg.setAttribute("stroke-width",'0.5px');
				if (this.getLegendRectStyle(s)) leg.setAttribute("style", this.getLegendRectStyle(s)) // JSL4133
				svgLegendGroup.appendChild(leg);
			}

			if (legRect[s] && this._yAxisForSeries[s] != this.currYAxis && this.tag != "bubbleChart" && this.tag != "xyChart") {
				// if user clicks on non-current series, switch axis
				legRect[s].setAttribute("opacity",0.0);
				var f = new Function('return zenPage.getComponent('+this.index+').setCurrYAxis('+this._yAxisForSeries[s]+');');
				leg.addEventListener('click',f,false);
				legRect[s].addEventListener('click',f,false);
			}
		}

		var text = this.document.createElementNS(SVGNS,"text");
		text.setAttribute("class","chart-legendLabel");
		text.setAttribute("style",this.legendLabelStyle + ((s<0)?'font-weight:bold;opacity:0.6;':''));
		text.setAttribute("x", 15);		// JMD1100 use pixels
		text.setAttribute("y", ty*this._scaleY);

		var label = (s<0) ? legendTitle : legends[sno];
		var textNode = this.document.createTextNode(label);
		text.appendChild(textNode);
		svgLegendGroup.appendChild(text);

		var bbox = zenGetBBox(text);
		var tw = ((zenGetComputedTextLength(text)*1.3)/ this._scaleX);
		legWid = (legWid > tw) ? legWid : tw;
		var th = ((bbox.height*1.4/this._scaleY)<3) ? 3 : (bbox.height*1.4/this._scaleY);

		text.setAttribute("x", 0); 
		text.setAttribute("y", 0); 
		text.setAttribute("transform","translate("+(20)+","+((ty+(2*th/3))*this._scaleY)+")"); 

		if (leg) {	
			// JMD1100 offset in pixels; not scaled units
			var xm = 10;
			var ya = 1;			
			leg.setAttribute("transform","translate("+(xm)+","+(((ty+ya)+(2*th/3)-2)*this._scaleY)+")");
		}

		if (s<0) {
			th = th * 1.3;
		}

		if (legRect[s]) {
			legRect[s].setAttribute("x",2);
			legRect[s].setAttribute("y",ty*this._scaleY);
			legRect[s].setAttribute("height",(th*this._scaleY)-2);
		}

		ty += th;
		legHgt += th;
	}
	
	if (autoWid) {
		legWid = legWid + (15+15)/this._scaleX;
		brect.setAttribute("width",((legWid-1)*this._scaleX));
		svgLegendGroup.setAttribute('x',((100-legWid)*this._scaleX));
		svgLegendGroup.setAttribute('width',(legWid*this._scaleX)+2);

		this._legendWidth = legWid;
	}
	else {
		this._legendWidth = null;
	}

	// adjust size of legRects
	if (legRect.length) {
		for (var s = start; s < scount; s++) {
			if (legRect[s]) {
				legRect[s].setAttribute("width",((legWid-1)*this._scaleX)-4);
			}
		}
	}

	if (autoHgt) {
		legHgt += 1;
		var top = this._marginTop;
		var btm = this._marginBottom;
		if (legHgt > (100 - (top + btm))) {
			legHgt = (100 - (top + btm));
		}
		brect.setAttribute("height",(legHgt*this._scaleY));
		svgLegendGroup.setAttribute('height',(legHgt*this._scaleY));
	}
}

/// Draw the control bar for this chart.
/// This houses the zoom and pan buttons, if present.
ClientMethod renderControlBar() [ Internal, Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	var hgt = this._controlBarH;	// pixels

	var controlBar = this.findSVGElement('controlBar');
	if (null == controlBar && (parseInt(this.height) > hgt)) {
		// create
		controlBar = this.document.createElementNS(SVGNS,"g");
		controlBar.setAttribute("id",this.makeId('controlBar'));
		controlBar.setAttribute("transform",'translate(0,'+(parseInt(this.height)-hgt)+')');
		this.svgGroup.appendChild(controlBar);
	}
	this.renderZoomTool();

	// return height in pixels
	return hgt;
}

/// Draw the zoom and scroll tools for this chart.
ClientMethod renderZoomTool() [ Internal, Language = javascript ]
{
	var dx = 24;
	var x = 10;
	var y = 6;
	
	var group = this.findSVGElement('controlBar');
	var zoomIn = this.findSVGElement('zoomIn');
	var zoomOut = this.findSVGElement('zoomOut');
	var scrollLeft = this.findSVGElement('scrollLeft');
	var scrollRight = this.findSVGElement('scrollRight');

	if (null == zoomIn) {
		// create

		// zoomIn
		zoomIn = this.document.createElementNS(SVGNS,"path");
		zoomIn.setAttribute("id",this.makeId('zoomIn'));
		zoomIn.setAttribute("d",'M 0 0 l 4.8 0 0 -4.8 4.8 0 0 4.8 4.8 0 0 4.8 -4.8 0 0 4.8 -4.8 0 0 -4.8 -4.8 0 z');
		zoomIn.setAttribute("class",'chart-scrollButton');
		zoomIn.setAttribute("style",this.scrollButtonStyle);
		group.appendChild(zoomIn);
		var f = new Function('evt','return zenPage.getComponent('+this.index+').zoomToolHandler(evt,true);');
		zoomIn.addEventListener('click',f,false);

		// zoomOut
		zoomOut = this.document.createElementNS(SVGNS,"path");
		zoomOut.setAttribute("id",this.makeId('zoomOut'));
		zoomOut.setAttribute("d",'M 0 4.8 l 13.8 0 0 -4.8 -13.8 0 z');
		zoomOut.setAttribute("class",'chart-scrollButton');
		zoomOut.setAttribute("style",this.scrollButtonStyle);
		group.appendChild(zoomOut);

		var f = new Function('evt','return zenPage.getComponent('+this.index+').zoomToolHandler(evt,false);');
		zoomOut.addEventListener('click',f,false);

		// scrollLeft
		scrollLeft = this.document.createElementNS(SVGNS,"path");
		scrollLeft.setAttribute("id",this.makeId('scrollLeft'));
		scrollLeft.setAttribute("class",'chart-scrollButton');
		scrollLeft.setAttribute("style",this.scrollButtonStyle);
		scrollLeft.setAttribute("d",'M 0 3 l 4 -4 8 0 0 8 -8 0 z');
		group.appendChild(scrollLeft);

		var f = new Function('evt','return zenPage.getComponent('+this.index+').scrollHandlerDown(evt,true);');
		scrollLeft.addEventListener('mousedown',f,false);
		var f = new Function('evt','return zenPage.getComponent('+this.index+').scrollHandlerUp(evt);');
		scrollLeft.addEventListener('mouseup',f,false);

		// scrollRight
		scrollRight = this.document.createElementNS(SVGNS,"path");
		scrollRight.setAttribute("d",'M 3 3 l -4 -4 -8 0 0 8 8 0 z');
		scrollRight.setAttribute("id",this.makeId('scrollRight'));
		scrollRight.setAttribute("class",'chart-scrollButton');
		scrollRight.setAttribute("style",this.scrollButtonStyle);
		group.appendChild(scrollRight);

		var f = new Function('evt','return zenPage.getComponent('+this.index+').scrollHandlerDown(evt,false);');
		scrollRight.addEventListener('mousedown',f,false);
		var f = new Function('evt','return zenPage.getComponent('+this.index+').scrollHandlerUp(evt);');
		scrollRight.addEventListener('mouseup',f,false);

		var f = new Function('evt','if (parseFloat(evt.target.getAttribute("opacity"))>=0.5){evt.target.setAttribute("opacity",1.0);}return true;');
		zoomIn.addEventListener('mouseover',f,false);
		zoomOut.addEventListener('mouseover',f,false);
		scrollLeft.addEventListener('mouseover',f,false);
		scrollRight.addEventListener('mouseover',f,false);

		var f = new Function('evt','if (parseFloat(evt.target.getAttribute("opacity"))>=0.5){evt.target.setAttribute("opacity",0.6);}return true;');
		zoomIn.addEventListener('mouseout',f,false);
		zoomOut.addEventListener('mouseout',f,false);
		scrollLeft.addEventListener('mouseout',f,false);
		scrollRight.addEventListener('mouseout',f,false);
	}

	// adjust scroll buttons
	zoomIn.setAttribute("transform","translate("+x+","+y+")");
	x += dx;
	zoomOut.setAttribute("transform","translate("+x+","+y+")");
	x += dx;
	scrollLeft.setAttribute("transform","translate("+x+","+y+")");
	x += dx;
	scrollRight.setAttribute("transform","translate("+x+","+y+")");
	x += dx;

	// hide/show buttons
	if (this.chartPivot || this._hzMaxStep == 0 || this.hzZoomStep == 0) { 
		scrollRight.setAttribute("display",'none');
		scrollLeft.setAttribute("display",'none');
	}
	else {
		scrollRight.setAttribute("display",'block');
		scrollLeft.setAttribute("display",'block');
		scrollRight.setAttribute("opacity",0.75);
		scrollLeft.setAttribute("opacity",0.75);

		var currScroll = parseFloat(this.scrollLeft);
		if (currScroll >= this._maxScrollLeft) {
			scrollRight.setAttribute("opacity",0.1);
		}
		if (currScroll <= 0) {
			scrollLeft.setAttribute("opacity",0.1);
		}
	}

	if (this.chartPivot || this._hzMaxStep == 0) { 
		zoomIn.setAttribute("display",'none');
		zoomOut.setAttribute("display",'none');
	}
	else {
		zoomIn.setAttribute("display",'block');
		zoomOut.setAttribute("display",'block');

		zoomIn.setAttribute("opacity",0.75);
		zoomOut.setAttribute("opacity",0.75);
		var currStep = parseInt(this.hzZoomStep);
		if (currStep >= this._hzMaxStep) {
			zoomIn.setAttribute("opacity",0.1);
		}
		if (currStep <= 0) {
			zoomOut.setAttribute("opacity",0.1);
		}
	}
}

/// Click handler for zoom tool.
ClientMethod zoomToolHandler(evt, zoomIn) [ Internal, Language = javascript ]
{
	var currStep = parseInt(this.hzZoomStep);
	if (zoomIn) {
		if (currStep < this._hzMaxStep) {
			this.hzZoomStep = currStep + 1;
			this.updateChart();
		}
	}
	else {
		if (currStep > 0) {
			this.hzZoomStep = currStep - 1;
			this.updateChart();
		}
	}
}

/// Mouse down handler for scroll button.
ClientMethod scrollHandlerDown(evt, left) [ Internal, Language = javascript ]
{
	this._interval = 1;

	if (this._timerId) {
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}

	this.scrollHandler(left);
	this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").btnTimerHandler("+(left?'true':'false')+")",750);
}

/// Timer handler for scroll buttons.
ClientMethod btnTimerHandler(left) [ Internal, Language = javascript ]
{
	delete this._timerId;

	this.scrollHandler(left);
	this._interval = (this._interval) ? this._interval + 0.5 : 1;
	this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").btnTimerHandler("+(left?'true':'false')+")",100);
}

/// Mouse up handler for scroll button.
ClientMethod scrollHandlerUp(evt) [ Internal, Language = javascript ]
{
	if (this._timerId) {
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}
}

/// Perform the scroll action when the button is pressed.
ClientMethod scrollHandler(left) [ Internal, Language = javascript ]
{
	var go = false;
	this.scrollLeft = parseFloat(this.scrollLeft);
	this.scrollLeft = isNaN(this.scrollLeft) ? 0 : this.scrollLeft;
	var currScroll = this.scrollLeft;
	var items = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
	if (this.hasMultiples()) {
		items = this.getSeriesSize();
	}

	var int = (this._interval) ? Math.floor(this._interval) : 1;
	var delta = int * (this._plotWidth / items);

	if (left && currScroll > 0) {
		this.scrollLeft -= delta;
		this.scrollLeft = (this.scrollLeft < 1) ? 0 : this.scrollLeft;
		go = true;
	}
	else if (!left && currScroll < this._maxScrollLeft) {
		this.scrollLeft += delta;
		this.scrollLeft = (this.scrollLeft > (this._maxScrollLeft-1)) ? this._maxScrollLeft : this.scrollLeft;
		go = true;
	}

	if (go) {
		// JMD1100 loop over multiples 
		var multiples = 1;
		if (this.hasMultiples()) {
			multiples = this.getSeriesCount();
		}
		this.currMultiple = '';
		for (var n = 0; n < multiples; n++) {
			if (this.hasMultiples()) {
				this.currMultiple = n;
			}

			var virtualGroup = this.findSVGElement('virtualGroup'+this.currMultiple);
			virtualGroup.setAttribute("transform",'translate('+ -(parseFloat(this.scrollLeft)*this._scaleX)+',0)');
			var virtualLabelGroup = this.findSVGElement('virtualLabelGroup'+this.currMultiple);
			virtualLabelGroup.setAttribute("transform",'translate('+ -((parseFloat(this.scrollLeft)-this._labelPadL)*this._scaleX)+',0)');
		}

		var scrollLeft = this.findSVGElement('scrollLeft');
		var scrollRight = this.findSVGElement('scrollRight');

		currScroll = parseFloat(this.scrollLeft);
		if (currScroll >= this._maxScrollLeft) {
			scrollRight.setAttribute("opacity",0.3);
		}
		else {
			scrollRight.setAttribute("opacity",0.6);
		}
		if (currScroll <= 0) {
			scrollLeft.setAttribute("opacity",0.3);
		}
		else {
			scrollLeft.setAttribute("opacity",0.6);
		}
	}
}

/// The Normalized viewbox ranges from 0 0 to 100 100, the physical space 
/// occupied by the chart is specified as the width and height (in pixels) of
/// the base SVG group.  This function returns a mapping of logical picture 
/// units to pixels in the vertical direction. 
ClientMethod getPelToPixelVRatio() [ Language = javascript ]
{
	// JMD1100
	if (this.viewBoxWidth == '' && this.viewBoxHeight == '') {
		return 1;
	}
	var physicalHeight = parseInt(this.svgGroup.getAttribute('height'),10);
	return(100/physicalHeight);
}

/// The Normalized viewbox ranges from 0 0 to 100 100, the physical space 
/// occupied by the chart is specified as the width and height (in pixels) of
/// the base SVG group.  This function returns a mapping of logical picture 
/// units to pixels in the horizontal direction. 
ClientMethod getPelToPixelHRatio() [ Language = javascript ]
{
	// JMD1100
	if (this.viewBoxWidth == '' && this.viewBoxHeight == '') {
		return 1;
	}
	var physicalWidth = parseInt(this.svgGroup.getAttribute('width'),10);
	return(100/physicalWidth);
}

ClientMethod removeChildNodes(node) [ Language = javascript ]
{
	while(node.firstChild) {
		node.removeChild(node.firstChild);
	}
}

ClientMethod computeEffectiveExtents(x, y, w, h, angle) [ Language = javascript ]
{
	var rad = Math.PI*angle/180;
	var sin = Math.sin(rad);
	var cos = Math.cos(rad);
	var minX = x*cos - y*sin;
	var minY = x*sin + y*cos;
	var maxX = minX;
	var maxY = minY;

	var nX = x;
	var nY = y+h;
	var rX = nX*cos - nY*sin;
	if (rX<minX) minX=rX;
	if (rX>maxX) maxX=rX;
	var rY = nX*sin + nY*cos;
	if (rY<minY) minY=rY;
	if (rY>maxY) maxY=rY;

	var nX = x+w;
	var nY = y;
	var rX = nX*cos - nY*sin;
	if (rX<minX) minX=rX;
	if (rX>maxX) maxX=rX;
	var rY = nX*sin + nY*cos;
	if (rY<minY) minY=rY;
	if (rY>maxY) maxY=rY;

	var nX = x+w;
	var nY = y+h;
	var rX = nX*cos - nY*sin;
	if (rX<minX) minX=rX;
	if (rX>maxX) maxX=rX;
	var rY = nX*sin + nY*cos;
	if (rY<minY) minY=rY;
	if (rY>maxY) maxY=rY;

	var ex = {};
	ex.minX = minX;
	ex.minY = minY;
	ex.maxX = maxX;
	ex.maxY = maxY;
	ex.w=maxX-minX;
	ex.h=maxY-minY;
	return(ex);
}

/// Create a text node.
ClientMethod createSVGTextNode(caption, fontSize, autoScale, align, rotate, parentNode, txtClass, txtStyle) [ Language = javascript ]
{
var debug=false;

	// JMD1100 remove text scale, ignore autoScale!
	// change scaleX/Y to refer to chart scale
	var scaleX = this._scaleX;
	var scaleY = this._scaleY;
	var offsetAdj = 3;			// DTB197 - Pad size measurements to prevent collisions later on.

	var textGroup = this.document.createElementNS(SVGNS,"g");
	var text = this.document.createElementNS(SVGNS,"text");
if (debug) {
	var box = this.document.createElementNS(SVGNS,"rect");
	var bbox = this.document.createElementNS(SVGNS,"rect");
}
	text.setAttribute("font-size",fontSize);
	text.setAttribute("text-anchor",align);

	// JMD1182: apply style to get correct metrics
	if (txtClass) {
		text.setAttribute("class",txtClass);
	}
	if (txtStyle) {
		// text.setAttribute("style",txtStyle); // JSL4131 - txtStyle is an object, can't be used in setAttribute
		this.embedStyle(text,txtStyle);
	}

	text.setAttribute("x", 0);
	text.setAttribute("y", 0);
		
	var transform = ""
	if (rotate!=0) {
		transform = " rotate("+rotate+",0,0)";
		text.setAttribute("transform",transform);
	}

if (debug) {
box.setAttribute("transform",transform);
box.setAttribute("stroke","black");
box.setAttribute("stroke-width","1");
box.setAttribute("fill","none");

bbox.setAttribute("stroke","red");
bbox.setAttribute("stroke-width","1");
bbox.setAttribute("fill","yellow");
bbox.setAttribute("opacity",0.5);

}
	// create the text node and append it
	if (caption===null) caption='';
	var textNode = this.document.createTextNode(caption);
	text.appendChild(textNode);
	textGroup.appendChild(text);
if (debug) {
	textGroup.appendChild(box);
	textGroup.appendChild(bbox);
}
	if (parentNode) {
		parentNode.appendChild(textGroup);
		var txtBB = zenGetBBox(text);
		// DTB197 - Err on the side of providing more space
		var lH = (txtBB.height/scaleY)*1.1;
		var lW = (txtBB.width/scaleX)+offsetAdj;	
		
		var eH = lH;
		var eW = lW;
		
		var ex = null;
		// DTB197 - Err on the side of providing more space
		var yOfs = (txtBB.y/scaleY)*1.1;
		var xOfs = (txtBB.x/scaleX)+offsetAdj;
		if (rotate!=0) {
			// JMD1125 - apply scaling after computation
			ex = this.computeEffectiveExtents(txtBB.x,txtBB.y,txtBB.width,txtBB.height,rotate);
			eH = ex.h/scaleY;
			eW = ex.w/scaleX;
			yOfs = ex.minY/scaleY*1.1;
			xOfs = ex.minX/scaleX+offsetAdj;
		}
		
if (debug) {		
box.setAttribute("x", txtBB.x);
box.setAttribute("y", txtBB.y);
box.setAttribute("width", txtBB.width);
box.setAttribute("height", txtBB.height);

bbox.setAttribute("x",xOfs*scaleX);
bbox.setAttribute("y",yOfs*scaleY);
		
bbox.setAttribute("width",eW*scaleX);
bbox.setAttribute("height",eH*scaleY);
}
		text.setAttribute("logicalHeight",lH);
		text.setAttribute("logicalWidth",lW);
		textGroup.setAttribute("logicalHeight",lH);
		textGroup.setAttribute("logicalWidth",lW);

		text.setAttribute("effectiveHeight",eH);
		text.setAttribute("effectiveWidth",eW);
		textGroup.setAttribute("effectiveHeight",eH);
		textGroup.setAttribute("effectiveWidth",eW);

		text.setAttribute("xOffset",xOfs);
		text.setAttribute("yOffset",yOfs);
		textGroup.setAttribute("xOffset",xOfs);
		textGroup.setAttribute("yOffset",yOfs);
	}

	// return the outer group
	return(textGroup);
}

ClientMethod stripWhitespace(str) [ Language = javascript ]
{
	if (!str) return("");
	var w=str.split(' ');
	var start=0;
	while (start<w.length && !w[start]) start++;
	var end=w.length-1;
	while (end>start && !w[end]) end--;
	return(w.slice(start,end+1).join(''));
}

/// Integrate a new Style specification into an existing set of
/// name-value style pairs, adding and overwriting existing styles
/// as appropriate
ClientMethod integrateStyleSpec(styleNVP, newRule) [ Language = javascript ]
{
	var a = styleNVP.attr;
	var v = styleNVP.value;
	var items = newRule.toLowerCase().split(';'); // separate clauses
	for (var i=0;i<items.length;i++) {
		if (items[i]) {
			var pair = items[i].split(':');
			if (pair && pair.length==2) {
				newAttr = this.stripWhitespace(pair[0]);
				if (newAttr && newAttr.length>0) {
					// JMD1125 don't remove white space from attr
					// newVal = this.stripWhitespace(pair[1]);
					newVal = pair[1];
					for (var j=0;j<a.length;j++) {
						if (a[j]==newAttr) {
							v[j]=newVal;
							j=a.length;
						}
					}
					if (j==a.length) {
						a[j]=newAttr;
						v[j]=newVal;
					}
				}
			}
		}
	}
}

/// Compute and return the effective style that governs the rendering
/// of a given SVG element based on class and Id
ClientMethod computeStyle(className, idName) [ Language = javascript ]
{
	var classSelector = "."+className;
	var idSelector = "#"+idName;
	var s = {}
	s.attr = [];
	s.value = [];

	var ssa = document.styleSheets;
	var ssl = ssa.length;

	for(var si=0;si<ssl;si++) {
		var ss=ssa[si];
		var rA = null;

		if (ss.href!=null && ss.href.indexOf("://")>0) {
			if (ss.href.indexOf("http")!=0 && ss.href.indexOf("file")!=0) continue;
			if (window.location && ss.href.indexOf(window.location.host)<0) continue;
		}

		if (ss.cssRules) {
			rA = ss.cssRules;
		}
		else if (ss.rules) {
			rA = ss.rules;
		}
		else return(s);
		for (var ri=0; ri<rA.length;ri++) {
			var rule = rA[ri];
			if (rule.selectorText==classSelector) {
				this.integrateStyleSpec(s,rule.style.cssText);
			}
		}
		for (var ri=0; ri<rA.length;ri++) {
			var rule = rA[ri];
			if (rule.selectorText==idSelector) {
				this.integrateStyleSpec(ss,rule.style.cssText);
			}
		}
	}	
	return(s);
}

/// Embed the various settings of a computed style name-value object
/// as direct attributes of the given node.
ClientMethod embedStyle(element, styleNVP) [ Language = javascript ]
{
	var s = styleNVP;
	var styleString = '';
	for (var i=0;i<s.attr.length;i++) {
		var attr = s.attr[i];

		// JMD1125: font-family & others do not seem to work as attributes
		switch (attr) {
		case 'font-family':
			styleString += attr + ':' + s.value[i] + ';';
			break;
		case 'text-shadow':
			styleString += attr + ':' + s.value[i] + ';';
			break;
		default:
			element.setAttribute(attr,s.value[i]);
			styleString += attr + ':' + s.value[i] + ';';  // JSL4131
			break;
		}
	}
	if (styleString!='') {
		element.setAttribute('style',styleString);
	}
}

/// Given a resolved style name-value pairing object, return the specified font
/// size, if none has been specified, return one of three default values based on the 
/// value of the textSize property.
ClientMethod getComputedFontSize(styleNVP, defaultMedium, defaultSmall, defaultLarge) [ Language = javascript ]
{
		var s = styleNVP;
		var idx = -1;
		for (var i=0;i<s.attr.length;i++) {
			if (s.attr[i]=='font-size') {
				idx=i;
				i=s.length;
			}
		}
		var fSz = defaultMedium;
		if (idx<0) {
			if (this.textSize == 'large') fSz = defaultLarge;
			else if (this.textSize == 'small') fSz = defaultSmall;
			// JMD1100: if (!this.autoScaleText) fSz *= 4;
		}
		else {
			fSz = parseFloat(s.value[idx]);
			s.value[idx]=fSz;
		}
		return(fSz);
}

/// Draw the title for the chart. Return the height of the title.
ClientMethod renderTitle() [ Language = javascript ]
{
	this._titleHeight = 0;
	this._titleImageWidth = 0;
	this._titleImageTop = 0;
	this._titleImageLeft = 0;
	if (zenIsMissing(this.document)) return;

	var text;
	var chartTitleBox = this.findSVGElement('chartTitleBox'+this.currMultiple);
	if (null != chartTitleBox) {
		// DTB197 - remove old titleBox
		this.svgGroup.removeChild(chartTitleBox);
		chartTitleBox = null;
	}
	var chartTitle = this.findSVGElement('chartTitle'+this.currMultiple);
	if (null != chartTitle) {
		// remove old title
		this.svgGroup.removeChild(chartTitle);
		chartTitle = null;
	}
	var chartSubtitle = this.findSVGElement('chartSubtitle'+this.currMultiple);
	if (null != chartSubtitle) {
		// remove old subtitle
		this.svgGroup.removeChild(chartSubtitle);
		chartSubtitle = null;
	}

	var chartImage = this.findSVGElement('chartTitleImage'+this.currMultiple);
	if (null != chartImage) {
		// remove old image
		this.svgGroup.removeChild(chartImage);
		chartImage = null;
	}

	// rectangle under title (normally not shown)
	var trect = this.document.createElementNS(SVGNS,"rect");
	trect.setAttribute("class","chart-titleBox");
	trect.setAttribute("id",this.makeId('chartTitleBox'+this.currMultiple));
	trect.setAttribute("style",this.titleBoxStyle);
	this.svgGroup.appendChild(trect);

	var titleText = this.getChartTitle();
	var subtitleText = this.getChartSubtitle();
	var titleH = 0;
	var subtitleH = 0;

	// image & image size
	var imageLeft = 0;
	var imageTop = 0;
	var imageWidth = 0;
	var imageHeight = 0;

	// use absolute URL for to render properly for PDF export
	if (this.titleImage) {
		var currUrl = window.location.href.split("/");
		var imageURL = currUrl[0] + "//" + currUrl[2] + "/csp/sys/" + this.titleImage;
		var imageStyle = this.titleImageStyle;
	}

	if (imageURL) {
		imageWidth = 50;
		imageHeight = 50;
		if (imageStyle) {
			var t = imageStyle.toString().split(';');
			for (var ti = 0; ti < t.length; ti++) {
				var t2 = t[ti].toString().split(':');
				switch (t2[0]) {
				case 'left':
					imageLeft = parseInt(t2[1],10);
					break;
				case 'top':
					imageTop = parseInt(t2[1],10);
					break;
				case 'width':
					imageWidth = parseInt(t2[1],10);
					break;
				case 'height':
					imageHeight = parseInt(t2[1],10);
					break;
				}
			}
		}
		this._titleImageWidth = imageWidth / this._scaleX;
		this._titleImageTop = imageTop / this._scaleY;
		this._titleImageLeft = imageLeft / this._scaleX;
	}
	if (imageURL) {
		var image = this.document.createElementNS(SVGNS,'image');
		image.setAttribute("id",this.makeId('chartTitleImage'+this.currMultiple));
		image.setAttributeNS('http://www.w3.org/1999/xlink','xlink:href',imageURL);
		image.setAttribute('preserveAspectRatio','none');
		// move this in adjustTitle
		image.setAttribute('x',imageLeft);
		image.setAttribute('y',imageTop);
		image.setAttribute('width',imageWidth);
		image.setAttribute('height',imageHeight);
		this.svgGroup.appendChild(image);
	}

	if ('' != titleText) {
		var titleStyleObj = this.computeStyle('chart-title','chartTitle');
		var titleStyle = this.hasMultiples() ? (this.titleStyle+this.multipleTitleStyle) : this.titleStyle;
		if (titleStyle) this.integrateStyleSpec(titleStyleObj,titleStyle);
		
		var fSz = this.getComputedFontSize(titleStyleObj, 14, 8, 18);
		
		var anchor = ('left'==this.titleAlign) ? 'start' : ('right'==this.titleAlign) ? 'end' : 'middle';
		var text = this.createSVGTextNode(titleText,fSz,this.autoScaleText,anchor,0,this.svgGroup);
		text.setAttribute("id",this.makeId('chartTitle'+this.currMultiple));
		text.setAttribute("class","chart-title");

		this.embedStyle(text.firstChild,titleStyleObj);
		titleH = (parseFloat(text.getAttribute("logicalHeight"))* 1.2);
	}
	if ('' != subtitleText) {
		var subtitleStyleObj = this.computeStyle('chart-subtitle',null);
		var subtitleStyle = this.subtitleStyle;
		if (subtitleStyle) this.integrateStyleSpec(subtitleStyleObj,subtitleStyle);
		var fSz = this.getComputedFontSize(subtitleStyleObj, 9, 6, 12);

		var anchor = ('left'==this.titleAlign) ? 'start' : ('right'==this.titleAlign) ? 'end' : 'middle';
		var stext = this.createSVGTextNode(subtitleText,fSz,this.autoScaleText,anchor,0,this.svgGroup);
		stext.setAttribute("id",this.makeId('chartSubtitle'+this.currMultiple));
		stext.setAttribute("class","chart-subtitle");

		this.embedStyle(stext.firstChild,subtitleStyleObj);
		subtitleH = (parseFloat(stext.getAttribute("logicalHeight"))* 1.2);
	}

	// JMD1100 (2)
	this._titleHeight = parseFloat(titleH) + parseFloat(subtitleH);
	if (this._titleHeight < (imageHeight + imageTop)/this._scaleY) {
		this._titleHeight = (imageHeight + imageTop)/this._scaleY;
	}
}

/// Adjust position of chart title and legend (if needed).
ClientMethod adjustChartTitle() [ Language = javascript ]
{
	switch(this.titleAlign) {
	case 'left':
		var tx = ('' != this.titleX) ? this.xToLogical(this.titleX) : (8/this._scaleX + this._marginLeft + this._titleImageWidth + this._titleImageLeft);
		break;
	case 'right':
		var tx = ('' != this.titleX) ? this.xToLogical(this.titleX) : (this._plotLeft + this._rplotWidth - 8/this._scaleX);
		break;
	case 'center':
	default:
		var tx = ('' != this.titleX) ? this.xToLogical(this.titleX) : (this._plotLeft + this._rplotWidth / 2);
		break;
	}

	var ty = 0;
	var text = this.findSVGElement('chartTitle'+this.currMultiple);
	if (text) {
		var ty = ('' != this.titleY) ? this.yToLogical(this.titleY) : (text.getAttribute("logicalHeight")*1.2);
		text.setAttribute("transform","translate("+(tx*this._scaleX)+","+(ty*this._scaleY)+")");
	}

	var stext = this.findSVGElement('chartSubtitle'+this.currMultiple);
	if (stext) {
		var ty = ty + (('' != this.titleY) ? this.yToLogical(this.titleY) : (stext.getAttribute("logicalHeight")*1.2));
		stext.setAttribute("transform","translate("+(tx*this._scaleX)+","+(ty*this._scaleY)+")");
	}
	
	var trect = this.findSVGElement('chartTitleBox'+this.currMultiple);
	if (trect) {
		trect.setAttribute("x", this._plotLeft*this._scaleX);
		trect.setAttribute("y", 2);	// 2 pixels
		trect.setAttribute("width", this._rplotWidth*this._scaleX);
		trect.setAttribute("height",(this._marginTop*this._scaleY) - 4);
	}

	// JMD1072 Move title and box to front
	if (trect) {
		var parent = trect.parentNode;
		parent.removeChild(trect);
		parent.appendChild(trect);
	}
	if (text) {
		var parent = text.parentNode;
		parent.removeChild(text);
		parent.appendChild(text);
	}
	if (stext) {
		var parent = stext.parentNode;
		parent.removeChild(stext);
		parent.appendChild(stext);
	}
	var image = this.findSVGElement('chartTitleImage'+this.currMultiple);
	if (image) {
		image.setAttribute('x',(this._marginLeft+this._titleImageLeft) * this._scaleX);
		image.setAttribute('y',2 + this._titleImageTop * this._scaleY);
		var parent = image.parentNode;
		parent.removeChild(image);
		parent.appendChild(image);
	}


	// test legend
	var svgLegendGroup = this.findSVGElement('legendGroup');
	if (svgLegendGroup) {
		var lh = svgLegendGroup.getAttribute('height');
		if (lh > this._plotHeight) {
			svgLegendGroup.setAttribute('height',(this._plotHeight*this._scaleY));
		}
	}
}

/// Get title for the chart.
ClientMethod getChartTitle() [ Language = javascript ]
{
	var title = '';

	// for multiples, use series name
	if (this.hasMultiples()) {
		var snames = this.getSeriesNames();
		title = snames[this.currMultiple] ? snames[this.currMultiple] : '';
	}
	else {
		var controller = this.getController();
		if (controller && controller.getDataSourceCaption) {
			title = controller.getDataSourceCaption('title',this.title);
		}
		if (title==='') {
			title = this.title;
		}
	}
	return title;
}

/// Get subtitle for the chart.
ClientMethod getChartSubtitle() [ Language = javascript ]
{
	var title = '';
	var controller = this.getController();
	if (controller && controller.getDataSourceCaption) {
		title = controller.getDataSourceCaption('subtitle',this.subtitle);
	}
	if (title==='') {
		title = this.subtitle;
	}
	return title;
}

/// Draw the upper/lower bands for the chart.
ClientMethod renderBands() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;

	var text;
	var plotAreaGroup = this.findSVGElement('plotAreaGroup'+this.currMultiple);
	var virtualGroup = this.findSVGElement('virtualGroup'+this.currMultiple);
	zenASSERT(plotAreaGroup,'Unable to find plotAreaGroup',arguments);

	// create bands
	var bandUpper = this.findSVGElement('bandUpper'+this.currMultiple);
	var bandLower = this.findSVGElement('bandLower'+this.currMultiple);
	if (null == bandUpper) {
		bandUpper = this.document.createElementNS(SVGNS,"rect");
		bandUpper.setAttribute('id',this.makeId('bandUpper'+this.currMultiple));
		virtualGroup.appendChild(bandUpper);

		// default click handler: turn off selected item
		var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,null,null);');
		bandUpper.addEventListener('click',f,false);
	}
	if (null == bandLower) {
		bandLower = this.document.createElementNS(SVGNS,"rect");
		bandLower.setAttribute('id',this.makeId('bandLower'+this.currMultiple));
		virtualGroup.appendChild(bandLower);

		// default click handler: turn off selected item
		var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,null,null);');
		bandLower.addEventListener('click',f,false);
	}

	// JMD: bandUpper/Lower can be arrays or literals
	var sx = this.currMultiple=='' ? 0 : this.currMultiple;
	if (typeof this.bandUpper=='object' && this.bandUpper.length) {
		var bu = parseFloat(this.bandUpper[sx]);
	}
	else {
		var bu = parseFloat(this.bandUpper);
	}
	if (typeof this.bandLower=='object' && this.bandLower.length) {
		var bl = parseFloat(this.bandLower[sx]);
	}
	else {
		var bl = parseFloat(this.bandLower);
	}

	var hide = false;
	if (isNaN(bu)) {
		hide = true;
	}
	else if (this.chartPivot) {
		// JMD1130
		var w = this.getPlotX(bu) - this._plotLeft;
		if (w <= 0) {
			hide = true;
		}
		else {
			w = (w > this._plotWidth) ? this._plotWidth : w;
			bandUpper.setAttribute("class","chart-band");
			bandUpper.setAttribute("x",w*this._scaleX);
			bandUpper.setAttribute("y",this._plotTop*this._scaleY);
			bandUpper.setAttribute("height",this._plotHeight*this._scaleY);
			bandUpper.setAttribute("width",(this._plotWidth-w)*this._scaleX);
			bandUpper.setAttribute("style",this.bandUpperStyle);
		}
	}
	else {
		var h = this.getPlotY(bu,sx) - this._plotTop;
		if (h <= 0) {
			hide = true;
		}
		else {
			h = (h > this._plotHeight) ? this._plotHeight : h;
			bandUpper.setAttribute("class","chart-band");
			bandUpper.setAttribute("x",0*this._scaleX);
			bandUpper.setAttribute("y",this._plotTop*this._scaleY);
			bandUpper.setAttribute("width",this._plotWidth*this._scaleX);
			bandUpper.setAttribute("height",h*this._scaleY);
			bandUpper.setAttribute("style",this.bandUpperStyle);
		}
	}
	if (hide) {
 		bandUpper.setAttribute("display","none");
	}
	else {
 		bandUpper.setAttribute("display","inherit");
	}

	var hide = false;
	if (isNaN(bl)) {
		hide = true;
	}
	else if (this.chartPivot) {
		// JMD1130
		var w = this.getPlotX(bl) - this._plotLeft;
		if (w <= 0) {
			hide = true;
		}
		else {
			w = (w > this._plotWidth) ? this._plotWidth : w;
			bandLower.setAttribute("class","chart-band");
			bandLower.setAttribute("x",0*this._scaleX);
			bandLower.setAttribute("y",this._plotTop*this._scaleY);
			bandLower.setAttribute("height",this._plotHeight*this._scaleY);
			bandLower.setAttribute("width",w*this._scaleX);
			bandLower.setAttribute("style",this.bandLowerStyle);
		}
	}
	else {
		var h = this.getPlotY(bl,sx);
		if (h >= (this._plotTop+this._plotHeight)) {
			hide = true;
		}
		else {
			h = (h < this._plotTop) ? this._plotTop : h;
			bandLower.setAttribute("class","chart-band");
			bandLower.setAttribute("x",0*this._scaleX);
			bandLower.setAttribute("y",h*this._scaleY);
			bandLower.setAttribute("width",this._plotWidth*this._scaleX);
			bandLower.setAttribute("height",(this._plotHeight - h + this._plotTop)*this._scaleY);
			bandLower.setAttribute("style",this.bandLowerStyle);
		}
	}
	if (hide) {
 		bandLower.setAttribute("display","none");
	}
	else {
 		bandLower.setAttribute("display","inherit");
	}
	
	// JMD1130 baseLine
	var baseLine = this.findSVGElement('baseLine'+this.currMultiple);
	if (null == baseLine) {
		baseLine = this.document.createElementNS(SVGNS,"line");
		baseLine.setAttribute('id',this.makeId('baseLine'+this.currMultiple));
		virtualGroup.appendChild(baseLine);
	}

	var hide = false;
	if (this.chartPivot) {
		if (isNaN(parseFloat(this._xBaseValue))) {
			hide = true;
		}
		else {
			var w = this.getPlotX(this._xBaseValue) - this._plotLeft;
			if (w <= 0) {
				hide = true;
			}
			else {
				baseLine.setAttribute("class","chart-baseLine");
				baseLine.setAttribute("x1",w*this._scaleX);
				baseLine.setAttribute("y1",this._plotTop*this._scaleY);
				baseLine.setAttribute("y2",(this._plotTop+this._plotHeight)*this._scaleY);
				baseLine.setAttribute("x2",w*this._scaleX);
				baseLine.setAttribute("style",this.baseLineStyle);
			}
		}
	}
	else {
		if (isNaN(parseFloat(this._yBaseValue[0]))) {
			hide = true;
		}
		else {
			var h = this.getPlotY(this._yBaseValue[0],0);
			if (h <= 0) {
				hide = true;
			}
			else {
				baseLine.setAttribute("class","chart-baseLine");
				baseLine.setAttribute("x1",0*this._scaleX);
				baseLine.setAttribute("y1",h*this._scaleY);
				baseLine.setAttribute("x2",this._plotWidth*this._scaleX);
				baseLine.setAttribute("y2",h*this._scaleY);
				baseLine.setAttribute("style",this.baseLineStyle);
			}
		}
	}

	if (hide) {
 		baseLine.setAttribute("display","none");
	}
	else {
 		baseLine.setAttribute("display","inherit");
	}
	
	//					this._yBaseValue[yAxisNo] = 0;
}

/// Given a logical value, return the corresponding x-axis
/// coordinate.
ClientMethod getPlotX(val) [ Language = javascript ]
{
	var pct = 0;
	if (this._xRange != 0) {
		pct = (val - this._xMinValue) / this._xRange;
	}
	
	return this._plotLeft + (pct * this._plotWidth);
}

/// Given a logical value, return the corresponding y-axis
/// coordinate.
ClientMethod getPlotY(val, yAxisNo) [ Language = javascript ]
{
	var q = yAxisNo;
	// test every combination of undefined!
	yAxisNo = ('undefined' == typeof yAxisNo || isNaN(yAxisNo) || ''===yAxisNo) ? 0 : yAxisNo;
	var pct = 0;

	if (this._yRange[yAxisNo] != 0) {
		pct = (val - this._yMinValue[yAxisNo]) / this._yRange[yAxisNo];
	}
	return this._plotBottom - (pct * this._plotHeight);
}

/// Given a logical value, return the text to use for an axis label.
/// Subclasses can override this for custom behavior.
/// JSL4133 - pass an optional base we can add to val when label is null
ClientMethod getXLabelText(val, base, noformat) [ Language = javascript ]
{
	// JMD1263: if noformat try not to apply time formatting
	// this is used for finding ranges for time-based axes
	noformat = zenGet(noformat,false);

	if (zenIsMissing(base)) {
		base = 1;  // JSL4133 - avoid NAN and change the default to adding 1
	}

	var label = null;
	if ('category'==this._xGridType) {
		// see if we are connected to a dataSource
		var controller = this.getController();
		if (controller) {
			// use label from controller
			val = controller.getLabel(val,1,noformat);
		}
	}

	// test for callback
	if (''!=this.ongetLabelX) {
		label = zenInvokeCallbackMethod(this.ongetLabelX,this,'ongetLabelX','value',val);
	}

	if (label===null || (typeof label == 'undefined')) {
		// JMD1130
		if ('value'!=this._xGridType) {
			if (!controller && ''==this.ongetLabelX) { // JSL4156 - if label supplied by controller or ongetLabelX take it as is!!!
				label = val + base;
			} else {
				label = val;
			}
		}
		else {
			var xAxis = this.getXAxis();
			switch(xAxis?xAxis.axisType:'') {
			case 'percent':
				label = zenFormatNumber(val,"#.%");
				break;
			default:
				label = this.getNumericAbbreviation(val,this._xMinValue,this._xMaxValue);
				break;
			}
		}
	}

	var maxlen = parseInt(this.maxLabelLen,10);
	if (maxlen && label.toString().length > maxlen) {
		label = label.toString().substr(0,maxlen)+'...';
	}

	return label;
}

/// Given a logical value, return the text to use for an axis label.
/// base is an arbitrary delta but can be used to make labels 0-based or 1-based
/// default is 0-based for backwards compatibility
/// Can be overriden by user through sub-classing
ClientMethod getYLabelText(val, yAxisNo, base) [ Language = javascript ]
{
	var label = null;
	
	if (zenIsMissing(base)) {
		base = 1 // JSL4129, backwards compatibilty JSL4129 set it to 0, JSL4133, make everything 1-based when labels are not defined
	}

	yAxisNo = ('undefined' == typeof yAxisNo || isNaN(yAxisNo) || ''==yAxisNo) ? 0 : yAxisNo;
	if ('category'==this._yGridType || !this.hasAxes()) {
		// see if we are connected to a dataSource
		// (no axes means pie-type chart)
		var controller = this.getController();
		if (controller) {
			// use label from controller
			val = controller.getLabel(val,1);
		}	
	}

	// test for callback
	if (''!=this.ongetLabelY) {
		label = zenInvokeCallbackMethod(this.ongetLabelY,this,'ongetLabelY','value',val,'yAxisNo',yAxisNo);
	}
	if (label===null) {
		// JMD1130
		if (('value'!=this._yGridType)) {
			if (!controller && ''==this.ongetLabelY) { // JSL4156 - if label supplied by controller or ongetLabelY take it as is!!!
				label = val+base; // JSL4129 val+base instead of val
			} else {
				label = val;
			}
		}
		else {
			var yAxis = this.getYAxis(yAxisNo);
			switch(yAxis?yAxis.axisType:'') {
			case 'percent':
				label = zenFormatNumber(val,"#.%");
				break;
			default:
				if (this._yMinValue && this._yMaxValue) { // JSL4129 guard against null or undefined min and max values
					label = this.getNumericAbbreviation(val,this._yMinValue[yAxisNo],this._yMaxValue[yAxisNo]);
				} else {
					label = val + base; // JSL4129 if yMinValue, yMaxValue null or undefined, val + base
				}
				break;
			}
		}
	}

	var maxlen = parseInt(this.maxLabelLen,10);
	if (maxlen && label && label.toString().length > maxlen) { // JSL4129 guard against null label, even though in the above logic, it is ensured that label is never null!
		label = label.toString().substr(0,maxlen)+'...';
	}
	return label;
}

/// Convert a user-provided x-coordinate into 0-100 logical space.
/// This means: 10 returns 10, but "10px" is converted using the current width of the chart.  
ClientMethod xToLogical(val) [ Language = javascript ]
{
	return (''==val)?val:('string'==typeof val && val.indexOf('px')>0) ? parseFloat(val)/this._scaleX : parseFloat(val);
}

/// Convert a user-provided y-coordinate into 0-100 logical space.
/// This means: 10 returns 10, but "10px" is converted using the current height of the chart.  
ClientMethod yToLogical(val) [ Language = javascript ]
{
	return (''==val)?val:('string'==typeof val && val.indexOf('px')>0) ? parseFloat(val)/this._scaleY : parseFloat(val);
}

/// Return a numeric abbreviation for a value.
/// <var>min</var> and <var>max</var> are range that value falls within.
/// E.g., 10K for 10000
ClientMethod getNumericAbbreviation(val, min, max) [ Language = javascript ]
{
	var factor = 1;
	var maxVal = factor * max;
	var minVal = factor * min;
	var range = maxVal-minVal;

	var absmax = Math.abs(factor * max);
	var absmin = Math.abs(factor * min);
	var test = (absmax > absmin) ? absmax : absmin;
	
	// test for abbreviated labels
	if (test >= 600000000) {
		// billions
		val = Math.round(val / 10000000)/100 + ((val!=0)?$$$Text('G','%ZEN'):'');
	}
	else if (test >= 600000) {
		// millions
		val = Math.round(val / 10000)/100 + ((val!=0)?$$$Text('M','%ZEN'):'');
	}
	else if (test >= 10000) {
		// thousands
		val = Math.round(val / 10)/100 + ((val!=0)?$$$Text('K','%ZEN'):'');
	}
	else if (range >= 100) {  //SAM used to be test
		// no abbrev: round
		val = Math.round(val);
	}
	else {
		if (range>=10) {
			val = Math.round(val*10)/10;
			val = val.toFixed(1);
		}
		else if (range>=1) {
			val = Math.round(val*100)/100;
			val = val.toFixed(2);
		}			
		else {
		// small number, 3 decimal digits
			val = Math.round(val*1000)/1000;
			val = val.toFixed(3);
		}
	}
	return val;
}

/// Internal method: acquire data for this chart
/// and store a copy in a local cache.
ClientMethod acquireData() [ Internal, Language = javascript ]
{
	var controller = this.getController();
	if (null == controller) {
		// try to connect to dataController
		this.connectToController();
		controller = this.getController();
	}

	var seriesNumber = parseInt(this.seriesNumber);

	if (controller) {
		// get data from controller (make sure data is loaded)
		var dims = controller.getDimensions();

		// set data size based on controller
		this.seriesSize = controller.getDimSize(1);
		this.seriesCount = controller.getDimSize(2);

		// build arrays to hold local copy of data
		// get these arrays directly from the dataController
		this._dataSeries = controller.getDataAsArrays();
		if (null == this._dataSeries) {
			this._dataSeries = [];
			var size = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			for (var n = 0; n < size; n++) {
				this._dataSeries[n] = [];
			}
		}

		// compute series names (for pie-style charts)
		if (!this.hasAxes()) {
			var size = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			var snames = new Array();
			for (var n = 0; n < size; n++) {
				snames[n] = controller.getLabel(n,1);
			}
			this.seriesNames = snames.join(',');
		}
	}
	else {
		// get data from user callbacks
		var scount = this.getSeriesCount();
		this._dataSeries = new Array(scount);
		var sz = 0;
		for (var s = 0; s < scount; s++) {
			if (isNaN(seriesNumber) || (s==seriesNumber)) {
				this._dataSeries[s] = this.acquireSeriesData(s);
				// find longest series
				sz = (this._dataSeries[s].length > sz) ? this._dataSeries[s].length : sz;
			}
		}
		// JMD1314
		if (this.seriesSize==='') {
			this.seriesSize = sz;
		}
	}
}

/// Internal method: return (as an object) the minimum
/// and maximum data values for this chart. This is used
/// for ranges that are automatically calculated.
ClientMethod findDataRange(yAxisNo) [ Internal, Language = javascript ]
{
	// compute range for given y-axis
	// if yAxisNo is -1, then we are computed x axis values
	if (yAxisNo!=-1) {
		yAxisNo = ('undefined' == typeof yAxisNo || isNaN(yAxisNo) || ''===yAxisNo) ? this.getCurrYAxis() : yAxisNo;
	}

	var range = new Object();
	range.minValue = null;
	range.maxValue = null;
	range.minValue2 = null; // used by x/y type charts
	range.maxValue2 = null;
	
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();

	var	useSum = this.useSumForRange();
	if (useSum) {
		range.minValue = 0;
	}

	if (!this.usePercentForRange()) {
		// sum up each series
		var hasData = false;
		for (var n = 0; n < items; n++) {
			// JMD1125 track negative total separately
			var barTotal = null;
			var areaTotal = null;
			var barTotalNeg = null;
			var areaTotalNeg = null;
			for (var s = 0; s < scount; s++) {
				if ((yAxisNo==-1) || (this._yAxisForSeries[s] == yAxisNo)) {
					var group = this.getRangeGroupForSeries(s);
					var data = this._dataSeries[s];
					if (data) {
						hasData = true;
						var val = data[n];
						// JMD1314
						if ('object'==typeof val) {
							val = val.value;
						}
						if (!isNaN(parseFloat(val))) {
							if (group=='bar') {
								if (parseFloat(val)>=0) {
									barTotal += parseFloat(val);
								}
								else {
									barTotalNeg += parseFloat(val);
								}
							}
							else if (group=='area') {
								if (parseFloat(val)>=0) {
									areaTotal += parseFloat(val);
								}
								else {
									areaTotalNeg += parseFloat(val);
								}
							} else if (this.usePercentForRange()) {
							
							}
							else {
								val = parseFloat(val);
								range.minValue = (isNaN(range.minValue)) ? val : (val < range.minValue) ? val : range.minValue;
								range.maxValue = (isNaN(range.maxValue)) ? val : (val > range.maxValue) ? val : range.maxValue;
							}
						}
					}
				}
			}
			if (!isNaN(barTotal)) {
				range.minValue = (isNaN(range.minValue)) ? barTotal : (barTotal < range.minValue) ? barTotal : range.minValue;
				range.maxValue = (isNaN(range.maxValue)) ? barTotal : (barTotal > range.maxValue) ? barTotal : range.maxValue;
				if (useSum && barTotalNeg) {
					range.minValue = (barTotalNeg < range.minValue) ? barTotalNeg : range.minValue;
				}
			}
			if (!isNaN(areaTotal)) {
				range.minValue = (isNaN(range.minValue)) ? areaTotal : (areaTotal < range.minValue) ? areaTotal : range.minValue;
				range.maxValue = (isNaN(range.maxValue)) ? areaTotal : (areaTotal > range.maxValue) ? areaTotal : range.maxValue;
				if (useSum && barTotalNeg) {
					range.minValue = (areaTotalNeg < range.minValue) ? areaTotalNeg : range.minValue;
				}
			}
		}

		if (!hasData) {
			range.minValue = 0;
			range.maxValue = 0;
		}
	} else {
		// percentage bar chart
		range.minValue = 0;
		range.maxValue = 100;
	}
	return range;
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
/// Typically a chart will return true if it is in "stacked" mode.
ClientMethod useSumForRange() [ Language = javascript ]
{
	return false;
}

/// This method returns true if data series is a "percentage bar chart" and so
/// calculated data range should be 0 to 100%
ClientMethod usePercentForRange() [ Language = javascript ]
{
	return false;
}

/// Internal method: Go to external data source and
/// eturn an array containing data values for the
/// given series (0-based).
ClientMethod acquireSeriesData(series) [ Internal, Language = javascript ]
{
	var data = null;
	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber) && (series!=seriesNumber)) {
		return data;
	}

	// test for callback
	if (''!=this.ongetData) {
		data = zenInvokeCallbackMethod(this.ongetData,this,'ongetData','series',series);
		if (null != data) {
			return data;
		}
	}

	// default data
	var data = new Array(this.seriesSize);
	for (var i = 0; i < this.seriesSize; i++) {
		data[i] = 0;
	}
	return data;
}

/// Return data values for the given series (0-based)
/// from the chart's data cache.
ClientMethod getSeriesData(series) [ Language = javascript ]
{
	//zenASSERT(this._dataSeries,'Chart data cache is missing',arguments);
	//zenASSERT(this._dataSeries[series],'Chart data series is missing: '+series,arguments);
	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber) && (series!=seriesNumber)) {
		return null;
	}

	return this._dataSeries ? this._dataSeries[series] : null;
}

/// Return the number of data series for this chart.
ClientMethod getSeriesCount() [ Language = javascript ]
{
	return this.seriesCount;
}

/// Return an array containing the names of the data series for this chart.<br/>
/// If a name is missing, the series number is used.<br/>
/// If the chart is connected to a data controller, get the names from the controller.
ClientMethod getSeriesNames() [ Language = javascript ]
{
	var names = new Array(this.seriesCount);
	var controller = this.getController();
	if (controller) {
		for (i = 0; i < this.getSeriesNamesSize(); i++) {
			names[i] = controller.getLabel(i,2);
		}
	}
	else {	
		var sn = this.seriesNames.split(',');
		for (i = 0; i < this.getSeriesNamesSize(); i++) {
			names[i] = (null == sn[i] || '' == sn[i]) ? (parseInt(i,10)+1) : sn[i];
		}
	}
	
	return names;
}

/// Return an array of labels to display within the Legend box.<br/>
/// Default implementation is to return a list of series names.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	return this.getSeriesNames();
}

/// Return the marker type that should be used for the given series.
ClientMethod getMarkerShape(series) [ Language = javascript ]
{
	var mk = this.markerShapes.split(',');
	if (mk.length == 0) {
		return 'circle';
	}
	return (''==mk[series%mk.length] ? 'circle' : mk[series%mk.length]);
}

/// Return an array of color values for given data series color scheme.
ClientMethod getColorSchemeArray(scheme) [ Language = javascript ]
{
	var colors;

	switch(scheme) {
	case 'bright':
		colors = ['url(#shade-blue)','url(#shade-green)','url(#shade-red)','url(#shade-yellow)','url(#shade-purple)','url(#shade-orange)','url(#shade-teal)'];
		break;
	case 'glow':
		colors = ['url(#glow-blueDiag)','url(#glow-greenDiag)','url(#glow-redDiag)','url(#glow-yellowDiag)','url(#glow-purpleDiag)','url(#glow-orangeDiag)','url(#glow-tealDiag)'];
		break;
	case 'gray':
		colors = ['#F0F0F0','#C0C0C0','#A0A0A0','#808080','#606060','#D0D0D0','#B0B0B0','#909090'];
		break;
	case 'pastel':
		colors = ['#5F9EA0','#E9967A','#EEE8AA','#98FB98','#DDA0DD','#8FBC8F','#FFE4B5','#EE82EE'];
		break;
	case 'urban':
		colors = ['rgb(71,89,104)','rgb(169,141,109)','rgb(156,152,142)','rgb(91,89,83)','rgb(43,59,64)','rgb(71,89,83)','rgb(127,136,126)','rgb(192,204,173)'];
		break;
	case 'tuscan':
		colors = ['rgb(231,192,80)','rgb(210,156,80)','rgb(56,85,47)','rgb(56,57,45)','rgb(55,42,15)','rgb(164,57,39)','rgb(190,226,250)','rgb(226,226,199)'];
		break;
	case 'caribbean':
		colors = ['rgb(0,167,153)','rgb(0,220,216)','rgb(0,185,255)','rgb(0,91,102)','rgb(0,80,35)','rgb(127,166,69)','rgb(255,245,199)','rgb(230,199,145)'];
		break;
	case 'rustbelt':
		colors = ['rgb(156,51,11)','rgb(110,11,0)','rgb(41,41,42)','rgb(62,49,46)','rgb(109,109,111)','rgb(156,157,156)','rgb(208,208,207)'];
		break;
	case 'solid':
	default:
		colors = ['blue','green','red','yellow','purple','orange','teal'];
		break;
	}
	return colors;
}

/// Return the CSS color that should be used for the given series.
ClientMethod getSeriesColor(series) [ Language = javascript ]
{
	// JMD1258 check for callback
	if (''!=this.ongetSeriesColor) {
		var sclr = zenInvokeCallbackMethod(this.ongetSeriesColor,this,'ongetSeriesColor','series',series);
		if (sclr) {
			return sclr;
		}
	}

	var clr = this._seriesColors;
	if (clr==null || clr.length == 0) {
		return 'black';
	}
	return (''==clr[series%clr.length] ? 'black' : clr[series%clr.length]);
}

/// Return the number of items within each data series
/// (this assumes that all data series have the same number of items).
ClientMethod getSeriesSize() [ Language = javascript ]
{
	return this.seriesSize;
}

/// Returns if there is a current selected element.
ClientMethod hasSelectedItem() [ Language = javascript ]
{
	return (parseInt(this.selectedSeries,10)>=0 && parseInt(this.selectedItem,10)>=0);
}

/// Return any additional select/unselect style to apply to a chart element.
ClientMethod getSelectedStyle(series, item, isMarker) [ Language = javascript ]
{
	isMarker = zenGet(isMarker,false);
	var selStyle = ''
	if (this.hasSelectedItem()) {
		if (series == this.selectedSeries && (('undefined'==typeof item) || item == this.selectedItem)) {
			selStyle = this.selectedItemStyle;
		}
		else if ('2D' == this.appearance) {
			selStyle = this.unselectedItemStyle;
			if (isMarker) {
				// make sure unselected markers look alright
				selStyle += 'opacity:1.0;stroke-opacity:0.6;';
			}
		}
	}
	
	// JMD1130 no fill for selected lines in combo (unless there are markers)
	var stype = this.getSeriesType(series);
	if (stype == 'line' && !this.markersVisible) {
		selStyle += 'fill:none;';
	}
	return selStyle;
}

/// Returns index number (0-based) of the data series of the
/// current selected item, or -1 if there is no current selection.
ClientMethod getSelectedSeries() [ Language = javascript ]
{
	return this.selectedSeries;
}

/// Returns index number (0-based) of the
/// current selected item, or -1 if there is no current selection.
ClientMethod getSelectedItem() [ Language = javascript ]
{
	return this.selectedItem;
}

/// Create a plot marker.
/// This may be used by subclasses to display markers.
/// type can be 'up','down','circle','square'.
ClientMethod createMarker(series, item, x, y, color, type, noevents) [ Language = javascript ]
{
	var marker;
	var markerSize = 10;	// pixels
	if (this._scaleX < 2) {
		// small markers
		markerSize = 5;
	}

	// create marker element
	switch (type) {
	case 'square':
		marker = this.document.createElementNS(SVGNS,"rect");
		marker.setAttribute("x",-(markerSize*0.8)/2);
		marker.setAttribute("y",-(markerSize*0.8)/2);
		marker.setAttribute("width",(markerSize*0.8));
		marker.setAttribute("height",(markerSize*0.8));
		break;
	case 'circle':
		marker = this.document.createElementNS(SVGNS,"circle");
		marker.setAttribute("cx",0);
		marker.setAttribute("cy",0);
		marker.setAttribute("r",markerSize/2);
		break;
	case 'down':
		marker = this.document.createElementNS(SVGNS,"polyline");
		var pts = [-markerSize/2,-markerSize/2, markerSize/2,-markerSize/2, 0,markerSize/2, -markerSize/2,-markerSize/2];
		marker.setAttribute("points",pts.join(','));
		break;
	case 'up':
	default:
		marker = this.document.createElementNS(SVGNS,"polyline");
		var pts = [-markerSize/2,markerSize/2, markerSize/2,markerSize/2, 0,-markerSize/2, -markerSize/2,markerSize/2];
		marker.setAttribute("points",pts.join(','));
		break;
	}

	var scale = '';
	if ('' != this.markerScale) {
		 scale = "scale("+this.markerScale+","+this.markerScale+")"; 
	}

	marker.setAttribute("transform","translate("+(x*this._scaleX)+","+(y*this._scaleY)+")" + scale);

	// indicate that this is a marker so that we can apply different highlighting when selected
	marker.setAttribute("isMarker",true);

	marker.setAttribute("class","chart-seriesMarker");
	marker.setAttribute("stroke",color);
	marker.setAttribute("style",this.markerStyle + (series>=0?this.getSelectedStyle(series,item,true):''));

	if (!noevents) {
		marker.setAttribute('id',this.makeId('el'+this.currMultiple+'_' + series + '_' + item));

		// chartElementClickHandler
		var sno = this.currMultiple=='' ? series : this.currMultiple;
		var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+sno+','+item+');');
		marker.addEventListener('click',f,false);
	}
	return marker;
}

/// Select the specified chart element.
ClientMethod selectElement(series, item) [ Language = javascript ]
{
	// JMD1100 Update all chart elements
	if (this.selectedSeries != series || this.selectedItem != item) {
		series = parseInt(series,10);
		item = parseInt(item,10);

		this.selectedSeries = series;
		this.selectedItem = item;

		var scount = this.getSeriesCount();
		var icount = this.getSeriesSize();

		// JMD1314: move/hide indicator
		// JMD1422: deal with multiples
		if (this.showMultiples) {
			for (var s = 0; s < scount; s++) {
				this.currMultiple = s;
				this.updateIndicator();
			}
			this.currMultiple = '';
		}
		else {
			this.updateIndicator();
		}

		for (var s = 0; s < scount; s++) {
			for (var i = 0; i < icount; i++) {
				var el = this.getChartElement(s,i);
				if (el) {
					var isMarker = el.getAttribute('isMarker');
					var style = this.getChartElementStyle(s,i)+this.getSelectedStyle(s,i,isMarker);
					el.setAttribute('style',style);
					var rel = this.getChartRelatedElements(s,i);
					if (rel && rel.length) {
						//+  JSL4137
						var relStyle = this.getRelatedElementStyle(s,i);
						if (relStyle) {
							style = relStyle;
						}
						//- JSL4137
						for (var n = 0; n < rel.length; n++) { 
							rel[n].setAttribute('style',style);
						}
					}
				}
			}
		}
	}
}

/// Return the svg group element that contains the data series elements.
ClientMethod getSeriesSVGGroup() [ Language = javascript ]
{
	return this.findSVGElement('seriesGroup'+this.currMultiple);
}

/// Return the svg object for a specified data element (if any).
ClientMethod getChartElement(series, item) [ Language = javascript ]
{
	return this.findSVGElement('el_' + series + '_' + item);
}

/// Return an array of related svg objects for a specified data element (if any).
/// (such as the edges of a 3d rendering).
ClientMethod getChartRelatedElements(series, item) [ Language = javascript ]
{
	return null;
}

/// Return default style for the specified data element (if any).
/// This is used to restore styles when chart elements are unselected.
/// Subclasses can override this.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	return this.markerStyle;
}

/// Mouse click handler for chart elements.
/// Subclasses can use this method to associated click events
/// with chart elements.
ClientMethod chartElementClickHandler(evt, series, item) [ Language = javascript ]
{
	evt.stopPropagation();
	if (this._tooltip) {
		this.hideToolTip();
	}
	this.selectElement(series!==null?series:-1,item!==null?item:-1);
	zenInvokeCallbackMethod(this.onelementClick,this,'onelementClick','chart',this);
}

/// Mouse over handler for chart elements.
/// This takes care of tooltips.
ClientMethod chartElementMouseOver(evt, series, item) [ Internal, Language = javascript ]
{
	evt.stopPropagation();

	if (this._timerId) {
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}

	// show tip after 1 second
	this._mouseOverSeries = series;
	this._mouseOverItem = item;

	// JMD1090 IE8 correction
	this._clientX = evt.clientX;
	this._clientY = evt.clientY;
	this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").showToolTip()",500);
}

/// Mouse out handler for chart elements.
ClientMethod chartElementMouseOut(evt, series, item) [ Internal, Language = javascript ]
{
	evt.stopPropagation();
	// JMD1090 ignore unless user has moved mouse
	if (this._clientX != evt.clientX && this._clientY != evt.clientY) {
		if (this._timerId) {
			window.clearTimeout(this._timerId);
			delete this._timerId;
		}
		if (this._tooltip) {
			this.hideToolTip();
		}
	}
}

/// Create a tooltip for the current chart item.
ClientMethod showToolTip() [ Internal, Language = javascript ]
{
	if (this._tooltip) return;
	if (null == this._mouseOverSeries || null == this._mouseOverItem) return;
	var captions = [];
	var values = [];
	this.getToolTipInfo(this._mouseOverSeries, this._mouseOverItem,captions,values);

	// invoke callback
	if (this.onshowTooltip!='') {
		// stash arrays for callback
		this._tooltipCaptions = captions;
		this._tooltipValues = values;
		zenInvokeCallbackMethod(this.onshowTooltip,this,'onshowTooltip','chart',this);
		this._tooltipCaptions = null;
		this._tooltipValues = null;
	}

	if (captions.length == 0 || values.length == 0) return;

	this.setDimToolTip(captions, values, this._clientX, this._clientY, false);
	try {
		//this.svgGroup.appendChild(this._tooltip); // JSL4484
	} catch(ex) {
	}
	this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").revealToolTip()",20);
}

ClientMethod setDimToolTip(captions, values, x, y, final) [ Language = javascript ]
{

	// + WAL103 -- x can be negative when the tooltip is very long
	//             in this case, set x to 0 so that the left side (labels)
	//             will be included on the chart and only the end of the value
	//             on the right will be truncated
	if (x<0) x=0;
	// - WAL103

	// highlight for chart element
	var style = 'stroke-opacity:0.5;stroke:darkblue;stroke-width:3;';
	var sno = isNaN(parseInt(this.seriesNumber)) ? this._mouseOverSeries : 0;
	var el = this.getChartElement(this._mouseOverSeries, this._mouseOverItem);
	if (el) {
		el.setAttribute('style',this.getChartElementStyle(sno, this._mouseOverItem) + this.getSelectedStyle(sno, this._mouseOverItem) + style);
	}
	var rel = this.getChartRelatedElements(this._mouseOverSeries, this._mouseOverItem);
	if (rel && rel.length) {
		for (var n = 0; n < rel.length; n++) {
			rel[n].setAttribute('style',this.getChartElementStyle(sno, this._mouseOverItem) + style);
		}
	}

	// we call this method recursively to find the right values of x and y and create the tooltip, remove tooltip if necessary
	try {
		if (this._tooltip != null) {
			this.svgGroup.removeChild(this._tooltip);
		}
	} catch(err) {
	}

	if (final == true) {
		// delete what we've created - it's no good
		try {
			this.svgGroup.removeChild(this._tooltip);
		} catch (ex) {
		}
	}
	ttGroup = this.document.createElementNS(SVGNS,"svg");
	this.svgGroup.appendChild(ttGroup); 
	
	//ttGroup.setAttribute("x",5*this._scaleX);
	//ttGroup.setAttribute("y",5*this._scaleY);
	ttGroup.setAttribute("x",x); // JSL4484
	ttGroup.setAttribute("y",y); // JSL4484

	// fade in
	this._tooltipAnimate = 1;
	this._tooltip = ttGroup;
	this._tooltip.setAttribute("opacity",0);

	// tooltip background
	var brect = this.document.createElementNS(SVGNS,"rect");
	brect.setAttribute("class",'chart-tooltipRect');
    if (!zenIsMissing(this.tooltipRectStyle)) {
 		brect.setAttribute("style", this.tooltipRectStyle);
    }
	brect.setAttribute("x",1);
	brect.setAttribute("y",1);
	brect.setAttribute("rx",4);
	brect.setAttribute("width",25*this._scaleX - 2);
	brect.setAttribute("height",10*this._scaleY - 2);
	ttGroup.appendChild(brect);

	// shadow
	// JMD1171 -- filters are broken in recent firefoxen
	var who=navigator.userAgent;
	if (who.indexOf("Firefox")>=0) {
		brect.setAttribute("style",'stroke:3px;');
	}
	else {
		ttGroup.setAttribute("style","filter: url(#dropShadow);");
	}

	// text
	var labelText = new Array();
	var labelValue = new Array();
	
	var tx = 0;
	var ty = 1;
	var lwid = 0;
	var vwid = 0;
	var fSz = 12;
	for (var n = 0; n < captions.length; n++) {
		var val = values[n];
		if ((null != val) && ('' != val)) {
			var tg = this.createSVGTextNode(captions[n],fSz,false,"end",0,ttGroup);
			labelText[n] = tg.firstChild;
			labelText[n].setAttribute("class","chart-tooltipCaption");

			var tsz = labelText[n].getComputedTextLength() / this._scaleX;
			lwid = (lwid > tsz) ? lwid : tsz;

			var tg = this.createSVGTextNode(val,fSz,false,"start",0,ttGroup);
			labelValue[n] = tg.firstChild;
			labelValue[n].setAttribute("class","chart-tooltipValue");
			var textNode = this.document.createTextNode(val);
			var vsz = labelValue[n].getComputedTextLength() / this._scaleX;
			vwid = (vwid > vsz) ? vwid : vsz;

			var th = (zenGetBBox(labelValue[n]).height * 1.2) / this._scaleY;
			
			ty += th;
			labelText[n].setAttribute("y",ty*this._scaleY);
			labelValue[n].setAttribute("y",ty*this._scaleY);
		}
	}

	brect.setAttribute("height",((ty*this.getPelToPixelVRatio()) + 2)*this._scaleY);
	brect.setAttribute("width",(((lwid + vwid)*this.getPelToPixelVRatio()) + 10)*this._scaleX);

	for (var n = 0; n < captions.length; n++) {
		if (labelText[n] && labelValue[n]) {
			labelText[n].setAttribute("x",(1 + lwid)*this._scaleX);
			labelValue[n].setAttribute("x",(3 + lwid)*this._scaleX);
		}
	}
	
	//+ JSL4484
	var height = parseFloat(brect.getAttribute("height"));
	var width = parseFloat(brect.getAttribute("width"));

	var plotRect = this.findSVGElement('plotArea'+this.currMultiple);
	var noPlotRect = 0;
	if (plotRect == null) {
		noPlotRect = 1;
		var scaleX = this._scaleX;
		var scaleY = this._scaleY;
		plotRect = this.document.createElementNS(SVGNS,"rect");;
		plotRect.setAttribute("class","chart-plotArea");
		plotRect.setAttribute("style",this.plotAreaStyle);
		plotRect.setAttribute("x",this._plotLeft*scaleX);
		plotRect.setAttribute("y",this._plotTop*scaleY);
		plotRect.setAttribute("width",this._rplotWidth*scaleX);
		plotRect.setAttribute("height",this._plotHeight*scaleY);

	}
	var plotRectWidth = parseFloat(plotRect.getAttribute('width'));
	var plotRectHeight = parseFloat(plotRect.getAttribute('height'));
	var xPlotRect = parseFloat(plotRect.getAttribute('x'));
	var yPlotRect = parseFloat(plotRect.getAttribute('y'));
	if (final == false) {
	
		if (x + width > xPlotRect + plotRectWidth ) {		
			this.setDimToolTip(captions, values, xPlotRect + (plotRectWidth - width), y, true);
			x = xPlotRect + (plotRectWidth - width);
		}
		if (y + height > yPlotRect + plotRectHeight) {
			this.setDimToolTip(captions, values, x, yPlotRect +(plotRectHeight-height), true);
		}
	}
	if (noPlotRect) {
		delete plotRect; 
	}
	//- JSL4484
}

/// Fade in tooltip.
ClientMethod revealToolTip() [ Internal, Language = javascript ]
{
	if (this._tooltip) {
		this._tooltipAnimate = this._tooltipAnimate * 0.95;
		var opacity = 1-this._tooltipAnimate;
		opacity = (opacity>0.99) ? 1 : opacity;
		this._tooltip.setAttribute("opacity",opacity);

		if (opacity < 1) {
			this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").revealToolTip()",5);
		}
	}
}

/// Remove the current tool tip.
ClientMethod hideToolTip() [ Internal, Language = javascript ]
{
	if (this._tooltip) {
		if (null != this._mouseOverSeries && null != this._mouseOverItem) {
			var sno = isNaN(parseInt(this.seriesNumber)) ? this._mouseOverSeries : 0;
			var el = this.getChartElement(this._mouseOverSeries, this._mouseOverItem);
			if (el) {
				el.setAttribute('style',this.getChartElementStyle(sno, this._mouseOverItem) + this.getSelectedStyle(this._mouseOverSeries,this._mouseOverItem));
			}
			var rel = this.getChartRelatedElements(this._mouseOverSeries, this._mouseOverItem);
			if (rel && rel.length) {
				for (var n = 0; n < rel.length; n++) {
					var style=this.getRelatedElementStyle(sno, this._mouseOverItem); // JSL4137
					if (!style) { // JSL4137
						style=this.getChartElementStyle(sno, this._mouseOverItem)
					}
					rel[n].setAttribute('style',style);
				}
			}
		}
		try {
			this.svgGroup.removeChild(this._tooltip);
		} catch(err) {
		}
	}
	delete this._tooltip;
}

/// Return an object containing tooltip information for the given element.
ClientMethod getToolTipInfo(series, item, captions, values) [ Internal, Language = javascript ]
{
	var controller = this.getController();
	var oldmax = this.maxLabelLen;
	this.maxLabelLen = 0;
	
	// + WAL102 -- try to determine if this is a %DeepSee.Component.pivotTable and whether it can provide special info
	var isPivotTable = false;
	if (controller && ('%DeepSee.Component.pivotTable'==zenGet(controller._serverClass))) {
		// DTB627 - Check the actual dataSource type before switching to use callGetItemSpec
		var dataSourceType = controller.dataSourceName.split('.')[controller.dataSourceName.split('.').length-1];
		isPivotTable = ('pivot'==dataSourceType);
		if (isPivotTable) {
			var labelInfo = new zenProxy();
			controller.callGetItemSpec(labelInfo,item+1,series+1);
		}
	}
	// - WAL102
	
	// item
	if (this.getSeriesSize() >= 1) {
		var name = '';
		var yAxisNo = this.getCurrYAxis();
		if (controller && controller.getDimName) {
			// WAL102 -- this should only apply to %DeepSee.Component.pivotTable type controllers      
			if (isPivotTable) {
				name = labelInfo.rowCaption;
			}
			else {
				name = controller.getDimName(0);
			}
			// - WAL102
		}
		captions[captions.length] = (''==name) ? !this.usePercentForRange() ? $$$Text('Item') : 'Series' : name;
		// JSL4133 - increment by 1
		if (null != this.chartPivot) {
			values[values.length] = this.chartPivot ? this.getYLabelText(!this.usePercentForRange() ? item : series,yAxisNo,1) : this.getXLabelText(!this.usePercentForRange() ? item : series,1);
		}
		else {
			values[values.length] = this.getYLabelText(!this.usePercentForRange() ? item : series,'',1);
		}
	}

	// series
	if (this.getSeriesCount() >= 1) {
		var name = '';
		// + WAL102
		if (controller && controller.getDimName) {
			if (isPivotTable) {
				name = labelInfo.colCaption;
			}
			else {
				name = controller.getDimName(1);
			}
		}
		// - WAL102
		captions[captions.length] = (''==name) ? !this.usePercentForRange() ? 'Series' : $$$Text('Item') : name;

		var names = (!this.usePercentForRange()) ? this.getSeriesNames() :  this.getLegendLabels(); // JSL4130 - for series use getSeriesName
		values[values.length] = names[!this.usePercentForRange() ? series : item];
	}

	// filters
	if (controller && controller.getFilterInfo) {
		var fnames = new Array();
		var fvalues = new Array();
		controller.getFilterInfo(fnames,fvalues);
		for (var n = 0; n < fnames.length; n++) {
			captions[captions.length] = fnames[n];
			values[values.length] = fvalues[n];
		}
	}

	// + WAL102 -- value handles the measures case
	// value
	if (isPivotTable) {
		captions[captions.length] = labelInfo.measure;
	}
	else if (controller && controller.getValueName) {
		captions[captions.length] = controller.getValueName();
	}
	else {
		captions[captions.length] = 'Value';
	}
	// - WAL102
	var data = this.getSeriesData(series);
	if (data && null != data[item]) {
		var val = data[item];
		// JMD1314
		if ('object'==typeof val) {
			val = val.value;
		}		
		if (!isNaN(parseFloat(val))) {
			// + WAL122 -- give the pivot table a chance to format the number
			//             with the format string if available
			if (isPivotTable && (this.valueLabelFormat=='')) { // WAL122 (2) -- check for existing value label format
				var formattedVal = new zenProxy();
				controller.callFormatValue(val, formattedVal, item+1, series+1);
				if (formattedVal.formatted==1) {
					val = formattedVal.value;
				}
				else {
					if (parseFloat(val)!=parseInt(val)) {
						val = this.formatNumeric(parseFloat(val).toFixed(2));
					}
					else {
						val = this.formatNumeric(parseInt(val));
					}	
				}
			}
			else {
				if (parseFloat(val)!=parseInt(val)) {
					val = this.formatNumeric(parseFloat(val).toFixed(2));
				}
				else {
					val = this.formatNumeric(parseInt(val));
				}
			}
			// - WAL122
		}
		values[values.length] = val;
	}
	else {
		values[values.length] = '';
	}
	
	// + WAL118 -- trim the measures from the row/column caption if necessary
	if (isPivotTable) {
		values = controller.removeMeasureLabels(values,labelInfo.measure);	
	}
	// - WAL118

	this.maxLabelLen = oldmax;
}

/// Notification that the dataController associated with this dataView
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
		// another ie workaround-- this one for deepsee
		if (zenPage._containerClosing) {
			delete zenPage._containerClosing;
			break;
		}
	case 'modelChange':
		// some change in dataController
		this.scrollLeft = 0;
		this.hzZoomStep = 0;
		this.updateChart();
		break;
	case 'beginWait':
		if (this.beginWaitState) {
			this.beginWaitState();
		}
		break;
	case 'endWait':
		if (this.endWaitState) {
			this.endWaitState();
		}
		break;
	case 'seriesChange':
		break;
	case 'chartUpdate':
		break;
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value1, value2) [ Language = javascript ]
{
	// JMD1371: don't let argument value change!
	var value = value1;
	switch(property) {
	case 'backgroundStyle':
		var attrs = this.parseStyleSVG(this.backgroundStyle); // JSL4483
		if (zenGet(attrs['opacity']) == '') {                 // JSL4483
			attrs['opacity'] = 1.0;                           // JSL4483
		}                                                     // JSL4483
		this.setSeeThrough(attrs['opacity']);                 // JSL4483
		if (this[property]!=value) {
			this.backgroundStyle = value;
			var rect = this.findSVGElement('background');
			if (rect) {
				rect.setAttribute("style",this.backgroundStyle);
			}
		}
		break;
	case 'plotAreaStyle':
		var attrs = this.parseStyleSVG(this.plotAreaStyle);
		if (zenGet(attrs['opacity']) == '') {
			attrs['opacity'] = 1.0;
		}
		this.setSeeThrough(attrs['opacity'])
		if (this[property]!=value) {
			this.plotAreaStyle = value;
			if (this.showMultiples) {
				this.render();
			}
			else {
				var rect = this.findSVGElement('plotArea');
				if (rect) {
					rect.setAttribute("style",this.plotAreaStyle);
				}
				else {
					this.render();
				}
			}
		}
		break;
	case 'bandUpperStyle':
		if (this[property]!=value) {
			this.bandUpperStyle = value;
			if (this.showMultiples) {
				this.render();
			}
			else {
				var rect = this.findSVGElement('bandUpper');
				if (rect) {
					rect.setAttribute("style",this.bandUpperStyle);
				}
			}
		}
		break;
	case 'bandLowerStyle':
		if (this[property]!=value) {
			this.bandLowerStyle = value;
			if (this.showMultiples) {
				this.render();
			}
			else {
				var rect = this.findSVGElement('bandLower');
				if (rect) {
					rect.setAttribute("style",this.bandLowerStyle);
				}
			}
		}
		break;

	case 'marginTop':
	case 'marginLeft':
	case 'marginBottom':
	case 'marginRight':
		if (this[property]!==value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'bandUpper':
	case 'bandLower':
	case 'markerScale':
		value = (value==='') ? '' : parseFloat(value);
		if (this[property]!==value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'lineStyle':
	case 'markerStyle':
	case 'indicatorStyle':
	case 'plotStyle':
	case 'plotEdgeStyle':
	case 'markerStyle':
	case 'markerShapes':
	case 'seriesColorScheme':
	case 'seriesColors':
	case 'seriesColorsOverride':
	case 'seriesNames':
	case 'seriesNumber':
	case 'seriesYAxes':
	case 'startTime':
	case 'endTime':
	case 'titleImage':
	case 'titleImageStyle':
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'seriesCount':
	case 'seriesSize':
		value = (value=='') ? '' : parseInt(value,10);
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'title':
	case 'titleStyle':
	case 'titleAlign':
	case 'subtitle':
	case 'subtitleStyle':
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;
	case 'msgIfNoData': // JSL4478
	case 'warnIfNoData': // JSL4478
	case 'noDataOpacity': // JSL4478
	case 'noDataFill': // JSL4478
	case 'noDataStroke': // JSL4478
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;
	case 'gridStyle':
	case 'borderStyle':
	case 'axisTitleStyle':
	case 'labelStyle':
	case 'legendStyle':
	case 'legendLabelStyle':
	case 'legendRectStyle':
	case 'selectedItemStyle':
	case 'unselectedItemStyle':
	case 'axisLineStyle':
	case 'baseLineStyle':
	case 'ongetData':
	case 'ongetLabelX':
	case 'ongetLabelY':
	case 'onrenderData':
	case 'onrenderPlotArea':
	case 'onshowTooltip':
	case 'stripeStyle':
	case 'textSize':
	case 'scrollButtonStyle':
	case 'autoScaleText':
	case 'valueLabelStyle':
	case 'valueLabelFormat':
	case 'valueBoxStyle':
	case 'legendTitle':
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'titleX':
	case 'titleY':
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'borderRadius':
	case 'borderOffset':
	case 'currYAxis':
	case 'maxLabelLen':
		value = parseInt(value,10);
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'legendX':
	case 'legendY':
	case 'legendWidth':
	case 'legendHeight':
		if (this[property]!=value) {
			this[property] = value;
			this.render();
		}
		break;

	case 'legendVisible':
		value = (value === true) ? 'true' : value;
		value = (false === true) ? 'false' : value;
		if (this[property]!=value) {
			this[property] = value;
			this.unrender();
			this.render();
		}
		break;

	case 'appearance':
	case 'titleBoxStyle':
		if (this[property] != value) {
			this[property] = value;
			this.unrender();
			this.render();
		}
		break;

	case 'stripesVisible':
	case 'showMultiples':
	case 'labelsVisible':
	case 'markersVisible':
	case 'indicatorsVisible':
	case 'valueLabelsVisible':
	case 'plotToEdge':
	case 'timeBased':
		value = value ? true : false;
		if (value != this[property]) {
			this[property] = value;
			this.unrender();
			this.render();
		}
		break;

	case 'hasZoom':
		// JMD1130
		value = value ? true : false;
		if (value != this[property]) {
			// reset
			this.hzZoomStep = 0;
			this[property] = value;
			this.unrender();
			this.render();
		}
		break;

	case 'controllerId':
		// pass this change on to dataView
		this.setControllerId(value);
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Notification that this component has been resized.
ClientMethod setSizeHandler() [ Language = javascript ]
{
	// re-render so that font-sizes can be adjusted
	this.render();
}

/// Format numeric value.
ClientMethod formatNumeric(nStr) [ Language = javascript ]
{
	// JSL4282 - allow for percentage axis type
	if (zenIsMissing(this.valueLabelFormat)) {
		var yAxisNo = this.getCurrYAxis();
		var yAxis = this.getYAxis(yAxisNo);
		switch(yAxis?yAxis.axisType:'') {
		case 'percent':
			nStr = 100*nStr; // convert to a percentage
			nStr += '%'; // convert to a string and a add percentage sign
			break;
		default:
			nStr += ''; // convert to a string
			break;
		}
	} else {
		// JSL4282 - use valueLabelFormat		
		if (!isNaN(parseFloat(nStr))) {
			nStr = zenFormatNumber(nStr,this.valueLabelFormat);
			nStr += ''; // convert to a string
		} else {
			nStr += ''; // convert to a string (whatever it is)
		}
		
	}
	x = nStr.split('.');
	x1 = x[0];
	x2 = x.length > 1 ? '.' + x[1] : '';
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(x1)) {
		x1 = x1.replace(rgx, '$1' + ',' + '$2');
	}
	return x1 + x2;
}

/// Indicate which "group" should be used for computing axis ranges.
/// This is overridden by combo charts.
ClientMethod getRangeGroupForSeries(series) [ Language = javascript ]
{
	// bar means, add up as stacked bar; otherwise compute independently.
	return this.useSumForRange() ? 'bar' : 'none';
}

/// Draw a line for one data series, <var>s</var> (0-based).
/// <var>data</var> contains the data for all series as an array of arrays.
ClientMethod plotLineForSeries(group, s, data, stacked, chartFilled, markersVisible, hasEvents) [ Language = javascript ]
{
	// see if there is a selected element
	var hasSelect = this.hasSelectedItem();
	var seriesNumber = parseInt(this.seriesNumber);

	// JMD1208
	var multipleOffset = (this.currMultiple?this.currMultiple:0);

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	var items = this.getSeriesSize();
	var color = this.getSeriesColor(s+multipleOffset);
	var marker = 'circle';
	if (markersVisible) {
		marker = this.getMarkerShape(s+multipleOffset);
	}

	var poly = this.document.createElementNS(SVGNS,"path");
	poly.setAttribute("class","chart-seriesLine");
	var path = ''; // path for this line
	poly.setAttribute("fill",'none');
	if (!hasEvents) {
		// special case for background area
		poly.setAttribute("fill-opacity",'0.25');
	}
	group.appendChild(poly);

	// special fill for background "area" plot.
	var fillToEdge = !hasEvents && chartFilled && !this.plotToEdge;

	// y-axis
	var yAxisNo = this._yAxisForSeries[s+multipleOffset];

	// JMD1130 pt2
	var timeBased = this.isTimeBased();

	if (!this.chartPivot) {
		// normal orientation
		var dx, adj;
		if (timeBased) {
			// JMD1130 pt2: set these to 0
			dx = 0;
			adj = 0;
		}
		else if (this.plotToEdge) {
			dx = (items<=1) ? (this._plotWidth/2) : (this._plotWidth / (items-1));
			adj = (items<=1) ? 0 : dx;
		}
		else {
			dx = (items<=1) ? (this._plotWidth/2) : (this._plotWidth / items);
			adj = (items<=1) ? 0 : dx/2;
		}

		var x = 0;
		var base = 0;
		if (chartFilled) {
			if (isNaN(parseFloat(this._yBaseValue[yAxisNo]))) {
				base = this._plotHeight;
			}
			else {
				base = this.getPlotY(this._yBaseValue[yAxisNo],yAxisNo) - this._plotTop;
			}
		}

		if (chartFilled) {
			if (fillToEdge) {
				path = 'M ' + (x*scaleX) + ' ' + (base*scaleY) + ' ';
			}
			else {
				path = 'M ' + ((x+dx-adj)*scaleX) + ' ' + (base*scaleY) + ' ';
			}
			firstPoint = false;
		}
		else {
			firstPoint = true;
		}

		for (var n = 0; n < items; n++) {
			// JMD1100
			if (timeBased) {
				// JMD1314: check for time in data element
				if (data[s] && data[s][n] && 'object'==typeof data[s][n] && data[s][n].time) {
					var time = data[s][n].time;
				}
				else {
					var time = this.getXLabelText(n,1,true);
				}
				x = this.getTimeX(time);
				x = x===null ? 0 : x;
				// test if visible
				// JMD1314 (skip non-visible items only if there are a lot of items)
				if ((items>200) && (x < -0.0001 || x > 100.0001)) {
					continue;
				}
			}
			else {
				x += dx;
			}

			// JMD1314
			// get this, prior, and next value
			if (data[s]) {
				var ic = data[s].length;
				var val = data[s][n];
				val = (val!==null && 'object'==typeof val) ? val.value : val;
				var nextVal = data[s][n+1];
				nextVal = (nextVal!==null && 'object'==typeof nextVal) ? nextVal.value : nextVal;
				var priorVal = (n>0) ? data[s][n-1] : null;
				priorVal = (priorVal!==null && 'object'==typeof priorVal) ? priorVal.value : priorVal;

				nextMissing = (n == ic-1) ? false : ((null == nextVal) || ('number' != typeof nextVal && '' == nextVal) || (isNaN(nextVal)));
				nextMissing = (ic == 1) ? true : nextMissing;

				prevMissing = (n == 0) ? false : ((null == priorVal) || ('number' != typeof priorVal && '' == priorVal) || (isNaN(priorVal)));
				missing = (null == val) || ('number' != typeof val && '' == val) || (isNaN(val));
				val = (null == val) ? 0 : val;
				val = isNaN(val) ? 0 : val;
			}
			else {
				val = 0;
				missing = false;
				nextMissing = false;
				prevMissing = false;
			}

			/* JMD1125
			if (stacked && val < 0) {
				// only positive values make sense for stacked charts
				val = 0;
			}
			*/
			var isNeg = (val<0);
			if (stacked && s > 0) {
				var dval = 0;
				for (q = 0; q < s; q++) {
					var v = (null == data[q]) ? 0 : ((null == data[q][n]) ? 0 : data[q][n]);
					v = ('object'==typeof v) ? parseFloat(v.value) : parseFloat(v);
					if ((isNeg && v < 0)||(!isNeg && v > 0)) {
						dval += v;
					}
				}
				val += dval;
			}
			y = this.getPlotY(val,yAxisNo) - this._plotTop;
			if (missing) {
				// skip; place a marker for this point
				firstPoint = true;
			}
			else {
				if (fillToEdge && n==0) {
					path += 'L ' + (0*scaleX) + ' ' + (y*scaleY) + ' ';
				}
				if (firstPoint && chartFilled) {
					path += 'M ' + ((x-adj)*scaleX) + ' ' + (base*scaleY) + ' ';
					firstPoint = false;
				}
				path += (firstPoint ? 'M ' : 'L ') + ((x-adj)*scaleX) + ' ' + (y*scaleY) + ' ';
				firstPoint = false;

				if ((markersVisible || nextMissing || prevMissing)) {
					var mk = this.createMarker(s,n,(x-adj),y,color,marker);
					group.appendChild(mk);
					if (!markersVisible) {
						mk.setAttribute('fill',color);
					}
					if (hasEvents) {
						// mouseover/out handlers
						var sno = isNaN(seriesNumber) ? s : this.seriesNumber;
						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+sno+','+n+');');
						mk.addEventListener('mouseover',f,false);

						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+sno+','+n+');');
						mk.addEventListener('mouseout',f,false);
					}
				}
				if (chartFilled && (nextMissing || n == items-1)) {
					if (fillToEdge) {
						path += (x*scaleX) + " " + (y*scaleY) + " ";
						path += (x*scaleX) + " " + (base*scaleY) + " z";
					}
					else {
						path += ((x-adj)*scaleX) + " " + (base*scaleY) + " z";
					}
				}
			}
		}
	}
	else {
		// pivotted
		// normal orientation
		var dy, adj;
		if (this.plotToEdge) {
			dy = (items<=1) ? this._plotHeight : (this._plotHeight / (items-1));
			adj = dy;
		}
		else {
			dy = this._plotHeight / items;
			adj = (dy/2);
		}

		var y = 0;
		var base = 0;
		if (chartFilled) {
			if (isNaN(parseFloat(this._xBaseValue))) {
				base = 0;
			}
			else {
				base = this.getPlotX(this._xBaseValue) - this._plotLeft;
			}
		}

		if (chartFilled) {
			if (fillToEdge) {
				path = 'M ' + (base*scaleX) + ' ' + (y*scaleY) + ' ';
			}
			else {
				path = 'M ' + (base*scaleX) + ' ' + ((y+dy-adj)*scaleY) + ' ';
			}
			firstPoint = false;
		}
		else {
			firstPoint = true;
		}

		for (var n = 0; n < items; n++) {
			// JMD1314
			// get this, prior, and next value
			if (data[s]) {
				var ic = data[s].length;
				var val = data[s][n];
				val = (val!==null && 'object'==typeof val) ? val.value : val;
				var nextVal = data[s][n+1];
				nextVal = (nextVal!==null && 'object'==typeof nextVal) ? nextVal.value : nextVal;
				var priorVal = (n>0) ? data[s][n-1] : null;
				priorVal = (priorVal!==null && 'object'==typeof priorVal) ? priorVal.value : priorVal;

				nextMissing = (n == ic-1) ? false : ((null == nextVal) || ('number' != typeof nextVal && '' == nextVal) || (isNaN(nextVal)));
				nextMissing = (ic == 1) ? true : nextMissing;

				prevMissing = (n == 0) ? false : ((null == priorVal) || ('number' != typeof priorVal && '' == priorVal) || (isNaN(priorVal)));
				missing = (null == val) || ('number' != typeof val && '' == val) || (isNaN(val));
				val = (null == val) ? 0 : val;
				val = isNaN(val) ? 0 : val;
			}
			else {
				val = 0;
				missing = false;
				nextMissing = false;
				prevMissing = false;
			}

			if (stacked && val < 0) {
				// only positive values make sense for stacked charts
				val = 0;
			}
			if (stacked && s > 0) {
				var dval = 0;
				for (q = 0; q < s; q++) {
					var v = (null == data[q]) ? 0 : ((null == data[q][n]) ? 0 : parseFloat(data[q][n]));
					dval += ((v > 0) ? v : 0);
				}
				val += dval;
			}
			y += dy;
			x = this.getPlotX(val) - this._plotLeft;

			if (missing) {
				// skip
				firstPoint = true;
			}
			else {
				if (fillToEdge && n==0) {
					path += 'L ' + (x*scaleX) + ' ' + (0*scaleY) + ' ';
				}
				if (firstPoint && chartFilled) {
					path += 'M ' + (base*scaleX) + ' ' + ((y - adj)*scaleY) + ' ';
					firstPoint = false;
				}
				path += (firstPoint ? 'M ' : 'L ') + (x*scaleX) + ' ' + ((y - adj)*scaleY) + ' ';
				firstPoint = false;
				if (markersVisible || nextMissing || prevMissing) {
					var mk = this.createMarker(s,n,x,y-adj,color,marker);
					group.appendChild(mk);
					if (!markersVisible) {
						mk.setAttribute('fill',color);
					}
					if (hasEvents) {
						// mouseover/out handlers
						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+s+','+n+');');
						mk.addEventListener('mouseover',f,false);

						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+s+','+n+');');
						mk.addEventListener('mouseout',f,false);
					}
				}
				if (chartFilled && (nextMissing || n == items-1)) {
					if (fillToEdge) {
						path += (x*scaleX) + " " + (y*scaleY) + " ";
						path += (base*scaleX) + " " + (y*scaleY) + " z";
					}
					else {
						path += (base*scaleX) + " " + ((y-adj)*scaleY) + " z";
					}
				}

			}
		}
	}

	if (path) {
		poly.setAttribute("d",path);
		poly.setAttribute("stroke",color);
		poly.setAttribute("fill",chartFilled ? color : 'none');
	}
	else {
		poly.setAttribute("stroke",'none');
	}

	// JMD1100 (2) if there are markers, don't select line
	if (hasEvents && !markersVisible) {
		// don't fill selected line
		// JMD1100 use lineStyle for non-filled line
		poly.setAttribute("style",this.lineStyle + this.getSelectedStyle(s) + (chartFilled?'':'fill:none;')); // JSL4176, use this.lineStyle instead of plotStyle for filled line charts - area charts

		// chartElementClickHandler
		var sno = isNaN(seriesNumber) ? s : this.seriesNumber;
		if (this.hasMultiples()) {
			sno = this.currMultiple;
		}
		var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+sno+',0);');
		poly.addEventListener('click',f,false);
		poly.setAttribute('id',this.makeId('el'+this.currMultiple+'_' + sno + '_' + 0));
	}
	else {
		// JMD1125: make sure line style is used
		// PFS100 - When markers exist, do not apply selected style to line
		poly.setAttribute("style",this.lineStyle + (chartFilled?'':'fill:none;'));
	}
}

/// Return the type (how a series should be displayed) for the given data series (0-based).
/// This is used by combo chart and ignored by all others.
ClientMethod getSeriesType(series) [ Language = javascript ]
{
	return '';
}

/// Return the index (0-based) of the y-axis associated with the given data series.
/// It may return -1 if the chart is not rendered yet.
ClientMethod getYAxisIndexForSeries(series) [ Language = javascript ]
{
	if (this._yAxisForSeries && null!==this._yAxisForSeries[series]) {
		return this._yAxisForSeries[series];
	}
	// not defined yet!
	return -1;
}

/// Indicates that this chart supports and is in "show multiples" mode.
/// A subclass may override this.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return false;
}

/// Compute scaling information for a time-based x-axis.
ClientMethod computeXAxisTimeLine() [ Language = javascript ]
{
	// JMD1100
	// find time scale to display
	var startTime = this.getStartTime();
	var endTime = this.getEndTime();

	var startDate = zenStringToDate(startTime);
	var endDate = zenStringToDate(endTime);

	// JMD1130(3) test for hours/minutes
	var hms = startTime.toString().split(' ')[1];
	if (hms) {
		var t = hms.split(':');
		if (t[0]) {	startDate.setHours(parseInt(t[0],10));}
		if (t[1]) {	startDate.setMinutes(parseInt(t[1],10));}
		if (t[2]) {	startDate.setSeconds(parseInt(t[2]),10);}
	}
	var hms = endTime.toString().split(' ')[1];
	if (hms) {
		var t = hms.split(':');
		if (t[0]) {	endDate.setHours(parseInt(t[0],10));}
		if (t[1]) {	endDate.setMinutes(parseInt(t[1],10));}
		if (t[2]) {	endDate.setSeconds(parseInt(t[2],10));}
	}

	// get span of timeline in seconds
	var spanSecs = (endDate - startDate)/1000;
	// pick major units based on delta
	var majorUnits = 'years';
	var minorUnits = 'quarters';
	var startUnits = 0;
	var endUnits = 0;

	if (spanSecs > (31536000*20)) {
		majorUnits = 'decades';
		minorUnits = 'years';
		startUnits = Math.floor((startDate.getFullYear() - 1900) / 10);
		endUnits = Math.floor((endDate.getFullYear() - 1900) / 10);
	}
	else if (spanSecs > (31536000*4)) {
		majorUnits = 'years';
		minorUnits = 'quarters';
		startUnits = startDate.getFullYear() - 1900;
		endUnits = endDate.getFullYear() - 1900;
	}
	else if (spanSecs > (31536000*2)) {
		majorUnits = 'years';
		minorUnits = 'months';
		startUnits = startDate.getFullYear() - 1900;
		endUnits = endDate.getFullYear() - 1900;
	}
	else if (spanSecs > (31536000)) {
		majorUnits = 'quarters';
		minorUnits = 'months';
		startUnits = ((startDate.getFullYear()-1900)*4) + Math.floor(startDate.getMonth()/3);
		endUnits = ((endDate.getFullYear()-1900)*4) + Math.floor(endDate.getMonth()/3);
	}
	else if (spanSecs > (24 * 3600 * 15)) {
		majorUnits = 'months';
		minorUnits = 'days';
		startUnits = ((startDate.getFullYear()-1900)*12) + Math.floor(startDate.getMonth());
		endUnits = ((endDate.getFullYear()-1900)*12) + Math.floor(endDate.getMonth());
	}
	else if (spanSecs > (24*60*60)) {
		majorUnits = 'days';
		minorUnits = 'hours';

		// days since 1900
		startUnits = (startDate - this._date1900)/(24*60*60*1000);
		endUnits = (endDate - this._date1900)/(24*60*60*1000);
	}
	else if (spanSecs > (60*60)) {
		majorUnits = 'hours';
		minorUnits = 'minutes';

		// hours since 1900
		startUnits = (startDate - this._date1900)/(60*60*1000);
		endUnits = (endDate - this._date1900)/(60*60*1000);
	}
	else {
		majorUnits = 'minutes';
		minorUnits = 'seconds';

		// minutes since 1900
		startUnits = (startDate - this._date1900)/(60*1000);
		endUnits = (endDate - this._date1900)/(60*1000);
	}

	// tick marks
	var plotWidth = this._rplotWidth;

	// find (virtual) pixels/sec
	this._pixPerSec = spanSecs>0 ? (plotWidth/spanSecs) : 0;

	// find scroll offset
	var offset = (startDate)/1000;
	this._offset = offset;

	this._startUnits = startUnits;
	this._endUnits = endUnits;
	this._majorUnits = majorUnits;
	this._minorUnits = minorUnits;
}

/// Render x-axis labels and tick marks for time-based x-axis.
ClientMethod renderXAxisTimeLine(timeCellGroup, y) [ Language = javascript ]
{
	var majorHeight = 3;
	var minorHeight = 1;
	var minorHeight2 = 1.5;

	var scaleX = this._scaleX;
	var scaleY = this._scaleY;

	// tick marks
	var plotWidth = this._rplotWidth;

	var offset = this._offset;
	var startUnits = this._startUnits;
	var endUnits = this._endUnits;
	var majorUnits = this._majorUnits;
	var minorUnits = this._minorUnits;

	// plot
	var d = '';
	var dMinor = '';
	if (plotWidth>0) {
		// time bar
		var lastLabelX = 0;
		for (var cell = startUnits; cell <= endUnits; cell++) {
			var info = this.getCellInfo(cell,majorUnits,minorUnits,cell-startUnits);
			var x = (this._pixPerSec * (info.startSecs-offset));

			d += ' M ' + x*scaleX + ' ' + this._plotTop*scaleY + ' L ' + x*scaleX + ' ' + this._plotBottom*scaleY;

			// Major tick
			var tick = this.document.createElementNS(SVGNS,'line');
			tick.setAttribute('class','chart-majorTick');
			tick.setAttribute('x1',x*scaleX);
			tick.setAttribute('x2',x*scaleX);
			tick.setAttribute('y1',y*scaleY);
			if ((lastLabelX==0)||(lastLabelX<x)) {
				tick.setAttribute('y2',(y+majorHeight)*scaleY);
			}
			else {
				tick.setAttribute('y2',(y+minorHeight)*scaleY);
			}
			timeCellGroup.appendChild(tick);

			// label
			if ('' != info.caption && ((lastLabelX==0)||(lastLabelX<x))) {
				var tStyle = this.computeStyle('chart-xLabel',null);
				if (this._xLabelStyle) this.integrateStyleSpec(tStyle,this._xLabelStyle);
				var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);

				// Create and add a new scaled text node
				var text = this.createSVGTextNode(info.caption,fSz,this.autoScaleText,"start",0,timeCellGroup);
				text.setAttribute("class","chart-xLabel");
				this.embedStyle(text.firstChild,tStyle);
				var h = 1.1*parseFloat(text.getAttribute("effectiveHeight"));
				lastLabelX = x + parseFloat(text.getAttribute("effectiveWidth"));
				text.setAttribute("transform","translate("+((x+0.2)*scaleX)+","+((y+h)*scaleY)+")");
			}

			// JMD1166: skip based on gap between minor units
			var deltaPix = scaleX * (info.minorTicks[1] - info.minorTicks[0]) * this._pixPerSec;
			var freq = (deltaPix<=4) ? 3 : 1;
			for (var j = 0; j < info.minorTicks.length; j++) {
				if ((j-freq)%freq==0) {
					var xm = (this._pixPerSec * (info.minorTicks[j]-offset));
					var tick = this.document.createElementNS(SVGNS,'line');
					tick.setAttribute('class','chart-minorTick');
					tick.setAttribute('x1',xm*scaleX);
					tick.setAttribute('x2',xm*scaleX);
					tick.setAttribute('y1',y*scaleY);
					if (majorUnits=='months' && j%5==0) {
						// JMD1130 pt2
						tick.setAttribute('y2',(y+minorHeight2)*scaleY);
					}
					else {
						tick.setAttribute('y2',(y+minorHeight)*scaleY);
					}
					timeCellGroup.appendChild(tick);

					if (this._xMinorGrid) {
						dMinor += ' M ' + xm*scaleX + ' ' + this._plotTop*scaleY + ' L ' + xm*scaleX + ' ' + this._plotBottom*scaleY;
					}
				}
			}
		}
	}

	// x minor grid path
	var xgrid = this.findSVGElement('xGridLineMinor'+this.currMultiple);
	if (xgrid) {
		if (this._xMinorGrid && dMinor) {
			xgrid.setAttribute("d",dMinor);
			xgrid.setAttribute("visibility","visible");
		}
		else {
			xgrid.setAttribute("visibility","hidden");
		}
	}

	// x major grid path
	var xgrid = this.findSVGElement('xGridLine'+this.currMultiple);
	if (xgrid) {
		if (this._xMajorGrid && d) {
			xgrid.setAttribute("d",d);
			xgrid.setAttribute("visibility","visible");
		}
		else {
			xgrid.setAttribute("visibility","hidden");
		}
	}
}

/// For a given time value, YYYY-MM-DD, find the corresponding x coordinate in virtual pixels.
ClientMethod getTimeX(time) [ Language = javascript ]
{
	var x = null;
	if (this._pixPerSec) {
		var d = zenStringToDate(time);
		if (d) {
			// JMD1130(3) test for hours/minutes
			var hms = time.toString().split(' ')[1];
			if (hms) {
				var t = hms.split(':');
				if (t[0]) {	d.setHours(parseInt(t[0],10));}
				if (t[1]) {	d.setMinutes(parseInt(t[1],10));}
				if (t[2]) {	d.setSeconds(parseInt(t[2],10));}
			}

			var startSecs = d.getTime()/1000;
			// JMD1130 pt2: remove _plotLeft
			x = (this._pixPerSec * (startSecs-this._offset));
		}
	}
	return x;
}

/// Return information about a cell within a time line grid.
ClientMethod getCellInfo(cell, majorUnits, minorUnits, index) [ Internal, Language = javascript ]
{
	var caption = '';		// caption for cell
	var startSecs = 0;		// number of secs at start of cell

	// minor ticks is an array of starting seconds
	var minorTicks = [];

	switch(majorUnits) {
	case 'decades':
		var year = (parseInt(cell,10)*10) + 1900;
		caption = year;
		var d = new Date(year,0,1,0,0,0,0);
		startSecs = d.getTime()/1000;

		switch(minorUnits) {
		default:
		case 'years':
			for (var n = 1; n <= 9; n++) {
				var dt = new Date(year+n,0,1,0,0,0,0);
				minorTicks[minorTicks.length] = dt.getTime()/1000;
			}
			break;
		}
		break;

	case 'years':
		var year = parseInt(cell,10) + 1900;
		caption = year;
		var d = new Date(year,0,1,0,0,0,0);
		startSecs = d.getTime()/1000;

		switch(minorUnits) {
		default:
		case 'quarters':
			for (var n = 1; n <= 3; n++) {
				var dt = new Date(year,n*3,1,0,0,0,0);
				minorTicks[minorTicks.length] = dt.getTime()/1000;
			}
			break;
		case 'months':
			for (var n = 1; n <= 11; n++) {
				var dt = new Date(year,n,1,0,0,0,0);
				minorTicks[minorTicks.length] = dt.getTime()/1000;
			}
			break;
		}
		break;
	case 'quarters':
		var year = parseInt(Math.floor(cell/4),10) + 1900;
		caption = 'Q' + (cell%4+1);
		if ((cell%4==0)||index==0) {
			caption += ('-' + year);
		}
		var d = new Date(year,(cell%4)*3,1,0,0,0,0);
		startSecs = d.getTime()/1000;
		// months
		for (var n = 1; n <= 2; n++) {
			var dt = new Date(year,((cell%4)*3)+n,1,0,0,0,0);
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	case 'months':
		var year = parseInt(Math.floor(cell/12),10) + 1900;
		caption = _zenResource['zenMonthShortNames'].split(',')[(cell%12)];
		if ((cell%12==0)||(index<=1)) {
		 	caption += ('-' + (year));
		}
		var d = new Date(year,(cell%12),1,0,0,0,0);
		startSecs = d.getTime()/1000;
		var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
		if ((year%4==0) && !(year%100==0 && year%400!=0)) {
			daysInMonth[1] = 29;
		} 

		// days
		for (var n = 1; n <= daysInMonth[cell%12]; n++) {
			var dt = new Date(year,(cell%12),n,0,0,0,0);
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	case 'days':
		var d = new Date(1900,0,1,0,0,0,0);
		d.setDate(this._date1900.getDate() + Math.floor(cell));
		startSecs = d.getTime()/1000;
		if (this.dateFormat) {
			caption = zenDateToString(d,false,this.dateFormat);
		}
		else {
			var months = _zenResource['zenMonthShortNames'].split(',');
			caption = months[d.getMonth()] + ' ' + d.getDate();
		}

		// hours
		for (var n = 1; n < 24; n+=1) {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(d.getTime() + (n*3600*1000));
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	case 'hours':
		var d = new Date(1900,0,1,0,0,0,0);
		d.setHours(this._date1900.getHours() + Math.floor(cell));
		startSecs = d.getTime()/1000;
		caption = zenDateToString(d,true,this.dateFormat);
		caption = caption.split(' ')[1];	// time only
		caption = caption.split(':');
		caption.length = 2;
		caption = caption.join(':');

		// 10 minutes
		for (var n = 1; n < 6; n+=1) {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(d.getTime() + ((n*10)*60*1000));
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;

	case 'minutes':
		var d = new Date(1900,0,1,0,0,0,0);
		d.setMinutes(this._date1900.getMinutes() + Math.floor(cell));
		
		startSecs = d.getTime()/1000;
		caption = zenDateToString(d,true,this.dateFormat);
		caption = caption.split(' ')[1];	// time only
		caption = caption.split(':');
		caption.length = 2;
		caption = caption.join(':');

		// 15 secs
		for (var n = 1; n < 4; n+=1) {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(d.getTime() + ((n*15)*1000));
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	}
	return { caption:caption, startSecs:startSecs, minorTicks:minorTicks  };
}

/// Set the timeline start and end dates and update the chart.
/// If <var>endTime</var> is not provided, update it to preserve the current time range using
/// <var>startTime</var> as a new starting time.<br/>
/// Time values are in 'yyyy-mm-dd' format.
/// This prevents the repaint that would happen if start and end dates are set separately.
ClientMethod setTimeRange(startTime, endTime, final) [ Language = javascript ]
{
	final = 'undefined' == typeof final ? true : final;
	if (!endTime) {
		// year only?
		startTime = startTime ? (parseInt(startTime)==startTime?startTime+'-01-01':startTime) : startTime;
		var endTime = this.endTime;
		endTime = endTime ? (parseInt(endTime)==endTime?endTime+'-12-31':endTime) : endTime;

		var startDate = zenStringToDate(startTime);
		var endDate = zenStringToDate(endTime);
		startDate = startDate ? startDate : new Date(2000,0,1,0,0,0,0);
		endDate = endDate ? endDate : new Date(startDate.getFullYear(),11,31,0,0,0,0);
		var delta = endDate-startDate;
		startDate.setTime(startDate.getTime()+delta);
		endTime = zenDateToString(startDate);
	}

	this.startTime = startTime;
	this.endTime = endTime;

	// update plot and axis
	if (this.showMultiples) {
		if (final) {
			this.render();
		}
	}
	else {
		this.renderPlotArea();
		this.renderSeriesGroup();
	}
}

/// Internal utility method. Return the xml version of a given zen object.
/// Add any properties in the <var>add</var> list.
/// Skip any properties in the <var>skip</var> list.
ClientMethod objectToXML(object, tag, add, skip) [ Internal, Language = javascript ]
{
	var xml = '';
	if (object) {
		xml += '<' + tag;

		var template = zenPage.createComponent(object._type);

		var settings = {};
		object.getSettings(settings);

		// fold in add list
		if (add) {
			for (var p in add) {
				settings[p] = add[p];
			}
		}
		var elements = [];

		for (var p in settings) {
			if (!skip || !skip[p]) {
				var type = settings[p];
				type = type.toString().split(':')[0];
				var value = object.getProperty(p);
				if (value!=='' && (null!==template[p]||type=='object') && value!==template.getProperty(p)) {
					switch (type) {
					case 'object':
					case 'list':
						// add to elements list
						elements[elements.length] = p;
						break;
					case 'boolean':
						xml += ' ' + p + '="' + (value?'true':'false') + '"';
						break;
					case 'enum':
						if (value!=='') {
							// 
							if (isNaN(parseInt(value))||(value=='2D')||(value=='3D')) {
								var choice = value;
							}
							else {
								var choices = settings[p].toString().split(':')[1];
								var choice = choices.split(',')[value];
							}
							xml += ' ' + p + '="' + zenEscapeXML(choice) + '"';
						}
						break;
					case 'string':
					default:
						xml += ' ' + p + '="' + zenEscapeXML(value.toString()) + '"';
						break;
					}
				}
			}
		}
		
		if (!elements.length) {
			xml += '/>';
		}
		else {
			xml += '>\n';
			// elements
			for (var n = 0; n < elements.length; n++) {
				var p = elements[n];
				var type = settings[p];
				switch(type) {
				case 'list':
					var ltag = p;
					if (p=='yAxisList') {
						ltag = 'yAxis';
					}
					var list = object.getProperty(p);
					if (list && list.length) {
						for (var j = 0; j < list.length; j++) {
							xml += this.objectToXML(list[j],ltag) + '\n';
						}
					}
					break;
				case 'object':
					xml += this.objectToXML(object.getProperty(p),p) + '\n';
					break;
				}
			}
			xml += '</' + tag + '>';
		}
	}
	return xml;
}

/// Get the start time for a time-based chart.
ClientMethod getStartTime() [ Language = javascript ]
{
	var startTime = this.startTime;
	if (!startTime) {
		if (isNaN(parseInt(this._xMinValue,10))) {
			startTime = '2012-01-01';
		}
		else {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(this._xMinValue*1000);
			startTime = zenDateToString(dt,true);
		}
	}
	return startTime;
}

/// Get the end time for a time-based chart.
ClientMethod getEndTime() [ Language = javascript ]
{
	var endTime = this.endTime;
	if (!endTime) {
		if (isNaN(parseInt(this._xMaxValue,10))) {
			endTime = '2012-12-31';
		}
		else {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(this._xMaxValue*1000);
			endTime = zenDateToString(dt,true);
		}
	}
	return endTime;
}

ClientMethod getLegendRectStyle(s) [ Language = javascript ]
{
	return '';
}

ClientMethod getRelatedElementStyle(series, item) [ Language = javascript ]
{
	return '';
}

ClientMethod getLegendsCount(legends) [ Language = javascript ]
{
	var scount = legends.length;
	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber)) {
		scount = 1;
	}

	return (!this.usePercentForRange() ? scount : this.seriesSize);
}

ClientMethod getSeriesNamesSize() [ Language = javascript ]
{
	return (!this.usePercentForRange() ? this.seriesCount : this.seriesSize)
}

/// Update the "indicator" (crosshairs) for the selected item.
ClientMethod updateIndicator() [ Language = javascript ]
{
	if (!this.indicatorsVisible) return;

	// JMD1314
	var series = parseInt(this.selectedSeries,10);
	var item = parseInt(this.selectedItem,10);

	// create indicators if needed
	var seriesGroup = this.findSVGElement('seriesGroup'+this.currMultiple);
	if (!seriesGroup) return;

	var vtIndicator = this.findSVGElement('vtIndicator'+this.currMultiple);
	if (null == vtIndicator) {
		vtIndicator = this.document.createElementNS(SVGNS,"line");
		vtIndicator.setAttribute("class","chart-indicator");
		vtIndicator.setAttribute("style",this.indicatorStyle);
		vtIndicator.setAttribute("id",this.makeId('vtIndicator'+this.currMultiple));
		seriesGroup.appendChild(vtIndicator);
	}
	var hzIndicator = this.findSVGElement('hzIndicator'+this.currMultiple);
	if (null == hzIndicator) {
		hzIndicator = this.document.createElementNS(SVGNS,"line");
		hzIndicator.setAttribute("class","chart-indicator");
		hzIndicator.setAttribute("style",this.indicatorStyle);
		hzIndicator.setAttribute("id",this.makeId('hzIndicator'+this.currMultiple));
		seriesGroup.appendChild(hzIndicator);
	}

	// compute position of lines
	var vtShow = false;
	var hzShow = false;
	
	vtIndicator.setAttribute("y1",0);
	vtIndicator.setAttribute("y2",this._plotBottom*this._scaleY);

	hzIndicator.setAttribute("x1",0);
	hzIndicator.setAttribute("x2",100*this._scaleX);

	var xAxisType = this.getXAxisType();
	var yAxisType = this.getYAxisType();

	var x, y;
	if (this.hasAxes() && this._dataSeries && !this.chartStacked) {
		if (series >= 0) {
			var items = this.getSeriesSize();
			var val = this._dataSeries[series][item];
			// JMD1314
			var dval = null;
			if ('object'==typeof val) {
				dval = val;
				val = val.value;
			}
			if (val !== null) {
				if (this.isTimeBased()) {
					vtShow = true;
					hzShow = true;
					var time = dval&&dval.time ? dval.time : this.getXLabelText(item,1,true);
					x = this.getTimeX(time);
					x = x===null ? 0 : x;
					y = this.getPlotY(val) - this._plotTop;
				}
				else if (this.plotToEdge) {
					vtShow = true;
					hzShow = true;
					if (xAxisType == 'value') {
						if (yAxisType == 'value') {
							// x/y chart
							val = this._dataSeries[0][item];
							// JMD1314
							if ('object'==typeof val) {
								val = val.value;
							}
						}
						x = this.getPlotX(val) - this._plotLeft;
					}
					else {
						var dx = (items<=1) ? (this._plotWidth/2) : (this._plotWidth / (items-1));
						var adj = (items<=1) ? 0 : dx;
						x = (item-1) * dx + adj;
					}
					if (yAxisType == 'value') {
						if (xAxisType == 'value') {
							// x/y chart
							if (this._dataSeries[series+1]) {
								var val2 = this._dataSeries[series+1][item];
								if ('object'==typeof val2) {
									val2 = val2.value;
								}
								y = this.getPlotY(val2) - this._plotTop;
							}
							else {
								vtShow = false;
							}
						}
						else {
							y = this.getPlotY(val) - this._plotTop;
						}
					}
					else {
						var dy = (items<=1) ? (this._plotHeight/2) : (this._plotHeight / items);
						var adj = (items<=1) ? 0 : dy/2;
						y = (item) * dy + adj;
					}
				}
				else {
					if (this.chartPivot) {
						vtShow = true;
						var dy = (items<=1) ? (this._plotHeight/2) : (this._plotHeight / items);
						var adj = (items<=1) ? 0 : dy/2;
						y = (item) * dy + adj;
						x = this.getPlotX(val) - this._plotLeft;
					}
					else {
						hzShow = true;
						var dx = (items<=1) ? (this._plotWidth/2) : (this._plotWidth / items);
						var adj = (items<=1) ? 0 : dx/2;
						x = (item) * dx + adj;
						y = this.getPlotY(val) - this._plotTop;
					}
				}
				vtIndicator.setAttribute('x1',x * this._scaleX);
				vtIndicator.setAttribute('x2',x * this._scaleX);

				hzIndicator.setAttribute('y1',y * this._scaleY);
				hzIndicator.setAttribute('y2',y * this._scaleY);
			}
		}
	}

	// JMD1422 only show vtlines in this case
	if (this.showMultiples) {
		hzShow = false;
	}

	vtIndicator.setAttribute('visibility',vtShow ? 'visible' : 'hidden');
	hzIndicator.setAttribute('visibility',hzShow ? 'visible' : 'hidden');
}

/// Render a set of time-events within the chart.
ClientMethod renderTimeEvents(group) [ Language = javascript ]
{
	delete this._timeEvents;
	var events = null;
	if (''!=this.ongetTimeEvents) {
		events = zenInvokeCallbackMethod(this.ongetTimeEvents,this,'ongetTimeEvents');
	}
	if (!events || !events.length) return;

	this._timeEvents = events;

	/*
	// "events" show events and their duration along the timeline
	// add callback to get events
	// add callback on event click
	var events = [
		{ start:'2012-01-01', end:'2012-11-02', caption:'Coumadin', style:'', marker:'square'},
	];
	*/
	// make copy and sort by duration (longest first)
	// add original index # to copy
	var sortedEvents = [];
	for (var n = 0; n < events.length; n++) {
		var old = events[n];
		if (old) {
			sortedEvents.push({index:n, start:zenGet(old.start,null),end:zenGet(old.end,null)});
		}
	}

	sortedEvents.sort(function(a,b) {
			// find duration of a and b
			var aDuration = 0;
			if (a.start && a.end) {
				var d1 = zenStringToDate(a.start);
				var d2 = zenStringToDate(a.end);
				aDuration = d2-d1;
			}
			var bDuration = 0;
			if (b.start && b.end) {
				var d1 = zenStringToDate(b.start);
				var d2 = zenStringToDate(b.end);
				bDuration = d2-d1;
			}
			if (aDuration<bDuration) return 1;
			if(aDuration>bDuration) return -1;
			return 0;
		});

	var scaleX = this._scaleX;
	var scaleY = this._scaleY;
	var boxHgt = 6;
	var markerY = 6;
	var y = this._plotBottom - this._plotTop;
	var markerY = y - (boxHgt*1.5);
	
	for (var n = 0; n < sortedEvents.length; n++) {
		var sortEvent = sortedEvents[n];
		if (!sortEvent) continue;
		var idx = sortEvent.index;
		var tlEvent = events[idx];
		if (tlEvent && tlEvent.start) {
			var x1 = this.getTimeX(tlEvent.start);
			var x2 = tlEvent.end ? this.getTimeX(tlEvent.end) : x1;
			var wid = x2-x1;

			// marker + line
			var mtype = zenGet(tlEvent.marker,'circle');
			if (mtype!='none') {
				var line = this.document.createElementNS(SVGNS,'line');
				line.setAttribute('class','chart-timeEventLine');
				line.setAttribute('x1',x1*scaleX);
				line.setAttribute('x2',x1*scaleX);
				line.setAttribute('y1',markerY*scaleY);
				line.setAttribute('y2',y*scaleY);
				group.appendChild(line);

				var mk = this.createMarker(-2,idx,x1,markerY,zenGet(tlEvent.markerColor,'#808080'),mtype);
				group.appendChild(mk);
			}

			var rect = this.document.createElementNS(SVGNS,'rect');
			rect.setAttribute('class','chart-timeEvent');
			rect.setAttribute('style',zenGet(tlEvent.style));
			rect.setAttribute('x',x1*scaleX);
			rect.setAttribute('width',wid*scaleX);
			rect.setAttribute('y',(y-boxHgt)*scaleY);
			rect.setAttribute('height',boxHgt*scaleY);
			group.appendChild(rect);

			rect.setAttribute('id',this.makeId('evrect'+this.currMultiple+'_' + (-2) + '_' + idx));

			// chartElementClickHandler
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+(-2)+','+idx+');');
			rect.addEventListener('click',f,false);

			// label
			if (tlEvent.caption) {
				var tStyle = this.computeStyle('chart-timeEventLabel',null);
				// if (this._xLabelStyle) this.integrateStyleSpec(tStyle,this._xLabelStyle);
				var fSz = this.getComputedFontSize(tStyle, 12, 8, 16);

				// Create and add a new scaled text node
				var text = this.createSVGTextNode(tlEvent.caption,fSz,this.autoScaleText,"start",0,group);
				text.setAttribute("class","chart-xLabel");
				this.embedStyle(text.firstChild,tStyle);
				var th = 1.1*parseFloat(text.getAttribute("effectiveHeight"));
				var tw = parseFloat(text.getAttribute("effectiveWidth"));
				text.setAttribute("transform","translate("+((x1+0.2)*scaleX)+","+((y-boxHgt+th)*scaleY)+")");
				if (tw > (wid*0.9)) {
					text.setAttribute("visibility","hidden");
				}
			}
		}
	}
}

ClientMethod setSeeThrough(opacity) [ Language = javascript ]
{
	//+ JSL4483
	if (this.getFrame() == null) { // JSL4531
		return;
	}
	if (this.getFrame().getEnclosingDiv()) {
		var p=this.getFrame().getEnclosingDiv(); // JSL4483
	} else {
		var p = null;
	}
	if (p == null) { // JSL4531
		return; 
	}
	var c = p.firstChild;
	while (c != null) {
		if (c.tagName == 'DIV' && c.getAttribute('class')=='svgFrame') {
			break;
		}
		c = c.nextSibling;
	}
	var frameDiv=c;
	if (frameDiv) {
		if (opacity < 1.0) {
			frameDiv.style.backgroundColor="transparent";
		} else {
			frameDiv.style.backgroundColor = "white";
		}
	}
	// find dragGroup containing svgFrame
	var p=frameDiv.parentNode
	while (p != null) {
		if (p.tagName=='DIV' && p.getAttribute('class')=='dragGroup') {
			break;
		}
		p=p.parentNode;
	}
	var dragGroup = p;
	if (dragGroup) {
		if (opacity < 1.0) {
			dragGroup._transparent = 1; // JSL4503 - keep track of whether dragGroup is transparent and if it is don't set to #F0F0F0 color
			dragGroup.style.background="transparent";
			//dragGroup.style.backgroundColor="transparent";
			//dragGroup.style.opacity = opacity;
		} else {
			if (!dragGroup._transparent) { // JSL4503 add test and _transparent variable
				dragGroup.style.backgroundColor="#F0F0F0";
			} else {
				dragGroup.style.backgroundColor="transparent"; // JSL4503 set to transparet if _transparent set
			}
		}
		if (false) {
			var divToolBar = document.getElementById(dragGroup.id+'/header');
			if (divToolBar) {
				divToolBar.style.backgroundColor = "#F0F0F0";
				divToolBar.style.opacity = opacity;
			}
		}
		if (this.document == null) { // JSL4531
			return; 
		}
		var zenbackground = this.document.getElementById('zenBackground');
		if (zenbackground == null) { // JSL4531
			return;
		}
		if (opacity < 1.0) {
			zenbackground.setAttribute('fill-opacity',0);
		} else {
			zenbackground.setAttribute('fill-opacity',1.0);
		}
	}
	//- JSL4483
}

/// Utility method. Split an SVG css value into individual style values.
/// Return an object containing these values.
ClientMethod parseStyleSVG(style) [ Language = javascript ]
{
	// added method - JSL4483 - copy-and-pasted from navigator
	var result = {};

	// for svg we have to parse
	var items = style.toString().toLowerCase().split(';');
	for (var i=0; i<items.length; i++) {
		if (items[i]) {
			var pair = items[i].split(':');
			if (pair && pair.length==2) {
				newAttr = zenTrim(pair[0]);
				if (newAttr && newAttr.length>0) {
					newVal = zenTrim(pair[1]);
					if (newVal !== '') {
						result[newAttr] = newVal;
					}
				}
			}
		}
	}
	return result;
}

}
