/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, %mft)

/// The %MFT.Box class is the subclass of %MFT.API which implements the APIs using Box.<br>
Class %MFT.Box Extends %MFT.API [ System = 4 ]
{

Parameter BOXFIELDS = "name,content_modified_at,modified_at,modified_by,item_status";

/// Get the form of id for a file or folder that is most efficient for subsequent calls.
/// GetRequestId will return either an id of the form "id:<id>" or a full path depending on which is more efficient.
/// This method is included to allow the id for future requests to be saved in the most efficient form.
ClassMethod GetRequestId(connection As %SYS.MFT.Connection.Box, itemInfo As %MFT.ItemInfo) As %String
{
	Quit "id:"_itemInfo.ItemId
}

/// Return the item info object which describes the specified folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the path to specify the current folder.
/// If a folder does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod GetFolderInfo(connection As %SYS.MFT.Connection.Box, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetFolderInfo]","path="_path)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// If a normal folder path is passed, then convert to an id and type.  Check type.
			Set sc=..GetItemId(connection,.path,.itemId,.type)

			// If file returned, then folder not found
			If $$$ISOK(sc),type'=$$$MFTfolder {
				Set itemInfo=""
				Quit
			}
			If $$$ISERR(sc) Quit
			Set containerPath=$piece(path,"/",1,*-1)_"/"
		} Else {
			Set containerPath=""
		}

		// Get folder info based on the id.
		Set sc=connection.MakeRequest("GET","folders/"_itemId,,,.response)
		If $$$ISERR(sc) {
			Set err=$system.Status.GetErrorText(sc)
			// Not finding an item is not an error.
			If (err["Error response: ERROR not_found") || (err["Error response: ERROR trashed") {
				Set itemInfo=""
				Set sc=$$$OK
			}
		} Else {
			// Create the returned folder item info object.
			Set itemInfo=..CreateItemInfo(response,containerPath)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetFolderInfo]","MFT",sc)
	}
	Quit sc
}

/// Return the id and type of the file or folder specified by the input path.
ClassMethod GetItemId(connection As %SYS.MFT.Connection.Box, ByRef path As %String, Output id As %String, Output type As %Integer) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	// Normalize the path
	Set path=connection.NormalizePath(path)
	If $extract(path,*)="/" {
		Set $extract(path,*)=""
	}
	
	// Store parts of the path in local array parts
	Set parts=0
	For i=1:1:$length(path,"/") {
		Set part=$piece(path,"/",i)
		If part="" Continue
		Set parts=parts+1
		Set parts(parts)=part
	}
	
	// Move down through the folder tree until the lowest level to get the id.
	// Begin at the root folder
	Set found=1
	Set itemId=0
	Set itemType=$$$MFTfolder
	Set newPath="/"
	For iPart=1:1:parts {
		// Get items in this folder
		Set folderContents=##class(%MFT.FolderContents).%New()
		Set sc=..GetFolderContentsInternal(connection,itemId,newPath,0,folderContents)
		If $$$ISERR(sc) Quit
		
		// Search the items for the needed part
		Set found=0
		Set part=parts(iPart)
		Set list=folderContents.Contents
		For iItem=1:1:list.Count() {
			Set itemInfo=list.GetAt(iItem)
			If itemInfo.Name=part,(itemInfo.Type=$$$MFTfolder) || (iPart=parts) {
				Set found=1
				Quit
			}
		}
		If 'found Quit
		Set itemId=itemInfo.ItemId
		Set itemType=itemInfo.Type
		Set newPath=newPath_part_"/"
	}

	// If found, get the details for the final itemId
	If found {
		Set id=itemId
		Set type=itemType
	} Else {
		Set id=""
		Set type=""
	}
	
	Quit sc
}

