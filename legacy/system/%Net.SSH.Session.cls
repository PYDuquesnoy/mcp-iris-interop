/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSSH

/// Represents an SSH session object.  Each SSH session object must first be connected, then authenticated
/// with the remote system.  Note that there are multiple methods of authentication, this class supports
/// password and publickey.  Once connected and authenticated, the SSH object can be used to perform
/// SCP (Secure Copy) operations of single files to and from the remote system, it can also be used
/// to execute remote commands, tunnel TCP traffic and forms the base connection for SFTP operations (see
/// %Net.SSH.SFTP).
/// <br/>
/// The Test() method of this class illustrates some basic usage scenarios for this class.
/// <br/>
/// <b>NOTE:</b> %Net.SSH is currently not supported on OpenVMS platforms.
Class %Net.SSH.Session Extends %RegisteredObject [ System = 3 ]
{

/// Default SSH port
Parameter SSHPORT As INTEGER [ Final ] = 22;

/// Enables tracing of SSH transactions
Parameter SSHTRACETRANS As INTEGER [ Final ] = 2;

/// Enables tracing of SSH key exchange
Parameter SSHTRACEKEX As INTEGER [ Final ] = 4;

/// Enables tracing of SSH authentication
Parameter SSHTRACEAUTH As INTEGER [ Final ] = 8;

/// Enables tracing of SSH connections
Parameter SSHTRACECONN As INTEGER [ Final ] = 16;

/// Enables tracing of SSH/SCP operations
Parameter SSHTRACESCP As INTEGER [ Final ] = 32;

/// Enables tracing of SSH/SFTP operations
Parameter SSHTRACESFTP As INTEGER [ Final ] = 64;

/// Enables tracing of SSH error operations
Parameter SSHTRACEERROR As INTEGER [ Final ] = 128;

/// Enables tracing of SSH public key operations
Parameter SSHTRACEPUBLICKEY As INTEGER [ Final ] = 256;

/// Enables tracing of low level socket operations
Parameter SSHTRACESOCKET As INTEGER [ Final ] = 512;

/// Host Key Type: MD5
Parameter SSHHOSTKEYMD5 As STRING [ Final ] = "MD5";

/// Host Key Type: SHA1
Parameter SSHHOSTKEYSHA1 As STRING [ Final ] = "SHA1";

/// Host Key Type: SHA256
Parameter SSHHOSTKEYSHA256 As STRING [ Final ] = "SHA256";

/// Remote host key.  The hash type is determined from the
/// number of bits (from the number of hex chars) in the hash:
/// <li>MD5: 128 bits / 32 hex chars</li>
/// <li>SHA1: 160 bits / 40 hex chars</li>
/// <li>SHA256: 256 bits / 64 hex chars</li>
/// 
Property HostKey As %String;

/// Character set used by the remote server.  Will almost certainly be
/// UTF-8 for any SSH server.
Property RemoteCharset As %String [ InitialExpression = "UTF8" ];

/// Character set used by the local system.  Defaults to the system call
/// translation table (which is likely UTF8 on UNIX).
/// 
Property LocalCharset As %String [ InitialExpression = {$$GetPDefIO^%SYS.NLS(8)} ];

/// SSH Session handle
Property Session As %String [ Internal, Private ];

Method %OnNew() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	#dim result As %List

	// CacheSSH is not currently supported on VMS
	If $$$isVMS Quit $$$ERROR($$$FeatureNotSupported,"CacheSSH/VMS")

	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHCREATESESSION)
	Quit:+$LG(result) $$$SSHERROR(result,"CreateSession")
	
	Set ..Session = $LI(result,2)
	
	Quit $$$OK
}

/// Called before connecting to a remote host to specify various preferred algorithms and methods that
/// should be used.  Format of the preferences string is as follows:
/// <blockquote>
/// &lt;category&gt;=&lt;option&gt;[:&lt;category1&gt;=&lt;option1&gt;[:...]]
/// </blockquote>
/// Where &lt;category&gt; is one of:
/// <li><b>KEX</b> Key Exchange Methods</li>
/// <li><b>HOSTKEY</b> Hostkey public key algorithms</li>
/// <li><b>CRYPT</b> Encryption algorithms</li>
/// <li><b>MAC</b> MAC algorithms</li>
/// <li><b>COMP</b>Compression Algorithms</li>
/// <b>NOTE:</b> The allowed values can be found here:<br/>
///       http://libssh2.sourceforge.net/doc/#libssh2sessionmethodpref
/// And &lt;option&gt; is a comma delimited list of one or more values.
/// 
Method SetPreferredAlgorithms(preferences As %String) As %Status
{
	#dim result As %List
	
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSETPREFERREDALGORITHMS,$LB(..Session,preferences))
	Quit:+$LG(result) $$$SSHERROR(result,"SetPreferredAlgorithms")
	
	Quit $$$OK
}

