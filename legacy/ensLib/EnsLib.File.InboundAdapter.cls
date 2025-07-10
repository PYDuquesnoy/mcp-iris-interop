/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Finds files in a FilePath directory and submits all that match a FileSpec wildcard to an associated BusinessService for processing
Class EnsLib.File.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.File.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Stream.Object";

/// Wildcard filename to look for; may be a semicolon-separated list of wildcards.
Property FileSpec As %String(MAXLEN = 400) [ InitialExpression = "*" ];

/// This is the Semaphore file specification to control when to process files found that match 'File Spec'.<br/>
/// The Default is empty which means process files when the Confirm Complete requirement is met.<br/>
/// If specified the files matching File Spec will not be processed until a corresponding semaphore file has been detected in the same directory.<br>
/// The semaphore sepcification can be a wildcard filename pairing of target=semaphore filename e.g. <br/>
/// ABC*.TXT=ABC*.SEM
/// which means do not process any files found that match ABC*.TXT unless a corresponding ABC*.SEM exists for each one. <br/>
/// <br/>
/// Multiple pairings are separated by ; <br/>
///  *.TXT=*.SEM;*.DAT=*.READY
/// <br/>
/// The target pattern is case sensitive and the semaphore pattern case sensitivity will be OS dependent<br/>
/// e.g. *.TXT=*.SEM will only be applied to target files found ending with capitalized .TXT but the OS may not differentiate between *.SEM and *.sem<br/>
/// <br/>
/// If a singleton is specified e.g. *.SEM or READY.SEM then that is taken as the semaphore pattern for all files. The following are equivalent:<br/>
/// *.SEM
/// *=*.SEM
/// <br/>
/// If no wildcard is used in the semaphore pattern then the semaphore pattern is taken as the file name and will be used for the one polling interval.<br/>
/// If such a semaphore file appears during the middle of a polling interval it will not be used until the start of polling interval.<br>
/// This is to prevent deletion of the semaphore file before all relevant files are processed.<br>
/// <br/>
/// If a semaphore pattern is specified and a file found based on File Spec does not have a semaphore pattern match then the file will not be processed unless an * is specified as the last semaphore pattern.<br/>
/// <br/>
/// The same semaphore check is carried out at all subdirectory levels. <br/>
/// </br/>
/// Confirm Complete setting is still applied but if a semaphore file is specified then you can consider changing Confirm Complete setting to None <br/>
/// <br/>
/// If a File Spec of * is specified along with a semaphore file then the semaphore file will not be processed by the Adapter as a target file but only as a semaphore file. <br/>
/// <br/>
/// Semaphore files are deleted after all target files found during the polling interval are processed and those target files are marked for deletion.<br/>
Property SemaphoreSpec As %String(MAXLEN = 400);

/// Path to move a file to after processing is completed. If not given, the file will be deleted after processing is completed
/// unless the setting DeleteFromServer is false and the WorkPath setting is the empty string.<p>
/// Note that the AppendTimestamp option must be used to avoid name collisions in the archive directory if the same filename will be retrieved repeatedly. 
Property ArchivePath As %String(MAXLEN = 1000);

/// Path to move a file to while it is being processed. If not given, the file will not move while in process.<p>
/// This setting is useful when the same filename is used for repeated file submissions. <p>
/// Note: This setting takes precedence over DeleteFromServer and the file is moved from the source directory to this directory if
/// DeleteFromServer is false. 
Property WorkPath As %String(MAXLEN = 1000);

/// Number of levels of subdirectory depth under the FilePath directory that should be searched for files matching the FileSpec pattern.
Property SubdirectoryLevels As %Integer(MINVAL = 0) [ InitialExpression = 0 ];

/// Append a timestamp to Archive and Working filenames in order to prevent possible name collisions on repeated processing of the same filename.<p>
/// If this value is empty or 0, no timestamp will be appended. If it is 1, then the standard timestamped filename specification template '%f_%Q' will be used.<p>
/// Any other value will be used directly as a timestamped filename specification template.
Property AppendTimestamp As %String [ InitialExpression = 1 ];

