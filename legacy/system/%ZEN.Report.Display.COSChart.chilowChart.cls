/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.chilowChart Extends cchart [ Deprecated, System = 4 ]
{

/// This is an SVG <class>chart</class> component that displays a hi-low-close chart.<br>
/// This chart displays three data series as a set of rectangles: the top of each rectangle
/// represents the high value; the bottom, the low value; a marker is drawn for
/// the closing value.<br>
/// The three data series are interpreted as:
/// <ul>
/// <li>First series: set of high values.</li>
/// <li>Second series: set of low values. Each low value is assumed to be smaller than 
/// its corresponding high value.</li>
/// <li>Third series: set of optional closing values. Each closing value is assumed to between
/// its corresponding high and low values.</li>
/// </ul>
/// You can view pivot the chart using the <property>chartPivot</property> property.<br>
/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for bars where the high value is less than the low value.
Property invertedBarStyle As %ZEN.Datatype.svgStyle;

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
	Set this=##this
	// create series shapes

	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()

	// we only care about 3 series at most
	Set scount = $s((scount > 3) : 3, 1 : scount)

	// see if there is a selected element
	Set hasSelect = this.hasSelectedItem()

	// JMD1100
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)

	if (items > 0) {
		// first get data for all series
		for s = 0:1:(scount-1) {
			Set data(s+1) = this.getSeriesData(s) ; multidimensional array of lists
		}

		Set color = this.getSeriesColor(0)
		Set x = 0
		Set y = 0
		if ('this.chartPivot) {
			if (this.plotToEdge) {
				Set delta = $s((items<=1) : this.%plotWidth, 1 : (this.%plotWidth / (items-1)))
				Set adj = delta
			}
			else {
				Set delta = this.%plotWidth / items
				Set adj = (delta/2)
			}

			// JMD1100: bar size does not depend on number of series
			Set barsize = (0.25) * (this.%plotHeight / items)

		}
		else {
			if (this.plotToEdge) {
				Set delta = $s((items<=1) : this.%plotHeight, 1 : (this.%plotHeight / (items-1)))
				Set adj = delta
			}
			else {
				Set delta = this.%plotHeight / items
				Set adj = (delta/2)
			}
			// JMD1100: bar size does not depend on number of series
			Set barsize = (0.25) * (this.%plotHeight / items)

		}
		Set shift = -barsize/2

		// loop over items
		for n = 1:1:items {
			Set hi = $s(('$D(data(1))) : 0 , 1: $s(("" = $LG(data(1),n)) : 0, 1 : $$$PARSEFLOAT($LG(data(1),n))))
			Set low = $s(('$D(data(2))) : 0 , 1: $s(("" = $LG(data(2),n)) : 0, 1 : $$$PARSEFLOAT($LG(data(2),n))))
			Set close = $s(('$D(data(3))) : 0 , 1: $s(("" = $LG(data(3),n)) : 0, 1 : $$$PARSEFLOAT($LG(data(3),n))))

			// create shapes
			Set bar=##class(node).%New()
			do bar.createElementSVG("rect")
			do bar.setAttribute("class","chart-seriesBar")
			do bar.setAttribute("fill",color)
			Set barStyle = ""
			do group.appendChild(bar)

			// close marker
			Set marker = ""
			if (scount > 2) {
				Set marker=##class(node).%New()
				do marker.createElementSVG("polyline")
				do marker.setAttribute("class","chart-seriesBar")
				do marker.setAttribute("style",this.plotStyle _ ";fill:"_color_";")
				do marker.setAttribute("fill",color)
				do group.appendChild(marker)
			}

			if ('this.chartPivot) {
				Set x = x + delta
				Set top = this.getPlotY(hi) - this.%plotTop
				Set bottom = this.getPlotY(low) - this.%plotTop
				Set mid = this.getPlotY(close) - this.%plotTop

				// marker
				if (marker'="") {
					Set points = "0,5 0,-5 5,0 0,5"
					do marker.setAttribute("points",points)
					do marker.setAttribute("transform","translate("_((x-adj-shift)*scaleX)_","_(mid*scaleY)_")")
				}

				// hi-low bar
				Set hgt = bottom-top
				if (hgt < 0) {
					// show inverted bar
					Set a = top
					Set top = bottom
					Set bottom = a
					Set hgt = -hgt
					do bar.setAttribute("class","chart-seriesBarInverted")
					Set barStyle = this.invertedBarStyle
				}

				do bar.setAttribute("x",(x-adj+shift)*scaleX)
				do bar.setAttribute("y",top*scaleY)
				do bar.setAttribute("width",barsize*scaleX)
				do bar.setAttribute("height",hgt*scaleY)
			}
			else {
				Set y = y + delta
				Set right = this.getPlotX(hi) - this.%plotLeft
				Set left = this.getPlotX(low) - this.%plotLeft
				Set mid = this.getPlotX(close) - this.%plotLeft

				// marker
				if (marker) {
					Set points = "-5,0 5,0 0,5 -5,0"
					do marker.setAttribute("points",points)
					do marker.setAttribute("transform","translate("_(mid*scaleX)_","_((y-adj-shift)*scaleY)_")")
				}

				// hi-low bar
				Set wid = right-left
				if (wid < 0) {
					// show inverted bar
					Set a = right
					Set right = left
					Set left = a
					Set wid = -wid
					do bar.setAttribute("class","chart-seriesBarInverted")
					Set barStyle = this.invertedBarStyle
				}

				do bar.setAttribute("x",left*scaleX)
				do bar.setAttribute("y",(y-adj+shift)*scaleY)
				do bar.setAttribute("width",wid*scaleX)
				do bar.setAttribute("height",barsize*scaleY)
			}

			// see if we are the selected item
			if (hasSelect) {
				if ((0 = this.selectedSeries) && (n = this.selectedItem)) {
					do bar.setAttribute("style",this.plotStyle _ ";"_ this.selectedItemStyle _ ";"_ barStyle)
				}
				else {
					do bar.setAttribute("style",this.plotStyle_";"_this.unselectedItemStyle_";"_barStyle)
				}
			} else {
				do bar.setAttribute("style",this.plotStyle_";"_barStyle)
			}
			// chartElementClickHandler (series = 0)
			do bar.setAttribute("id",this.makeId("el_0_" _ n))
		}
	}
}

/// Return an array of labels to display within the Legend box.<br>
/// A hilow chart only displays one logical data series, so only one
/// item is displayed in the legend box.
Method getLegendLabels()
{
	Set this=##this
	// construct an array of one element
	Set legends="" ; list
	Set names = this.getSeriesNames()
	Set $LI(legends,1) = $LG(names,1)
	quit legends
}

/// Return default style for a bar element.
Method getChartElementStyle(series, item)
{
	Set this=##this
	quit this.plotStyle
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType()
{
	Set this=##this
	quit $s(this.chartPivot : "value", 1 : "category")
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType()
{
	Set this=##this
	quit $s(this.chartPivot : "category", 1 : "value")
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
Method useSumForRange()
{
	Set this=##this
	quit 0
}

}
