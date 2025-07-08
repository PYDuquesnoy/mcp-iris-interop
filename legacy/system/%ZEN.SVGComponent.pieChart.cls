/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a pie chart.<br>
/// The <property>plotBy</property> property specifies how the slices of the chart and their labels
/// should be calculated.<br>
/// The size of each slice is adjusted proportionally so that a complete circle is formed.<br>
/// The colors of the slice is determined by the <property>seriesColors</property> property.
/// If there are more slices than colors, then the colors are repeated.<br>
Class %ZEN.SVGComponent.pieChart Extends chart [ Deprecated, System = 3 ]
{

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "2D";

/// Default size of hole in center of the chart.
Parameter DEFAULTHOLESIZE = 0;

/// Specifies how the pie chart will plot its data.
/// <ul>
/// <li>"items" - plot a slice for every item within this chart's data. If
/// there are multiple data series, each slice represents the total of each item
/// summed across the data series.<br>
/// The labels for the slices are treated as Y axis labels: the <property>onGetLabelY</property> event handler is
/// called to get the label values, or the labels are provided by a <class>%ZEN.Auxiliary.dataController</class>
/// if present.
/// </li>
/// <li>"series" - plot a slice for every data series within this chart's data.
/// Each slice represents the total value of all items within each series.<br>
/// The labels for the slices are specified by the <property>seriesNames</property> property.</li>
/// <li>"both" - plot a slice for each item within each data series (that is, there
/// will be seriesCount * seriesSize slices).<br>
/// The slices are labeled as items; the chart legend will display the series names.
/// </li>
/// <li>"auto" - automatically select the appropriate way to display data based on how many data
/// series and items are present.
/// </li>
/// </ul>
Property plotBy As %ZEN.Datatype.string(VALUELIST = ",auto,items,series,both") [ InitialExpression = "auto" ];

/// Scaling factor used to compute size of pie within the chart.<br/>
/// The default scaling value is 1.0. A value larger than 1.0 makes the pie
/// bigger relative to the chart's plot area; a value smaller than 1.0 makes the
/// pie smaller.
Property pieScale As %ZEN.Datatype.float [ InitialExpression = 1.0 ];

/// If true, percentage values (rounded to nearest integer) are displayed as 
/// part of the label for each slice.
Property showPercentage As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, the item value is displayed as part of the label for each slice.
Property showValue As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// For pie charts with <property>appearance</property> set to "3D",
/// this controls the apparent height of 3D pie chart.<br/>
/// The value of this property is a percentange of the chart's 
/// radius along the x axis. If the size of the chart is changed,
/// its depth will maintain its proportional size.<br/>
/// The value can range from 0 to 1. The default value is 0.33.
Property pieHeight As %ZEN.Datatype.float(MAXVAL = 1, MINVAL = 0) [ InitialExpression = 0.33 ];

/// This controls whether a hole is displayed in the center of the
/// pie chart, and if so, how big the hole is.<br/>
/// The value of this property is a percentange of the chart's 
/// radius along the x axis. If the size of the chart is changed,
/// the size of the center hole will maintain its proportional size.<br/>
/// The value can range from 0 to 0.9. The default value is 0.
/// Set this to 0.2 to display a "donut chart".
Property holeSize As %ZEN.Datatype.float(MAXVAL = 0.9, MINVAL = 0) [ InitialExpression = {..#DEFAULTHOLESIZE} ];

/// If specified, rotate the pie chart by this amount (in degrees).
Property rotateBy As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// Position of labels as a multiple of the chart radius.
/// The default is 1.1.
Property labelRadius As %ZEN.Datatype.float(MAXVAL = 1.5, MINVAL = 0.5);

XData SVGStyle
{
}

/// Indicates that this chart has no axes and associated grids
ClientMethod hasAxes() [ Language = javascript ]
{
	return false;
}

/// Do not show 3-D plot area.
ClientMethod is3D() [ Language = javascript ]
{
	return false;
}

/// Return an array of labels to display within the Legend box.<br>
/// Override to get appropriate labels for Pie Chart.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	var legends = new Array();

	var sc = this.getSeriesCount();
	var ic = this.getSeriesSize();
	if ('auto' == this.plotBy && (ic == 1 || sc == 1)) {
		return legends;
	}

	switch (this.getPlotBy()) {
	case 'series':
	case 'both':
		var names = this.getSeriesNames();
		for (i = 0; i < sc; i++) {
			legends[i] = (null == names[i] || '' == names[i]) ? (parseInt(i,10)+1) : names[i];
		}
		break;
	case 'items':
	default:
		for (var i = 0; i < ic; i++) {
			var	lbl = this.getYLabelText(i,'',1); // JSL4129 - make 1 based
			// Note that getYLabelText(i) never returns null!!!! JSL - 3/20/2013
			legends[i] = zenIsMissing(lbl) ? (parseInt(i,10)+1) : lbl;
		}
		break;
	}

	return legends;
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	try {
		// assemble data for plotting
		var sc = this.getSeriesCount();
		var ic = this.getSeriesSize();
		var items = 0;
		var values = new Array();
		var total = 0;
		var snames = null;
		var plotBy = this.getPlotBy();

		// JMD1100
		var scaleX = this._scaleX ? this._scaleX : 1;
		var scaleY = this._scaleY ? this._scaleY : 1;

		var seriesNumber = parseInt(this.seriesNumber);
		if (!isNaN(seriesNumber)) {
			sc = 1;
		}

		// limit series if we are in small multiples mode
		if (this.showMultiples) {
			seriesNumber = this.currMultiple;
			sc = 1;
			plotBy = 'items';
		}

		switch (plotBy) {
		case 'series':
			items = sc;
			snames = this.getSeriesNames();
			for (var s = 0; s < sc; s++) {
				var data = this._dataSeries[isNaN(seriesNumber)?s:seriesNumber];
				var value = 0;
				for (var i = 0; i < ic; i++) {
					value += (data==null || data[i] == null || data[i] < 0 || isNaN(parseFloat(data[i]))) ? 0 : (parseFloat(data[i]));
				}
				values[s] = value;
				total += value;
			}
			break;
		case 'items':
		default:
			items = ic;
			for (var i = 0; i < ic; i++) {
				var value = 0;
				for (var s = 0; s < sc; s++) {
					var data = this._dataSeries[isNaN(seriesNumber)?s:seriesNumber];
					value += (data == null || data[i] == null || data[i] < 0 || isNaN(parseFloat(data[i]))) ? 0 : (parseFloat(data[i]));
				}
				values[i] = value;
				total += value;
			}
			break;
		case 'both':
			items = sc*ic;
			snames = this.getSeriesNames();
			for (var s = 0; s < sc; s++) {
				var data = this._dataSeries[isNaN(seriesNumber)?s:seriesNumber];
				for (var i = 0; i < ic; i++) {
					var value = (data == null ||data[i] == null || data[i] < 0 || isNaN(parseFloat(data[i]))) ? 0 : (parseFloat(data[i]));
					values[values.length] = value;
					total += value;
				}
			}
			break;
		}

		// Hide labels for wedges with % smaller than this
		// the more wedges, the bigger the min size!
		var minWedge = items <= 12 ? 0.01 : items <= 24 ? 0.025 : 0.05;

		// find size of pie (ignore margins)
		var gw = (this._plotWidth * 0.55);
		var gh = (this._plotHeight * 0.70);

		var sz = (gw > gh) ? gh/2 : gw/2;
		var cx = this._plotWidth / 2;
		var cy = this._plotHeight / 2;
		sz = sz * parseFloat(this.pieScale);

		var hs = parseFloat(this.holeSize);
		hs = (hs < 0) ? 0 : (hs > 0.9) ? 0.9 : hs;
		var hole = sz * hs;

		// 3d info
		var xRadius =  sz;
		var yRadius =  sz / 1.8;
		var xHoleRadius =  hole;
		var yHoleRadius =  hole / 1.8;

		var ph = parseFloat(this.pieHeight);
		ph = (ph < 0) ? 0 : (ph > 1) ? 1 : ph;
		var pieHeight = (Math.round(sz * ph *1000)/1000);
		var is3D = ('3D' == this.appearance);
		var seriesGroup = this.getSeriesSVGGroup();

		// JMD1100 make pie round if not 3D
		if (is3D) {
			var scaleRX = scaleX;
			var scaleRY = scaleY;
		}
		else {
			if (scaleX > scaleY) {
				var scaleRX = scaleY;
				var scaleRY = scaleY;
			}
			else {
				var scaleRX = scaleX;
				var scaleRY = scaleX;
			}
		}

		// if number of slices has changed, clear out the old slices
		if ((0 == total) || (null == seriesGroup) || (null == seriesGroup.firstChild) || (items == 0) || (this._slices && (items != this._slices.length))) {
			// remove SVG elements within our group.
			while(null != group.firstChild) {
				group.removeChild(group.firstChild);
			}
			delete this._circle;
			delete this._slices;
			delete this._edges;
			delete this._innerEdges;
			delete this._shadow;
			delete this._underEdge;
			delete this._innerUnderEdge;
		}
		
		if (0 == total) {
			// nothing to show
			var circ = this._circle;
			if (null == circ) {
				circ = this.document.createElementNS(SVGNS,"ellipse");
				this._circle = circ;
				group.appendChild(circ);
			}
			circ.setAttribute("cx",cx*scaleX);
			circ.setAttribute("cy",cy*scaleY);
			circ.setAttribute("rx",sz*scaleRX);
			circ.setAttribute("ry",sz*scaleRY);
			circ.setAttribute("style","stroke: none; fill: darkblue; opacity: 0.1;");
			return;
		}

		// create new slices & labels
		if ((null == seriesGroup) || 
			(null == seriesGroup.firstChild) || 
			((null == this._slices) && items > 0)) {
			if (null==this._slices) { this._slices = new Array(items); }
			if (null==this._edges) { this._edges = new Array(items); }
			if (null==this._innerEdges) { this._innerEdges = new Array(items); }

			// circle in the middle
			if (!is3D) {
				var circ = this._circle;
				if (null == circ) {
					circ = this.document.createElementNS(SVGNS,"ellipse");
					this._circle = circ;
					group.appendChild(circ);
				}
				circ.setAttribute("cx",cx*scaleX);
				circ.setAttribute("cy",cy*scaleY);
				circ.setAttribute("rx",sz*scaleRX);
				circ.setAttribute("ry",sz*scaleRY);
				if (hole > 0) {
					circ.setAttribute("display","none");
				}
				circ.setAttribute("style","stroke: none; fill: white; opacity: 0.5;");
			}
			else {
				// shadow and under edge
				var shadow = this._shadow;
				if (null == shadow) {
					shadow = this.document.createElementNS(SVGNS,"ellipse");
					this._shadow = shadow;
					group.appendChild(shadow);
				}
				shadow.setAttribute("cx",(cx + xRadius / 20)*scaleX);
				shadow.setAttribute("cy",(cy + pieHeight + yRadius / 20)*scaleY);
				shadow.setAttribute("rx",xRadius*scaleRX);
				shadow.setAttribute("ry",yRadius*scaleRY);
				shadow.setAttribute("style","stroke: none; fill: black; opacity: 0.5;");

				var edge = this._underEdge;
				if (null == edge) {
					edge = this.document.createElementNS(SVGNS,"path");
					this._underEdge = edge;
					group.appendChild(edge);
				}
				var X1 = (cx + (xRadius * 1));
				var Y1 = (cy + (yRadius * 0));
				var X2 = (cx + (xRadius * -1));
				var Y2 = (cy + (yRadius * 0));
				edge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(xRadius*scaleX)+' '+(yRadius*scaleY)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(xRadius*scaleX)+' '+(yRadius*scaleY)+' 0 0 0 '+(X1*scaleX)+' '+ ((Y1+pieHeight)*scaleY)+ ' z');
				edge.setAttribute("style","stroke: none; fill: black; opacity: 1.0;");

				var edge = this._innerUnderEdge;
				if (null == edge) {
					edge = this.document.createElementNS(SVGNS,"path");
					this._innerUnderEdge = edge;
				}
				var X1 = (cx + (xHoleRadius * -1));
				var Y1 = (cy + (yHoleRadius * 0));
				var X2 = (cx + (xHoleRadius * 1));
				var Y2 = (cy + (yHoleRadius * 0));
				edge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 0 0 '+(X1*scaleX)+' '+ ((Y1+pieHeight)*scaleY)+ ' z');
				edge.setAttribute("style","stroke: none; fill: black; opacity: 1.0;");
			}

			// slices
			for (var i = 0; i < items; i++) {
				if (null == this._slices[i]) {
					this._slices[i] = this.document.createElementNS(SVGNS,"path");
					this._slices[i]._index = i;
					group.appendChild(this._slices[i]);
				}
			}
			// edges
			if (is3D) {
				for (var i = 0; i < items; i++) {
					if (null == this._edges[i]) {
						this._edges[i] = this.document.createElementNS(SVGNS,"path");
						group.appendChild(this._edges[i]);
					}
					if (hole > 0) {
						if (null == this._innerEdges[i]) {
							this._innerEdges[i] = this.document.createElementNS(SVGNS,"path");
							group.insertBefore(this._innerEdges[i],group.firstChild);
						}
						if (i >= (items-1)) {
							group.insertBefore(this._innerUnderEdge,group.firstChild);
						}
					}
				}
			}

			// JMD1178: move label creation to main loop
		}

		// compute size of slices

		// now set the position of all slices for this series
		var value, curr;
		var last = (isNaN(parseFloat(this.rotateBy)) ? 0 : (parseFloat(this.rotateBy)/360));
		var lastcurr = 0;
		var lasty2 = 0;
		var lastx = 0;
		var lastth = 0;
		var pct = new Array();
		
		var ts = '';
		ts = ('large' == this.textSize) ? 'font-size:3pt;' : ts;
		ts = ('small' == this.textSize) ? 'font-size:1.8pt;' : ts;

		for (var i = 0; i < items; i++) {
			var clr = this.getSeriesColor(('both' != plotBy) ? i : Math.floor(i/ic));
			value = values[i];
			curr = (total == 0) ? 0 : (value / total);
			pct[i] = Math.round(curr * 100);
			var slice = this._slices[i];
			var edge = is3D ? this._edges[i] : null;
			var innerEdge = is3D ? this._innerEdges[i] : null;
			if (curr >=1) {
				// don't draw a complete circle
				curr=0.99999;
				pct[i] = 100;
			}
						
			// find series and item #s
			var sno,ino;
			switch (plotBy) {
			case 'series':
				sno = i;
				ino = 0;
				break;
			case 'items':
			default:
				sno = 0;
				ino = i;
				break;
			case 'both':
				sno = Math.floor(i/ic);
				ino = i % ic;
				break;
			}

			if (!is3D) {
				var path = "";
				if (hole <= 0) {
				 	path += "M 0 0 L "
				}
				else {
					path += "M " + ((hole * Math.cos(last * Math.PI * 2))*scaleRX) + " " + ((hole * Math.sin(last * Math.PI * 2))*scaleRY) + " L ";
				}
				path += ((sz * Math.cos(last * Math.PI * 2))*scaleRX) + " " + ((sz * Math.sin(last * Math.PI * 2))*scaleRY);
				if (curr >= 0.5) {
					path += " A" + (sz*scaleRX) + " " + (sz*scaleRY) + " 0 1 1 " + (sz * Math.cos((last + curr) * Math.PI * 2)*scaleRX) + " " + (sz * Math.sin((last + curr) * Math.PI * 2)*scaleRY);
				}
				else {
					path += " A" + (sz*scaleRX) + " " + (sz*scaleRY) + " 0 0 1 " + (sz * Math.cos((last + curr) * Math.PI * 2)*scaleRX) + " " + (sz * Math.sin((last + curr) * Math.PI * 2)*scaleRY);
				}
				if (hole <= 0) {
					path += " z";
				}
				else {
					path += "L " + (hole * Math.cos((last+curr) * Math.PI * 2)*scaleRX) + " " + (hole * Math.sin((last+curr) * Math.PI * 2)*scaleRY);
					if (curr >= 0.5) {
						path += " A" + (hole*scaleRX) + " " + (hole*scaleRY) + " 0 1 0 " + (hole * Math.cos(last * Math.PI * 2)*scaleRX) + " " + (hole * Math.sin(last * Math.PI * 2)*scaleRY);
					}
					else {
						path += " A" + (hole*scaleRX) + " " + (hole*scaleRY) + " 0 0 0 " + (hole * Math.cos(last * Math.PI * 2)*scaleRX) + " " + (hole * Math.sin(last * Math.PI * 2)*scaleRY);
					}
					path += " z";
				}
			}
			else {				
				var startAngle = (360 * last) % 360;
				var endAngle = startAngle + (curr * 360);
				// round off to avoid ie math bugs!
				startAngle = (Math.round(startAngle*1000)/1000);
				endAngle = (Math.round(endAngle*1000)/1000);

				var edgeStartAngle = (startAngle < 0) ? 0 : startAngle;
				var edgeEndAngle = endAngle;
				var innerEdgeStartAngle = (startAngle < 180) ? 180 : startAngle;
				var innerEdgeEndAngle = (endAngle > 360) ? 360 : endAngle;
				
				// JMDXXX: test if edge exists
				if (edge && value > 0 && edgeStartAngle < 180 || edgeEndAngle > 360) {
					// visible
					if (edgeStartAngle > 180 && edgeEndAngle > 360) {
						edgeStartAngle = 0;
						edgeEndAngle = edgeEndAngle % 360;
					}
					edgeEndAngle = (edgeEndAngle > 180) ? 180 : edgeEndAngle;

					var startRad = edgeStartAngle * (Math.PI / 180);
					var endRad = edgeEndAngle  * (Math.PI / 180);
					var X1 = cx + (xRadius * Math.cos(startRad));
					var Y1 = cy + (yRadius * Math.sin(startRad));
					var X2 = cx + (xRadius * Math.cos(endRad));
					var Y2 = cy + (yRadius * Math.sin(endRad));
					X1 = (Math.round(X1*1000)/1000);
					Y1 = (Math.round(Y1*1000)/1000);
					X2 = (Math.round(X2*1000)/1000);
					Y2 = (Math.round(Y2*1000)/1000);

					edge.setAttribute('visibility','visible');
					var edgeOp = 0.1 + edgeEndAngle/ 180;
					edgeOp = (edgeOp > 1) ? 1 : edgeOp;
					edge.setAttribute('opacity',edgeOp);
					if (X1!=X2||Y1!=Y2) {
						edge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(Math.round(xRadius*1000*scaleX)/1000)+' '+(Math.round(yRadius*1000*scaleY)/1000)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(Math.round(xRadius*scaleX*1000)/1000)+' '+(Math.round(yRadius*scaleY*1000)/1000)+' 0 0 0 '+(X1*scaleX)+' '+((Y1+pieHeight)*scaleY)+ ' z');
					}
					else {
						// DTB566 - Always define edge
						edge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(Math.round(xRadius*1000*scaleX)/1000)+' '+(Math.round(yRadius*1000*scaleY)/1000)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(Math.round(xRadius*scaleX*1000)/1000)+' '+(Math.round(yRadius*scaleY*1000)/1000)+' 0 0 0 '+(X1*scaleX)+' '+((Y1+pieHeight)*scaleY)+ ' z');
						edge.setAttribute('visibility','hidden');
					}
				}
				else {
					// DTB566 - Always define edge
					edge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(Math.round(xRadius*1000*scaleX)/1000)+' '+(Math.round(yRadius*1000*scaleY)/1000)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(Math.round(xRadius*scaleX*1000)/1000)+' '+(Math.round(yRadius*scaleY*1000)/1000)+' 0 0 0 '+(X1*scaleX)+' '+((Y1+pieHeight)*scaleY)+ ' z');
					edge.setAttribute('visibility','hidden');
				}
			
				// inner edge
				if (hole > 0 && innerEdge) {
					if (innerEdgeStartAngle < innerEdgeEndAngle) {
						var startRad = innerEdgeStartAngle * (Math.PI / 180);
						var endRad = innerEdgeEndAngle  * (Math.PI / 180);
						var X1 = cx + (xHoleRadius * Math.cos(startRad));
						var Y1 = cy + (yHoleRadius * Math.sin(startRad));
						var X2 = cx + (xHoleRadius * Math.cos(endRad));
						var Y2 = cy + (yHoleRadius * Math.sin(endRad));

						innerEdge.setAttribute('visibility','visible');
						innerEdge.setAttribute('opacity',0.9);
						innerEdge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 0 0 '+(X1*scaleX)+' '+((Y1+pieHeight)*scaleY)+ ' z');
					}
					else {
						// DTB566
						innerEdge.setAttribute('d','M '+(X1*scaleX)+' '+(Y1*scaleY)+' A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 0 1 '+(X2*scaleX)+' '+(Y2*scaleY)+' v '+(pieHeight*scaleY)+' ' + 'A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 0 0 '+(X1*scaleX)+' '+((Y1+pieHeight)*scaleY)+ ' z');
						innerEdge.setAttribute('visibility','hidden');
					}
				}

				// wedge
				var startRad = startAngle * (Math.PI / 180);
				var endRad = endAngle * (Math.PI / 180);
				if (hole > 0) {
					var hX1 = cx + (xHoleRadius * Math.cos(startRad));
					var hY1 = cy + (yHoleRadius * Math.sin(startRad));
					var hX2 = cx + (xHoleRadius * Math.cos(endRad));
					var hY2 = cy + (yHoleRadius * Math.sin(endRad));
					//+MES002 rounding causes points to be equal and conditions below to fail in single item case
					if (items > 1) {
						hX1 = (Math.round(hX1*1000)/1000);
						hY1 = (Math.round(hY1*1000)/1000);
						hX2 = (Math.round(hX2*1000)/1000);
						hY2 = (Math.round(hY2*1000)/1000);
					}					
					//-MES002
				}
				var X1 = cx + (xRadius * Math.cos(startRad));
				var Y1 = cy + (yRadius * Math.sin(startRad));
				var X2 = cx + (xRadius * Math.cos(endRad));
				var Y2 = cy + (yRadius * Math.sin(endRad));
				//+MES002
				if (items > 1) {
					X1 = (Math.round(X1*1000)/1000);
					Y1 = (Math.round(Y1*1000)/1000);
					X2 = (Math.round(X2*1000)/1000);
					Y2 = (Math.round(Y2*1000)/1000);
				}
				//-MES002
				
				var dir = (endAngle-startAngle > 180) ? 1 : 0;
				
				path = (hole > 0) ? 'M '+(hX1*scaleX)+' '+(hY1*scaleY) : 'M '+(cx*scaleX)+' '+(cy*scaleY);
				path += ' L '+(X1*scaleX)+' '+(Y1*scaleY)+' ';
				if (X1!=X2||Y1!=Y2) {
					path += ' A '+(xRadius*scaleX)+' '+(yRadius*scaleY)+' 0 '+dir+' 1 '+(X2*scaleX)+' '+(Y2*scaleY);
				}
				if (hole > 0) {
					if (hX1!=hX2 || hY1!=hY2) {
						path += ' L '+(hX2*scaleX)+' '+(hY2*scaleY);
						path += ' A '+(xHoleRadius*scaleX)+' '+(yHoleRadius*scaleY)+' 0 '+dir+' 0 '+(hX1*scaleX)+' '+(hY1*scaleY);
					}
				}
				path += ' z';
				
			}

			var style = this.getChartElementStyle(sno,ino);
			slice.setAttribute("d",path);
			if (!is3D) {
				slice.setAttribute("transform","translate(" + (cx*scaleX) + "," + (cy*scaleY) + ")");
			}
	
			// see if we are the selected item
			if (sno == this.selectedSeries && ino == this.selectedItem) {
				slice.setAttribute("style",style + this.selectedItemStyle);
				if (edge) {
					edge.setAttribute("style",style + this.selectedItemStyle);
				}
				if (innerEdge) {
					innerEdge.setAttribute("style",style + this.selectedItemStyle);
				}
			}
			else {
				slice.setAttribute("style",style);
				if (edge) {
 					edge.setAttribute("style",style);
				}
				if (innerEdge) {
					innerEdge.setAttribute("style",style);
				}
			}

			// mouse
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartMouseDownHandler(evt,'+slice._index+');');
			slice.addEventListener('mousedown',f,false);

			// we'll set these when a spin operation starts
			this._mmHandler = new Function('evt','return zenPage.getComponent('+this.index+').mousemoveHandler(evt);');
			this._muHandler = new Function('evt','return zenPage.getComponent('+this.index+').mouseupHandler(evt);');

			if (this.showMultiples) {
				var rsno = this.currMultiple;
			}
			else {
				var rsno = isNaN(seriesNumber) ? sno : this.seriesNumber;
			}
			rsno = (''===rsno) ? 0 : rsno;

			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+ino+');');
			slice.addEventListener('click',f,false);
			slice.setAttribute('id',this.makeId('el_' + rsno + '_' + ino));
			if (edge) {
				edge.setAttribute('id',this.makeId('edge_' + rsno + '_' + ino));
			}
			if (innerEdge) {
				innerEdge.setAttribute('id',this.makeId('inedge_' + rsno + '_' + ino));
			}

			// mouseover/out handlers
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+rsno+','+ino+');');
			slice.addEventListener('mouseover',f,false);
			if (edge) {
				edge.addEventListener('mouseover',f,false);
			}

			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+rsno+','+ino+');');
			slice.addEventListener('mouseout',f,false);
			if (edge) {
				edge.addEventListener('mouseout',f,false);
			}

			// JMD1178: create labels as needed
			// n.b. if showPercentage is on but labels are not visible, then show % only
			// same goes for showValue
			if (this.labelsVisible || this.showPercentage || this.showValue) {
				var sin = Math.sin((last + curr/2) * Math.PI * 2);
				var cos = Math.cos((last + curr/2) * Math.PI * 2);

				// n.b tx/y are in *pixels*
				var labelRadius = parseFloat(this.labelRadius);
				labelRadius = isNaN(labelRadius) ? 1.1 : labelRadius;
				var ladj = 1;
				if (is3D) {
					ladj = (sin>=0) ? 1 : 0.6;
				}
				var tx = cx*scaleX + (sz*labelRadius * cos * scaleRX);
				var ty = cy*scaleY + (sz*labelRadius * sin * scaleRY * ladj);
				var anchor = (cos>=0) ? 'start' : 'end';

				// box under label
				var box = this.document.createElementNS(SVGNS,"rect");
				box.setAttribute("class","chart-valueLabelBox");
				box.setAttribute("style",this.valueBoxStyle);

				group.appendChild(box);
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+ino+');');
				box.addEventListener('click',f,false);
					
				var text = this.document.createElementNS(SVGNS,"text");
				group.appendChild(text);

				text.setAttribute("x", tx);
				text.setAttribute("y", ty);
				text.setAttribute("class","chart-sliceLabel");
				text.setAttribute("style",this.labelStyle);
				text.setAttribute("text-anchor",anchor);
				text.addEventListener('click',f,false);

				// get label text
				var lbl = null;
				if (!this.labelsVisible) {
					lbl = '';
				}
				else {
					switch (plotBy) {
					case 'series':
						lbl = snames[i];
						lbl = (null == lbl) ? (parseInt(i,10)+1) : lbl;
						break;
					case 'items':
					default:
						lbl = this.getYLabelText(i);
						lbl = zenIsMissing(lbl) ? (parseInt(i,10)+1) : lbl;
						break;
					case 'both':
						var idx = Math.floor(i/ic);
						lbl = this.getYLabelText(i % ic);
						lbl = zenIsMissing(lbl) ? (parseInt(i%ic,10)+1) : lbl;
						break;
					}
				}

				if (this.showValue) {
					var lval = values[i];
					if (!isNaN(parseFloat(lval))) {
						var format = this.valueLabelFormat;
						format = format ? format : ((Math.floor(lval)!=lval)?'#,#.##':'#,#');
						lval = zenFormatNumber(lval,format);
						lbl += (lbl===''?'':' ') + lval;
					}
				}
				if (this.showPercentage) {
					if (lbl==='') {
						lbl += pct[i] + '%';
					}
					else {
						lbl += ' (' + pct[i] + '%)';
					}
				}

				var textNode = this.document.createTextNode(lbl);
				text.appendChild(textNode);
				// use pixels
				var th = zenGetBBox(text).height;
				var tw = zenGetBBox(text).width;
					
				box.setAttribute('rx',3);
				if (anchor=='start') {
					box.setAttribute('x',(tx)-3);
				}
				else {
					box.setAttribute('x',((tx-tw))-3);
				}
				box.setAttribute('y',(ty-(th*(1/1.1))));
				box.setAttribute('width',(tw)+6);
				box.setAttribute('height',(th*1.13));
			}

			// remember (normalized) angle of this wedge
			slice._angle = (360 * ((last + (curr/2)) - (isNaN(parseFloat(this.rotateBy)) ? 0 : (parseFloat(this.rotateBy)/360)))) % 360;
			// move to next slot
			last += curr;
			lastcurr = curr;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in pieChart.renderSeries');
	}
}