/// Called to retrieve the current set of negotiated algorithms/methods for various categories.
/// Format of the result string is as follows:
/// <blockquote>
/// &lt;category&gt;=&lt;option&gt;[:&lt;category1&gt;=&lt;option1&gt;[:...]]
/// </blockquote>
/// Where &lt;category&gt; is one of:
/// <li><b>KEX</b> Key Exchange Methods</li>
/// <li><b>HOSTKEY</b> Hostkey public key algorithms</li>
/// <li><b>CRYPT</b> Encryption algorithms</li>
/// <li><b>MAC</b> MAC algorithms</li>
/// <li><b>COMP</b>Compression Algorithms</li>
/// <b>NOTE:</b> The allowed values can be found here:<br/>
///       http://libssh2.sourceforge.net/doc/#libssh2sessionmethodpref
/// And &lt;option&gt; is a comma delimited list of one or more values.
/// 
Method GetAlgorithms(ByRef preferences As %String) As %Status
{
	#dim result As %List
	
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHGETALGORITHMS,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"GetAlgorithms")
	
	Set preferences = $LI(result,2)
	
	Quit $$$OK
}

/// Called to retrieve the set of supported algorithms for various categories.
/// Format of the string is as follows:
/// <blockquote>
/// &lt;category&gt;=&lt;option&gt;[:&lt;category1&gt;=&lt;option1&gt;[:...]]
/// </blockquote>
/// Where &lt;category&gt; is one of:
/// <li><b>KEX</b> Key Exchange Methods</li>
/// <li><b>HOSTKEY</b> Hostkey public key algorithms</li>
/// <li><b>CRYPT</b> Encryption algorithms</li>
/// <li><b>MAC</b> MAC algorithms</li>
/// <li><b>COMP</b> Compression Algorithms</li>
/// <b>NOTE:</b> The allowed values can be found here:<br/>
///       http://libssh2.sourceforge.net/doc/#libssh2sessionmethodpref
/// 
Method GetSupportedAlgorithms(ByRef algs As %String) As %Status
{
	#dim result As %List
	
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHGETSUPPORTEDALGORITHMS,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"GetSupportedAlgorithms")
	
	Set algs = $LI(result,2)
	
	Quit $$$OK
}

/// Connect to a remote host, specifying the hostname, and optionally the port and remote hostkey to match.
/// The hostkey helps prevent impersonation attacks, it is a hash of the remote hosts' public key as a
/// string of ASCII hex digits representing the bytes of the hash.  The type of hash is determined from the
/// number of bits (from the number of hex chars) in the hash:
/// <li>MD5: 128 bits / 32 hex chars</li>
/// <li>SHA1: 160 bits / 40 hex chars</li>
/// <li>SHA256: 256 bits / 64 hex chars</li>
/// The returned host key can be specified by passing one of "MD5", "SHA1" or "SHA256" (see ..#SSHHOSTKEYxyz values),
/// the default is "MD5".  If the host key isn't available, it will be "" (e.g. MD5 in FIPS mode).
/// 
Method Connect(hostname As %String, port As %Integer = {..#SSHPORT}, hostkey As %String = "", hostkeytype As %String = "") As %Status
{
	#dim result As %List
	
	If ..Session="" {
		Set result = $ZF(-6,$$$SSHLibrary,$$$SSHCREATESESSION)
		Quit:+$LG(result) $$$SSHERROR(result,"CreateSession")
		
		Set ..Session = $LI(result,2)
	}
	
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHCONNECT,$LB(..Session,hostname,port,hostkey,hostkeytype))
	Quit:+$LG(result) $$$SSHERROR(result,"Connect")
	
	Set ..HostKey = $LI(result,2)
	
	Quit $$$OK
}

/// Clean up any resources
Method %OnClose() As %Status
{
	#dim result As %List
	Quit:..Session="" $$$OK
	
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHDELETESESSION,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"DeleteSession")
	
	Set ..Session = ""
	Set ..HostKey = ""
	
	Quit $$$OK
}

/// Disconnect from the remote host
Method Disconnect() As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHDISCONNECT,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"Disconnect")
	
	Set ..HostKey = ""
	
	Quit $$$OK
}

