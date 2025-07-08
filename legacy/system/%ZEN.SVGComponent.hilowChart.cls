/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a hi-low-close chart.<br>
/// This chart displays three data series as a set of rectangles: the top of each rectangle
/// represents the high value; the bottom, the low value; a marker is drawn for
/// the closing value.<br>
/// The three data series are interpreted as:
/// <ul>
/// <li>First series: set of high values.</li>
/// <li>Second series: set of low values. Each low value is assumed to be smaller than 
/// its corresponding high value.</li>
/// <li>Third series: set of optional closing values. Each closing value is assumed to between
/// its corresponding high and low values.</li>
/// </ul>
/// You can view pivot the chart using the <property>chartPivot</property> property.<br>
Class %ZEN.SVGComponent.hilowChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for bars where the high value is less than the low value.
Property invertedBarStyle As %ZEN.Datatype.svgStyle;

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,val;
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();

	// we only care about 3 series at most
	scount = (scount > 3) ? 3 : scount;

	// see if there is a selected element
	var hasSelect = this.hasSelectedItem();

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	if (items > 0) {
		// first get data for all series
		var data = new Array(scount);
		for (var s = 0; s < scount; s++) {
			data[s] = this.getSeriesData(s);
		}

		var delta,barsize,adj;
		var color = this.getSeriesColor(0);
		var x = 0;
		var y = 0;
		if (!this.chartPivot) {
			if (this.plotToEdge) {
				delta = (items<=1) ? this._plotWidth : (this._plotWidth / (items-1));
				adj = delta;
			}
			else {
				delta = this._plotWidth / items;
				adj = (delta/2);
			}
			// JMD1100: bar size does not depend on number of series
			barsize = (0.25) * (this._plotWidth / items);
		}
		else {
			if (this.plotToEdge) {
				delta = (items<=1) ? this._plotHeight : (this._plotHeight / (items-1));
				adj = delta;
			}
			else {
				delta = this._plotHeight / items;
				adj = (delta/2);
			}
			// JMD1100: bar size does not depend on number of series
			barsize = (0.25) * (this._plotHeight / items);
		}
		var shift = -barsize/2;

		// loop over items
		for (var n = 0; n < items; n++) {
			var hi = (null == data[0]) ? 0 : ((null == data[0][n]) ? 0 : parseFloat(data[0][n]));
			var low = (null == data[1]) ? 0 : ((null == data[1][n]) ? 0 : parseFloat(data[1][n]));
			var close = (null == data[2]) ? 0 : ((null == data[2][n]) ? 0 : parseFloat(data[2][n]));

			// create shapes
			var bar = this.document.createElementNS(SVGNS,"rect");
			bar.setAttribute("class","chart-seriesBar");
			bar.setAttribute("fill",color);
			var barStyle = '';
			group.appendChild(bar);

			// close marker
			var marker = null;
			if (scount > 2) {
				marker = this.document.createElementNS(SVGNS,"polyline");
				marker.setAttribute("class","chart-seriesBar");
				marker.setAttribute("style",this.plotStyle + ";fill:"+color+";");
				group.appendChild(marker);
			}

			if (!this.chartPivot) {
				x += delta;
				var top = this.getPlotY(hi) - this._plotTop;
				var bottom = this.getPlotY(low) - this._plotTop;
				var mid = this.getPlotY(close) - this._plotTop;

				// marker
				if (marker) {
					var points = '0,5 0,-5 5,0 0,5';
					marker.setAttribute("points",points);
					marker.setAttribute("transform",'translate('+((x-adj-shift)*scaleX)+','+(mid*scaleY)+')');
				}

				// hi-low bar
				var hgt = bottom-top;
				if (hgt < 0) {
					// show inverted bar
					var a = top;
					top = bottom;
					bottom = a;
					hgt = -hgt;
					bar.setAttribute("class","chart-seriesBarInverted");
					barStyle = this.invertedBarStyle;
				}

				bar.setAttribute("x",(x-adj+shift)*scaleX);
				bar.setAttribute("y",top*scaleY);
				bar.setAttribute("width",barsize*scaleX);
				bar.setAttribute("height",hgt*scaleY);
			}
			else {
				y += delta;
				var right = this.getPlotX(hi) - this._plotLeft;
				var left = this.getPlotX(low) - this._plotLeft;
				var mid = this.getPlotX(close) - this._plotLeft;

				// marker
				if (marker) {
					var points = '-5,0 5,0 0,5 -5,0';
					marker.setAttribute("points",points);
					marker.setAttribute("transform",'translate('+(mid*scaleX)+','+((y-adj-shift)*scaleY)+')');
				}

				// hi-low bar
				var wid = right-left;
				if (wid < 0) {
					// show inverted bar
					var a = right;
					right = left;
					left = a;
					wid = -wid;
					bar.setAttribute("class","chart-seriesBarInverted");
					barStyle = this.invertedBarStyle;
				}

				bar.setAttribute("x",left*scaleX);
				bar.setAttribute("y",(y-adj+shift)*scaleY);
				bar.setAttribute("width",wid*scaleX);
				bar.setAttribute("height",barsize*scaleY);
			}

			// see if we are the selected item
			// JMD1000
			if (hasSelect) {
				if (0 == this.selectedSeries && n == this.selectedItem) {
					bar.setAttribute("style",this.plotStyle + ";" + this.selectedItemStyle + ";" + barStyle);
				}
				else {
					bar.setAttribute("style",this.plotStyle + ";" + this.unselectedItemStyle + ";" + barStyle);
				}
			}
			else {
				bar.setAttribute("style",this.plotStyle+";"+barStyle);
			}

			// chartElementClickHandler (series = 0)
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,0,'+n+');');
			bar.addEventListener('click',f,false);
			bar.setAttribute('id',this.makeId('el_0_' + n));

			// JMD1100 mouseover/out handlers
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+0+','+n+');');
			bar.addEventListener('mouseover',f,false);

			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+0+','+n+');');
			bar.addEventListener('mouseout',f,false);
		}
	}
}

/// Return an array of labels to display within the Legend box.<br>
/// A hilow chart only displays one logical data series, so only one
/// item is displayed in the legend box.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	// construct an array of one element
	var legends = new Array(1);
	var names = this.getSeriesNames();
	legends[0] = names[0];
	return legends;
}

/// Return default style for a bar element.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	return this.plotStyle;
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

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
ClientMethod useSumForRange() [ Language = javascript ]
{
	return this.chartStacked;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'chartPivot':
	case 'invertedBarStyle':
		this[property] = value ? true : false;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

}
