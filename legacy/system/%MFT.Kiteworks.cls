/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %mft

/// The %MFT.Kiteworks class is the subclass of %MFT.API which implements the APIs using Accellion Kiteworks.<br>
Class %MFT.Kiteworks Extends %MFT.API [ System = 4 ]
{

/// Get the form of id for a file or folder that is most efficient for subsequent calls.
/// GetRequestId will return either an id of the form "id:<id>" or a full path depending on which is more efficient.
/// This method is included to allow the id for future requests to be saved in the most efficient form.
ClassMethod GetRequestId(connection As %SYS.MFT.Connection.Kiteworks, itemInfo As %MFT.ItemInfo) As %String
{
	Quit "id:"_itemInfo.ItemId
}

/// Return the item info object which describes the specified folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the path to specify the current folder.
/// If a folder does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod GetFolderInfo(connection As %SYS.MFT.Connection.Kiteworks, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetFolderInfo]","path="_path)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// If a normal folder path is passed, then get info based on the path
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			
			// If file returned, then folder not found
			If $$$ISOK(sc),$isobject(itemInfo),itemInfo.Type'=$$$MFTfolder {
				Set itemInfo=""
			}

		} Else {
			// Get folder info based on the id.
			Set sc=connection.MakeRequest("GET","rest/folders/"_itemId,,.query,.response)
			If $$$ISERR(sc) {
				// Not finding an item is not an error.
				Set err=$system.Status.GetErrorText(sc)
				If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
					Set itemInfo=""
					Set sc=$$$OK
				}
			} Else {
				// Create the returned folder item info object.
				Set itemInfo=..CreateItemInfo(response)
			}

		}
		
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetFolderInfo]","MFT",sc)
	}
	Quit sc
}

/// Internal method to return the item info object which describes the specified file or folder.
/// "" May be used as the itemPath to specify the current folder.<br>
/// If an item does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".<br>
/// %MFT.Dropbox only supports the file's owner getting information about a file.
ClassMethod GetItemInfo(connection As %SYS.MFT.Connection.Kiteworks, itemPath As %String, Output itemInfo As %MFT.ItemInfo) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetItemInfo]","itemPath="_itemPath)
		Set itemInfo=""
		Set folder=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Remove / from the end of a path
		Set path=connection.NormalizePath(itemPath)
		If $extract(path,*)="/" {
			Set $extract(path,*)=""
			Set folder=1
		}
		If path="" {
			Set itemInfo=##class(%MFT.ItemInfo).%New()
			Set itemInfo.Container="/"
			Set itemInfo.Type=$$$MFTfolder
			Set itemInfo.ItemId=0
			Quit
		}

		// Request the metadata for this item.
		Set query("path")=path
		Set sc=connection.MakeRequest("GET","rest/search",,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set files=response.files
		Set folders=response.folders
		If '$isobject(files) || ($classname(files)'="%Library.DynamicArray") ||
		   '$isobject(folders) || ($classname(folders)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetItemInfo",text)
			Quit
		}

		// If duplicate file and folder name, then return error		
		Set filesSize=..GetEntry(files,.fileItem)
		Set foldersSize=..GetEntry(folders,.folderItem)
		If (filesSize+foldersSize)>1 {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetItemInfo",text)
			Quit
		}
	
		Set containerPath=$piece(path,"/",1,*-1)_"/"
		If filesSize=1 {
			// If folder requested, then make sure that a file was not found.
			If folder {
				Set sc=$$$ERROR($$$MFTFolderExpected,itemPath)
				Quit
			}
			// Create the returned file item info object.
			Set itemInfo=..CreateItemInfo(fileItem,containerPath)
		} ElseIf foldersSize=1 {
			// Create the returned folder item info object.
			Set itemInfo=..CreateItemInfo(folderItem,containerPath)
		} Else {
			// Not finding an item is not an error, just no item returned.
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetItemInfo]","MFT",sc)
	}
	Quit sc
}

/// Remove deleted items from array
ClassMethod GetEntry(entries As %DynamicArray, Output entry As %DynamicObject) As %Integer [ Internal ]
{
	Set entry=""
	Set size=0
	Set iterator=entries.%GetIterator()
	While iterator.%GetNext(.key,.item) {
		If 'item.deleted {
			Set size=size+1
			Set entry=item
		}
	}
	Quit size
}

