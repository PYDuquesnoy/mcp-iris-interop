/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class provides the ability to index and search a character stream from SQL.
/// Specify this class as the type class for a stream property and supply values for
/// the <PARAMETER>LANGUAGECLASS</PARAMETER> and (optionally) <PARAMETER>SIMILARITYINDEX</PARAMETER>
/// parameters.
/// 
Class %Stream.GlobalCharacterSearchable Extends %Stream.GlobalCharacter [ MemberSuper = %Library.TextStreamInterface, System = 4 ]
{

Property container As %ObjectHandle [ Transient ];

Property containerProperty As %RawString [ Transient ];

Method ReadPassage(ByRef len As %Integer = 24576, ByRef sc As %Status) As %RawString
{
	Set sc=$$$OK
	#; Read the next chunk of length len or less.  This may cause one or more buffers to be read.
	Set atEnd = i%AtEnd
	Set chunk = ..ReadLine(.len,.sc,.eol)
	Set bufferPos = i%Position
	Quit:i%AtEnd=1 chunk
	
	#; Find a word delimiter near the end of the chunk
	Set maxWordLen = 256  // Intention: $$$MaxSubscriptLen
	Set windowStart = len-(maxWordLen*2) 
	Quit:windowStart<1 chunk
	For i=len:-1:windowStart quit:$e(chunk,i)?.(1P,1C)
	Set:i<windowStart i=$s(len-maxWordLen>(len\2):len-maxWordLen,1:len\2)
	Set:i<len i%AtEnd=0
	Set i%Position=bufferPos-len+i
	Quit $e(chunk,1,i)
}

Method BuildValueArray(ByRef subvalue As %String) As %Status [ Private ]
{
	if ($Isobject(i%container)) && (i%containerProperty '= "" ) && ($Data(@(i%%Location)@(i%Id))) {
		try {
			do $method(i%container,i%containerProperty_"BuildValueArray",..%Oid(),.subvalue)
		} catch {}
	}
	Quit $$$OK
}

ClassMethod %SVAExists(pStream As %String(MAXLEN="")) As %Integer [ Internal, ServerOnly = 1 ]
{
	set tStreamType = $$$oidClassName(pStream)
	if tStreamType '= "%Stream.GlobalCharacterSearchable" { quit $classmethod(tStreamType,"ValueArrayExists",.pStream) }
	set tStreamId = $$$oidPrimary(pStream), tStreamLocation = $$$oidSysAd1(pStream)
	if pStream = "" { quit 0 }
	quit $Select($Data(^||%isc.strv(pStream)):1,1:0)
}

ClassMethod %GetValueArray(pStream As %String(MAXLEN=""), pContainer As %String(MAXLEN="") = "", pContainerProperty As %String(MAXLEN="") = "", ByRef pValueArray As %String(MAXLEN="")) As %Integer [ Internal, ServerOnly = 1 ]
{
	set tStreamType = $$$oidClassName(pStream)
	if tStreamType '= "%Stream.GlobalCharacterSearchable" { quit $classmethod(tStreamType,"ValueArrayExists",.pStream,.pValueArray) }
	if pStream = "" { quit 0 }
	if $Data(^||%isc.strv(pStream)) { merge pValueArray = ^||%isc.strv(pStream) quit 1 }
	elseif (pContainer '= "") && (pContainerProperty '= "" ) {
		try {
			if $$$ISOK($classmethod(pContainer,pContainerProperty_"BuildValueArray",..%Open(pStream),.tSubValue)) { set tIndex = 1 } else { set tIndex = 0 }
		}
		catch tException { set tIndex = 0 }
	}
	else { set tIndex = 0 }
	quit 0
}

ClassMethod %PutValueArray(pStream As %String(MAXLEN=""), pContainer As %String(MAXLEN="") = "", pContainerProperty As %String(MAXLEN="") = "") As %Integer [ Internal, ServerOnly = 1 ]
{
	set tStreamType = $$$oidClassName(pStream)
	if tStreamType '= "%Stream.GlobalCharacterSearchable" { quit $classmethod(tStreamType,"ValueArrayExists",.pStream,.pValueArray) }
	if pStream = "" { quit 0 }
	if (pContainer '= "") && (pContainerProperty '= "" ) {
		try {
			if $$$ISOK($classmethod(pContainer,pContainerProperty_"BuildValueArray",..%Open(pStream),.tSubValue)) { set tIndex = 1 } else { set tIndex = 0 }
		}
		catch tException { set tIndex = 0 }
	}
	else { set tIndex = 0 }
	if tIndex { merge ^||%isc.strv(pStream) = pValueArray }
	quit tIndex
}

}
