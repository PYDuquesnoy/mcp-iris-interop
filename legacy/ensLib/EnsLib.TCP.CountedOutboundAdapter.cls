/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Adapter that sends out a counted block of bytes over a TCP connection and receives a response block
Class EnsLib.TCP.CountedOutboundAdapter Extends (EnsLib.TCP.OutboundAdapter, EnsLib.TCP.CountedCommon) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Read out any data in the input buffer before sending output. This ensures that any reply received corresponds to the sent message, and if not looking for replies that the input buffer does not fill up with unexpected junk.
Property FlushBeforeSend As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "FlushBeforeSend:Connection";

Method SendMessageStream(pRequestStream As %Stream.Object, ByRef pResponseStream As %CharacterStream = "%GlobalCharacterStream") As %Status
{
	Set tResponseStream=pResponseStream Set:'$IsObject(pResponseStream) pResponseStream=$$$NULLOREF
	Set tSC=..Connect(..ConnectTimeout)
	If $$$ISERR(tSC) { Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectException) ..BusinessHost.Retry=1  Quit tSC }

	If ..FlushBeforeSend {
		#; Clean out any pending replies left over from earlier messages
		Set $ZT="Trap",tJunk0="",tJunkCnt=0  While 1 {
			Read tJunk:0
			Quit:""=tJunk
			Set tJunkCnt=tJunkCnt+$L(tJunk)
			Set:""=tJunk0 tJunk0=tJunk, tJunk=""
		}
		Set $ZT=""
Read
		If tJunkCnt {
			If $$$ISERR(tSC) {
				$$$LOGWARNING("Discarding data found in buffer before counted stream send: "_$E(tJunk0,1,1000)_$S($L(tJunk0)>1000||$L(tJunk):"..."_$E(tJunk,*-100,*),1:""))
				$$$ASAVEIOLOGENTRY(tSC,"after counted stream TCP pre-write Read error on "_..IOAddr,$E(tJunk0,1,30000)_$S($L(tJunk0)>30000||$L(tJunk):"..."_$E(tJunk,*-1000,*),1:""))
			} Else {
				If ..GetReply $$$LOGWARNING("Discarding data found in buffer before counted stream send: "_$E(tJunk0,1,1000)_$S($L(tJunk0)>1000||$L(tJunk):"..."_$E(tJunk,*-100,*),1:""))
				$$$ASAVEIOLOGENTRY(tSC,"after counted stream TCP pre-write Read on "_..IOAddr,$E(tJunk0,1,30000)_$S($L(tJunk0)>30000||$L(tJunk):"..."_$E(tJunk,*-1000,*),1:""))
			}
			Quit:$$$ISERR(tSC)&&..BusinessHost.Retry tSC ; ignore non-disconnect errors : parse errors etc
		}
	}
	Set tCharset=..Charset  Set:$Case($ZCVT(..Charset,"L"),"default":1,"auto":1,:0) tCharset="UTF-8"
	Set:..Connected tSC=..WriteCountedStream(pRequestStream, tCharset)
	If $$$ISERR(tSC) {
		If ..IsWriteError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Counted Write",..IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If '..StayConnected { Do ..Disconnect() }
			Else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		Quit tSC
	}
	If ..GetReply {
		Set tSC=..ReadCountedStream(.tResponseStream, tCharset, ..ResponseTimeout, ..ReadTimeout)
		Set:$IsObject(tResponseStream) pResponseStream=tResponseStream
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Counted Read", ..IOAddr, $$$StatusDisplayString(tSC))
				Set ..BusinessHost.Retry=1 Do ..Disconnect()
			} Else {
				Set:$$$StatusEquals(tSC,$$$EnsErrTCPReadTimeoutExpired,$$$EnsErrTCPReadBlockSizeTimeoutExpired) ..BusinessHost.Retry=1
				Do ..TestConnection() ; calls Disconnect() if connection is down
			}
		}
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	If ..IsReadError(tSC) {
		Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"Counted stream pre-write Read",..IOAddr,$$$StatusDisplayString(tSC))
		Set ..BusinessHost.Retry=1  Do ..Disconnect()
	}
	Goto Read
}

