/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occIO, %syINET)

/// Common class members to both Socket and ServerSocket
Class %IO.SocketCommon [ Abstract, CompileAfter = %IO.I.Stream, System = 2 ]
{

Property Port As %String(MAXLEN = 6, TRUNCATE = 1);

Property InputBufferSize As %Integer [ InitialExpression = 32767 ];

Property OutputBufferSize As %Integer [ InitialExpression = 32767 ];

/// The name of an existing SSL/TLS system configuration set to use (Secure Socket Layer / Transport Layer Security, configured via the system portal's Security Management page). May include a certificate password after a '|' character for inbound connections.
Property SSLConfig As %String;

/// The IP address and port of the remote end of the socket connection
/// Time and IP address and port (and disconnect time) of the last connected remote socket
Property Remote As %String [ ReadOnly ];

/// Object on which to call OnDisconnect() when a connection is lost
Property DisconnectHandler As %RegisteredObject;

/// Connection-specific TCP keepalive interval in seconds. A setting of -1 means KeepAlive
/// should be disabled entirely. InterSystems IRIS supports per socket keepalive on Windows and Linux,
/// so this setting is ignored on other platforms. The default value of 0 will use the 
/// current system-wide TCP keepalive interval. Valid settings are -1, to disable keepalive 
/// entirely, and between 0 seconds and 432000 seconds (5 days), where positive values less than
/// 30 will be treated as a 30 second interval.
Property KeepAliveInterval As %Integer(MAXVAL = 432000, MINVAL = -1) [ InitialExpression = 0 ];

/// Control the size, in bytes, of the TCP Send Buffer (SO_SNDBUF) for the TCP device.
/// This should be used in conjunction with <property>TCPReceiveBuffer</property>
/// to increase the TCP window as per RFC1323. The primary use case is in situations
/// with high latency or bandwidth, where the default sizes of the respective buffers
/// may constrain throughput.
/// The default value of 0 will use the OS default setting.
Property TCPSendBuffer As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// Control the size, in bytes, of the TCP Receive Buffer (SO_RCVBUF) for the TCP device.
/// This should be used in conjunction with <property>TCPSendBuffer</property>
/// to increase the TCP window as per RFC1323. The primary use case is in situations
/// with high latency or bandwidth, where the default sizes of the respective buffers
/// may constrain throughput.
/// The default value of 0 will use the OS default setting.
Property TCPReceiveBuffer As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// In a multi-homed system, specify which local network interface the TCP connection should go through. An empty value means use any interface. See GetLocalInterfaces() to enumerate available choices.
Property LocalInterface As %String;

/// Override InitialExpression
Property LineTerminator As %String(TRUNCATE = 1) [ InitialExpression = {$Char(10)} ];

/// Override InitialExpression
Property AtEnd As %Boolean [ InitialExpression = 0, ReadOnly ];

Method WriteLine(pLine As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name)  Quit
	Set $ZT="Trap", tIO=$IO
	Use ..Name  Write pLine_..LineTerminator Write:$G(pFlush,1) *-3  Use tIO ; ..DefaultFlushOnWrite=1
	Set pSC=$$$OK
	Quit
Trap
	Set $ZT="", tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Use tIO
	If ..isWriteError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") { Do $method($this,"Disconnect",,0,pSC) }
		Else { Do ..Close(,0,pSC) }
	}
	Quit
}

/// Write pLine to the stream buffer, followed by the current LineTerminator characters. If pFlush is True, ensure that the characters are actually sent to the stream.
Method Write(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name)  Quit
	Set $ZT="Trap", tIO=$IO
	Use ..Name  Write pData Write:$G(pFlush,1) *-3	 Use tIO ; ..DefaultFlushOnWrite=1
	Set pSC=$$$OK
	Quit
Trap
	Set $ZT="", tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Use tIO
	If ..isWriteError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") { Do $method($this,"Disconnect",,0,pSC) }
		Else { Do ..Close(,0,pSC) }
	}
	Quit
}

/// Read until pMaxReadLen chars are gotten or pTimeout expires.
/// On return, if pTimeout=0 it means no timeout occurred and the returned string contains the full pMaxReadLen characters.
/// If pTimeout is unchanged it means the full timeout period expired before encountering pMaxReadLen chars and the returned string is shorter than pMaxReadLen.
Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Set $ZT="Trap", tIO=$IO, tData=""
	Use ..Name:(::"+") ; turn off terminators
	
	If -1=pTimeout { Read tData#pMaxReadLen  Set tTimedOut=0 }
	Else { Read tData#pMaxReadLen:pTimeout  Set tTimedOut='$Test }
	Set:'tTimedOut pTimeout=0
Exit
	Use tIO
	Quit tData
Trap
	Set $ZT="", tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Set pTimeout=0,tData=$G(tData)
	If ..isReadError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") { Do $method($this,"Disconnect",,0,pSC) }
		Else { Do ..Close(,0,pSC) }
		Set:""'=tData pSC=$$$OK
	}
	Goto Exit
}

