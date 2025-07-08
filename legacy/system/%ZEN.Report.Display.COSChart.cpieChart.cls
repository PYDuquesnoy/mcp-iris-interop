/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a pie chart.<br>
/// The <property>plotBy</property> property specifies how the slices of the chart and their labels
/// should be calculated.<br>
/// The size of each slice is adjusted proportionally so that a complete circle is formed.<br>
/// The colors of the slice is determined by the <property>seriesColors</property> property.
/// If there are more slices than colors, then the colors are repeated.<br>
Class %ZEN.Report.Display.COSChart.cpieChart Extends cchart [ Deprecated, System = 4 ]
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

/// Private properties
Property %circle [ Private ];

Property %slices As list Of node [ Private ];

Property %lines As list Of node [ Private ];

Property %labels As list Of node [ Private ];

Property %edges As list Of node [ Private ];

Property %innerEdges As list Of node [ Private ];

Property %shadow [ Private ];

Property %underEdge [ Private ];

Property %innerUnderEdge [ Private ];

XData SVGStyle
{
}

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

/// Return an array of labels to display within the Legend box.<br>
/// Override to get appropriate labels for Pie Chart.
Method getLegendLabels()
{
	Set this=##this
	
	Set legends = ..split(..legendLabels,",",1)  // JSL4144
	if ($LL(legends)'=0) {
		quit legends // JSL4144, most probably we have legends from DeepSee
	}

	Set legends = "" ; empty list
	
	Set sc = this.getSeriesCount()
	Set ic = this.getSeriesSize()
	if (("auto" = this.plotBy) && (ic = 1 || (sc = 1))) {
		quit legends
	}

	if this.getPlotBy()="series"|| (this.getPlotBy()="both") {
		Set names = this.getSeriesNames()
		for i = 1:1:sc {
			Set $LI(legends,i) = $s(("" = $LG(names,i) ) : i, 1 : $LI(names,i))
		}
	} else {
		for i = 1:1:ic {
			Set lbl = this.getYLabelText(i-1,"",1)
			Set $LI(legends,i) = $s(lbl="" : i, 1 : lbl)
		}
	}


	quit legends
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
	Set this=##this
	//try {
		// assemble data for plotting
		Set sc = this.getSeriesCount()
		Set ic = this.getSeriesSize()
		set items = 0
		Set values = "" ; list
		Set total = 0
		Set snames = ""
		Set plotBy = this.getPlotBy()

		// JMD1100
		Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
		Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)


		Set seriesNumber = this.seriesNumber
		if ('$$$ISNAN($$$PARSEINT(seriesNumber))) {
			Set sc = 1
		}

		// limit series if we are in small multiples mode
		if (this.showMultiples) {
			Set seriesNumber = this.currMultiple
			Set sc = 1
			Set plotBy = "items"
		}


		if plotBy="series" {
			Set items = sc
			Set snames = this.getSeriesNames()
			for s = 1:1:sc {
				merge data = this.%dataSeries($s($$$ISNAN($$$PARSEINT(seriesNumber)):s-1, 1:seriesNumber))
				Set value = 0
				for i = 1:1:ic {
					Set value = value + $s('$D(data) || ($g(data(i-1)) = "") || (data(i-1) < 0) || $$$ISNAN($$$PARSEFLOAT(data(i-1))) : 0, 1 : ($$$PARSEFLOAT(data(i-1))))
				}
				Set $LI(values,s) = value
				Set total = total + value
			}
		}
		elseif plotBy="both" {
			Set items = sc*ic
			Set snames = this.getSeriesNames() ; list
			for s = 1:1:sc {
				merge data = this.%dataSeries($s($$$ISNAN($$$PARSEINT(seriesNumber)):s-1,1:seriesNumber))
				for i = 1:1:ic {
					Set value = $s('$D(data) || ($g(data(i-1)) = "") || (data(i-1) < 0) || $$$ISNAN($$$PARSEFLOAT(data(i-1))) : 0, 1 : ($$$PARSEFLOAT(data(i-1))))
					Set $LI(values,$LL(values)+1) = value
					Set total = total + value
				}
			}
		} else { ; items or default
			Set items = ic
			for i = 1:1:ic {
				Set value = 0
				for s = 1:1:sc {
					merge data = this.%dataSeries($s($$$ISNAN($$$PARSEINT(seriesNumber)):s-1,1:seriesNumber))
					Set value = value + $s('$D(data) || ($g(data(i-1)) = "") || (data(i-1) < 0) || $$$ISNAN($$$PARSEFLOAT(data(i-1))) : 0, 1 : ($$$PARSEFLOAT(data(i-1))))
				}
				Set $LI(values,i) = value
				Set total = total + value
			}
			
			
		}
		
		// Hide labels for wedges with % smaller than this
		// the more wedges, the bigger the min size!
		Set minWedge = $s(items <= 12 : 0.01, 1 : $s(items <= 24 : 0.025, 1 : 0.05))

		
		// find size of pie (ignore margins)
		Set gw = (this.%plotWidth * 0.55)
		Set gh = (this.%plotHeight * 0.70)
		Set sz = $s((gw > gh) : gh/2, 1 : gw/2)
		Set cx = this.%plotWidth / 2
		Set cy = this.%plotHeight / 2
		Set sz = sz * $$$PARSEFLOAT(this.pieScale)

		Set hs = $$$PARSEFLOAT(this.holeSize)
		Set hs = $s((hs < 0) : 0, 1 : $s((hs > 0.9) : 0.9, 1 : hs))
		Set hole = sz * hs

		// 3d info
		Set xRadius =  sz
		Set yRadius =  sz / 1.8
		Set xHoleRadius =  hole
		Set yHoleRadius =  hole / 1.8
		Set ph = $$$PARSEFLOAT(this.pieHeight)
		Set ph = $s((ph < 0) : 0, 1 : $s((ph > 1) : 1, 1 : ph))
		Set pieHeight = ($$$ROUND(sz * ph *1000)/1000)
		Set is3D = ("3D" = this.appearance)
		Set seriesGroup = this.getSeriesSVGGroup()
		
		// JMD1100 make pie round if not 3D
		if (is3D) {
			Set scaleRX = scaleX
			Set scaleRY = scaleY
		}
		else {
			if (scaleX > scaleY) {
				Set scaleRX = scaleY
				Set scaleRY = scaleY
			}
			else {
				Set scaleRX = scaleX
				Set scaleRY = scaleX
			}
		}		

		// if number of slices has changed, clear out the old slices
		if ((0 = total) || ("" = seriesGroup) || ("" = seriesGroup.firstChild()) || (items = 0) || ((this.%slices.Size'=0) && (items '= this.%slices.Size))) {
			// remove SVG elements within our group.
			do group.clearChildren()
			Set this.%circle = ""
			Set this.%slices = ""
			;Set this.%lines= "" JMD1178 deletes these
			;Set this.%labels= ""
			Set this.%edges= ""
			Set this.%innerEdges= ""
			Set this.%shadow= ""
			Set this.%underEdge= ""
			Set this.%innerUnderEdge= ""
		}

		if (0 = total) {
			// nothing to show
			Set circ = this.%circle
			if ("" = circ) {
				Set circ=##class(node).%New()
				do circ.createElementSVG("circle")
				Set this.%circle = circ
				do group.appendChild(circ)
			}
			do circ.setAttribute("cx",cx*scaleX)
			do circ.setAttribute("cy",cy*scaleY)
			//do circ.setAttribute("r",sz)
			do circ.setAttribute("rx",sz*scaleRX)
			do circ.setAttribute("ry",sz*scaleRY)
			do circ.setAttribute("style","stroke: none; fill: darkblue; opacity: 0.1;")
			quit
		}

		// create new slices & labels
		if (("" = seriesGroup) || 
			("" = seriesGroup.firstChild()) || 
			((this.%slices.Size=0) && (items > 0))) {
			;s t=$io u 0 w !,"create new slices and labels items="_items u t
			;if (null==this.%slices) { this.%slices = new Array(items); }
			;if (null==this.%lines) { this.%lines = new Array(items); }
			;if (null==this.%labels) { this.%labels = new Array(items); }
			;if (null==this.%edges) { this.%edges = new Array(items); }
			;if (null==this.%innerEdges) { this.%innerEdges = new Array(items); }
	
			// circle in the middle
			if ('is3D) {
				Set circ = this.%circle
				if ("" = circ) {
					Set circ=##class(node).%New()
					do circ.createElementSVG("ellipse")
					Set this.%circle = circ
					do group.appendChild(circ)
				}
				do circ.setAttribute("cx",cx*scaleX)
				do circ.setAttribute("cy",cy*scaleY)
				do circ.setAttribute("rx",sz*scaleRX)
				do circ.setAttribute("ry",sz*scaleRY)
					if (hole > 0) {
					do circ.setAttribute("display","none")
				}
				do circ.setAttribute("style","stroke: none; fill: darkblue; opacity: 1.0;")
			}
			else {
				// shadow and under edge
				Set shadow = this.%shadow
				if ("" = shadow) {
					Set shadow=##class(node).%New()
					do shadow.createElementSVG("ellipse")
					Set this.%shadow = shadow
					do group.appendChild(shadow)
				}
				do shadow.setAttribute("cx",(cx + (xRadius / 20))*scaleX)
				do shadow.setAttribute("cy",(cy + pieHeight + (yRadius / 20))*scaleY)
				do shadow.setAttribute("rx",xRadius*scaleRX)
				do shadow.setAttribute("ry",yRadius*scaleRY)
				do shadow.setAttribute("style","stroke: none; fill: black; opacity: 0.5;")

				Set edge = this.%underEdge
				if ("" = edge) {
					Set edge = ##class(node).%New()
					do edge.createElementSVG("path")
					Set this.%underEdge = edge
					do group.appendChild(edge)
				}
				Set X1 = cx + (xRadius * 1)
				Set Y1 = cy + (yRadius * 0)
				Set X2 = cx + (xRadius * -1)
				Set Y2 = cy + (yRadius * 0)
				do edge.setAttribute("d","M " _ (X1*scaleX) _ " " _ (Y1*scaleY) _ " A " _ (xRadius*scaleX) _ " " _ (yRadius*scaleY) _ " 0 0 1 " _ (X2*scaleX) _ " " _ (Y2*scaleY) _ " v " _ (pieHeight*scaleY) _ " "  _  "A " _ (xRadius*scaleX) _ " " _ (yRadius*scaleY) _ " 0 0 0 " _ (X1*scaleX) _ " " _  ((Y1+pieHeight)*scaleY) _  " z") ; ' +
				//do edge.setAttribute("d","M "_X1_" "_Y1_" A "_xRadius_" "_yRadius_" 0 0 1 "_X2_" "_Y2_" v "_pieHeight_" " _ "A "_xRadius_" "_yRadius_" 0 0 0 "_X1_" "_ (Y1+pieHeight)_ " z")
				do edge.setAttribute("style","stroke: none; fill: black; opacity: 1.0;")

				Set edge = this.%innerUnderEdge
				if ("" = edge) {
					Set edge=##class(node).%New()
					do edge.createElementSVG("path")
					Set this.%innerUnderEdge = edge
				}
				Set X1 = cx + (xHoleRadius * -1)
				Set Y1 = cy + (yHoleRadius * 0)
				Set X2 = cx + (xHoleRadius * 1)
				Set Y2 = cy + (yHoleRadius * 0)
				do edge.setAttribute("d","M "_(X1*scaleX)_" "_(Y1*scaleY)_" A "_(xHoleRadius*scaleX)_" "_(yHoleRadius*scaleY)_" 0 0 1 "_(X2*scaleX)_" "_(Y2*scaleY)_" v "_(pieHeight*scaleY)_" " _ "A "_(xHoleRadius*scaleX)_" "_(yHoleRadius*scaleY)_" 0 0 0 "_(X1*scaleX)_" "_ ((Y1+pieHeight)*scaleY)_ " z") ; ' +
				do edge.setAttribute("style","stroke: none; fill: black; opacity: 1.0;")
			}

			// slices
			for i = 1:1:items {
				if ("" = this.%slices.GetAt(i)) {
					Set tSlice = ##class(node).%New()
					do this.%slices.SetAt(tSlice,i)
					do tSlice.createElementSVG("path")
					Set tSlice.%index = i
					do group.appendChild(tSlice)
				}
			}
			// edges
			if (is3D) {
				for i = 1:1:items {
					if ("" = this.%edges.GetAt(i)) {
						Set tEdge=##class(node).%New()
						do this.%edges.SetAt(tEdge,i)
						do tEdge.createElementSVG("path")
						do group.appendChild(tEdge)
					}
					if (hole > 0) {
						if ("" = this.%innerEdges.GetAt(i)) {
							Set tInnerEdge=##class(node).%New()
							do this.%innerEdges.SetAt(tInnerEdge,i)
							do tInnerEdge.createElementSVG("path")
							do group.insertBefore(this.%innerEdges.GetAt(i),group.firstChild())
						}
						if (i >= (items)) {
							do group.insertBefore(this.%innerUnderEdge,group.firstChild())
						}
					}
				}
			}
			// JMD1178: move label creation to main loop
		}
		// compute size of slices

		// now set the position of all slices for this series
		Set last = $s(($$$ISNAN($$$PARSEFLOAT(this.rotateBy))) : 0, 1 : ($$$PARSEFLOAT(this.rotateBy)/360))
		Set lastcurr = 0
		Set lasty2 = 0
		Set lastx = 0
		Set lastth = 0
		Set pct = "" ; list
		
		Set ts = ""
		Set ts = $s(("large" = this.textSize) : "font-size:3pt;", 1 : ts)
		Set ts = $s(("small" = this.textSize) : "font-size:1.8pt;", 1 : ts)

		for i = 1:1:items {
			Set clr = this.getSeriesColor($s(("both" '= plotBy) : (i-1), 1 : $$$FLOOR((i-1)/ic)))
			Set value = $LG(values,i)
			Set curr = $s((total = 0) : 0, 1 : (value / total))
			Set $LI(pct,i) = $$$ROUND(curr * 100)
			Set slice = this.%slices.GetAt(i)
			Set edge = $s(is3D : this.%edges.GetAt(i), 1 : "")
			Set innerEdge = $s(is3D : this.%innerEdges.GetAt(i), 1 : "")
			if (curr >=1) {
				// don"t draw a complete circle
				Set curr=0.99999
				Set $LI(pct,i) = 100
			}

			// find series and item #s
			if (plotBy="series") {
				Set sno = i - 1
				Set ino = 0
			} elseif (plotBy="both") {
				Set sno = $$$FLOOR((i - 1)/ic)
				Set ino = (i - 1) # ic
			} else { ; items or default
				Set sno = 0
				Set ino = i - 1
				
			}

			if ('is3D) {
				Set path = ""
				if (hole <= 0) {
				 	Set path = path _ "M 0 0 L "
				}
				else {
					Set path = path_ "M " _ ((hole * $zcos(last * $ZPI * 2))*scaleRX) _ " " _ ((hole * $zsin(last * $ZPI * 2))*scaleRY) _ " L "
				}
				Set path = path_ (sz * $zcos(last * $ZPI * 2)*scaleRX) _ " " _ (sz * $zsin(last * $ZPI * 2)*scaleRY)
				if (curr >= 0.5) {
					Set path = path _ " A" _ (sz*scaleRX) _ " " _ (sz*scaleRY) _ " 0 1 1 " _ ((sz * $zcos((last + curr) * $ZPI * 2))*scaleRX) _ " " _ (sz * $zsin((last + curr) * $ZPI * 2)*scaleRY)
				}
				else {
					Set path = path _ " A" _ (sz*scaleRX) _ " " _ (sz*scaleRY) _ " 0 0 1 " _ ((sz * $zcos((last + curr) * $ZPI * 2))*scaleRX) _ " " _ ((sz * $zsin((last + curr) * $ZPI * 2)*scaleRY))
				}
				if (hole <= 0) {
					Set path = path _ " z"
				}
				else {
					Set path = path _ "L " _ (hole * $zcos((last+curr) * $ZPI * 2)*scaleRX) _ " " _ (hole * $zsin((last+curr) * $ZPI * 2)*scaleRY)
					if (curr >= 0.5) {
						Set path = path _ " A" _ (hole*scaleRX) _ " " _ (hole*scaleRY) _ " 0 1 0 " _ (hole * $zcos(last * $ZPI * 2)*scaleRX) _ " " _ (hole * $zsin(last * $ZPI * 2)*scaleRY)
					}
					else {
						Set path = path _ " A" _ (hole*scaleRX) _ " " _ (hole*scaleRY) _ " 0 0 0 " _ ((hole * $zcos(last * $ZPI * 2))*scaleRX) _ " " _ ((hole * $zsin(last * $ZPI * 2)*scaleRY))
					}
					Set path = path _ " z"
				}
			}
			else {
				Set startAngle = (360 * last) # 360
				Set endAngle = startAngle + (curr * 360)
				// round off to avoid ie math bugs!
				Set startAngle = ($$$ROUND(startAngle*1000)/1000)
				Set endAngle = ($$$ROUND(endAngle*1000)/1000)

				Set edgeStartAngle = $s((startAngle < 0) : 0, 1 : startAngle)
				Set edgeEndAngle = endAngle
				Set innerEdgeStartAngle = $s((startAngle < 180) : 180, 1 : startAngle)
				Set innerEdgeEndAngle = $s((endAngle > 360) : 360, 1 : endAngle)

				if ((value > 0) && (edgeStartAngle < 180) || (edgeEndAngle > 360)) {
					// visible
					if ((edgeStartAngle > 180) && (edgeEndAngle > 360)) {
						Set edgeStartAngle = 0
						Set edgeEndAngle = edgeEndAngle # 360
					}
					Set edgeEndAngle = $s((edgeEndAngle > 180) : 180, 1 : edgeEndAngle)

					Set startRad = edgeStartAngle * ($ZPI / 180)
					Set endRad = edgeEndAngle  * ($ZPI / 180)
					Set X1 = cx + (xRadius * $zcos(startRad))
					Set Y1 = cy + (yRadius * $zsin(startRad))
					Set X2 = cx + (xRadius * $zcos(endRad))
					Set Y2 = cy + (yRadius * $zsin(endRad))
					Set X1 = ($$$ROUND(X1*1000)/1000)
					Set Y1 = ($$$ROUND(Y1*1000)/1000)
					Set X2 = ($$$ROUND(X2*1000)/1000)
					Set Y2 = ($$$ROUND(Y2*1000)/1000)

					do edge.setAttribute("visibility","visible")
					Set edgeOp = 0.1 + (edgeEndAngle/ 180)
					Set edgeOp = $s((edgeOp > 1) : 1, 1 : edgeOp)
					do edge.setAttribute("opacity",edgeOp)
					if (X1'=X2||(Y1'=Y2)) {
						do edge.setAttribute("d","M "_(X1*scaleX)_" "_(Y1*scaleY)_" A "_($$$ROUND(xRadius*1000*scaleX)/1000)_" "_($$$ROUND(yRadius*1000*scaleY)/1000)_" 0 0 1 "_(X2*scaleX)_" "_(Y2*scaleY)_" v "_(pieHeight*scaleY)_" " _ "A "_($$$ROUND(xRadius*scaleX*1000)/1000)_" "_($$$ROUND(yRadius*scaleY*1000)/1000)_" 0 0 0 "_(X1*scaleX)_" "_((Y1+pieHeight)*scaleY)_ " z")
					}
					else {
						do edge.setAttribute("visibility","hidden")
					}
				}
				else {
					do edge.setAttribute("visibility","hidden")
				}
			
				// inner edge
				if ((hole > 0) && (innerEdge'="")) {
					if (innerEdgeStartAngle < innerEdgeEndAngle) {
						Set startRad = innerEdgeStartAngle * ($ZPI / 180)
						Set endRad = innerEdgeEndAngle  * ($ZPI / 180)
						Set X1 = cx + (xHoleRadius * $zcos(startRad))
						Set Y1 = cy + (yHoleRadius * $zsin(startRad))
						Set X2 = cx + (xHoleRadius * $zcos(endRad))
						Set Y2 = cy + (yHoleRadius * $zsin(endRad))

						do innerEdge.setAttribute("visibility","visible")
						do innerEdge.setAttribute("opacity",0.9)
						do innerEdge.setAttribute("d","M "_(X1*scaleX)_" "_(Y1*scaleY)_" A "_(xHoleRadius*scaleX)_" "_(yHoleRadius*scaleY)_" 0 0 1 "_(X2*scaleX)_" "_(Y2*scaleY)_" v "_(pieHeight*scaleY)_" " _ "A "_(xHoleRadius*scaleX)_" "_(yHoleRadius*scaleY)_" 0 0 0 "_(X1*scaleX)_" "_((Y1+pieHeight)*scaleY)_ " z")
					}
					else {
						do innerEdge.setAttribute("visibility","hidden")
					}
				}

				// wedge
				Set startRad = startAngle * ($ZPI / 180)
				Set endRad = endAngle * ($ZPI / 180)
				if (hole > 0) {
					Set hX1 = cx + (xHoleRadius * $zcos(startRad))
					Set hY1 = cy + (yHoleRadius * $zsin(startRad))
					Set hX2 = cx + (xHoleRadius * $zcos(endRad))
					Set hY2 = cy + (yHoleRadius * $zsin(endRad))
					Set hX1 = ($$$ROUND(hX1*1000)/1000)
					Set hY1 = ($$$ROUND(hY1*1000)/1000)
					Set hX2 = ($$$ROUND(hX2*1000)/1000)
					Set hY2 = ($$$ROUND(hY2*1000)/1000)
				}
				Set X1 = cx + (xRadius * $zcos(startRad))
				Set Y1 = cy + (yRadius * $zsin(startRad))
				Set X2 = cx + (xRadius * $zcos(endRad))
				Set Y2 = cy + (yRadius * $zsin(endRad))
				Set X1 = ($$$ROUND(X1*1000)/1000)
				Set Y1 = ($$$ROUND(Y1*1000)/1000)
				Set X2 = ($$$ROUND(X2*1000)/1000)
				Set Y2 = ($$$ROUND(Y2*1000)/1000)

				Set dir = $s(((endAngle-startAngle) > 180) : 1, 1 : 0)
				if (hole > 0) {
					Set path = "M "_(hX1*scaleX)_" "_(hY1*scaleY)
				}
				else {
					Set path = "M "_(cx*scaleX)_" "_(cy*scaleY)
				}
				Set path = path _ "L "_(X1*scaleX)_" "_(Y1*scaleY)_" "
				if (X1'=X2||(Y1'=Y2)) {
					Set path = path_ "A "_(xRadius*scaleX)_" "_(yRadius*scaleY)_" 0 "_dir_" 1 "_(X2*scaleX)_" "_(Y2*scaleY)
				}
				if (hole > 0) {
					if (hX1'=hX2||(hY1'=hY2)) {
						Set path = path _ "L "_(hX2*scaleX)_" "_(hY2*scaleY)
						Set path = path _ " A "_(xHoleRadius*scaleX)_" "_(yHoleRadius*scaleY)_" 0 "_dir_" 0 "_(hX1*scaleX)_" "_(hY1*scaleY)
					}
				}
				Set path = path _ "z"
			}
			Set style = this.getChartElementStyle(sno,ino)
			do slice.setAttribute("d",path)
			if ('is3D) {
				do slice.setAttribute("transform","translate(" _ (cx*scaleX) _ "," _ (cy*scaleY) _ ")")
			}
	
			// see if we are the selected item
			if ((sno = this.selectedSeries) && (ino = this.selectedItem)) {
				do slice.setAttribute("style",style _ this.selectedItemStyle)
				if (edge'="") {
					do edge.setAttribute("style",style _ this.selectedItemStyle)
				}
				if (innerEdge'="") {
					do innerEdge.setAttribute("style",style _ this.selectedItemStyle)
				}
			}
			else {
				do slice.setAttribute("style",style)
				if (edge'="") {
 					do edge.setAttribute("style",style)
				}
				if (innerEdge'="") {
					do innerEdge.setAttribute("style",style)
				}
			}
			
			if (this.showMultiples) {
				Set rsno = this.currMultiple
			} else {
				Set rsno = $s($$$ISNAN($$$PARSEINT(seriesNumber)) : sno, 1 : this.seriesNumber)				
			}
			Set rsno = $s(""=rsno : 0, 1 : rsno)
			if (edge'="") {
				do edge.setAttribute("id",this.makeId("edge_"_this.currMultiple _ rsno _ "_" _ ino))
			}
			if (innerEdge'="") {
				do innerEdge.setAttribute("id",this.makeId("inedge_"_this.currMultiple _ rsno _ "_" _ ino))
			}

			// JMD1178: create labels as needed
			// n.b. if showPercentage is on but labels are not visible, then show % only
			// same goes for showValue
			if (this.labelsVisible || this.showPercentage || this.showValue) {
				Set sin = $zsin((last + (curr/2)) * $zpi * 2)
				Set cos = $zcos((last + (curr/2)) * $zpi * 2)

				// n.b tx/y are in *pixels*
				Set labelRadius = $$$PARSEFLOAT(this.labelRadius)
				Set labelRadius = $s($$$ISNAN(labelRadius) : 1.1, 1 : labelRadius)
				Set ladj = 1
				if (is3D) {
					Set ladj = $s(sin>=0 : 1, 1 : 0.6)
				}
				Set tx = cx*scaleX + (sz*labelRadius * cos * scaleRX)
				Set ty = cy*scaleY + (sz*labelRadius * sin * scaleRY * ladj)
				Set anchor = $s(cos>=0 : "start", 1 : "end")

				// box under label
				Set box = ##class(node).newElementSVG("rect")
				do box.setAttribute("class","chart-valueLabelBox")
				do box.setAttribute("style",this.valueBoxStyle)

				do group.appendChild(box)
				;var f = new Function('evt','series','item','return zenPage.getComponent('+this.index+').chartElementClickHandler(evt,'+rsno+','+ino+');');
				;box.addEventListener('click',f,false);
					
				Set text = ##class(node).newElementSVG("text")
				do group.appendChild(text)

				do text.setAttribute("x", tx)
				do text.setAttribute("y", ty)
				do text.setAttribute("class","chart-sliceLabel")
				do text.setAttribute("style",this.labelStyle)
				do text.setAttribute("text-anchor",anchor)
				;text.addEventListener('click',f,false);

				// get label text
				Set lbl = ""
				if ('this.labelsVisible) {
					Set lbl = ""
				}
				else {
					// Prodlog 109080
					if (plotBy="series") {
						Set lbl = $LG(snames,i)
						Set lbl = $s("" = lbl : ($$$PARSEINT(i-1)+1), 1 : lbl)
						
					} elseif (plotBy = "both") {
						Set idx = $$$FLOOR((i-1)/ic)
						Set lbl = this.getYLabelText((i-1) # ic)
						Set lbl = $s("" = lbl : ($$$PARSEINT(i-1)+1), 1 : lbl)

					} else {
						Set lbl = this.getYLabelText(i-1)
						Set lbl = $s("" = lbl : ($$$PARSEINT(i-1)+1), 1 : lbl)
						
					}
				}
				if (this.showValue) {
					Set lval = $LG(values,i)
					if ('$$$ISNAN($$$PARSEFLOAT(lval))) {
						Set format = this.valueLabelFormat
						Set format = $s(format : format, 1 : $s(($$$FLOOR(lval)'=lval):"#,#.##",1:"#,#"))
						;lval = zenFormatNumber(lval,format);
						Set lval = ##class(%DeepSee.ResultSet).%FormatNumber(lval,format)
						Set lbl = lbl _ $s(lbl="":"",1:" ") _ lval
					}
				}
				if (this.showPercentage) {
					if (lbl="") {
						Set lbl = lbl _ $LI(pct,i) _ "%"
					}
					else {
						Set lbl = lbl _ " (" _ $LI(pct,i) _ "%)"
					}
				}

				;var textNode = this.document.createTextNode(lbl);
				;text.appendChild(textNode);
				do text.setText(lbl)
				// use pixels
				Set th = ..GetBBox(text).height
				Set tw = ..GetBBox(text).width
					
				do box.setAttribute("rx",3)
				if (anchor="start") {
					do box.setAttribute("x",(tx)-3)
				}
				else {
					do box.setAttribute("x",((tx-tw))-3)
				}
				do box.setAttribute("y",(ty-(th*(1/1.1))))
				do box.setAttribute("width",(tw)+6)
				do box.setAttribute("height",(th*1.13))
			}

			// remember (normalized) angle of this wedge
			Set slice.%angle = (360 * ((last + (curr/2)) - $s(($$$ISNAN($$$PARSEFLOAT(this.rotateBy))) : 0, 1 : ($$$PARSEFLOAT(this.rotateBy)/360))) # 360)
			// move to next slot
			Set last = last + curr
			Set lastcurr = curr
		}
	//}
	//catch(ex) {
		;zenExceptionHandler(ex,arguments,'Error in pieChart.renderSeries');
	//}
}

/// Determine the actual plot by method for this chart.
Method getPlotBy()
{
	Set this=##this
	Set plotBy = this.plotBy
	if ("auto" = plotBy) {
		Set sc = this.getSeriesCount()
		Set ic = this.getSeriesSize()
		if ((sc > 1) && (ic > 1)) {
			Set plotBy = "both"
		}
		elseif ((sc = 1) && (ic = 1)) {
			Set plotBy = "both"
		}
		elseif (sc <= 1) {
			Set plotBy = "items"
		}
		else {
			Set plotBy = "series"
		}
	}
	quit plotBy
}

/// Return default style for slice element.
Method getChartElementStyle(series, item)
{
	Set this=##this
	Set op = "1.0"

	Set plotBy = this.getPlotBy()
	if (this.showMultiples) {
		Set plotBy = "items"
	}

	if (plotBy= "both") {
		// use same color for items in series but alternate intensity.
		Set clr = this.getSeriesColor(series)
		Set op = $s((item#2) : "1.0", 1 : "0.85")
	} elseif (plotBy= "series") {
		// use same color for items in series but alternate intensity.
		Set clr = this.getSeriesColor(series)
	} else { //items or default
		Set clr = this.getSeriesColor(item)
	}
	quit "stroke-width: 0.25px; fill-opacity: "_op_"; stroke: " _ "gray" _ "; fill: " _ clr _ ";" _ this.plotStyle
}

/// Indicates that this chart supports "show multiples" mode.
Method hasMultiples()
{
	Set this=##this
	quit this.showMultiples
}

}
