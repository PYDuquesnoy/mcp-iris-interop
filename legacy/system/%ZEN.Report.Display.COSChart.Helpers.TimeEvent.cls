/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// time events for rendering time events on a chart
/// Here is a JavaScript example: { start:'2012-01-01', end:'2012-11-02', caption:'Coumadin', style:'', marker:'square'}
Class %ZEN.Report.Display.COSChart.Helpers.TimeEvent Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// start of event in ODBC format
Property start As %ZEN.Datatype.string;

/// end of event in ODBC format
Property end As %ZEN.Datatype.string;

/// label for event when we draw it
Property caption As %ZEN.Datatype.string;

Property style As %ZEN.Datatype.svgStyle;

/// marker that will be rendered when event is drawn
Property marker As %ZEN.Datatype.string;

Property markerColor As %ZEN.Datatype.color;

}
