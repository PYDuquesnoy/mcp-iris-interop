/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.Telnet.OutboundAdapter Extends Ens.OutboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Server to connect to
Property TelnetServer As %String(MAXLEN = 1500) [ Required ];

/// Server port to connect to
Property TelnetPort As %Integer [ InitialExpression = 23 ];

/// Prompt to wait for before submitting Username to the remote host
Property LoginPrompt As %String [ InitialExpression = "login:" ];

/// Prompt to wait for before submitting Password to the remote host
Property PasswordPrompt As %String [ InitialExpression = "Password:" ];

/// Text to wait for to verify successful login
Property LoginConfirmation As %String [ InitialExpression = "Last login: " ];

/// Text to wait for to detect failed login
Property LoginFailNotice As %String [ InitialExpression = "Login incorrect" ];

/// If non-zero, stay connected to the remote system between handling Requests until idle for this number of seconds. A value of -1 means never disconnect.
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// Number of seconds to wait on each connection attempt
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// Number of seconds to wait for a complete response. Setting the timeout to -1 means wait forever.
Property ResponseTimeout As %Numeric(MINVAL = -1) [ InitialExpression = 5 ];

/// Number of seconds of idle time to tolerate while waiting for a complete response
Property ResponseIdleTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// The name of an existing SSL/TLS system configuration set to use (Secure Socket Layer / Transport Layer Security, configured via the system portal's Security Management page).
/// <p>If your SSL Configuration requires you to supply a password for the local private key file, specify it in 
/// the Private key password property of the SSL/TLS Configuration.
Property SSLConfig As %String;

/// These properties can be configured or set by the associated Business Operation
Parameter SETTINGS = "TelnetServer:Basic,TelnetPort:Basic,Credentials:Basic:credentialsSelector,SSLConfig:Connection:sslConfigSelector,LoginPrompt,PasswordPrompt,LoginConfirmation,LoginFailNotice,StayConnected,ConnectTimeout,ResponseTimeout,ResponseIdleTimeout";

/// Optional macro to evaluate to log in after detecting the Login (Username) Prompt string
/// The following variables are defined in the context of the macro: %Username=..%CredentialsObj.Username, %Password=..%CredentialsObj.Password, %Adapter=Adapter object. Text enclosed in &Raw() will be sent out without escaping or translation
Property LoginMacro As %String;

/// Optional macro to evaluate to log in after detecting the Password Prompt string
/// The following variables are defined in the context of the macro: %Username=..%CredentialsObj.Username, %Password=..%CredentialsObj.Password, %Adapter=Adapter object. Text enclosed in &Raw() will be sent out without escaping or translation
Property LoginPasswordMacro As %String;

/// Telnet Session object
Property Telnet As %Net.TelnetStream;

/// Holds a record of the signon screen received from the remote host after sending username & password.
Property SignonScreen As %String;

Method OnInit() As %Status
{
	If '$IsObject(..Telnet) Set ..Telnet=##class(%Net.TelnetStream).%New()  $$$ASSERT($IsObject(..Telnet))
	Set ..Telnet.StreamIn.DisconnectHandler=$this
	Set tSC=##super() Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0 ..KeepaliveInterval=..StayConnected
	If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	$$$EnsCheckSSLConfig(..SSLConfig)
	Quit $$$OK
}

