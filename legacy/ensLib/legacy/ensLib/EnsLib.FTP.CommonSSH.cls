/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Adapter that receives files via the FTP protocol.
Class EnsLib.FTP.CommonSSH Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// FTP Server to connect to
Property FTPServer As %String(MAXLEN = 1000);

/// TCP Port on the FTP Server to connect to. For FTP the standard port is 21 and for SFTP it is 22. Leave this field blank to use the appropriate standard value.
Property FTPPort As %Integer;

/// If non-zero, stay connected to the remote system between handling Requests until idle for this number of seconds. A value of -1 means never disconnect.
Property StayConnected As %Numeric(MINVAL = -1) [ InitialExpression = -1 ];

/// Number of seconds to wait on each connection attempt
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// AuthenticationMethods supported: <br>
/// Empty - use public/private key if defined, otherwise use username and password from Credentials <br>
/// p - use username and password from Credentials <br>
/// k - use public/private key <br>
/// i - use Interactive (Challenge/Response) <br>
/// For multiple combine in the order required, for example <br>
/// kp <br>
/// This will lead to public/private key authentication first followed by username and password <br>
Property SFTPAuthenticationMethods As %String(MAXLEN = 10);

/// File path to a file containing the SSH public key certificate
Property SFTPPublicKeyFile As %String(MAXLEN = 1000);

/// File path to a file containing the SSH private key certificate. <br>
/// The password from the Credentials setting will be used as the passphrase for the private key
/// unless SFTPPassphraseCredentials is specified, in which case the password from that will 
/// be used as the passphrase for the private key.
Property SFTPPrivateKeyFile As %String(MAXLEN = 1000);

/// This can be used to specify different credentials entry from which the password
/// will be used as the Key authentication Passphrase.
/// If this is blank the Credentials setting will be used. <br>
/// This separate setting allows having both Public Key and Password authentication
Property SFTPPassphraseCredentials As %String;

/// This is the credentials object containing the values to be used for the SFTPPassphraseCredentials
Property %SFTPPassphraseCredentialsObj As Ens.Config.Credentials;

/// If specified this is the DTL to used to handle the Interactive Authentication 
/// - also known as the keyboard-interactive or Challenge/Response authentication.
/// This can be a DTL to create an array of answers for the challenge response authentication
/// See Ens.SSH.InteractiveAuth.DTL
/// Leave blank to return just Credentials password
Property SFTPInteractiveDTL As %String(MAXLEN = 256);

/// SFTP File Access Mode specifies the access permissions to assign to the file on the remote system when transferred. <br>
/// It can be specified as either octal e.g. 0600 or symbolic such  as u+rw,g+r <br>
/// The default is 0600. If specifying octal 4 digits are required.<br>
/// For symbolic and specifying all use 'ugo' and not 'a' e.g ugo+rw.
Property SFTPFileAccessMode As %String [ InitialExpression = "0600" ];

/// When Putting a file with requested SFTP File Access Mode the SFTP server may apply
/// a umask. A separate SetPermissions call that might not be modified by a umask
/// can be made to apply the requested permissions.<br>
/// The default is to use an extra SetPermissions call.<br>
/// If the SFTP File Access Mode is 0600 a SetPermissions call will not be made irrespective of this setting.<br>
/// Note - this call may not succeed if the target file has already been collected on the server.
/// A Warning will be issued if the SetPermissions call errors. <br>
Property SFTPSetFileAccessModeByClient As %Boolean [ InitialExpression = 1 ];

/// The preferred SSH Key Exchange (KEX) algorithm.
/// Available options depend on the host OS.
Property SFTPKexAlgorithm As %String;

Parameter SETTINGS = "FTPServer:Basic,FTPPort:Basic,Credentials:Basic:credentialsSelector,FilePath:Basic,Charset::selector?context={Ens.ContextSearch/CharacterSets},StayConnected:Connection,ConnectTimeout:Connection,SFTPAuthenticationMethods:SFTP,SFTPPublicKeyFile:SFTP,SFTPPrivateKeyFile:SFTP,SFTPPassphraseCredentials:SFTP:credentialsSelector,SFTPInteractiveDTL:SFTP,SFTPFileAccessMode:SFTP,SFTPSetFileAccessModeByClient:SFTP,SFTPRemoteCharset:SFTP:selector?context={Ens.ContextSearch/CharacterSets?internalTables=1},SFTPLocalCharset:SFTP:selector?context={Ens.ContextSearch/CharacterSets?internalTables=1},SFTPKexAlgorithm:SFTP:selector?context={Ens.ContextSearch/SupportedKexAlgorithms}";

