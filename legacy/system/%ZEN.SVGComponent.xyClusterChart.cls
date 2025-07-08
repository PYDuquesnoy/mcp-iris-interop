/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays an X-Y chart.<br>
/// This chart plots two or more series of data as a series
/// of x,y points on the chart. The first data series provides
/// the x values, the second provides the correlated y values.<br>
/// Additional data series are plotted as y values 
/// correlated to the x values provided by the first series.<br>
/// The first series name is used as the name of the first series containing
/// y-values.
Class %ZEN.SVGComponent.xyClusterChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Default value for the markersVisible property.
Parameter DEFAULTMARKERSVISIBLE = 1;

XData SVGStyle
{
}

/// Return the type of x axis (category or value) used by
/// this chart.
ClientMethod getXAxisType() [ Language = javascript ]
{
	return 'value';
}

/// Return the type of y axis (category or value) used by
/// this chart.
ClientMethod getYAxisType() [ Language = javascript ]
{
	return 'value';
}

/// Internal method: return (as an object) the minimum
/// and maximum data values for this chart. This is used
/// for ranges that are automatically calculated.
ClientMethod findDataRange() [ Language = javascript ]
{
	var range = new Object();
	range.minValue = null;
	range.maxValue = null;
	range.minValue2 = null; // used by x/y type charts
	range.maxValue2 = null;
	
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();

	// get x range
	for (var s = 0; s < scount; s += 2) {
		var data = this._dataSeries[s];
		for (var n = 1; n < items; n++) {
			var val = data[n];
			if (!isNaN(val)) {
				val = parseFloat(val);
				range.minValue2 = (null==range.minValue2) ? val : (val < range.minValue2) ? val : range.minValue2;
				range.maxValue2 = (null==range.maxValue2) ? val : (val > range.maxValue2) ? val : range.maxValue2;
			}
		}
	}
	
	// get y range
	for (var s = 1; s < scount; s += 2) {
		var data = this._dataSeries[s];
		for (var n = 1; n < items; n++) {
			var val = data[n];
			if (!isNaN(val)) {
				val = parseFloat(val);
				range.minValue = (null==range.minValue) ? val : (val < range.minValue) ? val : range.minValue;
				range.maxValue = (null==range.maxValue) ? val : (val > range.maxValue) ? val : range.maxValue;
			}
		}
	}

	return range;
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,xval,yval;
	var scount = this.getSeriesCount()/2;
	var items =  this.getSeriesSize();
	if (items > 0) {

		// get set of x values
		var xData = new Array();
		var yData = new Array();
		for (var s = 0; s < scount; s++) {
			xData[s] = this.getSeriesData(2*s);
			yData[s] = this.getSeriesData((2*s) + 1);
		}

		// plot points
		for (var s = 0; s < scount; s++) {
			var color = this.getSeriesColor(s);
			if (this.markersVisible) {
				var marker = this.getMarkerShape(s);
			}

			var poly = this.document.createElementNS(SVGNS,"polyline");
			poly.setAttribute("class","chart-seriesLine");
			group.appendChild(poly);
			var points = ''; // set of points for this line

			items = xData[s][0];
			for (var n = 1; n <= items; n++) {
				xval = (null == xData[s]) ? 0 : ((null == xData[s][n]) ? 0 : xData[s][n]);
				yval = (null == yData[s]) ? 0 : ((null == yData[s][n]) ? 0 : yData[s][n]);
				x = this.getPlotX(xval) - this._plotLeft;
				y = this.getPlotY(yval) - this._plotTop;
				points += x + ' ' + y + ' ';

				if (this.markersVisible) {
					group.appendChild(this.createMarker(s,n,x,y,color,marker));
				}
			}
		
			poly.setAttribute("points",points);
			poly.setAttribute("stroke",color);
			poly.setAttribute("fill",'none');
			poly.setAttribute("style",this.plotStyle);
		}
	}
}

/// Return an array of labels to display within the Legend box.<br>
/// For xy chart we have to skip the first series, as it contains
/// x-values, and not a logical data series.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	var scount = this.getSeriesCount();
	if (scount>1) {		
			scount = scount - 1;		
	}
	var legends = new Array(scount);
	var names = this.getSeriesNames();
	for (i = 0; i < scount; i++) {
		legends[i] = (null == names[i] || '' == names[i]) ? (parseInt(i,10)+1) : names[i];
	}
	return legends;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

}