/// Send the given pRequestString, and return in pResponseString any data received back up until pTimeout seconds have elapsed, or until pIdleTimeout seconds elapse with no further data received, or up until any of the optional pTarget strings is encountered.<p>
/// If pTarget strings are provided the pWhich output argument will contain an integer indicating which of them was matched. A value of 0 in pWhich indicates that none was matched and therefore the timeout expired or an error occurred.<p>
/// Setting pInsensitive=1 means the pTarget strings will match data received in a case-insensitive way.<p>
/// To make this method return without waiting for any reply data, call it with pTimeout=0.
Method SendMessageString(pRequestString As %String, Output pResponseString As %String, ByRef pTimeout As %Numeric = {..ResponseTimeout}, pIdleTimeout As %Numeric = {..ResponseIdleTimeout}, pInsensitive As %Boolean, Output pWhich As %Integer, pTarget...) As %Status
{
	Set tTimeout=pTimeout, (pTimeout,pWhich)=0, pResponseString=""
	Set tSC=..Connect(..ConnectTimeout)

	#; Write output string if any
	Do ..Telnet.WriteLine(pRequestString,1,.tSC)
	If '..Telnet.IsOpen||($$$ISERR(tSC)&&..Telnet.StreamIn.isWriteError(tSC)) {
		Set ..BusinessHost.Retry=1
		Quit $$$ERROR($$$EnsErrOutConnectionLost,"Telnet Write", ..Telnet.StreamIn.Name, $$$StatusDisplayString(tSC))
	}
	ElseIf $$$ISERR(tSC) {
		If '..StayConnected { Do ..Disconnect() }
		Quit tSC
	}
	If tTimeout {
		#; Read return data until timeout or pTarget string match
		Set pTimeout=tTimeout
		Set pResponseString = ..Telnet.ReadUntilArray(,.pTimeout,pIdleTimeout,,.pInsensitive,.pWhich,.tSC,.pTarget)
		If 'pWhich {
			If '..Telnet.IsOpen||($$$ISERR(tSC)&&..Telnet.StreamIn.isReadError(tSC)) {
				Do ..Disconnect()  Set ..BusinessHost.Retry=1
				Quit $$$ERROR($$$EnsErrOutConnectionLost,"Telnet Read", ..Telnet.StreamIn.Name, $$$StatusDisplayString(tSC))
			}
			If $G(pTarget) {
				If $$$ISOK(tSC)&&(pTimeout=tTimeout) {
					Set tSC=$$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired,tTimeout_"/"_pIdleTimeout,"Target1='"_$G(pTarget(1))_"'",pResponseString)
				}
				Set tSC=$$$ERROR($$$EnsErrTelnetFindFailed,"response string",$G(pTarget(1)),$$$StatusDisplayString(tSC)_" / "_pResponseString)
			} ; else we may have timed out but that's what we expected...
		}
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	Quit tSC
}

/// Prepare for Telnet transfer by logging in, setting the directory and transfer mode
Method Connect(pTimeout As %Numeric) As %Status
{
	Quit:..Telnet.IsOpen $$$OK
	Set $ZT="Trap",tSC=$$$OK

	#; Connect to the Telnet server
	$$$sysTRACE("Connecting to "_..TelnetServer_":"_..TelnetPort_" with timeout="_pTimeout_" and SSLConfig="_..SSLConfig)
	
	If '$IsObject(..Telnet.StreamIn)||'..Telnet.StreamIn.%Extends("%IO.Socket") {
		Quit $$$ERROR($$$ErrIONoDelegatedStream)
	}
	Set ..Telnet.StreamIn.Host=..TelnetServer
	Set ..Telnet.StreamIn.Port=..TelnetPort
	Set ..Telnet.StreamIn.SSLConfig=..SSLConfig

	If '..Telnet.Open(,,pTimeout,.tSC) {
		If $$$StatusEquals(tSC,$$$ErrIOOpenTimeout) Set ..BusinessHost.Retry=1
		#; Give an informative error message but don't show the password
		Quit $$$ERROR($$$EnsErrTelnetConnectFailed,..TelnetServer_":"_..TelnetPort_" /SSLConfig='"_..SSLConfig_"'",$$$StatusDisplayString(tSC)) 
	} $$$ASSERT($$$ISOK(tSC))
	Set $ZT="OnConnectTrap"
	Set tSC=..BusinessHost.OnConnect(pTimeout) Quit:$$$ISERR(tSC) tSC
