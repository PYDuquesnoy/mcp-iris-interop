/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %syStats)

/// The methods here control the Process Monitor which allow a programmer to capture 
/// metrics for the current process. The metrics are the same counters as 
/// captured by the PERFMON utility, but they are only captured for the current 
/// process and stored in the process local memory. This ensures that it has 
/// minimal effect on the rest of the system.
/// <br><br>
/// Application programmers can embed the methods in their code, so that the 
/// Process Monitor can be enabled and metrics reported by user processes, 
/// allowing them to analyze trouble spots on live systems.
/// <br><br>
/// Note that all of the counters are either 32 or 64-bit counters, according to the word length
/// of the platform, and follow the SNMP Counter32 and Counter64 semantics defined in RFC1442.
/// Application code which subtracts a previous value from the current value must take into account the possible
/// wrap around back to zero. All counters for a process may be initialized to zero using Clear().
Class %Monitor.Process [ Abstract, System = 4 ]
{

/// Start the Process Monitor for the current process. The counters from
/// any previous collections are cleared when the Process Monitor is enabled.
ClassMethod Enable() As %Status
{
 s status=$zu(84,1,6)
 q $$$OK
}

/// Stop the Process Monitor for the current process. The current values for all
/// metrics remain in memory until they are zeroed using the Clear() method or
/// the Process Monitor is enabled again.
ClassMethod Disable() As %Status
{
 s status=$zu(84,0,6)
 q $$$OK
}

/// Set all Process Monitor counters for the current process to zero. 
ClassMethod Clear() As %Status
{
 s status=$zu(84,2,6)
 q $$$OK
}

/// Returns a comma-delimited list of all Process Monitor counters for the current 
/// process. The Metrics() method provides a list of the names for the metrics.
/// <br><br>
/// Note that only the current process can report its counters. To be viewed
/// by other processes they must be written to a global or file. 
ClassMethod Report() As %String
{
 q $zu(84,7,6)
}

/// Returns a comma-delimited list of all the Process Monitor metrics. These are in 
/// the same order as the metric counters returned by the Report() method. Although the list
/// of metrics and the order of these metrics should be fairly static, it is possible
/// that new metrics might be added or the order changed for some reason in future 
/// versions. Use this method to "name" the metrics when reporting them. 
/// <br><br>
/// The metrics are the same as those reported by ^PERFMON, and the documentation for 
/// PERFMON gives a brief description of each metric.
ClassMethod Metrics() As %String
{
	q $$Metrics^%SYS.MONLBL($$$MONPID)
}

/// Shows the current status of the Process Monitor for this process. 
/// Returns a '1' for enabled and a '0' for disabled.
ClassMethod Status() As %Integer
{
 q $zu(84,8,6)
}

}
