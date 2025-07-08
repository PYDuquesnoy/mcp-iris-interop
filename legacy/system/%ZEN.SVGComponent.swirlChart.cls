/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.SVGComponent.swirlChart Extends %ZEN.SVGComponent.chart [ Deprecated, System = 3 ]
{

/// Whether or not to 'invert' the swirl. In an inverted swirl, the labels are on the outside
/// and the slices are lines rather than real surfaces.
/// <br>Note, that the invert property is only active when labels are visible (labelsVisible=true)
Property invert As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property separateSeriesScale As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// space between first slice and last slice in degrees
Property gap As %ZEN.Datatype.integer(MAXVAL = 135, MINVAL = 0) [ InitialExpression = 30 ];

/// when drawing start, draw slices and labels in an animation or just show finished product
Property animate As %ZEN.Datatype.string(VALUELIST = ",none,auto,manual") [ InitialExpression = "auto" ];

/// Overriding default value: now FALSE
Property legendVisible As %ZEN.Datatype.string(VALUELIST = ",auto,false,true") [ InitialExpression = "false" ];

/// plotBy - items - this is default, it results in slices that are colored by items and a legend that is organized by labels on the slices
/// <br>plotBy - series - it results in slices where slices of the same series are the same color, and legend shows labels for each series (not labels on the slices)
Property plotBy As %ZEN.Datatype.string(VALUELIST = ",items,series") [ InitialExpression = "items" ];

XData SVGStyle
{
<style type="text/css">
</style>
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

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
		case 'invert':
		case 'separateSeriesScale':
			this[property] = value ? true : false;
			this.render();
			break;
		case 'gap':
			if (value < 0) {
				alert(value+$$$Text(" is too small for gap whose minimum is 0"));
				value = 0;
			}
			if (value > 135) {
				alert(value+$$$Text(" is too large for gap whose maximum is 135"));
				value = 135;
			}
		
			this[property] = value;
			this.render();
			break;
		case 'animation':
			this[property] = value;
			this.render();
			break;
		case 'plotBy':
			this[property] = value;
			this.render();
			break;
		default:
			return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Indicates that this chart supports "show multiples" mode.
ClientMethod hasMultiples() [ Language = javascript ]
{
	return false;
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
ClientMethod renderSeries(group) [ Language = javascript ]
{
	try {
		if (this.gap < 0) {
			this.gap = 0;
		}
		if (this.gap > 135) {
			this.gap = 135;
		}
		
		var scaleX = this._scaleX ? this._scaleX : 1;
		var scaleY = this._scaleY ? this._scaleY : 1;
		var pw = this._plotWidth; var ph = this._plotHeight;
		var scaleR = (pw < ph) ? scaleX : scaleY;
		
		var seriesCount = this.getSeriesCount();
		if (this._dataSeries) { seriesCount = Math.min(seriesCount, this._dataSeries.length); }
		var seriesSize = this.getSeriesSize();
		if (this._dataSeries && (this._dataSeries.length>0) && this._dataSeries[0]) { seriesSize = Math.min(seriesSize, this._dataSeries[0].length); }
		var seriesNames = this.getSeriesNames();
		
		// first build labels, but don't position them yet
		var labels = []; var labelValues = []; 
		var maxLabelWidth = 0;
		for (var i = 0; i<seriesSize; i++) {
			var text = this.document.createElementNS(SVGNS,"text");
			group.appendChild(text);
			labels[i] = text;
			text.setAttribute("id", this.makeId("lbl_"+i));
			
			try {
				labelValues[i] = this.getXLabelText(i);
			} catch (ex) {
				labelValues[i] = "[undefined]";
			}
			var textNode = this.document.createTextNode(labelValues[i]);
			text.appendChild(textNode);
			
			var title = this.document.createElementNS(SVGNS,"title")
			text.appendChild(title);
			title.appendChild(this.document.createTextNode(labelValues[i]));
			
			var style = this.labelStyle + " pointer-events: visiblePainted;"
			text.setAttribute("style", style);
			text.setAttribute("class","chart-valueLabel");
			//text.setAttribute("cursor","pointer");
			
			var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,0,'+i+');');
			text.addEventListener('click',f,false);
			
			var labelWidth = zenGetBBox(text).width/scaleX;
			if (labelWidth > maxLabelWidth) { maxLabelWidth = labelWidth; }
		}
		
		// now calculate radius and rotationStep
		var rotationStep = Math.round((360 - parseInt(this.gap)) / seriesSize);
		var cx = pw*0.5; var cy = ph*0.5;
		var cxs = (Math.round(cx*scaleX*1000)/1000);
		var cys = (Math.round(cy*scaleY*1000)/1000);
		var cxy = cxs+','+cys;
		
		// outerRadius is the outer boundary of the graph
		var outerRadius = ((pw < ph) ? pw : ph) * 0.41;
		
		// innerRadius is the outer boundary of the inner part (labels or bars)
		var smallMode = !this.labelsVisible;
		if (!smallMode) {
			if (this.invert) {
				var innerRadius = (outerRadius - maxLabelWidth);
				smallMode = (innerRadius < (outerRadius * 0.4))
			} else {
				var innerRadius = maxLabelWidth * 1.2;
				smallMode = (innerRadius > (outerRadius * 0.9))
			}
		}
		if (smallMode) { innerRadius = outerRadius * 0.05; }
		
		/* debug
		var inner = this.document.createElementNS(SVGNS,"circle");
		group.appendChild(inner);
		inner.setAttribute("cx",cxs);
		inner.setAttribute("cy",cys);
		inner.setAttribute("r",innerRadius*scaleX);
		inner.setAttribute("stroke","grey");
		inner.setAttribute("fill", "none");
		var outer = this.document.createElementNS(SVGNS,"circle");
		group.appendChild(outer);
		outer.setAttribute("cx",cxs);
		outer.setAttribute("cy",cys);
		outer.setAttribute("r",outerRadius*scaleX);
		outer.setAttribute("stroke","black");
		outer.setAttribute("fill", "none");
		var line = this.document.createElementNS(SVGNS,"line");
		group.appendChild(line);
		line.setAttribute("x1",cxs);
		line.setAttribute("y1",cys);
		line.setAttribute("x2",cxs);
		line.setAttribute("y2",(cy-outerRadius)*scaleY);
		line.setAttribute("stroke","red");*/
		
		
		// find the maximum values
		var maxValues = []; var maxValue = 0;
		for (var i = 0; i < seriesCount; i++) {
			maxValues[i]=0;
			for (var j = 0; j < seriesSize; j++) {
				var v = parseFloat(this._dataSeries[i][j]);
				if (isNaN(v)) continue;
				if (this.separateSeriesScale) {
					if (v > maxValues[i]) { maxValues[i] = v; }
				} else {
					if (v > maxValue) { maxValue = v; }
				}
			}
		}
		
		delete this._animated;
		this._animated = [];
		
		// now we can position the labels and build the slices
		var diffRadius = this.invert ? (innerRadius*0.9) : (outerRadius-innerRadius);
		var angle = (Math.PI * 2 * (360 - parseFloat(this.gap)) / 360) / (seriesCount * seriesSize * 1.1); 
		var angleCos = Math.cos(angle); var angleSin = Math.sin(angle);
		var rotationSubStep = (rotationStep*0.90) / seriesCount; 
		var startAngle = -90-(0.45*rotationStep);
		for (var ino = 0; ino < seriesSize; ino++) {
		
			// position the label
			if (smallMode) {
				group.removeChild(labels[ino]);
			} else {
				var th = zenGetBBox(labels[ino]).height/scaleY;
				var tx = cx + innerRadius;
				var ty = cy + (th/5);
				labels[ino].setAttribute("x", tx*scaleX);
				labels[ino].setAttribute("y", ty*scaleY)
				var angle = (ino*rotationStep-90)
				labels[ino].setAttribute("transform", 'rotate('+((this.animate=="none")?angle:-90)+' '+cxy+')');
				labels[ino].setAttribute("text-anchor", this.invert ? 'start' : 'end');
				
				if (this.animate != 'none') {
					this.setAnimation(labels[ino],100,-90, angle, cxy);
				}
			}
			
			// build a slice for each series		
			for (var sno = 0; sno < seriesCount; sno++) {
				
				// calculate size
				var value = parseFloat(this._dataSeries[sno][ino]);
				if (isNaN(value) || (value == 0)) continue;
				var pct = this.separateSeriesScale ? (value / maxValues[sno]) : (value / maxValue);
				
				// don't show value labels. tooltips will do
				
				var slice = this.document.createElementNS(SVGNS,"path");
				group.appendChild(slice);
				slice.setAttribute("id", this.makeId("el_"+sno+"_"+ino));
				
				// build slice path
				if (this.invert && !smallMode) {
					var rad1 = ((innerRadius*0.4)+((1-pct)*(0.54*innerRadius)))*scaleX;
					var rad2 = innerRadius*0.95 * scaleX;
				} else {
					var rad1 = innerRadius*1.05 * scaleX;
					var rad2 = ((innerRadius*1.05) + ((outerRadius-(innerRadius*1.05))*pct)) * scaleX;
				}
				var p1 = (cxs+rad1)+','+cys;
				var p2 = (cxs+rad2)+','+cys;
				var p3 = (cxs+(angleCos*rad2))+','+(cys+(angleSin*rad2));
				var p4 = (cxs+(angleCos*rad1))+','+(cys+(angleSin*rad1));
				slice.setAttribute("d", 'M '+p1+' L'+p2+' A'+rad2+','+rad2+' 0 0,1 '+p3+' L'+p4+' A'+rad1+','+rad1+' 0 0,0 '+p1+' z');
				
				var style =  this.getChartElementStyle(sno, ino);
				if (sno == this.selectedSeries && ino == this.selectedItem) {
					style += this.selectedItemStyle;
				}
				slice.setAttribute("style", style);
				angle = startAngle + (ino*rotationStep) + (sno*rotationSubStep);
				slice.setAttribute("transform", 'rotate('+((this.animate == "none") ? angle : startAngle)+' '+cxy+')');
				
				// listeners
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+sno+','+ino+');');
				slice.addEventListener('click',f,false);
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOver(evt,'+sno+','+ino+');');
				slice.addEventListener('mouseover',f,false);
				var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementMouseOut(evt,'+sno+','+ino+');');
				slice.addEventListener('mouseout',f,false);
				
				/*// show tooltip with series name and formatted value
				var fValue = value;
				if (!isNaN(value)) {
					var format = this.valueLabelFormat;
					format = format ? format : ((Math.floor(value)!=value)?'#,#.##':'#,#');
					fValue = zenFormatNumber(value,format);
				}
				if ((seriesNames!=null) && (seriesNames.length>sno)) {
					fValue = seriesNames[sno] + ': ' + fValue;
				}
				var title = this.document.createElementNS(SVGNS,"title")
				slice.appendChild(title);
				title.appendChild(this.document.createTextNode(fValue));*/
				
				if (smallMode) {
					var title = this.document.createElementNS(SVGNS,"title")
					slice.appendChild(title);
					title.appendChild(this.document.createTextNode(labelValues[i]));
				}
				
				// add animation
				if (this.animate != 'none') {
					this.setAnimation(slice,100,startAngle, angle, cxy);
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in termSwirl.renderSeries');
	}
}

ClientMethod getChartElementStyle(series, item) [ Language = javascript ]
{
	if (this.plotBy=='series') {
		var clr = this.getSeriesColor(series);
		var style = 'stroke-width: 0.25px; stroke: '+clr+'; stroke-opacity: ' + ((series%2) ? '1.0' : '0.85') + '; ';
		style = style + 'fill: '+clr+'; ';
		
	} else if (this.plotBy=='items') {
		var clr = this.getSeriesColor(item);
		var style = 'stroke-width: 0.25px; stroke: '+clr+'; stroke-opacity: ' + ((series%2) ? '1.0' : '0.85') + '; ';
		style = style + 'fill: '+clr+'; fill-opacity: '+ ((series%2) ? '0.80' : '0.60') + '; ';
		
	}
	return  style + ' ' + this.plotStyle;
}

ClientMethod getYLabelText(val, yAxisNo, base) [ Language = javascript ]
{
	// return X label for tooltip
	return this.getXLabelText(val,base);
}

ClientMethod setAnimation(label, steps, from, to, center) [ Language = javascript ]
{
	var delta = (to - from)/steps;
	var timerNo = window.setInterval(function	() {
		try {
			from += delta;
			if (from >= to) {
				window.clearInterval(timerNo);
				from = to;
			}
			label.setAttribute("transform","rotate("+from+" "+center+")");
		} catch(err) {
			alert(err.message);
		}
	}, 1);
}

ClientMethod getLegendsCount(legends) [ Language = javascript ]
{
	var scount = legends.length;
	var seriesNumber = parseInt(this.seriesNumber);
	if (!isNaN(seriesNumber)) {
		scount = 1;
	}

	return (this.plotBy == 'series' ? scount : this.seriesSize);
}

ClientMethod getSeriesNamesSize() [ Language = javascript ]
{
	return (this.plotBy == 'series' ? this.seriesCount : this.seriesSize)
}

/// Return an array of labels to display within the Legend box.<br/>
/// Default implementation is to return a list of series names.
ClientMethod getLegendLabels() [ Language = javascript ]
{
	if (this.plotBy == 'series') {
		return this.getSeriesNames();
	} else {
		var legends = [];
		for (i=0; i < this.seriesSize; i++) {
			legends[i] = this.getXLabelText(i);
		}
		return legends;
	}
}

}
