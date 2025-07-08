/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %IO.ServerSocket Extends (%IO.DeviceStream, %IO.IParts.ServerSocketIO, %IO.SocketCommon) [ Inheritance = right, System = 2 ]
{

/// Until pTimeout, wait for an inbound TCP connection to be received on the port specified in the prior Open() call.
/// Note that the OS may accept up to ConnectionQueueSize connections for the port on your behalf before you call this method.
/// If the OS has queued one or more accepted connections, this method will return immediately with one of them connected.
Method Listen(ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit 0
	If i%IsConnected Set pSC=$$$ERROR($$$FileAlreadyOpen,..Name) Quit 0
	Set ..LocalInterface=$ZStrip($P(..LocalInterface,"("),"*W")
	Set pSC = $$$OK, tIO=$IO, $ZT="Trap"  Use ..Name
	If -1=pTimeout { Read dummy  Set tNewConnection=1 }
	Else { Read dummy:pTimeout  Set tNewConnection=$Test }
	If 'tNewConnection {
		Set pSC=$$$ERROR($$$ErrIOListenTimeout,..Name,pTimeout)
		Use tIO
		Quit 0
	}
	If '..remoteIPAllowed(..AllowedClientIPAddresses,.tRemote,.tSC1) {
		Write *-2
		Set pSC=$$$ERROR($$$GeneralError,"ServerSocket rejected connection attempt on port "_..Port_" from "_tRemote_" which was not found in AllowedClientIPAddresses list '"_..AllowedClientIPAddresses_"'"_$S($$$ISOK(tSC1):"",1:" :"_$$getAllStatusTexts(tSC1)))
		Use tIO
		Quit 0
	}
	Set i%Remote=$ZDT($ZTS,3,,3)_"|"_tRemote, i%IsConnected=1, i%AtEnd=0, pTimeout=0
	Use tIO
	Quit 1
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Use tIO
	Quit 0
getAllStatusTexts(sc,sep,language)
	Quit:sc=$$$OK $System.Status.GetOneStatusText($$$ERROR("<%ObjectErrors>OK"),1,.language)
	Set (txt,msg)=$System.Status.GetOneStatusText(sc,1,.language)
	For iMsg=2:1 { Set msg=$System.Status.GetOneStatusText(sc,iMsg,.language)  Quit:""=msg
		Set txt=txt_$G(sep,$C(13,10,43,13,10))_msg
	}
	Quit txt
}