/// FTP Session object - %Net.FtpSession, or for SFTP it is an instance of this current class that serves as a proxy for %Net.SSH.SFTP)
Property FTP As %RegisteredObject [ Internal ];

/// Shadows ..FTP.Connected. For SFTP the proxy session object and the Adapter are one and the same so this property is shared.
Property Connected As %Boolean [ InitialExpression = 0, Internal ];

Property %LastSetFilePath As %String [ Internal ];

Property %sshSession As %Net.SSH.Session [ Internal ];

Property %sftpSession As %Net.SSH.SFTP [ Internal ];

/// Character set for filenames used by the remote server.<br>
/// Defaults to UTF8. <br> 
/// Set to empty string for no character set translation for filenames.<br>
/// This setting is used to set the RemoteCharset property in the %Net.SSH.Session object.<br>
Property SFTPRemoteCharset As %String [ InitialExpression = "UTF8" ];

/// Character set used by the local system for filename encoding.<br>
/// For Windows the default is the empty setting which will leave local filenames as Unicode.<br>
/// For Unix the default is to convert to UTF8.<br>
/// This setting is used to set the LocalCharset in the %Net.SSH.Session object.<br>
Property SFTPLocalCharset As %String [ InitialExpression = {$CASE($system.Version.GetOS(),"Windows":"",:"UTF8")} ];

Method ConnectSSH(pTimeout As %Numeric = 15, pInbound As %Boolean = 0, pSFTPPort As %Integer) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tSFTP As %Net.SSH.SFTP

	Try {
		Set ..%sshSession = ##class(%Net.SSH.Session).%New()

		Set ..%sshSession.RemoteCharset = ..SFTPRemoteCharset
		Set ..%sshSession.LocalCharset = ..SFTPLocalCharset

		#; SetTimeout() uses ms. -1 is the default = no timeout.
		If pTimeout '=-1 {
			Set tSC = ..%sshSession.SetTimeout(pTimeout*1000)
			Quit:$$$ISERR(tSC)
		}

		#; Set Preferred KEX algorithm
		If ..SFTPKexAlgorithm'="" {
			Set tSC = ..%sshSession.SetPreferredAlgorithms("KEX="_..SFTPKexAlgorithm)
			Quit:$$$ISERR(tSC)
		}

		Set tSC = ..%sshSession.Connect(..FTPServer,pSFTPPort)  Quit:$$$ISERR(tSC)

		Set tSC = ..AuthenticateSSH()  Quit:$$$ISERR(tSC)

		Set tSC = ..%sshSession.OpenSFTP(.tSFTP)  Quit:$$$ISERR(tSC)
	
		Set ..%sftpSession=tSFTP

	} Catch ex {
		Set tSC=$$$SystemError
		Set tSC =$$$ERROR($$$EnsErrOutConnectException,$$$StatusText(tSC),"SFTP",..FTPServer_":"_pSFTPPort_"/"_..Credentials_","_..SFTPPrivateKeyFile_","_..SFTPPublicKeyFile)
	}
	#; Ensure if any errors we remove any connections made.
	If $$$ISERR(tSC) Do ..Logout()

	Quit tSC
}

Method TestConnectionSSH(pInbound)
{
	If '..Connected Do:$IsObject(..%sshSession) ..Logout()  Quit ; force FTP class into sync in case it made a mistake
	Quit ; no test currently
}

/*
 SFTP / %Net.FtpSession compatibility proxy wrapper properties and methods
*/
/// ReturnCode is a the three digit number that an FTP server reponds to commands
/// with. For SFTP we will simulate this
Property ReturnCode As %Integer [ InitialExpression = 0, Internal ];

/// ReturnMessage is set to the text message that the sftp server responds with.
/// This often contains useful information if a method failed
Property ReturnMessage As %String [ Internal ];

/// The translate table to be used when reading or writing files.<br>
Property TranslateTable As %String;

/// Our internal record of what our current directory has been set to
Property %serverPath As %String [ Internal ];

Method Logout() As %Boolean [ Internal ]
{
	Set (tSC,tSC1)=$$$OK, ..ReturnCode=0, ..ReturnMessage=""

	If $IsObject(..%sftpSession) Set tSC=..%sftpSession.CloseSFTP()  Set ..%sftpSession=$$$NULLOREF
	If $IsObject(..%sshSession) Set tSC1=..%sshSession.Disconnect()  Set ..%sshSession=$$$NULLOREF
	Set ..Connected=0
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP CloseSFTP() "_$$$StatusDisplayString(tSC)  Quit 0
	If $$$ISERR(tSC1) Set ..ReturnMessage="Error in SFTP Disconnect() "_$$$StatusDisplayString(tSC1)  Quit 0
	Quit 1
}