/// Create an ItemInfo object from a Kiteworks response
ClassMethod CreateItemInfo(response As %DynamicObject, containerPath As %String = "") As %MFT.ItemInfo [ Internal ]
{
	// The item has been deleted.
	If response.deleted Quit ""

	// Build the ItemInfo object.
	Set itemInfo=##class(%MFT.ItemInfo).%New()
	If response.type="f" {
		Set itemInfo.Type=$$$MFTfile
	} ElseIf response.type="d" {
		Set itemInfo.Type=$$$MFTfolder
	} Else {
		// Unrecognized item
		Quit ""
	}

	Set itemInfo.Name=response.name
	Set itemInfo.Container=containerPath
	Set itemInfo.ItemId=response.id
	Set itemInfo.Details=response.%ToJSON()
	If response.modified'="" {
		Set itemInfo.Modified=$zdatetime($zdatetimeh(response.modified,3,5),3)
	}
	Set modifiedBy=response.lastModifiedBy
	If $isobject(modifiedBy) {
		Set itemInfo.ModifiedBy=$lb(modifiedBy.id,modifiedBy.email)
	} Else {
		Set itemInfo.ModifiedBy=response.userId
	}
	Quit itemInfo
}

/// Get the external username that corresponds to the specified internal user id.
ClassMethod GetUsername(connection As %SYS.MFT.Connection.Kiteworks, internalId As %String, Output username As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetUsername]","internalId="_internalId)
		Set username=""
		Set sc=$$$OK

		// First check if it is our internal list format
		Try {
			Set username=$list(internalId,2)
		} Catch {
		}
		
		// If the id was in Box native format, then need to ask Box
		If username="" {
			Set sc=..GetUserById(connection,internalId,.userInfo)
			If $$$ISOK(sc),$isobject(userInfo) Set username=userInfo.Username
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetUsername]","MFT",sc)
	}
	Quit sc
}

/// Delete the remote folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// If permanent is true, then the folder will be permanently deleted. Otherwise the folder will be moved to trash.<br>
/// If the remote folder does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod DeleteFolder(connection As %SYS.MFT.Connection.Kiteworks, path As %String, permanent As %Boolean = 0) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:DeleteFolder]","path="_path)
		Set itemInfo=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Normalize path
			Set fullpath=connection.NormalizePath(path)
			If $extract(fullpath,*)="/" {
				Set $extract(fullpath,*)=""
			}
			If fullpath="" {
				Set sc=$$$ERROR($$$MFTRootDelete)
				Quit
			}

			// Find the item		
			Set sc=..GetItemInfo(connection,fullpath,.itemInfo)
			If $$$ISERR(sc) Quit
			
			// Not finding an item is not an error.
			If '$isobject(itemInfo) Quit
		
			Set itemId=itemInfo.ItemId
		}
		
		// Request that the item be deleted.
		Set sc=connection.MakeRequest("DELETE","rest/folders/"_itemId,,,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error.
			Set err=$system.Status.GetErrorText(sc)
			If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
				$$$SysLog(2,"MFT","[%MFT.Kiteworks:DeleteFolder]","err="_err)
				Set sc=$$$OK
			}
		}

		// If delete successful and permananet delete requested, delete the folder from trash.
		If $$$ISOK(sc),permanent {
			Set sc=connection.MakeRequest("DELETE","rest/folders/"_itemId_"/actions/permanent",,,.response)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:DeleteFolder]","MFT",sc)
	}
	Quit sc
}

