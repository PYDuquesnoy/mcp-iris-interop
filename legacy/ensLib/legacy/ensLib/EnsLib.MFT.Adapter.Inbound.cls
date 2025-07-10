/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// MFT Inbound Adapter
Class EnsLib.MFT.Adapter.Inbound Extends (Ens.InboundAdapter, EnsLib.MFT.Adapter.Common) [ System = 4 ]
{

/// Name(s) of source MFT Folders to search in. <p>
/// The name can be one folder or a comma separated list of folders or an @ followed by the name of a Lookup Table.<p>
/// If @ is the first character and the remainder of the string identifies an existing Lookup Table then
/// the values for all rows in the Lookup Table are used as the MFT Source Folders.<br>
/// The drop down will list Lookup Tables preceded by a @ for those users with %Ens_LookupTables:READ privilege.<p>
/// If @ is the first character and the remainder of the string does not identify an existing Lookup Table then
/// the folder name will be taken to be the complete value of the setting including the @ - this is to
/// allow for the possibility that the MFT server supports folder names beginning with @ <br>
Property MFTSourceFolders As %String(MAXLEN = "") [ InitialExpression = "/" ];

/// This is the array of source folders to search in. It is generated from MFTSourceFolders.<br>
/// The first level subscript can be "Folder" followed by the folder to be searched and the value
/// is the actual folder string used by the API. For example it might be translated to an ID representation.<br>
/// The first level subscript can be "ID" followed by the ID of the folder and the value is the folder <br>
Property %mftFolders As %String [ Internal, MultiDimensional, Transient ];

/// This flag can be set to not download the stream - just the ItemInfo.<br>
Property DownloadItemInfoOnly As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "MFTConnectionName:Basic:mftconnectionSelector,MFTSourceFolders:Basic:lookuptableSelector,FilesToRetrieve:Basic,IncludeSubFolders:Basic,DeleteFromServer:Basic,FindModifiedByUsername:Basic,DownloadItemInfoOnly:Basic";

/// Specifies if we search through sub folders<br>
Property IncludeSubFolders As %Boolean [ InitialExpression = 0 ];

/// Specifies whether or not to delete files on the remote MFT server after successful processing. <br>
/// The three options are:<br><br>
/// <b>No</b> = Do not request any form of delete from the server but record locally that the file has been processed based on
/// file id, its container and modified date so that the file is not reprocessed.<br>
/// If the modified date changes the file will be processed again.<br>
/// Note - the local list of processed files will be amended based on the list found on the server.<br>
/// Files will be removed from the list if they are no longer found on the server and
/// it is possible for this list to keep growing. <br><br>
/// The functionality of the following 2 options may be implemented differently or not at all on the remote MFT server:<br><br> 
/// <b>Trash</b> = Request the MFT server to mark the remote file as deleted but recoverable by manual intervention.<br><br>
/// <b>Permanent</b> = Request the MFT server to permanently delete the file.<br><br>
/// The Default is No<br>
Property DeleteFromServer As %Integer(DISPLAYLIST = ",No,Trash,Permanent", VALUELIST = ",0,1,2") [ InitialExpression = 0 ];

/// Regular expression to match against file names to retrieve. <br>
/// Empty value is the default and means all files. <br>
/// An example of retrieving only files with
/// extension pdf or jpg case insensitive would be: <br>
/// (?i) .*\.pdf | .*\.jpg <br>
/// Where (?i) means case insensitive <br>
/// .* means any characters <br>
/// \. means a period <br>
/// pdf means ends with pdf <br>
/// | means OR  <br>
/// See documentation on Regular expressions for further information.
Property FilesToRetrieve As %String(MAXLEN = 1000);

/// Set this to true if a separate call is to be made for each download to find the
/// service's username that modified the document.<br>
Property FindModifiedByUsername As %Boolean [ InitialExpression = 0 ];

Method OnInit() As %Status
{
	#; Remove prior errored and failed match cached entries so can be retried.
	Kill $$$EnsRuntimeAppData(..BusinessHost.%ConfigName)

	#; Populate %mftFolders from MFTSourceFolders begin @
	#dim tSC = ..setMFTFolders()
	If $$$ISERR(tSC) Quit tSC

	If '$Data(..%mftFolders) {
		// Support empty string for root folder e.g. Drop Box can use "".
		Set ..%mftFolders("Folder",$LB("")) = ""
	}

	Quit ##class(EnsLib.MFT.Adapter.Common)$this.OnInit()
}

