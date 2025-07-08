/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for SVG-based Charts for Dashboard.
Class CSPX.Dashboard.Chart Extends Meter [ Abstract, ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINWIDTH = 75;

Parameter MINHEIGHT = 75;

/// Overridden by subclasses to specify which JS object to use for chart.
Parameter CHARTTYPE = "Chart";

/// Number of points to display
Property Points As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// Specifies the source of X-series data:<br>
/// By default, ("history") values are based on the elements within multi-dimensional Metric property;
/// If set to "instances", then values are based on the set of Metric instances for the Metric property.<br>
/// If set to "series", then values are based on the first value of each data series associated with the chart.<br>
Property XDimension As %String(MAXLEN = 20, VALUELIST = ",instances,series,history", XMLPROJECTION = "ATTRIBUTE");

/// Number of vertical grid lines
Property XGridLines As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 10 ];

/// Number of horizontal grid lines
Property YGridLines As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 8 ];

/// Style to apply to chart (this is a string and is dependent on the chart type).
/// Currently, the only available style is 'filled' for LineCharts.
Property Style As %String(MAXLEN = 100, XMLPROJECTION = "ATTRIBUTE");

/// Optional source for labels (along x-axis for line and bar charts).
/// This is the name of multi-dimensional metric property that contains
/// a list of label names.
/// If XDimensions is set to "instances", then this value is ignored.
Property LabelSource As %String(MAXLEN = 64, XMLPROJECTION = "ATTRIBUTE");