/// Creates the remote folder at the specified folderPath.
/// Each level of the folder path should be created separately if it does not already exist.
/// An %MFT.ItemInfo object is returned for the new folder.
ClassMethod CreateFolder(connection As %SYS.MFT.Connection.Kiteworks, folderPath As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:CreateFolder]","folderPath="_folderPath)
		Set itemInfo=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Remove trailing / from folder name
		Set path=connection.NormalizePath(folderPath)
		If $extract(path,*)="/" {
			Set $extract(path,*)=""
		}
		Set folderName=$piece(path,"/",*)
		Set folderParent=$piece(path,"/",1,*-1)_"/"
		Set sc=..GetItemInfo(connection,folderParent,.parentItemInfo)
		If $$$ISERR(sc) Quit
		
		// Parent folder must exist
		If '$isobject(parentItemInfo) {
			Set sc=$$$ERROR($$$MFTFolderExpected,folderParent)
			Quit
		}

		// Request that the specified folder be created.
		Set request=##class(%DynamicObject).%New()
		Set request.name=folderName
		If folderParent="/" {
			Do request.%Set("syncable",1,"boolean")
		}
		Do request.%Set("expire",0,"number")
		Do request.%Set("fileLifetime",0,"number")
		Do request.%Set("secure",0,"boolean")
		Set query("returnEntity")="true"
		Set sc=connection.MakeRequest("POST","rest/folders/"_parentItemInfo.ItemId_"/folders",request,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If (response.name="") || (response.id="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"CreateFolder",text)
			Quit
		}
	
		// Create the returned item info object.
		Set itemInfo=..CreateItemInfo(response,folderParent)

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:CreateFolder]","MFT",sc)
	}
	Quit sc
}

/// Return the folder contents object for the specified folder.
/// folderPath may be a folder path.
/// folderPath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the folderPath to specify the current folder.
/// The FolderContents object will include a list of %MFT.ItemInfo objects which contain a file or folder name
/// and some additional simple information.
ClassMethod GetFolderContents(connection As %SYS.MFT.Connection.Kiteworks, folderPath As %String, recursive As %Boolean = 0, Output folderContents As %MFT.FolderContents) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetFolderContents]","folderPath="_folderPath_", recursive="_recursive)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set folderId=$$$MFTGetId(folderPath)
		If folderId="" {
			// Get the id for this folder.
			Set sc=..GetItemInfo(connection,folderPath,.itemInfo)
			If $$$ISERR(sc) Quit
			
			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,folderPath)
				Quit
			}
			Set folderId=itemInfo.ItemId
			Set path=itemInfo.GetPath()
		} Else {
			Set path=""
		}

		// Get contents of folder possibly recursing over children of the folder also.
		Set folderContents=##class(%MFT.FolderContents).%New()
		Set folderContents.Recursive=''recursive
		Set sc=..GetFolderContentsInternal(connection,folderId,path,recursive,folderContents)

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetFolderContents]","MFT",sc)
	}
	Quit sc
}

/// Internal method for recursing over subfolders to return the folder contents object for the specified folder.
ClassMethod GetFolderContentsInternal(connection As %SYS.MFT.Connection.Kiteworks, folderId As %String, path As %String, recursive As %Boolean = 0, folderContents As %MFT.FolderContents) As %Status [ Internal ]
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetFolderContentsInternal]","folderId="_folderId_", recursive="_recursive)

		// Request the folder contents.
		Set query("deleted")="false"
		If folderId=0 {
			Set parameters="rest/folders/top"
		} Else {
			Set query("with")="(lastModifiedBy)"
			Set parameters="rest/folders/"_folderId_"/children"
		}
		Set sc=connection.MakeRequest("GET",parameters,,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set entries=response.data
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetFolderContents",text)
			Quit
		}
		
		// Add the entries in this response to the list.
		Set iterator=entries.%GetIterator()
		While iterator.%GetNext(.key,.entry) {
			// Create the returned item info object for the folder child.
			Set itemInfo=..CreateItemInfo(entry,path)
			If itemInfo="" Continue
			Do folderContents.Contents.Insert(itemInfo)

			// If recorsive required, then add the children
			If recursive,itemInfo.Type=$$$MFTfolder {
				Set sc=..GetFolderContentsInternal(connection,itemInfo.ItemId,itemInfo.GetPath(),recursive,folderContents)
				If $$$ISERR(sc) Quit
			}
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetFolderContentsInternal]","MFT",sc)
	}
	Quit sc
}