Method Store(Filename As %String, Stream As %AbstractStream, Append As %Integer = 0) As %Boolean [ Internal ]
{
	Set ..ReturnCode=0, ..ReturnMessage=""
	Set tIsFile=$S(Stream.%Extends("%Library.FileStreamAdaptor"):1, Stream.%Extends("%Stream.FileBinary"):2, Stream.%Extends("%IO.FileStream"):3, 1:0)
	If (tIsFile=1) || (tIsFile=2) {
		Set tLocalFilename=Stream.Filename
	} ElseIf tIsFile=3 {
		Set tLocalFilename=Stream.Name
	} Else {
		#; not checking if Stream.IOStream is an object since required for this.
		If ((Stream.%Extends("%IO.LibraryStream")) && (Stream.IOStream.%Extends("%IO.FileStream"))) {
			Set tLocalFilename=Stream.IOStream.Name
		} Else {
			Set tTempStream=##class(%Library.FileBinaryStream).%New()
			Set tSC=tTempStream.CopyFrom(Stream)
			Set:$$$ISOK(tSC) tSC=tTempStream.Flush()
			Set:$$$ISOK(tSC) tSC=tTempStream.Rewind()
			Set tLocalFilename = tTempStream.Filename
			If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP stream ("_Stream_") copy to local file '"_tLocalFilename_"' (size="_tTempStream.Size_") "_$$$StatusDisplayString(tSC)  Quit 0
		}
	}
	$$$sysTRACE("About to put from local file '"_tLocalFilename_"' / stream "_Stream_") to SFTP file '"_..%serverPath_Filename_"' with Access mode of '"_..SFTPFileAccessMode_"' ")
	Set tSC=..%sftpSession.Put(tLocalFilename,..%serverPath_Filename,..SFTPFileAccessMode,Append)
	#;SFTP server may apply umask to request permissions to allow client side SetPermissions
	If tSC&&(..SFTPFileAccessMode'="0600") && ..SFTPSetFileAccessModeByClient{
		#dim tSCPerm=..%sftpSession.SetPermissions(..%serverPath_Filename,..SFTPFileAccessMode)
		If $$$ISERR(tSCPerm) $$$LOGWARNING("Error in SFTP SetPermissions('"_..%serverPath_Filename_"','"_..SFTPFileAccessMode_"') "_$$$StatusDisplayString(tSCPerm))
	}
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP Put('"_tLocalFilename_"','"_..%serverPath_Filename_"') "_$$$StatusDisplayString(tSC)  Quit 0
	Quit 1
}