/// Special measures to confirm complete receipt of a file, in case it is still being written at the time we detect it in the FilePath directory.<p/>
/// - 'Size' means wait until the size reported for the file in the FilePath directory listing stops increasing.  <br/>
///          This option alone may not be sufficient when the source application is sluggish. If the OS reports the same 
///           size for the file for a duration of the FileAccessTimeout value then InterSystems IRIS will consider the file complete. <br/>
/// - 'Rename' means keep trying to read more data for a file until the OS allows us to rename it. 
///         If WorkPath or ArchivePath is different from FilePath, this option is implied because the file must be moved which is equivalent to renaming.
/// 			This option may not be effective because it is common for an OS to allow InterSystems IRIS to rename a file even while another application has the file open and is still writing more data into it.<br/>
/// - 'Readable' means if we consider the file complete if we are simply able to open it in Read mode. Depending on the OS and the details of the process that puts 
///             the file in the FilePath directory where we find it, this may be enough although in many cases it isn't. <br/>
/// - 'Writable' means if we consider the file complete if we are able to open it in Write mode (as a test - we generally don't intend to write to it.).  This may be enough depending on the OS and the details of the process that puts the file in the FilePath directory where we find it. <p/>
Property ConfirmComplete As %Integer(DISPLAYLIST = ",None,Size,Rename,Readable,Writable", VALUELIST = ",0,1,2,4,8") [ InitialExpression = "4" ];

/// Amount of idle time to wait before abandoning our attempt to confirm complete access to a file we've found (see the ConfirmComplete option)
Property FileAccessTimeout As %Integer [ InitialExpression = 2 ];

Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=File},FilePath:Basic:directorySelector,FileSpec:Basic,ArchivePath:Basic:directorySelector,WorkPath:Basic:directorySelector,SubdirectoryLevels,DeleteFromServer,Charset::selector?context={Ens.ContextSearch/CharacterSets},AppendTimestamp,ConfirmComplete,FileAccessTimeout,SemaphoreSpec";

/* override from Common superclass with new description (file coming in not going out) */
/// Path to directory to look for files in - may be prefixed with @MyAgent:
Property FilePath As %String(MAXLEN = 1000) [ Required ];

/* override from Common superclass with new description (file coming in not going out) */
/// Character encoding scheme used for translating input from files. For binary input, use 'Binary'.
/// Other choices include: <br/>
///  Native - the default character encoding of the installed locale of the InterSystems IRIS server <br/>
///  latin1 - the ISO Latin1 8-bit encoding <br/>
///  ISO-8859-1 - the ISO Latin1 8-bit encoding <br/>
///  UTF-8 - the Unicode 8-bit encoding <br/>
///  Unicode - the Unicode 16-bit encoding  (Little-Endian) <br/>
///  UnicodeBig - the Unicode 16-bit encoding (Big-Endian) <br/>
///  @&lt;ttable&gt; - &lt;ttable&gt; means a raw InterSystems character translation table name. A prefix of '@' means to use the named table.
Property Charset As %String [ InitialExpression = "Native" ];

/// Specifies whether or not to delete files from the local file server after successful processing <p>
/// If not deleted, the adapter will ignore files already processed until something else deletes them. <p>
/// Note 1: If this setting is false an attempt will be made to delete file when the IRIS message is purged.<br>
/// Note 2: If a WorkPath is specified this setting is ignored and the file is moved to the work path. <br>
Property DeleteFromServer As %Boolean [ InitialExpression = 1 ];

/// ResultSet carried over to multiple OnTask() calls if multiple rows found
Property %CurrResultSet As %ResultSet [ Internal ];

Property %isVMS As %Boolean [ Internal ];

Property VMSLatestVersionOnly As %Boolean [ InitialExpression = 1 ];

Method OnInit() As %Status
{
	Do ..testPaths(1)
	Set ..%CurrResultSet=##class(%ResultSet).%New($$$CurrentClass_":DeepList")  $$$ASSERT($IsObject(..%CurrResultSet))
	Kill ..%CurrResultSet.Data
	Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.file") ; clean up on restart
	Set:$$$isVMS&&("*"=..FileSpec) ..FileSpec="*.*" ; force functional wildcard for $zSearch on VMS
	If 0=..BusinessHost.%GetParameter("LOGTRANSFERS") Set ..%logTransfers=0
	Set ..%isVMS=$$$isVMS
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
	Quit $$$OK
}

