/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDP.Common Extends %RegisteredObject [ System = 4 ]
{

ClassMethod Open(pDevice As %String = "", pParameters As %String = "", pTimeout As %Integer = 5) As %Status
{
	#dim eOpen As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Open pDevice:(pParameters):pTimeout
		If ('$Test) Set tStatus = $$$ERROR($$$GeneralError, "Timed out while opening device:  " _ pDevice) Quit
		
		Use pDevice
	}
	Catch eOpen {
		Set tStatus = eOpen.AsStatus()
	}

	Quit tStatus
}

ClassMethod Close(pDevice As %String = "") As %Status
{
	#dim eClose As %Exception.AbstractException
	Set tStatus = $$$OK
	
	Try {
		Use pDevice Write $Char(3),!
		
		Close pDevice
	}
	Catch eClose {
		Set tStatus = eClose.AsStatus()
	}

	Quit tStatus
}

ClassMethod Send(pDevice As %String = "", pBuffer As %Stream.Object = {$$$NULLOREF}) As %Status
{
	#dim eSend As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Do pBuffer.Rewind()

		Use pDevice Do pBuffer.OutputToDevice()
		Use pDevice Write !
	}
	Catch eSend {
		Set tStatus = eSend.AsStatus()
	}

	Quit tStatus
}

ClassMethod Receive(pDevice As %String = "", Output pValue As %String = "", pTimeout As %Integer = 5) As %Status
{
	#dim eReceive As %Exception.AbstractException
	
	Set tStatus = $$$OK
	
	Try {
		Use pDevice
		
		Read pValue:pTimeout
		
		If ('$Test) Set tStatus = $$$ERROR($$$GeneralError, "Timed out while waiting for a message from:  " _ pDevice) Quit
	}
	Catch eReceive {
		Set pValue = ""

		Set tStatus = eReceive.AsStatus()
	}
	
	Quit tStatus
}

}