/// Determine the actual plot by method for this chart.
ClientMethod getPlotBy() [ Language = javascript ]
{
	var plotBy = this.plotBy;
	if ('auto' == plotBy) {
		var sc = this.getSeriesCount();
		var ic = this.getSeriesSize();
		if (sc > 1 && ic > 1) {
			plotBy = 'both';
		}
		else if (sc == 1 && ic == 1) {
			plotBy = 'both';
		}
		else if (sc <= 1) {
			plotBy = 'items';
		}
		else {
			plotBy = 'series';
		}
	}
	return plotBy;
}

/// Return default style for slice element.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	var clr;
	var op = '1.0';

	var plotBy = this.getPlotBy();
	if (this.showMultiples) {
		plotBy = 'items';
	}

	switch (plotBy) {
	case 'both':
		// use same color for items in series but alternate intensity.
		clr = this.getSeriesColor(series);
		op = (item%2) ? '1.0' : '0.85';
		break;
	case 'series':
		// use same color for items in series but alternate intensity.
		clr = this.getSeriesColor(series);
		break;
	case 'items':
	default:
		clr = this.getSeriesColor(item);
		break;
	}
	return "stroke-width: 0.25px; fill-opacity: "+op+"; stroke: " + 'gray' + "; fill: " + clr + ";" + this.plotStyle;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'showValue':
	case 'showPercentage':
		this[property] = value ? true : false;
		this.render();
		break;
	case 'plotBy':
		this.selectedItem = -1;
		this.selectedSeries = -1;
		this[property] = value;
		this.render();
		break;
	case 'holeSize':
	case 'pieScale':
	case 'pieHeight':
		this[property] = parseFloat(value);
		this.render();
		break;

	case 'labelRadius':
		this[property] = (value==='') ? '' : parseFloat(value);
		this.render();
		break;

	case 'rotateBy':
		value = parseFloat(value) % 360;
		value = (value < 0) ? (360 + value) : value;
		this[property] = value;
		if (this.showMultiples) {
			this.render();
		}
		else {
			this.renderSeriesGroup();
		}
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Return an array of related svg objects for a specified data element (if any).
/// (such as the edges of a 3d rendering).
ClientMethod getChartRelatedElements(series, item) [ Language = javascript ]
{
	var array = null;
	var edge = this.findSVGElement('edge_' + series + '_' + item);
	var innerEdge = this.findSVGElement('inedge_' + series + '_' + item);
	if (edge||innerEdge) {
		array = [];
		if (edge) {
			array[array.length] = edge;
		}
		if (innerEdge) {
			array[array.length] = innerEdge;
		}
	}
	return array;
}

