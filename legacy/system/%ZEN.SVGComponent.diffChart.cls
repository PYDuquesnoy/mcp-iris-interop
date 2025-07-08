/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a difference chart.<br>
/// This is a specialized type of line chart that
/// displays the difference between a reference data series
/// (the first data series) and an actual data series
/// (the second data series).
Class %ZEN.SVGComponent.diffChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Optional: default style applied to the reference line elements used for plotting
/// data by this chart.
Property refLineStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "stroke-dasharray: 1,1;" ];

Property seriesYAxes As %ZEN.Datatype.csv(XMLPROJECTION = "none");

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	// create series shapes
	var x,y,val;
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();
	if (items > 0) {
		// first get data for all series
		// (there should be 2 series)
		var data = new Array(scount);
		for (var s = 0; s < scount; s++) {
			data[s] = this.getSeriesData(s);
		}

		// plot series in reverse order
		for (var s = scount-1; s >=0; s--) {
			var color = this.getSeriesColor(s);
			if (this.markersVisible) {
				var marker = this.getMarkerShape(s);
			}

			var poly = this.document.createElementNS(SVGNS,"polyline");
			poly.setAttribute("class","chart-seriesLine");
			group.appendChild(poly);
			var points = ''; // set of points for this line

			var dx, adj;
			if (this.plotToEdge) {
				dx = (items<=1) ? this._plotWidth : (this._plotWidth / (items-1));
				adj = dx;
			}
			else {
				dx = this._plotWidth / items;
				adj = (dx/2);
			}

			var x = 0;

			for (var n = 0; n < items; n++) {
				val = (null == data[s]) ? 0 : ((null == data[s][n]) ? 0 : parseFloat(data[s][n]));
				x += dx;
				y = this.getPlotY(val) - this._plotTop;
				points += ((x-(adj))*scaleX) + ' ' + (y*scaleY) + ' ';
				if (this.markersVisible) {
					group.appendChild(this.createMarker(s,n,(x-adj),y,color,marker));
				}
			}
			
			if (s > 0) {
				// get path to fill area between this series and reference
				for (var n = items-1; n >= 0; n--) {
					val = (null == data[0]) ? 0 : ((null == data[0][n]) ? 0 : parseFloat(data[0][n]));
					y = this.getPlotY(val) - this._plotTop;
					points += ((x-(adj))*scaleX) + ' ' + (y*scaleY) + ' ';
					x -= dx;
				}
			}

			poly.setAttribute("points",points);
			poly.setAttribute("stroke",color);
			poly.setAttribute("style",(s==0) ? this.refLineStyle : this.plotStyle);
			poly.setAttribute("fill",(s > 0) ? color : 'none');
		}
	}
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
ClientMethod useSumForRange() [ Language = javascript ]
{
	return false;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'refLineStyle':
		this[property] = value;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

}
