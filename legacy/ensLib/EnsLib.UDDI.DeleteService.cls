/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a Service in a UDDI registry
Class EnsLib.UDDI.DeleteService Extends EnsLib.UDDI.Deleter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Collection of Services to update the UDDI registry with
Property ServiceKeys As list Of EnsLib.UDDI.uddi.serviceKey;

/// Transmits the DeleteService request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection) As %Status
{
	#dim tClient As %RegisteredObject
	
	$$$PROLOGUE  
	
	#; Create a the web client instance
    $$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)
	
	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Do tClient.deleteservice(pConnection.AuthInfo,..ServiceKeys)

	$$$EPILOGUE
}

/// Helper method to add a ServiceKey
Method AddServiceKey(pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	Do ..ServiceKeys.Insert(pServiceKey)
	Quit $$$OK
}

/// Test the functionality by deleteing a specifc Service
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	#dim tSC As %Status
	#dim tDelete As EnsLib.UDDI.DeleteService
	
	$$$PROLOGUE
		
	Write !!!,"Test Delete Service",!!
		
	#; Want to delete Services
	$$$NEW(tDelete,"EnsLib.UDDI.DeleteService")
	
	Set tSC=tDelete.AddServiceKey(pServiceKey)
	
	#; Now delete
	Set tSC=tDelete.Send(pConnection)
	If $$$ISERR(tSC) Quit
	
	Write !,"Test Delete Service - OK"
		
	$$$EPILOGUE
}

}
