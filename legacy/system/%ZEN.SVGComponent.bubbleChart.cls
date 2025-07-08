/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a bubble chart.<br/>
/// This chart expects at least 2 data series, the first supplying x values and the second
/// supplying y values.<br/>
/// Additional series are interpreted as:<br/>
/// Series 2: radius (radius of each bubble).<br/>
/// Series 3: colors (items are grouped into buckets by value).<br/>
/// Series 4: opacity (opacity of items from 0 to 1 -- values are not normalized).<br/>
Class %ZEN.SVGComponent.bubbleChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Default value for the markersVisible property.
Parameter DEFAULTMARKERSVISIBLE = 0;

/// Default radius (in logical units) for bubbles. If there is a radius series, its
/// values are scaled and multiplied by this value.
Property radius As %ZEN.Datatype.float [ InitialExpression = 3 ];

/// Default opacity (from 0 to 1) for bubbles.  If there is a opacity series, its
/// values are scaled and multiplied by this value.
Property opacity As %ZEN.Datatype.float [ InitialExpression = 0.75 ];

/// Center value along x-axis. Used to draw background "quadrants".
Property xCenterValue As %ZEN.Datatype.float;

/// Center value along y-axis. Used to draw background "quadrants".
Property yCenterValue As %ZEN.Datatype.float;

/// If true, then draw background "quadrants".
Property showQuadrant As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, then draw a computed linear regression line.
Property showRegression As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property tag As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "bubbleChart", Internal ];

/// Optional: style applied to the upper right quadrant background.
Property upperRightStyle As %ZEN.Datatype.svgStyle;