/// Authenticate with the remote server using a username/password via the "password" authentication
/// scheme.  Note that this is NOT the same as keyboard-interactive which is typically what login
/// sessions use.
/// <br/>
/// See notes in <method>AuthenticateWithKeyPair()</method> when using multiple forms of authentication.
/// <br/>
/// 
Method AuthenticateWithUsername(username As %String, password As %String) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHAUTHENTICATEWITHUSERNAME,$LB(..Session,username,password))
	Quit:+$LG(result) $$$SSHERROR(result,"AuthenticateWithUsername")

	Quit $$$OK
}

/// Authenticate with the remote server using a public/private key pair and passphrase (for the private key).
/// The private keys are PEM encoded and the public keys are in OpenSSH format.<br/>
/// If multiple forms of authentication are required by the server, for example <tt>/etc/ssh/sshd_config</tt>
/// contains:<br/>
/// <pre>
/// AuthenticationMethods publickey,password
/// </pre>
/// Then in this case read the "," (comma) as AND; the server will require <i>both</i> forms of authentication.</br>
/// <br/>
/// Calling AuthenticateWithKeyPair fails with <tt>LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED</tt> which is a bit
/// misleading ... it's really "authenticated with partial success" so we can then try authenticating with
/// a password which should then succeed (or <tt>keyboard-interactive</tt>).<br/>
/// 
Method AuthenticateWithKeyPair(username As %String, publickeyfile As %String, privatekeyfile As %String, passphrase As %String) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHAUTHENTICATEWITHKEYPAIR,$LB(..Session,username,publickeyfile,privatekeyfile,passphrase))
	Quit:+$LG(result) $$$SSHERROR(result,"AuthenticateWithKeyPair")

	Quit $$$OK
}

/// Authenticate with the remote server using the "keyboard-interactive" authentication scheme.  This requires
/// a callback lambda/function that will be called with a list of one or challenges to which the lambda will return
/// the responses to the challenge(s).  The lambda is invoked with the following arguments:
/// <li><tt>username As %String</tt> Username being authenticated</li>
/// <li><tt>instructions As %String</tt> Instructions from the server (optional)</li>
/// <li><tt>prompts As %List</tt> A $LIST of challenge prompt(s)</li>
/// <li><tt>promptflags As %List</tt> A $LIST of flags for each of the challenge prompt(s)</li>
/// <li><tt>ByRef context</tt> A pass-by-ref context value</li>
/// The lambda must return a $LIST of responses, with each Nth element in the $LIST corresponding to the Nth
/// challenge prompt.  If there is no response for a prompt, then that Nth $LIST element should be empty.
/// The allowed values for <tt>promptflags</tt> are as follows:<br/>
/// <li><tt>E</tt> Echo on.  If E is missing DO NOT ECHO! (e.g. password entry)</li>
/// <b>NOTE:</b> The <tt>context</tt> can be anything of your choosing (an array, object or whatever) and it is passed
/// by reference.
/// <br/>
/// See notes in <method>AuthenticateWithKeyPair()</method> when using multiple forms of authentication.
/// <br/>
/// 
Method AuthenticateWithKeyboardInteractive(username As %String, lambda As %String, ByRef context) As %Status [ PublicList = (lambda, context) ]
{
	#dim result As %List
	Set $ZE=""  // Clear $ZE when we invoke callbacks so CACHEERROR() is reset
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHAUTHENTICATEWITHKBDINT,$LB(..Session,username,$THIS,"kbdintcallback"))
	Quit:+$LG(result) $$$SSHERROR(result,"AuthenticateWithKeyboardInteractive")

	Quit $$$OK
}

/// Internal helper method to act as a callback for keyboard-interactive authentication.
Method kbdintcallback(username As %String, instructions As %String, prompts As %List, promptflags As %List) As %List [ CodeMode = expression, Internal, PublicList = (lambda, context) ]
{
$XECUTE(lambda,username,instructions,prompts,promptflags,.context)
}

/// Open up an SFTP session for SFTP activity.
Method OpenSFTP(ByRef sftp As %Net.SSH.SFTP) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHOPENSFTP,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"OpenSFTP")
	
	// Construct an SFTP wrapper
	Set sftp = ##class(%Net.SSH.SFTP).%New($this,$LI(result,2,3))

	Quit $$$OK
}