/// Mouse down handler for a slice.
ClientMethod chartMouseDownHandler(evt, index) [ Internal, Language = javascript ]
{
	if (this._timerId) {
		// turn off tooltip
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}
	if (!this.showMultiples || this.getSeriesCount()==1) {
		this.startSpinChart(evt,index);
	}
}

/// Start of spin operation.
ClientMethod startSpinChart(evt, index) [ Internal, Language = javascript ]
{
	var slice = null;
	if (this._slices && this._slices.length) {
		var slice = this._slices[index];
	}
	if (!slice) return;

	this._inSpin = true;
	this._spinIndex = index;
	this.rotateBy = parseFloat(this.rotateBy);
	if (isNaN(parseFloat(this.rotateBy))) {
		this.rotateBy = 0;
	}
	var currZoom = 100;
	
	// remember start of operation
	this._spinX = evt.clientX;
	this._spinY = evt.clientY;
	this._startRotate = this.rotateBy;
	this._spinAngle = (slice._angle + this.rotateBy) % 360;
	this._spinAngle = (this._spinAngle < 0) ? (360 + this._spinAngle) : this._spinAngle;

	// turn on mouse handlers
	this.svgGroup.addEventListener('mousemove',this._mmHandler,false);
	this.svgGroup.addEventListener('mouseup',this._muHandler,false);
}

