/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A stream class that uses a String for its storage. The underlying String may be in any supported encoding;
/// Set the CharEncoding property to control the interpretation of the string. Note that on Unicode systems it 
/// is possible to use a string containing wide-character values. In this case the results of any encoding other than 'Native' are undefined.
Class %IO.StringStream Extends %IO.I.CharacterSeekableStream [ System = 2 ]
{

/// Names the character encoding used to encode this character stream in its storage or transport format
/// A value of "Native" in this property means the stream is encoded in the native format for the local installation, with no translation done.
/// Values of "RawBytes" or "Binary" mean that each character is represented by the corresponding byte in the external storage or transport format.
/// (This property is overridden from %IO.IParts.ByteIO but has a different meaning in this character IO context.)
Property CharEncoding As %String(TRUNCATE = 1) [ InitialExpression = "Native" ];

/// cached value of the encoding translation table derived from CharEncoding
Property %TranslationTable As %String(TRUNCATE = 1) [ ReadOnly ];

/// Underlying encoded string data
Property Data As %String(TRUNCATE = 1) [ ReadOnly ];

/// Map of byte positions to character positions
Property charposmap [ MultiDimensional, Private ];

Method CharEncodingSet(pCharEncoding As %String) As %Status
{
	Set i%CharEncoding=$S("binary"=$ZCVT(pCharEncoding,"L"):"RawBytes",1:pCharEncoding)
	Set tOld=..%TranslationTable, i%%TranslationTable=$S("native"=$ZCVT(pCharEncoding,"L"):"", 1:##class(%IO.I.TranslationDevice).GetCharEncodingTable(..CharEncoding))
	If tOld'=..%TranslationTable Kill ..charposmap Set ..charposmap(1)=1
	Quit $$$OK
}

Method %OnNew(initvalue As %String) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set i%Data=$G(initvalue), ..charposmap(1)=1, i%AtEnd=(""=..Data), (i%Position,i%ExternalBytePosition)=1, i%IsOpen=1
	Quit $$$OK
}

Method Write(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	Set pSC=$$$OK
	Quit:""=pData
	Set $ZT="Trap"
	Set tStart=$E(..Data,1,..ExternalBytePosition-1)
	Set tExtData=$S(""=..%TranslationTable:pData, 1:$ZCVT(pData,"O",..%TranslationTable))
	Set i%Data=tStart_tExtData_$E(..Data,..ExternalBytePosition,*)
	Set i%Position=..Position+$L(pData)
	Set i%ExternalBytePosition=..ExternalBytePosition+$L(tExtData)
	Quit:""=..%TranslationTable
	Set ..charposmap(..ExternalBytePosition)=..Position
	Set k=..ExternalBytePosition For  Set k=$O(..charposmap(k),1,pos) Quit:""=k  Set ..charposmap(k)=pos+$L(tExtData) ; slide up any map entries greater than write pos (??)
	Quit
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Quit
}

Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, Output pSC As %Status) As %String
{
	Set pTimeout=0
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Quit:0=pMaxReadLen||..AtEnd ""
	Set $ZT="Trap"	
	Set tData=$E(..Data,..ExternalBytePosition,*)
	Set:""'=..%TranslationTable tData=$ZCVT(tData,"I",..%TranslationTable)
	If pMaxReadLen>=$L(tData) { Set i%AtEnd=1, i%ExternalBytePosition=$L(..Data)+1, i%Position=..Position+$L(tData), ..charposmap(i%ExternalBytePosition)=i%Position  Quit tData }
	Set tData=$E(tData,1,pMaxReadLen)
	If ""=..%TranslationTable Set (i%Position,i%ExternalBytePosition)=..Position+$L(tData) Quit tData
	Do ..Seek(..Position+$L(tData),.pSC)
	Quit tData
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Quit ""
}

Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, Output pSC As %Status, ByRef pLineTerminator As %String = {..LineTerminator}) As %String
{
	Set pSC=$$$OK, pTimeout=0, tLineTerminator=pLineTerminator, pLineTerminator="", tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Quit:0=pMaxReadLen||..AtEnd ""
	Set $ZT="Trap"
	Set tData=$E(..Data,..ExternalBytePosition,*)
	Set:""'=..%TranslationTable tData=$ZCVT(tData,"I",..%TranslationTable)
	Set tFirst=0 For i=1:1:$L(tLineTerminator) {
		Set tEOL(i)=$F(tData,$E(tLineTerminator,i))-1
		Set:tEOL(i)>=0&&(tEOL(i)<=$G(tEOL(tFirst),pMaxReadLen+1)) tFirst=i
	}
	Set tEOL(0)=$L(tData)+1
	Set tZB="", tLen=$S(pMaxReadLen<=(tEOL(tFirst)-1):pMaxReadLen,1:tEOL(tFirst)-1)  Set:pMaxReadLen>tLen tZB=$E(tLineTerminator,tFirst)
	Set:tZB=$C(13)&&($E(tData,tLen+2)=$C(10)) tZB=tZB_$C(10)
	Set tData=$E(tData,1,tLen)
	Set pLineTerminator=tZB

	Do ..Seek(..Position+$L(tData)+$L(tZB),.pSC)
	Quit tData
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Quit ""
}

