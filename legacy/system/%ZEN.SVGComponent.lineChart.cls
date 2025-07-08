/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a line chart.<br>
/// This chart displays one or more data series as a set of lines.<br>
/// If there are multiple data series, the lines are either superimposed or
/// or stacked atop one another, as specified by the <property>chartStacked</property> property.<br>
/// You can use the <property>chartFilled</property> property to specify that
/// the area under the lines should be filled, turning this into an area chart.<br>
/// You can view pivot the chart using the <property>chartPivot</property> property.<br>
Class %ZEN.SVGComponent.lineChart Extends chart [ Deprecated, System = 3 ]
{

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
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,val,missing,nextMissing,prevMissing;
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();
	var firstPoint = false;

	// see if there is a selected element
	var hasSelect = !zenIsMissing(this.selectedSeries) && !zenIsMissing(this.selectedItem) && (this.selectedSeries >= 0) && (this.selectedItem >= 0);

	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber)) {
		scount = 1;
	}
	// limit series if we are in small multiples mode
	if (this.showMultiples) {
		seriesNumber = this.currMultiple;
		scount = 1;
	}

	if (items > 0) {
		// first get data for all series
		var data = new Array(scount);
		if (!isNaN(seriesNumber)) {
			data[0] = this.getSeriesData(seriesNumber);
		}
		else {
			for (var s = 0; s < scount; s++) {
				data[s] = this.getSeriesData(s);
			}
		}

		// plot series in reverse order to make sure filled,stacked works!
		for (var s = scount-1; s >=0; s--) {
			// dispatch to common line plot method
			this.plotLineForSeries(group,s,data,this.chartStacked,this.chartFilled,this.markersVisible,true);
		}
	}
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
ClientMethod useSumForRange() [ Language = javascript ]
{
	return (''==this.seriesNumber)&&this.chartStacked;
}

/// Return the type of x axis (category or value) used by
/// this chart.
ClientMethod getXAxisType() [ Language = javascript ]
{
	return this.chartPivot ? 'value' : 'category';
}

/// Return the type of y axis (category or value) used by
/// this chart.
ClientMethod getYAxisType() [ Language = javascript ]
{
	return this.chartPivot ? 'category' : 'value';
}

/// Test if a time-based x axis should be used.
/// This is overridden in subclasses.
ClientMethod isTimeBased() [ Language = javascript ]
{
	return this.chartPivot ? false : this.timeBased;
}

/// Return default style for a line element.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	// JMD1314:
	if (this.markersVisible) {
		return this.markerStyle;
	}
	else {
		return this.lineStyle;
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'chartPivot':
	case 'chartFilled':
	case 'chartStacked':
		this[property] = value ? true : false;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Indicates that this chart supports "show multiples" mode.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return this.showMultiples;
}

}
