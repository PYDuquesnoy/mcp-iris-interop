/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occIO

/// Adapts %IO stream classes to provide a legacy %Library.AbstractStream interface
Class %IO.LibraryStream Extends %Library.AbstractStream [ ClassType = "", System = 2 ]
{

/// The %IO.I.Stream that we are wrapping
Property IOStream As %IO.I.Stream;

Property AtEnd As %Boolean;

Method %OnNew(initvalue As %String) As %Status [ Private ]
{
	Set:$IsObject($G(initvalue)) ..IOStream=initvalue, ..Attributes("Name")=initvalue.Name, i%LineTerminator=..LineTerminatorGet()
	Quit $$$OK
}

Method AtEndGet() As %Boolean [ CodeMode = expression ]
{
..IOStream.AtEnd
}

Property Size As %Integer [ Calculated ];

Method SizeGet() As %Integer [ CodeMode = expression ]
{
$S(..IOStream.%Extends("%IO.IParts.SeekableIO"):..IOStream.Size,1:-1)
}

Property LastModified As %TimeStamp [ Calculated, ReadOnly ];

Method LastModifiedGet() As %TimeStamp [ CodeMode = expression ]
{
$S(..IOStream.%Extends("%IO.FileStream"):..IOStream.LastModified,1:"")
}

Property LineTerminator As %String(MAXLEN = 10);

Method LineTerminatorGet() As %String [ CodeMode = expression ]
{
$S(..IOStream.%Extends("%IO.IParts.LineIO"):..IOStream.LineTerminator,1:"")
}

Method LineTerminatorSet(terminator As %String) As %Status
{
	Set:..IOStream.%Extends("%IO.IParts.LineIO") ..IOStream.LineTerminator=terminator
	Set i%LineTerminator=terminator
	Quit $$$OK
}

Method Rewind() As %Status
{
	Quit:'..IOStream.%Extends("%IO.IParts.SeekableIO") $$$OK
	Do ..IOStream.Rewind(.tSC)
	Quit tSC
}

Method Flush() As %Status
{
	Do ..IOStream.Flush(.tSC)
	Quit tSC
}

Method Read(ByRef len As %Integer = 32000, ByRef sc As %Status) As %RawString
{
	Set tData=..IOStream.Read(len,,.sc)
	Set len=$S(""=tData:0-..IOStream.AtEnd,1:$L(tData))
	Quit tData
}

Method ReadLine(ByRef len As %Integer = 32000, ByRef sc As %Status, ByRef eol As %Boolean) As %RawString
{
	If '..IOStream.%Extends("%IO.IParts.LineIO") { 	Set len=-1,sc=$$$OK,eol=0  Quit "" }
	Set term=..IOStream.LineTerminator
	Set tData=..IOStream.ReadLine(len,,.sc,.term)
	Set eol=(""'=term)
	Set len=$S(tData_term="":0-..IOStream.AtEnd,1:$L(tData))
	Quit tData
}

Method ReadLineIntoStream(ByRef sc As %Status) As %Library.AbstractStream
{
	If '..IOStream.%Extends("%IO.IParts.LineIO") { 	Set len=-1,sc=$$$OK,eol=0  Quit $$$NULLOREF }
	Set stream=##class(%Library.GlobalCharacterStream).%New()
	Do {
		Set tData=..ReadLine(,.sc,.eol)
		Set sc1=stream.Write(tData)  Set:$$$ISOK(sc) sc=sc1
	} While $$$ISOK(sc)&&'eol
	Quit stream
}

Method Write(data As %RawString) As %Status
{
	Do ..IOStream.Write(data,,.tSC)
	Quit tSC
}

/// Appends the string <var>data</var> along with a line terminator to the stream and advances the 
/// current stream position by the number of characters in <var>data</var> plus the line terminator.
/// 
/// <p>Returns a <CLASS>%Status</CLASS> value indicating success or failure.
Method WriteLine(data As %RawString = "") As %Status
{
	Do ..IOStream.Write(data_$S(..IOStream.%Extends("%IO.IParts.LineIO"):..IOStream.LineTerminator, 1:$S($$$isWINDOWS:$Char(13,10),1:$Char(10))),,.tSC)
	Quit tSC
}

/// Copy the contents of the given source %IO, %Library or %Stream stream to the wrappered %IO stream
Method CopyFrom(source As %Stream.Object) As %Status
{
	Quit:source=$$$NULLOREF $$$ERR($$$OrefInvalid)

	Do source.Rewind()
	Set (sc,sc1)=$$$OK
	
	If source.%Extends("%IO.I.Stream") {
		While 'source.AtEnd&&$$$ISOK(sc)&&$$$ISOK(sc1) { Set len=32000 Do ..IOStream.Write(source.Read(len,,.sc1),,.sc) }
	} Else {
		While 'source.AtEnd&&$$$ISOK(sc)&&$$$ISOK(sc1) { Set len=32000 Do ..IOStream.Write(source.Read(len,.sc1),,.sc) }
	}
	If $$$ISERR(sc)||$$$ISERR(sc1) Quit $$$ADDSC(sc,sc1)

	#; Now copy the attributes
	If source.%Extends("%Library.AbstractStream") {
		Set name="" For { Set name=source.NextAttribute(name) Quit:name=""  Do ..SetAttribute(name,source.GetAttribute(name)) }
	}
	Set ..IOStream.Name = source.GetAttribute("Name",..IOStream.Name)
	Set:..IOStream.%Extends("%IO.I.ExternalByteStream") ..IOStream.CharEncoding = source.GetAttribute("CharEncoding",..IOStream.CharEncoding)

	Quit $$$OK
}

Method Clear() As %Status
{
	If '$IsObject(..IOStream) Quit $$$ERROR($$$ErrIONoDelegatedStream)
	If '..IOStream.%Extends("%IO.IParts.SeekableIO")  Quit $$$ERROR($$$ErrIODelegatedNotSeekable)
	Do ..IOStream.Clear(.tSC)
	Quit tSC
}

Method MoveToEnd() As %Status
{
	If '$IsObject(..IOStream) Quit $$$ERROR($$$ErrIONoDelegatedStream)
	If '..IOStream.%Extends("%IO.IParts.SeekableIO")  Quit $$$ERROR($$$ErrIODelegatedNotSeekable)
	Do ..IOStream.Seek(..IOStream.Size,.tSC)
	Quit tSC
}

Method MoveTo(position As %Integer) As %Boolean
{
	Quit:'..IOStream.%Extends("%IO.IParts.SeekableIO") 0
	Quit ..IOStream.Seek(position)
}

/// Find the first occurrence of <var>target</var> in the stream starting the
/// search at <var>position</var>. It returns the position at this match starting
/// at the beginning of the stream. If it does not find the target string then
/// return -1. If <var>position</var>=-1 then start searching from the current
/// location and just return the offset from the last search, useful for searching
/// through the entire file. If you are doing this you should pass in <var>tmpstr</var>
/// by reference in every call which is used as a temporary location to store information
/// being read so the next call will start where the last one left off.
Method FindAt(position As %Integer, target As %RawString, ByRef tmpstr As %RawString) As %Integer
{
	Set find=0,targetlen=$length(target)
	If position=-1 {
		Set position=1
		If '$data(tmpstr) Set tmpstr=""
		Set find=$find(tmpstr,target)
		If find {
			Set tmpstr=$extract(tmpstr,find,*)
			Quit position+find-targetlen-1
		} Else {
			Set tmp=$length(tmpstr)-targetlen
			Set position=position+$select(tmp>0:tmp+1,1:0)
		}
	} Else {
		If '..MoveTo(position) Quit -1
		Set tmpstr=""
	}
	
	While '..AtEnd {
		Set tmp=..Read(20000,.sc),tmpstr=$extract(tmpstr,$length(tmpstr)-targetlen+2,*)_tmp
		If 'sc Quit
		Set find=$find(tmpstr,target)
		If find Set tmpstr=$extract(tmpstr,find,*) Quit
		Set position=position+$length(tmpstr)-targetlen+1
	}
	If find Quit position+find-targetlen-1
	Quit -1
}

/// Write out <var>len</var> characters of the stream to the current device starting from the current position. This
/// method is optimised for performance by the various sub classes. If <var>len</var> is omitted or set to -1 then
/// it will write out the entire stream starting at the beginning.
Method OutputToDevice(ByRef len As %Integer = -1) As %Status
{
	Set $ZTrap="OutputError"
	If len=0 Quit $$$OK
	If len=-1 {
		Do ..Rewind()
		Set tSC=$$$OK
		For  Quit:(..AtEnd||$$$ISERR(tSC))  Write ..Read(32000,.tSC)
		Do ..Rewind()
	} Else {
		Set total=0,tSC=$$$OK
		For  Quit:(..AtEnd||$$$ISERR(tSC))  Set chunk=$S(len-total>32000:32000,1:len-total) Write ..Read(.chunk,.tSC) Set total=total+chunk Quit:total=len
	}
	Quit tSC
OutputError	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Input <var>len</var> characters from the current device into the stream. This is equivalent to doing a series of
/// reads and calling <METHOD>Write</METHOD> for each of them but it may be optimised by the subclasses. On return
/// <var>len</var> will be the number of characters still to read in (if no timeout has occured this should be 0).
Method InputFromDevice(ByRef len As %Integer = 0, timeout As %Integer = 20) As %Status
{
	Set $Ztrap="InputError"
	If len=0 Do ..Write("") Quit $$$OK
	For  Read data#$S(len>32000:32000,1:len):timeout Quit:'$Test  Do ..Write(data) Set len=len-$L(data) Quit:len=0
	If len=0 Quit $$$OK
	Quit $$$ERROR($$$FileDoesNotExist)
InputError	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Output the stream to the current device starting at <var>position</var> of length
/// <var>length</var>. The length if passed by reference returns the number of characters
/// output.
Method OutputToDeviceAt(position As %Integer, ByRef length As %Integer) As %Status
{
	If '(..MoveTo(position)) Set length=0 Quit $$$ERROR($$$StreamMoveToError,position)
	Quit ..OutputToDevice(.length)
}

Method CopyFromAndSave(source As %Stream.Object) As %Status
{
	Quit $$$ERROR($$$NotImplemented,"%IO.LibraryStream::CopyFromAndSave")
}

}
