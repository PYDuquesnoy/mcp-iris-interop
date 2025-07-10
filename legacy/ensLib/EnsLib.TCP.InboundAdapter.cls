/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A generic, protocol-agnostic TCP adapter. Handles making connections. Traffic content is up to the associated Business Service class.
Class EnsLib.TCP.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.TCP.Common) [ Abstract, ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// TCP Port to connect to (integer value below 65536), may be prepended with @AgentName:
Property Port As Ens.DataType.TCPAgentPort [ Required ];

/// Spawn a new Job to handle each incoming TCP connection. Allows simultaneous handling of multiple connections. <br/>
/// Note that the performance of this setting can be affected by changing the configured QSize setting of this adapter and by configuring Job Servers as a system configuration option.
/// Note also that when JobPerConnection=1, PoolSize is used to limit the number of connection jobs if it is configured with a value greater than 1.
Property JobPerConnection As %Boolean [ InitialExpression = 1 ];

/// Optional comma-separated list of remote IP addresses to accept connections from.<p>
/// You may enter a comma-separated list of remote IP addresses to accept connections from,
/// with IP addresses in dotted decimal form for IPV4 and colon-hex form for IPV6, with optional :port for IPV4 and |port for IPV6, e.g.<p>
/// 192.168.1.22, 192.168.1.22:3298 or fe80::4c60:9595:7fb3:8139, fe80::4c60:9595:7fb3:8139|3298.<p>
/// If :port or |port is specified, connections from other ports at the associated address will be refused.<p>
/// If AllowedIPAddresses starts with a '!', the Adapter will initiate a connection to the specified address. In this case only one address may be given.
/// If a port is included, it will supersede the value of the Port setting; otherwise the Port setting will be used to connect to the remote system.<p>
/// Leaving this value empty means connections will be accepted from any remote IP address.
Property AllowedIPAddresses As %String(MAXLEN = 1000);

/// How many incoming connections should the OS hold open until the Business Service processes them. <p>
/// The default value is 100 and the maximum allowed value is 1000.<br>
/// However, the maximum incoming connections the OS can hold open until the Business Service processes them depends on the TCP implementation.<p>
/// Set to 0 if only one connection at a time is expected and subsequent connections ought to be refused immediately by the OS.<p>
/// Note: If QSize is 0 a client attempting to connect will be refused connection by the operating system (RST,ACK) if the Business Service is processing a previous incoming connection.<br>
/// This could lead to a scenario where a client is connected to the Business Service but disconnects and attempts
/// to reconnect again in the brief period before the listening socket is re-opened by the Business Service and the client does not retry to connect as a result.
Property QSize As %Integer(MAXVAL = 1000, MINVAL = 0) [ InitialExpression = 100 ];

Parameter SETTINGS = "Port:Basic,JobPerConnection:Connection,AllowedIPAddresses:Connection,QSize:Connection";

Parameter OpenTimeout As %Numeric = 5;

Property %outIPAddr As %String;

/// Force a single listener job regardless of PoolSize setting
Parameter SINGLEPOOLJOB As %Boolean = 1;

Property %warnedConnect As %String [ Internal ];

Property %PoolLimit As %Integer;

Property %warnedLimit As %Boolean [ Internal ];

Property %tracedLimit As %Boolean [ Internal ];

/// In your Service or subclass, set this flag to force a "!" outbound connection attempt in OnTask even if StayConnected is not -1.
Property %OutDataReady As %Boolean [ InitialExpression = 1, Internal ];

Method ConnectedSet(pValue As %Boolean) As %Status
{
	Set i%Connected=pValue
	If ""=..%outIPAddr { ; normal listen-for-connection mode
		#; empty $zu(53) means it's not a tcp spawned child worker job
		Set:'pValue&&..JobPerConnection&&(""=$ZU(53))&&(..QSize>0) pValue="." ; marker for listening mode
	}
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_..IOAddr)
	Quit $$$OK
}

