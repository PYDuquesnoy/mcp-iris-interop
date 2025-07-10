/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMS.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.JMS.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ISINBOUND As BOOLEAN = 1;

Method OnTask() As %Status
{
	set tSC = $$$OK
	try {
		set tSC = ..CheckGatewayConnection() quit:$$$ISERR(tSC)
		set errorText = ..%JavaGatewayProxy.ReceiveMessage(..CallInterval)
		if errorText'="" set tSC = $$$ERROR($$$EnsErrGeneral,"JMS call ReceiveMessage() failed with status: "_errorText) quit
		set message = ..%JavaGatewayProxy.GetLastReceivedMessage()
		if $IsObject(message) {
			$$$TRACE("JMS message '"_message.getMessageId()_"' received")
			set tSC = ..BusinessHost.ProcessInput(message,.response) quit:$$$ISERR(tSC)
			if $isObject($g(response)) $$$LOGWARNING("Response object ignored")
		} else {
			$$$SetHostMonitor(..BusinessHost.%ConfigName,$$$eMonitorStatus,"OK")
		}
	} catch ex {
		set tSC = ex.AsStatus()
		do ..CheckGatewayDisconnection()
	}
	quit tSC
}

}
