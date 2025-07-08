/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %mft

/// The %MFT.Dropbox class is the subclass of %MFT.API which implements the APIs using Dropbox.<br>
/// NOTE: Two different kinds of Dropbox applications (and hence two different %SYS.MFT.Connection.Dropbox objects)
/// are needed in order to use the full API in this class.  
/// A connection based on a Dropbox User application with Full Dropbox permission is needed to manage files and folders.
/// A connection based on a Dropbox Business application with Team Memeber Management permission is needed to manage users.
Class %MFT.Dropbox Extends %MFT.API [ System = 4 ]
{

/// Get the form of id for a file or folder that is most efficient for subsequent calls.
/// GetRequestId will return either an id of the form "id:<id>" or a full path depending on which is more efficient.
/// This method is included to allow the id for future requests to be saved in the most efficient form.
ClassMethod GetRequestId(connection As %SYS.MFT.Connection.Dropbox, itemInfo As %MFT.ItemInfo) As %String
{
	Quit itemInfo.GetPath()
}

/// Return the item info object which describes the specified folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the path to specify the current folder.
/// If a folder does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod GetFolderInfo(connection As %SYS.MFT.Connection.Dropbox, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetFolderInfo]","path="_path)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set sc=..GetItemInfo(connection,path,.itemInfo)
		// If file returned, then folder not found
		If $$$ISOK(sc),$isobject(itemInfo),itemInfo.Type'=$$$MFTfolder {
			Set itemInfo=""
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetFolderInfo]","MFT",sc)
	}
	Quit sc
}

/// Return the item info object which describes the specified file or folder.
/// "" May be used as the itemPath to specify the current folder.<br>
/// If an item does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".<br>
/// %MFT.Dropbox only supports the file's owner getting information about a file.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod GetItemInfo(connection As %SYS.MFT.Connection.Dropbox, itemPath As %String, Output itemInfo As %MFT.ItemInfo) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetItemInfo]","itemPath="_itemPath)
		Set itemInfo=""
		Set folder=""
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		If $$$MFTGetId(itemPath)'="" {
			// If id specified, then use it as the path
			Set path=itemPath
		} Else {
			// The root folder always has the same item info
			Set path=connection.NormalizePath(itemPath)
			If $extract(path,*)="/" {
				Set $extract(path,*)=""
				Set folder=1
			}
			If path="" {
				Set itemInfo=##class(%MFT.ItemInfo).%New()
				Set itemInfo.Container="/"
				Set itemInfo.Type=$$$MFTfolder
				Quit
			}
		}

		// Request the metadata for this item.
		Set request={}
		Set request.path=path
		Set sc=connection.MakeRPCRequest("files/get_metadata",request,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error, just no item returned.
			If $system.Status.GetErrorText(sc)["""error_summary"": ""path/not_found/" Set sc=$$$OK
			Quit
		}

		// Validate the response	
		If $case(response.".tag","file":0,"folder":0,:1) || (response.name="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetItemInfo",text)
			Quit
		}
	
		// Create the returned item info object.
		Set itemInfo=..CreateItemInfo(response)
		Set itemInfo.Type=$case(response.".tag","file":$$$MFTfile,"folder":$$$MFTfolder,:"")
		
		// If folder requested, then make sure that it is not a file.
		If folder,itemInfo.Type'=$$$MFTfolder {
			Set sc=$$$ERROR($$$MFTFolderExpected,itemPath)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetItemInfo]","MFT",sc)
	}
	Quit sc
}

/// Create an ItemInfo object from a Dropbox response
ClassMethod CreateItemInfo(response As %DynamicObject) As %MFT.ItemInfo [ Internal ]
{
	Set itemInfo=##class(%MFT.ItemInfo).%New()
	Set itemInfo.Name=response.name
	Set itemInfo.Container=$piece(response."path_display","/",1,*-1)_"/"
	Set id=$$$MFTGetId(response.id)
	Set itemInfo.ItemId=$select(id="":response.id,1:id)
	Set itemInfo.Details=response.%ToJSON()
	If response."server_modified"'="" {
		Set itemInfo.Modified=##class(%TimeStamp).XSDToLogical(response."server_modified")
	}
	Set share=response."sharing_info"
	If share'="" {
		Set itemInfo.ModifiedBy=share."modified_by"
	}
	Quit itemInfo
}

/// Get the external username that corresponds to the specified internal user id.
/// This call only works for files, since Dropbox does not return id of the last user that modified.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod GetUsername(connection As %SYS.MFT.Connection.Dropbox, internalId As %String, Output username As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetUsername]","internalId="_internalId)
		Set username=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}
		
		// Dropbox does not return ModifiedBy for the last user who modified.
		If internalId="" {
			Set username=connection.Username
			Set sc=$$$OK
			Quit
		}

		// Request the user information.
		Set request={}
		Set request."account_id"=internalId
		Set sc=connection.MakeRPCRequest("users/get_account",request,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error, just no item returned.
			If $system.Status.GetErrorText(sc)["""error_summary"": ""path/not_found/" Set sc=$$$OK
			Quit
		}

		// Validate the response	
		If (response."account_id"="") || (response.email="") || (response.name="") {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUsername",text)
			Quit
		}
	
		// Return the username which is the email address for Dropbox.
		Set username=response.email

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetUsername]","MFT",sc)
	}
	Quit sc
}