/// Create an ItemInfo object from a Box response
ClassMethod CreateItemInfo(response As %DynamicObject, containerPath As %String = "") As %MFT.ItemInfo [ Internal ]
{
	// The item has been deleted.
	If response."item_status"'="active" Quit ""
	
	// Build the ItemInfo object.
	Set itemInfo=##class(%MFT.ItemInfo).%New()
	Set itemInfo.Name=$select(response.id=0:"",1:response.name)
	Set itemInfo.Container=containerPath_$select(containerPath="":"",$extract(containerPath,*)'="/":"/",1:"")
	Set itemInfo.ItemId=response.id
	If response.type="file" {
		Set itemInfo.Type=$$$MFTfile
	} ElseIf response.type="folder" {
		Set itemInfo.Type=$$$MFTfolder
	} Else {
		// unexpected type
		Quit ""
	}
	If response."modified_at"'="" {
		Set itemInfo.Modified=##class(%TimeStamp).XSDToLogical(response."modified_at")
	} ElseIf response."content_modified_at"'="" {
		Set itemInfo.Modified=##class(%TimeStamp).XSDToLogical(response."content_modified_at")
	}
	Set user=response."modified_by"
	If $isobject(user),user.type="user" {
		Set itemInfo.ModifiedBy=$lb(user.id,user.login)
	}
	Set itemInfo.Details=response.%ToJSON()
	Quit itemInfo
}

/// Get the external username that corresponds to the specified internal user id.
ClassMethod GetUsername(connection As %SYS.MFT.Connection.Box, internalId As %String, Output username As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetUsername]","internalId="_internalId)
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
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetUsername]","MFT",sc)
	}
	Quit sc
}

/// Delete the remote folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the folder will be permanently deleted. Otherwise the folder will be moved to trash.<br>
/// If the remote folder does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod DeleteFolder(connection As %SYS.MFT.Connection.Box, path As %String, permanent As %Boolean = 0) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:DeleteFolder]","path="_path)
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
			Set sc=..GetFolderInfo(connection,fullpath,.itemInfo)
			If $$$ISERR(sc) Quit
			
			// Not finding an item is not an error.
			If '$isobject(itemInfo) Quit
		
			Set itemId=itemInfo.ItemId
		}
		
		// Request that the item be deleted.
		Set query("recursive")="true"
		Set sc=connection.MakeRequest("DELETE","folders/"_itemId,,.query,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error.
			Set err=$system.Status.GetErrorText(sc)
			If (err["Error response: ERROR not_found") || (err["Error response: ERROR trashed") {
				$$$SysLog(2,"MFT","[%MFT.Box:DeleteFolder]","err="_err)
				Set sc=$$$OK
			}
		}

		// If delete successful and permananet delete requested, delete the folder from trash.
		If $$$ISOK(sc),permanent {
			Set sc=connection.MakeRequest("DELETE","folders/"_itemId_"/trash",,,.response)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:DeleteFolder]","MFT",sc)
	}
	Quit sc
}

/// Creates the remote folder at the specified folderPath.
/// Each level of the folder path should be created separately if it does not already exist.
/// An %MFT.ItemInfo object is returned for the new folder.
ClassMethod CreateFolder(connection As %SYS.MFT.Connection.Box, folderPath As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:CreateFolder]","folderPath="_folderPath)
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
		Set sc=..GetFolderInfo(connection,folderParent,.parentItemInfo)
		If $$$ISERR(sc) Quit
		
		// Parent folder must exist
		If '$isobject(parentItemInfo) {
			Set sc=$$$ERROR($$$MFTFolderExpected,folderParent)
			Quit
		}

		// Request that the specified folder be created.
		Set request=##class(%DynamicObject).%New()
		Set request.name=folderName
		Set parent=##class(%DynamicObject).%New()
		Set parent.id=parentItemInfo.ItemId
		Set request.parent=parent
		Set sc=connection.MakeRequest("POST","folders",request,,.response)
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
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:CreateFolder]","MFT",sc)
	}
	Quit sc
}

/// Return the folder contents object for the specified folder.
/// folderPath may be a folder path.
/// folderPath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the folderPath to specify the current folder.
/// The FolderContents object will include a list of %MFT.ItemInfo objects which contain a file or folder name
/// and some additional simple information.
ClassMethod GetFolderContents(connection As %SYS.MFT.Connection.Box, folderPath As %String, recursive As %Boolean = 0, Output folderContents As %MFT.FolderContents) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetFolderContents]","folderPath="_folderPath_", recursive="_recursive)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set folderId=$$$MFTGetId(folderPath)
		If folderId="" {
			// Get the id for this folder.
			Set sc=..GetFolderInfo(connection,folderPath,.itemInfo)
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
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetFolderContents]","MFT",sc)
	}
	Quit sc
}