/// Test whether the remote TCP socket conforms to the given list of allowed IP addresses / host names. Also return a formatted string representing the remote address.
ClassMethod remoteIPAllowed(pAllowedIPAddresses As %String, Output pRemote As %String, Output pStatus As %Status) As %Boolean [ Internal ]
{
	Set pStatus=$$$OK
#define digitsHex(%count) %count(1N,1"a",1"A",1"b",1"B",1"c",1"C",1"d",1"D",1"e",1"E",1"f",1"F")
#define isNumericIP(%addr) (%addr?1(1.3N3(1"."1.3N).1(1":"1.5N),.1"["$$$digitsHex(.4)2.7(1":"$$$digitsHex(.4)).1(1(1"|",1"]:")1.5N)))
	If '$D(pRemote,tRem) {
		Set tRem=$zu(111,0)
		Set ps=$S($L(tRem)>6:"|",1:":"), tRemoteIP=$$$IPBinaryToText($E(tRem,1,*-2)), tRemotePort=$ZWAscii($Reverse($E(tRem,*-1,*))), pRemote=tRemoteIP_ps_tRemotePort
	} Else {
		Set ps=$S(tRem["|":"|",1:":"), tRemoteIP=$P(tRem,ps,1), tRemotePort=$P(tRem,ps,2)
	}
	Quit:""=pAllowedIPAddresses 1
	Set tIPOK=0
	Set tLocalHostName=$ZCVT(##class(%SYSTEM.INetInfo).LocalHostName(),"L")
	For i=1:1:$L(pAllowedIPAddresses,",") { Set tIPHost=$ZStrip($P(pAllowedIPAddresses,",",i),"<>W")  Continue:""=tIPHost
		#; If not a numeric IPv4 or IPv6 address, see if NIS/DNS can resolve it as a host name into one or more numeric addresses
		If '$$$isNumericIP(tIPHost) {
			Set tIPHostPort=$P(tIPHost,$S(tIPHost["|":"|",1:":"),2)
			Set tPlainName=$E(tIPHost,1,*-$S(""=tIPHostPort:0,1:$L(tIPHostPort)+1))
			If $ZCVT(tPlainName,"L")=tLocalHostName&&$Case(tRemoteIP, "127.0.0.1":1, "::1":1, :0) {
				Set tIPHost=tRemoteIP
			} Else {
				Set tIPList=##class(%SYSTEM.INetInfo).HostNameToAddrMulti(tPlainName)
				Set tIPHost="" For j=1:1:$LL(tIPList) { Set tIP=$LI(tIPList,j)  Continue:""=tIP
					Set tIPHost=tIPHost_","_tIP_$S(""=tIPHostPort:"",1:ps_tIPHostPort)
				} Set tIPHost=$E(tIPHost,2,*) ; strip leading comma
				If ""=tIPHost Set pStatus=$$$ADDSC(pStatus,$$$ERROR($$$GeneralError,"Unable to resolve any IP address from allowed IP host name "_tPlainName_" during connection attempt"))
			}
		}
		For j=1:1:$L(tIPHost,",") { Set tIP=$ZStrip($P(tIPHost,",",j),"<>W")  Continue:""=tIP
			If $P(tIP,ps)=tRemoteIP && $Case($P(tIP,ps,2), "":1, tRemotePort:1, :0) Set tIPOK=1  Quit
		} Quit:tIPOK
	}
	Quit tIPOK
}

/// Until pTimeout, listen for incoming connections and spawn a job for each one, up to pMaxJobs. If pMaxJobs
/// threshold has already been reached, wait for an existing connected job to quit and then spawn a job for the new connection.
/// When the timeout expires, this method will return but any spawned jobs will continue running until they terminate on their own.
/// pOnConnectedClass is the classname of a customer defined class that must contain a classmethod called OnConnected().  ListenJob() will arrange for this classmethod to be called each time a new connection arrives. It will call OnConnected() with 2 arguments, a  %IO.ServerSocket instance representing the connected socket, and a string that was passed in to ListenJob() in the pJobArgs argument.  This allows the OnConnected() method to engage in TCP communications over the socket from within a fresh job created for the purpose.
/// The pSocketClass argument to ListenJob() allows you to specify a subclass of %IO.ServerSocket should be instantiated in the connection jobs. This could implement additional methods for handling common protocol elements expected to be exchanged across the TCP connection. Normally you will just use %IO.ServerSocket and its Read() and Write() methods.
/// The pDummy argument is ignored.
Method ListenJob(ByRef pTimeout As %Numeric = -1, pOnConnectedClass As %String, pJobArgs As %String = "", pSocketClass As %String = "%IO.ServerSocket", pMaxJobs As %Integer = -1, pDummy As %Boolean, Output pSC As %Status) As %Integer
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit 0
	If i%IsConnected Set pSC=$$$ERROR($$$FileAlreadyOpen,..Name) Quit 0
	Set:pTimeout>0 tStartTime=$zh
	Set pSC=$$$OK, tConnections=0, tTimeRemaining=pTimeout, tIO=$IO, $ZT="Trap"
	Kill ^IRIS.Temp.ServerSocket($this_$Job)
	Use ..Name
	For {
		If -1=pTimeout { Read dummy  Set tNewConnection=1 }
		Else { Read dummy:tTimeRemaining  Set tNewConnection=$Test }
		If tNewConnection {
			Set tRemote=$zu(111,0), ps=$S($L(tRemote)>6:"|",1:":"), tRemote=$$$IPBinaryToText($E(tRemote,1,*-2))_ps_$ZWAscii($Reverse($E(tRemote,*-1,*)))
			If ""'=..AllowedClientIPAddresses {
				Set tIPOK=0
				For i=1:1:$L(..AllowedClientIPAddresses,",") { Set tIP=$P(..AllowedClientIPAddresses,",",i)  Continue:""=tIP
					If tIP["|" { If tRemote=tIP Set tIPOK=1 Quit }
					ElseIf 1=$L(tIP,":") { If $P(tRemote,":")=tIP Set tIPOK=1 Quit }
					ElseIf $L(tIP,":")>2 { If $P(tRemote,"|")=tIP Set tIPOK=1 Quit }
					Else { If tRemote=tIP Set tIPOK=1 Quit }
				}
				If 'tIPOK Write *-2  Set pSC=$$$ERROR($$$GeneralError,"ServerSocket rejected connection attempt on port "_..Port_" from "_tRemote_" which was not found in AllowedClientIPAddresses list '"_..AllowedClientIPAddresses_"'")  Continue
			}
			Set i%Remote=$ZDT($ZTS,3,,3)_"|"_tRemote, i%IsConnected=1, i%AtEnd=0

			Set tOK=1 While pMaxJobs>0 && ($G(^IRIS.Temp.ServerSocket($this_$Job),0)>=pMaxJobs) {
				#; wait for a job to quit
				Set tOK=0
				Quit:'pTimeout

				Hang 0.5
				If pTimeout>0 {
					Set tTimeRemaining=(pTimeout-($zh-tStartTime))
					Quit:tTimeRemaining<=0
				}
				Set tOK=1
			}
			Quit:'tOK
			Set tConnections=tConnections+1
			Set tSocketProps=$LB(..AllowedClientIPAddresses
								,..CharEncoding
								,..LineTerminator
								,..InputBufferSize
								,..OutputBufferSize
								,..KeepAliveInterval
								,..TCPReceiveBuffer
								,..TCPSendBuffer
								,..SSLConfig
								,..ConnectionQueueSize)
			Job ClassMethod^%apiOBJ(..%ClassName(1),"connectionJob",$this_$Job,pOnConnectedClass,pSocketClass,tSocketProps,pJobArgs):(:65560)
			Do ..Disconnect()
		} ; tNewConnection
		Quit:'pTimeout
		Continue:pTimeout<0
		Set tTimeRemaining=(pTimeout-($zh-tStartTime))
		Quit:tTimeRemaining<=0
	} ; For
Exit
	Use tIO
	Quit tConnections
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

Method jobAttachProps(pSocketProps As %String, pDevice As %String) [ Internal ]
{
	Set ..AllowedClientIPAddresses=$LG(pSocketProps,1)
		,..CharEncoding=$LG(pSocketProps,2)
		,..LineTerminator=$LG(pSocketProps,3)
		,i%InputBufferSize=$LG(pSocketProps,4)
		,i%OutputBufferSize=$LG(pSocketProps,5)
		,..KeepAliveInterval=+$LG(pSocketProps,6)
		,..TCPReceiveBuffer=+$LG(pSocketProps,7)
		,..TCPSendBuffer=+$LG(pSocketProps,8)
		,..SSLConfig=$LG(pSocketProps,9)
		,..ConnectionQueueSize=$LG(pSocketProps,10)
	Set i%IsConnected=1
	Set ..Port=$P(pDevice,"|",3)
	If ""=..SSLConfig {
		If ..KeepAliveInterval=-1 {
			Use ..Name:(::"SW-D"::..InputBufferSize:..OutputBufferSize:0:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE)
		} Else {
			Use ..Name:(::"SW-D"::..InputBufferSize:..OutputBufferSize:0:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval)
		}
	} Else {
		If ..KeepAliveInterval=-1 {
			Use ..Name:(::"SW-D"::..InputBufferSize:..OutputBufferSize:0:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig)
		} Else {
			Use ..Name:(::"SW-D"::..InputBufferSize:..OutputBufferSize:0:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig)
		}
	}
	Set tRemote=$zu(111,0), ps=$S($L(tRemote)>6:"|",1:":"), tRemote=$$$IPBinaryToText($E(tRemote,1,*-2))_ps_$ZWAscii($Reverse($E(tRemote,*-1,*)))
	Set i%Remote=$ZDT($ZTS,3,,3)_"|"_tRemote
	Quit
}

ClassMethod connectionJob(pSubscript As %String, pOnConnectedClass As %String, pSocketClass As %String, pSocketProps As %String, pJobArgs As %String) As %Status [ Internal ]
{
	Set tCnt=$I(^IRIS.Temp.ServerSocket(pSubscript))
	Set tSC=$$$OK, $ZT="Trap", tOldIO=$IO
	Do $ZU(68,57,1) ; turn on PSW2NOTHROTTLE bit to bypass throttle
	Set tDevice = $ZUtil(53) ; $zu(53) means it's a tcp spawned job
	If tDevice="" Goto Exit
	Use tDevice
	Set tSocket=$classmethod(pSocketClass,"AttachNew",,.tSC)
	Do tSocket.jobAttachProps(pSocketProps, tDevice)
	Use tOldIO
	Do $classmethod(pOnConnectedClass,"OnConnected",tSocket,pJobArgs)
Exit
	Set tCnt=$I(^IRIS.Temp.ServerSocket(pSubscript),-1)
	Quit tSC
Trap
	Set $ZT="",tZE=$ZE, tSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Goto Exit
}

/// Open the socket for listening on the port given by pPort, waiting up to pTimeout for the port to be available to listen on.
Method Open(pPort As %String = "", ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Boolean
{
	#; Must close before calling Open() again
	If ..IsOpen Set pSC = $$$ERROR($$$FileAlreadyOpen,..Name_"/"_..Port) Quit 0
	Set:""=pPort pPort=..Port
	Set ..Name="|TCP|"_pPort
	If ","_$TR($P($View(-1,$job),"^",3),"*")_","[(","_..Name_",") Set pSC=$$$ERROR($$$FileAlreadyOpen,..Name) Quit 0

	Set $ZT="Trap",pSC=$$$OK
	
	#; Note: the LineTerminator will be set on each Read()
	If -1=pTimeout {
		If ..ConnectionQueueSize>0 {
			If ""=..SSLConfig {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE) Set tTimedOut=0
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval) Set tTimedOut=0
				}
			} Else {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig) Set tTimedOut=0
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig) Set tTimedOut=0
				}
			}
		} Else {
			If ""=..SSLConfig {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE) Set tTimedOut=0
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval) Set tTimedOut=0
				}
			} Else {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig) Set tTimedOut=0
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig) Set tTimedOut=0
				}
			}
		}
	} Else {
		If ..ConnectionQueueSize>0 {
			If ""=..SSLConfig {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE):pTimeout Set tTimedOut='$Test
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval):pTimeout Set tTimedOut='$Test
				}
			} Else {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig):pTimeout Set tTimedOut='$Test
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:..ConnectionQueueSize:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig):pTimeout Set tTimedOut='$Test
				}
			}
		} Else {
			If ""=..SSLConfig {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE):pTimeout Set tTimedOut='$Test
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval):pTimeout Set tTimedOut='$Test
				}
			} Else {
				If ..KeepAliveInterval=-1 {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/NOKEEPALIVE:/SSL=..SSLConfig):pTimeout Set tTimedOut='$Test
				} Else {
					Open ..Name:(:pPort:"SWA-D"::..InputBufferSize:..OutputBufferSize:1:/CLOSELISTEN:/TCPNOXY:/BINDTO=..LocalInterface:/TCPSNDBUF=..TCPSendBuffer:/TCPRCVBUF=..TCPReceiveBuffer:/KEEPALIVE=..KeepAliveInterval:/SSL=..SSLConfig):pTimeout Set tTimedOut='$Test
				}
			}
		}
	}
	If tTimedOut Set pSC=$$$ERROR($$$ErrIOOpenTimeout,..Name,pTimeout) Quit 0

	Do ..initDeviceTranslationTable()
	Set i%IsOpen=1,i%AtEnd=1,i%IsConnected=0,..Port=pPort,pTimeout=0
	Quit 1
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Close ..Name
	Quit 0
}

