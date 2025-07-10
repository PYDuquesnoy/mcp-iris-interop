/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDP.InboundAdapter Extends (Ens.InboundAdapter, EnsLib.UDP.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SERVICEINPUTCLASS = "Ens.StringContainer";

Parameter SETTINGS = "UDPReceiver,UDPPort,UDPDebugOutputFile";

Property UDPReceiver As %String(MAXLEN = 128) [ InitialExpression = {$System.Util.InstallDirectory() _ "bin/udprecv"} ];

Property UDPPort As %Integer [ InitialExpression = 10000 ];

Property UDPDebugOutputFile As %String;

Property Device As %String(MAXLEN = 128) [ Private ];

Method OnInit() As %Status
{
	#dim eOnInit As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Set ..Device = ..UDPReceiver _ " " _ ..UDPPort
		
		Set tStatus = ..Open(..Device, "RQ", 5) Quit:$$$ISERR(tStatus)
		If (..UDPDebugOutputFile ] "") {
			Open ..UDPDebugOutputFile:"WNS":1

			If '$Test Set tStatus = $$$ERROR($$$GeneralError, "Unable to open debug file:  " _ ..UDPDebugOutputFile) Quit
		}
	}
	Catch eOnInit {
		Set tStatus = eOnInit.AsStatus()
	}
	
	Quit tStatus
}

Method OnTearDown() As %Status
{
	#dim eOnTearDown As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Set tStatus = ..Close(..Device)
		
		Close ..UDPDebugOutputFile
	}
	Catch eOnTearDown {
		Set tStatus = eOnTearDown.AsStatus()
	}
	
	Quit tStatus
}

Method OnTask() As %Status
{
	#dim eOnTask As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Set tUDPLine	= ""
		Set tStatus		= ..Receive(..Device, .tUDPLine) Quit:$$$ISERR(tStatus)

		If (tUDPLine = "") {
			Set tStatus = $$$ERROR($$$GeneralError, "Empty UDP message received") Quit
		}

		If (..UDPDebugOutputFile ] "") { Use ..UDPDebugOutputFile Write tUDPLine,! Use ..Device }
		
		Set tInput = ##class(Ens.StringContainer).%New()
		Set tInput.StringValue = tUDPLine
		
		Set tStatus = ..BusinessHost.ProcessInput(tInput)
	}
	Catch eOnTask {
		Set tStatus = eOnTask.AsStatus()
	}
	
	Quit tStatus
}

}
