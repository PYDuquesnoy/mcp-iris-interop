/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Load-Balancing is implemented in a round robin fashion. 
/// Each new user session will be connected to the next available 'alternative' server 
/// (including the 'Default' Server).  Once a user session is established on a server, 
/// the Gateway will endeavor to maintain the session on that server unless it becomes unavailable, 
/// in which case the session will be failed-over to the next available server in the list.  
/// State-aware sessions (preserve mode = 1) cannot be failed-over under any circumstances and, 
/// consequently, the session will be closed if the hosting server becomes unavailable.
/// </br >This object is part of the <class>%CSP.Mgr.GatewaySystemStatus</class> object.
Class %CSP.Mgr.Helper.AlternativeServer Extends (%SerialObject, %XML.Adaptor)
{

Parameter XMLIGNOREINVALIDTAG As BOOLEAN = 1;

Parameter XMLIGNORENULL As STRING = 1;

Property CacheServerName As %String;

Property Activity As %String;

/// The purpose for which this server is being used.
/// <p>Use for Load-Balancing. (Fail-over in implied for this option).</p>
/// <p>Use for Fail-over only. (Use the alternatives only if the main (i.e. default) 
/// server becomes unavailable.)</p>
/// <p>Disable. (Do not connect to the alternative servers under any circumstances.)</p>
Property Status As %String;

Storage Default
{
<Data name="AlternativeServerState">
<Value name="1">
<Value>CacheServerName</Value>
</Value>
<Value name="2">
<Value>Activity</Value>
</Value>
<Value name="3">
<Value>Status</Value>
</Value>
</Data>
<State>AlternativeServerState</State>
<StreamLocation>^%CSP.Mgr.H7E9C.AlternativeEB55S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
