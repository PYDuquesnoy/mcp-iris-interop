/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsRecordMap

/// Base class for RecordMap parsers, which are generated based on the content of RecordMaps
Class EnsLib.RecordMap.RecordMap Extends %RegisteredObject [ System = 4 ]
{

Parameter OBJECTNAME As %String;

/// Method to retrieve a record from a stream or device. This method will be generated based on the
/// structure of the RecordMap. For testing purposes, a file name may be passed in the pStream argument.
ClassMethod GetObject(pStream As %IO.DeviceStream, Output pObject As %RegisteredObject, pTimeout As %Numeric = -1, ByRef pLookAhead As %String = "", pLabelFound As %Boolean = 0) As %Status [ Abstract ]
{
}

/// Method to write a record to a stream or device. This method will be generated based on the
/// structure of the RecordMap. For testing purposes, a file name may be passed in the pStream argument.
ClassMethod PutObject(pStream As %IO.DeviceStream, pObject As %RegisteredObject, pFlush As %Boolean = 1, ByRef pPadArray As %String) As %Status [ Abstract ]
{
}

ClassMethod GetGeneratedClasses(Output pClasses As %String) As %Status
{
	Kill pClasses
	Quit $$$OK
}

ClassMethod GetRecordIdentifier(pRecordMap As %String = "") As %String
{
	If '..Exists(pRecordMap) Quit ""
	Set tDone = 0
	Set tIdentifier = ""
	Try {
		Set tClassname = $$$NormalizeClassname(pRecordMap)
		Set tIdentifier = $classmethod(tClassname,"getIdentifier")
		Set tDone = 1
	}
	Catch {}
	If tDone Quit tIdentifier

	Set tModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(pRecordMap,.tStatus)
	If $$$ISERR(tStatus) Quit ""
	Quit tModel.label
}

ClassMethod GetRecordType(pRecordMap As %String = "") As EnsLib.RecordMap.Model.DataType.RecordType
{
	If '..Exists(pRecordMap) Quit ""
	Set tDone = 0
	Set tRecType = ""
	Try {
		Set tClassname = $$$NormalizeClassname(pRecordMap)
		Set tRecType = $classmethod(tClassname,"getType")
		Set tDone = 1
	}
	Catch {}
	If tDone Quit tRecType

	Set tModel = ##class(EnsLib.RecordMap.Model.Record).LoadFromClass(pRecordMap,.tStatus)
	If $$$ISERR(tStatus) Quit ""
	Quit tModel.type
}

ClassMethod getIdentifier() As %String [ Abstract ]
{
}

ClassMethod getType() As EnsLib.RecordMap.Model.DataType.RecordType [ Abstract ]
{
}

/// Delete an existing RecordMap, and optionally delete the target class definition and the target class's extent.<br>
/// The option to remove the extent is only evaluated if the target class is also being deleted, otherwise the option is ignored.<br>
/// The input parameter pLeaveClassDeleteToCaller & output parameter pTargetClass allow the caller to delete the RecordMap class
/// and optional delete of TargetClass within a separate Source Control aware API.
ClassMethod DeleteRecordMap(pRecordMap As %String = "", pRemoveTargetClass As %Boolean = 0, pRemoveTargetExtent As %Boolean = 0, pLeaveClassDeleteToCaller As %Boolean = 0, Output pTargetClass As %String = "") As %Status
{
	If '##class(EnsLib.RecordMap.RecordMap).Exists(pRecordMap) Quit $$$ERROR($$$ClassDoesNotExist, pRecordMap)

	#dim tStatus = $$$OK
	#dim ex As %Exception.AbstractException

	Try {
		#dim tRecordMap = $$$NormalizeClassname(pRecordMap)
		#; We'll pass back target class as pTargetClass if use it.
		#dim tTargetClass = $$$comMemberKeyGet(tRecordMap,$$$cCLASSparameter,"OBJECTNAME",$$$cPARAMdefault)
		If 'pLeaveClassDeleteToCaller {
			Set tStatus = ##class(%Dictionary.ClassDefinition).%DeleteId(tRecordMap)
			If $$$ISERR(tStatus) Quit
		}
		If pRemoveTargetClass && (tTargetClass '= "") {
			Set pTargetClass = $$$NormalizeClassname(tTargetClass)
			If pRemoveTargetExtent && ##class(%Dictionary.CompiledClass).%ExistsId(pTargetClass) && $classmethod(pTargetClass, "%IsA", "%Library.Persistent") {
				Set tStatus = $classmethod(pTargetClass, "%DeleteExtent")
				If $system.Status.Equals(tStatus, $$$ERRORCODE($$$ClassDoesNotExist), $$$ERRORCODE($$$DeleteObjectNotFound)) Set tStatus = $$$OK
				If $$$ISERR(tStatus) Quit
			}
			If 'pLeaveClassDeleteToCaller {
				// Returns an error if target class doesn't exist
				Set tStatus = ##class(%Dictionary.ClassDefinition).%DeleteId(pTargetClass)
				If $$$ISERR(tStatus) Quit
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// Internal helper method to perform parse of incoming data
ClassMethod GetRecord(pStream As %IO.DeviceStream, pObject As %RegisteredObject, pGetTopFields As %Boolean, pTimeout As %Numeric, pLookAhead As %String = "", pLabelFound As %Boolean = 0) As %Status [ Abstract, Internal, Private ]
{
	Quit $$$OK
}

/// Internal helper method to output object to a stream
ClassMethod PutRecord(pStream As %IO.DeviceStream, pObject As %RegisteredObject, pHasTopFields As %Boolean) As %Status [ Abstract, Internal, Private ]
{
	Quit $$$OK
}

/// This functionality has been moved to <class>EnsLib.RecordMap.Utils</class>, which is invoked from this entry point.
ClassMethod SampleParse(pRecordMap As %String, pSampleFile As %String, Output pOutputHTML As %Stream.TmpCharacter, pGetTopFields As %Boolean = 1, pLabelFound As %Boolean = 0, pMaxRecords As %Integer = 3) As %Status [ Internal ]
{
	Quit ##class(EnsLib.RecordMap.Utils).SampleParse(.pRecordMap,.pSampleFile,.pOutputHTML,pGetTopFields,pLabelFound,pMaxRecords)
}

/// Get actual characters from an internal string representation.
ClassMethod getChars(pChars As %String) As %String [ Internal ]
{
	Set tChars = ""
	If $zconvert(pChars,"L") '[ "$char" Quit pChars
	Set tSep = $piece($piece(pChars,"$char(",2),")",1)
	For j = 1:1:$length(tSep, ",") {
		
		Set tSepVal = $piece(tSep, ",", j)
		If $IsValidNum(tSepVal) {
			Set tChars = tChars _ $char(tSepVal)
		}
		ElseIf tSepVal '= ""{
			Set tChars = tChars _ tSepVal
		}
	}
	Quit tChars
}

/// Escape characters for HTML output
ClassMethod escapeChars(pChars As %String, ByRef pBreaks As %Integer = 0, pIgnoreSpaces As %Boolean = 0) As %String [ Internal ]
{
	Set tChars = ""
	For i=1:1:$length(pChars) {
		Set tChar = $ascii($extract(pChars, i))
		If pIgnoreSpaces && (tChar = 32) {
			Set tChars = tChars _ " "
		}
		ElseIf (tChar <= 32) {
			Set tHex = $zconvert($zhex(tChar), "l")
			If tChar < 16 Set tHex = "0"_ tHex
			Set tChars = tChars _ "\x"_ tHex
			If tChar = 10 {
				Set pBreaks = pBreaks + 1
			}
		}
		Else {
			Set tChars = tChars _ $zconvert($char(tChar), "O", "HTML")
		}
	}
	Quit tChars
}

/// Read the supplied label from the stream.
ClassMethod readLabel(pStream As %IO.DeviceStream, pLabel As %String, pTimeout As %Numeric = -1, ByRef pExtra As %String = "") As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Set tTimeout = pTimeout
	Set tLabelLen = $length(pLabel)
	Set tExtraLen = $length(pExtra)
	If tExtraLen >= tLabelLen {
		Set tLabelRead = $extract(pExtra, 1, tLabelLen)
		Set pExtra = $extract(pExtra, tLabelLen + 1, *)
	}
	Else {
		Set tLabelLen = tLabelLen - tExtraLen
		Set tLabelRead = pExtra _ pStream.Read(tLabelLen, .tTimeout, .tStatus)
		If $$$ISERR(tStatus) Quit tStatus
		If tTimeout {
			Quit $$$ERROR($$$EnsErrTCPReadTimeoutExpired, pTimeout, tLabelLen, pStream.CharEncoding)
		}
		Set pExtra = ""
		If (tLabelRead = "")&&(pStream.AtEnd) {
			Quit $$$ERROR($$$EnsRecordMapErrStreamAtEnd, pStream.Name)
		}
	}
	If tLabelRead '= pLabel {
		Quit $$$ERROR($$$EnsRecordMapErrLabelMismatch, ..escapeChars(pLabel), ..escapeChars(tLabelRead))
	}
	Quit tStatus
}