Method OnInit() As %Status
{
	Quit:$G($$$EnsJobLocal("TCPIn.OutsideJob")) $$$OK ; do nothing if SOAP CSP job
	Set tSC=##super()  Quit:$$$ISERR(tSC) tSC
	Set ..OldIO=$IO  Do ##class(Ens.Util.Trace).SetTraceDevice(..OldIO)
	Set ..LocalInterface=$ZStrip($P(..LocalInterface,"("),"*W")
	If 0=..BusinessHost.%GetParameter("LOGCONNECTIONS") Set ..%logConnections=0
	Do $ZU(68,57,1) ; turn on PSW2NOTHROTTLE bit to bypass throttle
	Set:..StayConnected>0 ..KeepaliveInterval=..StayConnected
	
	#; $ZU(53) means it's a tcp spawned job
	Set tDevice = $ZU(53)
	If ""'=tDevice {
		#; initialize for spawned TCP job (only possible in normal listen-for-connection mode)
		Set ..Device = tDevice
		If ""=..SSLConfig {
			Use tDevice:(::..#Mode_"-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:0:/TCPNOXY)
		} Else {
			Use tDevice:(::..#Mode_"-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:0:/TCPNOXY:/SSL=..SSLConfig)
		}
		Do SetIO^%NLS("RAW") ; turn off translation mode
		Set tRemote=$zu(111,0), ps=$S($L(tRemote)>6:"|",1:":"), tRemote=$$$IPBinaryToText($E(tRemote,1,*-2))_ps_$ZWAscii($Reverse($E(tRemote,*-1,*)))
		Set ..IOAddr=..Port_"<-"_tRemote_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig), ..Connected=1
		Use ..OldIO
		$$$sysTRACE("Using device '"_tDevice_"' in spawned TCP job "_$J_" on port "_..Port_" from "_tRemote)
		Set:'$IsObject(..Socket) ..Socket=..SocketNewObject()
		Do ..Socket.Attach(..Device)
		Set:""'=..Terminators ..Socket.LineTerminator=..Terminators
		Set $ZT="OnConnectTrap"
		Set tSC=..BusinessHost.OnConnect(0)  If $$$ISERR(tSC) Do ..Disconnect()  Quit
OnConnectTrap
	} Else {
		#; initialize for main TCP listener job
		If "!"'=$E(..AllowedIPAddresses) { ; normal listen-for-connection mode
			Set ..%PoolLimit=$$$ConfigPoolSize(..BusinessHost.%ConfigName)  Kill ^IRIS.Temp.EnsTCPJobs($Job)
			Set ..%outIPAddr=""
			Set ..Device="|TCP|"_..Port
			$$$sysTRACE("Opening Port "_..Port_" to listen for incoming connections")
			$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC)
			If ..QSize>0 {
				If ""=..SSLConfig {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..QSize:/TCPNOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
				} Else {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..QSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
					$$$EnsCheckSSLConfig(..SSLConfig)
				}
			} Else {
				If ""=..SSLConfig {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
				} Else {
					Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
					$$$EnsCheckSSLConfig(..SSLConfig)
				}
			}
			If tOpenFailed {
				Set tDevice=..Device, ..Device=""
				Quit $$$EnsError($$$EnsErrTCPListen,..Port,..#OpenTimeout,"Open """_tDevice_""":(:"_..Port_":"""_..#Mode_"A-D"_""":"_..Terminators_":"_..#InputBufferSize_":"_..#OutputBufferSize_":"_$S(..QSize>0:..QSize,1:"1:/CLOSELISTEN")_":/TCPNOXY:"_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig)_"):"_..#OpenTimeout)
			}
			$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,".|"_$$$timeUTC)
			Use ..Device
			Do SetIO^%NLS("RAW") ; turn off translation mode
			Use ..OldIO
		} Else { ; If in connect-and-read mode
			Set tAddr=$P($E(..AllowedIPAddresses,2,*),","), ps=$S($L(tAddr,":")<=2:":",1:"|"), tPort=$P(tAddr,ps,2)
			Set ..%outIPAddr=$P(tAddr,ps)  Set:""'=tPort ..Port=tPort
			If ..StayConnected Set tSC=..ConnectOut(..CallInterval)  If $$$ISERR(tSC) Set tTxt=$$$StatusDisplayString(tSC) $$$LOGWARNING(tTxt)  Set ..%warnedConnect=tTxt // timeout is not fatal at this point, but do log it
		}
		If ..StayConnected>=0 Set ..BusinessHost.%LastReportedError=$$$StatusDisplayString($S(""'=..%outIPAddr:$$$ERROR($$$EnsErrInNoConnectionIP,..%outIPAddr_$S(..%outIPAddr[":":"|",1:":")_..Port,..CallInterval),1:$$$ERROR($$$EnsErrInNoConnectionPort,..Port,..CallInterval))) ; Prime %LastReportedError so it doesn't alert the first time if no connection arrives provided connection not required
	}
	Quit $$$OK
}

