/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simplistic Batch implementation to allow for rapid development of batches
/// with a simple, deterministic batch header and trailer structure
/// Note that the RecordMap framework will automatically define a relationship called Records
/// to the Record type contained in the batch. The RECORDMAPGENERATED parameter should be set to 0 if this 
/// automatic update should not occur.
Class EnsLib.RecordMap.SimpleBatch Extends EnsLib.RecordMap.Batch [ Abstract, System = 4 ]
{

/// Contents of the Batch Header
Parameter BatchHeader;

/// The terminator (if any) for the Batch Header. Hex values preceded by \x should be
/// used for control characters.
Parameter HeaderTerm;

/// Contents of the Batch Trailer
Parameter BatchTrailer;

/// The terminator (if any) for the Batch Trailer. Hex values preceded by \x should be
/// used for control characters.
Parameter TrailerTerm;

/// Parameter to control whether warnings should be logged when leading data is found before the Batch Header characters.
Parameter IgnoreLeadingData As BOOLEAN = 0;

/// Property used to contain the Batch Header and terminators for output.
/// This allows for easy manipulation of the output, if needed.
Property BatchHeader As %String(MAXLEN = "", XMLPROJECTION = "NONE") [ InitialExpression = {..#BatchHeader _ ..GetHeaderTerm()} ];

/// Property used to contain the Batch Trailer and terminators for output.
/// This allows for easy manipulation of the output, if needed.
Property BatchTrailer As %String(MAXLEN = "", XMLPROJECTION = "NONE") [ InitialExpression = {..#BatchTrailer _ ..GetTrailerTerm()} ];

/// Get the Batch Header from an incoming stream. This is only invoked once by the RecordMap
/// batch services when a new stream is passed in. Any extra data must be returned in pLookAhead
/// for use in parsing the first record.
ClassMethod GetBatchHeader(pIOStream As %IO.DeviceStream, pTimeout As %Numeric = -1, Output pBatch As EnsLib.RecordMap.SimpleBatch, ByRef pLookAhead As %String) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set pBatch = ""
		Set tTerm = ..GetHeaderTerm()
		Set tFullHeader = ..#BatchHeader _ tTerm
		Set tHeaderLen = $length(tFullHeader)
		If tHeaderLen {
			Set tFound = 0
			Set tLeadingJunk = ""
			Set pLookAhead = $get(pLookAhead)
			Set tTimeout = pTimeout
			Set tEndTime = $zhorolog + pTimeout
			While ('tFound) && ('pIOStream.AtEnd) {
				Set tReadLen = tHeaderLen - $length(pLookAhead)
				If tReadLen > 0 {
					Set tData = pLookAhead _ pIOStream.Read(tReadLen, .tTimeout, .tStatus)
					If $$$ISERR(tStatus) Quit
					If tTimeout {
						Set tStatus = $$$ERROR($$$EnsErrTCPReadTimeoutExpired, pTimeout, tReadLen)
						Quit
					}
					Set pLookAhead = ""
				}
				Else {
					Set tData = $extract(pLookAhead, 1, tHeaderLen)
					Set pLookAhead = $extract(pLookAhead, tHeaderLen + 1, *)
				}
				If (tData = tFullHeader) {
					Set pBatch = ..%New()
					Set tFound = 1
					Quit
				}
				Else {
					Set pLookAhead = pLookAhead _ tData
					#; Check if we should start discarding leading data
					If ($length(pLookAhead) >= tHeaderLen) {
						If ($length(tLeadingJunk) < 400) {
							Set tLeadingJunk = tLeadingJunk _ $extract(pLookAhead,1)
						}
						Set pLookAhead = $extract(pLookAhead,2,*)
					}
					
				}
				If (pTimeout = -1) {
					Set tTimeout = -1
				}
				Else {
					Set tCurrTime = $zhorolog
					If (tCurrTime > tEndTime) {
						Set tStatus = $$$ERROR($$$EnsErrTCPReadTimeoutExpired, pTimeout, tReadLen)
						Quit
					}
					Set tTimeout = tEndTime - tCurrTime
				}
			}
			If $$$ISERR(tStatus) Quit
			#; Clear the lookahead buffer if we didn't find the batch header
			If ('tFound) && ($length(tLeadingJunk) < 400){
				Set tLeadingJunk = tLeadingJunk _ $get(pLookAhead)
				Set pLookAhead = ""
			}
			If (tLeadingJunk '= "") && ('..#IgnoreLeadingData) {
				#; Use JS escaping to handle control characters
				Set tLoggedJunk = $zconvert($extract(tLeadingJunk,1,400),"O","JS") _ $select($length(tLeadingJunk) > 400: "...", 1: "")
				$$$LOGWARNING($$$FormatText($$$Text("Discarding unexpected leading data: '%1'","Ensemble"),tLoggedJunk))
			}
			If ('tFound) {
				Set pBatch = ""
				Set tStatus = $$$ERROR($$$EnsRecordMapErrBatchHeaderNotFound,$classname($this))
				Quit
			}
		}
		Else {
			Set pBatch = ..%New()
			Set pLookAhead = $get(pLookAhead)
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Check for the Batch Trailer. The RecordMap batch services will invoke this method on every
/// record in a file after the Batch Header is found. 
ClassMethod GetBatchTrailer(pIOStream As %IO.DeviceStream, pTimeout As %Numeric = -1, Output pFound As %Boolean, pBatch As EnsLib.RecordMap.SimpleBatch, ByRef pLookAhead As %String) As %Status
{
	Try {
		Set tStatus = $$$OK
		Set tTerm = ..GetTrailerTerm()
		Set tTrailerLen = $length(..#BatchTrailer) + $length(tTerm)
		If tTrailerLen {
			Set tTimeout = pTimeout
			Set tReadLen = $length(..#BatchTrailer) + $length(tTerm)
			Set tData = pIOStream.Read(tReadLen, .tTimeout, .tStatus)
			If $$$ISERR(tStatus) Quit
			If tTimeout {
				Set tStatus = $$$ERROR($$$EnsErrTCPReadTimeoutExpired, pTimeout, tReadLen)
				Quit
			}
			If tData = (..#BatchTrailer _ tTerm) {
				Set pFound = 1
				Set pLookAhead = ""
				Quit
			}
			Else {
				Set pFound = 0
				Set pLookAhead = tData
				Quit
			}

		}
		Else {
			Set pFound = pIOStream.AtEnd
			Set pLookAhead = $get(pLookAhead)
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Write out the Batch Header for the current Batch object
Method PutBatchHeader(pIOStream As %IO.DeviceStream) As %Status
{
	Try {
		Set tStatus = $$$OK
		If ..BatchHeader '= "" {
			Do pIOStream.Write(..BatchHeader,0, .tStatus)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Write out the Batch Trailer for the current Batch object
Method PutBatchTrailer(pIOStream As %IO.DeviceStream) As %Status
{
	Try {
		Set tStatus = $$$OK
		If ..BatchTrailer '= "" {
			Do pIOStream.Write(..BatchTrailer,, .tStatus)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

ClassMethod GetHeaderTerm() As %String
{
	Quit ..GetTerm("Header")
}

ClassMethod GetTrailerTerm() As %String
{
	Quit ..GetTerm("Trailer")
}

ClassMethod GetTerm(pName As %String) As %String [ Private ]
{
	Set tTerm = ""
	If $parameter(,pName_"Term") '= "" {
		Set tCharTerm = ##class(EnsLib.RecordMap.Generator).getLogicalChars($parameter(,pName_"Term"))
		If tCharTerm '= "" {
			Set tTerm = ##class(EnsLib.RecordMap.RecordMap).getChars(tCharTerm)
		}
	}
	Quit tTerm
}

}