/// Delete the remote folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the folder will be permanently deleted. Otherwise the folder will be moved to trash.<br>
/// The permanent argument is not yet implemented for Dropbox because using the permanently_delete API call
/// requires a different type of connection than that used for files, folders or users.
/// Dropbox support indicates that permanently_delete may be supported in the future for file API.<br>
/// If the remote folder does not exist at the specified path, then $$$OK is returned as status.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod DeleteFolder(connection As %SYS.MFT.Connection.Dropbox, path As %String, permanent As %Boolean = 0) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:DeleteFolder]","path="_path)
		Set itemInfo=""

		// permanent argument is not yet implemented because using permanently_delete API call
		// requires a different type of connection than that used for files, folders or users.
		// Dropbox support indicates that permanently_delete may be supported in the future for folder API.
		If permanent {
			Set sc=$$$ERROR($$$NotImplemented)
			Quit
		}

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		If $$$MFTGetId(path)'="" {
			// If id specified, then use it as the path
			Set fullpath=path
		} Else {
			// Normalize path
			Set fullpath=connection.NormalizePath(path)
			If $extract(fullpath,*)="/" {
				Set $extract(fullpath,*)=""
			}
			If fullpath="" {
				Set sc=$$$ERROR($$$MFTRootDelete)
				Quit
			}
		}

		// Find the folder or file		
		Set sc=..GetItemInfo(connection,fullpath,.existingItemInfo)
		If $$$ISERR(sc) Quit
		// Not finding an item is not an error, just no item returned.
		If '$isobject(existingItemInfo) || (existingItemInfo.Type'=$$$MFTfolder ) Quit
		// Unshare the folder.  Ignore error if not shared.
		Do ..UnshareFolderAll(connection,,existingItemInfo)
		
		// Request that the item be deleted.
		Set request={}
		Set request.path=existingItemInfo.GetPath(0)
		Set sc=connection.MakeRPCRequest("files/delete_v2",request,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error, just no item returned.
			Set err=$system.Status.GetErrorText(sc)
			If err["""error_summary"": ""path/not_found/" {
				Set sc=$$$OK
				$$$SysLog(2,"MFT","[%MFT.Dropbox:DeleteFolder]","err="_err)
			}
		} Else {
			// Validate the response	
			If (response.metadata.".tag"'="folder") || (response.metadata.name="") {
				Set text=$extract(response.%ToJSON(),1,200)
				Set sc=$$$ERROR($$$MFTUnexpectedResponse,"DeleteItem",text)
				Quit
			}
		}
	
		;; Remove until API support is available for normal connection.
		;;// If delete successful and permananet delete requested, delete the folder from trash.
		;;If $$$ISOK(sc),permanent {
		;;	Set sc=connection.MakeRPCRequest("files/permanently_delete",request,.response)
		;;}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:DeleteFolder]","MFT",sc)
	}
	Quit sc
}

/// Creates the remote folder at the specified folderPath.
/// Each level of the folder path should be created separately if it does not already exist.
/// An %MFT.ItemInfo object is returned for the new folder.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod CreateFolder(connection As %SYS.MFT.Connection.Dropbox, folderPath As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:CreateFolder]","folderPath="_folderPath)
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

		// Request the that the specified folder be created.
		Set request={}
		Set request.path=path
		Set sc=connection.MakeRPCRequest("files/create_folder",request,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If response.name="" {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"CreateFolder",text)
			Quit
		}
	
		// Create the returned item info object.
		Set itemInfo=..CreateItemInfo(response)
		Set itemInfo.Type=$$$MFTfolder

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:CreateFolder]","MFT",sc)
	}
	Quit sc
}

/// Return the folder contents object for the specified folder.
/// folderPath may be a folder path.
/// folderPath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the folderPath to specify the current folder.
/// The FolderContents object will include a list of %MFT.ItemInfo objects which contain a file or folder name
/// and some additional simple information.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod GetFolderContents(connection As %SYS.MFT.Connection.Dropbox, folderPath As %String, recursive As %Boolean = 0, Output folderContents As %MFT.FolderContents) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetFolderContents]","folderPath="_folderPath_", recursive="_recursive)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		If $$$MFTGetId(folderPath)'="" {
			// If id specified, then find the path
			Set sc=..GetItemInfo(connection,folderPath,.itemInfo)
			If $$$ISERR(sc) Quit
			// Not finding an item is not an error, just no item returned.
			If '$isobject(itemInfo) || (itemInfo.Type'=$$$MFTfolder ) {
				Set sc=$$$ERROR($$$MFTFolderExpected,folderPath)
				Quit
			}
			Set path=itemInfo.GetPath()

		} Else {
			Set path=connection.NormalizePath(folderPath)
		}

		// Remove trailing / from path
		If $extract(path,*)="/" {
			Set $extract(path,*)=""
		}

		// Get the list of the folder's children
		Set folderContents=##class(%MFT.FolderContents).%New()
		Set folderContents.Recursive=''recursive
		
		// Request the folder contents.
		Set request={}
		Set request.path=path
		Do request.%Set("recursive",''recursive,"boolean")
		Set sc=connection.MakeRPCRequest("files/list_folder",request,.response)
		If $$$ISERR(sc) Quit

		// Add children to the list
		For {
			// Validate the response	
			If (response.cursor="") || (response."has_more"="") {
				Set text=$extract(response.%ToJSON(),1,200)
				Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetFolderContents",text)
				Quit
			}
			
			// Add the entries in this response to the list.
			Set entries=response.entries
			If $isobject(entries),$classname(entries)="%Library.DynamicArray" {
				Set iterator=entries.%GetIterator()
				While iterator.%GetNext(.key,.value) {
					// Create the returned item info object for the folder child.
					Set itemInfo=..CreateItemInfo(value)
					Set itemInfo.Type=$case(value.".tag","file":$$$MFTfile,"folder":$$$MFTfolder,:"")
					// Skip the parent folder which is returned by Dropbox for recursive request.
					If itemInfo.Type'="",'recursive || (path'=(itemInfo.Container_itemInfo.Name)) {
						Do folderContents.Contents.Insert(itemInfo)
					}
				}
			}
			
			// If all entries read, then we are done.
			If 'response."has_more" Quit

			// Request additional folder contents if has_more flag true.
			Set request={}
			Set request.cursor=response.cursor
			Set sc=connection.MakeRPCRequest("files/list_folder/continue",request,.response)
			If $$$ISERR(sc) Quit
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetFolderContents]","MFT",sc)
	}
	Quit sc
}

/// Return the item info object which describes the specified file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// If a file does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod GetFileInfo(connection As %SYS.MFT.Connection.Dropbox, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetFileInfo]","path="_path)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set sc=..GetItemInfo(connection,path,.itemInfo)
		// If folder returned, then file not found
		If $$$ISOK(sc),$isobject(itemInfo),itemInfo.Type'=$$$MFTfile {
			Set itemInfo=""
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetFileInfo]","MFT",sc)
	}
	Quit sc
}

/// Delete the remote file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the file will be permanently deleted. Otherwise the file will be moved to trash.<br>
/// The permanent argument is not yet implemented for Dropbox because using the permanently_delete API call
/// requires a different type of connection than that used for files, folders or users.
/// Dropbox support indicates that permanently_delete may be supported in the future for file API.<br>
/// If the remote file does not exist at the specified path, then $$$OK is returned as status.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod DeleteFile(connection As %SYS.MFT.Connection.Dropbox, path As %String, permanent As %Boolean = 0) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:DeleteFile]","path="_path)
		Set itemInfo=""
		
		// permanent argument is not yet implemented because using permanently_delete API call
		// requires a different type of connection than that used for files or users.
		// Dropbox support indicates that permanently_delete may be supported in the future for file API.
		If permanent {
			Set sc=$$$ERROR($$$NotImplemented)
			Quit
		}

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		If $$$MFTGetId(path)'="" {
			// If id specified, then use it as the path
			Set fullpath=path
		} Else {
			// Normalize path
			Set fullpath=connection.NormalizePath(path)
			If $extract(fullpath,*)="/" {
				Set $extract(fullpath,*)=""
			}
			If fullpath="" {
				Set sc=$$$ERROR($$$MFTRootDelete)
				Quit
			}
		}

		// Find the folder or file		
		Set sc=..GetItemInfo(connection,fullpath,.existingItemInfo)
		If $$$ISERR(sc) Quit
		// Not finding an item is not an error, just no item returned.
		If '$isobject(existingItemInfo) || (existingItemInfo.Type'=$$$MFTfile ) Quit
		// Unshare the file.  Ignore error if not shared.
		Do ..UnshareFileAll(connection,existingItemInfo)
		
		// Request that the item be deleted.
		Set request={}
		Set request.path=existingItemInfo.GetPath()
		Set sc=connection.MakeRPCRequest("files/delete_v2",request,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error, just no item returned.
			Set err=$system.Status.GetErrorText(sc)
			If err["""error_summary"": ""path/not_found/" {
				Set sc=$$$OK
				$$$SysLog(2,"MFT","[%MFT.Dropbox:DeleteFile]","err="_err)
			}
		} Else {
			// Validate the response	
			If (response.metadata.".tag"'="file") || (response.metadata.name="") {
				Set text=$extract(response.%ToJSON(),1,200)
				Set sc=$$$ERROR($$$MFTUnexpectedResponse,"DeleteItem",text)
				Quit
			}
		}
	
		;; Remove until API support is available for normal connection.
		;;// If delete successful and permananet delete requested, delete the file from trash.
		;;If $$$ISOK(sc),permanent {
		;;	Set sc=connection.MakeRPCRequest("files/permanently_delete",request,.response)
		;;}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:DeleteFile]","MFT",sc)
	}
	Quit sc
}

