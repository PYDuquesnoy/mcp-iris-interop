/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%SYS.DBSRV, %syDatabase)

Class %Net.Remote.Gateway Extends %RegisteredObject [ System = 3 ]
{

/// Messages
Parameter CONNECT [ Final ] = "Y0";

Parameter EXECUTEMETHOD [ Final ] = "Y1";

Parameter GENERATECLASSES [ Final ] = "Y2";

Parameter GETOBJECT [ Final ] = "Y3";

Parameter DISCONNECT [ Final ] = "Y4";

Parameter EXCEPTIONRAISED [ Final ] = "Y5";

Parameter SHUTDOWN [ Final ] = "Y6";

Parameter OBJECTCREATED [ Final ] = "Y9";

Parameter GETAVAILABLECLASSES [ Final ] = "YC";

Parameter SUCCESS [ Final ] = "YY";

Parameter JAVASERVICE [ Final ] = "YK";

Parameter LOADCOSCLASS [ Final ] = "YL";

Parameter ADDTOCURRENTCLASSPATH [ Final ] = "YP";

Parameter PING [ Final ] = "YQ";

Parameter LOADJAVACLASS [ Final ] = "YZ";

Parameter LOADJAVACLASSSYNCH [ Final ] = "YW";

Parameter GETTIMESTAMP [ Final ] = "YT";

Parameter INPUTTIMEOUT = 30;

Property GatewayDevice As %String(TRUNCATE = 1);

Property CurrentDevice As %String(TRUNCATE = 1);

/// Used by GatewayLight to save current device multiple times in case of reentrancy
Property CurrentDeviceStack As %String(TRUNCATE = 1) [ MultiDimensional ];

Property SequenceNumber As %Integer [ MultiDimensional ];

Property Namespace As %String(TRUNCATE = 1);

Property ClosedProxies As %String [ MultiDimensional ];

Property Closed As %Boolean;

Property ProtocolVersion As %Integer;

Property connectParameters As %String(MAXLEN = "") [ Transient ];

Property connectClassPaths As %ListOfDataTypes [ Transient ];

Property AttemptReconnect As %Boolean [ InitialExpression = 0 ];

Property SHMConnectString As %String;

Property ProxyObjectHolder As %Library.RawString [ MultiDimensional ];

Property DisableOutputRedirect As %Boolean;

Property ExternalLanguage As %String;

Property ExternalLanguageVersion As %String;

Property IsUsingSharedMemory As %Boolean [ ReadOnly ];

Property xdbcConnection As %Boolean [ InitialExpression = 0 ];

Method %OnNew() As %Status
{
	set ..Closed = 1
	set ..ProtocolVersion = $$$ProtocolVersion
	set ..CurrentDevice = $io
	set ..SequenceNumber = 0
	set ..DisableOutputRedirect = ''$G(^%SYS("Gateway","Remote","DisableOutputRedirect"),0)
	quit $$$OK
}

/// Connect to an External Language Server.
/// To connect to an External Language Server by name, please pass empty string as first argument and Gateway name as second argument.
/// Please note if a ELS definition is secure, then connecting by ELS name is required.
/// Connecting using host and port only works for unsecure External Language Servers.
Method %Connect(host As %String = "127.0.0.1", port As %Integer, namespace As %String = {$namespace}, timeout As %Numeric = 5, additionalClassPaths As %ListOfDataTypes = "", sslConfiguration As %String = "", Output isUsingSharedMemory, useSharedMemoryIfPossible As %Boolean, VerifySSLHostName As %Boolean = 0) As %Status [ Final ]
{
	Set status=$$$OK
	Set (isUsingSharedMemory, i%IsUsingSharedMemory) = 0
	set serverName = ""
	set serverFullName = ""
	Try {
		// If host is empty string, we treat port value as name of an Object Gateway entry
		if host="" {
			set serverName = port
			set port = ""
		} else {
			set serverName = ..%FindServerByHostPort(host,port)
		}
		if serverName'="" {
			set status = ##class(%Net.Remote.Service).OpenGateway(serverName, .objGateway) quit:$$$ISERR(status)
			set status = $$CheckRequiredResource^%SYS.Gateway(objGateway) quit:$$$ISERR(status)
			;
			set allowedip = objGateway.AllowedIPAddresses
			set host = $s(objGateway.Type="Remote":objGateway.Address,1:$case(allowedip,"0.0.0.0":"127.0.0.1","::":"::1",:allowedip))
			if port="" set port = objGateway.Port
			set sslConfiguration = objGateway.SSLConfigurationClient
			set VerifySSLHostName = objGateway.VerifySSLHostName			
			if ##class(%Net.Remote.Utility).IsServerLocal(host)&&##class(%Net.Remote.Utility).CheckLocalPortFree(host,port,allowedip) {
				set status = ##class(%Net.Remote.Service).SpawnGateway(serverName) quit:$$$ISERR(status)
			}
			if $d(useSharedMemoryIfPossible)=0 set useSharedMemoryIfPossible = objGateway.UseSharedMemory
			if objGateway.Type'="Remote" set serverFullName = objGateway.FullName
		} else {
			set useSharedMemoryIfPossible = ''$g(useSharedMemoryIfPossible)
		}

		Set ..connectParameters = "",..connectClassPaths=$$$NULLOREF

		Set sharedMemorySupported = ($$$isWINDOWS || $$$isUNIX)
		Set isLocalhostOrLoopback = ((host="127.0.0.1") || ($zconvert(host,"L")="localhost"))
		Set usingSSL = (sslConfiguration'="")
		
		// shared memory connection explicitly specified
		If ($extract(host,1,3)="SHM") {
			If ('sharedMemorySupported) {
				Set status=$$$ERROR($$$RemoteGatewayError,"Shared memory connections are not supported on this platform")
				Quit
			}

			Set ..SHMConnectString = host
			Set host = "127.0.0.1" // set the host to the loopback, because we'll open a TCP/IP device using it first
		}

		// try to use shared memory when possible, even if not explicitly specified
		Elseif (sharedMemorySupported && isLocalhostOrLoopback && useSharedMemoryIfPossible) {
			Set ..SHMConnectString = "SHM|||||"
			// keep host the same, because we'll open a TCP/IP device using it first
		}

		// not using shared memory
		Else {
			// clear the property to prevent reusing a previous value if %Connect is called on the same instance more than once
			Set ..SHMConnectString = ""
		}
		
		If (..SHMConnectString'="") {
			// find first free XDEV device name, try up to 100 times
			Set ctr = $get(^||%XDEVshm,0)
			Set foundFreeDevice = 0
			Set numTries = 0
			While (numTries<100) {
				Set numTries = numTries +1

				Set shmDevice = "|XDEV|"_+$job
				Set shmName = "Global\Xdev"_+$job
				If (ctr'=0) {
					Set shmDevice = shmDevice_ctr
					Set shmName = shmName_"."_ctr
				}

				Set openDevices = $translate($piece($view(-1,$job),"^",3),"*","")
				If ($find(openDevices,shmDevice_",")=0) {
					Set foundFreeDevice = 1
					Quit
				} Else {
					Set ctr = (ctr + 1) #100
				}
			}
			If ('foundFreeDevice) {
				Set status=$$$ERROR($$$RemoteGatewayError,"No free XDEV device name found for the current process. Maximum number of devices supported per process is 100.")
				Set ..SHMConnectString = ""
				Quit
			}
			Set ^||%XDEVshm = (ctr + 1) #100
						
			Set shmConnectStr = ..SHMConnectString
			Set $piece(shmConnectStr,"|",4) = shmName
			Set ..SHMConnectString = shmConnectStr
		}

		Set:$get(host)="" host = "127.0.0.1"
		Quit:(..Closed=0)&&(..GatewayDevice'="")
		Set ..GatewayDevice=..%freeTCPDevice(port)
		Set ..Namespace=namespace
		Set ..CurrentDevice=$IO
		Set ..Closed=1
		If (sslConfiguration="") {
			Open ..GatewayDevice:(host:port:"AdS"::::5):timeout
			If '$T Set status=$$$ERROR($$$RemoteGatewayError,"Connection cannot be established") Quit
		} Else {
			s doopen=0
			Try {
				Set tns=$namespace zn "%SYS"
				Set srv=##class(Security.SSLConfigs).%OpenId(sslConfiguration,,.tSC)
				If $$$ISOK(tSC) && (srv.Type=0) { Set doopen=1 }
				zn tns
			} catch {
				//Namespace error checking for SSLConfig, try anyway
				Set doopen=1
			}
			if doopen=1 {
				Open ..GatewayDevice:(host:port:/SSL=sslConfiguration::::5):timeout
				If '$T Set status=$$$ERROR($$$RemoteGatewayError,"SSL Connection cannot be established") Quit
			} else {
				Set status=$$$ERROR($$$RemoteGatewayError,"SSL Configuration: """_sslConfiguration_""" is invalid, Connection terminated") Quit
			}
		}
		Use ..GatewayDevice:(::"A-dS"::32767:32767)
		Set ..Closed=0
		Set ..connectParameters=$LB(host,port,namespace,timeout,sslConfiguration,useSharedMemoryIfPossible)
		Set ..connectClassPaths=additionalClassPaths
		do $system.IS.DefaultTimeout(-1)

		// Send passphrase if defined
		#dim tPhrase As %Integer
		If ##class(%Net.Remote.Utility).GetPassphrase(serverName,.tPhrase) {
			Write $C(0,0,0,0)_$e($j(tPhrase,8),1,8)_$C(0,0),*-3
		}

		// Use new continuation logic
		Set x=$zobjexport(1,31)
		set callargs($i(callargs)) = ..ProtocolVersion // gatewayProtocol and dbsrvProtocol have been merged and are always the same
		set callargs($i(callargs)) = $zbitget($zversion(0),1)
		set callargs($i(callargs)) = $$GetCharset^%SYS.NLS()
		set callargs($i(callargs)) = +$J  //Used to monitor IRIS process for SHM
		set callargs($i(callargs)) = ..Namespace
		// Additional class paths, if any
		do ..convertClassPaths(.thelist,additionalClassPaths)
		set callargs($i(callargs)) = thelist
		for i=1:1:thelist {
			set callargs($i(callargs)) = thelist(i)
		}
		// Standard output redirection. In order to disable redirection, set below
		// global reference to 1, otherwise all Java/.Net output will be redirected to Ensemble
		set callargs($i(callargs)) = ..DisableOutputRedirect
		set callargs($i(callargs)) = 0	// not used (was disable proxy deployment)
		set callargs($i(callargs)) = ..ProtocolVersion	// gatewayProtocol and dbsrvProtocol have been merged and are always the same
		set callargs($i(callargs)) = $case(..SHMConnectString,"":"",:$system.Util.InstallDirectory())
		set callargs($i(callargs)) = ..SHMConnectString
		set callargs($i(callargs)) = $zboolean($System.Process.ListFormat(),1,1)
		; CONNECT must have sequence number 0 in order to negotiate with older jar file
		do $system.OS.SendRequest(0,"",..#CONNECT,callargs...)
		;
		try {
			set returnCode = $system.IS.ReceiveHeader(..#INPUTTIMEOUT)
		} catch {
			Set status=$$$ERROR($$$RemoteGatewayError,"Communication failure on port '"_port_"', ensure there is an Object Gateway running on this port") Quit
		}
		quit:$$$ISERR(status)
		set msgid = $li(returnCode,2)
		set fun = $li(returnCode,4)
		;
		Use ..GatewayDevice
		If (fun=..#EXCEPTIONRAISED) {
			Set status=..%GetException()
		} Else {
			Set x=$system.IS.Receive(),..ProtocolVersion=$system.IS.Receive() // gatewayProtocol and dbsrvProtocol have been merged and are always the same
			set %protocol = ..ProtocolVersion // set in %protocol for reentrancy purposes
			if %protocol<57 set status=$$$ERROR($$$RemoteGatewayError,"Protocol mismatch; only protocols >= 57 supported")
			if %protocol<65,$zboolean($System.Process.ListFormat(),1,1) {
				set status=$$$ERROR($$$RemoteGatewayError,"Version mismatch: External Gateway Server does not support the Compact Double feature")
			}
		}
		quit:$$$ISERR(status)

		set serverSupportsSharedMemory=0
		if $System.IS.BytesLeftInMsg()>0 set serverSupportsSharedMemory = $system.IS.Receive()

		set serverNameExternal = ""
		if $System.IS.BytesLeftInMsg()>0 set serverNameExternal = $system.IS.Receive()

		if (serverNameExternal'="")&&(serverFullName'="")&&(serverFullName'=serverNameExternal) {
			set status=$$$ERROR($$$RemoteGatewayError,"Gateway Server name mismatch") quit
		}

		if sslConfiguration'="",VerifySSLHostName {
			set status = ##class(%Net.HttpRequest).CheckSSLCN(host)
			quit:$$$ISERR(status)
		}
		
		if (..SHMConnectString'="") {
			if serverSupportsSharedMemory {
				new %qrc,%msg,%qOBUFSIZE,%qIBUFSIZE
				do $SYSTEM.Context.XDBCServer().pushState() set contextStatePushed=1
				do ##class(%SYS.DBSRV).SetupShmDevice(.shmDevice,..SHMConnectString,1,.tSC,..GatewayDevice)
				set (isUsingSharedMemory, i%IsUsingSharedMemory) = $$$ISOK(tSC)
				if $$$ISOK(tSC) {
					// close ..GatewayDevice // close TCP/IP device  // No need for this.  Device was closed in %SYS.DBSRV.InitSHM method 
					set ..GatewayDevice = shmDevice
				} else {
					// continue with TCP/IP device if shared memory connection failed
					set ..SHMConnectString = ""
				}
				use ..GatewayDevice
				do $SYSTEM.Context.XDBCServer().popState() set contextStatePushed=0
			} else {
				// continue with TCP/IP device if shared memory connection not supported on the server
				set (isUsingSharedMemory, i%IsUsingSharedMemory) = 0
				set ..SHMConnectString = ""
			}
		}
	} Catch exception {
		If ($ZE["<READ>")||($ZE["<DSCON>") Set status=$$$ERROR($$$RemoteGatewayError,"TCP error on port '"_port_"', ensure there is an Object Gateway running on this port")
		Else  Set status=..%SetStatus(exception)
		if $g(contextStatePushed) { do $SYSTEM.Context.XDBCServer().popState() }
	}
	;
	Use ..CurrentDevice
	If (..Closed=0) && $$$ISERR(status) {
		Close ..GatewayDevice
		Set ..Closed=1
	}
	Quit status
}

Method %Reconnect() As %Status
{
	#dim status As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	
	If ..connectParameters="" Return $$$ERROR($$$RemoteGatewayError,"Unable to Reconnect since not connected previously")

	Try {
		/* 1 host, 2 port, 3 namespace, 4 timeout, ..connectClassPaths, 5 sslConfiguration, 6 useSharedMemoryIfPossible */
		Set status=..%Connect($LG(..connectParameters,1),$LG(..connectParameters,2),$LG(..connectParameters,3),$LG(..connectParameters,4),..connectClassPaths,$LG(..connectParameters,5),,$LG(..connectParameters,6))
	} Catch ex {
		Set status = $$$ERROR($$$RemoteGatewayError,"Unable to Reconnect: "_$System.Status.GetOneErrorText(ex.AsStatus()))
	}
	
	Quit status
}

Method isAlive() As %Boolean
{
	if ..Closed return 0
	try {
		set currentDevice = $io
		use ..GatewayDevice
		do $system.OS.SendRequest(0,"",..#PING)
		set returnCode = $system.IS.ReceiveHeader(..#INPUTTIMEOUT)
		use currentDevice
		return $li(returnCode,4)=..#PING
	} catch ex {
		use currentDevice
		return 0
	}
}

/// Check if an External Language Server still alive. <br/>
/// To connect to an External Language Server by name, please pass empty string as first argument and Gateway name as second argument
/// Please note if a ELS definition is secure, then connecting by ELS name is required.
/// Connecting using host and port only works for unsecure External Language Servers
/// When parameter <var>reuseSocket</var> is true (the default is false), the TCP socket will not be opened or closed and
/// it is up to the caller must ensure that the device is already opened.
ClassMethod %Ping(host As %String = "127.0.0.1", port As %Integer, timeout As %Numeric = 5, reuseSocket As %Boolean = 0, ByRef gatewayDevice As %String = "", ByRef serverFullName As %String = "", sslConfiguration As %String = "") As %Status [ Final ]
{
	Set status=$$$OK
	Set currentDevice=$IO
	set serverName = ""
	set serverFullName = ""
	Try {
		if host="" {
			set serverName = port
			set port = ""
		} else {
			set serverName = ..%FindServerByHostPort(host,port)
		}
		if serverName'="" {
			set status = ##class(%Net.Remote.Service).OpenGateway(serverName, .objGateway) quit:$$$ISERR(status)
			set status = $$CheckRequiredResource^%SYS.Gateway(objGateway) quit:$$$ISERR(status)
			set allowedip = objGateway.AllowedIPAddresses
			set host = $s(objGateway.Type="Remote":objGateway.Address,1:$case(allowedip,"0.0.0.0":"127.0.0.1","::":"::1",:allowedip))
			if port="" set port = objGateway.Port
			set sslConfiguration = objGateway.SSLConfigurationClient
		}
		If reuseSocket {
			#;Compatibility - some code relies on device always being "|TCP|"_port.
			If gatewayDevice="" Set gatewayDevice="|TCP|"_port
			Use gatewayDevice
		}
		Else {
			set closeDevice = 1
			Set gatewayDevice=..%freeTCPDevice(port)
			;
			if (sslConfiguration="") {
				open gatewayDevice:(host:port:"AdS"::::5):timeout
				if '$T Set status=$$$ERROR($$$RemoteGatewayError,"Connection cannot be established") quit
			} else {
				set doopen=0
				try {
					set tns=$namespace zn "%SYS"
					set srv=##class(Security.SSLConfigs).%OpenId(sslConfiguration,,.tSC)
					if $$$ISOK(tSC) && (srv.Type=0) { set doopen=1 }
					zn tns
				} catch {
					//Namespace error checking for SSLConfig, try anyway
					set doopen=1
				}
				if doopen=1 {
					open gatewayDevice:(host:port:/SSL=sslConfiguration::::5):timeout
					if '$T Set status=$$$ERROR($$$RemoteGatewayError,"SSL Connection cannot be established") Quit
				} else {
					set status=$$$ERROR($$$RemoteGatewayError,"SSL Configuration: """_sslConfiguration_""" is invalid, Connection terminated") quit
				}
			}
			;
			Use gatewayDevice:(::"-d"::32767:32767)
			// Send passphrase if defined
			#dim tPhrase As %Integer
			If ##class(%Net.Remote.Utility).GetPassphrase(serverName,.tPhrase) {
				Write $C(0,0,0,0)_$e($j(tPhrase,8),1,8)_$C(0,0),*-3
			}
		}
		; PING always uses sequence number 0
		do $system.OS.SendRequest(0,"",..#PING)
		;
		try {
			set returnCode = $system.IS.ReceiveHeader(..#INPUTTIMEOUT)
			if $System.IS.BytesLeftInMsg()>0 set serverFullName = $system.IS.Receive()
		} catch {
			if reuseSocket {
				Set status=$$$ERROR($$$RemoteGatewayError,"Communication failure on device: "_gatewayDevice)
			} else {
				Set status=$$$ERROR($$$RemoteGatewayError,"Communication failure on port: "_port)
			}
		}
		if $$$ISERR(status) quit
		;
		set msgid = $li(returnCode,2)
		If 'reuseSocket {
			Try {
				Use gatewayDevice
				; PING always uses sequence number 0
				do $system.OS.SendRequest(0,"",..#DISCONNECT)
				set returnCode = $system.IS.ReceiveHeader()
			} Catch exception {
				Set status=..%SetStatus(exception)
			}
			Close gatewayDevice
		}
	} Catch exception {
		If ($ZE["<READ>")||($ZE["<DSCON>") Set status=$$$ERROR($$$RemoteGatewayError,"TCP error on port '"_port_"', ensure there is an Object Gateway running on this port")
		Else  Set status=..%SetStatus(exception)
	}
	if $g(closeDevice) close gatewayDevice
	Use currentDevice
	Quit status
}

/// Close the connection
Method %Disconnect() As %Status [ Final ]
{
	Quit:..Closed $$$OK
	Set status=$$$OK
	if '..xdbcConnection {
		Try {
			Set ..CurrentDevice=$IO
			Use ..GatewayDevice
			; CONNECT must have sequence number 0 in order to negotiate with older jar file
			do $system.OS.SendRequest(0,"",..#DISCONNECT)
			Try {
				// this read is here to prevent closing the GatewayDevice below, before the
				// server has had a chance to read the disconnect message sent above. for shared
				// memory connections closing the device too quickly after sending the disconnect
				// message may mean that the server never sees the message and keeps the connection
				// open until this process terminates. waiting until this header read either completes
				// or throws a <READ> or <NOTOPEN> error (which indicates the server process has
				// already disconnected) prevents this race condition.
				set returnCode = $system.IS.ReceiveHeader()
				//Set:fun="B1" fun=..%CallServer(fun,msgid)
			} Catch ex { }
		} Catch exception {
			Set status=..%SetStatus(exception)
		}
	}
	Set ..Closed=1
	Try {
		Use ..CurrentDevice
		Close ..GatewayDevice
		kill ..ClosedProxies
		Kill ..ProxyObjectHolder
		do ##class(%SYS.DBSRV).GWDisconnect(..GatewayDevice)
	} Catch exception {
		Set:$$$ISOK(status) status=..%SetStatus(exception)
	}
	Quit status
}

/// This callback method is invoked by the <METHOD>%Close</METHOD> method to 
/// provide notification that the current object is being closed.
/// 
/// <P>The return value of this method is ignored.
Method %OnClose() As %Status [ Private, ProcedureBlock = 1 ]
{
	Quit ..%Disconnect()
}

/// Shut down the Gateway
Method %Shutdown(timeout = 0) As %Status [ Final ]
{
	quit:..Closed $$$ERROR($$$RemoteGatewayError,"Connection not open")
	try {
		set soft = ''timeout
		set ..CurrentDevice=$IO
		use ..GatewayDevice
		set status = ..sendOneShutdown(soft)
		;
		if $$$ISERR(status) use ..CurrentDevice quit
		if timeout=-1       use ..CurrentDevice quit
		if ..Closed         use ..CurrentDevice quit
		;
		for i=1:1:timeout {
			set count = ..%CallUtilityMethod("getGatewayThreadCount")
			if count=1 {
				return ..%Disconnect()
			}
			hang 1
		}
		;
		set status = ..sendOneShutdown(0)
		set ..Closed=1
		use ..CurrentDevice
		close ..GatewayDevice
		;
	} catch exception {
		set status=..%SetStatus(exception)
	}
	quit status
}

Method sendOneShutdown(soft = 0) As %Status [ Final ]
{
	Try {
		Set status=$$$OK
		set ..SequenceNumber = ..SequenceNumber+2
		do $system.OS.SendRequest(..SequenceNumber,"",..#SHUTDOWN, soft)
		Try {
			// this read is here to prevent closing the GatewayDevice below, before the
			// server has had a chance to read the shutdown message sent above. for shared
			// memory connections closing the device too quickly after sending the shutdown
			// message may mean that the server never sees the message and proceeds as though
			// a disconnect happened instead. waiting until this header read either completes
			// or throws a <READ> or <NOTOPEN> error (which indicates the server process has
			// already shutdown) prevents this race condition.
			set returnCode = $system.IS.ReceiveHeader()
			;
			set msgid = $li(returnCode,2)
			set context = $li(returnCode,3)
			set fun = $li(returnCode,4)
			;
			if fun=..#SHUTDOWN return status
			if fun="DC" quit
			set status = $$$ERROR($$$RemoteGatewayError,"Invalid function code, expecting "_..#SHUTDOWN_", received "_fun)
			
		} Catch ex { }
		
		Set ..Closed=1
		Use ..CurrentDevice
		Close ..GatewayDevice
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Quit status
}

/// Creates all necessary proxy classes
Method %Import(javaClass As %String, ByRef javaClasses As %ListOfDataTypes, additionalClassPaths As %ListOfDataTypes = "", exclusions As %ListOfDataTypes = "", verbose As %Boolean = 0) As %Status [ Final ]
{
	Quit:..Closed $$$ERROR($$$RemoteGatewayError,"Connection not open")
	Quit:(verbose&&(..CurrentDevice=..GatewayDevice)) $$$ERROR($$$RemoteGatewayError,"Cannot print output because current device is gateway device")
	Set cosClasses=##class(%ListOfDataTypes).%New()
	Set javaClasses=##class(%ListOfDataTypes).%New()
	Try {
		Set status=$$$OK
		Set ..CurrentDevice=$IO
		Use ..GatewayDevice
		// name of Java class/jarFile to be imported
		Set x=$zobjexport(javaClass,18)
		do ..convertClassPaths(.thelist,additionalClassPaths)
		set x = $zobjexport(thelist,18)
		for i=1:1:thelist {
			set x = $zobjexport(thelist(i),18)
		}
		// list of java class package and class prefixes to be excluded
		// during dependency class generation
		If (exclusions="") {
			Set x=$zobjexport(0,18)
		} Else {
			Set size=exclusions.Count()
			Set x=$zobjexport(size,18)
			For i=1:1:size {
				Set x=$zobjexport(exclusions.GetAt(i),18)
			}
		}
		set ..SequenceNumber = ..SequenceNumber+2
		set x=$zobjexport(..SequenceNumber,1)
		Set x=$zobjexport(..#GENERATECLASSES,8)
LoadLoop Quit:status'=$$$OK
		Use ..GatewayDevice 
		Set msgid=$zobjexport(21),fun=$zobjexport(15)
		If (fun=..#LOADCOSCLASS) {
			Set javaName=$zobjexport(12)
			Set cosName=$zobjexport(12)
			Set status=..%LoadCOSClass(verbose,..CurrentDevice,..GatewayDevice)
			Quit:status'=$$$OK
			Do javaClasses.Insert(javaName)
			Do cosClasses.Insert(cosName)
			Goto LoadLoop
		} ElseIf (fun=..#EXCEPTIONRAISED) {
			Set status=..%GetException()
		} ElseIf (fun=..#GETTIMESTAMP) {
			Do ..%GetTimestamp(msgid)
			Goto LoadLoop
		}
		If status=$$$OK {
			Use ..CurrentDevice
			Set qspec = $Select(verbose:"frd",1:"fr-d")
			if $g(^%SYS("Gateway","Remote","Recast",$namespace),$g(^%SYS("Gateway","Remote","Recast"),1)) {
				For i=1:1:cosClasses.Count() {
					do ..%RecastClass(cosClasses.GetAt(i),verbose)
				}
			}
			For i=1:1:cosClasses.Count() {
				Set status=$System.OBJ.Compile(cosClasses.GetAt(i),qspec)
				Quit:status'=$$$OK
			}
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Use ..CurrentDevice
	Quit status
}

ClassMethod %RecastClass(classname, verbose)
{
	if verbose write "Recasting class "_classname_" ..."
	set class = ##class(%Dictionary.ClassDefinition).%OpenId(classname)
	if class="" quit
	set class.Super = "%Net.Remote.Base"
	;
	for u=1:1:class.UDLTexts.Count() {
		set udl = class.UDLTexts.GetAt(u)
		set content = udl.Content
		set text = ""
		for l=1:1 {
			quit:content.AtEnd
 			set line = content.ReadLine($$$MaxLocalLength)
 			if $e(line,*)=$c(13) set line=$e(line,1,*-1)
 			if $e(line,1,2)="//" set line = $e(line,3,*)
			set text = text_$c(13,10)_line
		}
		set UDL(udl.SequenceNumber) = text
	}
	do class.UDLTexts.Clear()
	;
	for m=1:1:class.Methods.Count() {
		set method = class.Methods.GetAt(m)
		if method="" continue
		;
		set fullFormalspec = method.FormalSpec
		set cleanFormalSpec =""
		for i=1:1:$l(fullFormalspec,",") {
			set arg = $p(fullFormalspec,",",i)
			set arg = $p(arg,":",1)
			if $e(arg,1)="&" set arg = $e(arg,2,*)
			set cleanFormalSpec = cleanFormalSpec_","_arg
		}
		set cleanFormalSpec = $e(cleanFormalSpec,2,*)
		;
		if method.Name="%OnNew" {
			set method.Description = "Method "_method.Name_"(gateway"
			set cleanFormalSpec = $p(cleanFormalSpec,",",1,*-1)
			if cleanFormalSpec'="" set method.Description = method.Description_","_cleanFormalSpec
			set method.Description = method.Description_")"
		} elseif method.ClassMethod {
			set method.Description = "ClassMethod "_method.Name_"(gateway"
			set cleanFormalSpec = $p(cleanFormalSpec,",",1,*-1)
			if cleanFormalSpec'="" set method.Description = method.Description_","_cleanFormalSpec
			set method.Description = method.Description_")"
		} else {
			set method.Description = "Method "_method.Name_"("_cleanFormalSpec_")"
		}
		set udltext = $g(UDL(method.SequenceNumber-1))
		if udltext="",cleanFormalSpec'="" set udltext = $c(13,10)_"argument(s) overloaded"
		set method.Description = method.Description_udltext
		;
		;if classname="InterSystems.Gateway.UnitTest.Person" break
		if method.Name="%OnNew" {
			set line1 = method.Implementation.ReadLine()
			set line2 = method.Implementation.ReadLine()
			set correctline = ($p($p($p(line2,"""",1)," ",1),":",1)=($c(9)_"Quit")) && ($p($p(line2,"""",1)," ",2)="..%Constructor(p0,")
			set realname = $p(line2,"""",2)
			if correctline&&(realname'=classname) {
				set parameter = ##class(%Dictionary.ParameterDefinition).%New()
				set parameter.Name = "REMOTECLASSNAME"
				set parameter.Default = realname
				set parameter.Type = "STRING"
				set parameter.SequenceNumber = 1
				do class.Parameters.Insert(parameter)
			}
		}
		if method.Name = "%OnNew" {
			set method.FormalSpec = "gateway:%Net.Remote.Gateway,args..."
			set line1 = "    if $IsObject($g(gateway))=0 return $$$OK"
			set line2 = "    quit ..%Constructor(gateway,,args...)"
			set method.ReturnType = "%Status"
		} elseif method.ClassMethod {
			set method.FormalSpec = "gateway:%Net.Remote.Gateway,&args...:%ObjectHandle"
			set line1 = "    quit:$quit ..%dispatch(,$classname(),"""_method.Name_""",gateway,args...)"
			set line2 = "    do ..%dispatch(,$classname(),"""_method.Name_""",gateway,args...)"
			set method.ReturnType = "%ObjectHandle"
		} else {
			set method.FormalSpec = "&args...:%ObjectHandle"
			set line1 = "    quit:$quit ..%dispatch(,$this,"""_method.Name_""",..%gateway,args...)"
			set line2 = "    do ..%dispatch(,$this,"""_method.Name_""",..%gateway,args...)"
			set method.ReturnType = "%ObjectHandle"
		}
		do method.Implementation.Rewind()
		do method.Implementation.WriteLine(line1)
		do method.Implementation.WriteLine(line2)
	}
	set sc = class.%Save()
	if $$$ISERR(sc) do $system.OBJ.DisplayError(sc)
	if verbose write !
	quit
}

ClassMethod %LoadCOSClass(verbose As %Boolean = 0, currentDevice As %String = "", gatewayDevice As %String = "") As %Status [ Final ]
{
	Quit:(verbose&&(currentDevice=gatewayDevice)) $$$ERROR($$$RemoteGatewayError,"Cannot print output because current device is gateway device")
	Set chunks=$zobjexport(12)
	Set stream=##class(%GlobalCharacterStream).%New()
	For i=1:1:chunks {
		Do stream.Write($zobjexport(12))
	}
	If verbose&&(""'=currentDevice)&&(""'=gatewayDevice) {
		Use currentDevice
		Set tSC = $System.OBJ.LoadStream(stream,"d")
		Use gatewayDevice
	} Else {
		Set tSC = $System.OBJ.LoadStream(stream,"-d")
	}
	Quit tSC
}

/// Add to current classpath
Method %AddToCurrentClassPath(paths As %ListOfDataTypes, useProcessLoader As %Boolean = 0) As %Status [ Final ]
{
	Set status=$$$OK
	Try {
		do ..convertClassPaths(.thelist,paths)
		if thelist=0 quit
		Set ..CurrentDevice=$IO
		Use ..GatewayDevice	
		Set x=$zobjexport($s(useProcessLoader:thelist_":system",1:thelist),18)
		For i=1:1:thelist {
			Set x=$zobjexport(thelist(i),18)
		}
		set ..SequenceNumber = ..SequenceNumber+2
		set x=$zobjexport(..SequenceNumber,1)
		Set x=$zobjexport(..#ADDTOCURRENTCLASSPATH,8)
		for {
			Set msgid=$zobjexport(21),fun=$zobjexport(15),context=0
			If (fun=..#EXCEPTIONRAISED) {
				Set status=..%GetException()
				quit
			}
			if msgid#2=1 {
				; push gateway context stack
				do $system.Context.Gateway().push($this)
				; dispatch to system to handle
				do $system.IS.SetApplicationDevice(..CurrentDevice)
				set returnCode = ##class(%Net.Remote.Object).%DispatchNativeCall(..GatewayDevice,msgid,context,fun)
				; pop gateway context stack
				do $system.Context.Gateway().pop()
				continue
			}
			quit
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Use ..CurrentDevice
	Quit status
}

ClassMethod convertClassPaths(thelist, paths)
{
	set thelist = 0
	if $isObject(paths) {
		if $classname(paths)="%Library.DynamicArray" {
			for i=1:1:paths.%Size() set thelist($i(thelist)) = paths.%Get(i-1)_""
		} else {
			for i=1:1:paths.Count() set thelist($i(thelist)) = paths.GetAt(i)_""
		}
	} else {
		if paths'="" {
			set thelist($i(thelist)) = paths
		}
	}
	quit
}

/// Calls Class.forName
Method %ClassForName(className As %String) As %Status [ Final ]
{
	Quit:..Closed $$$ERROR($$$RemoteGatewayError,"Connection not open")
	Try {
		Set status=$$$OK
		Set ..CurrentDevice=$IO
		Use ..GatewayDevice
		Set x=$zobjexport(className,18)
		set ..SequenceNumber = ..SequenceNumber+2
		set x=$zobjexport(..SequenceNumber,1)
		Set x=$zobjexport(..#LOADJAVACLASS,8)
		Set msgid=$zobjexport(21),fun=$zobjexport(15)
		If (fun=..#EXCEPTIONRAISED) {
			Set status=..%GetException()
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Use ..CurrentDevice
	Quit status
}

Method %ClassForNameSynch(className As %String) As %Status [ Final ]
{
	// synchronize on DriverManager to load JDBC drivers
	Quit:..Closed $$$ERROR($$$RemoteGatewayError,"Connection not open")
	Try {
		Set status=$$$OK
		Set ..CurrentDevice=$IO
		Use ..GatewayDevice
		Set x=$zobjexport(className,18)
		set ..SequenceNumber = ..SequenceNumber+2
		set x=$zobjexport(..SequenceNumber,1)
		Set x=$zobjexport(..#LOADJAVACLASSSYNCH,8)
		Set msgid=$zobjexport(21),fun=$zobjexport(15)
		If (fun=..#EXCEPTIONRAISED) {
			Set status=..%GetException()
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Use ..CurrentDevice
	Quit status
}

/// Use the implements parameter to limit the classes to those implementing a specific interface
/// The interface must be declared either in isc-gateway, or jarFileName JAR file
Method %GetAllClasses(jarFileName As %String, ByRef allClasses As %ListOfDataTypes, implements As %String = "") As %Status
{
	Quit:..Closed $$$ERROR($$$RemoteGatewayError,"Connection not open")
	Try {
		Set status=$$$OK
		Set ..CurrentDevice=$IO
		Use ..GatewayDevice
		Set x=$zobjexport(jarFileName,18)
		If (implements '= "") {
			Set x=$zobjexport(implements,18)
		}
		set ..SequenceNumber = ..SequenceNumber+2
		set x=$zobjexport(..SequenceNumber,1)
		Set x=$zobjexport(..#GETAVAILABLECLASSES,8)
		Set msgid=$zobjexport(21),fun=$zobjexport(15)
		If (fun=..#EXCEPTIONRAISED) {
			Set status=..%GetException()
		} Else {
			Use ..GatewayDevice Set count=$zobjexport(12)
			Set allClasses=##class(%ListOfDataTypes).%New()
			For i=1:1:count {
				Do allClasses.Insert($zobjexport(12))
			}
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Use ..CurrentDevice
	Quit status
}

Method %GetTimestamp(msgid As %Integer)
{
	Use ..GatewayDevice
	Set className=$zobjexport(12)
	Try {
		set isClassRecast = $g(^oddDEF(className,60))="%Net.Remote.Base"
		if (''$g(^%SYS("Gateway","Remote","Recast",$namespace),$g(^%SYS("Gateway","Remote","Recast"))))=isClassRecast {
			set timestamp=$classmethod(className,"%GetParameter","IMPORTTIMESTAMP")
		} else {
			set timestamp="0"
		}
	} Catch {
		Set timestamp="0"
	}
	Set x=$zobjexport(timestamp,18)
	Set x=$zobjexport(msgid,1)
	Set x=$zobjexport(..#GETTIMESTAMP,8)
}

Method %GetException() As %String [ Private ]
{
	Use ..GatewayDevice Set error=$zobjexport(12)
	Use ..CurrentDevice
	Quit $$$ERROR($$$RemoteGatewayError,error)
}

ClassMethod %SetStatus(exception As %Exception.StatusException) As %Status
{
	Quit $$$ERROR($$$RemoteGatewayError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
}

Method %RegUpdate()
{
	Use ..GatewayDevice
	set count=0,oref="" for  set oref=$o(..ClosedProxies(oref)) quit:oref=""  set count=count+1,orefs(count)=oref
	set x=$zobjexport(count,18)
	for i=1:1:count set x=$zobjexport(orefs(i),18)
	kill ..ClosedProxies
}

/// Generate proxy classes for an External language module.
/// To connect to an External Language Server by name, please pass empty string as first argument and Gateway name as second argument.
/// Please note if a ELS definition is secure, then connecting by ELS name is required.
/// Connecting using host and port only works for unsecure External Language Servers.
ClassMethod %ExpressImport(name As %String, port As %Integer, host As %String = "127.0.0.1", silent As %Boolean = 0, additionalClassPaths As %ListOfDataTypes = "", exclusions As %ListOfDataTypes = "") As %ListOfDataTypes [ Final ]
{
	Try {
		Set namespace=$namespace,timeout=2,classes=""
		Set currentDevice=$IO
		Set gateway=##class(%Net.Remote.Gateway).%New()
		Set status=gateway.%Connect(host,port,namespace,timeout,additionalClassPaths) If status'=$$$OK { Write $system.OBJ.DisplayError(status) Quit }
		Set p=1
		For {
			Set piece=$P(name,";",p)
			Quit:piece=""
			Set status=gateway.%Import(piece,.classes,additionalClassPaths,exclusions) 
			If status'=$$$OK { Write $system.OBJ.DisplayError(status),! Quit }
			Set p=p+1
		}
		Quit:status'=$$$OK
		Set status=gateway.%Disconnect()  
		If status'=$$$OK { Write $system.OBJ.DisplayError(status) Quit }
		Quit:silent
		If $G(classes)="" Set classes="" Quit
		Use currentDevice
		If classes.Count()=0 {
			Write "No proxy classes generated/all proxies up-to-date",!
			Quit
		}
		Write !,"Generated the following proxy classes:",!
		For i=1:1:classes.Count() {
			Write "  ["_i_"] "_classes.GetAt(i),!
		}
		Write !
	} Catch exception {
		Set status=##class(%Net.Remote.Gateway).%SetStatus(exception)
		Write $system.OBJ.DisplayError(status)
	}
	Quit classes
}

ClassMethod %RegisterSuperServer(name As %String, host As %String, port As %Integer = 0) [ Final ]
{
	do RegisterSuperServer^%SYS.Gateway(name, host, port)
}

ClassMethod %DeregisterSuperServer(name As %String) [ Final ]
{
	do DeregisterSuperServer^%SYS.Gateway(name)
	do ##class(%Net.Remote.Utility).ClearPassphrase(name)
}

ClassMethod %FindServerByHostPort(host As %String, port As %Integer) As %String [ Final ]
{
	set name="" for  {
		set name = $o(^%SYS("Gateway","Remote","ActiveSuperServers",name),1,hostport) quit:name=""
		if $li(hostport,2)'=port continue
		if ($li(hostport,1)="0.0.0.0")||($li(hostport,1)="::") {
			if ##class(%Net.Remote.Utility).IsServerLocal(host) return name
		} else {
			if $li(hostport,1)=host return name
		}
	}
	return ""
}

ClassMethod %TerminateSuperServer(name As %String, namespace As %String, deregister As %Boolean) [ Final ]
{
	set tSC = $$$OK
	try {
		set gateway = ##class(%Net.Remote.Gateway).%New()
		set tSC = gateway.%Connect("",name,namespace,1,,,,0)
		quit:$$$ISERR(tSC)
		set tSC = gateway.%Shutdown()
		quit:$$$ISERR(tSC)
		do:deregister ..%DeregisterSuperServer(name)
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %TerminateAllSuperServers() [ Final ]
{
	try {
		l +^%SYS("Gateway","Remote","ActiveSuperServers")
		set name = "" for  {
			set name = $o(^%SYS("Gateway","Remote","ActiveSuperServers",name)) quit:name=""
			do ..%TerminateSuperServer(name,$namespace,1)
		}
		do ClearAllSuperServers^%SYS.Gateway()
		do ClearAllPassphrases^%SYS.Gateway()
		l -^%SYS("Gateway","Remote","ActiveSuperServers")
	} catch ex {
		l -^%SYS("Gateway","Remote","ActiveSuperServers")
	}
}

ClassMethod %RemoteService(host As %String, port As %Integer, serviceName As %String, arguments As %String, additionalClassPaths As %ListOfDataTypes = "") As %String [ Final ]
{
	Set namespace=$namespace,timeout=2
	Set gateway=##class(%Net.Remote.Gateway).%New()
	$$$ThrowOnError(gateway.%Connect(host,port,namespace,timeout,additionalClassPaths))
	$$$ThrowOnError(gateway.%ServiceRequest(serviceName,arguments,.response))
	$$$ThrowOnError(gateway.%Disconnect())
	Quit response
}

Method %ServiceRequest(serviceName As %String, arguments As %String, ByRef response As %String) As %Status [ Final ]
{
	Quit:..Closed $$$ERROR($$$RemoteGatewayError,"Connection not open")
	Try {
		Set status=$$$OK
		Set ..CurrentDevice=$IO
		Use ..GatewayDevice
		Set x=$zobjexport(serviceName,18)
		Set x=$zobjexport(arguments,18)
		set ..SequenceNumber = ..SequenceNumber+2
		set x=$zobjexport(..SequenceNumber,1)
		Set x=$zobjexport(..#JAVASERVICE,8)
		Set msgid=$zobjexport(21),fun=$zobjexport(15)
		If (fun=..#JAVASERVICE) {
			Set response=$zobjexport(12)
		} ElseIf (fun=..#EXCEPTIONRAISED) {
			Set status=..%GetException()
		} Else {
			Set status=$$$ERROR($$$RemoteGatewayError,"Unknown response: "_fun)
		}
	} Catch exception {
		Set status=..%SetStatus(exception)
	}
	Use ..CurrentDevice
	Quit status
}

ClassMethod %freeTCPDevice(pRequest As %Integer = 55555, pMaxTries As %Integer = 1000) As %String [ Internal ]
{
	#dim tProc As %SYS.ProcessQuery
	#dim tDevice As %String = "|TCP|"_pRequest
	#dim tOpenDevices As %String
	#dim tTries As %Integer = 0
	#dim tJob As %String = $Job
	
	Try {
		/* %SYS.ProcessQuery not available at compilation time */
		Set tOpenDevices=$TR($P($View(-1,$j),"^",3),"*","")
		While (tOpenDevices[(tDevice_","))&&($I(tTries)<pMaxTries) {
			Set pRequest = $R(2147483647)+1
			Set tDevice = "|TCP|"_pRequest
		}
	} Catch {}

	Quit tDevice
}

/// Used to check if still connected to the gateway and mark as closed if no TCP connection
Method %LostConnectionCleanup() As %Boolean
{
	#dim tCurrentDevice As %String = $IO
	
	// using shared memory connection
	If (..SHMConnectString '= "") {
		Try {
			Set gwydev = ..GatewayDevice
			Set tSC = ..%Ping("127.0.0.1",$job,,1,.gwydev)
			$$$ThrowOnError(tSC)
		} Catch ex {
			Set ..Closed = 1
			kill ..ClosedProxies
			Close ..GatewayDevice
		}
	}
	// using TCP/IP connection
	Else {
		Try {
			Use ..GatewayDevice
			If '$SYSTEM.INetInfo.Connected() {
				Set ..Closed = 1
				kill ..ClosedProxies
				Close ..GatewayDevice
			}
		} Catch ex {
			#;Mark as closed if error since not valid
			Set ..Closed = 1
		}
	}
	
	#;Prevent <NOTOPEN> error if Closed for Use tCurrentDevice since at this point we are using ..GatewayDevice
	Use:..GatewayDevice'=tCurrentDevice tCurrentDevice
	
	Quit ..Closed
}

Method %PushGatewayDevice()
{
	set ..CurrentDeviceStack = $g(..CurrentDeviceStack)+1
	set ..CurrentDeviceStack(..CurrentDeviceStack) = $IO
	use ..GatewayDevice
	quit
}

Method %PopGatewayDevice()
{
	use ..CurrentDeviceStack(..CurrentDeviceStack)
	kill ..CurrentDeviceStack(..CurrentDeviceStack)
	set ..CurrentDeviceStack = $g(..CurrentDeviceStack)-1
	quit
}

Method %ClearGatewayDevice()
{
	use ..CurrentDeviceStack(1)
	kill ..CurrentDeviceStack
	quit
}

/// Returns true if the connection is open and connected over shared memory, false otherwise.
Method %IsUsingSharedMemory() As %Boolean
{
	quit ('..Closed && (..SHMConnectString'=""))
}

ClassMethod %GetContextGateway() As %Net.Remote.Gateway
{
	quit $system.Context.Gateway().get()
}

ClassMethod %CreateReverseGateway(device, protocol) As %Net.Remote.Gateway
{
	set gateway = ..%New()
	set gateway.GatewayDevice = device
	set gateway.ProtocolVersion = protocol
	set gateway.Closed = 0
	set gateway.xdbcConnection = 1
	quit gateway
}

ClassMethod %RetainObject(oref, gateway = "")
{
	if $g(%protocol)<58 quit
	if $isObject($g(oref))=0 quit
	if gateway="" set gateway = ##class(%Net.Remote.Gateway).%GetContextGateway()
	set key = +oref
	set gateway.ProxyObjectHolder(key) = $g(gateway.ProxyObjectHolder(key))+1
	set gateway.ProxyObjectHolder(key,gateway.ProxyObjectHolder(key)) = oref
	quit
}

ClassMethod %ReleaseObjects(orefs) As %String
{
	if $g(%protocol)<58 quit ""
	set gateway = ##class(%Net.Remote.Gateway).%GetContextGateway()
	for i=1:1:$l(orefs,",") {
		set key = +$p(orefs,",",i)
		if key=0 continue
		if $d(gateway.ProxyObjectHolder(key))#2=0 continue
		kill gateway.ProxyObjectHolder(key,gateway.ProxyObjectHolder(key))
		set gateway.ProxyObjectHolder(key) = gateway.ProxyObjectHolder(key)-1
		if gateway.ProxyObjectHolder(key)<=0 kill gateway.ProxyObjectHolder(key)
	}
	if $d(gateway.ClosedProxies) {
		set list = ""
		set oref="" for  set oref=$o(gateway.ClosedProxies(oref)) quit:oref=""  set list=list_","_oref
		kill gateway.ClosedProxies
		quit $e(list,2,*)
	} else {
		quit ""
	}
}

ClassMethod %SubscriptSortOrder(global, sub1, sub2) As %String
{
	if $e(global)="^" set global = $e(global,2,*)
	if $g(sub1)'="" kill X set X(sub1)="" set sub1 = $o(X(""))
	if $g(sub2)'="" kill X set X(sub2)="" set sub2 = $o(X(""))
	set dest = ##Class(%SYS.Namespace).GetGlobalDest($namespace,global)
	if $e(dest,1)="^" { 
		set coll = $zu(167,6,2,$p(dest,"^",2),global)
		if coll<0 set coll = $$$dbcollation($p(dest,"^",2))
	} else {
		set dollardata = $d(@("^"_global)) ; doing a $data() to force updating of ECP information
		set coll = $zu(167,7,2,$p(dest,"^",1),$p(dest,"^",2),global)
		if coll< 0 {
			set sfn = $zu(49,$p(dest,"^",1),$p(dest,"^",2),7)
			set coll = $p($zu(49,sfn,3),"^",5)
		}
	}
	set key1 = $zu(70,2,sub1,$zu(70,0,coll))
	set key2 = $zu(70,2,sub2,$zu(70,0,coll))
	if key2]key1 return 1
	if key1]key2 return -1
	return 0
}

ClassMethod %Benchmark(options As %String = "", server As %String = "", ByRef output) As %Numeric
{
	set tSC = $$$OK
	try {
		set iterations=1000000,type="shm",jobs=2,action="echo",mode="zobjexport",language="",verbose=0,prompt=1,display=1
		for i=1:1:$l(options,",") {
			set one = $p(options,",",i)
			continue:one=""
			if one["=" { set key=$p(one,"=",1),value=$p(one,"=",2) } else { set key=one,value=1 }
			set key = $zcvt($zstrip(key,"<>w"),"l")
			if key="count"      set iterations = value continue
			if key="iterations" set iterations = value continue
			if key="shm"        set type = "shm" continue
			if key="tcp"        set type = "tcp" continue
			if key="type"       set type = value continue
			if key="jobs"       set jobs = value continue
			if key="echo"       set action = "echo" continue
			if key="service"    set action = "service" continue
			if key="action"     set action = value continue
			if key="sysio"      set mode = "sysio" continue
			if key="zobjexport" set mode = "zobjexport" continue
			if key="raw"        set mode = "raw" continue
			if key="mode"       set mode = value continue
			if key="java"       set language = "java" continue
			if key=".net"       set language = ".net" continue
			if key="dotnet"     set language = ".net" continue
			if key="python"     set language = "python" continue
			if key="language"   set language = value continue
			if key="verbose"    set verbose = 1 continue
			if key="noprompt"   set prompt = 0 continue
			if key="nodisplay"  set display=0 continue
			write "invalid keyword: ",key,!
		}
		;
		if prompt read "press return to start tests ...",input,!
		;
		if server="" {
			if language="" set language = "java"
			set server = $case(language, "java":"%Java Server", ".net":"%DotNet Server", "python":"%Python Server", 1:"")
		} else {
			set tSC = ##class(%Net.Remote.Service).OpenGateway(server, .serverobj) quit:$$$ISERR(tSC)
			set language = $zconvert(serverobj.Type,"l")
			if (language'="java")&&(language'=".net")&&(language'="python") {
				set tSC = $$$ERROR($$$GeneralError,"Language """_language_""" not supported")
				quit
			}
		}
		;
		lock +^%Net.Remote.Gateway.Benchmark:30
		else  set tSC = $$$ERROR($$$GeneralError,"Unable to acquire lock") quit
		;
		set index = $i(^CacheTemp)
		kill ^CacheTemp(index)
		;
		for i=1:1:jobs {
			job ##class(%Net.Remote.Gateway).%BenchmarkOneJob(index,iterations,server,language,type,action,mode)
		}
		;
		lock -^%Net.Remote.Gateway.Benchmark
		;
		h 1
		;
		lock +^%Net.Remote.Gateway.Benchmark
		lock -^%Net.Remote.Gateway.Benchmark
		;
		if verbose zw ^CacheTemp(index)
		;
		set haserror = 0
		set job="" for  {
			set job = $o(^CacheTemp(index,job)) quit:job=""
			set error = $g(^CacheTemp(index,job,"error"))
			if error'="" set haserror=1 write error,!
		}
		if haserror quit
		;
		set overallStarted="",overallStopped="",overallDuration=0,overallSpeed="",jobCount=0,overallIterations=0
		set job="" for  {
			set job = $o(^CacheTemp(index,job)) quit:job=""
			set jobCount = jobCount + 1
			set overallIterations = overallIterations + ^CacheTemp(index,job,"iterations")
			if (overallStarted="")||(overallStarted>^CacheTemp(index,job,"started")) set overallStarted = ^CacheTemp(index,job,"started")
			if (overallStopped="")||(overallStopped<^CacheTemp(index,job,"stopped")) set overallStopped = ^CacheTemp(index,job,"stopped")
		}
		set overallDuration = overallStopped-overallStarted
		set overallSpeed = overallIterations\overallDuration
		;
		if display {
			write !
			write "      number of jobs: ",jobs,!
			write "     connection type: ",type,!
			write "              action: ",action,!
			write "           code mode: ",mode,!
			write "            language: ",language,!
			write "  iterations per Job: ",$fn(iterations,","),!
			write !
			write "  overall iterations: ",$fn(overallIterations,","),!
			write "overall time started: ",overallStarted,!
			write "overall time stopped: ",overallStopped,!
			write "    overall duration: ",overallDuration," seconds",!
			write "       overall speed: ",$fn(overallSpeed,",")," per second",!
		}
		;
	} catch ex {
		lock -^%Net.Remote.Gateway.Benchmark
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) do $system.OBJ.DisplayError(tSC)
	;
	quit $g(overallSpeed)
}

ClassMethod %BenchmarkOneJob(index = "", iterations = 1000000, server, language = "java", type = "shm", action = "echo", mode = "zobjexport")
{
	set tSC = $$$OK
	try {
		lock +^%Net.Remote.Gateway.Benchmark($j)
		set classname = $s(language="java":"com.intersystems.gateway.Benchmark",".net":"InterSystems.Data.IRISClient.Gateway.Benchmark",1:"")
		set gateway = $system.external.getGateway(server,type="shm")
		use gateway.GatewayDevice
		;set waitTimeTotal = 0
		;
		if action="echo" {
			if mode="raw" {
				set timeStarted = $zh
				for ctr=1:1:iterations {
					write $c(0,0,0,0,0,0,0,0,0,0,0,0)_"YY",!
					;set waitTimeStarted = $zh
					read response#14
					;set waitTimeTotal = waitTimeTotal+$zh-waitTimeStarted
				}
				set timeStopped = $zh
			} elseif mode="sysio" {
				set timeStarted = $zh
				for ctr=1:1:iterations {
					do $system.OS.SendRequest(0,"","YY")
					;set waitTimeStarted = $zh
					do $system.IS.ReceiveHeader()
					;set waitTimeTotal = waitTimeTotal+$zh-waitTimeStarted
				}
				set timeStopped = $zh
			} else {
				set timeStarted = $zh
				for ctr=1:1:iterations {
					set x=$zobjexport(0,1)
					set x=$zobjexport("YY",8)
					;set waitTimeStarted = $zh
					set msgid=$zobjexport(21),fun=$zobjexport(15)
					;set waitTimeTotal = waitTimeTotal+$zh-waitTimeStarted
				}
				set timeStopped = $zh
			}
		} else {
			if mode="raw" {
				set len = $l($lb(classname,"ABC"))
				set timeStarted = $zh
				for ctr=1:1:iterations {
					write $c(len,0,0,0,0,0,0,0,0,0,0,0)_"YK"_$lb(classname,"ABC"),!
					;set waitTimeStarted = $zh
					read response#19
					;set waitTimeTotal = waitTimeTotal+$zh-waitTimeStarted
					set response = $e(response,17,19)
					if response'="ABC" set tSC = $$$ERROR($$$GeneralError,"Incorrect data received") quit
				}
				set timeStopped = $zh
			} elseif mode="sysio" {
				set timeStarted = $zh
				for ctr=1:1:iterations {
					do $system.OS.SendRequest(0,"","YK",classname,"ABC")
					do $system.IS.ReceiveHeader()
					;set waitTimeStarted = $zh
					set response = $system.IS.Receive()
					;set waitTimeTotal = waitTimeTotal+$zh-waitTimeStarted
					if response'="ABC" set tSC = $$$ERROR($$$GeneralError,"Incorrect data received") quit
				}
				set timeStopped = $zh
			} else {
				set timeStarted = $zh
				for ctr=1:1:iterations {
					set x=$zobjexport(classname,18)
					set x=$zobjexport("ABC",18)
					set x=$zobjexport(0,1)
					set x=$zobjexport("YK",8)
					set msgid=$zobjexport(21),fun=$zobjexport(15)
					;set waitTimeStarted = $zh
					set response=$zobjexport(12)
					;set waitTimeTotal = waitTimeTotal+$zh-waitTimeStarted
					if response'="ABC" set tSC = $$$ERROR($$$GeneralError,"Incorrect data received") quit
				}
				set timeStopped = $zh
			}
		}
		quit:$$$ISERR(tSC)
		set tSC = gateway.%Disconnect() quit:$$$ISERR(tSC)
		;
		set result("type") = type
		set result("action") = action
		set result("mode") = mode
		set result("language") = language
		set result("iterations") = iterations
		set result("started") = timeStarted
		set result("stopped") = timeStopped
		set result("duration") = timeStopped-timeStarted
		set result("speed") = iterations\(timeStopped-timeStarted)
		;set result("wait") = waitTimeTotal
		;
	} catch ex {
		use $p
		set tSC = ex.AsStatus()
	}
	;
	if $$$ISERR(tSC) set result("error") = $system.Status.GetErrorText(tSC)
	;
	if index'="" merge ^CacheTemp(index,$j) = result
	lock -^%Net.Remote.Gateway.Benchmark($j)
	;
	use $p
	zw result
	;
	quit
}

Method %CallUtilityMethod(methodname, args...)
{
	try {
		return ##class(%Net.Remote.Object).%ClassMethod($this,"**Utility**",methodname,args...)
	} catch ex {
		return ""
	}
}

Method ExternalLanguageGet()
{
	return ..%CallUtilityMethod("getLanguageName")
}

Method ExternalLanguageVersionGet()
{
	return ..%CallUtilityMethod("getLanguageVersion")
}

Method getProductVersion()
{
	return ..%CallUtilityMethod("getProductVersion")
}

ClassMethod %RedirectOutput(data As %String = "") As %Integer
{
	set gateway = ##class(%Net.Remote.Gateway).%GetContextGateway()
	if $isObject(gateway)=0 { RETURN 0 }
	do gateway.%CallUtilityMethod("writeOutput",data)
	RETURN 1
}

ClassMethod %WriteOutput(data1 As %String = "", data2 As %String = "")
{
	set currentDevice = $io
	set device = $g(^||%gatewayDevice(+$g(^||%gatewayDevice)))
	if device'="" use device
	;
	set gateway = ..%GetContextGateway()
	if (gateway'="")&&(gateway.OutputRedirectHandler'="") {
		set classname = $li(gateway.OutputRedirectHandler,1)
		set methodname = $li(gateway.OutputRedirectHandler,2)
		do $classmethod(classname,methodname,data1_data2)
	} else {
		for data = data1,data2 {
			for i=1:1:$l(data,$c(10)) {
				set line = $p(data,$c(10),i)
				if i>1 write !
				if $e(line,*)=$c(13) {
					write $e(line,1,*-1)
				} else {
					write line
				}
			}
		}
	}
	;
	if device'="" use currentDevice
}

Property OutputRedirectHandler As %String;

Method %SetOutputRedirectHandler(classname, methodname)
{
	set ..OutputRedirectHandler = $lb(classname, methodname)
}

Method %DumpProxyMaps()
{
	set separator = "------------------------------"
	set header = ">>> "
	set indent = "        "
	;
	; do one roundtip to clear all pending actions
	set unused = ..ExternalLanguage
	;
	set externalDump = ..%CallUtilityMethod("dumpProxyMaps")
	set externalDump = $tr(externalDump,$c(13),"")
	;
	write !
	write separator,!
	write "***       Proxy maps       ***",!
	write separator,!
	write header,"IRIS: closed %Net.Remote.Object objects:",!
	set oref="" for count=0:1 {
		set oref = $o(..ClosedProxies(oref)) quit:oref=""
		write indent,oref,!
	}
	if count=0 write indent,"(empty)",!
	;
	write separator,!
	write header,"IRIS: retained objects:",!
	set oref="" for count=0:1 {
		set oref = $o(..ProxyObjectHolder(oref),1,total) quit:oref=""
		if total {
			write indent,oref," = ",total,!
		} else {
			set count = count-1
		}
	}
	if count=0 write indent,"(empty)",!
	;
	for linenumber=1:1:$l(externalDump,$c(10)) {
		set line = $p(externalDump,$c(10),linenumber)
		set type = $p(line,":",1)
		set dump = $p(line,":",2,*)
		if type="" continue
		set data(type) = dump
	}
	;
	set types(1) = $lb("NetRemoteObjectMap", "External: %Net.Remote.Object proxy map:")
	set types(2) = $lb("IRISObjectMap",      "External: IRISObject proxy map:")
	set types(3) = $lb("PendingReleaseList", "External: pending release list:")
	;
	for index=1:1:3 {
		set dataindex = $li(types(index),1)
		set description = $li(types(index),2)
		write separator,!
		write header,description,!
		if $d(data(dataindex))=0 {
			write indent,"(unavailable)",!
		} elseif data(dataindex)="" {
			write indent,"(empty)",!
		} else {
			set data = data(dataindex)
			for i=1:1:$l(data,",") {
				write indent,$p(data,",",i),!
			}
		}
	}
	;
	write separator,!
	;
	quit
}

Method %FlushClosedIRISObjects() As %Boolean
{
	quit ''..%CallUtilityMethod("flushClosedIRISObjects")
}

}
