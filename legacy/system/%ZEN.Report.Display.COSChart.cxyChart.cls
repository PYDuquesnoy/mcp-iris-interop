/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.cxyChart Extends cchart [ Deprecated, System = 4 ]
{

/// This is an SVG <class>chart</class> component that displays an X-Y chart.<br/>
/// This chart plots two or more series of data as a series
/// of x,y points on the chart. The first data series provides
/// the x values, the second provides the correlated y values.<br/>
/// Additional data series are plotted as y values 
/// correlated to the x values provided by the first series.<br/>
/// The first series name is used as the name of the first series containing
/// y-values.<br/>
/// You can supply more than one set of x values using the <property>independentXSeries</property>
/// property.
/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Default value for the markersVisible property.
Parameter DEFAULTMARKERSVISIBLE = 1;

/// Optional: if false (the default) the first data series is used to supply
/// x values for the chart and all other data series provide y values.<br/>
/// If false, then the chart will display multiple x series. In this case, the first
/// data series provides the first set of x values, the second
/// data provides the first set of y values, the third data series provides the second
/// set of x values, and so on.
Property independentXSeries As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property seriesYAxes As %ZEN.Datatype.csv(XMLPROJECTION = "none");

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
	Set range = ##class(range).%New()
	Set range.minValue = ""
	Set range.maxValue = ""
	Set range.minValue2 = "" // used by x/y type charts
	Set range.maxValue2 = ""
	
	Set scount = this.getSeriesCount()
	set items = this.getSeriesSize()

	if (scount <= 1) {
		// use series 0 as y;
		Set range.minValue2 = 0
		Set range.maxValue2 = items
		if (scount = 1) {
			merge data = this.%dataSeries(0)
			for n = 0:1:items-1 {
				Set val = data(n)
				if ('$$$ISNAN(val)) {
					Set val = $$$PARSEFLOAT(val)
					Set range.minValue = $s((""=range.minValue) : val, 1 : $s(val < range.minValue : val, 1 : range.minValue))
					Set range.maxValue = $s((""=range.maxValue) : val, 1 : $s((val > range.maxValue) : val, 1 : range.maxValue))
				}
			}
		}
	}
	else {
				// loop over series to compute x & y range
		for s = 0:1:scount-1 {
			merge data = this.%dataSeries(s)
			Set which = $s(this.independentXSeries:($s((s#2)=0:"x",1:"y")),1:$s(s=0:"x",1:"y"))
			if $D(data) {
				for n = 0:1:items-1 {
					Set val = data(n)
					if ('$$$ISNAN(val)) {
						Set val = $$$PARSEFLOAT(val)
						if (which = "y") {
							Set range.minValue = $s((""=range.minValue) : val, 1 : $s(val < range.minValue : val, 1 : range.minValue))
							Set range.maxValue = $s((""=range.maxValue) : val, 1 : $s((val > range.maxValue) : val, 1 : range.maxValue))						}
						else {
							Set range.minValue2 = $s((""=range.minValue2) : val, 1 : $s(val < range.minValue2 : val, 1 : range.minValue2))
							Set range.maxValue2 = $s((""=range.maxValue2) : val, 1 : $s((val > range.maxValue2) : val, 1 : range.maxValue2))						}
						}
					}
				}
			}
		}

		/*
		// get x range
		var data = this._dataSeries[0];
		for (var n = 0; n < items; n++) {
			var val = data[n];
			if (!isNaN(val)) {
				val = parseFloat(val);
				range.minValue2 = (null==range.minValue2) ? val : (val < range.minValue2) ? val : range.minValue2;
				range.maxValue2 = (null==range.maxValue2) ? val : (val > range.maxValue2) ? val : range.maxValue2;
			}
		}

		
		
		
		
		// get x range
		merge data = this.%dataSeries(1)
		for n = 1:1:items {
			Set val = data(n)
			if ('$$$ISNAN(val)) {
				Set val = $$$PARSEFLOAT(val)
				Set range.minValue2 = $s((""=range.minValue2) : val,1 : $s((val < range.minValue2) : val, 1 : range.minValue2))
				Set range.maxValue2 = $s((""=range.maxValue2) : val,1 : $s((val > range.maxValue2) : val, 1 : range.maxValue2))
			}
		}

		// get y range
		for s = 1:1:scount {
			merge data = this.%dataSeries(s)
			for n = 1:1:items {
				Set val = data(n)
				if ('$$$ISNAN(val)) {
					Set val = $$$PARSEFLOAT(val)
					Set range.minValue = $s((""=range.minValue) : val, 1 : $s((val < range.minValue) : val, 1 : range.minValue))
					Set range.maxValue = $s((""=range.maxValue) : val , 1: $s((val > range.maxValue) : val, 1 : range.maxValue))
				}
			}
		}
	}
	*/
	if (..chartPivot) {
		// swap ranges
		Set tmin=range.minValue
		Set tmax=range.maxValue
		Set range.minValue=range.minValue2
		Set range.maxValue=range.maxValue2
		Set range.minValue2=tmin
		Set range.maxValue2=tmax
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
	
	// create series shapes
	
	Set scount = this.getSeriesCount()
	Set items = this.getSeriesSize()
	if (items > 0) {
		// get set of x values
		Set xData = "" ; list
		Set yData = "" ; list
		if (scount <= 1) {
			// if only one series, use it for y values
			// and pretend there is an x series
			Set xData(1) = ""
			for n = 0:1:items-1 {
				Set $LI(xData(1),n+1) = n
			}
			Set yData(1) = this.getSeriesData(0)
			Set scount = 1
			Set startSeries = 0
		}
		elseif (this.independentXSeries) {
			set scount = $$$CEIL(scount / 2)

			for s = 0:1:scount-1 {
				Set xData(s+1) = this.getSeriesData(s*2)
				Set yData(s+1) = this.getSeriesData((s*2)+1)
			}
			Set startSeries = 0
		}
		else {
			Set xData(1) = this.getSeriesData(0)
			for s = 1:1:scount-1 {
				Set yData(s+1) = this.getSeriesData(s)
			}
			Set startSeries = 1
		}

		// plot points
		for s = startSeries:1:scount-1 {
			Set ms = $s(this.independentXSeries : s, 1 : s-1)
			Set xs = $s(this.independentXSeries : s, 1 : 0)
			Set ys = s
			Set color = this.getSeriesColor(ms)
			if (this.markersVisible) {
				Set marker = this.getMarkerShape(ms)
			}

			Set poly = ##class(node).%New()
			do poly.createElementSVG("polyline")
			do poly.setAttribute("class","chart-seriesLine")
			do group.appendChild(poly)
			Set points = "" // set of points for this line
			for n = 0:1:items-1 {
				if '..chartPivot {
					Set xval = $s('$D(xData(xs+1)) : 0, 1 : $s("" = $LG(xData(xs+1),n+1) : "", 1 : $LG(xData(xs+1),n+1)))
					Set yval = $s('$D(yData(ys+1)) : 0, 1 : $s(("" = $LG(yData(ys+1),n+1)) : "", 1 : $LG(yData(ys+1),n+1)))
				} else {
					Set yval = $s('$D(xData(xs+1)) : 0, 1 : $s("" = $LG(xData(xs+1),n+1) : "", 1 : $LG(xData(xs+1),n+1)))
					Set xval = $s('$D(yData(ys+1)) : 0, 1 : $s(("" = $LG(yData(ys+1),n+1)) : "", 1 : $LG(yData(ys+1),n+1)))
				}					
				
				Set x = this.getPlotX(xval) - this.%plotLeft
				Set y = this.getPlotY(yval) - this.%plotTop
				if (yval '= "") {
					Set points = points_( (x*scaleX) _ " " _ (y*scaleY) _ " ")
				}

				if (this.markersVisible) {
					if (yval '= "") {
						do group.appendChild(this.createMarker(s,n,x,y,color,marker))
					}
				}
			}
		
			do poly.setAttribute("points",points)
			do poly.setAttribute("stroke",color)
			do poly.setAttribute("fill","none")
			do poly.setAttribute("style",this.plotStyle)
		}
	}
}

/// Return an array of labels to display within the Legend box.<br>
/// For xy chart we have to skip the first series, as it contains
/// x-values, and not a logical data series.
Method getLegendLabels()
{
	Set this=##this
	Set legends = "" ; list
	Set names = this.getSeriesNames() ; list

	Set scount = this.getSeriesCount()
	if (scount>1) {
		if (this.independentXSeries) {
			Set scount = $$$CEIL(scount / 2)
		}
		else {
			Set scount = scount - 1
		}
	}

	// JMD1296 show correct labels
	if ..independentXSeries {
	for i = 1:1:scount  {
			Set c = 2 * i
			Set $LI(legends,i) = $s(("" = $LG(names,c)) : i, 1 : $LI(names,c))
		}		
	} else {
		for i = 1:1:scount  {
			Set $LI(legends,i) = $s(("" = $LG(names,i+1)) : i, 1 : $LI(names,i+1))
		}
	}
	quit legends
}

}
