/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Helper class for Framed TCP inbound/outbound
Class EnsLib.TCP.FramedCommon Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// Should the adapter construct a FileStream or a GlobalStream for data received?
Property UseFileStream As %Boolean;

/// Comma separated list of control characters that indicate start of a message.<br>
/// Can be Decimal or Hex if have preceding 'x'
/// For example 11 or x0B
Property MessageFrameStart As %String [ InitialExpression = "11" ];

/// Used to store actual Frame start characters
Property MessageFrameStartAsChars As %String [ Transient ];

/// Comma separated list of control characters that indicate terminators to a message.<br>
/// Can be Decimal or Hex if have preceding 'x'
/// For example 28,13 or x1C,x0D
Property MessageFrameEnd As %String [ InitialExpression = "28,13" ];

/// Used to store actual Frame end characters
Property MessageFrameEndAsChars As %String [ Transient ];

/// Remove Framing characters from data received
Property RemoveFraming As %Boolean [ InitialExpression = 1 ];

/// Discard any data not within expected frame
Property DiscardDataNotwithinFraming As %Boolean [ InitialExpression = 1 ];

/// Write the stream contents as a framed block on the TCP socket
/// (logs errors except for <WRITE> error.)
Method WriteFramedStream(pStream As %Stream.Object, pCharset As %String = "", pInbound As %Boolean = 0, pUseFrameProperties As %Boolean = 1) As %Status
{
	Set tSC=$$$OK
	Try {
		Try {Set tStreamSize=pStream.Size} Catch {Set tStreamSize=0}
		If tStreamSize {
			Do pStream.Rewind()
			If pUseFrameProperties {
				Set tSC = ..Write(..MessageFrameStartAsChars,pInbound)
				Do:tSC ..Socket.Flush(.tSC)
			}
			While tSC,'pStream.AtEnd {
				Set tSC = ..Write(pStream.Read(),pInbound) ;Ensure correct Charencoding
				Do:tSC ..Socket.Flush(.tSC)
				If $$$ISERR(tSC) {
					Quit
				}
			}
			If tSC, pUseFrameProperties {
				Set tSC = ..Write(..MessageFrameEndAsChars,pInbound)
				Do:tSC ..Socket.Flush(.tSC)				
			}
			If $$$ISERR(tSC) {
					Set tIsWriteErr=..IsWriteError(tSC)
					If tIsWriteErr||..IsReadError(tSC) {
						Set tSC=$$$ERROR($$$EnsErrInConnectionLost,$S(tIsWriteErr:"Write",1:"Read"),..IOAddr,$$$StatusDisplayString(tSC))
						Set tQuitErr=0  Do ..Disconnect()
					}
			}
			If $$$ISOK(tSC)&&$$$DoTrace {
				Do pStream.Rewind()
				$$$catTRACE("protocol","Wrote output stream to "_..IOAddr_": "_pStream.Read(1000))
			}
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	If ..IsWriteError(tSC) {
		Set tSC=$$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),"Framed Write", ..IOAddr, $$$StatusDisplayString(tSC))
		Set:'pInbound ..BusinessHost.Retry=1
		Do ..Disconnect()
	}	
	Quit tSC
}

/// Write the stream contents as a framed block on the TCP socket
/// (logs errors except for <WRITE> error.)
Method WriteFramedString(pString As %String, pCharset As %String = "", pInbound As %Boolean = 0) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tTempStream = ##class(%Stream.TmpBinary).%New()
		Do tTempStream.Write(pString), tTempStream.Rewind()
		Set tSC = ..WriteFramedStream(tTempStream, pCharset,pInbound)
	} Catch {
		Set tSC = $$$SystemError
	}
	If ..IsWriteError(tSC) {
		Set tSC=$$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),"Framed Write", ..IOAddr, $$$StatusDisplayString(tSC))
		Set:'pInbound ..BusinessHost.Retry=1
		Do ..Disconnect()
	}
	Quit tSC
}

