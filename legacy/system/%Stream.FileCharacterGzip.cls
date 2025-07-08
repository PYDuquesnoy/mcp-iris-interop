/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p><b>For information on this class</b>, see 
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25Stream.FileCharacterGzip">Working with Streams</a>.</p>
Class %Stream.FileCharacterGzip Extends FileCharacter
{

Parameter FILEEXT = "stream.gz";

Parameter GZIP = 1;

/// Return the current size of the data stream.
Method SizeGet() As %Integer
{
	Set file=$select(i%Mode=$$$modeREADCHANGED||(i%Mode=$$$modeWRITE):i%NormalizedDirectory_i%TempFile,i%Mode=$$$modeREADNOTCHANGED||(i%Mode=$$$modeWRITEJUSTSAVED):i%NormalizedDirectory_..Id,1:"")
	If file="" Quit 0
	If ..FileBinarySize()=0 Quit 0
	Set atstart=(..TranslateTable=0)
	If atstart Do ..Read(0)
	Set table=..TranslateTable
	#; Fix this to set the default process file system translate table
	If table="" Set table=$$GetPDefIO^%SYS.NLS(3)
	#; On VMS we can not determine the file size because we can not goto the current position again
	#; But if we are at the start of the file we can go back to this, or at the end
	Set mode=..Mode
	Set io=$io
	If 'atstart Do ..Rewind()
	Set size=0
	
	Set $ztrap="readError"
	#; This will switch to this device and set it up for us
	If (..ReadMode'=$$$modeREADNORMAL)||(..CurrFile="") {
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
	If mode=$$$modeWRITE Set ..Mode=$$$modeREADCHANGED Do ..MoveToEnd() Quit size
	Do ..Rewind()
	Quit size
readError	Set $ztrap=""
	If $D(tEOFMode) Do $ZU(68,40,tEOFMode)
	If $zerror'["<READ>" ztrap $zerror
	Goto cont
}

}
