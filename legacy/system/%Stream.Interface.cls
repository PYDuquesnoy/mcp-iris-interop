/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Stream.Interface Extends %RegisteredObject [ System = 3 ]
{

ClassMethod ReadStream(handle As %Stream.Object, length As %Integer, ByRef msg As %String) As %Integer
{
	If handle.IsCharacter() {
		Set x=$zu(96,18,2,"UTF8") 
		Set rc=..OutputToDevice(handle,length) 
		Set x=$zu(96,18,2,"RAW") 
 	} Else {
		Set rc=..OutputToDevice(handle,length)
 	}
 	Quit:rc 0
 	Set msg=..GetError(rc)
 	Quit 412
}

ClassMethod ReadStreamAt(handle As %Stream.Object, position As %Integer, length As %Integer, ByRef msg As %String) As %Integer
{
 	Do handle.MoveTo(position)
 	Quit ..ReadStream(handle,length,.msg)
}

ClassMethod WriteStream(handle As %Stream.Object, length As %Integer, ByRef msg As %String) As %Integer
{
 	If handle.IsCharacter() {
		Set x=$zu(96,18,2,"UTF8") 
		Set rc=..InputFromDevice(handle,.length) 
		Set x=$zu(96,18,2,"RAW") 
 	} Else {
 		Set rc=..InputFromDevice(handle,.length)
 	}
 	Quit:rc 0
 	Set msg=..GetError(rc)
 	Quit 412
}

ClassMethod OutputToDevice(handle As %Stream.Object, len As %Integer = -1) As %Status [ Private ]
{
	Set $ZTrap="Error",sc=$$$OK
	If len=0 Quit $$$OK
	If len=-1 {
		Set sc=handle.Rewind() If $$$ISERR(sc) Quit sc
		For  Quit:handle.AtEnd  Set rc=$zobjexport(handle.Read(,.sc),5) If $$$ISERR(sc) Quit
		If $$$ISOK(sc) Set sc=handle.Rewind()
	} Else {
		Set total=0
		For  Quit:handle.AtEnd  Set chunk=$select(len-total>32000:32000,1:len-total) Set rc=$zobjexport(handle.Read(chunk,.sc),5),total=total+chunk Quit:total=len||($$$ISERR(sc))
	}
	Quit sc
Error	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod InputFromDevice(handle As %Stream.Object, ByRef len As %Integer = 0) As %Status
{
	Set $Ztrap="Error",sc=$$$OK
	If len=0 Quit handle.Write("")
	For  Set data=$zobjexport($select(len>32000:32000,1:len),13) Set sc=handle.Write(data),len=len-$length(data) Quit:len=0||($$$ISERR(sc))
	If len'=0 Set sc=$select($$$ISOK(sc):$$$ERROR($$$FileDoesNotExist),1:sc)
	Quit sc
Error	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod AppendFromDevice(ByRef handle As %Stream.Object, len As %Integer, ByRef written As %Integer) As %Status
{
	Set $Ztrap="Error",sc=$$$OK
	Set written=0
	For  Set data=$zobjexport($select(len>32000:32000,1:len),13) Set sc=handle.Write(data) Set len=len-$length(data),written=written+$length(data) Quit:len=0||($$$ISERR(sc))
	If len'=0 Set sc=$select($$$ISOK(sc):$$$ERROR($$$FileDoesNotExist),1:sc)
	Quit sc
Error  Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

ClassMethod CopyFrom(source As %Stream.Object, ByRef target As %Stream.Object, offset As %Integer, length As %Integer) As %Status
{
	Quit:source=$$$NULLOREF $$$ERR($$$OrefInvalid)	
	Set sc=$$$OK
	If offset>source.Size {
		Quit $$$OK
	}
	If source.IsCharacter() {
		Set target=##class(%GlobalCharacterStream).%New()
	} Else {
		Set target=##class(%GlobalBinaryStream).%New()
	}
	If length>source.Size {
		Set length=source.Size
	}
	Do source.MoveTo(offset)
	While (length>0) {
		Quit:(source.AtEnd)
		If (length>32000) { Set len=32000,length=length-32000 } Else { Set len=length,length=0 }
		Set data=source.Read(len,.sc) If $$$ISERR(sc) Quit
		Set sc=target.Write(data) If $$$ISERR(sc) Quit
	}	
	Quit sc
}

ClassMethod Truncate(source As %Stream.Object, length As %Integer) As %Status
{
	Quit:source=$$$NULLOREF $$$ERR($$$OrefInvalid)	
	Set sc=$$$OK
	Quit:length>source.Size 0
	If source.IsCharacter() {
		Set temp=##class(%GlobalCharacterStream).%New()
	} Else {
		Set temp=##class(%GlobalBinaryStream).%New()
	}
	Do source.Rewind()
	While (length>0) {
		Quit:(source.AtEnd)
		If (length>32000) { Set len=32000,length=length-32000 } Else { Set len=length,length=0 }
		Set data=source.Read(len,.sc) If $$$ISERR(sc) Quit
		Set sc=temp.Write(data) If $$$ISERR(sc) Quit
	}
	Goto:$$$ISERR(sc) Error
	Set sc=source.CopyFrom(temp)
	Goto:$$$ISERR(sc) Error
	Do source.Rewind()
	Set sc=source.%Save() If $$$ISERR(sc) Goto Error
	Quit 0
Error
 	Set msg=..GetError(sc)
 	Quit 412
}

ClassMethod SetBytesAt(ByRef source As %Stream.Object, offset As %Integer, length As %Integer, ByRef written As %Integer) As %Status
{
	Set rc=..CopyFrom(source,.target,0,offset)
	Goto:$$$ISERR(rc) Error
	Set rc=..AppendFromDevice(.target,length,.written)
	Goto:$$$ISERR(rc) Error
	If written<source.Size {
		Set offset=offset+written+1
		Do source.MoveTo(offset)
	}
	Set sc=$$$OK
	For  Quit:(source.AtEnd)||($$$ISERR(rc))  Set len=32000,rc=target.Write(source.Read(len,.sc)) If $$$ISERR(sc) Set rc=sc Quit
	If $$$ISERR(rc) Goto Error
	Set rc=source.CopyFrom(target)
	Goto:$$$ISERR(rc) Error
	Set rc=source.%Save() If $$$ISERR(rc) Goto Error
	Set rc=source.Rewind() If $$$ISERR(rc) Goto Error
	Quit 0
Error
 	Set msg=..GetError(rc)
	Quit 412
}

ClassMethod GetError(rc As %Status) As %String [ Private ]
{
	Set msg=$$DecomposeStatus^%apiOBJ(rc,.msg) 
 	Set:msg msg=msg(1)
 	Quit msg
}

ClassMethod CopyFromFileStream(source As %Stream.FileBinary, dest As %Stream.Object)
{
	do source.%Save()
	set filename = source.Filename
	set source = ##class(%Stream.FileCharacter).%New()
	do source.LinkToFile(filename)
	do dest.CopyFrom(source)
	do source.Clear()
}

}
