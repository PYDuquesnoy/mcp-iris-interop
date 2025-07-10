/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%mft, Ensemble)

/// Base class for MFT Adapters <CLASS>EnsLib.LDAP.Adapter.Inbound</CLASS>
/// and <CLASS>EnsLib.LDAP.Adapter.Outbound</CLASS>
Class EnsLib.MFT.Adapter.Common Extends Ens.Adapter [ ProcedureBlock, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Name of Managed File Transfer Connection to the file management service.<br>
/// The list of available Connection definitions will only be shown to users with
/// appropriate privilege (SQL select on table %SYS_MFT_Connection.Base).
Property MFTConnectionName As %String(MAXLEN = 64);

/// MFT Connection instance
Property MFTConnection As %SYS.MFT.Connection.Base;

/// Class Name of MFT API for the Service. <br>
/// This is calculated from the connection.
Property MFTAPIClass As %String(MAXLEN = 1000) [ Transient ];

/// Internal use to limit event log warnings
Property %lastMFTwarning As %String(MAXLEN = "") [ Internal, Transient ];

Method OnInit() As %Status
{
	#dim tSC = ..GetMFTConnection()
	If $$$ISERR(tSC) $$$LOGWARNING($$$StatusText(tSC))
	Quit ##super()
}

/// Obtains the MFT Connection and executes a test GetUser() call.
Method GetMFTConnection() As %Status
{

	#dim tSC = $$$OK
	#dim tSCCheck As %Status = $$$OK
	#dim tFolderInfo As %MFT.UserInfo = $$$NULLOREF

	Set ..MFTConnection = ""
	Set ..MFTAPIClass = ""

	Set ..MFTConnection = ##class(%MFT.API).GetConnection(..MFTConnectionName,.tSC)

	$$$sysTRACE("MFT API GetConnection: "_..MFTConnectionName_" "_$S(tSC=$$$OK:"OK",1:$$$StatusText(tSC)))
	
	If $$$ISOK(tSC) && $IsObject(..MFTConnection) {

		Set ..MFTAPIClass=$$$MFTAPIClassname(..MFTConnection)

		#; Now check if we can access root folder but do not use any data returned.
		Set tSCCheck = ..GetFolderInfo("/",.tFolderInfo)

		If tSCCheck = $$$OK || $SYSTEM.Status.Equals(tSCCheck,$$$NotImplemented) {

			Set ..BusinessHost.%LastReportedError=""
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")

			Set ..%lastMFTwarning = ""

		} Else {
	
			#; Reset tSC from $$$OK to reflect tSCCheck Error
			Set tSC = tSCCheck
			
			#; Clear connection since not believed to be good
			Set ..MFTConnection = ""
			Set ..MFTAPIClass = ""

		}

		$$$sysTRACE("MFT Connection Check: "_..MFTConnectionName_" "_$S(tSC=$$$OK:"OK ",1:$$$StatusText(tSC)))

	}

	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,$$$ISOK(tSC)_"|"_$$$timeUTC_"|"_..MFTConnectionName)

	Quit tSC
}

/// This method wraps the MFT system method UploadStream.<br>
/// The first parameter is the stream object to upload.<br>
/// The second parameter is the filename to write the stream to on the target.<br>
/// The third parameter indicates if the target filename ought to be overwritten.
/// (An MFT server may not overwrite but create multiple versions)<br>
/// The method returns the status from the MFT call.<br>
/// The method also returns in parameter pResponse the %MFT.ItemInfo response.<br>
/// Parameter pTriedReconnecting indicates if there was an error whether the error was a connection type error<br>
/// Parameter pReconnectedOnError indicates if it was a connection error if it was able to recover<br>
/// If there was a connection error and there was an error trying to reconnect both errors are included in the return status.<br>
Method UploadStream(pStream As %Stream.Object, pFilename As %String, pUploadIfSameFileOnServer As %Boolean = 0, Output pResponse As %MFT.ItemInfo, Output pTriedReconnecting As %Boolean = 0, Output pReconnectedOnError) As %Status
{
	#dim tSC As %Status = $$$OK

	Set pResponse = ##class(%MFT.ItemInfo).%New()

	$$$sysTRACE("MFT UploadStream: "_..MFTConnectionName_" "_pFilename_$S(pUploadIfSameFileOnServer:" with overwrite option. ",1:"")_ "Size="_pStream.Size)

	Set tSC = $classmethod($$$EnsCoreMFTAPIClass,"UploadStream",
							..MFTConnection,
							pStream,
							pFilename,
							pUploadIfSameFileOnServer,
							.pResponse)

	If $$$ISERR(tSC) {

		#dim tSCGetMFT = $$$OK
		Set tSCGetMFT = ..HandleMFTError(tSC, .pTriedReconnecting, .pReconnectedOnError)
		If $$$ISERR(tSCGetMFT) Set tSC = $$$ADDSC(tSC,tSCGetMFT)
	}

	Quit tSC
}

