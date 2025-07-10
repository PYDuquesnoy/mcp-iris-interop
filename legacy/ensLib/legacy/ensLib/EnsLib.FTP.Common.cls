/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Adapter that receives files via the FTP protocol.
Class EnsLib.FTP.Common Extends EnsLib.FTP.CommonSSH [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// The name of an existing SSL/TLS system configuration set to use for FTPS (Secure Socket Layer / Transport Layer Security, configured via the system portal's Security Management page). <br/>
/// This is for FTPS, meaning an encrypted connection to a normal FTP server. <br/>
/// If you append an asterisk (*) to the configuration name you enter, this adapter will use legacy FTPS mode.  FTPS is defined by RFC4217 but some servers operate with a non-compliant variant which simply assumes that the command channel should use TLS. Earlier versions of this adapter worked only with this sort of non-compliant server. Append an asterisk to the SSL configuration name if you need to (continue to) work with this sort of server.
/// <p>
/// For prior version compatibility a value of !SFTP is still supported to indicate the protocol is SFTP.
/// The recommendation is to use the Protocol setting to indicate SFTP. <br/>
Property SSLConfig As %String;

/// When making an FTP over SSL connection check the server identity in the certificate matches the name of the system we are connecting to.
/// This defaults to being OFF but it is recommended to enable. <br>
/// If enabled it matches based on the rules layed out in section 3.1 of RFC 2818.<br>
Property SSLCheckServerIdentity As %Boolean [ InitialExpression = 0 ];

/// When making the SSL connection for the data channel, reuse session parameters from the command channel.<br>
/// This feature requires OpenSSL v1.1.x+.<br>
Property SSLUseSessionResumption As %Boolean [ InitialExpression = 0 ];

/// Use Passive FTP mode: server returns a data port address and the client connects to it.
/// Most firewalls are more tolerant of Passive mode FTP because both the control and data TCP connections are initiated by the client.
Property UsePASV As %Boolean [ InitialExpression = 1 ];

/// Use this setting to indicate whether the protocol is FTP - File Transfer Protocol or SFTP - SSH File Transfer Protocol.<br>
/// If the protocol is FTP it is possible to use the setting SSL Configuration to configure FTP over SSL<br>
/// <p>
/// If the protocol is SFTP then: <br/>
/// - the UsePASV and ServerListStyle values will be ignored.<br/>
/// - the FTPPort value should ordinarily be set to 22.<br/>
/// - you must supply a Credentials value <br/>
/// - if you supply values for both SFTPPublicKeyFile and SFTPPrivateKeyFile the adapter will attempt key pair authentication. It will do this in conjunction with the username and password supplied via the Credentials setting, using the password in the Credentials as the passphrase for the private key.<br/>
/// - if you don't supply both KeyFile values the adapter will attempt only username/password authentication based on the Credentials setting.
/// <p>
/// If this setting is blank then the protocol will be FTP - File Transfer Protocol subject to:<br>
/// <p>
/// In order to support prior version compatibility a setting value of !SFTP for SSL Configuration will result in using 
/// the SFTP - SSH File Transfer Protocol irrespective of this Protocol setting.<br>
Property Protocol As %String(VALUELIST = ",FTP,SFTP");

/// For FTP Protocol the translate table to use for the command channel, specifically for the filename/pathnames.
/// Normally this should not be specified in which case if the ftp server supports UTF8 then
/// we will use that for the filename/pathnames, if the server does not support UTF8 then we
/// will use RAW mode and just read the bytes as sent. <br><br>
/// It is possible for a server to provide the filename list in RAW and for it to support UTF8.
/// In this case it might be necessary to set the Command Translate Table to RAW to override the
/// the detected UTF8 <br><br>
/// The values shown in the list are the internal table names.
Property CommandTranslateTable As %String;

Parameter SETTINGS = "Protocol:Connection,SSLConfig:Connection:sslConfigSelector,SSLCheckServerIdentity:Connection,SSLUseSessionResumption:Connection,UsePASV:Connection,CommandTranslateTable:FTP:selector?context={Ens.ContextSearch/CharacterSets?internalTables=1}";

/// Result of SYST command to FTP Server
Property %Syst As %String [ Internal ];

/// Does SYST result say the FTP Server is a VMS machine?
Property %isVMS As %String [ Internal ];

Property %isSFTP As %Boolean [ Calculated, Internal, ReadOnly ];

/// String naming remote FTP server address:port, and various credentials if applicable
Property %IOAddr As %String [ Internal ];

Property %LastNetErr As %String [ InitialExpression = "%%%%%", Internal ];

Property FileListStream As %GlobalCharacterStream [ Internal ];

Method %isSFTPGet() As %Boolean [ CodeMode = expression, Internal ]
{
(("!SFTP"=$ZCVT($ZStrip(..SSLConfig,"<>WC"),"U"))||(..Protocol="SFTP"))
}

Method FTPServerSet(server As %String) As %Status [ Internal ]
{
	Set tConnected = ..Connected
	Do:tConnected ..Disconnect()
	Set i%FTPServer=server
	If tConnected Do ..Connect(..ConnectTimeout) // avoid referencing ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method FTPPortSet(port As %String) As %Status [ Internal ]
{
	Set tConnected = ..Connected
	Do:tConnected ..Disconnect()
	Set i%FTPPort=port
	If tConnected Do ..Connect(..ConnectTimeout) // avoid referencing ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method CredentialsSet(pInVal As %String) As %Status [ Internal ]
{
	Set:..Connected&&$IsObject(..%CredentialsObj) tUsername=..%CredentialsObj.Username
	Set tSC=##class(Ens.Adapter)($this).CredentialsSet(pInVal) Quit:$$$ISERR(tSC) tSC
	
	#; If the username changes then disconnect
	If ..Connected {
		Set:$IsObject(..%CredentialsObj) tNewUsername=..%CredentialsObj.Username
		Quit:$G(tUsername)=$G(tNewUsername) $$$OK
		Do ..Disconnect()
		Do:..StayConnected ..Connect(..ConnectTimeout) // timeout is not fatal at this point, but do log it
	}
	Quit $$$OK
}

Method SSLConfigSet(sslcfg As %String) As %Status [ Internal ]
{
	#; force reconnect even if unchanged, just in case the referenced configuration settings changed
	Set sslcfg=$ZStrip(sslcfg,"<>WC")
	Set tBlank=(""=sslcfg||..%isSFTP)&&($ZCVT(i%SSLConfig,"U")=$ZCVT(sslcfg,"U"))
	Set tConnected = ..Connected
	Do:tConnected&&'tBlank ..Disconnect()
	Set i%SSLConfig=sslcfg
	If tConnected&&'tBlank Do ..Connect(..ConnectTimeout) // avoid referencing ..StayConnected to avoid trouble at startup time
	Quit $$$OK
}

Method ConnectedSet(pValue As %Boolean) As %Status [ Internal ]
{
	If i%Connected'=pValue {
		Set i%Connected=pValue
		$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,pValue_"|"_$$$timeUTC_"|"_..%IOAddr)
	}
	Quit $$$OK
}

/// Connect to the FTP server and log in, setting the directory and transfer mode
Method Connect(pTimeout As %Numeric = 30, pInbound As %Boolean = 0) As %Status
{
	Set $ZT="Trap", tSC=$$$OK, tFTPPort=..FTPPort
	Do {
		If ..Connected { Do ..TestConnection(pInbound) Quit:..Connected }

		#; Connect to the FTP server
		If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials) If '$IsObject(..%CredentialsObj) { Set tSC=$$$ERROR($$$EnsErrNoCredentials,..Credentials) Quit }
		Set ..%LastSetFilePath=""

		#; find FTP type; get a configuration-settings instance, use it to open an FTP Session instance
	 	If ..%isSFTP {
		 	#; Connect using an SFTP object
			Set:""=tFTPPort tFTPPort=22
			Set tIOAddr=..FTPServer_":"_tFTPPort_"/"_..Credentials_"/SSL='"_..SSLConfig_"'/PubKey='"_..SFTPPublicKeyFile_"'/PrivKey='"_..SFTPPrivateKeyFile_"'"
			$$$catTRACE("connwait","Connecting to "_tIOAddr_"/"_..Credentials_"'/PubKey='"_..SFTPPublicKeyFile_"'/PrivKey='"_..SFTPPrivateKeyFile_"' with timeout="_pTimeout)
		 	Set:'$IsObject(..FTP)||'..FTP.%Extends("EnsLib.FTP.CommonSSH") ..FTP=$this
		 	Set t0=$zh
		 	Set tSC=..FTP.ConnectSSH(pTimeout, pInbound, tFTPPort)
	 	} Else {
		 	#; Connect using standard FTP, or FTPS with SSLConfig
			Set:""=tFTPPort tFTPPort=21
			Set tIOAddr=..FTPServer_":"_tFTPPort_"/"_..Credentials_"/SSL='"_..SSLConfig
			$$$catTRACE("connwait","Connecting to "_tIOAddr_"/"_..Credentials_" with timeout="_pTimeout)
		 	Set:'$IsObject(..FTP)||'..FTP.%Extends("%Net.FtpSession") ..FTP=##class(%Net.FtpSession).%New()
			Set t0=$zh, ..FTP.Timeout=pTimeout, ..FTP.UsePASV=..UsePASV, ..FTP.LegacySSL=("*"=$E(..SSLConfig,*)), ..FTP.SSLConfiguration=$S("*"=$E(..SSLConfig,*):$E(..SSLConfig,1,*-1),1:..SSLConfig)
			If (..FTP.SSLConfiguration'="") {
				Set ..FTP.SSLCheckServerIdentity = ..SSLCheckServerIdentity
				Set ..FTP.SSLUseSessionResumption = ..SSLUseSessionResumption
			}
			If '..FTP.Connect(..FTPServer,..%CredentialsObj.Username,..%CredentialsObj.Password,tFTPPort) {
				Set tSC=$$$ERROR($$$EnsErrFTPConnectFailed,tIOAddr_"/"_..Credentials,..FTP.ReturnMessage,..FTP.ReturnCode)
			}
			#; Set after connect since FTP class will query server if empty string
			Set ..FTP.CommandTranslateTable = ..CommandTranslateTable
	 	}
		If $$$ISERR(tSC) {
			Set tSC=$S((-1'=pTimeout)&&(t0+pTimeout<=$zh): $$$ADDSC($$$ERROR($$$EnsErrOutConnectExpired,pTimeout,$S(..%isSFTP:"SFTP",1:"FTP"),tIOAddr),tSC)
													 , 1: $$$ERROR($$$EnsErrOutConnectFailed,$$$StatusDisplayString(tSC),$S(..%isSFTP:"SFTP",1:"FTP"),tIOAddr))
			Set ..FTP=$$$NULLOREF
			Quit
		}
		#; Get the system declaration from the FTP server
		Set ..%Syst=""  Set:..FTP.System(.tSystem) ..%Syst=tSystem
		If ""'=..%Syst {
			Set ..%isVMS = ("VMS " = $E(..%Syst,1,$L("VMS ")))
			$$$catTRACE("connwait","Detected FTP server system type '"_..%Syst_"'")
		}
		#; Set the current directory
		Set ..%LastSetFilePath=..fixSvrPath(..FilePath,0)
		If ""=..%LastSetFilePath {
			$$$catTRACE("connwait","Not setting FTP working directory because FilePath is empty")
		} Else {
			If ..FTP.SetDirectory(..%LastSetFilePath) {
				$$$catTRACE("connwait","Set FTP working directory to "_..%LastSetFilePath)
			} Else {
				Set tSC=$$$ERROR($$$EnsErrFTPDirectoryChangeFailed,..%LastSetFilePath,..FTP.ReturnMessage,..FTP.ReturnCode) 
				Set ..%LastSetFilePath=""
				Quit
			}
		}
		#; Set the transfer mode
		Set tTable = "RAW"
		Set csetlc=$ZCVT(..Charset,"L")
		Set tAscii=$Case($E(csetlc,1,5),"":1,"defau":1,"ascii":1,"latin":1,"iso-8":1,"utf-8":1,:0)
		If 'tAscii {
			If '..FTP.Binary() {
				Set tSC=$$$ERROR($$$EnsErrFTPModeChangeFailed,"Binary",..FTP.ReturnMessage,..FTP.ReturnCode)
				Set ..FTP.TranslateTable = ""
				Quit
			}
			If "binary"'=csetlc {
				Set tEnc=..Charset   Set:"*"=$E(tEnc) $E(tEnc)=""
				Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(tEnc)
				Set:tTable="" tTable="RAW"
			}
		} Else {
			If '..FTP.Ascii() {
				Set tSC=$$$ERROR($$$EnsErrFTPModeChangeFailed,"Ascii",..FTP.ReturnMessage,..FTP.ReturnCode)
				Quit
			}
			If "ascii"'=csetlc {
				If $Case(csetlc,"":0,"default":0,"native":0,:1) {
					Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
				} Else { Set tTable = "" }
				Set:tTable="" tTable=$$DefIO^%NLS(5)
			}
		}
		#; Success
		Set ..FTP.TranslateTable = tTable
		Set tTxt="Connected to FTP Server '"_tIOAddr_"' at path '"_..%LastSetFilePath_"' using Credentials '"_..Credentials_"'"
		If ..StayConnected<0 { $$$LOGINFO(tTxt) }
		Else {
			If pInbound&&'..StayConnected { $$$catTRACE("connwait",tTxt) }
			ElseIf ..%logTransfers { $$$LOGINFO(tTxt) }
			Else { $$$sysTRACE(tTxt) }
		}
		Set ..Connected=1
		$$$ASSERT(..FTP.Connected)
		If (..BusinessHost.%LastReportedError [ "ERROR <Ens>ErrOutConnect")
		 ||(..BusinessHost.%LastReportedError [ ..%LastNetErr) {
			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}
		Set ..%LastNetErr="%%%%%"
		Set i%%IOAddr=tIOAddr
	} While 0
Exit
	If $$$ISERR(tSC) {
		$$$ASSERT('..Connected)
		Do:..FTP.Connected ..FTP.Logout() ; force FTP class into sync in case it made a mistake
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Set tSC =$$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),$S(..%isSFTP:"SFTP",1:"FTP"),tIOAddr_"/"_..Credentials)
	Goto Exit
}

