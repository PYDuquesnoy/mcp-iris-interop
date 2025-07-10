/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMS.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.JMS.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ISINBOUND As BOOLEAN = 0;

Method SendMessage(pMessage As %Net.Remote.Proxy) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..CheckGatewayConnection() quit:$$$ISERR(tSC)
		set errorText = ..%JavaGatewayProxy.SendMessage(pMessage)
		if errorText'="" set tSC = $$$ERROR($$$EnsErrGeneral,"JMS call SendMessage() failed with status: "_errorText) quit
		$$$TRACE("JMS message sent successfully as '"_pMessage.getMessageId()_"'")
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

Method GetNewMessage(Output newMessage As %Net.Remote.Proxy) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..CheckGatewayConnection() quit:$$$ISERR(tSC)
		set newMessage = ##class(%Net.Remote.Object).%New(..%JavaGateway,"com.intersystems.enslib.jms.Message")
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

}
