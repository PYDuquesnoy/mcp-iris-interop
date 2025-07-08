/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a chart data series definition within a Dashboard widget definition.
/// This is used by the Widget editor. It is not the saved state of the data series.
Class %DeepSee.Component.dataSeriesDefinition Extends %ZEN.Component.object [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Color for this series.<br/>
Property color As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// How to display this series ("area","bar","line").<br/>
Property type As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// Marker for this series ("circle", etc).<br/>
Property markerShape As %String(MAXLEN = 255, XMLPROJECTION = "attribute");

/// yAxis (0-based) to use for this series.<br/>
Property yAxisIndex As %Integer(MINVAL = 0, XMLPROJECTION = "attribute") [ InitialExpression = 0 ];

/// If false, do not include this series in the chart legend.<br/>
Property hasLegend As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

}