/// Disconnect from the datasource
Method Disconnect(pInbound As %Boolean = 0) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Quit:'..Connected
		Set tTxt="Disconnecting from "_..FTPServer
		If ..StayConnected<0 { $$$LOGINFO(tTxt) }
		Else {
			If pInbound&&'..StayConnected { $$$catTRACE("connwait",tTxt) }
			ElseIf ..%logTransfers { $$$LOGINFO(tTxt) }
			Else { $$$sysTRACE(tTxt) }
		}
		Set ..Connected=..FTP.Connected
		If '..Connected Set ..FTP=$$$NULLOREF  Quit
		Set:'..FTP.Logout() tSC=$$$ERROR($$$EnsErrFTPConnectFailed,"Logout from"_..%IOAddr,..FTP.ReturnMessage,..FTP.ReturnCode)
		If $$$ISERR(tSC) $$$sysTRACE($$$StatusText(tSC)) ; log it here because nobody will return the error to the calling BP or BS
		$$$ASSERT('..FTP.Connected)
		Set ..Connected=0, ..FTP=$$$NULLOREF
	} While 0
Exit
	Set ..%IOAddr=""
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method TestConnection(pInbound)
{
	If ..%isSFTP Do ..TestConnectionSSH(pInbound)  Quit

	If '..Connected Do:..FTP.Connected ..FTP.Logout()  Quit ; force FTP class into sync in case it made a mistake

	$$$catTRACE("connwait","Testing Connection to "_..%IOAddr)
	Set ..Connected=..FTP.Connected
	Quit:..Connected

	Set tTxt=$$$StatusText($$$ERROR($$$EnsErrOutConnectionLost,"FTP", ..%IOAddr, "..FTP.Connected"))
	If ..StayConnected<0 { $$$LOGWARNING(tTxt) } Else { If ..%logTransfers { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } }
	Do ..Disconnect()
	Quit
}

