/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a data series for a Dashboard grid This class is for internal use only.
Class CSPX.Dashboard.GridSeries Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

/// Metric property providing the metric for this series.
/// The Metric class is defined by the grid.
Property Property As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// (Optional) Metric instance name providing the data for this series.
Property Instance As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Label displayed for this series; If not specified, <var>Property</var>
/// is used.
Property Label As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// (Internal) Holder for initial data for series.
Property Data As %String(MAXLEN = 10000, XMLPROJECTION = "NONE");

}