/// Chunk the incoming data into pieces while looking for the supplied terminator and/or maximum length.
ClassMethod chunkRecord(pStream As %IO.DeviceStream, Output pRecordChunk As %Integer, Output pCharCount As %Integer, pMaxLen As %Integer = "", pTimeout As %Numeric = -1, ByRef pRecordTerminator As %String = "", pLabel As %String = "", ByRef pExtra As %String = "", pQuoteChar As %String = "", ByRef pAllowEmbeddedRecTerm As %Boolean = 0) As %Status [ Internal ]
{
	Try {
		Set tStatus = $$$OK
		Kill pRecordChunk, pCharCount
		Set tTimeout = pTimeout
		Set pCharCount = 0
		Set tExtra = pExtra
		Set pExtra = ""
		
		If pLabel '= "" {
			Set tStatus = ..readLabel(pStream, pLabel, pTimeout, .tExtra)
			If $$$ISERR(tStatus) Quit
		}
		
		Set pRecordChunk = 0
		Set tRead = 0
		
		Set tCharsSeen = 0
		Set tRecTerm = $extract(pRecordTerminator, 1)
		Set tRest = $extract(pRecordTerminator, 2, *)
		Set tRestLen = $length(tRest)
		Set pRecordTerminator = ""
		
		Set tQuoteOpen = 0
		Set tQuoteLen = $length(pQuoteChar)
		
		While ('tRead) && ('pStream.AtEnd||(""'=tExtra)) {
			Set tTimeout = pTimeout
			Set tTerm = tRecTerm
			
			Set pRecordChunk = pRecordChunk + 1
			Set tRemLen = $select(pMaxLen:pMaxLen + $length(tRecTerm) - $length(pLabel) - tCharsSeen,1:"")
			If tRecTerm '= "" {
				If tExtra[tRecTerm {
					Set tTermLoc = $find(tExtra,tRecTerm)-1
					If (""'=tRemLen)&&(tRemLen<tTermLoc) {
						Set pRecordChunk(pRecordChunk) = $extract(tExtra,1,tRemLen)
						Set tExtra = $extract(tExtra,tRemLen+1,*)
						set tTerm = ""
					} Else {
						Set pRecordChunk(pRecordChunk) = $extract(tExtra,1,tTermLoc-1)
						Set tExtra = $extract(tExtra,tTermLoc+1,*)
					}
					Set tTimeout = 0
				} Else {
					Set tReadLen = $select(""'=tRemLen:tRemLen - $length(tExtra),1:"")
					Set pRecordChunk(pRecordChunk) = tExtra _ pStream.ReadLine(tReadLen, .tTimeout, .tStatus, .tTerm)
					Set tExtra = ""
				}
			}
			Else {
				If (""'=tRemLen)&&($length(tExtra)>tRemLen) {
					Set pRecordChunk(pRecordChunk) = $extract(tExtra,1,tRemLen)
					Set tExtra = $extract(tExtra,tRemLen+1,*)
					Set tTimeout = 0
				} Else {
					Set tReadLen = $select(""'=tRemLen:tRemLen - $length(tExtra),1:"")
					Set pRecordChunk(pRecordChunk) = tExtra _ pStream.Read(tReadLen, .tTimeout, .tStatus)
					Set tExtra = ""
				}
			}
			If $$$ISERR(tStatus) Quit
			
			Set tCharsSeen = tCharsSeen + $length(pRecordChunk(pRecordChunk))
			
			If tTimeout {
				If tRecTerm = "" {
					Set tStatus = $$$ERROR($$$EnsErrTCPReadTimeoutExpired, pTimeout, tReadLen, pStream.CharEncoding)
				}
				Else {
					Set tStatus = $$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired, pTimeout, ##class(EnsLib.RecordMap.Generator).getLogicalChars(pRecordTerminator))
				}
				Quit
			}
			ElseIf (pRecordChunk(pRecordChunk) = "")&&(tTerm = "") { // No data available
				Set tStatus = $$$ERROR($$$EnsRecordMapErrStreamAtEnd, pStream.Name)
				Quit
			}
			ElseIf (""'=tRemLen)&&($length(pRecordChunk(pRecordChunk)) = tRemLen) { // Read entire record
				If (tRecTerm = "") {
					Set tStatus = $$$OK
				}
				ElseIf (tTerm = "")||(tTerm '= tRecTerm) {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrRecTermNotFound, ..escapeChars(tRecTerm_tRest))
					Set tExtra = $extract(pRecordChunk(pRecordChunk), *)_tExtra
					Set pRecordChunk(pRecordChunk) = $extract(pRecordChunk(pRecordChunk), 1, *-1)
				}
				ElseIf tRestLen {
					Set tStatus = $$$ERROR($$$EnsRecordMapErrRecTermNotFound, ..escapeChars(tRest))
				}
				Else {
					Set tStatus = $$$OK
				}
				Quit
			}
			
			// Process delimited escape blocks
			If pQuoteChar '= "" {
				Set tQuotePos = $find(pRecordChunk(pRecordChunk), pQuoteChar)
				If (tQuotePos = 0) && tQuoteOpen {
					Set pRecordChunk(pRecordChunk, "block") = "mid"
				}
				// Assume delimiter is 1 character
				While tQuotePos {
					If ('tQuoteOpen) && (tQuotePos = (1 + tQuoteLen)) { // start of block
						Set pRecordChunk(pRecordChunk, "block") = "start"
						Set pRecordChunk(pRecordChunk) = $extract(pRecordChunk(pRecordChunk), tQuotePos, *)
						Set tQuoteOpen = 1
						Set tStartPos = 0
					}
					ElseIf tQuoteOpen && ($extract(pRecordChunk(pRecordChunk),tQuotePos,tQuotePos+tQuoteLen-1) = pQuoteChar) {
						// Quote character is repeated and we found the first one
						Set $extract(pRecordChunk(pRecordChunk),tQuotePos-tQuoteLen,tQuotePos+tQuoteLen-1) = pQuoteChar
						Set tStartPos = tQuotePos
					}
					Else {
						Set pRecordChunk = pRecordChunk + 1
						If tQuoteOpen {
							Set tCopyPos = tQuotePos + 1
							Set pRecordChunk(pRecordChunk - 1, "block") = "end"
						}
						Else {
							Set tCopyPos = tQuotePos
							Set pRecordChunk(pRecordChunk, "block") = "start"
						}
						Kill tRemainingQuoted
						If $length(pRecordChunk(pRecordChunk - 1)) > (tQuotePos-1) {
							Set tRemainingQuoted = $extract(pRecordChunk(pRecordChunk - 1), tCopyPos, *)
						}
						// -2 for $extract syntax AND leading delimiter if Quote not open
						Set pRecordChunk(pRecordChunk - 1) = $extract(pRecordChunk(pRecordChunk - 1), 1, tQuotePos - tQuoteLen - 1 - ('tQuoteOpen))
						Set tQuoteOpen = 'tQuoteOpen
						If $data(tRemainingQuoted) {
							Set pRecordChunk(pRecordChunk) = tRemainingQuoted
						}
						Else {
							Set pRecordChunk = pRecordChunk - 1
							Quit
						}
						Set tStartPos = 0
					}
					
					Set tQuotePos = $find(pRecordChunk(pRecordChunk), pQuoteChar, tStartPos)
				}
			}
			
			If tTerm = tRecTerm {
				Set tCharsSeen = tCharsSeen + $length(tTerm)
				If tRestLen { ; check we have the full terminator string
					Set tTermDone = 0
					Set tPrev = ""
					While ('tTermDone) {
						Set tTimeout = pTimeout
						If ("" '= tExtra) {
							Set tLenDiff = tRestLen - $length(tPrev)
							Set tPrev = tPrev _ $extract(tExtra,1,tLenDiff)
							Set tExtra = $extract(tExtra,tLenDiff + 1, *)
						}
						Set tString = tPrev _ pStream.Read(tRestLen - $length(tPrev), .tTimeout, .tStatus)
						If $$$ISERR(tStatus) Quit
						If tTimeout {
							Set tStatus = $$$ERROR($$$EnsErrTCPTerminatedReadTimeoutExpired, pTimeout, ##class(EnsLib.RecordMap.Generator).getLogicalChars(pRecordTerminator))
							Quit
						}
						If tString = tRest {
							Set tRead = 1
							Set tTermDone = 1
							Set pRecordTerminator = tTerm_tRest
						}
						ElseIf tString [ tRecTerm {
							Set tTermPos = $find(tString, tRecTerm)
							Set tPrev = $extract(tString, tTermPos, *)
							Set tString = $extract(tString, 1, tTermPos-1)
							If tString'="" {
								Set pRecordChunk = pRecordChunk + 1
								Set pRecordChunk(pRecordChunk) = tString
							}
						}
						Else {
							Set tTermDone = 1
							Set pRecordChunk = pRecordChunk + 1
							Set pRecordChunk(pRecordChunk) = tString
						}
					}
					If $$$ISERR(tStatus) Quit
				}
				Else {
					Set pRecordTerminator = tTerm
					Set tRead = 1
				}
				If tRead && pAllowEmbeddedRecTerm && tQuoteOpen && (pQuoteChar '= "") {
					Set tRead = 0
					Set pRecordChunk = pRecordChunk + 1
					Set pRecordChunk(pRecordChunk) = pRecordTerminator
					Set pRecordChunk(pRecordChunk, "block") = "mid"
			}
		}
		}
		If $$$ISERR(tStatus) Quit
		If (pQuoteChar '= "") && tQuoteOpen {
			Set tStatus = $$$ERROR($$$EnsRecordMapErrQuoteCharMismatch)
			Quit
		}
		Set pCharCount = tCharsSeen
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Set pExtra = tExtra
	Quit tStatus
}

/// Helper method for parsing chunked fixed width records
ClassMethod checkFixedWidthChunk(ByRef pStatus As %Status, ByRef pNewChunk, ByRef pCurrChunk, ByRef pRecordData, ByRef pCurrString, ByRef pCurrLen, ByRef pCurrPos, pWidth As %Integer, pSep As %String = "", pTrailing As %String = "", pFieldName As %String = "", pAllowEarlyTerminator As %Integer = 0) As %String [ Internal ]
{
	Set tCurrVal = ""
	Set tRead = 0
	Set tSepWidth = $length(pSep)
	Set tTrailWidth = $length(pTrailing)
	
	Set tReadWidth = pWidth + tTrailWidth + tSepWidth
	Set pStatus = $$$OK
	
	While ('tRead) {
		If pNewChunk {
			If pCurrChunk > pRecordData {
				Set pStatus = $select(pAllowEarlyTerminator: $$$OK, 1: $$$ERROR($$$EnsRecordMapErrIncompleteRecord))
				Quit
			}
			Set pCurrString = pRecordData(pCurrChunk)
			Set pCurrLen = $length(pCurrString)
			Set pCurrChunk = pCurrChunk + 1
			If pCurrPos > pCurrLen {
				Set pCurrPos = 1
				Set pCurrString = $get(pRecordData(pCurrChunk))
				Set pCurrLen = $length(pCurrString)
				Set pCurrChunk = pCurrChunk + 1
			}
			Set pNewChunk = 0
		}
		If (pCurrLen-pCurrPos+1)< tReadWidth {
			
			Set tExtra = tReadWidth - (pCurrLen - pCurrPos + 1)
			If 'pAllowEarlyTerminator && (($get(pRecordData("charcount")) - pCurrPos) < tExtra) {
				Set pStatus = $$$ERROR($$$EnsRecordMapErrIncompleteRecord)
				Quit
			}
			
			Set tNext = $extract(pCurrString, pCurrPos, *)
			If pCurrChunk > pRecordData {
				If 'pAllowEarlyTerminator {
					Set pStatus = $$$ERROR($$$EnsRecordMapErrIncompleteRecord)
					Quit
				}
			} Else {
				Set tNext = tNext _ $extract(pRecordData(pCurrChunk), 1, tExtra)
			}
			Set tCurrVal = tCurrVal _ tNext
			
			If $length(tNext)<tExtra {
				Set tExtra = $length(tNext)
				Set tReadWidth = tReadWidth - $length(tNext)
			}
			Else {
				If pSep '= "" {
					Set tSepRead = $extract(tCurrVal, * - tSepWidth + 1, *)
					If tSepRead '= pSep {
						Set pStatus = $$$ERROR($$$EnsRecordMapErrFieldSepMismatch, pFieldName, ..escapeChars(pSep), ..escapeChars(tSepRead))
						Quit
					}
				}
				If pTrailing '= "" {
					Set tTrailing = $extract(tCurrVal, * - (tSepWidth + tTrailWidth) + 1, * - tSepWidth)
					If tTrailing '= pTrailing {
						Set pStatus = $$$ERROR($$$EnsRecordMapErrTrailingDataMismatch, pFieldName, ..escapeChars(pTrailing), ..escapeChars(tTrailing))
						Quit
					}
				}
				Set tRead = 1
			}
			Set pCurrPos = 1 + tExtra
			Set pNewChunk = 1
		}
		Else {
			Set tCurrVal = $extract(pCurrString, pCurrPos, pCurrPos + tReadWidth - 1)
			If pSep '= "" {
				Set tSepRead = $extract(tCurrVal, * - tSepWidth + 1, *)
				If tSepRead '= pSep {
					Set pStatus = $$$ERROR($$$EnsRecordMapErrFieldSepMismatch, pFieldName, ..escapeChars(pSep), ..escapeChars(tSepRead))
					Quit
				}
			}
			If pTrailing '= "" {
				Set tTrailing = $extract(tCurrVal, * - (tSepWidth + tTrailWidth) + 1, * - tSepWidth)
				If tTrailing '= pTrailing {
					Set pStatus = $$$ERROR($$$EnsRecordMapErrTrailingDataMismatch, pFieldName, ..escapeChars(pTrailing), ..escapeChars(tTrailing))
					Quit
				}
			}
			Set tCurrVal = $extract(tCurrVal, 1, * - (tSepWidth + tTrailWidth))
			Set tRead = 1
			Set pCurrPos = pCurrPos + tReadWidth
			If pCurrPos > pCurrLen {
				Set pCurrPos = 1
				Set pNewChunk = 1
			}
		}
	}
	If $$$ISERR(pStatus) Quit ""
	Quit tCurrVal
}

