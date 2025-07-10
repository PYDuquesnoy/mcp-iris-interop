/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Utility functions for pipe functionality
Class Ens.Util.Pipe Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod RunCommand(pCmd As %String, pMode As %String = "", pCharset As %String = "Default", pInput = "", ByRef pOutput = "", pTimeout As %Integer = -1) As %Status
{
	Set tSC = $$$OK,$ZT="Trap",tIO=$IO,tZU68comma40=$ZU(68,40,1)
	do {
		
		If (pInput'="") || $IsObject(pInput) {
			Set:pMode="" pMode = pMode _ "W"
		} Else {
#if $$$isWINDOWS
			Set pCmd = pCmd _ " < nul:"
#elseif $$$isUNIX
			Set pCmd = pCmd _ " < /dev/null"
#elseif $$$isVMS
			// ???
#endif
		}

		Set tMode = "QR"_pMode
		If $Case($ZCVT(pCharset,"L"),"":0,"default":0,"native":0,:1) {
			// Specify the translation table if a charset was given
			If $ZCVT(pCharset,"L") = "binary" {
				Set tTable = "RAW"
			} Else {
				Set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
			}
			Set tMode = tMode _ "K\" _ tTable _ "\"
		}

		If '$IsObject(pOutput) Set pOutput = ##class(%GlobalCharacterStream).%New()
		
		$$$TRACE("Running command: " _ pCmd)
		
		Open pCmd:tMode:1
		If '$TEST {
			// Failed to open the pipe
			Set tSC=$$$ERROR($$$GeneralError,pCmd)
			Quit
		}
		
		Use pCmd
		
		// First, write any input to the pipe
		If pMode["W" {
			If $IsObject(pInput) {
				Do pInput.OutputToDevice()
			} Else {
				Write pInput
			}
		}

		// Next, we read back the output, a line at a time
		do {
			Use pCmd
			If pTimeout'<0 {
				Read tLine:pTimeout
				If '$TEST {
					$$$TRACE("Timed out: "_pTimeout)
					Quit
				}
			} Else {
				Read tLine
			}
			
			$$$LOGINFO("Read: " _ tLine)
			
			If $ZEOF'=0 Quit
			
			Do pOutput.WriteLine(tLine)
			
		} while ($ZEOF=0)
		
		Do pOutput.Rewind()
	
	} while (0)
	
Exit
	// Clean up
	Use tIO
	Close pCmd
	Do $ZU(68,40,tZU68comma40)
	
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod CheckTimer(pTimer As %String, ByRef pSeconds As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pSeconds = 0
	
	// Is this a duration?
	If "Pp"[$E(pTimer,1) {
		Set tSC = ##class(Ens.Util.Time).Duration(pTimer,.pSeconds)
	} Else {
		Set tSC = ##class(Ens.Util.Time).SecondsUntil(pTimer,.pSeconds)
	}
	
	Quit tSC
}

}
