/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.SVGComponent.percentbarChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "3D";

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
/// This includes the logic for display combo charts as it is shared with
/// its subclass.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	// create series shapes
	var x,y,val;
	var scount = this.getSeriesCount();
	var items = this.getSeriesSize();
	var is3D = this.is3D();
	var adj3D = is3D ? 3 : 0;
	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber)) {
		scount = 1;
	}

	// JMD1100
	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	// find out how many series are "bars"
	// build map of series to bar series #
	var barMap = [];
	var barSeriesCount = 0;
	for (var s = 0; s < scount; s++) {
		var plotType = this.getSeriesType(s);
		if (plotType=='bar') {
			barMap[s] = barSeriesCount;
			barSeriesCount++;
		}
	}

	// see if there is a selected element
	var hasSelect = !zenIsMissing(this.selectedSeries) && !zenIsMissing(this.selectedItem) && (this.selectedSeries >= 0) && (this.selectedItem >= 0);

	var groupEdge;
	if (is3D) {
		groupEdge = this.document.createElementNS(SVGNS,"g");
		group.appendChild(groupEdge);
	}

	var valueGroup;
	if (this.valueLabelsVisible) {
		valueGroup = this.document.createElementNS(SVGNS,"g");
		group.appendChild(valueGroup);
	}

	if (items > 0) {
		var barwid = 1;
		if (barSeriesCount > 0) {
			if (!this.chartPivot) {
				barwid = 0.8 * (this._plotWidth / scount);
			}
			else {
				barhgt = 0.8 * (this._plotHeight / scount);
			}
		}

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
		if (is3D) {
			var edgeArray = new Array(items);
			barwid = barwid * 0.75;
		}

		// track size to see if value label needs to be hidden (stacked only)
		var lastBarSize = [];
		var lastValueLabelSize = [];
		var lastValueLabel = [];

		var plotType = [];
		for (var s = 0; s < scount; s++) {
			plotType[s] = this.getSeriesType(s);
		}

		// first plot any "area" series in reverse order to get correct paint order
		for (var s = scount-1; s >=0; s--) {
			if (plotType[s]=='area') {
				var filled = true;
				var hasEvents = false;
				var hasMarkers =false;
				var stacked = false;
				this.plotLineForSeries(group,s,data,stacked,filled,hasMarkers,hasEvents);
			}
		}
		// calculate totals
		
		var total=[];
		for (q = 0; q < scount; q++) {
			total[q] = 0;
			if (plotType[q]=='bar') {
				for (var n = 0; n < items; n++) {						
					var v = (null == data[q]) ? 0 : ((null == data[q][n]) ? 0 : parseFloat(data[q][n]));
					v = isNaN(v) ? 0 : v;
					total[q] += ((v > 0) ? v : 0);
				}
			}
			
		}
		
		var x,y;
		if (!this.chartPivot) {
			x = 0;
		} else {
			y = 0;
		}

		for (var s = 0; s < scount; s++) {
			if (plotType[s]=='area') {
				continue;
			}
			else if (plotType[s]=='line') {
				var filled = false;
				var hasEvents = true;
				var hasMarkers = this.markersVisible;
				var stacked = false;
				this.plotLineForSeries(group,s,data,stacked,filled,hasMarkers,hasEvents);
				continue;
			}

			// find yAxis for this series
			var yAxisNo = this._yAxisForSeries[s];

			// create rects for each data point
			if (this.valueLabelsVisible) {
				lastBarSize[s] = 0;
				lastValueLabelSize[s] = 0;
				lastValueLabel[s] = null;
			}

			if (!this.chartPivot) {
				// normal orientation
				var dx = this._plotWidth / scount;
				var adj = (dx/2);
				var base = 0;
				var bs = barMap[s];
				var shift = -barwid/2;

				if (isNaN(parseFloat(this._yBaseValue[yAxisNo]))) {
					base = this._plotHeight;
				}
				else {
					base = this.getPlotY(this._yBaseValue[yAxisNo],yAxisNo) - this._plotTop;
				}
			}
			else {
				// pivotted
				var dy = this._plotHeight / scount;
				var adj = (dy/2);
				var base = 0;
				var bs = barMap[s];
				var shift = -barhgt/2;
	
				if (isNaN(parseFloat(this._xBaseValue))) {
					base = 0;
				}
				else {
					base = this.getPlotX(this._xBaseValue) - this._plotLeft;
				}
			}

			var valsave = 0;
			for (var n = 0; n < items; n++) {
				var color = this.getSeriesColor(n);
				val = (null == data[s]) ? 0 : ((null == data[s][n]) ? 0 : parseFloat(data[s][n]));
				val = isNaN(val) ? 0 : val;
				if (val < 0  && barSeriesCount>1) {
					// only positive values make sense for stacked bars
					val = 0;
				}
				val = 100 * val / total[s];
				var dval = 0;
				var init = 0
				dval=valsave;
					
				if (!this.chartPivot) {
					base = this.getPlotY(dval,yAxisNo) - this._plotTop;
				}
				else {
					base = this.getPlotX(dval) - this._plotLeft;
				}
				val += dval;
				valsave = val;
					
				var bar = this.document.createElementNS(SVGNS,"rect");
				bar.setAttribute("class","chart-seriesBar");
				if (is3D) {
					var edgeSide = this.document.createElementNS(SVGNS,"path");
					edgeSide.setAttribute("fill","black");
					edgeSide.setAttribute("stroke","none");

					var edgeSide2 = this.document.createElementNS(SVGNS,"path");
					edgeSide2.setAttribute("class","chart-seriesBar");
					edgeSide2.setAttribute("fill",color);
					edgeSide2.setAttribute("fill-opacity","0.5");
					edgeSide2.setAttribute("stroke","black");

					var edgeTop = this.document.createElementNS(SVGNS,"path");
					edgeTop.setAttribute("class","chart-seriesBar");
					edgeTop.setAttribute("fill",color);
					edgeTop.setAttribute("stroke","black");

					if (!this.chartPivot) {
						groupEdge.appendChild(edgeSide);
						groupEdge.appendChild(edgeSide2);
						groupEdge.appendChild(edgeTop);
					}
					else {
						groupEdge.insertBefore(edgeSide2,edgeArray[n]?edgeArray[n]:groupEdge.firstChild);
						groupEdge.insertBefore(edgeSide,edgeSide2);
						if (true) { //(s == barSeriesCount-1) {
							groupEdge.insertBefore(edgeTop,edgeSide);
							edgeArray[n] = edgeTop;
						}
						else {
							edgeArray[n] = edgeSide;
						}
					}
				}
				if (!this.chartPivot) {
					if (n==0) {
						x += dx;
					}
					y = this.getPlotY(val,yAxisNo) - this._plotTop;

					var top,hgt;
					if (y <= base) {
						top = y;
						hgt = base-y;
					}
					else {
						top = base;
						hgt = y-base;
					}
					bar.setAttribute("x",(x-adj+shift-adj3D)*scaleX);
					bar.setAttribute("y",(top+adj3D)*scaleY);
					bar.setAttribute("width",barwid*scaleX);
					bar.setAttribute("height",hgt*scaleY);

					if (is3D) {
						edgeTop.setAttribute("d",'M '+((x-adj+shift-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' L '+((x-adj+shift)*scaleX)+' '+((top)*scaleY)+' '+((x-adj+shift+barwid)*scaleX)+' '+(top*scaleY)+' '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' z');
						edgeSide.setAttribute("d",'M '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' L '+((x-adj+shift+barwid)*scaleX)+' '+(top*scaleY)+' '+((x-adj+shift+barwid)*scaleX)+' '+((top+hgt)*scaleY)+' '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D+hgt)*scaleY)+' z');
						edgeSide2.setAttribute("d",'M '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' L '+((x-adj+shift+barwid)*scaleX)+' '+(top*scaleY)+' '+((x-adj+shift+barwid)*scaleX)+' '+((top+hgt)*scaleY)+' '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D+hgt)*scaleY)+' z');
					}
				}
				else {
					if (n==0) {
						y += dy;
					}
					x = this.getPlotX(val) - this._plotLeft;

					var left,wid;
					if (x <= base) {
						left = x;
						wid = base-x;
					}
					else {
						left = base;
						wid = x-base;
					}
					bar.setAttribute("x",(left-adj3D)*scaleX);
					bar.setAttribute("y",(y-adj+shift+adj3D)*scaleY);
					bar.setAttribute("width",wid*scaleX);
					bar.setAttribute("height",barhgt*scaleY);
					if (is3D) {
						edgeTop.setAttribute("d",'M '+((left-adj3D+wid)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' L '+((left+wid)*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid)*scaleX)+' '+((y-adj+shift+barhgt)*scaleY)+' '+((left-adj3D+wid)*scaleX)+' '+((y-adj+shift+adj3D+barhgt)*scaleY)+' z');
						edgeSide.setAttribute("d",'M '+((left-adj3D)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' L '+((left)*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid)*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid-adj3D)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' z');
						edgeSide2.setAttribute("d",'M '+((left-adj3D)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' L '+(left*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid)*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid-adj3D)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' z');
					}
				}

				bar.setAttribute("fill",color);
				group.appendChild(bar);

				if (this.valueLabelsVisible) {
					/* labels on percentBarCharts should not be marked invisible in this way
					if (lastValueLabel[s] && (lastValueLabelSize[s] > lastBarSize[s])) {
						lastValueLabel[s].setAttribute("display","none");
					}
					*/
					// JMD1125 backing rect for value box
					var box = this.document.createElementNS(SVGNS,"rect");
					box.setAttribute("class","chart-valueLabelBox");
					box.setAttribute("style",this.valueBoxStyle);
					valueGroup.appendChild(box);
										
					// value label for bar
					var fSz = 10;
					var align = 'middle';
					var lval = (null == data[s]) ? '' : ((null == data[s][n] || ''===data[s][n]) ? '' : parseFloat(data[s][n]));
					var value = '';
					if (!isNaN(parseFloat(lval))) {
						var format = this.valueLabelFormat;
						format = format ? format : ((Math.floor(lval)!=lval)?'#,#.##':'#,#');
						value = zenFormatNumber(lval,format);
					}

					// JMD1191: place labels in center of bar
					// get size of current bar
					var cbx = parseFloat(bar.getAttribute("x"));
					var cby = parseFloat(bar.getAttribute("y"));
					var cbw = parseFloat(bar.getAttribute("width"));
					var cbh = parseFloat(bar.getAttribute("height"));

					// find mid-point of bar
					var cbxMid = cbx + cbw/2;
					var cbyMid = cby + cbh/2;					
					var tg = this.createSVGTextNode(value,fSz,false,align,0,valueGroup);
					var textNode = tg.firstChild;	
					textNode.setAttribute("class","chart-valueLabel");
					textNode.setAttribute("style",this.valueLabelStyle);
					// position box and text in pixels
					var bbox = zenGetBBox(textNode);
					textNode.setAttribute("text-anchor","middle");
					textNode.setAttribute("x",cbxMid);
					textNode.setAttribute("y",cbyMid + ((bbox.height/2)*0.8));

					box.setAttribute("x", cbxMid - (bbox.width/2));
					box.setAttribute("y", cbyMid - (bbox.height/2));
					box.setAttribute("rx", 3);
					box.setAttribute("width", bbox.width*1.1);
					box.setAttribute("height", bbox.height*1.2);
	
					if (this.chartPivot) {
						lastBarSize[s] = wid;
					}
					else {
						lastBarSize[s] = hgt;
					}
				}	

				// see if we are the selected item
				if (hasSelect && s == this.selectedSeries && n == this.selectedItem) {
					bar.setAttribute("style",this.plotStyle + this.selectedItemStyle);
					if (is3D) {
						edgeTop.setAttribute("style",this.plotStyle + this.selectedItemStyle);
						edgeSide2.setAttribute("style",this.plotStyle + this.selectedItemStyle);
					}
				}
				else {
					bar.setAttribute("style",this.plotStyle);
					if (is3D) {
						edgeTop.setAttribute("style",this.plotStyle);
						edgeSide2.setAttribute("style",this.plotStyle);
					}
				}
				// chartElementClickHandler
				// JMD1100 use seriesNumber, not this.seriesNumber
				var sno = isNaN(seriesNumber) ? s : seriesNumber;
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+sno+','+n+');');
				bar.addEventListener('click',f,false);
				bar.setAttribute('id',this.makeId('el_' + sno + '_' + n));

				// mouseover/out handlers
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+sno+','+n+');');
				bar.addEventListener('mouseover',f,false);

				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+sno+','+n+');');
				bar.addEventListener('mouseout',f,false);

			}
		}
	}

	if (this.valueLabelsVisible) {
		/* labels on percentBarCharts should not be marked invisible in this way
		for (var s = 0; s < barSeriesCount; s++) {
			if (lastValueLabel[s] && (lastValueLabelSize[s] > lastBarSize[s])) {
				lastValueLabel[s].setAttribute("display","none");
			}
		}
		*/
		// move group to end
		group.removeChild(valueGroup);
		group.appendChild(valueGroup);
	}
}

/// Return default style for a bar element.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	var type = this.getSeriesType(series);
	if (type=='bar') {
		return this.plotStyle;
	}
	return this.markerStyle;
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
	return true;
}

/// This method returns true if data series is from a percentage bar chart
/// when calculating data range for the chart.
ClientMethod usePercentForRange() [ Language = javascript ]
{
	return true;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'chartPivot':
	case 'chartStacked':
		this[property] = value ? true : false;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Return the type (how a series should be displayed) for the given data series (0-based).
/// Overridden in combo chart.
ClientMethod getSeriesType(series) [ Language = javascript ]
{
	return 'bar';
}

}
