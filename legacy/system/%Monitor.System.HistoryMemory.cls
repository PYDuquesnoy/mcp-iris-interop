/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySite

/// %Monitor class to collect and manage part of the Monitor History Database.
/// This class collects the SYS.History.HistoryMemory samples for the Shared Memory Heap Metrics,
/// at a default interval of 300 seconds.
/// <br>
Class %Monitor.System.HistoryMemory Extends %Monitor.System.Adaptor [ System = 4 ]
{

/// Keep track of last date to see of it's time to purge/summarize
Property Day As %Integer [ Internal ];

/// Status of last sample
Property Status As %Monitor.String [ Internal ];

/// Keep count of consecutive errors
Property Errors As %Integer [ Internal ];

/// Values to control sample times
Property LastTime As %Integer;

/// Interval between samples.
Property Interval As %Integer [ InitialExpression = 300 ];

/// Initialize property values
Method Startup() As %Status [ Internal ]
{
	s h=$h,..Day=$p(h,","),..LastTime = (..Day*86400)+$p(h,",",2)
	try {
		// Try to get the defined interval rather than using default value
		s time=""
		d ##class(%Monitor.Manager).ClassInterval("%Monitor.System.HistoryMemory",.time)
		s:time ..Interval=time
	} catch {}
	Quit $$$OK
}

ClassMethod Purge() As %Status [ Internal ]
{
	q $$$OK
}

Method Initialize() As %Status [ Internal ]
{
	q $$$OK
}

Method Shutdown() As %Status [ Internal ]
{
	q $$$OK
}

/// <p>Get the basic SYS.History.PerfData sample for the Monitor History Database. 
Method GetSample() As %Status
{
	s $zt="SampleErr"
	#; check if sample interval has expired
	s h=$h, day=$p(h,","),nowSeconds=(day*86400)+$p(h,",",2)
	s Length = nowSeconds-..LastTime
	q:(Length < (..Interval-1)) $$$OK			// Allow for a bit of rounding.
	#;
	#; We can get another sample.
	#;
	#;
	#; Get a sample of all ths shared memory data
	#;
	s ref = ##class(SYS.History.SharedMemoryData).%New()
	s ref.Length = Length
	s sample = ref.Sample()
	s ref = ref.Finalise(sample)
	d ref.%Save()	
	#;
	#; Think about doing a purge of old data
	#;
	if ((..LastTime\86400)'=day) {
		d ##class(SYS.History.SharedMemoryData).Purge()
		s ..Day=(..LastTime\86400)
	}
	s ..LastTime = nowSeconds
	s ..Errors=0,..Status="OK"
	Quit $$$OK
SampleErr
	s $zt=""
	d $$$LOGMSG("Error in %Monitor.System.HistoryMemory - "_$ze,0,1)
	s ..Errors=..Errors+1
	i ..Errors>5 {
		d $$$LOGMSG("Too many errors in %Monitor.System.HistoryMemory, deactivating the collection.",0,1)
		#;deactivate class
		d ##class(%Monitor.ItemGroup).MetricsClassItemGroup("%Monitor.System.HistoryMemory",.id)
		s class=##class(%Monitor.ItemGroup).%OpenId(id)
		i $IsObject(class) s class.Activated=0 d class.%Save() k class
		d ##class(%Monitor.Manager).RefreshApp()
		d $$$LOGMSG("Run ^%MONAPPMGR to activate and restart the %Monitor.System.HistoryMemory collection.",0,0)
		s ..Errors=0		
	}
	s ..Status="Error"
	q $$$OK
	Q 0
}

}
