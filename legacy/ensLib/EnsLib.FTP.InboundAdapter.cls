/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Adapter that receives files via the FTP protocol.
Class EnsLib.FTP.InboundAdapter Extends (EnsLib.File.InboundAdapter, EnsLib.FTP.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/* (may be overridden in BusinessService's OnInit() method by setting the properties
    ..Adapter.FilenameExpression,TimestampExpression,IsDirExpression,SizeExpression) */
/// Type of listing format returned by the FTP server.<p/>
/// 'VMSAllVersions' means on VMS FTP servers, retrieve all versions listed, not only the latest VMS version of the file <br/>
/// This value is not pertinent if the protocol is SFTP.
Property ServerListStyle As %String(VALUELIST = ",Unix,MSDOS,AS/400,VMS,VMSAllVersions,NetWare") [ InitialExpression = "Unix" ];

/* override from File superclass with new description (FTP not File) */
/// Specifies whether or not to delete files from the FTP server after successful processing <br/>
/// If not deleted, the adapter will ignore files already processed until something else removes them from the FTP server.
Property DeleteFromServer As %Boolean [ InitialExpression = 1 ];

/// Should the adapter construct a FileStream or a GlobalStream for data received? <br/>
/// Note that regardless of this setting a FileStream will be used if ArchivePath or ArchiveIO is set.
Property UseFileStream As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=FTP},FilePath:Basic,DeleteFromServer:Basic,CheckModifiedBeforeDelete:Basic,FileSpecDelimiter:Basic,UseFileStream,-WorkPath,ServerListStyle,-SFTPFileAccessMode,-SFTPSetFileAccessModeByClient,RetryableErrors";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/* override from CommonSSH superclass with new description (no StayConnected time) */
/// If zero, disconnect from the remote FTP server between attempts to retrieve a directory listing. A value of -1 means never disconnect.
Property StayConnected As %Numeric(MINVAL = -1, VALUELIST = ",0,-1") [ InitialExpression = -1 ];

/* override from File superclass with new description (mention FTP server) */
/// Directory on the FTP server in which to effect FTP operations. <br>
/// This setting cannot be blank if SubdirectoryLevels is greater than 0.
Property FilePath As %String(MAXLEN = 1000) [ Required ];

/* override from File superclass with new description (mention FTP Binary vs. Ascii) and new InitialExpression */
/// Use the named Character encoding to translate characters from the file. <br/>
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

/* override from File superclass with new description (mention FTP server) */
/// Path on the InterSystems IRIS server to save a copy of each file received from the FTP server. If not given, the local copy of the file will be stored in a temporary location and then deleted after processing is completed.
/// Note that the AppendTimestamp option must be used to avoid name collisions in the archive directory if the same filename will be retrieved repeatedly.
Property ArchivePath As %String(MAXLEN = 1000);

/* override from File superclass with new description */
/// Filename or wildcard file specification for file(s) to retrieve from the FTP server
/// Multiple file specifications can be entered separated by a delimiter.
/// It is necessary to enter the delimiter used in the File Specification Delimiter setting.
/// Enter the FileSpec as one line.
/// Maximum length is 2000 characters.<br/>
/// This setting must be given and not be blank.<br/>
Property FileSpec As %String(MAXLEN = 2000);

Property %multiFileSpec As %String [ MultiDimensional ];

/// When multiple wildcards in the File Specification this contains the original
/// File Specification setting value
Property %completeFileSpec As %String [ Transient ];

/// When multiple wildcards in the File Specification this is the current file specification being used
Property %currentFileSpec As %String [ Transient ];

/// Internal flag to indicate multiple wild cards in FileSpec
Property %fileSpecHasMulti As %Boolean [ InitialExpression = 0, Transient ];

/// If this is non empty then it will be used as the delimiter
/// to split the File Specification setting into multiple filename/wild card searches.
Property FileSpecDelimiter As %String;

/* override from File superclass with new description (FTP related options) */
/// Confirm complete receipt of file if possible, in case it is not completely available on the server at the time downloading begins.<p/>
/// 'None' offers the fastest performance for small files because no extra FTP directory listing needs to be retrieved for each file download attempt <p/>
/// 'Size' means keep reading more data for a file until the file size reported by the server directory listing does not increase  <br/>
///          This option is only reliable for Charset='binary' transfers (In text mode the file position used for downloading may get corrupted by the insertion or removal of Linefeed characters) <br/>
///          This option alone may not be sufficient if the FTP server or source application is sluggish. If the server reports the same <br/>
///           size for the file 2 times in a row, 2 seconds apart, then InterSystems IRIS will consider the download complete. Therefore the 'Size &amp; Rename' setting is preferable if the server supports 'Rename'. <br/>
///          This option relies on correct results from the Adapter.SizeExpression string set in the OnInit() method of the Business Service.<p/>
/// 'Rename' means keep trying to read more data for a file until the server allows us to rename it <br>
///          This option will only work if the FTP server grants Rename privilege to InterSystems IRIS for the download directory, using the Credentials <br/>
///          configured on this adapter, and if the file permissions on the file itself are set so that the FTP server has privilege to rename it. <br/>
///          If not then the Rename attempt will always fail and the InterSystems IRIS download will never complete
Property ConfirmComplete As %Integer(DISPLAYLIST = ",None,Size,Rename,Size & Rename", VALUELIST = ",0,1,2,3") [ InitialExpression = "1" ];

/* override from File superclass with new description (omit mention of WorkPath) */
/// Append a timestamp to Archive filenames in order to prevent possible name collisions on repeated processing of the same filename.<p/>
/// If this value is empty or 0, no timestamp will be appended. If it is 1, then the standard timestamped filename specification template '%f_%Q' will be used.<p/>
/// Any other value will be used directly as a timestamped filename specification template.
Property AppendTimestamp As %String [ InitialExpression = 1 ];

Property FileSizeStream As %GlobalCharacterStream [ Internal ];

/// Expression for extracting the filename portion of a line of the FTP directory listing (%line)
Property FilenameExpression As %String;

/// Expression for extracting the timestamp portion of a line of the FTP directory listing (%line)
Property TimestampExpression As %String;

/// Expression for extracting the is-a-directory flag from the FTP directory listing (%line)
Property IsDirExpression As %String;

/// Expression for extracting the file size from the FTP directory listing (%line); if present used for detecting download complete status
Property SizeExpression As %String;

/// Lookahead buffer for VMS. Contains the next line in the input stream.
Property %NextLine As %String(MAXLEN = 2048) [ Internal ];

/// Previous file Size string for AS/400
Property %PrevSize As %String [ Internal ];

/// Previous file Modified string for AS/400
Property %PrevMod As %String [ Internal ];

/// Previous file Name string for AS/400
Property %PrevFile As %String [ Internal ];

/// Previous error if failed to get member FILENAME.FILENAME (forget it if we find any members)
Property %LastErr [ InitialExpression = {$$$OK}, Internal ];

/// Record that the last file looked at in OnTask encountered a network error or needs retrying.
Property %LastFileNeedsRetrying As %Boolean [ InitialExpression = 0, Internal ];

