/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a "bullseye" chart.<br>
/// A bullseye chart displays a series of values as a set of concentric circles. The area of 
/// each circle is proportional to its value. Negative values are ignored. 
/// Values are plotted in decreasing order. The size of the outer circle is fixed and
/// represents the largest value.
Class %ZEN.SVGComponent.bullseyeChart Extends chart [ Deprecated, System = 3 ]
{

/// Scaling factor used to compute size of the main circle within the chart.<br/>
/// The default scaling value is 1.0. A value larger than 1.0 makes the circle
/// bigger relative to the chart's plot area; a value smaller than 1.0 makes the
/// circle smaller.
Property pieScale As %ZEN.Datatype.float [ InitialExpression = 1.0 ];

/// Indicates if the labels should include a value, and if so, which value to display.
Property labelValue As %ZEN.Datatype.string(VALUELIST = ",none,value,pctOfTotal,pctOfMax") [ InitialExpression = "pctOfMax" ];

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
		var snames = null;

		var seriesNumber = parseInt(this.seriesNumber);
		if (!isNaN(seriesNumber)) {
			sc = 1;
		}

		// limit series if we are in small multiples mode
		if (this.showMultiples) {
			seriesNumber = this.currMultiple;
			sc = 1;
		}

		if (this.showMultiples) {
			var rsno = this.currMultiple;
		}
		else {
			var rsno = isNaN(seriesNumber) ? 0 : this.seriesNumber;
		}
		rsno = (''===rsno) ? 0 : rsno;

		// get array of data items
		var dataItems = [];
		var total = 0;
		var maxValue = 0;
		items = ic;
		for (var i = 0; i < ic; i++) {
			var value = 0;
			// sum data across series!
			for (var s = 0; s < sc; s++) {
				var data = this._dataSeries[isNaN(seriesNumber)?s:seriesNumber];
				value += (data == null || data[i] == null || data[i] < 0 || isNaN(parseFloat(data[i]))) ? 0 : (parseFloat(data[i]));
			}
			dataItems[i] = {value:value, itemNo:i, label:this.getYLabelText(i,'',1)};
			total += value;
			if (value > maxValue) {
				maxValue = value;
			}
		}

		// reverse sort items
		dataItems.sort(function(a,b) { return parseFloat(b.value) - parseFloat(a.value) });

		// remove SVG elements within our group.
		while(null != group.firstChild) {
			group.removeChild(group.firstChild);
		}

		// plot items
		var scaleX = this._scaleX ? this._scaleX : 1;
		var scaleY = this._scaleY ? this._scaleY : 1;
		if (scaleX > scaleY) {
			var scaleR = scaleY;
		}
		else {
			var scaleR = scaleX;
		}

		// find size of main circle (ignore margins)
		var gw = (this._plotWidth * 0.80);
		var gh = (this._plotHeight * 0.80);

		var sz = (gw > gh) ? gh/2 : gw/2;
		var cx = this._plotWidth / 2;
		var cy = this._plotHeight / 2;
		sz = sz * parseFloat(this.pieScale);

		// circles
		// JMD1448
		//var cx = 50;
		//var cy = 50;

		var tx = 5;
		var ty = 5;
		for (var n = 0; n < dataItems.length; n++) {
			var value = dataItems[n].value;
			var itemNo = dataItems[n].itemNo;
			var label = dataItems[n].label;
			var style = this.getChartElementStyle(seriesNumber,itemNo);
			if (value && maxValue) {
				var r = Math.sqrt(sz*sz*(value/maxValue));
				dataItems[n].r = r;
				var circ = this.document.createElementNS(SVGNS,"circle");
				group.appendChild(circ);
				circ.setAttribute("cx",cx*scaleX);
				circ.setAttribute("cy",cy*scaleY);
				circ.setAttribute("r",r*scaleR);
				circ.setAttribute("class","");
				circ.setAttribute("style",style);

				// mouse
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+itemNo+');');
				circ.addEventListener('click',f,false);
				circ.setAttribute('id',this.makeId('el_' + rsno + '_' + itemNo));
				
				// JSL4132 - add more mouse functions so tooltip works
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+rsno+','+itemNo+');');
				circ.addEventListener('mouseover',f,false);

				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+rsno+','+itemNo+');');
				circ.addEventListener('mouseout',f,false);
				
			}
		}

		// labels
		if (this.labelsVisible) {
			var tx = 2;
			var ty = (dataItems.length > 5) ? 10 : 20;
			for (var n = 0; n < dataItems.length; n++) {
				var value = dataItems[n].value;
				var itemNo = dataItems[n].itemNo;
				var label = dataItems[n].label;
				var r = dataItems[n].r;
				if (value && maxValue) {

					// label & line
					if (label!=='') {
						// outline box under label (used to indicate selected item)
						var box2 = this.document.createElementNS(SVGNS,"rect");
						box2.setAttribute("class","chart-labelBox");
						box2.setAttribute('id',this.makeId('box_' + rsno + '_' + itemNo));
						group.appendChild(box2);

						// box under label
						var box = this.document.createElementNS(SVGNS,"rect");
						box.setAttribute("class","chart-labelBox");
						box.setAttribute("style","fill-opacity:0.8;");

						group.appendChild(box);
						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+itemNo+');');
						box.addEventListener('click',f,false);
		
						// JSL4132 - add more mouse functions so tooltip works
						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+rsno+','+itemNo+');');
						box.addEventListener('mouseover',f,false);

						var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+rsno+','+itemNo+');');
						box.addEventListener('mouseout',f,false);
						
						var text = this.document.createElementNS(SVGNS,"text");
						group.appendChild(text);

						text.setAttribute("x", tx*scaleX);
						text.setAttribute("y", ty*scaleY);
						text.setAttribute("class","chart-sliceLabel");
						text.setAttribute("style",this.labelStyle);
						text.addEventListener('click',f,false);

						var t = label;
						switch (this.labelValue) {
						case 'value':
							t += ' (' + zenFormatNumber(value,"#,#") + ')';
							break;
						case 'pctOfTotal':
							t += ' (' + zenFormatNumber(value/total,"#.#%") + ')';
							break;
						case 'pctOfMax':
							t += ' (' + zenFormatNumber(value/maxValue,"#.#%") + ')';
							break;
						}
						var textNode = this.document.createTextNode(t);
						text.appendChild(textNode);
						var th = zenGetBBox(text).height / scaleY;
						var tw = zenGetBBox(text).width / scaleX;
						
						box.setAttribute('rx',3);
						box.setAttribute('x',(tx*scaleX)-3);
						box.setAttribute('y',(ty-(th*(1/1.1)))*scaleY);
						box.setAttribute('width',(tw*scaleX)+6);
						box.setAttribute('height',(th*1.13)*scaleY);
						box2.setAttribute('rx',3);
						box2.setAttribute('x',(tx*scaleX)-3);
						box2.setAttribute('y',(ty-(th*(1/1.1)))*scaleY);
						box2.setAttribute('width',(tw*scaleX)+6);
						box2.setAttribute('height',(th*1.13)*scaleY);

						// line
						// (skip if labels go past horizontal mid-point)
						if ((tx+tw) < cx) {
							var line = this.document.createElementNS(SVGNS,"path");
							var d = 'M '+(cx*scaleX)+' '+((cy-r)*scaleR)+' L '+((tx+tw)*scaleX+4)+' '+((ty-th/3)*scaleY);
							line.setAttribute("class","chart-sliceLine");
							line.setAttribute("style",'stroke-width: 0.5px;');
							line.setAttribute("d",d);
							group.appendChild(line);

							var endPoint = this.document.createElementNS(SVGNS,"circle");
							endPoint.setAttribute("class","chart-sliceLine");
							endPoint.setAttribute("style",'fill:white;');
							endPoint.setAttribute("cx",cx*scaleX);
							endPoint.setAttribute("cy",(cy-r)*scaleR);
							endPoint.setAttribute("r",3.5);
							group.appendChild(endPoint);
						}

						ty += (th * 1.2) + 3;
					}
				}
			}
		}

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in bullseyeChart.renderSeries');
	}
}

