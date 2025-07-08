/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a tree map.<br>
/// A tree map displays a series of values as a set of rectangles. The area of 
/// each rectangle is proportional to its value. Negative values are ignored.
Class %ZEN.SVGComponent.treeMapChart Extends chart [ Deprecated, System = 3 ]
{

/// If true, percentage values (rounded to 2 decimal places integer) are displayed as 
/// part of the label for each box.
Property showPercentage As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// ongetColorScaleData event handler:
/// This event handler, if defined, is called by the chart to compute the color scale
/// for a given data item. It should match the format of <method>ongetData</method>,
/// returning corresponding color scale values for each data point returned by
/// <method>ongetData</method>. For example, to scale the colors of each data point
/// according to the "value" of that data point itself, set this property to the 
/// same event handler as <method>ongetData</method>.
/// The scaled colors will be using the first color defined in 
/// <property>seriesColorScheme</property>, optionally overridden by
/// <property>seriesColors</property>.
Property ongetColorScaleData As %ZEN.Datatype.eventHandler;

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

		// get array of data items
		var dataItems = [];
		var total = 0;
		items = ic;
		for (var i = 0; i < ic; i++) {
			var value = 0;
			// sum data across series!
			for (var s = 0; s < sc; s++) {
				var data = this._dataSeries[isNaN(seriesNumber)?s:seriesNumber];
				value += (data == null || data[i] == null || data[i] < 0 || isNaN(parseFloat(data[i]))) ? 0 : (parseFloat(data[i]));
			}
			dataItems[i] = {value:value, itemNo:i};
			total += value;
		}
		
		this._totalValue = total;
		
		// reverse sort
		dataItems.sort(function(a,b) { return parseFloat(b.value) - parseFloat(a.value) });

		// remove SVG elements within our group.
		while(null != group.firstChild) {
			group.removeChild(group.firstChild);
		}

		var qCount = 2;
		this.plotItems(group,dataItems,this._plotWidth,this._plotHeight,0,0,qCount,isNaN(seriesNumber)?0:seriesNumber);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in treeMapChart.renderSeries');
	}
}

/// Plot map items onto the chart.
ClientMethod plotItems(group, dataItems, width, height, x, y, qCount, seriesNumber) [ Language = javascript ]
{
	// find sum of items
	var sum = 0;
	for (var n = 0; n < dataItems.length; n++) {
		var val = parseFloat(dataItems[n].value);
		sum += (isNaN(val)?0:val);
	}

	// special case: test if first item is bigger than the rest combined
	var plotOne = false;
	if (dataItems.length >= 2) {
		var a0 = parseFloat(dataItems[0].value);
		if (a0 > (sum/2)) {
			plotOne = true;
		}
	}

	// give an advantage to the larger dimension
	var svgWidth = parseInt(this.width);
	var svgHeight = parseInt(this.height);
	if (svgWidth > svgHeight) {
		var wFactor = 0.6;
		var hFactor = 1.0;
	}
	else {
		var wFactor = 1.0;
		var hFactor = 0.6;
	}

	// find orientation
	if ((width*wFactor*this._scaleX) >= (height*hFactor*this._scaleY)) {
		var vertical = true;
		var size = height;
		var ratio = width / size;
	}
	else {
		var vertical = false;
		var size = width;
		var ratio = height / size;
	}

	if (dataItems.length < qCount) {
		qCount = dataItems.length;
	}

	if (plotOne) {
		// place first item by itself
		var a0 = parseFloat(dataItems[0].value);
		var edge = (a0/sum)*size*ratio;

		if (vertical) {
			var x1 = x;
			var y1 = y;
			var w1 = edge;
			var h1 = size;
		}
		else {
			var x1 = x;
			var y1 = y;
			var w1 = size;
			var h1 = edge;
		}

		var itemNo = dataItems[0].itemNo;
		this.plotOneBox(group,seriesNumber,itemNo,x1,y1,w1,h1,a0);

		// remove item; repeat
		dataItems.splice(0,1);
		if (dataItems.length>0) {
			if (vertical) {
				this.plotItems(group,dataItems,width-edge,height,x+edge,y,qCount,seriesNumber);
			}
			else {
				this.plotItems(group,dataItems,width,height-edge,x,y+edge,qCount,seriesNumber);
			}
		}
	}
	else {
		// place first N items
		var a = [];
		var idx = [];
		var split = [];
		var asum = 0;
		for (var n = 0; n < qCount; n++) {
			a[n] = parseFloat(dataItems[n].value);
			asum += a[n];
		}
		if (asum>0) {
			var edge = (asum/sum)*size*ratio;
			for (var n = 0; n < qCount; n++) {
				split[n] = a[n]/asum;
			}

			var xi = [];
			var yi = [];
			var wi = [];
			var hi = [];
			for (var n = 0; n < qCount; n++) {
				if (vertical) {
					xi[n] = x;
					yi[n] = n>0 ? (y + (split[n-1]*size)) : y;
					wi[n] = edge;
					hi[n] = split[n]*size;
				}
				else {
					xi[n] = n>0 ? (x + (split[n-1]*size)) : x;
					yi[n] = y;
					wi[n] = split[n]*size;
					hi[n] = edge;
				}
			}

			// render
			for (var n = 0; n < qCount; n++) {
				var itemNo = dataItems[n].itemNo;
				this.plotOneBox(group,seriesNumber,itemNo,xi[n],yi[n],wi[n],hi[n],a[n]);
			}

			// remove items; repeat
			dataItems.splice(0,qCount);

			if (dataItems.length>0) {
				if (vertical) {
					this.plotItems(group,dataItems,width-edge,height,x+edge,y,qCount,seriesNumber);
				}
				else {
					this.plotItems(group,dataItems,width,height-edge,x,y+edge,qCount,seriesNumber);
				}
			}
		}
	}
}

