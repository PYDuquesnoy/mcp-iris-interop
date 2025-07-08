/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %mft

/// The File Management API is an implementation of access to the REST APIS from Box, Dropbox and Accellion Kiteworks.
/// The connection to the underlying service is defined by the connection object, a subclass of %SYS.MFT.Connection.Base.
/// This connection is passed as the first argument to each of the API calls either as the name of a saved
/// persistent object or as a oref of a connection object.
/// The remote files and folders being operated upon will be specified as a Unix style path.
/// If the remote path is relative then it will be relative to the current remote folder.
/// The root remote folder will always be denoted as "/".
/// The local files will be specified as usual by a file system based path.
/// If the local path is relative it will be relative to the manager directory.<br>
/// 
/// The file management API will be implemented in subclasses of the %MFT.API class which are particular
/// to the vendor service.
Class %MFT.API Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Get the connection object associated with the specified connection name.
ClassMethod GetConnection(connectionName As %String, Output sc As %Status) As %SYS.MFT.Connection.Base
{
	$$$SysLog(2,"MFT","[%MFT.API:GetConnection]","connectionName="_connectionName)
	Quit ##class(%SYS.MFT.Connection.Base).%OpenId(connectionName,,.sc)
}

/// Returns the current remote folder path.
ClassMethod GetCurrentFolder(connection As %SYS.MFT.Connection.Base, Output folderPath As %String) As %Status
{
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"MFT","[%MFT.API:GetCurrentFolder]","")

		Set folderPath=connection.CurrentFolder
		$$$SysLog(3,"MFT","[%MFT.API:GetCurrentFolder]","folderPath="_folderPath)

	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.API:GetCurrentFolder]","MFT",sc)
	}
	Quit sc
}

/// Set the current remote folder path.
ClassMethod SetCurrentFolder(connection As %SYS.MFT.Connection.Base, folderPath As %String) As %Status
{
	Set sc=$$$OK
	
	Try {
		$$$SysLog(3,"MFT","[%MFT.API:SetCurrentFolder]","folderPath="_folderPath)

		Set folderPath=$translate(folderPath,"\","/")
		If $extract(folderPath,*)'="/" Set folderPath=folderPath_"/"
		Set connection.CurrentFolder=connection.NormalizePath(folderPath)
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}

	If $$$ISERR(sc) {
		Do ##class(%OAuth2.Utils).LogError("[%MFT.API:SetCurrentFolder]","MFT",sc)
	}
	Quit sc
}

/// Get the form of id for a file or folder that is most efficient for subsequent calls.
/// GetRequestId will return either an id of the form "id:<id>" or a full path depending on which is more efficient.
/// This method is included to allow the id for future requests to be saved in the most efficient form.
ClassMethod GetRequestId(connection As %SYS.MFT.Connection.Base, itemInfo As %MFT.ItemInfo) As %String
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetRequestId",connection,itemInfo)
}

/// Return the item info object which describes the specified folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the path to specify the current folder.
/// If a folder does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod GetFolderInfo(connection As %SYS.MFT.Connection.Base, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetFolderInfo",connection,path,.itemInfo)
}

/// Get the external username that corresponds to the specified internal user id.
ClassMethod GetUsername(connection As %SYS.MFT.Connection.Base, internalId As %String, Output username As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetUsername",connection,internalId,.username)
}

/// Delete the remote folder.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the folder will be permanently deleted. Otherwise the folder will be moved to trash.<br>
/// If the remote folder does not exist at the specified path, then $$$OK is returned as status.
ClassMethod DeleteFolder(connection As %SYS.MFT.Connection.Base, path As %String, permanent As %Boolean = 0) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"DeleteFolder",connection,path,permanent)
}

/// Creates the remote folder at the specified folderPath.
/// Each level of the folder path should be created separately if it does not already exist.
/// An %MFT.ItemInfo object is returned for the new folder.
ClassMethod CreateFolder(connection As %SYS.MFT.Connection.Base, folderPath As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"CreateFolder",connection,folderPath,.itemInfo)
}

/// Return the folder contents object for the specified folder.
/// folderPath may be a folder path.
/// folderPath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// "" May be used as the folderPath to specify the current folder.
/// The FolderContents object will include a list of %MFT.ItemInfo objects which contain a file or folder name
/// and some additional simple information.
ClassMethod GetFolderContents(connection As %SYS.MFT.Connection.Base, folderPath As %String, recursive As %Boolean = 0, Output folderContents As %MFT.FolderContents) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetFolderContents",connection,folderPath,recursive,.folderContents)
}

/// Return the item info object which describes the specified file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// If a file does not exist at the specified path, then $$$OK is returned as status and itemInfo is returned as "".
ClassMethod GetFileInfo(connection As %SYS.MFT.Connection.Base, path As %String, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetFileInfo",connection,path,.itemInfo)
}

