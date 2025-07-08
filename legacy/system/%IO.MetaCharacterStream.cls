/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Provides a %IO seekable stream wrapper for one or more %IO streams, %Library streams or %Stream streams. It can use different streams for input/Read and output/Write, and
/// it can write a copy of input stream data to one or more additional output streams.
Class %IO.MetaCharacterStream Extends (%IO.I.CharacterSeekableStream, %IO.IParts.MetaIO) [ Inheritance = right, System = 2 ]
{

/// Buffer to hold leftover line data when reading GlobalStream line where LineTerminator is a superset string
Property %GlobalLineExtra As %String [ Internal ];

Method %OnNew(pBaseStream As %IO.I.Stream = "") As %Status
{
	Set tSC=##class(%IO.IParts.MetaIO)$this.%OnNew(pBaseStream)  Quit:$$$ISERR(tSC) tSC
	Set:$IsObject(pBaseStream)&&(pBaseStream.%Extends("%IO.IParts.LineIO")||pBaseStream.%Extends("%Stream.Object")) ..LineTerminator=pBaseStream.LineTerminator
	Quit tSC
}

Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status, ByRef pLineTerminator As %String = {..LineTerminator}) As %String
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream),pTimeout=0 Quit
	Set tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	Set s=..StreamIn, tZB=pLineTerminator, pLineTerminator="", tReadEOL = 0
	If s.%Extends("%IO.I.Stream") {
		Set tTable=$S(s.%Extends("%IO.DeviceStream"):$S("RAW"=s.TranslationTable:"x",1:"")
					, s.%Extends("%IO.I.ByteStream"):"x"
					, 1:"")
		Set:"x"=tTable tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.CharEncoding)
		If ""=tTable||("RAW"=tTable) {
			If s.%Extends("%IO.IParts.LineIO") {
				Set pLineTerminator=tZB, tLine = s.ReadLine(pMaxReadLen,.pTimeout,.pSC,.pLineTerminator)
			} Else {
				#; Brute char-by-char read, looking for LineTerminator
				Set tLine=""  Do {
					Set tChar = ..delegateRead(s,1,.pTimeout,.pSC) Quit:""=tChar||$$$ISERR(pSC)
					If tZB[tChar Set pLineTerminator=tChar Quit
					Set tLine=tLine_tChar
					#;!!! Read extra to test for CR/LF if both are in LineTerminator, push back the extra char if not
				} While $L(tLine)<pMaxReadLen
			}
		} Else {
			// Not RAW; get chars and then look for terminators
			#; Brute char-by-char read, looking for LineTerminator
			Set tLine=""  Do {
				Set tChar = ..delegateRead(s,1,.pTimeout,.pSC) Quit:""=tChar||$$$ISERR(pSC)
				If tZB[tChar Set pLineTerminator=tChar Quit
				Set tLine=tLine_tChar
				#;!!! Read extra to test for CR/LF if both are in LineTerminator, push back the extra char if not
			} While $L(tLine)<pMaxReadLen
		}
	}
	ElseIf s.%Extends("%Stream.Object") {
		Set tTable=$S(s.IsCharacter():"RAW"
					, s.%Extends("%Library.AbstractStream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable($G(s.Attributes("CharEncoding")))
					, s.%Extends("%CSP.Stream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.GetAttribute("CharEncoding"))
					, 1:"")
		If ""=tTable||("RAW"=tTable) {
			Set tZBLen=$L(tZB), tZZB="", tAtEnd=s.AtEnd
			Set:tZB'=s.LineTerminator&&'tAtEnd s.LineTerminator=tZB
			Set tLine=..%GlobalLineExtra, pSC=$$$OK  Set:'tAtEnd tLine=tLine_s.ReadLine(pMaxReadLen-$L(..%GlobalLineExtra),.pSC,.tReadEOL)
			Set pTimeout=0
			If 's.%Extends("%Library.GlobalStreamAdaptor")&&'s.%Extends("%Stream.GlobalCharacter")&&'s.%Extends("%Stream.TmpCharacter") { Set:'tAtEnd (pLineTerminator,tZZB)=$ZB }
			Else { Set pLineTerminator=$S(tReadEOL:tZB, 1:"") }
			If $L(pLineTerminator)<tZBLen && (tZBLen>1) && (tLine'=$TR(tLine,tZB)) {
				Set tLine=tLine_tZZB
				Set tStart=tLine  For i=1:1:tZBLen {
					Set p=$F(tStart,$E(tZB,i))
					Set:p tStart=$E(tLine,1,p-2), pLineTerminator=$E(tLine,p-1)
				}
				Set:tZB=$C(13,10)&&($C(13,10)=$E(tLine,$L(tStart)+1,$L(tStart)+2)) pLineTerminator=$C(13,10)
				Set ..%GlobalLineExtra=$E(tLine,$L(tStart)+$L(pLineTerminator)+1,*), tLine=tStart
			} Else { Set ..%GlobalLineExtra="" }
			Set:""=pLineTerminator&&'s.AtEnd&&($L(tLine)<pMaxReadLen) pLineTerminator=$E(tZB)
		} Else {
			// Not RAW; get chars and then look for terminators
			#; Brute char-by-char read, looking for LineTerminator
			Set tLine=""  Do {
				Set tChar = ..delegateRead(s,1,.pTimeout,.pSC) Quit:""=tChar||$$$ISERR(pSC)
				If tZB[tChar Set pLineTerminator=tChar Quit
				Set tLine=tLine_tChar
				#;!!! Read extra to test for CR/LF if both are in LineTerminator, push back the extra char if not
			} While $L(tLine)<pMaxReadLen
		}
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)),pTimeout=0 Quit "" }

	Set tEOL=($$$ISOK(pSC)&&(tReadEOL||($L(tLine)<pMaxReadLen)))
	Set i%%Position=..%Position+$L(tLine)+tEOL
	Quit:$$$ISERR(pSC) tLine
	
	#; copy to the BindCopyInput output streams
	Set k="" for i=0:1 {
		Set k=..StreamsCopyInput.Next(k) Quit:""=k
		Set s=..StreamsCopyInput.GetAt(k)
		Do ..delegateWrite(s,tLine_$S(tEOL:pLineTerminator,1:""))
	}
	Quit tLine
}

