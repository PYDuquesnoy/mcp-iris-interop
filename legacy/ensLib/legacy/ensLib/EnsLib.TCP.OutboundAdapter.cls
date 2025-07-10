/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A generic, protocol-agnostic TCP adapter. Handles making connections. Traffic content is up to the associated Business Operation class.
Class EnsLib.TCP.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.TCP.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// IP Address to make a TCP connection to; may be prepended with @AgentName:.<p>
/// If IPAddress starts with '!', the Adapter will wait for a connection from a remote system. If no IP 
/// address follows the '!', any remote system may connect; otherwise any listed IP addresses/ports will 
/// be allowed to connect.<p>
/// After the '!' you may enter a comma-separated list of remote IP addresses to accept connections from,
/// with IP addresses in dotted decimal form for IPV4 and colon-hex form for IPV6, with optional :port for IPV4 and |port for IPV6,
/// e.g. 192.168.1.22, 192.168.1.22:3298 or fe80::4c60:9595:7fb3:8139, fe80::4c60:9595:7fb3:8139|3298.<br>
/// If :port or |port is specified, connections from other ports at the associated address will be refused.
Property IPAddress As %String(MAXLEN = 1000) [ Required ];

/// TCP Port to connect to
Property Port As %Integer(MAXVAL = 65535, MINVAL = 0) [ Required ];

/// Number of times the adapter attempts to send a message before dropping the connection and reconnecting. A value of 0 (zero) means that the adapter attempts to send the message forever without disconnecting. The default value is 5.
Property ReconnectRetry As %Integer(MINVAL = 0) [ InitialExpression = 5 ];

/// Number of seconds to wait on each connection attempt
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// If true, wait to read a reply message back from the socket before returning.
Property GetReply As %Boolean [ InitialExpression = 1 ];

/* Note: ResponseTimeout is only used in our subclasses */
/// Number of seconds to wait for a response to begin arriving back from the remote system after sending a request. Setting the timeout to -1 means wait forever.
Property ResponseTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 15 ];

Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=OTHER},IPAddress:Basic,Port:Basic,StayConnected:Connection,ConnectTimeout:Connection,ReconnectRetry:Connection,GetReply:Connection,ResponseTimeout:Connection";

/// Override initial value
Property KeepaliveInterval As %Numeric [ InitialExpression = 1 ];

Property %lastRetryReconnect As %Integer [ InitialExpression = 0 ];

/// How many incoming connections should the OS hold open on our behalf until we get around to dealing with them?
/// For outbound we don't need any QSize. Either we are outbound, or we are in '!' inbound mode, in which case only 1 client at a time (per BO pool job) is allowed.
Parameter QSize As %Integer = 0;

Method ConnectedSet(pValue As %Boolean) As %Status
{
	Set i%Connected=pValue
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_..IOAddr)
	Quit $$$OK
}

Method OnInit() As %Status
{
	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	/*	If the TCP.OuboundAdapter is being used by an InProc Operation
		that is called from a TCP based service need to ensure do not
		set the trace device to the service's TCP channel.
		See also this same line in EnsLib.File.OutboundAdapter.
	*/
	Set ..OldIO = $IO  Do ##class(Ens.Util.Trace).SetTraceDevice($S($IO?1"|TCP|".e:"",1:$IO))
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC)
	Set ..LocalInterface=$ZStrip($P(..LocalInterface,"("),"*W")
	If 0=..BusinessHost.%GetParameter("LOGCONNECTIONS") Set ..%logConnections=0
	If "!"'=$E(..IPAddress) {
		If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	} Else { ; If in wait-for-incoming-connection-before-write mode
		Set ..Device="|TCP|"_..Port
		$$$sysTRACE("Opening Port "_..Port_" to wait for incoming connection")
		Set $ZTrap="InTrap"
		If ..#QSize>0 {
			If ""=..SSLConfig {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..#QSize:/TCPNOXY:/BINDTO=..LocalInterface):..ConnectTimeout  Set tTimedOut='$Test
			} Else {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..#QSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..ConnectTimeout  Set tTimedOut='$Test
			}
		} Else {
			If ""=..SSLConfig {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface):..ConnectTimeout  Set tTimedOut='$Test
			} Else {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..ConnectTimeout  Set tTimedOut='$Test
			}
		}
		If tTimedOut {
			Set tDevice=..Device, ..Device=""
			Quit $$$EnsError($$$EnsErrTCPListen,..Port,..ConnectTimeout,"Open """_tDevice_""":(:"_..Port_":"""_..#Mode_"A-D"_""":"_..Terminators_":"_..#InputBufferSize_":"_..#OutputBufferSize_":"_$S(..#QSize>0:..#QSize,1:"1:/CLOSELISTEN")_":/TCPNOXY:"_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig)_"):"_..ConnectTimeout)
		}
		Use ..Device
		Do SetIO^%NLS("RAW") ; turn off translation mode
		Use ..OldIO
		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,".|"_$$$timeUTC)
		$$$EnsCheckSSLConfig(..SSLConfig)
	}
	Quit $$$OK