Method setMFTFolders() As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim iFolder As %Integer
	#dim tOneFolder As %String = ""
	#dim tSettingIsALookupTable = 0

	Try {

		Kill ..%mftFolders

		If $E(..MFTSourceFolders)="@" {

			#dim tProxyList As %ZEN.proxyObject
			Set tSC = ##class(EnsPortal.LookupSettings).GetLookupTableProxy($E(..MFTSourceFolders,2,*),.tProxyList)
			If $$$ISERR(tSC) Quit

			#; If Timestamp is empty then not a defined lookup table
			If tProxyList.Timestamp '= "" {

				For iFolder = 1:1:tProxyList.values.Count() {

					Set tOneFolder = tProxyList.values.GetAt(iFolder).value
					#; Ignore key. The value of the subscript being set might be updated in ProcessFolder()
					If tOneFolder '="" Set ..%mftFolders("Folder",tOneFolder) = ""

				}

				Set tSettingIsALookupTable = 1

			}

		}

		If 'tSettingIsALookupTable {

			For iFolder=1:1:$L(..MFTSourceFolders, ",") {

				Set tOneFolder = $ZStrip($Piece(..MFTSourceFolders,",",iFolder),"<>W")
				If tOneFolder '="" Set ..%mftFolders("Folder",tOneFolder) = ""

			}

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}
	Quit tSC
}

Method OnTask() As %Status
{
	#dim tSC = $$$OK
	#dim tSCGetMFT = $$$OK
	#dim ex As %Exception.AbstractException

	#; Set this to some text to be able to identify a clean run based on this being ""
	#dim tExitReason As %String = "OnTask starting...."
			
	Try{

		If '$IsObject(..MFTConnection) || (..MFTAPIClass="") {

			Set tSCGetMFT = ..GetMFTConnection()

			If $$$ISERR(tSCGetMFT) Quit

		}

		If $IsObject(..MFTConnection) && (..MFTAPIClass'="") {

			#dim iFolder As %Integer
			#dim tOneFolder As %String = ""
			#dim tFolderId As %String = ""

			/*	Local temp list of items seen for this poll.
				This is used if we do not delete the source file since we 
				are recording what files we have processed.
				We use this list to prune the local list of files processed and 
				we only use this list if we looked in all folders successfully.
			*/
			Kill $$$EnsMFTIDsSeen
			Set tExitReason = ""
			
			Set tOneFolder = $Order(..%mftFolders("Folder",""),1,tFolderId)

			While (tOneFolder '= "") {

				/*	Do not map to Folder Ids if doing recursive folder
					search since Container name will be missing.
					If not IncludeSubFolders we can use pFolder in ConstructRequestStream
					if Container property empty.
				*/
				If ..IncludeSubFolders {

					#; Since recursive don't try to get folder ids
					Kill tFolderId
					$$$sysTRACE("Processing MFT Folder: '"_tOneFolder_"'")

				} Else {

					#; Set to empty string if necessary and do not try to get the folder ID
					If (tOneFolder = $LB("")) {
						Set tOneFolder = ""
						Kill tFolderId
					}

					$$$sysTRACE("Processing MFT Folder: '"_tOneFolder_"' with cached id of '"_$Get(tFolderId)_"'")

				}

				Set tSC = ..ProcessFolder(tOneFolder, .tFolderId, .tExitReason)

				If tExitReason '= "" {

					If $$$ISERR(tSC) {

						#dim tWarning = $$$FormatText("Exiting processing folder list with Reason %1",tExitReason_" "_$$$StatusText(tSC))
						#; GetMFTConnection may have reset %lastMFTWarning to "" if reconnected based on HTTP error code and so may repeat warnings.
						If ..%lastMFTwarning '= tWarning {
							$$$LOGWARNING(tWarning)
							Set ..%lastMFTwarning = tWarning
						}

					} Else {

						$$$sysTRACE("Exiting processing folder list with Reason "_tExitReason)

					}

					Quit

				}

			Set tOneFolder = $Order(..%mftFolders("Folder",tOneFolder),1,tFolderId)

			}

		}

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	If $$$ISERR(tSC) {

		#dim tTriedReconnecting, tReconnectedOnError As %Boolean = 0
		Set tSCGetMFT = ..HandleMFTError(tSC, .tTriedReconnecting, .tReconnectedOnError)
		If $$$ISERR(tSCGetMFT) {

			Set tSC = $$$ADDSC(tSC,tSCGetMFT)

		} Else {
			
			#; Return success if we reconnected. Error could happen on any of the MFT methods.
			If tTriedReconnecting && tReconnectedOnError Set tSC = $$$OK
		}

	} Else {

		#; If error at the start trying to reconnect then return that status
		If $$$ISERR(tSCGetMFT) Set tSC = tSCGetMFT

	}

	/*	We only clean up duplicate prevention tables if:
			we had no errors
			and we saw at least one file as a further safeguard.
	*/
	If $$$ISOK(tSC) && (tExitReason = "") {

		If $Data($$$EnsMFTIDsSeen) Do ..cleanDuplicatePreventionTables()

		#; Reset status to OK if we had a successful poll and no messages. Don't wait for new data
		If ..BusinessHost.%LastReportedError'="" {
			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}

	}

	#; Remove temp table of items seen in this poll.
	Kill $$$EnsMFTIDsSeen

	Quit tSC
}