/// Return the item info object which describes the specified file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// If a file does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod GetFileInfo(connection As %SYS.MFT.Connection.Kiteworks, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetFileInfo]","path="_path)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// If a normal file path is passed, then get info based on the path
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			
			// If folder returned, then file not found
			If $$$ISOK(sc),$isobject(itemInfo),itemInfo.Type'=$$$MFTfile {
				Set itemInfo=""
			}

		} Else {
			// Get file info based on the id.
			Set query("with")="(lastModifiedBy)"
			Set sc=connection.MakeRequest("GET","rest/files/"_itemId,,.query,.response)
			If $$$ISERR(sc) {
				// Not finding an item is not an error.
				Set err=$system.Status.GetErrorText(sc)
				If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
					Set itemInfo=""
					Set sc=$$$OK
				}
			} Else {
				// Create the returned file item info object.
				Set itemInfo=..CreateItemInfo(response)
			}

		}
		
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetFileInfo]","MFT",sc)
	}
	Quit sc
}

/// Delete the remote file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the file will be permanently deleted. Otherwise the file will be moved to trash.<br>
/// If the remote file does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod DeleteFile(connection As %SYS.MFT.Connection.Kiteworks, path As %String, permanent As %Boolean = 0) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:DeleteFile]","path="_path)
		Set itemInfo=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Normalize path
			Set fullpath=connection.NormalizePath(path)
			If $extract(fullpath,*)="/" {
				Set $extract(fullpath,*)=""
			}
			If fullpath="" {
				Set sc=$$$ERROR($$$MFTRootDelete)
				Quit
			}

			// Find the item		
			Set sc=..GetItemInfo(connection,fullpath,.itemInfo)
			If $$$ISERR(sc) Quit
			
			// Not finding an item is not an error.
			If '$isobject(itemInfo) Quit
		
			Set itemId=itemInfo.ItemId
		}
		
		// Request that the item be deleted.
		Set sc=connection.MakeRequest("DELETE","rest/files/"_itemId,,,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error.
			Set err=$system.Status.GetErrorText(sc)
			If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
				$$$SysLog(2,"MFT","[%MFT.Kiteworks:DeleteFile]","err="_err)
				Set sc=$$$OK
			}
		}
		
		// If delete successful and permananet delete requested, delete the file from trash.
		If $$$ISOK(sc),permanent {
			Set sc=connection.MakeRequest("DELETE","rest/files/"_itemId_"/actions/permanent",,,.response)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:DeleteFile]","MFT",sc)
	}
	Quit sc
}

/// Update the specified remote file with the contents of the specified local file.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.
ClassMethod UploadFile(connection As %SYS.MFT.Connection.Kiteworks, localFilePath As %String, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=localFilePath
	Quit ..UploadStream(.connection,stream,filePath,replace,.itemInfo)
}

/// Update the specified remote file with the contents of the specified stream.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.
ClassMethod UploadStream(connection As %SYS.MFT.Connection.Kiteworks, stream As %BinaryStream, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:Upload]","filePath="_filePath_", replace="_replace)
		Set itemInfo=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Normalize path and make sure a file is being uploaded, not a folder.
		Set path=connection.NormalizePath(filePath)
		If $extract(path,*)="/" {
			Set sc=$$$ERROR($$$MFTNoFolder)
			Quit
		}
		
		// If not able to replace, then first check for existence of file
		If 'replace {
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit
			If $isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFileExists,path)
				Quit
			}
		}
		
		// Find id of parent folder
		Set fileName=$piece(path,"/",*)
		Set folderName=$piece(path,"/",1,*-1)_"/"
		Set sc=..GetItemInfo(connection,folderName,.parentItemInfo)
		If $$$ISERR(sc) Quit

		If '$isobject(parentItemInfo) {
			Set sc=$$$ERROR($$$MFTFolderExpected,folderName)
			Quit
		}

		// Request the upload
		Set query("returnEntity")="true"
		Set sc=connection.MakeUploadRequest("rest/folders/"_parentItemInfo.ItemId_"/actions/file",fileName,.query,stream,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If response.name'=$piece(path,"/",*) {
			Set text=$extract(response.%ToJSON(),1,300)_"...."_path
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"Upload",text)
			Quit
		}
	
		// Create the returned item info object.
		Set itemInfo=..CreateItemInfo(response,folderName)

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:Upload]","MFT",sc)
	}
	Quit sc
}