/// Internal method for recursing over subfolders to return the folder contents object for the specified folder.
ClassMethod GetFolderContentsInternal(connection As %SYS.MFT.Connection.Box, folderId As %String, path As %String, recursive As %Boolean = 0, folderContents As %MFT.FolderContents) As %Status [ Internal ]
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetFolderContentsInternal]","folderId="_folderId_", recursive="_recursive)
		
		Set offset=0
		For {
			// Request the folder contents.
			Set query("fields")=..#BOXFIELDS
			Set query("offset")=offset
			If $get(^ISC.MFT("ForceAsync")) {
				Set query("limit")=2
			} Else {
				Set query("limit")=1000
			}
			Set parameters="folders/"_folderId_"/items"
			Set sc=connection.MakeRequest("GET",parameters,,.query,.response)
			If $$$ISERR(sc) Quit

			// Validate the response
			Set entries=response.entries
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

				// If recursive required, then add the children
				If recursive,itemInfo.Type=$$$MFTfolder {
					Set sc=..GetFolderContentsInternal(connection,itemInfo.ItemId,itemInfo.GetPath(),recursive,folderContents)
					If $$$ISERR(sc) Quit
				}
			}
			If $$$ISERR(sc) Quit
			
			// Get next offset.  Done if we have read total items.
			Set offset=response.offset+response.limit
			If offset>=response."total_count" Quit
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetFolderContentsInternal]","MFT",sc)
	}
	Quit sc
}

/// Return the item info object which describes the specified file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// If a file does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod GetFileInfo(connection As %SYS.MFT.Connection.Box, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetFileInfo]","path="_path)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// If a normal folder path is passed, then convert to an id and type.  Check type.
			Set sc=..GetItemId(connection,.path,.itemId,.type)

			// If file returned, then folder not found
			If $$$ISOK(sc),type'=$$$MFTfile {
				Set itemInfo=""
				Quit
			}
			If $$$ISERR(sc) Quit
			Set containerPath=$piece(path,"/",1,*-1)_"/"
		} Else {
			Set containerPath=""
		}

		// Get file info based on the id.
		Set sc=connection.MakeRequest("GET","files/"_itemId,,,.response)
		If $$$ISERR(sc) {
			Set err=$system.Status.GetErrorText(sc)
			// Not finding an item is not an error.
			If (err["Error response: ERROR not_found") || (err["Error response: ERROR trashed") {
				Set itemInfo=""
				Set sc=$$$OK
			}
		} Else {
			// Create the returned folder item info object.
			Set itemInfo=..CreateItemInfo(response,containerPath)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetFileInfo]","MFT",sc)
	}
	Quit sc
}

/// Delete the remote file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the file will be permanently deleted. Otherwise the file will be moved to trash.<br>
/// If the remote file does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod DeleteFile(connection As %SYS.MFT.Connection.Box, path As %String, permanent As %Boolean = 0) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:DeleteFile]","path="_path)
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
			Set sc=..GetFileInfo(connection,fullpath,.itemInfo)
			If $$$ISERR(sc) Quit
			
			// Not finding an item is not an error.
			If '$isobject(itemInfo) Quit
		
			Set itemId=itemInfo.ItemId
		}
		
		// Request that the item be deleted.
		Set sc=connection.MakeRequest("DELETE","files/"_itemId,,,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error.
			Set err=$system.Status.GetErrorText(sc)
			If (err["Error response: ERROR not_found") || (err["Error response: ERROR trashed") {
				Set sc=$$$OK
				$$$SysLog(2,"MFT","[%MFT.Box:DeleteFile]","err="_err)
			}

		}

		// If delete successful and permananet delete requested, delete the file from trash.
		If $$$ISOK(sc),permanent {
			Set sc=connection.MakeRequest("DELETE","files/"_itemId_"/trash",,,.response)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:DeleteFile]","MFT",sc)
	}
	Quit sc
}

/// Update the specified remote file with the contents of the specified local file.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.
ClassMethod UploadFile(connection As %SYS.MFT.Connection.Box, localFilePath As %String, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=localFilePath
	Quit ..UploadStream(.connection,stream,filePath,replace,.itemInfo)
}