/// Execute a remote command on the remote system.  In order to do I/O with the remote
/// command, an XDEV device instance is passed back via the pDevice parameter.  This is
/// a normal device and can be used with the USE/READ/WRITE/CLOSE commands.
/// Note that environment variables for the remote command can be passed as an array
/// of name/value pairs.
Method Execute(pCommand As %String, ByRef pDevice As %String, ByRef pEnv) As %Status
{
	#dim result As %List
	#dim environ As %List

	// Check for at least 2 args, otherwise the device name could be lost
	// (NOTE: there's currently no way to check for a ByRef argument ...)
	Quit:$ZU(141)<2 $$$ERROR($$$RequiredArgumentMissing)
	
	Set environ="",i=""
	For {
		Set i=$O(pEnv(i))
		Quit:i=""
		
		Set environ=environ_$LB($LB(i,pEnv(i)))
	}
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHEXECUTE,$LB(..Session,pCommand,environ))
	Quit:+$LG(result) $$$SSHERROR(result,"Execute")
	
	Quit ..openXDEV($LI(result,2),$LI(result,3),"SSHEXECUTE",.pDevice,..RemoteCharset)
}

/// Demonstrates the execution of a remote command (by default, uname -a).
ClassMethod TestExecute(host As %String, username As %String, password As %String, command As %String = "uname -a", pTimeout As %Integer = -1) As %Status
{
	Set s = ##class(%Net.SSH.Session).%New()
	Set sc = s.Connect(host)
	Quit:$$$ISERR(sc) sc
	If pTimeout'=-1 {
		Set sc = s.SetTimeout(pTimeout)
		Quit:$$$ISERR(sc) sc
	}
	Set sc = s.AuthenticateWithUsername(username,password)
	Quit:$$$ISERR(sc) sc
	Set sc = s.Execute(command,.tDevice)
	Quit:$$$ISERR(sc) sc
	
	Set $ZT="Trap"
	For {
		Use tDevice
		Read X
		Use $P
		If X'[$C(13) {
			For i=1:1:$L(X,$C(10)) Write $P(X,$C(10),i),!
		} Else {
			Write X
		}
	}
Exit
	Use $P
	Close tDevice
	Quit sc
Trap
	Set sc = $S($ZE["<ENDOFFILE>":$$$OK,1:$$$ERROR($$$ObjectScriptError,$ZE))
	Goto Exit
}

/// Forwards traffic via the SSH connection to a remote host/port.  The traffic is sent via an XDEV device
/// that is opened by ForwardPort() and passed back by reference via the pDevice parameter.
Method ForwardPort(pRemoteHost As %String, pRemotePort As %Integer, ByRef pDevice As %String) As %Status
{
	#dim result As %List

	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHFORWARDPORT,$LB(..Session,pRemoteHost,+pRemotePort))
	Quit:+$LG(result) $$$SSHERROR(result,"ForwardPort")
	
	Quit ..openXDEV($LI(result,2),$LI(result,3),"SSHFORWARDPORT",.pDevice,"RAW") // RAW data
}

/// Retrieves the client and server SSH versions.  If the server version is not available,
/// or if the session is not connected, then pServerVersion will be undefined.  Note that the
/// client version refers to the release of libssh2 being used.
Method VersionInfo(ByRef pClientVersion As %String, ByRef pServerVersion As %String) As %Status
{
	#dim result As %List

	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHVERSIONINFO,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"VersionInfo")
	
	Set pClientVersion = $LG(result,2)
	If $LD(result,3) {
		// Server version available, grab it
		Set pServerVersion = $LG(result,3)
	} Else {
		// No server version available (or not connected)
		Kill pServerVersion
	}
	
	Quit $$$OK
}

/// Sets the timeout for SSH operations in milliseconds.  An infinite timeout can be set by passing -1 to this 
/// methods; the default timeout is set to 30 seconds.
Method SetTimeout(pTimeoutMS As %Integer = -1) As %Status
{
	#dim result As %List
    
	If '$$$SSHVALIDINT(pTimeoutMS) || (pTimeoutMS'>-2) {
		Quit $$$ERROR($$$InvalidArgument)
	}
    
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSETTIMEOUT,$LB(..Session,pTimeoutMS\1))
	Quit:+$LG(result) $$$SSHERROR(result,"SetTimeout")
	
	Quit $$$OK
}

/// Gets the timeout for SSH operations in milliseconds.  An infinite timeout is represented by the value of -1;
/// the default timeout is set to 30 seconds.
Method GetTimeout(ByRef pTimeoutMS As %Integer = -1) As %Status
{
	#dim result As %List

	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHGETTIMEOUT,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"GetTimeout")

	// Grab the current timeout value
	Set pTimeoutMS = $LG(result,2)
	
	Quit $$$OK
}