Method testPaths(pOnInit As %Boolean = 1) As %Status
{
	#;Only need to check FilePath in OnInit since %FileSet query will check and return error.
	If pOnInit,("@"'=$E(..FilePath)),'##class(%File).DirectoryExists(..FilePath) {
		$$$LOGWARNING($$$StatusText($$$ERROR($$$DirectoryNotExist,..FilePath)))
	}
	If (""'=..WorkPath),(..WorkPath'=..FilePath),'##class(%File).DirectoryExists(..WorkPath) {
		Set tSC=$$$ERROR($$$DirectoryNotExist,..WorkPath)
		If 'pOnInit Quit tSC
		$$$LOGWARNING($$$StatusText(tSC))
	}
	If (""'=..ArchivePath),(..ArchivePath'=..FilePath),(..ArchivePath'=..WorkPath),'##class(%File).DirectoryExists(..ArchivePath) {
		Set tSC=$$$ERROR($$$DirectoryNotExist,..ArchivePath)
		If 'pOnInit Quit tSC
		$$$LOGWARNING($$$StatusText(tSC))
	}
	Quit $$$OK
}

Method OnTask() As %Status
{
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

	If ("@"=$E(..FilePath)) {
		#; Dequeue from Agent proxy
		Set tQueueName=$$$getConfigQueueName(..BusinessHost.%ConfigName,"")
		Set tSC = ##class(Ens.Queue).DeQueue(tQueueName,.tHeaderIn,0,.tIsTimedOut,1)  Quit:$$$ISERR(tSC) tSC
		Quit:tIsTimedOut tSC
		Quit:'$IsObject(tHeaderIn) tSC
		Do tHeaderIn.SetStatus($$$eMessageStatusDelivered)
		Set (..BusinessHost.%SessionId,$$$JobSessionId) = tHeaderIn.SessionId

		try {
			If ""'=tHeaderIn.MessageBodyClassName && $classmethod(tHeaderIn.MessageBodyClassName,"%Extends","Ens.StreamContainer") {
				Set tMsgIn = $classmethod(tHeaderIn.MessageBodyClassName,"%OpenId",tHeaderIn.MessageBodyId,,.tSC)
				If '$IsObject(tMsgIn) {
					Set tSC=$$$ERROR($$$EnsErrGeneral,"Could not open MessageBody "_tHeaderIn.MessageBodyId_" for MessageHeader #"_tHeaderIn.%Id()_" with body class "_tHeaderIn.MessageBodyClassName_":"_$$$StatusDisplayString(tSC))
				}
			} Else {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Only Ens.StreamContainer message bodies are accepted on the agent queue; found message body of class "_tHeaderIn.MessageBodyClassName_" for MessageHeader #"_tHeaderIn.%Id())
			}
		} catch {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Only Ens.StreamContainer message bodies are accepted on the agent queue; error testing message body for MessageHeader #"_tHeaderIn.%Id()_": "_$ZE)
		}
		If $$$ISERR(tSC) {
			Do tHeaderIn.SetStatus($$$eMessageStatusDiscarded)
		} Else {
			Set tAgent=tHeaderIn.Description
			$$$sysTRACE("Processing stream '"_tMsgIn.OriginalFilename_"' from agent '"_tAgent_"' via proxy '"_tHeaderIn.SourceConfigName_"'")
			Set tPS=..BusinessHost.%PreserveSession, ..BusinessHost.%PreserveSession=1
			Set tSC=..BusinessHost.ProcessInput(tMsgIn.Stream)
			Set ..BusinessHost.%PreserveSession=tPS

			#; archive or delete the file, and remove the file from do-not-process list if successful
			If ""'=..ArchivePath&&$$$ISOK(tSC) {
				Set tArchiveFilename = ..getArchiveFilename(tMsgIn.OriginalFilename)
				Set tArchiveStream=##class(%Library.FileBinaryStream).%New()
				Set tSC=tArchiveStream.FilenameSet(tArchiveFilename)
				Set:$$$ISOK(tSC) tSC=tArchiveStream.CopyFrom(tMsgIn.Stream)
				If $$$ISOK(tSC) {
					$$$sysTRACE("Saved stream from agent '"_tAgent_"' via proxy '"_tHeaderIn.SourceConfigName_"' to Archive file '"_tArchiveFilename_"'")
				} Else {
					If ##class(%File).Exists(tArchiveFilename) {
						$$$LOGERROR("Can't archive '"_tMsgIn.OriginalFilename_"' from agent '"_tAgent_"' because Archive file '"_tArchiveFilename_"' already exists: "_$$$StatusDisplayString(tSC))
					} Else {
						$$$LOGERROR("Failed to move '"_tMsgIn.OriginalFilename_"' from agent '"_tAgent_"' to Archive file '"_tArchiveFilename_"': "_$$$StatusDisplayString(tSC))
					}
				}
			}
			If $$$ISERR(tSC) {
				Do tHeaderIn.SetStatus($$$eMessageStatusError)
			} Else {
				Do tHeaderIn.SetStatus($$$eMessageStatusCompleted)
			}
		}
		Kill $$$EnsActiveMessage($$$SystemName_":"_$Job)
		If $$$ISERR(tSC) {
			$$$LOGSTATUS(tSC)
		}
		Quit $$$OK
	}