/// Disconnect the current connection but keep the socket open for listening
Method Disconnect(Output pSC As %Status, pIntentional As %Boolean = 1, pSCReason As %Status = {$$$OK})
{
	Set pSC = $$$OK
	Quit:'i%IsConnected
	Set $ZT="TrapD", tIO=$IO
	Use ..Name  Write *-2
TrapD
	Set $ZT="Trap"
	Set i%IsConnected=0
	If ..ConnectionQueueSize<=0 {
		Do ..Close(), ..Open(,4,.pSC)
	}
Trap
	Set $ZT="" Use tIO  Set i%IsConnected=0, i%AtEnd=1, i%Remote=i%Remote_"|"_$ZDT($ZTS,3,,3)
	If $IsObject(..DisconnectHandler) {
		Set $ZT="UserTrap"
		Do ..DisconnectHandler.OnDisconnect($this,pIntentional,pSCReason)
	}
UserTrap
	Quit
}

/// Disconnect the current connection and close the Socket for listening.  Any connections the OS may have accepted
/// for the current port and queued for us will be disconnected as well.
Method Close(Output pSC As %Status) As %Boolean
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit 0
	If i%IsConnected Do ..Disconnect(.pSC)
	Else  Set pSC=$$$OK
	Set $ZT="Trap"
	Close ..Name
Trap
	Set $ZT="", i%IsOpen=0
	Quit 1
}

Method IsConnectedGet() As %Boolean [ Internal ]
{
	Quit:'i%IsConnected 0
	Set $ZT="Trap", tIO=$IO
	Use ..Name  Set tOK=$zu(189)
	If tOK Use tIO Quit 1	
Trap
	Set $ZT=""  Use tIO  Do ..Disconnect(,0)
	Quit 0
}

}
