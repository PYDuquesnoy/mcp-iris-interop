/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.Helpers.IndexedEvent Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property index As %ZEN.Datatype.integer;

/// start of event in ODBC format
Property start As %ZEN.Datatype.string;

/// end of event in ODBC format
Property end As %ZEN.Datatype.string;

}
