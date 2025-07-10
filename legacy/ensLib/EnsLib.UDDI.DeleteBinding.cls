/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a Binding in a UDDI registry
Class EnsLib.UDDI.DeleteBinding Extends EnsLib.UDDI.Deleter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Collection of Bindings to update the UDDI registry with
Property BindingKeys As list Of EnsLib.UDDI.uddi.bindingKey;

/// Transmits the DeleteBinding request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection) As %Status
{
	#dim tClient As %RegisteredObject

	$$$PROLOGUE
	 
	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)

	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Do tClient.deletebinding(pConnection.AuthInfo,..BindingKeys)
	 
	$$$EPILOGUE
}

/// Helper method to add a BindingKey
Method AddBindingKey(pBindingKey As EnsLib.UDDI.uddi.bindingKey) As %Status
{
	Do ..BindingKeys.Insert(pBindingKey)
	Quit $$$OK
}

/// Test the functionality by deleteing a specifc Binding
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pBindingKey As EnsLib.UDDI.uddi.bindingKey) As %Status
{
	#dim tSC As %Status
	#dim tDelete As EnsLib.UDDI.DeleteBinding
	
	$$$PROLOGUE
		
	Write !!,"Test Delete Binding",!!
			
	#; Want to delete Bindings
	$$$NEW(tDelete,"EnsLib.UDDI.DeleteBinding")
	
	Set tSC=tDelete.AddBindingKey(pBindingKey)
	
	#; Now delete
	Set tSC=tDelete.Send(pConnection)
	If $$$ISERR(tSC) Quit
	

	Write !,"Test Delete Binding - OK"
		
	$$$EPILOGUE
}

}