InTrap
	Set $ZT="",tSC=$$$SystemError
	Quit $$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),"TCP listen",..IOAddr)
}

Method Connect(pTimeout As %Numeric) As %Status
{
	Set tWasConnected=..Connected
	If ..Connected {
		Do ..TestConnection()
		If ..ReconnectRetry>0 {
			#; Disconnect after this number of connected retry attempts so we can try re-connecting 
			If ..Connected {
				If ..BusinessHost.RetryCount<=1 { Set ..%lastRetryReconnect=1 }
				ElseIf ..BusinessHost.RetryCount>=(..ReconnectRetry+..%lastRetryReconnect) {
					$$$LOGINFO("Attempting to re-connect on try #"_..BusinessHost.RetryCount_" (ReconnectRetry value is "_..ReconnectRetry)
					Set ..%lastRetryReconnect=..BusinessHost.RetryCount
					Do ..Disconnect()
				} ; Else just do a regular connected retry
			} Else { Set ..%lastRetryReconnect=..BusinessHost.RetryCount }
		}
		Quit:..Connected $$$OK
	}
	If "!"'=$E(..IPAddress) {
		$$$catTRACE("connwait","Trying to open TCP connection to "_..IPAddress_$S(..IPAddress[":":"|",1:":")_..Port_":/SSL="_..SSLConfig_" with timeout="_pTimeout)
		Set $ZT="OutTrap", tSC=$$$OK
		Set ..Device="|TCP|"_..Port_"|"_$P($Job,":")
		If ""=..SSLConfig {
			Open ..Device:(..IPAddress:..Port:..#Mode_"-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface):pTimeout
		} Else {
			Open ..Device:(..IPAddress:..Port:..#Mode_"-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):pTimeout
		}
		If '$Test {
			Set $ZT=""
			Quit $$$ERROR($$$EnsErrOutConnectExpired,pTimeout,"TCP",..IPAddress_$S(..IPAddress[":":"|",1:":")_..Port)
		}
		Use ..Device
		Set ..IOAddr=..IPAddress_$S(..IPAddress[":":"|",1:":")_..Port_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig), ..Connected=1, tTxt="Opened TCP connection to "_..IOAddr
		If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
	} Else { ; If in wait-for-incoming-connection-before-write mode
		$$$catTRACE("connwait","Waiting for connection on port "_..Port_" with timeout "_pTimeout)
		Set $ZT="InTrap", tSC=$$$OK
		If ""=..Device {
			Set ..Device="|TCP|"_..Port
			If ..#QSize>0 {
				If ""=..SSLConfig {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..#QSize:/TCPNOXY:/BINDTO=..LocalInterface):..ConnectTimeout  Set tTimedOut='$Test
				} Else {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..#QSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..ConnectTimeout  Set tTimedOut='$Test
				}
			} Else {
				If ""=..SSLConfig {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface):..ConnectTimeout  Set tTimedOut='$Test
				} Else {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..ConnectTimeout  Set tTimedOut='$Test
				}
			}
			If tTimedOut {
				Set tDevice=..Device, ..Device=""
				Set tSC=$$$EnsError($$$EnsErrTCPListen,..Port,..ConnectTimeout,"Open """_tDevice_""":(:"_..Port_":"""_..#Mode_"A-D"_""":"_..Terminators_":"_..#InputBufferSize_":"_..#OutputBufferSize_":"_$S(..#QSize>0:..#QSize,1:"1:/CLOSELISTEN")_":/TCPNOXY:"_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig)_"):"_..ConnectTimeout)
				Quit
			}
		}
		Use ..Device
		Read tDummy:pTimeout Set tNewConnection=$Test
		If tNewConnection {
			Set tIPOK=##class(%IO.ServerSocket).remoteIPAllowed($E(..IPAddress,2,*),.tRemote,.tSC1)
			If tIPOK {
				Set ..IOAddr="!"_..Port_"<-"_tRemote_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig), ..Connected=1, tTxt="Accepted connection on port "_..Port_" from "_tRemote
				If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
			} Else {
				Write *-2
				Set $ZT="InTrap2"
				Use ..OldIO
				$$$LOGWARNING("Rejected connection attempt on port "_..Port_" from "_tRemote_" which was not found in AllowedIPAddresses list '"_..IPAddress_"'"_$S($$$ISOK(tSC1):"",1:" :"_$$$StatusDisplayString(tSC1)))
				Quit $$$ERROR($$$EnsErrOutConnectExpired,pTimeout,"TCP","port:"_..Port)
			}
		} Else {
			Set $ZT="InTrap2"
			Use ..OldIO
			Quit $$$ERROR($$$EnsErrOutConnectExpired,pTimeout,"TCP listen","port:"_..Port)
		}
	}
	Set:'$IsObject(..Socket) ..Socket=..SocketNewObject()
	Do ..Socket.Attach(..Device)
	Set:""'=..Terminators ..Socket.LineTerminator=..Terminators
	Set $ZT="OnConnectTrap"
	Set tSC=..BusinessHost.OnConnect(pTimeout)  Do:$$$ISERR(tSC) ..Disconnect()
OnConnectTrap
	If $$$ISOK(tSC) && 'tWasConnected && (""'=..BusinessHost.%LastReportedError) && ("ERROR <Ens>ErrOutConnectExpired:"=$E(..BusinessHost.%LastReportedError,1,$L("ERROR <Ens>ErrOutConnectExpired:"))) {
		Set ..BusinessHost.%LastReportedError=""
		$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
	}
	Quit tSC