Method OnTearDown() As %Status [ Internal ]
{
	Do ..Disconnect()
	Set ..FTP=$$$NULLOREF
	Quit $$$OK
}

Method fixSvrPath(pPath As %String, pAppendSlash As %Boolean = 1) As %String [ CodeMode = expression, Internal ]
{
$S(pPath="":""
	,..%isVMS:$S($E(pPath,*)="]"||'pAppendSlash:pPath, pPath[":":pPath_"[000000]", 1:"[."_pPath_"]")
	,'pAppendSlash&&("/"=$TR($E(pPath,*),"\","/"))&&($L(pPath)>1):$TR($E(pPath,1,*-1),"\","/")
	,1:$TR(pPath,"\","/")_$S(pAppendSlash&&($TR($E(pPath,*),"\","/")'="/"):"/", 1:""))
}

/// Return pieces of input string separated by arbitrary numbers of an arbitrary set of separator characters.
ClassMethod spacepiece(str As %String, p1 As %Integer = 1, p2 As %Integer = "", sepchars As %String = {" "_$C(9)}, Output numpieces) As %String [ Internal ]
{
	Set:""=p2 p2=p1
	If ""=sepchars Set numpieces=1 Quit str
	Set numpieces=0,out=""
	Set sep=$E(sepchars), seplen=$L(sepchars)
	For i=1:1:$L(str,sep) {  Set piece=$P(str,sep,i) Continue:""=piece
		Set:p1<1 p1=1  Quit:p2<p1
		Set piece=..spacepiece(piece,p1,p2,$E(sepchars,2,seplen),.num), numpieces=numpieces+num
		Set:numpieces>=p1 out=out_$S((""'=out)&&(""'=piece):sep,1:"")_piece
		Set p1=p1-num, p2=p2-num
	}
	Quit out
}

Method OnKeepalive() As %Status
{
	If ..Connected && (..StayConnected>0) && ($ZH-..BusinessHost.%LastHandledTime>=..StayConnected) {
		$$$sysTRACE("Disconnecting on expiration of idle interval StayConnected="_..StayConnected)
		Do ..Disconnect()
	}
	//Quit ##super($$$OK)
	Quit ##class(Ens.Adapter)$this.OnKeepalive($$$OK)
}

/// Use this method, ..CreateTimestamp(), when naming files on the remote FTP server, use ##class(Ens.Util.File).CreateTimestamp() when naming local files. 
Method CreateTimestamp(pFilename As %String, pSpec As %String, pDummyVMS As %Boolean, pDirectory As %String, pDummyLocal As %Boolean) As %String [ CodeMode = expression ]
{
##class(Ens.Util.File).CreateTimestamp(.pFilename,.pSpec,..%isVMS,.pDirectory,0)
}

Method disconnectOnNetErr(pText As %String, pInbound As %Boolean = 0) [ Internal ]
{
	Quit:'..Connected
	Set tNetErr=('$IsObject(..FTP)||'..FTP.Connected)
	If tNetErr {Do ..Disconnect(pInbound) Quit}
	Set:""=$G(pText) pText=..FTP.ReturnMessage_"="_..FTP.ReturnCode
	Quit:pText="OK"
	Set tNetErr=(((pText["<READ>")||(pText["<WRITE>")&&(pText'[".File"))||(pText["<NOTOPEN>")||(pText["=425")||(pText["=529"))
	If tNetErr {Do ..Disconnect(pInbound) Quit}
	If (pText["SSH Error") {
		Try {
			/*
			example of pText:
			"FTP: Failed to Put file 'DebugTestFile.txt' (msg='Error in SFTP Put('C:\InterSystems\Ens122\mgr\Temp\8Hhozlr2aqS1cw.sftp','sftp/DebugTestFile.txt') ERROR #7500: SSH Put Error '-2146430933': SSH Error [8010102B]: Timeout waiting for status message"
			Selected 'reconnectable' from libssh2.h
			
			LIBSSH2_ERROR_SOCKET_SEND               -7	: 07
			LIBSSH2_ERROR_TIMEOUT                   -9	: 09
			LIBSSH2_ERROR_SOCKET_DISCONNECT         -13	: 0D
			LIBSSH2_ERROR_PROTO                     -14	: 0E
			LIBSSH2_ERROR_CHANNEL_OUTOFORDER        -20	: 14
			LIBSSH2_ERROR_CHANNEL_FAILURE           -21	: 15
			LIBSSH2_ERROR_CHANNEL_UNKNOWN           -23	: 17
			LIBSSH2_ERROR_CHANNEL_WINDOW_EXCEEDED   -24	: 18
			LIBSSH2_ERROR_CHANNEL_PACKET_EXCEEDED   -25 : 19
			LIBSSH2_ERROR_CHANNEL_CLOSED            -26	: 1A
			LIBSSH2_ERROR_CHANNEL_EOF_SENT          -27	: 1B
			LIBSSH2_ERROR_SCP_PROTOCOL              -28 : 1C
			LIBSSH2_ERROR_SOCKET_TIMEOUT            -30	: 1E
			LIBSSH2_ERROR_SFTP_PROTOCOL             -31	: 1F
			LIBSSH2_ERROR_EAGAIN                    -37 : 25
			LIBSSH2_ERROR_BUFFER_TOO_SMALL          -38	: 26
			LIBSSH2_ERROR_SOCKET_RECV               -43 : 2B
			LIBSSH2_ERROR_BAD_SOCKET                -45 : 2D
			*/
			Set tSSHErrorCode=-$ZH(""_$P($P(pText,"SSH Error [801010",2),"]",1))
			Set tNetErr=$CASE(tSSHErrorCode,
							 	-7:1,
							 	-9:1,
							 	-13:1,
							 	-14:1,
							 	-20:1,
							 	-21:1,
							 	-23:1,
							 	-24:1,
							 	-25:1,
							 	-26:1,
							 	-27:1,
							 	-28:1,
							 	-30:1,
							 	-31:1,
							 	-37:1,
							 	-38:1,
							 	-43:1,
							 	-45:1,
								:0)
		} Catch { Set tSSHErrorCode=""}
		Do:tNetErr ..Disconnect(pInbound) 
		Quit
	}	;End SSH Error check
	/* 
		Now Check if left with a SFTP Error 
		See DMC706
		Example "ERROR <Ens>ErrFTPPutFailed: FTP: Failed to Put file 'DebugTestFile.txt' (msg='Error in SFTP Put('C:\InterSystems\Ens122\mgr\Temp\0fLushbg6tavEQ.sftp','sftp/DebugTestFile.txt') ERROR #7500: SSH Put Error '-2146426877': SFTP Error [80102003]: Permission Denied [80102003] at .\SFTP.cpp:539,0',code=0)"
				"OK",				
				"End-of-file",			
				"No Such File",			
				"Permission Denied",		
				"Operation Failed",		
				"Bad Message",			
				"No Connection",		
				"Connection Lost",		
				"Operation Unsupported",	
				"Invalid Handle",		
				"No Such Path",			
				"File Already Exists",		
				"Write Protect",		
				"No Media",			
				"No Space On Filesystem",	
				"Quota Exceeded",		
				"Unknown Principal",		
				"Lock Conflict",		
				"Directory Not Empty",		
				"Not A Directory",		
				"Invalid Filename",		
				"Link Loop",			
	*/
	Set tNetErr=((pText["SFTP Error [801020")&&(pText["Connection"))
	Do:tNetErr ..Disconnect(pInbound)
}

/// This query is a shadow of the FileSet query in %Library.File, using an interface to the Adapter and skipping directories
/// The dirsOrNoDirs argument if 0 (the default) will exclude directory entries, or if 1 will return directory entries only.
Query FileList(adapter As Ens.Adapter, directory As %String(MAXLEN=""), wildcards As %String, dirsOrNoDirs As %Boolean = 0, semaphoreSpec As %String = "") As %Query(ROWSPEC = "Name:%String,Type:%String,Size:%BigInt,DateCreated:%TimeStamp,DateModified:%TimeStamp,ItemName:%String,ItemDir:%String,SemaphoreName:%String") [ SqlProc ]
{
}

ClassMethod FileListExecute(ByRef QHandle As %Binary, adapter As Ens.Adapter, directory As %String, wildcards As %String, dirsOrNoDirs As %Boolean = 0, semaphoreSpec As %String = "") As %Status
{
	Set QHandle=adapter
	Set tSC=adapter.Connect(adapter.ConnectTimeout,1)
	If $$$ISERR(tSC) $$$ASSERT('adapter.Connected)  Quit tSC
	$$$ASSERT(adapter.Connected)

	#; get file list
	Set QHandle("dirsOrNoDirs")=dirsOrNoDirs, QHandle("directory")=adapter.fixSvrPath(directory,1)
	Set QHandle("semaphoreSpec")=semaphoreSpec
	$$$ASSERT($E(directory,1,$L(adapter.FilePath))=adapter.FilePath)
	If (directory'=adapter.%LastSetFilePath)&&'adapter.FTP.SetDirectory(directory) Quit $$$ERROR($$$EnsErrFTPDirectoryChangeFailed,directory,adapter.FTP.ReturnMessage,adapter.FTP.ReturnCode) 
	Set:dirsOrNoDirs&&(wildcards="_") wildcards=directory
	Set tSC = $S(adapter.FTP.List(wildcards,adapter.FileListStream):$$$OK,
				 adapter.FTP.ReturnMessage["file not found":$$$OK, ; VMS
				 adapter.FTP.ReturnMessage["cannot find the file":$$$OK, ; IIS non-wildcard spec
				 1:$$$ERROR($$$EnsErrFTPListFailed,adapter.FileSpec,adapter.FTP.ReturnMessage,adapter.FTP.ReturnCode))
	If (directory'=adapter.%LastSetFilePath)&&'adapter.FTP.SetDirectory(adapter.%LastSetFilePath) Quit $$$ERROR($$$EnsErrFTPDirectoryChangeFailed,adapter.%LastSetFilePath,adapter.FTP.ReturnMessage,adapter.FTP.ReturnCode) 
	Quit:$$$ISERR(tSC) tSC
	$$$catTRACE("connwait","got FileListStream("_adapter.FileListStream.Size_")")
	// Add a simplistic check to ensure we are using the correct line terminator for the stream.
	// 1000 characters should be sufficient to work out which terminator is in use.
	If adapter.FileListStream.Size {
		Set tListPeek = adapter.FileListStream.Read(1000)
		Do adapter.FileListStream.Rewind()
		Set tListTerm = $select(tListPeek [ $c(13,10): $c(13,10), tListPeek [ $c(10): $c(10), tListPeek [ $c(13): $c(13), 1: $c(13,10))
		Set adapter.FileListStream.LineTerminator = tListTerm
	}
	Quit tSC
}

ClassMethod FileListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	#; find the next non-directory filename
	Set tSC=$$$OK, adapter=QHandle, dirsOrNoDirs=QHandle("dirsOrNoDirs")
	For {
		If $L(adapter.%NextLine) {
			Set tLine=adapter.%NextLine, tLen=$L(adapter.%NextLine), adapter.%NextLine=""
		} Else {
			Kill tLen  If 'adapter.FileListStream.Size { Set tLen=-1 } Else { Set tLine=adapter.FileListStream.ReadLine(.tLen) }
		}
		If tLen=-1 {
			#; Done with this FileList now
			Do adapter.FileListStream.Clear()
			Set Row="", AtEnd=1
			Quit
		}
		#; If VMS server, check lookahead buffer for possible multi-line directory listing
		If adapter.%isVMS {
			#; A line starting with a space denotes continuation of the previous line in the listing
			For {
				Kill tLen1 Set adapter.%NextLine=adapter.FileListStream.ReadLine(.tLen1)
				Quit:$E(adapter.%NextLine)'=" "
				Set tLine=tLine_adapter.%NextLine, tLen=tLen+tLen1, adapter.%NextLine=""
			}				
	 		$$$sysTRACE("got full VMS List() line '"_tLine_"' and NextLine buffer = '"_adapter.%NextLine_"'")
	 		If "Directory "=$E(tLine,1,$L("Directory ")) Continue
	 		If ("Total of "=$E(tLine,1,$L("Total of ")))&&(adapter.%NextLine = "")&&adapter.FileListStream.AtEnd {
				$$$sysTRACE("Ignoring VMS List() line '"_tLine_"' as VMS summary line")
				Continue
			}
		}
		Continue:tLen<40
		Set tName=tLine, tStyle = $ZSTRIP($ZCVT(adapter.ServerListStyle,"L"),"*W","-_,;:/")
		Set tOK=adapter.ParseFilename(.tName,.tModified,.tSize,.tIsDir)
		If 'tOK||tIsDir {
			If tStyle="as400" && ("*MEM"=$ZCVT(tSize,"U")) && ("*FILE"=$E(adapter.%PrevMod,*+1-$L("*FILE"),*)) {
				Set tName=$P(tModified,tSize_"_",2), tSize=adapter.%PrevSize, tModified=$Replace(adapter.%PrevMod,"*FILE","*MEM"), adapter.%LastErr=$$$OK
				Continue:adapter.%PrevFile_"."_adapter.%PrevFile=tName ; if the member is the same as the file, then we already tried to get it
			} Else { Continue:'tOK }
			Quit:'dirsOrNoDirs='tIsDir  ; skip directories or non-directories
		} ElseIf tStyle="as400" {
			If $$$ISERR(adapter.%LastErr) {
				Set tSC=adapter.%LastErr, adapter.%LastErr=$$$OK, adapter.%NextLine=tLine, adapter.BusinessHost.%WaitForNextCallInterval=0
				Quit
			}
			Set adapter.%PrevFile=tName, adapter.%PrevSize=tSize, adapter.%PrevMod=$ZCVT(tModified,"U")
			Quit:'dirsOrNoDirs='tIsDir  ; skip directories or non-directories
		} Else {
			Set tSemaphoreFile=""
			If 'dirsOrNoDirs='tIsDir { ; skip directories or non-directories
				Quit:(QHandle("semaphoreSpec")="")
				Set tSemaphoreSpec=QHandle("semaphoreSpec"),tTargetFile=tName
				Set tHaveSemaphore=0,tStatus=1
				For c=1:1:$L(tSemaphoreSpec,";") {
					Set tTargetPattern=$P(tSemaphoreSpec,";",c),tSemaphorePattern=$P(tTargetPattern,"=",2),tTargetPattern=$P(tTargetPattern,"=",1)
					Set tLike=$S(tTargetPattern="*":1,tTargetPattern="*.*":1,1:##class(Ens.Util.File).FileLikePattern(tTargetFile,tTargetPattern,.tStatus))
					Quit:$$$ISERR(tStatus)
					If tLike {
						Set tSemaphoreFile=##class(Ens.Util.File).GenerateSemaphoreFilename(tTargetFile,tSemaphorePattern,.tStatus)
						Quit:$$$ISERR(tStatus)
						If (tSemaphoreFile'=tTargetFile) {
							Kill tSemStream
							If (QHandle("directory")'=adapter.%LastSetFilePath)&&'adapter.FTP.SetDirectory(QHandle("directory")) {
								Set tStatus =  $$$ERROR($$$EnsErrFTPDirectoryChangeFailed,QHandle("directory"),adapter.FTP.ReturnMessage,adapter.FTP.ReturnCode)
								Quit
							}
							Set tHaveSemaphore=$S(adapter.FTP.List(tSemaphoreFile,.tSemStream):1,
				 						adapter.FTP.ReturnMessage["file not found":0, ; VMS
				 						adapter.FTP.ReturnMessage["cannot find the file":0, ; IIS non-wildcard spec
										1:0)
							If (QHandle("directory")'=adapter.%LastSetFilePath)&&'adapter.FTP.SetDirectory(adapter.%LastSetFilePath) {
								Set tStatus =  $$$ERROR($$$EnsErrFTPDirectoryChangeFailed,adapter.%LastSetFilePath,adapter.FTP.ReturnMessage,adapter.FTP.ReturnCode)
								Quit
							}
							If tHaveSemaphore {
								If 'tSemStream.Size {
									Set tHaveSemaphore = 0
								} Else {
									Do tSemStream.Rewind()
									Set tHaveSemaphore = (tSemStream.Read()[tSemaphoreFile)
								}
							}
							#;Check in case there is a single semaphore file that appears mid poll and need to wait. Hash to avoid long subscripts.
							If 'tHaveSemaphore,$G(tSemaphoreFile)'="" Set QHandle("semaphoreSpec","wait",$system.Encryption.SHA1Hash(QHandle("directory")_tSemaphoreFile))=""
							#;Only process a file for a semaphore if don't have a previous waiter from this cycle
							If tHaveSemaphore,$G(tSemaphoreFile)'="",$D(QHandle("semaphoreSpec","wait",$system.Encryption.SHA1Hash(QHandle("directory")_tSemaphoreFile))) Set tHaveSemaphore=0				
							Quit:tHaveSemaphore
						}
						Set tSemaphoreFile=""
				
					}		
				}
				Quit:($$$ISERR(tStatus)||tHaveSemaphore)
			}
		}
	}
	If 'AtEnd,((QHandle("semaphoreSpec")="")||$G(tHaveSemaphore)){
 		Set Row=$LB(QHandle("directory")_tName, $S(tIsDir:"D",1:"F"), tSize, tModified, tModified, tName, QHandle("directory"),$G(tSemaphoreFile))
	}
	Quit tSC
}

ClassMethod FileListClose(QHandle As %Binary) As %Status
{
	Kill QHandle
	Set QHandle=""
	Quit $$$OK
}

}
