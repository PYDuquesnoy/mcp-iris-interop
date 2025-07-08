/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a combination of
/// line and bar chart information.<br/>
/// This chart displays one or more data series each of which can be presented as lines
/// or bars.<br/>
/// Pivotted combo charts are not supported.
Class %ZEN.Report.Display.COSChart.ccomboChart Extends %ZEN.Report.Display.COSChart.cbarChart [ Deprecated, System = 4 ]
{

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "2D";

/// Comma-delimited list of types indicating how each series within the chart should be displayed.
/// Possible types are "line", "area", "target", and "bar". If a type is not supplied, the type is "bar".
/// "target" draws a target bar across any bars series.
Property seriesTypes As %ZEN.Datatype.csv;

/// Return the type (how a series should be displayed) for the given data series (0-based).
Method getSeriesType(series)
{
	Set t = ..split(..seriesTypes,",")
	Set type = $s($LG(t,series+1)'="": $LG(t,series+1), 1 : $s(..isTimeBased():"line", 1:"bar"))
	quit type
}

/// For line/bar charts with stacked bars, indicate which "group" should
/// be used for computing axis ranges.
Method getRangeGroupForSeries(series)
{
	Set this=##this
	Set group = ""

	// JMD1208
	Set multipleOffset = $s(this.currMultiple'="":this.currMultiple, 1:0)

	Set seriesType = ..getSeriesType(series+multipleOffset)
	//Set seriesType = $zobjmethod(%report,"getSeriesType",series)
	if (seriesType="bar" || (seriesType="target")) {
		if (this.useSumForRange()) {
			// add up as stacked bars
			Set group = "bar"
		}
		else {
			Set group = "none"
		}
	} elseif (seriesType="area") {
		Set group = "none"
	} elseif(seriesType="line") {
		Set group = "none"
	} else {
		Set group = "none"
	}
	quit group
}

/// Test if this is a combo chart.
Method isCombo()
{
	quit 1
}

/// Test if a time-based x axis should be used.
/// This is overridden in subclasses.
Method isTimeBased()
{
	quit $s(..chartPivot : 0, 1 : ..timeBased)
}

}