/// If true, then scale for this chart is adjusted automatically
/// to match current data values. RangeUpper and RangeLower are ignored.<br>
/// By default, AutoScale is false.<br>
/// If RangeUpper and RangeLower are not defined, then this will be set to true as a convenience.
Property AutoScale As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// If false, then all series for this chart share the same y-axis scale.
/// If true, then the range for each series is specified by each series.
/// By default, IndependentScale is true.
Property IndependentScale As %Boolean(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Optional collection of Series definitions for this chart.
/// If Series are defined the Property defined for this chart is ignored.
Property SeriesList As list Of ChartSeries(XMLNAME = "Series", XMLPROJECTION = "ELEMENT");

/// Internal holder for initial x labels for series.
Property XLabels As %String(MAXLEN = 10000, XMLPROJECTION = "NONE");

ClassMethod OnSVGStyle()
{
	&html<
.Chart-InnerPanel { 
	fill: #000040;
	stroke: gray;
	stroke-width: 1px;
	filter: url(#dropShadow);
}

.Chart-OuterPanel { 
	fill: none;
	stroke: none;
	stroke-width: 1px;
}

.Chart-PlotArea { 
	fill: black;
	stroke: none;
}

.Chart-Axis { 
	stroke: gray;
	stroke-width: 1px;
	stroke-linecap: round;
	fill: none;
}

.Chart-GridLine { 
	stroke: gray;
	stroke-width: 0.5px;
	opacity: 0.7;
}

.Chart-Series { 
	stroke-width: 0.8px;
	fill: none;
	stroke-linecap: round;
	stroke-linejoin: round;
}

.Chart-Bars { 
	fill: green;
	stroke: gray;
	stroke-width: 0.5px;
	fill-opacity: 0.9; 
}

.Chart-yLabel { 
	pointer-events: none;
	font-size: 6;
	fill: yellow;
	stroke: none;
}
.Chart-xLabel { 
	pointer-events: none;
	font-size: 6;
	fill: yellow;
	stroke: none;
}

	>
}

ClassMethod OnSVGHead()
{
	Write "<script type='text/ecmascript' xlink:href='cspchart.js'/>",!
}

ClassMethod OnSVGScript()
{
	// adjust xgridlines for barcharts
	Set adjust = 0
	If (..%ClassName(0) = "BarChart") {
		Set adjust = 1
	}
	
	// customize method name for subclasses
	Write "function ",..%ClassName(0),"_setProperty(property,value,idx)",!
	&js<
{
	switch (property) {
	default:
		return false;

	case 'series':
		// value is a ":" delimited set of points
		if (this.seriesData[idx] == value) {
			// make sure that scale gets updated even when last series does not change
			if (this.autoScale && (this.seriesData.length == (idx+1))) {
				// compute and set auto-scale (only for last series)
				this.chart.updateScale();
			}
			return;
		}
		this.seriesData[idx] = value;

		this.chart.setGridLines(this.xGridLines + #(adjust)#,this.yGridLines);
		if (!this.autoScale) {
			if (!this.independentScale) {
				this.chart.setScale(this.rangeLower, this.rangeUpper, this.scaleFactor);
			}
			else {
				this.chart.setScale(this.seriesRangeLower[idx], this.seriesRangeUpper[idx], this.seriesScaleFactor[idx], idx);
			}
		}

		// find values to plot
		var plotVals,sno,color;
		if ('series' == this.xDimension) {
			// build plotVals across each series
			// ignore 'points'
			sno = 0; // only one series
			color = this.seriesColor[0];
			plotVals = new Array();
			for (var i = 0; i != this.seriesData.length; i++) { 
				plotVals[i] = this.seriesData[i].split(":")[0];
			}
		}
		else {
			sno = idx;
			color = this.seriesColor[idx];
			plotVals = value.split(":");
			if (this.points!=0 && !lessThanEq(plotVals.length,this.points)) {
				// chop off extra points (from the beginning)
				plotVals.splice(0, plotVals.length-this.points);
			}
		}
		
		// do not refresh for auto-scale mode
		this.chart.setSeries(sno,plotVals,color,!this.autoScale);

		if (this.autoScale && (this.seriesData.length == (idx+1))) {
			// compute and set auto-scale (only for last series)
			this.chart.updateScale();
		}

		// set level to most recent value (for one series charts)
		if (plotVals.length == 1) {
			this.level = plotVals[plotVals.length-1];
		}
		else {
			this.level = 'N/A';
		}

		break;
	case 'xlabels':
		// value is a ":" delimited set of labels
		var labels = value.split(':');
		this.chart.setXLabels(labels);
		break;
	}
	return true;
}
	>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	&html<<g id="#(..MeterId)#_chart" transform="translate(5,5)" />>
}

Method OnSVGInitJS()
{
	// build the chart
	&js<meter.chart = new #(..#CHARTTYPE)#(#(..MeterId)#,document.getElementById("#(..MeterId)#_chart"),#(..Width-10)#,#(..Height-25)#,10,15,25,10,'#(..Style)#');>
	&js<meter.chart.showAxes();>
	&js<meter.chart.meter = meter;>

	// set up initial data for chart
	&js<meter.seriesData = new Array();>
	&js<meter.seriesColor = new Array();>
	&js<meter.seriesLabel = new Array();>
	&js<meter.seriesProperty = new Array();>
	&js<meter.seriesInstance = new Array();>
	&js<meter.seriesRangeUpper = new Array();>
	&js<meter.seriesRangeLower = new Array();>
	&js<meter.seriesScaleFactor = new Array();>
	
	For i = 1:1:..SeriesList.Count() {
		Set sno = i-1
		&js<meter.seriesData[#(sno)#] = '#(..SeriesList.GetAt(i).Data)#';>
		&js<meter.seriesColor[#(sno)#] = '#(..SeriesList.GetAt(i).Color)#';>
		&js<meter.seriesLabel[#(sno)#] = '#(..SeriesList.GetAt(i).Label)#';>
		&js<meter.seriesProperty[#(sno)#] = '#(..SeriesList.GetAt(i).Property)#';>
		&js<meter.seriesInstance[#(sno)#] = '#(..SeriesList.GetAt(i).Instance)#';>
		&js<meter.seriesRangeUpper[#(sno)#] = #(+..SeriesList.GetAt(i).RangeUpper)#;>
		&js<meter.seriesRangeLower[#(sno)#] = #(+..SeriesList.GetAt(i).RangeLower)#;>
		&js<meter.seriesScaleFactor[#(sno)#] = #(+..SeriesList.GetAt(i).ScaleFactor)#;>
	}

	// test for labels
	&js<if (meter.xLabels != '') {
		var labels = meter.xLabels.split(':');

		// chop off extra labels
		//!!!if (greaterThanEq(labels.length,#(..SeriesList.Count())#)) {
		//	labels.length = #(..SeriesList.Count())#;
		//}
		meter.chart.setXLabels(labels);
	}
	>

	// test for independentScale
	&js<if (meter.independentScale) {
		meter.chart.independentScale = true;
	}
	>
}

/// Called by Dashboard class to generate code to
/// create an instance of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do ##super(pCode)

	Do:(..Style'="") pCode.WriteLine(" Set tMeter.Style=""" _ ..Style _ """")
	Do:((..XDimension'="")&&(..XDimension'="history")) pCode.WriteLine(" Set tMeter.XDimension=""" _ ..XDimension _ """")
	Do:(..XGridLines'="") pCode.WriteLine(" Set tMeter.XGridLines=" _ ..XGridLines)
	Do:(..YGridLines'="") pCode.WriteLine(" Set tMeter.YGridLines=" _ ..YGridLines)
	Do:(..LabelSource'="") pCode.WriteLine(" Set tMeter.LabelSource=""" _ ..LabelSource _ """")

	If (+..IndependentScale) {
		Do pCode.WriteLine(" Set tMeter.AutoScale=" _ +..AutoScale)
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.AutoScale=$S((+tMeter.RangeLower=0)&&(+tMeter.RangeUpper=0):1,1:" _ +..AutoScale _ ")")
	}
	Do pCode.WriteLine(" Set tMeter.IndependentScale=" _ +..IndependentScale)
	
	If (..SeriesList.Count() = 0) {
		// if no series, use Property for this object
		Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.ChartSeries).%New()")
		Do pCode.WriteLine(" Set tSeries.Property=""" _ ..Property _ """")
		Do pCode.WriteLine(" Set tSeries.Label=""" _ ..Label _ """")
		Do pCode.WriteLine(" Set tSeries.RangeUpper=" _ +..RangeUpper)
		Do pCode.WriteLine(" Set tSeries.RangeLower=" _ +..RangeLower)
		Do pCode.WriteLine(" Set tSeries.ScaleFactor=" _ +..ScaleFactor)
		Do pCode.WriteLine(" Do tMeter.SeriesList.Insert(tSeries)")
	}
	Else {
		For i=1:1:..SeriesList.Count() {
			Set tSeries = ..SeriesList.GetAt(i)
			Do pCode.WriteLine(" Set tSeries = ##class(CSPX.Dashboard.ChartSeries).%New()")
			Do:(tSeries.Property'="") pCode.WriteLine(" Set tSeries.Property=""" _ tSeries.Property _ """")
			Do:(tSeries.Instance'="") pCode.WriteLine(" Set tSeries.Instance=""" _ tSeries.Instance _ """")
			Do:(tSeries.Color'="") pCode.WriteLine(" Set tSeries.Color=""" _ tSeries.Color _ """")
			Do pCode.WriteLine(" Set tSeries.RangeUpper=" _ +tSeries.RangeUpper)
			Do pCode.WriteLine(" Set tSeries.RangeLower=" _ +tSeries.RangeLower)
			Do pCode.WriteLine(" Set tSeries.ScaleFactor=" _ +tSeries.ScaleFactor)

			Do:(tSeries.Color'="") pCode.WriteLine(" Set tSeries.Color=""" _ tSeries.Color _ """")
			If (tSeries.Label'="") {
				Do pCode.WriteLine(" Set tSeries.Label=""" _ tSeries.Label _ """")
			}
			Else {
				Do pCode.WriteLine(" Set tSeries.Label=""" _ tSeries.Property _ """")
			}

			Do pCode.WriteLine(" Do tMeter.SeriesList.Insert(tSeries)")
		}

		// set Property for this object (just to pick up Units etc.)
		Do pCode.WriteLine(" Set tMeter.Property=""" _ ..SeriesList.GetAt(i).Property _ """")
	}

	// Points
	If (..Points'="") {
		Do pCode.WriteLine(" Set tMeter.Points=" _ ..Points)
	}
	Else {
		// get default
		Do pCode.WriteLine(" Set tMeter.Points = tMeter.GetPoints()")
	}
	
	Quit $$$OK
}

/// Returns the number of points used for the metric associated with this meter.
/// This is relevant for multidimensional metrics and is based on the
/// AUTOHISTORY parameter (if defined).
Method GetPoints() As %String
{
	Set $ZT="Trap", tPoints=""
	If ((..Metric '= "") && (..Property '= "")) {
		Set tMetric = $P(..Metric,"(",1)

		// convert Metric to class name
		Set tClass = $$$ConfigClassName(tMetric)
		Set tPoints = +$zobjclassmethod(tClass,..Property_"Points")
	}
Done
	Quit tPoints
Trap
	Set $ZT=""
	Goto Done
}

}