/// Helper method to ensure delimited data spread over multiple chunks is correctly reconstituted.
ClassMethod checkMerge(ByRef pCurrChunk, ByRef pRecordData, ByRef pCurrString, pCurrSep, ByRef pCurrPiece, ByRef pEscaping) [ Internal ]
{
	If $data(pRecordData(pCurrChunk, "block")) {
		If pRecordData(pCurrChunk, "block") = "end" {
			If pCurrChunk < pRecordData {
				Set pCurrString = pRecordData(pCurrChunk)
				Set pCurrChunk = pCurrChunk + 1
				Set pCurrPiece = 1
			} Else {
				Set pCurrString = $S(pCurrPiece=1:pRecordData(pCurrChunk),1:"")
				// Do not increment pCurrChunk to point where pRecordData(pCurrChunk) is undefined.  Use pCurrPiece '= 1 instead as indicator that we are beyond the final chunk. 
				Set pCurrPiece = pCurrPiece + 1
			}
		}
		Else { // not end block
			#; If start do not rely on caller to populate pCurrString with the starting data
			If pRecordData(pCurrChunk, "block") = "start" Set pCurrString = pRecordData(pCurrChunk)
			For i=pCurrChunk+1:1:pRecordData {
				If '$data(pRecordData(i, "block")) Quit
				
				Set pCurrString = pCurrString _ $get(pRecordData(i))
				If ($get(pRecordData(i, "block")) = "end") Quit
			}
			If '$data(pRecordData(i, "block")) {
				#; not used the data yet so don't increment.
				Set pCurrChunk = i
				Set pCurrPiece = 1
			} Else {
				// Do not increment pCurrChunk to point where pRecordData(pCurrChunk) is undefined.  Use pCurrPiece '= 1 instead as indicator that we are beyond the final chunk.
				If pCurrChunk < pRecordData {
					Set pCurrChunk = i+1
					Set pCurrPiece = 1
				} Else {
					Set pCurrChunk = i
					Set pCurrPiece = pCurrPiece + 1
				}
			}
		}
	}
	ElseIf $length($get(pRecordData(pCurrChunk)), pCurrSep) = pCurrPiece {
		If pCurrChunk < pRecordData {
			For i=pCurrChunk+1:1:pRecordData {
				// We are not in a block
				If $data(pRecordData(i, "block")) {
					Set pCurrChunk = i
					Set pCurrPiece = 1
					Quit
				}
				Set tCurrData = $get(pRecordData(i))
				If $length(tCurrData, pCurrSep) = 1 {
					Set pCurrString = pCurrString _ tCurrData
				}
				Else {
					Set pCurrString = pCurrString _ $piece(tCurrData, pCurrSep, 1)
					Set pCurrChunk = i
					Set pCurrPiece = 2
					Quit
				}
				
				If i = pRecordData { ; if we are at the end of the data
					Set pCurrChunk = pRecordData
					Set pCurrPiece = 2
				}
			}
		}
		Else {
			Set pCurrPiece = pCurrPiece + 1
		}
	}
	Else {
		Set pCurrPiece = pCurrPiece + 1
	}

	Quit
}