/// Update the specified remote file with the contents of the specified stream.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.
ClassMethod UploadStream(connection As %SYS.MFT.Connection.Box, stream As %BinaryStream, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:Upload]","filePath="_filePath_", replace="_replace)
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

		// Find id of parent folder
		Set fileName=$piece(path,"/",*)
		Set folderName=$piece(path,"/",1,*-1)_"/"
		Set sc=..GetFolderInfo(connection,folderName,.parentItemInfo)
		If $$$ISERR(sc) Quit

		If '$isobject(parentItemInfo) {
			Set sc=$$$ERROR($$$MFTFolderExpected,folderName)
			Quit
		}

		// See if file exists		
		Set sc=..GetFileInfo(connection,path,.itemInfo)
		If $$$ISERR(sc) Quit

		// Setup argument for upload call
		If $isobject(itemInfo) {
			// If not able to replace, then first check for existence of file
			If 'replace {
				Set sc=$$$ERROR($$$MFTFileExists,path)
				Quit
			}
			Set parameters="files/"_itemInfo.ItemId_"/content"
			Set request=""
		} Else {
			Set parameters="files/content"
			Set request=##class(%DynamicObject).%New()
			Set request.name=$zcvt(fileName,"O","UTF8")
			Set parent=##class(%DynamicObject).%New()
			Do parent.%Set("id",parentItemInfo.ItemId,"string")
			Set request.parent=parent
		}
		
		// Request the upload
		Set sc=connection.MakeUploadRequest(parameters,fileName,request,stream,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		Set entries=response.entries
		If (response."total_count"'=1) || '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") ||
		   (response.entries.%Get(0).name'=$piece(path,"/",*)) {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"Upload",text)
			Quit
		}
	
		// Create the returned item info object.
		Set itemInfo=..CreateItemInfo(entries.%Get(0),folderName)

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:Upload]","MFT",sc)
	}
	Quit sc
}

/// Download the specified remote file and store at the location given by localFilePath.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod DownloadFile(connection As %SYS.MFT.Connection.Box, filePath As %String, localFilePath As %String) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=localFilePath
	Quit ..DownloadStream(.connection,filePath,stream)
}

/// Download the specified remote file and store in the specified stream which must be a %FileBinaryStream or a %GlobalBinaryStream.
/// If stream is not specified, then a %GlobalBinaryStream will be created.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod DownloadStream(connection As %SYS.MFT.Connection.Box, filePath As %String, ByRef stream As %BinaryStream) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:Download]","filePath="_filePath)
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

			Set sc=..GetFileInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit
			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFileNeeded,filePath)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Request the download
		If $get(stream)="" Set stream=##class(%GlobalBinaryStream).%New()
		Set sc=connection.MakeDownloadRequest("files/"_itemId_"/content",stream,.response)
		If $$$ISERR(sc) {
			// Not found error
			Set err=$system.Status.GetErrorText(sc)
			If (err["Error response: ERROR not_found") || (err["Error response: ERROR trashed") {
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
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:Download]","MFT",sc)
	}
	Quit sc
}

/// Share a folder with a list of users pass as a $list.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// The "editor" and "viewer" access levels are supported for all vendors.
/// The defined Box roles are supported as access levels.
/// The editor access level becomes the Manager role and the viewer access level becomes the Viewer role.
/// A Box user is specified as the email address associated with the account.
ClassMethod ShareFolder(connection As %SYS.MFT.Connection.Box, path As %String, accessLevel As %String = "viewer", users As %List) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:ShareFolder]","path="_path_", accessLevel="_accessLevel_", users="_$listtostring(users))

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Get the internal id
			Set sc=..GetFolderInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}
		
		// Get internal id for each user
		Set userids=0
		For i=1:1:$listlength(users) {
			Set user=$listget(users,i)
			If user="" Continue
			
			Set sc=..GetUser(connection,user,.userInfo)
			If $$$ISERR(sc) Quit
			
			Set userids=userids+1
			Set userids(userids)=userInfo.Userid
		}
		If $$$ISERR(sc) Quit

		// Request the folder be shared for each user.
		For j=1:1:userids {
			Set request=##class(%DynamicObject).%New()
			Set item=##class(%DynamicObject).%New()
			Set item.type="folder"
			Do item.%Set("id",itemId)
			Set request.item=item
			Set accessibleBy=##class(%DynamicObject).%New()
			Set accessibleBy.type="user"
			Set accessibleBy.id=userids(j)
			Set request."accessible_by"=accessibleBy
			Set request.role=accessLevel
			Do request.%Set("can_view_path",0,"boolean")
			Set sc1=connection.MakeRequest("POST","collaborations",request,,.response)
			If $$$ISERR(sc1) Set sc=$$$ADDSC(sc,sc1)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:ShareFolder]","MFT",sc)
	}
	Quit sc
}