/// Read a framed block from the TCP socket into the Stream using a Charset for translation.
/// (logs errors except for <READ> errors after the initial blocksize read.)
Method ReadFramedStream(ByRef pStream As %Stream.Object = "", pCharset As %String = "", pStartTimeout As %Numeric = -1, pChunkTimeout As %Numeric = 60, pInbound As %Boolean = 0, Output pProcessMessage As %Integer = 0, Output pDiscardedMessage As %Integer = 0) As %Status
{
#define MapCtlChars(%s)	$TR(%s,$C(1,2,9,10,11,13,28),"12tlsre")
#define MapCtlLine(%s)	($$$MapCtlChars($E(%s,1,1000))_$S($L(%s)>1000:"...",1:""))
#define MapCtlLineZB(%s,%zb)	($$$MapCtlLine(%s)_"+"_$$$MapCtlChars(%zb))

	Set tSC=$$$OK
	Try {
		Set tStartTime = $ZH
		$$$catTRACE("connwait","Beginning read for terminator '"_$A($E(..Terminators))_$S(""=$E(..Terminators,2):"",1:","_$A($E(..Terminators,2)))_"' with timeout "_pStartTimeout_" on "_..IOAddr)

		/* Used to store characters we have read to compare against end framing */
		Set tLastEndChars = ""
		/* Used to store characters we have read to compare against start framking if need to remove */
		Set tStartCharsStillToRemove = ..MessageFrameStartAsChars
		/* Used to identify if data between terminator characters. Set but not used - reserved for future use if needed. */
		Set tHadDataBetweenTerminators = 0
		/* Used to idenitfy first read */
		Set tTimeout = "x"
		/* Store incoming message either correctly or incorrectly framed */
		Set pStream = ""
		/* Used to record if received data withoug correct terminators */
		Set tDataWithoutTerminators = 0
		/* Used to store end terminator read in order to determine if received in correct order for removing */
		Set tEndTermHold = ""
		/* Used to remember data in case removing framing and in middle. */
		Set tDataHold = ""
		/* Record length of end Frame characters*/
		Set tTermLen = $L(..MessageFrameEndAsChars)
		/* We may concatenate 2 reads if separated by one of the end framing characters. Prevent MaxString */
		Set tMaxReadSize = $$$MaxLocalLength\4
		Set:""=..%Table ..%Table=##class(%IO.I.TranslationDevice).GetCharEncodingTable(..Charset)
		If (pCharset=..Charset) {Set tTable=..%Table} Else {Set tTable=##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)}
		Do {
			/* First read CallInterval then set to ReadTimeout */
			Set tTimeout=$S(tTimeout="x":pStartTimeout,1:pChunkTimeout)
			Set tZB=..MessageFrameEndAsChars, tData = ""
			Set tData=..Socket.ReadLine(tMaxReadSize,.tTimeout,.tSC,.tZB)
			If $$$ISERR(tSC) {
				If ..IsReadError(tSC) {
					Set tSC=$$$ERROR($$$EnsErrInConnectionLost,"TCP Read",..IOAddr,$$$StatusDisplayString(tSC))
					Set tQuitErr=0  Do ..Disconnect()
					If ""=tData Set tTxt=$$$StatusText(tSC), tSC=$$$OK  If ..StayConnected<0 { $$$LOGWARNING(tTxt) } ElseIf ..%logConnections { $$$LOGINFO(tTxt) } Else { $$$sysTRACE(tTxt) } ; change error to info if lost connection with no data
				}
				Quit
			} ElseIf tTimeout=pStartTimeout {
				If ""'=tData {
					/* Don't report error if timed out after getting some data */
					Set tQuitErr=0
					$$$catTRACE("protocol","Received data but timed out waiting for correct terminators")
					Set tDataWithoutTerminators = 1
				}
				Quit
			}

			$$$catTRACE("connwait","Got data '"_$$$MapCtlLineZB(tData,tZB)_"'")

			/*
				If ReadLine() read maximum size then $Key = "" and tZB will be the last character in the data
				ReadLine() might have reduced the maximum amount of data to read - as code currently stands it ought not to since it uses $$$MaxLocalLength and we are asking for $$$MaxLocalLength\4
			*/
			If ($Key = "") && ($Extract(tData,*)=tZB) {
				Set tZB = ""
			}

			If (tData_tZB '= "") {
				/* Check we received all the terminators we expected as $ZB only returns 1 */
				Set tZBsaved = tZB ;Save since may clear if we have not received all terminators

				Set tDataToWrite = tData

				If (tZB'="") {
					If (tTermLen>1) {
						/* Need to look at last tTermLen chars of pStream so use tLastEndChars which we clear before each message read */
						Set tLastEndChars = $S($L(tData_tZB)<=tTermLen:tLastEndChars_tData_tZB,1:$E(tData_tZB,$L(tData_tZB)-tTermLen+1,*))
						Set:($L(tLastEndChars)>tTermLen) tLastEndChars = $E(tLastEndChars,$L(tLastEndChars)-tTermLen+1,*)
						If (($L(tLastEndChars)<tTermLen)||(tLastEndChars'=..MessageFrameEndAsChars)){
							/* More terminators left so set this to empty to keep loop going */
							Set tZB = ""
						}
					} ElseIf (tTermLen=1) {
						If (tZB=..MessageFrameEndAsChars) {
							Set tLastEndChars = ..MessageFrameEndAsChars
							/* Had all the data we expect */
							Set tData = ""
						}
					}
				}
				If ..RemoveFraming {
					If (tStartCharsStillToRemove'="") {
						Set tStartCount = $L(tStartCharsStillToRemove)
						Kill tMatched
						Set tMatched(0)=""
						For c=1:1:tStartCount {
							/* We only want to remove matches if prior in count matched */
							If $D(tMatched(c-1)),$E(tDataToWrite)=$E(tStartCharsStillToRemove) {
								Set $E(tDataToWrite)="",$E(tStartCharsStillToRemove)="",tMatched(c)=""
							}
						}
					}
					/* End frame check and remove if needed */
					If (tZBsaved'="") {
						If $L(..MessageFrameEndAsChars) = 1 {
							/* End framing sequence found do not write to stream */
							Set:(tZBsaved=..MessageFrameEndAsChars) tZBsaved = ""
						} Else {
							If (tEndTermHold'=""),(tDataToWrite'="") {
								/* Write what we have and record last tZB since more than one end char */
								Set tDataToWrite = tDataHold_tEndTermHold_tDataToWrite
								Set tEndTermHold = tZBsaved, tZBsaved = "", tDataHold = ""
							} ElseIf (tEndTermHold_tZBsaved = ..MessageFrameEndAsChars) {
								/* End framing sequence found do not write to stream */
								Set tZBsaved = "", tEndTermHold = ""
								Set tDataToWrite = tDataHold, tDataHold = ""
							} ElseIf (tEndTermHold_tZBsaved = $E(..MessageFrameEndAsChars,1,$L(tEndTermHold_tZBsaved))) {
								/* Possible part of end framing sequence don't write and keep for next read.*/
								Set tEndTermHold = tEndTermHold_tZBsaved, tZBsaved = ""
								/* Either tDataHold will be "" or tDataToWrite will be = "" depending on number of terminators */
								Set tDataHold = tDataHold_tDataToWrite, tDataToWrite = ""
							} ElseIf (tEndTermHold '= "") {
								/* Not part of the end framing sequence write previous ZB to stream and remember current*/
								Set tEndTermHoldNew = tZBsaved, tZBsaved = tEndTermHold, tEndTermHold = tEndTermHoldNew, tEndTermHoldNew = ""
								Set tDataHoldNew = tDataToWrite, tDataToWrite = tDataHold, tDataHold = tDataHoldNew, tDataHoldNew = ""							
							}
						}
					}	
				}
				If pStream = "" {
					If "binary"=$ZCVT(pCharset,"L") {
						If ..UseFileStream {
							Set pStream=##class(%Stream.FileBinary).%New()
						} Else {
							Set pStream=##class(%Stream.GlobalBinary).%New()
						}
					} Else {
						If ..UseFileStream {
							Set pStream=##class(%Stream.FileCharacter).%New()
							Set pStream.TranslateTable="UnicodeLittle", pStream.BOM=""
						} Else {
							Set pStream=##class(%Stream.GlobalCharacter).%New()
						}
					}
				}
				/* May hold data and hence may not be anything to write this pass */
				If ((tDataToWrite_tZBsaved)'="") {
					If "RAW"'=tTable { 
						Do pStream.Write($ZCVT(tDataToWrite,"I",tTable)_$ZCVT(tZBsaved,"I",tTable))
					} Else {
						Do pStream.Write(tDataToWrite_tZBsaved)
					}
				}

			}
		/* Loop while we believe there is more to read from the TCP buffer until we reach terminators. */
		} While tSC&&((tData'="")||(tZB="")||(tDataHold'=""))&&(tTimeout'=pStartTimeout)
		
		If (tDataHold'="") {
			If "RAW"'=tTable { 
				Do pStream.Write($ZCVT(tDataHold,"I",tTable)_$S(..RemoveFraming:"",1:$ZCVT(tEndTermHold,"I",tTable)))
			} Else {
				Do pStream.Write(tDataHold_$S(..RemoveFraming:"",1:tEndTermHold))
			}
			$$$catTRACE("connwait","Got data before missing terminators '"_$$$MapCtlLineZB(tDataHold,tEndTermHold)_"'")
		}
		
		/* If last terminator not present then tSC is a read timeout but we still have data */
		If (pStream'=""),(tSC||tDataWithoutTerminators),(pStream.Size){
			/* Check the starting frame */
			Set tFrameStartOK = 0
			If '..RemoveFraming {
				Do pStream.Rewind()
			 	If (pStream.Read($L(..MessageFrameStartAsChars))=..MessageFrameStartAsChars) {
			 		Set tFrameStartOK = 1
			 	}
			} ElseIf (tStartCharsStillToRemove="") {
				Set tFrameStartOK = 1
			}
			Set pProcessMessage = 1
			/* Allow terminators to be used in message and hence do not check 'tHadDataBetweenTerminators, */
			If (tLastEndChars=..MessageFrameEndAsChars),tFrameStartOK,'tDataWithoutTerminators {
				$$$catTRACE("protocol","Continuing with correctly framed message")
			} ElseIf '..DiscardDataNotwithinFraming {
				$$$catTRACE("protocol","Continuing with incorrect framed message")
			} Else {
				$$$catTRACE("protocol","Discarding incorrect framed message")
				Set pDiscardedMessage = 1
			}		
		} Else {
			#; No Data received
		}
	} Catch {
		Set tSC = $$$SystemError
	}
	
	If ..IsReadError(tSC) {
		Set tSC=$$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),"Framed Read", ..IOAddr, $$$StatusDisplayString(tSC))
		Set:'pInbound ..BusinessHost.Retry=1
		Do ..Disconnect()
	}
	Quit tSC
}