/// Optional: style applied to the lower left quadrant background.
Property lowerLeftStyle As %ZEN.Datatype.svgStyle;

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

	if (scount >= 2) {
		// loop over series to compute x & y range
		for (var s = 0; s < 2; s++) {
			var data = this._dataSeries[s];
			var which = s==0?'x':'y';
			if (data) {
				for (var n = 0; n < items; n++) {
					var val = data[n];
					if (!isNaN(val)) {
						val = parseFloat(val);
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
	}
	return range;
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,xval,yval,rval,cval,opval;
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();
	var defRadius = parseFloat(this.radius);

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;
	var scaleR = (scaleX>scaleY) ? scaleY : scaleX;

	this._hist = null;
	this._valueLabels = [];

	if (items > 0) {
		var xData = this.getSeriesData(0);
		var yData = this.getSeriesData(1);
		var rData = this.getSeriesData(2);
		var cData = this.getSeriesData(3);
		var opData = this.getSeriesData(4);
		var cDataIndex = {};

		// find histogram of items in cData
		// sort cItems into buckets
		this._hist = {};
		if (cData) {
			for (var n = 0; n < items; n++) {
				cval = ((null === cData[n]) ? '' : cData[n]);
				if (cval !== '') {
					this._hist[cval] = n;
				}
			}
			for (var n in this._hist) {
				this._valueLabels[this._valueLabels.length] = n;
			}
			this._valueLabels.sort();
			for (var n = 0; n <  this._valueLabels.length; n++) {
				cDataIndex[this._valueLabels[n]] = n;
			}
		}
		else {
			this._valueLabels[0] = 'Value';
		}

		var rMinValue = null;
		var rMaxValue = null;

		// find range of radius values
		if (rData) {
			for (var n = 0; n < items; n++) {
				var val = rData[n];
				if (!isNaN(val)) {
					val = parseFloat(val);
					rMinValue = (null==rMinValue) ? val : (val < rMinValue) ? val : rMinValue;
					rMaxValue = (null==rMaxValue) ? val : (val > rMaxValue) ? val : rMaxValue;
				}
			}
		}

		var opMinValue = null;
		var opMaxValue = null;

		// find range of opacity values
		if (opData) {
			for (var n = 0; n < items; n++) {
				var val = opData[n];
				if (!isNaN(val)) {
					val = parseFloat(val);
					opMinValue = (null==opMinValue) ? val : (val < opMinValue) ? val : opMinValue;
					opMaxValue = (null==opMaxValue) ? val : (val > opMaxValue) ? val : opMaxValue;
				}
			}
		}

		// sort items by radius; plot smaller items last
		// also find mean for x and y
		var sortedList = [];
		var itemCount = 0;
		var xTotal = 0;
		var yTotal = 0;
		for (var n = 0; n < items; n++) {
			// compute radii for items
			rval = (null == rData) ? 0 : ((null == rData[n]) ? 0 : rData[n]);
			if (rMinValue == null || rMaxValue == null) {
				var r = defRadius;
			}
			else {
				var rRange = rMaxValue - rMinValue;
				var r = (rRange==0) ? defRadius : ((rval / rRange) * defRadius)+0.2;
			}

			// compute opacity for items
			opval = (null == opData) ? 0 : ((null == opData[n]) ? 0 : opData[n]);
			if (opMinValue == null || opMaxValue == null) {
				var op = this.opacity;
			}
			else {
				var opRange = opMaxValue - opMinValue;
				var op = (opRange==0) ? this.opacity : ((opval / opRange) * this.opacity);
			}

			xval = (null == xData) ? '' : ((null == xData[n]) ? '' : xData[n]);
			yval = (null == yData) ? '' : ((null == yData[n]) ? '' : yData[n]);
			if (xval!=='' && yval!=='') {
				itemCount++;
				xTotal += parseFloat(xval);
				yTotal += parseFloat(yval);
			}
			sortedList[n] = {index:n, r:r,x:xval,y:yval,op:op};
		}

		var xMean = (itemCount>0) ? xTotal / itemCount : 0;
		var yMean = (itemCount>0) ? yTotal / itemCount : 0;

		// sort by radius
		var sortFunc = new Function('a','b','return b.r-a.r;');
		sortedList.sort(sortFunc);

		// plot data
		// compute regression as we go
		var sumX = 0;
		var sumXX = 0;
		var sumY = 0;
		var sumYY = 0;
		var sumXY = 0;
		var sumXM2 = 0;
		var sumYM2 = 0;

		for (var n = 0; n < items; n++) {
			var idx = sortedList[n].index;
			var r = sortedList[n].r;
			var opacity = sortedList[n].op;
			xval = sortedList[n].x;
			yval = sortedList[n].y;
			
			if (xval==='' || yval==='') {
				continue;
			}

			cval = (null == cData) ? '' : ((null == cData[idx]) ? '' : cData[idx]);

			if (this.showRegression && !isNaN(parseFloat(xval)) && !isNaN(parseFloat(yval))) {
				sumX += parseFloat(xval);
				sumY += parseFloat(yval);
				sumXX += parseFloat(xval*xval);
				sumYY += parseFloat(yval*yval);
				sumXY += parseFloat(xval*yval);
				sumXM2 += (parseFloat(xval) - xMean)*(parseFloat(xval) - xMean);
				sumYM2 += (parseFloat(yval) - yMean)*(parseFloat(yval) - yMean);
			}

			x = this.getPlotX(xval) - this._plotLeft;
			y = this.getPlotY(yval,this.currYAxis) - this._plotTop;

			cval = (cval===''||!cDataIndex[cval])?0:cDataIndex[cval];
			var color = this.getSeriesColor(cval);

			var bubble = this.document.createElementNS(SVGNS,"circle");
			bubble.setAttribute("class","chart-seriesBar");
			bubble.setAttribute("cx",x*scaleX);
			bubble.setAttribute("cy",y*scaleY);
			bubble.setAttribute("r",r*scaleR);
			bubble.setAttribute("opacity",opacity);
			bubble.setAttribute("fill",color);
			bubble.setAttribute("stroke",'#404040');
			bubble.setAttribute("stroke-width",'0.01');
			group.appendChild(bubble);

			if (idx == this.selectedItem) {
				bubble.setAttribute("style",this.plotStyle + this.selectedItemStyle);
			}
			else {
				bubble.setAttribute("style",this.plotStyle);
			}

			// mouseover/out handlers
			var sno = 0;
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+sno+','+idx+');');
			bubble.addEventListener('click',f,false);
			bubble.setAttribute('id',this.makeId('el_' + sno + '_' + idx));

			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+sno+','+idx+');');
			bubble.addEventListener('mouseover',f,false);

			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+sno+','+idx+');');
			bubble.addEventListener('mouseout',f,false);
		}
	}

	var xMin = this._xMaxValue;
	var xMax = this._xMinValue;

	if (this.showRegression && xMin!==null && xMax!==null && itemCount > 0) {
		// stats
		var N = itemCount;

		// pearson's correlation
		var pr = (sumXY - ((sumX*sumY)/N)) / Math.sqrt(((sumXX - (sumX*sumX)/N)*(sumYY - (sumY*sumY)/N)));

		// stddev
		var stdX = Math.sqrt(sumXM2/N);
		var stdY = Math.sqrt(sumYM2/N);

		// slope and y-intercept
		var b = pr * (stdY/stdX);
		var A = yMean - (b * xMean);

		var yval1 = A + (b*xMin);
		var yval2 = A + (b*xMax);

		var y1 = this.getPlotY(yval1,this.currYAxis) - this._plotTop;
		var y2 = this.getPlotY(yval2,this.currYAxis) - this._plotTop;

		var x1 = this.getPlotX(xMin) - this._plotLeft;
		var x2 = this.getPlotX(xMax) - this._plotLeft;

		var line = this.document.createElementNS(SVGNS,"line");
		line.setAttribute("class","chart-seriesLine");
		line.setAttribute("style",this.lineStyle);
		line.setAttribute("x1",x1*scaleX);
		line.setAttribute("y1",y1*scaleY);
		line.setAttribute("x2",x2*scaleX);
		line.setAttribute("y2",y2*scaleY);
		line.setAttribute("stroke",'#8080F0');
		group.appendChild(line);
	}
}

