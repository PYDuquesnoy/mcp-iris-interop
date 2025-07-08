/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.cdiffChart Extends cchart [ Deprecated, System = 4 ]
{

/// This is an SVG <class>chart</class> component that displays a difference chart.<br>
/// This is a specialized type of line chart that
/// displays the difference between a reference data series
/// (the first data series) and an actual data series
/// (the second data series).
/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Optional: default style applied to the reference line elements used for plotting
/// data by this chart.
Property refLineStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "stroke-dasharray: 1,1;" ];

Property seriesYAxes As %ZEN.Datatype.csv(XMLPROJECTION = "none");

XData SVGStyle
{
}

/// Draw data series for this chart.
/// <var>group</var> is the SVG container for the chart components.
Method renderSeries(group)
{
	Set this=##this
	// JMD1100
	Set scaleX = $s(this.%scaleX : this.%scaleX, 1 : 1)
	Set scaleY = $s(this.%scaleY : this.%scaleY, 1 : 1)

	// create series shapes
	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()
	if (items > 0) {
		// first get data for all series
		// (there should be 2 series)
		Set data = "" ; list
		for s = 0:1:(scount-1) {
			Set data(s+1) = this.getSeriesData(s) ; array of lists
		}

		// plot series in reverse order
		for s = scount:-1:1 {
			Set color = this.getSeriesColor(s-1) ; zero-based
			if (this.markersVisible) {
				Set marker = this.getMarkerShape(s-1)
			}

			Set poly = ##class(node).%New()
			do poly.createElementSVG("polyline")
			do poly.setAttribute("class","chart-seriesLine")
			do group.appendChild(poly)
			Set points = "" // set of points for this line

			if (this.plotToEdge) {
				Set dx = $s((items<=1) : this.%plotWidth, 1 : (this.%plotWidth / (items-1)))
				Set adj = dx
			}
			else {
				Set dx = this.%plotWidth / items
				Set adj = (dx/2)
			}

			Set x = 0

			for n = 1:1:items {
				Set val = $s('$D(data(s)) : 0, 1 : $s(("" = $LG(data(s),n)) : 0, 1 : $$$PARSEFLOAT($LG(data(s),n))))
				Set x = x + dx
				Set y = this.getPlotY(val) - this.%plotTop
				Set points = points _ ((x-(adj))*scaleX) _ " " _ (y*scaleY) _ " "
				if (this.markersVisible) {
					do group.appendChild(this.createMarker(s-1,n-1,(x-adj),y,color,marker))
				}
			}
			
			if (s > 1) {
				// get path to fill area between this series and reference
				for n = items:-1:1 {
					Set val = $s('$D(data(1)) : 0, 1 : $s(("" = $LG(data(1),n)) : 0, 1 : $$$PARSEFLOAT($LG(data(1),n))))
					Set y = this.getPlotY(val) - this.%plotTop
					Set points = points _ ((x-(adj))*scaleX) _ " " _ (y*scaleY) _ " "
					Set x = x - dx
				}
			}

			do poly.setAttribute("points",points)
			do poly.setAttribute("stroke",color)
			do poly.setAttribute("style",$S((s=1) : this.refLineStyle, 1 : this.plotStyle))
			do poly.setAttribute("fill",$s((s > 1) : color, 1 : "none"))
		}
	}
}

/// This method returns true if data series should be summed
/// when calculating data range for the chart.
Method useSumForRange()
{
	quit 0
}

}
