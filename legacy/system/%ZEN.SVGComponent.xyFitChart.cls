/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.SVGComponent.xyFitChart Extends %ZEN.SVGComponent.xyChart [ Deprecated, System = 3 ]
{

Property hasFit As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property X0Min As %ZEN.Datatype.float;

Property X0Max As %ZEN.Datatype.float;

/// Return the number of data series for this chart.
ClientMethod getSeriesCount() [ Language = javascript ]
{
	if (this.hasFit) {
		return 3;
	}
	return 2;
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	this.renderPoints(group);
	if (this.hasFit) {
		this.renderLine(group);
	}
}

ClientMethod renderPoints(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,val;
	var scount = this.getSeriesCount() - 1;
	var items = this.getSeriesSize();
	if (items <= 0)
		return; 
	// get set of x values
	var xData;
	var yData = new Array();

	xData = this.getSeriesData(0);
	for (var n = 0; n < items; n++) {
		xData[n] = this.getPlotX(xData[n]);
	}
	yData = this.getSeriesData(1);

	// plot points
	var color = this.getSeriesColor(0);
	if (this.markersVisible) {
		var marker = this.getMarkerShape(0);
	}

	var poly = this.document.createElementNS(SVGNS,"polyline");
	poly.setAttribute("class","chart-seriesLine");
	group.appendChild(poly);
	var points = ''; // set of points for this line
	this.X0Min = undefined;
	this.X0Max = undefined;

	for (var n = 0; n < items; n++) {
		val = (null == yData) ? 0 : ((null == yData[n]) ? 0 : yData[n]);
		x = xData[n] - this._plotLeft;
		y = this.getPlotY(val) - this._plotTop;
		points += x + ' ' + y + ' ';
		if ((this.X0Min == undefined) || (x < this.X0Min)) {
			this.X0Min = x;
		}
		if ((this.X0Max == undefined) || (x > this.X0Max)) {
			this.X0Max = x;
		}

		if (this.markersVisible) {
			group.appendChild(this.createMarker(1,n,x,y,color,marker));
		}
	}
		
	// alert(points);
	poly.setAttribute("points",points);
	poly.setAttribute("stroke",color);
	poly.setAttribute("fill",'none');
	poly.setAttribute("style",this.plotStyle);
}

ClientMethod renderLine(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,val,missing,nextMissing,prevMissing;
	var items = this.getSeriesSize();
	var firstPoint = false;

	// see if there is a selected element
	var hasSelect = !zenIsMissing(this.selectedSeries) && !zenIsMissing(this.selectedItem) && (this.selectedSeries >= 0) && (this.selectedItem >= 0);

	var seriesNumber = 2;
	if (items < 1)
		return;
	
	// first get data for all series
	var data = this.getSeriesData(seriesNumber);
	//alert(data)

	// plot series in reverse order to make sure filled,stacked works!
	var color = this.getSeriesColor(2);

	var poly = this.document.createElementNS(SVGNS,"path");
	poly.setAttribute("class","chart-seriesLine");
	var path = ''; // path for this line
	poly.setAttribute("fill",'none');
	group.appendChild(poly);

	var dx, adj;
	var x1 = this.X0Min;
	var xn = this.X0Max;
	var w = xn - x1;
	
	if (this.plotToEdge) {
		dx = (items<=1) ? (w/2) : (w / (items-1));
		adj = (items<=1) ? 0 : dx;
	} else {
		dx = (items<=1) ? (w/2) : (w / items);
		adj = (items<=1) ? 0 : dx/2;
	}
	
	var x = x1
	var base = 0;
	firstPoint = true;

	for (var n = 0; n < items; n++) {
		nextMissing = (null == data || (n == items-1)) ? false : ((null == data[n+1]) || ('number' != typeof data[n+1] && '' == data[n+1]) || (isNaN(data[n+1])));
		nextMissing = (items == 1) ? true : nextMissing;
		prevMissing = (null == data || (n == 0)) ? false : ((null == data[n-1]) || ('number' != typeof data[n-1] && '' == data[n-1]) || (isNaN(data[n-1])));
		missing = (null == data) ? false : ((null == data[n]) || ('number' != typeof data[n] && '' == data[n]) || (isNaN(data[n])));
		val = (null == data) ? 0 : ((null == data[n]) ? 0 : parseFloat(data[n]));
		val = isNaN(val) ? 0 : parseFloat(val);

		x += dx;
		y = this.getPlotY(val) - this._plotTop;
		if (missing) {
			// skip; place a marker for this point
			firstPoint = true;
		} else {
			path += (firstPoint ? 'M ' : 'L ') + (x-adj) + ' ' + y + ' ';
			firstPoint = false;
		}
	}

	poly.setAttribute("d",path);
	poly.setAttribute("stroke",color);

	// see if we are the selected item
	if (this.linePlotStyle = null)
		this.linePlotStyle = this.plotStyle
	if (hasSelect && seriesNumber == this.selectedSeries) {
		poly.setAttribute("style",this.linePlotStyle + this.selectedItemStyle);
	}
	else {
		poly.setAttribute("style",this.linePlotStyle);
	}

	// chartElementClickHandler
	var sno = seriesNumber;
	var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+sno+',0);');
	poly.addEventListener('click',f,false);
	poly.setAttribute('id',this.makeId('el_' + sno + '_' + 0));
}

}
