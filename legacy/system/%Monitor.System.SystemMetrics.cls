/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Monitor PERFMON metrics for the system.<br>
/// <br>** DEPRECATED **. This class has been deprecated for performance issues, and will no longer collect SystemMetrics.<br>
/// <br>This class, and others that inherit from %Monitor.System.Abstract, provides an object 
/// API to the same system metrics as the ^PERFMON utility. Instantiating this class also
/// starts the collection of ^PERFMON system level metrics, which can have a significant
/// impact on a busy system. Note that stopping ^PERFMON will also disable the sampling here.<br><br>
/// Properties are inherited from AbstractMetrics and AbstractGlobals.
Class %Monitor.System.SystemMetrics Extends (%Monitor.System.Abstract, %Monitor.System.AbstractMetrics, %Monitor.System.AbstractGlobals) [ Deprecated, Inheritance = right, System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Property Data As %String [ Internal, MultiDimensional ];

/// On Startup enable PERFMON
Method Startup() As %Status
{
 Quit $$$OK
}

/// Initialize system metrics
Method Initialize() As %Status
{
	Quit $$$OK
}

/// Get system metric sample
/// A return code of $$$OK indicates there is a new sample instance.
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	Q $$$OK
}

}
