/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a bar chart.<br>
/// This chart displays one or more data series as rectangular bars whose
/// size is proportional to the data value.<br>
/// If there are multiple data series, the bars are plotted either side-by-side
/// or stacked, as specified by the <property>chartStacked</property> property.<br>
/// You can view data as a set of horizontal columns by setting the <property>chartPivot</property> property.<br>
/// Note: the <property>plotToEdge</property> property is always
/// treated as false for bar charts.
Class %ZEN.SVGComponent.barChart Extends chart [ Deprecated, System = 3 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "2D";

/// If true, this is a <i>stacked</i> bar chart. That is,
/// data series are plotted on top of one another.<br>
/// If false, then data series are plotted side-by-side.<br>
Property chartStacked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

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

	// JMD1208
	var multipleOffset = (this.currMultiple?this.currMultiple:0);

	// limit series if we are in small multiples mode
	if (this.showMultiples) {
		seriesNumber = this.currMultiple;
		scount = 1;
	}

	// find out how many series are "bars"
	// build map of series to bar series #
	var barMap = [];
	var barSeriesCount = 0;
	for (var s = 0; s < scount; s++) {
		var plotType = this.getSeriesType(s+multipleOffset);
		if (plotType=='bar') {
			barMap[s] = barSeriesCount;
			barSeriesCount++;
		}
	}

	// JMD: take yaxis # into account for stacked bars
	var yaList = this._yAxisForSeries;

	// see if there is a selected element
	var hasSelect = !zenIsMissing(this.selectedSeries) && !zenIsMissing(this.selectedItem) && (this.selectedSeries >= 0) && (this.selectedItem >= 0);
	var barwid, barhgt;

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
				if (this.chartStacked) {
					barwid = 0.8 * (this._plotWidth / items);
				}
				else {
					barwid = (0.8/barSeriesCount) * (this._plotWidth / items);
				}
			}
			else {
				if (this.chartStacked) {
					barhgt = 0.8 * (this._plotHeight / items);
				}
				else {
					barhgt = (0.8/barSeriesCount) * (this._plotHeight / items);
				}
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

		var plotType = [];
		for (var s = 0; s < scount; s++) {
			plotType[s] = this.getSeriesType(s+multipleOffset);
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

		for (var s = 0; s < scount; s++) {
			if ((plotType[s]!='bar')) {
				continue;
			}

			var color = this.getSeriesColor(s+multipleOffset);

			// find yAxis for this series
			var yAxisNo = this._yAxisForSeries[s+multipleOffset];

			// create rects for each data point
			if (!this.chartPivot) {
				// normal orientation
				var dx = this._plotWidth / items;
				var adj = (dx/2);
				var x = 0;
				var base = 0;
				var bs = barMap[s];
				var shift = this.chartStacked ? -barwid/2 : ((bs * barwid) - (barSeriesCount*barwid)/2);

				if (isNaN(parseFloat(this._yBaseValue[yAxisNo]))) {
					base = this._plotHeight;
				}
				else {
					base = this.getPlotY(this._yBaseValue[yAxisNo],yAxisNo) - this._plotTop;
				}
			}
			else {
				// pivotted
				var dy = this._plotHeight / items;
				var adj = (dy/2);
				var y = 0;
				var base = 0;
				var bs = barMap[s];
				var shift = this.chartStacked ? -barhgt/2 : ((bs * barhgt) - (barSeriesCount*barhgt)/2);

				if (isNaN(parseFloat(this._xBaseValue))) {
					base = 0;
				}
				else {
					base = this.getPlotX(this._xBaseValue) - this._plotLeft;
				}
			}

			// loop over items in series
			for (var n = 0; n < items; n++) {
				val = (null == data[s]) ? 0 : ((null == data[s][n]) ? 0 : parseFloat(data[s][n]));
				val = isNaN(val) ? 0 : val;
				/* JMD1125 plot negative bars below the line!
				if (this.chartStacked && val < 0  && barSeriesCount>1) {
					// only positive values make sense for stacked bars
					val = 0;
				}
				*/
				var isNeg = (val<0);

				if (this.chartStacked && s > 0) {
					var dval = 0;
					for (q = 0; q < s; q++) {
						if (plotType[q]=='bar' && (yaList[q]==yAxisNo)) {
							var v = (null == data[q]) ? 0 : ((null == data[q][n]) ? 0 : parseFloat(data[q][n]));
							v = isNaN(v) ? 0 : v;
							if ((isNeg && v < 0)||(!isNeg && v > 0)) {
								dval += v;
							}
						}
					}
					if (!this.chartPivot) {
						base = this.getPlotY(dval,yAxisNo) - this._plotTop;
					}
					else {
						base = this.getPlotX(dval) - this._plotLeft;
					}
					val += dval;
				}

				var bar = this.document.createElementNS(SVGNS,"rect");
				bar.setAttribute("class","chart-seriesBar");
				if (is3D) {
					var edgeSide = this.document.createElementNS(SVGNS,"path");
					edgeSide.setAttribute("fill","#404040");
					edgeSide.setAttribute("stroke","none");

					var edgeSide2 = this.document.createElementNS(SVGNS,"path");
					edgeSide2.setAttribute("class","chart-seriesBar");
					edgeSide2.setAttribute("fill",color);
					edgeSide2.setAttribute("fill-opacity","0.5");
					edgeSide2.setAttribute("stroke","#404040");

					var edgeTop = this.document.createElementNS(SVGNS,"path");
					edgeTop.setAttribute("class","chart-seriesBar");
					edgeTop.setAttribute("fill",color);
					edgeTop.setAttribute("stroke","#404040");

					if (!this.chartPivot) {
						if (!this.chartStacked) {
							var node = null;
							if (s>0) {
								node = edgeArray[n+1];
							}
							if (null == node) {
								groupEdge.appendChild(edgeSide);
								groupEdge.appendChild(edgeSide2);
								groupEdge.appendChild(edgeTop);
							}
							else {
								groupEdge.insertBefore(edgeSide2,node);
								groupEdge.insertBefore(edgeSide,edgeSide2);
								groupEdge.insertBefore(edgeTop,edgeSide);
							}
							if (0 == s) {
								edgeArray[n] = edgeTop;
							}
						}
						else {
							groupEdge.appendChild(edgeSide);
							groupEdge.appendChild(edgeSide2);
							groupEdge.appendChild(edgeTop);
						}
					}
					else {
						if (!this.chartStacked) {
							groupEdge.insertBefore(edgeSide2,edgeArray[n]?edgeArray[n]:groupEdge.firstChild);
							groupEdge.insertBefore(edgeSide,edgeSide2);
							groupEdge.insertBefore(edgeTop,edgeSide);
							edgeArray[n] = edgeTop;
						}
						else {
							groupEdge.insertBefore(edgeSide2,edgeArray[n]?edgeArray[n]:groupEdge.firstChild);
							groupEdge.insertBefore(edgeSide,edgeSide2);
							if (s == barSeriesCount-1) {
								groupEdge.insertBefore(edgeTop,edgeSide);
								edgeArray[n] = edgeTop;
							}
							else {
								edgeArray[n] = edgeSide;
							}
						}
					}
				}

				if (!this.chartPivot) {
					x += dx;
					y = this.getPlotY(val,yAxisNo) - this._plotTop;
					// JMD1100
					if (this.isTimeBased()) {
						var time = this.getXLabelText(n);
						x = this.getTimeX(time);
						x = x===null ? 0 : x;
					}

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
						edgeTop.setAttribute("d",'M '+((x-adj+shift-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' L '+((x-adj+shift)*scaleX)+' '+((top)*scaleY)+' '+((x-adj+shift+barwid)*scaleX)+' '+((top)*scaleY)+' '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' z');
						edgeSide.setAttribute("d",'M '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' L '+((x-adj+shift+barwid)*scaleX)+' '+((top)*scaleY)+' '+((x-adj+shift+barwid)*scaleX)+' '+((top+hgt)*scaleY)+' '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D+hgt)*scaleY)+' z');
						edgeSide2.setAttribute("d",'M '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D)*scaleY)+' L '+((x-adj+shift+barwid)*scaleX)+' '+((top)*scaleY)+' '+((x-adj+shift+barwid)*scaleX)+' '+((top+hgt)*scaleY)+' '+((x-adj+shift+barwid-adj3D)*scaleX)+' '+((top+adj3D+hgt)*scaleY)+' z');
					}
				}
				else {
					y += dy;
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
						edgeSide2.setAttribute("d",'M '+((left-adj3D)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' L '+((left)*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid)*scaleX)+' '+((y-adj+shift)*scaleY)+' '+((left+wid-adj3D)*scaleX)+' '+((y-adj+shift+adj3D)*scaleY)+' z');
					}
				}

				bar.setAttribute("fill",color);
				group.appendChild(bar);

				if (this.valueLabelsVisible) {
					// value label for bar
					var fSz = 10;
					var align = 'middle';
					var lval = (null == data[s]) ? '' : ((null == data[s][n] || ''===data[s][n]) ? '' : parseFloat(data[s][n]));
					// JMD959
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

					// JMD1125 backing rect for value box
					var box = this.document.createElementNS(SVGNS,"rect");
					box.setAttribute("class","chart-valueLabelBox");
					box.setAttribute("style",this.valueBoxStyle);
					valueGroup.appendChild(box);

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

		// JMD1100 (2) target bars and lines go last
		for (var s = 0; s < scount; s++) {
			if (plotType[s]=='target') {
				this.plotTargetForSeries(group,s,data);
			}
			else if (plotType[s]=='line') {
				var filled = false;
				var hasEvents = true;
				var hasMarkers = this.markersVisible;
				var stacked = false;
				this.plotLineForSeries(group,s,data,stacked,filled,hasMarkers,hasEvents);
			}
		}
	}

	if (this.valueLabelsVisible) {
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
	return this.chartStacked;
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

/// Indicates that this chart supports "show multiples" mode.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return this.showMultiples;
}

