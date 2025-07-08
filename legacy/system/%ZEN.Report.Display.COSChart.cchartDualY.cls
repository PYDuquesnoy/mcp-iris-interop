/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

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
Class %ZEN.Report.Display.COSChart.cchartDualY Extends (%ZEN.Report.Display.node, %ZEN.Report.Display.tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property children As list Of node(XMLPROJECTION = "NONE");

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

/// If defined, this is used to calculate the width of the
/// viewBox attribute of the enclosing svg element.<br/>
Property viewBoxWidth As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTVIEWBOXWIDTH} ];

/// If defined, this is used to calculate the height of the
/// viewBox attribute of the enclosing svg element.<br/>
Property viewBoxHeight As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTVIEWBOXHEIGHT} ];

/// Optional: If true, display chart as number of small multiple charts, one per data series.
/// This is only used by charts that support small multiples otherwise it is ignored.
Property showMultiples As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for title text within each "multiple" charts.
/// Used when <property>showMultiples</property> is enabled.
Property multipleTitleStyle As %ZEN.Datatype.svgStyle;

/// Internal property used to track which multiple is being rendered.
Property currMultiple As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Height of the chart within the report.
Property height As %ZEN.Datatype.length;

Property svgGroup As %ZEN.Report.Display.COSChart.node;

Property topLevel As %ZEN.Report.Display.COSChart.node;

/// x axis specification for this chart.
Property xAxis As caxis(XMLPROJECTION = "ELEMENT");

/// Deprecated. y axis specifications for this chart.
/// This is replaced by yAxisList. This property is kept here so that
/// applications that set yAxis directly will still function.
Property yAxis As caxis(XMLPROJECTION = "none");