/// Download the specified remote file and store at the location given by localFilePath.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod DownloadFile(connection As %SYS.MFT.Connection.Kiteworks, filePath As %String, localFilePath As %String) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=localFilePath
	Quit ..DownloadStream(.connection,filePath,stream)
}

/// Download the specified remote file and store in the specified stream which must be a %FileBinaryStream or a %GlobalBinaryStream.
/// If stream is not specified, then a %GlobalBinaryStream will be created.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod DownloadStream(connection As %SYS.MFT.Connection.Kiteworks, filePath As %String, ByRef stream As %BinaryStream) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:Download]","filePath="_filePath)
		Set itemInfo=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(filePath)
		If itemId="" {
			// Normalize the file path
			Set path=connection.NormalizePath(filePath)
			// Verify that the path refers to a file and get the id
			If $extract(path,*)="/" {
				Set sc=$$$ERROR($$$MFTNoFolder)
				Quit
			}

			Set sc=..GetItemInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit
			If '$isobject(itemInfo) || (itemInfo.Type'=$$$MFTfile) {
				Set sc=$$$ERROR($$$MFTFileNeeded,filePath)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Request the download
		If $get(stream)="" Set stream=##class(%GlobalBinaryStream).%New()
		Set sc=connection.MakeDownloadRequest("rest/files/"_itemId_"/content",stream,.response)
		If $$$ISERR(sc) {
			// Not found error
			Set err=$system.Status.GetErrorText(sc)
			If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
				Set sc=$$$ERROR($$$MFTFileNeeded,filePath)
				Quit
			}
		}

		// Save the stream.
		Set sc=stream.SaveStream()
	
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:Download]","MFT",sc)
	}
	Quit sc
}

/// Share a folder with a list of users pass as a $list.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// The "editor" and "viewer" access levels are supported for all vendors.
/// The defined Kiteworks roles are supported as access levels.
/// The editor access level becomes the Manager role and the viewer access level becomes the Viewer role.
/// A Kiteworks user is specified as the email address associated with the account.
ClassMethod ShareFolder(connection As %SYS.MFT.Connection.Kiteworks, path As %String, accessLevel As %String = "viewer", users As %List) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:ShareFolder]","path="_path_", accessLevel="_accessLevel_", users="_$listtostring(users))

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Get the internal id
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Make sure that the access level is a valid role and map to roleId.
		// Map our general access level to specific vendor access level.
		Set sc=..GetRoleId(connection,accessLevel,.roleId)
		If $$$ISERR(sc) Quit
		
		// Request the folder be shared.
		Set request=##class(%DynamicObject).%New()
		Set members=[]
		For i=1:1:$listlength(users) {
			Set user=$listget(users,i)
			If user="" Continue
			Do members.%Push(user)
		}
		Set request.emails=members
		Do request.%Set("roleId",roleId,"number")
		Set query("partialSuccess")="false"
		Set sc=connection.MakeRequest("POST","rest/folders/"_itemId_"/members",request,.query,.response)
		If $$$ISERR(sc) Quit

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:ShareFolder]","MFT",sc)
	}
	Quit sc
}

/// Unshare a folder from a specified user.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// A Kiteworks user is specified as the email address associated with the account.
ClassMethod UnshareFolder(connection As %SYS.MFT.Connection.Kiteworks, path As %String, user As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:UnshareFolder]","path="_path_", User="_user)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Get the internal id
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Get the user id for the specified user
		Set query("email")=user
		Set sc=connection.MakeRequest("GET","rest/users",,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set entries=response.data
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") || (entries.%Size()>1) {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"UnshareFolder",text)
			Quit
		}
		
		If entries.%Size()=0 {
			Set sc=$$$ERROR($$$MFTNoUser,user)
			Quit
		}

		// Remove the specified user.
		Set userid=entries.%Get(0).id
		Set sc=connection.MakeRequest("DELETE","rest/folders/"_itemId_"/members/"_userid,,,.response)
		If $$$ISERR(sc) {
			Set err=$system.Status.GetErrorText(sc)
			If err["""code"": ""ERR_ENTITY_PARENT_FOLDER_MEMBER_EXISTS""" {
				Set sc=$$$ERROR($$$MFTUnshareOwner,path,user)
			} ElseIf (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
				Set sc=$$$ERROR($$$MFTNotShared,path,user)
			}
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:UnshareFolder]","MFT",sc)
	}
	Quit sc
}

