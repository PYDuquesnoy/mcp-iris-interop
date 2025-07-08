/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a series for a Dashboard chart. This class is for internal use only.
Class CSPX.Dashboard.ChartSeries Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

/// Metric property providing the metric for this series.
/// The Metric class is defined by the chart.
Property Property As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// (Optional) Metric instance name providing the data for this series.
Property Instance As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Label displayed for this series; If not specified, <var>Property</var>
/// is used.
Property Label As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// SVG Color used to display this series.
Property Color As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Holder for initial data for series.
Property Data As %String(MAXLEN = 10000, XMLPROJECTION = "NONE");

/// Upper range value for this series. Only used if
/// the chart has SharedScale set to false.
Property RangeUpper As %Float(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 100 ];

/// Lower range value for this series. Only used if
/// the chart has SharedScale set to false.
Property RangeLower As %Float(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

/// Scale factor for this series. Only used if
/// the chart has SharedScale set to false.
Property ScaleFactor As %Float(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

}
