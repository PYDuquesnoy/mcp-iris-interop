/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines dimension specification for a Dashboard grid. This class is for internal use only.
Class CSPX.Dashboard.GridDimension Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

/// Source of data for this this dimension: this can be
/// "series", "instances","history" or "".
Property Source As %String(MAXLEN = 20, VALUELIST = ",series,instances,history", XMLPROJECTION = "ATTRIBUTE");

/// Optional: number of cells to display for data along this dimension.
Property Size As %Integer(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE");

/// Optional: Show data for this dimension in reverse order
Property Reverse As %Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Optional: Name of aggregate function to apply along this dimension.
Property Aggregate As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Optional: Label to apply for aggregate function row or column.
Property AggregateLabel As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Optional collection of Series definitions for this grid dimension.
/// If Series are defined the Property defined for this chart is ignored.
Property SeriesList As list Of GridSeries(XMLNAME = "Series", XMLPROJECTION = "ELEMENT");

}
