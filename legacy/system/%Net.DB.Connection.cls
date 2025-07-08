/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// This class implements the IRIS Native API for Object Script Connection interface. This class 
/// should never be instantiated directly, only through <class>%Net.DB.DataSource</class> using the 
/// CreateMethod() function. 
/// </p>
/// <p>
/// The public interface for this class includes only those items specified here. All other members are internal. 
/// <br>
/// 	<table border="1" cellspacing="0" cellpadding="1">
/// 		<tr>
/// 			<td><property>Host</property></td>
/// 			<td>property</td>
/// 			<td>The host specified when establishing the connection </td>
/// 		</tr>
/// 		<tr>
/// 			<td><property>Port</property></td>
/// 			<td>property</td>
/// 			<td>The port that this connection is connected. </td>
/// 		</tr>
/// 		<tr>
/// 			<td><property>Namespace</property></td>
/// 			<td>property</td>
/// 			<td>The namespace that this connection is connected. </td>
/// 		</tr>
/// 		<tr>
/// 			<td><property>Timeout</property></td>
/// 			<td>property</td>
/// 			<td>The timeout value specified establishing the connection </td>
/// 		</tr>
/// 		<tr>
/// 			<td><method>IsClosed</method></td>
/// 			<td>method</td>
/// 			<td>Returns true if this connection instance is no longer connected. </td>
/// 		</tr>
/// 		<tr>
/// 			<td><method>Close</method></td>
/// 			<td>method</td>
/// 			<td>Close this connection. </td>
/// 		</tr>
/// 		<tr>
/// 			<td><method>CreateIris</method></td>
/// 			<td>method</td>
/// 			<td>Returns an instance of <class>%Net.DB.Iris</class>. </td>
/// 		</tr>
/// 	</table>
/// </p>
/// <p>
/// </p>
Class %Net.DB.Connection Extends %RegisteredObject
{

Method CreateIris()
{
	if '..IsConnected {
		throw ##class(%Exception.General).%New("ConnectionError","ConnectionError","CreateIris","cannot create an iris object with a closed connection")
	}
	return ##class(%Net.DB.Iris).%New($this)
}

Method Close() As %Boolean
{
	$$$THROWONERROR(status,..Disconnect())
	return 1
}

Method IsClosed() As %Boolean
{
	return '(..IsConnected)
}

Property Host As %String;

Property Port As %Integer;

Property Namespace As %String;

Property Timeout As %Integer [ InitialExpression = 5 ];

Property IsConnected As %Boolean [ InitialExpression = 0, Internal ];

Property Type As %String [ Internal ];

Property RemoteIPAddress As %String [ Internal ];

Property RemoteProtocol As %Integer [ Internal ];

Property RemoteUnicode As %Boolean [ Internal ];

Property RemoteLocale As %String [ Internal ];

Property RemoteJobNumber As %String [ Internal ];

Property BufferSize As %Integer [ InitialExpression = {1024*1024}, Internal ];

Property TCPDevice As %String [ Internal ];

Property SHMFileName As %String [ Internal ];

Property SHMSize As %Integer [ Internal ];

Property SHMWaitFlag As %Boolean [ InitialExpression = 1, Internal ];

Property SHMTimeout As %Integer [ Internal ];

Property Device As %String [ Internal ];

Property MessageId As %Integer [ InitialExpression = 1, Internal ];

