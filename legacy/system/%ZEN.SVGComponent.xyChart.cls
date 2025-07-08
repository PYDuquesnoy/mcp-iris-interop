/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays an X-Y chart.<br/>
/// This chart plots two or more series of data as a series
/// of x,y points on the chart. The first data series provides
/// the x values, the second provides the correlated y values.<br/>
/// Additional data series are plotted as y values 
/// correlated to the x values provided by the first series.<br/>
/// The first series name is used as the name of the first series containing
/// y-values.<br/>
/// You can supply more than one set of x values using the <property>independentXSeries</property>
/// property.
Class %ZEN.SVGComponent.xyChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Default value for the markersVisible property.
Parameter DEFAULTMARKERSVISIBLE = 1;

/// Optional: if false (the default) the first data series is used to supply
/// x values for the chart and all other data series provide y values.<br/>
/// If false, then the chart will display multiple x series. In this case, the first
/// data series provides the first set of x values, the second
/// data provides the first set of y values, the third data series provides the second
/// set of x values, and so on.
Property independentXSeries As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property seriesYAxes As %ZEN.Datatype.csv(XMLPROJECTION = "none");

Property tag As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "xyChart", Internal ];

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

	if (scount <= 1) {
		// use series 0 as y;
		range.minValue2 = 0;
		range.maxValue2 = items;
		if (scount == 1) {
			var data = this._dataSeries[0];
			for (var n = 0; n < items; n++) {
				var val = data[n];
				if (!isNaN(val)) {
					val = parseFloat(val);
					range.minValue = (null==range.minValue) ? val : (val < range.minValue) ? val : range.minValue;
					range.maxValue = (null==range.maxValue) ? val : (val > range.maxValue) ? val : range.maxValue;
				}
			}
		}
	}
	else {
		// loop over series to compute x & y range
		for (var s = 0; s < scount; s++) {
			var data = this._dataSeries[s];
			var which = this.independentXSeries?(s%2==0?'x':'y'):(s==0?'x':'y');
			if (data) {
				for (var n = 0; n < items; n++) {
					var val = data[n];
					val = parseFloat(val);					
					if (!isNaN(val)) {
						if (which == 'y') {
							range.minValue = (null==range.minValue) ? val : (val < range.minValue) ? val : range.minValue;
							range.maxValue = (null==range.maxValue) ? val : (val > range.maxValue) ? val : range.maxValue;
						}
						else {
							range.minValue2 = (null==range.minValue2) ? val : (val < range.minValue2) ? val : range.minValue2;
							range.maxValue2 = (null==range.maxValue2) ? val : (val > range.maxValue2) ? val : range.maxValue2;
						}
					}
				}
			}
		}
		/*
		// get x range
		var data = this._dataSeries[0];
		for (var n = 0; n < items; n++) {
			var val = data[n];
			if (!isNaN(val)) {
				val = parseFloat(val);
				range.minValue2 = (null==range.minValue2) ? val : (val < range.minValue2) ? val : range.minValue2;
				range.maxValue2 = (null==range.maxValue2) ? val : (val > range.maxValue2) ? val : range.maxValue2;
			}
		}

		// get y range
		for (var s = 1; s < scount; s++) {
			var data = this._dataSeries[s];
			for (var n = 0; n < items; n++) {
				var val = data[n];
				if (!isNaN(val)) {
					val = parseFloat(val);
					range.minValue = (null==range.minValue) ? val : (val < range.minValue) ? val : range.minValue;
					range.maxValue = (null==range.maxValue) ? val : (val > range.maxValue) ? val : range.maxValue;
				}
			}
		}
		*/
	}
	if (this.chartPivot) {
		// swap ranges
		tmin=range.minValue
		tmax=range.maxValue
		range.minValue=range.minValue2
		range.maxValue=range.maxValue2
		range.minValue2=tmin
		range.maxValue2=tmax
	}

	return range;
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;
	var hasEvents = true;

	// create series shapes
	var x,y,xval,yval;
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();
	if (items > 0) {
		// get set of x values
		var xData = [];
		var yData = [];
		if (scount <= 1) {
			// if only one series, use it for y values
			// and pretend there is an x series
			xData[0] = new Array(items);
			for (var n = 0; n < items; n++) {
				xData[0][n] = n;
			}
			yData[0] = this.getSeriesData(0);
			scount = 1;
			var startSeries = 0;
		}
		else if (this.independentXSeries) {
			scount = Math.ceil(scount / 2);

			for (var s = 0; s < scount; s++) {
				xData[s] = this.getSeriesData(s*2);
				yData[s] = this.getSeriesData((s*2)+1);
			}
			var startSeries = 0;
		}
		else {
			xData[0] = this.getSeriesData(0);
			for (var s = 1; s < scount; s++) {
				yData[s] = this.getSeriesData(s);
			}
			var startSeries = 1;
		}

		// plot points
		for (var s = startSeries; s < scount; s++) {
			var ms = this.independentXSeries ? s : s-1;
			var xs = this.independentXSeries ? s : 0;
			var ys = s;
			var color = this.getSeriesColor(ms);
			if (this.markersVisible) {
				var marker = this.getMarkerShape(ms);
			}

			var poly = this.document.createElementNS(SVGNS,"polyline");
			poly.setAttribute("class","chart-seriesLine");
			group.appendChild(poly);
			var points = ''; // set of points for this line

			for (var n = 0; n < items; n++) {
				if (!this.chartPivot) {
					xval = (null == xData[xs]) ? '' : ((null == xData[xs][n]) ? '' : xData[xs][n]);
					yval = (null == yData[ys]) ? '' : ((null == yData[ys][n]) ? '' : yData[ys][n]);
				} else {
					xval = (null == yData[ys]) ? '' : ((null == yData[ys][n]) ? '' : yData[ys][n]);
					yval = (null == xData[xs]) ? '' : ((null == xData[xs][n]) ? '' : xData[xs][n]);					
				}
				x = this.getPlotX(xval) - this._plotLeft;
				y = this.getPlotY(yval) - this._plotTop;
				if ('' !== yval) {
					points += (x*scaleX) + ' ' + (y*scaleY) + ' ';
				}

				if (this.markersVisible) {
					if ('' !== yval) {
						// JMD1296: show tooltip
						var mk = this.createMarker(s,n,x,y,color,marker);
						group.appendChild(mk);
					}
					if (hasEvents) {
						// mouseover/out handlers
						var sno = s;
						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+sno+','+n+');');
						mk.addEventListener('mouseover',f,false);

						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+sno+','+n+');');
						mk.addEventListener('mouseout',f,false);
					}
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
	var legends = [];
	var names = this.getSeriesNames();
	var scount = this.getSeriesCount();
	if (scount>1) {
		if (this.independentXSeries) {
			scount = Math.ceil(scount / 2);
		}
		else {
			scount = scount - 1;
		}
	}

	// JMD1296 show correct labels
	if (this.independentXSeries) {
		for (var i = 1; i < scount+1;i++) {
			var c = ((i-1)*2)+1;
			legends.push((null == names[c] || '' == names[c]) ? (parseInt(i,10)+1) : names[c]);
		}
	}
	else {
		for (var i = 1; i < scount+1; i++) {
			legends.push((null == names[i] || '' == names[i]) ? (parseInt(i,10)+1) : names[i]);
		}
	}
	return legends;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'independentXSeries':
		this[property] = value ? true : false;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Return an object containing tooltip information for the given element.
ClientMethod getToolTipInfo(series, item, captions, values) [ Internal, Language = javascript ]
{
	// JMD1296 override for xy
	var controller = this.getController();

	if (this.getSeriesSize() > 1) {
		var xData = [];
		var yData = [];

		var name = '';
		var names = this.getSeriesNames();
		var scount = this.getSeriesCount();

		if (this.independentXSeries) {
			scount = Math.ceil(scount / 2);
			for (var s = 0; s < scount; s++) {
				xData[s] = this.getSeriesData(s*2);
				yData[s] = this.getSeriesData((s*2)+1);
			}
		}
		else {
			xData[0] = this.getSeriesData(0);
			for (var s = 1; s < scount; s++) {
				yData[s] = this.getSeriesData(s);
			}
		}

		var format = this.valueLabelFormat ? this.valueLabelFormat : '#,#.##';
		if (this.independentXSeries) {
			// y value
			if (names[series*2+1]) {
				captions.push(names[series*2+1]);
				var val = zenGet(yData[series][item]);
				values.push(val!=='' ? zenFormatNumber(val.toString(),format) : '');
			}
			// x value
			if (names[series*2]) {
				captions.push(names[series*2]);
				var val = zenGet(xData[series][item]);
				values.push(val!=='' ? zenFormatNumber(val.toString(),format) : '');
			}
		}
		else {
			// y value
			if (names[series]) {
				captions.push(names[series]);
				var val = zenGet(yData[series][item]);
				values.push(val!=='' ? zenFormatNumber(val.toString(),format) : '');
			}
			// x value
			if (names[0]) {
				captions.push(names[0]);
				var val = zenGet(xData[0][item]);
				values.push(val!=='' ? zenFormatNumber(val.toString(),format) : '');
			}
		}
	}

	// filters
	if (controller && controller.getFilterInfo) {
		var fnames = new Array();
		var fvalues = new Array();
		controller.getFilterInfo(fnames,fvalues);
		for (var n = 0; n < fnames.length; n++) {
			captions.push(fnames[n]);
			values.push(fvalues[n]);
		}
	}
}

}