/// When DeleteFromServer is enabled, this optional flag can be used to influence checking
/// whether a file has been modified since initial listing for download and then processing
/// 
/// This Switch is applied when both of the following conditions are true:
/// <ul>
/// <li>Setting "DeleteFromServer" is enabled</li>
/// <li>Setting ConfirmComplete is by "Size"</li>
/// </ul>
/// The Size check captures the latest current modified datetime during the download of a file.
/// Note: The precision on a file modified time is limited to minutes. This is used in combination with the Size
/// to decern whether a file has changed on the FTP server since download. ie: Should be deleted,
/// and should be processed as new content.
/// In the case of large files that are syncronously processed (ArchivePath is empty) significant time may elapse
/// between the download and attempt to delete the file. Additionally the delete from FTP server could be deferred due to network inturuption. 
/// This feature may meet sufficiently, the data file transfer requirements of some integrations.
/// Note: If there are limitations in the FTP Server view, where modified date is unreliable, then this option should not be enabled,
/// to avoid reprocessing content.
/// Meaning of setting options:
/// <ul>
///  <li>No  - Never Check. Just attempt to delete.</li>
///  <li>Deferred - If the delete gets deferred then check the modified value (Default).
///  <li>Yes - Always check if modified before an attempt to delete.</li>
/// </ul>
Property CheckModifiedBeforeDelete As %String(DISPLAYLIST = ",Never,Deferred,Always", VALUELIST = ",0,1,2") [ InitialExpression = 1 ];

/// This setting needs to be a comma-separated list of error types that should be ignored and should not cause a file to be skipped in the future. <br>
/// Example: <Ens>ErrGeneral,<Ens>AnotherError
Property RetryableErrors As %String;

/// An multi-dimentional array that stores retryable errors, which are not deemed to be normal errors.
Property %RetryableErrors As %String [ Internal, MultiDimensional, Private ];

/* below are propertySet methods duplicated from OutboundAdapter because EnsLib.FTP.Common does not inerit from EnsLib.File.Common to avoid double-inheritance of EnsLib.File.Common */
Method FilePathSet(path As %String) As %Status [ Internal ]
{
	If i%FilePath'=path {
		Set i%FilePath=path
		If ..Connected {
			Set tSC=..setFilePath(path)
			If $$$ISERR(tSC) {
				$$$LOGSTATUS(tSC)
				Do ..disconnectOnNetErr(,1)
			}
		}
	}
	Quit $$$OK
}

Method setFilePath(pPath As %String, Output pOldPath As %String) As %Status [ Internal ]
{
	Set tFixed=..fixSvrPath(pPath,0), pOldPath=..%LastSetFilePath
	If tFixed'=..%LastSetFilePath {
		If ..FTP.SetDirectory(tFixed) {
			$$$sysTRACE("Set FTP working directory to "_tFixed)
			Set ..%LastSetFilePath=tFixed
		} Else {
			Set ..%LastSetFilePath=""
			Quit $$$ERROR($$$EnsErrFTPDirectoryChangeFailed,tFixed,..FTP.ReturnMessage,..FTP.ReturnCode) 
		}
	}
	Quit $$$OK
}

Method restoreFilePath(pOldPath As %String) As %Status [ Internal ]
{
	If pOldPath'=..%LastSetFilePath {
		If ..FTP.SetDirectory(pOldPath) {
			$$$sysTRACE("Restored FTP working directory to "_pOldPath)
			Set ..%LastSetFilePath=pOldPath
		} Else {
			Set ..%LastSetFilePath=""
			Quit $$$ERROR($$$EnsErrFTPDirectoryChangeFailed,pOldPath,..FTP.ReturnMessage,..FTP.ReturnCode) 
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
		Set tAscii=$Case($E(csetlc,1,5),"":1,"defau":1,"ascii":1,"latin":1,"iso-8":1,"utf-8":1,:0)
		If 'tAscii {
			If '..FTP.Binary() {
				Do $$$EnsError($$$EnsErrFTPModeChangeFailed,"Binary",..FTP.ReturnMessage,..FTP.ReturnCode)
				Set ..FTP.TranslateTable = ""
				Do ..disconnectOnNetErr(,1)
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
				Do ..disconnectOnNetErr(,1)
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
#define RetryableErrors $LISTBUILD($$$EnsErrFTPGetSizeFailed)
   Set retryableErrors = $$$RetryableErrors _ $LISTFROMSTRING(..RetryableErrors)
   Set ptr = 0
   While $LISTNEXT(retryableErrors, ptr, err) {
	  Set:err'="" ..%RetryableErrors(err) = 1
   }

   Do ..testPaths(1)
   Set tStyle = $ZSTRIP($ZCVT(..ServerListStyle,"L"),"*W","-_,;:/")
   Set:..%isSFTP tStyle="unix"
   Set:"vmsa"=$E(tStyle,1,$L("vmsa")) ..VMSLatestVersionOnly=0
   If ""=..FilenameExpression {
      If "msdos"=tStyle {
         // Standard listing style for Windows server in MS-DOS mode
         Set ..FilenameExpression = "$this.TakeFromCol(%line,4)" ; 4th space-delimited piece is the name
         Set ..TimestampExpression = "$this.spacepiece(%line,1,3)" ; include size too - to detect that kind of change also
         Set ..IsDirExpression = "($this.spacepiece(%line,3)=""<DIR>"")"
         Set ..SizeExpression = "$this.spacepiece(%line,3)"
      } Elseif "vms"=tStyle || ("vmsa"=$E(tStyle,1,$L("vmsa"))) {
         // Standard VMS style server listing
         Set ..FilenameExpression = "$this.spacepiece(%line,1)"
         Set ..TimestampExpression = "$this.spacepiece(%line,3,6)"
         Set ..IsDirExpression = "($this.spacepiece(%line,1)["".DIR;"")"
         Set ..SizeExpression = "$piece($this.spacepiece(%line,2),""/"",1)"
      } Elseif "as400"=tStyle {
         // AS/400 / iSeries style server listing
         Set ..FilenameExpression = "$this.spacepiece(%line,6)"
         Set ..TimestampExpression = "$this.spacepiece(%line,1,5)"
         Set ..IsDirExpression = "($ZCVT($this.spacepiece(%line,5),""U"")=""*DIR"")"
         Set ..SizeExpression = "$this.spacepiece(%line,2)"
         If ..ConfirmComplete#2 Set ..ConfirmComplete=$$$XOR(..ConfirmComplete,1)  $$$LOGWARNING("Turning off ConfirmComplete='Size' not allowed for AS400 file 'members'")
      } ElseIf "netware"=tStyle {
         // NetWare listing style
         Set ..FilenameExpression = "$this.TakeFromCol(%line,8)" 
         Set ..TimestampExpression = "$this.spacepiece(%line,1,7)" 
         Set ..IsDirExpression = "(""d""=$E(%line))"
         Set ..SizeExpression = "$this.spacepiece(%line,4)"
      } Else {
         // Standard Unix style server listing
         Set ..FilenameExpression = "$this.TakeFromCol(%line,9)"
         Set ..TimestampExpression = "$this.spacepiece(%line,1,8)"
         Set ..IsDirExpression = "(""d""=$E(%line))"
         Set ..SizeExpression = "$this.spacepiece(%line,5)"
      }
   }
   Set ..SemaphoreSpec=$ZSTRIP(..SemaphoreSpec,"<>W")
   If ..SemaphoreSpec'="" {
      Set tSemaphoreSpec="",tNumberOfSpecs=$L(..SemaphoreSpec,";")
      For c=1:1:tNumberOfSpecs {
         Set tPair=$P(..SemaphoreSpec,";",c),tWarn=0
         If tPair'="" {
            Set tTargetSpec=$P(tPair,"=",1)
            Set:(tTargetSpec="") tTargetSpec="*",tWarn=1
            Set tSemSpec=$P(tPair,"=",2)
            Set:(tSemSpec="") tSemSpec=tTargetSpec,tTargetSpec="*"
            Set:('tWarn&&(tTargetSpec'="*")) tWarn=tSemSpec=tTargetSpec 
            If tWarn $$$LOGWARNING("Incorrect Semaphore Specification"_" "_..SemaphoreSpec)
            Set tSemaphoreSpec=tSemaphoreSpec_tTargetSpec_"="_tSemSpec_$S(c=tNumberOfSpecs:"",1:";")
         }
      }
      Set ..SemaphoreSpec=tSemaphoreSpec
   }
   Set:..StayConnected>0&&(..StayConnected<..CallInterval) ..KeepaliveInterval=..StayConnected
   Do ..FileListStreamNewObject() $$$ASSERT($IsObject(..FileListStream))
   Set ..FileListStream.LineTerminator=$C(13,10)
   Do ..FileSizeStreamNewObject() $$$ASSERT($IsObject(..FileSizeStream))
   Set ..FileSizeStream.LineTerminator=$c(13,10)

   Set ..%CurrResultSet=##class(%ResultSet).%New($$$CurrentClass_":DeepList")  $$$ASSERT($IsObject(..%CurrResultSet))
   Kill ..%CurrResultSet.Data
   Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.ftp") ; clean up on restart
   Set:"vms"=tStyle&&("*"=..FileSpec) ..FileSpec="*.*" ; force functional wildcard for Search on VMS
   If 0=..BusinessHost.%GetParameter("LOGTRANSFERS") Set ..%logTransfers=0

	If (..FileSpec="") {
		$$$LOGWARNING($$$Text("File Spec Setting is empty and needs to be specified"))
	} ElseIf (..FileSpecDelimiter'="") {
		Do ..initMultiFileSpec()
	}

   If ..StayConnected<0 { Set tSC=..Connect(..ConnectTimeout,1)  If $$$ISERR(tSC) $$$LOGWARNING($$$StatusDisplayString(tSC)) } // timeout is not fatal at this point, but do log it
   Else { $$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,"0|"_$$$timeUTC) }
   Quit $$$OK
}