/// Append the data contained in <var>Stream</var> to the file named in <var>Filename</var>.
/// Note: Because Append is not supported natively by all SFTP servers, we have to retrieve and re-send
/// the entire file plus the appended addition.
Method Append(Filename As %String, Stream As %AbstractStream) As %Boolean [ Internal ]
{
	Set $ZT="TrapServerAppend"
	//If SFTPAppendMode use the SFTP Append call (DMC818)
	If ($ZCVT(..SFTPAppendMode,"L") [ "server") {
		$$$catTRACE("adapter","Put file with SFTP Server side Append ('"_..%serverPath_Filename_"'). This is not supported by all SFTP servers.")
		Quit ..Store(Filename,Stream,1)
	}
	Set $ZT="Trap",tIO=$IO,tTempExt=".ToBeAppendedTo"

	/*
	Look for prior version of file
	Look for prior temporary version of the file
	If both exist then the old temporary will be overwritten.
	*/
	$$$catTRACE("adapter","Looking for remote "_..%serverPath_Filename)
	Set tSCExisting=..%sftpSession.FileInfo(..%serverPath_Filename,.tList)

	$$$catTRACE("adapter","Looking for remote temporary version "_..%serverPath_Filename_tTempExt_" if it exists since we will need to rename it back.")
	Set tSCExistingTemp=..%sftpSession.FileInfo(..%serverPath_Filename_tTempExt,.tList)
	If tSCExistingTemp $$$catTRACE("adapter","Found a prior temporary : "_..%serverPath_Filename_tTempExt_" to "_..%serverPath_Filename)

	If tSCExisting {
		/* We want to rename remote so that if necessary we can put back */
		If tSCExistingTemp {
			$$$LOGWARNING("Deleting prior temporary file ("_..%serverPath_Filename_tTempExt_") since non temporary remote also exists. The temporary file ought to have been deleted before.")
			Set tSC=..%sftpSession.Delete(..%serverPath_Filename_tTempExt)
		}
		$$$catTRACE("adapter","About to rename remote pre-existing "_..%serverPath_Filename_" to "_..%serverPath_Filename_tTempExt)
		Set tSC=..%sftpSession.Rename(..%serverPath_Filename,..%serverPath_Filename_tTempExt)
		If $$$ISERR(tSC) {
			Set ..ReturnMessage="Error in SFTP Append() Rename of ('"_..%serverPath_Filename_"') prior to append."_$$$StatusDisplayString(tSC)
			Quit 0
		}
	} ElseIf 'tSCExistingTemp {
		$$$catTRACE("adapter","Did not find remote pre-existing "_..%serverPath_Filename_" to append to. Issuing Store command.")
		/* Carry on with normal Store. */
		Quit ..Store(Filename,Stream)
	}

	/* Get a local filename to store both stream and remote copy if it exists
		Caller of TempFilename must delete the file created by api even if not used.
	*/
	Set tLocalFilename=##class(%File).TempFilename("sftp")
	Set tAppended = 0
	$$$catTRACE("adapter","Attempting to retrieve existing remote using temporary name "_..%serverPath_Filename_tTempExt)
	Set tSC=..%sftpSession.Get(..%serverPath_Filename_tTempExt,tLocalFilename,420)
	If $$$ISERR(tSC) {
		Set ..ReturnMessage="Error in SFTP Append() Get("_..%serverPath_Filename_tTempExt_","_tLocalFilename_","_420_") "_$$$StatusDisplayString(tSC)
	}  Else {
		$$$catTRACE("adapter","Retrieved remote pre-existing (using remote temporary name)"_..%serverPath_Filename_tTempExt_" to append to.")
		If ..%logTransfers $$$LOGINFO("Appending data to existing remote "_..%serverPath_Filename_". Removing remote and appending locally.")
		/*
		We now have a remote file with temporary extension that we will either delete or put back later.
		Proceed to append locally the contents of new stream
		*/
		Open tLocalFilename:("AWU"):1
		If $Test {
			Set tLocalFileOpened = 1
			Use tLocalFilename
			Do Stream.OutputToDevice()
			Use tIO
			Close tLocalFilename
			Set tLocalFileOpened = 0
			$$$catTRACE("adapter","About to Put from temp file '"_tLocalFilename_"' / stream "_Stream_") to SFTP file '"_..%serverPath_Filename_"'"_"' with Access mode of '"_..SFTPFileAccessMode_"' ")
			Set tSC=..%sftpSession.Put(tLocalFilename,..%serverPath_Filename,..SFTPFileAccessMode)
			#;SFTP server may apply umask to request permissions to allow client side SetPermissions
			If tSC&&(..SFTPFileAccessMode'="0600") && ..SFTPSetFileAccessModeByClient{
				#dim tSCPerm=..%sftpSession.SetPermissions(..%serverPath_Filename,..SFTPFileAccessMode)
				If $$$ISERR(tSCPerm) $$$LOGWARNING("Error in SFTP SetPermissions('"_..%serverPath_Filename_"','"_..SFTPFileAccessMode_"') "_$$$StatusDisplayString(tSCPerm))
			}
			If $$$ISERR(tSC) {
				Set ..ReturnMessage="Error in SFTP Append() Put('"_tLocalFilename_"','"_..%serverPath_Filename_"') "_$$$StatusDisplayString(tSC)
				/* Need to put back temporary file */
				$$$catTRACE("adapter","About to rename to original remote pre-existing due to append failure: "_..%serverPath_Filename_tTempExt_" to "_..%serverPath_Filename)
				Set tSC=..%sftpSession.Rename(..%serverPath_Filename_tTempExt,..%serverPath_Filename)
				If $$$ISERR(tSC) {
					Set ..ReturnMessage="Error in SFTP Append() Rename back to original of ('"_..%serverPath_Filename_tTempExt_"') after failed append."_$$$StatusDisplayString(tSC)_". "_..ReturnMessage
					/*
					We are now in a position where we failed to append and the original on the remote system is left we temporary name/.
					We may have lost network access and hence need to put back when restarted.
					*/
				}
			} Else {
				$$$catTRACE("adapter","About to Delete temporary renamed prior version of remote file ('"_..%serverPath_Filename_tTempExt_"')")
				Set tSC=..%sftpSession.Delete(..%serverPath_Filename_tTempExt)
				/* We have successfully sent the appended version so treat as success but log warning failed to delete temporary */
				If $$$ISERR(tSC) $$$LOGWARNING("Failed in SFTP Append() to delete temporary copy of prior version of remote file('"_..%serverPath_Filename_tTempExt_"') "_$$$StatusDisplayString(tSC) )
				/* Append was a success */
				Set tAppended = 1
			}
		} Else {
			Set ..ReturnMessage="Error in SFTP Append() Failed to open temporary file "_tLocalFilename
		}
	}
	Do ##class(%File).Delete(tLocalFilename)
	Quit tAppended
Trap
	Set $ZT=""
	Use tIO
	Set tSC=$$$SystemError
	If $G(tLocalFilename) {
		If $G(tLocalFileOpened) Close tLocalFilename
		Do ##class(%File).Delete(tLocalFilename)
	}
	Set ..ReturnMessage="System Error in SFTP Append() ('"_tLocalFilename_"','"_..%serverPath_Filename_"') "_$$$StatusDisplayString(tSC)
	Quit 0
TrapServerAppend
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Set ..ReturnMessage="System Error in calling SFTP Server Append() "_$$$StatusDisplayString(tSC)
	Quit 0
}