/// Render one item in the chart.
ClientMethod plotOneBox(group, seriesNo, itemNo, x, y, width, height, value) [ Language = javascript ]
{
	var clr = this.getSeriesColor(itemNo, seriesNo, itemNo);

	var scaleX = this._scaleX ? this._scaleX : 1;
	var scaleY = this._scaleY ? this._scaleY : 1;

	// JMD1174: get real series #
	if (this.showMultiples) {
		var rsno = this.currMultiple;
	}
	else {
		var rsno = seriesNo;
	}
	rsno = (''===rsno) ? 0 : rsno;

	// mouse
	var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+itemNo+');');

	var rect = this.document.createElementNS(SVGNS,"rect");
	rect.setAttribute("x",x*scaleX);
	rect.setAttribute("y",y*scaleY);
	rect.setAttribute("width",width*scaleX);
	rect.setAttribute("height",height*scaleY);
	rect.setAttribute('id',this.makeId('el_' + rsno + '_' + itemNo));
	var selectedStyle = "";
	if (rsno == this.selectedSeries && itemNo == this.selectedItem) {
		selectedStyle=this.selectedItemStyle+";";
	}
	rect.setAttribute("style",'stroke:#808080;stroke-width:0.1;fill:'+clr+';'+ ((this.plotStyle)? this.plotStyle + ';' : '')+selectedStyle);
	group.appendChild(rect);
	rect.addEventListener('click',f,false);

	var borderWidth = 3;
	var wx = borderWidth/scaleX;
	var hx = borderWidth/scaleY;
	if ((borderWidth>0)&&(width>(wx*2))&&(height>(hx*2))) {
		var rect = this.document.createElementNS(SVGNS,"rect");
		rect.setAttribute("x",(x+wx)*scaleX);
		rect.setAttribute("y",(y+hx)*scaleY);
		rect.setAttribute("width",(width-(wx*2))*scaleX);
		rect.setAttribute("height",(height-(hx*2))*scaleY);
		rect.setAttribute("style",'stroke:none;fill:url(#glow-silverDiag);opacity:0.2;');
		rect.setAttribute('id',this.makeId('el_' + rsno + '_' + itemNo));
		group.appendChild(rect);
		rect.addEventListener('click',f,false);
	}

	// JMD1174: mouseover/out handlers
	var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+rsno+','+itemNo+');');
	rect.addEventListener('mouseover',f,false);

	var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+rsno+','+itemNo+');');
	rect.addEventListener('mouseout',f,false);

	// label
	var textColor = (this.labelStyle || (this.ongetColorScaleData=='')) ? '' : ('fill: '+this.getFGColor(clr)+';'); // BDB435
	if (this.labelsVisible) {
		lbl = this.getYLabelText(itemNo);
		var text = this.document.createElementNS(SVGNS,"text");
		group.appendChild(text);

		text.setAttribute("text-anchor","middle");
		text.setAttribute("x",(parseFloat(x)+(width/2))*scaleX);
		text.setAttribute("y",(parseFloat(y)+(height/2))*scaleY);
		text.setAttribute("class","chart-valueLabel");		// DTB109

		var textNode = this.document.createTextNode(lbl);
		text.appendChild(textNode);

		if (this.labelStyle) {
			// JMD1174: if labelStyle supplied, do not auto-size text
			text.setAttribute("style",this.labelStyle);
			var tw = zenGetComputedTextLength(text)/scaleX;
			var th = zenGetBBox(text).height/scaleY;
		}
		else {
			var fSize = 20;
			text.setAttribute("style","font-size:"+fSize+"px;"+textColor);
			var tw = zenGetComputedTextLength(text)/scaleX;
			var th = zenGetBBox(text).height/scaleY;
			var attempts = 0;
			while (tw > (width*0.9) && attempts < 5) {
				fSize *= 0.8;
				text.setAttribute("style","font-size:"+fSize+"px;opacity:0.75;"+textColor);
				tw = zenGetComputedTextLength(text)/scaleX;
				th = zenGetBBox(text).height/scaleY;
				attempts++;
			}
		}

		if (tw > (width*0.9) || (th > height*0.9)) {
			text.setAttribute("style","display: none;");
		}
		else {
			if (this.showPercentage) {
				var text2 = this.document.createElementNS(SVGNS,"text");

				text2.setAttribute("text-anchor","middle");
				text2.setAttribute("x",(parseFloat(x)+(width/2))*scaleX);
				text2.setAttribute("y",(parseFloat(y)+(height/2)+th)*scaleY);
				text2.setAttribute("class","chart-sliceLabel");
				if (this.labelStyle) {
					text2.setAttribute("style",this.labelStyle);
				}
				else {
					text2.setAttribute("style","font-size:"+fSize+"px;opacity:0.35;"+textColor);
				}
				var pct = this._totalValue ? (100*value/this._totalValue).toFixed(2) : '';
				var t = pct + '%';
				var textNode = this.document.createTextNode(t);
				text2.appendChild(textNode);
				group.appendChild(text2);
				var tw2 = zenGetComputedTextLength(text2)/scaleX;
				var th2 = zenGetBBox(text2).height/scaleY;
				if (tw2 > (width*0.9) || (th2 > height*0.9)) {
					text2.setAttribute("style","display: none;");
				}
			}
		}
	} else {
		// labels not visible, check if showPercentage is true
		if (this.showPercentage) {
				var fSize = 20;
			
				var text = this.document.createElementNS(SVGNS,"text");

				text.setAttribute("text-anchor","middle");
				text.setAttribute("x",(parseFloat(x)+(width/2))*scaleX);
				text.setAttribute("y",(parseFloat(y)+(height/2))*scaleY);
				text.setAttribute("class","chart-sliceLabel");
				if (this.labelStyle) {
					text.setAttribute("style",this.labelStyle);
				}
				else {
					text.setAttribute("style","font-size:"+fSize+"px;opacity:0.35;"+textColor);
				}
				var pct = this._totalValue ? (100*value/this._totalValue).toFixed(2) : '';
				var t = pct + '%';
				var textNode = this.document.createTextNode(t);
				text.appendChild(textNode);
				group.appendChild(text);
				
				var tw = zenGetComputedTextLength(text)/scaleX;
				var th = zenGetBBox(text).height/scaleY;
				var attempts = 0;
				while (tw > (width*0.9) && attempts < 5) {
					fSize *= 0.8;
					text.setAttribute("style","font-size:"+fSize+"px;opacity:0.75;"+textColor);
					tw = zenGetComputedTextLength(text)/scaleX;
					th = zenGetBBox(text).height/scaleY;
					attempts++;
				}

				if (tw > (width*0.9) || (th > height*0.9)) {
					text.setAttribute("style","display: none;");
				}
			
		}			
	}
}