Method initMultiFileSpec() [ Internal ]
{
	#dim i, oneWildCard, count
	Set ..%fileSpecHasMulti = 1
	Kill ..%multiFileSpec
	Set ..%currentFileSpec = ""
	Set ..%completeFileSpec = ..FileSpec
	For i=1:1:$length(..FileSpec,..FileSpecDelimiter) {
		Set oneWildCard=$zstrip($piece(..FileSpec,..FileSpecDelimiter,i),"<>W")
		If oneWildCard '= "" {
			Set ..%multiFileSpec(oneWildCard) = ""
			If $I(count) {}
		}
	}
	#; No need to use multispec logic
	If ($get(count,0) < 2) {
		Set ..%fileSpecHasMulti = 0
		Kill ..%multiFileSpec
		Set ..%completeFileSpec = ""
	}
}

Method testPaths(pOnInit As %Boolean = 1) As %Status
{
	If (""'=..ArchivePath),'##class(%File).DirectoryExists(..ArchivePath) {
		Set tSC=$$$ERROR($$$DirectoryNotExist,..ArchivePath)
		If 'pOnInit Quit tSC
		$$$LOGWARNING($$$StatusText(tSC))
	}
	Quit $$$OK
}

Method OnTask() As %Status [ Internal ]
{
#define ErrorFileTable(%tk) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.ftp",%tk)
#define ErrorFileTableNode(%tKey,%tNode) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.ftp",%tKey,%tNode)
#define DoneFileTable(%tk)  $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.ftp",%tk)
#define DoneFileTableNode(%tKey,%tNode) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.ftp",%tKey,%tNode)
#def1arg QueueDeleteFileTable(%subkeys) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.ftp.queueDelete",%subkeys)
#define UnitTestCoverageHooks(%val)
#define IsRetryableError(%sc) ($$$ISERR(%sc) && $DATA(..%RetryableErrors($SYSTEM.Status.GetErrorCodes(%sc))))

	#;Check WorkPath and ArchivePath if defined are accessible	
	Set tSC=..testPaths(0)
	If $$$ISERR(tSC) {
		If '..BusinessHost.%PreserveSession {
			#; We do not want to clean %SuperSession if set before %SessionId
			If '..BusinessHost.%SuperSessionCreatedBeforeSession  Set ..BusinessHost.%SuperSession = ""
			Set ..BusinessHost.%SessionId = ""
		}
		Quit tSC
	}

	Set $ZT="Trap", tSC=$$$OK, (tOneFilename,tFullFilename,tFilename,tTableKey)="", tDone=0
	Do {
		Quit:""=..FileSpec
		If '$D(..%CurrResultSet.Data) {
			If ..%fileSpecHasMulti {
				#; Need to keep the list of retrieved files across multi in case not DeleteFromServer
				If ..%currentFileSpec="" Kill ^||Ens.FileInbound.Found,^||Ens.FileInbound.Semaphore
				Set ..FileSpec = $Order(..%multiFileSpec(..%currentFileSpec))
				Set ..%currentFileSpec = ..FileSpec
				If ..FileSpec = "" {
					#; Empty ..%currentFileSpec and non empty ..%completeFileSpec will be indicator to finish current OnTask() cycle
					Set ..FileSpec = ..%completeFileSpec
					Do:'..StayConnected ..Disconnect(1)
					Quit
				}
			} else {
				Kill ^||Ens.FileInbound.Found,^||Ens.FileInbound.Semaphore
			}
			#; get file list
			$$$catTRACE("connwait","Looking for files '"_..FileSpec_"' in path '"_..FilePath_"'")
			Set tSC=..%CurrResultSet.Execute($this,..FilePath,..FileSpec,..SubdirectoryLevels,$S(..%isSFTP:"FileListSSH",1:"FileList"),..SemaphoreSpec)  Quit:$$$ISERR(tSC)
		} Else {
			/*  
				%CurrResultSet.Execute() connects if not connected
				but if we disconnected due a network error when 
				iterating through the resultset on prior OnTask
				we need to connect again.
			*/
			If '..Connected Set tSC=..Connect(..ConnectTimeout,1)
			Quit:$$$ISERR(tSC)
		}
		#; find the next one that can be processed
		For {
			/* 
				Check if the last file needs retrying 
				and use the current row rather than advancing.
			*/
			If ..%LastFileNeedsRetrying { 
				Set ..%LastFileNeedsRetrying=0
			} Else {
				If '..%CurrResultSet.Next(.tSC) {
					#; Done iterating the ResultSet for the current query execution - clean it up
					Do ..%CurrResultSet.Close()
					Kill ..%CurrResultSet.Data ; clean it out so next loop iteration will re-Execute the query
					#; delete the semaphore files used in this cycle
					Set tTableKey=$O(^||Ens.FileInbound.Semaphore(""),1,tSemaphorename)
					While tTableKey'="",..DeleteFromServer {
						If ..delete($LG(tSemaphorename,2),$LG(tSemaphorename,1)) {
							$$$sysTRACE("Deleted semaphore '"_$LG(tSemaphorename,2)_"' in directory '"_$LG(tSemaphorename,1)_"' after successful processing")
						} Else {
							Do ..disconnectOnNetErr(,1)
							If '..Connected Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to delete semaphore '"_$LG(tSemaphorename,2)_"' in directory '"_$LG(tSemaphorename,1)_"' after successful processing - "_..FTP.ReturnCode_":"_..FTP.ReturnMessage)  Quit
							$$$LOGWARNING("Failed to delete semaphore '"_$LG(tSemaphorename,2)_"' in directory '"_$LG(tSemaphorename,1)_"' from FTP server after successful processing - "_..FTP.ReturnCode_":"_..FTP.ReturnMessage)
						}
						Set tTableKey=$O(^||Ens.FileInbound.Semaphore(tTableKey),1,tSemaphorename)
					}
					#; handle deferred Deletes
					If ..DeleteFromServer {
						Set pTableKey=""
						For {
							Set pTableKey=$O($$$QueueDeleteFileTable(pTableKey),1,listdata)
							Quit:""=pTableKey
							Quit:'..Connected
							Set deferDir=$LI(listdata,1)
							Set deferFile=$LI(listdata,2)
							Set pModified=$LI(listdata,3)
							
							#; Conditionally determine whether to proceed with Delete if Modified
							#; Only available if the Download Completion utilizes File Size
							Quit:'..isDeleteStillNeeded(deferFile,deferDir,pModified,1,.deferDelete,1)
							$$$UnitTestCoverageHooks(if $D(^ahang("defer")) {)
							$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: Before Hang MOD FILE Defer Delete"))
							$$$UnitTestCoverageHooks(	H ^ahang("defer"))
							$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: After Hang MOD FILE Defer Delete"))
							$$$UnitTestCoverageHooks(})
							If ..delete(deferFile,deferDir) {  // Tested 5A.3
								$$$sysTRACE("Deleted file '"_deferFile_"' in directory '"_deferDir)
								Kill $$$QueueDeleteFileTable(pTableKey)
							} Else {
								Do ..disconnectOnNetErr(,1)
								If '..Connected {
									// Failure due to connectivity so retry indefinitely. Tested UT:11, UT:12
									Quit
								} Else {
									#; Failue due to readonly access, incorrect file permissions, or already deleted by other means
									$$$LOGWARNING("Failed to delete Queued Delete '"_deferFile_"' in directory '"_deferDir_"'. Confirm readwrite access and file permissions")
									Kill $$$QueueDeleteFileTable(pTableKey)  // Tested UT:13
								}
							}
						}
					}
					#; Don't disconnect if in multi spec pass
					If '..%fileSpecHasMulti || $$$ISERR(tSC) || (..%currentFileSpec = "") Do:'..StayConnected ..Disconnect(1)
					#; Remove errored files from the Error global if they no longer exist, and remove processed files from the Done global if they no longer exist
					Quit:$$$ISERR(tSC) ; if the list failed we don't know if the files are still there
					#; Do not look to remove if still in multi spec pass
					If '..%fileSpecHasMulti || (..%currentFileSpec = "") {
						Set tk="" For  Set tk=$O($$$DoneFileTable(tk)) Quit:tk=""   If ""=$G(^||Ens.FileInbound.Found(tk)) $$$sysTRACE("Removed absent file keyed as '"_tk_"' from processed list")  Kill $$$DoneFileTable(tk)
						Set tk="" For  Set tk=$O($$$ErrorFileTable(tk)) Quit:tk=""  If ""=$G(^||Ens.FileInbound.Found(tk)) If ""'=$G($$$ErrorFileTable(tk)) { $$$sysTRACE("Removed absent file keyed as '"_tk_"' from errored list") } If $D($$$DoneFileTable(tk)) { Set $$$ErrorFileTable(tk)="" } Else { Kill $$$ErrorFileTable(tk) }
					}
					Quit
				} Else { $$$ASSERT($$$ISOK(tSC)) }
			}
			Set tOneFilename=..%CurrResultSet.Data("ItemName"), tFullFilename=..%CurrResultSet.Data("Name"), tFileDir=..%CurrResultSet.Data("ItemDir"), tModified=..%CurrResultSet.Data("DateModified"), tSize=..%CurrResultSet.Data("Size"), tSemaphorename=..%CurrResultSet.Data("SemaphoreName")  $$$ASSERT(""'=tOneFilename&&(""'=tFullFilename))
			Set tTableKey = ..getFileSubscript(tFullFilename)
			Set ^||Ens.FileInbound.Found(tTableKey)=tFullFilename
			#;Hash to avoid subscript error from long filename and path
			#;Delete all used semaphore files at the end of polling cycle. "*/
			If (tSemaphorename'="")&&..DeleteFromServer Set ^||Ens.FileInbound.Semaphore($system.Encryption.SHA1Hash(tFileDir_tSemaphorename))=$LB(tFileDir,tSemaphorename)
			Lock +$$$ErrorFileTable(tTableKey):0 Else  $$$LOGINFO("Skipping locked file '"_tTableKey_"'") Continue

			#; Skip the files we have already processed except if they are modified; if they errored only warn once
			If $D($$$DoneFileTable(tTableKey),tTabModified)#2 {
				If (..ServerListStyle="Unix") && '..%isSFTP {
					#; Check to see if same date & filesize but now displaying year instead of time. Update table if so
					If (tTabModified'=tModified) && ($P(tTabModified,"_",1,*-1)=$P(tModified,"_",1,*-1)) && ($P(tTabModified,"_",*) ? 2N1":"2N) && ($P(tModified,"_",*) ? 4N) {
						Set $$$DoneFileTable(tTableKey) = tModified
					}
				}
				If $$$DoneFileTable(tTableKey)=tModified {
					If '$G($$$DoneFileTableNode(tTableKey,"done")) {
						Set $$$DoneFileTableNode(tTableKey,"done")=1
						$$$LOGINFO($$$FormatText($$$Text("Skipping previously processed file '%1'"),tFullFilename))
					}
					Lock -$$$ErrorFileTable(tTableKey)
					Continue
				}
			}
			
			If $D($$$ErrorFileTable(tTableKey),tTabModified)#2 {
				If (..ServerListStyle="Unix") && '..%isSFTP {
					#; Check to see if same date & filesize but now displaying year instead of time. Update table if so
					If (tTabModified'=tModified) && ($P(tTabModified,"_",1,*-1)=$P(tModified,"_",1,*-1)) && ($P(tTabModified,"_",*) ? 2N1":"2N) && ($P(tModified,"_",*) ? 4N) {
						Set $$$ErrorFileTable(tTableKey) = tModified
					}
				}
				If $$$ErrorFileTable(tTableKey)=tModified {
					If $G($$$ErrorFileTableNode(tTableKey,"wrn")) {
						Kill $$$ErrorFileTableNode(tTableKey,"wrn")
						$$$LOGWARNING($$$FormatText($$$Text("Skipping previously errored file '%1' with timestamp '%2'"),tFullFilename,tModified))
					}
					Lock -$$$ErrorFileTable(tTableKey)
					Continue
				}
			}
			If ..VMSLatestVersionOnly && ..%isVMS && ('..IsVMSLatestVersion(tFullFilename)) {
				If '..DeleteFromServer {
					If '$G($$$ErrorFileTableNode(tTableKey,"ver")) {
						Set $$$ErrorFileTableNode(tTableKey,"ver")=1  $$$sysTRACE($$$FormatText($$$Text("Skipping not-latest version of file '%1'"),tFullFilename))
					} 
				} Else {
					If '..delete(tOneFilename,tFileDir) {
						Do ..disconnectOnNetErr(,1)
						If '$G($$$ErrorFileTableNode(tTableKey,"ver")) {
							Set $$$ErrorFileTableNode(tTableKey,"ver")=1 $$$LOGWARNING($$$FormatText($$$Text("Failed to delete not-latest version of file '%1' - %2:%3"),tFullFilename,..FTP.ReturnCode,..FTP.ReturnMessage))
						}
					} Else {
						$$$LOGINFO($$$FormatText($$$Text("Deleted non-latest version of file %1"),tFullFilename))
						Kill $$$ErrorFileTable(tTableKey)					
					}
				}
				Lock -$$$ErrorFileTable(tTableKey)  Continue
			}
			Set $$$ErrorFileTable(tTableKey)=tModified, $$$ErrorFileTableNode(tTableKey,"wrn")=1
			Set tFilename=tOneFilename, tOneFilename=""
			Quit ; found a good one
		}
		Quit:""=tFilename
		$$$sysTRACE("About to process file '"_tFullFilename_"' (size '"_tSize_"') with timestamp '"_tModified_"', ConfirmComplete="_..ConfirmComplete)
		Set tSC=..processFile(tFilename,.tModified,tSize,.tDone,tFileDir,tSemaphorename,tTableKey)
		#; If error before completing the processing e.g. ProcessInput returned an error do not mark the file as done.
		If $$$ISERR(tSC),'tDone Quit
		#; mark the file as done if not deleted, whether or not we tried. e.g. we could get disconnected after having obtained the file and during successful processing.
		Set:tDone>0 $$$DoneFileTable(tTableKey)=tModified
	} While 0
