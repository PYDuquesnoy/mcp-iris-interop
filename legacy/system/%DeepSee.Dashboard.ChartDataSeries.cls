/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class defines options for a chart data series within a user-defined DeepSee dashboard widget.
/// This lets the user customize the display of data series within a chart.
Class %DeepSee.Dashboard.ChartDataSeries Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee/library";

Parameter XMLNAME = "chartDataSeries";

Parameter XMLIGNORENULL = 1;

/// How to display this series (used by comboCharts).
Property type As %String(MAXLEN = 255, VALUELIST = ",bar,line,area", XMLPROJECTION = "attribute");

/// Marker to display for this series (used by line Charts).
Property markerShape As %String(MAXLEN = 255, VALUELIST = ",up,down,circle,square", XMLPROJECTION = "attribute");

/// Color for this data series.
Property color As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// yAxis (0-based) to use for this series.<br/>
Property yAxisIndex As %Integer(MINVAL = 0, XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If false, do not include this series in the chart legend.<br/>
Property hasLegend As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// Copy contents of this instance to <var>pTarget</var>.
Method %CopyTo(pTarget As %DeepSee.Dashboard.ChartDataSeries) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pTarget.type = ..type
		Set pTarget.color = ..color
		Set pTarget.yAxisIndex = ..yAxisIndex
		Set pTarget.hasLegend = ..hasLegend
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Storage Default
{
<Data name="ChartDataSeriesState">
<Value name="1">
<Value>type</Value>
</Value>
<Value name="2">
<Value>color</Value>
</Value>
<Value name="3">
<Value>marker</Value>
</Value>
<Value name="4">
<Value>markerShape</Value>
</Value>
<Value name="5">
<Value>yAxisIndex</Value>
</Value>
<Value name="6">
<Value>hasLegend</Value>
</Value>
</Data>
<State>ChartDataSeriesState</State>
<StreamLocation>^%DeepSee.D3E8F.ChartDataSeC99FS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
