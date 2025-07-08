/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// <p><b>For information on this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Library.File">Using %Library.File</a>.</p>
/// The <CLASS>%File</CLASS> class represents a disk file. It contains a
/// number of class methods that provide a number of file system 
/// services.
/// 
/// <p>For example,
/// 
/// <EXAMPLE>
/// If ##class(%File).Exists("file.txt") Write "It exists",!
/// </EXAMPLE>
/// 
/// <p>You can also create an instance of a <CLASS>%File</CLASS> object that 
/// represents a particular file. <CLASS>%File</CLASS> makes a number of file 
/// attributes accessible as properties as well as providing a 
/// <CLASS>%AbstractStream</CLASS> interface on the file.
/// 
/// <p>For example,
/// <EXAMPLE>
/// Set file=##class(%File).%New("file.txt")
/// Write file.Size
/// Do file.Open("WSN")
/// Do file.WriteLine("This is a line of text")
/// </EXAMPLE>
/// Note that this class is a fairly simple wrapper around the ObjectScript file commands. For simply reading/writing to a file it is suggested that
/// you look at the <class>%Stream.FileCharacter</class> and
/// <class>%Stream.FileBinary</class> classes. These open the file using the
/// correct mode automatically in order to read or write to the file and so
/// are simpler to use.
Class %Library.File Extends %AbstractStream [ System = 2 ]
{

Parameter SQLPUBLICSECURITY = "{""File_DriveList"":""Requires:%Development:USE"",""File_FileSet"":""Requires:%Development:USE"",""File_ParseDirectory"":""E""}";

/// The name of this file.
Property Name As %String(MAXLEN = 5000);

/// Read only property that returns the canonical filename if the file is open and "" if the file is not open.
Property CanonicalName As %String(MAXLEN = 5000) [ Calculated ];

Method CanonicalNameGet() As %String
{
	If '..IsOpen Quit ""
	Set io=$IO
	Use ..Name Set name=$zio
	Use io
	Quit name
}

/// The creation date for this file (rounded to the millisecond). Only Windows
/// maintains the created date; other operating systems return the date
/// of the last file "status" change.
Property DateCreated As %Date [ Calculated ];

/// The last modified date for this file (rounded to the millisecond).
Property DateModified As %Date [ Calculated ];

/// True (1) if this file is currently open, false (0) otherwise.
Property IsOpen As %Boolean [ InitialExpression = 0 ];

Property openmode As %String(MAXLEN = 5000) [ Internal, Private ];

Method %Load(sid As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
 Quit $$$OK
}

ClassMethod %DeleteData(soid As %String, concurrency As %Integer) As %Status [ Private, ProcedureBlock = 1 ]
{
	QUIT $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Quit $$$OK
}

/// Returns true (1) if <var>filename</var> exists.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod Exists(filename As %String, Output return As %Integer) As %Boolean
{
	Set return=$$$FileExistsRet(filename)
	Quit return=0
}

/// Tests if <var>filename</var> is a directory.
/// returns 1 if it is a directory, otherwise, returns 0.
ClassMethod DirectoryExists(filename As %String) As %Boolean
{
	Quit $$$FileDirectoryExists(filename)
}

/// Returns a normalized absolute directory from the <var>directory</var> that is passed in including any trailing directory delimiter.<p>
/// If the <var>directory</var> is a relative path (rather than an absolute path) then the <var>absolutedirectory</var> parameter
/// determines what we normalize the <var>directory</var> compoent relative to. If <var>absolutedirectory</var> is "" or not passed in then
/// we normalize relative to the current default directory otherwise we will normalize relative to the passed in
/// <var>absolutedirectory</var>.<p>
/// <var>addnull</var> use is deprecated
ClassMethod NormalizeDirectory(directory As %String, absolutedirectory As %String = "", addnull As %Boolean) As %String
{
	If absolutedirectory'="" {
		Try {
			Set olddir=$$$FileSetCurrentDir(absolutedirectory)
			Set return=$$$FileNormalizeDirectoryFull(directory)
		} Catch {
			Set return=""
		}
		If $get(olddir)'="" Do $$$FileSetCurrentDir(olddir)
		Quit return
	}
	Set addnull=0
	Try {
		Set return=$$$FileNormalizeDirectoryFull(directory)
	} Catch {
		Set return=""
	}
	Quit return
}

/// Returns the normalized form of the <var>filename</var>.
/// If you pass <var>directory</var> then it will normalize this filename relative to the provided directory,
/// if no <var>directory</var> is supplied then it is relative to the current default directory. If the
/// <var>directory</var> does not exist then this method will return the empty string. Otherwise, this method
/// returns the normalized full path name of the specified file.
ClassMethod NormalizeFilename(filename As %String, directory As %String = "") As %String
{
	If '$data(filename) Quit ""
	Try {
		If directory'="" Set olddir=$$$FileSetCurrentDir(directory)
		Set name=$$$FileNormalizeFilenameFull(filename)
	} Catch {
		Set name=""
	}
	If $get(olddir)'="" Do $$$FileSetCurrentDir(olddir)
	Quit name
}

/// Returns the canonical form of the <var>filename</var>. If the file can not be opened then it will return ""
ClassMethod CanonicalFilename(filename As %String) As %String
{
	Set opened=0,io=$IO,name=""
	Try {
		#;SML3019 ; Handle file name with ",".
		If '$LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$ZU(12,filename)) {
			Open filename:"R":0 Else  Quit
			Set opened=1
		}
		Use filename Set name=$zio
	} Catch {}
	Use io
	If opened Close filename
	Quit name
}

/// Returns the path of the manager directory.
ClassMethod ManagerDirectory() As %String [ CodeMode = expression ]
{
$$$FileNormalizeDirectory($$$FileMgrDir)
}

