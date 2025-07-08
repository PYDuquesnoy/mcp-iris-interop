/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %IO.Socket Extends (%IO.DeviceStream, %IO.IParts.SocketIO, %IO.SocketCommon) [ Inheritance = right, System = 2 ]
{

Property Host As %String(MAXLEN = 500);

/// Establish a TCP connection to the given host computer on the given port number, if possible within pTimeout.
Method Open(pHost As %String = "", pPort As %String = "", ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean
{
	#; Must close before calling Open() again
	If i%IsOpen Set pSC = $$$ERROR($$$FileAlreadyOpen,..Name_"/"_..Host_$S(..Host[":":"|",1:":")_..Port) Quit 0
	Set:""=pHost pHost=..Host
	Set:""=pPort pPort=..Port
	Set ..Name="|TCP|"_pPort_"|"_$P($Job,":")_$P($this,"@")

	If ""=pHost||(""=pPort) Set pSC = $$$ERROR($$$FileCanNotOpen,..Name_"/"_pHost_$S(..Host[":":"|",1:":")_pPort) Quit 0

	Set $ZT="Trap",pSC=$$$OK
	Set ..LocalInterface=$ZStrip($P(..LocalInterface,"("),"*W")

	#; Note: the LineTerminator will be set on each Read()
	If -1=pTimeout {
		If ""=..SSLConfig {
			If ..KeepAliveInterval = -1 {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE) Set tTimedOut=0
			}
			Else {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval) Set tTimedOut=0
			}
		} Else {
			If ..KeepAliveInterval = -1 {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig) Set tTimedOut=0
			}
			Else {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig) Set tTimedOut=0
			}
		}
	} Else {
		If ""=..SSLConfig {
			If ..KeepAliveInterval = -1 {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE):pTimeout Set tTimedOut='$Test
			}
			Else {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval):pTimeout Set tTimedOut='$Test
			}
		} Else {
			If ..KeepAliveInterval = -1 {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig):pTimeout Set tTimedOut='$Test
			}
			Else {
				Open ..Name:(pHost:pPort:"SW-D"::..InputBufferSize:..OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig):pTimeout Set tTimedOut='$Test
			}
		}
	}
	If tTimedOut Set pSC=$$$ERROR($$$ErrIOOpenTimeout,..Name,pTimeout) Quit 0
	
	Do ..initDeviceTranslationTable()
	Set i%IsOpen=1,i%AtEnd=0,..Host=pHost,..Port=pPort,pTimeout=0
	Set tIO=$IO Use ..Name
	Set tRemote=$zu(111,0), ps=$S($L(tRemote)>6:"|",1:":"), tRemote=$$$IPBinaryToText($E(tRemote,1,*-2))_ps_$ZWAscii($Reverse($E(tRemote,*-1,*)))
	Set i%Remote=$ZDT($ZTS,3,,3)_"|"_tRemote
	Use tIO
	Quit 1
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Close ..Name
	Quit 0
}

/// Disconnect and close the current connection
Method Close(Output pSC As %Status, pIntentional As %Boolean = 1, pSCReason As %Status = {$$$OK}) As %Boolean
{
	If 'i%IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit 0
	Set $ZT="Trap",pSC=$$$OK
	Close ..Name
Trap
	Set $ZT="", i%IsOpen=0, i%AtEnd=1, i%Remote=i%Remote_"|"_$ZDT($ZTS,3,,3)
	If $IsObject(..DisconnectHandler) {
		Set $ZT="UserTrap"
		Do ..DisconnectHandler.OnDisconnect($this,pIntentional,pSCReason)
	}
UserTrap
	Quit 1
}

Method IsOpenGet() As %Boolean [ Internal ]
{
	Quit:'i%IsOpen 0
	Set $ZT="Trap", tIO=$IO
	Use ..Name  Set tOK=$zu(189)
	If tOK Use tIO Quit 1	
Trap
	Set $ZT=""  Use tIO  Do ..Close(,0)
	Quit 0
}

}