/// Update the specified remote file with the contents of the specified local file.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod UploadFile(connection As %SYS.MFT.Connection.Dropbox, localFilePath As %String, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=localFilePath
	Quit ..UploadStream(.connection,stream,filePath,replace,.itemInfo)
}

/// Update the specified remote file with the contents of the specified stream.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod UploadStream(connection As %SYS.MFT.Connection.Dropbox, stream As %BinaryStream, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:Upload]","filePath="_filePath)
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

		// Request the upload
		Set request={}
		Set request.path=path
		Set request.mode=$select(replace:"overwrite",1:"add")
		Set sc=connection.MakeUploadRequest("files/upload",request,stream,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If response.name'=$piece(path,"/",*) {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"Upload",text)
			Quit
		}
	
		// Create the returned item info object.
		Set itemInfo=..CreateItemInfo(response)
		Set itemInfo.Type=$$$MFTfile

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:Upload]","MFT",sc)
	}
	Quit sc
}

/// Download the specified remote file and store at the location given by localFilePath.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod DownloadFile(connection As %SYS.MFT.Connection.Dropbox, filePath As %String, localFilePath As %String) As %Status
{
	Set stream=##class(%FileBinaryStream).%New()
	Set stream.Filename=localFilePath
	Quit ..DownloadStream(.connection,filePath,stream)
}

