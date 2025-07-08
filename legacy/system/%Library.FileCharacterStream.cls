/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DYNAMICDISPATCH

/// Stream class that stores character data in external files.
/// This class is deprecated in favor of <class>%Stream.FileCharacter</class>.
/// For example the following code opens a file character stream, points it at a particular file
/// on the filesystem and then reads it in line by line:
/// <example>
/// Set stream=##class(%FileCharacterStream).%New()
/// Set stream.Filename="c:\myfile.txt"
/// While 'stream.AtEnd {
/// Set line=stream.ReadLine()
/// ; Process the line here
/// }
/// </example>
/// The difference between file character stream and file binary streams is that the character
/// stream understands that it is writing character data and this may be subject to characterset
/// translation. For example you may wish to utf-8 encode character data being written to the file,
/// but with a binary file stream it is just a series of binary data and so this is always read/written
/// exactly as it is without and translation. Also the file is written in 'S' mode so for example
/// writing cr/lf on a unix system will just append lf as this is the unix line terminator.
Class %Library.FileCharacterStream Extends (%CharacterStream, %FileStreamAdaptor) [ Deprecated, Inheritance = right, MemberSuper = (%Compiler.Type.FileStream, %Compiler.Type.StreamLegacy), StorageStrategy = Custom, System = 2 ]
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
	Quit $$$oidComposeAd1(..%Id(),$classname(),$select(..TranslateTable=0:..%Location,1:$char(0)_$listbuild(..%Location,$listbuild("TranslateTable",..TranslateTable))))
}

/// The translation table to be used when reading or writing the file.<br>
/// See <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=LANDING+TRANSLATETABLES">Translation Tables</a>.</p>
/// Initial value of 0 indicates that the table has not yet been set.<br>
/// If translation table is set after the file has been opened
/// then switch the table used for the file.
/// If the translation table is set to "", then the "RAW" table is used.
Property TranslateTable As %String [ InitialExpression = "0", Transient ];

/// If translation table is set after the file has been opened
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
	Set i%TranslateTable=table,i%BOM=""
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

/// BOM characters that appear at start of file to signify which encoding it is using
Property BOM As %String [ Transient ];

/// Returns true if the file is Unicode.
/// This method may only be called after data has been read
/// from the file stream.
Method IsFileUnicode() As %Boolean
{
	Quit ($extract(i%TranslateTable,1,7)="Unicode")
}

Method GetReadOpenParameter(filename As %String, mode As %Integer, ByRef pos As %Integer) As %String [ Private ]
{
	Set parm = $select(mode=..#READLINE:..#OPENREADTERM,1:..#OPENREAD)
	If pos=0 {
		Set i%BOM=""
		Set io=$io
		Open filename:("RUK\RAW\":/noxy=1):0 Else  Quit parm ; caller will report error
		Try {
			Use filename Read header#2
		} Catch {
			Set header=""
		}
		If $extract(header,1,2)=$Char(255,254) Set i%TranslateTable="UnicodeLittle",i%BOM=$char(255,254),pos=2
		If $extract(header,1,2)=$Char(254,255) Set i%TranslateTable="UnicodeBig",i%BOM=$char(254,255),pos=2
		If $extract(header,1,2)=$char(239,187) {
			Try {
				Read header#1
				If header=$char(191) Set i%TranslateTable="UTF8",i%BOM=$char(239,187,191),pos=3
			} Catch {
			}
		}
		Use io
		Close filename
	}
	
	If i%TranslateTable=0 Set i%TranslateTable=""
	
	Quit parm_$select(i%TranslateTable'="":"K\"_i%TranslateTable_"\",1:"")
}

Method GetWriteOpenParameter(filename As %String, mode As %Integer) As %String [ Private ]
{
	Set parm=$select(mode=..#WRITEAPPEND:..#OPENAPPEND,1:..#OPENWRITE)
	
	If i%TranslateTable=0 Set i%TranslateTable=""
	If mode'=..#WRITEAPPEND,i%BOM'="" {
		Set io=$io
		Open filename:(..#OPENWRITE_"K\RAW\":/noxy=1):0 Else  Goto exit
		Use filename
		Write i%BOM
		Use io
		Close filename
		Set parm=..#OPENAPPEND
	}
	If '..StreamFormatWrite Set parm=$translate(parm,"S","U")
exit	Quit parm_$select(i%TranslateTable'="":"K\"_i%TranslateTable_"\",1:"")
}

/// Return the current size of the data stream.
/// Note this is complicated by having to worry about the translate table used to write the file.
Method SizeGet() As %Integer
{
	Set file=$select(i%Mode=..#READCHANGED||(i%Mode=..#WRITE):i%NormalizedDirectory_i%TempFile,i%Mode=..#READNOTCHANGED||(i%Mode=..#WRITEJUSTSAVED):i%NormalizedDirectory_i%StoreFile,1:"")
	If file="" Quit 0
	Set size=..FileBinarySize()
	If size=0 Quit 0
	Set noread=(..TranslateTable=0)
	If noread Do ..Read(0)
	Set table=..TranslateTable
	#; Fix this to set the default process file system translate table
	If table="" Set table=$$GetPDefIO^%SYS.NLS(3)
	If table="UnicodeLittle"||(table="UnicodeBig") Quit size-$length(..BOM)/2
	#; Check for translate table is a 1byte to 1char one
	If table="RAW"||($extract(table,1,$length("Latin"))="Latin")||($extract(table,1,$length("CP"))="CP") Quit size-$length(..BOM)
	Set mode=i%Mode
	Set pos=-(i%CurrFile=""),io=$io
	If mode'=..#WRITE,pos=0 {
		Use file Set pos=$zseek() Use io
	}
	If 'noread Do ..Rewind()
	Set size=0
	
	Set $ztrap="readError"
	#; This will switch to this device and set it up for us
	If (..ReadMode'=..#READNORMAL)||(..CurrFile="") {
		Set sc=..SetupRead(..#READNORMAL) If $$$ISERR(sc) Use io Quit 0
	} Else {
		Use ..CurrFile
	}
	#; Enable $zeof handling to replace <ENDOFFILE> errors
	#; Note that $zeof is set as a consequence of read and at EOF
	#; an empty string is returned
	Set tEOFMode=$ZU(68,40,1)
	Do { Read out Set size=size+$length(out) } While '$zeof
	Set $ztrap="" Do $ZU(68,40,tEOFMode)
cont	Use io
	If mode=..#WRITE Set ..Mode=..#READCHANGED Do ..MoveToEnd() Quit size
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

Storage Custom
{
<StreamLocation>^%Library.FileCharacterStreamS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