/// Return an array of labels to display within the Legend box.<br>
/// For xy chart we have to skip the first series, as it contains
/// x-values, and not a logical data series.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	var legends = [];
	var names = this.getSeriesNames();
	var items = this.getSeriesSize();

	// compute labels
	var cData = this.getSeriesData(3);
	var cDataIndex = {};

	// find histogram of items in cData
	// sort cItems into buckets
	this._hist = {};
	if (cData) {
		for (var n = 0; n < items; n++) {
			cval = ((null === cData[n]) ? '' : cData[n]);
			if (cval !== '') {
				this._hist[cval] = n;
			}
		}
		for (var n in this._hist) {
			legends[legends.length] = n;
		}
		legends.sort();
		for (var n = 0; n < legends.length; n++) {
			cDataIndex[legends[n]] = n;
		}
	}
	else {
		legends[0] = names[0];
	}
	return legends;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'radius':
	case 'opacity':
	case 'xCenterValue':
	case 'yCenterValue':
		this[property] = (value=='') ? '' : parseFloat(value);
		this.render();
		break;
	case 'showRegression':
	case 'showQuadrant':
		this[property] = value ? true : false;
		this.render();
		break;

	case 'upperRightStyle':
	case 'lowerLeftStyle':
		this[property] = value;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Draw the upper/lower bands for the chart.