/// For a given folder on an MFT server process the contents.<br>
/// pFolderId is passed by reference since may not be defined.<br>
/// If pFolderIs is passed in as the empty string then it can be changed in this method to the ID of pFolder
/// and this folder id will be used in the request. <br>
Method ProcessFolder(pFolder As %String, ByRef pFolderId As %String, Output pExitReason As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tPostProcessStatus As %Status = $$$OK

	#dim ex As %Exception.AbstractException

	#dim tFolderContents As %MFT.FolderContents
	#dim tItemCounter As %Integer = 0
	#dim tCurrentItemInfo As %MFT.ItemInfo
	#dim tItemStream As %Stream.Object = $$$NULLOREF
	#dim tFileId As %String
	#dim tCachedFolderId As %String = ""

	#dim tNotProcessingReason As %String

	/*
		MFT methods called:
			GetFolderContents
			DownloadStream
			GetUsername (optional)
			DeleteFile (optional)
	*/

	Try {

			Set tSC = ..GetFolderContents(pFolder,
											..IncludeSubFolders,
											.tFolderContents,
											.pFolderId)

			If $$$ISERR(tSC) {

				Set pExitReason = "GetFolderContents Error"
				Quit

			}

			/*	Cache pFolderId if used to save next call to GetFolderContents
				having to make extra call.
			*/
			If ($Get(pFolderId) '= "") && ($Data(..%mftFolders("Folder",pFolder),tCachedFolderId)#2)  && (tCachedFolderId '= pFolderId) {

				Set ..%mftFolders("Folder",pFolder) = pFolderId
				Set ..%mftFolders("ID",pFolderId) = pFolder
				$$$sysTRACE("Caching MFT server Folder Id '"_pFolderId_"' to use in place of Folder string '"_pFolder_"'")

			}

			For tItemCounter=1:1:tFolderContents.Contents.Count() {

				Set tCurrentItemInfo = tFolderContents.Contents.GetAt(tItemCounter)

				If ..CheckIfProcessItem(tCurrentItemInfo, .tSC, .tNotProcessingReason) = 0 {

					If $$$ISERR(tSC) {
						Set pExitReason = "Error in checking if item ought to be processed."
						#; Stop all further processing
						Quit
					}

					$$$sysTRACE("Not Processing ID="_tCurrentItemInfo.ItemId_", Name="_tCurrentItemInfo.Name_", Reason="_tNotProcessingReason)

					Continue

				}

				Set tFileId = ..GetRequestId(tCurrentItemInfo)

				If '..DownloadItemInfoOnly {

					#; If error Downloading then return directly to caller
					Set tSC = ..DownloadStream(tFileId, .tItemStream)

					$$$sysTRACE("DownloadStream ID="_tCurrentItemInfo.ItemId_", Name="_tCurrentItemInfo.Name_" "_$S(tSC:"OK",1:$$$StatusText(tSC)))

					If $$$ISERR(tSC) {

						#; Stop all further processing
						Set pExitReason = "DownloadStream Error"
						Quit

					}

				}

				#dim tMFTStreamObject As Ens.MFT.StreamContainer

				Set tSC = ..ConstructStreamRequest(tCurrentItemInfo, tItemStream, pFolder, .tMFTStreamObject)

				$$$sysTRACE("ConstructStreamRequest ID="_tCurrentItemInfo.ItemId_", Name="_tCurrentItemInfo.Name_" "_$S(tSC:"OK",1:$$$StatusText(tSC)))

				If $$$ISERR(tSC) {

					#; Stop all further processing
					Set pExitReason = "Construct Stream Request Error"
					Quit

				}

				#;Force New Session each item and give to Business Service
				Set ..BusinessHost.%SessionId = ""
				Set tSC = ..BusinessHost.ProcessInput(tMFTStreamObject)

				Set tPostProcessStatus =  ..PostProcess(tSC, tFileId, tCurrentItemInfo)
				If $$$ISERR(tPostProcessStatus) {
				
					#; Stop all further processing
					Set pExitReason = "Post ProcessInput Error"
					Set tSC = $$$ADDSC(tSC,tPostProcessStatus)
					Quit

				} ElseIf $$$ISERR(tSC) {
				
					#; Stop all further processing
					Set pExitReason = "ProcessInput Error"
					Quit

				}

				#; Return from OnTask if ought to quiesce
				If (tItemCounter '= tFolderContents.Contents.Count()) && 
								(##class(Ens.Job).ShouldBeQuiescent() || 
								##class(Ens.Job).ShouldTerminate()) {

								Set pExitReason = "System Quiesce Request"
								Quit

				}

			}

	} Catch ex {

		Set pExitReason = "Unexpected SYSTEM error"
		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

/// This method is used to check if the item ought to be processed/downloaded.<br>
/// It checks if the item is a file, has not been processed before and matches the file pattern regular expression.
Method CheckIfProcessItem(pItemInfo As %MFT.ItemInfo, Output pSC As %Status = {$$$OK}, Output pNotProcessReason As %String = "") As %Boolean [ Internal ]
{
	#dim ex As %Exception.AbstractException

	#dim tProcessItem As %Boolean = 1

	#dim tFileId As %String = ..GetRequestId(pItemInfo)

	#dim tprodItemIdentifier = ..prodItemIdentifier(pItemInfo)

	#; Needed to clean up done/error/failedMatch tables
	Set $$$EnsMFTIDsSeen(tprodItemIdentifier) = ""

	#; Need to account for Pool Size > 1
	Lock +$$$EnsMFTErrorFileTable(tprodItemIdentifier):0
	If '$Test {

		$$$LOGINFO("Skipping file due to locked file key ID="_pItemInfo.ItemId_", Name="_pItemInfo.Name_"( Adapter key "_$system.Encryption.Base64Encode(tprodItemIdentifier)_" )")
		Set tProcessItem = 0

		Quit tProcessItem

	}


	$$$sysTRACE("Processing Item ID="_pItemInfo.ItemId_", Name="_pItemInfo.Name_"( Adapter key "_$system.Encryption.Base64Encode(tprodItemIdentifier)_" )")

	Try {

		If pItemInfo.Type '= $$$MFTfile {

			Set pNotProcessReason = "Not a file"
			Set tProcessItem = 0

		} ElseIf $Get($$$EnsMFTDoneFileTable(tprodItemIdentifier))=pItemInfo.Modified {

			Set pNotProcessReason = "Already Marked as Done"
			Set tProcessItem = 0

		} ElseIf $Get($$$EnsMFTErrorFileTable(tprodItemIdentifier))=pItemInfo.Modified {

			Set pNotProcessReason = "Already Marked as Errored"
			Set tProcessItem = 0

			If $Data($$$EnsMFTErrorFileTable(tprodItemIdentifier,"wrn"))#2 {

				Kill $$$EnsMFTErrorFileTable(tprodItemIdentifier,"wrn")
				$$$LOGWARNING("Skipping previously errored file ID="_pItemInfo.ItemId_", Name="_pItemInfo.Name_", Modified By="_pItemInfo.Modified)

			}

		} ElseIf ..FilesToRetrieve'="" {

			If $Get($$$EnsMFTFailedMatchTable(tprodItemIdentifier)) = pItemInfo.Name {

				Set pNotProcessReason = "Already Marked as failing name pattern match"
				Set tProcessItem = 0

			} Else {

				#; If error in regex match then return directly from Try/Catch to caller
				Try {

					If '$MATCH(pItemInfo.Name,..FilesToRetrieve) {

						Set $$$EnsMFTFailedMatchTable(tprodItemIdentifier) = pItemInfo.Name

						Set pNotProcessReason = "Failed name pattern match"
						Set tProcessItem = 0

					}

				 } Catch ex {

				 	If ex.Name = "<REGULAR EXPRESSION>" {

				 		$$$LOGERROR("Invalid Regular expression entered for FilesToRetrieve Setting: "_..FilesToRetrieve)
				 		Set pSC = ##class(%Regex.Matcher).LastStatus()

				 	} Else {

				 		Set pSC = ex.AsStatus()

				 	}

					Set pNotProcessReason = "Failed name pattern match with error "_$$$StatusText(tSC)
				 	Set tProcessItem = 0

				 }

			}

		}

	} Catch ex {

		Set pNotProcessReason = "Caught System Error"
		Set pSC = ex.AsStatus()
		Set tProcessItem = 0

	}

	Lock -$$$EnsMFTErrorFileTable(tprodItemIdentifier)

	Quit tProcessItem
}

