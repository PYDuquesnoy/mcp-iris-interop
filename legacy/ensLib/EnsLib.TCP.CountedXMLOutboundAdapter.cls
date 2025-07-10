/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Adapter that sends out XML exported objects out as a counted block of bytes over a TCP connection and imports a response object
Class EnsLib.TCP.CountedXMLOutboundAdapter Extends (EnsLib.TCP.CountedOutboundAdapter, Ens.Util.XML.Reader) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/* override default Setting inherited from base class) */
/// Text Charset to use to decode incoming data and encode outgoing data
Property Charset As %String [ InitialExpression = "Auto" ];

Method SendMessageXMLObj(pRequest As %RegisteredObject, Output pResponse As %RegisteredObject, pResponseClassname As %String) As %Status
{
	Kill pResponse  Set pResponse=$$$NULLOREF
	$$$ASSERT($IsObject(pRequest)&&pRequest.%Extends("Ens.Request"))
	Set $ZT="Trap",tSC=$$$OK
	Do {
	 	Set tStream = ##class(%GlobalCharacterStream).%New("") $$$ASSERT($IsObject(tStream))
		Set tSC = pRequest.XMLExportToStream(tStream)  Quit:$$$ISERR(tSC)

		$$$sysTRACE("Request content (size="_tStream.Size_")")
		Set tSC=..SendMessageStream(tStream,.tOutStream)  Quit:$$$ISERR(tSC)

		If ..GetReply {
			Set pResponseClassname=$G(pResponseClassname,pRequest.%GetParameter("RESPONSECLASSNAME"))
			If ""'=pResponseClassname {
				$$$sysTRACE("Got Response Data (size="_tOutStream.Size_"), looking for response of type "_pResponseClassname)
				If "auto"'=$ZCVT(..Charset,"L") {
					#; We translated it when we read it in; now change the header to say it's Unicode
					Set tOutStream = ##class(Ens.Util.XML.Reader).ChangeXMLStreamEncoding(tOutStream,"")
				}	
				Set tSC = ..ObjectFromStream(.pResponse,tOutStream,pResponseClassname)
			} Else {
				Set pResponse=tOutStream ; if no response class given, return the stream and let the caller sort it out
			}
		}
	} While 0
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

}