/// Constructor.
/// parameters:
/// 	remoteHost		[required] "SHM" for shared memory, host address for TCP
/// 						(plan to allow full shared memory host string to overwrite the other arguments in the future, but this is not supported yet)
/// 	remotePort		[required] port number for TCP connection
/// 	remoteNamespace	[required] namespace to connect to on server
/// 	bufferSize		[optional] TCP buffer size, and also the shared memory size if not specified separately. defaults to 2^20 bytes.
/// 	timeout			[optional] TCP device open timeout, and also the shared memory device timeout if not specified separately. defaults to 5 seconds.
/// 	shmFileName		[optional] name of physical file. defaults to empty string, indicating virtual page file.
/// 	shmSize			[optional] shared memory size. defaults to the TCP buffer size if not specified.
/// 	shmWaitFlag		[optional] controls logging on/off = 1/0. default is logging on = 1. possibly controls other options also, but not sure.
/// 	shmTimeout		[optional] time to wait for shared memory device to open. defaults to the TCP timeout if not specified.
/// <p>
/// Examples:
/// <pre>
/// 	(1) connect and disconnect over TCP/IP
/// 	set conn = ##class(%Net.DB.Connection).%New("127.0.0.1",56773,"USER")
/// 	set tSC = conn.Connect("_SYSTEM","SYS")
/// 	set tSC = conn.Disconnect()
/// 	
/// 	(2) connect and disconnect over shared memory
/// 	set conn = ##class(%Net.DB.Connection).%New("SHM",56773,"USER")
/// 	set tSC = conn.Connect("_SYSTEM","SYS")
/// 	set tSC = conn.Disconnect()
/// </pre>
/// </p>
Method %OnNew(remoteHost, remotePort, remoteNamespace, bufferSize, timeout, shmFileName, shmSize, shmWaitFlag, shmTimeout) As %Status [ Internal ]
{
	set ..Port = remotePort
	set ..Namespace = remoteNamespace
	set ..Type = $case($extract(remoteHost,1,3),"SHM":"SHM",:"TCP")
	set ..RemoteIPAddress = $case(..Type,"SHM":"127.0.0.1",:remoteHost)
	set:$get(bufferSize) ..BufferSize = bufferSize
	
	set ..SHMFileName = $get(shmFileName)
	set ..SHMSize = $get(shmSize,..BufferSize)
	set ..SHMWaitFlag = $get(shmWaitFlag,1)
	set ..SHMTimeout = $get(shmTimeout,..Timeout)
	set ..Host = $case(..Type,"SHM":"SHM|"_..RemoteJobNumber_"|"_..SHMSize_"|"_..SHMFileName_"|"_..SHMWaitFlag_"|"_..SHMTimeout,:remoteHost)
	
	quit $$$OK
}

/// Increments the MessageId property and returns the value.
Method NextMessageId() As %Integer [ Final, Internal ]
{
	set ..MessageId = (..MessageId+1)
	quit ..MessageId
}