/// Indicates that this chart supports "show multiples" mode.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return this.showMultiples;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'showPercentage':
		this[property] = value ? true : false;
		this.render();
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Return an array of labels to display within the Legend box.<br>
/// Override to get appropriate labels for TreeMap Chart.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	var legends = [];

	var sc = this.getSeriesCount();
	var ic = this.getSeriesSize();
	if ((ic == 1 || sc == 1)) {
		return legends;
	}
	for (var i = 0; i < ic; i++) {
		var	lbl = this.getYLabelText(i,'',1);
		legends[i] = zenIsMissing(lbl) ? (parseInt(i,10)+1) : lbl;
	}
	return legends;
}

/// Return default style for slice element.
ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	var clr;
	var op = '1.0';

	clr = this.getSeriesColor(item, series, item);
	return "stroke-width: 0.25px; fill-opacity: "+op+"; stroke: " + 'gray' + "; fill: " + clr + ";" + this.plotStyle;
}

ClientMethod acquireData() [ Internal, Language = javascript ]
{
	this.invokeSuper('acquireData')
	
	// BDB435: now also load color scale data and precalc max and min values
	if (this.ongetColorScaleData!='') {
		delete this._colorScaleData
		var seriesNumber = parseInt(this.seriesNumber);
		var scount = this.getSeriesCount();
		this._colorScaleData = new Array(scount);
		this._colorScaleDataMax = new Array(scount);
		for (var s = 0; s < scount; s++) {
			if (isNaN(seriesNumber) || (s==seriesNumber)) {
				var data = zenInvokeCallbackMethod(this.ongetColorScaleData,this,'ongetColorScaleData','series',s);
				var max = 'x'; var min = 'x';
				this._colorScaleData[s] = [];
				if (data) {
					for (var i = 0; i < data.length; i++) {
						var v = parseFloat(data[i]);
						this._colorScaleData[s][i] = v;
						if ((isNaN(max) || (max < v)) && !isNaN(v)) {
							max = v;
						}
						if ((isNaN(min) || (min > v)) && !isNaN(v)) {
							min = v;
						}
					}
					this._colorScaleDataMax[s] = { 'max':isNaN(max)?0:max, 'min':isNaN(min)?0:min };
				}
			}
		}
	}
}