/// Unshare a folder from all users.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod UnshareFolderAll(connection As %SYS.MFT.Connection.Kiteworks, path As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:UnshareFolderAll]","path="_path)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Get the internal id
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Get the list of members for this folder.		
		Set sc=connection.MakeRequest("GET","rest/folders/"_itemId_"/members",,,.response)
		If $$$ISERR(sc) Quit
		
		// Validate the response
		Set entries=response.data
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"UnshareFolderAll",text)
			Quit
		}
		
		// Remove each member.
		Set iterator=entries.%GetIterator()
		While iterator.%GetNext(.key,.entry) {
			// Remove the specified user.
			Set userid=entry.userId
			Set sc=connection.MakeRequest("DELETE","rest/folders/"_itemId_"/members/"_userid,,,.response)
			If $$$ISERR(sc) {
				Set err=$system.Status.GetErrorText(sc)
				// Skip the owner
				If err["""code"": ""ERR_ENTITY_PARENT_FOLDER_MEMBER_EXISTS""" {
					Continue
				}
				Quit
			}
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:UnshareFolderAll]","MFT",sc)
	}
	Quit sc
}

/// MountFolder is a Dropbox specific method to mount a shared folder that was shared by a different user.
/// MountFolder is treated as a NOP for all other services.
ClassMethod MountFolder(connection As %SYS.MFT.Connection.Kiteworks, folderName As %String) As %Status
{
	// A NOP if not Dropbox
	Quit $$$OK
}

/// UnmountFolder is a Dropbox specific method to unmount a shared folder that was shared by a different user.
/// UnmountFolder is treated as a NOP for all other services.
ClassMethod UnmountFolder(connection As %SYS.MFT.Connection.Kiteworks, folderName As %String) As %Status
{
	// A NOP if not Dropbox
	Quit $$$OK
}

/// Get the role id that is associated with a role name.
ClassMethod GetRoleId(connection As %SYS.MFT.Connection.Kiteworks, role As %String, Output roleId As %Integer) As %Status [ Internal ]
{
	Set roleId=""
	Set sc=$$$OK
	
	Try {
		// Get the role list if we do not already have it.
		If connection.Roles.Count()=0 {
			Set sc=connection.MakeRequest("GET","rest/roles",,,.response)
			If $$$ISERR(sc) Quit

			// Validate the response
			Set entries=response.data
			If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
				Set text=$extract(response.%ToJSON(),1,200)
				Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetRoleList",text)
				Quit
			}
			
			// Save the roles in connection object, but will not persist.
			Set iterator=entries.%GetIterator()
			While iterator.%GetNext(.key,.entry) {
				Do connection.Roles.SetAt(entry.id,entry.name)
			}
		}
		
		// Make sure that the role is a valid role.
		// Map our general access level to specific vendor role.
		Set mappedRole=$case(role,"editor":"Manager","viewer":"Viewer",:role)
		Set roleId=connection.Roles.GetAt(mappedRole)
		If roleId="" {
			Set sc=$$$ERROR($$$MFTBadAccessLevel,role)
			Quit
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Create a new user.
/// The Userid and Detail properties are filled in by CreateUser if it is successful.
ClassMethod CreateUser(connection As %SYS.MFT.Connection.Kiteworks, userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:CreateUser]","username="_userInfo.Username)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request that the specified user be created.
		Set request=##class(%DynamicObject).%New()
		Set request.email=userInfo.Username
		Set request.name=userInfo.Name
		Do request.%Set("sendNotification",1,"boolean")
		Set query("returnEntity")="true"
		Set sc=connection.MakeRequest("POST","rest/users",request,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If (response.name="") || (response.id="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"CreateFolder",text)
			Quit
		}
		
		Set userInfo=..CreateUserInfo(response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:CreateUser]","MFT",sc)
	}
	Quit sc
}

/// Delete the user that is specified by the id.
ClassMethod DeleteUserById(connection As %SYS.MFT.Connection.Kiteworks, userid As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:DeleteUserById]","userid="_userid)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Delete the user by id.
		Set sc=connection.MakeRequest("DELETE","rest/users/"_userid,,,.response)
		If $$$ISERR(sc) {
			// Not finding a user is not an error.
			Set err=$system.Status.GetErrorText(sc)
			If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
				Set sc=$$$OK
			}
			Quit
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:DeleteUserById]","MFT",sc)
	}
	Quit sc
}

