/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.cbarChartDualY Extends cchartDualY [ Deprecated, LegacyInstanceContext, System = 4 ]
{

/// This is an SVG <class>chart</class> component that displays a bar chart.<br>
/// This chart displays one or more data series as rectangular bars whose
/// size is proportional to the data value.<br>
/// If there are multiple data series, the bars are plotted either side-by-side
/// or stacked, as specified by the <property>chartStacked</property> property.<br>
/// You can view data as a set of horizontal columns by setting the <property>chartPivot</property> property.<br>
/// Note: the <property>plotToEdge</property> property is always
/// treated as false for bar charts.
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

Property %edgeArray As list Of node(XMLPROJECTION = "none");

Property %lastValueLabel As list Of node(XMLPROJECTION = "none");

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
#if 0
	s t=$io u 0 w !,"renderSeries ..seriesNumber="_..seriesNumber u t
#endif	
	// create series shapes
	Set this=##this
	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()
	Set is3D = this.is3D()
	Set adj3D = $s(is3D : 3, 1 : 0)
	Set seriesNumber = ..seriesNumber
	if ('$$$ISNAN($$$PARSEINT(seriesNumber))) {
		Set scount = 1
	}

	// JMD1100
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1: 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)

	// JMD1208
	Set multipleOffset = $s(this.currMultiple'="":this.currMultiple, 1:0)

	// limit series if we are in small multiples mode
	if (this.showMultiples) {
		Set seriesNumber = this.currMultiple
		Set scount = 1
	}

	// find out how many series are "bars"
	// build map of series to bar series #
	Set barMap = "" // null $LB list
	Set barSeriesCount = 0
	
	// JMD: take yaxis # into account for stacked bars
	Set yaList = ..split(..seriesYAxes,",")

	if (this.valueLabelsVisible) {
		Set valueGroup = ##class(node).%New()
		do valueGroup.createElementSVG("g")
		do group.appendChild(valueGroup)
	}

	if (items > 0) {
		Set barwid = 1

		// first get data for all series
		if ('$$$ISNAN($$$PARSEINT(seriesNumber))) {
			merge data(0) = this.%dataSeries(seriesNumber)
		}
		else {
			for s = 0:1:scount-1 {
				merge data(s) = this.%dataSeries(s)
			}
		}
		//merge data=this.%dataSeries		

		Set plotType = "" // empty $LB list
		for s=1:1:scount {
			Set $LI(plotType,s) = ..getSeriesType(s-1+multipleOffset) // 0-based
		}

		// first plot any "area" series in reverse order to get correct paint order
		for s = (scount-1):-1:0 { // 0-based as in Java Script code which is 0-based
			if ($LI(plotType,s+1)="area") {
				Set filled = 1
				Set hasEvents = 0
				Set hasMarkers = 0
				Set stacked = 0
				do this.plotLineForSeries(group,s,.data,stacked,filled,hasMarkers,hasEvents)
			}
		}

		for s = 0:1:(scount-1) {
			; 0-based and JavaScript code is 0-based
			if ($LI(plotType,s+1)'="bar") {
				continue
			}

			Set color = this.getSeriesColor(s+multipleOffset) ; 0 based
			// create rects for each data point

			// find yAxis for this series
			Set yAxisNo = $LG(this.%yAxisForSeries,s+1+multipleOffset) ; 1 based $LIST, but 0 based yAxisNo

			if ('this.chartPivot) {
				// normal orientation
				Set dx = this.%plotWidth / items
				Set adj = (dx/2)
				Set x = 0
				Set base = 0
				Set bs = $LI(barMap,s+1)
				// s is 0-based and contents of barMap are 1-based				
				Set shift = $s(this.chartStacked : -barwid/2, 1 : ((bs * barwid) - ((barSeriesCount*barwid)/2)))

				if ($$$ISNAN($$$PARSEFLOAT($LG(this.%yBaseValue,yAxisNo+1)))) {
					Set base = this.%plotHeight
				}
				else {
					Set base = this.getPlotY($LG(this.%yBaseValue,yAxisNo+1)) - this.%plotTop
				}
			}
			else {
				// pivotted
				Set dy = this.%plotHeight / items
				Set adj = (dy/2)
				Set y = 0
				Set base = 0
				Set bs = $LI(barMap,s+1)
				// s is 0-based and contents of barMap are 1-based 12-08-11
				Set shift = $s(this.chartStacked : -barhgt/2, 1 : ((bs * barhgt) - ((barSeriesCount*barhgt)/2)))
	
				if ($$$ISNAN($$$PARSEFLOAT(this.%xBaseValue))) {
					Set base = 0
				}
				else {
					Set base = this.getPlotX(this.%xBaseValue) - this.%plotLeft
				}
			}

			// loop over items in series
			for n=0:1:items-1 {
				Set val = $s(('$D(data(s))) : 0, 1 : $s('$D(data(s,n)) : 0, 1 : $$$PARSEFLOAT(data(s,n))))
				Set val = $s($$$ISNAN(val) : 0, 1 : val)
				/* JMD1125 plot negative bars below the line!
				if (this.chartStacked && (val < 0) && (barSeriesCount>1)) {
					// only positive values make sense for stacked bars
					Set val = 0
				}
				*/
				Set isNeg = (val<0)
				if (this.chartStacked && (s > 0)) {
					Set dval = 0
					for q=0:1:(s-1) {
						if (($LI(plotType,q+1)="bar") && (+$LG(yaList,q+1)=yAxisNo)) {
							Set v = $s(('$D(data(q))) : 0 ,1 : $s(('$D(data(q,n))) : 0, 1 : $$$PARSEFLOAT(data(q,n))))
							Set v = $s($$$ISNAN(v) : 0, 1 : v)
							if ((isNeg && (v < 0))||('isNeg && (v > 0))) {
								Set dval = dval + v
							}

						}
					}
					if ('this.chartPivot) {
						Set base = this.getPlotY(dval,yAxisNo) - this.%plotTop
					}
					else {
						Set base = this.getPlotX(dval) - this.%plotLeft
					}
					Set val = val + dval
				}

				Set bar = ##class(node).%New()
				do bar.createElementSVG("rect")
				do bar.setAttribute("class","chart-seriesBar")
				if (is3D) {
					Set edgeSide = ##class(node).%New()
					do edgeSide.createElementSVG("path")
					do edgeSide.setAttribute("fill","#404040")
					do edgeSide.setAttribute("stroke","none")
					do edgeSide.setAttribute("id",..makeId("edgeSide n="_n_" s="_s))

					Set edgeSide2 = ##class(node).%New()
					do edgeSide2.createElementSVG("path")
					do edgeSide2.setAttribute("class","chart-seriesBar")
					do edgeSide2.setAttribute("fill",color)
					do edgeSide2.setAttribute("fill-opacity","0.5")
					do edgeSide2.setAttribute("stroke","#404040")
					do edgeSide2.setAttribute("id",..makeId("edgeSide2 n="_n_" s="_s))

					Set edgeTop = ##class(node).%New()
					do edgeTop.createElementSVG("path")
					do edgeTop.setAttribute("class","chart-seriesBar")
					do edgeTop.setAttribute("fill",color)
					do edgeTop.setAttribute("stroke","#404040")
					do edgeTop.setAttribute("id",..makeId("edgeTop n="_n_" s="_s))

					if ('this.chartPivot) {
						if ('this.chartStacked) {
							Set node = ""
							if (s>0) {
								Set node = this.%edgeArray.GetAt(n+1)
							}
							if ("" = node) {
								do groupEdge.appendChild(edgeSide)
								do groupEdge.appendChild(edgeSide2)
								do groupEdge.appendChild(edgeTop)
							}
							else {
								Set found=groupEdge.insertBefore(edgeSide2,node)
								;if found=0 w ^goobar
								Set found=groupEdge.insertBefore(edgeSide,edgeSide2)
								;if found=0 w ^goobar
								Set found=groupEdge.insertBefore(edgeTop,edgeSide)
								;if found=0 w ^goobar
							}
							if (0 = s) {
								do this.%edgeArray.SetAt(edgeTop,n+1) 
							}
						}
						else {
							do groupEdge.appendChild(edgeSide)
							do groupEdge.appendChild(edgeSide2)
							do groupEdge.appendChild(edgeTop)
						}
					}
					else {
						if ('this.chartStacked) {
							set found=groupEdge.insertBefore(edgeSide2,$s(this.%edgeArray.GetAt(n+1)'="":this.%edgeArray.GetAt(n+1),1:groupEdge.firstChild()))
							set found=groupEdge.insertBefore(edgeSide,edgeSide2)
							;if found=0 w ^goobar
							set found=groupEdge.insertBefore(edgeTop,edgeSide)
							;if found=0 w ^goobar
							do this.%edgeArray.SetAt(edgeTop,n+1)
						}
						else {
							do groupEdge.insertBefore(edgeSide2,$s(this.%edgeArray.GetAt(n+1)'="":this.%edgeArray.GetAt(n+1), 1:groupEdge.firstChild()))
							do groupEdge.insertBefore(edgeSide,edgeSide2)
							if (s = barSeriesCount-1) {							
								do groupEdge.insertBefore(edgeTop,edgeSide)
								do this.%edgeArray.SetAt(edgeTop,n+1)
							}
							else {
								do this.%edgeArray.SetAt(edgeSide,n+1)
							}
						}
					}
				}

				if ('this.chartPivot) {
					Set x = x + dx
					Set y = this.getPlotY(val,yAxisNo) - this.%plotTop
					// JMD1100
					if (this.isTimeBased()) {
						Set time = this.getXLabelText(n)
						Set x = this.getTimeX(time)
						Set x = $s(x="" : 0, 1 : x)
					}					
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
					Set y = y + dy
					Set x = this.getPlotX(val) - this.%plotLeft

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
						do edgeSide.setAttribute("d","M "_((left-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" L "_(left*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid)*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" z")
						do edgeSide2.setAttribute("d","M "_((left-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" L "_(left*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid)*scaleX)_" "_((y-adj+shift)*scaleY)_" "_((left+wid-adj3D)*scaleX)_" "_((y-adj+shift+adj3D)*scaleY)_" z")
					}
				}

				do bar.setAttribute("fill",color)
				do group.appendChild(bar)

				if (this.valueLabelsVisible) {
					// value label for bar
					Set fSz = 10
					Set align = "middle"
					Set lval = $s('$D(data(s)) : "" , 1: $s(('$g(data(s,n))="") : "", 1 : $$$PARSEFLOAT(data(s,n))))
					// TBD - JMD959 below with %FormatNumber
					;Set value = $fnumber(lval,",",0)
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

					// JMD1125 backing rect for value box
					SEt box = ##class(node).newElementSVG("rect") 
					do box.setAttribute("class","chart-valueLabelBox")
					do box.setAttribute("style",this.valueBoxStyle)
					do valueGroup.appendChild(box)
					
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
				}	

				do bar.setAttribute("style",this.plotStyle)
				if (is3D) {
					do edgeTop.setAttribute("style",this.plotStyle)
					do edgeSide2.setAttribute("style",this.plotStyle)
				}

			}
		}
		// JMD1100 (2) target bars and lines go last
		for s = 0:1:scount-1 {
			if ($LI(plotType,s+1)="target") {
				do this.plotTargetForSeries(group,s,.data)
			}
			elseif ($LI(plotType,s+1)="line") {
				Set filled = 0
				Set hasEvents = 1
				Set hasMarkers = this.markersVisible
				Set stacked = 0
				do this.plotLineForSeries(group,s,.data,stacked,filled,hasMarkers,hasEvents)
			}
			elseif ($LI(plotType,s+1)="linked") {
				Set filled = 0
				Set hasEvents = 1
				Set hasMarkers = this.markersVisible
				Set stacked = 0
				do this.plotLinkedLineForSeries(group,s,.data,stacked,filled,hasMarkers,hasEvents)
			}
		}
		
	}

	if (this.valueLabelsVisible) {
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
	quit ..chartStacked
}

/// Return the type (how a series should be displayed) for the given data series (0-based).
/// Overridden in combo chart.
Method getSeriesType(series)
{
	quit "bar"
}

/// Indicates that this chart supports "show multiples" mode.
Method hasMultiples()
{
	quit ..showMultiples
}

/// Plot a set of target lines based on the given data series.
Method plotTargetForSeries(group, sno, data)
{
	Set this=##this
	Set items = this.getSeriesSize()
	Set is3D = this.is3D()
	Set adj3D = $s(is3D : 3, 1: 0)

	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)

	if (items > 0) {
		if ('this.chartPivot) {
			Set barwid = 0.9 * (this.%plotWidth / items)
		}
		else {
			Set barhgt = 0.9 * (this.%plotHeight / items)
		}

		Set color = this.getSeriesColor(sno)

		// find yAxis for this series
		Set yAxisNo = $LI(this.%yAxisForSeries,sno+1)

		if ('this.chartPivot) {
			// normal orientation
			Set dx = this.%plotWidth / items
			Set adj = (dx/2)
			Set x = 0
			Set base = 0
			Set shift = -(barwid)/2

			if ($$$ISNAN($$$PARSEFLOAT($LG(this.%yBaseValue,yAxisNo+1)))) {
				Set base = this.%plotHeight
			}
			else {
				Set base = this.getPlotY($LG(this.%yBaseValue,yAxisNo+1)) - this.%plotTop
			}
		}
		else {
			// pivotted
			Set dy = this.%plotHeight / items
			Set adj = (dy/2)
			Set y = 0
			Set base = 0
			Set shift = -(barhgt)/2

			if ($$$ISNAN($$$PARSEFLOAT(this.%xBaseValue))) {
				Set base = 0
			}
			else {
				Set base = this.getPlotX(this.%xBaseValue) - this.%plotLeft
			}
		}

		// loop over items in series
		for n = 0:1:items-1 {
			Set val = $s(('$D(data(sno))) : 0, 1 : $s('$D(data(sno,n)) : 0, 1 : $$$PARSEFLOAT(data(sno,n))))
			Set val = $s($$$ISNAN(val) : 0, 1 : val)

			Set bar = ##class(node).%New()
			do bar.createElementSVG("rect")

			do bar.setAttribute("class","chart-seriesTarget")

			if ('this.chartPivot) {
				Set x = x + dx
				Set y = this.getPlotY(val,yAxisNo) - this.%plotTop

				if (this.isTimeBased()) {
					Set time = this.getXLabelText(n)
					Set x = this.getTimeX(time)
					Set x = $s(x="" : 0, 1 : x)
				}

				if (y <= base) {
					Set top = y
				}
				else {
					Set top = base
				}
				
				// 3 pixels
				Set hgt = 3/scaleY
				
				do bar.setAttribute("x",$$$ROUND((x-adj+shift-adj3D)*scaleX)+0.5)
				do bar.setAttribute("y",$$$ROUND((top+adj3D)*scaleY)+0.5)
				do bar.setAttribute("width",$$$ROUND(barwid*scaleX))
				do bar.setAttribute("height",$$$ROUND(hgt*scaleY))
			}
			else {
				Set y = y + dy
				Set x = this.getPlotX(val) - this.%plotLeft

				if (x < base) {
					Set left = base-x
				}
				else {
					Set left = x-base
				}
				// 3 pixels
				Set wid = 3/scaleX

				do bar.setAttribute("x",$$$ROUND((left-adj3D)*scaleX)+0.5)
				do bar.setAttribute("y",$$$ROUND((y-adj+shift+adj3D)*scaleY)+0.5)
				do bar.setAttribute("width",$$$ROUND(wid*scaleX))
				do bar.setAttribute("height",$$$ROUND(barhgt*scaleY))
			}

			do bar.setAttribute("fill",color)
			do group.appendChild(bar)

		}
	}
}

}
