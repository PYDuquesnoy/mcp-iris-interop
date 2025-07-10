/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.TCP.DuplexAdapter Extends (Ens.InboundAdapter, Ens.OutboundAdapter) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "Ens.StringContainer";

Parameter InputBufferSize As %Integer = 8192;

Parameter OutputBufferSize As %Integer = 8192;

Parameter OpenTimeout As %Numeric = 5;

/// Spawn a new Job to handle each incoming TCP connection. Allows simultaneous handling of multiple connections.
Property JobPerConnection As %Boolean [ InitialExpression = 1 ];

/// Store the principal device of the current process
Property PrincipalDevice As %String;

/// IP address to connect to. This property is null if it is in listening mode
Property IPAddress As %String;

/// IP Port
Property IPPort As %Integer;

/// The TCP device name
Property IPDevice As %String;

/// Boolean to indicate if the TCP device is connected
Property IsConnected As %Boolean [ InitialExpression = 0 ];

/// The event device name
Property EventDevice As %String;

Method EventDeviceSet(arg) As %Status
{
	Set i%EventDevice = arg
	If $Extract(arg,1,5)="|TCP|" Set ..%isTCPEventDevice = 1
	Quit $$$OK
}

Property %isTCPEventDevice As %Boolean [ InitialExpression = 0, Transient ];

/// The event device port number
Property EventPort As %Integer;

/// Boolean to indicate if the current job is spawned with TCP device
Property IsSpawnedJob As %Boolean [ InitialExpression = 0 ];

/// Indicate number of seconds to wait before calling OnDeviceTimeout
Property TCPReadTimeout As %Integer;

/// The name of an existing SSL/TLS system configuration to use (Secure Socket Layer / Transport Layer Security), which can be configured in the System Management Portal 
/// under System Administration > Security. <br/>
/// <p>If your SSL Configuration requires you to supply a password for the local private key file, specify it in 
/// the Private key password property of the SSL/TLS Configuration.
Property SSLConfig As %String(MAXLEN = 350);

/// How many incoming connections should the OS hold open until the Business Service processes them. <p>
/// The default value is 100 and the maximum allowed value is 1000.<br>
/// However, the maximum incoming connections the OS can hold open until the Business Service processes them depends on the TCP implementation.<p>
/// Set to 0 if only one connection at a time is expected and subsequent connections ought to be refused immediately by the OS.<p>
/// Note: If QSize is 0 a client attempting to connect will be refused connection by the operating system (RST,ACK) if the Business Service is processing a previous incoming connection.<br>
/// This could lead to a scenario where a client is connected to the Business Service but disconnects and attempts
/// to reconnect again in the brief period before the listening socket is re-opened by the Business Service and the client does not retry to connect as a result.
Property QSize As %Integer(MAXVAL = 1000, MINVAL = 0) [ InitialExpression = 100 ];

/// In a multi-homed system, specify which network interface the TCP connection should go through.  An empty value means to use any interface. <br/>
/// To be able to bind to IPv6 interfaces you may need to enable IPv6 in your Ensemble instance.  This is done in the System Management Portal under 
/// System Administration > Configuration > Additional Settings > Startup, by editing the IPv6 setting.
Property LocalInterface As %String(MAXLEN = 250);

Parameter SETTINGS = "JobPerConnection:Connection,SSLConfig:Connection:sslConfigSelector,QSize:Connection,LocalInterface:Connection:selector?context={Ens.ContextSearch/TCPLocalInterfaces},IPPort:Basic,IPAddress:Basic";

