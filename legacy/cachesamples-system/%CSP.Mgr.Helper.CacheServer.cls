/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// </br >This object is part of the <class>%CSP.Mgr.GatewaySystemStatus</class> object.
Class %CSP.Mgr.Helper.CacheServer Extends (%SerialObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

Parameter XMLIGNORENULL As STRING = 1;

/// Name of the system connected to.
Property CacheServerName As %String;

/// Name of the Mirror Member connected to.
Property MirrorMember As %String;

/// Status of the Mirror Member connected to.
Property MirrorStatus As %String;

/// IP address of the system.
Property IPAddress As %String;

/// TCP port on the InterSystems IRIS server through which the connectin communicates.
Property TCPPort As %String;

/// Number of connections to the InterSystems IRIS server
Property TotalConnections As %Integer;

/// Number of connections that are currently in use (actively serving a Web request).
Property ConnectionsInUse As %Integer;

/// Number of connections that are currently in use as state-aware sessions (preserve mode 1).
Property PrivateConnections As %Integer;

/// Total number of transactions (hits) the system has processed.
Property Activity As %String;

/// Number of Web requests that are held in a queue waiting for a free connection 
/// to the InterSystems IRIS server Queued requests are an indication that the InterSystems IRIS license should be increased in order to maintain good performance.
Property QueuedRequests As %Integer;

Storage Default
{
<Data name="CacheServerState">
<Value name="1">
<Value>CacheServerName</Value>
</Value>
<Value name="2">
<Value>IPAddress</Value>
</Value>
<Value name="3">
<Value>TCCPPort</Value>
</Value>
<Value name="4">
<Value>TotalConnections</Value>
</Value>
<Value name="5">
<Value>ConnectionsInUse</Value>
</Value>
<Value name="6">
<Value>PrivateConnections</Value>
</Value>
<Value name="7">
<Value>Activity</Value>
</Value>
<Value name="8">
<Value>QueuedRequests</Value>
</Value>
<Value name="9">
<Value>TCPPort</Value>
</Value>
<Value name="10">
<Value>MirrorMember</Value>
</Value>
<Value name="11">
<Value>MirrorStatus</Value>
</Value>
</Data>
<State>CacheServerState</State>
<StreamLocation>^%CSP.Mgr.Helper.CacheServerS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