/// Mouse move handler for chart.
ClientMethod mousemoveHandler(evt) [ Internal, Language = javascript ]
{
	this.hideToolTip();

	var oldEvent = zenEvent;
	zenEvent = evt ? evt : window.event;
	if (this._inSpin) {
		var delta = 0;
		var dx = evt.clientX - this._spinX;
		var dy = evt.clientY - this._spinY;
		if (Math.abs(dx) > Math.abs(dy)) {
			if (this._spinAngle >= 0 && this._spinAngle <= 180) {
				delta = -dx;
			}
			else {
				delta = dx;
			}
		}
		else {
			if (this._spinAngle >= 90 && this._spinAngle <= 270) {
				delta = -dy;
			}
			else {
				delta = dy;
			}
		}
		this.rotateBy += delta;
		if (Math.abs(this.rotateBy - this._startRotate) > 3) {
			this._startRotate = this.rotateBy;
			this.setProperty('rotateBy',this.rotateBy);
		}
		this._spinX = evt.clientX;
		this._spinY = evt.clientY;
	}
	zenEvent = oldEvent;
}

/// Mouse up handler for frame.
ClientMethod mouseupHandler(evt) [ Language = javascript ]
{
	var oldEvent = zenEvent;
	zenEvent = evt ? evt : window.event;
	zenEvent = oldEvent;
	this._inSpin = false;

	// turn off mouse events
	this.svgGroup.removeEventListener('mousemove',this._mmHandler,false);
	this.svgGroup.removeEventListener('mouseup',this._muHandler,false);
}

/// Client-side method to render control.
ClientMethod renderContents() [ Language = javascript ]
{
	return this.invokeSuper('renderContents',arguments);
}

/// Indicates that this chart supports "show multiples" mode.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return this.showMultiples;
}

}