Method OpenDevice() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim tOpenFailed As %Boolean = 1
	#dim tMode As %String
	
	Try {
		If ..IPPort="" Set tSC=$$$EnsError($$$GeneralError,"TCP port not specified") Quit
		
		Set tMode=$Select(..IPAddress="":"SA-D",1:"S-D")

		Set ..IPDevice="|TCP|"_..IPPort
		
		If (..IPAddress=""){ 
			#; Listening mode
			If ..QSize>0 {
				If ""=..SSLConfig {
					Open ..IPDevice:(..IPAddress:..IPPort:tMode::..#InputBufferSize:..#OutputBufferSize:..QSize:/NOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
				} Else {
					Open ..IPDevice:(..IPAddress:..IPPort:tMode::..#InputBufferSize:..#OutputBufferSize:..QSize:/NOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
				}
			} Else {
				If ""=..SSLConfig {
					Open ..IPDevice:(..IPAddress:..IPPort:tMode::..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/NOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
				} Else {
					Open ..IPDevice:(..IPAddress:..IPPort:tMode::..#InputBufferSize:..#OutputBufferSize:1:/CLOSELISTEN:/NOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
				}
			}
		} Else {
			If ""=..SSLConfig {
				Open ..IPDevice:(..IPAddress:..IPPort:tMode::..#InputBufferSize:..#OutputBufferSize:/NOXY:/BINDTO=..LocalInterface):..#OpenTimeout  Set tOpenFailed='$Test
			} Else {
				Open ..IPDevice:(..IPAddress:..IPPort:tMode::..#InputBufferSize:..#OutputBufferSize:/NOXY:/BINDTO=..LocalInterface:/SSL=..SSLConfig):..#OpenTimeout  Set tOpenFailed='$Test
			}
		}

		If tOpenFailed Set tSC=$$$EnsError($$$GeneralError,"Unable to open Device "_..IPDevice) Set ..IPDevice="" Quit

		Set ..IsConnected=(tMode'["A")
		
		If ..IsConnected Set tSC=..OnOpenConnection() 
		
	} Catch {
		Set tSC=$$$EnsSystemError
	}
	
	Quit tSC
}

Method CloseDevice() As %Status
{
	#dim tSC As %Status = $$$OK
	
	Try {
		Set tSC=..OnCloseConnection() Quit:$$$ISERR(tSC)
		
		If (""'=..IPDevice) {
			/*
				If in listening mode try to disconnect
				even if we think we're already disconnected
			*/
			If (""=..IPAddress) {
				Try { Use ..IPDevice Write *-2 } Catch {}
			}
			
			/*
				Close if:
					Connected Out or 
					TCP Qsize is 0 means using /CLOSELISTEN and must close and reopen in order to be able to listen again or
					Job Per Connection and we are not the master listener (spawned job).
			*/
			If ((""'=..IPAddress)||(..QSize<=0)||..IsSpawnedJob) {
				Close ..IPDevice
				Set ..IPDevice=""
			}
		}
		
		If ..IsSpawnedJob Set ..BusinessHost.%QuitTask=1
		
		Set ..IsConnected=0
	} Catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Method ResetDevice() As %Status
{
	#dim tSC As %Status = $$$OK
	
	Try {
		Set tSC=..CloseDevice() Quit:$$$ISERR(tSC)
		If ..BusinessHost.%QuitTask=0 {
			If ..IPAddress="" Set tSC=..OpenDevice()
		}
	} Catch {
		Set tSC=$$$EnsSystemError
	}
	
	Quit tSC
}

Method OpenEventDevice(pUseTCP As %Boolean = 0) As %Status
{
	If pUseTCP Quit ..OpenTCPEventDevice()
	Set ..EventDevice = $$$EnsSelectInterruptID
	Quit ..BusinessHost.SetEventDevice(..EventDevice)
}

Method CloseEventDevice() As %Status
{
	If ..%isTCPEventDevice Quit ..CloseTCPEventDevice()
	Quit $$$OK
}

Method ClearEventDevice() As %Status
{
	If ..%isTCPEventDevice Quit ..ClearTCPEventDevice()
	Quit $$$OK
}

Method OpenTCPEventDevice() As %Status
{
	Set tSC=$$$OK
	try {
		For tEventPort=20001:1:30000 {
			Set tEventDevice="|TCP|"_tEventPort
			Open tEventDevice:(:tEventPort:"SA"::::1000):0
			If $test Set ..EventDevice=tEventDevice,..EventPort=tEventPort Quit
		}
		If ..EventDevice'="" Set tSC=..BusinessHost.SetEventDevice(..EventDevice)
		$$$sysTRACE("Set event device: "_..EventDevice)
		Quit
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Method CloseTCPEventDevice() As %Status
{
	Set tSC=$$$OK
	try {
		If ..EventDevice'="" Close ..EventDevice
		Set ..EventDevice=""
		Quit
	} catch {
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Method ClearTCPEventDevice() As %Status
{
	Set tSC=$$$OK
	try {
		Use ..EventDevice
		For  Read tChar#1:0 Quit:'$t
		Use ..PrincipalDevice
	} catch {
		Use ..PrincipalDevice
	}
	Quit tSC
}

ClassMethod connectedJob(pBusinessServiceConfigName As %String) As %Status
{
	Quit ##class(Ens.Job).Start(pBusinessServiceConfigName,0,1) ; UnRegister will clean up & decrement child count
}

Method OnTask() As %Status
{
	Set tSC=$$$OK
	try {
		If ..IPAddress="",..IPDevice="" Set tSC=$$$EnsError($$$GeneralError,"Device not open") Quit
		If ..IPDevice="" Quit
		;
		Set tSelectList=$lb(..IPDevice)
		#; Only add event device to Socket select list if TCP
		If ..%isTCPEventDevice Set tSelectList=tSelectList_$lb(..EventDevice)
		;
		Set tTimeout=+..CallInterval
		If ..TCPReadTimeout'="" {
			If tTimeout>..TCPReadTimeout Set tTimeout=+..TCPReadTimeout
			Set tReadTimeoutAbsolute=$zh+..TCPReadTimeout
		}
		;
		If tTimeout<1 Set tTimeout=1
		;
		Set tReadyList=$System.Socket.Select(tSelectList,tTimeout)
		;
		#; If interrupted via SelectInterrupt() then tReadyList is -1. Set to "" for $List compatibility
		If tReadyList = -1 Set tReadyList = ""
		;
		If $lf(tReadyList,..IPDevice) {
			$$$sysTRACE("DeviceReady: "_..IPDevice)
			If ..TCPReadTimeout'="" Set ..TCPReadTimeout="" $$$sysTRACE("TCPReadTimeout cancelled.")
			If ..IsConnected=0 {
				If ..JobPerConnection {
					Use ..IPDevice
					Job ClassMethod^%apiOBJ($classname(),"connectedJob",..BusinessHost.%ConfigName):(:65560)
					Use ..PrincipalDevice
					$$$sysTRACE("spawned TCP socket reader child process '"_$zchild_"'")
					Do ..ResetDevice()
				} Else {
					Set ..IsConnected=1
					Set tSC=..OnOpenConnection() Quit:$$$ISERR(tSC)
				}
			} Else {
				Set tShouldExit=0
				Set tSC=..OnDeviceReady(.tShouldExit)
				If (($$$ISERR(tSC))||(tShouldExit)) Do ..ResetDevice()
			}
		} Else {
			If ..TCPReadTimeout'="" {
				Set tReadTimeoutRemaining=tReadTimeoutAbsolute-$zh
				If tReadTimeoutRemaining<=0 {
					$$$sysTRACE("TCP read timed out.")
					Set ..TCPReadTimeout=""
					Set tShouldExit=0
					Set tSC=..OnDeviceTimeout(.tShouldExit)
					If (($$$ISERR(tSC))||(tShouldExit)) Do ..ResetDevice()
				} Else {
					Set ..TCPReadTimeout=tReadTimeoutRemaining
				}
			}
		}
		If ..%isTCPEventDevice && $lf(tReadyList,..EventDevice) {
			$$$sysTRACE("DeviceReady: "_..EventDevice)
			Do ..ClearEventDevice()
		}
		#; make BS call this OnTask method immediately after checking for queue
		Set ..BusinessHost.%WaitForNextCallInterval=0
		Quit
	} catch {
		Use ..PrincipalDevice
		Set tSC=$$$EnsSystemError
		Do ..ResetDevice()
	}
	Quit tSC
}

Method OnDeviceReady(pShouldExit As %Boolean) As %Status
{
	Set tSC=$$$OK
	try {
		If ..IsConnected=0 Set tSC=$$$EnsError($$$GeneralError,"Device not connected") Quit
		;
		Use ..IPDevice
		;
		Read tLengthCode#4:5 Set tSuccessful=$test
		If 'tSuccessful Use ..PrincipalDevice Quit
		;
		Set tLength=$sconvert(tLengthCode,"u4",1) 
		Set tLine=""
		;
		If tLength Read tLine#tLength
		;
		Use ..PrincipalDevice
		;
		Set tSC=..BusinessHost.ProcessInput(##class(Ens.StringContainer).%New(tLine))
		;
		; Test ..TCPReadTimeout
		if tLine=+tLine set ..TCPReadTimeout=tLine
		;
		Quit
		;
	} catch {
		Use ..PrincipalDevice
		If $ZE["<READ>" Do ..ResetDevice()
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Method OnDeviceTimeout(pShouldExit As %Boolean) As %Status
{
	Quit $$$OK
}

Method OutputData(pData As %String) As %Status
{
	Set tSC=$$$OK
	try {
		If ..IPAddress="",..IPDevice="" Set tSC=$$$EnsError($$$GeneralError,"Device not open") Quit
		If ..IPAddress="",..IsConnected=0 Set tSC=$$$EnsError($$$GeneralError,"Device not connected") Quit
		If ..IPDevice="" Set tSC=..OpenDevice() Quit:$$$ISERR(tSC)
		;
		Use ..IPDevice
		Write $nconvert($l(pData),"u4",1),pData,!
		Use ..PrincipalDevice
		Quit
	} catch {
		Use ..PrincipalDevice
		Set tSC=$$$EnsSystemError
	}
	Quit tSC
}

Method OnInit() As %Status
{
	#dim tSC As %Status = $$$OK
	Set ..PrincipalDevice=$io
	Set ..LocalInterface=$ZStrip($P(..LocalInterface,"("),"*W")

	#dim tDevice As %String = $ZU(53)
	#dim tMode As %String = $S(..IPAddress="":"SA-D",1:"S-D")
	#; initialize for spawned TCP job (only possible in normal listen-for-connection mode)		
	If ""'=tDevice {
		Set ..IsSpawnedJob=1
		Set ..IPDevice=tDevice
		Set ..IsConnected=1
		If ""=..SSLConfig {
			Use tDevice:(::tMode::..#InputBufferSize:..#OutputBufferSize:0:/NOXY)
		} Else {
			Use tDevice:(::tMode::..#InputBufferSize:..#OutputBufferSize:0:/NOXY:/SSL=..SSLConfig)
			$$$EnsCheckSSLConfig(..SSLConfig)
		}
		Set tSC=..OnOpenConnection() Quit:$$$ISERR(tSC)
	} Else {
		If ..IPAddress="" Set tSC=..OpenDevice()
	}
	Quit tSC
}

Method OnTearDown() As %Status
{
	#dim tSC As %Status = $$$OK
	try {
		Quit:""=..IPDevice
		Set tSC = ..CloseDevice()
		If $$$ISERR(tSC) Quit
		Quit:""=..IPDevice
		Close ..IPDevice
	} catch {Set tSC=$$$EnsSystemError}
	Quit tSC
}

Method OnOpenConnection() As %Status
{
	Quit $$$OK
}

Method OnCloseConnection() As %Status
{
	Quit $$$OK
}

Method OnDeviceDisconnected() As %Status
{
	$$$LOGERROR("Peer disconnected.")
	Quit $$$OK
}

}