Login
	Set $ZT="Trap"
	If (""=..LoginPrompt)&&(""=..PasswordPrompt) {
		$$$sysTRACE("Connected but not logging in to Telnet Server "_..TelnetServer_" because user and password prompts to match were not provided")
		Quit tSC
	}
	#; try to log in
	Do {
		If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials) If '$IsObject(..%CredentialsObj) { Set tSC=$$$ERROR($$$EnsErrNoCredentials,..Credentials) Quit }
		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"1|"_$$$timeUTC_"|"_..TelnetServer_":"_..TelnetPort)
		If ""'= ..LoginPrompt {
			Set tTimeout = pTimeout
			$$$sysTRACE("Beginning wait ("_tTimeout_") for login prompt '"_..LoginPrompt_"'")
			Set tText=..Telnet.ReadUntil(,.tTimeout,,,1,.tOK,.tSC,..LoginPrompt) If 'tOK {
				Set:tTimeout=pTimeout ..BusinessHost.Retry=1
				Set tSC=$$$ERROR($$$EnsErrTelnetFindFailed,"Login Prompt",..LoginPrompt,$$$StatusDisplayString(tSC)_" / '"_tText_"'")
				Quit
			} $$$ASSERT($$$ISOK(tSC))
			$$$sysTRACE("Got login prompt ; sending login (Username)")
			If ""=..LoginMacro { Do ..Telnet.WriteLine(..%CredentialsObj.Username,1,.tSC) }
			Else { Do ..writeLoginMacro(..LoginMacro,1,.tSC) }
		}
		If ""'= ..PasswordPrompt {
			Set tTimeout=pTimeout
			$$$sysTRACE("Beginning wait ("_tTimeout_") for password prompt '"_..PasswordPrompt_"'")
			Set tText=..Telnet.ReadUntil(,.tTimeout,,,1,.tOK,.tSC,..PasswordPrompt) If 'tOK {
				Set:tTimeout=pTimeout ..BusinessHost.Retry=1
				Set tSC=$$$ERROR($$$EnsErrTelnetFindFailed,"Password Prompt",..PasswordPrompt,$$$StatusDisplayString(tSC)_" / '"_tText_"'")
				Quit
			} $$$ASSERT($$$ISOK(tSC))
			$$$sysTRACE("Got password prompt ; sending Password")
			If ""=..LoginPasswordMacro { Do ..Telnet.WriteLine(..%CredentialsObj.Password,1,.tSC) }
			Else { Do ..writeLoginMacro(..LoginPasswordMacro,1,.tSC) }
			Quit:$$$ISERR(tSC)
		}
		#; Wait for success or failure
		Set tTimeout = pTimeout
		$$$sysTRACE("Beginning wait ("_tTimeout_") for login success/failure string")
		Set ..SignonScreen=..Telnet.ReadUntil(,.tTimeout,,,1,.tWhich,.tSC,..LoginConfirmation,..LoginFailNotice)  If 'tWhich {
			Set:tTimeout=pTimeout ..BusinessHost.Retry=1
			Set tSC=$$$ERROR($$$EnsErrTelnetFindFailed,"login success/failure",..LoginConfirmation_"'/'"_..LoginFailNotice,$$$StatusDisplayString(tSC)_" / '"_$ZCVT(..SignonScreen,"O","URL")_"'")
			Quit
		} $$$ASSERT($$$ISOK(tSC))
		If tWhich>1 { Set tSC=$$$ERROR($$$EnsErrTelnetLoginFailed,..TelnetServer,..LoginFailNotice) Quit }
		$$$ASSERT(tWhich=1)

		#; finish reading the signon message up to the first prompt...
		Set ..SignonScreen=..SignonScreen_..Telnet.Read(,0.1,.tSC)
		$$$sysTRACE("Got success string and remaining Signon Screen text: '"_..SignonScreen_"'")
		If $$$ISERR(tSC)&&..Telnet.StreamIn.isReadError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"Telnet Login", ..Telnet.StreamIn.Name, $$$StatusDisplayString(tSC))
		}
	} While 0
Exit
	If $$$ISERR(tSC) { Do ..Disconnect() }
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"1|"_$$$timeUTC_"|"_..TelnetServer_":"_..TelnetPort) }
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
OnConnectTrap
	Set $ZT="",tSC=$$$SystemError
	$$$sysTRACE("Couldn't call BusinessHost's (optional) OnConnect() method - "_$$$StatusDisplayString(tSC))
	Goto Login
}

