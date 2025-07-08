/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Monitor Server clients.<br>
Class %Monitor.System.Clients Extends (%Monitor.System.Adaptor, %Monitor.System.Globals) [ Inheritance = right, System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Property Data As %String [ Internal, MultiDimensional ];

Property Count As %Integer [ Internal ];

Parameter INDEX [ Internal ] = "ClientName";

/// Client name
Property ClientName As %Monitor.String;

/// Buffers for a client
Property Buffers As %Monitor.Integer;

/// Global kills sent to a client
Property GloKills As %Monitor.Integer;

/// Global refs sent to client
Property GloRefs As %Monitor.Integer;

/// Global sets sent to a client
Property GloSets As %Monitor.Integer;

/// Network cache hits
Property Hits As %Monitor.Integer;

/// Outgoing network IJC writes for a client
Property IJCw As %Monitor.Integer;

/// Lock commands sent to a client
Property Locks As %Monitor.Integer;

/// Network cache misses
Property Misses As %Monitor.Integer;

/// Requests sent by a client
Property Requests As %Monitor.Integer;

/// Retransmits for a client
Property Retransmits As %Monitor.Integer;

/// On Startup enable PERFMON
Method Startup() As %Status
{
 d ##class(%Monitor.Manager).StartSystemCounters(0)
 Quit $$$OK
}

/// Initialize client metrics
Method Initialize() As %Status
{
	 ; Collect global stats
	k stat Do ..GetStat("I",.stat)
	Merge ..Data = stat
	Set ..Count = 0
	Quit $$$OK
}

/// Get client metric sample
/// A return code of $$$OK indicates there is a new sample instance.
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	Set ..Count = ..Count+1
	I ..Count > ..Data Q 0
	Set ..ClientName=..Name(..Data(..Count,"Name"),"I")	; Client system
	Set ..Requests=$p(..Data(..Count,"Stat"),",",1)
	Set ..GloRefs=$p(..Data(..Count,"Stat"),",",2)
	Set ..GloSets=$p(..Data(..Count,"Stat"),",",3)
	Set ..GloKills=$p(..Data(..Count,"Stat"),",",4)
	Set ..Locks=$p(..Data(..Count,"Stat"),",",5)
	Set ..Buffers=$p(..Data(..Count,"Stat"),",",6)
	Set ..Retransmits=$p(..Data(..Count,"Stat"),",",7)
	Set ..Hits=$p(..Data(..Count,"Stat"),",",8)
	Set ..Misses=$p(..Data(..Count,"Stat"),",",9)
	Set ..IJCw=$p(..Data(..Count,"Stat"),",",10)
	Q $$$OK
}

}