/// Unshare a folder from a specified user.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// A Box user is specified as the email address associated with the account.
ClassMethod UnshareFolder(connection As %SYS.MFT.Connection.Box, path As %String, user As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:UnshareFolder]","path="_path_", User="_user)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Get the internal id
			Set sc=..GetFolderInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Get the user id for the specified user
		Set sc=..GetUser(connection,user,.userInfo)
		If $$$ISERR(sc) Quit
		
		// Find the collaboration id for this user
		Set sc=..GetCollaborations(connection,itemId,.collaborations)
		If $$$ISERR(sc) Quit
		Set collaborationId=$get(collaborations(user))
		If collaborationId="" {
			Set sc=$$$ERROR($$$MFTNotShared,path,user)
			Quit
		}

		// Remove the specified collaboration.
		Set sc=connection.MakeRequest("DELETE","collaborations/"_collaborationId,,,.response)
		If $$$ISERR(sc) Quit

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:UnshareFolder]","MFT",sc)
	}
	Quit sc
}

/// Unshare a folder from all users.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod UnshareFolderAll(connection As %SYS.MFT.Connection.Box, path As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:UnshareFolderAll]","path="_path)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set itemId=$$$MFTGetId(path)
		If itemId="" {
			// Get the internal id
			Set sc=..GetFolderInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
			
			Set itemId=itemInfo.ItemId
		}

		// Get the list of collaboration ids for this folder
		Set sc=..GetCollaborations(connection,itemId,.collaborations)
		If $$$ISERR(sc) Quit
		
		// Remove each collaboration
		Set username=""
		For {
			Set username=$order(collaborations(username))
			If username="" Quit
			
			// Remove the collaboration
			Set sc1=connection.MakeRequest("DELETE","collaborations/"_collaborations(username),,,.response)
			If $$$ISERR(sc1) Set sc=$$$ADDSC(sc,sc1)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:UnshareFolderAll]","MFT",sc)
	}
	Quit sc
}

/// MountFolder is a Dropbox specific method to mount a shared folder that was shared by a different user.
/// MountFolder is treated as a NOP for all other services.
ClassMethod MountFolder(connection As %SYS.MFT.Connection.Box, folderName As %String) As %Status
{
	// A NOP if not Dropbox
	Quit $$$OK
}

/// UnmountFolder is a Dropbox specific method to unmount a shared folder that was shared by a different user.
/// UnmountFolder is treated as a NOP for all other services.
ClassMethod UnmountFolder(connection As %SYS.MFT.Connection.Box, folderName As %String) As %Status
{
	// A NOP if not Dropbox
	Quit $$$OK
}

/// Internal method for getting all collaboration ids by user associated with a folder.
/// The collaborations local array is returned as collaboration(<username>)=<collaboration id>
ClassMethod GetCollaborations(connection As %SYS.MFT.Connection.Box, folderId As %String, Output collaborations As %String) As %Status [ Internal ]
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetCollaborations]","folderId="_folderId)
		Kill collaborations
		
		// Request the collaborations for this folder
		Set parameters="folders/"_folderId_"/items"
		Set sc=connection.MakeRequest("GET","folders/"_folderId_"/collaborations",,,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set entries=response.entries
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetFolderContents",text)
			Quit
		}
		
		// Add the collaboration entries in this response to the list.
		Set iterator=entries.%GetIterator()
		While iterator.%GetNext(.key,.entry) {
			If entry.type="collaboration" {
				Set collaborations(entry."accessible_by".login)=entry.id
			}
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetCollaborations]","MFT",sc)
	}
	Quit sc
}

/// Create a new user.
/// The Userid and Detail properties are filled in by CreateUser if it is successful.
ClassMethod CreateUser(connection As %SYS.MFT.Connection.Box, userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:CreateUser]","username="_userInfo.Username)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request that the specified user be created.
		Set request=##class(%DynamicObject).%New()
		Set request.login=userInfo.Username
		Set request.name=userInfo.Name
		Set request.role="user"
		Do request.%Set("is_sync_enabled",1,"boolean")
		Set request.status="active"
		Set sc=connection.MakeRequest("POST","users",request,,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If (response.name="") || (response.id="") || (response.login="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"CreateFolder",text)
			Quit
		}
		
		Set userInfo=..CreateUserInfo(response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:CreateUser]","MFT",sc)
	}
	Quit sc
}