/// Override standard "bands" and replace with "quadrant" boxes.
ClientMethod renderBands() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;

	var text;
	var plotAreaGroup = this.findSVGElement('plotAreaGroup');
	var virtualGroup = this.findSVGElement('virtualGroup');
	zenASSERT(plotAreaGroup,'Unable to find plotAreaGroup',arguments);

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	// create quadrants
	var qUR = this.findSVGElement('qUR');
	var qLL = this.findSVGElement('qLL');

	if (null == qUR) {
		qUR = this.document.createElementNS(SVGNS,"rect");
		qUR.setAttribute('id',this.makeId('qUR'));
		virtualGroup.appendChild(qUR);
	}
	if (null == qLL) {
		qLL = this.document.createElementNS(SVGNS,"rect");
		qLL.setAttribute('id',this.makeId('qLL'));
		virtualGroup.appendChild(qLL);
	}

	var xMidPoint = this.xCenterValue;
	var yMidPoint = this.yCenterValue;

	var hideUR = !this.showQuadrant;
	var hideLL = !this.showQuadrant;
	if (isNaN(parseFloat(xMidPoint))) {
		xMidPoint = (this._xRange/2) + this._xMinValue
	}
	if (isNaN(parseFloat(yMidPoint))) {
		yMidPoint = (this._yRange[0]/2) + this._yMinValue[0]
	}
	var h = this.getPlotY(yMidPoint,this.currYAxis) - this._plotTop;
	var w = this.getPlotX(xMidPoint) - this._plotLeft;

	// JMD1181: hide quadrants independently
	h = (h > this._plotHeight) ? this._plotHeight : h; 
	w = (w > this._plotWidth) ? this._plotWidth : w; 

	if ((h<0)||(this._plotWidth-w)<0) {
		hideUR = true;
	}
	else {
		qUR.setAttribute("class","chart-band");
		qUR.setAttribute("x",w*scaleX);
		qUR.setAttribute("y",this._plotTop*scaleY);
		qUR.setAttribute("width",(this._plotWidth - w)*scaleX);
		qUR.setAttribute("height",h*scaleY);
		qUR.setAttribute("style",'opacity:0.15;fill:#80D080;'+this.upperRightStyle);
	}

	if ((w<0)||(this._plotHeight-h)<0) {
		hideLL = true;
	}
	else {
		var y = this._plotTop + h;
		if (h<0) { // JSL4359
			y = this._plotTop;
			h = 0;
		}
		qLL.setAttribute("class","chart-band");
		qLL.setAttribute("x",0);
		qLL.setAttribute("y",(y)*scaleY);
		qLL.setAttribute("width",w*scaleX);
		qLL.setAttribute("height",(this._plotHeight - h)*scaleY);
		//alert("y="+y+" height="+h+" _plotTop="+this._plotTop)
		qLL.setAttribute("style",'opacity:0.15;fill:#D08080;'+this.lowerLeftStyle);
	}

	if (hideUR) {
 		qUR.setAttribute("display","none");
	}
	else {
 		qUR.setAttribute("display","block");
	}
	if (hideLL) {
 		qLL.setAttribute("display","none");
	}
	else {
 		qLL.setAttribute("display","block");
	}
}

/// Override and use seriesNames only.
ClientMethod getSeriesNames() [ Language = javascript ]
{
	var names = [];
	var sn = this.seriesNames.split(',');
	for (i = 0; i < sn.length; i++) {
		names[i] = (null == sn[i] || '' == sn[i]) ? (parseInt(i,10)+1) : sn[i];
	}
	return names;
}

/// Return the x axis title.
ClientMethod getXAxisTitle() [ Language = javascript ]
{
	var title = '';
	if (this.xAxis && ''!=this.xAxis.title) {
		title = this.xAxis.title;
	}
	else {
		var controller = this.getController();
		if (controller) {
			title = controller.getLabel(0,2);
		}
		else {
			title = 'x';
		}
	}
	return title;
}

/// Return the y axis title.
ClientMethod getYAxisTitle() [ Language = javascript ]
{
	var title = '';
	var yAxis = this.getYAxis(this.currYAxis);
	if (yAxis && ''!=yAxis.title) {
		title = yAxis.title;
	}
	else {
		var controller = this.getController();
		if (controller) {
			title = controller.getLabel(1,2);
		}
		else {
			title = 'y';
		}
	}
	return title;
}

/// Return an object containing tooltip information for the given element.
ClientMethod getToolTipInfo(series, item, captions, values) [ Internal, Language = javascript ]
{
	var controller = this.getController();

	var xData = this.getSeriesData(0);
	var yData = this.getSeriesData(1);
	var rData = this.getSeriesData(2);

	if (controller && controller.getDimName) {
		var name = controller.getDimName(0);
		if (''!==name) {
			captions[captions.length] = name;
			values[values.length] = controller.getLabel(item,1);
		}
	}

	if (xData) {
		captions[captions.length] = this.getXAxisTitle();
		values[values.length] = xData[item];
	}
	if (yData) {
		captions[captions.length] = this.getYAxisTitle();
		values[values.length] = yData[item];
	}
	var controller = this.getController();
	if (rData) {
		if (controller) {
			captions[captions.length] = controller.getLabel(2,2);
			values[values.length] = rData[item];
		}
	}
	// are there more series?
	var scount = this.getSeriesCount();
	for (var s = 3; s < scount; s++) {
		if (controller) {
			var sData = this.getSeriesData(s);
			captions[captions.length] = controller.getLabel(s,2);
			values[values.length] = sData[item];
		}
	}
}

}