Method fileRetrieve(Filename As %String, ByRef Stream As %AbstractStream, pRetry As %Boolean = 0) As %Integer [ Internal ]
{
	#dim tSC As %Status
	#dim tIsFile As %Boolean
	#dim tIsBinary As %Boolean
	#dim tLocalFilename As %String

	Set ..ReturnCode=0, ..ReturnMessage=""
	Set tIsFile=$S(Stream.%Extends("%Library.FileStreamAdaptor"):1, Stream.%Extends("%Stream.FileBinary"):2, Stream.%Extends("%IO.FileStream"):3, 1:0)
	Set tIsBinary=Stream.%Extends("%BinaryStream")

	// Force Stream to pick up a filename by triggering write ""
	If (tIsFile=1) && (Stream.Filename="") Do Stream.Write("")

	// Create a temp file
	Set tLocalFilename=##class(%File).TempFilename("sftp")

	$$$sysTRACE("About to get SFTP file '"_..%serverPath_Filename_"' to local file '"_tLocalFilename_"' / stream "_Stream_" with TranslateTable of "_..TranslateTable)
	Set tSC=..%sftpSession.Get(..%serverPath_Filename,tLocalFilename,420)
	If $$$ISERR(tSC) {
		Set ..ReturnMessage="Error in SFTP Get("_..%serverPath_Filename_","_tLocalFilename_","_$S(tIsFile:420,1:384)_") "_$$$StatusDisplayString(tSC)
		Do:'tIsFile ##class(%File).Delete(tLocalFilename)
		Quit 0
	}

	If pRetry Do Stream.Clear()

	Set tTempStream = $S(tIsBinary:##class(%FileBinaryStream).%New(), 1:##class(%FileCharacterStream).%New())
	If 'tIsBinary Set tTempStream.TranslateTable = ..TranslateTable
	Do tTempStream.LinkToFile(tLocalFilename)
	Do Stream.CopyFrom(tTempStream)
	
	// Delete the temp file anyway
	Do ##class(%File).Delete(tLocalFilename)

	Quit 1
}

Method Retrieve(Filename As %String, ByRef Stream As %AbstractStream) As %Integer [ Internal ]
{
	Quit ..fileRetrieve(.Filename,.Stream,0)
}

Method RetryRetrieve(Filename As %String, Stream As %AbstractStream) As %Integer [ Internal ]
{
	Quit ..fileRetrieve(.Filename,.Stream,1)
}

Method DeleteSSH(Filename As %String) As %Boolean [ Internal ]
{
	Set tSC=..%sftpSession.Delete(..%serverPath_Filename), ..ReturnCode=0, ..ReturnMessage=""
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP Delete("_..%serverPath_Filename_") "_$$$StatusDisplayString(tSC)  Quit 0
	Quit 1
}

Method RenameSSH(OldFilename As %String, NewFilePath As %String) As %Boolean [ Internal ]
{
	Set tNew=$S(NewFilePath["/":NewFilePath, 1:..%serverPath_NewFilePath)
	Set tSC=..%sftpSession.Rename(..%serverPath_OldFilename, tNew), ..ReturnCode=0, ..ReturnMessage=""
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP Rename("_..%serverPath_OldFilename_","_tNew_") "_$$$StatusDisplayString(tSC)  Quit 0
	Quit 1
}

Method NameListSSH(Path As %String, ByRef FileArray As %ArrayOfDataTypes) As %Boolean [ Internal ]
{
	Set:"/*"=$E(Path,*-1,*) Path=$E(Path,1,*-1) ; sftpSession.Dir() only supports getting all files currently with implicit * pattern
	Set tSC=..%sftpSession.Dir(Path,.files), ..ReturnCode=0, ..ReturnMessage=""
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP Dir("_Path_",.files) "_$$$StatusDisplayString(tSC)  Quit 0

	If $IsObject($G(FileArray)) {
		Do FileArray.Clear()
	} Else {
		Set FileArray=##class(%ArrayOfDataTypes).%New()
	}
	#; Loop over files array and insert values into the output FileArray
	Set i="" For { Set i = $O(files(i),1,tInfo)  Quit:""=i
		Set tName=$LG(tInfo,1)
		Set tIsDir=("D"=$LG(tInfo,3))
		Continue:tIsDir ; skip dirs
		Do FileArray.SetAt(tName,i)
	}
	Quit 1
}

Method List(Pattern As %String, ByRef Stream As %AbstractStream) As %Boolean [ Internal ]
{
	If '$IsObject($Get(Stream)) {
		If ..transferType=1 { Set Stream=##class(%GlobalCharacterStream).%New() } Else { Set Stream=##class(%GlobalBinaryStream).%New() }
	}
	Set tSC=..%sftpSession.Dir(..%serverPath_$S("*"=Pattern:"",1:Pattern),.files), ..ReturnCode=0, ..ReturnMessage="" ; sftpSession.Dir() only supports getting all files currently with implicit * pattern
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP Dir("_..%serverPath_$S("*"=Pattern:"",1:Pattern)_",.files) "_$$$StatusDisplayString(tSC)  Quit 0
	Set i="",FileArray=0 For { Set i = $O(files(i),1,tInfo)  Quit:""=i
		#;  1) Filename
		#;  2) Size
		#;  3) File type
		#;     P: Named pipe (FIFO)
		#;     C: Character special
		#;     D: Directory
		#;     B: Block special
		#;     F: Regular file
		#;     L: Symbolic link
		#;     S: Socket
		#;     U: Unknown
		#;  4) Permissions
		#;  5) UID
		#;  6) GID
		#;  7) Last Access Time
		#;  8) Last Modification Time
		Set tName=$LG(tInfo,1)
		Do Stream.Write($LG(tInfo,4)_" 1 "_$LG(tInfo,5)_" "_$LG(tInfo,6)_" "_$LG(tInfo,2)_" "_$LG(tInfo,8)_" "_tName_" "_$C(10))
	}
	Quit 1
}

Method getFileInfo(Filename As %String, ByRef Info) As %Status [ Internal ]
{
	Set tSC=..%sftpSession.FileInfo(..%serverPath_Filename,.Info), ..ReturnCode=0, ..ReturnMessage="" ; sftpSession.Dir() only supports getting all files currently with implicit * pattern
	If $$$ISERR(tSC) Set ..ReturnMessage="Error in SFTP FileInfo("_..%serverPath_Filename_",.Info) "_$$$StatusDisplayString(tSC)
	Quit tSC
}

Method System(ByRef System As %String) As %Boolean
{
	Set System="SFTP/SSH"
	Quit 1
}

Method SetDirectory(Path As %String) As %Boolean [ Internal ]
{
	Set ..%serverPath = ..fixSvrPath(Path,1)
	Quit 1
}

Method Binary() As %Boolean [ Internal ]
{
	Quit 1
}

Method Ascii() As %Boolean [ Internal ]
{
	Set ..ReturnMessage="Ascii mode not supported for SFTP"
	Quit 0 ; not supported
}

/// This query is a shadow of the FileSet query in %Library.File, using an interface to the Adapter and skipping directories
/// The dirsOrNoDirs argument if 0 (the default) will exclude directory entries, or if 1 will return directory entries only.
Query FileListSSH(adapter As Ens.Adapter, directory As %String(MAXLEN=""), wildcards As %String, dirsOrNoDirs As %Boolean = 0, semaphoreSpec As %String = "") As %Query(ROWSPEC = "Name:%String,Type:%String,Size:%BigInt,DateCreated:%TimeStamp,DateModified:%TimeStamp,ItemName:%String,ItemDir:%String,SemaphoreName:%String") [ SqlProc ]
{
}

ClassMethod FileListSSHExecute(ByRef QHandle As %Binary, adapter As Ens.Adapter, directory As %String, wildcards As %String, dirsOrNoDirs As %Boolean = 0, semaphoreSpec As %String = "") As %Status
{
	Set QHandle("adapter")=adapter
	Set tSC=adapter.Connect(adapter.ConnectTimeout,1)
	If $$$ISERR(tSC) $$$ASSERT('adapter.Connected)  Quit tSC
	$$$ASSERT(adapter.Connected)

	#; get file list
	Set QHandle("dirsOrNoDirs")=dirsOrNoDirs, QHandle("directory")=adapter.fixSvrPath(directory,1)
	Set QHandle("semaphoreSpec")=semaphoreSpec
	$$$ASSERT($E(directory,1,$L(adapter.FilePath))=adapter.FilePath)
	Set:dirsOrNoDirs&&(wildcards="_") wildcards="*"
	Set tSC=adapter.%sftpSession.Dir(directory,.QHandle,wildcards) /*Requires DMC841 for wildcards parameter*/
	If $$$ISERR(tSC) Set tSC=$$$ERROR($$$EnsErrGeneral,"Error in SFTP Dir("_directory_") "_$$$StatusDisplayString(tSC))  Quit tSC
	/* Need to account for QHandle containing QHandle("adapter")="2@EnsLib.FTP.InboundAdapter" and QHandle="". No need to compute if not tracing*/
	$$$catTRACE("connwait","got SFTP dir list("_directory_")"_$S(dirsOrNoDirs:" looking for directories",1:"")_"="_$S($O(QHandle("A"),-1)'="":$O(QHandle("A"),-1)+1-$O(QHandle("")),1:0))
	Set QHandle("pos")=-1

	/*
		If using a semaphore specification populate
		array of directory listing for all files in directory
		to prevent Dir() call for each semaphore file
	*/
	If semaphoreSpec'="" {

			#; Account for sub directory searching
			#dim tPPGKey=$system.Encryption.SHA1Hash(directory)
			If tPPGKey="" Set tPPGKey=$Random(10000)
			Set QHandle("ppgKey")=tPPGKey
			Kill ^||EnsSFTPAllList(tPPGKey)

			$$$catTRACE("connwait","getting full directory listing for semaphore matching")
			#dim tSemlist
			Set tSC=adapter.%sftpSession.Dir(directory,.tSemlist)
			If $$$ISERR(tSC) Set tSC=$$$ERROR($$$EnsErrGeneral,"Error in SFTP Dir("_directory_") "_$$$StatusDisplayString(tSC))  Quit tSC

			If $Data(tSemlist) {

				#dim tInfo,tName
				#dim tPos = $Order(tSemlist(""),1,tInfo)
				While tPos'="" {

					Set tName=$LG(tInfo,1)
					If ($LG(tInfo,3)'="D")&&(tName'="") {
						Set ^||EnsSFTPAllList(tPPGKey,tName)=""
					}

					Set tPos = $Order(tSemlist(tPos),1,tInfo)

				}

			}

			$$$catTRACE("connwait","finished getting full directory listing for semaphore matching")
	}

	Quit tSC
}

ClassMethod FileListSSHFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	#; find the next non-directory filename
	Set adapter=QHandle("adapter"), dirsOrNoDirs=QHandle("dirsOrNoDirs")
	Set tPos=$G(QHandle("pos"))
	For { Set:""'=tPos tPos=$O(QHandle(tPos),1,tInfo)  If ""=tPos Set (Row,tName,tIsDir,tInfo)=""  Quit
		Continue:tPos'=+tPos
		#; Gets information about a file.  On return, info is a $LIST containing:
		#;  1) Filename
		#;  2) Size
		#;  3) File type
		#;     P: Named pipe (FIFO)
		#;     C: Character special
		#;     D: Directory
		#;     B: Block special
		#;     F: Regular file
		#;     L: Symbolic link
		#;     S: Socket
		#;     U: Unknown
		#;  4) Permissions
		#;  5) UID
		#;  6) GID
		#;  7) Last Access Time
		#;  8) Last Modification Time
		Set tName=$LG(tInfo,1)
		Set tIsDir=("D"=$LG(tInfo,3))
		Set tSemaphoreFile=""
		/* We want to return this row if its name is not . or .. and either a)it is a directory and we want directories or b) we don't want directories and it is not a directory */
		/* Handle semaphore check here */
		If (QHandle("semaphoreSpec")'=""),'tIsDir,$Case(tName,".":0,"..":0,:1) {
			#;Only check files otherwise let through as before
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
						Set tHaveSemaphore=$Data(^||EnsSFTPAllList(QHandle("ppgKey"),tSemaphoreFile))#2
						Quit:tHaveSemaphore
					}
					Set tSemaphoreFile=""
				}
			}
			Quit:($$$ISERR(tStatus)||tHaveSemaphore)
		} Else {
			Quit:((dirsOrNoDirs=tIsDir)&&$Case(tName,".":0,"..":0,:1))
		}
	}
	Set QHandle("pos")=tPos
	Set AtEnd=(""=tPos)
	#; ROWSPEC = "Name:%String,Type:%String,Size:%BigInt,DateCreated:%TimeStamp,DateModified:%TimeStamp,ItemName:%String,ItemDir:%String") [ SqlProc ]
	Set:""'=tIsDir Row=$LB(QHandle("directory")_tName,  $LG(tInfo,3), $LG(tInfo,2), $LG(tInfo,7), $LG(tInfo,8), tName, QHandle("directory"),$G(tSemaphoreFile))
	Quit $$$OK
}