#define ErrorFileTable(%tk) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.file",%tk)
#define DoneFileTable(%tk)  $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.file",%tk)

	#; Normal non-Agent file service handling
	Set $ZT="Trap", tSC=$$$OK, (tOneFilename,tFilename,tLockFilename,tTableKey,tSemaphorename)="", tDone=0
	Do {
		Quit:(""=..FilePath)||(""=..FileSpec)
		If '$D(..%CurrResultSet.Data) {
			#; get file list
			$$$catTRACE("connwait","Looking for files '"_..FileSpec_"' in path '"_..FilePath_"'")
			Set tSC=..%CurrResultSet.Execute($this,..FilePath,..FileSpec,..SubdirectoryLevels,,..SemaphoreSpec)  Quit:$$$ISERR(tSC)
			Kill ^||Ens.FileInbound.Found,^||Ens.FileInbound.Semaphore
		}
		#; find the next one that can be processed
		For {
			If '..%CurrResultSet.Next(.tSC) {
				#; Done iterating the ResultSet for the current query execution - clean it up
				Do ..%CurrResultSet.Close()
				Kill ..%CurrResultSet.Data ; clean it out so next loop iteration will re-Execute the query
				#; Remove errored files from the Error global if they no longer exist, and remove processed files from the Done global if they no longer exist
				Quit:$$$ISERR(tSC) ; if the list failed we don't know if the files are still there
				Set tk="" For  Set tk=$O($$$DoneFileTable(tk)) Quit:tk=""   If ""=$G(^||Ens.FileInbound.Found(tk)) $$$sysTRACE("Removed absent file keyed as '"_tk_"' from processed list")  Kill $$$DoneFileTable(tk)
				Set tk="" For  Set tk=$O($$$ErrorFileTable(tk)) Quit:tk=""  If ""=$G(^||Ens.FileInbound.Found(tk)) If ""'=$G($$$ErrorFileTable(tk)) { $$$sysTRACE("Removed absent file keyed as '"_tk_"' from errored list") } If $D($$$DoneFileTable(tk)) { Set $$$ErrorFileTable(tk)="" } Else { Kill $$$ErrorFileTable(tk) }
				#; delete the semaphore files.
				Set tTableKey=$O(^||Ens.FileInbound.Semaphore(""),1,tSemaphorename)
				While tTableKey'="",..DeleteFromServer {
					If ##Class(%File).Delete(tSemaphorename) {
						$$$sysTRACE("Deleted semaphore '"_tSemaphorename_"' after successful processing")
					} Else {
						$$$LOGERROR("Failed to delete semaphore '"_tSemaphorename_"' after successful processing")
					}
					Set tTableKey=$O(^||Ens.FileInbound.Semaphore(tTableKey),1,tSemaphorename)
				}
				Quit
			}
			Set tOneFilename=..%CurrResultSet.Data("Name"), tModified=..%CurrResultSet.Data("DateModified"), tSize=..%CurrResultSet.Data("Size"), tSemaphorename=..%CurrResultSet.Data("SemaphoreName")  $$$ASSERT(""'=tOneFilename)
			Set tTableKey=..getFileSubscript(tOneFilename)
			Set ^||Ens.FileInbound.Found(tTableKey)=tOneFilename
			#;Record semaphore files for deletion. Hash to avoid subscript error from long filename and path
			If tSemaphorename'="" Set ^||Ens.FileInbound.Semaphore($system.Encryption.SHA1Hash(tSemaphorename))=tSemaphorename
			Lock +$$$ErrorFileTable(tTableKey):0 Else  $$$LOGINFO("Skipping locked file key '"_tTableKey_"' for file '"_tOneFilename_"'") Continue
			#; Skip the files we have already processed except if they are modified; if they errored only warn once
			If $G($$$DoneFileTable(tTableKey))=tModified If '$G(^(tTableKey,"done"_$E($G($$$ErrorFileTable(tTableKey)),-1))) { Set ^("done")=1 $$$LOGINFO("Skipping previously processed file '"_tOneFilename_"'") } Lock -$$$ErrorFileTable(tTableKey)  Continue
			If $G($$$ErrorFileTable(tTableKey))=tModified If $G(^(tTableKey,"wrn")) { Kill ^("wrn") $$$LOGWARNING("Skipping previously errored file '"_tOneFilename_"' with timestamp '"_tModified_"'") } Lock -$$$ErrorFileTable(tTableKey)  Continue
			If ..VMSLatestVersionOnly && ..%isVMS && ('..IsVMSLatestVersion(.tOneFilename)) {
				If '$G(^(tTableKey,"ver"_$E($G($$$ErrorFileTable(tTableKey)),-1))) { Set ^("ver")=1  $$$sysTRACE("Skipping not-latest version of file '"_tOneFilename_"'") }
				Lock -$$$ErrorFileTable(tTableKey)  Continue
			}
			Set $$$ErrorFileTable(tTableKey)=tModified, ^(tTableKey,"wrn")=1
			Set tFilename=tOneFilename, tOneFilename=""
			Quit ; found a good one
		}
		Quit:""=tFilename
		$$$sysTRACE("About to process file '"_tFilename_"' (size '"_tSize_"') with timestamp '"_tModified_"', ConfirmComplete="_..ConfirmComplete)
		Set tLockFilename=tFilename
		Set tSC=..processFile(.tLockFilename,tModified,tSize,.tDone,tTableKey,tSemaphorename)  Quit:$$$ISERR(tSC)
		#; mark the file as done if not renamed, whether or not we tried
		Set:tDone>0 $$$DoneFileTable(tTableKey)=tModified
	} While 0
	If $$$ISOK(tSC) {
		#;If Directory invalid or testPaths() failed previously but in this cycle were successful
		If (..BusinessHost.%LastReportedError [ "ERROR #5007")||(..BusinessHost.%LastReportedError [ "ERROR #5021") {
			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}
	}
Exit
	If tDone&&(""'=tLockFilename) {
		If tDone=-1&&..VMSLatestVersionOnly&&..%isVMS {
			#; If renamed on VMS but other VMS versions of the file may exist, suppress messages about them
			Set $$$ErrorFileTable(tTableKey)=""
		} Else {
			Kill $$$ErrorFileTable(tTableKey)
		}
	}
	Lock:""'=tLockFilename -$$$ErrorFileTable(tTableKey)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Lock:""'=tOneFilename -$$$ErrorFileTable(tTableKey)
	Goto Exit
}

Method processFile(ByRef pFilename As %String, pModified As %String, pSize As %String, Output pDone As %Boolean, pTableKey As %String, pSemaphorename As %String = "") As %Status [ Internal ]
{
#define ErrorFileTable(%tk) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"adapter.file",%tk)
	Set (tComplete,pDone,tEverSize)=0, (tSize,tNewSize,tOldSize)=pSize, tSizeTargTime="", tSC=$$$OK, tKeepFilename=pFilename, tFirst = 1
	Do {
		Set tTimeoutStart = $ZH, tTimeElapsed=0
		If ""'=..WorkPath&&(..WorkPath'=..FilePath) {
			Set tWorkFilename = ..getWorkFilename(pFilename)
		} Else {
			Set tWorkFilename = pFilename
		}
		If (pSemaphorename'="") $$$sysTRACE("Got semaphore file "_pSemaphorename_" for "_pFilename)
		#; Open the file (loop waiting for it to become accessible / complete)
		Set doRename=..ConfirmComplete\2#2 || (tWorkFilename'=pFilename)
		Set doReadable=..ConfirmComplete\4#2
		Set doWritable=..ConfirmComplete\8#2
		For { ; loop checking size / availability
			Set:..ConfirmComplete&&(""=tSizeTargTime) tSizeTargTime = $ZH+..FileAccessTimeout
			Set tNewFilename=pFilename, tNewSize=$S(+tSize'=tSize||'(..ConfirmComplete#2):tSize, 1:##class(%File).GetFileSize(pFilename))
			If +tSize'=tSize && (..ConfirmComplete#2) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Unable to verify ConfirmComplete=Size size because initial SizeExpression result = '"_tSize_"'")
				Quit
			} ElseIf tNewSize>tOldSize {
				Set tNow=$ZH
				$$$sysTRACE("Got partial "_pFilename_" that was listed as size "_tSize_" and now shows "_tNewSize)
			} ElseIf tNewSize<tSize && (tNewSize'="") {
				#; Assume we got the old file and this is a new copy of the file we should process later
				$$$sysTRACE("Accepting "_pFilename_" that was listed as size "_tSize_" and now shows "_tNewSize)
				Set tComplete=1
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
						Set tSC=$$$ERROR($$$EnsErrGeneral,"Could not get "_$S(tEverSize:"",1:"any ")_"size for "_pFilename_" ConfirmComplete=Size verification within FileAccessTimeout("_..FileAccessTimeout_")")
						Quit
					}
					If '(..ConfirmComplete\2#8 || (tWorkFilename'=pFilename)) {
						#; not trying rename or open test
						Set tComplete=1
						Quit
					} Else {
						If doRename {
							#; try rename
							If tWorkFilename '= pFilename {
								// Rename file with date etc. (loop waiting for it to become accessible)
								If ##class(%File).Rename(pFilename,tWorkFilename) {
									$$$sysTRACE("Confirmed complete "_pFilename_" via rename to "_tWorkFilename)
									#; Release the file right away now that we've moved it
									If ..VMSLatestVersionOnly&&..%isVMS {
										#; If renamed on VMS but other VMS versions of the file may exist, suppress messages about them
										Set $$$ErrorFileTable(pTableKey)=""
									} Else {
										Kill $$$ErrorFileTable(pTableKey)
									}
									Lock -$$$ErrorFileTable(pTableKey)
									Set pFilename=""
									Set tComplete=1
									Quit
								} Else {
									If tNow>=tSizeTargTime {
										Set tSC=$$$ERROR($$$EnsErrGeneral,"Could not move '"_pFilename_"' to '"_tWorkFilename_"' within "_..FileAccessTimeout_" seconds")
										Quit
									} Else {
										$$$sysTRACE("Got "_pFilename_" listed as size "_tSize_" but can't rename it yet; trying for more data")
									}
								}
							} Else { ; tWorkFilename = pFilename
								Set tPartLen=$L($E($P(pFilename,"."),1,12))  Set:tPartLen<8 tPartLen=8
								Set tNewFilename=$E($TR("X"_$ZH_"000000","."),1,tPartLen)_"."_$P(pFilename,".",2,999)
								If ##class(%File).Rename(pFilename,tNewFilename) {
									$$$sysTRACE("Confirmed complete "_pFilename_" via rename to "_tNewFilename_"; renaming back again")
									Set:##class(%File).Rename(tNewFilename,pFilename) tNewFilename=pFilename
									Set tComplete=1
									Quit
								} Else {
									If tNow>=tSizeTargTime {
										Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to confirm complete "_pFilename_" listed as size "_tSize_" by renaming to "_tNewFilename_" within FileAccessTimeout("_..FileAccessTimeout_")")
										Quit
									} Else {
										$$$sysTRACE("Got "_pFilename_" listed as size "_tSize_" but can't rename it yet; trying for more data for "_(tSizeTargTime-tNow)_" more seconds")
									}
								}
							}
						}
						If doWritable||doReadable {
							#; try open
							Set tF = ##class(%File).%New(tWorkFilename) $$$ASSERT($IsObject(tF))
							Set tSC = tF.Open($S(doWritable:"W",1:"R"))
							Kill tF ; We were just testing...
							If $$$ISOK(tSC) {
								$$$sysTRACE("Confirmed complete "_pFilename_" via open for "_$S(doWritable:"Write",1:"Read"))
								Set tComplete=1
								Quit
							} Else {
								If tNow>=tSizeTargTime {
									Set tSC=$$$ERROR($$$EnsErrGeneral,"Failed to confirm complete "_pFilename_" listed as size "_tSize_" by opening for "_$S(doWritable:"Write",1:"Read")_" within FileAccessTimeout("_..FileAccessTimeout_")")
									Quit
								} Else {
									$$$sysTRACE("Got "_pFilename_" listed as size "_tSize_" but can't open it for "_$S(doWritable:"Write",1:"Read")_" yet; trying for more data for "_(tSizeTargTime-tNow)_" more seconds")
								}
							}
						}
					}
				}
			} ; else tSize

			#; don't retry more often than every ..FileAccessTimeout seconds
			Set tWaitTime=tSizeTargTime-tNow  Set:tWaitTime<0 tWaitTime=0

			Set tSC1=##class(Ens.Queue).DeQueue("SystemSignal:"_$Job,,tWaitTime,,0)  Quit:$$$ISERR(tSC1)
			If ##class(Ens.Job).ShouldBeQuiescent() || ##class(Ens.Job).ShouldTerminate() {
				$$$LOGWARNING("Abandoning wait to confirm complete "_pFilename_" because of shutdown request")
				Quit
			}
			Set tWaitTime=tSizeTargTime-$ZH  Hang:tWaitTime>0 tWaitTime ; finish the delay in case DeQueue() returned early
			Set:tNewSize>tSize tSizeTargTime="" ; restart the clock
			Set:""'=tNewSize tOldSize=tSize,tSize=tNewSize ; re-base the size
			Set tFirst = 0
		} ; end loop

		If tComplete {
			#; Open Stream on file to pass to BusinessService
			If "binary"=$ZCVT(..Charset,"L") {
				Set tStream=##class(%FileBinaryStream).%New() $$$ASSERT($IsObject(tStream))
			} Else {
				Set tStream=##class(%FileCharacterStream).%New() $$$ASSERT($IsObject(tStream))
				Set:$Case($ZCVT(..Charset,"L"),"":0,"default":0,"native":0,:1) tStream.TranslateTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
			}
			Set tSC = tStream.LinkToFile(tWorkFilename)  Quit:$$$ISERR(tSC)
			Set tStream.Attributes("Filename")=tWorkFilename

			Set tSC=..BusinessHost.ProcessInput(tStream)  Quit:$$$ISERR(tSC)
			#; ensure file handle is released
			Kill tStream

			#; archive or delete the file, and remove the file from do-not-process list if successful
			Set pDone=$S(""=pFilename:-1,1:1)
			If ##class(%File).Exists(tWorkFilename) {
				If ""'=..ArchivePath&&(..ArchivePath'=..FilePath) {
					/*	Previously we compared tWorkFilename to ArchiveFilename
						but getWorkFilename will return a different value from getArchiveFilename
						if AppendTimestamp is false and the file contains characters such as [
						This is because getArchiveFilename always calls CreateTimestamp() which
						always removes the characters regarded as illegal - even though they might not be. 
					*/
					If ..WorkPath '= ..ArchivePath {
						Set tArchiveFilename = ..getArchiveFilename(tWorkFilename)
						Set tOK = ##class(%File).Rename(tWorkFilename,tArchiveFilename)
						If tOK {
							Set pDone=$S(tArchiveFilename'=tKeepFilename:-1,1:1)
							$$$sysTRACE("Moved '"_tWorkFilename_"' to Archive file '"_tArchiveFilename_"'")
						} Else {
							If ##class(%File).Exists(tArchiveFilename) {
								$$$LOGERROR("Can't move '"_tWorkFilename_"' because Archive file '"_tArchiveFilename_"' already exists")
							} Else {
								$$$LOGERROR("Failed to move '"_tWorkFilename_"' to Archive file '"_tArchiveFilename_"'")
							}
						}
					}
				} ElseIf ..DeleteFromServer {
					#; delete the file, and remove the file from do-not-process list if it is deleted
					If ##Class(%File).Delete(tWorkFilename) {
						Set pDone=-1
						$$$sysTRACE("Deleted '"_tWorkFilename_"' after successful processing")
					} Else {
						$$$LOGERROR("Failed to delete '"_tWorkFilename_"' after successful processing")
					}
				} Else {
					$$$sysTRACE("Not Deleting '"_tWorkFilename_"' after successful processing")
				}
			}
		}
	} While 0
	Quit tSC
}

