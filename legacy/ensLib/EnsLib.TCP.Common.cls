/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %syINET)

Class EnsLib.TCP.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// The default value of -1 means to stay permanently connected, even during idle times, and treat a disconnection as an error. <br/>
/// If the value is a positive number, then the adapter will stay connected to the remote system between handling requests until idle for this number of seconds. <br/>
/// A zero value means to disconnect immediately after every input event. 
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/* Note: ReadTimeout is only used in our subclasses */
/// Number of seconds to wait for each successive incoming TCP read, following receipt of initial data from remote TCP port.
Property ReadTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// The name of an existing SSL/TLS system configuration to use (Secure Socket Layer / Transport Layer Security), which can be configured in the System Management Portal 
/// under System Administration > Security. <br/>
/// <p>If your SSL Configuration requires you to supply a password for the local private key file, specify it in 
/// the Private key password property of the SSL/TLS Configuration.
Property SSLConfig As %String;

/// In a multi-homed system, specify which network interface the TCP connection should go through.  An empty value means to use any interface. <br/>
/// To be able to bind to IPv6 interfaces you may need to enable IPv6 in your InterSystems IRIS instance.  This is done in the System Management Portal under 
/// System Administration > Configuration > Additional Settings > Startup, by editing the IPv6 setting.
Property LocalInterface As %String(MAXLEN = 250);

Parameter SETTINGS = "StayConnected:Connection,ReadTimeout:Connection,SSLConfig:Connection:sslConfigSelector,LocalInterface:Connection:selector?context={Ens.ContextSearch/TCPLocalInterfaces}";

/// Read-terminator character or characters, if any, for subclasses that do terminated reads.
Property Terminators As %String;

/* Default Mode value 'S-D' means Stream mode, <DISCONNECT> exceptions disabled */
/// The Device Mode that will be used to open the TCP socket
Parameter Mode As %String = "S";

Parameter InputBufferSize As %Integer = 32767;

Parameter OutputBufferSize As %Integer = 32767;

Property Device As %String;

Property Connected As %Boolean [ InitialExpression = 0 ];

Property OldIO As %String(MAXLEN = 1000) [ InitialExpression = 0 ];

/// Local flag controlling logging of connection and disconnection events.
Property %logConnections As %Boolean [ InitialExpression = 1 ];

/// String naming remote TCP/IP address:port, and local port if applicable
Property IOAddr As %String;

/// IOStream object for TCP device
Property Socket As %IO.DeviceStream;

ClassMethod FlushWrite()
{
 Set tSC=$$$OK
 Do {
  Write *-3 // flush buffer
  $$$sysTRACE("TCP Flushed Write Buffer")
 } While 0
Exit
 Quit tSC
Trap
 Set $ZT="",tZE=$ZE,tSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
 Goto Exit
}

ClassMethod IsReadError(pSC As %Status) As %Boolean
{
	Set tText=$$$StatusText(pSC)  Quit tText["<READ>"||(tText["<NOTOPEN>")
}

ClassMethod IsWriteError(pSC As %Status) As %Boolean
{
	Set tText=$$$StatusText(pSC)  Quit tText["<WRITE>"||(tText["<NOTOPEN>")
}

Method GetAddress() As %String [ CodeMode = expression ]
{
..IOAddr
}

}