Exit
	If tDone || $$$IsRetryableError(tSC) {
		#;If were supposed to delete but failed the delete then errored tSC expected.
		If (tDone=-1)||('..DeleteFromServer) $$$ASSERT($$$ISOK(tSC) || $$$IsRetryableError(tSC))
		If tDone=-1&&..VMSLatestVersionOnly&&..%isVMS {
			#; If deleted on VMS but other VMS versions of the file may exist, suppress messages about them
			Set $$$ErrorFileTable(tTableKey)=""
		} Else {
			Kill $$$ErrorFileTable(tTableKey)
		}
	} ElseIf $$$ISERR(tSC) {
		#;If tDone and an error then the disconnect would have been handled in processFile()
		Set tErrText=$$$StatusText(tSC)
		Do ..disconnectOnNetErr(tErrText,1)
		#; Don't count it as a file error if it was a network error or retryable
		If (""'=tFilename) && ('..Connected || (($$$StatusDisplayString(tSC)["<Ens>ErrFTP") && (tErrText?.E1"="1(1"52"1N,1"4"2N)1PC.E))) { ; retry on timeouts also
			Kill $$$ErrorFileTable(tTableKey)
			Set ..%LastFileNeedsRetrying=1
		}
		If ..StayConnected {
			If '..Connected Set ..%LastNetErr=tErrText
		} Else {
			#; Need to disconnect if StayConnected is 0 and error returned by %CurrResultSet.Execute()
			#; NoOp if already disconnected
			Do ..Disconnect(1)
		}
	}
	Lock:""'=tFilename -$$$ErrorFileTable(tTableKey)
	#; If testPaths() failed previously but then was successful
	If $$$ISOK(tSC)&&(..BusinessHost.%LastReportedError [ "ERROR #5021") {
		Set ..BusinessHost.%LastReportedError=""
		$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
	}

	#;if errored or finished looping over multi File Spec (indicated by currentFileSpec = "")
	If ..%fileSpecHasMulti {
		If (..%currentFileSpec = "") || $$$ISERR(tSC) {
			#;reset ..FileSpec to starting
			Set ..FileSpec = ..%completeFileSpec
			If $$$ISERR(tSC) Set ..%currentFileSpec = ""
		} Else {
			#;Don't wait to be called again so can process next wildcard
			Set ..BusinessHost.%WaitForNextCallInterval = 0
		}
	}
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock:""'=tFilename -$$$ErrorFileTable(tTableKey)
	Goto Exit
}

/// Parameter pTableKey is an newer additional parameter that supports deferred delete
/// Default to empty string in case of customer sub-classing.
/// Newer Deferred Delete behavor is not available if not supplied  
Method processFile(pFilename As %String, ByRef pModified As %String, pSize As %String, Output pDone As %Boolean, pFileDir As %String, pSemaphorename As %String = "", pTableKey As %String = "") As %Status [ Internal ]
{
#def1arg QueueDeleteFileTable(%subkeys) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.ftp.queueDelete",%subkeys)
#define UnitTestCoverageHooks(%val)
	Set (tComplete,pDone,tEverSize)=0, (tSize,tNewSize,tOldSize)=pSize, tFirst=1, tSizeTargTime="", tSC=$$$OK
	Set fileOverwrittenDuringSizeCheck=0
	Do {
		Set tSaveAsFile=(""'=..ArchivePath||..BusinessHost.ArchiveIO||..UseFileStream)
		Kill %objlasterror
		Set tIsBinary = "binary"=$ZCVT(..Charset,"L")
		Set tStream = $S(tIsBinary: $S(tSaveAsFile:##class(%FileBinaryStream).%New(), 1:##class(%GlobalBinaryStream).%New())
							, 1:$S(tSaveAsFile:##class(%FileCharacterStream).%New(), 1:##class(%GlobalCharacterStream).%New()))
		// Set the charset here only when the protocol is FTP, the file is to be saved, and the file is not binary
		If ('..%isSFTP) && tStream.%Extends("%FileCharacterStream") Set tStream.TranslateTable = ..FTP.TranslateTable

		Set tSC=$G(%objlasterror,$$$OK)
		Set:'$IsObject(tStream)||$$$ISERR(tSC) tSC=$$$ERROR($$$EnsErrGeneral,"Failed to create archive stream due to error:"_$S($$$ISERR(tSC):$$$StatusDisplayString(tSC),1:$$$ERROR($$$EnsErrGeneral,"%New() failed with no error report")))
		Quit:$$$ISERR(tSC)
		If tSaveAsFile {
			If ""=..ArchivePath { Set tArchiveName="" }
			Else {
				Set tArchiveName=..getArchiveFilename(pFilename)
				Set tSC=tStream.LinkToFile(tArchiveName)
				If $$$ISERR(tSC) { $$$LOGWARNING("Failed to create archive file '"_tArchiveName_"' due to error:"_$$$StatusDisplayString(tSC)) }
			}
		}
		If (pSemaphorename'="") $$$sysTRACE("Got semaphore file "_pSemaphorename_" for "_pFilename)
		
		#; Get the file
		For { ; loop getting chunks
			Set:..ConfirmComplete&&(""=tSizeTargTime) tSizeTargTime = $ZH+..FileAccessTimeout
			If tFirst {
				Set tSC=..retrieveFile(pFilename,tStream,pFileDir,0)
				If $$$ISERR(tSC) {
					#; If it was an AS/400 *FILE, quit OK but save the error - we will only return it later if no *MEM members are found.
					#; Don't count it as a file error if it was a network error
					Set tStyle = $ZSTRIP($ZCVT(..ServerListStyle,"L"),"*W","-_,;:/")
					Set:tStyle="as400"&&("*FILE"=$E(pModified,*+1-$L("*FILE"),*))&&..FTP.Connected ..%LastErr=tSC, tSC=$$$OK, ..BusinessHost.%WaitForNextCallInterval=0
					Quit
				}
			} ElseIf tNewSize>tOldSize {
				Set tSC=..retrieveFile(pFilename,tStream,pFileDir,1)  Quit:$$$ISERR(tSC) ; retry
			}
			Set tNewFilename=pFilename, tOldMod=pModified
			If (+tSize'=tSize||'(..ConfirmComplete#2)) {
				Set tNewSize=tSize
			} Else {
				Set tNewSize=..getSize(pFilename,pFileDir,.pModified)
				/* Need to reset tSizeTargTime since we want to ignore retrieval time
						'Size' means keep reading more data for a file until 
						the file size reported by the server directory listing 
						does not increase.
					Only reset if we did retrieve a size value.
				*/
				If tNewSize'="" Set tSizeTargTime = $ZH+..FileAccessTimeout
			}
			If +tSize'=tSize && (..ConfirmComplete#2) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to verify ConfirmComplete=Size size because initial SizeExpression result = '"_tSize_"'")
				Quit
			} ElseIf tNewSize>tSize {
				Set tNow=$ZH
				$$$sysTRACE("Got partial "_pFilename_"("_tStream.Size_") that was listed as size "_tSize_" (modified='"_tOldMod_"') and now shows "_tNewSize_" (modified='"_pModified_"')")
			} ElseIf tNewSize<tSize && (tNewSize'="") {
				#; Assume we got the old file and this is a new copy of the file we should process later
				$$$sysTRACE("Accepting "_pFilename_"("_tStream.Size_") that was listed as size "_tSize_" and now shows "_tNewSize)
				Set tComplete=1
				Set fileOverwrittenDuringSizeCheck=1  // The previous file is being overwritten on FTP Service
				#; If going to base decision to delete by modified datetime
				#; Can't use the future file modified datetime
				if ((..DeleteFromServer)&&(..ConfirmComplete#2)&&(tOldMod'=pModified)) {  // Limiting impact where needed 
					set pModified=tOldMod
				}
				Quit
			} Else {
				#; tNewSize is empty or same - if ConfirmComplete keep trying for a new size until ..FileAccessTimeout
				Set tNow=$ZH
				If ..ConfirmComplete#2 {
					If 'tEverSize {
						If tNewSize'="" {
							Set tEverSize=1
							$$$sysTRACE("Got same size "_tSize_" for "_pFilename_" with ConfirmComplete=Size; waiting for new size or FileAccessTimeout("_..FileAccessTimeout_")")
						} Else {
							$$$sysTRACE("Unable to obtain ConfirmComplete=Size ; waiting for new size or FileAccessTimeout("_..FileAccessTimeout_")")
						}
					}
				}
				If '(..ConfirmComplete#2) || (tNow>=tSizeTargTime) || ((tNewSize=tSize) && 'tFirst) {
					If ..ConfirmComplete#2 && (tNewSize="") && (tNow>=tSizeTargTime) {
						Set tSC=$$$ERROR($$$EnsErrFTPGetSizeFailed, "Could not get "_$S(tEverSize:"",1:"any ")_"size for "_pFilename_" ConfirmComplete=Size verification within FileAccessTimeout("_..FileAccessTimeout_")")
						Quit
					}
					If '(..ConfirmComplete\2#2) {
						#; not trying rename
						$$$sysTRACE("Confirmed complete "_pFilename_" with size "_tSize_" unchanged during FileAccessTimeout("_..FileAccessTimeout_") seconds (modified='"_pModified_"')")
						Set tComplete=1
						Quit
					} Else {
						#; try rename
						Set tPartLen=$L($E($P(pFilename,"."),1,12))  Set:tPartLen<8 tPartLen=8
						Set tNewFilename=$E($TR("X"_$ZH_"000000","."),1,tPartLen)_"."_$P(pFilename,".",2,999)
						Set tOK=..rename(pFilename,tNewFilename,pFileDir)
						If tOK {
							Set tOK=..rename(tNewFilename,pFilename,pFileDir)
							If tOK {
								$$$sysTRACE("Confirmed complete "_pFilename_" via rename to "_tNewFilename_"; renaming back again")
								Set tNewFilename=pFilename
								Set tComplete=1
								Quit
							}
						}
						#; If 'tOK
						Do ..disconnectOnNetErr(,1)
						If tNow>=tSizeTargTime || '..Connected {
							Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to confirm complete "_pFilename_"("_tStream.Size_") listed as size "_tSize_" by renaming to "_tNewFilename_" within FileAccessTimeout("_..FileAccessTimeout_") : FTP code "_..FTP.ReturnCode_" - "_..FTP.ReturnMessage)
							Quit
						} Else {
							$$$sysTRACE("Got "_pFilename_"("_tStream.Size_") listed as size "_tSize_" but can't rename it yet : FTP code "_..FTP.ReturnCode_" - "_..FTP.ReturnMessage_"; trying for more data")
						}
					}
				}
			} ; else tSize
			#; don't retry more often than every ..FileAccessTimeout seconds
			Set tWaitTime=tSizeTargTime-tNow  Set:tWaitTime<0 tWaitTime=0
			Set tSC1=##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,tWaitTime,,0)  Quit:$$$ISERR(tSC1)
			If ##class(Ens.Job).ShouldBeQuiescent() || ##class(Ens.Job).ShouldTerminate() {
				$$$LOGWARNING("Abandoning partial download of "_pFilename_" because of shutdown request")
				Quit
			}
			Set tWaitTime=tSizeTargTime-$ZH  Hang:tWaitTime>0 tWaitTime ; finish the delay in case DeQueue() returned early
			Set:tNewSize>tSize||(..ConfirmComplete\2#2) tSizeTargTime="" ; restart the clock
			Set:""'=tNewSize tOldSize=tSize, tSize=tNewSize ; re-base the size
			Set tFirst=0
		} ; end chunk loop

		If tComplete {
			#;If saving as a file, 0 size  and never been written to we need to force creation with an empty Write
			If tSaveAsFile,(tStream.Size=0),tStream.%IsNull() {Set tSC=tStream.Write() Quit:$$$ISERR(tSC)}
			Set tTxt="Retrieved file '"_pFilename_"' of size "_tStream.Size_" (modified='"_pModified_"')"_$S(tSaveAsFile:", archived as file '"_tStream.Filename_"'",1:"")
			If ..%logTransfers { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) }
			Set tStream.Attributes("Filename")=pFilename, tStream.Attributes("FTPDir")=pFileDir
			If tSaveAsFile { Set tSC1=tStream.SaveStream() If $$$ISERR(tSC1) $$$LOGERROR("Failed to save retrieved file '"_pFilename_"' of size "_tStream.Size_" to archive file '"_tStream.Filename_"'; Status: "_$$$StatusDisplayString(tSC1)) }
			Set tSC = ..BusinessHost.ProcessInput(tStream) Quit:$$$ISERR(tSC)
			Kill tStream
			Set pDone=1
			#; Delete Files is enabled
			If ((..DeleteFromServer)&&('fileOverwrittenDuringSizeCheck)) {
				Set deferDelete=0
				Do {
					#; Situated within "do" as may need to evaluate "deferDelete" after call
					Quit:'..isDeleteStillNeeded(pFilename,pFileDir,pModified,2,.deferDelete,1)
					#; Attempt 1. Delete the file, and remove the file from do-not-process list if it is deleted
					$$$UnitTestCoverageHooks(if $D(^ahang("deleteFirst")) {)
					$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: Before Hang MOD FILE First Delete"))
					$$$UnitTestCoverageHooks(	H ^ahang("deleteFirst"))
					$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: After Hang MOD FILE First Delete"))
					$$$UnitTestCoverageHooks(})
					If ..delete(tNewFilename,pFileDir) {
						Set pDone=-1  // Tested UT:2
						$$$sysTRACE("Deleted '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' from FTP server after successful processing")
					} Else {
						#; If the connection timed out during processing
						#; Don't wait for next cycle. Reconnect and allow following delete to succeed
						Do ..disconnectOnNetErr(,1)  // Required if skipping optional size check. Do not remove.
						if ..Connected {  // UT:5C
							#; Fail permamnetly. For example File access may be readonly or have incorrect permissions to support delete
							$$$LOGWARNING("Failed to delete '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' from FTP server after successful processing. Check readwrite access and file permissions. - "_..FTP.ReturnCode_":"_..FTP.ReturnMessage)
							Quit
						}
						$$$sysTRACE("Delete failed due to network. In Retry Delete")
						Do ..Connect(..ConnectTimeout,1)  // Required if skipping optional size check. Do not remove.
						Quit:'..isDeleteStillNeeded(pFilename,pFileDir,pModified,2,.deferDelete,1)

						If '..Connected {
							#; still no connectivity. Tested UT:5A
							Set deferDelete=1
						} Else { 
							$$$sysTRACE("Reconnect Succeeded prior to Delete of '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' after successful processing")
							
							$$$UnitTestCoverageHooks(if $D(^ahang("deleteRetry")) {)
							$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: Before Hang MOD FILE Retry Delete"))
							$$$UnitTestCoverageHooks(	H ^ahang("deleteRetry"))
							$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: After Hang MOD FILE Retry Delete"))
							$$$UnitTestCoverageHooks(})
							#; Attempt 2. Delete the file, and remove the file from do-not-process list if it is deleted
							If ..delete(tNewFilename,pFileDir) {
								Set pDone=-1  // Tested UT:4
								$$$sysTRACE("Deleted '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' from FTP server after successful processing")
							} Else {
								Do ..disconnectOnNetErr(,1)
								If '..Connected {
									Set deferDelete=1  // Tested UT:5B
								} Else {
									#; Fail permamnetly. For example File access may be readonly or have incorrect permissions to support delete
									$$$LOGWARNING("Failed to delete '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' from FTP server after successful processing. Check readwrite access and file permissions. - "_..FTP.ReturnCode_":"_..FTP.ReturnMessage)
								}
							}
						}
					}
				} while 0
				If deferDelete {  // Tested UT:5A, UT:5B, UT:14, UT:15
					#;  Cache the current modified datetime for later deferred delete check
					#;  pTableKey added as new parameter. Guarded use incase of customer subclassing
					Set:""'=$G(pTableKey) $$$QueueDeleteFileTable(pTableKey)=$LB(pFileDir,tNewFilename,pModified)
					$$$sysTRACE("Reconnect Failed. Defer Delete of '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' from FTP server after successful processing")
				}
			} Else {
				// Tested UT:5C
				$$$sysTRACE("Not Deleting '"_pFilename_$S(pFilename=tNewFilename:"",1:"' / '"_tNewFilename)_"' from FTP server after successful processing")
			}
		}
	} While 0
	Quit tSC
}