/// Delete the user that is specified by the email address (i.e. username).
ClassMethod DeleteUser(connection As %SYS.MFT.Connection.Kiteworks, username As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:DeleteUser]","username="_username)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}
		
		// Get the userid based from the username
		Set sc=..GetUser(connection,username,.userInfo)

		// Delete the user by id.
		If $$$ISOK(sc),$isobject(userInfo) {
			Set sc=..DeleteUserById(connection,userInfo.Userid)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:DeleteUser]","MFT",sc)
	}
	Quit sc
}

/// Retrieve the %MFT.UserInfo specified by the service defined Userid.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".
ClassMethod GetUserById(connection As %SYS.MFT.Connection.Kiteworks, userid As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetUserById]","userid="_userid)
		Set userInfo=""
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// First check if it is our internal list format
		Try {
			Set id=$list(userid,1)
		} Catch {
			Set id=userid
		}
		
		// Request the user information.
		Set sc=connection.MakeRequest("GET","rest/users/"_id,,,.response)
		If $$$ISERR(sc) {
			// Not finding a user is not an error, just no item returned.
			Set err=$system.Status.GetErrorText(sc)
			If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED") {
				Set sc=$$$OK
			}
			Quit
		}

		// Validate the response	
		If (response.id="") || (response.email="") || (response.name="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUsername",text)
			Quit
		}
		
		Set userInfo=..CreateUserInfo(response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetUserById]","MFT",sc)
	}
	Quit sc
}

/// Retrieve the %MFT.UserInfo specified by the username
/// which is the email address for all currently supported services.
/// GetUser is potentially less efficient than GetUserById.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".
ClassMethod GetUser(connection As %SYS.MFT.Connection.Kiteworks, username As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetUser]","username="_username)
		Set userInfo=""
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Get user info based on the email.
		Set query("deleted")="false"
		Set query("active")="true"
		Set query("email")=username
		Set sc=connection.MakeRequest("GET","rest/users",,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set entries=response.data
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUser",text)
			Quit
		}
		
		// Not found if not exactly one response
		If response.metadata.total'=1 Quit
		
		// Create the UserInfo object.
		Set entry=entries.%Get(0)
		Set userInfo=..CreateUserInfo(entry)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetUser]","MFT",sc)
	}
	Quit sc
}

/// Return the list of all currently defined users for this team or enterprise.
ClassMethod GetUserList(connection As %SYS.MFT.Connection.Kiteworks, Output userList As %MFT.UserList) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Kiteworks:GetUserList]","")

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request the user list.
		Set userList=##class(%MFT.UserList).%New()
		Set query("deleted")="false"
		Set query("active")="true"
		Set sc=connection.MakeRequest("GET","rest/users",,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set entries=response.data
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUserList",text)
			Quit
		}
		
		// Add the entries in this response to the list.
		Set iterator=entries.%GetIterator()
		While iterator.%GetNext(.key,.entry) {
			// Create the returned user info object.
			Set userInfo=..CreateUserInfo(entry)
			If userInfo="" Continue
			Do userList.Users.Insert(userInfo)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Kiteworks:GetUserList]","MFT",sc)
	}
	Quit sc
}

/// Create an UserInfo object from a Kiteworks response
ClassMethod CreateUserInfo(response As %DynamicObject) As %MFT.UserInfo [ Internal ]
{
	// The item has been deleted.
	If response.deleted Quit ""

	// Build the UserInfo object.
	Set userInfo=##class(%MFT.UserInfo).%New()
	Set userInfo.Username=response.email
	Set userInfo.Name=response.name
	Set userInfo.Userid=response.id
	Set userInfo.Details=response.%ToJSON()
	Quit userInfo
}

}