/// If WorkFilename is the same, then we didn't timestamp it, so add timestamp here
Method getArchiveFilename(pWorkFilename As %String) As %String [ CodeMode = expression, Internal ]
{
..CreateTimestamp(##class(%File).GetFilename(pWorkFilename),$S(""'=..WorkPath&&(..WorkPath'=..FilePath):"%f",1:$Case(..AppendTimestamp,"":"%f",0:"%f",1:"%f_%Q%!+(_a)",:..AppendTimestamp)),,..ArchivePath)
}

Method getWorkFilename(pFilename As %String) As %String [ Internal ]
{
	Set tWorkFilename = ##class(%File).GetFilename(pFilename)
	Set tDirectory = $S(""'=..WorkPath:..WorkPath,1:##class(%File).GetDirectory(pFilename))
	If $Case(..AppendTimestamp,"":1,0:1,:0) {
		Set tWorkFilename=tDirectory_tWorkFilename
	} Else {
		Set tWorkFilename = ..CreateTimestamp(tWorkFilename,$Case(..AppendTimestamp,1:"%f_%Q%!+(_a)",:..AppendTimestamp),,tDirectory)
	}
	#; Guard against duplicate timestamps...
	While ##class(%File).Exists(tWorkFilename) {
		If "_"=$E(tWorkFilename,*-1) {
			Set c=$E(tWorkFilename,*)  Quit:$A(c)'<$A("z") ; allow collision if exhausted
			Do { Set c=$C($A(c)+1) } While ""=$ZStrip(c,"*E'A'N")
			Set $E(tWorkFilename,$L(tWorkFilename))=c
		} Else {
			Set tWorkFilename=tWorkFilename_"_1"
		}
	}
	Quit tWorkFilename
}

Method getFileSubscript(pFilename As %String) As %String [ Internal ]
{
	For i=0:1:100000 {
		Set tSubscript = $S($L(pFilename)<=230:pFilename, 1:$E(pFilename,1,220)_".x"_$$$NUM($ZHex($ZCRC($E(pFilename,221,*)_$S('i:"",1:i),7)),8))
		Quit:'$D(^||Ens.FileInbound.Found(tSubscript),fn)||(fn=pFilename)
	}
	Quit tSubscript
}

Method FilePathSet(pInVal As %String) As %Status [ Internal ]
{
	Set i%FilePath=..fixPath(pInVal)
	Quit $$$OK
}

Method ArchivePathSet(pInVal As %String) As %Status [ Internal ]
{
	Set i%ArchivePath=..fixPath(pInVal)
	Quit $$$OK
}

Method WorkPathSet(pInVal As %String) As %Status [ Internal ]
{
	Set i%WorkPath=..fixPath(pInVal)
	Quit $$$OK
}

Method IsVMSLatestVersion(pFilename As %String) As %Boolean
{
	Set tfn=$E(pFilename,1,$L($P(pFilename,";",1))), tFilenameVersion=$P(pFilename,";",2), tHighestVersion=0
	#; Check the local array of files found in this List() call context
	#; Optimised to $order over files with same name
	Set fn=""
	Set (tk,fileName)=$P($E(pFilename,1,220),";",1)
	For { Set tk=$O(^||Ens.FileInbound.Found(tk),1,fn)  Quit:(""=tk)||($P($E(tk,1,220),";")'=fileName)
		If tfn=$E(fn,1,$L($P(fn,";",1))) && (tHighestVersion<$P(fn,";",2)) Set tHighestVersion=$P(fn,";",2)
	}
	Quit tFilenameVersion>=tHighestVersion
}

}