/// Call to MFT GetFolderContents using current connection <br>
/// If pFolderId is not defined then pFolder is used for the target folder specification. <br>
/// If pFolderId is defined and not empty then it is used for the target folder specification. <br>
/// If pFolderId is defined as empty then API calls will be made to find the ID of pFolder and 
/// pFolderId will be updated, used as the target folder specification and passed back by reference to the caller. <br>
/// If pIncludeSubFolders is true and pFolderId is used then it is possible that the Container property for
/// file items found will be empty and it is recommended to call this method with pFolderId undefined if Container property is required.<br>
Method GetFolderContents(pFolder As %String, pIncludeSubFolders As %Boolean = 0, Output pFolderContents As %MFT.FolderContents, ByRef pFolderId As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException

	#dim tFolderToUse As %String = pFolder

	#dim tFolderInfo As %MFT.ItemInfo

	Try {

		/*	Find the efficient folder ID to use if passed in empty string for pFolderId
			If  pFolderId was passed in not empty that is used as it is copied to tFolderToUse
			
				GetFolderInfo
				GetRequestId
		*/
		If $Data(pFolderId,tFolderToUse)#2 && (tFolderToUse="") {

			Set tSC = ..GetFolderInfo(pFolder, .tFolderInfo)
			If $$$ISERR(tSC) Quit

			Set tFolderToUse = ..GetRequestId(tFolderInfo)

			#; Assume non empty return to be used and pass back
			If tFolderToUse '= "" {

				Set pFolderId = tFolderToUse

			} Else {

				#; Reset to what is passed in as first parameter - empty string is allowed.
				Set tFolderToUse = pFolder

			}

		}

		Set tSC = $classmethod($$$EnsCoreMFTAPIClass,"GetFolderContents",
											..MFTConnection,
											tFolderToUse,
											pIncludeSubFolders,
											.pFolderContents)

	} Catch ex {

		Set tSC = ex.AsStatus()

	}

	Quit tSC
}

/// Call to MFT GetFolderInfo using current connection
Method GetFolderInfo(pFolder As %String, Output pItemInfo As %MFT.ItemInfo) As %Status
{
	#dim tSC As %Status = $$$OK

	Set tSC = $classmethod($$$EnsCoreMFTAPIClass,"GetFolderInfo",
										..MFTConnection,
										pFolder,
										.pItemInfo)

	Quit tSC
}

/// Call to MFT GetRequestId using current connection
Method GetRequestId(pItemInfo As %MFT.ItemInfo) As %String
{
	Quit $classmethod($$$EnsCoreMFTAPIClass,"GetRequestId",
										..MFTConnection,
										pItemInfo)
}

/// Call to MFT Download Stream using current connection
Method DownloadStream(pFileId As %String, ByRef pItemStream As %BinaryStream) As %Status
{
	#dim tSC As %Status = $$$OK

	Set tSC = $classmethod($$$EnsCoreMFTAPIClass,"DownloadStream",
										..MFTConnection,
										pFileId,
										.pItemStream)

	Quit tSC
}

/// Call to MFT GetUsername using current connection
Method GetUsername(pModifiedBy As %String, Output pMFTUsername As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK

	Set tSC = $classmethod($$$EnsCoreMFTAPIClass,"GetUsername",
										..MFTConnection,
										pModifiedBy,
										.pMFTUsername)

	Quit tSC
}