InTrap
	Set $ZT="InTrap2",tSC=$$$SystemError
	#; Reopen the listener device in case it got messed up ; in wait-for-incoming-connection-before-write mode
	$$$LOGINFO("Re-opening Port "_..Port_" to wait for incoming connection")
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC)
	If ..#QSize>0 {
		If ""=..SSLConfig {
			Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..#QSize:/TCPNOXY:/BINDTO=..LocalInterface):..ConnectTimeout  Set tTimedOut='$Test
		} Else {
			Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..#QSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..ConnectTimeout  Set tTimedOut='$Test
		}
	} Else {
		If ""=..SSLConfig {
			Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface):..ConnectTimeout  Set tTimedOut='$Test
		} Else {
			Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..ConnectTimeout  Set tTimedOut='$Test
		}
	}
	If tTimedOut {
		$$$LOGWARNING("Reopen Failed: Open """_..Device_""":(:"_..Port_":"""_..#Mode_"A-D"_""":"_..Terminators_":"_..#InputBufferSize_":"_..#OutputBufferSize_":"_$S(..#QSize>0:..#QSize,1:"1:/CLOSELISTEN")_":/TCPNOXY:"_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig)_"):"_..ConnectTimeout)
	} Else {
		Use ..Device
		Do SetIO^%NLS("RAW") ; turn off translation mode
		Use ..OldIO
		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,".|"_$$$timeUTC)
	}
Exit
	Quit $$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),"TCP listen",..IOAddr)
InTrap2
	Set $ZT="",tSCx=$$$EnsSystemError
	Goto Exit
OutTrap
	Set $ZT="", tSC=$$$SystemError
	Quit $$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),"TCP",..IOAddr)
}

Method Disconnect()
{
	Set $ZT="Trap", tSC=$$$OK
	If ..Connected {
		Set tTxt="Disconnecting from  "_..IOAddr
		If ..StayConnected&&..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
	}
	If "!"=$E(..IPAddress)&&(""'=..Device) {
		#; go ahead and try to disconnect even if we think we're already disconnected - we'll just trap out or fail if we already are
		Use ..Device  Write *-2
	}
Exit
	Quit:'..Connected
	Set ..IOAddr="", ..Connected=0
	If $IO=..Device Use ..OldIO
	#; If using /CLOSELISTEN, we must close and reopen in order to be able to listen again
	If (("!"'=$E(..IPAddress))||(..#QSize<=0))&&(""'=..Device) Close ..Device  Set ..Device=""
	Quit
Trap
	Set $ZT="", tSC=$$$EnsSystemError
	Goto Exit
}

/// Fix up the properties reflecting our connection state in case we thought we were connected but we lost the socket.
Method TestConnection()
{
	Quit:'..Connected
	Set $ZT="Trap", tSC=$$$OK
	Quit:$zu(189)
Exit
	Set tTxt = $$$StatusText($$$ERROR($$$EnsErrOutConnectionLost,"TCP", ..IOAddr, $S($$$ISOK(tSC):"$zu(189)",1:$$$StatusDisplayString(tSC))))
	If ..%logConnections { If ..StayConnected<0 { $$$LOGWARNING(tTxt) } Else { $$$LOGINFO(tTxt) } } Else { $$$sysTRACE(tTxt) }
	Do ..Disconnect()
	Quit
Trap
	Set $ZT="", tSC=$$$EnsSystemError
	Goto Exit
}

Method OnTearDown() As %Status
{
	Quit:""=..Device $$$OK
	Do ..Disconnect()
	If "!"=$E(..IPAddress) {
		Quit:""=..Device $$$OK
		Set $ZT="Trap"
		Use ..OldIO
		Close ..Device
	}
Exit
	Quit $$$OK
Trap
	Set $ZT="", tSC=$$$EnsSystemError
	Goto Exit
}

Method OnKeepalive(pUnused As %Status) As %Status
{
	Set tSC=$$$OK
	If ..Connected && (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
		$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
		Do ..Disconnect()
	} Else {
		Do:..Connected ..TestConnection()
	}
	If ..StayConnected<0&&'..Connected Set tSC=..Connect(..ConnectTimeout)
	Quit ##super(tSC)
}

}