ClassMethod FileListSSHClose(QHandle As %Binary) As %Status
{
	#dim tPPGKey
	If $Data(QHandle("ppgKey"),tPPGKey)#2 Kill ^||EnsSFTPAllList(tPPGKey)

	Kill QHandle
	Set QHandle=""
	Quit $$$OK
}

Method SFTPPassphraseCredentialsSet(pInVal As %String) As %Status
{
	#; Copy of Ens.Adapater::CredentialsSet
	Set ..%SFTPPassphraseCredentialsObj=$$$NULLOREF

	Set tClassname=$zobjmethod($this,"%ClassName",1) ; call subclass
	Set tClass = $$$comMemberKeyGet(tClassname,$$$cCLASSproperty,"%SFTPPassphraseCredentialsObj",$$$cPROPtype)
	If ""'=tClass {
		Set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tObj,tClassname,tClass,pInVal)
		If $$$ISOK(tSC) { Set ..%SFTPPassphraseCredentialsObj=tObj }
		ElseIf '$$$StatusEquals(tSC,$$$EnsErrNoCallerCredentials) {
			$$$LOGSTATUS(tSC)
		}
	}
	Set i%SFTPPassphraseCredentials=pInVal
	Quit $$$OK
}

Method AuthenticateSSH() As %Status
{
	#dim tSC = $$$OK
	#; If more than one authentication mechanism
	#dim tNonFinalAuthErrors = $$$OK

	#dim tCredentialsUsername = ..%CredentialsObj.Username
	#dim tCredentialsPassword = ..%CredentialsObj.Password

	#dim tKeyUsername
	#dim tKeyPassphrase

	#dim tSFTPAuthenticationMethods = ..SFTPAuthenticationMethods

	If tSFTPAuthenticationMethods = "" {

		If (""'=..SFTPPrivateKeyFile)&&(""'=..SFTPPublicKeyFile) {

			Set tSFTPAuthenticationMethods = "k"

		} Else {

			Set tSFTPAuthenticationMethods = "p"

		}

	}

	#dim count
	#dim authMethod = ""

	For count = 1:1:$Length(tSFTPAuthenticationMethods) {

		Set authMethod = $ZConvert($Extract(tSFTPAuthenticationMethods,count,count),"l")

		If authMethod = "k" {

			If (..SFTPPassphraseCredentials = "") {

				Set tKeyUsername = tCredentialsUsername
				Set tKeyPassphrase = tCredentialsPassword

			} Else {

				Set tKeyUsername = ..%SFTPPassphraseCredentialsObj.Username
				Set tKeyPassphrase = ..%SFTPPassphraseCredentialsObj.Password

			}

			Set tSC = ..%sshSession.AuthenticateWithKeyPair(tKeyUsername,..SFTPPublicKeyFile,..SFTPPrivateKeyFile,tKeyPassphrase)

		} ElseIf authMethod = "p" {

			Set tSC = ..%sshSession.AuthenticateWithUsername(tCredentialsUsername,tCredentialsPassword)

		} ElseIf authMethod = "i" {

			#dim lamdaForXecute = "(username,instructions,prompts,promptflags,context) Quit ##class(Ens.SSH.Util).InteractiveAuth(username,instructions,prompts,promptflags,.context)"
			Set tSC = ..%sshSession.AuthenticateWithKeyboardInteractive(tCredentialsUsername, lamdaForXecute, $this)

		} Else {

			Set tSC = $$$ERROR($$$EnsErrFTPConnectFailed,"Unknown authentication method","Invalid spec",authMethod)

		}

		If (count '= $Length(tSFTPAuthenticationMethods)) {
			/* Carry onto next server authentication method.
				Save any error in case final authentication attempt
				is an error. Note: intermediary error might not be
				a final error. See %Net.SSH.Session docs.
			*/
			If $$$ISERR(tSC) {
				Set tAuthErrorText = $system.Status.GetErrorText(tSC)
				$$$catTRACE("extern","Error returned from authenticating method '" _ authMethod _ "' : " _ tAuthErrorText)
				Set tNonFinalAuthErrors = $$$ADDSC(tNonFinalAuthErrors,tSC)
				Set tSC = $$$OK
			}
		} ElseIf $$$ISERR(tSC) {
 			#; add in any prior errors to last auth method error
			Set:(count>1) tSC = $$$ADDSC(tNonFinalAuthErrors,tSC)
		}
	}

	Return tSC
}

}