Method AtEndGet() As %Boolean [ CodeMode = expression ]
{
$S($IsObject(..StreamIn):..StreamIn.AtEnd&&(""=..%GlobalLineExtra), 1:1)
}

Method BindInput(pInputStream As %IO.I.Stream, Output pSC As %Status)
{
	Set pSC = $$$OK
	Set ..StreamIn = pInputStream
	Set ..%GlobalLineExtra=""
}

ClassMethod delegateRead(s As %RegisteredObject, ByRef pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, Output pSC As %Status) [ Private ]
{
	Set tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	If s.%Extends("%IO.I.Stream") {
		Set tTable=$S(s.%Extends("%IO.DeviceStream"):$S("RAW"=s.TranslationTable:"x",1:"")
					, s.%Extends("%IO.I.ByteStream"):"x"
					, 1:"")
		Set:"x"=tTable tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.CharEncoding)
		If ""=tTable||("RAW"=tTable) {
			Quit s.Read(pMaxReadLen,.pTimeout,.pSC)
		} Else {
			#;!!! Read a byte at a time and convert until we have the right number of characters+1. Push the extra byte back.
			//For  Set tChar = $ZCVT(tBytes,"i",tTable), tLen=tLen+$L(tData), pData=$E(pData,tChunkSize+1,$L(pData))
			Set tBytes = s.Read(pMaxReadLen, .pTimeout,.pSC)
			Set tChars = $ZCVT(tBytes,"i",tTable)
			//w "Got tBytes("_$L(tBytes)_"),tChars("_$L(tChars)_")='"_tChars_"'",!
			Quit tChars
		}
	}
	ElseIf s.%Extends("%Stream.Object") {
		Set tTable=$S(s.IsCharacter():"RAW"
					, s.%Extends("%Library.AbstractStream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable($G(s.Attributes("CharEncoding")))
					, s.%Extends("%CSP.Stream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.GetAttribute("CharEncoding"))
					, 1:"")
		Set pTimeout=0
		If ""=tTable||("RAW"=tTable) {
			Quit s.Read(pMaxReadLen,.pSC)
		} Else {
			#;!!! Read a byte at a time and convert until we have the right number of characters+1. Push the extra byte back.
			//For  Set tChar = $ZCVT(tBytes,"i",tTable), tLen=tLen+$L(tData), pData=$E(pData,tChunkSize+1,$L(pData))
			Set tBytes=s.Read(pMaxReadLen,.pSC)
			Set tChars = $ZCVT(tBytes,"i",tTable)
			Quit tChars
		}
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) Quit "" }
}

