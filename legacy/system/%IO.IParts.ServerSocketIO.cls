/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %IO.IParts.ServerSocketIO [ Abstract, System = 2 ]
{

/// Is there a connection open from a remote client
Property IsConnected As %Boolean [ ReadOnly ];

/// A comma-separated list of remote IP addresses to accept connections from optional. Accepts IP addresses in dotted decimal form for IPV4 and colon-hex form for IPV6, with optional :port for IPV4 and |port for IPV6, e.g. 192.168.1.22, 192.168.1.22:3298 or fe80::4c60:9595:7fb3:8139, fe80::4c60:9595:7fb3:8139|3298.<br>
/// If :port or |port is specified, connections from other ports at the associated address will be refused.
Property AllowedClientIPAddresses As %String(TRUNCATE = 1);

/// Number of connections that can queue up waiting for this server socket to attend to them.
Property ConnectionQueueSize As %Integer(MINVAL = 0) [ InitialExpression = 1 ];

Method DefaultFlushOnWriteGet() [ CodeMode = expression ]
{
1
}

Method Listen(ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean [ Abstract ]
{
}

Method ListenJob(ByRef pTimeout As %Numeric = -1, pOnConnectedClass As %String, pJobArgs As %String, pSocketClass As %String = "%IO.ServerSocket", pMaxJobs As %Integer = -1, pForeground As %Boolean = 0, Output pSC As %Status) As %Integer [ Abstract ]
{
}

Method Open(pPort As %String, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean [ Abstract ]
{
}

}