/// Connects to another InterSystems IRIS process via the DBSRV routine.
/// Sends two messages: handshake (HS), connect (CN).
/// parameters:
/// 	username			[required] server username
/// 	password			[required] server password
/// 	autoCommit			[optional] 1=yes,2=no. default is 1=yes.
/// 	isolationLevel		[optional] READ_VERIFIED=3,READ_COMMITTED=2,READ_UNCOMMITTED=1. default is 2=READ_COMMITTED.
/// 	clientSQLOptions	[optional] options supported by client, only for protocol 57+. fastSelect=1,fastInsert=2,Sharding=4,Parallel=8. default is 1=fastSelect only.
/// 	licenseIPAddress	[optional] IP address to use for license ID. only applies to TCP/IP connections.
Method Connect(username As %String = "", password As %String = "", autoCommit As %Integer = 1, isolationLevel As %Integer = 2, clientSQLOptions As %Integer = 1, licenseIPAddress As %String = "") As %Status [ Internal ]
{
	quit:..IsConnected $$$ERROR($$$GeneralError,"Already connected")
	
	set io = $IO
	set tSC = $$$OK
	try {
		set ..TCPDevice = ##class(%Net.Remote.Gateway).%freeTCPDevice()
		close ..TCPDevice
		open ..TCPDevice:(..RemoteIPAddress:..Port:"S"::..BufferSize:..BufferSize):..Timeout
		if '$test set tSC = $$$ERROR($$$GeneralError,"TCP device failed to open") quit
		use ..TCPDevice
		
		// client --> server
		set x = $zobjexport(..NextMessageId(),1) // write msgid
		set x = $zobjexport(0,2) // write stmtid=0
		set x = $zobjexport("HS",8) // write header, opcode HS=handshake
		write 57,! // local protocol version
		
		// server --> client
		set msgid = $zobjexport(21) // read header msgid,stmtid
		set stmtid = $zobjexport(10)
		set errcode = $zobjexport(11)
		if (errcode'=0) {
			set errmsg = $zobjexport(12)
			set tSC = $$$ERROR($$$GeneralError,"Error on handshake message (HS) reply from server: "_errmsg)
			quit
		}
		set ..RemoteProtocol = $ascii($zobjexport(2,13)) // server protocol version
		set ..RemoteUnicode = $ascii($zobjexport(2,13)) // server unicode boolean
		set ..RemoteLocale = $zobjexport(12) // server local
		
		// client --> server
		set x = $zobjexport(..NextMessageId(),1) // write msgid
		set x = $zobjexport(0,2) // write stmtid=0
		set x = $zobjexport("CN",8) // write header, opcode CN=connect
		set x = $zobjexport(..Namespace,3) // server namespace
		set x = $zobjexport($zutil(124,0,username),3) // server username, Unicode encoded
		set x = $zobjexport($zutil(124,0,password),3) // server password, Unicode encoded
		set x = $zobjexport($system.Process.UserName(),3) // client machine username
		set x = $zobjexport($zu(67,12,$job),3) // client machine name
		set x = $zobjexport($classname(),3) // client application name
		set x = $zobjexport($zu(67,14,$job),3) // client machine info
		set:$get(licenseIPAddress)="" licenseIPAddress = $system.Process.ClientIPAddress()
		set:$get(licenseIPAddress)="" licenseIPAddress = "127.0.0.1"
		set x = $zobjexport($case(..Type,"SHM":..Host,:licenseIPAddress),3) // client IP address used as license ID
		set x = $zobjexport($char(0),3) // event class
		set x = $zobjexport(autoCommit,3) // auto commit 1=yes/2=no
		set x = $zobjexport(isolationLevel,3) // isolation level READ_VERIFIED=3,READ_COMMITTED=2,READ_UNCOMMITTED=1
		set:..RemoteProtocol>56 x = $zobjexport(clientSQLOptions,3) // options supported by client only (fastSelect=1, fastInsert=2, Sharding=4, Parallel=8)
		set x = $zobjexport(0,8)
		
		// server --> client
		set msgid = $zobjexport(21) // read header msgid,stmtid
		set stmtid = $zobjexport(10)
		set errcode = $zobjexport(11)
		if (errcode'=0) {
			set errmsg = $zobjexport(12)
			set tSC = $$$ERROR($$$GeneralError,"Error on connect message (CN) reply from server: "_errmsg)
			quit
		}
		set serverVersion = $zobjexport(12) // server version string
		if $find(serverVersion,"Access Denied") {
			$$$ThrowStatus($$$ERROR($$$GeneralError,serverVersion))
		}
		set delimitedIds = $zobjexport(12) // delimited ids
		set synchronousCommit = $zobjexport(12) // server synchronous commit
		set supportedIsolationLevels = $zobjexport(12) // server supported isolation levels
		set ..RemoteJobNumber = $zobjexport(12) // server Cache job number
		set:..RemoteProtocol>41 sqlEmptyString = $zobjexport(12) // sql empty string
		set:..RemoteProtocol>56 serverOptions = $zobjexport(12) // options supported by client and server (fastSelect=1, fastInsert=2, Sharding=4, Parallel=8)
		
		set ..Device = ..TCPDevice
		if (..Type="SHM") {
			new %qrc,%msg,%qOBUFSIZE,%qIBUFSIZE
			do $SYSTEM.Context.XDBCServer().pushState() set contextStatePushed=1
			set shmConnectionStr = "SHM|"_..RemoteJobNumber_"|"_..SHMSize_"|"_..SHMFileName_"|"_..SHMWaitFlag_"|"_..SHMTimeout
			do ##class(%SYS.DBSRV).SetupShmDevice(.shmDevice,shmConnectionStr,1,.tSC,..Device)
			quit:$$$ISERR(tSC)
			set ..Device = shmDevice
			do $SYSTEM.Context.XDBCServer().popState() set contextStatePushed=0
		}
		set ..IsConnected = 1
	} catch exception {
		try {
			close ..Device
			close ..TCPDevice
			if $g(contextStatePushed) { do $SYSTEM.Context.XDBCServer().popState() }
		} catch inner {
		}
		use io
		set tSC = $$$ERROR($$$GeneralError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	use io
	quit tSC
}

/// Disconnects from another InterSystems IRIS process via the DBSRV routine.
/// Sends one disconnect message (DC).
Method Disconnect() As %Status [ Internal ]
{
	quit:'..IsConnected $$$ERROR($$$GeneralError,"Already disconnected")

	set io = $IO
	set tSC = $$$OK
	try {
		use ..Device
		
		// client --> server
		set x = $zobjexport(..NextMessageId(),1) // write msgid
		set x = $zobjexport(0,2) // write stmtid=0
		set x = $zobjexport("DC",8) // write header, opcode DC=disconnect
		
		close ..Device
		close ..TCPDevice
		
		set ..IsConnected = 0
	} catch exception {
		set tSC = $$$ERROR($$$GeneralError,exception.Name_exception.Location_$Select(exception.Data'="":" *"_exception.Data,1:""))
	}
	use:(io'=..TCPDevice)&&(io'=..Device) io
	quit tSC
}

Method %OnClose() As %Status [ Internal ]
{
	try {
		do ..Disconnect()
	} catch ex {}
	quit $$$OK
}

}
