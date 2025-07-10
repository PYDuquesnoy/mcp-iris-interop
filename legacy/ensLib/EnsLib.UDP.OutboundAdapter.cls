/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDP.OutboundAdapter Extends (Ens.OutboundAdapter, EnsLib.UDP.Common) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter SETTINGS = "UDPSender,UDPHost,UDPPort,UDPDebugOutputFile";

Property UDPSender As %String(MAXLEN = 128) [ InitialExpression = {$System.Util.InstallDirectory() _ "bin/udpsend"} ];

Property UDPHost As %String [ InitialExpression = "127.0.0.1" ];

Property UDPPort As %Integer [ InitialExpression = 10000 ];

Property UDPDebugOutputFile As %String;

Property Device As %String(MAXLEN = 128) [ Private ];

Method OnInit() As %Status
{
	#dim eOnInit As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Set ..Device = ..UDPSender _ " " _ ..UDPHost _ " " _ ..UDPPort
		Set tStatus = ..Open(..Device, "WQ", 5)
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

Method SendStream(pBuffer As %Stream.Object) As %Status
{
	#dim eSendStream As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Do pBuffer.Rewind()
		
		Set tStatus = ..Send(..Device, pBuffer)

		If (..UDPDebugOutputFile ] "") { Use ..UDPDebugOutputFile Do pBuffer.Rewind(), pBuffer.OutputToDevice() Write ! Use ..Device }
	}
	Catch eSendStream {
		Set tStatus = eSendStream.AsStatus()
	}
	
	Quit tStatus
}

}