Method OnTearDown() As %Status
{
	Quit:""=..Device $$$OK
	Do ..Disconnect()
	Quit:""=..Device $$$OK
	Set $ZT="Trap"
	Use ..OldIO
	Close ..Device
Exit
	Quit $$$OK
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method OnTask() As %Status
{
	#; $ZU(53) means it's a tcp spawned child worker job
	If ""'=$ZU(53) {
		Set tSC=$$$OK, $ZT="ChildTrap"
		Use ..Device
		Set $ZT="OCTrap"
		Set tSC=..OnConnected()
		If $$$ISERR(tSC) $$$sysTRACE("OnConnected() returned %QuitTask="_..BusinessHost.%QuitTask_", '"_$$$StatusText(tSC)_"'")
		Set $ZT="ChildTrap"
		
		If '..StayConnected||$$$ISERR(tSC) { Do ..Disconnect() }
		Else { Do ..TestConnection() }
		If '..Connected Set ..BusinessHost.%QuitTask=1  Set tTxt="Closing TCP Connection Job"  If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
	} Else {
		#; ... otherwise it's the master listener job
		Set tSC=$$$OK, $ZT="Trap"
		Do {
			Use:..Connected ..Device
			Do:..Connected ..TestConnection()
			Set tWasConnected=..Connected
			If '..Connected {
				If ""=..%outIPAddr {
					If ..%PoolLimit<=1 || (..%PoolLimit>$G(^IRIS.Temp.EnsTCPJobs($Job,"children"))) {
						If ""=..Device {
							Set ..Device="|TCP|"_..Port
							If ..QSize>0 {
								If ""=..SSLConfig {
									Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..QSize:/TCPNOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
								} Else {
									Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..QSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
								}
							} Else {
								If ""=..SSLConfig {
									Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
								} Else {
									Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
								}
							}
							If tOpenFailed {
								Set tDevice=..Device, ..Device=""
								Set tSC=$$$EnsError($$$EnsErrTCPListen,..Port,..#OpenTimeout,"Open """_tDevice_""":(:"_..Port_":"""_..#Mode_"A-D"_""":"_..Terminators_":"_..#InputBufferSize_":"_..#OutputBufferSize_":"_$S(..QSize>0:..QSize,1:"1:/CLOSELISTEN")_":/TCPNOXY:"_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig)_"):"_..#OpenTimeout)
								Quit
							}
						}
						$$$catTRACE("connwait","Waiting for connection on port "_..Port_" with timeout "_..CallInterval)
						$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,".|"_$$$timeUTC)
						Use ..Device
						Read tDummy:..CallInterval Set tNewConnection=$Test
						If tNewConnection {
							Set tIPOK=##class(%IO.ServerSocket).remoteIPAllowed(..AllowedIPAddresses,.tRemote,.tSC1)
							If tIPOK {
								Set ..IOAddr=..Port_"<-"_tRemote_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig), ..Connected=1
							} Else {
								Do ..Disconnect()
								$$$LOGWARNING("Rejected connection attempt on port "_..Port_" from "_tRemote_" which was not found in AllowedIPAddresses list '"_..AllowedIPAddresses_"'"_$S($$$ISOK(tSC1):"",1:" :"_$$$StatusDisplayString(tSC1)))
							}
							Set ..%tracedLimit=0 ; reset when below pool limit
						}
					} Else { ; limit reached; don't accept new connections
						If '..%warnedLimit { Set ..%warnedLimit=1 $$$LOGWARNING("Not accepting new connections because limit of "_..%PoolLimit_" connection jobs has been reached") }
						ElseIf '..%tracedLimit { Set ..%tracedLimit=1 $$$sysTRACE("Not accepting new connections because limit of "_..%PoolLimit_" connection jobs has been reached") }
					}
				}
				Else { ; If in connect-and-read mode
					If ..StayConnected=-1 || ..%OutDataReady {
						Set tSC=..ConnectOut(..CallInterval)
						If $$$ISERR(tSC) { Set tTxt=$$$StatusDisplayString(tSC)
							If tTxt'=..%warnedConnect { $$$LOGWARNING(tTxt)  Set ..%warnedConnect=tTxt }
							Else { $$$catTRACE("connwait",tTxt) }
							Set tSC=$$$OK // timeout is not fatal at this point, but do log it
						} Else { Set ..%warnedConnect="" }
					} Else {
						$$$catTRACE("connwait","Not attempting to connect out because no output data is ready")
					}
				}
			}
			If ..Connected {
				If 'tWasConnected {
					Set tTxt="New connection"_$S(""=..%outIPAddr:" on port "_..Port_" from "_tRemote, 1:" to "_..%outIPAddr_$S(..%outIPAddr[":":"|",1:":")_..Port)
					If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
					If ""=..%outIPAddr {
						If ..JobPerConnection {
							Job ClassMethod^%apiOBJ(..%ClassName(1),"connectedJob",..BusinessHost.%ConfigName,..%PoolLimit):(:65560)
							$$$sysTRACE("spawned TCP socket reader '"_$zchild_"'")
							Do ..Disconnect()
							#; don't hang around before listening again
							Set ..BusinessHost.%WaitForNextCallInterval=0
							Quit
						}
						Set:'$IsObject(..Socket) ..Socket=..SocketNewObject()
						Do ..Socket.Attach(..Device)
						Set:""'=..Terminators ..Socket.LineTerminator=..Terminators
						Set $ZT="OnConnectTrap"
						Set tSC=..BusinessHost.OnConnect(0)  If $$$ISERR(tSC) Do ..Disconnect()  Quit
OnConnectTrap
					}
					If ((..BusinessHost.%LastReportedError["<Ens>ErrInNoConnectionIP:") || (..BusinessHost.%LastReportedError["<Ens>ErrInNoConnectionPort:")) {
						Set ..BusinessHost.%LastReportedError=""
						$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
					}
				}
				Set $ZT="OCTrap"
				set tSC=..OnConnected()
				Set $ZT="Trap"
				Do:'..StayConnected ..Disconnect()
OCContinue
				If $$$ISERR(tSC) $$$sysTRACE("OnConnected() returned %QuitTask="_..BusinessHost.%QuitTask_", '"_$$$StatusText(tSC)_"'")
			} ElseIf ..StayConnected<0&&'..JobPerConnection {
				Set tSC=$S(""'=..%outIPAddr:$$$ERROR($$$EnsErrInNoConnectionIP,..%outIPAddr_$S(..%outIPAddr[":":"|",1:":")_..Port,..CallInterval),1:$$$ERROR($$$EnsErrInNoConnectionPort,..Port,..CallInterval))
			}
		} While 0
	} ; end Else '$zu(53)
Exit
	#; $$$sysTRACE("Exit from OnTask: "_tSC)
	Use ..OldIO
	$$$ACLOSEIOLOGENTRY(tSC,"StillConnected="_..Connected,$$$NULLOREF)
	Quit tSC
Trap
	Set $ZT="ChildTrap",tSC=$$$SystemError
	#; Reopen the device in case it got messed up
	If (""=..%outIPAddr) {
		$$$LOGINFO("Re-opening Port "_..Port_" to listen for incoming connections")
		Use ..OldIO
		Close ..Device
		If ..QSize>0 {
			If ""=..SSLConfig {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..QSize:/TCPNOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
			} Else {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:..QSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
			}
		} Else {
			If ""=..SSLConfig {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
			} Else {
				Open ..Device:(:..Port:..#Mode_"A-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
			}
		}
		If tOpenFailed {
			Set tDevice=..Device, ..Device=""
			Set tSC=$$$EnsError($$$EnsErrTCPListen,..Port,..#OpenTimeout,"Open """_tDevice_""":(:"_..Port_":"""_..#Mode_"A-D"_""":"_..Terminators_":"_..#InputBufferSize_":"_..#OutputBufferSize_":"_$S(..QSize>0:..QSize,1:"1:/CLOSELISTEN")_":/TCPNOXY:"_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig)_"):"_..#OpenTimeout)
		} Else {
			Use ..Device
			Do SetIO^%NLS("RAW") ; turn off translation mode
		}
	} Else { ; If in connect-and-read mode
		Do:..IsReadError(tSC) ..Disconnect()
	}
	Goto Exit
ChildTrap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
OCTrap
	Set $ZT="Trap",tSC=$$$SystemError
	Goto OCContinue
}

Method ConnectOut(pTimeout As %Numeric) As %Status
{
	if ..Connected { Do ..TestConnection() Quit:..Connected $$$OK }

	$$$catTRACE("connwait","Trying to open TCP connection to "_..%outIPAddr_$S(..%outIPAddr[":":"|",1:":")_..Port_":/SSL="_..SSLConfig_" with timeout="_pTimeout)
	Set $ZT="Trap", tSC=$$$OK
	Set ..Device="|TCP|"_..Port_"|"_$P($Job,":")
	If ""=..SSLConfig {
		Open ..Device:(..%outIPAddr:..Port:..#Mode_"-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface):pTimeout  Set tTimedOut='$Test
	} Else {
		Open ..Device:(..%outIPAddr:..Port:..#Mode_"-D":..Terminators:..#InputBufferSize:..#OutputBufferSize:/TCPNOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):pTimeout  Set tTimedOut='$Test
	}
	If tTimedOut {
		Set $ZT="", ..Device=""
		Quit $$$ERROR($$$EnsErrOutConnectExpired,pTimeout,"TCP",..%outIPAddr_$S(..%outIPAddr[":":"|",1:":")_..Port)
	}
	Use ..Device
	Set $ZT=""
	Set ..IOAddr="!"_..%outIPAddr_$S(..%outIPAddr[":":"|",1:":")_..Port_$S(""=..SSLConfig:"",1:"/SSL="_..SSLConfig), ..Connected=1
	Set tTxt="Opened TCP connection to "_..IOAddr
	If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
	Set:'$IsObject(..Socket) ..Socket=..SocketNewObject()
	Do ..Socket.Attach(..Device)
	Set:""'=..Terminators ..Socket.LineTerminator=..Terminators
	Set $ZT="OnConnectTrap"
	Set tSC=..BusinessHost.OnConnect(pTimeout)  Do:$$$ISERR(tSC) ..Disconnect()
OnConnectTrap
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Quit $$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),"TCP",..IOAddr)
}

Method Disconnect()
{
	Set $ZT="Trap",tSC=$$$OK
	If ..Connected {
		Set tTxt="Disconnecting from "_..IOAddr
		If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
	}
	If ""=..%outIPAddr&&(""'=..Device) {
		#; go ahead and try to disconnect even if we think we're already disconnected - we'll just trap out or fail if we already are
		Use ..Device Write *-2
	}
Exit
	Set ..IOAddr="", ..Connected=0
	Use:$IO=..Device ..OldIO
	#; If connected outbound or spawned we should close the socket right now; non-empty $zu(53) means it's a tcp spawned child worker job
	#; If using /CLOSELISTEN, we must close and reopen in order to be able to listen again
	Set tSpawned=(..JobPerConnection&&(""'=$ZU(53)))
	If ""'=..Device && ((""'=..%outIPAddr)||(..QSize<=0)||tSpawned) Close ..Device  Set ..Device=""
	Set:tSpawned ..BusinessHost.%QuitTask=1
	Quit
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

/// Fix up the properties reflecting our connection state in case we thought we were connected but we lost the socket.
Method TestConnection()
{
	Quit:'..Connected
	#; $$$sysTRACE("Testing Connection on Port "_..Port)
	
	Set tSC=$$$OK, $ZT="Trap"
	Quit:$zu(189)
Exit
	Set tTxt = $$$StatusText($$$ERROR($$$EnsErrInConnectionLost,"TCP", ..IOAddr, $S($$$ISOK(tSC):"$zu(189)",1:$$$StatusDisplayString(tSC))))
	If ..StayConnected<0 { $$$LOGWARNING(tTxt) } Else { If ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } }
	Do ..Disconnect()
	Quit
Trap
	Set $ZT="",tSC=$$$SystemError
	Goto Exit
}

ClassMethod connectedJob(pBusinessServiceConfigName As %String, pPoolLimit As %Integer) As %Status
{
	#; create the adapter and business service instances
	If pPoolLimit>1 Set ^IRIS.Temp.EnsTCPJobs($Job)=$ZParent  If $I(^IRIS.Temp.EnsTCPJobs($ZParent,"children"))
	Quit ##class(Ens.Job).Start(pBusinessServiceConfigName,0,1) ; UnRegister will clean up & decrement child count
}

Method OnConnected() As %Status [ Abstract ]
{
	#; subclass responsibility
	Quit $$$OK
}

Method OnKeepalive(pUnused As %Status) As %Status
{
	If ..Connected && (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
		$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
		Do ..Disconnect()
		Quit $$$OK
	}
	Quit ##super($$$OK)
}

}
