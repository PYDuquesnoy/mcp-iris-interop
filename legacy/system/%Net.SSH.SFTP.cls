/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSSH

/// <p><b>For information on using this class</b>, see
/// <a target="_top" href="/csp/docbook/DocBook.UI.Page.cls?FIND=CLASSES+%25Net.SSH.SFTP">Using SSH</a>.</p>
/// A wrapper object for an SFTP session running over and existing SSH connection.  Use the OpenSFTP() method
/// of a previously connected and authenticated %Net.SSH.Session to instantiate a valid SFTP object for use.
/// <br/>
/// You should <b>NOT</b> create instances of %Net.SSH.SFTP directly!
/// <br/>
/// <b>NOTE:</b> %Net.SSH is currently not supported on OpenVMS platforms.
Class %Net.SSH.SFTP Extends %RegisteredObject [ System = 3 ]
{

/// SFTP Session handle
Property Session As %String [ Internal, Private ];

/// SFTP Remote Server Version
Property Version As %Integer;

/// SSH Session that hosts this SFTP session.
Property SSH As %Net.SSH.Session;

Method %OnNew(ssh As %Net.SSH.Session, sftp As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..SSH = ssh
	Set ..Session = $LI(sftp,1)
	Set ..Version = $LI(sftp,2)

	Quit $$$OK
}

/// Enumerate the contents of a directory.  Populates the <var>contents</var> array with $LIST entries for
/// each file in the directory, subscripted by a integer sequence, the $LIST is composed in the same
/// format as with the <method>FileInfo()<method> method.
/// <br/>
/// The optional <var>spec</var> parameter allows for wildcards when searching the directory.  The wildcards
/// that can be used are as follows:<br/>
/// <ul>
/// <li>*: Match zero or more characters</li>
/// <li>?: Match exactly one character</li>
/// </ul>
/// Some examples are:
/// <blockquote><pre>
/// *.txt
/// journal_???.*
/// 201?-??-??.log
/// </pre></blockquote>
/// 
Method Dir(directory As %String, ByRef contents, spec As %String = "", dotFiles As %Boolean = 0) As %Status [ PublicList = (contents, pattern, filter) ]
{
	New pattern,filter
	Set pattern=$CASE(spec,"":"",:..genPattern(spec))
	Set filter=$S(dotFiles:"",1:"1""."".e")
	Quit ..DirEnum(directory,$this,"dircallback")
}

/// Enumerate the contents of a directory by calling the specified instance method once for each entry
/// in the directory.  The signature of the callback should take two arguments, first an integer
/// sequence number and secondly a $LIST composed in the same format as with the FileInfo() method
/// (see FileInfo).
/// 
Method DirEnum(directory As %String, oref As %RegisteredObject, method As %String) As %Status
{
	#dim result As %List
	Set $ZE=""  // Clear $ZE when we invoke callbacks so CACHEERROR() is reset
	Quit:'$IsObject($G(oref)) $$$ERROR($$$OrefInvalid,$G(oref))
	Quit:'$ZNAME($G(method)) $$$ERROR($$$MethodNameInvalid,$G(method))
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPDIR,$LB(..Session,..fnremote(directory,"O"),oref,method))
	Quit:+$LG(result) $$$SSHERROR(result,"DirEnum")
	
	Quit $$$OK
}

/// Gets information about a file.  On return, info is a $LIST containing:
/// 
///   1) Filename
///   2) Size
///   3) File type
///      P: Named pipe (FIFO)
///      C: Character special
///      D: Directory
///      B: Block special
///      F: Regular file
///      L: Symbolic link
///      S: Socket
///      U: Unknown
///   4) Permissions
///   5) UID
///   6) GID
///   7) Last Access Time
///   8) Last Modification Time
/// 
/// Depending on the remote system, some information may not be available and
/// will be indicated by a null list element.
/// 
Method FileInfo(file As %String, ByRef info As %List) As %Status
{
	#dim result As %List
	Kill info
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPFILEINFO,$LB(..Session,..fnremote(file,"O")))
	Quit:+$LG(result) $$$SSHERROR(result,"FileInfo")

	// This is a $LIST
	Set info = $LI(result,2)
	Set tName = ..fnremote($LG(info,1),"I")
	Set $LI(info,1)=tName  // Convert name from remote charset
	
	Quit $$$OK
}