Method writeLoginMacro(pMacro As %String, pFlush As %Boolean, Output pSC As %Status) As %String
{
	new %lstr,%Username,%Password,%Adapter
	Set %Username=..%CredentialsObj.Username
	Set %Password=..%CredentialsObj.Password
	Set %Adapter=$this
	Xecute "Set %lstr="_pMacro
	Set tLStr=%lstr
	Set pSC=$$$OK,i=1 While 1 {
		Set tPiece=$P(tLStr,"&Raw(",1), tLStr=$P(tLStr,"&Raw(",2)
		If ""'=tPiece If ""=tLStr { Do ..Telnet.Write(tPiece,.pFlush,.pSC) } Else { Do ..Telnet.Write(tPiece,0,.pSC) }  Quit:$$$ISERR(pSC)
		Quit:""=tLStr
		Set tPiece=$P(tLStr,")",1), tLStr=$P(tLStr,")",2)
		If ""'=tPiece If ""=tLStr { Do ..Telnet.WriteRaw(tPiece,.pFlush,.pSC) } Else { Do ..Telnet.WriteRaw(tPiece,0,.pSC) }  Quit:$$$ISERR(pSC)
		Quit:""=tLStr
	}
	Quit pSC
}

/// Notify of Disconnect from the datasource
Method OnDisconnect(pSocket As %IO.Socket, pIntentional As %Boolean, pSCReason As %Status)
{
	$$$sysTRACE("Disconnecting from "_..TelnetServer)
	#; !!Logout?
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,0_"|"_$$$timeUTC_"|"_..TelnetServer_":"_..TelnetPort)
	If 'pIntentional {
		Set tTxt=$$$StatusText($$$ERROR($$$EnsErrOutConnectionLost,"Telnet", ..TelnetServer_":"_..TelnetPort, $S($$$ISOK(pSCReason):"$zu(189)",1:$$$StatusDisplayString(pSCReason))))
		If ..StayConnected { $$$LOGWARNING(tTxt) } Else { $$$LOGINFO(tTxt) }
	}
}

/// Disconnect from the datasource
Method Disconnect() As %Status
{
	Quit:'..Telnet.IsOpen $$$OK
	Do ..Telnet.Close(.pSC)
	Quit pSC
}

Method OnTearDown() As %Status
{
	Do ..Disconnect()
	Quit $$$OK
}

ClassMethod fromHex(pLine)
{
	Set tFoundSep=0
	Set (tNum,tBuf,tPrefix)=""  For i=1:1:$L(pLine) { Set tByte=$TR($ZCVT($E(pLine,i),"L"),$C(9)_"|:"," --")
		If (" "=tByte)||("-"=tByte) { // byte is whitespace or separator
			If "-"=tByte { // found separator after digits
				If ":"=$E(pLine,i) && (""=tPrefix) { Set tPrefix=tBuf,tNum="" }
				Else { Set tFoundSep=1 }
			}
			If tNum'="" w !,"Unbalanced digits in Hex string: "_pLine_" at position "_i Quit
			If tFoundSep Quit
		} Else { 
			Set tDigit=$Case(tByte,0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,"a":10,"b":11,"c":12,"d":13,"e":14,"f":15,:"")
			If ""=tDigit {
				If ""'=tPrefix { Set tBuf=tPrefix, tPrefix="", tFoundSep=1 }
				//ElseIf tNum'="" { w !,"Unbalanced digits in Hex string: "_pLine_" at position "_i }
				Quit // found a non-digit
			}
			If tNum'="" { Set tBuf=tBuf_$C(((16*tNum)+tDigit)), tNum="" }
			Else { Set tNum=tDigit }
		}
	}
	If ""'=tPrefix || (tBuf=tPrefix) Set $E(tBuf,1,$L(tPrefix))=""
	Quit $S(tFoundSep||(i=$L(pLine)):tBuf, 1:"")
}

ClassMethod asHex(pStr) As %String
{
	Set tQStr="" for i=1:1:$L(pStr) {
		set tHex=$ZHex($A($E(pStr,i)))
		set tQStr=tQStr_$S($L(tHex)<2:"0",1:"")_tHex_" "
	}
	Quit tQStr
}

ClassMethod quote(pStr) As %String
{
	Set tQStr="",ch="-",a=0 for i=1:1:$L(pStr) set prev=a,ch=$E(pStr,i), a=$A(ch), tQStr=tQStr_$S(prev>200||(a<32)||((a>=126)&&(a<=159))||(a>200):$C(674)_a_$C(673),1:ch)
	Quit tQStr
}

Method OnKeepalive(pUnused As %Status) As %Status
{
	If ..Telnet.IsOpen && (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
		$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
		Do ..Disconnect()
	}
	Quit ##super($$$OK)
}

}