/// Demonstrates the use of port forwarding to whatismyipaddress.com via the remote SSH server.
ClassMethod TestForwardPort(host As %String, username As %String, password As %String, remotehost As %String = "whatismyipaddress.com", remoteport As %Integer = 80) As %Status
{
	Set s = ##class(%Net.SSH.Session).%New()
	Set sc = s.Connect(host)
	Quit:$$$ISERR(sc) sc
	Set sc = s.AuthenticateWithUsername(username,password)
	Quit:$$$ISERR(sc) sc
	Set sc = s.ForwardPort(remotehost,remoteport,.tDevice)
	Quit:$$$ISERR(sc) sc
	
	Set $ZT="Trap"
	
	Use tDevice
	Write "GET / HTTP/1.0"_$C(13,10,13,10)
	Write *-3 // Flush
	
	// Now the response
	For {
		Use tDevice
		Read X
		Use $P
		If X'[$C(13) {
			For i=1:1:$L(X,$C(10)) Write $P(X,$C(10),i),!
		} Else {
			Write X
		}
	}
Exit
	Use $P
	Close tDevice
	Quit sc
Trap
	Set sc = $S($ZE["<ENDOFFILE>":$$$OK,1:$$$ERROR($$$ObjectScriptError,$ZE))
	Goto Exit
}

/// Sets the trace mask and log file for SSH tracing/logging.  The trace mask is a bitmap consisting
/// of flags specified above in the SSHTRACE* parameters.
Method SetTraceMask(pTraceMask As %Integer, pTraceFile As %String = "") As %Status [ Internal ]
{
	#dim result As %List

	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHTRACEMASK,$LB(..Session,+pTraceMask,pTraceFile))
	Quit $S(+$LG(result):$$$SSHERROR(result,"TraceMask"),1:$$$OK)
}

/// Sets up an XDEV device for use with port forwarding or remote command execution.
ClassMethod openXDEV(pXDEV As %String, pOwner As %String, pType As %String, ByRef pDevice As %String, pCharset As %String = "UTF8") As %Status [ Internal, Private ]
{
	Set $ZT="Trap"
	Set pDevice = "|XDEV|"_($ZCRC(pOwner,7)\2)
	Set tTimeout = 0
	Open pDevice:(pXDEV:"":"S":/HOSTNAME=pType:/IOT=pCharset:/IBU=16384:/OBU=16384):tTimeout
	Quit $S($TEST:$$$OK,1:$$$ERROR($$$ErrIOOpenTimeout,pDevice,tTimeout))
Trap
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Maps COM_HRESULT error codes to the equivalent status codes.
ClassMethod ssherror(pHResult As %Integer, pText As %String, pOrigin As %String = "") As %Status [ Internal ]
{
	#define COMHR(%h) ##expression($zhex("%h"))

	#dim tFacility As %Integer = (pHResult\(2**16))#(2**15)
	#dim tGroup As %Integer    = (pHResult\(2**12))#16
	#dim tCode As %Integer     = (pHResult)#(2**12)
	#dim tStatus As %Status

	Set tStatus = $CASE(pHResult,
							// First, some specific errors we want to map

							$$$COMHR(80100003):$$$ERROR($$$SSHInvalidHostname),	// POSIX: COM_E_SSH_INVALIDHOSTNAME
							$$$COMHR(80072AF9):$$$ERROR($$$SSHInvalidHostname),	// WIN32: WSAHOST_NOT_FOUND

							// Otherwise, by facility/group
							:$CASE(tFacility,
								// Map COM_FACILITY_SSH errors
								16:$CASE(tGroup,
										// GROUP_CACHESSH
										0:$S((tCode>0)&&(tCode<10):$$Error^%apiOBJ($$$ERRORCODE($$$SSHGeneralError)+tCode),
										     (tCode>9)&&(tCode<12):$$Error^%apiOBJ($$$ERRORCODE($$$SSHSFTPError)+(tCode-9)),
											1:""),

										// GROUP_SSH (libssh2 SSH errors)
										1:$$$ERROR($$$SSHSSHError,-tCode,pText),

										// GROUP_SFTP (libssh2 SFTP errors)
										2:$$$ERROR($$$SSHSFTPError,tCode,pText),

										:""),
								:""))

	// If we didn't map it, return a general SSH error
	Quit $SELECT(tStatus="":$$$ERROR($$$SSHGeneralError,pHResult,pText),1:tStatus)
}

}