/// Download the specified remote file and store in the specified stream which must be a %FileBinaryStream or a %GlobalBinaryStream.
/// If stream is not specified, then a %GlobalBinaryStream will be created.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod DownloadStream(connection As %SYS.MFT.Connection.Dropbox, filePath As %String, ByRef stream As %BinaryStream) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:Download]","filePath="_filePath)
		Set itemInfo=""

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		Set path=$$$MFTGetId(filePath)
		If path="" {
			// Normalize the file path
			Set path=connection.NormalizePath(filePath)
			If $extract(path,*)="/" {
				Set sc=$$$ERROR($$$MFTNoFolder)
				Quit
			}
			Set isId=0
		} Else {
			Set path=filePath
			Set isId=1
		}

		// Request the download
		Set request={}
		Set request.path=path
		If $get(stream)="" Set stream=##class(%GlobalBinaryStream).%New()
		Set sc=connection.MakeDownloadRequest("files/download",request,stream,.response)
		If $$$ISERR(sc) Quit

		// Validate the response	
		If (response.name="") || ('isId && (response.name'=$piece(path,"/",*))) {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"Download",text)
			Quit
		}
		
		// Save the stream.
		Set sc=stream.SaveStream()
	
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:Download]","MFT",sc)
	}
	Quit sc
}

/// Share a folder with a list of users pass as a $list.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// The "editor" and "viewer" access levels are supported for all vendors.
/// Any additional Dropbox access levels are also supported.
/// A Dropbox user is specified as the email address associated with the account.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod ShareFolder(connection As %SYS.MFT.Connection.Dropbox, path As %String, accessLevel As %String = "viewer", users As %List) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:ShareFolder]","path="_path_", accessLevel="_accessLevel_", users="_$listtostring(users))
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Get the internal id
		Set sc=..GetItemInfo(connection,path,.itemInfo)
		If $$$ISERR(sc) Quit

		If '$isobject(itemInfo) {
			Set sc=$$$ERROR($$$MFTFolderExpected,path)
			Quit
		}

		// Request the folder be shared.
		// If sharing a folder, we must first make it a shared folder
		Set request={}
		Set request.path=itemInfo.GetPath(0)
		Set sc=connection.MakeRPCRequest("sharing/share_folder",request,.response)
		If $$$ISERR(sc) Quit

		// We must wait for the share to complete.
		Set asyncId=response."async_job_id"
		If asyncId'="" {
			Set hangTime=.25
			For {
				Set asyncRequest={}
				Set asyncRequest."async_job_id"=asyncId
				Set sc=connection.MakeRPCRequest("sharing/check_share_job_status",asyncRequest,.response)
				If $$$ISERR(sc) Quit
				If response.".tag"="complete" Quit
				hang hangTime
				Set hangTime=2*hangTime
			}
			If $$$ISERR(sc) Quit
		}

		// Validate the response	
		If response."shared_folder_id"="" {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"Share Folder",text)
			Quit
		}

		// Now add members
		Set request={}
		Set request."shared_folder_id"=response."shared_folder_id"
		Set members=[]
		For i=1:1:$listlength(users) {
			Set user=$listget(users,i)
			If user="" Continue
			Set member={".tag":"email"}
			Set member.email=user
			Set level={}
			Set level.".tag"=accessLevel
			Set memberAndLevel={}
			Set memberAndLevel.member=member
			Set memberAndLevel."access_level"=level
			Do members.%Push(memberAndLevel)
		}
		Set request.members=members
		Set sc=connection.MakeRPCRequest("sharing/add_folder_member",request,.response)
		If $$$ISERR(sc) Quit

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:ShareFolder]","MFT",sc)
	}
	Quit sc
}

