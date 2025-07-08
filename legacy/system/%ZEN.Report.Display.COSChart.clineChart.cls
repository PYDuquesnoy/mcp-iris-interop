/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.clineChart Extends cchart [ Deprecated, System = 4 ]
{

/// This is an SVG <class>chart</class> component that displays a line chart.<br>
/// This chart displays one or more data series as a set of lines.<br>
/// If there are multiple data series, the lines are either superimposed or
/// or stacked atop one another, as specified by the <property>chartStacked</property> property.<br>
/// You can use the <property>chartFilled</property> property to specify that
/// the area under the lines should be filled, turning this into an area chart.<br>
/// You can view pivot the chart using the <property>chartPivot</property> property.<br>
/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Specifies whether the area under the line is filled (as
/// in an area chart) or not filled (as in a line chart).
Property chartFilled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this is a <i>stacked</i> line chart. That is,
/// data series are plotted above one another.<br>
/// Note that negative values are ignored in stacked charts.
Property chartStacked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
	// create series shapes
	Set this=##this
	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()
	Set firstPoint = 0

	Set seriesNumber = this.seriesNumber
	if ('$$$ISNAN($$$PARSEFLOAT(seriesNumber))) {
		Set scount = 1
	}
	// limit series if we are in small multiples mode
	if (this.showMultiples) {
		Set seriesNumber = this.currMultiple
		Set scount = 1
	}

	if (items > 0) {
		if ('$$$ISNAN($$$PARSEINT(seriesNumber))) {
			// get data from this.%dataSeries at this slice through array
			Set list = this.getSeriesData(seriesNumber)
			for i=1:1:$LL(list) {
				Set data(0,i-1)=$LI(list,i)
			}
		} else {
			// first get data for all series
			merge data=this.%dataSeries		
		}
		// plot series in reverse order to make sure filled,stacked works!
		
		for s = scount-1:-1:0 {
			// dispatch to common line plot method
			do this.plotLineForSeries(group,s,.data,this.chartStacked,this.chartFilled,this.markersVisible,1)
		}
	}
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
Method useSumForRange()
{
	Set this=##this
	quit (""=this.seriesNumber)&&this.chartStacked
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType()
{
	Set this=##this
	quit $s(this.chartPivot : "value", 1 : "category")
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType()
{
	Set this=##this
	quit $s(this.chartPivot : "category", 1 : "value")
}

/// Test if a time-based x axis should be used.
/// This is overridden in subclasses.
Method isTimeBased()
{
	Set this=##this
	quit $s(this.chartPivot  : 0, 1 : this.timeBased)
}

/// Return default style for a line element.
Method getChartElementStyle(series, item)
{
	Set this=##this
	// JMD1314:
	if (this.markersVisible) {
		quit this.markerStyle
	}
	else {
		quit this.lineStyle
	}
}

/// Indicates that this chart supports "show multiples" mode.
Method hasMultiples()
{
	set this=##this
	quit this.showMultiples
}

}