/// List of y axis specifications for this chart.
Property yAxisList As list Of caxis(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE");

/// Optional: style used for chart background panel.
Property backgroundStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for chart plot area panel.
Property plotAreaStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill:url(#glow-silverDiag);" ];

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

Property chartPivot As %ZEN.Datatype.boolean;

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

/// Internal used by DeepSee to support data-driven series colors
Property dataDrivenSeriesColors As %String(XMLPROJECTION = "none");

/// Internal used by DeepSee to support data-driven series colors
Property %dataDrivenSeriesColors As %List(XMLPROJECTION = "none");

Property dateFormat As %String(XMLPROJECTION = "none");

Property %seriesColors As %List(XMLPROJECTION = "none") [ MultiDimensional ];

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
Property seriesNames As %ZEN.Datatype.csv;

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

/// Optional: legendLabels 
Property legendLabels As %ZEN.Datatype.csv;

/// Optional: legend position
Property legendPosition As %ZEN.Datatype.string(VALUELIST = ",top,left,bottom,right,none");

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

/// If defined, then a colored band (specified by <property>bandRightStyle</property>)
/// is displayed on the plot area covering the range greater than this value;
Property bandRight As %ZEN.Datatype.float;

/// If defined, then a colored band (specified by <property>bandLeftStyle</property>)
/// is displayed on the plot area covering the range lower than this value;
Property bandLeft As %ZEN.Datatype.float;

/// Optional: style used for right band on plot area.
Property bandRightStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for left band on plot area.
Property bandLeftStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to line drawn for x and y axes.
Property axisLineStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to base line.
Property baseLineStyle As %ZEN.Datatype.svgStyle;

/// Controls the appearance of this chart.<br/>
/// Set this to "2D" (the default) for a standard chart appearance.<br/>
/// Setting this to "3D" will give the chart a 3-D appearance; the
/// plot area will appear to be recessed. Certain chart types, such are
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

/// ongetData method
/// This method is called by the chart
/// to get an array of values to plot for a data series.
/// The array has the format values(s,i) where s is the series
/// and is i is the member of the series and values(s,i) is numeric.
/// <br/>
/// The method is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. 
Property ongetData As %ZEN.Datatype.string;

/// ongetLabelX event handler:
/// This method, if defined, is called by the chart
/// to get the text for a given label on the x axis.<br/>
/// The method is passed an argument, <var>value</var>,
/// that contains the ordinal number (0-based) of the label.<br/>
/// The method is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. 
Property ongetLabelX As %ZEN.Datatype.string;

/// ongetLabelY event handler:
/// This method, if defined, is called by the chart
/// to get the text for a given label on the y axis.<br/>
/// The method is passed an argument, <var>value</var>,
/// that contains the ordinal number (0-based) of the label.<br/>
/// The method is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. 
Property ongetLabelY As %ZEN.Datatype.string;

/// ongetSeriesName event handler:
/// This method, if defined, is called by the chart
/// to get the text for a given series number.<br/>
/// The method is passed an argument
/// that contains the ordinal number (0-based) of the series name.<br/>
/// The method is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. 
Property ongetSeriesName As %ZEN.Datatype.string;

/// onrenderData callback:
/// This callback, if defined, is called by the chart
/// just after it is finished displaying grid lines and data.
/// The event handler is passed an argument, <var>chart</var>,
/// that is <i>this</i> chart object. If it also passed <var>group</var>,
/// which is the SVG group to which any new svg content should be added.
Property onrenderData As %ZEN.Datatype.eventHandler;

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
Property hzZoomStep As %ZEN.Datatype.float(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Internal amount of horizontal scroll.
Property scrollLeft As %ZEN.Datatype.float(XMLPROJECTION = "none") [ InitialExpression = 0.0, Internal ];

/// A dataSeries used to provide a series-worth of data for the report
Property dataSeries As list Of dataSeries(XMLNAME = "dataSeries", XMLPROJECTION = "ELEMENT");

/// pass the chart object to onget... methods, set it to false for old behavior where no chart object passed
Property passChartObject As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

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

/// Optional. The id of the <class>%ZEN.Report.Display.COSChart.abstractController</class> object that
/// provides data for this chart.<br/>
/// If provided, this must be the valid id of a <class>%ZEN.Report.Display.COSChart.abstractController</class> object.
Property controllerId As %ZEN.Datatype.id(COMPONENTTYPE = "dataController");

Property zenMonthShortNames As %ZEN.Datatype.caption(XMLPROJECTION = "none") [ InitialExpression = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec" ];

/// turns on category value calcuation of JMD1100 (this is in JSL3955)
Property oldLabelCalc As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// adjust calculated height of text by multiplying by FontYScale
Property FontYScale As %ZEN.Datatype.float [ InitialExpression = 1.0 ];

/// adjust calculated width of text by multiplying by FontXScale
Property FontXScale As %ZEN.Datatype.float [ InitialExpression = .75 ];

/// used for debugging label placement JSL3955
Property debugBBox As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: URL of image to display within the title area.
Property titleImage As %ZEN.Datatype.uri;

/// Optional. Style for titleImage: left,top,width, and height.
Property titleImageStyle As %ZEN.Datatype.svgStyle;

/// Set to 1 to display a localized warning message if chart has no data
Property warnIfNoData As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// localized warning message if chart has no data
Property msgIfNoData As %ZEN.Datatype.caption [ InitialExpression = "No Data" ];

/// opacity of no data message background rectangle
Property noDataOpacity As %ZEN.Datatype.float [ InitialExpression = 1.0 ];

/// fill color rectange
Property noDataFill As %ZEN.Datatype.color [ InitialExpression = "red" ];

/// color of message
Property noDataStroke As %ZEN.Datatype.color [ InitialExpression = "white" ];

Property %yMajorUnits As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yMinorUnits As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yLabelUnits As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yLabelAngle As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yLabelStyle As %String(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yMajorGrid As %Double(XMLPROJECTION = "none");

Property %yMinorGrid As %Double(XMLPROJECTION = "none");

Property %yMajorGridStyle As %Double(XMLPROJECTION = "none");

Property %yMinorGridStyle As %Double(XMLPROJECTION = "none");

Property %xMajorUnits As %Double(XMLPROJECTION = "none");

Property %xMinorUnits As %Double(XMLPROJECTION = "none");

Property %xLabelUnits As %Double(XMLPROJECTION = "none");

Property %xLabelAngle As %Double(XMLPROJECTION = "none");

Property %xLabelStyle As %Double(XMLPROJECTION = "none");

Property %xMajorGrid As %Double(XMLPROJECTION = "none");

Property %xMinorGrid As %Double(XMLPROJECTION = "none");

Property %xMajorGridStyle As %Double(XMLPROJECTION = "none");

Property %xMinorGridStyle As %Double(XMLPROJECTION = "none");

Property %yGridType As %Double(XMLPROJECTION = "none");

Property %xGridType As %Double(XMLPROJECTION = "none");

Property %plotLeft As %Double(XMLPROJECTION = "none");

Property %plotTop As %Double(XMLPROJECTION = "none");

Property %rplotWidth As %Double(XMLPROJECTION = "none");

Property %plotHeight As %Double(XMLPROJECTION = "none");

Property %labelPad As %Double(XMLPROJECTION = "none");

Property %labelPadL As %Double(XMLPROJECTION = "none");

Property %labelPadR As %Double(XMLPROJECTION = "none");

Property %xMinValue As %Double(XMLPROJECTION = "none");

Property %xMaxValue As %Double(XMLPROJECTION = "none");

Property %oldXMax As %Double(XMLPROJECTION = "none");

Property %yMinValue As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yMaxValue As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %marginTop As %Double(XMLPROJECTION = "none");

Property %marginBottom As %Double(XMLPROJECTION = "none");

Property %legendRight As %Double(XMLPROJECTION = "none");

Property %legendWidth As %Double(XMLPROJECTION = "none");

Property %legendHeight As %Double(XMLPROJECTION = "none");

Property %labelBottom As %Double(XMLPROJECTION = "none");

Property %legendVisible As %Boolean(XMLPROJECTION = "none");

Property %xBaseValue As %Double(XMLPROJECTION = "none");

Property %yBaseValue As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %xRange As %Double(XMLPROJECTION = "none");

Property %yRange As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %yAxisTitle As %String(XMLPROJECTION = "none");

Property %xAxisTitle As %String(XMLPROJECTION = "none");

Property %marginLeft As %Double(XMLPROJECTION = "none");

Property %marginRight As %Double(XMLPROJECTION = "none");

Property %plotLeftOut As %Double(XMLPROJECTION = "none");

Property %plotRightOut As %Double(XMLPROJECTION = "none");

Property %rplotRightOut As %Double(XMLPROJECTION = "none");

Property %rplotRight As %Double(XMLPROJECTION = "none");

Property %plotWidth As %Double(XMLPROJECTION = "none");

Property %plotRight As %Double(XMLPROJECTION = "none");

Property %hzMaxStep As %Double(XMLPROJECTION = "none");

Property %maxScrollLeft As %Double(XMLPROJECTION = "none");

Property %xAxisLabelH As %Double(XMLPROJECTION = "none");

Property %dataSeries As %Double(XMLPROJECTION = "none") [ MultiDimensional ];

Property %xAxisTitleH As %Double(XMLPROJECTION = "none");

Property %plotTopOut As %Double(XMLPROJECTION = "none");

Property %plotBottomOut As %Double(XMLPROJECTION = "none");

Property %plotBottom As %Double(XMLPROJECTION = "none");

Property %yAxisForSeries As %List(XMLPROJECTION = "none") [ MultiDimensional ];

Property %scaleX As %Double(XMLPROJECTION = "none");

Property %scaleY As %Double(XMLPROJECTION = "none");

Property %controlBarH As %Double(XMLPROJECTION = "none");

Property %yLabelOnTheRight As %Boolean(XMLPROJECTION = "none");

Property %yLabelOnTheLeft As %Boolean(XMLPROJECTION = "none");

Property %xLabelOnTheTop As %Boolean(XMLPROJECTION = "none");

Property %xLabelOnTheBottom As %Boolean(XMLPROJECTION = "none");

Property %date1900 As Date(XMLPROJECTION = "none");

Property %offset As %String(XMLPROJECTION = "none");

Property %startUnits As %String(XMLPROJECTION = "none");

Property %endUnits As %String(XMLPROJECTION = "none");

Property %majorUnits As %String(XMLPROJECTION = "none");

Property %minorUnits As %String(XMLPROJECTION = "none");

Property %pixPerSec As %Double(XMLPROJECTION = "none");

Property %titleHeight As %Double(XMLPROJECTION = "none");

Property %maxXHeight As %Double(XMLPROJECTION = "none");

Property %firstXLabelWidth As %Double(XMLPROJECTION = "none");

Property %lastXLabelWidth As %Double(XMLPROJECTION = "none");

Property %titleImageWidth As %Double(XMLPROJECTION = "none");

Property %titleImageTop As %Double(XMLPROJECTION = "none");

Property %titleImageLeft As %Double(XMLPROJECTION = "none");

Property %timeEvents As %String(XMLPROJECTION = "none") [ MultiDimensional ];

XData SVGStyle
{
<style type="text/css"><![CDATA[

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
	fill: #F0F0F0;
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

/* @doc="Upper or lower band or right or left band." */
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
	stroke-width: 0.1px;
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

.scoreCardBackground {
	fill: #FFFFFE;
	stroke: black;
}

.scoreCardRowEven {
	fill: white;
	fill-opacity: 0;
	stroke: none;
}
.scoreCardRowOdd {
	fill: rgb(206,205,165);
	fill-opacity: 0.2;
	stroke: none;
	stroke-width: 0.1px;
}

.scoreCardRowSelected {
	fill: #FFEEAA;
	stroke: blue;
	stroke-width: 0.1px;
}

/* line on top and bottom of card */
.scoreCardSeparator {
	fill: none;
	stroke: #404040;
	stroke-width: 0.25px;
}

.scoreCardTitle {
	pointer-events: none;
	font-size: 16pt;
	fill: rgb(164,57,39);
	stroke: none;
}

.scoreCardSubtitle {
	pointer-events: none;
	font-size: 10pt;
	fill: rgb(164,164,164);
	stroke: none;
}

.scoreCardHeader {
	pointer-events: none;
	font-size: 11pt;
	font-weight: bold;
	fill: #404040;
	stroke: none;
}

.scoreCardLabel {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
}

.scoreCardLabelBig {
	pointer-events: none;
	font-size: 18pt;
	fill: #404040;
	stroke: none;
}

.scoreCardCellCaption {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
}

.scoreCardValue {
	pointer-events: none;
	font-size: 10pt;
	fill: #404040;
	stroke: none;
}

.scoreCardValueBig {
	pointer-events: none;
	font-size: 20pt;
	fill: #404040;
	stroke: none;
}

.scoreCardTrendLine {
	fill: none;
	stroke: rgb(164,57,39);
	stroke-width: 2px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.scoreCardTrendBars {
	fill: rgb(47,98,128);
	stroke: none;
	stroke-width: 1px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.scoreCardArrow {
	fill: #AA6666;
	stroke: none;
	stroke-width: 0.1px;
}

.scoreCardLamp {
	stroke: none;
	stroke-width: 0.5px;
}

.scoreCardPlotBoxOuter {
	fill: #D0D0D0;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxMiddle {
	fill: #B0B0B0;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxInner {
	fill: #909090;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxValue {
	fill: #202020;
	stroke: none;
}

.scoreCardPlotBoxTarget {
	stroke: #202060;
	stroke-width: 2px;
	stroke-linecap: round;
	fill: none;
}

.scoreCardScale {
	stroke: #404040;
	stroke-width: 0.5px;
	fill: none;
	stroke-linecap: round;
	stroke-linejoin: round;
}

.scoreCardScaleLabel {
	pointer-events: none;
	font-size: 7pt;
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

]]></style>
}

XData SVGStyleNoHTML5
{
<svg:style type="text/css"><![CDATA[

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
	fill: #F0F0F0;
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

/* @doc="Upper or lower band or right or left band." */
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
	stroke-width: 0.1px;
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

.scoreCardBackground {
	fill: #FFFFFE;
	stroke: black;
}

.scoreCardRowEven {
	fill: white;
	fill-opacity: 0;
	stroke: none;
}
.scoreCardRowOdd {
	fill: rgb(206,205,165);
	fill-opacity: 0.2;
	stroke: none;
	stroke-width: 0.1px;
}

.scoreCardRowSelected {
	fill: #FFEEAA;
	stroke: blue;
	stroke-width: 0.1px;
}

/* line on top and bottom of card */
.scoreCardSeparator {
	fill: none;
	stroke: #404040;
	stroke-width: 0.25px;
}

.scoreCardTitle {
	pointer-events: none;
	font-size: 16pt;
	fill: rgb(164,57,39);
	stroke: none;
}

.scoreCardSubtitle {
	pointer-events: none;
	font-size: 10pt;
	fill: rgb(164,164,164);
	stroke: none;
}

.scoreCardHeader {
	pointer-events: none;
	font-size: 11pt;
	font-weight: bold;
	fill: #404040;
	stroke: none;
}

.scoreCardLabel {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
}

.scoreCardLabelBig {
	pointer-events: none;
	font-size: 18pt;
	fill: #404040;
	stroke: none;
}

.scoreCardCellCaption {
	pointer-events: none;
	font-size: 11pt;
	fill: #404040;
	stroke: none;
}

.scoreCardValue {
	pointer-events: none;
	font-size: 10pt;
	fill: #404040;
	stroke: none;
}

.scoreCardValueBig {
	pointer-events: none;
	font-size: 20pt;
	fill: #404040;
	stroke: none;
}

.scoreCardTrendLine {
	fill: none;
	stroke: rgb(164,57,39);
	stroke-width: 2px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.scoreCardTrendBars {
	fill: rgb(47,98,128);
	stroke: none;
	stroke-width: 1px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.scoreCardArrow {
	fill: #AA6666;
	stroke: none;
	stroke-width: 0.1px;
}

.scoreCardLamp {
	stroke: none;
	stroke-width: 0.5px;
}

.scoreCardPlotBoxOuter {
	fill: #D0D0D0;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxMiddle {
	fill: #B0B0B0;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxInner {
	fill: #909090;
	fill-opacity: 0.75;
	stroke: none;
}

.scoreCardPlotBoxValue {
	fill: #202020;
	stroke: none;
}

.scoreCardPlotBoxTarget {
	stroke: #202060;
	stroke-width: 2px;
	stroke-linecap: round;
	fill: none;
}

.scoreCardScale {
	stroke: #404040;
	stroke-width: 0.5px;
	fill: none;
	stroke-linecap: round;
	stroke-linejoin: round;
}

.scoreCardScaleLabel {
	pointer-events: none;
	font-size: 7pt;
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


]]></svg:style>
}

/// Set of standard svg defs shared by all svg components.
XData SVGDef
{
<defs>
<pattern id="zenHatch" patternUnits="userSpaceOnUse" x="0" y="0" width="10" height="10">
  <g style="fill:none; stroke:#808080; stroke-width:1">
    <path d="M 0 0 l 10 10"/>
    <path d="M 10 0 l -10 10"/>
  </g>
</pattern>
<linearGradient id="deep-red" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:#800000" />
</linearGradient>

<linearGradient id="shade-red" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF8080" />
<stop offset="20%" style="stop-color:#FF0000" />
<stop offset="80%" style="stop-color:#A00000" />
<stop offset="100%" style="stop-color:#600000" />
</linearGradient>

<linearGradient id="glow-red" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="glow-redHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="glow-redDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="40%" style="stop-color:#FF0000" />
<stop offset="60%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>


<linearGradient id="deep-green" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:#008000" />
</linearGradient>

<linearGradient id="shade-green" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#80FF80" />
<stop offset="20%" style="stop-color:#00FF00" />
<stop offset="80%" style="stop-color:#00A000" />
<stop offset="100%" style="stop-color:#006000" />
</linearGradient>

<linearGradient id="glow-green" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="glow-greenHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="glow-greenDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="40%" style="stop-color:#00FF00" />
<stop offset="60%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="deep-blue" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:#000080" />
</linearGradient>

<linearGradient id="shade-blue" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#8080FF" />
<stop offset="20%" style="stop-color:#0000FF" />
<stop offset="80%" style="stop-color:#0000A0" />
<stop offset="100%" style="stop-color:#000060" />
</linearGradient>

<linearGradient id="glow-blue" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#0000FF" />
<stop offset="70%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="glow-blueHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#0000FF" />
<stop offset="70%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="glow-blueDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="40%" style="stop-color:#0000FF" />
<stop offset="60%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="deep-yellow" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="shade-yellow" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FFFF80" />
<stop offset="20%" style="stop-color:#FFFF00" />
<stop offset="80%" style="stop-color:#A0A000" />
<stop offset="100%" style="stop-color:#606000" />
</linearGradient>

<linearGradient id="glow-yellow" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-yellowHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-yellowDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="40%" style="stop-color:#FFFF00" />
<stop offset="60%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="deep-purple" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="shade-purple" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF80FF" />
<stop offset="20%" style="stop-color:#FF00FF" />
<stop offset="80%" style="stop-color:#A000A0" />
<stop offset="100%" style="stop-color:#600060" />
</linearGradient>

<linearGradient id="glow-purple" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="glow-purpleHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="glow-purpleDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="40%" style="stop-color:#FF00FF" />
<stop offset="60%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="deep-teal" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#008080" />
</linearGradient>

<linearGradient id="shade-teal" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#80FFFF" />
<stop offset="20%" style="stop-color:#00FFFF" />
<stop offset="80%" style="stop-color:#00A0A0" />
<stop offset="100%" style="stop-color:#006060" />
</linearGradient>

<linearGradient id="glow-teal" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="30%" style="stop-color:#00FFFF" />
<stop offset="70%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="glow-tealHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="30%" style="stop-color:#00FFFF" />
<stop offset="70%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="glow-tealDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="40%" style="stop-color:#00FFFF" />
<stop offset="60%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="deep-orange" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF8000" />
<stop offset="100%" style="stop-color:#804000" />
</linearGradient>

<linearGradient id="shade-orange" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF8080" />
<stop offset="20%" style="stop-color:#FF8000" />
<stop offset="80%" style="stop-color:#A04000" />
<stop offset="100%" style="stop-color:#604000" />
</linearGradient>

<linearGradient id="glow-orange" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:orange" />
<stop offset="70%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-orangeHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:orange" />
<stop offset="70%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-orangeDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="40%" style="stop-color:orange" />
<stop offset="60%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="deep-silver" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="shade-silver" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="20%" style="stop-color:#F0F0F0" />
<stop offset="80%" style="stop-color:#A0A0A0" />
<stop offset="100%" style="stop-color:#606060" />
</linearGradient>

<linearGradient id="glow-silver" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="30%" style="stop-color:#FFFFFF" />
<stop offset="70%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="glow-silverHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="30%" style="stop-color:#FFFFFF" />
<stop offset="70%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="glow-silverDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="40%" style="stop-color:#FFFFFF" />
<stop offset="60%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="bg-chrome" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="2%" style="stop-color:#F0F0FF" />
<stop offset="10%" style="stop-color:#E0E0E0" />
<stop offset="90%" style="stop-color:#E0E0E0" />
<stop offset="98%" style="stop-color:#F0F0F0" />
<stop offset="100%" style="stop-color:#FFFFFF" />
</linearGradient>

<filter id="dropShadow" x="-2%" y="-2%" height="120%" width="120%">
<feGaussianBlur in="SourceAlpha" stdDeviation="3" />
<feOffset dx="4" dy="4" result="offsetBlur" />
<feMerge>
	<feMergeNode in="offsetBlur"/>
	<feMergeNode in="SourceGraphic"/>
</feMerge>
</filter>
</defs>
}

/// Set of standard svg defs shared by all svg components.
XData SVGDefNoHTML5
{
<svg:defs xmlns="http://www.w3.org/2000/svg">
<pattern id="zenHatch" patternUnits="userSpaceOnUse" x="0" y="0" width="10" height="10">
  <g style="fill:none; stroke:#808080; stroke-width:1">
    <path d="M 0 0 l 10 10"/>
    <path d="M 10 0 l -10 10"/>
  </g>
</pattern>
<linearGradient id="deep-red" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:#800000" />
</linearGradient>

<linearGradient id="shade-red" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF8080" />
<stop offset="20%" style="stop-color:#FF0000" />
<stop offset="80%" style="stop-color:#A00000" />
<stop offset="100%" style="stop-color:#600000" />
</linearGradient>

<linearGradient id="glow-red" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="glow-redHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="glow-redDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="40%" style="stop-color:#FF0000" />
<stop offset="60%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>


<linearGradient id="deep-green" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:#008000" />
</linearGradient>

<linearGradient id="shade-green" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#80FF80" />
<stop offset="20%" style="stop-color:#00FF00" />
<stop offset="80%" style="stop-color:#00A000" />
<stop offset="100%" style="stop-color:#006000" />
</linearGradient>

<linearGradient id="glow-green" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="glow-greenHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="glow-greenDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="40%" style="stop-color:#00FF00" />
<stop offset="60%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="deep-blue" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:#000080" />
</linearGradient>

<linearGradient id="shade-blue" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#8080FF" />
<stop offset="20%" style="stop-color:#0000FF" />
<stop offset="80%" style="stop-color:#0000A0" />
<stop offset="100%" style="stop-color:#000060" />
</linearGradient>

<linearGradient id="glow-blue" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#0000FF" />
<stop offset="70%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="glow-blueHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#0000FF" />
<stop offset="70%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="glow-blueDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="40%" style="stop-color:#0000FF" />
<stop offset="60%" style="stop-color:#0000FF" />
<stop offset="100%" style="stop-color:darkblue" />
</linearGradient>

<linearGradient id="deep-yellow" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="shade-yellow" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FFFF80" />
<stop offset="20%" style="stop-color:#FFFF00" />
<stop offset="80%" style="stop-color:#A0A000" />
<stop offset="100%" style="stop-color:#606000" />
</linearGradient>

<linearGradient id="glow-yellow" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-yellowHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-yellowDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="40%" style="stop-color:#FFFF00" />
<stop offset="60%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="deep-purple" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="shade-purple" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF80FF" />
<stop offset="20%" style="stop-color:#FF00FF" />
<stop offset="80%" style="stop-color:#A000A0" />
<stop offset="100%" style="stop-color:#600060" />
</linearGradient>

<linearGradient id="glow-purple" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="glow-purpleHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="glow-purpleDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#800080" />
<stop offset="40%" style="stop-color:#FF00FF" />
<stop offset="60%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:#800080" />
</linearGradient>

<linearGradient id="deep-teal" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#008080" />
</linearGradient>

<linearGradient id="shade-teal" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#80FFFF" />
<stop offset="20%" style="stop-color:#00FFFF" />
<stop offset="80%" style="stop-color:#00A0A0" />
<stop offset="100%" style="stop-color:#006060" />
</linearGradient>

<linearGradient id="glow-teal" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="30%" style="stop-color:#00FFFF" />
<stop offset="70%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="glow-tealHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="30%" style="stop-color:#00FFFF" />
<stop offset="70%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="glow-tealDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#008080" />
<stop offset="40%" style="stop-color:#00FFFF" />
<stop offset="60%" style="stop-color:#00FFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="deep-orange" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FF8000" />
<stop offset="100%" style="stop-color:#804000" />
</linearGradient>

<linearGradient id="shade-orange" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FF8080" />
<stop offset="20%" style="stop-color:#FF8000" />
<stop offset="80%" style="stop-color:#A04000" />
<stop offset="100%" style="stop-color:#604000" />
</linearGradient>

<linearGradient id="glow-orange" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:orange" />
<stop offset="70%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-orangeHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:orange" />
<stop offset="70%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="glow-orangeDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="40%" style="stop-color:orange" />
<stop offset="60%" style="stop-color:orange" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="deep-silver" x1="0%" y1="0%" x2="10%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:#808080" />
</linearGradient>

<linearGradient id="shade-silver" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="20%" style="stop-color:#F0F0F0" />
<stop offset="80%" style="stop-color:#A0A0A0" />
<stop offset="100%" style="stop-color:#606060" />
</linearGradient>

<linearGradient id="glow-silver" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="30%" style="stop-color:#FFFFFF" />
<stop offset="70%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="glow-silverHz" x1="0%" y1="0%" x2="100%" y2="0%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="30%" style="stop-color:#FFFFFF" />
<stop offset="70%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="glow-silverDiag" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:darkgray" />
<stop offset="40%" style="stop-color:#FFFFFF" />
<stop offset="60%" style="stop-color:#FFFFFF" />
<stop offset="100%" style="stop-color:darkgray" />
</linearGradient>

<linearGradient id="bg-chrome" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#FFFFFF" />
<stop offset="2%" style="stop-color:#F0F0FF" />
<stop offset="10%" style="stop-color:#E0E0E0" />
<stop offset="90%" style="stop-color:#E0E0E0" />
<stop offset="98%" style="stop-color:#F0F0F0" />
<stop offset="100%" style="stop-color:#FFFFFF" />
</linearGradient>

<filter id="dropShadow" x="-2%" y="-2%" height="120%" width="120%">
<feGaussianBlur in="SourceAlpha" stdDeviation="3" />
<feOffset dx="4" dy="4" result="offsetBlur" />
<feMerge>
	<feMergeNode in="offsetBlur"/>
	<feMergeNode in="SourceGraphic"/>
</feMerge>
</filter>
</svg:defs>
}

/// Client-side method to render control.
Method renderContents()
{
	Set this=##this

	// used for computations (JMD1130 pt 3)
	Set this.%date1900 = ##class(Date).createDate(1900,0,1)
	
		// track if we have computed an xmax (for time-based charts)
	Set oldXMax = $s(this.%xMaxValue : this.%xMaxValue, 1 : "")

	// JMD1100
	// if view box is turned off; find scaling factors
	if ((this.viewBoxWidth = "") && (this.viewBoxHeight = "")) {
		Set this.%scaleX = $$$PARSEINT(this.width)/100
		Set this.%scaleY = $$$PARSEINT(this.height)/100
	}
	else {
		Set this.%scaleX = 1
		Set this.%scaleY = 1
	}

	Set scaleX = this.%scaleX
	Set scaleY = this.%scaleY

	// JMD1125 do not render if too small
	if (($$$PARSEINT(this.width) <= 1) || ($$$PARSEINT(this.height) <= 1)) {
		quit $$$OK
	}

	// get data for chart	
	Do ..acquireData()

	// JMD1125: skip if nothing to do
	// JSL4478 - comment out
	//if (this.getSeriesSize()<=0) { // we need a method call in ZEN Report case
	//	quit $$$OK
	//}

	Set Status=$$$OK
	
	// JSL4332
	if ..dataDrivenSeriesColors'="" {
		Set ..%dataDrivenSeriesColors = ..split(..dataDrivenSeriesColors,"~")
	}
	
	// error test
	set yaCount = this.getYAxisCount()
	if ((this.currYAxis < 0) || (this.currYAxis >= yaCount)) {
		Set Status=$$$ERROR($$$GeneralError,"currYAxis is out of range for chart, " _ this.currYAxis _ ", in chart '" _ %context("id") _ "' axis count='"_yaCount_"'")
		quit Status
	}

	// set up data series colors
	if (..seriesColors'="") {
		// JMD1064-- we can't use split as their could be rgb(r,g,b) values in the list!
		Set str = this.seriesColors_","
		Set inParen = 0
		Set token = ""
		Set this.%seriesColors = "" ; null list
		for n = 1:1:$L(str) {
			Set ch = $e(str,n)
			if (inParen) {
				Set token = token _ ch
				if (ch = ")") {
					Set inParen = 0
				}
			}
			else {
				if (ch = ",") {
					if (token'="") {
						Set $LI(this.%seriesColors,$LL(this.%seriesColors)+1) = token
					}
					Set token = ""
				}
				elseif (ch = "(") {
					Set inParen = 1
					Set token = token _ ch
				}
				else {
					Set token = token _ ch
				}
			}
		}

	}
	else {
		Set ..%seriesColors = ..getColorSchemeArray(..seriesColorScheme)
	}
	
		// define mapping of data series to y-axis.
		
	Set this.%yAxisForSeries = ""
	if (this.hasAxes() && (this.seriesYAxes'="")) {
		Set t = ..split(this.seriesYAxes,",")
		for s=1:1:..getSeriesCount() {
			Set ax = $s($LG(t,s)'="" : +$LG(t,s), 1 : 0)
			if (""=ax || $$$ISNAN(ax)) {
				Set Status=$$$ERROR($$$GeneralError,"Illegal value in seriesYAxes, " _ $LG(t,s) _ ", in chart '" _ %context("id") _ "'")
				quit 
			}
			elseif ((ax < 0) || (ax >= yaCount)) {
				Set Status=$$$ERROR($$$GeneralError,"Out-of-range value in seriesYAxes, " _ $LG(t,s) _ ", in chart '" _ %context("id") _ "'")
				quit
			}
			Set $LI(this.%yAxisForSeries,s) = ax
		}
		If $$$ISERR(Status) quit Status
	}
	else {
		for s=1:1:this.getSeriesCount() {
			Set $LI(this.%yAxisForSeries,s) = 0
		}
	}

	// merge in override colors
	if (this.seriesColorsOverride'="") {
		// JSL3748 port JMD831-- we can't use split as their could be rgb(r,g,b) values in the list!
		Set str = this.seriesColorsOverride_","
		Set inParen = 0
		Set token = ""
		Set over = "" ; empty list
		for n=1:1:$L(str) {
			Set ch = $e(str,n)
			if (inParen) {
				Set token = token_ch
				if (ch = ")") {
					Set inParen = 0
				}
			}
			else {
				if (ch = ",") {
					if (token'="") {
						Set $LI(over,$LL(over)+1) = token
					} else {
						Set $LI(over,$LL(over)+1) = ""
					}
					Set token = ""
				}
				elseif (ch = "(") {
					Set inParen = 1
					Set token = token _ ch
				}
				else {
					Set token = token _ ch
				}
			}
		}
		// Set over = ..split(this.seriesColorsOverride,",")
		Set c = $s($LL(over) > $LL(this.%seriesColors) : $LL(over) ,1 : $LL(this.%seriesColors))
		for n=1:1:c {
			if ($LG(over,n)'="") {
				Set $LI(this.%seriesColors,n) = $LG(over,n)
			}
			elseif ($LG(this.%seriesColors,n)="") {
				Set $LI(this.%seriesColors,n) = "blue"
			}
		}
	}

	if (this.hasMultiples()) {
		// skip repaint optimizations
		do this.unrender()
	}

	// create chart background panel
	Set borderOffset = $$$PARSEINT(this.borderOffset) // pixels
	Set borderOffset = $s($$$ISNAN(borderOffset)||(borderOffset<0) : 0, 1 : borderOffset)
	Set borderOffset = $s(borderOffset>(100*scaleY*2) : 0, 1 : borderOffset)

	Set pane=##class(%ZEN.Report.Display.COSChart.node).%New()
	Do pane.createElementSVG("rect")
	Do pane.setAttribute("id",..makeId("background"))
	Do pane.setAttribute("class","chart-background")
	Do pane.setAttribute("style",..backgroundStyle)
	Do pane.setAttribute("rx",..borderRadius)
	Do pane.setAttribute("x",0)
	Do pane.setAttribute("y",0)
	Do pane.setAttribute("width",100*scaleX)
	Do pane.setAttribute("height",100*scaleY)
	Set ..svgGroup=##class(%ZEN.Report.Display.COSChart.node).%New()
	do ..svgGroup.createElementSVG("svg")
	Set ..topLevel=##class(%ZEN.Report.Display.COSChart.node).%New()
	do ..topLevel.createElementSVG("svg")
	do ..topLevel.setAttribute("x",0) ; magic to make PDF display
	do ..topLevel.setAttribute("y",0)
	do ..topLevel.setAttribute("shape-rendering","geometricPrecision")
	if ..height'="" {
		do ..svgGroup.setAttribute("height",..height)
		do ..topLevel.setAttribute("height",..height)
	} else {
		do ..svgGroup.setAttribute("height",100)
		do ..topLevel.setAttribute("height",100)
	}
	if ..width'="" {
		do ..svgGroup.setAttribute("width",..width)
		do ..topLevel.setAttribute("width",..width)
	} else {
		do ..svgGroup.setAttribute("width",100)
		do ..topLevel.setAttribute("width",100)
		
	}
	do ..svgGroup.setAttribute("viewBox",..calculateViewBox()) ; JMD1100 - this is in canvas in ZEN code
	do ..svgGroup.setAttribute("preserveAspectRatio","none")	
	Set defs=##class(node).%New()
	do defs.createElementSVG("defs")
	do ..svgGroup.appendChild(defs)
	do ..svgGroup.appendChild(pane)
	do ..topLevel.appendChild(..svgGroup)
	// create chart border
	Set border=##class(%ZEN.Report.Display.COSChart.node).%New()
	Do border.createElementSVG("rect")
	Do border.setAttribute("id",..makeId("border"))
	Do border.setAttribute("class","chart-border")
	Do border.setAttribute("style",..borderStyle)
	Do border.setAttribute("rx",..borderRadius)
	Do border.setAttribute("x",borderOffset)
	Do border.setAttribute("y",borderOffset)
	Do border.setAttribute("width",(100*scaleX)-(borderOffset*2))
	Do border.setAttribute("height",(100*scaleY)-(borderOffset*2))
	Do ..svgGroup.appendChild(border)
	
	// JMD1100
	Set this.%controlBarH = 0
	if (this.hasAxes() && this.hasZoom && 'this.isTimeBased() && 'this.chartPivot && (this.appearance = "2D")) {
		Set this.%controlBarH = 18
	}
	
	// new logic for SmallMultiples - JMD863, put in setting and looping 01/09/12
	Set multiples = 1
	Set rowCount = 1
	Set colCount = 1
	Set this.currMultiple = ""
#if 0
	s t=$io u 0 w !,"this.hasMultipes()="_this.hasMultiples()_" this.getSeriesCount()="_this.getSeriesCount() u t
#endif			
	
	if (this.hasMultiples()) {
		Set multiples = this.getSeriesCount()
		Set this.currMultiple = 0

		if (this.isTimeBased()) {
			Set rowCount = multiples
			Set colCount = 1
		} else {		
			// find number of rows and colums needed to display multiples
			if (this.width <= this.height) {
				Set colCount = $$$FLOOR($zsqr(multiples))
				Set rowCount = $$$CEIL(multiples/colCount)
			}
			else {
				// JMD1100: add 1 to force 3 items to use 2 rows
				Set rowCount = $$$FLOOR($zsqr(multiples+1))
				Set colCount = $$$CEIL(multiples/rowCount)
				
			}
		}
	}

	// if multiples, then loop
	Set oldGroup = this.svgGroup
	for r = 0:1:rowCount-1 {
		for c = 0:1:colCount-1 {
			if (this.hasMultiples()) {
				// create frame for multiple
				// var frame = this.document.createElementNS(SVGNS,"svg");
				Set frame=##class(%ZEN.Report.Display.COSChart.node).%New()
				do frame.createElementSVG("svg")
				//do frame.setAttribute("viewBox","0 0 100 100")
				// JMD1072
				// frame.setAttribute("preserveAspectRatio","none"); <-- commented out in JMD1100
				Set fh = 100 / rowCount
				Set fw = 100 / colCount
				
				do frame.setAttribute("x",c * fw * scaleX)
				do frame.setAttribute("y",r * fh * scaleY)
				do frame.setAttribute("width",fw * scaleX)
				do frame.setAttribute("height",fh * scaleY)
				do oldGroup.appendChild(frame)
				Set this.svgGroup = frame
				
				// reset scaling for multiple JMD1100
				Set this.%scaleX = scaleX / colCount
				Set this.%scaleY = scaleY / rowCount
			}


			// create title (and compute title height)
			Set titleH = ..renderTitle()

			if ..legendPosition = "bottom" || (..legendPosition = "top") || (..legendPosition = "left") {
				// calc legend width and height needed in calculate range values
				Do ..calculateLegendDimensions()
				// calculate ranges & other values needed for plotting (such as margins)
				Do ..calculateRangeValues() // need to calculate %plotBottom for renderLegend
			}

			// create legend (and compute right margin)
			Do ..renderLegend()

			// calculate ranges & other values needed for plotting (such as margins)
			if ..legendPosition '= "bottom",..legendPosition'="top",..legendPosition'="left" {
				Do ..calculateRangeValues()
			}

			// create grid (plot area)
			Do ..renderPlotArea()

			// final placement of title & legend
			Do ..adjustChartTitle()

			// plot series data (via subclass)
			Do ..renderSeriesGroup()
	
			// test for user callback
			if ("" '= this.onrenderData) {
				// pass old value along
				Set this.%oldXMax = oldXMax
				Set group = ..svgGroup.findSVGElement("seriesGroup"_this.currMultiple)
				do $zobjmethod(%report,this.onrenderData,this,group)
			}
			if (this.hasMultiples()) {
				Set this.currMultiple = this.currMultiple+1
				if (this.currMultiple>= multiples) quit
			}

		}
		if (this.hasMultiples() && (this.currMultiple>= multiples)) {
			quit
		}

	}
	// restore group
	Set this.svgGroup = oldGroup
	Set this.currMultiple = ""
	Set this.%scaleX = scaleX
	Set this.%scaleY = scaleY

	// control bar (zoom buttons)
	//if (this.hasAxes() && this.hasZoom && 'this.isTimeBased() && 'this.chartPivot && (this.appearance="2D")) {
		//do this.renderControlBar()
	//}
	quit Status
}

/// Get the current y Axis definition used for this chart.
/// <var>which</var> is "left" or "right".
Method getCurrYAxis(which)
{
	Set this=##this
	Set axisNo = 0
	
	// n.b. labelPosition can be ''
	Set which = $s('$D(which) : "left", 1 : which)
	if which="right" {
		if ((this.yAxisList.GetAt(this.currYAxis+1)'="") && (this.yAxisList.GetAt(this.currYAxis+1).labelPosition'="right")) {
			// find first right axis
			for n = 0:1:this.yAxisList.Count()-1 {
				if ((this.yAxisList.GetAt(n+1)'="") && (this.yAxisList.GetAt(n+1).labelPosition="right")) {
					Set axisNo = n
					quit
				}
			}
		}
		else {
			Set axisNo = this.currYAxis
		}
	} else {
		// JMD1208: for multiples, select y axis by multiple
		Set mAxisNo=""
		if (this.hasMultiples()) {
			Set t = ..split(..seriesYAxes,",")
			Set mAxisNo = $LG(t, this.currMultiple+1)
		}
		if mAxisNo'="" {
			Set axisNo = mAxisNo
		} else {
			if ((this.yAxisList.GetAt(this.currYAxis+1)'="") && (this.yAxisList.GetAt(this.currYAxis+1).labelPosition="right")) {
				// find first left axis
				for n = 0:1:this.yAxisList.Count()-1 {
					if ((this.yAxisList.GetAt(n+1)'="") && (this.yAxisList.GetAt(n+1).labelPosition="left")) {
						Set axisNo = n
						quit
					}
				}
			}
			else {
				Set axisNo = this.currYAxis
			}
		}
	}


	quit axisNo
}

/// Return the x Axis definition for this chart.
Method getXAxis()
{
	quit ..xAxis
}

/// Return the y Axis definition for this chart.
Method getYAxis(index)
{
	Set this=##this
	if (this.yAxis'="") {
		quit this.yAxis
	}
	Set index=$s('$D(index):this.currYAxis, 1:index)
	quit ..yAxisList.GetAt(index+1)
}

/// Return the number of y Axis definitions for this chart.
Method getYAxisCount()
{
	Set this=##this
	if (this.yAxis'="") {
		quit 1
	}
	quit $s($isObject(this.yAxisList)&&(this.yAxisList.Count()>0) : this.yAxisList.Count(), 1 : 1)
	;quit ..yAxisList.Count()
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType()
{
	quit "category"
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType()
{
	quit "value"
}

/// Return the x axis title.
Method getXAxisTitle()
{
	Set title = ""
	if ($IsObject(..xAxis) && (""'=..xAxis.title)) {
		Set title = ..xAxis.title
	}
	quit title
}

/// Return the y axis title.
Method getYAxisTitle(which)
{
	Set this=##this
	Set title = ""
	Set yAxis = this.getYAxis(this.getCurrYAxis(which))
	if ($IsObject(yAxis) && (""'=yAxis.title)) {
		Set title = yAxis.title
	} else {
		// JMD1208: for multiples, use series name
		if (this.hasMultiples()) {
			Set snames = this.getSeriesNames()
			Set sname = $LG(snames,this.currMultiple+1)
			Set title = $s(sname'="": sname, 1 : "")
		}
				
	}
	Quit title
}

/// Indicates whether this chart should be drawn with a 3-D
/// appearance.
Method is3D()
{
	quit ("3D" = ..appearance)
}

/// Internal method: Set up range and other information.
Method calculateRangeValues() [ Internal ]
{
	Set this=##this
	Set is3D = ..is3D()
	Set hasAxes = ..hasAxes()
	
	if (hasAxes) {
		do ..initializeAxisProperties()
		do ..calculateAxisConstraints()
	}

	// get corner points ("Out" is foreground for 3D)
	Set adj = $s(is3D : 5, 1:0)

	// look at xlabels first!
	if (this.%xLabelOnTheBottom) {
		Set xAHtop = (10/this.%scaleY)
		Set xAHbot = $s((hasAxes) : this.calculateXAxisHeight(), 1 : (10/this.%scaleY))
	}
	else {
		Set xAHtop = $s((hasAxes) : this.calculateXAxisHeight(), 1 : (10/this.%scaleY))
		Set xAHbot = (10/this.%scaleY)
	}

	Set ..%labelBottom = xAHbot // JSL4252
	
	// do we need to compute the size of the left margin?
	Set computeLeft = 0

	if (this.marginLeft="") {
		if (hasAxes && this.%yLabelOnTheLeft) {
			// compute size of left margin
			Set this.%marginLeft = this.calculateYAxisWidth("left") 
		}
		else {
			// JMD1100 10pixels
			Set this.%marginLeft = 10/this.%scaleX
			
		}
		// JMD1125- look at size of last x label
		if ((this.%firstXLabelWidth'="") && (this.%marginLeft<(this.%firstXLabelWidth/2))) {
			Set this.%marginLeft = this.%firstXLabelWidth/2
		}
		Set this.%marginLeft = this.%marginLeft + $s(..legendPosition="left":..%legendWidth,1:0)

	}
	else {
		Set this.%marginLeft = this.xToLogical(this.marginLeft)
	}
	// JMD1100 - test for size of right hand axis
	if (this.marginRight="") {
		if (hasAxes && this.%yLabelOnTheRight) {
			// compute size of right margin
			Set this.%marginRight = this.calculateYAxisWidth("right") + $s(this.%legendWidth'=""&&(..legendPosition'="left"):this.%legendWidth, 1:0)
		}
		else {
			// JMD1100
			Set this.%marginRight = $s(this.%legendWidth'=""&&(..legendPosition'="left"):this.%legendWidth, 1:(10/this.%scaleX))
		}
		// JMD1125- look at size of last x label
		if (this.%lastXLabelWidth'="") && (this.%marginRight<(this.%lastXLabelWidth*1.1)/2) {
			Set this.%marginRight = (this.%lastXLabelWidth*1.1)/2
		}

	}
	else {
		Set this.%marginRight = this.xToLogical(this.marginRight)
	}

	if ((this.%marginLeft + this.%marginRight) > 100) {
		Set this.%marginLeft = 100 - this.%marginRight
	}

	Set ..%plotLeftOut = ..%marginLeft
	Set ..%plotLeft = ..%plotLeftOut + adj
	Set ..%rplotRight = 100 - ..%marginRight
	Set ..%rplotRightOut = ..%rplotRight - adj
	Set ..%rplotWidth = (100 - (..%marginLeft + ..%marginRight + adj))

	if (hasAxes) {
		// width of virtual plot area (for scrolling) 
		Set hzScale = 1.0
		Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
		if (..hzZoomStep > 0) {
			// convert zoom step to scale factor
			Set itemsPerPage = $s(items # 2 : items+1, 1 : items)
			Set n = +..hzZoomStep
			Set ..hzZoomStep = 0
			while (n > 0 && (itemsPerPage >= 2)) {
				Set ..hzZoomStep = ..hzZoomStep+1
				Set itemsPerPage = $$$FLOOR(itemsPerPage/2)
				Set n = n -1
			}
			if (items > 0) { // add items>0 JSL4478
				Set hzScale = items / itemsPerPage
			} else {
				Set hzScale = 1 // JSL4478
			}
		}
		Set ..%plotWidth = ..%rplotWidth * hzScale
		Set ..%plotRight = ..%plotLeft + ..%plotWidth

		// number of zoom steps
		if (items > 0) { // JSL4478 - add items > 0
			Set ..%hzMaxStep = $$$FLOOR($zln(items)/$zln(2))
		} else {
			Set ..%hzMaxStep = 0 // JSL4478
		}

		// scrolling range
		Set ..%maxScrollLeft = ..%plotWidth - ..%rplotWidth
		Set ..scrollLeft = $s((..scrollLeft < 0) : 0, 1 : ..scrollLeft)
		Set ..scrollLeft = $s((..scrollLeft > ..%maxScrollLeft) : ..%maxScrollLeft, 1: ..scrollLeft)
	}
	else {
		Set ..%plotWidth = ..%rplotWidth
	}

	// set top margin
	if (""'=this.marginTop) {
		Set this.%marginTop = this.yToLogical(this.marginTop)
	}
	else {
		Set this.%marginTop = this.%titleHeight + xAHtop+$s(..legendPosition="top":..%legendHeight,1:0)
		if (this.%marginTop < 3) {
			// room for top of yAxis label!
			Set this.%marginTop = 3
		}
	}
	
	if (this.marginBottom="") {
		Set this.%marginBottom = xAHbot + (this.%controlBarH/this.%scaleY) + $s(..legendPosition="bottom":..%legendHeight,1:0)
	}
	else {
		Set this.%marginBottom = this.yToLogical(this.marginBottom) + (this.%controlBarH/this.%scaleY) 
	}

	if ((this.%marginBottom + this.%marginTop) > 100) {
		Set this.%marginBottom = 100 - this.%marginTop 
	}

	// apply defaults for missing values
	// top is set by renderTitle
	Set ..%plotTop = ..%marginTop
	Set ..%plotTopOut = ..%plotTop + adj
	Set ..%plotBottomOut = 100 - ..%marginBottom
	Set ..%plotBottom = ..%plotBottomOut - adj
	Set ..%plotHeight = (100 - (..%marginTop + ..%marginBottom + adj))
}

Method initializeAxisProperties()
{
	// units & grids
	Set this=##this
	Set this.%yMajorUnits="" ; empty list
	Set this.%yMinorUnits="" ; empty list
	Set this.%yLabelUnits="" ; empty list
	Set this.%yLabelAngle = "" ; empty list
	Set this.%yLabelStyle = "" ; empty list

	// JMD1100 Determine if there are left or right labels
	Set this.%yLabelOnTheRight = 0
	Set this.%yLabelOnTheLeft = 0
	Set this.%xLabelOnTheTop = 0
	Set this.%xLabelOnTheBottom = 0
	
	Set yaCount = this.getYAxisCount()
	for yAxisNo=1:1:yaCount {
		Set yAxis = this.getYAxis(yAxisNo-1)
		if ($isObject(yAxis) && (yAxis.labelPosition = "right")) {
			Set this.%yLabelOnTheRight = 1
		}
		else {
			Set this.%yLabelOnTheLeft = 1
		}
		Set $LI(this.%yMajorUnits,yAxisNo) = $s($IsObject(yAxis) : yAxis.majorUnits, 1 : "")
		Set $LI(this.%yMajorUnits,yAxisNo) = $s("" = $LG(this.%yMajorUnits,yAxisNo) : "", 1 : $LG(this.%yMajorUnits,yAxisNo))
		Set $LI(this.%yMinorUnits,yAxisNo) = $s($IsObject(yAxis) : yAxis.minorUnits, 1 : "")
		Set $LI(this.%yMinorUnits,yAxisNo) = $s("" = $LG(this.%yMinorUnits,yAxisNo) : "", 1 : $LG(this.%yMinorUnits,yAxisNo))
		Set $LI(this.%yLabelUnits,yAxisNo) = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.labelUnits, 1 : "")
		Set $LI(this.%yLabelUnits,yAxisNo) = $s("" = $LG(this.%yLabelUnits,yAxisNo) : $LG(this.%yMajorUnits,yAxisNo), 1 : $LG(this.%yLabelUnits,yAxisNo))
		
		Set $LI(this.%yLabelAngle,yAxisNo) = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.labelAngle, 1 : 0)
		Set $LI(this.%yLabelStyle,yAxisNo) = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.labelStyle, 1 : "")
	} // yAxisNo

	// left axis drives grid lines
	Set yAxis = this.getYAxis(this.getCurrYAxis("left"))

	Set ..%yMajorGrid = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.majorGridLines ,1: 1)
	Set ..%yMinorGrid = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.minorGridLines, 1 : 0)
	Set ..%yMajorGridStyle = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.majorGridStyle, 1 : "")
	Set ..%yMinorGridStyle = $s((yAxis'="")&&$IsObject(yAxis) : yAxis.minorGridStyle, 1 : "")

	if ($isObject(this.xAxis) && (this.xAxis.labelPosition="top")) {
		Set this.%xLabelOnTheTop = 1
	}
	else {
		Set this.%xLabelOnTheBottom = 1
	}


	Set ..%xMajorUnits = $s($isObject(..xAxis) : ..xAxis.majorUnits, 1 : "")
	Set ..%xMinorUnits = $s($isObject(..xAxis) : ..xAxis.minorUnits, 1 : "")
	Set ..%xLabelUnits = $s($isObject(..xAxis) : ..xAxis.labelUnits, 1 : "")
	Set ..%xLabelAngle = $s($isObject(..xAxis) : ..xAxis.labelAngle, 1 : 0)
	Set ..%xLabelStyle = $s($isObject(..xAxis) : ..xAxis.labelStyle, 1 : "")

	Set ..%xMajorGrid = $s($isObject(..xAxis) : ..xAxis.majorGridLines, 1 : 0)
	Set ..%xMinorGrid = $s($isObject(..xAxis) : ..xAxis.minorGridLines, 1 : 0)
	Set ..%xMajorGridStyle = $s($isObject(..xAxis) : ..xAxis.majorGridStyle, 1 : "")
	Set ..%xMinorGridStyle = $s($isObject(..xAxis) : ..xAxis.minorGridStyle, 1 : "")

	// figure out type of axes (category or value)
	Set ..%yGridType = ..getYAxisType()
	Set ..%xGridType = ..getXAxisType()
}

/// If the plot has axes, pre-calculate the internal values that will be used
/// to govern how those axes are rendered
Method calculateAxisConstraints()
{
	// ranges
	// get data range for chart
	// there can be multiple "scales" for y axis
	// we have to loop over these and compute them
	Set this=##this
	Set this.%yMaxValue = "" ; empty list
	Set this.%yMinValue = "" ; empty list
	Set this.%yBaseValue = "" ; empty list
	Set this.%yRange = ""
	Set xOnly = 0 ; false
	Set range = "" ; empty list
	
	// JMD1130 - look at axis first!
	// x (if value axis)
	Set ..%xBaseValue = $s($isObject(..xAxis) : ..xAxis.baseValue, 1 : "")
	Set ..%xMinValue = $s($isObject(..xAxis) : ..xAxis.minValue, 1 : "")
	Set ..%xMaxValue = $s($isObject(..xAxis) : ..xAxis.maxValue, 1 : "")
	

	Set yaCount = this.getYAxisCount()
	if ("category"=this.%yGridType) && ("value"=this.%xGridType) {
		// get range for xAxis
		Set range(0) = this.findDataRange(-1)
		Set xOnly = 1
	}
	else {
		for yAxisNo=1:1:yaCount {
			// get data range(s) for chart
			// must be in local array so Oref will be usuable, findDataRange returns Oref/Object
			Set range(yAxisNo-1) = this.findDataRange(yAxisNo-1)
		}
	}

	for yAxisNo=1:1:yaCount {
		// JMD1271: get min/max from axis
		Set yAxis = ..getYAxis(yAxisNo-1)
		Set $LI(..%yBaseValue,yAxisNo) = $S($isObject(yAxis) : yAxis.baseValue, 1 : "")
		Set $LI(..%yMinValue,yAxisNo) = $S($isObject(yAxis) : yAxis.minValue, 1 : "")
		Set $LI(..%yMaxValue,yAxisNo) = $S($isObject(yAxis) : yAxis.maxValue, 1 : "")

		// units
		if (("value"=..%yGridType) && $$$ISNAN($$$PARSEFLOAT($LG(..%yMajorUnits,yAxisNo)))) {
			// figure out units automatically
			if ('..usePercentForRange()) {
				Set max = $s($$$ISNAN($$$PARSEFLOAT($LG(..%yMaxValue,yAxisNo))) : range(yAxisNo-1).maxValue, 1 : $LG(..%yMaxValue,yAxisNo))
				Set min = $s($$$ISNAN($$$PARSEFLOAT($LG(..%yMinValue,yAxisNo))) : range(yAxisNo-1).minValue, 1 : $LG(..%yMinValue,yAxisNo))
				Set max = $s($$$ISNAN(max) : 0, 1 : max)
				Set min = $s($$$ISNAN(min) : 0, 1 : min)
				Set scale = ..findScaleUnits(max - min)
			} else {
				Set max = 100
				Set min = 0
				Set scale = 20
			}
			Set $LI(..%yMajorUnits,yAxisNo) = scale
			if ($$$ISNAN($$$PARSEFLOAT($LG(..%yLabelUnits,yAxisNo)))) {
				Set $LI(..%yLabelUnits,yAxisNo) = $LG(..%yMajorUnits,yAxisNo)
			}

			if ($$$ISNAN($$$PARSEFLOAT($LG(..%yMinorUnits,yAxisNo)))) {
				Set $LI(..%yMinorUnits,yAxisNo) = $LG(..%yMajorUnits,yAxisNo) / 5
			}
		}
		elseif (("category"=..%yGridType) && $$$ISNAN($$$PARSEFLOAT($LG(..%yMajorUnits,yAxisNo)))) {
			Set scale = 1
			Set size = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
			Set f = $s(((size#5)=0) : 5, 1 : 2)
			while (size/scale > 10) {
				Set scale = scale * f
			}
			Set $LI(..%yMajorUnits,yAxisNo) = scale
			if ($$$ISNAN($$$PARSEFLOAT($LG(..%yLabelUnits,yAxisNo)))) {
				Set $LI(..%yLabelUnits,yAxisNo) = 1
			}
		}
	} // yAxisNo
	
	if ("value"=..%xGridType && $$$ISNAN($$$PARSEFLOAT(..%xMajorUnits))) {
		// figure out units automatically
		if ("value"=..%yGridType) {
			// x/y type chart
			Set max = $s($$$ISNAN($$$PARSEFLOAT(..%xMaxValue)) : $$$PARSEFLOAT(range(0).maxValue2), 1 : ..%xMaxValue)
			Set min = $s($$$ISNAN($$$PARSEFLOAT(..%xMinValue)) : $$$PARSEFLOAT(range(0).minValue2), 1 : ..%xMinValue)
		}
		else {
			Set max = $s($$$ISNAN($$$PARSEFLOAT(..%xMaxValue)) : $$$PARSEFLOAT(range(0).maxValue), 1 : ..%xMaxValue)
			Set min = $s($$$ISNAN($$$PARSEFLOAT(..%xMinValue)) : $$$PARSEFLOAT(range(0).minValue), 1 : ..%xMinValue)
		}
		if ('..usePercentForRange()) {
			Set max = $s($$$ISNAN(max) : 0, 1 : max)
			Set min = $s($$$ISNAN(min) : 0, 1 : min)
			Set scale = ..findScaleUnits(max - min)
		} else {
			Set max=100
			Set min=0
			Set scale=20
		}

		Set ..%xMajorUnits = scale
		if ($$$ISNAN($$$PARSEFLOAT(..%xLabelUnits))) {
			Set ..%xLabelUnits = ..%xMajorUnits
		}

		if ($$$ISNAN($$$PARSEFLOAT(..%xMinorUnits))) {
			Set ..%xMinorUnits = ..%xMajorUnits / 5
		}
	}
	elseif ("category"=..%xGridType && $$$ISNAN($$$PARSEFLOAT(..%xMajorUnits))) {
		Set ..%xMajorUnits = 1
		Set ..%xLabelUnits = 1
	}

	// min/max values
	Set this.%yBaseValue = "" ; empty list
	Set this.%yMinValue = "" ; empty list
	Set this.%yMaxValue = "" ; empty list
	Set this.%yRange = "" ; empty list
	
	Set useSum = this.useSumForRange()
	
	if ('xOnly) {		
		for yAxisNo=1:1:yaCount {	
			Set yAxis= this.getYAxis(yAxisNo-1)
			Set $LI(..%yBaseValue,yAxisNo) = $s($isObject(yAxis) : yAxis.baseValue, 1 : "")
			Set $LI(..%yMinValue,yAxisNo) = $s($isObject(yAxis) : yAxis.minValue, 1 : "")
			Set $LI(..%yMaxValue,yAxisNo) = $s($isObject(yAxis) : yAxis.maxValue,1 : "")
			if ((useSum||($$$PARSEFLOAT(range(yAxisNo-1).minValue)<0)) && ($LG(this.%yBaseValue,yAxisNo)="")) {
				// JMD1125: for stacked chart, default base to 0
				// JMD1130: or if minvalue is negative
				Set $LI(this.%yBaseValue,yAxisNo) = 0
			}

			if ($$$ISNAN($$$PARSEFLOAT($LG(..%yMinValue,yAxisNo)))) {
				// auto
				// round down to next major units (use base if present)
				// JMD1125 changes code below so we always go to "else" condition
				Set val = $s(0 && ..useSumForRange() : $s($$$ISNAN($$$PARSEFLOAT($LG(..%yBaseValue,yAxisNo))): range(yAxisNo-1).minValue, 1 : $LG(..%yBaseValue,yAxisNo)), 1 : range(yAxisNo-1).minValue)
				if (0'=$LG(..%yMajorUnits,yAxisNo)) {
					Set val = $$$FLOOR(val / $LG(..%yMajorUnits,yAxisNo)) * $LG(..%yMajorUnits,yAxisNo)
				}
				Set $LI(..%yMinValue,yAxisNo) = val
			}
			if ($$$ISNAN($$$PARSEFLOAT($LG(..%yMaxValue,yAxisNo)))) {
				// auto
				// round up to next major units
				Set val = range(yAxisNo-1).maxValue
				if (0'=$LG(..%yMajorUnits,yAxisNo)) {
					Set val = $$$CEIL((val*1.01) / $LG(..%yMajorUnits,yAxisNo)) * $LG(..%yMajorUnits,yAxisNo)
				}
				Set $LI(..%yMaxValue,yAxisNo) = val
			}

			Set $LI(..%yRange,yAxisNo) = ($LG(..%yMaxValue,yAxisNo) - $LG(..%yMinValue,yAxisNo))
		} // yAxisNo
	}
	
	if ((useSum||($$$PARSEFLOAT(range(0).minValue)<0)) && (this.%xBaseValue="")) {
		// JMD1125: for stacked chart, default base to 0
		// JMD1130: or if minvalue is negative
		Set this.%xBaseValue = 0
	}
	
	if (this.isTimeBased()) {

		// JMD1130 find start/end times for x axis
		Set items = this.getSeriesSize()
		for n = 0:1:items-1 {
			Set time = this.getXLabelText(n)
			Set d = ##class(%ZEN.Report.Display.COSChart.Date).stringToDate(time)
			if (d '="") {
				// JMD1130(3) test for hours/minutes
				Set hms = $LG(..split(time," "),2)
				if (hms'="") {
					Set t = ..split(hms,":")
					if ($LG(t,1)'="") {	do d.setHours($$$PARSEINT($LG(t,1)))}
					if ($LG(t,2)'="") {	do d.setMinutes($$$PARSEINT($LG(t,2)))}
					if ($LG(t,3)'="") {	do d.setSeconds($$$PARSEINT($LG(t,3)))}
				}
				
				Set val = d.getTime()/1000
				Set ..%xMinValue = $s($$$ISNAN($$$PARSEFLOAT(..%xMinValue)) : val, 1 : $s((val < ..%xMinValue) : val, 1 : ..%xMinValue))
				Set ..%xMaxValue = $s($$$ISNAN($$$PARSEFLOAT(..%xMaxValue)) : val, 1 : $s((val > ..%xMaxValue) : val, 1 : ..%xMaxValue))
			}
		}
		Set ..%xRange = (..%xMaxValue - ..%xMinValue)
	}
	else {
		if ($$$ISNAN($$$PARSEFLOAT(..%xMinValue))) {
			// auto
			// round down to next major units (use base if present)
			if ("value"=..%yGridType) {
				Set val = range(0).minValue2
			}
			else {
				Set val = $s((0&&this.useSumForRange()) : $s($$$ISNAN($$$PARSEFLOAT(this.%xBaseValue)) : range(0).minValue, 1 : ..%xBaseValue), 1 : range(0).minValue)
			}
			if (0'=..%xMajorUnits) {
				Set val = $$$FLOOR(val / ..%xMajorUnits) * ..%xMajorUnits
			}
			Set ..%xMinValue = val
		}
		if ($$$ISNAN($$$PARSEFLOAT(..%xMaxValue))) {
			// auto
			// round up to next major units
			Set val = $s("value"=..%yGridType : range(0).maxValue2, 1 : range(0).maxValue)
			if (0'=..%xMajorUnits) {
				Set val = $$$CEIL(val / ..%xMajorUnits) * ..%xMajorUnits
			}
			Set ..%xMaxValue = val
		}
		if (this.chartPivot && this.valueLabelsVisible && this.usePercentForRange()) { // if we have horizontal value labels, and we are a percentage bar-chart, allow some room at right to place them
			Set ..%xMaxValue = ..%xMaxValue * 1.1
		}
		Set ..%xRange = (..%xMaxValue - ..%xMinValue)
	}
}

/// Internal method: Find best scale units to use for given value.
Method findScaleUnits(val) [ Internal ]
{
	Set scale = 0

	if (val > 0) {
		Set log = $zlog(val)
		Set f = $$$FLOOR(log)
		if ((log - f) > .65) {
			Set scale = $zpower(10,f+1) / 5
		}
		elseif ((log - f) > .3) {
			Set scale = ($zpower(10,f) * 5) / 10
		}
		else {
			Set scale = ($zpower(10,f) * 2) / 4
		}
	}

	quit scale
}

/// Draw the plot area of the chart.
Method renderPlotArea()
{
	Set this=##this
	Set is3D = ..is3D()

	// create
	Set plotAreaGroup=##class(%ZEN.Report.Display.COSChart.node).%New()
	do plotAreaGroup.createElementSVG("g")
	do plotAreaGroup.setAttribute("id",..makeId("plotAreaGroup"_this.currMultiple))
	do ..svgGroup.appendChild(plotAreaGroup)
	// JMD1100
	Set scaleX = $s(this.%scaleX'="" : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY'="" : this.%scaleY, 1 : 1)


	Set rect=##class(%ZEN.Report.Display.COSChart.node).%New()
	do rect.createElementSVG("rect")
	do rect.setAttribute("id",..makeId("plotArea"_this.currMultiple))
	do plotAreaGroup.appendChild(rect)

	// edges (3D)
	Set edgeLeft=##class(%ZEN.Report.Display.COSChart.node).%New()
	do edgeLeft.createElementSVG("path")
	do edgeLeft.setAttribute("id",..makeId("edgeLeft"_this.currMultiple))
	do plotAreaGroup.appendChild(edgeLeft)

	Set edgeBottom = ##class(%ZEN.Report.Display.COSChart.node).%New()
	do edgeBottom.createElementSVG("path")
	do edgeBottom.setAttribute("id",..makeId("edgeBottom"_this.currMultiple))
	do plotAreaGroup.appendChild(edgeBottom)


	do rect.setAttribute("class","chart-plotArea")
	do rect.setAttribute("style",..plotAreaStyle)
	do rect.setAttribute("x",this.%plotLeft*scaleX)
	do rect.setAttribute("y",this.%plotTop*scaleY)
	do rect.setAttribute("width",this.%rplotWidth*scaleX)
	do rect.setAttribute("height",this.%plotHeight*scaleY)
	
	// edges (for 3D)
	if ('..is3D()) {
		do edgeLeft.setAttribute("visibility","hidden")
		do edgeBottom.setAttribute("visibility","hidden")
	}
	else {
		do edgeLeft.setAttribute("class","chart-plotEdge")
		do edgeLeft.setAttribute("style","opacity: 0.5;" _ this.plotEdgeStyle)
		do edgeLeft.setAttribute("d","M "_(this.%plotLeftOut*scaleX)_" "_(this.%plotTopOut*scaleY)_" L "_(this.%plotLeft*scaleX)_" "_(this.%plotTop*scaleY)_" "_(this.%plotLeft*scaleX)_" "_(this.%plotBottom*scaleY)_" "_(this.%plotLeftOut*scaleX)_" "_(this.%plotBottomOut*scaleY)_" z") 
		do edgeLeft.setAttribute("visibility","visible")

		do edgeBottom.setAttribute("class","chart-plotEdge")
		do edgeBottom.setAttribute("style",..plotEdgeStyle)
		do edgeBottom.setAttribute("d","M "_(this.%plotLeftOut*scaleX)_" "_(this.%plotBottomOut*scaleY)_" L "_(this.%plotLeft*scaleX)_" "_(this.%plotBottom*scaleY)_" "_(this.%rplotRight*scaleX)_" "_(this.%plotBottom*scaleY)_" "_(this.%rplotRightOut*scaleX)_" "_(this.%plotBottomOut*scaleY)_" z") ; JMD1100
		do edgeBottom.setAttribute("visibility","visible")
	}

	// svg group to clip items in virtual plot area
	// JMD1100: do not clip if 3D
	if ("3D" = this.appearance) {
		//Set clipGroup = this.document.createElementNS(SVGNS,"g")
		Set clipGroup=##class(%ZEN.Report.Display.COSChart.node).%New()
		Do clipGroup.createElementSVG("g")

	}
	else {
		//Set clipGroup = this.document.createElementNS(SVGNS,"svg")
		Set clipGroup=##class(%ZEN.Report.Display.COSChart.node).%New()
		Do clipGroup.createElementSVG("svg")
		
	} ; JDM1100

	do clipGroup.setAttribute("id",..makeId("clipGroup"_this.currMultiple))
	do plotAreaGroup.appendChild(clipGroup)

	// group to hold items in virtual plot area
	Set virtualGroup = ##class(%ZEN.Report.Display.COSChart.node).%New()
	do virtualGroup.createElementSVG("g")
	do virtualGroup.setAttribute("id",..makeId("virtualGroup"_this.currMultiple))
	do clipGroup.appendChild(virtualGroup)

	// clip group for x labels
	Set clipLabelGroup = ##class(%ZEN.Report.Display.COSChart.node).%New()
	do clipLabelGroup.createElementSVG("svg")
	do clipLabelGroup.setAttribute("id",..makeId("clipLabelGroup"_this.currMultiple))
	do plotAreaGroup.appendChild(clipLabelGroup)

	// group to hold x axis labels
	Set virtualLabelGroup = ##class(%ZEN.Report.Display.COSChart.node).%New()
	do virtualLabelGroup.createElementSVG("g")
	do virtualLabelGroup.setAttribute("id",..makeId("virtualLabelGroup"_this.currMultiple))
	do clipLabelGroup.appendChild(virtualLabelGroup)

	
	// provide extra space for x labels
	// JMD1100
	Set this.%labelPadL = $s(this.plotToEdge : 5, 1 : 4)
	Set this.%labelPadR = this.%labelPadL
	if (this.isTimeBased()) { 
		Set this.%labelPadL = 0 ; JMD1130 pt2
		Set this.%labelPadR = 0
	} ; JMD1100

	// JMD1100
	do virtualGroup.setAttribute("transform","translate(" _ (-($$$PARSEFLOAT(this.scrollLeft)*scaleX)) _ ",0)") ; '+
	do virtualLabelGroup.setAttribute("transform","translate(" _ (-(($$$PARSEFLOAT(this.scrollLeft)-this.%labelPadL)*scaleX)) _ ",0)") ; JMD1100

	if ("3D" = this.appearance) {
		do clipGroup.setAttribute("transform","translate(" _ (this.%plotLeft*scaleX) _ ",0)")
	}
	else {
		do clipGroup.setAttribute("x",..%plotLeft*scaleX)
		do clipGroup.setAttribute("y",0)
		do clipGroup.setAttribute("height",100*scaleY)
		do clipGroup.setAttribute("width",..%rplotWidth*scaleX)
	} ; JMD1100
	// JMD1100
	do clipLabelGroup.setAttribute("x",(this.%plotLeft - this.%labelPadL)*scaleX)
	do clipLabelGroup.setAttribute("y",0*scaleY)
	do clipLabelGroup.setAttribute("height",100*scaleY)
	do clipLabelGroup.setAttribute("width",(this.%rplotWidth + ((this.%labelPadL+this.%labelPadR))*scaleX)) ; JMD1100


	// if we have axes, draw them
	// (some charts, like pie charts, do not have axes)
	if (..hasAxes()) {
		// draw upper/lower bands and left/right binds
		do ..renderBands()

#if 0
		// test for user callback
		if ("" '= ..onrenderPlotArea) {
			do zenInvokeCallbackMethod(..onrenderPlotArea,this,"onrenderPlotArea","chart",this)
		}
#endif		

		// draw axes and grid lines
		do ..renderAxes()

		// labels
		// JMD1100 test for right/left labels
		if (this.%yLabelOnTheLeft) {
			do this.renderYLabels("left")
		}
		if (this.%yLabelOnTheRight) {
			do this.renderYLabels("right")
		} ; JMD1100
		do ..renderXLabels()
	}

	// axis lines
	Set axisLines = ##class(%ZEN.Report.Display.COSChart.node).%New()
	do axisLines.createElementSVG("path")
	do axisLines.setAttribute("id",..makeId("axisLines"_this.currMultiple))
	do plotAreaGroup.appendChild(axisLines)


	if (..hasAxes()) {
		// axis lines
		do axisLines.setAttribute("visibility","visible")
		do axisLines.setAttribute("class","chart-axisLines")
		do axisLines.setAttribute("style",..axisLineStyle)
		do axisLines.setAttribute("d","M "_(..%plotLeftOut*scaleX)_" "_(..%plotTopOut*scaleY)_" L "_(..%plotLeftOut*scaleX)_" "_(..%plotBottomOut*scaleY)_" Z M "_(this.%plotLeftOut*scaleX)_" "_(this.%plotBottomOut*scaleY)_" L "_(this.%rplotRightOut*scaleX)_" "_(this.%plotBottomOut*scaleY))
	}
	else {
		do axisLines.setAttribute("visibility","hidden")
	}
	// display warning message JSL4478
	//+ JSL4478
	if (this.warnIfNoData) { // JSL4478
		if ((this.getSeriesSize() = 0) || ((this.getSeriesSize() = 1)&&(this.getSeriesCount()=1)&&($g(this.%dataSeries(0,0))=""))) {
			Set debug= 1
			Set text = ..svgGroup.findSVGElement("textIfNoData"_this.currMultiple)
			if (text = "") {
				Set text=##class(%ZEN.Report.Display.COSChart.node).%New()
				do text.createElementSVG("text")

				do text.setAttribute("id",this.makeId("textIfNoData"_this.currMultiple))
				do text.setText(this.msgIfNoData)
				if (debug) {
					Set debugrect=##class(%ZEN.Report.Display.COSChart.node).%New()
					do debugrect.createElementSVG("rect")
					do debugrect.setAttribute("id",this.makeId("rectIfNoData"_this.currMultiple))
					do plotAreaGroup.appendChild(debugrect)
				}
				
			} else {
				Set debugrect = ..svgGroup.findSVGElement("rectIfNoData"_this.currMultiple)
			}
			do plotAreaGroup.appendChild(text)

			//text.setAttribute("class","chart-warnifnodata");
			//text.setAttribute("style","fill:white;font-size:12px");
			do text.setAttribute("stroke",..noDataStroke)
			do text.setAttribute("fill","none")
			do text.setAttribute("font-size","12px") // needed for bbox!!!
			//text.setAttribute("text-anchor","center");
			Set bbox = ..GetBBox(text, 0, 1, 1,"start")
			Set xtext = $$$PARSEFLOAT(clipGroup.getAttribute("x"))
			Set ytext = $$$PARSEFLOAT(clipGroup.getAttribute("y"))
			Set width = $$$PARSEFLOAT(clipGroup.getAttribute("width"))
			Set height = $$$PARSEFLOAT(clipGroup.getAttribute("height"))
			//alert("xtext="+xtext+" width="+width+" bbox.width="+bbox.width);
			do text.setAttribute("x",xtext+(width/2)-(bbox.width/2))
			do text.setAttribute("y",ytext+(height/2))
			if (debug) {
				do debugrect.setAttribute("x",xtext+(width/2)-(bbox.width/2)-2)
				do debugrect.setAttribute("y",ytext+(height/2) - bbox.height+2)
				do debugrect.setAttribute("width",bbox.width+2)
				do debugrect.setAttribute("height",bbox.height+2)
				do debugrect.setAttribute("opacity",..noDataOpacity)
				do debugrect.setAttribute("fill",..noDataFill)
			}
		} 
		
	} //-JSL4478
}

/// Indicates that this chart has axes and associated grids
/// A subclass may override this to turn off axis display.
Method hasAxes()
{
	quit 1
}

/// Test if a time-based x axis should be used.
/// This is overridden in subclasses.
Method isTimeBased()
{
	quit 0
}

/// Draw the x and y axes and grid lines.
Method renderAxes()
{
	Set this=##this
	Set is3D = ..is3D()

	Set plotAreaGroup = ..svgGroup.findSVGElement("plotAreaGroup"_this.currMultiple)
	Set virtualGroup = ..svgGroup.findSVGElement("virtualGroup"_this.currMultiple)
	//$$$ASSERT($isObject(plotAreaGroup))
	;zenASSERT(plotAreaGroup,'Unable to find plotAreaGroup',arguments);
	// JMD1100
	Set scaleX = $s(this.%scaleX'="" : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY'="" : this.%scaleY, 1 : 1) ; JMD1100

	// y grid stripes
	Set ystripes = ""
	if (..stripesVisible) {
		Set ystripes = ..svgGroup.findSVGElement("yGridStripes"_this.currMultiple)
		if ("" = ystripes) {
			Set ystripes=##class(%ZEN.Report.Display.COSChart.node).%New()
			do ystripes.createElementSVG("path")
			do ystripes.setAttribute("class","chart-gridStripes")
			do ystripes.setAttribute("id",..makeId("yGridStripes")_this.currMultiple)
			do virtualGroup.appendChild(ystripes)
		}
		do ystripes.setAttribute("style",..stripeStyle)
	}

	// x grid stripes
	Set xstripes = ""
	if (..stripesVisible) {
		Set xstripes = ..svgGroup.findSVGElement("xGridStripes"_this.currMultiple)
		if ("" = xstripes) {
			Set xstripes=##class(%ZEN.Report.Display.COSChart.node).%New()
			do xstripes.createElementSVG("path")
			do xstripes.setAttribute("class","chart-gridStripes")
			do xstripes.setAttribute("id",..makeId("xGridStripes"_this.currMultiple))
			do virtualGroup.appendChild(xstripes)
		}
		do xstripes.setAttribute("style",..stripeStyle)
	}

	// y major grid path
	Set ygrid = ..svgGroup.findSVGElement("yGridLine"_this.currMultiple)
	if ("" = ygrid) {
		Set ygrid=##class(%ZEN.Report.Display.COSChart.node).%New()
		do ygrid.createElementSVG("path")
		do ygrid.setAttribute("class","chart-majorGridLine")
		do ygrid.setAttribute("id",..makeId("yGridLine"_this.currMultiple))
		do virtualGroup.appendChild(ygrid)
	}
	do ygrid.setAttribute("style",this.gridStyle _ this.%yMajorGridStyle _ "fill:none;")

	// y minor grid path
	Set ygridMinor = ..svgGroup.findSVGElement("yGridLineMinor"_this.currMultiple)
	if ("" = ygridMinor) {
		Set ygridMinor =##class(%ZEN.Report.Display.COSChart.node).%New()
		do ygridMinor.createElementSVG("path")
		do ygridMinor.setAttribute("class","chart-minorGridLine")
		do ygridMinor.setAttribute("id",..makeId("yGridLineMinor"_this.currMultiple))
		do virtualGroup.appendChild(ygridMinor)
	}
	do ygridMinor.setAttribute("style",..gridStyle _ ..%yMinorGridStyle _ "fill:none;")

	// x major grid path
	Set xgrid = ..svgGroup.findSVGElement("xGridLine")
	if ("" = xgrid) {
		Set xgrid =##class(%ZEN.Report.Display.COSChart.node).%New()
		do xgrid.createElementSVG("path")
		do xgrid.setAttribute("class","chart-majorGridLine")
		do xgrid.setAttribute("id",..makeId("xGridLine"_this.currMultiple))
		do virtualGroup.appendChild(xgrid)
	}
	do xgrid.setAttribute("style",..gridStyle _ ..%xMajorGridStyle _ "fill:none;") ; JMD1100

	// x minor grid path
	Set xgridMinor = ..svgGroup.findSVGElement("xGridLineMinor"_this.currMultiple)
	if ("" = xgridMinor) {
		Set xgridMinor=##class(%ZEN.Report.Display.COSChart.node).%New()
		do xgridMinor.createElementSVG("path")
		do xgridMinor.setAttribute("class","chart-minorGridLine")
		do xgridMinor.setAttribute("id",..makeId("xGridLineMinor"_this.currMultiple))
		do virtualGroup.appendChild(xgridMinor)
	}
	do xgridMinor.setAttribute("style",..gridStyle _ ..%xMinorGridStyle _ "fill:none;") ; JMD1100

	// y axis
	// left axis drives grid
	Set yAxisNo = this.getCurrYAxis("left") ; JMD1100

	
	// create gridlines
	// find set of values that correspond with "unit" size
	// and fit within range
	if (..%yGridType = "value") {
		// yMajor
		Set d = ""
		Set sd = ""
		if (..%yMajorGrid && ($LG(..%yMajorUnits,yAxisNo+1) > 0)) {
			Set start = $$$CEIL($zabs($LG(..%yMinValue,yAxisNo+1)/$LG(..%yMajorUnits,yAxisNo+1)))*$LG(..%yMajorUnits,yAxisNo+1)*$s($LG(..%yMinValue,yAxisNo+1)>=0 : 1,1: -1)
			Set end = $$$FLOOR($zabs($LG(..%yMaxValue,yAxisNo+1)/$LG(..%yMajorUnits,yAxisNo+1)))*$LG(..%yMajorUnits,yAxisNo+1)*$s($LG(..%yMaxValue,yAxisNo+1)>=0 : 1, 1: -1)
			Set limit = 0
			Set lastY = ""
			Set v = start for {  q:'((v <= end)&&(limit < 200))
				Set y = ..getPlotY(v,yAxisNo)
				if (y < ..%plotBottomOut) {
					if (is3D) {
						Set d =  d _ " M " _ (-5*scaleX) _ " " _ ((y+5)*scaleY) _ " L " ; JMD1100
					}
					else {
						Set d = d_" M "
					}
					//d += 0 + ' ' + y*scaleY + ' L ' + ((this._plotRight-(is3D?6:0))*scaleX) + ' ' + y*scaleY;
					Set d = d_ 0 _ " " _ (y*scaleY) _ " L " _ ((this.%plotWidth)*scaleX) _ " " _ (y*scaleY) ; JMD1100


					if (lastY '= "") {
						Set sd = sd_" M "
						Set sd = sd _ 0 _ " " _ (lastY*scaleY) _ " L " _ ((this.%plotWidth)*scaleX) _ " " _ (lastY*scaleY) ; JMD1100
						Set sd = sd _ " " _ ((this.%plotWidth)*scaleX) _ " " _ (y*scaleY) _ " L " _ 0 _ " " _ (y*scaleY) _ " z" ; JMD1100
						Set lastY = ""
					}
					else {
						Set lastY = y
					}
				}
				Set v = v + $LG(..%yMajorUnits,yAxisNo+1)
				Set limit=limit + 1
			}
		}
		if ("" '= d) {
			do ygrid.setAttribute("d",d)
			do ygrid.setAttribute("visibility","visible")
		}
		else {
			do ygrid.setAttribute("visibility","hidden")
		}
		do ygrid.setAttribute("fill","none")

		if (ystripes && ("" '= sd)) {
			do ystripes.setAttribute("d",sd)
			do ystripes.setAttribute("visibility","visible")
		}
	
		// yMinor
		Set d = ""
		if (..%yMinorGrid && ($LG(..%yMinorUnits,yAxisNo+1) > 0)) {
			Set start = $$$CEIL($zabs($LG(..%yMinValue,yAxisNo+1)/$LG(..%yMinorUnits,yAxisNo+1)))*$LG(..%yMinorUnits,yAxisNo+1)*$s($LG(..%yMinValue,yAxisNo+1)>=0 : 1,1 : -1)
			Set end = $$$FLOOR($zabs($LG(..%yMaxValue,yAxisNo+1)/$LG(..%yMinorUnits,yAxisNo+1)))*$LG(..%yMinorUnits,yAxisNo+1)*$s($LG(..%yMaxValue,yAxisNo+1)>=0 : 1,1 : -1)
			Set limit = 0
			Set v = start
			while (v <= end && (limit < 200)) {
				Set y = ..getPlotY(v,yAxisNo)
				if (y < ..%plotBottomOut) {
					Set d = d _ " M " _ 0 _ " " _ (y*scaleY) _ " L " _ ((this.%plotWidth)*scaleX) _ " " _ (y*scaleY) ; JMD1100
				}
				Set v = v+ $LG(..%yMinorUnits,yAxisNo+1), limit= limit+1
			}
		}
		if ("" '= d) {
			do ygridMinor.setAttribute("d",d)
			do ygridMinor.setAttribute("visibility","visible")
		}
		else {
			do ygridMinor.setAttribute("visibility","hidden")
		}
	}
	else {
		// y category axis
		// find # of items and split axis evenly
		Set d = ""
		Set dmin = ""
		Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
		Set items = $s(..plotToEdge : items-1,1 : items)
		if (items > 0 && (this.%plotHeight>0)) {
			Set y = ..%plotTop
			Set dy = ..%plotHeight / items
			Set n =1
			while ((n < items)) {
				Set y = y + dy
				if (..%yMajorGrid && ($LG(..%yMajorUnits,yAxisNo+1)>0) && ((n#$LG(..%yMajorUnits,yAxisNo+1))=0)) {
					if (is3D) {
 						//Set d = d_" M " _ ..%plotLeftOut _ " " + (y+5) _ " L "
						Set d = d _ " M " _ (-1*(..%plotLeftOut/2)*scaleX) _ " " _ ((y+5)*scaleY) _ " L "
					}
					else {
						Set d = d_" M "
					}
					Set d = d _ 0 _ " " _ (y*scaleY) _ " L " _ (..%plotRight*scaleX) _ " " _ (y * scaleY) ; JMD1100
				}
				if (..%yMinorGrid && ($LG(..%yMinorUnits,yAxisNo+1)>0) && ((n#$LG(..%yMinorUnits,yAxisNo+1)) =0)) {
					Set dmin =  dmin_" M "_0 _" "_(y*scaleY)_" L "_(..%plotRight*scaleX) _" "_(y*scaleY) ; JMD1100
				}
				Set n=n+1
			}
		}

		if ("" '= d) {
			do ygrid.setAttribute("d",d)
			do ygrid.setAttribute("visibility","visible")
		}
		else {
			do ygrid.setAttribute("visibility","hidden")
		}
		do ygrid.setAttribute("fill","none")
		if ("" '= dmin) {
			do ygridMinor.setAttribute("d",dmin)
			do ygridMinor.setAttribute("visibility","visible")
		}
		else {
			do ygridMinor.setAttribute("visibility","hidden")
		}
	}
	if (this.isTimeBased()) { ; JMD1100
		// do nothing
	}
	elseif (..%xGridType = "value") {
		// xMajor
		Set d = ""
		Set sd = ""
		if (..%xMajorGrid && (..%xMajorUnits > 0)) {
			Set start = $$$CEIL($zabs(..%xMinValue/..%xMajorUnits))*..%xMajorUnits*$s(..%xMinValue>=0 : 1, 1 : -1)
			Set end = $$$FLOOR($zabs(..%xMaxValue/..%xMajorUnits))*..%xMajorUnits*$s(..%xMaxValue>=0 : 1, 1 : -1)
			Set limit = 0
			Set lastX = ""
			Set v = start
			while ( v <= end && (limit < 200)) {
				Set x = ..getPlotX(v) - ..%plotLeft
				Set d = d_ " M "_(x*scaleX)_" "_(..%plotTop*scaleY)_" L "_(x*scaleX)_" "_(..%plotBottom*scaleY)
				if (is3D) {
					Set d = d_" "_((x-5)*scaleX)_" "_(..%plotBottomOut*scaleY)
				}

				if (lastX '= "") {
					Set sd = sd_" M "
					Set sd = sd_(lastX*scaleX)_" "_(..%plotTop*scaleY)_" L "_(lastX*scaleX)_" "_(..%plotBottom*scaleY) ; JMD1100
					Set sd = sd_" "_(x*scaleX)_" "_(..%plotBottom*scaleY)_" L "_(x*scaleX)_" "_(..%plotTop*scaleY)_" z" ; JMD1100
					Set lastX = ""
				}
				else {
					Set lastX = x
				}
				Set v = v+ ..%xMajorUnits, limit=limit+1
			}
		}
		if ("" '= d) {
			do xgrid.setAttribute("d",d)
			do xgrid.setAttribute("visibility","visible")
		}
		else {
			do xgrid.setAttribute("visibility","hidden")
		}
		do xgrid.setAttribute("fill","none")

		if (xstripes && ("" '= sd)) {
			do xstripes.setAttribute("d",sd)
			do xstripes.setAttribute("visibility","visible")
		}

		// xMinor
		Set d = ""
		if (..%xMinorGrid && (..%xMinorUnits > 0)) {
			Set start = $$$CEIL($zabs(..%xMinValue/..%xMinorUnits))*..%xMinorUnits*$s(..%xMinValue>=0 : 1, 1 : -1)
			Set end = $$$FLOOR($zabs(..%xMaxValue/..%xMinorUnits))*..%xMinorUnits*$s(..%xMaxValue>=0 : 1, 1 :  -1)
			Set limit = 0
			Set v = start
			while (v <= end && (limit < 200)) {
				Set x = ..getPlotX(v) - ..%plotLeft
				Set d = d_" M "_(x*scaleX)_" "_(..%plotTop*scaleY)_" L "_(x*scaleX)_" "_(..%plotBottom*scaleY) ; JMD1100
				Set v = v+ ..%xMinorUnits, limit= limit+1
			}
		}
		if ("" '= d) {
			do xgridMinor.setAttribute("d",d)
			do xgridMinor.setAttribute("visibility","visible")
		}
		else {
			do xgridMinor.setAttribute("visibility","hidden")
		}
	}
	else {
		// x category axis
		// find # of items and split axis evenly
		Set d = ""
		Set dmin = ""
		Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
		Set items = $s(..plotToEdge : items-1 , 1: items)
		if (items > 0) {
			Set x = 0
			Set dx = ..%plotWidth / items
			Set n = 1
			while (n < items) {
				Set x = x + dx
				if (..%xMajorGrid && (..%xMajorUnits>0) && (((n#..%xMajorUnits) =0))) {
					Set d = d_" M "_(x*scaleX)_" "_(..%plotTop*scaleY)_" L "_(x*scaleX)_" "_(..%plotBottom*scaleY) ; JMD1100
					if (is3D) {
						Set d = d_" "_((x-5)*scaleX)_" "_(..%plotBottomOut*scaleY) ; JMD1100
					}				}
				if (..%xMinorGrid && (..%xMinorUnits>0) && (((n#..%xMinorUnits) =0))) {
					Set dmin = dmin_" M "_(x*scaleX)_" "_(..%plotTop*scaleY)_" L "_(x*scaleX)_" "_(..%plotBottom*scaleY)
				}
				Set n=n+1
			}
		}

		if ("" '= d) {
			do xgrid.setAttribute("d",d)
			do xgrid.setAttribute("visibility","visible")
		}
		else {
			do xgrid.setAttribute("visibility","hidden")
		}
		do xgrid.setAttribute("fill","none")

		if ("" '= dmin) {
			do xgridMinor.setAttribute("d",dmin)
			do xgridMinor.setAttribute("visibility","visible")
		}
		else {
			do xgridMinor.setAttribute("visibility","hidden")
		}
	}
}

/// Prepare the axis group for population with axis information
Method prepareAxisGroup(idName, parentNode)
{
	Set this=##this
	Set group = ..svgGroup.findSVGElement(idName_this.currMultiple)

	if ("" = group) {
		// create group to hold labels
		Set group = ##class(node).%New()
		do group.createElementSVG("g")
		do group.setAttribute("id",..makeId(idName_this.currMultiple))
		do parentNode.appendChild(group)
	}

	// clear out children of this group
	do ..removeChildNodes(group)
	
	quit group
}

Method createXLabelNode(index, fontSize, style, angle, group)
{
	Set align="middle"
	if (angle="") Set angle=0
	// JMD1125 change -60 to 90 except in one place
	if ($$$ISNAN(angle)) Set angle=-60
	if (angle<-90) Set angle=-90
	if (angle>0) Set angle=0
	if (angle'=0)&&(..oldLabelCalc) {
		Set align="end"
	}
	
	// JMD1125 - make alignment be start for angle of -90
	if (angle=-90) {
		Set align="start"
	}
	
	Set lbl = ..getXLabelText(index)
	// JMD1182: apply style in function call
	Set text = ..createSVGTextNode(lbl,fontSize,..autoScaleText,align,angle,group,"chart-xLabel",style)
	//do text.setAttribute("class","chart-xLabel")
	//do ..embedStyle(text.firstChild(),style)
	quit (text)
}

Method calculateXAxisTitleHeight()
{
	Set this=##this
	// JMD1100 return height
	Set hgt = 0
	Set xAxisTitle = this.getXAxisTitle()
	
	// height of x axis title
	if (xAxisTitle'="")	{
		// find size of axis title
		Set hgt = ..renderXAxisTitle(..svgGroup)
		Set xt = ..svgGroup.findSVGElement("xAxisTitle"_this.currMultiple)
		do ..svgGroup.removeChild(xt)
	}
	quit hgt
}

Method calculateXAxisHeight()
{
	Set this=##this
	Set idx="" ; list
	Set lWidth="" ; list
	Set maxWidth = 0
	Set maxHeight = 0
	Set dx = 0

	// JMD1125
	Set this.%firstXLabelWidth = ""
	Set this.%lastXLabelWidth = ""

	// JMD1125: as side effect compute width of first and last labels
	// to help with margin computation

	// we might not know plot width yet!
	Set plotWidth = $s(this.%plotWidth'="" : this.%plotWidth, 1 : 100)

	if (this.isTimeBased()) { // JMD1100
		Set maxHeight = 20/this.%scaleY 
	} else {
		// create new labels
		if (..labelsVisible && (..%xLabelUnits > 0)) {
			Set tStyle = ..computeStyle("chart-xLabel","")
			if (this.labelStyle'="") do this.integrateStyleSpec(tStyle,this.labelStyle)
			if (..%xLabelStyle'="") do ..integrateStyleSpec(tStyle,..%xLabelStyle)
			Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16)

			Set txtH = fSz
			if ('..autoScaleText) {
				Set txtH = fSz*..getPelToPixelVRatio()
			}
			Set ..%xAxisLabelH = txtH

			Set angle = 0
			if (..%xLabelAngle'="") Set angle= -..%xLabelAngle
			
			if (..%xGridType = "value") {
				// value labels
				Set start = $$$CEIL($zabs(..%xMinValue/..%xLabelUnits))*..%xLabelUnits*$s(..%xMinValue>=0 : 1, 1 : -1)
				Set end = $$$FLOOR($zabs(..%xMaxValue/..%xLabelUnits))*..%xLabelUnits*$s(..%xMaxValue>=0 : 1, 1 : -1)
				Set dx = ..getPlotX(start + ..%xLabelUnits) - ..getPlotX(start)
				Set limit = 0
				Set v = start
				while ( v <= end && (limit < 100)) {
					Set $LI(idx,limit+1)=v // zero-based
					Set text =..createXLabelNode(v, fSz, tStyle, 0, ..svgGroup)
					Set $LI(lWidth,limit+1) = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
					if ($LI(lWidth,limit+1)>maxWidth) Set maxWidth=$LI(lWidth,limit+1)
					do ..svgGroup.removeChild(text)
					
					// JMD1125
					if (v=start) {
						Set this.%firstXLabelWidth = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
					}
					elseif (v>=end) {
						Set this.%lastXLabelWidth = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
					}
					
					Set v = v+ ..%xLabelUnits, limit = limit+1
				}
			}
			else {
				// category labels
				Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
				if (..plotToEdge) {
					// JMD1125 - don't use member variable
					//Set dx = $s((items<=1) : (..%plotWidth/2), 1 : (..%plotWidth / (items-1)))
					Set dx = $s((items<=1) : (plotWidth/2), 1 : (plotWidth / (items-1)))
				}
				else {
					// JMD1125 - don't use member variable
					//Set dx = $s((items<=1) : (..%plotWidth/2), 1 : (..%plotWidth / items))
					Set dx = $s((items<=1) : (plotWidth/2), 1 : (plotWidth / items))
				}
				Set limit = 0
				Set n = 0
				while ( n < items) {
					if ((n#..%xLabelUnits) =0) {
						Set $LI(idx,limit+1)=n
						Set text =..createXLabelNode(n, fSz, tStyle, 0, ..svgGroup)
						Set $LI(lWidth,limit+1) = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
						if ($LI(lWidth,limit+1)>maxWidth) Set maxWidth=$LI(lWidth,limit+1)
						do ..svgGroup.removeChild(text)
						Set limit = limit+1
					}
					Set n=n+1
				}
			}
			if (dx<maxWidth) { // Houston, we have a problem...
				if ('..autoScaleText || (..%xGridType '= "value") ) {	
					Set nDx = dx
					// JMD1125 - scale dx
					if ('..autoScaleText) Set nDx = (dx*..%scaleX)/..getPelToPixelHRatio()
					/*
					if ((nDx'=0)&&((fSz/nDx) <= 1.0)) {
						Set angle = -$zarcsin(fSz/nDx)*180/$ZPI
					} else {
						Set angle = "NaN" ; emulate JavaScript Math.asin
					}
					*/
					// JMD1125 - always use right angle
					// always use right angle
					Set angle = -90
				}
			}
			Set n=0
			while (n<$LL(idx)) {
				Set text =..createXLabelNode($LI(idx,n+1), fSz, tStyle, angle, ..svgGroup)
				Set h = $$$PARSEFLOAT(text.getAttribute("effectiveHeight"))

				// JMD1125
				if (this.plotToEdge) {
					if (n=0) {
						Set this.%firstXLabelWidth = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
					}
					elseif (n>=($LL(idx)-1)) {
						Set this.%lastXLabelWidth = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
					}
				}

				if (h>maxHeight) Set maxHeight = h
				do ..svgGroup.removeChild(text)
				Set n = n + 1
			}
		}
	}
	Set xAxisTitleH = ..calculateXAxisTitleHeight()
	
	Set this.%maxXHeight = maxHeight
	
	
	Set tH = (xAxisTitleH*1.1) + (maxHeight*1.1) + (2*..getPelToPixelVRatio())
	quit (tH)
}

/// Draw the title section for the Y axis (if any) and
/// return the height reserved for the rendering
Method renderXAxisTitle(group)
{
	Set this=##this
	Set titleAdj=0
	Set xt = ..svgGroup.findSVGElement("xAxisTitle"_this.currMultiple)
	if (xt'="") {
		do ..svgGroup.removeChild(xt)
	}

	Set xAxisTitle = this.getXAxisTitle() ; JMD1100
	if ("" '= xAxisTitle) { ; JMD1100
		Set tStyle = ..computeStyle("chart-xAxisTitle","")
		// JMD1125 comments out two lines below
		//if (..%xLabelStyle'="") do ..integrateStyleSpec(tStyle,..%xLabelStyle)
		//if (..labelStyle'="") do ..integrateStyleSpec(tStyle,..labelStyle)
		if (..axisTitleStyle'="") do ..integrateStyleSpec(tStyle,..axisTitleStyle)
		Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16) ; JMD1100

		// Create and add to yLabelGroup a new scaled text node
		Set text = ..createSVGTextNode(xAxisTitle,fSz,..autoScaleText,"middle",0,group)
		do text.setAttribute("id",..makeId("xAxisTitle"_this.currMultiple))
		do text.setAttribute("class","chart-xAxisTitle")
		do ..embedStyle(text.firstChild(),tStyle)

		Set tx = ..%plotLeftOut + (..%rplotWidth/2)
		// JMD1100 (2) place label on top or bottom; place smarter
		if (this.%xLabelOnTheTop) {
			Set ty = this.%plotTopOut - $s(this.%maxXHeight'="" : this.%maxXHeight, 1 : 2)
		}
		else {
			// 4 pixels from bottom
			Set ty = 100 - (4/this.%scaleY)
		} 
		Set titleAdj = $$$PARSEFLOAT(text.getAttribute("logicalHeight"))+(2*..getPelToPixelVRatio())
		do text.setAttribute("transform","translate("_(tx*this.%scaleX)_","_(ty*this.%scaleY)_")")
	}
	quit (titleAdj)
}

/// Draw the labels for the x axis.
Method renderXLabels()
{
	Set this=##this
	Set is3D = ..is3D()

	Set virtualLabelGroup = ..svgGroup.findSVGElement("virtualLabelGroup"_this.currMultiple)
	Set xLabelGroup = ..prepareAxisGroup("xLabelGroup",virtualLabelGroup)

	// axis title
	do ..renderXAxisTitle(..svgGroup)
	
	// create new labels
	if ('..labelsVisible) {
		if (this.isTimeBased()) {
			// JMD1368: make sure time line is computed
			do this.computeXAxisTimeLine()
		}
	}
	elseif (..labelsVisible && (..%xLabelUnits > 0)) {
		Set tStyle = ..computeStyle("chart-xLabel","")
		if (..labelStyle'="") do ..integrateStyleSpec(tStyle,..labelStyle)
		if (..%xLabelStyle'="") do ..integrateStyleSpec(tStyle,..%xLabelStyle)
		Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16)

		Set th = fSz
		if ('..autoScaleText) {
			Set th = fSz*..getPelToPixelVRatio()
		}

		Set angle = 0
		if (..%xLabelAngle'="") Set angle= -..%xLabelAngle

		if (this.%xLabelOnTheTop) { // JMD1100
			Set y = this.%plotTopOut 
		}
		else {
			Set y = this.%plotBottomOut
		}
	
	
		Set rotated = (..%xLabelAngle '= "" && (..%xLabelAngle '= 0))

	// DO this in two passes, the first figures out what we want to print and how big it is
	// the second tries to fit it in the space available
		Set idx=""
		Set lWidth=""
		Set maxWidth = 0
		Set dx = 0
		Set adj = 0

		// JMD1100 dispatch for time axis
		if (this.isTimeBased()) {
			do this.computeXAxisTimeLine()
			do this.renderXAxisTimeLine(xLabelGroup,this.%plotBottomOut)
		}
		elseif (..%xGridType = "value") {
			// value labels
			Set start = $$$CEIL($zabs(..%xMinValue/..%xLabelUnits))*..%xLabelUnits*$s(..%xMinValue>=0 : 1, 1 : -1)
			Set end = $$$FLOOR($zabs(..%xMaxValue/..%xLabelUnits))*..%xLabelUnits*$s(..%xMaxValue>=0 : 1, 1 : -1)
			Set dx = ..getPlotX(start + ..%xLabelUnits) - ..getPlotX(start)
			Set limit = 0
			Set v = start
			while ( v <= end && (limit < 100)) {
				Set $LI(idx,limit+1)=v // 0 based
				Set text =..createXLabelNode(v, fSz, tStyle, 0, ..svgGroup)
				Set $LI(lWidth,limit+1) = $$$PARSEFLOAT(text.getAttribute("LogicalWidth"))
				if ($LI(lWidth,limit+1)>maxWidth) Set maxWidth=$LI(lWidth,limit+1)
				do ..svgGroup.removeChild(text)
				Set v = v + ..%xLabelUnits
				Set limit=limit+1
			}
		}
		else {
			// category labels
			Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
			if (..plotToEdge) {
				Set dx = $s((items<=1) : (..%plotWidth/2), 1 : (..%plotWidth / (items-1)))
				Set adj = $s((items<=1) : 0, 1 : dx)
			}
			else {
				Set dx = $s((items<=1) : (..%plotWidth/2), 1 : (..%plotWidth / items))
				;Set adj = $s((items<=1) : 0, 1 : $s(is3D:dx, 1:dx/2)) ; JMD1100
				Set adj = $s((items<=1) : 0, 1 : $s(is3D:dx,1:dx/2)) ; TBD - why does restoring old behavior work?
			}
			Set limit = 0
			Set n = 0
			while( n < items) {
				if ((n#..%xLabelUnits) =0) {
					Set $LI(idx,limit+1)=n // 0 based
					Set text = ..createXLabelNode(n, fSz, tStyle, 0, ..svgGroup)
					Set $LI(lWidth,limit+1) = $$$PARSEFLOAT(text.getAttribute("logicalWidth"))
					if ($LI(lWidth,limit+1)>maxWidth) Set maxWidth=$LI(lWidth,limit+1)
					do ..svgGroup.removeChild(text)
					Set n=n+1, limit=limit+1
				}
			}
		}
/// IF all went as expected, the idx array should have the indices of the labels we'd like
/// to print, the lWidth array should have the native widths of each label and maxWidth should
/// be the length of the longest label.	Now we need to print them.
		if ($LL(idx)=0) quit

		Set skip = 1
		if (dx<maxWidth) { // Houston, we have a problem...
			if ('..autoScaleText || (..%xGridType '= "value") ) {
				Set nDx = dx
				// JMD1125 scale dx
				if ('..autoScaleText) Set nDx = (dx*this.%scaleX)/..getPelToPixelHRatio()
				/*
				if ((nDx'=0) && ((fSz/nDx)<=1.0)) {
					Set angle = -$zarcsin(fSz/nDx)*180/$ZPI
				} else {
					Set angle = "NaN" ; emulate JavaScript Math.asin
				}
				*/
				// JMD1125: only use right angle
				Set angle = -90
				if ($$$ISNAN(angle)) {
					if (..%xGridType = "value") {
						Set skip=$$$CEIL(fSz/nDx)
					}
					else { // need to squish font
						Set fSz = nDx
					}
				}
			}
			else {
				Set skip = $$$CEIL(maxWidth/dx)
			}
		}
		if (skip>($LL(idx)-1)) Set skip = $LL(idx)-1
		if (skip=0) Set skip=1 ; Fix Prodlog 97436 <DIVIDE> error from skip=0, JavaScript code has NaN with mod operator

		Set x=0
		Set n=0
		while(n<$LL(idx)) {
			if (..%xGridType = "value") {
				Set x = ..getPlotX($LI(idx,n+1))+ $s((is3D&&..chartPivot) : -5, 1:0) - ..%plotLeft
			}
			else {
				Set x = x + dx
			}	
			if ((n#skip)=0) {
				Set text =this.createXLabelNode($LI(idx,n+1), fSz, tStyle, angle, xLabelGroup) // JSL for JMD1100 - this was left out, probably smooshed while editing
				// JMD1100 turn off yAdj; use th correctly
				// TBD - we go back to old logic and now labels placed properly
				if ('..oldLabelCalc) {
					Set yAdj = 0 // $$$PARSEFLOAT(text.getAttribute("yOffset"))
				} else {
					Set yAdj = $$$PARSEFLOAT(text.getAttribute("yOffset"))/..%scaleY
				}
				Set th = $$$PARSEFLOAT(text.getAttribute("effectiveHeight"))
				Set ofs = 0
				if (angle'=0) {
					// JMD1125
					//Set ofs = $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))+$$$PARSEFLOAT(text.getAttribute("xOffset"))
					Set yAdj = -2
					Set ofs = -2 / ..%scaleX
				} else {
					// JMD1320: center 3d labels
					if (is3D && '..plotToEdge) {
						Set ofs = -$$$PARSEFLOAT(text.getAttribute("effectiveWidth"))/2
					}
				}
				if (this.%xLabelOnTheTop) {
					do text.setAttribute("transform","translate(" _ ((x-adj-ofs)*this.%scaleX) _ "," _ ((y*this.%scaleY)-1) _ ")") ; JMD1100
				}
				else {
					if ('..oldLabelCalc) {
						do text.setAttribute("transform","translate(" _ ((x-adj-ofs)*this.%scaleX) _ "," _ ((y + th-yAdj)*this.%scaleY) _ ")") ; JMD1100 
					} else {
						do text.setAttribute("transform","translate(" _ ((x-adj-ofs)*this.%scaleX) _ "," _ ((y -yAdj)*this.%scaleY) _ ")") ; TBD - why does old behavior work?
					}
				}
				
			}
			Set n=n+1
		}
	}
}

/// This is the core of the vertical decimation algorithm.  Given a maximum number of label
/// to choose from an array,  pick a subset that will (hopefully) use the available
/// space effectively and keep things visually balanced.
Method pickVerticalSkips(flag, max)
{
	Set fl = $LL(flag)
	if (max>=fl || (fl<3)) { //room to show everyone
		Set i=1
		while (i<fl) {
			Set $LI(flag,i+1)=1 ; 0 based
			Set i=i+1
		}
		quit
	}

	// The first and last flags should always be set so point at the middle
	Set $LI(flag,0+1) = 1
	Set $LI(flag,fl-1+1) = 1
	Set max = max - 2
	Set sIdx=1
	Set eIdx=fl-2

	// If we're skipping at all we need to do at least every other one
	// or we risk overlap.  This means the items next to the end points
	// do not display, the range gets smaller.
	Set $LI(flag,sIdx+1)=0
	Set sIdx=sIdx+1
	Set $LI(flag,eIdx+1)=0
	Set eIdx=eIdx-1
	
	// See what we've got left to choose from
	Set seriesSpan = (eIdx-sIdx+1)

	// Get real max number of labels if we were to skip every other one
	Set rMax = $$$CEIL(seriesSpan/2)

	// If we asked for more labels than the practical max then clip it
	// to what we can show, we can't play with label spacing arbitrarily,
	// either the label's there or it isn't.
	if (max>rMax) {
		// Room to spare with skip one treatment.  Mark every other
		// label for printing.
		Set show=1
		Set i=sIdx
		while(i<=eIdx) {
			Set $LI(flag,i+1) = show
			Set show = 1-show
			Set i=i+1
		}
		quit
	}	
	else {
		// Okay printing every other label would still take too much 
		// room.  Time to pretend that we are clever...
		
		// Put back the two spaces we skipped earlier
		Set sIdx = sIdx - 1
		Set eIdx = eIdx + 1
		Set seriesSpan= seriesSpan+2

		// Get the number of labels we're NOT printing
		Set nSkip=seriesSpan-max
		// Get the number of clusters of skipped labels
		Set nSpans = max+1
		// Get (roughly) the number of labels skipped in each cluster
		Set skipGap = $$$FLOOR(nSkip/nSpans)
		// Account for any uneven division
		Set fill = nSkip-(nSpans*skipGap)
		// And figure out where to put the excess fill back in
		Set padIdx=$$$ROUND(nSpans-fill)/2
		Set i=sIdx
		Set spanCount=0
		while (i<=eIdx && (max>0)) {
			// First mark the skipped elements
			Set j=0
			while (j<skipGap) {
				Set $LI(flag,i+1) = 0
				Set i=i+1
				Set j=j+1
			}
			// If there's filling to be done add it in
			if (fill>0 && (spanCount>=padIdx)) {
				Set $LI(flag,i+1) = 0
				Set i=i+1
				Set fill=fill-1
			}
			// Update skip index to next span
			Set spanCount=spanCount+1
			// Enable the next label
			Set $LI(flag,i+1) = 1
			Set i=i+1
			// Count down the label left to go
			Set max = max -1
		}
	}
}

/// Internal method to calculate how much room should be reserved 
/// for the Y axis area.  This includes both the axis title and
/// the individual labels
Method calculateYAxisWidth(which) [ Internal ]
{
	Set this=##this
	
	// scale group for left y Axis
	Set yAxisNo = this.getCurrYAxis(which) ; JMD1100
	set yAxisTitle = this.getYAxisTitle(which) ; JMD1100 11:37 AM

	Set w=0
	Set is3D = ..is3D()
	Set group = ..prepareAxisGroup("yLabelGroup"_which,..svgGroup)

	if ("" '= yAxisTitle) {
		Set tStyle = ..computeStyle("chart-yAxisTitle","")
		// JMD1125
		//if ($LG(..%yLabelStyle,(yAxisNo+1))'="") do ..integrateStyleSpec(tStyle,$LG(..%yLabelStyle,(yAxisNo+1)))
		if (..axisTitleStyle'="") do ..integrateStyleSpec(tStyle,..axisTitleStyle)
		Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16)
		
		// Create and add to yLabelGroup a new scaled text node
		Set text = ..createSVGTextNode(yAxisTitle,fSz,..autoScaleText,"middle",-90,group)
		do text.setAttribute("class","chart-yAxisTitle")
		do ..embedStyle(text.firstChild(),tStyle)
		
		Set w = w + ($$$PARSEFLOAT(text.getAttribute("effectiveWidth"))*1.1)
	}
	
	// scale group for left y Axis
	;Set yAxisNo = ..currYAxis
	
	Set mW = 0
	if (..labelsVisible ) {
		Set tStyle = ..computeStyle("chart-yLabel","")
		if (this.labelStyle'="") do this.integrateStyleSpec(tStyle,this.labelStyle) // JMD1100
		if ($LG(..%yLabelStyle,yAxisNo+1)'="") do ..integrateStyleSpec(tStyle,$LG(..%yLabelStyle,yAxisNo+1))
		Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16)
		Set tw = 0
		Set rotate = ($LG(..%yLabelAngle,yAxisNo+1) '= "" && ($LG(..%yLabelAngle,(yAxisNo+1)) '= 0))
		Set angle = 0
		if ($LI(..%yLabelAngle,yAxisNo+1)'="") Set angle= -$LG(..%yLabelAngle,(yAxisNo+1))
		if (angle>0) Set angle = 0
		if (angle<-60) Set angle = -60

		if (..%yGridType = "value" && ($LG(..%yLabelUnits,yAxisNo+1) '= 0)) {
			Set start = $$$CEIL($zabs($LG(..%yMinValue,yAxisNo+1)/$LG(..%yLabelUnits,yAxisNo+1)))*$LG(..%yLabelUnits,yAxisNo+1)*$s($LG(..%yMinValue,yAxisNo+1)>=0 : 1, 1 : -1)
			Set end = $$$FLOOR($zabs($LG(..%yMaxValue,yAxisNo+1)/$LG(..%yLabelUnits,yAxisNo+1)))*$LG(..%yLabelUnits,yAxisNo+1)*$s($LG(..%yMaxValue,yAxisNo+1)>=0 : 1, 1 : -1)
			Set limit = 0
			Set v = start
			while ( v <= end && (limit < 100)) {
				Set lbl = ..getYLabelText(v)
				Set text = ..createSVGTextNode(lbl,fSz,..autoScaleText, "end", angle, group)
				do text.setAttribute("class","chart-yLabel")
				do ..embedStyle(text.firstChild(),tStyle)
				Set tw = $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))
				Set mW = $s((mW < tw) : tw, 1 : mW)
				Set v = v+ $LG(..%yLabelUnits,yAxisNo+1), limit = limit + 1
			}
		}
		else {
			// category labels
			Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
			if (items > 0) {								
				Set n = 0
				while ( n < items) {
					Set lbl = ..getYLabelText(n,yAxisNo)
					Set text = ..createSVGTextNode(lbl,fSz,..autoScaleText, "end", angle, group)
					do text.setAttribute("class","chart-yLabel")
					do ..embedStyle(text.firstChild(),tStyle)
					Set tw = $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))
					Set mW = $s((mW < tw) : tw, 1 : mW)
					Set n=n+1
				}
			}
		}
	}

	Set w = w+ mW+1.5
	do ..prepareAxisGroup("yLabelGroup"_which)
	Set w = $s(w > 50 : 50, 1 : w)
	quit (w)
}

/// Draw the title section for the Y axis (if any) and
/// return the width reserved for the rendering
Method renderYAxisTitle(group, which, xpos)
{
	Set this=##this
	Set yAxisTitle = this.getYAxisTitle(which)
	if ("" '= yAxisTitle) {
		Set yAxisNo = this.getCurrYAxis(which)
		Set tStyle = ..computeStyle("chart-yAxisTitle","")
		// JMD1125
		//if (..labelStyle'="") do ..integrateStyleSpec(tStyle,..labelStyle)
		//if ($LG(..%yLabelStyle,yAxisNo+1)'="") do ..integrateStyleSpec(tStyle,$LG(..%yLabelStyle,yAxisNo+1))
		if (..axisTitleStyle'="") do ..integrateStyleSpec(tStyle,..axisTitleStyle)
		Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16)
		
		// Create and add to yLabelGroup a new scaled text node
		Set angle = $s(which="right" : 90, 1 : -90) ; JMD1100

		Set text = ..createSVGTextNode(yAxisTitle,fSz,..autoScaleText,"middle",angle,group)
		do text.setAttribute("class","chart-yAxisTitle")
		do ..embedStyle(text.firstChild(),tStyle)
		
		Set ty = ..%plotTopOut + (..%plotHeight/2)
		if (which="right") {
			Set tx = xpos
			Set tx = 100 - (text.getAttribute("effectiveWidth")*1.1)
		}
		else {
			Set tx = $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))*1.1
		}
		do text.setAttribute("transform","translate("_(tx*this.%scaleX)_","_(ty*this.%scaleY)_")")
		quit (tx)
	}
	quit (0)
}

/// Draw the labels for the y axis.
/// If <var>test</var> is true, then this is a "test" plot to determine
/// the max width of the labels.
Method renderYLabels(which)
{
	Set this=##this
	// JMD1100 -- remove *test* argument
	Set is3D = ..is3D()
	
	// JMD1100 which is 'left' or 'right'
	Set which = $s('$D(which) : "left", 1 : which)

	Set yLabelGroup = ..prepareAxisGroup("yLabelGroup"_which,..svgGroup)
	//Set titleAdj = ..renderYAxisTitle(yLabelGroup) JMD1100?

	// create new labels
	Set maxWidth = 0
	
	// scale group for y axis
	Set yAxisNo = this.getCurrYAxis(which) ; JMD1100

	if (..labelsVisible && ($LG(..%yLabelUnits,yAxisNo+1) > 0)) {
		Set tStyle = ..computeStyle("chart-yLabel","")
		if (..labelStyle'="") do ..integrateStyleSpec(tStyle,..labelStyle)
		if ($LG(..%yLabelStyle,yAxisNo+1)'="") do ..integrateStyleSpec(tStyle,$LG(..%yLabelStyle,yAxisNo+1))
		Set fSz = ..getComputedFontSize(tStyle, 12, 8, 16)

		Set xoffPix = 5/this.%scaleX	// pixel offset
		;Set xoffPix = 2/this.%scaleX	// pixel offset JSL experiment
		Set tx = $s(which="left" : (this.%plotLeftOut-xoffPix), 1:(this.%rplotRightOut+xoffPix+$s(is3D:5, 1:0)))

		Set tw = 0
	
		Set rotate = ($LG(..%yLabelAngle,yAxisNo+1) '= "" && ($LG(..%yLabelAngle,yAxisNo+1) '= 0))

		Set angle = 0
		if ($LG(..%yLabelAngle,yAxisNo+1)'="") Set angle= -$LG(..%yLabelAngle,yAxisNo+1)
		if (angle>0) Set angle = 0
		if (angle<-60) Set angle = -60

		if (..%yGridType = "value" && ($LG(..%yLabelUnits,yAxisNo+1) '= 0)) {

			Set start = $$$CEIL($zabs($LG(..%yMinValue,yAxisNo+1)/$LG(..%yLabelUnits,yAxisNo+1)))*$LG(..%yLabelUnits,yAxisNo+1)*$s($LG(..%yMinValue,yAxisNo+1)>=0 : 1, 1 : -1)
			Set end = $$$FLOOR($zabs($LG(..%yMaxValue,yAxisNo+1)/$LG(..%yLabelUnits,yAxisNo+1)))*$LG(..%yLabelUnits,yAxisNo+1)*$s($LG(..%yMaxValue,yAxisNo+1)>=0 : 1, 1 : -1)
	
			Set lbl = ""
			Set show = ""

			Set limit = 0
			Set v = start
			while ( v <= end && (limit < 100)) {
				Set $LI(lbl,limit+1) = ..getYLabelText(v,yAxisNo)
				if (..autoScaleText) { Set $LI(show,limit+1)=1 }
				else { Set $LI(show,limit+1)=0 }
				Set v = v+ $LG(..%yLabelUnits,yAxisNo+1), limit = limit + 1
			}
			
			if ('..autoScaleText) {			
				Set vSpace = (fSz*..getPelToPixelVRatio()*1.23)
				if (angle'=0) {
					set aRad = $ZPI * (angle/180)
					Set cos = $zcos(aRad)
					Set vSpace = vSpace/cos
				}
				do ..pickVerticalSkips(show,$$$FLOOR((..%plotHeight*..%scaleY)/vSpace))
			}
			
			Set limit = 0
			Set v = start
			while (v <= end && (limit < 100)) {
				if ($LI(show,limit+1)=1) {
					Set y = this.getPlotY(v,yAxisNo) + $s((is3D&&'this.chartPivot&&(which="left")) : 5, 1:0)
					Set text = this.createSVGTextNode($LI(lbl,limit+1),fSz,this.autoScaleText, $s(which="left":"end", 1:"start"), angle, yLabelGroup) ; JMD1100 12:38 PM
					do text.setAttribute("class","chart-yLabel")
					do ..embedStyle(text.firstChild(),tStyle)
					Set ty = y+1
					do text.setAttribute("transform","translate("_(tx*this.%scaleX)_","_(ty*this.%scaleY)_")")
							
					Set tw = $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))
					Set maxWidth = $s((maxWidth < tw) : tw, 1 : maxWidth)
					
				}
				Set v = v + $LG(..%yLabelUnits,yAxisNo+1), limit = limit + 1
			}
		}

		else {
			// category labels must always show
			// if autoScaleText, just render and let user solve the problem by
			// fiddling with font size.
			// if not autoScaleText, and the area is too crunched, find a new font
			// size that will fit the available space.
			Set items = $s('..usePercentForRange():..getSeriesSize(),1:..getSeriesCount())
			if ((items > 0) && (..%plotHeight>0)) {
				if (..plotToEdge) {
					Set dy = $s((items<=1) : (..%plotHeight/2), 1: (..%plotHeight / (items-1)))
					Set adj = $s((items<=1) : 0, 1 : dy)
				}
				else {
					Set dy = $s((items<=1) : (..%plotHeight/2), 1 : (..%plotHeight / items))
					Set adj = $s((items<=1) : 0, 1 : dy/2)
				}

				Set y = ..%plotTopOut
				Set lastY = y
				Set th = 0

				if ('..autoScaleText) {
					Set mFZ = (dy*..%scaleY)/..getPelToPixelVRatio()*1.23
					if (fSz>mFZ) {
						Set fSz = mFZ/1.23
					}
				}
				Set n = 1
				while( n <= items) {
					Set y = y + dy
					Set text = ..createSVGTextNode(..getYLabelText(n-1,yAxisNo),fSz,..autoScaleText, $s(which="left":"end", 1:"start"), angle, yLabelGroup)
					do text.setAttribute("class","chart-yLabel")
					// JMD1125
					do ..embedStyle(text.firstChild(),tStyle)

					if (angle=0) {
						Set lh = text.getAttribute("logicalHeight")
						//Set th = (0.25*lh)+((dy-lh)/5)						
						// JMD1125 simplify
						Set th = lh/3
						
					}
					Set ty = y - adj + th

					do text.setAttribute("transform","translate("_(tx*this.%scaleX)_","_(ty*this.%scaleY)_")")
					Set lastY = y
					Set n=n+1
				}
			}
		}
	} else {
		Set xoffPix=0
	}
	do this.renderYAxisTitle(yLabelGroup,which,this.%rplotRightOut+xoffPix+maxWidth+$s(is3D:5,1:0))
	quit maxWidth
}

/// Draw the data series for this chart.
/// This method renders the container for the data series and
/// then invokes a sub-class specific <method>renderSeries</method> method.
Method renderSeriesGroup()
{
	Set this=##this
	Set is3D = ..is3D()

	Set seriesGroup = ..svgGroup.findSVGElement("seriesGroup"_this.currMultiple)
	Set virtualGroup = ..svgGroup.findSVGElement("virtualGroup"_this.currMultiple)

	if ("" = seriesGroup) {
		// create group to hold series & clip
			// JMD1100: do not clip if 3D
		if ("3D" = this.appearance) {
			Set seriesGroup = ##class(node).%New()
			do seriesGroup.createElementSVG("g")
		}
		else {
			Set seriesGroup = ##class(node).%New()
			do seriesGroup.createElementSVG("svg")
		}
		do seriesGroup.setAttribute("id",..makeId("seriesGroup"_this.currMultiple))
		do virtualGroup.appendChild(seriesGroup)
	}

	// clear out children of this group
	do seriesGroup.clearChildren()

	// make sure size of series group is ok
	Set adj = $s(is3D : 5, 1 : 0)
	
	//do seriesGroup.setAttribute("x",0 - adj)
	// JMD1100
	if ("3D" = this.appearance) {
		do seriesGroup.setAttribute("transform","translate(0,"_(this.%plotTop*this.%scaleY)_")")
	}
	else {

		do seriesGroup.setAttribute("y",..%plotTop*this.%scaleY)
		do seriesGroup.setAttribute("width",(..%plotWidth + adj)*this.%scaleX)
		do seriesGroup.setAttribute("height",(..%plotHeight + adj)*this.%scaleY)
		//do seriesGroup.setAttribute("viewBox",-adj_" "_0_" "_(..%plotWidth+adj)_" "_(..%plotHeight+adj))
	}
	
	// JMD1314:
	do ..renderTimeEvents(seriesGroup)
	do ..updateIndicator()
	
	// create the actual series
	do ..renderSeries(seriesGroup)
}

/// Draw data series for this chart.
/// This is implemented by subclasses.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
	//alert('Chart: renderSeries method is unimplemented.');
}

/// Draw the legend for the chart.
Method renderLegend()
{
	Set this=##this
	// determine is legend is visible
	Set legends = ..getLegendLabels()
	Set ..%legendVisible = 0
	if ("true" = ..legendVisible) {
		Set ..%legendVisible = 1
	}
	elseif ("auto" = ..legendVisible) {
		Set ..%legendVisible = ($LL(legends) > 1)
	}

	if (this.hasMultiples()&&(..legendLabels="")) { // also insist on ..legendLabels="", JSL4144
		// no legends for multiples
		Set ..%legendVisible = 0
	}

	Set svgLegendGroup = ..svgGroup.findSVGElement("legendGroup")
	if (svgLegendGroup '="") {
		// clear out children of this group
		do svgLegendGroup.clearChildren()
	}
	if ('..%legendVisible) {
		Set this.%legendWidth = ""
		quit
	}

	if ("" = svgLegendGroup) {
		// create
		Set svgLegendGroup = ##class(node).%New()
		do svgLegendGroup.createElementSVG("svg")
		do svgLegendGroup.setAttribute("id",..makeId("legendGroup"))
		do ..svgGroup.appendChild(svgLegendGroup)
	}


	// background
	Set brect = ##class(node).%New()
	do brect.createElementSVG("rect")
	do brect.setAttribute("id",..makeId("legendRect"))
	//do brect.setAttribute("style","fill: none;")
	do svgLegendGroup.appendChild(brect)

	Set scount = $LL(legends)
	set linkedcount=$L(legends,"^")-1
	set scount=scount+linkedcount
	Set seriesNumber = $$$PARSEINT(..seriesNumber)
	if ('$$$ISNAN(seriesNumber)) {
		Set scount = 1
	}
	// in renderLegend
	if ..legendPosition'="none" && (..legendPosition'="") && (..legendPosition'="right") {
		if this.legendPosition = "top" {
			Set hgt = ((scount*3)+2)
			Set wid = ..width / this.%scaleX
			Set autoWid = 0
			Set autoHgt = 1
			Set y = ..%plotTopOut - ..%legendHeight - 2
			if (this.%xLabelOnTheTop) {
				Set y = y - $s(this.%maxXHeight'="" : this.%maxXHeight, 1 : 2)
			}

			Set x = 0
		
		} elseif this.legendPosition = "bottom" {
			Set hgt = ((scount*3)+2)
			Set wid = ..width / this.%scaleX
			Set autoWid = 0
			Set autoHgt = 1
			//Set y = ..%plotBottom
			Set y = ..%plotBottomOut + ..%labelBottom - 2
			Set x = 0

		} elseif this.legendPosition = "left" {
			Set hgt = ((scount*3)+2)
			Set wid = ..%legendWidth
			Set autoWid = 0
			Set autoHgt = 1
			//Set y = ..%plotBottom
			// Set y = ..%plotTopOut - ..%legendHeight - 2
			Set y = 0
			Set x = 0
			
		} 
	}
	if ..legendPosition="" || (..legendPosition = "none") || (..legendPosition="right") {
		if ("" = this.legendX) {
			Set x = ..zenGet(this.%plotRight,0)
		}
		else {
			Set x = this.xToLogical(this.legendX)
		}
		if ("" = this.legendY) {
			Set y = ..zenGet(this.%marginTop,0)
		}
		else {
			Set y = this.yToLogical(this.legendY)
		}
		if (""=..legendWidth) {
			Set wid = 10
			Set autoWid = 1
		}
		else {
			Set wid = this.xToLogical(this.legendWidth)
			Set autoWid = 0
		}
		if (""=..legendHeight) {
			Set hgt = ((scount*3)+2)
			Set autoHgt = 1
		}
		else {
			Set hgt =  this.yToLogical(this.legendHeight)
			Set autoHgt = 0
		}
	}
	// size of legend
	do svgLegendGroup.setAttribute("x",x*this.%scaleX)
	do svgLegendGroup.setAttribute("y",y*this.%scaleY)
	do svgLegendGroup.setAttribute("width",wid*this.%scaleX)
	do svgLegendGroup.setAttribute("height",hgt*this.%scaleY)

	// background rect
	do brect.setAttribute("class","chart-legend")
	do brect.setAttribute("x",0)
	do brect.setAttribute("y",0)
	do brect.setAttribute("rx",5)
	do brect.setAttribute("width",(wid*this.%scaleX))
	do brect.setAttribute("height",(hgt*this.%scaleY))
	do brect.setAttribute("style",..legendStyle)

	// legend items
	Set legWid = 0
	Set legHgt = 2
	Set ..%legendHeight = 2
	Set ty = legHgt

	Set legendTitle = ..legendTitle

	Set start = $s(("" = legendTitle) : 0, 1 : -1)

	// backing rectangle for legend items
	// used when there are multiple y-axes in the chart
	Set yaCount = ..getYAxisCount()
	kill legRect ; multidimensional array

	set s = start
	while (s < ..getLegendsCount(legends)) {
		if (s >= 0) {
			if ('$$$ISNAN(seriesNumber)) {
				Set sno = seriesNumber
			}
			else {
				Set sno = s
			}
			Set color = ..getSeriesColor(sno)
			set (shape1,shape2,label1,label2)=""
			Set shape = ..getMarkerShape(sno)
			// check if linked
			if $F(shape,"^") {set shape1=$p(shape,"^",1)
				set shape2=$p(shape,"^",2)
				set shape=""
			}

			// special logic for comboCharts
			Set plotType = this.getSeriesType(s)

			// backing rect for item in legend
			Set legRect(s) = ""
			if ((this.yAxis="") && (yaCount>1)) {
				Set legRect(s) = ##class(%ZEN.Report.Display.COSChart.node).%New()
				Do legRect(s).createElementSVG("rect")
				do legRect(s).setAttribute("class", "chart-legendRect")
				do legRect(s).setAttribute("style",this.legendRectStyle)
				do svgLegendGroup.appendChild(legRect(s))
			}


			if (..markersVisible  && ((plotType="line")||(plotType="linked") || (plotType=""))) {
				// show plain rect if no marker OR we are in a comboChart and not a line
				if $g(shape)'="" {Set leg = ..createMarker(sno, 0, 2, ty, color, shape, 1)
				                   do svgLegendGroup.appendChild(leg)}
				else { Set leg = ..createMarker(sno, 0, 2, ty, color, shape1, 1)
				       do svgLegendGroup.appendChild(leg)}
			}
			else {
				Set leg = ##class(node).%New()
				do leg.createElementSVG("rect")
				do leg.setAttribute("x",-5)
				;do leg.setAttribute("y",ty)
				do leg.setAttribute("y",-5)
				do leg.setAttribute("width",10)
				do leg.setAttribute("height",10)
				do leg.setAttribute("fill",color)
				do leg.setAttribute("stroke","#808080")
				do leg.setAttribute("stroke-width","0.5px")
				if (this.getLegendRectStyle(s)'="") do leg.setAttribute("style", this.getLegendRectStyle(s)) // JSL4133
				do svgLegendGroup.appendChild(leg)
			}
			set opacity=1
			if ((legRect(s)'="") && ($LG(this.%yAxisForSeries,s+1) '= this.currYAxis) && ('this.%Extends("%ZEN.Report.Display.COSChart.cbubbleChart")) && ('this.%Extends("%ZEN.Report.Display.COSChart.xyChart"))) { // JSL4142 - guard against bubble charts and xy charts
				// if user clicks on non-current series, switch axis
				do legRect(s).setAttribute("opacity",0.0)
				set opacity=0
			}

		}

		Set text = ##class(node).%New()
		do text.createElementSVG("text")
		do text.setAttribute("class","chart-legendLabel")
		do text.setAttribute("style",..legendLabelStyle _ $s((s<0):";font-weight:bold;opacity:0.6;",1:""))
		do ..getStyleArray(..legendLabelStyle,.styleArray)
		do text.setAttribute("x", 15)  // JMD100 use pixels
		do text.setAttribute("y", ty*this.%scaleY)
		//do text.setAttribute("font-size",$s($g(styleArray("font-size"))="":12,1:$g(styleArray("font-size")))) ; TBD - how do we get font-size?  Need for GetBBox

		Set label = $s((s<0) : legendTitle , 1: $LG(legends,sno+1,""))
		
		// check if linked
		if $F(label,"^") {set label1=$p(label,"^",1)
				set label2=$p(label,"^",2)
				set label=""
		}
		
		if $g(label)'="" {	do text.setText($zcvt(label,"O","XML")) }
		else { do text.setText($zcvt(label1,"O","XML")) }
		
		do svgLegendGroup.appendChild(text)
		Set bbox = ..GetBBox(text,0, 1, 1,"start")
		Set tw = ((..getComputedTextLength(text)*1.3)/ this.%scaleX)
		Set legWid = $s((legWid > tw) : legWid, 1 : tw)
		Set th = $s(((bbox.height*1.4/this.%scaleY)<3) : 3, 1 : (bbox.height*1.4/this.%scaleY))
	;do text.setAttribute("y", ty + (2*th/3))
		
		do text.setAttribute("x", 0)
		do text.setAttribute("y", 0)
		do text.setAttribute("transform","translate("_(20)_","_((ty+(2*th/3))*this.%scaleY)_")") ; _ +

		
		if ($D(leg)&&$isObject(leg)) {
			// JMD1100 offset in pixels; not scaled units
			Set xm=10
			Set ya=1
			do leg.setAttribute("transform","translate("_(xm)_","_(((ty+ya) + (((2*th/3)-2))*this.%scaleY))_")")
		}
		if (s <0) {
			Set th = th * 1.3
		}
		if ($D(legRect(s))&&$IsObject(legRect(s))) {
			do legRect(s).setAttribute("x",2)
			do legRect(s).setAttribute("y",ty*this.%scaleY)
			do legRect(s).setAttribute("height",((th*this.%scaleY)-2))
		}

		Set ty = ty + th
		Set ..%legendHeight = ..%legendHeight + th
		Set legHgt = legHgt + th
		Set s=s+1 ; increment loop variable
				
		// now process marker and text for linked entry
		if $g(shape2)'="" {
			
			/// add the rectangle box into the mix - must make sure its "linked" to
			/// the environment without overlaying the counts of s so always have
			/// the block be s+99  --- can never image have more than 100 graphed items
			if ($D(legRect(s-1))&&$IsObject(legRect(s-1))) {
				Set legRect(s+99) = ""
				Set legRect(s+99) = ##class(%ZEN.Report.Display.COSChart.node).%New()
				Do legRect(s+99).createElementSVG("rect")
				do legRect(s+99).setAttribute("class", "chart-legendRect")
				do legRect(s+99).setAttribute("style",this.legendRectStyle)
				do svgLegendGroup.appendChild(legRect(s+99))
			}
			
			Set leg = ..createMarker(sno, 0, 2, ty, color, shape2, 1)
			do svgLegendGroup.appendChild(leg)
			
			/// Set opacity based off "linked" item so using the opacity variable
			if opacity=0 {
				// if user clicks on non-current series, switch axis
				do legRect(s+99).setAttribute("opacity",0.0)
			}
			
			Set text = ##class(node).%New()
			do text.createElementSVG("text")
			do text.setAttribute("class","chart-legendLabel")
			do text.setAttribute("style",..legendLabelStyle _ $s((s<0):";font-weight:bold;opacity:0.6;",1:""))
			do ..getStyleArray(..legendLabelStyle,.styleArray)
			do text.setAttribute("x", 15)  // JMD100 use pixels
			do text.setAttribute("y", ty*this.%scaleY)
			do text.setText($zcvt(label2,"O","XML")) 
		
			do svgLegendGroup.appendChild(text)
						
			Set bbox = ..GetBBox(text,0, 1, 1,"start")
			Set tw = ((..getComputedTextLength(text)*1.3)/ this.%scaleX)
			Set legWid = $s((legWid > tw) : legWid, 1 : tw)
			Set th = $s(((bbox.height*1.4/this.%scaleY)<3) : 3, 1 : (bbox.height*1.4/this.%scaleY))
			;do text.setAttribute("y", ty + (2*th/3))
		
			do text.setAttribute("x", 0)
			do text.setAttribute("y", 0)
			do text.setAttribute("transform","translate("_(20)_","_((ty+(2*th/3))*this.%scaleY)_")") ; _ +

 			Set xm=10
			Set ya=1
			do leg.setAttribute("transform","translate("_(xm)_","_(((ty+ya) + (((2*th/3)-2))*this.%scaleY))_")")

			/// I don't believe s will ever be negative at this point but added in as
			/// a safety measure
			if (s <0) {
				Set th = th * 1.3
			}
			if ($D(legRect(s+99))&&$IsObject(legRect(s+99))) {
				do legRect(s+99).setAttribute("x",2)
				do legRect(s+99).setAttribute("y",ty*this.%scaleY)
				do legRect(s+99).setAttribute("height",((th*this.%scaleY)-2))
			}

			Set ty = ty + th
			Set ..%legendHeight = ..%legendHeight + th
			Set legHgt = legHgt + th
		
				           
		}
				
	}
	
	if (autoWid) { // JMD1100
		Set legWid = legWid + ((15+15)/this.%scaleX)
		do brect.setAttribute("width",((legWid-1)*this.%scaleX))
		do svgLegendGroup.setAttribute("x",((100-legWid)*this.%scaleX))
		do svgLegendGroup.setAttribute("width",(legWid*this.%scaleX)+2)

		Set this.%legendWidth = legWid	
	}
	else {
		Set ..%legendWidth = "" ; JMD1100 2:22 PM
	}
	// adjust size of legRects
	if ($D(legRect)) {
		for s=start:1:scount-1 {
			if ($D(legRect(s))&&$isObject(legRect(s))) {
				do legRect(s).setAttribute("width",((legWid-1)*this.%scaleX)-4)
			}
			/// Adjust lengths of any linked rectangles
			if ($D(legRect(s+99))&&$isObject(legRect(s+99))) {
				do legRect(s+99).setAttribute("width",((legWid-1)*this.%scaleX)-4)
			}
		}
	}

	if (autoHgt) {
		Set legHgt = legHgt + 1
		Set top = this.%marginTop
		Set btm = this.%marginBottom
		if (legHgt > (100 - (top + btm))) {
			Set legHgt = (100 - (top + btm))
		}
		do brect.setAttribute("height",legHgt*this.%scaleY)
		do svgLegendGroup.setAttribute("height",legHgt*this.%scaleY)
	}
}

/// Draw the legend for the chart.
Method calculateLegendDimensions()
{
	Set this=##this
	// determine is legend is visible
	Set legends = ..getLegendLabels()
	Set ..%legendVisible = 0
	if ("true" = ..legendVisible) {
		Set ..%legendVisible = 1
	}
	elseif ("auto" = ..legendVisible) {
		Set ..%legendVisible = ($LL(legends) > 1)
	}

	if (this.hasMultiples()&&(..legendLabels="")) { // also insist on ..legendLabels="", JSL4144
		// no legends for multiples
		Set ..%legendVisible = 0
	}

	Set scount = $LL(legends)
	Set seriesNumber = $$$PARSEINT(..seriesNumber)
	if ('$$$ISNAN(seriesNumber)) {
		Set scount = 1
	}
	if ..legendPosition'="none" && (..legendPosition'="") {
		if this.legendPosition = "top" {
			Set hgt = ((scount*3)+2)
			Set wid = ..width / this.%scaleX
			Set autoWid = 0
			Set autoHgt = 1
			Set y = 0
			Set x = 0
		
		} elseif this.legendPosition = "bottom" {
			Set hgt = ((scount*3)+2)
			Set wid = ..width / this.%scaleX
			Set autoWid = 0
			Set autoHgt = 1
			//Set y = ..%marginBottom
			Set y = ..%marginBottom - ..%labelBottom
			Set x = 0

		} elseif this.legendPosition = "left" {
			Set hgt = ((scount*3)+2)
			Set wid = ..%legendWidth
			Set autoWid = 1
			Set autoHgt = 0
			//Set y = ..%plotBottom
			Set y = 0
			Set x = 0

		}
	}
	if ..legendPosition="" || (..legendPosition = "none") || (..legendPosition="right"){
		if ("" = this.legendX) {
			Set x = ..zenGet(this.%plotRight,0)
		}
		else {
			Set x = this.xToLogical(this.legendX)
		}
		if ("" = this.legendY) {
			Set y = ..zenGet(this.%marginTop,0)
		}
		else {
			Set y = this.yToLogical(this.legendY)
		}
		if (""=..legendWidth) {
			Set wid = 10
			Set autoWid = 1
		}
		else {
			Set wid = this.xToLogical(this.legendWidth)
			Set autoWid = 0
		}
		if (""=..legendHeight) {
			Set hgt = ((scount*3)+2)
			Set autoHgt = 1
		}
		else {
			Set hgt =  this.yToLogical(this.legendHeight)
			Set autoHgt = 0
		}
	}

	// legend items
	Set legWid = 0
	Set legHgt = 2
	Set ..%legendHeight = 2
	Set ty = legHgt

	Set legendTitle = ..legendTitle

	Set start = $s(("" = legendTitle) : 0, 1 : -1)

	// backing rectangle for legend items
	// used when there are multiple y-axes in the chart
	Set yaCount = ..getYAxisCount()
	kill legRect ; multidimensional array

	set s = start
	while (s < ..getLegendsCount(legends)) {

		Set text = ##class(node).%New()
		do text.createElementSVG("text")
		do text.setAttribute("class","chart-legendLabel")
		do text.setAttribute("style",..legendLabelStyle _ $s((s<0):";font-weight:bold;opacity:0.6;",1:""))
		do ..getStyleArray(..legendLabelStyle,.styleArray)
		do text.setAttribute("x", 15)  // JMD100 use pixels
		do text.setAttribute("y", ty*this.%scaleY)
		//do text.setAttribute("font-size",$s($g(styleArray("font-size"))="":12,1:$g(styleArray("font-size")))) ; TBD - how do we get font-size?  Need for GetBBox
		if (s >= 0) {
			if ('$$$ISNAN(seriesNumber)) {
				Set sno = seriesNumber
			}
			else {
				Set sno = s
			}
		}
		Set label = $s((s<0) : legendTitle , 1: $LG(legends,sno+1,""))
		do text.setText($zcvt(label,"O","XML"))

		Set bbox = ..GetBBox(text,0, 1, 1,"start")
		Set tw = ((..getComputedTextLength(text)*1.3)/ this.%scaleX)
		Set legWid = $s((legWid > tw) : legWid, 1 : tw)
		Set th = $s(((bbox.height*1.4/this.%scaleY)<3) : 3, 1 : (bbox.height*1.4/this.%scaleY))
		Set ty = ty + th
		Set ..%legendHeight = ..%legendHeight + th
		Set legHgt = legHgt + th
		Set s=s+1 ; increment loop variable
	}
	
	if (autoWid) { // JMD1100
		Set legWid = legWid + ((15+15)/this.%scaleX)
		Set this.%legendWidth = legWid	
	}
	else {
		Set ..%legendWidth = "" ; JMD1100 2:22 PM
	}

	if (autoHgt) {
		Set legHgt = legHgt + 1
		Set top = this.%marginTop
		Set btm = this.%marginBottom
		if (legHgt > (100 - (top + btm))) {
			Set legHgt = (100 - (top + btm))
		}
	}
}

/// The Normalized viewbox ranges from 0 0 to 100 100, the physical space 
/// occupied by the chart is specified as the width and height (in pixels) of
/// the base SVG group.  This function returns a mapping of logical picture 
/// units to pixels in the vertical direction. 
Method getPelToPixelVRatio()
{
	Set this=##this
	// JMD1100
	if ((this.viewBoxWidth = "") && (this.viewBoxHeight = "")) {
		quit 1
	}
	Set physicalHeight = $$$PARSEINT(..svgGroup.getAttribute("height"))
	quit (100/physicalHeight)
}

/// The Normalized viewbox ranges from 0 0 to 100 100, the physical space 
/// occupied by the chart is specified as the width and height (in pixels) of
/// the base SVG group.  This function returns a mapping of logical picture 
/// units to pixels in the horizontal direction. 
Method getPelToPixelHRatio()
{
	Set this=##this
	// JMD1100
	if ((this.viewBoxWidth = "") && (this.viewBoxHeight = "")) {
		quit 1
	}
	Set physicalWidth = $$$PARSEINT(..svgGroup.getAttribute("width"))
	quit (100/physicalWidth)
}

Method removeChildNodes(node As node)
{
	do node.clearChildren()
}

Method computeEffectiveExtents(x, y, w, h, angle) As extent
{
	Set rad = $zpi*angle/180
	Set sin = $zsin(rad)
	Set cos = $zcos(rad)
	Set minX = (x*cos) - (y*sin)
	Set minY = (x*sin) + (y*cos)
	Set maxX = minX
	Set maxY = minY

	Set nX = x
	Set nY = y+h
	Set rX = (nX*cos) - (nY*sin)
	if (rX<minX) Set minX=rX
	if (rX>maxX) Set maxX=rX
	Set rY = (nX*sin) + (nY*cos)
	if (rY<minY) Set minY=rY
	if (rY>maxY) Set maxY=rY

	Set nX = x+w
	Set nY = y
	Set rX = (nX*cos) - (nY*sin)
	if (rX<minX) Set minX=rX
	if (rX>maxX) Set maxX=rX
	Set rY = (nX*sin) + (nY*cos)
	if (rY<minY) Set minY=rY
	if (rY>maxY) Set maxY=rY

	Set nX = x+w
	Set nY = y+h
	Set rX = (nX*cos) - (nY*sin)
	if (rX<minX) Set minX=rX
	if (rX>maxX) Set maxX=rX
	Set rY = (nX*sin) + (nY*cos)
	if (rY<minY) Set minY=rY
	if (rY>maxY) Set maxY=rY

	Set ex = ##class(extent).%New()
	Set ex.minX = minX
	Set ex.minY = minY
	Set ex.maxX = maxX
	Set ex.maxY = maxY
	Set ex.w=maxX-minX
	Set ex.h=maxY-minY
	quit ex
}

/// Create a text node.
Method createSVGTextNode(caption, fontSize, autoScale, align, rotate, parentNode, txtClass, txtStyle) As node
{
	Set this=##this
	//Set debug=0

	// JMD1100 remove text scale, ignore autoScale!
	// change scaleX/Y to refer to chart scale
	Set scaleX = this.%scaleX
	Set scaleY = this.%scaleY
	Set textGroup=##class(node).%New()
	do textGroup.createElementSVG("g")
	Set text = ##class(node).%New()
	do text.createElementSVG("text")
	if (..debugBBox) {
		Set box = ##class(node).%New()
		do box.createElementSVG("rect")
		Set bbox = ##class(node).%New()
		do bbox.createElementSVG("rect")
	}
	do text.setAttribute("font-size",fontSize)
	do text.setAttribute("text-anchor",align)
	
	// JMD1182: apply style to get correct metrics
	if ($g(txtClass)'="") {
		do text.setAttribute("class",txtClass)
	}
	if ($g(txtStyle)'="") {
		// do text.setAttribute("style",txtStyle) // JSL4131 - txtStyle is an object, can't be used in setAttribute
		do this.embedStyle(text,txtStyle)
	}
	
	do text.setAttribute("x", 0)
	do text.setAttribute("y", 0)
		
	Set transform = ""
	if (rotate'=0) {
		Set transform = " rotate("_rotate_",0,0)"
		do text.setAttribute("transform",transform)
	}
	if (..debugBBox) {
	do box.setAttribute("transform",transform)
	do box.setAttribute("stroke","black")
	do box.setAttribute("stroke-width","1")
	do box.setAttribute("fill","none")
#if 1
	do bbox.setAttribute("stroke","red")
	do bbox.setAttribute("stroke-width","1")
	do bbox.setAttribute("fill","yellow")
	do bbox.setAttribute("opacity",0.5)
#endif
	}
	// create the text node and append it
	do text.setText($zcvt(caption,"O","XML"))
	if (..debugBBox) {	
	do box.appendChild(text)
	}
	do textGroup.appendChild(text)
	if (..debugBBox) {
	do textGroup.appendChild(box)
#if 0	
	do textGroup.appendChild(bbox)
#endif	
	}
	if ($isObject(parentNode)) {
		do parentNode.appendChild(textGroup)
		
		Set txtBB = ..GetBBox(text,rotate,scaleX,scaleY,align)
		Set lH = txtBB.height/scaleY
		Set lW = txtBB.width/scaleX
		Set eH = lH
		Set eW = lW
		
		Set ex = ""
		Set xOfs = txtBB.x/scaleX
		Set yOfs = txtBB.y/scaleY
		if (rotate'=0) {
			// JMD1125 - apply scaling after computation
			Set ex = ..computeEffectiveExtents(txtBB.x,txtBB.y,txtBB.width,txtBB.height,rotate)
			Set eH = ex.h / scaleY
			Set eW = ex.w / scaleX
			Set xOfs = ex.minX / scaleX
			Set yOfs = ex.minY / scaleY ; JMD1100
		}
	if (..debugBBox) {		
	do box.setAttribute("x", txtBB.x)
	do box.setAttribute("y", txtBB.y)
	do box.setAttribute("width", txtBB.width)
	do box.setAttribute("height", txtBB.height)

	do bbox.setAttribute("x",xOfs*scaleX)
	do bbox.setAttribute("y",yOfs*scaleY)
	do bbox.setAttribute("width",eW*scaleX)
	do bbox.setAttribute("height",eH*scaleY)
	}
		do text.setAttribute("logicalHeight",lH)
		do text.setAttribute("logicalWidth",lW)
		do textGroup.setAttribute("logicalHeight",lH)
		do textGroup.setAttribute("logicalWidth",lW)

		do text.setAttribute("effectiveHeight",eH)
		do text.setAttribute("effectiveWidth",eW)
		do textGroup.setAttribute("effectiveHeight",eH)
		do textGroup.setAttribute("effectiveWidth",eW)

		do text.setAttribute("xOffset",xOfs)
		do text.setAttribute("yOffset",yOfs)
		do textGroup.setAttribute("xOffset",xOfs)
		do textGroup.setAttribute("yOffset",yOfs)
	}
	
	// return the outer group
	quit textGroup
}

Method stripWhitespace(str)
{
	quit $zstrip(str,"*","W")
}

/// Integrate a new Style specification into an existing set of
/// name-value style pairs, adding and overwriting existing styles
/// as appropriate
Method integrateStyleSpec(styleNVP As styleNVP, newRule As %String)
{
	Set a=styleNVP.attr
	Set v=styleNVP.value
	Set items = ..split($zcvt(newRule,"l"),";") // separate clauses
	Set i=1
	while (i<=$LL(items)) {
		if ($LI(items,i)'="") {
			Set pair = ..split($LI(items,i),":")
			if ((pair'="") && ($LL(pair)=2)) {
				Set newAttr = ..stripWhitespace($LI(pair,1))
				if (newAttr'="") {
					// JMD1125 don't remove white space from attr
					// Set newVal = ..stripWhitespace($LI(pair,2))
					Set newVal = $LI(pair,2)
					Set j=1
					while(j<=a.Size) {
						if (a.GetAt(j)=newAttr) {
							do a.SetAt(newAttr,j)
							do v.SetAt(newVal,j)
							Set j=a.Size
						}
						Set j=j+1
					}
					if (j=(a.Size+1)) {
						do a.SetAt(newAttr,j)
						do v.SetAt(newVal,j)					}
				}
			}
		}
		Set i=i+1
	}
}

/// Compute and return the effective style that governs the rendering
/// of a given SVG element based on class and Id
Method computeStyle(className, idName)
{
	Set classSelector = "."_className
	Set idSelector = "#"_idName
	Set s = ##class(styleNVP).%New() 
	// TBD - fill in from class and id so non-empty
	quit s
}

/// Embed the various settings of a computed style name-value object
/// as direct attributes of the given node.
Method embedStyle(element, styleNVP)
{
	Set s = styleNVP
	Set styleString = ""
	Set i = 1
	/*
	while (i<=s.attr.Size) {
		do element.setAttribute(s.attr.GetAt(i),s.value.GetAt(i))
		Set i=i+1
	}
	*/
	while (i<=s.attr.Size) {
		Set attr = s.attr.GetAt(i)

		// JMD1125: font-family & others do not seem to work as attributes
		if attr = "font-family" {
			Set styleString = styleString _ attr _ ":" _ s.value.GetAt(i) _ ";"
		}
		elseif attr = "text-shadow" {
			Set styleString = styleString _ attr _ ":" _ s.value.GetAt(i) _ ";"
		}	
		else {
			do element.setAttribute(attr,s.value.GetAt(i))
			Set styleString = styleString _ attr _ ":" _ s.value.GetAt(i) _ ";" // JSL4131
		}
		Set i=i+1
		
	}
	if (styleString'="") {
		do element.setAttribute("style",styleString)
	}
}

/// Given a resolved style name-value pairing object, return the specified font
/// size, if none has been specified, return one of three default values based on the 
/// value of the textSize property.
Method getComputedFontSize(styleNVP, defaultMedium, defaultSmall, defaultLarge)
{
		Set s = styleNVP
		Set idx = -1
		Set i=1
		while(i<=s.attr.Size) {
			if (s.attr.GetAt(i)="font-size") {
				Set idx=i
				Set i=s.attr.Size
			}
			Set i=i+1
		}
		Set fSz = defaultMedium
		if (idx<0) {
			if (..textSize = "large") { Set fSz = defaultLarge }
			elseif (..textSize = "small") { Set fSz = defaultSmall }
			// JMD1100 if ('..autoScaleText) Set fSz = fSz * 4
			do s.value.SetAt("font-size",s.attr.Size+1)
			do s.value.SetAt(fSz,s.value.Size+1)
		}
		else {
			Set fSz = $$$PARSEFLOAT(s.value.GetAt(idx))
			do s.value.SetAt(fSz,idx)
		}
		quit fSz
}

/// Draw the title for the chart. Return the height of the title.
Method renderTitle()
{
	Set this=##this
	Set this.%titleHeight = 0
	Set this.%titleImageWidth = 0
	Set this.%titleImageTop = 0
	Set this.%titleImageLeft = 0

	Set chartTitle = ..svgGroup.findSVGElement("chartTitle"_..currMultiple)

	if ("" '= chartTitle) {
		// remove old title
		do ..svgGroup.removeChild(chartTitle)
		Set chartTitle = ""
	}
	Set chartSubtitle = ..svgGroup.findSVGElement("chartSubtitle"_this.currMultiple)
	if ("" '= chartSubtitle) {
		// remove old subtitle
		do this.svgGroup.removeChild(chartSubtitle)
		Set chartSubtitle = ""
	}
	
	Set chartImage = ..svgGroup.findSVGElement("chartTitleImage"_this.currMultiple) ; JMD1130 pt3
	if ("" '= chartImage) {
		// remove old image
		do this.svgGroup.removeChild(chartImage)
		Set chartImage = ""
	}

	// rectangle under title (normally not shown)
	Set trect = ##class(%ZEN.Report.Display.COSChart.node).%New()
	do trect.createElementSVG("rect")
	do trect.setAttribute("class","chart-titleBox")
	do trect.setAttribute("id",..makeId("chartTitleBox"_..currMultiple))
	do trect.setAttribute("style",..titleBoxStyle)
	do ..svgGroup.appendChild(trect)
	Set titleText = this.getChartTitle()
	Set subtitleText = this.getChartSubtitle()
	Set titleH = 0
	Set subtitleH = 0

	// image & image size
	Set imageLeft = 0
	Set imageTop = 0
	Set imageWidth = 0
	Set imageHeight = 0

	Set imageURL = this.titleImage
	Set imageStyle = this.titleImageStyle

	if (imageURL'="") {
		Set imageWidth = 50
		Set imageHeight = 50
		if (imageStyle'="") {
			Set t = imageStyle.split(";")
			for ti=1:1:$LL(t) {
				Set t2 = $LG(t,ti).split(":")
				//switch (t2[0]) {
				if $LG(t2,1)="left" {
					Set imageLeft = $$$PARSEINT($LG(t2,2))
				}
				elseif $LG(t2,1)="top" {
					Set imageTop = $$$PARSEINT($LG(t2,2))
				}
				elseif $LG(t2,1)="width" {
					Set imageWidth = $$$PARSEINT($LG(t2,2))
				}
				elseif $LG(t2,1)="height" {
					Set imageHeight = $$$PARSEINT($LG(t2,2))
				}
			}
		}
		Set this.%titleImageWidth = imageWidth / this.%scaleX
		Set this.%titleImageTop = imageTop / this.%scaleY
		Set this.%titleImageLeft = imageLeft / this.%scaleX
	}
	if (imageURL '= "") {
		Set image = ##class(node).newElementSVG("image")
		do image.setAttribute("id",this.makeId("chartTitleImage"_this.currMultiple))
		do image.setAttribute("xmlns:xlink","http://www.w3.org/1999/xlink")
		do image.setAttribute("xlink:href",imageURL)
		do image.setAttribute("preserveAspectRatio","none")
		// move this in adjustTitle
		do image.setAttribute("x",imageLeft)
		do image.setAttribute("y",imageTop)
		do image.setAttribute("width",imageWidth)
		do image.setAttribute("height",imageHeight)
		do this.svgGroup.appendChild(image)
	}
	
	if (""'=titleText) {
		Set titleStyleObj = ..computeStyle("chart-title","chartTitle")
		Set titleStyle = $s(..hasMultiples() : (..titleStyle _..multipleTitleStyle), 1 : ..titleStyle)
		// comment out line below - JSL3984
		//if (..labelStyle'="") do ..integrateStyleSpec(titleStyleObj,..labelStyle)
		if (titleStyle'="") do ..integrateStyleSpec(titleStyleObj,titleStyle)
		Set fSz = ..getComputedFontSize(titleStyleObj, 14, 8, 18)

		Set anchor = $s("left"=this.titleAlign : "start", 1 : $s("right"=this.titleAlign : "end", 1 : "middle")) ; JMD1100
		// Set titleText = ..getChartTitle() as part of JMD1100
		Set text = ..createSVGTextNode(titleText,fSz,..autoScaleText,anchor,0,..svgGroup)
		do text.setAttribute("id",..makeId("chartTitle"_..currMultiple))
		do text.setAttribute("class","chart-title")
		
		do ..embedStyle(text.firstChild(),titleStyleObj)
		Set titleH = ($$$PARSEFLOAT(text.getAttribute("logicalHeight"))* 1.2) // JMD1100 Part 2
	}
	if ("" '= subtitleText) { // JMD1100
		Set subtitleStyleObj = this.computeStyle("chart-subtitle","")
		Set subtitleStyle = this.subtitleStyle
		if (subtitleStyle'="") do this.integrateStyleSpec(subtitleStyleObj,subtitleStyle)
		Set fSz = this.getComputedFontSize(subtitleStyleObj, 9, 6, 12)

		Set anchor = $s("left"=this.titleAlign : "start", 1 : $s("right"=this.titleAlign : "end", 1 : "middle")) ; JMD1100
		Set stext = this.createSVGTextNode(subtitleText,fSz,this.autoScaleText,anchor,0,this.svgGroup)
		do stext.setAttribute("id",this.makeId("chartSubtitle"_this.currMultiple))
		do stext.setAttribute("class","chart-subtitle")

		do this.embedStyle(stext.firstChild(),subtitleStyleObj)
		Set subtitleH = ($$$PARSEFLOAT(stext.getAttribute("logicalHeight"))* 1.2)
	}
	
	// JMD1100 (2)
	Set this.%titleHeight = $$$PARSEFLOAT(titleH) + $$$PARSEFLOAT(subtitleH)
	if (this.%titleHeight < (imageHeight + imageTop)/this.%scaleY) {
		Set this.%titleHeight = (imageHeight + imageTop)/this.%scaleY
	}	
	quit this.%titleHeight
}

/// Adjust position of chart title and legend (if needed).
Method adjustChartTitle()
{
	Set this=##this
	if this.titleAlign = "left" {
		Set tx = $s("" '= this.titleX : this.xToLogical(this.titleX), 1 : (8/this.%scaleX + this.%marginLeft + this.%titleImageWidth + this.%titleImageLeft))
	} elseif this.titleAlign="right" {
		Set tx = $s("" '= this.titleX : this.xToLogical(this.titleX), 1 : (this.%plotLeft + this.%rplotWidth  - 8/this.%scaleX))
	} else {
		Set tx = $s("" '= this.titleX : this.xToLogical(this.titleX), 1 : (this.%plotLeft + ((this.%rplotWidth / 2))))
	}

	Set ty = 0
	Set text = ..svgGroup.findSVGElement("chartTitle"_this.currMultiple)
	if (text'="") {
		Set ty = $s("" '= this.titleY : this.yToLogical(this.titleY), 1 : (text.getAttribute("logicalHeight")*1.2))
		do text.setAttribute("transform","translate("_(tx*this.%scaleX)_","_(ty*this.%scaleY)_")")
	}

	Set stext = ..svgGroup.findSVGElement("chartSubtitle"_this.currMultiple)
	if (stext'="") {
		Set ty = ty + $s("" '= this.titleY : this.yToLogical(this.titleY), 1 : (stext.getAttribute("logicalHeight")*1.2))
		do stext.setAttribute("transform","translate("_(tx*this.%scaleX)_","_(ty*this.%scaleY)_")")
	}
	
	Set trect = ..svgGroup.findSVGElement("chartTitleBox"_this.currMultiple)
	if (trect'="") {
		do trect.setAttribute("x", this.%plotLeft*this.%scaleX)
		do trect.setAttribute("y", 2) ; 2 pixels
		do trect.setAttribute("width", this.%rplotWidth*this.%scaleX)
		; Set h = $s(this.%marginTop>2 : this.%marginTop-2, 1 : 0) JMD1100 - part2
		Set tTitleHeight = (this.%marginTop*this.%scaleY) - 4
		If tTitleHeight<0 Set tTitleHeight=0						// DTB273 - Prevent negative height
		do trect.setAttribute("height",tTitleHeight)
	}

	// JMD1072 Move title and box to front
	if (trect'="") {
		Set parent = trect.parent
		do parent.removeChild(trect)
		do parent.appendChild(trect)
	}
	if (text'="") {
		Set parent = text.parent
		do parent.removeChild(text)
		do parent.appendChild(text)
	}
	if (stext'="") {
		Set parent = stext.parent
		do parent.removeChild(stext)
		do parent.appendChild(stext)
	}

	Set image = ..svgGroup.findSVGElement("chartTitleImage"_this.currMultiple)
	if (image'="") {
		do image.setAttribute("x",(this.%marginLeft+this.%titleImageLeft) * this.%scaleX)
		do image.setAttribute("y",2 + (this.%titleImageTop * this.%scaleY))
		Set parent = image.parent
		do parent.removeChild(image)
		do parent.appendChild(image)

	}
	
	// test legend
	Set svgLegendGroup = ..svgGroup.findSVGElement("legendGroup")
	if ((svgLegendGroup'="") && $isObject(svgLegendGroup)) {
		Set lh = svgLegendGroup.getAttribute("height")
		if (lh > this.%plotHeight) {
			do svgLegendGroup.setAttribute("height",(this.%plotHeight*this.%scaleY))
		}
	}
}

/// Get title for the chart.
Method getChartTitle()
{
	Set title = ""

	// for multiples, use series name
	if (..hasMultiples()) {
		Set snames = ..getSeriesNames()
		Set title = $LG(snames,..currMultiple+1)
	}
	elseif ("" '= ..title) {
		Set title = ..title
	}
	quit title
}

/// Get subtitle for the chart.
Method getChartSubtitle()
{
	Set this=##this
	Set title = ""
	if ("" '= this.subtitle) {
		Set title = this.subtitle
	}
	quit title
}

/// Draw the upper/lower bands for the chart.
Method renderBands()
{
	Set this=##this
	Set plotAreaGroup = ..svgGroup.findSVGElement("plotAreaGroup")
	Set virtualGroup = ..svgGroup.findSVGElement("virtualGroup"_this.currMultiple)
	;zenASSERT(plotAreaGroup,'Unable to find plotAreaGroup',arguments);

	// create upper/lower bands
	Set bandUpper = ..svgGroup.findSVGElement("bandUpper"_this.currMultiple)
	Set bandLower = ..svgGroup.findSVGElement("bandLower"_this.currMultiple)
	if ("" = bandUpper) {
		Set bandUpper=##class(%ZEN.Report.Display.COSChart.node).%New()
		do bandUpper.createElementSVG("rect")
		do bandUpper.setAttribute("id",..makeId("bandUpper")_this.currMultiple)
		do virtualGroup.appendChild(bandUpper)
	}
	if ("" = bandLower) {
		Set bandLower = ##class(%ZEN.Report.Display.COSChart.node).%New()
		do bandLower.createElementSVG("rect")
		do bandLower.setAttribute("id",..makeId("bandLower")_this.currMultiple)
		do virtualGroup.appendChild(bandLower)
	}

	Set hide = 0
	if ($$$ISNAN($$$PARSEFLOAT(..bandUpper))) {
		Set hide = 1
	}
	elseif (this.chartPivot) {
		// JMD1130
		Set w = this.getPlotX(this.bandUpper) - this.%plotLeft
		if (w <= 0) {
			Set hide = 1
		}
		else {
			Set w = $s(w > this.%plotWidth : this.%plotWidth, 1 : w)
			do bandUpper.setAttribute("class","chart-band")
			do bandUpper.setAttribute("x",w*this.%scaleX)
			do bandUpper.setAttribute("y",this.%plotTop*this.%scaleY)
			do bandUpper.setAttribute("height",this.%plotHeight*this.%scaleY)
			do bandUpper.setAttribute("width",(this.%plotWidth-w)*this.%scaleX)
			do bandUpper.setAttribute("style",this.bandUpperStyle)
		}
	}
	else {
		Set h = ..getPlotY(..bandUpper,0) - ..%plotTop
		if (h <= 0) {
			Set hide = 1
		}
		else {
			Set h = $s((h > ..%plotHeight) : ..%plotHeight, 1 : h)
			do bandUpper.setAttribute("class","chart-band")
			do bandUpper.setAttribute("x",0)
			do bandUpper.setAttribute("y",..%plotTop*this.%scaleY)
			do bandUpper.setAttribute("width",..%plotWidth*this.%scaleX)
			do bandUpper.setAttribute("height",h*this.%scaleY)
			do bandUpper.setAttribute("style",..bandUpperStyle)
		}
	}
	if (hide) {
 		do bandUpper.setAttribute("display","none")
	}
	else {
 		do bandUpper.setAttribute("display","inherit")
	}

	Set hide = 0
	if ($$$ISNAN($$$PARSEFLOAT(..bandLower))) {
		Set hide = 1
	}
	elseif (this.chartPivot) {
		// JMD1130
		Set w = this.getPlotX(this.bandLower) - this.%plotLeft
		if (w <= 0) {
			Set hide = 1
		}
		else {
			Set w = $s(w > this.%plotWidth : this.%plotWidth, 1 : w)
			do bandLower.setAttribute("class","chart-band")
			do bandLower.setAttribute("x",0*this.%scaleX)
			do bandLower.setAttribute("y",this.%plotTop*this.%scaleY)
			do bandLower.setAttribute("height",this.%plotHeight*this.%scaleY)
			do bandLower.setAttribute("width",w*this.%scaleX)
			do bandLower.setAttribute("style",this.bandLowerStyle)
		}
	}
	else {
		Set h = ..getPlotY(..bandLower,0)
		if (h >= (..%plotTop+..%plotHeight)) {
			Set hide = 1
		}
		else {
			Set h = $s((h < ..%plotTop) : ..%plotTop, 1 : h)
			do bandLower.setAttribute("class","chart-band")
			do bandLower.setAttribute("x",0)
			do bandLower.setAttribute("y",h*this.%scaleY)
			do bandLower.setAttribute("width",..%plotWidth*this.%scaleX)
			do bandLower.setAttribute("height",(..%plotHeight - h + ..%plotTop)*this.%scaleY)
			do bandLower.setAttribute("style",..bandLowerStyle)
		}
	}
	if (hide) {
 		do bandLower.setAttribute("display","none")
	}
	else {
 		do bandLower.setAttribute("display","inherit")
	}

	// create left/right bands
	Set bandRight = ..svgGroup.findSVGElement("bandRight")
	Set bandLeft = ..svgGroup.findSVGElement("bandLeft")
	if ("" = bandRight) {
		Set bandRight=##class(%ZEN.Report.Display.COSChart.node).%New()
		do bandRight.createElementSVG("rect")
		do bandRight.setAttribute("id",..makeId("bandRight"))
		do virtualGroup.appendChild(bandRight)
	}
	if ("" = bandLeft) {
		Set bandLeft = ##class(%ZEN.Report.Display.COSChart.node).%New()
		do bandLeft.createElementSVG("rect")
		do bandLeft.setAttribute("id",..makeId("bandLeft"))
		do virtualGroup.appendChild(bandLeft)
	}

	Set hide = 0
	if ($$$ISNAN($$$PARSEFLOAT(..bandRight))) {
		Set hide = 1
	}
	else {
		Set w = ..%plotRight - ..getPlotX(..bandRight) 
		if (w <= 0) {
			Set hide = 1
		}
		else {
			Set w = $s((w > ..%plotWidth) : ..%plotWidth, 1 : w)
			do bandRight.setAttribute("class","chart-band")
			do bandRight.setAttribute("x",(..getPlotX(..bandRight)-..%plotLeft)*this.%scaleX)
			do bandRight.setAttribute("y",..%plotTop*this.%scaleY)
			do bandRight.setAttribute("width",w*this.%scaleX)
			do bandRight.setAttribute("height",..%plotHeight*this.%scaleY)
			do bandRight.setAttribute("style",..bandRightStyle)
		}
	}
	if (hide) {
 		do bandRight.setAttribute("display","none")
	}
	else {
 		do bandRight.setAttribute("display","inherit")
	}

	Set hide = 0
	if ($$$ISNAN($$$PARSEFLOAT(..bandLeft))) {
		Set hide = 1
	}
	else {
		Set w = ..getPlotX(..bandLeft)-..%plotLeft
		if (w < 0) {
			Set hide = 1
		}
		else {
			Set w = $s((w > ..%plotWidth) : ..%plotWidth, 1 : w)
			do bandLeft.setAttribute("class","chart-band")
			do bandLeft.setAttribute("x",0)
			do bandLeft.setAttribute("y",..%plotTop*this.%scaleY)
			do bandLeft.setAttribute("width",w * this.%scaleX)
			do bandLeft.setAttribute("height",..%plotHeight * this.%scaleY)
			do bandLeft.setAttribute("style",..bandLeftStyle)
		}
	}
	if (hide) {
 		do bandLeft.setAttribute("display","none")
	}
	else {
 		do bandLeft.setAttribute("display","inherit")
	}
	
	// JMD1130 baseLine
	Set baseLine = ..svgGroup.findSVGElement("baseLine"_this.currMultiple)
	if ("" = baseLine) {
		Set baseLine = ##class(node).newElementSVG("line")
		do baseLine.setAttribute("id",this.makeId("baseLine"_this.currMultiple))
		do virtualGroup.appendChild(baseLine)
	}

	Set hide = 0
	if (this.chartPivot) {
		if ($$$ISNAN($$$PARSEFLOAT(..%xBaseValue))) {
			Set hide = 1
		}
		else {
			Set w = this.getPlotX(this.%xBaseValue) - this.%plotLeft
			if (w <= 0) {
				Set hide = 1
			}
			else {
				do baseLine.setAttribute("class","chart-baseLine")
				do baseLine.setAttribute("x1",w*this.%scaleX)
				do baseLine.setAttribute("y1",this.%plotTop*this.%scaleY)
				do baseLine.setAttribute("y2",(this.%plotTop+this.%plotHeight)*this.%scaleY)
				do baseLine.setAttribute("x2",w*this.%scaleX)
				do baseLine.setAttribute("style",this.baseLineStyle)
			}
		}
	}
	else {
		if ($$$ISNAN($$$PARSEFLOAT($LG(this.%yBaseValue,1)))) {
			Set hide = 1
		}
		else {
			Set h = this.getPlotY($LG(this.%yBaseValue,1),0)
			if (h <= 0) {
				Set hide = 1
			}
			else {
				do baseLine.setAttribute("class","chart-baseLine")
				do baseLine.setAttribute("x1",0*this.%scaleX)
				do baseLine.setAttribute("y1",h*this.%scaleY)
				do baseLine.setAttribute("x2",this.%plotWidth*this.%scaleX)
				do baseLine.setAttribute("y2",h*this.%scaleY)
				do baseLine.setAttribute("style",this.baseLineStyle)
			}
		}
	}

	if (hide) {
 		do baseLine.setAttribute("display","none")
	}
	else {
 		do baseLine.setAttribute("display","inherit")
	}
}

/// Given a logical value, return the corresponding x-axis
/// coordinate.
Method getPlotX(val)
{
	Set pct = 0
	if (+..%xRange '= 0) {
		Set pct = (val - ..%xMinValue) / ..%xRange
	}
	
	quit ..%plotLeft + (pct * ..%plotWidth)
}

/// Given a logical value, return the corresponding y-axis
/// coordinate.
Method getPlotY(val, yAxisNo)
{
	Set yAxisNo = $s(('$D(yAxisNo))||($$$ISNAN(yAxisNo))||(""=yAxisNo):0,1:yAxisNo)
	Set pct = 0
	if (+$LG(..%yRange,yAxisNo+1) '= 0) {
		Set pct = (val - $LG(..%yMinValue,yAxisNo+1)) / $LG(..%yRange,yAxisNo+1)
	}
	quit ..%plotBottom - (pct * ..%plotHeight)
}

/// Given a logical value, return the text to use for an axis label.
/// Subclasses can override this for custom behavior.
Method getXLabelText(val, base, noformat)
{
	// JMD1263 - noformat added as a parameter
	Set this=##this
	// JMD1263: if noformat try not to apply time formatting
	// this is used for finding ranges for time-based axes
	// Note from JSL - it looks like noformat is sent to controller and ZEN Reports does not currently have controllers as way of getting data
	
	Set noformat = $G(noformat,0)
	
	if $g(base)="" {
		Set base=1 // JSL4133
	}
	Set label="" ; JMD1125
	// test for callback
	if (""'=..ongetLabelX) {
		if (..passChartObject) {
			Set label = $zobjmethod(%report,..ongetLabelX,val,$this)
		} else {
			Set label = $zobjmethod(%report,..ongetLabelX,val)
		}
	}
	if (label="") {
		// JMD1130
		if ("value"'=this.%xGridType) {
			Set label = val + base
		}
		else {
			Set xAxis = this.getXAxis()
			//switch(xAxis.axisType) 
			if $isObject(xAxis),xAxis.axisType="percent" {
				Set label = ##class(%DeepSee.ResultSet).%FormatNumber(val,"#.%")
			} else {
				//default:
				Set label = this.getNumericAbbreviation(val,this.%xMinValue,this.%xMaxValue)
			}
		}

	}
	Set maxlen = $$$PARSEINT(..maxLabelLen)
	if ((maxlen'="") && ($L(label) > maxlen)) {
		Set label = $e(label,1,maxlen)_"..."
	}
	;Set label=$ZCVT(label,"O","XML") JSL4495 comment out
	quit label
}

/// Given a logical value, return the text to use for an axis label.
/// Subclasses can override this for custom behavior.
Method getYLabelText(val, yAxisNo, base)
{
	Set this=##this
	Set label=""
	if $g(base)="" {
		Set base=1 ; JSL4133
	}
	Set yAxisNo = $s(('$D(yAxisNo))||($$$ISNAN(yAxisNo))||(""=yAxisNo):0,1:yAxisNo)
	// test for callback
	if (""'=..ongetLabelY) {
		if (..passChartObject) {
			Set label = $zobjmethod(%report,..ongetLabelY,val,yAxisNo,$this)
		} else {
			Set label = $zobjmethod(%report,..ongetLabelY,val,yAxisNo)
		}
	}
	
	if (label="") {
		// JMD1130
		if ("value"'=this.%yGridType) {
			Set label = val + base
		}
		else {
			Set yAxis = this.getYAxis(yAxisNo)
			if $isObject(yAxis),yAxis.axisType = "percent" {
				Set label = ##class(%DeepSee.ResultSet).%FormatNumber(val,"#.%")
			} else {
				Set label = this.getNumericAbbreviation(val,$LG(this.%yMinValue,yAxisNo+1),$LG(this.%yMaxValue,yAxisNo+1))
			}
		}

	}
	Set maxlen = $$$PARSEINT(..maxLabelLen)
	if ((maxlen'="") && ($L(label) > maxlen)) {
		Set label = $e(label,1,maxlen)_"..."
	}
	//Set label=$ZCVT(label,"O","XML") // JSL4495 comment out
	if $E(label,1)="." set label="0"_label
	
	quit label
}

/// Convert a user-provided x-coordinate into 0-100 logical space.
/// This means: 10 returns 10, but "10px" is converted using the current width of the chart.  
Method xToLogical(val)
{
	Set this=##this
	quit $s(""=val:val, 1:$s($find(val,"px")>0 : $$$PARSEFLOAT(val)/this.%scaleX , 1: $$$PARSEFLOAT(val)))
}

/// Convert a user-provided y-coordinate into 0-100 logical space.
/// This means: 10 returns 10, but "10px" is converted using the current height of the chart.  
Method yToLogical(val)
{
	set this=##this
	quit $s(""=val:val, 1:$s($find(val,"px")>0 : $$$PARSEFLOAT(val)/this.%scaleY , 1: $$$PARSEFLOAT(val)))
}

/// Return a numeric abbreviation for a value.
/// <var>min</var> and <var>max</var> are range that value falls within.
/// E.g., 10K for 10000
Method getNumericAbbreviation(val, min, max)
{
	Set factor = 1
	Set maxVal = factor * max
	Set minVal = factor * min
	Set range = maxVal-minVal

	Set absmax = $zabs(factor * max)
	Set absmin = $zabs(factor * min)
	Set test = $s((absmax > absmin) : absmax, 1 : absmin)
	
	// test for abbreviated labels
	if (test >= 600000000) {
		// billions
		Set val = ($$$ROUND(val / 10000000)/100)_$s(val'=0:"G", 1:"")
	}
	elseif (test >= 600000) {
		// millions
		Set val = ($$$ROUND(val / 10000)/100)_$s(val'=0:"M", 1:"")
	}
	elseif (test >= 10000) {
		// thousands
		Set val = ($$$ROUND(val / 10)/100)_$s(val'=0:"K", 1:"")
	}
	elseif (range >= 100) {  //SAM used to be test
		// no abbrev: round
		Set val = $$$ROUND(val)
	}
	else {
		if (range>=10) {
			Set val = $$$ROUND(val*10)/10
			Set val = $$$TOFIXED(val,1)
		}
		elseif (range>=1) {
			Set val = $$$ROUND(val*100)/100
			Set val = $$$TOFIXED(val,2)
		}			
		else {
		// small number, 3 decimal digits
			Set val = $$$ROUND(val*1000)/1000
			Set val = $$$TOFIXED(val,3)
		}
	}
	quit val
}

/// Internal method: acquire data for this chart
/// and store a copy in a local cache.
Method acquireData() [ Internal ]
{
	Set this=##this
	Set controller=##class(%ZEN.Report.reportPage).%GetComponentById(..controllerId)
	if (controller'="") {
		// We found a controller
		// get data from controller (make sure data is loaded)
		Set dims = controller.getDimensions()
		
		// set data size based on controller
		Set ..seriesSize = controller.getDimSize(1)
		set ..seriesCount = controller.getDimSize(2)

		// build arrays to hold local copy of data
		// get these arrays directly from the dataController
		do controller.getDataAsArrays(.values)
		merge ..%dataSeries=values ; this is not efficient but doing it for now
		if ('$D(..%dataSeries)) {
			/*
			this._dataSeries = [];
			var size = !this.usePercentForRange() ? this.getSeriesSize() : this.getSeriesCount();
			for (var n = 0; n < size; n++) {
				this._dataSeries[n] = [];
			}
			*/
		}

		// compute series names (for pie-style charts)
		if ('this.hasAxes()) {
			set size = $s(this.usePercentForRange() : this.getSeriesSize(), 1 : this.getSeriesCount())
			//var snames = new Array();
			for n = 1:1:size {
				Set $LI(snames,n) = controller.getLabel(n-1,1) // label is zero-based
			}
			Set ..seriesNames = $LISTTOSTRING(snames,",")
		}
	
	}
	elseif (..ongetData'="") {
		if (..passChartObject) {
			do $zobjmethod(%report,..ongetData,.values,$this)
		} else {
			do $zobjmethod(%report,..ongetData,.values)
		}
		merge ..%dataSeries=values ; this is not efficient but doing it for now
	} 
	else {
		for i=1:1:..dataSeries.Size {
			#dim tDataSeries As dataSeries
			Set tDataSeries=..dataSeries.GetAt(i)
			for j=1:1:tDataSeries.dataValue.Size {
				Set ..%dataSeries(i-1,j-1)=tDataSeries.dataValue.GetAt(j).value
			}
		}
	}
}

/// Internal method: return (as an object) the minimum
/// and maximum data values for this chart. This is used
/// for ranges that are automatically calculated.
Method findDataRange(yAxisNo) [ Internal ]
{
	Set this=##this
	// compute range for given y-axis
	// if yAxisNo is -1, then we are computed x axis values
	if (yAxisNo'=-1) { ; JMD1125
		Set yAxisNo = $s(('$D(yAxisNo))||($$$ISNAN(yAxisNo))||(""=yAxisNo):this.getCurrYAxis(),1:yAxisNo)
	}
	
	Set this=##this
	Set range = ##class(%ZEN.Report.Display.COSChart.range).%New()
	Set range.minValue = "" ; ZEN uses null which is isNaN=false in JavaScript and acts like 0
	Set range.maxValue = ""
	Set range.minValue2 = "" // used by x/y type charts
	Set range.maxValue2 = ""
	
	Set scount = ..getSeriesCount()
	if (scount="") {
		Set s=0
		while $D(..%dataSeries(s)) {
			Set s=s+1
		}
		Set scount=s
	}
	Set items = ..getSeriesSize()

	// JMD1125
	Set useSum = ..useSumForRange()
	if (useSum) {
		Set range.minValue = 0
	}

	if ('..usePercentForRange()) {
		// sum up each series
		Set hasData = 0
		for n = 0:1:(items-1) {
			// JMD1125 track negative total separately
			Set barTotal = ""
			Set areaTotal = ""
			Set barTotalNeg = ""
			Set areaTotalNeg = ""
			for s = 0:1:(scount-1) {
				if ((yAxisNo=-1) || ($LG(this.%yAxisForSeries,s+1)=yAxisNo)) {
					Set group = this.getRangeGroupForSeries(s)
					merge data = this.%dataSeries(s)
					if $D(data) {
						Set hasData = 1
						Set val = data(n)
						if $isObject(val) { // JMD1314
							Set val = val.value // JMD1314
						}
						if ('$$$ISNAN($$$PARSEFLOAT(val))) {
							if (group="bar") {
								if ($$$PARSEFLOAT(val)>=0) {
									Set barTotal = barTotal + $$$PARSEFLOAT(val)
								} else {
									Set barTotalNeg = barTotalNeg + $$$PARSEFLOAT(val)
								}
							}
							elseif (group="area") {
								if ($$$PARSEFLOAT(val)>=0) {
									Set areaTotal = areaTotal + $$$PARSEFLOAT(val)
								} else {
									Set areaTotalNeg = areaTotalNeg + $$$PARSEFLOAT(val)
								}
							}
							else {
								Set val = $$$PARSEFLOAT(val)
								Set range.minValue = $s($$$ISNAN(range.minValue) : val, 1 : $s((val < range.minValue) : val, 1 : range.minValue))
								Set range.maxValue = $s($$$ISNAN(range.maxValue) : val, 1 : $s((val > range.maxValue) : val, 1 : range.maxValue))
							}
						}
					}
				}
			}
			if ('$$$ISNAN(barTotal)) {
				Set range.minValue = $s($$$ISNAN(range.minValue) : barTotal, 1 : $s((barTotal < range.minValue) : barTotal, 1 : range.minValue))
				Set range.maxValue = $s($$$ISNAN(range.maxValue) : barTotal, 1 : $s((barTotal > range.maxValue) : barTotal, 1 : range.maxValue))
				if (useSum && (barTotalNeg'="")) { ; JMD1125
					Set range.minValue = $s(barTotalNeg < range.minValue : barTotalNeg, 1 : range.minValue)
				}
				
			}
			if ('$$$ISNAN(areaTotal)) {
				Set range.minValue = $s($$$ISNAN(range.minValue) : areaTotal, 1 : $s((areaTotal < range.minValue) : areaTotal, 1 : range.minValue))
				Set range.maxValue = $s($$$ISNAN(range.maxValue) : areaTotal, 1 : $s((areaTotal > range.maxValue) : areaTotal, 1 : range.maxValue))
				if (useSum && (areaTotalNeg'="")) {
					Set range.minValue = $s(areaTotalNeg < range.minValue : areaTotalNeg, 1 : range.minValue)
				}

			}
		}
		if ('hasData) {
			Set range.minValue = 0
			Set range.maxValue = 0
		}
	} else {
		// percentage bar chart
		Set range.minValue = 0
		Set range.maxValue = 100

	}

	quit range
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
/// Typically a chart will return true if it is in "stacked" mode.
Method useSumForRange()
{
	quit 0
}

/// This method returns true if data series is a "percentage bar chart" and so
/// calculated data range should be 0 to 100%
Method usePercentForRange()
{
	quit 0
}

/// Return the number of data series for this chart.
Method getSeriesCount()
{
	if (..seriesCount="") {
		Set s=0
		while $D(..%dataSeries(s)) {
			Set s=s+1
		}
		Set ..seriesCount=s // JSL4298
	}

	quit ..seriesCount
}

Method getDataSeriesCount()
{
	Set s=0
	while $D(..%dataSeries(s)) {
		Set s=s+1
	}
	quit s
}

/// Return the length of %dataSeries(0)
Method getDataSeriesLength()
{
	Set s=0
	while $D(..%dataSeries(0,s)) {
		Set s=s+1
	}
	quit s
}

/// Return an array containing the names of the data series for this chart.<br/>
/// If a name is missing, the series number is used.<br/>
Method getSeriesNames() As %List
{
	Set this=##this
	Set sn = ..split(..seriesNames,",")
	Set i=0
	Set names=""
	While (i < ..getSeriesNamesSize()) {
		if ..ongetSeriesName'="" {
			if (..passChartObject) {
				Set name=$zobjmethod(%report,this.ongetSeriesName,i,$this)
			} else {
				Set name=$zobjmethod(%report,this.ongetSeriesName,i)
			}
		} else {
			Set name= $LG(sn,i+1)
		}
		;Set name=$ZCVT(name,"O","XML") ; allow <null> to be processed amongst other XML like series names JSL4495 - comment out
		Set $LI(names,i+1) = $s("" = name : i+1, 1 : name)
		Set i=i+1
	}

	
	quit names
}

/// Return an array of labels to display within the Legend box.<br/>
/// Default implementation is to return a list of series names.
Method getLegendLabels()
{
	if ..legendLabels'="" quit ..split(..legendLabels,",",1) // JSL4144, JSL4161, xml escape legendLabels
	quit ..getSeriesNames()
}

/// Return the marker type that should be used for the given series.
Method getMarkerShape(series)
{
	Set mk = ..split(..markerShapes,",")
	if ($LL(mk)=0) {
		quit "circle"
	}
	quit $s(""=$LG(mk,(series#$LL(mk))+1) : "circle", 1:  $LG(mk,(series#$LL(mk))+1))
}

/// Return an array of color values for given data series
/// color scheme.
Method getColorSchemeArray(scheme) As %List
{
	Set colors = $LB()

	if scheme="bright" {
		Set colors = $LB("url(#shade-blue)","url(#shade-green)","url(#shade-red)","url(#shade-yellow)","url(#shade-purple)","url(#shade-orange)","url(#shade-teal)")
	}
	elseif scheme="glow" {
		Set colors = $LB("url(#glow-blueDiag)","url(#glow-greenDiag)","url(#glow-redDiag)","url(#glow-yellowDiag)","url(#glow-purpleDiag)","url(#glow-orangeDiag)","url(#glow-tealDiag)")
	}
	elseif scheme="gray" {
		Set colors = $LB("#F0F0F0","#C0C0C0","#A0A0A0","#808080","#606060","#D0D0D0","#B0B0B0","#909090")
	}
	elseif scheme="pastel" {
		Set colors = $LB("#5F9EA0","#E9967A","#EEE8AA","#98FB98","#DDA0DD","#8FBC8F","#FFE4B5","#EE82EE")
	} elseif scheme="urban" {
		Set colors = $LB("rgb(71,89,104)","rgb(169,141,109)","rgb(156,152,142)","rgb(91,89,83)","rgb(43,59,64)","rgb(71,89,83)","rgb(127,136,126)","rgb(192,204,173)") ;'
	} elseif scheme="tuscan" {
		Set colors = $LB("rgb(231,192,80)","rgb(210,156,80)","rgb(56,85,47)","rgb(56,57,45)","rgb(55,42,15)","rgb(164,57,39)","rgb(190,226,250)","rgb(226,226,199)") ; '
	} elseif scheme="caribbean" {
		Set colors = $LB("rgb(0,167,153)","rgb(0,220,216)","rgb(0,185,255)","rgb(0,91,102)","rgb(0,80,35)","rgb(127,166,69)","rgb(255,245,199)","rgb(230,199,145)") ; '
	} elseif scheme="rustbelt" {
		Set colors = $LB("rgb(156,51,11)","rgb(110,11,0)","rgb(41,41,42)","rgb(62,49,46)","rgb(109,109,111)","rgb(156,157,156)","rgb(208,208,207)") ;'
	} elseif scheme="solid" {
		Set colors = $LB("blue","green","red","yellow","purple","orange","teal")
	} else {
		Set colors = $LB("blue","green","red","yellow","purple","orange","teal")
	}
	quit colors
}

/// Return the CSS color that should be used for the given series.
/// 0 based
Method getSeriesColor(series)
{
	
	if $LL(..%dataDrivenSeriesColors)=0 {
		Set clr = ..%seriesColors
		if (clr="" || ($LL(clr)= 0)) {
			quit "black"
		}
		quit $s((""=$LG(clr,(series#$LL(clr)+1))) : "black", 1: $LG(clr,series#$LL(clr)+1))
	} else {
		Set clr = ..%dataDrivenSeriesColors
		if (clr="" || ($LL(clr)= 0)) {
			quit "rgb(160,160,160)"
		}
		quit $s((""=$LG(clr,(series#$LL(clr)+1))) : "rgb(160,160,160)", 1: $LG(clr,series#$LL(clr)+1))

	}
}

/// Return the number of items within each data series
/// (this assumes that all data series have the same number of items).
Method getSeriesSize()
{
	if (..seriesSize="") {
		Set smax=0
		For i=0:1:..getSeriesCount()-1 { // JSL4298 - get size of largest series
			Set s=0
			while $D(..%dataSeries(0,s)) {
				Set s=s+1
				Set smax=$$$MAX(s,smax)
			}
		}
		Set ..seriesSize=smax // JSL4298

	}
	Quit ..seriesSize
}

/// Returns if there is a current selected element.
Method hasSelectedItem()
{
	Set this=##this
	quit (($$$PARSEINT(this.selectedSeries)>=0) && ($$$PARSEINT(this.selectedItem)>=0))
}

/// Return any addition select/unselect style to apply to a chart element.
Method getSelectedStyle(series, item, isMarker)
{
	Set this=##this
	Set isMarker = $g(isMarker,0) // JMD1314
	Set selStyle = ""
	if (this.hasSelectedItem()) {
		if (series = this.selectedSeries && (('$D(item)) || (item = this.selectedItem))) {
			Set selStyle = this.selectedItemStyle
		}
		elseif ("2D" = this.appearance) {
			Set selStyle = this.unselectedItemStyle
			if (isMarker) {
				// make sure unselected markers look alright
				Set selStyle = selStyle _ "opacity:1.0;stroke-opacity:0.6;"
			}

		}
	}

	// JMD1130 no fill for selected lines in combo (unless there are markers!)
	Set stype = this.getSeriesType(series)
	if (stype = "line")&&('..markersVisible) {
		Set selStyle = selStyle _ "fill:none;"
	}

	Quit selStyle
}

/// Returns index number (0-based) of the data series of the
/// current selected item, or -1 if there is no current selection.
Method getSelectedSeries()
{
	Set this=##this
	quit this.selectedSeries
}

/// Returns index number (0-based) of the
/// current selected item, or -1 if there is no current selection.
Method getSelectedItem()
{
	Set this=##this
	quit this.selectedItem
}

/// Create a plot marker.
/// This may be used by subclasses to display markers.
/// type can be 'up','down','circle','square'.
Method createMarker(series, item, x, y, color, type, noevents) As node
{
	Set this=##this
	// JMD1100
	Set markerSize = 10	// pixels
	if (this.%scaleX < 2) {
		// small markers
		Set markerSize = 5
	}

	// create marker element
	if type="square" {
		Set marker = ##class(node).%New()
		do marker.createElementSVG("rect")
		do marker.setAttribute("x",-(markerSize*0.8)/2)
		do marker.setAttribute("y",-(markerSize*0.8)/2)
		do marker.setAttribute("width",(markerSize*0.8))
		do marker.setAttribute("height",(markerSize*0.8))

	}
	elseif type="circle" {
		Set marker = ##class(node).%New()
		do marker.createElementSVG("circle")
		do marker.setAttribute("cx",0)
		do marker.setAttribute("cy",0)
		do marker.setAttribute("r",markerSize/2)
	} elseif type="down" {
		Set marker = ##class(node).%New()
		do marker.createElementSVG("polyline")
		Set pts = $LB(-markerSize/2,-markerSize/2, markerSize/2,-markerSize/2, 0,markerSize/2, -markerSize/2,-markerSize/2)
		do marker.setAttribute("points",$LISTTOSTRING(pts))
	} else {
		Set marker = ##class(node).%New()
		do marker.createElementSVG("polyline")
		Set pts = $LB(-markerSize/2,markerSize/2, markerSize/2,markerSize/2, 0,-markerSize/2, -markerSize/2,markerSize/2)
		do marker.setAttribute("points",$LISTTOSTRING(pts))
	} ; JMD1100

	Set scale = ""
	if ("" '= ..markerScale) {
		Set scale = "scale("_..markerScale_","_..markerScale_")"
	}
	do marker.setAttribute("transform","translate("_(x*this.%scaleX)_","_(y*this.%scaleY)_")"_scale)
	// indicate that this is a marker so that we can apply different highlighting when selected
	do marker.setAttribute("isMarker",1) // JMD1314


	do marker.setAttribute("class","chart-seriesMarker")
	do marker.setAttribute("stroke",color)
	//do marker.setAttribute("fill","white") JMD1100 part II
	//do marker.setAttribute("fill-opacity",1.0)

	do marker.setAttribute("style",this.markerStyle _ $s(series>=0:..getSelectedStyle(series,item,1),1:""))
	do marker.setAttribute("id",..makeId("el_" _ series _ "_" _ item))

	quit marker
}

ClassMethod split(str As %String, delim As %String, isXMLEscaped As %Boolean = 0) As %List
{
	Set retVal=""
	for i=1:1:$L(str,delim) {
		Set strippedPiece =$zstrip($P(str,delim,i),"<>W") ; strip off leading and trailing whitespace
		if (isXMLEscaped) {
			Set strippedPiece=$ZCVT(strippedPiece,"O","XML")
		}
		Set retVal=retVal_$LB(strippedPiece)
	}
	quit retVal
}

ClassMethod Test()
{
#if 0	
	Set o=##class(cchart).%New()
	Set styleNVP=##class(styleNVP).%New()
	do o.integrateStyleSpec(styleNVP,"color:red")
	Set a=styleNVP.attr
	Set v=styleNVP.value
	w !,"a.Size="_a.Size
	for i=1:1:a.Size w !,a.GetAt(i)_":"_v.GetAt(i)
#endif
	w !,$$$ROUND(4.9)
	w !,$$$ROUND(-4.9)
}

Method getTextWidth(text, xfontsize)
{
	Set width=0
	for i=1:1:$L(text.content) {
		Set c=$e(text.content,i)
		//Set ratio=$case($a(c),0:0.00,1:0.00,2:0.00,3:0.00,4:0.00,5:0.00,6:0.00,7:0.00,8:0.00,9:0.00,10:0.00,11:0.00,12:0.00,13:0.00,14:0.00,15:0.00,16:0.00,17:0.00,18:0.00,19:0.00,20:0.00,21:0.00,22:0.00,23:0.00,24:0.00,25:0.00,26:0.00,27:0.00,28:0.00,29:0.00,30:0.00,31:0.00,32:0.00,33:0.67,34:0.67,35:0.67,36:0.67,37:1.00,38:1.00,39:0.33,40:0.67,41:0.67,42:0.67,43:0.67,44:0.33,45:0.67,46:0.33,47:0.33,48:0.67,49:0.67,50:0.67,51:0.67,52:0.67,53:0.67,54:0.67,55:0.67,56:0.67,57:0.67,58:0.33,59:0.33,60:0.67,61:0.67,62:0.67,63:0.67,64:1.33,65:1.00,66:0.67,67:0.67,68:1.00,69:0.67,70:0.67,71:1.00,72:1.00,73:0.67,74:0.67,75:1.00,76:0.67,77:1.00,78:1.00,79:1.00,80:0.67,81:1.00,82:0.67,83:0.67,84:0.67,85:1.00,86:1.00,87:1.33,88:1.00,89:1.00,90:0.67,91:0.67,92:0.33,93:0.67,94:0.67,95:0.67,96:0.67,97:0.67,98:0.67,99:0.67,100:0.67,101:0.67,102:0.67,103:0.67,104:0.67,105:0.33,106:0.33,107:0.67,108:0.33,109:1.00,110:0.67,111:0.67,112:0.67,113:0.67,114:0.67,115:0.67,116:0.33,117:0.67,118:0.67,119:1.00,120:0.67,121:0.67,122:0.67,123:0.67,124:0.33,125:0.67,126:0.67,127:0.00,128:0.00,129:0.00,130:0.00,131:0.00,132:0.00,133:0.00,134:0.00,135:0.00,136:0.00,137:0.00,138:0.00,139:0.00,140:0.00,141:0.00,142:0.00,143:0.00,144:0.00,145:0.00,146:0.00,147:0.00,148:0.00,149:0.00,150:0.00,151:0.00,152:0.00,153:0.00,154:0.00,155:0.00,156:0.00,157:0.00,158:0.00,159:0.00,160:0.33,161:0.67,162:0.67,163:0.67,164:0.67,165:0.67,166:0.33,167:0.67,168:0.67,169:1.00,170:0.33,171:0.67,172:0.67,173:0.00,174:1.00,175:0.67,176:0.67,177:0.67,178:0.67,179:0.67,180:0.67,181:0.67,182:0.67,183:0.67,184:0.67,185:0.67,186:0.67,187:0.67,188:1.00,189:1.00,190:1.00,191:0.67,192:1.00,193:1.00,194:1.00,195:1.00,196:1.00,197:1.00,198:1.00,199:0.67,200:0.67,201:0.67,202:0.67,203:0.67,204:0.67,205:0.67,206:0.67,207:0.67,208:1.00,209:1.00,210:1.00,211:1.00,212:1.00,213:1.00,214:1.00,215:0.67,216:1.00,217:1.00,218:1.00,219:1.00,220:1.00,221:1.00,222:0.67,223:0.67,224:0.67,225:0.67,226:0.67,227:0.67,228:0.67,229:0.67,230:0.67,231:0.67,232:0.67,233:0.67,234:0.67,235:0.67,236:0.33,237:0.33,238:0.33,239:0.33,240:0.67,241:0.67,242:0.67,243:0.67,244:0.67,245:0.67,246:0.67,247:0.67,248:0.67,249:0.67,250:0.67,251:0.67,252:0.67,253:0.67,254:0.67,) 
		// calculated throug //perforce/Users/levinson/FontMetrics/ShowFonts.svg which writes table to console
		Set ratio=$case($a(c),0:0.00,1:0.00,2:0.00,3:0.00,4:0.00,5:0.00,6:0.00,7:0.00,8:0.00,9:0.00,10:0.00,11:0.00,12:0.00,13:0.00,14:0.00,15:0.00,16:0.00,17:0.00,18:0.00,19:0.00,20:0.00,21:0.00,22:0.00,23:0.00,24:0.00,25:0.00,26:0.00,27:0.00,28:0.00,29:0.00,30:0.00,31:0.00,32:0.67,33:0.33,34:0.67,35:0.67,36:0.67,37:1.00,38:1.00,39:0.33,40:0.33,41:0.33,42:0.67,43:0.67,44:0.33,45:0.33,46:0.33,47:0.33,48:0.67,49:0.67,50:0.67,51:0.67,52:0.67,53:0.67,54:0.67,55:0.67,56:0.67,57:0.67,58:0.33,59:0.33,60:0.67,61:0.67,62:0.67,63:0.67,64:1.00,65:1.00,66:1.00,67:1.00,68:1.00,69:0.67,70:0.67,71:1.00,72:1.00,73:0.33,74:0.67,75:1.00,76:0.67,77:1.00,78:1.00,79:1.00,80:0.67,81:1.00,82:1.00,83:0.67,84:1.00,85:1.00,86:1.00,87:1.33,88:1.00,89:1.00,90:0.67,91:0.33,92:0.33,93:0.33,94:0.67,95:0.67,96:0.67,97:0.67,98:0.67,99:0.67,100:0.67,101:0.67,102:0.33,103:0.67,104:0.67,105:0.33,106:0.33,107:0.67,108:0.33,109:1.00,110:0.67,111:0.67,112:0.67,113:0.67,114:0.33,115:0.67,116:0.33,117:0.67,118:0.67,119:1.00,120:0.67,121:0.67,122:0.67,123:0.67,124:0.33,125:0.67,126:0.67,127:0.00,128:0.00,129:0.00,130:0.00,131:0.00,132:0.00,133:0.00,134:0.00,135:0.00,136:0.00,137:0.00,138:0.00,139:0.00,140:0.00,141:0.00,142:0.00,143:0.00,144:0.00,145:0.00,146:0.00,147:0.00,148:0.00,149:0.00,150:0.00,151:0.00,152:0.00,153:0.00,154:0.00,155:0.00,156:0.00,157:0.00,158:0.00,159:0.00,160:0.33,161:0.33,162:0.67,163:0.67,164:0.67,165:0.67,166:0.33,167:0.67,168:0.67,169:1.00,170:0.33,171:0.67,172:0.67,173:0.00,174:1.00,175:0.67,176:0.67,177:0.67,178:0.33,179:0.33,180:0.67,181:0.67,182:0.67,183:0.33,184:0.33,185:0.33,186:0.33,187:0.67,188:1.00,189:1.00,190:1.00,191:0.67,192:1.00,193:1.00,194:1.00,195:1.00,196:1.00,197:1.00,198:1.00,199:1.00,200:0.67,201:0.67,202:0.67,203:0.67,204:0.33,205:0.33,206:0.33,207:0.33,208:1.00,209:1.00,210:1.00,211:1.00,212:1.00,213:1.00,214:1.00,215:0.67,216:1.00,217:1.00,218:1.00,219:1.00,220:1.00,221:1.00,222:0.67,223:0.67,224:0.67,225:0.67,226:0.67,227:0.67,228:0.67,229:0.67,230:1.00,231:0.67,232:0.67,233:0.67,234:0.67,235:0.67,236:0.33,237:0.33,238:0.33,239:0.33,240:0.67,241:0.67,242:0.67,243:0.67,244:0.67,245:0.67,246:0.67,247:0.67,248:0.67,249:0.67,250:0.67,251:0.67,252:0.67,253:0.67,254:0.67,:1)
		;Set width=width+((ratio*xfontsize)*3/3.2) ; 3/3.2 is a magic number
		// multiply by .75 JSL3955
		Set width=width+((ratio*xfontsize)) // multiplying by .75 is a hack to make the bounding box in GetBBox line up better with the text
		;Set width=width+((ratio*xfontsize))
	}
	// instead of multipying by .75, JSL3956 multiply by property that stores magic number
	quit width * ..FontXScale
}

Method myCountSpaces(text)
{
	Set count=0
	for i=1:1:$L(text.content) {
		if $e(text.content,i)=" " Set count=count+1
	}
	quit count
}

Method GetBBox(text As node, rotate, scaleX, scaleY, align) As bbox
{
	Set this=##this
	if '$D(rotate) Set rotate=0
	if '$D(scaleX) Set scaleX=1
	if '$D(scaleY) Set scaleY=1
	if '$D(align) Set align="start"
	// TBD - pretty poor implementation, because fixed font table used for calcualting proportions of "M"
	Set bbox=##class(bbox).%New()
	Set bbox.x = (text.getAttribute("x"))
	Set fontsize = text.getAttribute("font-size")	
	Set xfontsize = ..computeXFontSize(text,fontsize) 
	Set yfontsize = ..computeYFontSize(text,fontsize) 
	Set bbox.height=yfontsize
	//Set bbox.y = text.getAttribute("y")+(-yfontsize * 3/3.2) // allow room for leadering
	Set bbox.y = text.getAttribute("y")+(-yfontsize) // allow room for leadering
	Set offset=0
	Set width=0
	Set width = ..getTextWidth(text, xfontsize) 
	;Set width = width - (..myCountSpaces(text)*xfontsize*.5) ; subtract width of spaces multiplied by a magic number, no longer need this hack with new table?
	Set bbox.width=width
	if align="start" {
		Set offset=0
	} elseif align="end" {
		Set offset=-width
	} elseif align="middle" {
		Set offset = -width/2
	}
	Set bbox.x = bbox.x + offset

#if 0
		Set x0=0 ; translate in min/max
		Set y0=0
		Set w=bbox.width
		Set h=bbox.height
			
		Set rotate = 0 ; ignore rotation?
		do ..calcVertex(x0,y0,x0,y0,rotate,.x1,.y1)
		do ..calcVertex(x0,y0,x0+w,y0,rotate,.x2,.y2)
		do ..calcVertex(x0,y0,x0+w,y0+h,rotate,.x3,.y3)
		do ..calcVertex(x0,y0,x0,y0+h,rotate,.x4,.y4)
		
		Set xmin=..min(x1+bbox.x,x2+bbox.x,x3+bbox.x,x4+bbox.x)
		Set xmax=..max(x1+bbox.x,x2+bbox.x,x3+bbox.x,x4+bbox.x)
		Set ymin=..min(y1+bbox.y,y2+bbox.y,y3+bbox.y,y4+bbox.y)
		Set ymax=..max(y1+bbox.y,y2+bbox.y,y3+bbox.y,y4+bbox.y)

		Set bbox.x=xmin
		Set bbox.y=ymin
		Set bbox.width=xmax-xmin
		Set bbox.height=ymax-ymin
#endif

	quit bbox
}

Method calcVertex(x0, y0, x, y, theta, Output x2, Output y2)
{
	; x0, y0 is origin
	; we are rotating x and y by theta about origin
	Set rad = (theta) * ($zPI / 180)
	Set cos=$zcos(rad)
	Set sin=$zsin(rad)
	Set deltax=x-x0
	Set deltay=y-y0
	Set x2 = x0+(deltax*cos)-(deltay*sin)
	Set y2 = y0+(deltax*sin)+(deltay*cos)
}

Method min(x1, x2, x3, x4)
{
	Set min=x1
	if x2 < min Set min = x2
	if x3< min Set min = x3
	if x4 < min Set min = x4
	quit min
}

Method max(x1, x2, x3, x4)
{
	Set max=x1
	if x2 > max Set max = x2
	if x3 > max Set max = x3
	if x4 > max Set max = x4
	quit max
}

Method computeScale(size, axis)
{
	Set suffix=$e(size,*-1,2)
	; is suffix numeric or pixels?
	Set scale=1
	if (+size=size) {
		if (axis="x") {
			Set scale = ..getPelToPixelHRatio() ; for JMD1100
		} elseif (axis="y") {
			Set scale = ..getPelToPixelVRatio() ; for JMD1100
		}
		
		quit scale*size
	}
	if (suffix="px") {
		; don't transform size to points
	} else {
		Set pointConversionFactor=$case(suffix, "pc":12, "in":72, "cm": 28.3464567, "mm": 2.83464567, "pt":1, :1)
		Set size=size*pointConversionFactor * 1.33 ; (multiply by 1.33 to convert from points to pixels
	}
	if (axis="x") {
		Set scale = ..getPelToPixelHRatio() ; for JMD1100
	} elseif (axis="y") {
		Set scale = ..getPelToPixelVRatio() ; for JMD1100
	}
	quit scale * size
}

Method computeXFontSize(text As node, size As %Double)
{
		
	quit ..computeScale(size,"x")
}

Method computeYFontSize(text As node, size As %Double)
{
	// multiply by .75 JSL3955
	// instead of multipying by .75, JSL3956 multiply by property that stores magic number
	quit ..computeScale(size,"y")*..FontYScale
}

Method getComputedTextLength(text As node) As %Double
{
	// TBD - pretty poor implementation
	Set fontsize = text.getAttribute("font-size")	
	Set xfontsize = ..computeXFontSize(text,fontsize) 
	quit ..getTextWidth(text, xfontsize)
}

Method makeId(id As %String)
{
	quit id_"_"_%context("id")
}

Method %DrawToHTML(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set tSC=$$$OK
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	$$$groupNumInc
	Set %context("id")=$$$groupNum
	Set %context("html")=1
	Do XSL.WriteLine("<div>")
#if 0	
	Do ..renderContents()	
	Do ..topLevel.Display(.context,.XSL,.delay)
#else ; JSL3626
	Do XSL.WriteLine("<xsl:call-template name='graphic"_$$$groupNum_"'/>")
	Do delay.WriteLine("<xsl:template name='graphic"_$$$groupNum_"'>")
	Set tSC=..renderContents()	
	If $$$ISERR(tSC) quit tSC
	Set delay2=##class(%GlobalCharacterStream).%New()
	Do:..topLevel'="" ..topLevel.Display(.context,.delay,.delay2)
	Do delay.WriteLine("</xsl:template>")
#endif	
	Do XSL.WriteLine("</div>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	quit tSC
}

Method %DrawToXSLFO(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set tSC=$$$OK
	Set this=##this
	d ..%BeginDrawFo(.context,.XSL,.delay)
	$$$groupNumInc
	Set %context("id")=$$$groupNum
	Set %context("html")=0 ; not html
#if 1 ; JSL3626
	Do XSL.WriteLine("<fo:block>")
	if '((($$$PARSEINT(this.width) <= 1) || ($$$PARSEINT(this.height) <= 1))) {
		Do XSL.WriteLine("<xsl:call-template name='graphic"_$$$groupNum_"'/>")
	}
	Do XSL.WriteLine("</fo:block>")
	Do delay.WriteLine("<xsl:template name='graphic"_$$$groupNum_"'>")
	// JMD1125 do not render if too small
	Do delay.WriteLine("<fo:instream-foreign-object>")
	Set tSC=..renderContents()	
	If $$$ISERR(tSC) quit tSC
	Set delay2=##class(%GlobalCharacterStream).%New()
	Do:..topLevel'="" ..topLevel.Display(.context,.delay,.delay2)
	Do delay.WriteLine("</fo:instream-foreign-object>")
	Do delay.WriteLine("</xsl:template>")
	Do delay.CopyFrom(delay2)
	d ..%EndDrawFo(.context,.XSL,.delay)
#else
	Do XSL.WriteLine("<fo:block>")
	Do XSL.WriteLine("<fo:instream-foreign-object>")
	Do ..renderContents()	
	Do ..topLevel.Display(.context,.XSL,.delay)
	Do XSL.WriteLine("</fo:instream-foreign-object>")
	Do XSL.WriteLine("</fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)
#endif	
	quit tSC
}

/// Return svg group elemment that contains the data series elements.
Method getSeriesSVGGroup()
{
	Set this=##this
	quit ..svgGroup.findSVGElement("seriesGroup")
}

/// Return data values for the given series (0-based)
/// from the chart's data cache.  Return data in %List format.
Method getSeriesData(series) As %List
{
	Set this=##this
	//zenASSERT(this._dataSeries,'Chart data cache is missing',arguments);
	//zenASSERT(this._dataSeries[series],'Chart data series is missing: '+series,arguments);
	Set seriesNumber = this.seriesNumber
	if ('$$$ISNAN($$$PARSEINT(seriesNumber)) && (series'=seriesNumber)) {
		quit ""
	}
	Set retSeries=""
	Set n=1
	while $D(this.%dataSeries(series,n-1)) {
		Set $LI(retSeries,n)=this.%dataSeries(series,n-1)
		Set n=n+1
	}
	quit retSeries
}

Method getStyleArray(styles As %String, ByRef array As %String)
{
	for i=1:1:$L(styles,";") {
		Set pair=$P(styles,";",i)
		Set style=$P(pair,":")
		if (style'="") {
			Set array(style)=$P(pair,":",2)
		}
	}
}

/// Indicate which "group" should be used for computing axis ranges.
/// This is overridden by combo charts.
Method getRangeGroupForSeries(series)
{
	Set this=##this
	// bar means, add up as stacked bar; otherwise compute independently.
	quit $s(this.useSumForRange() : "bar", 1 : "none")
}

/// Draw a line for one data series, <var>s</var> (0-based).
/// <var>data</var> contains the data for all series as an array of arrays.
/// in Java Script s was 0-based, in this code it is 0 based
/// Data is 0-based, colors and shapes are 0-based
Method plotLineForSeries(group, s, ByRef data, stacked, chartFilled, markersVisible, hasEvents)
{
	Set this=##this
	
	// see if there is a selected element
	Set hasSelect = this.hasSelectedItem() ; JMD1100
	Set seriesNumber = this.seriesNumber

	// JMD1208
	Set multipleOffset = $s(this.currMultiple'="":this.currMultiple, 1:0)

	// JMD1100
	Set scaleX = $s(this.%scaleX '= "" :this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY '="": this.%scaleY, 1 : 1)

	Set items = this.getSeriesSize()
	Set color = this.getSeriesColor(s+multipleOffset)
	Set marker = "circle"
	if (markersVisible) {
		Set marker = this.getMarkerShape(s+multipleOffset)
	}

	Set poly=##class(node).%New()
	do poly.createElementSVG("path")
	do poly.setAttribute("class","chart-seriesLine")

	Set path = "" ; path for this line
	do poly.setAttribute("fill","none")
	if ('hasEvents) {
		// special case for background area
		do poly.setAttribute("fill-opacity","0.25")
	}
	do group.appendChild(poly)

	// special fill for background "area" plot.
	Set fillToEdge = 'hasEvents && chartFilled && 'this.plotToEdge

	// y-axis
	Set yAxisNo = $LG(this.%yAxisForSeries,s+1+multipleOffset) ; s is 0-based but list is 1-based

	// JMD1130 pt2
	Set timeBased = this.isTimeBased()

	if ('this.chartPivot) {
		// normal orientation
		if (timeBased) {
			// JMD1130 pt2: set these to 0
			Set dx = 0
			Set adj = 0
		}
		elseif (this.plotToEdge) {
			Set dx = $s((items<=1) : (this.%plotWidth/2), 1 : (this.%plotWidth / (items-1)))
			Set adj = $s((items<=1) : 0, 1 : dx)
		}
		else {
			Set dx = $s((items<=1) : (this.%plotWidth/2), 1 : (this.%plotWidth / items))
			Set adj = $s((items<=1) : 0, 1 : dx/2)
		}

		Set x = 0
		Set base = 0
		if (chartFilled) {
			if ($$$ISNAN($$$PARSEFLOAT($LG(this.%yBaseValue,yAxisNo+1)))) {
				Set base = this.%plotHeight
			}
			else {
				// bug fixed in JMD1125 fix
				Set base = this.getPlotY($LG(this.%yBaseValue,yAxisNo+1),yAxisNo) - this.%plotTop
			}
		}

		if (chartFilled) {
			if (fillToEdge) {
				Set path = "M " _ (x*scaleX) _ " " _ (base*scaleY) _ " "
			}
			else {
				Set path = "M " _ ((x+dx-adj)*scaleX) _ " " _ (base*scaleY) _ " "
			}
			Set firstPoint = 0
		}
		else {
			Set firstPoint = 1
		}

		for n = 0:1:items-1 {
			// JMD1100
			if (timeBased) {
				// JMD1314: check for time in data element
				if ($D(data(s)) && $D(data(s,n)) && $isObject(data(s,n)) && (data(s,n).time'="")) {
					Set time = data(s,n).time
				}
				else {
					Set time = this.getXLabelText(n,1,1)
				}
				Set x = this.getTimeX(time)
				Set x = $s(x="" : 0, 1 : x)
				// test if visible
				// JMD1314 (skip non-visible items only if there are a lot of items)
				if (items > 200) && (x < -0.0001 || x > 100.0001) {
					continue
				}
			}
			else {
				Set x = x + dx
			}

			// JMD1314
			// get this, prior, and next value
			if ($D(data(s))) {
				// var ic = data[s].length;
				Set ic = items
				Set val = $g(data(s,n))
				Set val = $s($isObject(val): val.value, 1 : val)

				Set nextVal = $g(data(s,n+1))
				Set nextVal = $s($isObject(nextVal) : nextVal.value , 1: nextVal)
				Set priorVal = $s(n>0 : $g(data(s,n-1)), 1 : "")
				Set priorVal = $s($isObject(priorVal) : priorVal.value, 1 : priorVal)
                Set nextMissing = $s(n = (ic-1) : 0, 1 : (("" = nextVal) || ((nextVal '= +nextVal) && ("" = nextVal)) || ($$$ISNAN(nextVal))))
				Set nextMissing = $s(ic = 1: 1, 1 : nextMissing)

				Set prevMissing = $s(n = 0 : 0, 1 : (("" = priorVal) || ((priorVal '= +priorVal) && ("" = priorVal)) || ($$$ISNAN(priorVal))))
				Set missing = ("" = val) || ((val'=+val) && "" = val) || ($$$ISNAN(val))
				Set val = $s("" = val : 0, 1 : val)
				Set val = $s($$$ISNAN(val) : 0, 1 : val)
			}
			else {
				Set val = 0
				Set missing = 0
				Set nextMissing = 0
				Set prevMissing = 0
			}
			/* JMD1125
			if (stacked && (val < 0)) {
				// only positive values make sense for stacked charts
				Set val = 0
			}
			*/
			Set isNeg = (val<0)
			if (stacked && (s > 0)) {
				Set dval = 0
				for q = 0:1:s-1 {
					Set v = $s(('$D(data(q))) : 0, 1 : $s(('$D(data(q,n))) : 0, 1 : data(q,n)))
					Set v = $s($isObject(v) : $$$PARSEFLOAT(v.value), 1 : $$$PARSEFLOAT(v))
					// Set dval = dval+ $s((v > 0) : v, 1 : 0) bug? 11-16-2012
					if ((isNeg && (v < 0))||('isNeg && (v > 0))) {
						Set dval = dval + v
					}

				}
				Set val = val + dval
			}
			//Set x = x + dx
			;
			; now this is where I am thinking that I would have to
			; get some val = first point, second point
			; then I would get two y1 and y2
			; this would enable me to mark both at the same X
			;
			Set y = this.getPlotY(val,yAxisNo) - this.%plotTop
			if (missing) {
				// skip; place a marker for this point
				Set firstPoint = 1
			}
			else {
				if (fillToEdge && (n=0)) {
					Set path = path _ "L " _ (0*scaleX) _ " " _ (y*scaleY) _ " "
				}
				if (firstPoint && chartFilled) {
					Set path = path _ "M " _ ((x-adj)*scaleX) _ " " _ (base*scaleY) _ " "
					Set firstPoint = 0
				}
				; added this line of code
				if (firstPoint && ($g(priorVal)="fill")) {Set path = path _"L " _ ((x-adj)*scaleX) _ " " _ (y*scaleY) _ " "}
				else {Set path = path _ $s(firstPoint : "M ", 1 : "L ") _ ((x-adj)*scaleX) _ " " _ (y*scaleY) _ " "}
				; end of added code
				Set firstPoint = 0

				if (markersVisible || nextMissing || prevMissing) {
					// s and n are 0 based but markers are 0 based
					//   so we don't subtract 1 from s and n
					Set mk = this.createMarker(s,n,(x-adj),y,color,marker)
					do group.appendChild(mk)
					if ('markersVisible) {
						do mk.setAttribute("fill",color)
					}
				}
				if (chartFilled && (nextMissing || (n = (items-1)))) {
					if (fillToEdge) {
						Set path = path _ (x*scaleX) _ " " _ (y*scaleY) _ " "
						Set path = path _ (x*scaleX) _ " " _ (base*scaleY) _ " z"
					}
					else {
						Set path = path _ ((x-adj)*scaleX) _ " " _ (base*scaleY) _ " z"
					}
				}
			}
		}
	}
	else {
		// pivotted
		// normal orientation
		if (this.plotToEdge) {
			Set dy = $s((items<=1) : this.%plotHeight, 1 : (this.%plotHeight / (items-1)))
			Set adj = dy
		}
		else {
			Set dy = this.%plotHeight / items
			Set adj = (dy/2)
		}

		Set y = 0
		Set base = 0
		if (chartFilled) {
			if ($$$ISNAN($$$PARSEFLOAT(this.%xBaseValue))) {
				Set base = 0
			}
			else {
				Set base = this.getPlotX(this.%xBaseValue) - this.%plotLeft
			}
		}

		if (chartFilled) {
			if (fillToEdge) {
				Set path = "M " _ (base*scaleX) _ " " _ (y*scaleY) _ " "
			}
			else {
				Set path = "M " _ (base*scaleX) _ " " _ ((y+dy-adj)*scaleY) _ " "
			}
			Set firstPoint = 0
		}
		else {
			Set firstPoint = 1
		}

		for n = 0:1:(items-1) {
			// JMD1314
			// get this, prior, and next value
			if ($D(data(s))) {
				// Set ic = data[s].length;
				Set ic=items
				Set val = $g(data(s,n))
				Set val = $s($isObject(val) : val.value, 1 : val)
				Set nextVal = $g(data(s,n+1))
				Set nextVal = $s($isObject(nextVal) : nextVal.value, 1 : nextVal)
				Set priorVal = $s(n>0 : data(s,n-1), 1 : "")
				Set priorVal = $s($isObject(priorVal) : priorVal.value, 1 : priorVal)

				Set nextMissing = $s(n = (ic-1) : 0 , 1 : (("" = nextVal) || (nextVal'=+nextVal && ("" = nextVal)) || ($$$ISNAN(nextVal))))
				Set nextMissing = $s(ic = 1 : 1, 1 : nextMissing)

				Set prevMissing = $s(n = 0 : 0, 1 : (("" = priorVal) || (( priorVal'= +priorVal) && ("" = priorVal)) || ($$$ISNAN(priorVal))))
				Set missing = ("" = val) || ((val'=+val) && "" = val) || ($$$ISNAN(val))
				Set val = $s("" = val : 0, 1 : val)
				Set val = $s($$$ISNAN(val) : 0, 1 : val)
			}
			else {
				Set val = 0
				Set missing = 0
				Set nextMissing = 0
				Set prevMissing = 0
			}
			if (stacked && (val < 0)) {
				// only positive values make sense for stacked charts
				Set val = 0
			}
			if (stacked && (s > 0)) {
				Set dval = 0
				for q = 0:1:s-1 {
					Set v = $s('$D(data(q)) : 0, 1 : $s('$D(data(q,n)) : 0, 1 : $$$PARSEFLOAT(data(q,n))))
					Set dval = dval + $s((v > 0) : v,1 : 0)
				}
				Set val = val + dval
			}
			Set y = y + dy
			Set x = this.getPlotX(val) - this.%plotLeft

			if (missing) {
				// skip
				Set firstPoint = 1
			}
			else {
				// we check n=0 because data is 0 based
				if (fillToEdge && (n=0)) {
					Set path = path _ "L " _ (x*scaleX) _ " " _ (0*scaleY) _ " "
				}
				if (firstPoint && chartFilled) {
					Set path = path _ "M " _ (base*scaleX) _ " " _ ((y - adj)*scaleY) _ " "
					Set firstPoint = 0
				}
				Set path = path _ $s(firstPoint : "M ", 1 : "L ") _ (x*scaleX) _ " " _ ((y - adj)*scaleY) _ " "
				Set firstPoint = 0
				if (markersVisible || nextMissing || prevMissing) {
					Set mk = this.createMarker(s,n,x,y-adj,color,marker)
					do group.appendChild(mk)
					if ('markersVisible) {
						do mk.setAttribute("fill",color)
					}
				}
				if (chartFilled && (nextMissing || (n = (items-1)))) {
					if (fillToEdge) {
						Set path = path _ (x*scaleX) _ " " _ (y*scaleY) _ " "
						Set path = path _ (base*scaleX) _ " " _ (y*scaleY) _ " z"
					}
					else {
						Set path = path _ (base*scaleX) _ " " _ ((y-adj)*scaleY) _ " z"
					}
				}

			}
		}
	}

	if (path'="") { ; JMD1130
		do poly.setAttribute("d",path)
		do poly.setAttribute("stroke",color)
		do poly.setAttribute("fill",$s(chartFilled : color,1 : "none"))
	} else {
		do poly.setAttribute("stroke","none")
	}
	// JMD1125: make sure line style is used
	do poly.setAttribute("style",this.lineStyle _ ..getSelectedStyle(s) _ $s(chartFilled:"", 1:"fill:none;"))
}

/// Draw a line for one data series, <var>s</var> (0-based).
/// <var>data</var> contains the data for all series as an array of arrays.
/// in Java Script s was 0-based, in this code it is 0 based
/// Data is 0-based, colors and shapes are 0-based
Method plotLinkedLineForSeries(group, s, ByRef data, stacked, chartFilled, markersVisible, hasEvents)
{
	Set this=##this
	
	// see if there is a selected element
	Set hasSelect = this.hasSelectedItem() ; JMD1100
	Set seriesNumber = this.seriesNumber

	// JMD1208
	Set multipleOffset = $s(this.currMultiple'="":this.currMultiple, 1:0)

	// JMD1100
	Set scaleX = $s(this.%scaleX '= "" :this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY '="": this.%scaleY, 1 : 1)

	Set items = this.getSeriesSize()
	// Linked items share the same color
	Set color = this.getSeriesColor(s+multipleOffset)
	// Linked line must always have down and up markers - no other choices
	Set marker1 = "down"
	set marker2 = "up"

	Set poly=##class(node).%New()
	do poly.createElementSVG("path")
	do poly.setAttribute("class","chart-seriesLine")

	Set path = "" ; path for this line
	do poly.setAttribute("fill","none")
	if ('hasEvents) {
		// special case for background area
		do poly.setAttribute("fill-opacity","0.25")
	}
	do group.appendChild(poly)

	// special fill for background "area" plot.
	Set fillToEdge = 'hasEvents && chartFilled && 'this.plotToEdge

	// y-axis
	Set yAxisNo = $LG(this.%yAxisForSeries,s+1+multipleOffset) ; s is 0-based but list is 1-based

	// JMD1130 pt2
	Set timeBased = this.isTimeBased()

	if ('this.chartPivot) {
		// normal orientation
		if (timeBased) {
			// JMD1130 pt2: set these to 0
			Set dx = 0
			Set adj = 0
		}
		elseif (this.plotToEdge) {
			Set dx = $s((items<=1) : (this.%plotWidth/2), 1 : (this.%plotWidth / (items-1)))
			Set adj = $s((items<=1) : 0, 1 : dx)
		}
		else {
			Set dx = $s((items<=1) : (this.%plotWidth/2), 1 : (this.%plotWidth / items))
			Set adj = $s((items<=1) : 0, 1 : dx/2)
		}

		Set x = 0
		Set base = 0
		if (chartFilled) {
			if ($$$ISNAN($$$PARSEFLOAT($LG(this.%yBaseValue,yAxisNo+1)))) {
				Set base = this.%plotHeight
			}
			else {
				// bug fixed in JMD1125 fix
				Set base = this.getPlotY($LG(this.%yBaseValue,yAxisNo+1),yAxisNo) - this.%plotTop
			}
		}

		// always set firstPoint
		Set firstPoint = 1
		

		for n = 0:1:items-1 {
			// JMD1100
			Set x = x + dx
			
			// JMD1314
			// get this, prior, and next value
			if ($D(data(s))) {
				// var ic = data[s].length;
				Set ic = items
				Set val = $g(data(s,n))
				Set val = $s($isObject(val): val.value, 1 : val)
				//Remember on Linked Values you will have a val and a nextVal together
				set nextVal=$p(val,"^",2)
				set val=$p(val,"^",1)

				set priorVal=""
				set nextMissing=0
				set prevMissing=1
				
			}
			else {
				Set val = 0
				Set nextVal=0
				Set missing = 0
				Set nextMissing = 0
				Set prevMissing = 0
			}
			
			Set isNeg = (val<0)
			if (stacked && (s > 0)) {
				Set dval = 0
				for q = 0:1:s-1 {
					Set v = $s(('$D(data(q))) : 0, 1 : $s(('$D(data(q,n))) : 0, 1 : data(q,n)))
					Set v = $s($isObject(v) : $$$PARSEFLOAT(v.value), 1 : $$$PARSEFLOAT(v))
					// Set dval = dval+ $s((v > 0) : v, 1 : 0) bug? 11-16-2012
					if ((isNeg && (v < 0))||('isNeg && (v > 0))) {
						Set dval = dval + v
					}

				}
				Set val = val + dval
			}
			//Set x = x + dx

            if $G(nextVal)'="" {
				Set y = this.getPlotY(val,yAxisNo) - this.%plotTop
				Set path = path _"M "_ ((x-adj)*scaleX) _ " " _ (y*scaleY) _ " "
				Set mk1 = this.createMarker(s,n,(x-adj),y,color,marker1)
				do group.appendChild(mk1)
				if ('markersVisible) {
						do mk1.setAttribute("fill",color)
				}
				//
				Set y = this.getPlotY(nextVal,yAxisNo) - this.%plotTop
				Set path = path _"L "_ ((x-adj)*scaleX) _ " " _ (y*scaleY) _ " "
				Set mk2 = this.createMarker(s,n,(x-adj),y,color,marker2)
				do group.appendChild(mk2)
				if ('markersVisible) {
						do mk2.setAttribute("fill",color)
				}
            }

			
		}
	}

	if (path'="") { ; JMD1130
		do poly.setAttribute("d",path)
		do poly.setAttribute("stroke",color)
		do poly.setAttribute("fill",$s(chartFilled : color,1 : "none"))
	} else {
		do poly.setAttribute("stroke","none")
	}
	// JMD1125: make sure line style is used
	do poly.setAttribute("style",this.lineStyle _ ..getSelectedStyle(s) _ $s(chartFilled:"", 1:"fill:none;"))
}

/// Return the type (how a series should be displayed) for the given data series (0-based).
/// This is used by combo chart and ignored by all others.
Method getSeriesType(series)
{
	quit ""
}

/// Remove the inner SVG for this component.
/// See %ZEN.Display.COSCHart.node for methods being called
Method unrender()
{
	Set this=##this
	if ("" = this.svgGroup) {
		quit
	}
	
	if ("" = this.svgGroup.children || (0 = this.svgGroup.children.Size)) {
		quit
	}

	// remove SVG elements within our enclosing group.
	while("" '= this.svgGroup.firstChild()) {
		do this.svgGroup.removeChild(this.svgGroup.firstChild)
	}
}

/// Indicates that this chart supports and is in "show multiples" mode.
/// A subclass may override this.
Method hasMultiples()
{
	quit 0
}

/// Compute scaling information for a time-based x-axis.
Method computeXAxisTimeLine()
{
	Set this=##this
	// JMD1100
	// find time scale to display
	Set startTime = this.getStartTime()
	Set endTime = this.getEndTime()
	// startTime and endTime are strings since JMD1130!!!
	Set startDate = ##class(Date).stringToDate(startTime)
	Set endDate = ##class(Date).stringToDate(endTime)
	
	// JMD1130(3) test for hours/minutes
	Set hms = $LG(..split(startTime," "),2)
	if (hms'="") {
		Set t = ..split(hms,":")
		if ($LG(t,1)'="") {	do startDate.setHours($$$PARSEINT($LG(t,1)))}
		if ($LG(t,2)'="") {	do startDate.setMinutes($$$PARSEINT($LG(t,2)))}
		if ($LG(t,3)'="") {	do startDate.setSeconds($$$PARSEINT($LG(t,3)))}
	}
	Set hms = $LG(..split(endTime," "),2)
	if (hms'="") {
		Set t = ..split(hms,":")
		if ($LG(t,1)'="") {	do endDate.setHours($$$PARSEINT($LG(t,1)))}
		if ($LG(t,2)'="") {	do endDate.setMinutes($$$PARSEINT($LG(t,2)))}
		if ($LG(t,3)'="") {	do endDate.setSeconds($$$PARSEINT($LG(t,3)))}
	}

	// get span of timeline in seconds
	//Set spanSecs = (endDate.getDate() - startDate.getDate())/1000
	Set spanSecs = startDate.diff(endDate)/1000

	// pick major units based on delta
	Set majorUnits = "years"
	Set minorUnits = "quarters"
	Set startUnits = 0
	Set endUnits = 0

	if (spanSecs > (31536000*20)) {
		Set majorUnits = "decades"
		Set minorUnits = "years"
		Set startUnits = $$$FLOOR((startDate.getFullYear() - 1900) / 10)
		Set endUnits = $$$FLOOR((endDate.getFullYear() - 1900) / 10)
	}
	elseif (spanSecs > (31536000*4)) {
		Set majorUnits = "years"
		Set minorUnits = "quarters"
		Set startUnits = startDate.getFullYear() - 1900
		Set endUnits = endDate.getFullYear() - 1900
	}
	elseif (spanSecs > (31536000*2)) {
		Set majorUnits = "years"
		Set minorUnits = "months"
		Set startUnits = startDate.getFullYear() - 1900
		Set endUnits = endDate.getFullYear() - 1900
	}
	elseif (spanSecs > (31536000)) {
		Set majorUnits = "quarters"
		Set minorUnits = "months"
		Set startUnits = ((startDate.getFullYear()-1900)*4) + $$$FLOOR(startDate.getMonth()/3)
		Set endUnits = ((endDate.getFullYear()-1900)*4) + ($$$FLOOR(endDate.getMonth()/3))
	}
	elseif (spanSecs > (24 * 3600 * 15)) {
		Set majorUnits = "months"
		Set minorUnits = "days"
		Set startUnits = ((startDate.getFullYear()-1900)*12) + $$$FLOOR(startDate.getMonth())
		Set endUnits = ((endDate.getFullYear()-1900)*12) + $$$FLOOR(endDate.getMonth())
	}
	elseif (spanSecs > (24*60*60)) {
		Set majorUnits = "days"
		Set minorUnits = "hours"

		// days since 1900
		Set startUnits = (startDate.getTime() - this.%date1900.getTime())/(24*60*60*1000)
		Set endUnits = (endDate.getTime() - this.%date1900.getTime())/(24*60*60*1000)
	}
	elseif (spanSecs > (60*60)) {
		Set majorUnits = "hours"
		Set minorUnits = "minutes"

		// hours since 1900
		Set startUnits = (startDate.getTime() - this.%date1900.getTime())/(60*60*1000)
		Set endUnits = (endDate.getTime() - this.%date1900.getTime())/(60*60*1000)
	}
	else {
		Set majorUnits = "minutes"
		Set minorUnits = "seconds"

		// minutes since 1900
		Set startUnits = (startDate.getTime() - this.%date1900.getTime())/(60*1000)
		Set endUnits = (endDate.getTime() - this.%date1900.getTime())/(60*1000)
	}


	// tick marks
	Set plotWidth = this.%rplotWidth

	// find (virtual) pixels/sec
	Set this.%pixPerSec = $s(spanSecs>0 : (plotWidth/spanSecs), 1 : 0)

	// find scroll offset
	Set offset = (startDate.getTime())/1000
	Set this.%offset = offset

	Set this.%startUnits = startUnits
	Set this.%endUnits = endUnits
	Set this.%majorUnits = majorUnits
	Set this.%minorUnits = minorUnits
}

/// Render x-axis labels and tick marks for time-based x-axis.
Method renderXAxisTimeLine(timeCellGroup, y)
{
	Set this=##this
	Set majorHeight = 3
	Set minorHeight = 1
	Set minorHeight2 = 1.5 ; JMD1130 pt2

	Set scaleX = this.%scaleX
	Set scaleY = this.%scaleY

	// tick marks
	Set plotWidth = this.%rplotWidth

	Set offset = this.%offset
	Set startUnits = this.%startUnits
	Set endUnits = this.%endUnits
	Set majorUnits = this.%majorUnits
	Set minorUnits = this.%minorUnits

	// plot
	Set d = ""
	Set dMinor = ""
	if (plotWidth>0) {
		// time bar
		Set lastLabelX = 0
		for cell = startUnits:1:endUnits {
			Set info = this.getCellInfo(cell,majorUnits,minorUnits,cell-startUnits)
			Set x = (this.%pixPerSec * (info.startSecs-offset))

			Set d = d_" M " _ (x*scaleX) _ " " _ (this.%plotTop*scaleY) _ " L " _ (x*scaleX) _ " " _ (this.%plotBottom*scaleY) ; ' _ +

			// Major tick
			Set tick = ##class(node).%New()
			do tick.createElementSVG("line")

			//var tick = this.document.createElementNS(SVGNS,'line');
			do tick.setAttribute("class","chart-majorTick")
			do tick.setAttribute("x1",x*scaleX)
			do tick.setAttribute("x2",x*scaleX)
			do tick.setAttribute("y1",y*scaleY)
			if ((lastLabelX=0)||(lastLabelX<x)) {
				do tick.setAttribute("y2",(y+majorHeight)*scaleY)
			}
			else {
				do tick.setAttribute("y2",(y+minorHeight)*scaleY)
			}
			do timeCellGroup.appendChild(tick)

			// label
			if (("" '= info.caption) && ((lastLabelX=0)||(lastLabelX<x))) {
				Set tStyle = this.computeStyle("chart-xLabel","")
				if (this.%xLabelStyle'="") do this.integrateStyleSpec(tStyle,this.%xLabelStyle)
				Set fSz = this.getComputedFontSize(tStyle, 12, 8, 16)

				// Create and add a new scaled text node
				Set text = this.createSVGTextNode(info.caption,fSz,this.autoScaleText,"start",0,timeCellGroup)
				do text.setAttribute("class","chart-xLabel")
				do this.embedStyle(text.firstChild(),tStyle)
				Set h = 1.1*$$$PARSEFLOAT(text.getAttribute("effectiveHeight"))
				Set lastLabelX = x + $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))
				do text.setAttribute("transform","translate("_((x+0.2)*scaleX)_","_((y+h)*scaleY)_")")
			}

			// JMD1166: skip based on gap between minor units
			Set deltaPix = scaleX * (info.minorTicks.GetAt(1) - info.minorTicks.GetAt(0)) * this.%pixPerSec
	
			Set freq = $s((scaleX <=4) : 3 , 1 : 1)

			for j = 0:1:info.minorTicks.Size-1 {
				if ((j-freq)#freq=0) {
					Set xm = (this.%pixPerSec * (info.minorTicks.GetAt(j+1)-offset))
					//var tick = this.document.createElementNS(SVGNS,"line");
					Set tick = ##class(node).%New()
					do tick.createElementSVG("line")
					
					do tick.setAttribute("class","chart-minorTick")
					do tick.setAttribute("x1",xm*scaleX)
					do tick.setAttribute("x2",xm*scaleX)
					do tick.setAttribute("y1",y*scaleY)
					if (majorUnits="months") && (j#5=0) {
						// JMD1130 pt2
						do tick.setAttribute("y2",(y+minorHeight2)*scaleY)
					}
					else {
						do tick.setAttribute("y2",(y+minorHeight)*scaleY)
					}
					do timeCellGroup.appendChild(tick)
					
					if (this.%xMinorGrid'="") {
						Set dMinor = dMinor _ " M " _ (xm*scaleX) _ " " _ (this.%plotTop*scaleY) _ " L " _ (xm*scaleX) _ " " _ (this.%plotBottom*scaleY)
					}
					
				}
			}
		}
	}
	// x minor grid path
	Set xgrid = ..svgGroup.findSVGElement("xGridLineMinor"_this.currMultiple)
	if (xgrid'="") {
		if ((this.%xMinorGrid'="") && (dMinor'="")) {
			do xgrid.setAttribute("d",dMinor)
			do xgrid.setAttribute("visibility","visible")
		}
		else {
			do xgrid.setAttribute("visibility","hidden")
		}
	}

	// x major grid path
	Set xgrid = ..svgGroup.findSVGElement("xGridLine"_this.currMultiple)
	if (xgrid'="") {
		if ((this.%xMajorGrid'="") &&(d'="")) {
			do xgrid.setAttribute("d",d)
			do xgrid.setAttribute("visibility","visible")
		}
		else {
			do xgrid.setAttribute("visibility","hidden")
		}
	}
}

/// For a given time value, YYYY-MM-DD, find the corresponding x coordinate in virtual pixels.
Method getTimeX(time)
{
	Set x=""
	Set this=##this
	if (..%pixPerSec'="") {
		Set d = ##class(Date).stringToDate(time)
		if ($isObject(d)) {
			// JMD1130(3) test for hours/minutes
			Set hms = $LG(..split(time," "),2)
			if (hms'="") {
				Set t = ..split(hms,":")
				if ($LG(t,1)'="") {	do d.setHours($$$PARSEINT($LG(t,1)))}
				if ($LG(t,2)'="") {	do d.setMinutes($$$PARSEINT($LG(t,2)))}
				if ($LG(t,3)'="") {	do d.setSeconds($$$PARSEINT($LG(t,3)))}
			}
			Set startSecs = d.getTime()/1000
			// JMD1130 pt2: remove _plotLeft // !!!
			Set x = (this.%pixPerSec * (startSecs-this.%offset))
		}

	}
	quit x
}

/// Return information about a cell within a time line grid.
Method getCellInfo(cell, majorUnits, minorUnits, index)
{
	Set this=##this

	// { caption:caption, startSecs:startSecs, minorTicks:minorTicks  }
	Set info=##class(CellInfo).%New() ; unlike Java script code, we will fill in info object rather than creating it at end
	
	Set info.caption = ""		// caption for cell
	Set info.startSecs = 0		// number of secs at start of cell

	// minor ticks is an array of starting seconds
	//var minorTicks = [];

	//switch(majorUnits) {
	if (majorUnits = "decades") {
		Set year = ($$$PARSEINT(cell)*10) + 1900 
		Set info.caption = year
		Set d = ##class(Date).createDate(year,0,1)
		Set info.startSecs = d.getTime()/1000

			for n = 1:1:9 {
				Set dt = ##class(Date).createDate((year+n),0,1)
				do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
			}
		
	}

	elseif (majorUnits = "years") {
		Set year = $$$PARSEINT(cell) + 1900
		Set info.caption = year
		Set d = ##class(Date).createDate(year,0,1)
		Set info.startSecs = d.getTime()/1000

		//switch(minorUnits) {
		if (minorUnits="months") {
			for n = 1:1:11 {
				Set dt = ##class(Date).createDate(year,n,1)
				do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
			}
		} else { ; default and quarters
			for n = 1:1:3 {
				Set dt = ##class(Date).createDate(year,n*3,1)
				do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
			}
			
		}
	}

	elseif (majorUnits = "quarters") {
		Set year = $$$PARSEINT($$$FLOOR(cell/4)) + 1900
		Set info.caption = "Q" _ (cell#4+1)
		if ((cell#4=0)||(index=0)) {
			Set info.caption = info.caption_("-" _ year)
		}
		Set d = ##class(Date).createDate(year,(cell#4)*3,1)
		Set info.startSecs = d.getTime()/1000

		// months
		for n = 1:1:12 {
			Set dt = ##class(Date).createDate(year,(((cell#4)*3)+n),1)
			do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
		}
	}
	elseif (majorUnits = "months") {
		Set year = $$$PARSEINT($$$FLOOR(cell/12)) + 1900
		Set info.caption = $P(..zenMonthShortNames,",",(cell#12)+1)
		if (((cell#12=0))||(index<=1)) {
		 	Set info.caption = info.caption_ ("-" _ (year))
		}
		Set d = ##class(Date).createDate(year,(cell#12),1)
		Set info.startSecs = d.getTime()/1000
		Set daysInMonth = $LB(31,28,31,30,31,30,31,31,30,31,30,31)
		if ((year#4=0) && '((year#100)=0 && (year#400)'=0)) {
			Set $LI(daysInMonth,2) = 29
		} 

		// days
		for n = 1:1:$LI(daysInMonth,(cell#12)+1) {
			Set dt = ##class(Date).createDate(year,(cell#12),n)
			do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
		}
	}
	elseif (majorUnits = "days") {
		Set d = ##class(Date).createDate(1900,0,1)
		do d.setDate(this.%date1900.getDate() + $$$FLOOR(cell)) 
		Set info.startSecs = d.getTime()/1000
		Set info.caption = d.dateToString()  // TBD - suport different date formats

		// hours
		for n = 1:1:24-1 {
			Set dt = ##class(Date).createDate(1900,0,1)
			do dt.setTime(d.getTime() + (n*3600*1000)) 
			do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
		}
	}
	elseif (majorUnits = "hours") {
		Set d = ##class(Date).createDate1(1900,0,1,0,0,0,0)
		do d.setHours(this.%date1900.getHours() + $$$FLOOR(cell))
		Set info.startSecs = d.getTime()/1000
		;Set info.caption = ##class(Date).zenDateToString(d,1,..dateFormat)
		if (this.dateFormat'="") {
			Set info.caption = ##class(Date).zenDateToString(d,0,this.dateFormat)
		}
		else {
			Set months = ..zenMonthShortNames
			Set info.caption = $P(months,",",d.getMonth()+1) _ " " _ d.getDate()
		}
		
		Set info.caption = $P(info.caption," ",2) ; time only
		Set info.caption = $P(info.caption,":",1,$L(info.caption,":")-1)

		// 10 minutes
		for n = 1:1:5 {
			Set dt = ##class(Date).createDate1(1900,0,1,0,0,0,0)
			do dt.setTime(d.getTime() + ((n*10)*60*1000))
			do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
		}
	}

	elseif (majorUnits="minutes") {
		Set d = ##class(Date).createDate1(1900,0,1,0,0,0,0)
		do d.setMinutes(this.%date1900.getMinutes() + $$$FLOOR(cell))
		
		Set info.startSecs = d.getTime()/1000
		Set info.caption = ##class(Date).zenDateToString(d,1,this.dateFormat)
		Set info.caption = $P(info.caption," ",2) ; time only
		Set info.caption = $P(info.caption,":",1,$L(info.caption,":")-1)

		// 15 secs
		for n=1:1:3 {
			Set dt = ##class(Date).createDate1(1900,0,1,0,0,0,0)
			do dt.setTime(d.getTime() + ((n*15)*1000))
			do info.minorTicks.SetAt(dt.getTime()/1000,info.minorTicks.Size+1)
		}
	
	}
	quit info
}

/// JMD1100 - this is in canvas in ZEN
/// Calculate the value of the viewBox attribute of this
/// component's enclosing svg element.<br/>
/// Subclasses can override this, should they need to provide
/// a different behavior.
/// The default behavior is to use the width and height of this component
/// to come up with a 1 to 1 coordinate mapping; If the component
/// provides values for the <property>viewboxWidth</property> and 
/// <property>viewboxHeight</property> properties, then these are used to
/// calculate the viewBox (and thus define a fixed coordinate system for the component).
Method calculateViewBox()
{
	Set this=##this
	Set vw = $$$PARSEINT($s("" = this.viewBoxWidth : this.width, 1 : this.viewBoxWidth))
	Set vh = $$$PARSEINT($s("" = this.viewBoxHeight : this.height, 1 : this.viewBoxHeight))
	quit "0 0 " _ vw _ " " _ vh
}

ClassMethod zenGet(value, defvalue)
{
	if $g(value)'="" quit value
	if $g(defvalue)'="" quit defvalue 
	quit ""
}

/// Parse an SVGStyle XData block and put results in pParseClasses
/// pParsedClasses(classname, attribute)=value
ClassMethod ParseCSSStyle(pClassName As %String, ByRef pParsedClasses As %String)
{
	#; find XDATA block containing the style information
	Set tCDef = ##class(%Dictionary.CompiledClass).%OpenId(pClassName)
	if tCDef="" {
		set logId=$i(^%ISCLOG("zenreport","logentries"))
		set ^%ISCLOG("zenreport","logentries",logId,"ParseCSSStyle method",pClassName,"begintime")=$zts
		Quit
	}
	Set tIndex = tCDef.XDatas.FindObjectId(pClassName_"||SVGStyle")
	If (tIndex '= "") {
		#; get XDATA as stream
		Set tStream = tCDef.XDatas.GetAt(tIndex).Data
		Do tStream.Rewind()
		If (tStream.Size > 0) {
			Set state = "start" // simple XML processing!
			While ('tStream.AtEnd) {
				Set tLine = $zstrip(tStream.ReadLine(),"<>W") ; strip leading and trailing white-space
				if tLine [ "/*" { ; start comment, don't handle embedded comments
					Set state = "comment"
				}
				if state="comment",tLine [ "*/" { ; end comment, don't handle embedded comments
					Set state = "start"
					continue
				}
				If (state = "start") {
					If ($e(tLine) = ".") {
						Set tCSSClassName = $zstrip($P($P(tLine,".",2),"{"),"<>W") // strip off "{" introducer, remove leading and trailing white-space
					}
					if tLine [ "{" {
						Set state = "attributes"
					}
				}
				If (state = "attributes") {
					if tLine [ "{" {
						Set tLine=$P(tLine,"{",2)
					}
					for i=1:1:$L(tLine,";") {
						Set tPair = $P(tLine,";",i)
						Set tAttribute = $zstrip($P(tPair,":",1),"<>W")
						Set tValue = $zstrip($P(tPair,":",2),"<>W")
						if $D(tCSSClassName),tAttribute'="",tAttribute'="}" {
							Set pParsedClasses(tCSSClassName,tAttribute)=tValue
						}
					}
					if tLine [ "}" {
						Set state="start"
					} 
					
				
				}
			}
		}
	}
}

/// Get the start time for a time-based chart.
Method getStartTime()
{
	Set startTime = ..startTime
	if startTime="" {
		// JMD1130 get value from range
		if ($$$ISNAN($$$PARSEINT(..%xMinValue))) {
			Set startTime = "2012-01-01"
		}
		else {
			#dim dt As Date
			Set dt = ##class(Date).createDate(1900,0,1)
			do dt.setTime(..%xMinValue*1000)
			Set startTime = ##class(Date).zenDateToString(dt,1)
		}
	}
	quit startTime
}

/// Get the end time for a time-based chart.
Method getEndTime()
{
	Set endTime = ..endTime
	if endTime="" {
		if ($$$ISNAN($$$PARSEINT(..%xMaxValue))) {
			Set endTime = "2012-12-31"
		}
		else {
			Set dt = ##class(Date).createDate(1900,0,1)
			do dt.setTime(..%xMaxValue*1000)
			Set endTime = ##class(Date).zenDateToString(dt,1)
		}
	}
	quit endTime
}

/// Use in chart to give a specifc style to legend
/// Can be overriden by descendent class
Method getLegendRectStyle(s)
{
	quit ""
}

Method getLegendsCount(legends)
{
	Set scount = $LL(legends)
	Set seriesNumber = $$$PARSEINT(..seriesNumber)
	if ('$$$ISNAN(seriesNumber)) {
		Set scount = 1
	}

	quit $s('..usePercentForRange():scount,1:..getSeriesSize())
}

Method getSeriesNamesSize()
{
	quit $s('..usePercentForRange():..getSeriesCount(),1:..getSeriesSize())
}

/// Update the "indicator" (crosshairs) for the selected item.
Method updateIndicator()
{
	Set this=##this
	if ('..indicatorsVisible) quit

	// JMD1314
	Set series = $$$PARSEINT(..selectedSeries)
	Set item = $$$PARSEINT(..selectedItem)

	// create indicators if needed
	Set seriesGroup = ..svgGroup.findSVGElement("seriesGroup" _ this.currMultiple)
	if ('seriesGroup) quit

	Set vtIndicator = ..svgGroup.findSVGElement("vtIndicator"_this.currMultiple)
	if ("" = vtIndicator) {
		Set vtIndicator = ##class(node).newElementSVG("line")
		do vtIndicator.setAttribute("class","chart-indicator")
		do vtIndicator.setAttribute("style",this.indicatorStyle)
		do vtIndicator.setAttribute("id",this.makeId("vtIndicator"_this.currMultiple))
		do seriesGroup.appendChild(vtIndicator)
	}
	Set hzIndicator = ..svgGroup.findSVGElement("hzIndicator"_this.currMultiple)
	if ("" = hzIndicator) {
		Set hzIndicator = ##class(node).newElementSVG("line")
		do hzIndicator.setAttribute("class","chart-indicator")
		do hzIndicator.setAttribute("style",this.indicatorStyle)
		do hzIndicator.setAttribute("id",this.makeId("hzIndicator"_this.currMultiple))
		do seriesGroup.appendChild(hzIndicator)
	}

	// compute position of lines
	Set vtShow = 0
	Set hzShow = 0
	
	do vtIndicator.setAttribute("y1",0)
	do vtIndicator.setAttribute("y2",this.%plotBottom*this.%scaleY)

	do hzIndicator.setAttribute("x1",0)
	do hzIndicator.setAttribute("x2",100*this.%scaleX)

	Set xAxisType = this.getXAxisType()
	Set yAxisType = this.getYAxisType()

	if (this.hasAxes() && $D(this.%dataSeries) && 'this.chartStacked) {
		if (series >= 0) {
			Set items = this.getSeriesSize()
			Set val = $g(this.%dataSeries(series,item))
			// JMD1314
			Set dval =""
			if ($isObject(val)) {
				Set dval = val
				Set val = val.value
			}
			if (val '= "") {
				if (this.isTimeBased()) {
					Set vtShow = 1
					Set hzShow = 1
					Set time = $s((dval'="")&&(dval.time'="") : dval.time, 1 : this.getXLabelText(item,1,1))
					Set x = this.getTimeX(time)
					Set x = $s(x="": 0, 1 : x)
					Set y = this.getPlotY(val) - this.%plotTop
				}
				elseif (this.plotToEdge) {
					Set vtShow = 1
					Set hzShow = 1
					if (xAxisType = "value") {
						if (yAxisType = "value") {
							// x/y chart
							Set val = $g(this.%dataSeries(0,item))
							// JMD1314
							if ($isObject(val)) {
								Set val = val.value
							}
						}
						Set x = this.getPlotX(val) - this.%plotLeft
					}
					else {
						Set dx = $s(items<=1 : (this.%plotWidth/2), 1 : (this.%plotWidth / (items-1)))
						Set adj = $s(items<=1 : 0, 1 : dx)
						Set x = (item-1) * dx + adj
					}
					if (yAxisType = "value") {
						if (xAxisType = "value") {
							// x/y chart
							if ($D(this.%dataSeries(series+1))) {
								Set val2 = $g(this.%dataSeries(series+1,item))
								if ($isObject(val2)) {
									Set val2 = val2.value
								}
								Set y = this.getPlotY(val2) - this.%plotTop
							}
							else {
								Set vtShow = 0
							}
						}
						else {
							Set y = this.getPlotY(val) - this.%plotTop
						}
					}
					else {
						Set dy = $s((items<=1) : (this.%plotHeight/2), 1 : (this.%plotHeight / items))
						Set adj = $s((items<=1) : 0 , 1: dy/2)
						Set y = (item) * dy + adj
					}
				}
				else {
					if (this.chartPivot) {
						Set vtShow = 1
						Set dy = $s(items<=1 : (this.%plotHeight/2), 1 : (this.%plotHeight / items))
						Set adj = $s(items<=1 : 0 , 1: dy/2)
						Set y = (item) * dy + adj
						Set x = this.getPlotX(val) - this.%plotLeft
					}
					else {
						Set hzShow = 1
						Set dx = $s(items<=1 : (this.%plotWidth/2), 1 : (this.%plotWidth / items))
						Set adj = $s(items<=1 : 0, 1 : dx/2)
						Set x = (item) * dx + adj
						Set y = this.getPlotY(val) - this.%plotTop
					}
				}
				do vtIndicator.setAttribute("x1",x * this.%scaleX)
				do vtIndicator.setAttribute("x2",x * this.%scaleX)

				do hzIndicator.setAttribute("y1",y * this.%scaleY)
				do hzIndicator.setAttribute("y2",y * this.%scaleY)
			}
		}
	}

	do vtIndicator.setAttribute("visibility",$s(vtShow : "visible", 1 : "hidden"))
	do hzIndicator.setAttribute("visibility",$s(hzShow : "visible", 1 : "hidden"))
}

/// Render a set of time-events within the chart.
Method renderTimeEvents(group)
{
	/// JMD1314
	Set this=##this
	kill ..%timeEvents
	// var events = null;
	if (""'=..ongetTimeEvents) {
		do $zobjmethod(%report,..ongetTimeEvents,.events,$this)
		
	}
	
	if ('$D(events)) quit ; how do we check if events.length=0?

	merge this.%timeEvents = events

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
	Set sortedEvents = ##class(%ZEN.Report.Display.COSChart.Helpers.SortedEvents).%New()
	Set n="" for { Set n=$O(events(n)) q:n=""
		Set old = $g(events(n))
		if ($isObject(old)) {
			do sortedEvents.push(n, old.start, old.end)
		}
	}

	Set scaleX = this.%scaleX
	Set scaleY = this.%scaleY
	Set boxHgt = 6
	Set markerY = 6
	Set y = this.%plotBottom - this.%plotTop
	Set markerY = y - (boxHgt*1.5)
	
	Set dur="" for { Set dur=$O(sortedEvents.array(dur)) q:dur=""
		Set index="" for { Set index=$O(sortedEvents.array(dur,index),1,sortEvent) q:index=""
			if '$g(sortEvent) continue
			Set idx = sortEvent.index // hmmm... like Joe's code but we have index in index
			Set tlEvent = $g(events(idx))
			if (tlEvent'="" && (tlEvent.start'="")) {
				Set x1 = this.getTimeX(tlEvent.start)
				Set x2 = $s(tlEvent.end '= "" : this.getTimeX(tlEvent.end), 1 : x1)
				Set wid = x2-x1

				// marker + line
				Set mtype = $s(tlEvent.marker'="":tlEvent.marker, 1:"circle")
				if (mtype'="none") {
					Set line = ##class(node).newElementSVG("line")
					do line.setAttribute("class","chart-timeEventLine")
					do line.setAttribute("x1",x1*scaleX)
					do line.setAttribute("x2",x1*scaleX)
					do line.setAttribute("y1",markerY*scaleY)
					do line.setAttribute("y2",y*scaleY)
					do group.appendChild(line)

					Set mk = this.createMarker(-2,idx,x1,markerY,$s(tlEvent.markerColor'="":tlEvent.markerColor,1:"#808080"),mtype)
					do group.appendChild(mk)
				}

				Set rect = ##class(node).newElementSVG("rect")
				do rect.setAttribute("class","chart-timeEvent")
				do rect.setAttribute("style",tlEvent.style)
				do rect.setAttribute("x",x1*scaleX)
				do rect.setAttribute("width",wid*scaleX)
				do rect.setAttribute("y",(y-boxHgt)*scaleY)
				do rect.setAttribute("height",boxHgt*scaleY)
				do group.appendChild(rect)

				do rect.setAttribute("id",this.makeId("evrect"_this.currMultiple_"_" _ (-2) _ "_" _ idx))


				// label
				if (tlEvent.caption'="") {
					Set tStyle = ..computeStyle("chart-timeEventLabel","")
					// if (this._xLabelStyle) this.integrateStyleSpec(tStyle,this._xLabelStyle);
					Set fSz = this.getComputedFontSize(tStyle, 12, 8, 16)
					// Create and add a new scaled text node
					Set text = ..createSVGTextNode(tlEvent.caption,fSz,..autoScaleText,"start",0,group)
					do text.setAttribute("class","chart-xLabel")
					do ..embedStyle(text.firstChild(),tStyle)
					Set th = 1.1*$$$PARSEFLOAT(text.getAttribute("effectiveHeight"))
					Set tw = $$$PARSEFLOAT(text.getAttribute("effectiveWidth"))
					do text.setAttribute("transform","translate("_((x1+0.2)*scaleX)_","_((y-boxHgt+th)*scaleY)_")")
					if (tw > (wid*0.9)) {
						do text.setAttribute("visibility","hidden")
					}
				}
			}
		}
	}
}

}