/// Read until pMaxReadLen chars are gotten, pTimeout expires, or a LineTerminator character is encountered.
/// On return, if pTimeout=0 it means no timeout occurred. If pTimeout=0 and the returned string contains the full pMaxReadLen characters, it means no LineTerminator was encountered yet, even if the following character would be a LineTerminator.
/// If pTimeout=0 and the returned string is shorter than pMaxReadLen, then a LineTerminator was encountered.
/// If pTimeout is unchanged it means the full timeout period expired before encountering a LineTerminator character or pMaxReadLen chars and the returned string is shorter than pMaxReadLen.
/// On return, pLineTerminator contains the encountered LineTerminator character(s) if any.
Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout = -1, Output pSC As %Status, ByRef pLineTerminator As %String = {..LineTerminator}) As %String
{
	Set pSC=$$$OK, tZB=pLineTerminator, pLineTerminator=""
	Set tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Set $ZT="Trap", tIO=$IO, tData=""
	Use ..Name:(::"+":tZB) ; turn on terminators
	
	If -1=pTimeout { Read tData#pMaxReadLen  Set tTimedOut=0 }
	Else { Read tData#pMaxReadLen:pTimeout  Set tTimedOut='$Test }
	Set:'tTimedOut pTimeout=0
	Set pLineTerminator=$ZB
Exit
	Set pLen=$L(tData)
	Use tIO
	Quit tData
Trap
	Set $ZT="", tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Set pTimeout=0,tData=$G(tData)
	If ..isReadError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") { Do $method($this,"Disconnect",,0,pSC) }
		Else { Do ..Close(,0,pSC) }
		Set:""'=tData pSC=$$$OK
	}
	Goto Exit
}

/// Return as soon as any data arrives, or timeout expires, or MaxReadLen is reached
Method ReadAny(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Set $ZT="Trap", tIO=$IO, tData=""
	Use ..Name:(::"-S") ; turn off terminators, turn on Packet mode instead of Stream mode
	
	If -1=pTimeout { Read tData#pMaxReadLen  Set tTimedOut=0 }
	Else { Read tData#pMaxReadLen:pTimeout  Set tTimedOut='$Test }
	Set:'tTimedOut pTimeout=0
Exit
	Use:..IsOpen ..Name:(::"+S") ; turn off Packet, restore Stream mode
	Use tIO
	Quit tData
Trap
	Set $ZT="", tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$G(tZE))
	Set pTimeout=0,tData=$G(tData)
	If ..isReadError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") { Do $method($this,"Disconnect",,0,pSC) }
		Else { Do ..Close(,0,pSC) }
		Set:""'=tData pSC=$$$OK
	}
	Goto Exit
}

/// Ensure that any data already written to the TCP buffer are actually sent to the remote partner.
Method Flush(Output pSC As %Status)
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit
	Set pSC=$$$OK,tIO=$IO,$ZT="Trap"
	Use ..Name  Write *-3
Exit	
	Use tIO	Quit pSC
Trap
	Set $ZT="", tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	If ..isWriteError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") Do $method($this,"Disconnect",,0,pSC)
		Else  Do ..Close(,0,pSC)
	}
	Goto Exit
}

/// Get a list of link-local interface addresses
/// The output argument is an integer-subscripted array of local interface IP addresses. They may be IPv4 or IPv6 addresses. On LINUX systems the address will be suffixed with the name of the interface (e.g. %eth0). <p/>
/// After the IP address each list entry contains a space followed by, in parentheses, the text "IPv4" or "IPv6" depending on the type of interface, a space, and then the full name of the interface. <p/>
/// This entry may be set directly into the LocalInterface property of this class but only the IP address portion will be used in the binding of the socket to local network interfaces. <p/>
/// To be able to bind to IPv6 interfaces you may need to enable IPv6. This is done in the Management Portal by
/// going to System Administration / Configuration / Additional Settings / Startup and editing the IPv6 setting.
ClassMethod GetLocalInterfaces(Output pResults) As %Status
{
	Set tSC=$$$OK  Kill pResults
	Try {
		Set i=0, pResults=0
		Set i=i+1, pResults(i)="127.0.0.1 (any IPv4)"
		Set i=i+1, pResults(i)="::1 (any IPv6)"
		Kill %objlasterror
		Set list=##class(%SYSTEM.INetInfo).GetListOfConfiguredInterfaces()
		For j=1:1:$LL(list) {
			Try {
				Set tInterfaceLength = $LL($LI(list,j))
			} Catch { Set tInterfaceLength = 0 }
			For k=2:1:tInterfaceLength {
				Try {
					Set name=$LI($LI(list,j),1)
					Set addr=$P($P($LI($LI(list,j),k),"/"),"%")
				} Catch { Set addr = "" }
				If ""'=addr {
					Set:($ZCVT($$$CacheOS,"U")["LINUX")&&(name?1"%"1.L1.N) addr=addr_name
					Set name=$S($L(addr,":")>1:"IPv6 ",1:"IPv4 ")_name
					Set:""'=addr i=i+1, pResults(i) = addr_" ("_name_")"
				}
			}
		}
		Set pResults=i
	} Catch {
		Set tSC = $$$ERROR($$$ObjectScriptError,$ZE)
	}
	Quit tSC
}

}