/// Return the CSS color that should be used for the given series.
ClientMethod getSeriesColor(index, series, itemNo) [ Language = javascript ]
{
	// BDB435: get series color from ongetColorScaleData
	if ((''!=this.ongetColorScaleData) && (series!=null) && (itemNo!=null)) {
		
		// find the percentage-wise position of this item's value in the total interval
		if (this._colorScaleData[series].length>itemNo) {
			var value = this._colorScaleData[series][itemNo];
			var max = this._colorScaleDataMax[series];
			
			var pct = ((max['max']==max['min']) ? 0 : (value - max['min']) / (max['max'] - max['min']));
		} else {
			var pct = 0;
		}
		
		// derive color hops to scale between
		var colors = !zenIsMissing(this.seriesColors) ? this._seriesColors : [this._seriesColors[0]];
		if (colors==null || colors.length == 0) {
			colors = ['rgb(0,0,0)', 'rgb(0,255,0)'];
		} else if (colors.length == 1) {
			colors = ['rgb(0,0,0)', colors[0]];
		}
		// derive RGB values for each hop
		var colorsRGB = new Array(colors.length);
		for (var i = 0; i<colors.length; i++) {
			try {
				colorsRGB[i] = this.convertToRGB(colors[i]);
			} catch (err) {
				alert(err);
				return 'black';
			}
		}
		
		// pick the right color index and rescale pct to build scaled color between
		// colors[index] and colors[index+1]
		if ((colors.length == 2) || (pct==0)) {
			var index = 0; 
		} else {
			var maxIndex = colors.length-1;
			var index = Math.floor(pct * maxIndex);
			index = (index == maxIndex) ? index-1 : index;
			pct = (pct - (index / maxIndex)) * maxIndex; 
		}
		var scaledColor = new Array(3);
		//alert('index: '+index+' / '+colors.length+'\nvalue: '+data[itemNo]+' ['+tMin+'-'+tMax+'] --> '+pct+'\ndata: '+data.join(', '));
		for (i = 0; i < 3; i++) {
			low = parseInt(colorsRGB[index][i]);
			high = parseInt(colorsRGB[index+1][i]); 
			scaledColor[i] = Math.round(low + (pct * (high-low)));
		}
		
		return 'rgb('+scaledColor.join(',')+')';
	}
	
	// +PFS023 - Invoke from chart, this will handle default colors and Data-driven colors
	var sclr = this.invokeSuper('getSeriesColor',arguments)
	return sclr
	// -PFS023
}

