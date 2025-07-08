/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DYNAMICDISPATCH

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.FileCharacter">Working with Streams</a>.</p>
/// Stream class that stores character data in files.
/// For example, the following code opens a file binary stream, points it at a particular file
/// on the filesystem, and then reads it in chunks of 32,000 bytes:
/// <example>
/// Set stream=##class(%Stream.FileCharacter).%New()
/// Set sc=stream.LinkToFile("c:\myfile.txt")
/// While 'stream.AtEnd {
/// Set line=stream.Read()
/// ; Process the chunk here
/// }
/// </example>
/// The difference between file character stream and file binary streams is that the character
/// stream understands that it is writing character data and this may be subject to characterset
/// translation. For example you may wish to utf-8 encode character data being written to the file,
/// but with a binary file stream it is just a series of binary data and so this is always read/written
/// exactly as it is without and translation. Also the file is written in 'S' mode so for example
/// writing cr/lf on a unix system will just append lf as this is the unix line terminator.
Class %Stream.FileCharacter Extends %Stream.FileBinary [ ClientDataType = CHARACTERSTREAM, MemberSuper = (%Compiler.Type.FileStream, %Compiler.Type.Stream), OdbcType = LONGVARCHAR, System = 2 ]
{

Parameter OPENREAD = "RU";

Parameter OPENWRITE = "WSN";

Parameter OPENAPPEND = "AWS";

Parameter OPENREADTERM = "RS";

/// The StreamFormatWrite property controls whether file output is in stream or undefined format.
/// If StreamFormatWrite is 1 (true), the default, the file is written in S (stream) format.
/// If StreamFormatWrite is 0 (false), the file is written in U (Undefined) format.
/// For Unix file output, S format converts crlf to lf which can be a problem for MIME
/// output such as email. The user can now set messagepart.TextData.StreamFormatWrite=0 
/// to keep crlf in text message parts of the mail message.
Property StreamFormatWrite As %Boolean [ InitialExpression = 1, Transient ];

/// Returns the OID of this object.
Method %Oid() As %ObjectIdentity
{
	Quit $$$oidComposeAd1(i%Id,$classname(),$select(i%OidTranslateTable=0:i%%Location,1:$char(0)_$listbuild(i%%Location,$listbuild("TranslateTable",i%OidTranslateTable))))
}

/// The translation table to be used when reading or writing the file.
/// See <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.
/// <br>Initial value of 0 indicates that the table has not yet been set.<br>
/// If the translation table is set after the file has been opened,
/// then switch the table used for the file.
/// If the translation table is set to "", then the "RAW" table is used.
Property TranslateTable As %String [ InitialExpression = "0", Transient ];

/// Used to create the oid, only defined if user has explicitly set this.
Property OidTranslateTable As %String [ InitialExpression = 0, Internal, Private, Transient ];

/// If translation table is set after the file has been opened,
/// then switch the table used for the file.
/// If the translation table is set to "", then the "RAW" table is used.
Method TranslateTableSet(table As %String) As %Status
{
	If table="" Set table="RAW"
	If i%TranslateTable=table Quit $$$OK
	If table'="RAW",table'=0 {
		Try {
			Set x=$zconvert("","O",table)
		} Catch {
			Try {
				Set x=$zconvert("","O",$zconvert(table,"U")),table=$zconvert(table,"U")
			} Catch {
				Try {
					Set x=$zconvert("","O",$zconvert(table,"l")),table=$zconvert(table,"l")
				} Catch {
					$$$THROWILLEGALVALUE
				}
			}
		}
		If i%TranslateTable=table Quit $$$OK
	}
	Set i%TranslateTable=table,i%BOM="",i%OidTranslateTable=table
	If i%TranslateTable="UnicodeLittle" {
		Set i%BOM=$char(255,254)
	} ElseIf i%TranslateTable="UnicodeBig" {
		Set i%BOM=$char(254,255)
	}
	If (table'=0) && (i%CurrFile'="") {
		Set io=$io
		Use i%CurrFile $$$SETIO(table)
		Use io
	}
	Quit $$$OK
}

/// BOM characters that appear at start of file to signify which encoding it is using.
Property BOM As %String [ Transient ];

/// Returns true if the file is Unicode.
/// This method may only be called after data has been read
/// from the file stream.
Method IsFileUnicode() As %Boolean
{
	Quit ($extract(i%TranslateTable,1,7)="Unicode")
}

Method OpenDevice(filename As %String, mode As %Integer, nocheck As %Boolean = 0) As %Status [ Private ]
{
	Set parm = $select(mode=$$$modeREADLINE:..#OPENREADTERM,1:..#OPENREAD)
	If i%TranslateTable=0 Set i%TranslateTable=""
	If 'nocheck {
		Set io=$io
		Set i%BOM=""
		Open filename:(parm_"K\RAW\"::i%LineTerminator:/NOXY=1:/GZIP=..#GZIP):0 Else  Set i%ReadSize=-1,i%AtEnd=1 RETURN $select($$$FileExistsRet(filename)=0:$$$ERROR($$$FileCanNotOpen,filename),1:$$$ERROR($$$FileDoesNotExist,filename))
		Try {
			Use filename Read header#2
		} Catch {
			Set header=""
		}
		If $extract(header,1,2)=$Char(255,254) Set i%TranslateTable="UnicodeLittle",i%BOM=$char(255,254)
		If $extract(header,1,2)=$Char(254,255) Set i%TranslateTable="UnicodeBig",i%BOM=$char(254,255)
		If $extract(header,1,2)=$char(239,187) {
			Try {
				Read header#1
				If header=$char(191) Set i%TranslateTable="UTF8",i%BOM=$char(239,187,191)
			} Catch {
			}
		}
		If i%BOM'="" {
			$$$SETIO(i%TranslateTable)
			Use io
		} Else {
			Use io
			Close filename
		}
	}
	
	If nocheck||(i%BOM="") {
		Open filename:(parm_$select(i%TranslateTable'="":"K\"_i%TranslateTable_"\",1:"")::i%LineTerminator:/NOXY=1:/GZIP=..#GZIP):0 Else  Set i%ReadSize=-1,i%AtEnd=1 RETURN $select($$$FileExistsRet(filename)=0:$$$ERROR($$$FileCanNotOpen,filename),1:$$$ERROR($$$FileDoesNotExist,filename))
	}
	Set i%ReadMode=mode,i%ReadSize=$zutil(140,1,filename),i%CurrFile=filename
	Quit $$$OK
}

Method GetWriteOpenParameter(filename As %String, mode As %Integer) As %String [ Private ]
{
	Set parm=$select(mode=$$$modeWRITEAPPEND:..#OPENAPPEND,1:..#OPENWRITE)
	
	If i%TranslateTable=0 Set i%TranslateTable=""
	If mode'=$$$modeWRITEAPPEND,i%BOM'="" {
		Set io=$io
		Open filename:(..#OPENWRITE_"K\RAW\":/NOXY=1:/GZIP=..#GZIP):0 Else  Goto exit
		Use filename
		Write i%BOM
		Use io
		Close filename
		Set parm=..#OPENAPPEND
	}
	If '..StreamFormatWrite Set parm=$translate(parm,"S","U")
exit	Quit parm_$select(i%TranslateTable'="":"K\"_i%TranslateTable_"\",1:"")
}

/// Returns the current size of the data stream.
/// Note this is complicated by having to worry about the translate table used to write the file.
Method SizeGet() As %Integer
{
	Set file=$select(i%Mode=$$$modeREADCHANGED||(i%Mode=$$$modeWRITE):i%NormalizedDirectory_i%TempFile,i%Mode=$$$modeREADNOTCHANGED||(i%Mode=$$$modeWRITEJUSTSAVED):i%NormalizedDirectory_i%StoreFile,1:"")
	If file="" Quit 0
	Set size=..FileBinarySize()
	If size=0 Quit 0
	Set noread=(i%TranslateTable=0)
	If noread Do ..Read(0)
	Set table=i%TranslateTable
	#; Fix this to set the default process file system translate table
	If table="" Set table=$$GetPDefIO^%SYS.NLS(3)
	If table="UnicodeLittle"||(table="UnicodeBig") Quit size-$length(i%BOM)/2
	#; Check for translate table is a 1byte to 1char one
	If table="RAW"||($extract(table,1,$length("Latin"))="Latin")||($extract(table,1,$length("CP"))="CP") Quit size-$length(i%BOM)
	Set mode=i%Mode
	Set pos=-(i%CurrFile=""),io=$io
	If mode'=$$$modeWRITE,pos=0 {
		Use file Set pos=$zseek() Use io
	}
	If 'noread Do ..Rewind()
	Set size=0
	
	Set $ztrap="readError"
	#; This will switch to this device and set it up for us
	If (i%ReadMode'=$$$modeREADNORMAL)||(i%CurrFile="") {
		Set sc=..SetupRead($$$modeREADNORMAL) If $$$ISERR(sc) Use io Quit 0
	}
	Use ..CurrFile
	#; Enable $zeof handling to replace <ENDOFFILE> errors
	#; Note that $zeof is set as a consequence of read and at EOF
	#; an empty string is returned
	Set tEOFMode=$ZU(68,40,1)
	Do { Read out Set size=size+$length(out) } While '$zeof
	Set $ztrap="" Do $ZU(68,40,tEOFMode)
cont	Use io
	If mode=$$$modeWRITE Set i%Mode=$$$modeREADCHANGED Do ..MoveToEnd() Quit size
	Do ..Rewind()
	If pos'=-1 {
		Do ..Read(0)
		Set io=$io Use file:pos Use io
	}
	Quit size
readError	Set $ztrap=""
	If $D(tEOFMode) Do $ZU(68,40,tEOFMode)
	If $zerror'["<READ>" ztrap $zerror
	Goto cont
}

Method %ObjectModified() As %Integer [ ServerOnly = 1 ]
{
	Quit $select(m%LineTerminator:1,1:$case(i%Mode,$$$modeREADNOTCHANGED:0,$$$modeREADNODATA:0,$$$modeWRITEJUSTSAVED:0,:1))
}

Method %IsModified() As %Integer
{
	Quit $select(m%LineTerminator:1,1:$case(i%Mode,$$$modeREADNOTCHANGED:0,$$$modeREADNODATA:0,$$$modeWRITEJUSTSAVED:0,:1))
}

}
