/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.FTP.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.FTP.Common, EnsLib.File.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Overwrite output file if it exists instead of appending
Property Overwrite As %Boolean [ InitialExpression = 1 ];

/// If the protocol is SFTP and Overwrite=false then you should configure SFTP Append Mode also. <p/>
/// If the SFTP server supports appending then you should select 'Server' append mode. 
/// Some SFTP servers do not support appending. When connecting to such a server you should select 'Client' append mode. <br/>
/// <a href="EnsPortal.Dialog.SFTPTest.cls">Click here to test server side append</a>
/// <p/>
/// In 'Client' mode the FTP adapter will retrieve the remote file (if it exists) from the server,
/// append the new data locally, and then put the combined data back to the SFTP server.
/// <p/>
/// There is a chance that some other process will remove the file from the server or modify the file on the server before the adapter puts
/// the combined data back to the server. In this case the changes made by the other process could be lost.
/// <p/>
/// The logic the SFTP adapter uses for local appending is:<ol>
/// <li>Check if the remote file exists</li>
/// <li>If it exists it renames by adding  .ToBeAppendedTo to the end of the name </li>
/// <li>If it does not exist it looks for a prior name ending .ToBeAppendedTo </li>
/// <li>If either of these existing files are found it is downloaded and the new data appended </li>
/// <li>The combined file is put back and the prior file ending with .ToBeAppendedTo is removed </li>
/// <li>If there is a network failure before putting the combined file on the server the adapter
/// will use the .ToBeAppendedTo file on the next connection </li>
/// </ol>
/// Since the file being appended to might be locked by the SFTP server
/// you should also consider configuring ReplyCodeActions so that the Operation retries upon error,
/// e.g.  E=R or E*Error.
/// <p/>
Property SFTPAppendMode As %String(VALUELIST = ",Client,Server") [ InitialExpression = "Client" ];

/* override from File superclass with new description (mention FTP Binary vs. Ascii) and new InitialExpression */
/// FTP Only - Use the named Character encoding to translate characters from the file. <br/>
/// A * prepended to any of the charset names will cause a binary FTP transfer with the resulting data then translated using the specified encoding. <br/>
/// Note that Binary should be chosen for binary files and other cases when special characters such as line terminators must be preserved. <br/>
/// Other settings may be useful when transferring text documents via FTP. <p/>
/// Choices include: <br/>
///  Binary - binary transfer <br/>
///  Ascii - Ascii mode FTP transfer but no character encoding translation <br/>
///  Native - the default character encoding of the installed locale of the InterSystems IRIS server <br/>
///  latin1 - the ISO Latin1 8-bit encoding <br/>
///  ISO-8859-1 - the ISO Latin1 8-bit encoding <br/>
///  UTF-8 - the Unicode 8-bit encoding <br/>
///  Unicode - the Unicode 16-bit encoding  (Little-Endian) <br/>
///  UnicodeBig - the Unicode 16-bit encoding (Big-Endian) <br/>
///  @&lt;ttable&gt; - &lt;ttable&gt; means a raw InterSystems character translation table name. A prefix of '@' means to use the named table.
Property Charset As %String [ InitialExpression = "Binary" ];

/// These properties can be configured or set by the associated Business Operation
Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=FTP},Overwrite,SFTPAppendMode:SFTP";

/* override from File superclass with new description (mention FTP server) */
/// Directory on the FTP server in which to effect FTP operations.
Property FilePath As %String(MAXLEN = 1000) [ Required ];

Method FilePathSet(path As %String) As %Status [ Internal ]
{
	If i%FilePath'=path {
		Set i%FilePath=path
		If ..Connected {
			Set tFixed=..fixSvrPath(path,0)
			If tFixed'=..%LastSetFilePath {
				If ..FTP.SetDirectory(tFixed) {
					Set ..%LastSetFilePath=tFixed
					$$$sysTRACE("Set FTP working directory to "_tFixed)
				} Else {
					Set ..%LastSetFilePath=""
					Do $$$EnsError($$$EnsErrFTPDirectoryChangeFailed,tFixed,..FTP.ReturnMessage,..FTP.ReturnCode) 
					Do ..disconnectOnNetErr()
				}
			}
		}
	}
	Quit $$$OK
}