Method delegateWrite(s As %RegisteredObject, pData As %String, ByRef pFlush As %Boolean, Output pSC As %Status) [ Private ]
{
	If s.%Extends("%IO.I.Stream") {
		Set tTable=$S(s.%Extends("%IO.DeviceStream"):$S("RAW"=s.TranslationTable:"x",1:"")
					, s.%Extends("%IO.I.ByteStream"):"x"
					, 1:"")
		Set:"x"=tTable tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.CharEncoding)
		If ""=tTable||("RAW"=tTable) {
			Do s.Write(pData,.pFlush, .pSC)
		} Else {
			#; Convert to bytes, write bytes
			#; Use 8k chunks to allow up to 4x expansion in $ZCVT
			Set tLen=0,tLeft=$L(pData), tMaxChunk=($$$MaxLocalLength \ 4)
			For iChunk=1:1 {
				Set tChunkSize = $select(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				Set tBytes = $ZCVT($E(pData,1,tChunkSize),"o",tTable), tLen=tLen+$L(pData), pData=$E(pData,tChunkSize+1,$L(pData))
				Do s.Write(tBytes,0,.pSC)  Quit:$$$ISERR(pSC)
				Set tLeft = tLeft-tChunkSize  Quit:tLeft'>0
			}
			Do:$G(pFlush,s.DefaultFlushOnWrite) s.Flush()
		}
	}
	ElseIf s.%Extends("%Stream.Object") {
		If ..CharEncoding'="" {
			// CharEncoding is used by EnsLib.EDI,XML.Document to force translatation of output
			// CharEncoding could be used for this purpose from other parts of Ensemble
			Set tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(..CharEncoding)
		} Else {
			// Left as previous for compatibility.  I'm not sure if this is used anywhere.
			Set tTable=$S(s.IsCharacter():"RAW"
						, s.%Extends("%Library.AbstractStream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable($G(s.Attributes("CharEncoding")))
						, s.%Extends("%CSP.Stream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.GetAttribute("CharEncoding"))
						, 1:"")
		}
		If ""=tTable||("RAW"=tTable) {
			Set pSC=s.Write(pData) Quit:$$$ISERR(pSC)  Do:$G(pFlush,0) s.Flush()
		} Else {
			#; Use 8k chunks to allow up to 4x expansion in $ZCVT
			Set tLen=0,tLeft=$L(pData), tMaxChunk=($$$MaxLocalLength \ 4)
			For iChunk=1:1 {
				Set tChunkSize = $select(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				Set tBytes = $ZCVT($E(pData,1,tChunkSize),"o",tTable), tLen=tLen+$L(pData), pData=$E(pData,tChunkSize+1,$L(pData))
				Set pSC=s.Write(tBytes) Quit:$$$ISERR(pSC)
				Set tLeft = tLeft-tChunkSize  Quit:tLeft<=0
			}
			Do:$G(pFlush,0) s.Flush()
		}
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) }
}

Method Seek(pPosition As %Integer, Output pSC As %Status) As %Boolean
{
	// Shadow delegated StreamIn position with ..%Position
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0
	Set s=..StreamIn
	If s.%Extends("%IO.I.Stream") {
		If 's.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit 0
		Set tTable=$S(s.%Extends("%IO.DeviceStream"):$S("RAW"=s.TranslationTable:"x",1:"")
					, s.%Extends("%IO.I.ByteStream"):"x"
					, 1:"")
		Set:"x"=tTable tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.CharEncoding)
		If ""=tTable||("RAW"=tTable) {
			Set tOldPos=s.Position
			Set tOK = s.Seek(pPosition,.pSC)
			Set tNewPos=s.Position
		} Else {
			// Read through the file in character mode to get to char pos
			Set tOldPos=..%Position  Do s.Rewind(.pSC) If $$$ISOK(pSC) {
				Set tMaxLen=$$$MaxLocalLength
				Set tLeft=pPosition-1  While tLeft>0 {
					Set tmp=..delegateRead(s,$S(tLeft>tMaxLen:tMaxLen,1:tLeft),,.pSC), tLeft=tLeft-$L(tmp)
					Quit:""=tmp||$$$ISERR(pSC)
				}
			}
			Set tOK=$$$ISOK(pSC)
			Set:tOK (i%%Position,tNewPos)=pPosition
		}
	}
	ElseIf s.%Extends("%Stream.Object") {
		Set ..%GlobalLineExtra=""
		Set tTable=$S(s.IsCharacter():"RAW"
					, s.%Extends("%Library.AbstractStream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable($G(s.Attributes("CharEncoding")))
					, s.%Extends("%CSP.Stream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.GetAttribute("CharEncoding"))
					, 1:"")
		If ""=tTable||("RAW"=tTable) {
			Set tOldPos=..%Position, pSC=s.MoveTo(pPosition), tOK=$$$ISOK(pSC)
			Set:tOK (i%%Position,tNewPos)=pPosition
		} Else {
			// Read through the file in character mode to get to char pos
			Set tOldPos=..%Position  Do s.Rewind(.pSC) If $$$ISOK(pSC) {
				Set tMaxLen=$$$MaxLocalLength
				Set tLeft=pPosition-1  While tLeft>0 {
					Set tmp=..delegateRead(s,$S(tLeft>tMaxLen:tMaxLen,1:tLeft),,.pSC), tLeft=tLeft-$L(tmp)
					Quit:""=tmp||$$$ISERR(pSC)
				}
			}
			Set tOK=$$$ISOK(pSC)
			Set:tOK (i%%Position,tNewPos)=pPosition
		}
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) Quit 0 }
	Set:tOK&&(tOldPos'=tNewPos) ..WriteToStreamIn=1 ; Write after Seek() must go to StreamIn
	Quit tOK
}

Method SizeGet() As %Integer
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0 ; set %objlasterror
	Set s=..StreamIn
	If s.%Extends("%IO.I.Stream") {
		If 's.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit 0
		Set tTable=$S(s.%Extends("%IO.DeviceStream"):$S("RAW"=s.TranslationTable:"x",1:"")
					, s.%Extends("%IO.I.ByteStream"):"x"
					, 1:"")
		Set:"x"=tTable tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.CharEncoding)
		If ""=tTable||("RAW"=tTable) {
			Quit s.Size
		} Else {
			// Read the entire file in character mode to get char count
			Set tPos=s.Position
			Do s.Rewind(.pSC) Quit:$$$ISERR(pSC) -1
			Set tSize=0 While 1 {
				Set tmp=..delegateRead(s,,,.pSC),tSize=tSize+$L(tmp)
				Quit:""=tmp||$$$ISERR(pSC)
			}
			Do s.Seek(tPos) ; restore old seek position
			Quit $S($$$ISERR(pSC):-1,1:tSize)
		}
	}
	ElseIf s.%Extends("%Stream.Object") {
		Set tTable=$S(s.IsCharacter():"RAW"
					, s.%Extends("%Library.AbstractStream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable($G(s.Attributes("CharEncoding")))
					, s.%Extends("%CSP.Stream"):##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.GetAttribute("CharEncoding"))
					, 1:"")
		If ""=tTable||("RAW"=tTable) {
			Quit s.Size
		} Else {
			// Read the entire file in character mode to get char count
			Do s.Rewind(.pSC) Quit:$$$ISERR(pSC) -1
			Set tSize=0 While 1 {
				Set tmp=..delegateRead(s,,,.pSC),tSize=tSize+$L(tmp)
				Quit:""=tmp||$$$ISERR(pSC)
			}
			Quit $S($$$ISERR(pSC):-1,1:tSize)
		}
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) Quit 0 }
}