/// Unshare a folder from a specified user.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// A Dropbox user is specified as the email address associated with the account.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod UnshareFolder(connection As %SYS.MFT.Connection.Dropbox, path As %String, User As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:UnshareFolder]","path="_path_", User="_User)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Get the internal id
		Set sc=..GetItemInfo(connection,path,.itemInfo)
		If $$$ISERR(sc) Quit

		If '$isobject(itemInfo) {
			Set sc=$$$ERROR($$$MFTFolderExpected,path)
			Quit
		}

		// Request the that users be removed as members for this folder.
		Set request={}
		Set member={".tag":"email"}
		Set member.email=User
		Set request.member=member
		Set sharedId=..GetSharedFolderId(itemInfo)
		If sharedId="" {
			Set sc=$$$ERROR($$$MFTNotSharedFolder,path)
			Quit
		}
		Set request."shared_folder_id"=sharedId
		Do request.%Set("leave_a_copy",0,"boolean")
		Set sc=connection.MakeRPCRequest("sharing/remove_folder_member",request,.response)
		If $$$ISERR(sc) Quit

		// We must wait for the share to complete.
		Set asyncId=response."async_job_id"
		If asyncId'="" {
			Set hangTime=.25
			For {
				Set asyncRequest={}
				Set asyncRequest."async_job_id"=asyncId
				Set sc=connection.MakeRPCRequest("sharing/check_remove_member_job_status",asyncRequest,.response)
				If $$$ISERR(sc) Quit
				If response.".tag"="complete" Quit
				hang hangTime
				Set hangTime=2*hangTime
			}
			If $$$ISERR(sc) Quit
		}

		// Handle error response in body
		Set err=response."member_error"
		If err'="" {
			If $isobject(err) Set err=err.%ToJSON()
			Set sc=$$$ERROR($$$MFTErrorResponse,err)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:UnshareFolder]","MFT",sc)
	}
	Quit sc
}

/// Unshare a folder from all users.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// Passing intemInfo is for iternal use only.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod UnshareFolderAll(connection As %SYS.MFT.Connection.Dropbox, path As %String, itemInfo As %MFT.ItemInfo = "") As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:UnshareFolderAll]","path="_$get(path))

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		If $isobject(itemInfo) {
			Set path=itemInfo.ItemId
		} Else {
			// Get the internal id
			Set sc=..GetItemInfo(connection,path,.itemInfo)
			If $$$ISERR(sc) Quit

			If '$isobject(itemInfo) {
				Set sc=$$$ERROR($$$MFTFolderExpected,path)
				Quit
			}
		}
		
		// Request the folder be unshared.
		Set request={}
		Set sharedId=..GetSharedFolderId(itemInfo)
		If sharedId="" {
			Set sc=$$$ERROR($$$MFTNotSharedFolder,path)
			Quit
		}
		Set request."shared_folder_id"=sharedId
		Set sc=connection.MakeRPCRequest("sharing/unshare_folder",request,.response)
		If $$$ISERR(sc) Quit
		
		// We must wait for the unshare to complete.
		If response.".tag"="async_job_id" {
			Set asyncId=response."async_job_id"
			Set hangTime=.25
			For {
				Set asyncRequest={}
				Set asyncRequest."async_job_id"=asyncId
				Set sc=connection.MakeRPCRequest("sharing/check_job_status",asyncRequest,.response)
				If $$$ISERR(sc) Quit
				If response.".tag"="complete" Quit
				hang hangTime
				Set hangTime=2*hangTime
			}
			If $$$ISERR(sc) Quit
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:UnshareFolderAll]","MFT",sc)
	}
	Quit sc
}

/// MountFolder is a Dropbox specific method to mount a shared folder that was shared by a different user.
/// MountFolder is needed since folders are not available to a user until he does the mount.
/// Since Dropbox will always share folders at the root of the receiving user, only a folder name is needed.
/// MountFolder must be executed using the connection for the user being shared with, not the owner's connection.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod MountFolder(connection As %SYS.MFT.Connection.Dropbox, folderName As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:MountFolder]","folderName="_folderName)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Find the shared_folder_id of the specified folder.
		Set sc=..GetMountableFolder(connection,folderName,.sharedFolderId,.isMounted)
		If $$$ISERR(sc) Quit
		// All done if the folder is already mounted.
		If isMounted Quit
		
		// Request the that the specified folder be mounted
		Set request={}
		Set request."shared_folder_id"=sharedFolderId
		Set sc=connection.MakeRPCRequest("sharing/mount_folder",request,.response)
		If $$$ISERR(sc) Quit

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:MountFolder]","MFT",sc)
	}
	Quit sc
}