/// Create a new directory on the remote server, with the specified file mode (access).
Method MkDir(directory As %String, remotemode As %String = "0700") As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPMKDIR,$LB(..Session,..fnremote(directory,"O"),..parseMode(remotemode,448)))
	Quit:+$LG(result) $$$SSHERROR(result,"MkDir")
	
	Quit $$$OK
}

/// Remove a directory on the remote server
Method RmDir(directory As %String) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPRMDIR,$LB(..Session,..fnremote(directory,"O")))
	Quit:+$LG(result) $$$SSHERROR(result,"RmDir")
	
	Quit $$$OK
}

/// Delete a file on the remote server
Method Delete(file As %String) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPDELETE,$LB(..Session,..fnremote(file,"O")))
	Quit:+$LG(result) $$$SSHERROR(result,"Delete")
	
	Quit $$$OK
}

/// Rename a file on the remote server
Method Rename(old As %String, new As %String) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPRENAME,$LB(..Session,..fnremote(old,"O"),..fnremote(new,"O")))
	Quit:+$LG(result) $$$SSHERROR(result,"Rename")
	
	Quit $$$OK
}

/// Create a symlink on the remote server
Method SymLink(source As %String, target As %String) As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPSYMLINK,$LB(..Session,..fnremote(source,"O"),..fnremote(target,"O")))
	Quit:+$LG(result) $$$SSHERROR(result,"SymLink")
	
	Quit $$$OK
}

/// Put a file from the local filesystem to the remote server, setting the specified mode (access).
Method Put(local As %String, remote As %String, remotemode As %String = "0600", append As %Boolean = 0) As %Status
{
	#dim result As %List
	#dim perms As %Integer
	Set perms=..parseMode(remotemode,-1)
	If perms<0 {
		Quit $$$ERROR($$$InvalidArgument)
	}
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPPUT,$LB(..Session,..fnlocal(local,"O"),..fnremote(remote,"O"),perms,+$G(append)))
	Quit:+$LG(result) $$$SSHERROR(result,"Put")
	
	Quit $$$OK
}

/// Put a stream to the remote system, setting the specified mode (access).
/// If <var>stream</var> is a file stream we will just link to the file already present, otherwise we create a temp file to send.
Method PutStream(stream As %Stream.Object, remote As %String, remotemode As %String = "0600", append As %Boolean = 0) As %Status
{
	If $isobject($get(stream)),$case($classname(stream),"%Library.FileBinaryStream":1,"%Library.FileCharacterStream":1,"%Stream.FileBinary":1,"%Stream.FileCharacter":1,:0) {
		Set local=stream.Filename
	} Else {
		Set tmpstream=##class(%Stream.FileBinary).%New()
		Set tmpstream.RemoveOnClose=1
		Set sc=tmpstream.CopyFrom(stream) If $$$ISERR(sc) Quit sc
		Set local=tmpstream.Filename
	}
	Set sc=..Put(local,remote,.remotemode,.append)	// NOTE: Put() will convert the filename
	Quit sc
}

/// Get a file from the remote system, storing it in the local file system with the specified mode (access).
Method Get(remote As %String, local As %String, localmode As %String = "0600", append As %Boolean = 0) As %Status
{
	#dim result As %List
	#dim perms As %Integer
	Set perms=..parseMode(localmode,-1)
	If perms<0 {
		Quit $$$ERROR($$$InvalidArgument)
	}
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPGET,$LB(..Session,..fnremote(remote,"O"),..fnlocal(local,"O"),perms,+$G(append)))
	Quit:+$LG(result) $$$SSHERROR(result,"Get")
	
	Quit $$$OK
}

/// Get a file from the remote system, storing it in the <var>stream</var>.
/// If <var>stream</var> not defined on entry it will create a stream for this automatically. If <var>stream</var>
/// is a file stream we will just link to the file we created.
Method GetStream(remote As %String, ByRef stream As %Stream.Object, append As %Boolean = 0) As %Status
{
	Set local=##class(%File).TempFilename("ssh")
	Set sc=..Get(.remote,local,,.append)	// NOTE: Get() will convert the remote filename
	If $$$ISERR(sc) Quit sc
	If $isobject($get(stream)) {
		If $case($classname(stream),"%Library.FileBinaryStream":1,"%Library.FileCharacterStream":1,"%Stream.FileBinary":1,"%Stream.FileCharacter":1,:0) {
			Set sc=stream.LinkToFile(local) If $$$ISERR(sc) Quit sc
			Set stream.RemoveOnClose=1
		} Else {
			Set tmpstream=##class(%Stream.FileBinary).%New()
			Set sc=tmpstream.LinkToFile(local) If $$$ISERR(sc) Quit sc
			Set tmpstream.RemoveOnClose=1
			Set sc=stream.CopyFrom(tmpstream) If $$$ISERR(sc) Quit sc
		}
	} Else {
		Set stream=##class(%Stream.FileBinary).%New()
		Set sc=stream.LinkToFile(local) If $$$ISERR(sc) Quit sc
		Set stream.RemoveOnClose=1
	}
	Quit $$$OK
}

