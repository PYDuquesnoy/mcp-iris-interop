/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements Push Notification Utilities [ Internal ]
Class %Net.PushNotifications.Util
{

/// Helper method to double up quotes in a string
ClassMethod ConvertArrayToJSON(ByRef pArray) As %String [ Internal ]
{
	#dim tOutput As %String = ""
	#dim tSubscript As %String = ""
	
	For {
		Set tSubscript = $ORDER(pArray(tSubscript))
		Quit:tSubscript=""
		
		Set:tOutput'="" tOutput = tOutput _ ","
		
		Set tOutput = tOutput _ ..Quote(tSubscript) _ ": "
		
		If $GET(pArray(tSubscript))'="" {
			#dim tValue = pArray(tSubscript)
			
			If $LISTVALID(tValue) {
				#dim tIndex As %Integer
				
				// $LIST .. aka an array
				
				// NOTE: This only handles an array of scalar values
				Set tOutput = tOutput _ "[ "
				For tIndex = 1:1:$LISTLENGTH(tValue) {
					Set:tIndex>1 tOutput = tOutput _ ", "
					Set tOutput = tOutput _ ..Quote($LISTGET(tValue,tIndex),0)
				}
				
				Set tOutput = tOutput _ " ]"
			} Else {
				// Simple string
				Set tOutput = tOutput _ ..Quote(tValue,0)
			}
		} Else {
			// Child elements
			#dim tTemp
			
			Kill tTemp
			Merge tTemp = pArray(tSubscript)
			Set tOutput = tOutput _ ..ConvertArrayToJSON(.tTemp)
		}
	}
	
	Set tOutput = "{" _ tOutput _ "}"
	
	Quit tOutput
}

/// Helper method to double up quotes in a string
ClassMethod Quote(pInput As %String, pForce As %Boolean = 1) As %String [ Internal ]
{
	#dim tOutput As %String = """"
	#dim tIndex As %Integer
	
	If ('pForce) && (pInput?1.N) {
		// Don't quote numbers if not forced to
		Quit pInput
	}
	
	For tIndex = 1:1:$L(pInput) {
		#dim tChar As %String = $E(pInput,tIndex)
		Set tOutput = tOutput _ tChar
		
		// Double up any quotes
		If tChar="""" Set tOutput = tOutput _ """"
	}
	
	Set tOutput = tOutput _ """"
	
	Quit tOutput
}

/// Helper method to convert a $HOROLOG into UNIX time (seconds since 00:00 Jan 1, 1970 UTC)
ClassMethod TimeStampToUnix(pTimestamp As %TimeStamp, pIsUTC As %Boolean) As %Integer [ Internal ]
{
#define UNIXEPOCH 47117
#define SECPERDAY 86400
	#dim tH As %String = $ZDTH(pTimestamp,3)
	#dim tUTCH As %String = $S(pIsUTC:tH,1:$system.Util.LocalWithZTIMEZONEtoUTC(tH))
	
	Quit ((($P(tUTCH,",")-$$$UNIXEPOCH)*$$$SECPERDAY)+$P(tUTCH,",",2))
}

/// Helper to compute the delta between two timestamps
ClassMethod TimeStampDelta(pTimestamp As %TimeStamp, pEpoch As %TimeStamp = "", pIsUTC As %Boolean) As %Integer [ Internal ]
{
	If pEpoch="" {
		// If no epoch is specified, use "now"
		Set pEpoch = $ZDT($S(pIsUTC:$system.Util.LocalWithZTIMEZONEtoUTC($H),1:$H),3)
	}
	
	#dim tTS1 As %Integer = ..TimeStampToUnix(pTimestamp,pIsUTC)
	#dim tTS2 As %Integer = ..TimeStampToUnix(pEpoch,pIsUTC)
	
	Quit tTS1-tTS2
}

/// Helper class to generate a UTC timestamp with optional offset
ClassMethod UTCTimeStamp(pDelta As %Integer = 0, pHorolog As %String = {$H}, pIsUTC As %Boolean = 0) As %String [ Internal ]
{
	If pDelta '= 0 {
		// Recompute the $HOROLOG value to include the delta
		Set pHorolog = ($P(pHorolog,",",1) + (pDelta / 86400))
						_ "," _
					   ($P(pHorolog,",",2) + (pDelta # 86400))
	}
	
	Quit $ZDT($S(pIsUTC:pHorolog,1:$system.Util.LocalWithZTIMEZONEtoUTC(pHorolog)),3)
}

}