/// UnmountFolder is a Dropbox specific method to unmount a shared folder that was shared by a different user.
/// UnmountFolder is needed since folders need to be mounted before a user different than the owner
/// may access them even if they are shared.
/// Since Dropbox will always share folders at the root of the receiving user, only a folder name is needed.
/// UnmountFolder must be executed using the connection for the user being shared with, not the owner's connection.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod UnmountFolder(connection As %SYS.MFT.Connection.Dropbox, folderName As %String) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:UnmountFolder]","folderName="_folderName)

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Find the shared_folder_id of the specified folder.
		Set sc=..GetMountableFolder(connection,folderName,.sharedFolderId,.isMounted)
		If $$$ISERR(sc) Quit
		// All done if the folder is already mounted.
		If isMounted Quit
		
		// Request the that the specified folder be mounted
		Set request={}
		Set request."shared_folder_id"=sharedFolderId
		Set sc=connection.MakeRPCRequest("sharing/unmount_folder",request,.response)
		If $$$ISERR(sc) Quit

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:UnmountFolder]","MFT",sc)
	}
	Quit sc
}

/// GetMountableFolder is an internal method to get the shared_folder_id for the specified mountable folder.
/// GetMountableFolder sets isMounted to true if the folder is already mounted.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.
ClassMethod GetMountableFolder(connection As %SYS.MFT.Connection.Dropbox, folderName As %String, Output folderId As %String, Output isMounted As %Boolean) As %Status [ Internal ]
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetMountableFolder]","folderPath="_folderName)
		Set (isMounted,folderId)=""
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request the list of shared mountable folders.
		Set request={}
		Set sc=connection.MakeRPCRequest("sharing/list_mountable_folders",request,.response)
		If $$$ISERR(sc) Quit

		// Look for the path in the returned list
		Set found=0
		For {
			// Validate the response	
			Set entries=response.entries
			If '$isobject(entries) || ($classname(entries)'="%Library.DynamicArray") {
				Set text=$extract(response.%ToJSON(),1,200)
				Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetMountableFolder",text)
				Quit
			}
			
			// Look for the path in the returned list
			Set iterator=entries.%GetIterator()
			While iterator.%GetNext(.key,.item) {
				// Only check the folder name
				If item.name=folderName Set found=1 Quit
			}
			// If found, then return
			If found {
				Set folderId=item."shared_folder_id"
				Set isMounted=(item."path_lower"'="")
				Quit
			}
			
			// If all entries read, then we are done.
			If response.cursor="" Quit

			// Request additional folder contents if has_more flag true.
			Set request={}
			Set request.cursor=response.cursor
			Set sc=connection.MakeRPCRequest("sharing/list_mountable_folders/continue",request,.response)
			If $$$ISERR(sc) Quit
		}
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	If $$$ISOK(sc),'found {
		Set sc=$$$ERROR($$$MFTNotSharedFolder,folderName)
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:MountFolder]","MFT",sc)
	}
	Quit sc
}

/// Get the internal shared folder id
ClassMethod GetSharedFolderId(itemInfo As %MFT.ItemInfo) As %String [ Internal ]
{
	Set sharedId=""
	Set details=##class(%DynamicObject).%FromJSON(itemInfo.Details)
	If $isobject(details) {
		Set sharingInfo=details."sharing_info"
		If $isobject(sharingInfo) {
			Set sharedId=sharingInfo."shared_folder_id"
		}
	}
	Quit sharedId
}

/// Unshare a file from all users.<br>
/// This method requires a connection based on a Dropbox User application with Full Dropbox permission.<br>
/// For internal use only.
ClassMethod UnshareFileAll(connection As %SYS.MFT.Connection.Dropbox, ByRef itemInfo As %MFT.ItemInfo = "") As %Status [ Internal ]
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:UnshareFileAll]","")

		// Request the file be unshared.
		Set request={}
		Set request.file=itemInfo.ItemId
		Set sc=connection.MakeRPCRequest("sharing/unshare_file",request,.response)
		If $$$ISERR(sc) Quit

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:UnshareFileAll]","MFT",sc)
	}
	Quit sc
}