/// Delete the user that is specified by the id.
ClassMethod DeleteUserById(connection As %SYS.MFT.Connection.Box, userid As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:DeleteUserById]","userid="_userid)
		
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
		
		// Delete the user by id.
		Set query("notify")="true"
		Set query("force")="true"
		Set sc=connection.MakeRequest("DELETE","users/"_id,,.query,.response)
		If $$$ISERR(sc) {
			// Not finding a user is not an error.
			Set err=$system.Status.GetErrorText(sc)
			If (err["""code"": ""ERR_ENTITY_NOT_FOUND""") || (err["""code"": ""ERR_ENTITY_DELETED""") {
				Set sc=$$$OK
			}
			Quit
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:DeleteUserById]","MFT",sc)
	}
	Quit sc
}

/// Delete the user that is specified by the email address (i.e. username).
ClassMethod DeleteUser(connection As %SYS.MFT.Connection.Box, username As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:DeleteUser]","username="_username)
		
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
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:DeleteUser]","MFT",sc)
	}
	Quit sc
}

/// Retrieve the %MFT.UserInfo specified by the service defined Userid.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".
ClassMethod GetUserById(connection As %SYS.MFT.Connection.Box, userid As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetUserById]","userid="_userid)
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
		Set sc=connection.MakeRequest("GET","users/"_id,,,.response)
		If $$$ISERR(sc) {
			// Not finding a user is not an error, just no item returned.
			Set err=$system.Status.GetErrorText(sc)
			If err["Error response: ERROR not_found" {
				Set sc=$$$OK
			}
			Quit
		}

		// Validate the response	
		If (response.id="") || (response.login="") || (response.name="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUsername",text)
			Quit
		}
		
		Set userInfo=..CreateUserInfo(response)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetUserById]","MFT",sc)
	}
	Quit sc
}

/// Retrieve the %MFT.UserInfo specified by the username
/// which is the email address for all currently supported services.
/// GetUser is potentially less efficient than GetUserById.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".
ClassMethod GetUser(connection As %SYS.MFT.Connection.Box, username As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetUser]","username="_username)
		Set userInfo=""
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Get user info based on the email.
		Set query("user_type")="managed"
		Set query("filter_term")=username
		Set sc=connection.MakeRequest("GET","users",,.query,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set entries=response.entries
		If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUser",text)
			Quit
		}
		
		// Not found if not exactly one response
		If response."total_count"'=1 Quit
		
		// Create the UserInfo object.
		Set entry=entries.%Get(0)
		Set userInfo=..CreateUserInfo(entry)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetUser]","MFT",sc)
	}
	Quit sc
}

/// Return the list of all currently defined users for this team or enterprise.
ClassMethod GetUserList(connection As %SYS.MFT.Connection.Box, Output userList As %MFT.UserList) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Box:GetUserList]","")

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request the user list.
		Set offset=0
		Set userList=##class(%MFT.UserList).%New()
		Set query("user_type")="managed"
		If $get(^ISC.MFT("ForceAsync")) {
			Set query("limit")=2
		} Else {
			Set query("limit")=1000
		}
		For {
			Set query("offset")=offset
			Set sc=connection.MakeRequest("GET","users",,.query,.response)
			If $$$ISERR(sc) Quit

			// Validate the response
			Set entries=response.entries
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
			If $$$ISERR(sc) Quit
			
			// Get next offset.  Done if we have read total items.
			Set offset=response.offset+response.limit
			If offset>=response."total_count" Quit
		}
				
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Box:GetUserList]","MFT",sc)
	}
	Quit sc
}

/// Create an UserInfo object from a Box response
ClassMethod CreateUserInfo(response As %DynamicObject) As %MFT.UserInfo [ Internal ]
{
	// The item has been deleted.
	If response.deleted Quit ""

	// Build the UserInfo object.
	Set userInfo=##class(%MFT.UserInfo).%New()
	Set userInfo.Username=response.login
	Set userInfo.Name=response.name
	Set userInfo.Userid=response.id
	Set userInfo.Details=response.%ToJSON()
	Quit userInfo
}

}