/// Call to MFT DeleteFile using current connection
Method DeleteFile(pFileId As %String, pPermanent As %Boolean = 0) As %Status
{
	#dim tSC As %Status = $$$OK

	Set tSC = $classmethod($$$EnsCoreMFTAPIClass,"DeleteFile",..MFTConnection,pFileId,pPermanent)

	/*	Trap for NotImplemented if permanent delete requested and
		advise need to change settings to non permanent
	*/
	If $$$ISERR(tSC) && pPermanent && ($SYSTEM.Status.Equals(tSC,$$$NotImplemented)) {
		Set tSC = $$$ADDSC($$$GeneralError,"Permanent Delete not supported by remote MFT server. Change setting 'DeleteFromServer'.")
	}

	Quit tSC
}

/// This method is used to identify if the MFT method error was a connection issue that 
/// can be recovered by reconnecting and tries the reconnection.<br>
/// The first parameter is the MFT Status to be examined.<br>
/// The second parameter indicates if tried reconnecting.<br>
/// The third parameter is output indicating if it recovered the connection.<br> 
Method HandleMFTError(pMFTStatus As %Status, Output pTriedReconnecting As %Boolean = 0, Output pReconnectedOnError As %Boolean = 0) As %Status
{
	#dim tSCGetMFT = $$$OK

	If $$$ISERR(pMFTStatus) {

		#dim tMFTStatusText = $SYSTEM.Status.GetErrorText(pMFTStatus)
		#dim tHTTPResponseStatusCode = ""
		#dim tWarning

		If $IsObject(..MFTConnection) && $IsObject(..MFTConnection.HttpRequest) && $IsObject(..MFTConnection.HttpRequest.HttpResponse) {

			Try {Set tHTTPResponseStatusCode = ..MFTConnection.HttpRequest.HttpResponse.StatusCode} Catch {}

		}

		$$$sysTRACE("MFT Handling Error: "_..MFTConnectionName_" HTTP ResponseStatusCode: '"_tHTTPResponseStatusCode_"'. Error text: "_tMFTStatusText)

		If $SYSTEM.Status.Equals(pMFTStatus,$$$ObjectScriptError) {

			Set pTriedReconnecting = (tMFTStatusText["<WRITE>") ||
										(tMFTStatusText["<READ>") ||
										(tMFTStatusText["<NOTOPEN>") ||
										(tMFTStatusText["<INVALID OREF>")

		} ElseIf $SYSTEM.Status.Equals(pMFTStatus,$$$MFTBadConnection,
											$$$HttpRequestConnect) {

			Set pTriedReconnecting = 1

		} ElseIf $SYSTEM.Status.Equals(pMFTStatus,$$$OAuth2NoAccessToken) {

			Set tWarning = $$$Text("No Access Token. Requires action in  System > Security Management > Managed File Transfer Connections")
			If ..%lastMFTwarning '= tWarning {
				$$$LOGWARNING(tWarning)
				Set ..%lastMFTwarning = tWarning
			}

		} ElseIf tHTTPResponseStatusCode= "400" {

			Set pTriedReconnecting = 1

		} ElseIf (tHTTPResponseStatusCode= "401") || (tHTTPResponseStatusCode= "403") {

			Set tWarning = $$$Text("Unauthorized access. Check System > Security Management > Managed File Transfer Connections")
			If ..%lastMFTwarning '= tWarning {
				$$$LOGWARNING(tWarning)
				Set ..%lastMFTwarning = tWarning
			}

		}

		If pTriedReconnecting {

			#;Attempt reconnect
			Set tSCGetMFT = ..GetMFTConnection()
			If $$$ISOK(tSCGetMFT) {

				Set pReconnectedOnError = 1

			}

		}

		$$$sysTRACE("MFT Handled Error: "_..MFTConnectionName_"/"_$S(pMFTStatus=$$$OK:"OK",1:$$$StatusText(pMFTStatus))_"/"_pTriedReconnecting_"/"_pReconnectedOnError_"/"_$S(tSCGetMFT=$$$OK:"OK",1:$$$StatusText(tSCGetMFT)))

	}

	Quit tSCGetMFT
}

}