ClassMethod Escape(pData As %String, pSeps As %List, pEscaping As %String, pEscSequence As %String) As %String
{
	If pEscaping = "quote" {
		If (pData = "") Quit pData
		Set tEscape = 0
		For i=1:1:$listlength(pSeps) {
			Set tSep = $listget(pSeps, i)
			If tSep = "" Continue
			If (pData [ tSep) {
				Set tEscape = 1
				Quit
			}
		}
		If 'tEscape {
			Set tEscape = (pData [ pEscSequence)
			If 'tEscape { Quit pData }
		}
		
		Quit pEscSequence _ $replace(pData,pEscSequence,pEscSequence_pEscSequence) _ pEscSequence
	} Elseif pEscaping = "all" {
		Quit pEscSequence _ $replace(pData,pEscSequence,pEscSequence_pEscSequence) _ pEscSequence
	} Else {
		Quit pData
	}
}

/// Check for the existence of a specific RecordMap.
ClassMethod Exists(name As %String) As %Boolean
{
	Set tName = $$$NormalizeClassname(name)
	If '##class(%Dictionary.ClassDefinition).%ExistsId(tName) Quit 0
	Quit ##class(%Dictionary.XDataDefinition).%ExistsId(tName_"||RecordMap")
}

/// List the existing RecordMap definitions.
Query List() As %Query(ROWSPEC = "name:%String,modified:%TimeStamp,size:%Integer") [ SqlProc ]
{
}

ClassMethod ListExecute(ByRef qHandle As %Binary) As %Status
{
	Set qHandle = ""
	
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("EnsLib.RecordMap.RecordMap")
	If $$$ISERR(tSC) Quit tSC
		
	While tRS.Next() {
		Set tClassname = tRS.Get("Name")
		If tClassname = "EnsLib.RecordMap.RecordMap" Continue
		Set tClassIndex = $get(^rINDEXCLASS($zconvert(tClassname,"U")))
		Set tTimestamp = $listget(tClassIndex,1)
		Set tSize = $listget(tClassIndex,6)
		If $Extract(tClassname,1,5)="User." Set tClassname = $Extract(tClassname,6,*)
		
		Set qHandle("RecordMap",tClassname) = $lb(tTimestamp,tSize)
	}
	
	Quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
	Set Row = "", AtEnd = 0
	Set qHandle = $order(qHandle("RecordMap", qHandle))
	If qHandle = "" {
		Set AtEnd = 1
	}
	Else {
		Set tTimestamp = $lg(qHandle("RecordMap", qHandle), 1)
		Set tSize = $lg(qHandle("RecordMap", qHandle), 2)
		Set Row = $lb(qHandle, tTimestamp, tSize)
	}
	Quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListExecute ]
{
	Quit $$$OK
}

}