/// Read a framed block from the TCP socket into the String using a Charset for translation.
/// (logs errors except for <READ> errors after the initial blocksize read.)
Method ReadFramedString(ByRef pString As %String, pCharset As %String = "", pStartTimeout As %Numeric = -1, pChunkTimeout As %Numeric = 60, pInbound As %Boolean = 0, Output pProcessMessage As %Integer = 0, Output pDiscardedMessage As %Integer = 0) As %Status
{
	Set tSC=$$$OK
	Try {
		Set tSC = ..ReadFramedStream(.tTempStream,pCharset,pStartTimeout,pChunkTimeout,pInbound, .pProcessMessage, .pDiscardedMessage)
		If pProcessMessage {
			Set pString = "", tLen = 0
			While 'tTempStream.AtEnd {
				Set tChunk = tTempStream.Read()
				If (($L(tChunk)+tLen)>$$$MaxLocalLength) {
					Set pString = pString_$E(tChunk,1,$$$MaxLocalLength-tLen)
				} Else {
					Set pString = pString_tChunk
				}
				Set tLen = $L(pString)
			}
		}	
	} Catch {
		Set tSC = $$$SystemError
	}
	If ..IsReadError(tSC) {
		Set tSC=$$$ERROR($S(pInbound:$$$EnsErrInConnectionLost,1:$$$EnsErrOutConnectionLost),"Framed Read", ..IOAddr, $$$StatusDisplayString(tSC))
		Set:'pInbound ..BusinessHost.Retry=1
		Do ..Disconnect()
	}
	Quit tSC
}