Method CharsetSet(cset As %String) As %Status [ Internal ]
{
	Set tTable = "RAW"
	If i%Charset'=cset && ..Connected {
		Set csetlc=$ZCVT(cset,"L")
		#; Set the transfer mode
		Set tAscii=$Case($E(csetlc,1,5),"":1,"nativ":1,"defau":1,"ascii":1,"latin":1,"iso-8":1,"utf-8":1,:0)
		If 'tAscii {
			If '..FTP.Binary() {
				Do $$$EnsError($$$EnsErrFTPModeChangeFailed,"Binary",..FTP.ReturnMessage,..FTP.ReturnCode)
				Set ..FTP.TranslateTable = ""
				Do ..disconnectOnNetErr()
				Quit $$$OK
			}
			If "binary"'=csetlc {
				Set tEnc=cset   Set:"*"=$E(tEnc) $E(tEnc)=""
				Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(tEnc)
				Set:tTable="" tTable="RAW"
			}
		} Else {
			If '..FTP.Ascii() {
				Do $$$EnsError($$$EnsErrFTPModeChangeFailed,"Ascii",..FTP.ReturnMessage,..FTP.ReturnCode)
				Do ..disconnectOnNetErr()
				Quit $$$OK
			}
			If "ascii"'=csetlc {
				If $Case(csetlc,"":0,"default":0,"native":0,:1) {
					Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(cset)
				} Else { Set tTable = "" }
				Set:tTable="" tTable=$$DefIO^%NLS(5)
			}
		}
		Set ..FTP.TranslateTable = tTable
	}
	Set i%Charset=cset
	Quit $$$OK
}

Method OnInit() As %Status [ Internal ]
{
	Set tSC=##super() Quit:$$$ISERR(tSC) tSC
	Set:..StayConnected>0 ..KeepaliveInterval=..StayConnected
	If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
	Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
	If 0=..BusinessHost.%GetParameter("LOGTRANSFERS") Set ..%logTransfers=0
	Do ..FileListStreamNewObject() $$$ASSERT($IsObject(..FileListStream))
	Set ..FileListStream.LineTerminator=$C(13,10)
	Quit $$$OK
}

/// Passthrough method for the use of BatchStandardOperation classes. Non-trivial parallel version is defined in File adapter
Method CreateFilename(pFilename As %String, pSpec As %String, pIsVMS As %Boolean, pDirectory As %String, pLocal As %Boolean) As %String
{
	Quit ..CreateTimestamp(.pFilename,.pSpec,.pIsVMS,.pDirectory,.pLocal)
}

/// Store a Stream to an FTP server as a named file.
/// Server,Username,Password,FilePath and Transfer mode (Charset) are configured as Settings
/// for this Adapter. Returns a status value indicating the success of the FTP operation.
Method PutStream(pFilename As %String, pStream As %Stream.Object) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Prepare for Transfer
		Set tSC=..Connect(..ConnectTimeout)  Quit:$$$ISERR(tSC)
		
		#; Put the file
		$$$catTRACE("adapter","Putting stream "_pStream_" to "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" with timeout="_..ConnectTimeout)
		Set tStream=$S(pStream.%Extends("%IO.I.Stream"):##class(%IO.LibraryStream).%New(pStream),1:pStream)
		If '$S(..Overwrite:..FTP.Store(pFilename,tStream),1:..FTP.Append(pFilename,tStream)) { Set tSC=$$$ERROR($$$EnsErrFTPPutFailed,pFilename,..FTP.ReturnMessage,..FTP.ReturnCode)  Quit }
		Set tTxt="Put stream "_tStream_" to "_..fixSvrPath(..%LastSetFilePath,1)_pFilename
		If ..%logTransfers { $$$LOGINFO(tTxt) } Else { $$$catTRACE("adapter",tTxt) }
	} While 0
Exit
	Quit ..handleErr(tSC)
Trap
 	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Retrieve a named file from an FTP server and return it as a stream.
/// Server,Username,Password,FilePath and Transfer mode (Charset) are configured as Settings
/// for this Adapter. Returns a status value indicating the success of the FTP operation.
/// If the caller provides a stream, it must be the appropriate type of stream for the
/// transfer (Ascii, Binary). This method will create the stream if none is provided.
Method GetStream(pFilename As %String, ByRef pStream As %Stream.Object = {$$$NULLOREF}) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		#; Prepare for Transfer
		Set tSC=..Connect(..ConnectTimeout)  Quit:$$$ISERR(tSC)

		#; Get the file
		If '$IsObject(pStream) {
			If "binary"'=$ZCVT(..Charset,"L") { Set tStream=##class(%GlobalCharacterStream).%New() } Else { Set tStream=##class(%GlobalBinaryStream).%New() }
			$$$ASSERT($IsObject(tStream))
		} Else {
			Set tStream=$S(pStream.%Extends("%IO.I.Stream"):##class(%IO.LibraryStream).%New(pStream),1:pStream)
		}
		$$$catTRACE("adapter","Getting file "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" to stream "_pStream_" file "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" with timeout="_..ConnectTimeout)
		If '..FTP.Retrieve(pFilename,tStream) { Set tSC=$$$ERROR($$$EnsErrFTPGetFailed,pFilename,..FTP.ReturnMessage,..FTP.ReturnCode)  Quit }
		Set:'($IsObject(pStream)&&pStream.%Extends("%IO.I.Stream")) pStream=tStream

		Set tTxt="Got file "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" to stream "_pStream
		If ..%logTransfers { $$$LOGINFO(tTxt) } Else { $$$catTRACE("adapter",tTxt) }
	} While 0