/// This takes the downloaded stream and constructs the MFT Stream request object for the business services.<br>
Method ConstructStreamRequest(pItemInfo As %MFT.ItemInfo, pItemStream As %Stream.Object, pFolder As %String = "", Output pMFTStreamObject As Ens.MFT.StreamContainer) As %Status [ Internal ]
{

	#dim tSC As %Status = $$$OK

	Set pMFTStreamObject = ##class(Ens.MFT.StreamContainer).%New(pItemStream)
	Set pMFTStreamObject.ItemInfo = pItemInfo
	Set pMFTStreamObject.OriginalFilename = pItemInfo.Name

	/*	When Getting folder contents using the Folder Id the Container property
		might be empty.
		We can use the folder name if not searching sub folders (recursive folder search)
	*/
	If (pMFTStreamObject.ItemInfo.Container = "") && '..IncludeSubFolders {

		Set pMFTStreamObject.ItemInfo.Container = pFolder

	}

	If ..FindModifiedByUsername {

		#dim tMFTUsername = ""
		Set tSC = ..GetUsername(pItemInfo.ModifiedBy, .tMFTUsername)

		If $$$ISOK(tSC) {

			Set pMFTStreamObject.ModifiedByUsername = tMFTUsername

		} Else {

			If '$Data($$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"mft","warnusername"))#2 {

				Set $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,"mft","warnusername") = pItemInfo.ModifiedBy
				$$$LOGWARNING("Failed to identify MFT Modified By Username")

			}

		}

	}

	Quit tSC
}