Method PositionGet() As %Integer
{
	#; Report shadow ..%Position value if ..StreamIn.Position is not available or suitable
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0 ; set %objlasterror
	Set s=..StreamIn
	If s.%Extends("%IO.I.Stream") {
		If 's.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit 0
		Set tTable=$S(s.%Extends("%IO.DeviceStream"):$S("RAW"=s.TranslationTable:"x",1:"")
					, s.%Extends("%IO.I.ByteStream"):"x"
					, 1:"")
		Set:"x"=tTable tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(s.CharEncoding)
		If ""=tTable||("RAW"=tTable) {
			Quit s.Position
		} Else {
			Quit ..%Position
		}
	}
	ElseIf s.%Extends("%Stream.Object") {
		Quit ..%Position
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) Quit 0 }
}

Method IsOpenGet() As %Boolean
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0
	Quit $S(..StreamIn.%Extends("%IO.I.Stream"):..StreamIn.IsOpen,..StreamIn.%Extends("%Stream.Object"):1,1:+$$$ERROR($$$ErrIONotStream,..StreamIn))  ; set %objlasterror
}

Method LineTerminatorSet(pTerm As %String) As %Status
{
	If pTerm'=..LineTerminator {
		Set i%LineTerminator=pTerm
		Set:$IsObject(..StreamIn)&&(..StreamIn.%Extends("%IO.IParts.LineIO")||..StreamIn.%Extends("%Stream.Object"))&&(..StreamIn.LineTerminator'=pTerm) ..StreamIn.LineTerminator=pTerm
		#; Set the BindCopyInput output streams
		Set k="" While 1 { Set k=..StreamsCopyInput.Next(k) Quit:""=k
			Set s=..StreamsCopyInput.GetAt(k)
			Set:(s.%Extends("%%IO.IParts.LineIO")||s.%Extends("%Stream.Object"))&&(s.LineTerminator'=pTerm) s.LineTerminator=pTerm
		}
		#; Set the BindOutput output streams
		Set k="" While 1 { Set k=..StreamsOutput.Next(k) Quit:""=k
			Set s=..StreamsOutput.GetAt(k)
			Set:(s.%Extends("%IO.IParts.LineIO")||s.%Extends("%Stream.Object"))&&(s.LineTerminator'=pTerm) s.LineTerminator=pTerm
		}
	}
	Quit $$$OK
}

}