Method ExternalByteSizeGet() As %Integer [ CodeMode = expression ]
{
$L(..Data)
}

/// Return the current character size of the data stream. 
Method SizeGet() As %Integer
{
	Set $ZT="Trap"
	Quit $Case(..%TranslationTable, "":$L(..Data), "RAW":$L(..Data), :$L($ZCVT(..Data,"I",..%TranslationTable)))
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Quit 0
}

Method ExternalByteSeek(pBytePos As %Integer, Output pSC As %Status) As %Boolean
{
	If $L(..Data)+1<pBytePos||(pBytePos<=0) Set pSC=$$$ERROR($$$ErrIOSeekPastEnd,pBytePos,..Data) Quit 0
	Set pSC=$$$OK
	Quit:pBytePos=..ExternalBytePosition 1
	Set $ZT="Trap"
	Set tOldPos=..ExternalBytePosition, i%ExternalBytePosition=pBytePos
	Set i%Position=$G(..charposmap(pBytePos),$Case(..%TranslationTable,"":pBytePos,"RAW":pBytePos,:$L($ZCVT($E(..Data,1,pBytePos-1)+1,"I",..%TranslationTable))))
	Set i%AtEnd=(pBytePos>=($L(..Data)+1))
	Quit 1
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Quit 0
}

Method Seek(pPosition As %Integer = 1, Output pSC As %Status) As %Boolean
{
	Quit:pPosition<=1||$Case(..%TranslationTable,"":1,"RAW":1,:0) ..ExternalByteSeek(pPosition,.pSC)
	Set (ep,pos)=1  For { Set oep=ep, ep=$O(..charposmap(ep),1,pos)  Quit:""=ep
		Quit:pos=pPosition 
		If pos > pPosition {
			set pos=..charposmap(oep), ep=oep
			Quit
		}
	} Set:""=ep ep=pos ; if no map hit set external byte position ep back to 1
	Set tData=$ZCVT($E(..Data,ep,*),"I",..%TranslationTable)
	If pos+$L(tData)+1<pPosition { Set pSC=$$$ERROR($$$ErrIOSeekPastEnd,pPosition,$ZCVT(..Data,"I",..%TranslationTable))  Quit 0 }
	If tData=""||(pos+$L(tData)+1=pPosition) { Set i%AtEnd=1, i%Position=pos+$L(tData), i%ExternalBytePosition=$L(..Data)+1, ..charposmap(i%ExternalBytePosition)=i%Position  Quit 1 }
	Set tData=$E(tData,1,pPosition-pos)
	For end=$L(..Data)+1-ep:-1:0 {
		Quit:pos+$L($ZCVT($E(..Data,1,end),"I",..%TranslationTable))=pPosition
	}
	If end=0 { Set pSC=$$$ERROR($$$ErrIOSeekPastEnd,pPosition,$ZCVT(..Data,"I",..%TranslationTable))  Quit 0 }
	Set i%Position=pPosition, i%ExternalBytePosition=ep+end, ..charposmap(i%ExternalBytePosition)=i%Position
	Quit 1
}

Method ExternalByteTruncateAt(pBytePos As %Integer, Output pSC As %Status) As %Boolean
{
	If pBytePos>($L(..Data)+1)||(pBytePos<=0) Set pSC=$$$ERROR($$$ErrIOSeekPastEnd,pBytePos,..Data) Quit 0
	Set pSC=$$$OK
	Set i%Data=$E(..Data,1,pBytePos-1)
	Set i%ExternalBytePosition=pBytePos
	Set i%Position=$G(..charposmap(pBytePos),$Case(..%TranslationTable,"":pBytePos,"RAW":pBytePos,:$L($ZCVT($E(..Data,1,pBytePos-1)+1,"I",..%TranslationTable))))
	Set i%AtEnd=1
	Quit 1
}

Method TruncateAt(pPosition As %Integer, Output pSC As %Status) As %Boolean
{
	Quit:pPosition<=1||$Case(..%TranslationTable,"":1,"RAW":1,:0) ..ExternalByteTruncateAt(pPosition,.pSC)
	If '..Seek(pPosition,.pSC)  Quit 0
	Quit ..ExternalByteTruncateAt(i%ExternalBytePosition,.pSC)
}

/// Override so as not to call Close()
Method %OnClose() As %Status [ Internal, Private ]
{
	Quit $$$OK
}

}
