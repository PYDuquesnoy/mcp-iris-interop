/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// 
/// 
/// This class is designed to map an existing global named <B> ^["%SYS"]ISCcspPerformance </B>
/// 
/// which contains data about the CSP/ZEN Performance as long as the <B>PAGETIMING parameter 
/// 
/// is set to 1 </B>in the page. 
/// 
/// 
/// 
/// It contais data about each time a CSP/ZEN page is executed: Day, Time Slot, Hits, 
/// 
/// Global References, Lines Executed, and Maximum, Minimum and Total Execution Time.
/// 
/// 
/// 
/// This class will allow SQL access to the data. Some sample queries are provided.
/// 
/// One step further will be DeepSee enable it, to be able to use DeepSee against this data.
/// 
Class %CSP.Util.Performance Extends %Persistent [ StorageStrategy = CspPerformance, System = 4 ]
{

/// 
/// Indicates the type of the event (currently there is only one event named 'Page')
Property Event As %String(TRUNCATE = 1);

/// 
/// The full CSP page name, includes the application name
Property Page As %String(MAXLEN = 256, TRUNCATE = 1);

/// 
/// Date in YYYY-MM-DD format
Property Day As %String(TRUNCATE = 1);

/// 
/// The particular Slot within the Day the hit occured
/// 
/// The total number of Time Slots in a day is defined in the page with the <B>TIMINGSLOTS parameter</B>
Property Slot As %Integer;

/// 
/// Number of times the page was executed
Property Hits As %Numeric(SCALE = 0);

/// 
/// Number of global references (read/write)
Property Globals As %Numeric(SCALE = 0);

/// 
/// Number of lines of COS code executed
Property Lines As %Numeric(SCALE = 0);

Property GlobalsPerHit As %Integer [ Calculated, SqlComputeCode = { set {GlobalsPerHit}=({Globals}/{Hits})}, SqlComputed ];

Property LinesPerHit As %Integer [ Calculated, SqlComputeCode = { set {LinesPerHit}=({Lines}/{Hits})}, SqlComputed ];

/// 
/// Maximum Page execution time
Property MaxTime As %Numeric(SCALE = 6);

/// 
/// Minimum Page execution time
Property MinTime As %Numeric(SCALE = 6);

/// 
/// Total accumulated Page execution time
Property TotalTime As %Numeric(SCALE = 6);

Index IdKeyIdx On (Event, Page, Day, Slot) [ IdKey, Unique ];

/// 
/// top pages in number of Hits in a period of time
Query Top10Pages(from As %String, until As %String) As %SQLQuery [ SqlProc ]
{
	SELECT      TOP 10 Page, Hits

	FROM 	    %CSP_Util.Performance

	WHERE 		Day BETWEEN :from AND :until

	GROUP BY 	Page

	ORDER BY 	Hits DESC
}

Query PageAndDay(Page As %String, Day As %String = {""_$zdate($h,3)}) As %SQLQuery [ SqlProc ]
{
	SELECT 	Hits,Globals,GlobalsPerHit,Lines,LinesPerHit,MaxTime,MinTime,TotalTime,Page,Day,Slot 

	FROM 	%CSP_Util.Performance

 	WHERE 	(Page = :Page AND Day = :Day)

 	ORDER 	BY Slot
}

Storage CspPerformance
{
<DataLocation>^["%SYS"]ISCcspPerformance</DataLocation>
<DefaultData>^["%SYS"]ISCcspPerformance</DefaultData>
<ExtentSize>100000</ExtentSize>
<SQLMap name="Map1">
<Data name="Globals">
<Delimiter>"^"</Delimiter>
<Node>"globals"</Node>
<Piece>1</Piece>
</Data>
<Data name="Hits">
<Delimiter>"^"</Delimiter>
<Node>"hit"</Node>
<Piece>1</Piece>
</Data>
<Data name="Lines">
<Delimiter>"^"</Delimiter>
<Node>"lines"</Node>
<Piece>1</Piece>
</Data>
<Data name="MaxTime">
<Delimiter>"^"</Delimiter>
<Node>"max"</Node>
<Piece>1</Piece>
</Data>
<Data name="MinTime">
<Delimiter>"^"</Delimiter>
<Node>"min"</Node>
<Piece>1</Piece>
</Data>
<Data name="TotalTime">
<Delimiter>"^"</Delimiter>
<Node>"time"</Node>
<Piece>1</Piece>
</Data>
<Global>^["%SYS"]ISCcspPerformance</Global>
<RowIdSpec name="1">
<Expression>{L1}</Expression>
<Field>Event</Field>
</RowIdSpec>
<RowIdSpec name="2">
<Expression>{L2}</Expression>
<Field>Page</Field>
</RowIdSpec>
<RowIdSpec name="3">
<Expression>{L3}</Expression>
<Field>Day</Field>
</RowIdSpec>
<RowIdSpec name="4">
<Expression>{L4}</Expression>
<Field>Slot</Field>
</RowIdSpec>
<Subscript name="1">
<AccessType>Sub</AccessType>
<Expression>{Event}</Expression>
</Subscript>
<Subscript name="2">
<AccessType>Sub</AccessType>
<Expression>{Page}</Expression>
</Subscript>
<Subscript name="3">
<AccessType>Sub</AccessType>
<Expression>{Day}</Expression>
</Subscript>
<Subscript name="4">
<AccessType>Sub</AccessType>
<Expression>{Slot}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^%CSP.Util.PerformanceS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