/// Deletes the file <var>filename</var>. Returns true if it succeeds and false otherwise.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod Delete(filename As %String, Output return As %Integer) As %Boolean
{
	If filename["*" {
		Quit ..ComplexDelete(.filename,.return)
	} Else {
		Set return=$$$FileDeleteRet(filename)
		Quit 'return
	}
}

/// Return true if the file is read only and false if it is writable
ClassMethod ReadOnly(filename As %String) As %Boolean [ CodeMode = expression ]
{
$$$FileReadOnly(filename)
}

/// Handle delete of cases where <var>filename</var> contains a wildcard.
/// Note: this does not delete subdirectories in the given directory; only files are removed.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod ComplexDelete(filename As %String, Output return As %Integer) As %Boolean
{
	Set resultset=##class(%ResultSet).%New("%File:FileSet"),return=0
	Do resultset.Execute(..GetDirectory(filename),..GetFilename(filename))
	Set exit=1
	For {
		Quit:'resultset.Next()
		Set file=resultset.Data("Name")
		Set r=$$$FileDeleteRet(file) If r,exit Set exit=0,return=r
	}
	Quit exit
}

/// Return the canonical form of the directory name <var>filename</var>.
/// When <var>filename</var> is a non-full path directory, it will prefix
/// the <var>filename</var> with Manager Path instead of current directory.
ClassMethod ComputeFullDBDir(filename As %String) As %String
{
	Quit $$ComputeFullDBDir^%SYS.API(filename)
}

/// Creates a directory with name <var>name</var>. Returns true if it succeeds and false otherwise.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod CreateDirectory(name As %String, Output return As %Integer) As %Boolean
{
	Set return=$$$FileCreateDirectoryRet(name)
	Quit 'return
}

/// Given a directory name and the name of a new directory create this directory inside
/// the given directory. Return true if it succeeds and false otherwise.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod CreateNewDir(directory As %String, name As %String, Output return As %Integer) As %Boolean
{
	Set directory=$$$FileNormalizeDirectoryFull(directory),return=0
	If directory="" Quit 0
	If $$$isWINDOWS {
		Set directory=$translate(directory,"/","\")
		If $extract(directory,*)'="\" Set directory=directory_"\"
		Set newdir=directory_name
	} Else {
		Set directory=$translate(directory,"\","/")
		If $extract(directory,*)'="/" Set directory=directory_"/"
		Set newdir=directory_name
	}
	Set return=$$$FileCreateDirectoryRet(newdir)
	Quit 'return
}

/// Create this directory and all the parent directories if they do not exist. This differs from
/// <method>CreateDirectory</method> as that method only creates one new directory where as
/// this will create the entire chain of directories. Returns true if it succeeds and false otherwise.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod CreateDirectoryChain(name As %String, Output return As %Integer) As %Boolean
{
	Set name=$$$FileNormalizeDirectoryFull(name),return=0
	If name="" Quit 0
	If $$$FileDirectoryExists(name) Quit 1
	Set return=$$$FileCreateDirectoryChainRet(name)
	Quit 'return
}

/// Given a directory name and the name of a sub directory create the name for the
/// subdirectory inside the given directory. Return the new directory name.
/// This is useful as the parsing of filenames on Unix/Windows is different.
ClassMethod SubDirectoryName(directory As %String, name As %String, normalized As %Boolean = 0) As %String
{
	Set newdir=$$$FileNormalizeDirectoryFull(directory)
	If newdir="" Quit ""
	If $$$isWINDOWS {
		Set newdir=$translate(newdir,"/","\")
		If $extract(newdir,*)'="\" Set newdir=newdir_"\"
		Set newdir=newdir_name_$select(normalized:"\",1:"")
	} Else {
		Set newdir=$translate(newdir,"\","/")
		If $extract(newdir,*)'="/" Set newdir=newdir_"/"
		Set newdir=newdir_name_$select(normalized:"/",1:"")
	}
	Quit newdir
}

/// Given a directory name, return the name of its parent directory.<br>
/// If the directory is already the root (e.g., "/" on Unix, "c:\" on Windows), return the root.
ClassMethod ParentDirectoryName(directory As %String) As %String
{
	Set directory=$$$FileNormalizeDirectoryFull(directory)
	If directory="" Quit ""
	Set newdir=..SubDirectoryName(directory,"..")
	// SubDirectoryName() doesn't normalize its return
	Quit $$$FileNormalizeDirectoryFull(newdir)
}

/// Pass in an array of paths you want to turn into a filename for the server platform, for example:
/// <example>Set dirs($i(dirs))=$system.Util.DataDirectory()
/// Set dirs($i(dirs))="httpd"
/// Set dirs($i(dirs))="logs"
/// Set filename=##class(%File).Construct(dirs...)</example>
/// If you want the name returned to be a directory terminated with a '/' or '\' then
/// pass in a null <var>dirs</var> entry as the last piece. You can also call
/// <method>Deconstruct</method> with the returned filename to turn this back into
/// an array like <var>dirs</var>. If you pass in a blank array it will return the
/// default directory.
ClassMethod Construct(dirs... As %String) As %String
{
	If $$$isUNIX {
		Set from="\",to="/",filename="/"
	} Else {
		Set from="/",to="\",filename=""
	}
	Set i=""
	For num=1:1 {
		Set i=$order(dirs(i),1,path) Quit:i=""
		Set path=$translate(path,from,to)
		Set filename=filename_path_$select($e(path,*)=to:"",1:to)
	}
	Set filename=$e(filename,1,*-1)
	Quit $select($s($e(filename,*)=to:1,1:0):$$$FileNormalizeDirectory(filename),1:$$$FileNormalizeFilename(filename))
}

/// Pass in a full valid <var>filename</var> for the server platform and it will decompose it into the <var>dirs</var> array
/// with each integer subscript being a part of the path, this array can then be passed into
/// <method>Construct</method> to reconstruct the filename again. So on a Unix server you need to pass this a valid Unix filename
/// and on a Windows server this should be passed a Windows filename.
ClassMethod Deconstruct(filename As %String, ByRef dirs As %String)
{
	Kill dirs
	Set hasterm=$case($e(filename,*),"/":1,"\":1,:0)
	Set filename=$select(hasterm:$$$FileNormalizeDirectory(filename),1:$$$FileNormalizeFilename(filename))
	Set filename=$translate(filename,"/","\")
	If $$$isWINDOWS {
		If $length($piece(filename,":"))=1 {
			Set item=$piece(filename,":")_":"
			Set dirs($i(dirs))=item,filename=$e($piece(filename,":",2,*),2,*)
		} ElseIf $extract(filename,1,2)="\\" {
			Set item=$piece(filename,"\",1,3)
			Set dirs($i(dirs))=item,filename=$piece(filename,"\",4,*)
		} Else {
			Set filename=""
		}
	} Else {
		Set filename=$extract(filename,2,*)
	}
	For i=1:1:$length(filename,"\") {
		Set dirs($i(dirs))=$piece(filename,"\",i)
	}
}

/// Given a full directory and filename this will return just the filename portion of this name.
/// This is useful as the parsing of filenames on Unix/Windows is different.
ClassMethod GetFilename(name As %String) As %String
{
	Quit $piece($translate(name,"/","\"),"\",*)
}

/// Given a full directory and filename this will return just the directory portion of this name.
/// This is useful as the parsing of filenames on Unix/Windows is different.
ClassMethod GetDirectory(name As %String, keepterm As %Boolean = 0) As %String
{
	If $get(name)="" Set name=$$$FileCurrentDir
	If $$$isWINDOWS {
		Set name=$translate(name,"/","\"),name=$piece(name,"\",1,*-1)
		If name'["\" Quit name_$select(name="":"",keepterm:"\",1:"")
		Quit $$$FileNormalizeDirectory(name_$select(keepterm:"\",1:""))
	} ElseIf $$$isUNIX {
		Set name=$translate(name,"\","/"),name=$piece(name,"/",1,*-1)
		If name'["/" Quit name_$select(keepterm:"/",1:"")
		Quit $$$FileNormalizeDirectory(name_$select(keepterm:"/",1:""))
	}
}

/// Return the number of pieces in this directory name
ClassMethod GetDirectoryLength(name As %String) As %Integer
{
	If $get(name)="" Set name=$$$FileCurrentDir
	Do ..ParseDirectoryExecute(.qhandle,..SubDirectoryName(name,"dummy"))
	If qhandle="" Quit 0
	Quit $listlength($list(qhandle))
}

/// Return the piece of a directory name
ClassMethod GetDirectoryPiece(name As %String, piece As %Integer, ByRef fullpath As %String, ByRef IsDrive As %Boolean) As %String
{
	If $get(name)="" Set name=$$$FileCurrentDir
	Do ..ParseDirectoryExecute(.qhandle,..SubDirectoryName(name,"dummy"))
	If qhandle="" Quit ""
	Set tmp=$listget($list(qhandle),piece),fullpath=$listget(tmp,3),IsDrive=$listget(tmp,2)
	Quit $listget(tmp)
}

/// Return the amount of total space and free space in either Bytes,MB,GB on a drive or directory
/// <br>
/// Name = Valid Drive or directory specification<br>
/// Flag = 0 - Return bytes<br>
/// Flag = 1 - Return MB (Default)<br>
/// Flag = 2 - Return GB<br>
/// <br>
/// MB and GB returned are rounded to 2 decimal places.<br>
/// Any error status returned is O/S level error. Note that on Windows
/// only drives have a measurement for free space and directories can not so
/// the <var>FreeSpace</var> is only returned for drives.
ClassMethod GetDirectorySpace(Name As %String, ByRef FreeSpace As %String, ByRef TotalSpace As %String, Flag As %Integer = 1) As %Status
{
	If $get(Name)="" Set Name=$$$FileCurrentDir
	Set $ztrap="Error"
	Set FreeSpace=0,TotalSpace=0
	Set Status=$zutil(140,13,Name)
	If +Status<0 Quit $$$ERROR($$$ErrorCodeIs,$zabs(Status))
	Set BlockSize=$piece(Status,",",4)
	If $$$isUNIX {
		Set FreeSpace=$piece(Status,",",1)*BlockSize
	} Else {
		Set FreeSpace=$piece(Status,",",2)*BlockSize
	}
	Set TotalSpace=$piece(Status,",",3)*BlockSize
	If Flag=1 Set Div=1024*1024
	If Flag=2 Set Div=1024*1024*1024
	If Flag'=0 {
		Set FreeSpace=$fn(FreeSpace/Div,"",2)
		Set TotalSpace=$fn(TotalSpace/Div,"",2)
	}
	Quit $$$OK
Error Set $ztrap=""
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

/// Given a directory name return it pulled apart into individual subdirectories starting at the root node
/// and working down to the last directory name
Query ParseDirectory(directory As %String(MAXLEN="")) As %Query(ROWSPEC = "Name:%String,IsDrive:%Boolean,Directory:%String") [ SqlProc ]
{
}

ClassMethod ParseDirectoryExecute(ByRef QHandle As %Binary, directory As %String) As %Status
{
	Set QHandle=""
	If directory="" Quit $$$OK
	If $extract(directory,*)'="\"&&($extract(directory,*)'="/") { Set directory=..GetDirectory(directory) } Else { Set directory=$$$FileNormalizeDirectory(directory) }
	If $$$isWINDOWS {
		Set directory=$translate(directory,"/","\")
		If $length($piece(directory,":"))=1 {
			Set item=$piece(directory,":")_":"
			Set QHandle=$listbuild($listbuild(item,1,item_"\")),directory=$piece(directory,":",2,*)
		} ElseIf $extract(directory,1,2)="\\" {
			Set item=$piece(directory,"\",1,3)
			Set QHandle=$listbuild($listbuild(item,0,item_"\")),directory=$piece(directory,"\",4,*)
		} Else {
			Quit $$$OK
		}
		For i=1:1:$length(directory,"\") {
			Set tmp=$piece(directory,"\",i)
			If tmp'="" {
				Set item=item_"\"_tmp
				Set QHandle=QHandle_$listbuild($listbuild(tmp,0,item_"\"))
			}
		}
	} ElseIf $$$isUNIX {
		Set QHandle=$listbuild($listbuild("/",0,"/"))
		Set directory=$translate(directory,"\","/"),item=""
		For i=1:1:$length(directory,"/") {
			Set tmp=$piece(directory,"/",i)
			If tmp'="" {
				Set item=item_"/"_tmp
				Set QHandle=QHandle_$listbuild($listbuild(tmp,0,item_"/"))
			}
		}
	}
	Set QHandle=$listbuild(QHandle,0)
	Quit $$$OK
}

ClassMethod ParseDirectoryClose(ByRef QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ParseDirectoryFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set item=$listget(QHandle,2)+1
	If QHandle=""||(item>$listlength($list(QHandle))) Set AtEnd=1,QHandle="",Row="" Quit $$$OK
	Set Row=$list($list(QHandle),item)
	Set $list(QHandle,2)=item
	Quit $$$OK
}

/// Removes directory <var>name</var>. Returns true if it succeeds and false otherwise.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod RemoveDirectory(name As %String, Output return As %Integer) As %Boolean
{
	Set return=$$$FileRemoveDirectoryRet(name)
	Quit 'return
}

/// Recursively remove directory <var>pTarget</var>. Returns true if it succeeds and false otherwise.
ClassMethod RemoveDirectoryTree(pTarget As %String) As %Boolean
{
#define RDTREE	RDTree
#define RDTREETEMP $$$ISCQUERYTEMP$$$RDTREE

	Set %objlasterror=$$$OK,$ZT="Trap"

	// Directory Name cannot be ""
	If $Get(pTarget)="" Set %objlasterror=$$$ERROR($$$DirectoryNameRequired) Quit 0

	// If the target doesn't exist, then we're done
	If '$$$FileDirectoryExists(pTarget) Set %objlasterror = $$$ERROR($$$DirectoryNotExist,pTarget) Quit 0

	// Normalize the input directory names
	Set pTarget = $$$FileNormalizeDirectoryFull(pTarget)
	
	// Directory Name cannot be ""
	If $Get(pTarget)="" Set %objlasterror=$$$ERROR($$$DirectoryNameRequired) Quit 0

	// Set up an entry in IRIS.Temp
	Set tNode = $I($$$RDTREETEMP)
	Kill $$$RDTREETEMP(tNode)

	// Start by removing pTarget
	Set $$$RDTREETEMP(tNode,0) = pTarget
	
	While(1) {
		// Keep searching for work until there's nothing left.
		// We use a temp global to avoid being recursive in case of deep directory structures
		
		Set tIndex = $O($$$RDTREETEMP(tNode,""))
		Quit:tIndex=""
		
		// Grab the directory name to process next
		Set tNext = $$$RDTREETEMP(tNode,tIndex)
		
		// We must search this directory for:
		//	1) Additional directories to schedule for removal
		//	2) Files to delete


		// NOTE: If we ever implement a system level wildcard delete (i.e. not using a query to iterate) then
		//       we should delete files that way here, so the subsequent query will only return subdirectories
		//		 to be processed.  It's much faster to issue "rm *" to the OS (through an OS system call) than
		//		 to iterate.
		

		// Open a fileset on the directory
		Set tRS = ##class(%ResultSet).%New($classname()_":FileSet")
		If '$IsObject(tRS) ZTRAP "ERR"
		
		// Execute ...
		If 'tRS.Execute(tNext) ZTRAP "ERR"
		
		// Reset the "more work added" flag
		Set tMoreWorkAdded = 0
		
		// Now iterate over what's in the directory.  Note, if we don't have permissions to access this
		// directory, then the Next() returns 0 immediately since we can't "see" into the directory.
		While (tRS.Next()) {
			
			Set tType = tRS.Data("Type")
			Set tName = tRS.Data("Name")
			Set tItem = tRS.Data("ItemName")
			
			If tType = "D" {
				// Let's mark this directory for termination
				Set tDir = ..SubDirectoryName(tNext,tItem)
				Set $$$RDTREETEMP(tNode,$I($$$RDTREETEMP(tNode),-1)) = tDir  // Depth first, insert new dirs in front
				
				// But now we've added more work, so we can't remove this directory until it's empty of subdirs
				Set tMoreWorkAdded = 1
			} Else {
				// Delete the file
				If '$$$FileDelete(tName) Set %objlasterror = $$$ERROR($$$FileCanNotDelete,tName) ZTRAP "ERR"
			}
		}
		
		// At this point, we've removed any files from tNext and scheduled any subdirectories for removal
		// When the subdirectories have all been removed, we'll process this directory again and if it's
		// empty, we'll finally remove it
		
		If 'tMoreWorkAdded {
			
			// Remove the directory now that it is empty
			If '$$$FileRemoveDirectory(tNext) {
				// Failed ... probably a permissions problem or the directory could be in use (on Windows)
				Set %objlasterror = $$$ERROR($$$FileCanNotDelete,tNext) ZTRAP "ERR"
			}
			
			// Clean out this directory now it's been searched
			Kill $$$RDTREETEMP(tNode,tIndex)
		}
		
		// Loop again looking for more work
	}
	
Exit
	Kill $$$RDTREETEMP(tNode)
	
	// We return 0/1, but also set %objlasterror for the curious
	Quit $$$ISOK(%objlasterror)
	
Trap
	Set:$$$ISOK(%objlasterror) %objlasterror = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Rename file or directory <var>oldname</var> to <var>newname</var>. Returns true if it succeeds and false otherwise.
/// If you rename a file to a different filesystem, the result is to copy the file to a new
/// name and delete the original file.
/// You can use this method to rename a directory within the same filesystem; the method does
/// not work if the new name is on a different file system.
/// <br>Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod Rename(oldname As %String, newname As %String, Output return As %Integer) As %Boolean
{
	Set return=$$$FileRenameRet(oldname,newname)
	Quit 'return
}

/// Copy a host file <var>from</var> to host file <var>to</var>. <br>
/// Parameter <var>pDeleteBeforeCopy</var> may be used to specify that if the target file already exists then it should be deleted before being overwritten 
/// with the source file. The default is 0 or false. <br>
/// This method returns true if it succeeds and false otherwise.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code or of an IRIS simulated operating
/// system return code.<br>
/// Also see $SYSTEM.Process.OSError().
ClassMethod CopyFile(from As %String, to As %String, pDeleteBeforeCopy As %Boolean = 0, Output return As %Integer) As %Boolean
{
	Set tRet = 1,return=0
	If pDeleteBeforeCopy {
		If $$$FileExists(to) {
			Set return=$$$FileDeleteRet(to)
			If return {
				Set tRet = 0
				Set %objlasterror = $$$ERROR($$$FileCanNotDelete,to)
			}
		}
	}
	If tRet {
		Set return = $$$FileCopyRet(from,to)
		Set tRet='return
	}
	Quit tRet
}

/// Copy a host directory from <var>pSource</var> to <var>pTarget</var>. <br>
/// Parameter <var>pOverlay</var>
/// Parameter <var>pDeleteBeforeCopy</var> may be used to specify that any file that already exists in the target directory should be deleted before
/// being overwritten with the source file. The default is 0 or false.<br>
/// This method returns true if it succeeds and false otherwise. <br>
/// Note: (1) If the target directory exists and <var>pOverlay</var> is false (default), then the operation fails. Also, if any of the target files exist 
/// and <var>pDeleteBeforeCopy</var> is false (default), then the operation may fail usually due to operating system characteristics. 
/// (2) The total number of files or directories created/copied during the operation can be gotten by passing a byref value in <var>pCreated</var>.
ClassMethod CopyDir(pSource As %String, pTarget As %String, pOverlay As %Boolean = 0, ByRef pCreated = 0, pDeleteBeforeCopy As %Boolean = 0) As %Boolean
{
	Set pCreated = 0

	// Check source & target, source *must* exist and target must *not* exist
	If '$$$FileDirectoryExists(pSource) Set %objlasterror = $$$ERROR($$$DirectoryNotExist,pSource) Quit 0
	If 'pOverlay,$$$FileDirectoryExists(pTarget) Set %objlasterror = $$$ERROR($$$FileExists,pTarget) Quit 0

	// Normalize the input directory names
	Set pSource = $$$FileNormalizeDirectoryFull(pSource)
	Set pTarget = $$$FileNormalizeDirectoryFull(pTarget)
	
	Set $ZT="Trap"
	Set %objlasterror = $$$OK
	Set copytemp(pSource) = pTarget
	
	While(1) {
		// Keep searching until we're done
		Set tSrc = $O(copytemp(""),1,dest)
		Quit:tSrc=""
		
		// Ensure the destination directory has been normalized
		Set tDest = $$$FileNormalizeDirectoryFull(dest)
			
		// Firstly, we create the target dir
		If '$$$FileDirectoryExists(tDest)||'pOverlay {
			If '..CreateDirectoryChain(tDest) Set %objlasterror = $$$ERROR($$$CreateFailedBecause,tDest) ZTRAP "ERR"
			Set pCreated = pCreated + 1
		}
		
		// We must search this directory for:
		//	1) Additional directories to search
		//	2) Files to copy

		// Open a fileset on the source directory
		Set tRS = ##class(%ResultSet).%New($classname()_":FileSet")
		If '$IsObject(tRS) ZTRAP "ERR"
		
		// Execute ...
		If 'tRS.Execute(tSrc) ZTRAP "ERR"
		
		// Now iterate over what's in the directory
		While (tRS.Next()) {
			
			Set tType = tRS.Data("Type")
			Set tName = tRS.Data("Name")
			Set tItem = tRS.Data("ItemName")
			
			If tType = "F" {
				// Copy the file
				If '..CopyFile(tName,tDest_tItem,pDeleteBeforeCopy) Set %objlasterror = $$$ERROR($$$FileCanNotCopy,tName,tDest_tItem) ZTRAP "ERR"
				Set pCreated = pCreated + 1
			}
			
			If tType = "D" {
				// Let's mark this directory for searching
				Set tDir = ..SubDirectoryName(tDest,tItem)
				Set copytemp(tName) = tDir
			}
			
			// Anything other than F or D, we ignore (e.g. symlinks etc)
		}
		
		// Clean out this directory now it's been searched
		Kill copytemp(tSrc)
	}
	
Exit
	
	Quit $$$ISOK(%objlasterror)
	
Trap
	Set:$$$ISOK(%objlasterror) %objlasterror = $$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Return the size of file <var>filename</var> in bytes.
ClassMethod GetFileSize(filename As %String) As %Integer [ CodeMode = expression ]
{
$$$FileSize(filename)
}

/// Return the date created of file <var>filename</var> in $H format,
/// if the operating system supports it. Windows is the only current
/// platform that tracks the created date. Other systems return the date
/// of the last file "status" change.
/// By default this is local time. If you pass <var>utc</var> as true it returns it in UTC time.
/// The value is rounded to millisecond precision.
ClassMethod GetFileDateCreated(filename As %String, utc As %Boolean = 0) As %String [ CodeMode = expression ]
{
$$$FileDateCreatedUTC(filename,utc)
}

/// Return the date last modified of file <var>filename</var> in $H format.
/// By default this is local time. If you pass <var>utc</var> as true it returns it in UTC time.
/// The value is rounded to millisecond precision.
ClassMethod GetFileDateModified(filename As %String, utc As %Boolean = 0) As %String [ CodeMode = expression ]
{
$$$FileDateModifiedUTC(filename,utc)
}

/// Return the SHA 256 hash of file <var>filename</var>.
ClassMethod GetFileSHA256Hash(filename As %String, ByRef sc = 0) As %String
{
	s sc = $$$OK
	s rv = $$$FileSHA256Hash(filename)
	if ($l(rv) '= 32) s sc = $$$ERROR($$$FileCanNotOpen,filename)
	q rv
}

/// Return true if the file/directory is writable and false if it is not
ClassMethod Writeable(filename As %String) As %Boolean [ CodeMode = expression ]
{
$$$FileWritable(filename)
}

/// Return the attributes of the file.
/// The format of the returned value depends on the underlying operating system.
/// <p>
/// Microsoft Windows&reg; returns a value as a combination of bits whose meaning is:
/// <br>
/// <ul>
/// <li>1: 0x00001 - Read-only</li>
/// <li>2: 0x00002 -  Hidden</li>
/// <li>4: 0x00004 -  System</li>
/// <li>8:  0x00008 - Unused</li>
/// <li>16: 0x00010 -  Directory</li>
/// <li>32: 0x00020 -  Archive</li>
/// <li>64: 0x00040 -  Device</li>
/// <li>128: 0x00080 -  Normal</li>
/// <li>256: 0x00100 -  Temporary</li>
/// <li>512: 0x00200-  Sparse File</li>
/// <li>1024: 0x00400 -  Reparse Point</li>
/// <li>2048: 0x00800 -  Compressed</li>
/// <li>4096: 0x01000 -  Offline</li>
/// <li>8192: 0x02000 -  Content Not Indexed</li>
/// <li>16384: 0x04000 -  Encrypted</li>
/// <li>32768: 0x08000 -  Unused</li>
/// <li>65536: 0x10000 -  Virtual</li>
/// </ul>
/// <p>
/// In UNIX&reg;, the returned value represents the mode map:
/// <br>
/// <ul>
/// <li>1: 0x0001 - execute permission for others</li>
/// <li>2: 0x0002 -  write permission for others</li>
/// <li>4: 0x0004 -  read permission for others</li>
/// <li>7: 0x0007 - mask for others permissions
/// <li>8: 0x0008 -  execute permission for group</li>
/// <li>16: 0x0010 -  write permission for group</li>
/// <li>32: 0x0020 -  read permission for group</li>
/// <li>56: 0x0038 - mask for group  permissions
/// <li>64: 0x0040 -  execute permission for owner</li>
/// <li>128: 0x0080 -  write permission for owner</li>
/// <li>256: 0x0100 -  read permission for owner</li>
/// <li>448: 0x01C0 - mask for file owner permissions
/// <li>512: 0x0200 -  sticky bit</li>
/// <li>1024: 0x0400 -  set groupid</li>
/// <li>2048: 0x0800 -  set userid</li>
/// <li>4096: 0x1000 -  fifo</li>
/// <li>8192: 0x2000 -  character device</li>
/// <li>16384: 0x4000 -  directory</li>
/// <li>24576: 0x6000 - block device
/// <li>32768: 0x8000 -  regular file</li>
/// <li>40960: 0xA000 - symbolic link</li>
/// <li>49152: 0xC000 - socket</li>
/// <li>61440: 0xF000 - mask for file type</li>
/// </ul>
/// <p>
/// Note: Individual Operating System vendor differences may exist. 
/// The relevant man/help pages or other associated documentation 
/// should be consulted for a definitive description of the file attributes
/// on a given system.
/// 
ClassMethod Attributes(filename As %String) As %String [ ClientName = FileAttributes, CodeMode = expression ]
{
$$$FileAttributes(filename)
}

/// Set the OS specific attributes of the file.
/// See the Attribute method in this class for file attribute values.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod SetAttributes(filename As %String, attributes As %String, Output return As %Integer) As %Boolean
{
	Set return=$$$FileSetAttributesRet(filename,attributes)
	Quit return=1
}

/// Return the Owner and Group of a file or directory in the format Owner:Group.<br>
ClassMethod GetOwnerGroup(File As %String, ByRef OwnerGroup As %String) As %Status
{
 s $zt="Error"
 i '$$$ISUNIX q $$$ERROR($$$GeneralError,"Invalid operation")
 kill OwnerGroup
 set zv=$zcvt($SYSTEM.Version.GetPlatform(),"L")
 set pipe="|CPIPE|%FileGetOG" close pipe
 set io=$IO
 #; First try 'stat'
 if zv["linux" || (zv["ubuntu") {
	try {
		open pipe:(/command="stat":/args="-c","%U:%G",File:/KEEPPRIV)
		do {
			set rc=$SYSTEM.Process.PipeExitCode(pipe,.sc)
			if rc="" hang 0.5
		} while rc="" && (sc["Process Still Running") && ($I(cnt)<5)
		if rc'=0 {
			if (rc'="") {
				use pipe read errmsg
				set sc=$$$ERROR($$$GeneralError,errmsg)
			}
			use io close pipe
			return sc
		}
		use pipe read OwnerGroup
		use io close pipe
		return $$$OK
	} catch { close pipe }
 } elseif zv[" aix" {
	try {
		open pipe:(/command="istat":/args=File:/KEEPPRIV)
		do {
			set rc=$SYSTEM.Process.PipeExitCode(pipe,.sc)
			if rc="" hang 0.5
		} while rc="" && (sc["Process Still Running") && ($I(cnt)<5)
		if rc'=0 {
			if (rc'="") {
				use pipe read errmsg
				set sc=$$$ERROR($$$GeneralError,errmsg)
			}
			use io close pipe
			return sc
		}
		use pipe
		do {
			read Record
		} while Record'["Owner"
		set i=$F(Record,"(")
		while $E(Record,i)=" " { set i=i+1 }
		set Owner=$P($E(Record,i,*),")")
		while $E(Owner,*)=" " { set $E(Owner,*)="" }
		set i=$F(Record,"(",i)
		while $E(Record,i)=" " { set i=i+1 }
		set Group=$P($E(Record,i,*),")")
		while $E(Group,*)=" " { set $E(Group,*)="" }
		set OwnerGroup=Owner_":"_Group
		use io close pipe
		return $$$OK
	} catch { close pipe }
 } elseif zv["apple" {
	try {
		open pipe:(/command="stat":/args="-f","%Su:%Sg",File:/KEEPPRIV)
		do {
			set rc=$SYSTEM.Process.PipeExitCode(pipe,.sc)
			if rc="" hang 0.5
		} while rc="" && (sc["Process Still Running") && ($I(cnt)<5)
		if rc'=0 {
			if (rc'="") {
				use pipe read errmsg
				set sc=$$$ERROR($$$GeneralError,errmsg)
			}
			use io close pipe
			return sc
		}
		use pipe read OwnerGroup
		use io close pipe
		return $$$OK
	} catch { close pipe }
 }
 #; If stat failed, fall back to ls
 s TmpFile=##Class(%File).TempFilename()
 s Option(1)="-ld"
 s Option(2)=File
 s Keywords="/KEEPPRIV /STDOUT="""_TmpFile_""""
 s Result=$zf(-100,Keywords,"ls",.Option)
 i Result'=0 q $$$ERROR($$$GeneralError,"Error: ls -ld "_File_" returns: "_Result)
 o TmpFile:"RSD":5 
 i '$t {
	s Status=$$$ERROR($$$GeneralError,"ls -ld "_File_" unable to open file "_TmpFile)
	q Status
 }
 u TmpFile r Record
 c TmpFile
#;Record looks like "drwxr-xr-x 13 root root 4096 Aug 22 04:23 /169u1
#;Translate all multiple spaces to single spaces
 s i=1
 while i<=$l(Record) {
	i $e(Record,i)=" " {
		while $e(Record,i+1)=" " {
			s Record=$e(Record,1,i)_$e(Record,i+2,*)	
		}
	}
	s i=i+1
 }
 s OwnerGroup=$tr($p(Record," ",3,4)," ",":")
 q $$$OK
Error s $zt=""
 i $d(TmpFile) c TmpFile
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q Status
}

/// Set the Owner and Group of a file or directory.<br>
/// This uses the unix "chown" command to perform the operation, and is valid only on Unix platforms.
ClassMethod SetOwnerGroup(filename, OwnerGroup) As %Status
{
 s $zt="Error"
 i '$$$ISUNIX q $$$ERROR($$$GeneralError,"Invalid operation")
 i '$SYSTEM.Security.Check($$$SystemCallOutResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$SystemCallOutResourceName_":"_$$$PermUseName)
 s Option(1)=OwnerGroup
 s Option(2)=filename
 s Result=$zf(-100,"/KEEPPRIV","chown",.Option)
 i Result'=0 {
	 s Status=$$$ERROR($$$GeneralError,"Error: chown "_OwnerGroup_" "_filename_" returns: "_Result)
 } else {
	 s Status=$$$OK
 }
 q Status
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q Status
}

/// Make this file/directory writable (if we can). The <var>writeonly</var>
/// defaults to true in which case this makes the file write only, if you just
/// want to add writable to the existing permissions without modifying the
/// other permissions pass <var>writeonly</var>=0. The <var>writeonly</var>
/// has no effect on Windows so you do not need to pass this argument on this platform.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod SetWriteable(filename As %String, writeonly As %Boolean = 1, Output return As %Integer) As %Boolean
{
	Set existing=$$$FileAttributes(filename),new=existing,return=1
	If existing<0 Quit 0
	If $$$isWINDOWS {
        #; new attribute-set is old minus "read-only"
		Set new=$zboolean(existing,1,2)
	} ElseIf $$$isUNIX {
        #; existing PLUS [146 = 128/u+w + 16/g+w + 2/o+w]
        If writeonly Set new=$zboolean(existing,292,2)
        Set new=$zboolean(new,146,7)
	}
	If existing=new Quit 1
	Set return=$$$FileSetAttributesRet(filename,new)
	Quit return=1
}

/// Make this file/directory read only (if we can).
/// If <var>leaveexisting</var> is true then it will add read permissions to the
/// file/directory without changing the existing permissions, by default
/// it will remove all other permissions other than read only flags. The <var>leaveexisting</var>
/// has no effect on Windows so you do not need to pass this argument on this platform.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod SetReadOnly(filename As %String, leaveexisting As %Boolean = 0, Output return As %Integer) As %Boolean
{
	Set existing=$$$FileAttributes(filename),new=existing,return=1
	If existing<0 Quit 0
	If $$$isWINDOWS {
		Set new=$zboolean(existing,1,7)
	} ElseIf $$$isUNIX {
        If 'leaveexisting Set new=$zboolean(existing,292,7)
        Set new=$zboolean(new,146,2)
	}
	If existing=new Quit 1
	Set return=$$$FileSetAttributesRet(filename,new)
	Quit return=1
}

/// Truncate an existing file or create a new empty file.
/// Pass <var>return</var> by reference to obtain the low level return value in case of errors
/// which is the negative value of the operating system return code.
ClassMethod Truncate(filename As %String, Output return As %Integer) As %Boolean
{
	Set return=$$$FileTruncate(filename)
	Quit return=0
}

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	#; pass filename via %New()
	Set:initval'="" ..Name=initval
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	#; close the file if open
	Do:..IsOpen ..Close()
	Quit $$$OK
}

/// Open the current file with mode <var>mode</var>.
/// 
/// <p><var>mode</var> is a string containing one or more file modes including:
/// <table COLS=2>
/// <tr><TD><B>R</B></TD><TD>Read</TD></tr>
/// <tr><TD><B>W</B></TD><TD>Write</TD></tr>
/// <tr><TD><B>S</B></TD><TD>Stream mode</TD></tr>
/// <tr><TD><B>N</B></TD><TD>Create a new file (overwrite existing file)</TD></tr>
/// </table>
/// Note that if the <var>mode</var> contains ':' characters this is a delimiter.
/// For example if the mode="RN:/SHARED" then it will open the file with the equivalent
/// of the COS command 'Open name:("RN":/SHARED):0'. The first piece before the
/// ':' is quoted and the subsequent pieces are not.
/// <P>
/// A complete discussion of the available options for <var>mode</var> can 
/// be found in the online documentation in the book,
/// <B>I/O Devices Guide</B>, specifically the chapter on Sequential File I/O.
/// 
Method Open(mode As %String = "", timeout As %Integer = 0) As %Status
{
	Quit:..IsOpen $$$ERROR($$$FileAlreadyOpen,..Name)
	#;SML3019+ ; Handle file name with ",".
	Set devices=$LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2)
	If $LISTFIND(devices,$ZU(12,..Name)) Quit $$$ERROR($$$FileAlreadyOpen,..Name)
	#;SML3019-
	
	If mode'[":" {
		Open ..Name:(mode):timeout Else  Set i%IsOpen=0 Quit $$$ERROR($$$FileCanNotOpen,..Name)
	} Else {
		Set open="Open ..Name:("""_$piece(mode,":")_""""
		For i=2:1:$length(mode,":") Set open=open_":"_$piece(mode,":",i)
		Set open=open_"):"_timeout
		Xecute open Set opened=$test
		If opened=0 Set i%IsOpen=0 Quit $$$ERROR($$$FileCanNotOpen,..Name)
	}
	
	Set i%IsOpen=1,i%openmode=mode
	Set ..AtEnd=0
	
	Quit $$$OK
}

/// Close the current file.
Method Close()
{
	If ..IsOpen {
		Close ..Name
		Set i%IsOpen=0,..AtEnd=0
	}
	Quit
}

/// Moves the current location to the beginning of the stream.
Method Rewind() As %Status
{
	Quit:'..IsOpen $$$ERROR($$$FileNotOpen,..Name)
	
	#; rewind the device
	Set io=$io Use ..Name:0 Use io
	Set ..AtEnd=0
	
	Quit $$$OK
}

Method Clear() As %Status
{
	#; Get rid of the attributes first
	Kill i%Attributes
	
	Quit:'..IsOpen $$$ERROR($$$FileNotOpen,..Name)
	
	If $$$ISERR(..Write("")) Quit $$$ERROR($$$FileNotOpen,..Name)
	Do ..Close()
	Set sc=$$$FileDelete(..Name) Quit:$$$ISERR(sc) sc
	Set ..AtEnd=0
	Quit $$$OK
}

/// Read up to <var>len</var> characters from this <b>File</b>.
Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %RawString
{
	Set sc=$$$OK
	#; file not open?
	If '..IsOpen Set len=-1,..AtEnd=1 Quit ""
	
	#; don't allow reads of more than $$$MaxStringLength
	Set:len>$$$MaxStringLength len=$$$MaxStringLength
	
	#; test for end of file and other errors
	Set out="",$ZTRAP="ReadError"
	
	Set io=$io
	Use ..Name
	Read:len out#len
	If $ZEOF Set $ZE="<ENDOFFILE>" Goto ReadError
	Use io
	Set len=$l(out)
	Quit out

ReadError	Set $ZTRAP=""
	Use io
	
	; test for non-end-of-file error
	If $E($ze,1,11)'="<ENDOFFILE>" Set sc=$$$ERROR($$$ObjectScriptError,$zerror) Close ..Name Set i%IsOpen=0,..AtEnd=1,len=-1 Quit ""
	
	; we're at the end
	Set ..AtEnd=1
	Set len=$l(out)
	Set:len=0 len=-1 ;if we are at the end with no data return -1
	
	Quit out
}

/// Write <var>data</var> to this <CLASS>%File</CLASS> object.
Method Write(data As %RawString = "") As %Status
{
	Quit:'..IsOpen $$$ERROR($$$FileNotOpen,..Name)
	
	Set ..AtEnd=0
	
	Set $ZTRAP="WriteError"
	Set io=$io Use ..Name Write data Use io
	Quit $$$OK

WriteError	Set $ZTRAP=""
	Use io
	Close ..Name
	Set i%IsOpen=0
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Write <var>data</var> with a carriage return to this <CLASS>%File</CLASS> object.
Method WriteLine(data As %RawString = "") As %Status
{
	Quit:'..IsOpen $$$ERROR($$$FileNotOpen,..Name)
	
	Set ..AtEnd=1
	
	Set $ZTRAP="WriteLineError"
	Set io=$io Use ..Name Write data,! Use io
	Quit $$$OK

WriteLineError	Set $ZTRAP=""
	Use io
	Close ..Name
	Set i%IsOpen=0
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

Method IsOpenSet(%val As %Boolean) As %Status [ Private ]
{
	Quit $$$OK
}

Method DateCreatedGet() As %Date [ CodeMode = expression ]
{
$$$FileDateCreated(..Name)
}

Method DateModifiedGet() As %Date [ CodeMode = expression ]
{
$$$FileDateModified(..Name)
}

Method SizeGet() As %Integer [ CodeMode = expression ]
{
$$$FileSize(..Name)
}

/// This query was originally created to return Windows drive letters, hence its name.
/// Later it was extended to work on Unix.<ul>
/// <li>Windows: return a list of available drives</li>
/// <li>Unix: return a list of mounted file systems</li></ul>
/// On Windows, if <var>fullyqualified</var> is true then the drive letters include the
/// trailing '\' character.  The default is false; this is backward compatible and returns
/// 'c:' on Windows. This does not affect the behavior on Unix.
Query DriveList(fullyqualified As %Boolean = 0) As %Query(ROWSPEC = "Drive:%String") [ SqlProc ]
{
}

ClassMethod DriveListExecute(ByRef QHandle As %Binary, fullyqualified As %Boolean = 0) As %Status
{
 Set $zt="Error",d=""
 If $$$isWINDOWS Do
 . Set drv=$zu(108),j=1
 . For i=97:1:122 Set:i'=97 j=j*2 Quit:j>drv  Set:drv\j#2 d=d_$c(i)_":"_$select(fullyqualified:"\,",1:",")
 Else  If $$$isUNIX Do
 . Set d=$ZU(108)
 . If $$$isMACOSX Do
 . . Set i=$ZSEARCH("/Volumes/*")
 . . For  Quit:i=""  Set:i'="/Volumes/.DS_Store" d=d_i_"," Set i=$ZSEARCH("")
 s QHandle=d
 Quit $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

ClassMethod DriveListClose(QHandle As %Binary) As %Status
{
	Set QHandle=""
	Quit $$$OK
}

ClassMethod DriveListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row=$Piece(QHandle,",")
	Set QHandle=$Piece(QHandle,",",2,*)
	Set AtEnd=(QHandle="")
	If Row'="" Set Row=$listbuild(Row)
	Quit $$$OK
}

/// Return the list of files in <var>directory</var> matching the pattern <var>wildcards</var>.
/// The <var>sortby</var> can be one of:<ul>
/// <li>Name - the name of the file (the default)</li>
/// <li>Type - file type</li>
/// <li>DateCreated - the date the file was created (rounded to the millisecond)</li>
/// <li>DateModified - the date the file was last modified (rounded to the millisecond)</li>
/// <li>Size - the file size</li></ul>
/// The <var>includedirs</var> if true (default is 0) will force the list
/// of all directories to be returned before any files, the directories will ignore the pattern you supplied so it returns them all.
/// If it is false it will
/// return any files that match the pattern you give it, this may include directories if they match the pattern as well.
/// So true forces any directory to be included, but false does not exclude directories.
/// You may also specify the <var>delimiter</var> that is used to separate the <var>wildcards</var>
/// from each other, this defaults to ";".
Query FileSet(directory As %String(MAXLEN=""), wildcards As %String, sortby As %String = "", includedirs As %Boolean = 0, delimiter As %String = ";") As %Query(ROWSPEC = "Name:%String,Type:%String,Size:%BigInt,DateCreated:%TimeStamp,DateModified:%TimeStamp,ItemName:%String") [ SqlProc ]
{
}

ClassMethod FileSetExecute(ByRef QHandle As %Binary, directory As %String, wildcards As %String, sortby As %String = "", includedirs As %Boolean = 0, delimiter As %String = ";") As %Status
{
	Set directory=$get(directory)
	If directory="" Set directory=$$$FileNormalizeDirectory($$$FileCurrentDir)
	If '$$$FileDirectoryExists(directory) Quit $$$ERROR($$$DirectoryNotExist,directory)
	Set QHandle=""
	Set dir=$$$FileNormalizeDirectoryFull(directory)
	If $$$isUNIX {
		If '$$$FileExists(dir_".") Quit $$$ERROR($$$DirectoryPermission,directory)
	}
	
	#; create temp node of filenames in this directory
	Set tempnode = $increment(^||%FileList) Kill ^||%FileList(tempnode)
	Set index=0,dirinplace=0
	If $get(wildcards)="" Set wildcards="*"
	
	#; build the list of files
	#; optional temp is pre-sorted list of files
	#; if includedirs, we force a list of directories to be returned first
	#; for all queries
	If includedirs {
		If (wildcards="*")||(wildcards="*.*"&&('$$$isUNIX)) {
			Set dirinplace=1
		} Else {
			#; find all the directories first
			Set f = $zsearch(dir_"*")
			While (f '= "") {
				If $$$FileDirectoryExists(f) {
					Set filename=..GetFilename(f)
					If filename'=".",filename'="..",filename'="000000.DIR;1",filename'="" {
						Set filelist(filename)=""
						Set ^||%FileList(tempnode,0," "_$zconvert(filename,"l"),$increment(index))=$listbuild(f,filename)
					}
				}
				Set f = $zsearch("")
			}
		}
	}
	
	For i=1:1:$length(wildcards,delimiter) {
		Set wildcard=$piece(wildcards,delimiter,i)
		If $$$isWINDOWS {
			Set wildcard=$zconvert(wildcard,"l")
			If $data(wildcard(wildcard)) Continue
			Set wildcard(wildcard)=""
		}
		Set f = $zsearch(dir_wildcard)
		While (f '= "") {
			Set filename=..GetFilename(f)
			If filename="."||(filename="..")||(filename="000000.DIR;1")||(filename="") Goto cont
			If $data(filelist(filename)) Goto cont
			Set filelist(filename)=""
			If dirinplace,$$$FileDirectoryExists(f) {
				Set ^||%FileList(tempnode,0," "_$zconvert(filename,"l"),$increment(index))=$listbuild(f,filename)
				Goto cont
			}
			If sortby="DateCreated" {
				Set sort=$$$FileDateCreated(f),sort=$piece(sort,",")*86400+$piece(sort,",",2)
			} ElseIf (sortby = "DateModified") {
				Set sort=$$$FileDateModified(f),sort=$piece(sort,",")*86400+$piece(sort,",",2)
			} ElseIf (sortby = "Size") {
				Set sort=$$$FileSize(f)
			} ElseIf (sortby = "Type") {
				If includedirs {
					Set sort=" "_$zconvert($piece(f,".",*),"l")
				} ElseIf $$$FileDirectoryExists(f) {
					Set ^||%FileList(tempnode,0," "_$zconvert(filename,"l"),$increment(index))=$listbuild(f,filename) Goto cont
				} Else {
					Set sort=" "_$zconvert($piece(f,".",*),"l")
				}
			} Else {
				Set sort=" "_$zconvert(filename,"l")
			}
			Set ^||%FileList(tempnode,1,sort,$increment(index))=$listbuild(f,filename)
cont		Set f = $zsearch("")
		}
	}
	Set ^||%FileList(tempnode)=index
	Set index="",sort=""
	Set type=$order(^||%FileList(tempnode,"")) If type'="" Set sort=$order(^||%FileList(tempnode,type,"")) If sort'="" Set index=$order(^||%FileList(tempnode,type,sort,""),1,data)
	Set QHandle=$LB(tempnode,type,sort,index,data)
	
	Quit $$$OK
}

ClassMethod FileSetClose(QHandle As %Binary) As %Status
{
	#; close the collection
	Set tempnode=$listget(QHandle)
	If tempnode'="" Kill ^||%FileList(tempnode)
	Set QHandle=""
	Quit $$$OK
}

ClassMethod FileSetFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set Row="",AtEnd=0
	
	Set $listget(tempnode,type,sort,index,data)=QHandle
	If (tempnode="")||(sort="")||(index="")||(type="") Set AtEnd=1 Quit $$$OK
	Set filename=$list(data,2),f=$list(data)
	
	; name,type,size,create,modify
	Set size = $$$FileSize(f),created=$$$FileDateCreated(f),modified=$$$FileDateModified(f)
	Set:size<0 size = "" ; don't return size for directories
	Set created=$zdt(created,3,,$l($p(created,".",2)),,,,,,,""),modified=$zdt(modified,3,,$l($p(modified,".",2)),,,,,,,"")
	Set Row=$listbuild(f,$select(type=0:"D",$$$FileDirectoryExists(f):"D",1:"F"),size,created,modified,filename)
	Set index=$order(^||%FileList(tempnode,type,sort,index),1,data)
	If index="" {
		Set sort=$order(^||%FileList(tempnode,type,sort))
		If sort="" {
			Set type=$order(^||%FileList(tempnode,type))
			If type="" {
				Set AtEnd=1
			} Else {
				Set sort=$order(^||%FileList(tempnode,type,"")),index=$order(^||%FileList(tempnode,type,sort,""),1,data)
			}
		} Else {
			Set index=$order(^||%FileList(tempnode,type,sort,""),1,data)
		}
	}
	Set QHandle=$listbuild(tempnode,type,sort,index,data)
	Quit $$$OK
}

Method LastModifiedGet() As %TimeStamp
{
	Set timestamp=$$$FileDateModified(..Name)
	Quit $zdt($S(timestamp<1:$H,1:timestamp),3)
}

/// Set the date last modified of file <var>filename</var> to be <var>ntime</var> in $H format.
/// By default ntime is local time. If you pass <var>utc</var> as true, ntime will be treated as
/// UTC time. Pass <var>return</var> by reference to obtain the low level return value 
/// in case of errors which is the negative value of the operating system return code.
Method SetFileDateModified(filename As %String, ntime As %TimeStamp, utc As %Boolean = 0, Output return As %Integer) As %Boolean
{
	if ('utc) {
		Set ntime = $ZDATETIME(ntime,-3)	
	}
	Set return = $$$FileSetDateModified(filename, ntime)
	Quit return = 0
}

/// Method not implemented as it does not make sense in context of %File interface
Method CopyFromAndSave(source As %AbstractStream) As %Status
{
	Quit $$$ERROR($$$NotImplemented,"%Library.File::CopyFromAndSave")
}

/// Create an empty temporary file in the OS provided temp directory, or the directory
/// specified by <var>dir</var>, and return the filename.<br>
/// If you specify <var>ext</var> the filename will have this extension.<br>
/// You should delete the file after using it.<br>
/// Pass <var>return</var> by reference to obtain the low level return value in case of an error.
/// It will be the negative value of the operating system return code,
/// or 0 if there is no error.<br>
/// In case of an error, the method returns an empty string.
ClassMethod TempFilename(ext As %String, dir As %String, Output return As %Integer) As %String
{
	If $data(dir) {
		Set fn=$$$FileTempFileExtDir($Get(ext),dir)
	} Else {
		Set fn=$$$FileTempFileExt($Get(ext))
	}
	If fn<0 {
		Set return=fn, fn=""
	} Else {
		Set return=0, fn=..NormalizeFilename(fn)
	}
	Quit fn
}

/// Set umask to the given value and return the previous umask value.
/// Does not affect directories, which are always created with
/// permission 775 (UMask 002) by default.
ClassMethod SetUMask(NewMask As %Integer) As %Integer [ CodeMode = expression ]
{
$zu(47,NewMask)
}

/// Compare two files and return 1 if they are identical and 0 otherwise
ClassMethod Compare(file1 As %String, file2 As %String) As %Boolean
{
	If file1=""||(file2="") Quit 0
	If $zutil(140,1,file1)'=$zutil(140,1,file2) Quit 0
	Set io=$IO
	Open file1:("RUK\RAW\"):0 Else  Quit 0
	Open file2:("RUK\RAW\"):0 Else  Close file1 Quit 0
	Set same=1,exit=0
	Do {
		Try {
			Use file1 Read tmp1#32000 Use file2 Read tmp2#32000
			If tmp1'=tmp2 Set same=0,exit=1
			If $zeof Set exit=1
		} Catch {
			Set exit=1
		}
	} While 'exit
	Use io
	Close file1,file2
	Quit same
}

/// Return binary form of SHA1 hash on the <var>file</var> if <var>type</var> is 0 (the default).
/// If you want the string version then pass in <var>type</var> as 1. Note that if you already
/// have the file open in this process calling this function will close this file.
ClassMethod SHA1Hash(file As %String, type As %Integer = 0) As %String
{
	If file="" Quit ""
	Set io=$IO
	Close file
	Open file:("RUK\RAW\"):0 Else  Quit ""
	Set exit=0
	Do $System.Encryption.SHA1HashResult()
	Do {
		Try {
			Use file Read tmp#32000
			Do $system.Encryption.SHA1HashInput(tmp)
			If $zeof Set exit=1
		} Catch {
			Set exit=1
		} 
	} While 'exit
	Use io
	Close file
	Set value=$System.Encryption.SHA1HashResult()
	If type=0 Quit value
	Set str="" For i=1:1:$length(value) {
		Set str=str_$translate($justify($zhex($ascii(value,i)),2)," ",0)
	}
	Quit str
}

/// Normalize filenames containing spaces for the host platform.<br>
/// <br>
/// Parameter<br>
/// pathname : A filename or pathname.<br>
/// <br>
/// Description<br>
/// The NormalizeFilenameWithSpaces class method handles spaces in pathnames as appropriate
/// to the host platform.<br>
/// <br>
/// If a pathname contains spaces NormalizeFilenameWithSpaces returns the pathname
/// enclosed in double quotes ("path name").
/// If a pathname does not contain spaces, the method returns it
/// unchanged.  NormalizeFilenameWithSpaces performs no other pathname validation.<br>
/// <br>
/// NormalizefilenameWithSpaces is commonly used with the $ZF() functions.<br>
/// <br>
/// Note that this method does not perform the normalization actions of <method>NormalizeFilename</method>.
/// 
ClassMethod NormalizeFilenameWithSpaces(pathname As %String) As %String [ CodeMode = expression ]
{
$ZU(147,pathname)
}

}
