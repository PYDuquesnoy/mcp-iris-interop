/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.COSChart.Helpers.SortedEvents Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property array As %ZEN.Datatype.string(XMLPROJECTION = "none") [ MultiDimensional ];

Method push(index, start, end)
{
	Set indexedEvent=##class(IndexedEvent).%New()
	Set indexedEvent.index = index
	Set indexedEvent.start = start
	Set indexedEvent.end = end
	Set duration = 0
	if (indexedEvent.start'="" && (indexedEvent.end'="")) {
		Set d1 = ##class(%ZEN.Report.Display.COSChart.Date).stringToDate(indexedEvent.start)
		Set d2 = ##class(%ZEN.Report.Display.COSChart.Date).stringToDate(indexedEvent.end)
		Set duration = d2.time - d1.time
	}

	Set ..array(-duration,index)=indexedEvent // sort backwards, biggest durations first
}

/// Compare return 1 if a LT b
/// Compare return -1 if a GT b
/// Compare return 0 if a == b
Method Compare(a As IndexedEvent, b As IndexedEvent)
{
	Set aDuration = 0
	if (a.start'="" && (a.end'="")) {
		Set d1 = ##class(%ZEN.Report.Display.COSChart.Date).stringToDate(a.start)
		Set d2 = ##class(%ZEN.Report.Display.COSChart.Date).stringToDate(a.end)
		Set aDuration = d2.time - d1.time
	}
	Set bDuration = 0
	if (b.start'="" && (b.end'="")) {
		Set d1 = zenStringToDate(b.start)
		Set d2 = zenStringToDate(b.end)
		Set bDuration = d2.time-d1.time
	}
	if (aDuration<bDuration) quit 1
	if (aDuration>bDuration) quit -1
	quit 0
}

}