/// Create a new user.
/// The Userid and Detail properties are filled in by CreateUser if it is successful.<br>
/// This method requires a connection based on a Dropbox Business application with Team Memeber Management permission.
ClassMethod CreateUser(connection As %SYS.MFT.Connection.Dropbox, userInfo As %MFT.UserInfo) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:CreateUser]","username="_userInfo.Username)
		
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request that the user be created.
		Set member={}
		Set member."member_email"=userInfo.Username
		Set name=$zstrip(userInfo.Name,"<>W")
		If $length(name," ")>1 {
			Set member."member_given_name"=$piece(name," ",1,*-1)
			Set member."member_surname"=$piece(name," ",*)
		} Else {
			Set member."member_surname"=name
		}
		Do member.%Set("send_welcome_email",1,"boolean")
		Set newMembers=[]
		Do newMembers.%Push(member)
		Set request={}
		Set request."new_members"=newMembers
		// ^ISC.MFT("ForceAsync") is set to true to test async response
		If $get(^ISC.MFT("ForceAsync")) {
			Do request.%Set("force_async",1,"boolean")
		}
		Set sc=connection.MakeRPCRequest("team/members/add",request,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set error=0
		Set tag=response.".tag"
		If tag="complete" {
		} ElseIf tag="async_job_id" {
			If response."async_job_id"="" Set error=1
		} Else {
			Set error=1
		}
		
		// Wait for complete if asynchronous response
		If 'error,tag="async_job_id" {
			Set jobid=response."async_job_id"
			// repeat request until limit
			For i=1:1:10 {
				Hang 1
				Set request={}
				Set request."async_job_id"=jobid
				Set sc=connection.MakeRPCRequest("team/members/add/job_status/get",request,.response)
				If $$$ISERR(sc) Quit
				
				Set tag=response.".tag"
				If tag="in_progress" Continue
				If tag="complete" Quit
				If tag="failed" {
					Set sc=$$$ERROR($$$MFTAddUserError,response.failed)
					Quit
				} Else {
					Set error=1
				}
			}
			// Return error if no response in time
			If tag'="complete" {
				Set sc=$$$ERROR($$$MFTAddUserError,"timed out waiting for async response")
				Quit
			}
		}
	
		If 'error,tag="complete" {
			Set complete=response.complete
			If '$isobject(complete) || ($classname(complete)'="%Library.DynamicArray") || (complete.%Size()'=1) {
				Set error=1
			} Else {
				Set info=complete.%Get(0)
			}
			If info.".tag"="success" {
				Set userInfo=..CreateUserInfo(info.profile)
			} Else {
				Set sc=$$$ERROR($$$MFTAddUserError,info.".tag"_", "_info.%Get(info.".tag"))
				Quit
			}	
		}
		
		If error {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"CreateUser",text)
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:CreateUser]","MFT",sc)
	}
	Quit sc
}

/// Delete the user that is specified by the id.
/// For Dropbox the user will remain a Dropbox user, but be removed from the team.<br>
/// This method requires a connection based on a Dropbox Business application with Team Memeber Management permission.
ClassMethod DeleteUserById(connection As %SYS.MFT.Connection.Dropbox, userid As %String) As %Status
{
	$$$SysLog(2,"MFT","[%MFT.Dropbox:DeleteUserById]","userid="_userid)
		
	/// Delete the user by userid
	Set user={}
	Set user.".tag"="team_member_id"
	Set user."team_member_id"=userid
	Set sc=..DeleteUserCommon(connection,user)

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:DeleteUserById]","MFT",sc)
	}
	Quit sc
}

/// Delete the user that is specified by the email address (i.e. username).
/// For Dropbox the user will remain a Dropbox user, but be removed from the team.<br>
/// This method requires a connection based on a Dropbox Business application with Team Memeber Management permission.
ClassMethod DeleteUser(connection As %SYS.MFT.Connection.Dropbox, username As %String) As %Status
{
	$$$SysLog(2,"MFT","[%MFT.Dropbox:DeleteUser]","username="_username)
		
	/// Delete the user by username
	Set user={}
	Set user.".tag"="email"
	Set user.email=username
	Set sc=..DeleteUserCommon(connection,user)

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:DeleteUser]","MFT",sc)
	}
	Quit sc
}

/// Common code to get the user information response
ClassMethod DeleteUserCommon(connection As %SYS.MFT.Connection.Dropbox, user As %DynamicObject) As %Status [ Internal ]
{
	Try {
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request that the item be deleted.
		Set request={}
		Set request.user=user
		Set sc=connection.MakeRPCRequest("team/members/remove",request,.response)
		If $$$ISERR(sc) {
			// Not finding an item is not an error, just no item returned.
			Set err=$system.Status.GetErrorText(sc)
			If err["""error_summary"": ""user_not_found" {
				Set sc=$$$OK
			} ElseIf err["""error_summary"": ""user_not_in_team" {
				Set sc=$$$OK
			}
			Quit
		}

		// Validate the response
		Set error=0
		Set tag=response.".tag"
		If tag="async_job_id" {
			If response."async_job_id"="" Set error=1
		} ElseIf tag'="complete" {
			Set error=1
		}
		
		// Wait for complete if asynchronous response
		If 'error,tag="async_job_id" {
			Set jobid=response."async_job_id"
			For i=1:1:10 {
				Hang 1
				Set request={}
				Set request."async_job_id"=jobid
				Set sc=connection.MakeRPCRequest("team/members/remove/job_status/get",request,.response)
				If $$$ISERR(sc) Quit
				
				Set tag=response.".tag"
				If tag="in_progress" Continue
				If tag="complete" Quit
				Set error=1
				Quit
			}
			// Return error if no response in time
			If tag'="complete" {
				Set sc=$$$ERROR($$$MFTAddUserError,"timed out waiting for async response")
				Quit
			}
		}
	
		If error {
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"DeleteUserById",text)
			Quit
		}

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:DeleteUserById]","MFT",sc)
	}
	Quit sc
}

