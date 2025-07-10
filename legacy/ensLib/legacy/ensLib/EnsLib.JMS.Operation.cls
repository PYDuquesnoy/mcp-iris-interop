/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMS.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.JMS.OutboundAdapter";

Parameter INVOCATION = "Queue";

XData MessageMap
{
<MapItems>
<MapItem MessageType="EnsLib.JMS.Message"> 
<Method>OnJMSMessageRequest</Method>
</MapItem>
</MapItems>
}

Method OnJMSMessageRequest(pRequest As EnsLib.JMS.Message, Output pResponse As EnsLib.JMS.Response) As %Status
{
	try {
		set tSC = ..Adapter.GetNewMessage(.message) quit:$$$ISERR(tSC)
		;
		do message.setText(pRequest.text)
		do message.setType(pRequest.type)
		
		if (pRequest.type = "BytesMessage") {
			set bytes = ##class(%Net.Remote.Object).%New(..Adapter.%JavaGateway,"byte[*]",pRequest.bytes)
			do message.setBytes(bytes)
		}
		
		set key="" for  {
			set key = pRequest.getNextPropertyKey(key) quit:key=""
			set value = pRequest.getProperty(key)
			set type = pRequest.getPropertyType(key)
			do $method(message,"set"_type_"Property",key,value)
		}
		;
		set tSC = ..Adapter.SendMessage(message) quit:$$$ISERR(tSC)
		;
		set pResponse = ##class(EnsLib.JMS.Response).%New()
		set pResponse.messageId = message.getMessageId()
		;
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