/// Plot a set of target lines based on the given data series.
ClientMethod plotTargetForSeries(group, sno, data) [ Language = javascript ]
{
	var items = this.getSeriesSize();
	var is3D = this.is3D();
	var adj3D = is3D ? 3 : 0;

	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	var barwid, barhgt;

	if (items > 0) {
		if (!this.chartPivot) {
			barwid = 0.9 * (this._plotWidth / items);
		}
		else {
			barhgt = 0.9 * (this._plotHeight / items);
		}

		var color = this.getSeriesColor(sno);

		// find yAxis for this series
		var yAxisNo = this._yAxisForSeries[sno];

		if (!this.chartPivot) {
			// normal orientation
			var dx = this._plotWidth / items;
			var adj = (dx/2);
			var x = 0;
			var base = 0;
			var shift = -(barwid)/2;

			if (isNaN(parseFloat(this._yBaseValue[yAxisNo]))) {
				base = this._plotHeight;
			}
			else {
				base = this.getPlotY(this._yBaseValue[yAxisNo],yAxisNo) - this._plotTop;
			}
		}
		else {
			// pivotted
			var dy = this._plotHeight / items;
			var adj = (dy/2);
			var y = 0;
			var base = 0;
			var shift = -(barhgt)/2;

			if (isNaN(parseFloat(this._xBaseValue))) {
				base = 0;
			}
			else {
				base = this.getPlotX(this._xBaseValue) - this._plotLeft;
			}
		}

		// loop over items in series
		for (var n = 0; n < items; n++) {
			val = (null == data[sno]) ? 0 : ((null == data[sno][n]) ? 0 : parseFloat(data[sno][n]));
			val = isNaN(val) ? 0 : val;

			var bar = this.document.createElementNS(SVGNS,"rect");
			bar.setAttribute("class","chart-seriesTarget");

			if (!this.chartPivot) {
				x += dx;
				y = this.getPlotY(val,yAxisNo) - this._plotTop;

				if (this.isTimeBased()) {
					var time = this.getXLabelText(n);
					x = this.getTimeX(time);
					x = x===null ? 0 : x;
				}

				var top,hgt;
				if (y <= base) {
					top = y;
				}
				else {
					top = base;
				}
				
				// 3 pixels
				hgt = 3/scaleY;
				
				bar.setAttribute("x",Math.round((x-adj+shift-adj3D)*scaleX)+0.5);
				bar.setAttribute("y",Math.round((top+adj3D)*scaleY)+0.5);
				bar.setAttribute("width",Math.round(barwid*scaleX));
				bar.setAttribute("height",Math.round(hgt*scaleY));
			}
			else {
				y += dy;
				x = this.getPlotX(val) - this._plotLeft;

				var left,wid;
				if (x < base) {
					left = base-x;
				}
				else {
					left = x-base;
				}
				// 3 pixels
				wid = 3/scaleX;

				bar.setAttribute("x",Math.round((left-adj3D)*scaleX)+0.5);
				bar.setAttribute("y",Math.round((y-adj+shift+adj3D)*scaleY)+0.5);
				bar.setAttribute("width",Math.round(wid*scaleX));
				bar.setAttribute("height",Math.round(barhgt*scaleY));
			}

			bar.setAttribute("fill",color);
			group.appendChild(bar);

			// no selection for targets
			// no click handler for targets

			// mouseover/out handlers
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+sno+','+n+');');
			bar.addEventListener('mouseover',f,false);

			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+sno+','+n+');');
			bar.addEventListener('mouseout',f,false);
		}
	}
}

}