Exit
	Quit ..handleErr(tSC)
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Delete a named file from an FTP server.
/// Server,Username,Password, and FilePath are configured as Settings for this Adapter.
/// Returns a status value indicating the success of the FTP operation.
Method Delete(pFilename As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSC=..Connect(..ConnectTimeout) If $$$ISERR(tSC)  Quit:$$$ISERR(tSC)
		$$$catTRACE("adapter","Deleting "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" with timeout="_..ConnectTimeout)
		If '$S(..%isSFTP:..FTP.DeleteSSH(pFilename), 1:..FTP.Delete(pFilename)) { Set tSC=$$$ERROR($$$EnsErrFTPDeleteFailed,pFilename,..FTP.ReturnMessage,..FTP.ReturnCode)  Quit }
		Set tTxt="Deleted "_..fixSvrPath(..%LastSetFilePath,1)_pFilename
		If ..%logTransfers { $$$LOGINFO(tTxt) } Else { $$$catTRACE("adapter",tTxt) }
	} While 0
Exit
	Quit ..handleErr(tSC)
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Rename a file on an FTP server.
/// Server,Username,Password, and FilePath are configured as Settings for this Adapter.
/// Returns a status value indicating the success of the FTP operation.
Method Rename(pFilename As %String, pNewFilename As %String, pNewPath As %String = "") As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	Do {
		Set tSC=..Connect(..ConnectTimeout)  Quit:$$$ISERR(tSC)
		Set tNewFilePath=pNewFilename  Set:""'=pNewPath tNewFilePath=..fixSvrPath(pNewPath,1)_tNewFilePath
		$$$catTRACE("adapter","Renaming "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" to "_tNewFilePath_" with timeout="_..ConnectTimeout)
		If '$S(..%isSFTP:..FTP.RenameSSH(pFilename,tNewFilePath),1:..FTP.Rename(pFilename,tNewFilePath)) { Set tSC=$$$ERROR($$$EnsErrFTPRenameFailed,pFilename_" -> "_tNewFilePath,..FTP.ReturnMessage,..FTP.ReturnCode)  Quit }
		Set tTxt="Renamed "_..fixSvrPath(..%LastSetFilePath,1)_pFilename_" to "_tNewFilePath
		If ..%logTransfers { $$$LOGINFO(tTxt) } Else { $$$catTRACE("adapter",tTxt) }
	} While 0
Exit
	Quit ..handleErr(tSC)
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Get a list of files on an FTP server.
/// Server,Username,Password, and FilePath are configured as Settings for this Adapter.
/// The filenames are returned in a %ListOfDataTypes object.
/// Returns a status value indicating the success of the FTP operation.
Method NameList(Output pFileList As %ListOfDataTypes) As %Status
{
	Kill pFileList Set pFileList=$$$NULLOREF,$ZT="Trap",tSC=$$$OK
	Do {
		$$$catTRACE("adapter","Getting list of filenames for "_..fixSvrPath(..FilePath,0)_" with timeout="_..ConnectTimeout)
		Set tSC=..Connect(..ConnectTimeout)  Quit:$$$ISERR(tSC)
		If '$S(..%isSFTP:..FTP.NameListSSH(..fixSvrPath(..FilePath,0),.tFileArray),1:..FTP.NameList(..fixSvrPath(..FilePath,0),.tFileArray)) { Set tSC=$$$ERROR($$$EnsErrFTPNameListFailed,..fixSvrPath(..FilePath,0),..FTP.ReturnMessage,..FTP.ReturnCode)  Quit }
		#; copy from from array to list, strip off any path name to be consistent across servers and to be like File.OutboundAdapter.NameList
		Set tFileList = ##class(%ListOfDataTypes).%New()  $$$ASSERT($IsObject(tFileList))
		Set key="" For  Set key=tFileArray.Next(key) Quit:""=key  Set tFName=tFileArray.GetAt(key), tSC=tFileList.Insert($P(tFName,"/",$L(tFName,"/")))  Quit:$$$ISERR(tSC)
		If $$$ISERR(tSC) { $$$LOGSTATUS(tSC) }
		Else { Set pFileList=tFileList }
	} While 0
Exit
	Quit ..handleErr(tSC)
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method handleErr(pSC As %Status) As %Status [ Internal ]
{
	Set tErrText=$$$StatusText(pSC)
	Do ..disconnectOnNetErr(tErrText)
	If '..Connected || ($$$StatusDisplayString(pSC)["<Ens>ErrFTP" && (tErrText?.E1"="1(1"52"1N,1"4"2N)1PC.E)) { ; retry on timeouts also
		Set ..BusinessHost.Retry=1
	}
	Do:..Connected&&'..StayConnected ..Disconnect()
	Quit pSC
}

}