/// Retrieve the %MFT.UserInfo specified by the service defined Userid.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".<br>
/// This method requires a connection based on a Dropbox Business application with Team Memeber Management permission.
ClassMethod GetUserById(connection As %SYS.MFT.Connection.Dropbox, userid As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	$$$SysLog(2,"MFT","[%MFT.Dropbox:GetUserById]","userid="_userid)

	If userid="" {	
		/// If useid="", theen return userInfo for the user associated with this connection.
		/// We do this because ModifiedBy for files and folders is not specified for the connection user.
		Set member={}
		Set member.".tag"="email"
		Set member.email=connection.Username
	} Else {
		// userid has been specified
		Set member={}
		Set member.".tag"="team_member_id"
		Set member."team_member_id"=userid
	}

	/// Request the user information
	Set sc=..GetUserInfo(connection,member,.userInfo)

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetUserById]","MFT",sc)
	}
	
	Quit sc
}

/// Retrieve the %MFT.UserInfo specified by the username
/// which is the email address for all currently supported services.
/// GetUser is potentially less efficient than GetUserById.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".<br>
/// This method requires a connection based on a Dropbox Business application with Team Memeber Management permission.
ClassMethod GetUser(connection As %SYS.MFT.Connection.Dropbox, username As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	$$$SysLog(2,"MFT","[%MFT.Dropbox:GetUser]","username="_username)

	/// Request the user information
	Set member={}
	Set member.".tag"="email"
	Set member.email=username
	Set sc=..GetUserInfo(connection,member,.userInfo)

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetUser]","MFT",sc)
	}
	Quit sc
}

/// Common code to get the user information response
ClassMethod GetUserInfo(connection As %SYS.MFT.Connection.Dropbox, member As %DynamicObject, Output userInfo As %MFT.UserInfo) As %Status [ Internal ]
{
	Try {
		Set userInfo=""
		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}

		// Request the user information
		Set members=[]
		Do members.%Push(member)
		Set request={}
		Set request."members"=members
		Set sc=connection.MakeRPCRequest("team/members/get_info",request,.response)
		If $$$ISERR(sc) Quit

		// Validate the response
		Set error=0
		If '$isobject(response) || ($classname(response)'="%Library.DynamicArray") || (response.%Size()'=1) {
			Set error=1
		}
		
		/// Process the response
		If 'error {
			Set entry=response.%Get(0)
			Set tag=entry.".tag"
			If tag="member_info" {
				// Get the member info
				Set userInfo=..CreateUserInfo(entry.profile)
			} ElseIf tag="id_not_found" {
				// Not an error if the user is not found, just return userInfo=""
				Set userInfo=""
			} Else {
				Set error=1
			}
		}
		
		If error {
			// Unexpected response
			Set text=$extract(response.%ToJSON(),1,200)
			Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUser",text)
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	Quit sc
}

/// Return the list of all currently defined users for this team or enterprise.<br>
/// This method requires a connection based on a Dropbox Business application with Team Memeber Management permission.
ClassMethod GetUserList(connection As %SYS.MFT.Connection.Dropbox, Output userList As %MFT.UserList) As %Status
{
	Try {
		$$$SysLog(2,"MFT","[%MFT.Dropbox:GetUserList]","")

		// Validate the connection
		If connection.Service'=$piece($classname(),".",*) {
			Set sc=$$$ERROR($$$MFTBadConnection)
			Quit
		}
		
		// Request the user list.
		Set userList=##class(%MFT.UserList).%New()
		Set request={}
		// ^ISC.MFT("ForceAsync") is set to true to test async response
		If $get(^ISC.MFT("ForceAsync")) {
			Set request.limit=2
		}
		Do request.%Set("include_removed",0,"boolean")
		Set sc=connection.MakeRPCRequest("team/members/list",request,.response)
		If $$$ISERR(sc) Quit

		// Add users to the list
		For {
			// Validate the response	
			If (response.cursor="") || (response."has_more"="") {
				Set text=$extract(response.%ToJSON(),1,200)
				Set sc=$$$ERROR($$$MFTUnexpectedResponse,"GetUserList",text)
				Quit
			}
			
			// Add the entries in this response to the list.
			Set entries=response.members
			If $isobject(entries),$classname(entries)="%Library.DynamicArray" {
				Set iterator=entries.%GetIterator()
				While iterator.%GetNext(.key,.value) {
					// Create the returned user info.
					Set userInfo=..CreateUserInfo(value.profile)
					Do userList.Users.Insert(userInfo)
				}
			}
			
			// If all entries read, then we are done.
			If 'response."has_more" Quit

			// Request additional folder contents if has_more flag true.
			Set request={}
			Set request.cursor=response.cursor
			Set sc=connection.MakeRPCRequest("team/members/list/continue",request,.response)
			If $$$ISERR(sc) Quit
		}
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.Dropbox:GetUserList]","MFT",sc)
	}
	Quit sc
}

/// Create an UserInfo object from a Dropbox response
ClassMethod CreateUserInfo(response As %DynamicObject) As %MFT.UserInfo [ Internal ]
{
	// The item has been deleted.
	If response.deleted Quit ""

	// Build the UserInfo object.
	Set userInfo=##class(%MFT.UserInfo).%New()
	Set userInfo.Username=response.email
	Set userInfo.Name=response.name."display_name"
	Set userInfo.Userid=response."team_member_id"
	Set userInfo.Details=response.%ToJSON()
	Quit userInfo
}

}