/// Change the size of the specified file (by either truncating or extending it).
Method SetSize(remote As %String, size As %Integer) As %Status
{
	#dim result As %List
	If '$$$SSHVALIDINT(size) || (size<0) {
		Quit $$$ERROR($$$InvalidArgument)
	}
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPSETSIZE,$LB(..Session,..fnremote(remote,"O"),size))
	Quit:+$LG(result) $$$SSHERROR(result,"SetSize")
	
	Quit $$$OK
}

/// Change the permissions mode for the specified file or directory.
Method SetPermissions(remote As %String, mode As %String) As %Status
{
	#dim result As %List
	#dim perms As %Integer
	Set perms = ..parseMode(mode,-1)
	If perms<0 {
	    Quit $$$ERROR($$$InvalidArgument)
	}
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPSETPERMISSIONS,$LB(..Session,..fnremote(remote,"O"),perms))
	Quit:+$LG(result) $$$SSHERROR(result,"SetPermissions")
	
	Quit $$$OK
}

/// Change the uid/gid for the specified file or directory (you must be the current owner or root).
Method SetOwnerAndGroup(remote As %String, uid As %Integer, gid As %Integer) As %Status
{
	#dim result As %List
	If '$$$SSHVALIDINT(uid) || (uid<0) || '$$$SSHVALIDINT(gid) || (gid<0) {
		Quit $$$ERROR($$$InvalidArgument)
	}
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPSETOWNERANDGROUP,$LB(..Session,..fnremote(remote,"O"),uid,gid))
	Quit:+$LG(result) $$$SSHERROR(result,"SetOwnerAndGroup")
	
	Quit $$$OK
}

/// Touch the file to have an access time of now.
Method Touch(remote As %String) As %Status
{
	Set now = $ZDT($ZTIMESTAMP,3)  // NOTE: $ZTIMESTAMP is UTC time
	Quit ..SetFileTime(remote,now,now)	// NOTE: SetFileTime() will convert the remote filename
}

/// Change the access and last modification times for the specified file (you must be the current owner or root).  NOTE: Timestamp values must be in UTC time (see $ZTIMESTAMP).
Method SetFileTime(remote As %String, atimeUTC As %TimeStamp, mtimeUTC As %TimeStamp) As %Status
{
	#dim result As %List
	Set $ZT="Trap"
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSFTPTOUCH,$LB(..Session,..fnremote(remote,"O"),..H2UTCFileTime($ZDTH(atimeUTC,3)),..H2UTCFileTime($ZDTH(mtimeUTC,3))))
	Quit:+$LG(result) $$$SSHERROR(result,"Touch")
	
	Quit $$$OK
Trap	
	Quit $S($ZE["<ILLEGAL VALUE>":$$$ERROR($$$InvalidArgument),1:$$$ERROR($$$ObjectScriptError,$ZE))
}

/// Sets the transfer buffer size for SFTP operations (in bytes).  The default is 1MB, performance may be
/// degraded when this is set to small values.
Method SetBufferSize(pBufferSize As %Integer) As %Status
{
	#dim result As %List
    
	If '$$$SSHVALIDINT(pBufferSize) || (pBufferSize<1024) {
		Quit $$$ERROR($$$InvalidArgument)
	}
    
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHSETSFTPBUFFERSIZE,$LB(..Session,pBufferSize\1))
	Quit:+$LG(result) $$$SSHERROR(result,"SetBufferSize")
	
	Quit $$$OK
}

/// Gets the transfer buffer size for SFTP operations (in bytes).
Method GetBufferSize(ByRef pBufferSize As %Integer) As %Status
{
	#dim result As %List

	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHGETSFTPBUFFERSIZE,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"GetBufferSize")

	// Grab the current buffer size value
	Set pBufferSize = $LG(result,2)
	
	Quit $$$OK
}