/// Indicates that this chart supports "show multiples" mode.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return this.showMultiples;
}

/// Return default style for slice element.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	var clr;

	var ic = this.getSeriesSize();
	if (this._legendVisible) {
		var op = 1.0; // if legends are visible then let legend and slices have the same color rather than color determined by bleed-through
	} else {
		var op = ic>0 ? ((1-(item/ic))*0.8) : 0.8;
	}
	clr = this.getSeriesColor(item);
	return "stroke-width: 0.5px; fill-opacity: "+op+"; stroke: " + '#F0F0F0;' + "; fill: " + clr + ";" + this.plotStyle;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'pieScale':
		this[property] = parseFloat(value);
		this.render();
		break;
	case 'labelValue':
		this[property] = value;
		this.render();
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}
}

/// Return an array of related svg objects for a specified data element (if any).
/// (such as the edges of a 3d rendering).
ClientMethod getChartRelatedElements(series, item) [ Language = javascript ]
{
	var array = null;
	var box = this.findSVGElement('box_' + series + '_' + item);
	if (box) {
		array = [box];
	}
	return array;
}

ClientMethod getLegendRectStyle(item) [ Language = javascript ]
{
	return this.getChartElementStyle(1,item);
}

ClientMethod getRelatedElementStyle(series, item) [ Language = javascript ]
{
	var style="fill: white;fill-opacity: 0.1;stroke: #808080;stroke-width: 0.25px;";
	return style;
}

ClientMethod getLegendsCount(legends) [ Language = javascript ]
{
	return this.seriesSize;
}

ClientMethod getSeriesNamesSize() [ Language = javascript ]
{
	return this.seriesSize;
}

}
