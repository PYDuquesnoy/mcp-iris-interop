/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syNLS

/// The %SYS.Date.SlidingWindow class supports methods for
/// setting, modifying and inspecting the system-wide or
/// process-specific sliding window definitions. With the
/// exception of Get(), all the other class methods return a
/// %Status to indicate success or failure. Any modified
/// system-wide definition will be active until the system
/// is restarted. If necessary, users can add the new
/// settings to ^ZSTU or ^%ZSTART in order to make them
/// survive across reboots.<br><br>
/// 
/// In most cases, the first parameter indicates whether
/// the call is system or process-specific:<br><br>
/// Scope = 0: system (default)<br>
/// Scope = 1: process<br><br>
/// 
/// Depending of the method, start and end dates can be specified
/// in 3 different ways:<br><ol>
/// <li>Absolute Dates, represented in $H format</li>
/// <li>Absolute Years, represented by 4-digit numbers relative to the
/// start of the Common Era (0 C.E.)</li>
/// <li>Relative Years, represented by numbers relative the current year</li></ol>
/// When relative years are used to define a sliding window, the first
/// or only relative year is interpreted as the start year, expressed
/// as the number of years PRIOR to the current year. The second relative
/// year, if any, is interpreted as the end year, expressed as one more
/// than the number of years AFTER the current year.
Class %SYS.Date.SlidingWindow Extends %RegisteredObject [ System = 4 ]
{

/// Set default to be an "empty" window, so that all
/// years display using 4 digits.
ClassMethod NoWindow(Scope As %Integer = 0) As %String
{
 Set status=$$$OK
 Try { Set old=$ZU(123,'Scope,1,0) }
 Catch { Set status=$$$ERROR($$$ObjectScriptError,$ZE) }
 Quit status
}

/// Get current default definition in the format:<br><br>
/// OldStartDate^OldEndDate<br><br>
/// Where OldStartDate and OldEndDate are absolute dates
/// in $H format representing the start and end, respectively,
/// of the current sliding window.
ClassMethod Get(Scope As %Integer = 0) As %String
{
 Try { Set old=$ZU(123,'Scope) }
 Catch { Set old="" }
 Quit old
}

/// Remove current default so that a 20th century
/// fixed window is used by default.
ClassMethod Twentieth(Scope As %Integer = 0) As %Status
{
 Set status=$$$OK
 Try { Set old=$ZU(123,'Scope,0,0) }
 Catch { Set status=$$$ERROR($$$ObjectScriptError,$ZE) }
 Quit status
}

/// Set date window to begin on the absolute year StarYear
/// and to end on the absolute year EndYear.
ClassMethod SetAbsolute(Scope As %Integer = 0, StartYear As %Integer, EndYear As %Integer) As %Status
{
 Set status=$$$OK
 Try {
	If $D(EndYear)=0 { Set old=$ZU(123,'Scope,$$$CvtAbsStart(StartYear)) }
	Else { Set old=$ZU(123,'Scope,$$$CvtAbsStart(StartYear),$$$CvtAbsEnd(EndYear)) }
 } Catch { Set status=$$$ERROR($$$ObjectScriptError,$ZE) }
 Quit status
}

/// Set date window to begin on the absolute date StartDate
/// and to end on the absolute date EndDate.
ClassMethod SetDate(Scope As %Integer = 0, StartDate As %Integer, EndDate As %Integer) As %Status
{
 Set status=$$$OK
 Try {
	If $D(EndDate)=0 { Set old=$ZU(123,'Scope,StartDate) }
	Else { Set old=$ZU(123,'Scope,StartDate,EndDate) }
 } Catch { Set status=$$$ERROR($$$ObjectScriptError,$ZE) }
 Quit status
}

/// Set date window to begin on the relative year StartYear
/// and to end on the relative year EndYear.<br><br>
/// Example: If issued in 2008, the following command would
/// establish a process-specific sliding window definition
/// which would result in this process displaying two-digit
/// years for any dates in the range 01/01/1918 through
/// 12/31/2017, inclusive.<br><br>
/// Set status=##class(%SYS.Date.SlidingWindow).SetRelative(1,90,10)
ClassMethod SetRelative(Scope As %Integer = 0, StartYear As %Integer, EndYear As %Integer) As %Status
{
 Set status=$$$OK
 Try {
	If $D(EndYear)=0 { Set old=$ZU(123,'Scope,$$$CvtRelStart(StartYear)) }
	Else { Set old=$ZU(123,'Scope,$$$CvtRelStart(StartYear),$$$CvtRelEnd(EndYear)) }
 } Catch { Set status=$$$ERROR($$$ObjectScriptError,$ZE) }
 Quit status
}

/// Set process window to be the same as the current system default.
ClassMethod UseDefault()
{
 Set status=$$$OK
 Try {
	Set def=$ZU(123,1)
	Set start=$P(def,"^"),end=$P(def,"^",2)
	Set old=$ZU(123,0,start,end)
 } Catch { Set status=$$$ERROR($$$ObjectScriptError,$ZE) }
 Quit status
}

}
