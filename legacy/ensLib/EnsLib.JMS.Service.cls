/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMS.Service Extends Ens.BusinessService
{

Parameter ADAPTER = "EnsLib.JMS.InboundAdapter";

/// Configuration item(s) to which to send messages
Property TargetConfigNames As %String(MAXLEN = 2000);

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnProcessInput(pMessage As %Net.Remote.Proxy, Output pOutput As %RegisteredObject) As %Status
{
	set tSC = $$$OK
	try {
		set message = ##class(EnsLib.JMS.Message).%New()
		set message.type = pMessage.getType()
		set message.messageId = pMessage.getMessageId()
		
		if message.type = "TextMessage" {
			set message.text = pMessage.getText()	
		} elseif message.type = "BytesMessage" {
			set message.bytes = pMessage.getBytes().%getall()
			if (pMessage.getTextLength() < 3641144) {
				set message.text = pMessage.getText()	
			}
		}
		
		set keys = pMessage.getPropertyKeys()
		for i=1:1:keys.size() {
			set key = keys.get(i-1)
			set value = pMessage.getProperty(key)
			set type = pMessage.getPropertyType(key)
			do message.setProperty(key,value,type)
		}
		;
		for i=1:1:$l(..TargetConfigNames,",") {
			set oneTarget = $zstrip($p(..TargetConfigNames,",",i),"<>W")  continue:oneTarget=""
			set tSC1 = ..SendRequestAsync(oneTarget,message) set:$$$ISERR(tSC1) tSC = $$$ADDSC(tSC,tSC1)
		}
		;
	} catch ex {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
