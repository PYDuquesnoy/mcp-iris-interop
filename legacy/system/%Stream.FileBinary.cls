/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sySystem, %occStream)

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.FileBinary">Working with Streams</a>.</p>
/// Stream class that stores binary data in files.
/// For example, the following code opens a file binary stream, points it at a particular file
/// on the filesystem, and then reads it in chunks of 32,000 bytes:
/// <example>
/// Set stream=##class(%Stream.FileBinary).%New()
/// Set sc=stream.LinkToFile("c:\myfile.txt")
/// While 'stream.AtEnd {
///   Set line=stream.Read()
///   ; Process the chunk here
/// }
/// </example>
Class %Stream.FileBinary Extends %Stream.Object [ ClientDataType = BINARYSTREAM, OdbcType = LONGVARBINARY, System = 2 ]
{

Parameter STORAGE = "OTHER";

Parameter FILEEXT = "stream";

Parameter OPENREAD = "RUK\RAW\";

Parameter OPENWRITE = "WUNK\RAW\";

Parameter OPENAPPEND = "AWUK\RAW\";

Parameter OPENREADTERM = "RSK\RAW\";

Parameter GZIP = 0;

Method %IsNull() As %Boolean [ CodeMode = expression ]
{
i%Mode=$$$modeREADNODATA
}

/// Holds the filename part of the permanent storage location.
Property StoreFile As %String [ Internal, Private, Transient ];

Method IdSet(id As %String) As %Status
{
	If id["/"||(id["\") {
		Set i%StoreFile=##class(%File).GetFilename(id)
	} Else {
		Set i%StoreFile=id
	}
	Set i%Id=id
	Set i%"%%OID"=..%Oid()
	Quit $$$OK
}

/// If true, then when saving this file we need to move it to the default permanent location
Property MakePermLoc As %Boolean [ InitialExpression = 0, Private, Transient ];

/// Note that setting the <property>%Location</property> will cause a few things to happen.
/// It will delete any temporary file that may have been created. It will not touch any
/// permanent file that this object was associated with. If you wish to delete this pre-existing
/// permanent file then call <method>Clear</method> passing '1' as the argument before setting
/// the %Location. It then marks this object as pointing to a null stream in the new directory
/// you specified.
Method %LocationSet(dir As %String) As %Status
{
	Do ..Clear(0)
	Set i%NormalizedDirectory=$S(dir="":"",1:$$$FileNormalizeDirectoryFull(dir)),i%%Location=dir,i%MakePermLoc=0
	#; Reset file to the null stream ready for new data in this new directory
	Set i%TempFile="",..Id=""
	Set i%Mode=$$$modeREADNODATA,i%AtEnd=1
	Quit $$$OK
}

/// The filename that this stream is currently using<p>
/// If you set this property to update the file we will write to/read from
/// this operation can fail if for example the directory specified does not exist.
/// To detect this failure either check the %Status return code of the <method>FilenameSet</method>
/// or if using 'Set stream.Filename=newname' then check %objlasterror after the call to see if it
/// reported an error.
Property Filename As %String(MAXLEN = 5000) [ Calculated ];

Method FilenameSet(file As %String) As %Status [ CodeMode = call ]
{
..LinkToFile(file)
}

Method FilenameGet() As %String [ CodeMode = expression ]
{
$case(i%Mode,$$$modeREADNOTCHANGED:i%NormalizedDirectory_i%StoreFile,$$$modeWRITEJUSTSAVED:i%NormalizedDirectory_i%StoreFile,$$$modeREADCHANGED:i%NormalizedDirectory_i%TempFile,$$$modeWRITE:i%NormalizedDirectory_i%TempFile,:$select(i%TempFile'="":i%NormalizedDirectory_i%TempFile,1:""))
}

/// Read only property that returns the canonical filename if the file is open and "" if the file is not open.
Property CanonicalFilename As %String(MAXLEN = 5000) [ Calculated ];

Method CanonicalFilenameGet() As %String [ CodeMode = expression ]
{
##class(%File).CanonicalFilename(..Filename)
}

Property Mode As %Integer [ InitialExpression = 0, Private ];

/// Normalized form of the directory. This is used for access to the file (as it adds the
/// extra '/' if needed), but it stores the <Property>%Location</Property> in the Id as
/// this may be a relative path.
Property NormalizedDirectory As %String(MAXLEN = 5000) [ Private ];

/// Name of file (without directory) containing temporary stream.
Property TempFile As %String(MAXLEN = 5000) [ Private, Transient ];

/// Full path name of currently opened file. Equal to "" if no file is open.
Property CurrFile As %String(MAXLEN = 5000) [ Private, Transient ];

/// If true then remove the permanent file as well as any temp file when this object is closed.
/// If you call %Save on a stream where RemoveOnClose is true, it will set this to false because if you
/// explicitly save the stream you no longer want it to be removed when the object is closed. In order
/// to make sure %Save always runs the logic to reset the flag, setting this to true 
/// causes %IsModified/%ObjectModified to return true.
Property RemoveOnClose As %Boolean [ InitialExpression = 0, Transient ];

/// Mode the device is opened in, either with terminators as delimitors or not.
Property ReadMode As %Integer [ InitialExpression = {$$$modeREADNORMAL}, Private, Transient ];

/// While reading, this holds the file size.
Property ReadSize As %Integer [ Transient ];

/// For file streams, the line will terminate on any of the characters set in the LineTerminator. It does not support
/// multi-character line terminators because it uses the ObjectScript file behavior which terminates on any of the characters.<br>
/// Also, for %FileCharacterStream, even if you set this when you call <method>WriteLine</method>, because the file was opened in 'S'
/// mode it will normalize the line terminator as the data is being written, so for example if you set LineTerminator to
/// $char(13,10) on Unix systems when you call <method>WriteLine</method> it will only write $char(10) to the file.
Property LineTerminator As %String(MAXLEN = 10) [ InitialExpression = {$get(^%SYS("Stream","LineTerminator"),$select($$$isUNIX:$char(10),1:$char(13,10)))}, Transient ];

Method LineTerminatorSet(terminator As %String) As %Status
{
	Set i%LineTerminator=terminator,i%ReadMode=$$$modeREADNORMAL
	Quit $$$OK
}

Method %OnConstructClone(object As %RegisteredObject, deep As %Boolean = 0, ByRef cloned As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set i%Mode=$$$modeREADNODATA,i%AtEnd=0,i%TempFile="",i%CurrFile="",i%ReadMode=$$$modeREADNORMAL,i%ReadSize=0
	Set isnull=object.%IsNull()
	#; If the existing Id contains the directory information then the clone should be in the same directory and it too needs the directory in the Id
	#; If the original stream is null do not set this Id as we can locate a null stream in the default location and CopyFrom will not be called so
	#; no need to allocate a new filename
	If i%Id["/"||(i%Id["\"),'isnull {
		Set i%TempFile=..NewFileName($select(i%StoreFile[".":$piece(i%StoreFile,".",*),1:""),i%NormalizedDirectory)
		Set ..Id=i%NormalizedDirectory_i%TempFile
	} Else {
		Set ..Id=""
	}
	If 'isnull RETURN ..CopyFrom(object)
	Quit $$$OK
}

Method %OnNew(initval As %String = "") As %Status [ Private ]
{
	Do ..LineTerminatorSetModified(0)
	If initval=$char(0) {
		Set initval=$get(^%SYS("StreamLocation",$namespace)),i%%Location=""
	} Else {
		Set i%%Location=initval
	}
	If initval="" {
		Set initval=..DefaultStreamDir(1)
		Set i%MakePermLoc=1
	} Else {
		Set i%MakePermLoc=0
	}
	Set i%NormalizedDirectory=$S(initval="":"",1:$$$FileNormalizeDirectoryFull(initval))
	Quit $$$OK
}

/// Return the default directory to use for streams if none specified
ClassMethod DefaultStreamDir(skip As %Boolean = 0) As %String
{
	If 'skip Set dir=$get(^%SYS("StreamLocation",$namespace))
	If $get(dir)="" Set dir=$get(^%SYS("TempDir",$namespace))
	If dir="" Set dir=$get($$$SYSTempDir)
	Quit dir
}

Method %LoadData(id As %String) As %Status [ Private ]
{
	#; intialize member variables
	Set i%AtEnd=0,filename=id
	#; If the id contains the full path use this
	If id["/"||(id["\") {
		Set dir=##class(%File).GetDirectory(id),filename=##class(%File).GetFilename(id)
	} ElseIf i%%Location="" {
		Set dir=..DefaultStreamDir()
		If dir'="" Set i%MakePermLoc=0
	} Else {
		Set dir=i%%Location
	}
	Set i%NormalizedDirectory=$S(dir="":"",1:$$$FileNormalizeDirectoryFull(dir))
	
	If id=""||($$$FileExists(i%NormalizedDirectory_filename)=0) {
		#; No file stored so it is a null stream
		Set i%Mode=$$$modeREADNODATA,i%AtEnd=1,i%TempFile=filename
	} Else {
		#; Else the file really exists so link to it
		Set i%Mode=$$$modeREADNOTCHANGED,i%AtEnd=($$$FileSize(i%NormalizedDirectory_filename)=0),i%TempFile=""
	}
	Set ..Id=id
	Quit $$$OK
}

Method %OnClose() As %Status [ Private ]
{
	If i%CurrFile'="" Close i%CurrFile
	If (i%Mode=$$$modeREADCHANGED)||(i%Mode=$$$modeWRITE) If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	If i%RemoveOnClose,i%StoreFile'="" If '$$$FileDelete(i%NormalizedDirectory_i%StoreFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%StoreFile)
	Quit $$$OK
}

Method Rewind() As %Status
{
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	Set i%AtEnd=$select(i%Mode=$$$modeREADNODATA:1,1:0)
	Set i%Mode=$case(i%Mode,$$$modeWRITEJUSTSAVED:$$$modeREADNOTCHANGED,$$$modeWRITE:$$$modeREADCHANGED,:i%Mode)
	Quit $$$OK
}

Method Flush() As %Status
{
	#; Empty and internal buffer to disk and reopen at end
	If i%Mode'=$$$modeWRITE Quit $$$OK
	Do ..Rewind(),..MoveToEnd()
	Quit $$$OK
}

/// Return the current size of the data stream. 
Method SizeGet() As %Integer [ CodeMode = expression ]
{
..FileBinarySize()
}

/// Return the current size of the file in bytes.
Method FileBinarySize() As %Integer
{
	If (i%Mode=$$$modeWRITE) && (i%CurrFile'="") {
		Try {
			Set io=$io
			Use i%CurrFile
			Write *-1
			Set size=$$$FileSize(i%CurrFile)
		} Catch {
			#; If we get an error someone else closed the file, so report the file size and reset our state
			Set size=$$$FileSize(i%CurrFile)
			Set i%CurrFile="",i%Mode=$$$modeREADCHANGED
		}
		Use io
		Quit size
	}
	Quit $select(i%Mode=$$$modeREADCHANGED||(i%Mode=$$$modeWRITE):$$$FileSize(i%NormalizedDirectory_i%TempFile),i%Mode=$$$modeREADNOTCHANGED||(i%Mode=$$$modeWRITEJUSTSAVED):$$$FileSize(i%NormalizedDirectory_i%StoreFile),1:0)
}

/// This method lets you connect a file stream to a file called <var>filename</var> without
/// making a copy of it. If the file does not already exist it will still allow you to link
/// to this file, and %IsNull() will return true until you write to this file.
/// On non-Windows platforms, a '\' character in the <var>filename</var> is not converted
/// to a directory delimiter. Any such desired translation must be done before calling
/// <method>LinkToFile</method>.
/// <EXAMPLE>
/// Do object.Image.LinkToFile("C:\temp\image.jpg") ; if Windows
/// Do object.Image.LinkToFile("/tmp/image.jpg")    ; if Unix
/// Do object.%Save()
/// </EXAMPLE>
/// The method, as its name suggests, creates a LINK to an EXISTING 
/// file. So this is a 'shared public' file, as it can be shared by 
/// several instances of a class, or even several classes. 
/// Using the <method>CopyFrom</method> method, on the contrary, creates a 
/// 'private' image, not sharable by other instances/classes, so 
/// these two methods are really different.<p>
/// The problems with shared public images are that several instances 
/// are all allowed to update and even delete the image, causing 
/// problems for other instances.<p>
/// For example, if dog #2 has image 'test.gif', I can also 
/// assign that image to dog #5 or even person #24. 
/// If I change the image for dog #5, then the image is changed in 
/// place to another image, thus upsetting dog#2 and person#24. 
/// If I delete dog#5, the image is also deleted and thus dog#2 
/// and person#24 are changed.<p>
/// Also note that if there is currently some temporary data in the old stream when the
/// <method>LinkToFile</method> is called, this temporary data will be removed before the
/// stream is linked to this filename.
Method LinkToFile(filename As %String) As %Status
{
	If filename="" Quit $$$ERROR($$$FileNameInvalid,filename)
	#; Do not allow two objects to open the same file
	Set filename=$$$FileNormalizeFilename(filename)
	#;SML3019 ; Handle file name with ",".
	If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$zutil(12,filename)) Quit $$$ERROR($$$FileAlreadyOpen,filename)
	Set directory=##class(%File).GetDirectory(filename,1)
	Set fileexists=$$$FileExists(filename)
	If fileexists {
		Set atend=($$$FileSize(filename)=0)
	} ElseIf '$$$FileDirectoryExists(directory) {
		Quit $$$ERROR($$$DirectoryNameInvalid,directory)
	}
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	
	#; Mode = $$$modeREADCHANGED or $$$modeWRITE: Delete new data
	If (i%Mode=$$$modeREADCHANGED)||(i%Mode=$$$modeWRITE) {
		If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	}
	
	Set i%MakePermLoc=0,i%NormalizedDirectory=directory
	#; If linking to a file in expected location just store filename part in %Id, else store full path in id
	Set location=i%%Location
	If location="" Set location=..DefaultStreamDir()
	If directory=$$$FileNormalizeDirectoryFull(location) {
		Set filename=##class(%File).GetFilename(filename)
	}
	Set ..Id=filename
	#; If the file does not exist then this is the name of the new file we will create
	If fileexists=0 {
		Set i%Mode=$$$modeREADNODATA,i%AtEnd=1,i%TempFile=i%StoreFile
	} Else {
		#; Else the stored file is of this name
		Set i%Mode=$$$modeREADNOTCHANGED,i%TempFile="",i%AtEnd=atend
	}
	Quit $$$OK
}

Method %SaveData(ByRef sid As %String) As %Status [ Private ]
{
	#; If they save it then we should cancel any remove on close they have defined.
	Set i%RemoveOnClose=0
	If i%Mode=$$$modeREADNODATA||(i%Mode=$$$modeREADNOTCHANGED)||(i%Mode=$$$modeWRITEJUSTSAVED) Quit $$$OK
	
	#; close file (if open), go to read mode
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	If i%MakePermLoc,i%Id="" {
		Set dir=$get(^%SYS("StreamLocation",$namespace),i%NormalizedDirectory)
		#; Rename so that stored filename remains constant
		If dir'=i%NormalizedDirectory {
			If '$$$FileRename(i%NormalizedDirectory_i%TempFile,dir_i%TempFile) {
				If '$$$FileCopy(i%NormalizedDirectory_i%TempFile,dir_i%TempFile) Quit $$$ERROR($$$FileCanNotRename,i%NormalizedDirectory_i%TempFile)
				If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
			}
			Set i%NormalizedDirectory=dir,i%MakePermLoc=0
		}
		Set ..Id=i%TempFile,i%TempFile=""
	} ElseIf i%Id'="" {
		If i%StoreFile'=i%TempFile {
			If $$$FileReadOnly(i%NormalizedDirectory_i%StoreFile)||('$$$FileDelete(i%NormalizedDirectory_i%StoreFile)),$$$FileExists(i%NormalizedDirectory_i%StoreFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%StoreFile)
			#; Rename so that stored filename remains constant
			If '$$$FileRename(i%NormalizedDirectory_i%TempFile,i%NormalizedDirectory_i%StoreFile) {
				If '$$$FileCopy(i%NormalizedDirectory_i%TempFile,i%NormalizedDirectory_i%StoreFile) Quit $$$ERROR($$$FileCanNotRename,i%NormalizedDirectory_i%TempFile)
				If '$$$FileDelete(i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
			}
		}
	} Else {
		Set ..Id=i%TempFile,i%TempFile=""
	}
	If i%Mode=$$$modeWRITE { Set i%Mode=$$$modeWRITEJUSTSAVED } Else { Set i%Mode=$$$modeREADNOTCHANGED }
	Set sid = i%Id
	Quit $$$OK
}

ClassMethod %DeleteData(streamvalue As %String, concurrency As %Integer) As %Status [ Private ]
{
	Set node = $$$oidPrimary(streamvalue) Quit:(node="") $$$OK
	If '(node["/"||(node["\")) {
		Set root=$$$oidSysAd1(streamvalue)
		If $ascii(root)=0 Set root=$extract(root,2,*),root=$list(root)
		If root="" Set root=$get(^%SYS("StreamLocation",$namespace))
		If root="" Set root=$get(^%SYS("TempDir",$namespace),$get($$$SYSTempDir))
		Set root=$S(root="":"",1:$$$FileNormalizeDirectoryFull(root))
		Set node=root_node
	}
	If '$$$FileExists(node) Quit $$$OK
	If $$$FileReadOnly(node)||($$$FileDelete(node)=0) Quit $$$ERROR($$$FileCanNotDelete,node)
	Quit $$$OK
}

ClassMethod NewFileName(ext As %String = "", directory As %String = "") As %String
{
	Set ext=$piece($translate(ext,"\","/"),"/",*)
	If ext="" Set ext=..#FILEEXT
	If directory'="" RETURN $piece($translate($$$FileTempFileExtDir(ext,directory),"\","/"),"/",*)
	Quit $translate($zstrip($SYSTEM.Encryption.Base64Encode($system.Encryption.GenCryptRand(10)),">","="), "+/", "ab")_"."_ext
}

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %RawString
{
	Set sc=$$$OK,ze=$zerror
	If i%Mode=$$$modeWRITEJUSTSAVED Set i%Mode=$$$modeREADNOTCHANGED
	#; test if we've already read to the end, or there is no data
	If i%AtEnd=1||(i%Mode=$$$modeREADNODATA),i%Mode'=$$$modeWRITE Set len=-1,i%AtEnd=1 Quit ""
	
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	
	Set io=$io,out=""
	#; test for end of file
	Set $ZTRAP="ReadError"
	
	#; This will switch to this device and set it up for us
	If i%Mode=$$$modeWRITE Do ..Rewind()
	If (i%ReadMode'=$$$modeREADNORMAL)||(i%CurrFile="") {
		Set sc=..SetupRead($$$modeREADNORMAL) If $$$ISERR(sc) Use io Set $zerror=ze Quit ""
	}
	If len=0 Use io Quit ""
	Use i%CurrFile
	Read:len out#len If $zeof Set $ZE="<ENDOFFILE>" Goto ReadError

	If $zseek()=i%ReadSize Close i%CurrFile Set i%CurrFile="",i%AtEnd=1
	Use io
	Set len=$length(out),$zerror=ze
	Quit out
	
ReadError Set $ZTRAP=""
	Use io
	#; if error (not EOF) close file
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	If $E($ze,1,11)'="<ENDOFFILE>" Set sc=$$$ERROR($$$ObjectScriptError,$zerror)
	Set:'$D(out) out="" ; READ error may leave out undefined
	Set i%AtEnd=1,$zerror=ze
	Set len=$S($L(out)=0:-1,1:$L(out))
	Quit out
}

/// Move to this <var>position</var> in the stream. If this suceeds then return
/// true, else return false.
/// Note that moving to position 1 will be at the start of the stream, position 2 will be
/// at the second character of the stream, etc.
Method MoveTo(position As %Integer) As %Boolean
{
	Set position=position-1
	Set sc=..Rewind() If $$$ISERR(sc) RETURN 0
	If position>0 {
		Set io=$io Set sc=..SetupRead(i%Mode,position) Use io  ; Passing in 'position' argument makes this open the file and seek to this location
		If $$$ISERR(sc) RETURN 0
		; See if we were asked to move past the end of the file
		If position>$select(i%Mode=$$$modeREADCHANGED||(i%Mode=$$$modeWRITE):$$$FileSize(i%NormalizedDirectory_i%TempFile),i%Mode=$$$modeREADNOTCHANGED||(i%Mode=$$$modeWRITEJUSTSAVED):$$$FileSize(i%NormalizedDirectory_i%StoreFile),1:0) RETURN 0
	}
	RETURN 1
}

Method SetupRead(newMode As %Integer, pos As %Integer = 0) As %Status [ Private ]
{
	#; Mode $$$modeWRITE: in middle of Write with no rewind; rewind
	If i%Mode=$$$modeWRITE Do ..Rewind()
	
	#; read data from file; return 0 if no more data
	Set fileexists=1,io=$io
	Set $ZTRAP="SetupReadError"
	
	#; If we are changing read mode, then make a note of the position and force
	#; it to reopen the file by setting i%CurrFile=""
	If i%ReadMode'=newMode,i%CurrFile'="" {
		If pos=0 Use i%CurrFile Set pos=$ZSEEK() Use io
		Close i%CurrFile Set i%CurrFile=""
	}
	
	#; is the first time we are reading?
	#; if not changed, read from old file; else read from temp file
	If i%CurrFile="" {
		Set filename=i%NormalizedDirectory_$select(i%Mode=$$$modeREADNOTCHANGED:i%StoreFile,1:i%TempFile)
		#; Do not allow two objects to open the same file
		#;SML3019 ; Handle file name with ",".
		If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$zutil(12,filename)) Set len=-1,i%AtEnd=1 Quit $$$ERROR($$$FileAlreadyOpen,filename)
		Set sc=..OpenDevice(filename,newMode,pos'=0) If $$$ISERR(sc) Quit sc
		#; Force position to where we left off if doing ReadLine()
		If pos Use filename:pos
	}
	
	Quit $$$OK

SetupReadError	Set $ZTRAP="" Use io
	Set len=-1,i%AtEnd=1 
	Quit $$$ERROR($$$ObjectScriptError,$zerror)
}

Method Write(data As %RawString = "") As %Status
{
	#; Mode '= $$$modeWRITE; clear TempFile; prepare for write
	If i%Mode=$$$modeWRITEJUSTSAVED {
		Set sc=..MoveToEnd() If $$$ISERR(sc) Quit sc
	} ElseIf i%Mode'=$$$modeWRITE {
		#; Mode = READNODATA or $$$modeREADNOTCHANGED: set up for write: create new file
		If (i%Mode=$$$modeREADNODATA)||(i%Mode=$$$modeREADNOTCHANGED) Set:i%TempFile="" i%TempFile=..NewFileName($select(i%StoreFile[".":$piece(i%StoreFile,".",*),1:""),i%NormalizedDirectory)
		If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
		Set i%Mode=$$$modeWRITE
	}
	
	#; write is never at the end
	Set i%AtEnd=0,sc=$$$OK
	
	#; Open the file if this is the first time;
	If i%CurrFile="" {
		#; Do not allow two objects to open the same file
		#;SML3019 ; Handle file name with ",".
		If $LISTFIND($LFS($translate($piece($View(-1,$job),"^",3),"*"),",",2),$ZU(12,i%NormalizedDirectory_i%TempFile)) Quit $$$ERROR($$$FileAlreadyOpen,i%NormalizedDirectory_i%TempFile)
		Set parm=..GetWriteOpenParameter(i%NormalizedDirectory_i%TempFile,$$$modeWRITENORMAL)
		Set i%CurrFile=i%NormalizedDirectory_i%TempFile
		Open i%CurrFile:(parm:::/OBUFSIZE=32768:/NOXY=1:/GZIP=..#GZIP):0 Else  Set i%CurrFile="" Quit $$$ERROR($$$FileCanNotOpen,i%NormalizedDirectory_i%TempFile)
	}
	
	#; write data to file
	Try {
		Set io=$io
		Use i%CurrFile
		Write data
		Use io
	} Catch {
		Use io
		Close:i%CurrFile'="" i%CurrFile
		Set sc=$$$ERROR($$$ObjectScriptError,$zerror),i%CurrFile=""
	}
	Quit sc
}

/// Appends the string <var>data</var> along with a line terminator to the stream and advances the 
/// current stream position by the number of characters in <var>data</var> plus the line terminator.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method WriteLine(data As %RawString = "") As %Status
{
	If $length(data)+$length(i%LineTerminator)>$$$MaxLocalLength {
		Set sc=..Write(data)
		If $$$ISOK(sc) Set sc=..Write(i%LineTerminator)
	} Else {
		Set sc=..Write(data_i%LineTerminator)
	}
	Quit sc
}

Method MoveToEnd() As %Status
{
	#; If no data or in write mode already nothing to do
	If (i%Mode=$$$modeREADNODATA)||(i%Mode=$$$modeWRITE) Quit $$$OK
	
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	#; Need to copy file
	If i%Mode=$$$modeREADNOTCHANGED||(i%Mode=$$$modeWRITEJUSTSAVED) {
		Set:i%TempFile="" i%TempFile=..NewFileName($select(i%StoreFile[".":$piece(i%StoreFile,".",*),1:""),i%NormalizedDirectory)
		If '$$$FileCopy(i%NormalizedDirectory_i%StoreFile,i%NormalizedDirectory_i%TempFile) Quit $$$ERROR($$$FileCanNotCopy,i%NormalizedDirectory_i%StoreFile,i%NormalizedDirectory_i%TempFile)
	}
	
	#; reopen file in append mode
	If i%TempFile'="" {
		Set filename=i%NormalizedDirectory_i%TempFile
		Set parm=..GetWriteOpenParameter(filename,$$$modeWRITEAPPEND)
		Open filename:(parm:::/OBUFSIZE=32768:/NOXY=1:/GZIP=..#GZIP):0 Else  Quit $$$ERROR($$$FileCanNotOpen,filename)
		Set i%CurrFile=filename
	}
	
	#; a write is never at the end
	Set i%Mode=$$$modeWRITE,i%AtEnd=0
	Quit $$$OK
}

Method CopyFrom(source As %AbstractStream) As %Status
{
	Quit:source=$$$NULLOREF $$$ERROR($$$OrefInvalid,"")
	If $classname(source)'=$classname() Quit ##super(source)
	If ..%Extends("%Stream.FileCharacter"),$this.TranslateTable'=source.TranslateTable Quit ##super(source)
	
	Set sc=$$$OK
	
	#; Optimise for copy from one file to another
	If i%Mode=$$$modeWRITEJUSTSAVED Do ..MoveToEnd()
	#; Make sure all the data is accessible, also comes out of WRITE mode into READCHANGED
	Do source.Rewind()
	Set sourceFile=$S(source.Mode=$$$modeREADNODATA:"",source.Mode=$$$modeREADCHANGED:source.NormalizedDirectory_source.TempFile,source.Mode=$$$modeREADNOTCHANGED||(source.Mode=$$$modeWRITEJUSTSAVED):source.NormalizedDirectory_source.StoreFile)
	
	#; If this is replacing the old data we can use a copy
	If i%Mode'=$$$modeWRITE Do
	. If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	. If i%TempFile="" Do
	. . Set i%TempFile=..NewFileName($select(sourceFile[".":$piece(sourceFile,".",*),1:""),i%NormalizedDirectory)
	. Else  Do
	    #; delete old stream location, not really needed but is a good idea
	. . If $$$FileExists(i%NormalizedDirectory_i%TempFile),'$$$FileDelete(i%NormalizedDirectory_i%TempFile) Set sc=$$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	. If $$$ISERR(sc) Quit
	
	  #; Copy the data and setup the properties and make sure we are at the end in case we need to append more data
	. If sourceFile'="" Do
	. . If '$$$FileCopy(sourceFile,i%NormalizedDirectory_i%TempFile) Set sc=$$$ERROR($$$FileCanNotCopy,sourceFile,i%NormalizedDirectory_i%TempFile) Quit
	. . Set i%Mode=$$$modeREADCHANGED,i%CurrFile=i%NormalizedDirectory_i%TempFile
	    #; On Windows if the new file has the read only bit set then unset it
	. . If $$$isWINDOWS,$$$FileAttributes(i%CurrFile)#2 Do ##class(%File).SetWriteable(i%CurrFile,0)
	. . Do ..MoveToEnd()

	#; Else we can copy the data as fast as we can
	Else  If sourceFile'="" Do
	. Set io=$IO
	. Use i%CurrFile Set table=$$$GETIO
	. Open sourceFile:(..#OPENREAD_"K\"_table_"\":/NOXY=1:/OBUFSIZE=32768:/GZIP=..#GZIP):0 Else  Use io Quit
	. Set $ZTrap="EndCopyRead",eofmode=$ZU(68,40) Do $ZU(68,40,0)
	. For  Use sourceFile Read data#32000 Use i%CurrFile Write data
EndCopyRead	. Set $ZTrap="" Do $ZU(68,40,eofmode)
	. Close sourceFile Use io
	. If $E($ze,1,11)'="<ENDOFFILE>" Set sc=$$$ERROR($$$ObjectScriptError,$ze)
	
	Quit sc
}

Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Set $ZTrap="OutputError"
	If i%Mode=$$$modeREADNODATA Set len=-1,i%AtEnd=1 Quit $$$OK
	If len=0 Quit $$$OK
	Set io=$io,sc=$$$OK,eofmode=$ZU(68,40),sc=$$$OK
	Do $ZU(68,40,0)
	
	If len=-1 Do
	#; Note that Rewind turns off WRITE mode so we do not need to test for this, and it closes the file
	#; and sets i%CurrFile=""
	. Do ..Rewind()
	. Set filename=i%NormalizedDirectory_$S(i%Mode=$$$modeREADNOTCHANGED||(i%Mode=$$$modeWRITEJUSTSAVED):i%StoreFile,1:i%TempFile)
	. Set sc=..OpenDevice(filename,..#OPENREAD,0) If $$$ISERR(sc) Quit
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
	. If i%Mode=$$$modeWRITE||(i%Mode=$$$modeWRITEJUSTSAVED) Do ..Rewind()
	. If (i%ReadMode'=$$$modeREADNORMAL)||(i%CurrFile="") Set sc=..SetupRead($$$modeREADNORMAL) If $$$ISERR(sc) Quit
	
	. Set written=0
	. For  Quit:written=len  Use i%CurrFile Read data#$S(len-written<32000:len-written,1:32000) Use io Write data Set written=written+$L(data)
	. Use i%CurrFile Set:$zseek()=i%ReadSize i%AtEnd=1 Use io 
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
	If i%Mode=$$$modeREADNODATA Quit $$$OK
	
	#; close file if open
	If i%CurrFile'="" Close i%CurrFile Set i%CurrFile=""
	
	#; Mode = $$$modeREADCHANGED or $$$modeWRITE: Delete new data
	If (i%Mode=$$$modeREADCHANGED)||(i%Mode=$$$modeWRITE) {
		If i%TempFile'="" If $$$FileReadOnly(i%NormalizedDirectory_i%TempFile)||($$$FileDelete(i%NormalizedDirectory_i%TempFile)=0) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%TempFile)
	}
	If permanent {
		#; File not deleted, assume read only
		If i%StoreFile'="" {
			If $$$FileReadOnly(i%NormalizedDirectory_i%StoreFile)||($$$FileDelete(i%NormalizedDirectory_i%StoreFile)=0) Quit $$$ERROR($$$FileCanNotDelete,i%NormalizedDirectory_i%StoreFile)
			#; If we can reuse the old name do so
			Set i%TempFile=i%StoreFile
		}
		Set i%Mode=$$$modeREADNODATA,i%AtEnd=1
	} Else {
		Set i%Mode=$$$modeREADNOTCHANGED,i%AtEnd=1
	}
	Quit $$$OK
}

Method LastModifiedGet() As %TimeStamp
{
	Set timestamp=$$$FileDateModified(i%NormalizedDirectory_$S(i%Mode=$$$modeREADCHANGED||(i%Mode=$$$modeWRITE):i%TempFile,1:i%StoreFile))
	Quit $select(timestamp<1:"",1:$zdt(timestamp,3))
}

Method OpenDevice(filename As %String, mode As %Integer, nocheck As %Boolean = 0) As %Status [ Private ]
{
	Set parm = $select(mode=$$$modeREADLINE:..#OPENREADTERM,1:..#OPENREAD)
	Open filename:(parm::i%LineTerminator:/NOXY=1:/GZIP=..#GZIP):0 Else  Set i%ReadSize=-1,i%AtEnd=1  RETURN $select($$$FileExistsRet(filename)=0:$$$ERROR($$$FileCanNotOpen,filename),1:$$$ERROR($$$FileDoesNotExist,filename))
	Set i%ReadMode=mode,i%ReadSize=$zutil(140,1,filename),i%CurrFile=filename
	Quit $$$OK
}

Method GetWriteOpenParameter(filename As %String, mode As %Integer) As %String [ CodeMode = expression, Private ]
{
$select(mode=$$$modeWRITEAPPEND:..#OPENAPPEND,1:..#OPENWRITE)
}

/// Read a line from the file. Note that besides the normal ReadLine arguments this can also be passed a <var>term</var> which
/// will return the terminator that completed the line if we read in a whole line.
Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean, ByRef term As %String) As %RawString
{
	Set sc=$$$OK,eol=0,term=""
	#; test if we've already read to the end, or there is no data
	If i%AtEnd=1||(i%Mode=$$$modeREADNODATA) Set len=-1 Quit ""
	
	Set:len>$$$MaxLocalLength len=$$$MaxLocalLength
	
	Set out="",io=$io
	
	#; test for end of file
	Set $ZTRAP="ReadLineError"
	
	#; This will switch to this device and set it up for us
	If i%Mode=$$$modeWRITE||(i%Mode=$$$modeWRITEJUSTSAVED) Do ..Rewind()
	If (i%ReadMode'=$$$modeREADLINE)||(i%CurrFile="") {
		Set sc=..SetupRead($$$modeREADLINE)  If $$$ISERR(sc) Quit ""
	}
	If len=0 Use io Quit ""
	Use i%CurrFile
	Read out#len If $zb'="",i%LineTerminator[$extract($zb) Set eol=1,term=$zb
	If $ZEOF||($zseek()=i%ReadSize) Set $ZE="<ENDOFFILE>" Goto ReadLineError
	Use io
	Set len=$length(out)
	Quit out

ReadLineError	Set $ZTRAP=""
	Use io
	
	#; if error (not EOF) close file
	If $extract($zerror,1,11)'="<ENDOFFILE>" Close i%CurrFile Set i%CurrFile="",i%AtEnd=1,len=-1,sc=$$$ERROR($$$ObjectScriptError,$zerror) Quit ""
	
	#; if at end set AtEnd=1
	Set i%AtEnd=1
	
	#;if we are at the end with no data return -1
	Set len=$select($length(out)=0:-1,1:$length(out))
	Quit out
}

Method ReadLineIntoStream(ByRef sc As %Status) As %AbstractStream
{
	Set sc=$$$OK
	If i%AtEnd Quit ""
	Set stream=..%New()
	#; test if there is no data
	If (i%Mode=$$$modeREADNODATA) Set i%AtEnd=1  Quit stream
	
	Set out=""
	Set io=$io
	
	#; test for end of file
	Set $ZTRAP="ReadLineError"
	
	#; This will switch to this device and set it up for us
	If i%Mode=$$$modeWRITE||(i%Mode=$$$modeWRITEJUSTSAVED) Do ..Rewind()
	If (i%ReadMode'=$$$modeREADLINE)||(i%CurrFile="") {
		Set sc=..SetupRead($$$modeREADLINE) If $$$ISERR(sc) Use io Quit ""
	}
	Use i%CurrFile
	For  { 
		Read out:0 If $zb=i%LineTerminator Quit
		If $ZEOF||($zseek()=i%ReadSize) Set $ZE="<ENDOFFILE>" Goto ReadLineError
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
	Set root=$$$oidSysAd1(soid)
	If $ascii(root)=0 Set root=$extract(root,2,*),root=$list(root)
	Set root=$S(root="":$get(^%SYS("StreamLocation",$namespace)),1:$$$FileNormalizeDirectoryFull(root))
	Set node = $$$oidPrimary(soid) Quit:(node="") $$$OK
	Quit $$$FileExists(root_node)
}

Method %ObjectModified() As %Integer [ ServerOnly = 1 ]
{
	Quit $select(i%RemoveOnClose:1,1:$case(i%Mode,$$$modeREADNOTCHANGED:0,$$$modeREADNODATA:0,$$$modeWRITEJUSTSAVED:0,:1))
}

Method %IsModified() As %Integer
{
	Quit $select(i%RemoveOnClose:1,1:$case(i%Mode,$$$modeREADNOTCHANGED:0,$$$modeREADNODATA:0,$$$modeWRITEJUSTSAVED:0,:1))
}

ClassMethod %ObjectIsNull(soid As %ObjectIdentity) As %Boolean
{
	If soid=$$$NULLOID Quit 1
	If $isobject(soid)=1 Quit soid.%IsNull()
	Set class=$$$oidClassName(soid)
	If class'="" {
		Set class=$$$NormalizeClassname(class) If $classname()'=class Quit $classmethod(class,"%ObjectIsNull",soid)
	}
	Quit '..%Exists(soid)
}

}
