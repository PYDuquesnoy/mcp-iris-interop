/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Service to consume data from files using the RecordMap parsing framework.
Class EnsLib.RecordMap.Service.FileService Extends EnsLib.RecordMap.Service.Standard [ System = 4 ]
{

Parameter SETTINGS = "FatalErrors,SkipRecordParsingErrors";

/// An error saving an individual Record, such as a validation error, will be treated as fatal
/// and end the processing of the message when the setting is "Any". <br>
/// If "ParseOnly" is selected, errors when saving individual Records will not be treated as fatal,
/// and parsing of the message will continue after logging an error log and skipping the errored record.<br>
/// If AlertOnError is enabled, an alert will be sent for a save error when "ParseOnly" is selected.<br>
/// The default is "Any".<br>
Property FatalErrors As %String(VALUELIST = ",Any,ParseOnly") [ InitialExpression = "Any" ];

/// By default errors parsing data into a record such as <EnsRecordMap>ErrQuoteCharMismatch
/// will be treated as fatal and end the processing of the message. <br>
/// These parsing errors are those detected before the record is saved. <br>
/// If this setting is enabled, errors when parsing the data into a record before saving is attempted
/// will not be treated as fatal, no attempt will be made to try to save the record
/// and parsing of the message will continue. <br>
/// Note the record data may become out of alignment. <br>
/// If this setting is enabled and AlertOnError is enabled, an alert will be sent when such an
/// error is encountered. <br>
Property SkipRecordParsingErrors As %Boolean [ InitialExpression = 0 ];

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

/// Parse the incoming file and send the resulting objects to the targets in TargetConfigNames.
Method OnProcessInput(pInput As %Stream.Object, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tLookAhead = ""
		Set tIOStream = ##class(EnsLib.RecordMap.Service.FileServiceStream).%New(pInput)
		Set tIOStream.Name = ..GetFileName(pInput)

		If ..HeaderCount {
			Set tStatus = ..ReadHeaders(tIOStream)
			If $$$ISERR(tStatus) Quit
		}

		While 'tIOStream.AtEnd {
			Set tPosition = tIOStream.Position
			Set tSkipDueToGetObjectError = 0
			Set tStatus = ..GetObject(tIOStream, .tObject,,.tLookAhead)
			#; If this returned an error we will check below if it is one we are accepting for skipping
			If (tPosition=tIOStream.Position) Quit

			/*	Save the object here to check for errors prior to sending.
				The object is always saved when the corresponding message header
				is created prior to sending.
			*/
			If $$$ISOK(tStatus) {
				Set tStatus = tObject.%Save()
			} ElseIf (('..SkipRecordParsingErrors)||($SYSTEM.Status.GetErrorCodes(tStatus)'["<EnsRecordMap>")) {
				Quit
			} Else {
				Set tSkipDueToGetObjectError = 1
			}
			/*	tStatus will either be OK or 
				a Save validation error or
				a GetObject() fall through <EnsRecordMap> error with ..SkipRecordParsingErrors enabled
			*/
			If $$$ISERR(tStatus) {
				If ((..FatalErrors = "ParseOnly") || tSkipDueToGetObjectError) {
					#; Do not associate error with any prior session
					If '..UseSingleSession Set ..%SessionId = "", $$$JobSessionId = ""
					#dim tErrorText = $$$FormatText($$$Text("@IgnoreRecordSaveErrorPlace@Ignoring RecordMap save error for Record at stream position %1 in stream '%2'; error: '%3'","EnsRecordMap"),tPosition,tIOStream.Name,$system.Status.GetErrorText(tStatus))
					$$$LOGERROR(tErrorText)
					If ..AlertOnError Do ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,tErrorText)))
					#; Reset tStatus since if last record in stream we will not exit with an error.
					Set tStatus = $$$OK
					Continue
				}
				Quit
			}

			Set tStatus = ..SendRequest(tObject, '..SynchronousSend)
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit

		If 'tIOStream.AtEnd {
			$$$LOGWARNING($$$FormatText($$$Text("Failed to advance record stream. Stopped reading file '%1' at position %2, not at end.","Ensemble"),tIOStream.Name,tIOStream.Position))
		}
	}
	Catch ex {
		Set tStatus = $$$EnsSystemError
	}
	If $system.Status.Equals(tStatus,$$$EnsRecordMapErrStreamAtEnd) {
		Set tStatus = $$$OK
	}
	If $get(tLookAhead) '= "" {
		$$$LOGINFO("Discarding trailing characters: '"_tLookAhead_"'")
	}
	Quit tStatus
}

}
