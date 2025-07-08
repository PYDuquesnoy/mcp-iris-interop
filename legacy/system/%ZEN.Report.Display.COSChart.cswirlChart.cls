/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.cswirlChart Extends %ZEN.Report.Display.COSChart.cchart [ Deprecated, System = 4 ]
{

/// Whether or not to 'invert' the swirl. In an inverted swirl, the labels are on the outside
/// and the slices are lines rather than real surfaces.
/// <br>Note, that the invert property is only active when labels are visible (labelsVisible=1)
Property invert As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property separateSeriesScale As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// space between first slice and last slice in degrees
Property gap As %ZEN.Datatype.integer(MAXVAL = 135, MINVAL = 0) [ InitialExpression = 30 ];

/// Overriding default value: now FALSE
Property legendVisible As %ZEN.Datatype.string(VALUELIST = ",auto,false,true") [ InitialExpression = "false" ];

/// plotBy - items - this is default, it results in slices that are colored by items and a legend that is organized by labels on the slices
/// <br>plotBy - series - it results in slices where slices of the same series are the same color, and legend shows labels for each series (not labels on the slices)
Property plotBy As %ZEN.Datatype.string(VALUELIST = ",items,series") [ InitialExpression = "items" ];

/// Indicates that this chart has no axes and associated grids
Method hasAxes()
{
	quit 0
}

/// Do not show 3-D plot area.
Method is3D()
{
	quit 0
}

/// Indicates that this chart supports "show multiples" mode.
Method hasMultiples()
{
	quit 0
}

Method renderSeries(group)
{
	Set this=##this
	if (this.gap < 0) {
		Set this.gap = 0
	}
	if (this.gap > 135) {
		Set this.gap = 135
	}
	
	Set scaleX = $s(this.%scaleX '="" : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY '="" : this.%scaleY, 1 : 1)
	Set pw = this.%plotWidth,ph = this.%plotHeight
	Set scaleR = $s(pw < ph : scaleX, 1 : scaleY)
	
	Set seriesCount = this.getSeriesCount()
	if ($D(this.%dataSeries)) { Set seriesCount = $$$MIN(seriesCount, ..getDataSeriesCount()) }
	Set seriesSize = this.getSeriesSize()
	Set seriesSize = $$$MIN(seriesSize, ..getDataSeriesLength()) 
	Set seriesNames = this.getSeriesNames() ; this is a $LL list!
	
	// first build labels, but don't position them yet
	// var labels = []; var labelValues = []; 
	Set maxLabelWidth = 0
	for i=0:1:seriesSize-1 {
		Set text = ##class(node).newElementSVG("text")
		do group.appendChild(text)
		Set labels(i) = text
		do text.setAttribute("id", this.makeId("lbl_"+i))
		
		Set labelValues(i) = this.getXLabelText(i)
		do text.setText(labelValues(i))

		// unlike ZEN chart don't put in title, since it confuses the SVG parser
				
		Set style = this.labelStyle
		do text.setAttribute("style", style)
		do text.setAttribute("class","chart-valueLabel")
		do text.setAttribute("cursor","pointer")
		
		Set labelWidth = ..GetBBox(text).width/scaleX
		if (labelWidth > maxLabelWidth) { Set maxLabelWidth = labelWidth }
	}
	
	// now calculate radius and rotationStep
	Set rotationStep = $$$ROUND((360 - $$$PARSEINT(this.gap)) / seriesSize)
	Set cx = pw*0.5, cy = ph*0.5
	Set cxs = ($$$ROUND(cx*scaleX*1000)/1000)
	Set cys = ($$$ROUND(cy*scaleY*1000)/1000)
	Set cxy = cxs_" "_cys
	
	// outerRadius is the outer boundary of the graph
	Set outerRadius = ($s(pw < ph : pw, 1 : ph) * 0.41)
	
	// innerRadius is the outer boundary of the inner part (labels or bars)
	Set smallMode = 'this.labelsVisible
	if ('smallMode) {
		if (this.invert) {
			Set innerRadius = (outerRadius - maxLabelWidth)
			Set smallMode = (innerRadius < (outerRadius * 0.4))
		} else {
			Set innerRadius = maxLabelWidth * 1.2
			Set smallMode = (innerRadius > (outerRadius * 0.9))
		}
	}
	if (smallMode) { Set innerRadius = outerRadius * 0.05 }
	
	// debug
 /*	
	Set inner = ##class(node).newElementSVG("circle")
	do group.appendChild(inner)
	do inner.setAttribute("cx",cxs)
	do inner.setAttribute("cy",cys)
	do inner.setAttribute("r",innerRadius*scaleX)
	do inner.setAttribute("stroke","grey")
	do inner.setAttribute("fill", "none")
	Set outer = ##class(node).newElementSVG("circle")
	do group.appendChild(outer)
	do outer.setAttribute("cx",cxs)
	do outer.setAttribute("cy",cys)
	do outer.setAttribute("r",outerRadius*scaleX)
	do outer.setAttribute("stroke","black")
	do outer.setAttribute("fill", "none")
	Set line = ##class(node).newElementSVG("line")
	do group.appendChild(line)
	do line.setAttribute("x1",cxs)
	do line.setAttribute("y1",cys)
	do line.setAttribute("x2",cxs)
	do line.setAttribute("y2",(cy-outerRadius)*scaleY)
	do line.setAttribute("stroke","red")
	// end debug
*/
	
	// find the maximum values
	Set maxValue = 0
	for i = 0:1:seriesCount-1 {
		Set maxValues(i)=0
		for j = 0:1:seriesSize-1 {
			Set v = $$$PARSEFLOAT(this.%dataSeries(i,j))
			if ($$$ISNAN(v)) continue
			if (this.separateSeriesScale) {
				if (v > maxValues(i)) { Set maxValues(i) = v }
			} else {
				if (v > maxValue) { Set maxValue = v }
			}
		}
	}
	
	// now we can position the labels and build the slices
	Set diffRadius = $s(this.invert : (innerRadius*0.9), 1 : (outerRadius-innerRadius))
	Set angle = ($zPI * 2 * (360 - $$$PARSEFLOAT(this.gap)) / 360) / (seriesCount * seriesSize * 1.1)
	Set angleCos = $zcos(angle),angleSin = $zsin(angle)
	Set rotationSubStep = (rotationStep*0.90) / seriesCount
	Set startAngle = -90-(0.45*rotationStep)
	for ino = 0:1:seriesSize-1 {
	
		// position the label
		if (smallMode) {
			do group.removeChild(labels(ino))
		} else {
			Set th = ..GetBBox(labels(ino)).height/scaleY
			Set tx = cx + innerRadius
			Set ty = cy + (th/5)
			do labels(ino).setAttribute("x", tx*scaleX)
			do labels(ino).setAttribute("y", ty*scaleY)
			Set angle = (ino*rotationStep-90)
			do labels(ino).setAttribute("transform", "rotate("_angle_" "_cxy_")")
			do labels(ino).setAttribute("text-anchor", $s(this.invert : "start", 1 : "end"))
			
		}
		
		// build a slice for each series		
		for sno = 0:1:seriesCount-1 {
			
			// calculate size
			Set value = $$$PARSEFLOAT(this.%dataSeries(sno,ino))
			if ($$$ISNAN(value) || (value = 0)) continue
			Set pct = $s(this.separateSeriesScale : (value / maxValues(sno)), 1 : (value / maxValue))
			
			// don't show value labels. tooltips will do
			
			Set slice = ##class(node).newElementSVG("path")
			do group.appendChild(slice)
			do slice.setAttribute("id", this.makeId("el_"_sno_"_"_ino))
			
			// build slice path
			if (this.invert && 'smallMode) {
				Set rad1 = ((innerRadius*0.4)+((1-pct)*(0.54*innerRadius)))*scaleX
				Set rad2 = innerRadius*0.95 * scaleX
			} else {
				Set rad1 = innerRadius*1.05 * scaleX
				Set rad2 = ((innerRadius*1.05) + ((outerRadius-(innerRadius*1.05))*pct)) * scaleX
			}
			Set p1 = (cxs+rad1)_","_cys
			Set p2 = (cxs+rad2)_","_cys
			Set p3 = (cxs+(angleCos*rad2))_","_(cys+(angleSin*rad2))
			Set p4 = (cxs+(angleCos*rad1))_","_(cys+(angleSin*rad1))
			do slice.setAttribute("d", "M "_p1_" L"_p2_" A"_rad2_","_rad2_" 0 0,1 "_p3_" L"_p4_" A"_rad1_","_rad1_" 0 0,0 "_p1_" z")
			
			Set style =  this.getChartElementStyle(sno, ino)
			if (sno = this.selectedSeries && ino = this.selectedItem) {
				Set style = style_this.selectedItemStyle
			}
			do slice.setAttribute("style", style)
			Set angle = startAngle + (ino*rotationStep) + (sno*rotationSubStep)
			do slice.setAttribute("transform", "rotate("_ angle_" "_cxy_")")
			
			
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
				Set title = ##class(node).newElementSVG("title")
				do slice.appendChild(title)
				do title.setText(labelValues(i))
			}
			
		}
	}
}