Method delete(pFilename As %String, pFileDir As %String) As %Boolean
{
	Set tSC=..setFilePath(pFileDir,.tOldDir)  If $$$ISERR(tSC) { $$$LOGSTATUS(tSC)  Quit 0 }
	Set tOK=$S(..%isSFTP:..FTP.DeleteSSH(pFilename),1:..FTP.Delete(pFilename))
	Do:'tOK ..disconnectOnNetErr(,1)
	If ..Connected { Set tSC=..restoreFilePath(tOldDir)  If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Quit 0 }
	Quit tOK
}

Method rename(pFilename As %String, pNewFilename As %String, pFileDir As %String) As %Boolean
{
	Set tSC=..setFilePath(pFileDir,.tOldDir)  If $$$ISERR(tSC) { $$$LOGSTATUS(tSC)  Quit 0 }
	Set tOK=$S(..%isSFTP:..FTP.RenameSSH(pFilename,pNewFilename),1:..FTP.Rename(pFilename,pNewFilename))
	Do:'tOK ..disconnectOnNetErr(,1)
	If ..Connected { Set tSC=..restoreFilePath(tOldDir)  If $$$ISERR(tSC) $$$LOGSTATUS(tSC)  Quit 0 }
	Quit tOK
}

Method retrieveFile(pFilename As %String, pStream As %AbstractStream, pFileDir As %String, pRetry As %Boolean) As %Status
{
	Set tSC=..setFilePath(pFileDir,.tOldDir)  Quit:$$$ISERR(tSC) tSC
	Set tOK=$S(pRetry:..FTP.RetryRetrieve(pFilename,pStream),1:..FTP.Retrieve(pFilename,pStream))
	If 'tOK {
		Set tSC=$$$ERROR($$$EnsErrFTPGetFailed,pFilename_$S(pRetry:"+"_pStream.Size,1:""),..FTP.ReturnMessage,..FTP.ReturnCode)
		Do ..disconnectOnNetErr(,1)
	}
	If ..Connected { Set tSC1=..restoreFilePath(tOldDir)  If $$$ISERR(tSC1) $$$LOGSTATUS(tSC1) }
	Quit tSC
}