/// Read a fixed length block from the TCP socket into the Stream using a Charset for translation.
/// (logs errors except for <READ> errors after the initial blocksize read.)
Method ReadFixedLengthStream(ByRef pStream As %CharacterStream = "", pCharset As %String = "", pStartTimeout As %Numeric = -1, pChunkTimeout As %Numeric = 60, pInbound As %Boolean = 0, pLen As %Integer = 0) As %Status
{
	Set tSC=$$$OK, $ZT="TrapRS"
	Do {
		If 'pInbound $$$catTRACE("protocol","Waiting to read stream fixed length data "_pLen_" from "_..IOAddr_" using charset '"_pCharset_"' with timeout="_pStartTimeout)

		If '$IsObject(pStream)&&(pInbound||pLen) {
			If ""'=pStream {
			 	Set pStream=$classmethod(pStream,"%New")  
			} Else {
				If "binary"=$ZCVT(pCharset,"L") {
					If ..UseFileStream {
						Set pStream=##class(%Stream.FileBinary).%New()
					} Else {
						Set pStream=##class(%Stream.GlobalBinary).%New()
					}
				} Else {
					If ..UseFileStream {
						Set pStream=##class(%Stream.FileCharacter).%New()
						Set pStream.TranslateTable="UnicodeLittle", pStream.BOM=""
					} Else {
						Set pStream=##class(%Stream.GlobalCharacter).%New()
					}
				}
			}
			$$$ASSERT($IsObject(pStream))
		}
		If 'pLen {
			If $$$ISOK(tSC) { $$$catTRACE("protocol","Got stream inbound data block (size=0) from "_..IOAddr_", Status OK") }
			Quit
		}
		Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
		Set tLeft = pLen, tMaxChunk = $$$MaxLocalLength\4
		While tLeft>0 {
				Set tChunkSize = $select(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
				Set tStartTime=$zh
				Read data#tChunkSize:pChunkTimeout  If '$Test {
					If $zh-tStartTime < pChunkTimeout { Set tSC = $$$EnsError($$$EnsErrTCPReadBlockSize,pChunkTimeout,tChunkSize,"("_$L(data)_"):"_data)  Quit }
					Else { Set tSC = $$$EnsError($$$EnsErrTCPReadTimeoutExpired,pChunkTimeout,tChunkSize,pCharset)  Quit }
				}
				$$$catTRACE("protocol","Got stream data chunk, size="_$L(data)_"/"_tChunkSize)
				Set tLeft = tLeft-$L(data)
				If "RAW"'=tTable { 
					Do pStream.Write($ZCVT(data,"I",tTable))
				} Else {
					Do pStream.Write(data)
				}
		}
		If "RAW"'=tTable {$$$catTRACE("protocol","Converted("_pLen_") input stream bytes to ("_pStream.Size_") characters using charset '"_pCharset_"', table '"_tTable_"'")}
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

/// Method to convert comma delimited numbers to characters
Method AsciiOrHexAsChars(pAsciiOrHex As %String = "") As %String
{
	Set tChars = ""
	Try {
		For c = 1:1:$L(pAsciiOrHex,",") {
			Set tChar = $P(pAsciiOrHex,",",c)
			Set:(tChar'="") tChars = tChars_$C($S($ZCVT($E(tChar),"L")="x":$S($L(tChar)>1:$ZH($E(tChar,2,*)_""),1:""),1:tChar))
		}
	} Catch {
	}
	Quit tChars
}

}