/// Returns a 3-element array containing the RGB values for the string input. 
/// Supporte inputs: 
/// 		- RGB format: fe 'rgb(123,45,67)' => { 123, 45, 67 }
/// 		- HEX format, with or without leading #: fe '#ff0000' => { 255, 0, 0 }
/// 		- predefined CSS colors: fe 'white' => { 255, 255, 255 }
/// Throws a simple string error message if unsupported input is being supplied (such as "url(#glow-red)")
ClientMethod convertToRGB(string) [ Language = javascript ]
{
	string = zenTrim(string).toLowerCase();
	
	// RGB format
	if (string.substr(0,4)=='rgb(') {
		var arr = string.substring(4,string.length-1).split(',');
		for (var i = 0; i<3; i++) {
			arr[i] = parseInt(zenTrim(arr[i]));
		}
		return arr;
	}
	
	// HEX format
	var isHex = string.match(/#?[0-9abcdef]{6}/g);
	if (isHex && (isHex.length==1)) {
		if (string.charAt(0)=='#') { string = string.substr(1); }
		var arr = new Array(3);
		for (var i = 0; i<3; i++) {
			arr[i] = parseInt(string.substr(i*2,2),16);
		}
		return arr;
	}
	
	// predefined
	switch (string) {
		case 'aliceblue': return this.convertToRGB('#f0f8ff');
		case 'antiquewhite': return this.convertToRGB('#faebd7');
		case 'aqua': return this.convertToRGB('#00ffff');
		case 'aquamarine': return this.convertToRGB('#7fffd4');
		case 'azure': return this.convertToRGB('#f0ffff');
		case 'beige': return this.convertToRGB('#f5f5dc');
		case 'bisque': return this.convertToRGB('#ffe4c4');
		case 'black': return this.convertToRGB('#000000');
		case 'blanchedalmond': return this.convertToRGB('#ffebcd');
		case 'blue': return this.convertToRGB('#0000ff');
		case 'blueviolet': return this.convertToRGB('#8a2be2');
		case 'brown': return this.convertToRGB('#a52a2a');
		case 'burlywood': return this.convertToRGB('#deb887');
		case 'cadetblue': return this.convertToRGB('#5f9ea0');
		case 'chartreuse': return this.convertToRGB('#7fff00');
		case 'chocolate': return this.convertToRGB('#d2691e');
		case 'coral': return this.convertToRGB('#ff7f50');
		case 'cornflowerblue': return this.convertToRGB('#6495ed');
		case 'cornsilk': return this.convertToRGB('#fff8dc');
		case 'crimson': return this.convertToRGB('#dc143c');
		case 'cyan': return this.convertToRGB('#00ffff');
		case 'darkblue': return this.convertToRGB('#00008b');
		case 'darkcyan': return this.convertToRGB('#008b8b');
		case 'darkgoldenrod': return this.convertToRGB('#b8860b');
		case 'darkgray': return this.convertToRGB('#a9a9a9');
		case 'darkgreen': return this.convertToRGB('#006400');
		case 'darkkhaki': return this.convertToRGB('#bdb76b');
		case 'darkmagenta': return this.convertToRGB('#8b008b');
		case 'darkolivegreen': return this.convertToRGB('#556b2f');
		case 'darkorange': return this.convertToRGB('#ff8c00');
		case 'darkorchid': return this.convertToRGB('#9932cc');
		case 'darkred': return this.convertToRGB('#8b0000');
		case 'darksalmon': return this.convertToRGB('#e9967a');
		case 'darkseagreen': return this.convertToRGB('#8fbc8f');
		case 'darkslateblue': return this.convertToRGB('#483d8b');
		case 'darkslategray': return this.convertToRGB('#2f4f4f');
		case 'darkturquoise': return this.convertToRGB('#00ced1');
		case 'darkviolet': return this.convertToRGB('#9400d3');
		case 'deeppink': return this.convertToRGB('#ff1493');
		case 'deepskyblue': return this.convertToRGB('#00bfff');
		case 'dimgray': return this.convertToRGB('#696969');
		case 'dodgerblue': return this.convertToRGB('#1e90ff');
		case 'firebrick': return this.convertToRGB('#b22222');
		case 'floralwhite': return this.convertToRGB('#fffaf0');
		case 'forestgreen': return this.convertToRGB('#228b22');
		case 'fuchsia': return this.convertToRGB('#ff00ff');
		case 'gainsboro': return this.convertToRGB('#dcdcdc');
		case 'ghostwhite': return this.convertToRGB('#f8f8ff');
		case 'gold': return this.convertToRGB('#ffd700');
		case 'goldenrod': return this.convertToRGB('#daa520');
		case 'gray': return this.convertToRGB('#808080');
		case 'green': return this.convertToRGB('#008000');
		case 'greenyellow': return this.convertToRGB('#adff2f');
		case 'honeydew': return this.convertToRGB('#f0fff0');
		case 'hotpink': return this.convertToRGB('#ff69b4');
		case 'indianred ': return this.convertToRGB('#cd5c5c');
		case 'indigo ': return this.convertToRGB('#4b0082');
		case 'ivory': return this.convertToRGB('#fffff0');
		case 'khaki': return this.convertToRGB('#f0e68c');
		case 'lavender': return this.convertToRGB('#e6e6fa');
		case 'lavenderblush': return this.convertToRGB('#fff0f5');
		case 'lawngreen': return this.convertToRGB('#7cfc00');
		case 'lemonchiffon': return this.convertToRGB('#fffacd');
		case 'lightblue': return this.convertToRGB('#add8e6');
		case 'lightcoral': return this.convertToRGB('#f08080');
		case 'lightcyan': return this.convertToRGB('#e0ffff');
		case 'lightgoldenrodyellow': return this.convertToRGB('#fafad2');
		case 'lightgray': return this.convertToRGB('#d3d3d3');
		case 'lightgreen': return this.convertToRGB('#90ee90');
		case 'lightpink': return this.convertToRGB('#ffb6c1');
		case 'lightsalmon': return this.convertToRGB('#ffa07a');
		case 'lightseagreen': return this.convertToRGB('#20b2aa');
		case 'lightskyblue': return this.convertToRGB('#87cefa');
		case 'lightslategray': return this.convertToRGB('#778899');
		case 'lightsteelblue': return this.convertToRGB('#b0c4de');
		case 'lightyellow': return this.convertToRGB('#ffffe0');
		case 'lime': return this.convertToRGB('#00ff00');
		case 'limegreen': return this.convertToRGB('#32cd32');
		case 'linen': return this.convertToRGB('#faf0e6');
		case 'magenta': return this.convertToRGB('#ff00ff');
		case 'maroon': return this.convertToRGB('#800000');
		case 'mediumaquamarine': return this.convertToRGB('#66cdaa');
		case 'mediumblue': return this.convertToRGB('#0000cd');
		case 'mediumorchid': return this.convertToRGB('#ba55d3');
		case 'mediumpurple': return this.convertToRGB('#9370db');
		case 'mediumseagreen': return this.convertToRGB('#3cb371');
		case 'mediumslateblue': return this.convertToRGB('#7b68ee');
		case 'mediumspringgreen': return this.convertToRGB('#00fa9a');
		case 'mediumturquoise': return this.convertToRGB('#48d1cc');
		case 'mediumvioletred': return this.convertToRGB('#c71585');
		case 'midnightblue': return this.convertToRGB('#191970');
		case 'mintcream': return this.convertToRGB('#f5fffa');
		case 'mistyrose': return this.convertToRGB('#ffe4e1');
		case 'moccasin': return this.convertToRGB('#ffe4b5');
		case 'navajowhite': return this.convertToRGB('#ffdead');
		case 'navy': return this.convertToRGB('#000080');
		case 'oldlace': return this.convertToRGB('#fdf5e6');
		case 'olive': return this.convertToRGB('#808000');
		case 'olivedrab': return this.convertToRGB('#6b8e23');
		case 'orange': return this.convertToRGB('#ffa500');
		case 'orangered': return this.convertToRGB('#ff4500');
		case 'orchid': return this.convertToRGB('#da70d6');
		case 'palegoldenrod': return this.convertToRGB('#eee8aa');
		case 'palegreen': return this.convertToRGB('#98fb98');
		case 'paleturquoise': return this.convertToRGB('#afeeee');
		case 'palevioletred': return this.convertToRGB('#db7093');
		case 'papayawhip': return this.convertToRGB('#ffefd5');
		case 'peachpuff': return this.convertToRGB('#ffdab9');
		case 'peru': return this.convertToRGB('#cd853f');
		case 'pink': return this.convertToRGB('#ffc0cb');
		case 'plum': return this.convertToRGB('#dda0dd');
		case 'powderblue': return this.convertToRGB('#b0e0e6');
		case 'purple': return this.convertToRGB('#800080');
		case 'red': return this.convertToRGB('#ff0000');
		case 'rosybrown': return this.convertToRGB('#bc8f8f');
		case 'royalblue': return this.convertToRGB('#4169e1');
		case 'saddlebrown': return this.convertToRGB('#8b4513');
		case 'salmon': return this.convertToRGB('#fa8072');
		case 'sandybrown': return this.convertToRGB('#f4a460');
		case 'seagreen': return this.convertToRGB('#2e8b57');
		case 'seashell': return this.convertToRGB('#fff5ee');
		case 'sienna': return this.convertToRGB('#a0522d');
		case 'silver': return this.convertToRGB('#c0c0c0');
		case 'skyblue': return this.convertToRGB('#87ceeb');
		case 'slateblue': return this.convertToRGB('#6a5acd');
		case 'slategray': return this.convertToRGB('#708090');
		case 'snow': return this.convertToRGB('#fffafa');
		case 'springgreen': return this.convertToRGB('#00ff7f');
		case 'steelblue': return this.convertToRGB('#4682b4');
		case 'tan': return this.convertToRGB('#d2b48c');
		case 'teal': return this.convertToRGB('#008080');
		case 'thistle': return this.convertToRGB('#d8bfd8');
		case 'tomato': return this.convertToRGB('#ff6347');
		case 'turquoise': return this.convertToRGB('#40e0d0');
		case 'violet': return this.convertToRGB('#ee82ee');
		case 'wheat': return this.convertToRGB('#f5deb3');
		case 'white': return this.convertToRGB('#ffffff');
		case 'whitesmoke': return this.convertToRGB('#f5f5f5');
		case 'yellow': return this.convertToRGB('#ffff00');
		case 'yellowgreen': return this.convertToRGB('#9acd32');
	}
	
	throw "Unsupported color format: '"+string+"'";
}

/// Based on the supplied background color, return an appropriately contrasting foreground
/// color (for text labels). Currently, returns either black or white based on background
/// brightness
ClientMethod getFGColor(background) [ Language = javascript ]
{
	try {
		var rgb = this.convertToRGB(background);
	} catch (err) {
		//alert(err);
		return 'black';
	}
	var tBright = (rgb[0]*rgb[0]*0.241)+(rgb[1]*rgb[1]*0.691)+(rgb[2]*rgb[2]*0.068);
	return (tBright>16900) ? "black" : "white";
}

ClientMethod getToolTipInfo(series, item, captions, values) [ Internal, Language = javascript ]
{
	this.invokeSuper('getToolTipInfo',arguments);
	
	// BDB435 - append color scale value
	if ((this.ongetColorScaleData!="") && (series!=null) && (item!=null)
			 && this._colorScaleData && (this._colorScaleData.length>series)
			 && this._colorScaleData[series] && (this._colorScaleData[series].length>item)) {
		if (captions[captions.length-1]=='Value') {
			captions[captions.length-1] = 'Value (size)';
		}
		captions[captions.length] = $$$Text("Value (color)");
		
		var val = this._colorScaleData[series][item];
		if (!isNaN(parseFloat(val))) {
			if (parseFloat(val)!=parseInt(val)) {
				val = this.formatNumeric(parseFloat(val).toFixed(2));
			}
			else {
				val = this.formatNumeric(parseInt(val));
			}
		}
		values[values.length] = val;
	}
}

}
