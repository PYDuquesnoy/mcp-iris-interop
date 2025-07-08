/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.cpercentbarChart Extends cchart [ Deprecated, System = 4 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "3D";

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property %edgeArray As list Of node(XMLPROJECTION = "none");

Property %lastValueLabel As list Of node(XMLPROJECTION = "none");

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
/// This includes the logic for display combo charts as it is shared with
/// its subclass.
Method renderSeries(group)
{
	Set this=##this
	// JMD1100
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)

	// create series shapes
	Set scount = ..getSeriesCount()
	Set items = ..getSeriesSize()
	Set is3D = ..is3D()
	Set adj3D = $s(is3D : 3, 1 : 0)
	Set seriesNumber = $$$PARSEINT(..seriesNumber)
	if ('$$$ISNAN(seriesNumber)) {
		Set scount = 1
	}

	// find out how many series are "bars"
	// build map of series to bar series #
	Set barMap = "" ; empty list
	Set barSeriesCount = 0
	for s=1:1:scount {
		Set plotType = ..getSeriesType(s-1) ; 0-based
		if (plotType="bar") {
			Set $LI(barMap,s) = barSeriesCount
			Set barSeriesCount = barSeriesCount+1
		}
	}


	if (is3D) {
		Set groupEdge = ##class(node).%New()
		do groupEdge.createElementSVG("g")
		do groupEdge.setAttribute("id",..makeId("groupEdge"))
		do group.appendChild(groupEdge)
	}

	if (..valueLabelsVisible) {
		Set valueGroup = ##class(node).%New()
		do valueGroup.createElementSVG("g")
		do group.appendChild(valueGroup)
	}

	if (items > 0) {
		Set barwid = 1
		if (barSeriesCount > 0) {
			if ('..chartPivot) {
				Set barwid = 0.8 * (..%plotWidth / scount)
			}
			else {
				Set barhgt = 0.8 * (..%plotHeight / scount)
			}
		}

		merge data=..%dataSeries		
		if (is3D) {
			;for i=1:1:items {
				;do ..%edgeArray.SetAt("",i)
			;}
			Set barwid = barwid * 0.75
		}

		// track size to see if value label needs to be hidden (stacked only)
		Set lastBarSize = "" ; empty list
		Set lastValueLabelSize = "" ; empty list
		;Set lastValueLabel = [];

		Set plotType = "" // empty $LB list
		for s=1:1:scount {
			Set $LI(plotType,s) = ..getSeriesType(s-1) // 0-based
		}

		// first plot any "area" series in reverse order to get correct paint order
		for s = scount-1:-1:0 { // 1-based though in Java Script code 0-based
			if ($LI(plotType,s+1)="area") {
				Set filled = 1
				Set hasEvents = 0
				Set hasMarkers = 0
				Set stacked = 0
				do ..plotLineForSeries(group,s,.data,stacked,filled,hasMarkers,hasEvents)
			}
		}

		// calculate totals
		
		Set total="" ; empty list
		for q=0:1:scount-1 {
			Set $LI(total,q+1) = 0
			if ($LI(plotType,q+1)="bar") {
				for n=0:1:items-1 {
					Set v = $s('$D(data(q)) : 0, 1 : $s('$D(data(q,n)) : 0, 1 : $$$PARSEFLOAT(data(q,n))))
					Set v = $s($$$ISNAN(v) : 0, 1 : v)
					Set $LI(total,q+1) = $LI(total,q+1) + $s(v > 0 : v, 1 : 0)
				}
			}
			
		}
	
		if ('..chartPivot) {
			Set x = 0
		} else {
			Set y = 0
		}

		for s = 1:1:scount {
			; 1-based but JavaScript code is 0-based
			if ($LI(plotType,s)="area") {
				continue
			}
			elseif ($LI(plotType,s)="line") {
				Set filled = 0
				set hasEvents = 1
				Set hasMarkers = ..markersVisible
				Set stacked = 0
				do ..plotLineForSeries(group,s-1,.data,stacked,filled,hasMarkers,hasEvents)
				continue
			}
			// find yAxis for this series
			Set yAxisNo = $LG(..%yAxisForSeries,s) ; 1 based

			// create rects for each data point
			if (..valueLabelsVisible) {
				Set $LI(lastBarSize,s) = 0
				Set $LI(lastValueLabelSize,s) = 0
				do ..%lastValueLabel.SetAt("",s) ; all label nodes initially null
			}

			if ('..chartPivot) {
				// normal orientation
				Set dx = ..%plotWidth / scount
				Set adj = (dx/2)
				Set base = 0
				Set bs = $LI(barMap,s)
				// s is 1-based but contents of barMap are 0-based				
				Set shift =  -barwid/2

				if ($$$ISNAN($$$PARSEFLOAT($LG(..%yBaseValue,yAxisNo)))) {
					Set base = ..%plotHeight
				}
				else {
					Set base = ..getPlotY($LG(..%yBaseValue,yAxisNo)) - ..%plotTop
				}
			}
			else {
				// pivotted
				Set dy = ..%plotHeight / scount
				Set adj = (dy/2)
				Set base = 0
				Set bs = $LI(barMap,s)
				// s is 1-based but contents of barMap are 0-based
				Set shift =  -barhgt/2
	
				if ($$$ISNAN($$$PARSEFLOAT(..%xBaseValue))) {
					Set base = 0
				}
				else {
					Set base = ..getPlotX(..%xBaseValue) - ..%plotLeft
				}
			}

			Set valsave = 0
			for n=1:1:items {
				Set color = ..getSeriesColor(n-1)
				Set val = $s(('$D(data(s-1))) : 0, 1 : $s('$D(data(s-1,n-1)) : 0, 1 : $$$PARSEFLOAT(data(s-1,n-1))))
				Set val = $s($$$ISNAN(val) : 0, 1 : val)
				if ((val < 0)  && (barSeriesCount>1)) {
					// only positive values make sense for stacked bars
					Set val = 0
				}
				if $LI(total,s)'=0 {
					Set val = 100 * val / $LI(total,s)
				} else {
					Set val = 0
				}
				Set dval = 0
				Set init = 0
				Set dval=valsave
					
				if ('..chartPivot) {
					Set base = ..getPlotY(dval,yAxisNo) - ..%plotTop
				}
				else {
					Set base = ..getPlotX(dval) - ..%plotLeft
				}
				Set val = val + dval
				Set valsave = val
					
				Set bar = ##class(node).%New()
				do bar.createElementSVG("rect")
				do bar.setAttribute("class","chart-seriesBar")
				if (is3D) {
					Set edgeSide = ##class(node).%New()
					do edgeSide.createElementSVG("path")
					do edgeSide.setAttribute("fill","black")
					do edgeSide.setAttribute("stroke","none")
					do edgeSide.setAttribute("id",..makeId("edgeSide n="_n_" s="_s))

					Set edgeSide2 = ##class(node).%New()
					do edgeSide2.createElementSVG("path")
					do edgeSide2.setAttribute("class","chart-seriesBar")
					do edgeSide2.setAttribute("fill",color)
					do edgeSide2.setAttribute("fill-opacity","0.5")
					do edgeSide2.setAttribute("stroke","black")
					do edgeSide2.setAttribute("id",..makeId("edgeSide2 n="_n_" s="_s))

					Set edgeTop = ##class(node).%New()
					do edgeTop.createElementSVG("path")
					do edgeTop.setAttribute("class","chart-seriesBar")
					do edgeTop.setAttribute("fill",color)
					do edgeTop.setAttribute("stroke","black")
					do edgeTop.setAttribute("id",..makeId("edgeTop n="_n_" s="_s))

					if ('..chartPivot) {
						do groupEdge.appendChild(edgeSide)
						do groupEdge.appendChild(edgeSide2)
						do groupEdge.appendChild(edgeTop)
					}
					else {
						do groupEdge.insertBefore(edgeSide2,$s(..%edgeArray.GetAt(n)'="":..%edgeArray.GetAt(n), 1:groupEdge.firstChild()))
						do groupEdge.insertBefore(edgeSide,edgeSide2)
						if (1) { //(s = barSeriesCount-1) {							
							do groupEdge.insertBefore(edgeTop,edgeSide)
							do ..%edgeArray.SetAt(edgeTop,n)
						}
						else {
							do ..%edgeArray.SetAt(edgeSide,n)
						}
					}

				}


				if ('..chartPivot) {
					if (n=1) {
						Set x = x + dx
					}
					Set y = ..getPlotY(val,yAxisNo) - ..%plotTop

					if (y <= base) {
						Set top = y
						Set hgt = base-y
					}
					else {
						Set top = base
						Set hgt = y-base
					}
					do bar.setAttribute("x",(x-adj+shift-adj3D)*scaleX)
					do bar.setAttribute("y",(top+adj3D)*scaleY)
					do bar.setAttribute("width",barwid*scaleX)
					do bar.setAttribute("height",hgt*scaleY)
					
					if (is3D) {
						do edgeTop.setAttribute("d","M "_((x-adj+shift-adj3D)*scaleX)_" "_((top+adj3D)*scaleY)_" L "_((x-adj+shift)*scaleX)_" "_(top*scaleY)_" "_((x-adj+shift+barwid)*scaleX)_" "_(top*scaleY)_" "_((x-adj+shift+barwid-adj3D)*scaleX)_" "_((top+adj3D)*scaleY)_" z")
						do edgeSide.setAttribute("d","M "_((x-adj+shift+barwid-adj3D)*scaleX)_" "_((top+adj3D)*scaleY)_" L "_((x-adj+shift+barwid)*scaleX)_" "_(top*scaleY)_" "_((x-adj+shift+barwid)*scaleX)_" "_((top+hgt)*scaleY)_" "_((x-adj+shift+barwid-adj3D)*scaleX)_" "_((top+adj3D+hgt)*scaleY)_" z")
						do edgeSide2.setAttribute("d","M "_((x-adj+shift+barwid-adj3D)*scaleX)_" "_((top+adj3D)*scaleY)_" L "_((x-adj+shift+barwid)*scaleX)_" "_(top*scaleY)_" "_((x-adj+shift+barwid)*scaleX)_" "_((top+hgt)*scaleY)_" "_((x-adj+shift+barwid-adj3D)*scaleX)_" "_((top+adj3D+hgt)*scaleY)_" z")
					}
				}
				else {
					if (n=1) {
						Set y = y + dy
					}
					Set x = ..getPlotX(val) - ..%plotLeft

					if (x <= base) {
						Set left = x
						Set wid = base-x
					}
					else {
						Set left = base
						Set wid = x-base
					}
					do bar.setAttribute("x",(left-adj3D)*scaleX)
					do bar.setAttribute("y",(y-adj+shift+adj3D)*scaleY)
					do bar.setAttribute("width",wid*scaleX)
					do bar.setAttribute("height",barhgt*scaleY)
					if (is3D) {
						do edgeTop.setAttribute("d","M "_((left-adj3D+wid)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" L "_((left+wid)*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid)*scaleX)_" "_((y-adj+shift+barhgt)*scaleY)_" "_((left-adj3D+wid)*scaleX)_" "_((y-adj+shift+adj3D+barhgt)*scaleY)_" z")
						do edgeSide.setAttribute("d","M "_((left-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" L "_((left)*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid)*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" z")
						do edgeSide2.setAttribute("d","M "_((left-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" L "_(left*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid)*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" z")
					}
				}

				do bar.setAttribute("fill",color)
				do group.appendChild(bar)


				if (..valueLabelsVisible) {
					/* labels on percentBarCharts should not be marked invisible in this way
					if ((..%lastValueLabel.GetAt(s)'="") && ($LI(lastValueLabelSize,s) > $LI(lastBarSize,s))) {
						do ..%lastValueLabel.GetAt(s).setAttribute("display","none")
					}
					*/
					// JMD1125 backing rect for value box
					Set box = ##class(node).newElementSVG("rect")
					do box.setAttribute("class","chart-valueLabelBox")
					do box.setAttribute("style",this.valueBoxStyle)
					do valueGroup.appendChild(box)
				
					// value label for bar
					Set fSz = 10
					Set align = "middle"
					Set lval = $s('$D(data(s-1)) : "" , 1: $s(('$g(data(s-1,n-1))="") : "", 1 : $$$PARSEFLOAT(data(s-1,n-1))))
					;Set value = $fnumber(lval,",",0)
					// JMD959
					Set value=""
					if '$$$ISNAN($$$PARSEFLOAT(lval)) {
						Set format = ..valueLabelFormat
						Set format = $s(format'="" : format, 1 : $s(($$$FLOOR(lval)'=lval):"#,#.##", 1:"#,#"))
						//value = zenFormatNumber(lval,format);
						Set value=##class(%DeepSee.ResultSet).%FormatNumber(lval,format)
					}
					// JMD1191: place labels in center of bar
					// get size of current bar
					Set cbx = $$$PARSEFLOAT(bar.getAttribute("x"))
					Set cby = $$$PARSEFLOAT(bar.getAttribute("y"))
					Set cbw = $$$PARSEFLOAT(bar.getAttribute("width"))
					Set cbh = $$$PARSEFLOAT(bar.getAttribute("height"))

					// find mid-point of bar
					Set cbxMid = cbx + (cbw/2)
					Set cbyMid = cby + (cbh/2)
					Set tg = this.createSVGTextNode(value,fSz,0,align,0,valueGroup)
					Set textNode = tg.firstChild()
					do textNode.setAttribute("class","chart-valueLabel")
					do textNode.setAttribute("style",this.valueLabelStyle)
					// position box and text in pixels
					Set bbox = ..GetBBox(textNode)
					do textNode.setAttribute("text-anchor","middle")
					do textNode.setAttribute("x",cbxMid)
					do textNode.setAttribute("y",cbyMid + ((bbox.height/2)*0.8))

					do box.setAttribute("x", cbxMid - (bbox.width/2))
					do box.setAttribute("y", cbyMid - (bbox.height/2))
					do box.setAttribute("rx", 3)
					do box.setAttribute("width", bbox.width*1.1)
					do box.setAttribute("height", bbox.height*1.2)


					if (..chartPivot) {
						Set $LI(lastBarSize,s) = wid
					}
					else {
						Set $LI(lastBarSize,s) = hgt
					}
				}	

				do bar.setAttribute("style",..plotStyle)
				if (is3D) {
					do edgeTop.setAttribute("style",..plotStyle)
					do edgeSide2.setAttribute("style",..plotStyle)
				}

			}
		}
	}	
	
	if (..valueLabelsVisible) {
		/* labels on percentBarCharts should not be marked invisible in this way
		for s=1:1:barSeriesCount {
			if ((..%lastValueLabel.GetAt(s)'="") && ($LI(lastValueLabelSize,s) > $LI(lastBarSize,s))) {
				do ..%lastValueLabel.GetAt(s).setAttribute("display","none")
			}
		}
		*/
		// move group to end
		do group.removeChild(valueGroup)
		do group.appendChild(valueGroup)

	}
}

/// Return default style for a bar element.
Method getChartElementStyle(series, item)
{
	Set this=##this
	Set type = this.getSeriesType(series)
	if (type = "bar") {
		quit this.plotStyle
	}
	quit this.markerStyle
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType()
{
	quit $s(..chartPivot : "value", 1 : "category")
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType()
{
	quit $s(..chartPivot : "category", 1 : "value")
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
Method useSumForRange()
{
	quit 1
}

/// This method returns true if data series is from a percentage bar chart
/// when calculating data range for the chart.
Method usePercentForRange()
{
	quit 1
}

/// Return the type (how a series should be displayed) for the given data series (0-based).
/// Overridden in combo chart.
Method getSeriesType(series)
{
	quit "bar"
}

}
