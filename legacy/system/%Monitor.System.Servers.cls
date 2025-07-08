/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Monitor system metrics by ECP server.<br>
/// <br>This class, and others that inherit from %Monitor.System.Abstract, provides an object 
/// API to the same system metrics as the ^PERFMON utility. Instantiating this class also
/// starts the collection of ^PERFMON system metrics, which can have a significant
/// impact on a busy system. Note that stopping ^PERFMON will also disable the sampling here.<br><br>
Class %Monitor.System.Servers Extends (%Monitor.System.Adaptor, %Monitor.System.Abstract) [ Inheritance = right, System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Property Data As %String [ Internal, MultiDimensional ];

Property Count As %Integer [ Internal ];

Parameter INDEX [ Internal ] = "ServerName";

/// Server name
Property ServerName As %Monitor.String;

/// Buffers
Property Buffers As %Monitor.Integer;

/// Global kills received
Property GloKills As %Monitor.Integer;

/// Global references received
Property GloRefs As %Monitor.Integer;

/// Global sets received
Property GloSets As %Monitor.Integer;

/// Incoming net IJC messages received and written to the IJC device
Property IJCw0 As %Monitor.Integer(CAPTION = "IJC messages received/written");

/// Incoming net IJC messages received and NOT written to the IJC device
Property IJCw1 As %Monitor.Integer(CAPTION = "IJC messages received/not written");

/// Lock commands received
Property Locks As %Monitor.Integer;

/// Requests received
Property Requests As %Monitor.Integer;

/// On Startup enable PERFMON
Method Startup() As %Status
{
 d ##class(%Monitor.Manager).StartSystemCounters(0)
 Quit $$$OK
}

/// Initialize server metrics
Method Initialize() As %Status
{
	 ; Collect global stats
	k stat Do ..GetStat("O",.stat)
	Merge ..Data = stat
	Set ..Count = 0
	Quit $$$OK
}

/// Get server metric sample
/// A return code of $$$OK indicates there is a new sample instance.
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	Set ..Count = ..Count+1
	I ..Count > ..Data Q 0
	Set ..ServerName=..Name(..Data(..Count,"Name"),"O")	; Server system
	Set ..Requests=$p(..Data(..Count,"Stat"),",",1)
	Set ..GloRefs=$p(..Data(..Count,"Stat"),",",2)
	Set ..GloSets=$p(..Data(..Count,"Stat"),",",3)
	Set ..GloKills=$p(..Data(..Count,"Stat"),",",4)
	Set ..Locks=$p(..Data(..Count,"Stat"),",",5)
	Set ..Buffers=$p(..Data(..Count,"Stat"),",",6)
	Set ..IJCw0=$p(..Data(..Count,"Stat"),",",7)
	Set ..IJCw1=$p(..Data(..Count,"Stat"),",",8)
	Q $$$OK
}

}