/// Clean up any resources
Method %OnClose() As %Status
{
	Quit $S(..Session'="":..CloseSFTP(),1:$$$OK)
}

/// Close the SFTP session
Method CloseSFTP() As %Status
{
	#dim result As %List
	Set result = $ZF(-6,$$$SSHLibrary,$$$SSHCLOSESFTP,$LB(..Session))
	Quit:+$LG(result) $$$SSHERROR(result,"CloseSFTP")
	
	Set ..Session = ""
	Set ..SSH = $$$NULLOREF
	
	Quit $$$OK
}

/// Demonstrates use of an SFTP session to enumerate the contents of the /etc directory on the remote
/// server.
ClassMethod Test(host As %String, username As %String, password As %String, dir As %String = "/etc", spec As %String = "", dotFiles As %Boolean = 1, ByRef t) As %Status
{
	Set s = ##class(%Net.SSH.Session).%New()
	Set port = $P(host,":",2)
	Set sc = s.Connect($P(host,":"),$CASE(port,"":22,:port))
	Quit:$$$ISERR(sc) sc
	Set sc = s.AuthenticateWithUsername(username,password)
	Quit:$$$ISERR(sc) sc
	Set sc = s.OpenSFTP(.t)
	Quit:$$$ISERR(sc) sc
	Set sc = t.Dir(dir,.files,spec,dotFiles)
	Quit:$$$ISERR(sc) sc
	
	// Determine the length of the longest file
	Set i="",l=0
	For {
		Set i = $O(files(i))
		Quit:i=""
		Set fn=$LG(files(i),1)
		Set:$L(fn)>l l=$L(fn)
	}
	
	Set l=l+2
	Write "Name",?l,"Size",?(l+10),"Ty",?(l+14),"Perm",?(l+24),"UID",?(l+30),"GID",!
	Write $TR($J("",l+36)," ","="),!
	
	// Dump out the directory contents, note that file times are relative to UTC time.
	For {
		Set i = $O(files(i))
		Quit:i=""
		Write $LG(files(i),1)										// Filename
		Write ?l,$J($LG(files(i),2),8)								// Size
		Write ?(l+10),$LG(files(i),3)								// Type
		Write ?(l+14),..Permissions2Text($LG(files(i),4))			// Permissions
		Write ?(l+24),$LG(files(i),5)								// UID
		Write ?(l+30),$LG(files(i),6)								// GID
		//Write !,?20,$ZDT(..UTCFileTime2H($LG(files(i),7)),3)," UTC"	// Last Access Time
		//Write !,?20,$ZDT(..UTCFileTime2H($LG(files(i),8)),3)," UTC"	// Last Modification Time
		Write !
	}
	
	Quit $$$OK
}

/// Demonstrates use of an SFTP session to put a file to the remote
/// server.
ClassMethod TestPut(host As %String, username As %String, password As %String, srcfile As %String, destfile As %String) As %Status
{
	Set s = ##class(%Net.SSH.Session).%New()
	Set sc = s.Connect(host)
	Quit:$$$ISERR(sc) sc
	Set sc = s.AuthenticateWithUsername(username,password)
	Quit:$$$ISERR(sc) sc
	Set sc = s.OpenSFTP(.t)
	Quit:$$$ISERR(sc) sc

	Set time=$ZH
	Set sc = t.Put(srcfile,destfile)
	Quit:$$$ISERR(sc) sc
	Set time=$ZH-time

	WRITE "That took ",time,"s",!
	
	Quit $$$OK
}

/// Convert UNIX permissions flags to a string
ClassMethod Permissions2Text(permissions As %Integer) As %String
{
	Set text="rwxrwxrwx"
	For k=1:1:9 Set:permissions#2=0 $E(text,10-k)="-" Set permissions=permissions\2
	Quit text
}

/// Convert UNIX file time to $HOROLOG, for UNIX time is the number of seconds since Midnight Jan 1, 1970
/// which has a $HOROLOG date of 47117,0
ClassMethod UTCFileTime2H(filetime As %Integer) As %String
{
#define UNIXEPOCH 47117
#define SECPERDAY 86400
	Quit (filetime\$$$SECPERDAY+$$$UNIXEPOCH)_","_(filetime#$$$SECPERDAY)
}

/// Convert $HOROLOG to UNIX file time; note that UNIX time is the number of seconds since Midnight Jan 1, 1970
/// which has a $HOROLOG date of 47117,0
ClassMethod H2UTCFileTime(horolog As %String) As %Integer
{
#define UNIXEPOCH 47117
#define SECPERDAY 86400
	Quit (($P(horolog,",")-$$$UNIXEPOCH)*$$$SECPERDAY)+$P(horolog,",",2)
}

/// Parse a UNIX 'chmod' style filemode into the integer value
ClassMethod parseMode(mode As %String, defaultmode As %Integer = 384) As %Integer [ Internal ]
{
	// Preprocess the mode from a user string
	If mode?1.(1.3(1"u",1"g",1"o")1"+"1.3(1"r",1"w",1"x").1",") {
		Set octal="0000"
		For i=1:1:$L(mode,",") {
			Set smode=$P(mode,",",i)
			Set target=$TR($P(smode,"+",1),"ugoUGO","123123")
			Set flags=$TR($P(smode,"+",2),"xwrXWR","124124"),value=0
			For j=1:1:$L(flags) Set v=+$E(flags,j) Set:value\v#2=0 value=value+v
			For j=1:1:$L(target) Set $E(octal,1+$E(target,j))=value#8
		}
		// Now, convert from octal
		Set mode=octal
	}
	
	If mode?1"0"3(1"0",1"1",1"2",1"3",1"4",1"5",1"6",1"7") {
		Set imode=0
		For i=2:1:$L(mode) Set imode=(imode*8)+(+$E(mode,i)#8)
	} ElseIf mode?1"0x"1.(1N,1"A",1"B",1"C",1"D",1"E",1"F",1"a",1"b",1"c",1"d",1"e",1"f") {
		Set imode=+$ZHEX($E(mode,3,$L(mode)))
	} ElseIf mode?1.N {
		Set imode=+mode
	} Else {
		// For anything else, use the default.
		Set imode=defaultmode
	}
	
	Quit imode
}

/// Internal helper method to convert filenames.  If the SFTP version is >3, we use UTF8, otherwise we use
/// the value of RemoteCharset (if not specified, then nothing is done).
Method fnremote(pIn As %String, pDirection As %String) As %Integer [ CodeMode = expression, Internal ]
{
$ZCVT(pIn,pDirection,$SELECT(..Version>3:"UTF8",1:..SSH.RemoteCharset))
}

/// Internal helper method to convert filenames to the local character set (if not specified, then nothing is done).
Method fnlocal(pIn As %String, pDirection As %String) As %Integer [ CodeMode = expression, Internal ]
{
$ZCVT(pIn,pDirection,..SSH.LocalCharset)
}

/// Internal helper method to act as a callback for directory enumeration.
Method dircallback(pIndex As %Integer, pFileInfo As %List) [ Internal, PublicList = (contents, pattern, filter) ]
{
	// Grab the filename and convert from UTF-8
	Set tName = ..fnremote($LG(pFileInfo,1),"I")
	If ($G(pattern)'="") || ($G(filter)'="") {
		// Check against the pattern
		If $G(pattern)'="",tName'?@pattern Quit
		If $G(filter)'="",tName?@filter Quit
	}
	Set contents(pIndex)=$LB(tName)_$LI(pFileInfo,2,*)
	Quit
}

/// Passed a pattern match this returns an COS style pattern and a start and stop point.
ClassMethod genPattern(pSpec As %String) As %String [ Internal ]
{
	// Double up the quotes
	Set pSpec=$replace(pSpec,"""","""""")
	
	// Regular wildcards
	For  Quit:pSpec'["**"  Set pSpec=$Piece(pSpec,"**",1)_"*"_$Piece(pSpec,"**",2,$Length(pSpec,"**"))
	Set (tPattern,tPart)=""
	For tI=1:1:$Length(pSpec) Do
	. If "*?"[$Extract(pSpec,tI) Do  Quit
	. . If tPart]"" Set tPattern=tPattern_"1"""_tPart_"""",tPart=""
	. . If $Extract(pSpec,tI)="?" Do  Quit
	. . . Set tN=1 For tI=tI:1:$Length(pSpec) Quit:$Extract(pSpec,tI+1)'="?"  Set tN=tN+1
	. . . Set tPattern=tPattern_tN_"E"
	. . If $Extract(pSpec,tI)="*" Set tPattern=tPattern_".E" Quit
	. Set tPart=tPart_$E(pSpec,tI)
	If tPart]"" Set tPattern=tPattern_"1"""_tPart_"""",tPart=""
	Quit tPattern
}

}
