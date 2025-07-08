/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Monitor system metrics by process.<br>
/// <br>This class, and others that inherit from %Monitor.System.Abstract, provides an object 
/// API to the same system metrics as the ^PERFMON utility. Instantiating this class also
/// starts the collection of ^PERFMON system metrics, which can have a significant
/// impact on a busy system. Note that stopping ^PERFMON will also disable the sampling here.<br><br>
/// Properties are inherited from AbstractGlobals.
Class %Monitor.System.Processes Extends (%Monitor.System.Adaptor, %Monitor.System.Abstract, %Monitor.System.AbstractGlobals) [ Inheritance = right, System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Property Data As %String [ Internal, MultiDimensional ];

Property Count As %Integer [ Internal ];

Parameter INDEX [ Internal ] = "Pid";

/// Process id
Property Pid As %Monitor.Integer;

/// On Startup enable PERFMON
Method Startup() As %Status
{
 d ##class(%Monitor.Manager).StartSystemCounters(0)
 Quit $$$OK
}

/// Initialize process metrics
Method Initialize() As %Status
{
	 ; Collect global stats
	k stat Do ..GetStat("P",.stat)
	Merge ..Data = stat
	Set ..Count = 0
	Quit $$$OK
}

/// Get process metric sample
/// A return code of $$$OK indicates there is a new sample instance.
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	Set ..Count = ..Count+1
	I ..Count > ..Data Q 0
	s ..Pid=..Name(..Data(..Count,"Name"),"P")	; Pid #
	d ..SaveStat(..Data(..Count,"Stat"),"P",$this)
	Q $$$OK
}

}