/// Delete the remote file.
/// path may be a file path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.<br>
/// If permanent is true, then the file will be permanently deleted. Otherwise the file will be moved to trash.
/// If the remote file does not exist at the specified path, then $$$OK is returned as status.
ClassMethod DeleteFile(connection As %SYS.MFT.Connection.Base, path As %String, permanent As %Boolean = 0) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"DeleteFile",connection,path,permanent)
}

/// Update the specified remote file with the contents of the specified local file.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.
ClassMethod UploadFile(connection As %SYS.MFT.Connection.Base, localFilePath As %String, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"UploadFile",connection,localFilePath,filePath,replace,.itemInfo)
}

/// Update the specified remote file with the contents of the specified stream.
/// filePath must be a file path.  An id may not be specified.
/// If replace is true, then an existing file of the same name will be replaced.  
/// The default is to return an error if a replacement is attempted.
ClassMethod UploadStream(connection As %SYS.MFT.Connection.Base, stream As %BinaryStream, filePath As %String, replace As %Boolean = 0, Output itemInfo As %MFT.ItemInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"UploadStream",connection,stream,filePath,replace,.itemInfo)
}

/// Download the specified remote file and store at the location given by localFilePath.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod DownloadFile(connection As %SYS.MFT.Connection.Base, filePath As %String, localFilePath As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"DownloadFile",connection,filePath,localFilePath)
}

/// Download the specified remote file and store in the specified stream which must be a %FileBinaryStream or a %GlobalBinaryStream.
/// If stream is not specified, then a %GlobalBinaryStream will be created.
/// filePath may be a file path.
/// filePath may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod DownloadStream(connection As %SYS.MFT.Connection.Base, filePath As %String, ByRef stream As %BinaryStream) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"DownloadStream",connection,filePath,.stream)
}

/// Share a folder with a list of users pass as a $list.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
/// The "editor" and "viewer" access levels are supported for all vendors.
/// In addition, vendor specific access levels are supported.
ClassMethod ShareFolder(connection As %SYS.MFT.Connection.Base, path As %String, accessLevel As %String = "viewer", users As %List) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"ShareFolder",connection,path,.accessLevel,.users)
}

/// Unshare a folder from a specified user.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod UnshareFolder(connection As %SYS.MFT.Connection.Base, path As %String, user As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"UnshareFolder",connection,path,user)
}

/// Unshare a folder from all users.
/// path may be a folder path.
/// path may also be specified as an id of the form "id:<id>" which was obtained from a %MFT.ItemInfo object.
ClassMethod UnshareFolderAll(connection As %SYS.MFT.Connection.Base, path As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"UnshareFolderAll",connection,path)
}

/// MountFolder is a Dropbox specific method to mount a shared folder that was shared by a different user.
/// MountFolder is treated as a NOP for all other services.
ClassMethod MountFolder(connection As %SYS.MFT.Connection.Base, folderName As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"MountFolder",connection,folderName)
}

/// UnmountFolder is a Dropbox specific method to unmount a shared folder that was shared by a different user.
/// UnmountFolder is treated as a NOP for all other services.
ClassMethod UnmountFolder(connection As %SYS.MFT.Connection.Base, folderName As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"UnmountFolder",connection,folderName)
}

/// Delete the user that is specified by the id.
ClassMethod DeleteUserById(connection As %SYS.MFT.Connection.Base, userid As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"DeleteUserById",connection,userid)
}

/// Delete the user that is specified by the email address (i.e. username).
ClassMethod DeleteUser(connection As %SYS.MFT.Connection.Base, username As %String) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"DeleteUser",connection,username)
}

/// Create a new user.
/// The Userid and Detail properties are filled in by CreateUser if it is successful.
ClassMethod CreateUser(connection As %SYS.MFT.Connection.Base, userInfo As %MFT.UserInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"CreateUser",connection,userInfo)
}

/// Retrieve the %MFT.UserInfo specified by the service defined Userid.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".
ClassMethod GetUserById(connection As %SYS.MFT.Connection.Base, userid As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetUserById",connection,userid,.userInfo)
}

/// Retrieve the %MFT.UserInfo specified by the username
/// which is the email address for all currently supported services.
/// GetUser is potentially less efficient than GetUserById.
/// If the user does not exist, then $$$OK is returned as status and userInfo is returned as "".
ClassMethod GetUser(connection As %SYS.MFT.Connection.Base, username As %String, Output userInfo As %MFT.UserInfo) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetUser",connection,username,.userInfo)
}

/// Return the list of all currently defined users for this team or enterprise.
ClassMethod GetUserList(connection As %SYS.MFT.Connection.Base, Output userList As %MFT.UserList) As %Status
{
	Quit $classmethod($$$MFTAPIClassname(connection),"GetUserList",connection,.userList)
}

}
