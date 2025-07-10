/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.TCP.Framed.PassthroughOperation Extends Ens.BusinessOperation [ ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.TCP.FramedOutboundAdapter";

/// Comma separated list of control characters that indicate
/// message received OK.
/// This is compared to response if present
/// Can be Decimal or Hex if have preceding 'x'
/// For example 6 or x06
Property AckOK As %String [ InitialExpression = "6" ];

/// Used to store actual Acknowledgement OK characters
Property AckOKAsChars As %String [ Transient ];

/// Comma separated list of control characters that indicate
/// message not received OK
/// This is compared to response if present
/// Can be Decimal or Hex if have preceding 'x'
/// For example 21 or x15
Property AckNotOK As %String [ InitialExpression = "21" ];

/// Used to store actual Acknowledgement Not OK characters
Property AckNotOKAsChars As %String [ Transient ];

Parameter SETTINGS = "AckOK:Additional,AckNotOK:Additional";

Method OnMessage(pRequest As Ens.StreamContainer, Output pResponse As Ens.StreamContainer) As %Status
{
	Quit:'$IsObject(pRequest.Stream) $$$ERROR($$$EnsErrGeneral,"No Stream contained in StreamContainer Request")
	Set pResponse = $$$NULLOREF
	
	Set tSC=..Adapter.SendMessageStream(pRequest.Stream,.tReplyStream)
	Quit:$$$ISERR(tSC) tSC
	
	If ..Adapter.GetReply {
		Try {
			Set tReply=tReplyStream.Read()
			If (..AckOKAsChars'=""),(tReply=..AckOKAsChars) {
				Set tSC = $$$OK
			} ElseIf (..AckNotOKAsChars'=""),(tReply=..AckNotOKAsChars) {
				Set tSC=$$$ERROR($$$EnsErrGeneral,"Remote acknowledgement not OK:"_$E(tReply,1,1000))
			}
			Set pResponse = ##class(Ens.StreamContainer).%New(tReplyStream)
		} Catch {
			Set tSC=$$$ERROR($$$EnsErrGeneral,"Remote acknowledgement not received")
		}
	}
	
	Quit tSC
}

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	Try {
		#; No need to convert if not getting a reply
		Quit:('..Adapter.GetReply)
		#; Convert ACK/NACK settings to characters
		Set ..AckOKAsChars = ..Adapter.AsciiOrHexAsChars(..AckOK)
		Set ..AckNotOKAsChars = ..Adapter.AsciiOrHexAsChars(..AckNotOK)
	} Catch {}
	Quit ##super()
}

}