/// Returning an empty string indicates failure to obtain a size. 
Method getSize(pFilename As %String, pFileDir As %String, ByRef pModified As %String, pNoWarn As %Boolean = 0) As %Integer [ Internal ]
{
	Set tSC=$$$OK, $ZT="Trap"
	If '..Connected Set tSC=..Connect(..ConnectTimeout,1)
	Quit:$$$ISERR(tSC) ""

	Set tSC=..setFilePath(pFileDir,.tOldDir)  If $$$ISERR(tSC) { $$$LOGSTATUS(tSC)  Quit "" }
	Set rSize="" Do {
		If ..%isSFTP {
			Set tSC=..FTP.getFileInfo(pFilename,.info)
			If $$$ISERR(tSC) {
				$$$LOGWARNING("SFTP getSize GetFileInfo failed for "_pFilename_" : "_..FTP.ReturnCode_" - "_..FTP.ReturnMessage)
				Do ..disconnectOnNetErr(tSC,1)
				Quit
			}
			Set rSize=$LG(info,2), pModified=$LG(info,8)
			Quit
		}
		If '..FTP.List(..FileSpec,..FileSizeStream) {
			$$$LOGWARNING("FTP getSize List failed for "_..FileSpec_" : "_..FTP.ReturnCode_" - "_..FTP.ReturnMessage)
			Do ..disconnectOnNetErr(,1)
			Quit
		}
		// Add a simplistic check to ensure we are using the correct line terminator for the stream.
		// 1000 characters should be sufficient to work out which terminator is in use.
		If ..FileSizeStream.Size {
			Set tSizePeek = ..FileSizeStream.Read(1000)
			Do ..FileSizeStream.Rewind()
			Set tSizeTerm = $select(tSizePeek [ $c(13,10): $c(13,10), tSizePeek [ $c(10): $c(10), tSizePeek [ $c(13): $c(13), 1: $c(13,10))
			Set ..FileSizeStream.LineTerminator = tSizeTerm
		}
		Set tNextLine=""
		For {
			If $L(tNextLine) {
				Set tName=tNextLine, tLen=$L(tNextLine), tNextLine=""
			} Else {
				Kill tLen  Set tName=..FileSizeStream.ReadLine(.tLen)
				Quit:tLen=-1
			}
			#; If VMS server, check lookahead buffer for possible multi-line directory listing
			If ..%isVMS {
				#; A line starting with a space denotes continuation of the previous line in the listing
				For {
					Kill tLen1 Set tNextLine=..FileSizeStream.ReadLine(.tLen1)
					Quit:$E(tNextLine)'=" "
					Set tName=tName_tNextLine, tLen=tLen+tLen1, tNextLine=""
				}
				$$$sysTRACE("got full VMS List() line '"_tName_"' and NextLine buffer = '"_tNextLine_"'")
				If "Directory "=$E(tName,1,$L("Directory ")) Continue
				If ("Total of "=$E(tName,1,$L("Total of ")))&&(tNextLine = "")&&..FileSizeStream.AtEnd {
					$$$sysTRACE("Ignoring VMS List() line '"_tName_"' as VMS summary line")
					Continue
				}
			}
			Continue:tLen<40
			Set tOK=..ParseFilename(.tName,.pModified,.tSize,.tIsDir)
			Continue:'tOK||tIsDir||(pFilename'=tName)
			Set rSize=tSize
			Quit
		}
		Quit:pFilename=tName
		;# Suppress Warning when for example deferred delete, where a file is already removed by other FTP Server process
		if 'pNoWarn $$$LOGWARNING("Failed to get "_..FileSpec_" size : "_..FTP.ReturnCode_" - "_..FTP.ReturnMessage)
	} While 0
	If ..Connected { Set tSC=..restoreFilePath(tOldDir)  If $$$ISERR(tSC) $$$LOGSTATUS(tSC) }
	Quit rSize
Trap
	Set $ZT="", tErrText=$ZE  Do ..disconnectOnNetErr(tErrText,1)
	$$$LOGWARNING("Exception getting "_..FileSpec_" size : "_tErrText)
	Quit ""
}

// Skip the first 'col' space delimited columns of 's' and return everything after 

ClassMethod TakeFromCol(s, col)
{
   for i=1:1:col-1
   {
      set s=$zstrip(s,"<W")
      set s=$piece(s," ",2,*)
   }

   return $zstrip(s,"<W")
}

Method ParseFilename(pFilenameLine As %String, Output pTimestamp As %String, Output pSize As %String, Output pIsDir As %String) As %Boolean [ Internal ]
{
	New %line,%ts,%fn,%dir,%sz
	Set %line=pFilenameLine
	X "Set %dir="_..IsDirExpression
	X "Set %ts="_..TimestampExpression
	X "Set %fn="_..FilenameExpression
	X "Set %sz="_..SizeExpression
	Set pTimestamp=$TR($ZSTrip(%ts,"<>W")," "_$C(9),"__"), pFilenameLine=$ZSTrip(%fn,"<>W"), pSize=$ZSTrip(%sz,"<>W"), pIsDir=$ZSTrip(%dir,"<>W")
	$$$catTRACE("connwait","Parsed IsDir="_%dir_", filename '"_pFilenameLine_"', size '"_pSize_"' and timestamp '"_pTimestamp_"' from line '"_%line_"'")
	Quit (pFilenameLine'="")
}

Method getArchiveFilename(pFTPFilename As %String) As %String [ CodeMode = expression, Internal ]
{
##class(Ens.Util.File).CreateTimestamp(##class(%File).GetFilename(pFTPFilename),$Case(..AppendTimestamp,"":"%f",0:"%f",1:"%f_%Q%!+(_a)",:..AppendTimestamp),,..ArchivePath)
}

/// Checks whether a file should still be deleted based on testing for changed modified datetime of file on FTP Server
/// Recursive check to cater for disconnect via Retry parameter
Method isDeleteStillNeeded(pFilename As %String, pFileDir As %String, pModifiedTimeAtDownload As %String, checkLevel As %Integer, ByRef defer As %Boolean, retry = 0) As %Boolean
{
#define UnitTestCoverageHooks(%val)
	$$$sysTRACE("isDeleteStillNeeded called pModifiedTimeAtDownload:"_pModifiedTimeAtDownload_" and retry:"_retry)
	Quit:(..CheckModifiedBeforeDelete<checkLevel) 1  // No modified check to prevent delete. ie: 0 == Never Check. Just Delete
	Quit:1'=..ConfirmComplete 1  // No modified check to prevent delete. Not using File Size to Confirm completion when Renaming
	// COVERAGE START
	$$$UnitTestCoverageHooks(if $D(^ahang("isDeleteStillNeeded",checkLevel)) {)
	$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: Before Hang MOD FILE checkLevel"_ $Case(checkLevel,2:"Always",1:"Defer",:"Never")))
	$$$UnitTestCoverageHooks(	H ^ahang("isDeleteStillNeeded",checkLevel))
	$$$UnitTestCoverageHooks(	$$$sysTRACE("isDeleteStillNeeded: After Hang MOD FILE checkLevel "_ $Case(checkLevel,2:"Always",1:"Defer",:"Never")))
	$$$UnitTestCoverageHooks(})
	// COVERAGE END
	$$$sysTRACE("isDeleteStillNeeded: Call getSize on pFilename:"_pFilename)
	Set tSize=..getSize(pFilename,pFileDir,.newModified,1)
	If tSize="" {
		$$$sysTRACE("isDeleteStillNeeded: Call getSize failed")
		do ..disconnectOnNetErr(,1)
		if '..Connected {
			$$$sysTRACE("isDeleteStillNeeded: Not connected")  // Tested UT:7.1 (retry call), UT:8.1 (defer)
			if retry>0 { // Tested UT:8.1
				// Disconnect can come from long processing if this is the next command to run
				Quit ..isDeleteStillNeeded(pFilename, pFileDir, pModifiedTimeAtDownload,checkLevel,.defer, retry-1)
			}
			$$$sysTRACE("isDeleteStillNeeded: Not connected. use defer instead")
			set defer=1 // Defer Delete Tested UT:8.1
			Quit 0
		} 
		// Error caused by something other than network for example file was already deleted. Tested UT:9
		$$$sysTRACE("isDeleteStillNeeded: No Delete. Failed due to other than network for example file was already deleted")  
		Quit 0
	} else {
		$$$sysTRACE("isDeleteStillNeeded: newModified"_newModified)
		if (pModifiedTimeAtDownload'=newModified) {  // Tested UT:10
			$$$sysTRACE("isDeleteStillNeeded: Remote File has changed since download and processing so don't delete")
			// Remote File has changed since download and processing so don't delete, and don't defer
			Quit 0
		} else {
			// File unchanged, so can delete.  Tested UT:6
			$$$sysTRACE("isDeleteStillNeeded: File unchanged, so can delete")
			Quit 1  
		}
	}
}

}