Method SendMessageString(pRequestString As %String, Output pResponseString As %String) As %Status
{
	Set pResponseString=""
	Set tSC=..Connect(..ConnectTimeout)
	If $$$ISERR(tSC) { Set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectException) ..BusinessHost.Retry=1  Quit tSC }

	If ..FlushBeforeSend {
		#; Clean out any pending replies left over from earlier messages
		Set $ZT="Trap",tJunk0="",tJunkCnt=0  While 1 {
			Read tJunk:0
			Quit:""=tJunk
			Set tJunkCnt=tJunkCnt+$L(tJunk)
			Set:""=tJunk0 tJunk0=tJunk, tJunk=""
		}
		Set $ZT=""
Read
		If tJunkCnt {
			If $$$ISERR(tSC) {
				$$$LOGWARNING("Discarding data found in buffer before counted string send: "_$E(tJunk0,1,1000)_$S($L(tJunk0)>1000||$L(tJunk):"..."_$E(tJunk,*-100,*),1:""))
				$$$ASAVEIOLOGENTRY(tSC,"after counted string TCP pre-write Read error on "_..IOAddr,$E(tJunk0,1,30000)_$S($L(tJunk0)>30000||$L(tJunk):"..."_$E(tJunk,*-1000,*),1:""))
			} Else {
				If ..GetReply $$$LOGWARNING("Discarding data found in buffer before counted string send: "_$E(tJunk0,1,1000)_$S($L(tJunk0)>1000||$L(tJunk):"..."_$E(tJunk,*-100,*),1:""))
				$$$ASAVEIOLOGENTRY(tSC,"after counted string TCP pre-write Read on "_..IOAddr,$E(tJunk0,1,30000)_$S($L(tJunk0)>30000||$L(tJunk):"..."_$E(tJunk,*-1000,*),1:""))
			}
			Quit:$$$ISERR(tSC)&&..BusinessHost.Retry tSC ; ignore non-disconnect errors : parse errors etc
		}
	}
	Set tCharset=..Charset  Set:$Case($ZCVT(..Charset,"L"),"default":1,"auto":1,:0) tCharset="UTF-8"
	Set:..Connected tSC=..WriteCountedString(pRequestString, tCharset)
	If $$$ISERR(tSC) {
		If ..IsWriteError(tSC) {
			Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Counted Write",..IOAddr,$$$StatusDisplayString(tSC))
			Set ..BusinessHost.Retry=1  Do ..Disconnect()
		} Else {
			If '..StayConnected { Do ..Disconnect() }
			Else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		Quit tSC
	}
	If ..GetReply {
		Set tSC=..ReadCountedString(.pResponseString, $S("auto"=$ZCVT(..Charset,"L"):"Binary",1:tCharset), ..ResponseTimeout, ..ReadTimeout)
		If $$$ISERR(tSC) {
			If ..IsReadError(tSC) {
				Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Counted Read",..IOAddr,$$$StatusDisplayString(tSC))
				Set ..BusinessHost.Retry=1  Do ..Disconnect()
			} Else {
				Set:$$$StatusEquals(tSC,$$$EnsErrTCPReadTimeoutExpired,$$$EnsErrTCPReadBlockSizeTimeoutExpired) ..BusinessHost.Retry=1
				Do ..TestConnection() ; calls Disconnect() if connection is down
			}
		}
	}
	Do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	Quit tSC
Trap
	Set $ZT="", tSC=$$$SystemError
	If ..IsReadError(tSC) {
		Set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"Counted string pre-write Read",..IOAddr,$$$StatusDisplayString(tSC))
		Set ..BusinessHost.Retry=1  Do ..Disconnect()
	}
	Goto Read
}

}
