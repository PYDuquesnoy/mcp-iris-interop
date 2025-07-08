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
Class %ZEN.Report.Display.COSChart.cbubbleChart Extends %ZEN.Report.Display.COSChart.cchart [ Deprecated, System = 4 ]
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

Property %hist As %Float [ MultiDimensional ];

Property %valueLabels As %List [ MultiDimensional ];

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
Method getXAxisType()
{
	quit "value"
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType()
{
	quit "value"
}

/// Internal method: return (as an object) the minimum
/// and maximum data values for this chart. This is used
/// for ranges that are automatically calculated.
Method findDataRange()
{
	Set this=##this
	Set range = ##class(%ZEN.Report.Display.COSChart.range).%New()
	Set range.minValue = ""
	Set range.maxValue = ""
	Set range.minValue2 = "" // used by x/y type charts
	Set range.maxValue2 = ""

	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()

	if (scount >= 2) {
		// loop over series to compute x & y range
		for s=0:1:1 {
			merge data = this.%dataSeries(s)
			Set which = $s(s=0:"x",1:"y")
			if ($D(data)) {
				for n=0:1:items-1 {
					Set val = data(n)
					if ('$$$ISNAN(val)) {
						Set val = $$$PARSEFLOAT(val)
						if (which = "y") {
							Set range.minValue = $s((""=range.minValue) : val, 1 : $s((val < range.minValue) : val, 1 : range.minValue))
							Set range.maxValue = $s((""=range.maxValue) : val, 1 : $s((val > range.maxValue) : val, 1 : range.maxValue))
						}
						else {
							Set range.minValue2 = $s((""=range.minValue2) : val, 1 : $s((val < range.minValue2) : val, 1 : range.minValue2))
							Set range.maxValue2 = $s((""=range.maxValue2) : val, 1 : $s((val > range.maxValue2) : val, 1 : range.maxValue2))
						}
					}
				}
			}
		}
	}
	quit range
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
	Set this=##this
	
	// JMD1100
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)
	Set scaleR = $s(scaleX>scaleY : scaleY, 1 : scaleX)
	
	// create series shapes
	Set (x,y,xval,yval,rval,cval,opval)=""
	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()
	Set defRadius = $$$PARSEFLOAT(this.radius)

	kill this.%hist ; multidimensional array
	Set this.%valueLabels = "" ; list

	if (items > 0) {
		merge xData = this.%dataSeries(0)
		merge yData = this.%dataSeries(1)
		merge rData = this.%dataSeries(2)
		merge cData = this.%dataSeries(3)
		merge opData = this.%dataSeries(4)
		;var cDataIndex = []; cDataIndex is an array of cData

		// find histogram of items in cData
		// sort cItems into buckets
		;this._hist = {}; hist matches properties in cData to values
		if ($D(cData)) {
			for n=0:1:items-1 {
				Set cval = $s("" = $g(cData(n)) : "", 1 : cData(n))
				if (cval '= "") {
					Set this.%hist(cval) = n
				}
			}
			Set n="" for { Set n=$o(this.%hist(n)) q:n=""
				Set $LI(this.%valueLabels,$LL(this.%valueLabels)+1) = n
				Set cDataIndex(n) = $LL(this.%valueLabels)-1
				
			}
			for n = 1:1:$LL(this.%valueLabels) {
				Set cDataIndex($LG(this.%valueLabels,n)) = n-1
			}

		}
		else {
			Set $LI(this.%valueLabels,1) = "Value"
		}

		Set rMinValue = ""
		Set rMaxValue = ""

		// find range of radius values
		if ($D(rData)) {
			for n=0:1:items-1 {
				Set val = rData(n)
				if ('$$$ISNAN(val)) {
					Set val = $$$PARSEFLOAT(val)
					Set rMinValue = $s(""=rMinValue : val, 1 : $s(val < rMinValue : val, 1 : rMinValue))
					Set rMaxValue = $s(""=rMaxValue : val, 1 : $s(val > rMaxValue : val, 1 : rMaxValue))
				}
			}
		}
		
		Set opMinValue = ""
		Set opMaxValue = ""

		// find range of opacity values
		if ($D(opData)) {
			for n = 0:1:(items-1) {
				Set val = opData(n)
				if ('$$$ISNAN(val)) {
					Set val = $$$PARSEFLOAT(val)
					Set opMinValue = $s(""=opMinValue : val, 1 : $s(val < opMinValue : val, 1 : opMinValue))
					Set opMaxValue = $s(""=opMaxValue : val, 1 : $s(val > opMaxValue : val, 1 : opMaxValue))
				}
			}
		}

		// sort items by radius; plot smaller items last
		// also find mean for x and y
		; var sortedList = []; sorted list is an array of objects in the JavaScript version
		Set itemCount = 0
		Set xTotal = 0
		Set yTotal = 0
		for n=0:1:(items-1) {
			// compute radii for items
			Set rval = $s('$D(rData) : 0, 1: $s( "" = $g(rData(n)) : 0, 1 : rData(n)))
			if ((rMinValue = "") || (rMaxValue = "")) {
				Set r = defRadius
			}
			else {
				Set rRange = rMaxValue - rMinValue
				Set r = $s(rRange=0 : defRadius, 1 : ((rval / rRange) * defRadius)+0.2)
			}
			// compute opacity for items
			Set opval = $s('$D(opData) : 0, 1: $s("" = $g(opData(n)) : 0, 1 : opData(n)))
			if opMinValue = "" || (opMaxValue = "") {
				Set op = this.opacity
			}
			else {
				Set opRange = opMaxValue - opMinValue
				Set op = $s(opRange=0 : this.opacity, 1 : ((opval / opRange) * this.opacity))
			}

			Set xval = $s('$D(xData) : "", 1: $s( "" = $g(xData(n)) : "", 1 : xData(n)))
			Set yval = $s('$D(yData) : "", 1: $s( "" = $g(yData(n)) : "", 1 : yData(n)))
			if ((xval'="") && (yval'="")) {
				Set itemCount = itemCount+1
				Set xTotal = xTotal + $$$PARSEFLOAT(xval)
				Set yTotal = yTotal + $$$PARSEFLOAT(yval)
			}
			//sortedList[n] = {index:n, r:r,x:xval,y:yval};
			Set sortedList(r,n)=$LB(xval,yval,op)
		}

		Set xMean = $s((itemCount>0) : xTotal / itemCount, 1 : 0)
		Set yMean = $s((itemCount>0) : yTotal / itemCount, 1 : 0)

		// sort by radius
		//var sortFunc = new Function('a','b','return b.r-a.r;');
		//sortedList.sort(sortFunc);

		// plot data
		// compute regression as we go
		Set sumX = 0
		Set sumXX = 0
		Set sumY = 0
		Set sumYY = 0
		Set sumXY = 0
		Set sumXM2 = 0
		Set sumYM2 = 0
		Set r="" for { Set r=$O(sortedList(r)) q:r=""
			Set n="" for { Set n=$O(sortedList(r,n)) q:n=""
				Set idx = n
				Set xval = $LI(sortedList(r,n),1)
				Set yval = $LI(sortedList(r,n),2)
				Set opacity = $LI(sortedList(r,n),3)
				if (xval="" || yval="") {
					continue
				}

				Set cval = $s('$D(cData) : "", 1 : $s("" = $g(cData(idx)) : "", 1 : cData(idx)))

				if (this.showRegression && ('$$$ISNAN($$$PARSEFLOAT(xval))) && ('$$$ISNAN($$$PARSEFLOAT(yval)))) {
					Set sumX = sumX + $$$PARSEFLOAT(xval)
					Set sumY = sumY + $$$PARSEFLOAT(yval)
					Set sumXX = sumXX + $$$PARSEFLOAT(xval*xval)
					Set sumYY = sumYY + $$$PARSEFLOAT(yval*yval)
					Set sumXY = sumXY + $$$PARSEFLOAT(xval*yval)
					Set sumXM2 = sumXM2 + (($$$PARSEFLOAT(xval) - xMean)*($$$PARSEFLOAT(xval) - xMean))
					Set sumYM2 = sumYM2 + (($$$PARSEFLOAT(yval) - yMean)*($$$PARSEFLOAT(yval) - yMean))
				}

				Set x = this.getPlotX(xval) - this.%plotLeft
				Set y = this.getPlotY(yval,this.currYAxis) - this.%plotTop

				Set cval = $s(((cval="")||('$D(cDataIndex(cval)))):0, 1:cDataIndex(cval))

				Set color = this.getSeriesColor(cval)

				Set bubble=##class(%ZEN.Report.Display.COSChart.node).%New()
				Do bubble.createElementSVG("circle")
				do bubble.setAttribute("class","chart-seriesBar")
				do bubble.setAttribute("cx",x*scaleX)
				do bubble.setAttribute("cy",y*scaleY)
				do bubble.setAttribute("r",r*scaleR)
				do bubble.setAttribute("opacity",opacity)
				do bubble.setAttribute("fill",color)
				do bubble.setAttribute("stroke","#404040")
				do bubble.setAttribute("stroke-width","0.01")
				if (r >= 0) {
					// Batik throws an exception on circles with negative radius
					do group.appendChild(bubble)
				}

				if (idx = this.selectedItem) {
					do bubble.setAttribute("style",this.plotStyle _ this.selectedItemStyle)
				}
				else {
					do bubble.setAttribute("style",this.plotStyle)
				}

			}
		}
	
	}
	Set xMin = this.%xMaxValue
	Set xMax = this.%xMinValue

	if (this.showRegression && (xMin'="") && (xMax'="") && (itemCount > 0)) {
		// stats
		Set N = itemCount

		// pearson's correlation
		Set pr = (sumXY - ((sumX*sumY)/N)) / $zsqr(((sumXX - ((sumX*sumX)/N))*(sumYY - ((sumY*sumY)/N))))

		// stddev
		Set stdX = $zsqr(sumXM2/N)
		Set stdY = $zsqr(sumYM2/N)

		// slope and y-intercept
		Set b = pr * (stdY/stdX)
		Set A = yMean - (b * xMean)

		Set yval1 = A + (b*xMin)
		Set yval2 = A + (b*xMax)

		Set y1 = this.getPlotY(yval1,this.currYAxis) - this.%plotTop
		Set y2 = this.getPlotY(yval2,this.currYAxis) - this.%plotTop

		Set x1 = this.getPlotX(xMin) - this.%plotLeft
		Set x2 = this.getPlotX(xMax) - this.%plotLeft

		Set line=##class(%ZEN.Report.Display.COSChart.node).%New()
		Do line.createElementSVG("line")
		do line.setAttribute("class","chart-seriesLine")
		do line.setAttribute("style",this.lineStyle)
		do line.setAttribute("x1",x1*scaleX)
		do line.setAttribute("y1",y1*scaleY)
		do line.setAttribute("x2",x2*scaleX)
		do line.setAttribute("y2",y2*scaleY)
		// do line.setAttribute("opacity",0.5)
		do line.setAttribute("stroke","#8080F0")
		//do line.setAttribute("stroke-width","0.25px")
		do group.appendChild(line)
	}
}

/// Return an array of labels to display within the Legend box.<br>
/// For xy chart we have to skip the first series, as it contains
/// x-values, and not a logical data series.
Method getLegendLabels() As %List
{
	Set this=##this
	Set legends = ""
	Set names = this.getSeriesNames()
	Set items = this.getSeriesSize()

	// compute labels
	merge cData = this.%dataSeries(3)
	//var cDataIndex = {};

	// find histogram of items in cData
	// sort cItems into buckets
	//this._hist = {};
	if ($D(cData)) {
		for n = 0:1:items-1 {
			Set cval = $s("" = $g(cData(n)) : "", 1 : cData(n))
			if (cval '= "") {
				Set this.%hist(cval) = n
			}
		}
		Set n="" for {  Set n=$o(this.%hist(n)) q:n=""
			Set $LI(legends,$LL(legends)+1) = n
		}
		// legends.sort(); in sorted order since n is an alphabetically ordered index
		for n = 1:1:$LL(legends) {
			Set cDataIndex($LG(legends,n)) = n
		}
	}
	else {
		Set $LI(legends,1) = $LI(names,1)
	}
	quit legends
}

/// Draw the upper/lower bands for the chart.
/// Override standard "bands" and replace with "quadrant" boxes.
Method renderBands()
{
	Set this=##this
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)
	
	Set plotAreaGroup = ..svgGroup.findSVGElement("plotAreaGroup")
	Set virtualGroup = ..svgGroup.findSVGElement("virtualGroup")

	// create quadrants
	Set qUR = ..svgGroup.findSVGElement("qUR")
	Set qLL = ..svgGroup.findSVGElement("qLL")

	if ("" = qUR) {
		
		Set qUR = ##class(%ZEN.Report.Display.COSChart.node).%New()
		Do qUR.createElementSVG("rect")
		do qUR.setAttribute("id",this.makeId("qUR"))
		do virtualGroup.appendChild(qUR)
	}
	if ("" = qLL) {
		Set qLL = ##class(%ZEN.Report.Display.COSChart.node).%New()
		Do qLL.createElementSVG("rect")

		do qLL.setAttribute("id",this.makeId("qLL"))
		do virtualGroup.appendChild(qLL)
	}

	Set xMidPoint = this.xCenterValue
	Set yMidPoint = this.yCenterValue

	Set hideUR = 'this.showQuadrant
	Set hideLL = 'this.showQuadrant
	if ($$$ISNAN($$$PARSEFLOAT(xMidPoint))) {
		Set xMidPoint = (this.%xRange/2) + this.%xMinValue
	}
	if ($$$ISNAN($$$PARSEFLOAT(yMidPoint))) {
		Set yMidPoint = ($LG(this.%yRange,1)/2) + $LG(this.%yMinValue,1)
	}
	Set h = this.getPlotY(yMidPoint,this.currYAxis) - this.%plotTop
	Set w = this.getPlotX(xMidPoint) - this.%plotLeft

	// JMD1181: hide quadrants independently
	Set h = $s((h > this.%plotHeight) : this.%plotHeight, 1 : h)
	Set w = $s((w > this.%plotWidth) : this.%plotWidth, 1 : w)

	if ((h<0)||((this.%plotWidth-w)<0)) {
		Set hideUR = 1
	}
	else {
		do qUR.setAttribute("class","chart-band")
		do qUR.setAttribute("x",w*scaleX)
		do qUR.setAttribute("y",this.%plotTop*scaleY)
		do qUR.setAttribute("width",(this.%plotWidth - w)*scaleX)
		do qUR.setAttribute("height",h*scaleY)
		do qUR.setAttribute("style","fill:#80D080;opacity:0.15;fill:#80D080;"_this.upperRightStyle)
		//do qUR.setAttribute("opacity",0.15)
	}
	if ((w<0)||((this.%plotHeight-h)<0)) {
		Set hideLL = 1
	}
	else {
		Set y = this.%plotTop + h
		if (h<0) { // JSL4359
			Set y = this.%plotTop
			Set h = 0
		}

		do qLL.setAttribute("class","chart-band")
		do qLL.setAttribute("x",0)
		do qLL.setAttribute("y",(y)*scaleY)
		do qLL.setAttribute("width",w*scaleX) // JSL4143 - width of lower quadrant wrong
		do qLL.setAttribute("height",(this.%plotHeight - h)*scaleY)
		do qLL.setAttribute("style","opacity:0.15;fill:#D08080;"_this.lowerLeftStyle)
		//do qLL.setAttribute("opacity",0.15)
	}
	if (hideUR) {
 		do qUR.setAttribute("display","none")
	}
	else {
 		do qUR.setAttribute("display","block")
	}
	if (hideLL) {
 		do qLL.setAttribute("display","none")
	}
	else {
 		do qLL.setAttribute("display","block")
	}
}

/// Override and use seriesNames only.
Method getSeriesNames() As %List
{
	Set names = ""
	Set sn = ..split(..seriesNames,",")
	for i=1:1:$LL(sn) {
		Set $LI(names,i) = $s($LG(sn,i)="" : i, 1 : $LG(sn,i))
	}
	quit names
}

/// Return the x axis title.
Method getXAxisTitle()
{
	Set this=##this
	Set title = ""
	if ($IsObject(this.xAxis) && (""'=this.xAxis.title)) {
		Set title = this.xAxis.title
	}
	else {
		Set title = "x"

	}
	quit title
}

/// Return the y axis title.
Method getYAxisTitle()
{
	Set this=##this
	Set title = ""
	Set yAxis = this.getYAxis(this.currYAxis)
	if ($isObject(yAxis) && (""'=yAxis.title)) {
		Set title = yAxis.title
	}
	else {
		Set title = "y"
	}
	quit title
}

}