/// This handles ensuring the item is not processed again.<br>
/// Either by deleting if the DeleteFromServer setting is enabled or by
/// setting in global table.<br>
/// Files marked as errored are regarded as temporarily errored and can be processed again later when the item is restarted.<br>
Method PostProcess(pProcessInputStatus As %Status, pFileId As %String, pItemInfo As %MFT.ItemInfo) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	If $$$ISOK(pProcessInputStatus) {

		If ..DeleteFromServer {

			Set tSC = ..DeleteFile(pFileId,(..DeleteFromServer=2) /* 2=Permanent Delete request */)

			If $$$ISERR(tSC) {

				Set $$$EnsMFTDoneFileTable(..prodItemIdentifier((pItemInfo))) = pItemInfo.Modified
				$$$LOGWARNING("Failed to Delete MFT File: "_pFileId_" Marking as Done. "_$$$StatusText(tSC))

			}

		} Else {

			Set $$$EnsMFTDoneFileTable(..prodItemIdentifier((pItemInfo))) = pItemInfo.Modified

		}

	} Else {

		Set $$$EnsMFTErrorFileTable(..prodItemIdentifier((pItemInfo))) = pItemInfo.Modified
		Set $$$EnsMFTErrorFileTable(..prodItemIdentifier((pItemInfo)),"wrn") = ""
	}

	Quit tSC
}

/// Internal helper method to make subscript identifier by ConfigName, APIClass & File Id that can be used as a subscript
Method prodItemIdentifier(pItemInfo As %MFT.ItemInfo) As %String [ Internal ]
{
	#;The pItemInfo.Container might be empty if we ask for the file via id of the folder
	Quit $system.Encryption.SHA1Hash((..MFTAPIClass_pItemInfo.ItemId))
}

/// Internal helper method to manage duplicate tables
Method cleanDuplicatePreventionTables() [ Internal, Private ]
{

	#dim tk
	Set tk="" For  Set tk=$O($$$EnsMFTDoneFileTable(tk)) Quit:tk=""   If '$Data($$$EnsMFTIDsSeen(tk))#2 $$$sysTRACE("Removed absent file keyed as '"_$system.Encryption.Base64Encode(tk)_"' from processed list")  Kill $$$EnsMFTDoneFileTable(tk)

	Set tk="" For  Set tk=$O($$$EnsMFTErrorFileTable(tk)) Quit:tk=""  If '$Data($$$EnsMFTIDsSeen(tk))#2 $$$sysTRACE("Removed absent file keyed as '"_$system.Encryption.Base64Encode(tk)_"' from errored list") Kill $$$EnsMFTErrorFileTable(tk)

	Set tk="" For  Set tk=$O($$$EnsMFTFailedMatchTable(tk)) Quit:tk=""  If '$Data($$$EnsMFTIDsSeen(tk))#2 $$$sysTRACE("Removed absent file keyed as '"_$system.Encryption.Base64Encode(tk)_"' from failed match list") Kill $$$EnsMFTFailedMatchTable(tk)
}

}