Method getChartElementStyle(series, item) As %String
{
	Set this=##this
	if (this.plotBy="series") {
		Set clr = this.getSeriesColor(series)
		Set style = "stroke-width: 0.25px; stroke: "_clr_"; stroke-opacity: " _ $s((series#2) : "1.0", 1 : "0.85") _ "; "
		Set style = style _ "fill: "_clr_"; "
		
	} elseif (this.plotBy="items") {
		Set clr = this.getSeriesColor(item)
		Set style = "stroke-width: 0.25px; stroke: "_clr_"; stroke-opacity: " _ $s((series#2) : "1.0", 1 : "0.85") _ "; "
		Set style = style _ "fill: "_clr_"; fill-opacity: "_ $s((series#2) : "0.80", 1 : "0.60") _ "; "
		
	} else {
		Throw ##class(%Exception.General).%New("swirlChartException",5001,,"Bad plotBy, not series or items = "_this.plotBy)
	}
	quit style _ " " _ this.plotStyle
}

Method getYLabelText(val, yAxisNo, base)
{
	// return X label for tooltip (no tooltips in ZEN Reports)
	quit this.getXLabelText(val,base)
}

Method getLegendsCount(legends)
{
	Set this=##this
	Set scount = $LL(legends)
	Set seriesNumber = $$$PARSEINT(this.seriesNumber)
	if ('$$$ISNAN(seriesNumber)) {
		Set scount = 1
	}

	Quit $s(this.plotBy = "series" : scount, 1 : this.getSeriesSize())
}

Method getSeriesNamesSize()
{
	Quit $s(..plotBy = "series" : ..getSeriesCount(), 1 : ..getSeriesSize())
}

/// Return an array of labels to display within the Legend box.<br/>
/// Default implementation is to return a list of series names.
Method getLegendLabels()
{
	Set this=##this
	If (this.plotBy = "series") {
		Quit this.getSeriesNames()
	} Else {
		Set legends = ""
		for i=0:1:this.getSeriesSize()-1 {
			Set $LI(legends,i+1) = this.getXLabelText(i)
		}
		Quit legends
	}
}

}
