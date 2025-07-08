/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// Deprecated internal class.
/// Stream adaptor for streams that store data in external files. Not to be used directly.
Class %Library.FileStreamAdaptor Extends %AbstractStream [ Abstract, Deprecated, System = 2 ]
{

Parameter WRITEJUSTSAVED [ Final ] = 4;

Parameter STORAGE = "OTHER";

Parameter FILEEXT = "stream";

Parameter OPENREAD = "RUK\RAW\";

Parameter OPENWRITE = "WUNK\RAW\";

Parameter OPENAPPEND = "AWUK\RAW\";

Parameter OPENREADTERM = "RSK\RAW\";

Parameter READNORMAL [ Final ] = 0;

Parameter READLINE [ Final ] = 1;

Parameter WRITENORMAL [ Final ] = 0;

Parameter WRITEAPPEND [ Final ] = 1;

/// Directory where stream files are located.
Property Directory As %String(MAXLEN = 5000);

Method DirectorySet(dir As %String) As %Status [ Private ]
{
	Set i%Directory=dir
	Set i%NormalizedDirectory=$S(dir="":"",1:$$$FileNormalizeDirectoryFull(dir))
	Set ..MakePermLoc=0
	Quit $$$OK
}

Method %LocationSet(value As %String) As %Status
{
	Do ..Clear(0)
	Set ..Directory=value,i%%Location=value
	#; Reset file to the null stream ready for new data in this new directory
	Set i%TempFile="",i%StoreFile=""
	Set i%Mode=..#READNODATA,i%AtEnd=1
	Set i%"%%OID"=..%Oid()
	Quit $$$OK
}

Method %LocationGet() As %String [ CodeMode = expression ]
{
i%Directory
}

/// The filename that this stream is currently using<p>
/// If you set this property to update the file we will write to/read from
/// this operation can fail if for example the directory specified does not exist.
/// To detect this failure either check the %Status return code of the <method>FilenameSet</method>
/// or if using 'Set stream.Filename=newname' then check %objlasterror after the call to see if it
/// reported an error.
Property Filename As %String(MAXLEN = 5000) [ Calculated ];

Method FilenameSet(file As %String) As Status [ CodeMode = call ]
{
..LinkToFile(file)
}

Method FilenameGet() As %String [ CodeMode = expression ]
{
$select((i%Mode=..#READNOTCHANGED)||(i%Mode=..#WRITEJUSTSAVED):i%NormalizedDirectory_i%StoreFile,(i%Mode=..#READCHANGED)||(i%Mode=..#WRITE)||(i%TempFile'=""):i%NormalizedDirectory_i%TempFile,1:"")
}

/// Read only property that returns the canonical filename if the file is open and "" if the file is not open.
Property CanonicalFilename As %String(MAXLEN = 5000) [ Calculated ];

Method CanonicalFilenameGet() As %String [ CodeMode = expression ]
{
##class(%File).CanonicalFilename(..Filename)
}

/// Normalized form of the directory. This is used for access to the file (as it adds the
/// extra '/' if needed), but it stores the <ATTRIBUTE>Directory</ATTRIBUTE> in the Id as
/// this may be a relative path. This is read only, you should not try and set its value.
Property NormalizedDirectory As %String(MAXLEN = 5000) [ Private ];

/// Name of file (without directory) containing stored stream.
Property StoreFile As %String(MAXLEN = 5000) [ Private ];

/// Name of file (without directory) containing temporary stream.
Property TempFile As %String(MAXLEN = 5000) [ Private ];

/// Full path name of currently opened file. Equal to "" if no file 
/// is open.
Property CurrFile As %String(MAXLEN = 5000) [ Private, Transient ];

/// If true then remove the permanent file as well as any temp file when this object is closed
Property RemoveOnClose As %Boolean [ InitialExpression = 0, Transient ];

/// Mode the device is opened in, either with terminators as delimitors or not.
Property ReadMode As %Integer [ InitialExpression = {..#READNORMAL}, Private ];

/// If true then when saving this file we need to move it to the default permanent location
Property MakePermLoc As %Boolean [ InitialExpression = 0, Private ];

/// While reading this holds the file size
Property ReadSize As %Integer;

/// For file streams the line will terminate on any of the characters set in the LineTerminator, it does not support
/// multi-character line terminators because it uses the ObjectScript file behavior which terminates on any of the characters.<br>
/// Also for %FileCharacterStream even if you set this when you call <method>WriteLine</method> as the file was opened in 'S'
/// mode it will normalize the line terminator as the data is being written, so for example if you set LineTerminator to
/// $char(13,10) on Unix systems when you call <method>WriteLine</method> it will only write $char(10) to the file.
Property LineTerminator As %String(MAXLEN = 10) [ InitialExpression = {$get(^%SYS("Stream","LineTerminator"),$select($$$isUNIX:$char(10),1:$char(13,10)))}, Transient ];

Method LineTerminatorSet(terminator As %String) As %Status
{
 
	Set i%Attributes("LineTerminator")=terminator,i%LineTerminator=terminator,i%ReadMode=..#READNORMAL
	Quit $$$OK
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set location=..%Location
	Do ..IOInit()
	Set ..Directory=location,i%%Location=location
	Do:'object.%IsNull() ..CopyFrom(object)
	Quit $$$OK
}

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	#; pass directory via %New()
	If initval=$char(0) Set initval=$get(^%SYS("StreamLocation",$namespace))
	If initval="" {
		Set ..Directory=$get(^%SYS("TempDir",$namespace),$get($$$SYSTempDir)),..MakePermLoc=1
	} Else {
		Set ..Directory=initval
	}
	Do ..AttributesSetModified(0)
	Quit $$$OK
}

Method IOInit() [ Private ]
{
	#; intialize member variables
	Set i%Mode=0,i%AtEnd=0,i%StoreFile="",i%TempFile="",i%CurrFile="",i%Directory=$get(^%SYS("TempDir",$namespace),$get($$$SYSTempDir)),i%ReadMode=..#READNORMAL,i%NormalizedDirectory=$$$FileNormalizeDirectoryFull(i%Directory),i%ReadSize=0,i%RemoveOnClose=0,..MakePermLoc=1
	Quit
}

Method %OnClose() As %Status [ Private ]
{
	#; close file if open
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	
	#; Mode = ..#READCHANGED or ..#WRITE: Delete new data
	If (i%Mode=..#READCHANGED)!(i%Mode=..#WRITE) If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	
	If ..RemoveOnClose,..StoreFile'="" If '$$$FileDelete(i%NormalizedDirectory_i%StoreFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%StoreFile)
	
	Quit $$$OK
}

Method Rewind() As %Status
{
	Set i%AtEnd=0
	If i%Mode=..#WRITEJUSTSAVED Set i%Mode=..#READNOTCHANGED
	If i%Mode=..#READNODATA Set i%AtEnd=1 Quit $$$OK
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	If i%Mode=..#WRITE Set i%Mode=..#READCHANGED
	Quit $$$OK
}

Method Flush() As %Status
{
	#; Empty and internal buffer to disk and reopen at end
	If i%Mode'=..#WRITE Quit $$$OK
	Do ..Rewind(),..MoveToEnd()
	Quit $$$OK
}

/// Return the current size of the data stream. 
Method SizeGet() As %Integer [ CodeMode = call ]
{
..FileBinarySize()
}

/// Return the current size of the file in bytes.
Method FileBinarySize() As %Integer
{
	If (i%Mode=..#WRITE) && (i%CurrFile'="") {
		Try {
			Set io=$io
			Use i%CurrFile
			Write *-1
			Set size=$$$FileSize(i%CurrFile)
		} Catch {
			#; If we get an error someone else closed the file, so report the file size and reset our state
			Set size=$$$FileSize(i%CurrFile)
			Set i%CurrFile="",i%Mode=..#READCHANGED
		}
		Use io
		Quit size
	}
	Quit $select(i%Mode=..#READCHANGED||(i%Mode=..#WRITE):$$$FileSize(i%NormalizedDirectory_i%TempFile),i%Mode=..#READNOTCHANGED||(i%Mode=..#WRITEJUSTSAVED):$$$FileSize(i%NormalizedDirectory_i%StoreFile),1:0)
}

Method IOGetStreamId() As %String [ CodeMode = expression, Private ]
{
$select(..Mode=..#READNODATA:"",1:$listbuild($select(..Directory=$get(^%SYS("StreamLocation",$namespace)):"",1:..Directory),$S(i%StoreFile'="":i%StoreFile,1:i%TempFile)))
}

/// Open a stream given a stream id
Method OpenStream(sid As %String) As %Status
{
	#; Mode = ..#READCHANGED or ..#WRITE: Delete new data
	If (i%Mode=..#READCHANGED)||(i%Mode=..#WRITE) {
		If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
		Set i%Mode=..#READNODATA
	}
	
	#; sid is $LB(directory,filename)
	Set i%StoreFile=$LG(sid,2)
	Set dir=$listget(sid,1)
	If dir="",##class(%File).GetDirectory(i%StoreFile)="" Set dir=$get(^%SYS("StreamLocation",$namespace))
	Set ..Directory=dir
	Set i%TempFile=""
	Set i%RemoveOnClose=0
	
	#; No file stored so it is a null stream
	If i%StoreFile="" {
		Set i%Mode=..#READNODATA,i%AtEnd=1
	} ElseIf $$$FileExists(i%NormalizedDirectory_i%StoreFile)=0 {
		#; Else link to a file that does not exist ready to write to it, it is currently a null stream
		Set i%Mode=..#READNODATA,i%AtEnd=1
		Set i%TempFile=i%StoreFile
		Set i%StoreFile=""
	} Else {
		#; Else the file really exists so link to it
		Set i%Mode=..#READNOTCHANGED,i%AtEnd=(..FileBinarySize()=0)
	}
	
	Quit $$$OK
}

/// This method lets you connect a file stream to a file called <var>filename</var> without
/// making a copy of it. If the file does not already exist it will still allow you to link
/// to this file, and %IsNull() will return true until you write to this file.
/// <EXAMPLE>
/// Do object.Image.LinkToFile("\temp\image.jpg")
/// Do object.%Save()
/// </EXAMPLE>
/// The method as its name suggests creates a LINK to an EXISTING 
/// file. So this is a 'shared public' file, as it can be shared by 
/// several instances of a class, or even several classes. 
/// Using the <method>CopyFrom</method> method, on the contrary, creates a 
/// 'private' image, not sharable by other instances/classes, so 
/// these two methods are really different.<p>
/// The problems with shared public images are that several instances 
/// are all allowed to update and even delete the image, causing 
/// problems for other instances.<p>
/// For example, if dog #2 has image 'test.gif', I can also 
/// assign that image to dog #5 or even person #24 
/// If I change the image for dog #5, then the image is changed in 
/// place to another image, thus upsetting dog#2 and person#24. 
/// If I delete dog#5, the image is also deleted and thus dog#2 
/// and person#24 are changed.<p>
/// Also note that if there is currently some temporary data in the old stream when the
/// <method>LinkToFile</method> is called this temporary data will be removed before the
/// stream is linked to this filename.
Method LinkToFile(filename As %String) As %Status
{
	If filename="" Quit $$$ERROR($$$FileNameInvalid,filename)
	#; Do not allow two objects to open the same file
	Set filename=$$$FileNormalizeFilename(filename)
	#;SML3019 ; Handle file name with ",".
	If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$ZU(12,filename)) Quit $$$ERROR($$$FileAlreadyOpen,filename)
	Set directory=##class(%File).GetDirectory(filename,1),file=##class(%File).GetFilename(filename)
	If '##class(%File).DirectoryExists(directory) {
		Quit $$$ERROR($$$DirectoryNameInvalid,directory)
	}
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	
	#; Mode = ..#READCHANGED or ..#WRITE: Delete new data
	If (i%Mode=..#READCHANGED)||(i%Mode=..#WRITE) {
		If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	}
	
	#; If the file does not exist then this is the name of the new file we will create
	If $$$FileExists(filename)=0 {
		Set i%Mode=..#READNODATA,i%AtEnd=1
		Set i%StoreFile=""
		Set i%TempFile=file
		Set ..Directory=directory
	} Else {
		#; Else the stored file is of this name
		Set i%Mode=..#READNOTCHANGED
		Set i%StoreFile=file
		Set ..Directory=directory
		Set i%TempFile="",i%AtEnd=(..FileBinarySize()=0)
	}
	Set i%"%%OID"=..%Oid()
	
	Quit $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set status = ..SaveStream()
	Set sid = ..IOGetStreamId()
	Quit status
}

Method SaveStream() As %Status
{
	#; Cancel any remove on close as they are explicitly saving this
	Set i%RemoveOnClose=0
	If i%Mode=..#READNODATA||(i%Mode=..#READNOTCHANGED)||(i%Mode=..#WRITEJUSTSAVED) Quit $$$OK
	
	#; close file (if open), go to read mode
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	
	If ..MakePermLoc,i%StoreFile="" {
		Set dir=$get(^%SYS("StreamLocation",$namespace),i%NormalizedDirectory) 
		If dir'=i%NormalizedDirectory {
			#; Rename so that stored filename remains constant
			If '$$$FileRename(i%NormalizedDirectory_i%TempFile,dir_i%TempFile) {
				If '$$$FileCopy(i%NormalizedDirectory_i%TempFile,dir_i%TempFile) Quit $$$ERROR($$$FileCanNotRename,i%NormalizedDirectory_i%TempFile)
				If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
			}
			Set ..Directory=dir
		}
		Set i%StoreFile=i%TempFile,i%TempFile=""
	} ElseIf i%StoreFile'="" {
		If $$$FileReadOnly(i%NormalizedDirectory_i%StoreFile)||('$$$FileDelete(i%NormalizedDirectory_i%StoreFile)),$$$FileExists(i%NormalizedDirectory_i%StoreFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%StoreFile)
		#; Rename so that stored filename remains constant
		If '$$$FileRename(i%NormalizedDirectory_i%TempFile,i%NormalizedDirectory_i%StoreFile) {
			If '$$$FileCopy(i%NormalizedDirectory_i%TempFile,i%NormalizedDirectory_i%StoreFile) Quit $$$ERROR($$$FileCanNotRename,i%NormalizedDirectory_i%TempFile)
			If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
		}
	} Else {
		Set i%StoreFile=i%TempFile,i%TempFile=""
	}
	If i%Mode=..#WRITE { Set i%Mode=..#WRITEJUSTSAVED } Else { Set i%Mode=..#READNOTCHANGED }
	Quit $$$OK
}

ClassMethod IODeleteStream(sid As %String, concurrency As %Integer = 0) As %Status [ Private ]
{
	#; delete the stream file
	Set dir=$LG(sid,1)
	Set dir=$S(dir="":$get(^%SYS("StreamLocation",$namespace)),1:$$$FileNormalizeDirectoryFull(dir))
	Set file=$LG(sid,2)
	
	Quit:file="" $$$OK
	
	If '$$$FileDelete(dir_file) Quit $$$ERROR($$$FileCanNotDelete,dir_file)
	Quit $$$OK
}

ClassMethod NewFileName(ext As %String = "", directory As %String = "") As %String
{
	Set ext=$piece($translate(ext,"\","/"),"/",*)
	If ext="" Set ext=..#FILEEXT
	If directory'="" RETURN $piece($translate($$$FileTempFileExtDir(ext,directory),"\","/"),"/",*)
	RETURN $translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")_"."_ext
}

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %RawString
{
	Set sc=$$$OK,ze=$zerror
	If i%Mode=..#WRITEJUSTSAVED Set i%Mode=..#READNOTCHANGED
	#; test if we've already read to the end, or there is no data
	If i%AtEnd=1||(i%Mode=..#READNODATA),i%Mode'=..#WRITE Set len=-1,i%AtEnd=1 Quit ""
	
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	
	Set io=$io,out=""
	#; test for end of file
	Set $ZTRAP="ReadError"
	
	#; This will switch to this device and set it up for us
	If ..Mode=..#WRITE Do ..Rewind()
	If (..ReadMode'=..#READNORMAL)||(..CurrFile="") {
		Set sc=..SetupRead(..#READNORMAL) If $$$ISERR(sc) Use io Set $zerror=ze Quit ""
	} Else {
		Use ..CurrFile
	}
	If len=0 Use io Quit ""

	Read:len out#len
	If $ZEOF Set $ZE="<ENDOFFILE>" Goto ReadError
	#; If we read less than requested either we are at the end, or we have a surrogate pair
	If $zseek()=i%ReadSize Close i%CurrFile Set i%CurrFile="",i%AtEnd=1
	Use io
	Set len=$L(out),$zerror=ze
	Quit out

ReadError Set $ZTRAP=""
	Use io
	#; if error (not EOF) close file
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	If $E($ze,1,11)'="<ENDOFFILE>" Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	Set i%AtEnd=1,$zerror=ze
	Set len=$S($L(out)=0:-1,1:$L(out))
	Quit out
}

Method SetupRead(newMode As %Integer) As %Status [ Private ]
{
	#; Mode ..#WRITE: in middle of Write with no rewind; rewind
	If i%Mode=..#WRITE Do ..Rewind()
	
	#; read data from file; return 0 if no more data
	Set pos=0
	Set fileexists=1
	Set $ZTRAP="SetupReadError"
	
	#; If we are changing read mode, then make a note of the position and force
	#; it to reopen the file by setting i%CurrFile=""
	If (i%ReadMode'=newMode) && (i%CurrFile'="") {
		Use i%CurrFile
		Set pos=$ZSEEK()
		Close i%CurrFile
		Set i%CurrFile=""
	}
	
	#; is the first time we are reading?
	#; if not changed, read from old file; else read from temp file
	If i%CurrFile="" {
		Set filename=i%NormalizedDirectory_$S(i%Mode=..#READNOTCHANGED:i%StoreFile,1:i%TempFile)
		#; Do not allow two objects to open the same file
		#;SML3019 ; Handle file name with ",".
		If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$ZU(12,filename)) Set len=-1,i%AtEnd=1 Quit $$$ERROR($$$FileAlreadyOpen,filename)
		Set parm=..GetReadOpenParameter(filename,newMode,.pos)
		Open filename:(parm::..LineTerminator:/NOXY=1):0 Else  Set fileexists=0
		If fileexists {
			Set i%CurrFile=filename
			#; firsttime, force position to start or where we left off if doing ReadLine()
			Use filename:pos
			Set i%ReadMode=newMode,..ReadSize=$zutil(140,1,filename)
		} Else {
			Set ..ReadSize=-1
		}
	} Else {
		#; We are continuing to read from previous position
		Use i%CurrFile
	}
	
	#; This will exit before we change devices
	If fileexists=0 Set len=-1,i%AtEnd=1 Quit $$$ERROR($$$FileDoesNotExist,$get(filename,i%CurrFile))
	Quit $$$OK

SetupReadError	Set $ZTRAP=""
	Set len=-1,i%AtEnd=1 
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

Method Write(data As %RawString = "") As %Status
{
	#; Mode '= ..#WRITE; clear TempFile; prepare for write
	If i%Mode=..#WRITEJUSTSAVED Set sc=..MoveToEnd() If $$$ISERR(sc) Quit sc
	If i%Mode'=..#WRITE Do
	  #; Mode = READNODATA or ..#READNOTCHANGED: set up for write: create new file
	. If (i%Mode=..#READNODATA)!(i%Mode=..#READNOTCHANGED) Set:i%TempFile="" i%TempFile=..NewFileName($select(i%StoreFile[".":$piece(i%StoreFile,".",*),1:""))
	. If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	. Set i%Mode=..#WRITE
	
	#; write is never at the end
	Set i%AtEnd=0
	
	; test for write errors
	Set io=$io Set $ZTRAP="WriteError"
	
	#; Open the file if this is the first time;
	If i%CurrFile="" Set sc=$$$OK Do  If $$$ISERR(sc) Quit sc
	  #; Do not allow two objects to open the same file
	  #;SML3019 ; Handle file name with ",".
	. If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$ZU(12,i%NormalizedDirectory_i%TempFile)) Set sc=$$$ERROR($$$FileAlreadyOpen,i%NormalizedDirectory_i%TempFile) Quit
	. Set parm=..GetWriteOpenParameter(i%NormalizedDirectory_i%TempFile,..#WRITENORMAL)
	. Set i%CurrFile=i%NormalizedDirectory_i%TempFile
	. Open i%CurrFile:(parm:::/OBUFSIZE=32768:/NOXY=1):0
	. Else  Set sc=$$$ERROR($$$FileCanNotOpen,i%CurrFile) Set i%CurrFile="" 
	
	#; write data to file
	Use i%CurrFile
	Write data
	Use io
	
	Quit $$$OK

WriteError	Set $ZTRAP=""
	Use io
	Close:i%CurrFile'="" i%CurrFile
	Set i%CurrFile=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

Method MoveToEnd() As %Status
{
	#; If no data or in write mode already nothing to do
	If (i%Mode=..#READNODATA)||(i%Mode=..#WRITE) Quit $$$OK
	
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	#; Need to copy file
	If i%Mode=..#READNOTCHANGED||(i%Mode=..#WRITEJUSTSAVED) {
		Set:i%TempFile="" i%TempFile=..NewFileName($select(i%StoreFile[".":$piece(i%StoreFile,".",*),1:""))
		If '$$$FileCopy(i%NormalizedDirectory_i%StoreFile,i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotCopy,i%NormalizedDirectory_i%StoreFile,i%NormalizedDirectory_i%TempFile)
	}
	
	#; reopen file in append mode
	If i%TempFile'="" {
		Set filename=i%NormalizedDirectory_i%TempFile
		Set parm=..GetWriteOpenParameter(filename,..#WRITEAPPEND)
		Set i%CurrFile=filename
		Open filename:(parm:/OBUFSIZE=32768:/NOXY=1):0
		Else  Set i%CurrFile="" Quit $$$ERROR($$$FileCanNotOpen,filename)
	}
	
	Set i%Mode=..#WRITE
	
	#; a write is never at the end
	Set i%AtEnd=0
	
	Quit $$$OK
}

Method CopyFrom(source As %AbstractStream) As %Status
{
	Quit:source=$$$NULLOREF $$$ERR($$$OrefInvalid)
	If $classname(source)'=$classname() Quit ##super(source)
	If ..%Extends("%Library.FileCharacterStream"),$this.TranslateTable'=source.TranslateTable Quit ##super(source)
	
	Set sc=$$$OK
	
	#; Optimise for copy from one file to another
	If i%Mode=..#WRITEJUSTSAVED Do ..MoveToEnd()
	
	#; Make sure all the data is accessible, also comes out of WRITE mode into READCHANGED
	Do source.Rewind()
	Set sourceFile=$S(source.Mode=..#READNODATA:"",source.Mode=..#READCHANGED:source.NormalizedDirectory_source.TempFile,source.Mode=..#READNOTCHANGED||(source.Mode=..#WRITEJUSTSAVED):source.NormalizedDirectory_source.StoreFile)
	
	#; If this is replacing the old data we can use a copy
	If i%Mode'=..#WRITE Do
	. If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	. If i%TempFile="" Do
	. . Set i%TempFile=..NewFileName($select(sourceFile[".":$piece(sourceFile,".",*),1:""))
	. Else  Do
	    #; delete old stream location, not really needed but is a good idea
	. . If $$$FileExists(i%NormalizedDirectory_i%TempFile),'$$$FileDelete(i%NormalizedDirectory_i%TempFile) Set sc=$$$ERROR($$$ObjectScriptError,"Can not delete file "_i%NormalizedDirectory_i%TempFile)
	. If $$$ISERR(sc) Quit
	
	  #; Copy the data and setup the properties and make sure we are at the end in case we need to append more data
	. If sourceFile'="" Do
	. . If '$$$FileCopy(sourceFile,i%NormalizedDirectory_i%TempFile) Set sc=$$$ERROR($$$ObjectScriptError,"Can not copy "_sourceFile_" to "_i%NormalizedDirectory_i%TempFile) Quit
	. . Set i%Mode=..#READCHANGED,i%CurrFile=i%NormalizedDirectory_i%TempFile
	    #; On Windows if the new file has the read only bit set then unset it
	. . If $$$isWINDOWS,$$$FileAttributes(i%CurrFile)#2 Do ##class(%File).SetWriteable(i%CurrFile,0)
	. . Do ..MoveToEnd()
	
	#; Else we can copy the data as fast as we can
	Else  If sourceFile'="" Do
	. Set io=$IO
	. Use i%CurrFile Set table=$$$GETIO
	. Open sourceFile:(..#OPENREAD_"K\"_table_"\":/NOXY=1:/OBUFSIZE=32768):0 Else  Use io Quit
	. Set $ZTrap="EndCopyRead",eofmode=$ZU(68,40) Do $ZU(68,40,0)
	. For  Use sourceFile Read data#32000 Use i%CurrFile Write data
EndCopyRead	. Set $ZTrap="" Do $ZU(68,40,eofmode)
	. Close sourceFile Use io
	. If $E($ze,1,11)'="<ENDOFFILE>" Set sc=$$$ERROR($$$ObjectScriptError,$ze)
	#; Now copy the attributes
	If source.%Extends("%Library.AbstractStream")||(source.%Extends("%CSP.Stream")) Do
	. Set name="" For  Set name=source.NextAttribute(name) Quit:name=""  Do ..SetAttribute(name,source.GetAttribute(name))

	Quit sc
}

Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Set $ZTrap="OutputError"
	If i%Mode=..#READNODATA Set len=-1,i%AtEnd=1 Quit $$$OK
	If len=0 Quit $$$OK
	Set io=$io,sc=$$$OK,eofmode=$ZU(68,40),sc=$$$OK
	Do $ZU(68,40,0)
	
	If len=-1 Do
	#; Note that Rewind turns off WRITE mode so we do not need to test for this, and it closes the file
	#; and sets i%CurrFile=""
	. Do ..Rewind()
	
	. Set pos=0
	. Set filename=i%NormalizedDirectory_$S(i%Mode=..#READNOTCHANGED||(i%Mode=..#WRITEJUSTSAVED):i%StoreFile,1:i%TempFile)
	. Set parm=..GetReadOpenParameter(filename,..#OPENREAD,.pos)
	. Open filename:(parm:/NOXY=1):0 Else  Set sc=$$$ERROR($$$FileCanNotOpen,filename) Quit
	. Set i%CurrFile=filename
	  #; Force position to start of file to be safe
	. Use filename:pos
	
	. Set $ZTrap="EndOutputRead"
	. Set len=0
	. For  Use i%CurrFile Read data#32000 Use io Write data Set len=len+$length(data)
EndOutputRead	. Set $ZTrap=""
	. If $E($ze,1,11)'="<ENDOFFILE>" Set sc=$$$ERROR($$$ObjectScriptError,$ze) Quit
	. Do ..Rewind()
	
	#; Else we continue outputting from where we left off
	Else  Do
	. If i%AtEnd=1 Set len=-1 Quit
	
	. Set $ZTRAP="EndOutput2Read"
	
	  #; This will switch to this device and set it up for us
	. If ..Mode=..#WRITE||(..Mode=..#WRITEJUSTSAVED) Do ..Rewind()
	. If (..ReadMode'=..#READNORMAL)||(..CurrFile="") Set sc=..SetupRead(..#READNORMAL) If $$$ISERR(sc) Quit
	
	. Set written=0
	. For  Quit:written=len  Use i%CurrFile Read data#$S(len-written<32000:len-written,1:32000) Use io Write data Set written=written+$L(data)
	
	  #; If we don't read the number we expect we must be at the end of the file
	. Use i%CurrFile Set zseek=$zseek() Use io
	. If written'=len||(zseek=..ReadSize) Set i%AtEnd=1
	. Set len=written
	. Quit

EndOutput2Read	. Set $ZTRAP=""
	#; if error (not EOF) close file
	. If $E($ze,1,11)'="<ENDOFFILE>" Close i%CurrFile Set i%CurrFile="",i%AtEnd=1,len=-1,sc=$$$ERROR($$$ObjectScriptError,$ze) Quit
	. Set i%AtEnd=1
	. Set len=written
	
	Use io
	Do $ZU(68,40,eofmode)
	Quit sc
OutputError	Do:$G(eofmode)'="" $ZU(68,40,eofmode) Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

Method Clear(permanent As %Boolean = 1) As %Status
{
	If i%Mode=..#READNODATA Quit $$$OK
	
	#; close file if open
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	
	#; Mode = ..#READCHANGED or ..#WRITE: Delete new data
	If (i%Mode=..#READCHANGED)||(i%Mode=..#WRITE) {
		If i%TempFile'="" If $$$FileReadOnly(i%NormalizedDirectory_i%TempFile)||($$$FileDelete(i%NormalizedDirectory_i%TempFile)=0) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	}
	If permanent {
		#; File not deleted, assume read only
		If i%StoreFile'="" If $$$FileReadOnly(i%NormalizedDirectory_i%StoreFile)||($$$FileDelete(i%NormalizedDirectory_i%StoreFile)=0) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%StoreFile)
		#; If we can reuse the old name do so
		If i%StoreFile'="" Set i%TempFile=i%StoreFile,i%StoreFile=""
		Set i%Mode=..#READNODATA,i%AtEnd=1
	} Else {
		Set i%Mode=..#READNOTCHANGED,i%AtEnd=1
	}
	#; Get rid of the attributes
	Merge lt=i%Attributes("LineTerminator") Kill i%Attributes Merge i%Attributes("LineTerminator")=lt
	Quit $$$OK
}

Method LastModifiedGet() As %TimeStamp
{
	Set timestamp=$$$FileDateModified(i%NormalizedDirectory_$S(i%Mode=..#READCHANGED||(i%Mode=..#WRITE):i%TempFile,1:i%StoreFile))
	Quit $S(timestamp<1:"",1:$zdt(timestamp,3))
}

/// Generate a stream OId that links to this <var>file</var>. This can be used by the CSP
/// server to generate an OID that can be embedded in a web page and later
/// used to display this file. The <var>contenttype</var> is an optional parameter to
/// specify the content type of this stream for display with a stream server.
/// If I have a file called 'C:\Test.txt' then I can create a stream linked to this by:
/// <EXAMPLE>
/// Set id=##class(%FileCharacterStream).GetStreamIdForFile("c:\Test.txt")
/// Set stream=##class(%FileCharacterStream).%Open(id)
/// Do stream.OutputToDevice()
/// </EXAMPLE>
ClassMethod GetStreamIdForFile(file As %String, contenttype As %String = "", charset As %String = "") As %String [ CodeMode = generator ]
{
	Set %code=0
	$$$GENERATE(" Quit $LB($C(0)_$LB($LB("""",file),$S(contenttype="""":"""",1:$LB($LB(""ContentType"",contenttype)))_$S(charset="""":"""",1:$LB($LB(""CharSet"",charset)))),"""_$S($E(%class,1,8)="%Library":"%"_$E(%class,10,*),1:%class)_""")")
}

Method GetReadOpenParameter(filename As %String, mode As %Integer, ByRef pos As %Integer) As %String [ Private ]
{
	Quit $select(mode=..#READLINE:..#OPENREADTERM,1:..#OPENREAD)
}

Method GetWriteOpenParameter(filename As %String, mode As %Integer) As %String [ CodeMode = expression, Private ]
{
$select(mode=..#WRITEAPPEND:..#OPENAPPEND,1:..#OPENWRITE)
}

/// Read a line from the file. Note that besides the normal ReadLine arguments this can also be passed a <var>term</var> which
/// will return the termintor that completed the line if we read in a whole line.
Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean, ByRef term As %String) As %RawString
{
	Set sc=$$$OK,eol=0,term=""
	#; test if we've already read to the end, or there is no data
	If i%AtEnd=1||(..Mode=..#READNODATA) Set len=-1 Quit ""
	
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	
	Set out=""
	Set io=$io
	
	#; test for end of file
	Set $ZTRAP="ReadLineError"
	
	#; This will switch to this device and set it up for us
	If ..Mode=..#WRITE||(..Mode=..#WRITEJUSTSAVED) Do ..Rewind()
	If (..ReadMode'=..#READLINE)||(..CurrFile="") {
		Set sc=..SetupRead(..#READLINE)  If $$$ISERR(sc) Use io Quit ""
	} Else {
		Use ..CurrFile
	}
	If len=0 Use io Quit ""
	
	Read out#len If $zb'="",..LineTerminator[$extract($zb) Set eol=1,term=$zb
	If $ZEOF||($zseek()=..ReadSize) Set $ZE="<ENDOFFILE>" Goto ReadLineError
	Use io
	
	Set len=$L(out)
	Quit out

ReadLineError	Set $ZTRAP=""
	Use io
	
	#; if error (not EOF) close file
	If $E($ze,1,11)'="<ENDOFFILE>" Close i%CurrFile Set i%CurrFile="",i%AtEnd=1,len=-1,sc=$$$ERROR($$$ObjectScriptError,$zerror) Quit ""
	
	#; if at end set AtEnd=1
	Set i%AtEnd=1
	
	#;if we are at the end with no data return -1
	Set len=$S($L(out)=0:-1,1:$L(out))
	Quit out
}

Method ReadLineIntoStream(ByRef sc As %Status) As %AbstractStream
{
	Set sc=$$$OK
	Set stream=..%New()
	#; test if we've already read to the end, or there is no data
	If i%AtEnd=1||(..Mode=..#READNODATA) Quit stream
	
	Set out=""
	Set io=$io
	
	#; test for end of file
	Set $ZTRAP="ReadLineError"
	
	#; This will switch to this device and set it up for us
	If ..Mode=..#WRITE||(..Mode=..#WRITEJUSTSAVED) Do ..Rewind()
	If (..ReadMode'=..#READLINE)||(..CurrFile="") {
		Set sc=..SetupRead(..#READLINE) If $$$ISERR(sc) Use io Quit ""
	} Else {
		Use ..CurrFile
	}
	
	For  { 
		Read out:0 If $test Quit
		If $ZEOF||($zseek()=..ReadSize) Set $ZE="<ENDOFFILE>" Goto ReadLineError
		Do stream.Write(out)
	}
	Use io
	Do:out'="" stream.Write(out)
	
	Quit stream

ReadLineError	Set $ZTRAP=""
	Use io
	
	#; if error (not EOF) close file
	If $E($ze,1,11)'="<ENDOFFILE>" Close i%CurrFile Set i%CurrFile="",i%AtEnd=1,len=-1,sc=$$$ERROR($$$ObjectScriptError,$zerror) Quit ""
	
	#; if at end set AtEnd=1
	Set i%AtEnd=1
	Do:out'="" stream.Write(out)
	Quit stream
}

Method %NormalizeObject() As %Status [ CodeMode = expression ]
{
$$$OK
}

Method %ValidateObject(force As %Integer = 0) As %Status [ CodeMode = expression ]
{
$$$OK
}

ClassMethod %Exists(soid As %ObjectIdentity) As %Boolean
{
	Set id=$list($extract($$$oidPrimary(soid),2,*))
	Set location=$list(id,1),loctmp=$list(id,2)
	Set location=$S(location="":$get(^%SYS("StreamLocation",$namespace)),1:$$$FileNormalizeDirectoryFull(location))
	If location=""||(loctmp="") Quit 0
	Quit ''$$$FileExists(location_loctmp)
}

ClassMethod %ObjectIsNull(soid As %ObjectIdentity) As %Boolean
{
	If soid=$$$NULLOID Quit 1
	If $isobject(soid)=1 Quit soid.%IsNull()
	Set class=$$$oidClassName(soid)
	If class'="" {
		Set class=$$$NormalizeClassname(class) If $classname()'=class Quit $classmethod(class,"%ObjectIsNull",soid)
	}
	Set serialized=$$$oidPrimary(soid)
	If $ascii(serialized)=0,$listget($extract(serialized,2,*),2)'="" Quit 0
	Quit '..%Exists(soid)
}

Storage Custom
{
<Type>%Library.CompleteCustomStorage</Type>
}

}
