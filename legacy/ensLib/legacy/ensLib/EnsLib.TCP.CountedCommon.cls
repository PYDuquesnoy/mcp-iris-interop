/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, Ensemble)

/// TCP read & write helper classmethods
Class EnsLib.TCP.CountedCommon [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Character encoding scheme used for decoding incoming data and encoding outgoing data. For no encoding, use 'Binary'.
/// Other choices include: <br/>
///  Native - the default character encoding of the installed locale of the InterSystems IRIS server <br/>
///  latin1 - the ISO Latin1 8-bit encoding <br/>
///  ISO-8859-1 - the ISO Latin1 8-bit encoding <br/>
///  UTF-8 - the Unicode 8-bit encoding <br/>
///  Unicode - the Unicode 16-bit encoding  (Little-Endian) <br/>
///  UnicodeBig - the Unicode 16-bit encoding (Big-Endian) <br/>
///  @&lt;ttable&gt; - &lt;ttable&gt; means a raw InterSystems character translation table name. A prefix of '@' means to use the named table.
Property Charset As %String [ InitialExpression = "UTF-8" ];

/// Byte order of the block count prefix. Big endian means 4-byte MSB goes over the wire first; Little Endian means 4-byte LSB goes over the wire first. 
/// JavaUTF means 2-byte MSB goes over the wire first.
Property Endian As %String(VALUELIST = ",Big,Little,JavaUTF") [ InitialExpression = "Big" ];

/// Should the adapter construct a FileStream or a GlobalStream for data received?
Property UseFileStream As %Boolean;

Parameter SETTINGS = "Charset:Connection:selector?context={Ens.ContextSearch/CharacterSets},Endian:Connection";

/// Override the Device Mode that will be used to open the TCP socket
Parameter Mode As %String = "SW";

/// Write the stream contents as a counted block on the TCP socket
/// (logs errors except for <WRITE> error.)
Method WriteCountedStream(pStream As %Stream.Object, pCharset As %String = "", pInbound As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, $ZT="Trap"
	Do {
		Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
		Do SetIO^%NLS("RAW")

		If "RAW"=tTable {
			Set tLen=pStream.Size
			Set tLenStr=$Case(..Endian,"JavaUTF":$Reverse($ZWChar(tLen)),"Little":$ZLChar(tLen), :$Reverse($ZLChar(tLen)))
			Write tLenStr
			Set tSC = pStream.OutputToDevice()  Quit:$$$ISERR(tSC)
		} Else {
			#; Use 8k chunks to allow up to 4x expansion in $ZCVT
			Set tLen=0,tLeft=pStream.Size, tMaxChunk=$$$GetClassParameter("%Library.FileCharacterStream","MAXLOCALSIZE") \ 4
			For iChunk=1:1 {
				Set tChunkSize = $S(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				Set ^||EnsWCSChunk(iChunk) = $ZCVT(pStream.Read(tChunkSize),"O",tTable), tLen=tLen+$L(^||EnsWCSChunk(iChunk))
				Set tLeft = tLeft-tChunkSize  Quit:tLeft'>0
			}
			$$$catTRACE("protocol","Converted("_pStream.Size_") characters to ("_tLen_") output bytes using charset '"_pCharset_"', table '"_tTable_"'")
			Set tLenStr=$Case(..Endian,"JavaUTF":$Reverse($ZWChar(tLen)),"Little":$ZLChar(tLen), :$Reverse($ZLChar(tLen)))
			Write tLenStr
			For i=1:1:iChunk Write ^||EnsWCSChunk(i)
		}
		Write *-3 // flush buffer
	} While (0)
	If $$$ISOK(tSC)&&$$$DoTrace {
		Do pStream.Rewind()
		$$$catTRACE("protocol","Wrote output stream  data block(size="_tLen_") to "_..IOAddr_": "_$S("RAW"=tTable:pStream.Read(1000),1:$E(^||EnsWCSChunk(1),1,1000)))
	}
Exit
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

/// Write the stream contents as a counted block on the TCP socket
/// (logs errors except for <WRITE> error.)
Method WriteCountedString(pString As %String, pCharset As %String = "", pInbound As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, $ZT="Trap"
	Do {
		Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
		Do SetIO^%NLS("RAW")

		Set tLen=$L(pString)
		If "RAW"=tTable {
			Set tLenStr=$Case(..Endian,"JavaUTF":$Reverse($ZWChar(tLen)),"Little":$ZLChar(tLen), :$Reverse($ZLChar(tLen)))
			Write tLenStr,pString
		} Else {
			#; Use 8k chunks to allow up to 4x expansion in $ZCVT
			Set tLeft=tLen, tLen=0, tMaxChunk=$$$GetClassParameter("%Library.FileCharacterStream","MAXLOCALSIZE") \ 4
			For iChunk=1:1 {
				Set tChunkSize = $S(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				Set tmp(iChunk) = $ZCVT($E(pString,1,tChunkSize),"O",tTable), tLen=tLen+$L(tmp(iChunk)), $E(pString,1,tChunkSize)=""
				Set tLeft = tLeft-tChunkSize  Quit:tLeft<=0
			}
			$$$catTRACE("protocol","Converted("_tLen_") characters to ("_tLen_") output string bytes using charset '"_pCharset_"', table '"_tTable_"'")
			Set tLenStr=$Case(..Endian,"JavaUTF":$Reverse($ZWChar(tLen)),"Little":$ZLChar(tLen), :$Reverse($ZLChar(tLen)))
			Write tLenStr  For i=1:1:iChunk Write tmp(i)
		}
		Write *-3 // flush buffer
	} While (0)
	If $$$ISOK(tSC) {
		$$$catTRACE("protocol","Wrote output string data block(size="_tLen_") to "_..IOAddr_": "_$E($S("RAW"=tTable:pString,1:tmp(1)),1,1000))
	}
Exit
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	If ..IsWriteError(tSC) {
		Set tSC=$$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),$S('$D(tLenStr):"BlockCount Write",1:"Counted Write"), ..IOAddr, $$$StatusDisplayString(tSC))
		Set:'pInbound ..BusinessHost.Retry=1
		Do ..Disconnect()
	}
	Goto Exit
}

/// Read a counted block from the TCP socket into the Stream using a Charset for translation.
/// (logs errors except for <READ> errors after the initial blocksize read.)
Method ReadCountedStream(ByRef pStream As %CharacterStream = "", pCharset As %String = "", pStartTimeout As %Numeric = -1, pChunkTimeout As %Numeric = 60, pInbound As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, $ZT="TrapRS"
	Do {
		If 'pInbound $$$catTRACE("protocol","Waiting to read stream counted data block("_$Case(..Endian,"JavaUTF":2,:4)_") from "_..IOAddr_" using charset '"_pCharset_"' with timeout="_pStartTimeout)

		Do SetIO^%NLS("RAW")  ; Switch to RAW input mode
		If ..Endian="JavaUTF" {
			If -1=pStartTimeout { Read tLenStr#2  Set tTimedOut = 0 }
			Else { Read tLenStr#2:pStartTimeout  Set tTimedOut = '$Test }
		} Else {
			If -1=pStartTimeout { Read tLenStr#4  Set tTimedOut = 0 }
			Else { Read tLenStr#4:pStartTimeout  Set tTimedOut = '$Test }
		}
		Set $ZT="Trap"
		If tTimedOut { Set tSC = $$$ERROR($$$EnsErrTCPReadBlockSizeTimeoutExpired,pStartTimeout,$Case(..Endian,"JavaUTF":2,:4)) Quit }
		
		#; Convert count bytes to integer
		Set tLen = $Case(..Endian,"JavaUTF":$ZWAscii($Reverse(tLenStr)),"Little":$ZLAscii(tLenStr), :$ZLAscii($Reverse(tLenStr)))
		
		If '$IsObject(pStream)&&(pInbound||tLen) {
			If ""'=pStream {
			 	Set pStream=$classmethod(pStream,"%New")  
			} Else {
				If "binary"=$ZCVT(pCharset,"L") {
					If ..UseFileStream {
						Set pStream=##class(%FileBinaryStream).%New()
					} Else {
						Set pStream=##class(%GlobalBinaryStream).%New()
					}
				} Else {
					If ..UseFileStream {
						Set pStream=##class(%FileCharacterStream).%New()
						Set pStream.TranslateTable="UnicodeLittle", pStream.BOM=""
					} Else {
						Set pStream=##class(%GlobalCharacterStream).%New()
					}
				}
			}
			$$$ASSERT($IsObject(pStream))
		}
		If 'tLen {
			If $$$ISOK(tSC) { $$$catTRACE("protocol","Got stream inbound data block (size=0) from "_..IOAddr_", Status OK") }
			Quit
		}
		Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
		If "RAW"=tTable {
			$$$catTRACE("protocol","Got block count="_tLen_", waiting to read (raw) stream with timeout="_pChunkTimeout)
			Set tSC = pStream.InputFromDevice(.tLen,pChunkTimeout)
			If $$$ISERR(tSC) {
				If $$$StatusEquals(tSC,$$$FileDoesNotExist) Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,pChunkTimeout,tLen,pCharset)
				Quit	
			}
		} Else {
			Set tLeft = tLen, tMaxChunk=$$$GetClassParameter("%Library.FileCharacterStream","MAXLOCALSIZE")
			$$$catTRACE("protocol","Got stream block count="_tLen_", waiting to read in "_tMaxChunk_"-byte chunks using charset '"_pCharset_"' with chunk timeout="_pChunkTimeout)
			Set tStream = ##Class(%FileCharacterStream).%New()  $$$ASSERT($IsObject(tStream))
			Set tStream.TranslateTable = "RAW" ; Avoid data translation for temp writes.
			Set tStream.StreamFormatWrite = 0 ; Ensure writes to the stream don't convert $c(13,10) to $c(10).
			While tLeft>0 {
				Set tChunkSize = $select(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				Set tStartTime=$zh
				Read data#tChunkSize:pChunkTimeout  If '$Test {
					If $zh-tStartTime < pChunkTimeout { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,pChunkTimeout,tChunkSize,"("_$L(data)_"):"_data)  Quit }
					Else { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,pChunkTimeout,tChunkSize,pCharset)  Quit }
				}
				$$$catTRACE("protocol","Got stream data chunk, size="_$L(data)_"/"_tChunkSize)
				Set tLeft = tLeft-$L(data)
				Do tStream.Write(data)  ; Save out to the stream from the data we read in from the socket
			}
			Set tStream.TranslateTable = tTable
			Set tSC = pStream.CopyFrom(tStream)  Quit:$$$ISERR(tSC)
			$$$catTRACE("protocol","Converted("_tLen_") input stream bytes to ("_pStream.Size_") characters using charset '"_pCharset_"', table '"_tTable_"'")
		}
		$$$catTRACE("protocol","Got inbound stream data (size="_pStream.Size_") from "_..IOAddr_" : "_pStream.Read(1000))  Do pStream.Rewind()
	} While (0)
Exit
	Quit tSC
TrapRS
	Set $ZT="", tSC=$$$SystemErrorType("Block Count")
	Goto Exit
Trap
	Set $ZT="", tSC=$$$SystemError
	Goto Exit
}

/// Read a counted block from the TCP socket into the Stream using a Charset for translation.
/// (logs errors except for <READ> errors after the initial blocksize read.)
Method ReadCountedString(ByRef pString As %String, pCharset As %String = "", pStartTimeout As %Numeric = -1, pChunkTimeout As %Numeric = 60, pInbound As %Boolean = 0) As %Status
{
	Set tSC=$$$OK, pString="", $ZT="Trap"
	Do {
		If 'pInbound $$$catTRACE("protocol","Waiting to read string counted data block from "_..IOAddr_" using charset '"_pCharset_"' with timeout="_pStartTimeout)

		Do SetIO^%NLS("RAW")  ; Switch to RAW input mode
		If -1=pStartTimeout { Read tLenStr#4  Set tTimedOut = 0 }
		Else { Read tLenStr#4:pStartTimeout  Set tTimedOut = '$Test }
		If tTimedOut { Set tSC = $$$ERROR($$$EnsErrTCPReadBlockSizeTimeoutExpired,pStartTimeout,4) Quit }
		
		#; Convert to integer
		Set tLen = $Case(..Endian,"Little":$ZLAscii(tLenStr), :$Ascii(tLenStr)*256+$Ascii(tLenStr,2)*256+$Ascii(tLenStr,3)*256+$Ascii(tLenStr,4))
		If 'tLen {
			If $$$ISOK(tSC) { $$$catTRACE("protocol","Got inbound string data block (size=0) from "_..IOAddr_", Status OK") }
			Quit
		}
		Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
		If "RAW"=tTable {
			$$$catTRACE("protocol","Got block count="_tLen_", waiting to read (raw) string with timeout="_pChunkTimeout)
			If -1=pChunkTimeout { Read pString#tLen  Set tTimedOut = 0 }
			Else {
				Read pString#tLen:pChunkTimeout  Set tTimedOut = '$Test 
				If tTimedOut {
					#; read timed out duration may be slightly less than requested timeout period so check $ZA for timeout condition
					If ($ZA\2#2) { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,pChunkTimeout,tLen,pCharset)}
					Else { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,pChunkTimeout,tLen,"("_$L(pString)_"):"_pString)}
					Quit
				}
			}
		} Else {
			Set tLeft = tLen, tMaxChunk=$$$GetClassParameter("%Library.FileCharacterStream","MAXLOCALSIZE")
			$$$catTRACE("protocol","Got string block count="_tLen_", waiting to read in "_tMaxChunk_"-byte chunks using charset '"_pCharset_"' with chunk timeout="_pChunkTimeout)
			While tLeft>0 {
				Set tChunkSize = $select(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				If -1=pChunkTimeout { Read data#tChunkSize  Set tTimedOut = 0 }
				Else {
					Set tStartTime=$zh
					Read data#tChunkSize:pChunkTimeout  Set tTimedOut='$Test
					If tTimedOut {
						If ($zh-tStartTime) < pChunkTimeout { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,pChunkTimeout,tChunkSize,"("_$L(data)_"):"_data) }
						Else { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,pChunkTimeout,tChunkSize,pCharset) }
						Quit
					}
				}
				$$$catTRACE("protocol","Got string data chunk, size="_$L(data)_"/"_tChunkSize)
				Set tLeft = tLeft-$L(data)
				Set pString=pString_$ZCVT(data,"I",tTable)
			}
			$$$catTRACE("protocol","Converted("_tLen_") input string bytes to ("_$L(pString)_") characters using charset '"_pCharset_"', table '"_tTable_"'")
		}
		$$$catTRACE("protocol","Got inbound string data (size="_$L(pString)_") from "_..IOAddr_" : "_$E(pString,1,1000))
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	If ..IsReadError(tSC) {
		Set tSC=$$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),$S('$D(tLenStr):"BlockCount Read",1:"Counted Read"), ..IOAddr, $$$StatusDisplayString(tSC))
		Set:'pInbound ..BusinessHost.Retry=1
		Do ..Disconnect()
	}
	Goto Exit
}

}
