/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a Business in a UDDI registry
Class EnsLib.UDDI.DeleteBusiness Extends EnsLib.UDDI.Deleter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Collection of Businesss to update the UDDI registry with
Property BusinessKeys As list Of EnsLib.UDDI.uddi.businessKey;

/// Transmits the DeleteBusiness request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection) As %Status
{
	#dim tClient As %RegisteredObject
	
	$$$PROLOGUE 
	
	#; Create a the web client instance
    $$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)
	
	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Do tClient.deletebusiness(pConnection.AuthInfo,..BusinessKeys)

	$$$EPILOGUE
}

/// Helper method to add a BusinessKey
Method AddBusinessKey(pBusinessKey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	Do ..BusinessKeys.Insert(pBusinessKey)
	Quit $$$OK
}

/// Test the functionality by deleteing a specifc Business
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pBusinessKey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	#dim tSC As %Status
	#dim tDelete As EnsLib.UDDI.DeleteBusiness
	
	$$$PROLOGUE
		
	Write !!!,"Test Delete Business",!!
		
	#; Want to delete Businesss
	$$$NEW(tDelete,"EnsLib.UDDI.DeleteBusiness")
	
	#; Add the business key to delete
	Set tSC=tDelete.AddBusinessKey(pBusinessKey) 
	If $$$ISERR(tSC) Quit
	
	#; Now delete
	Set tSC=tDelete.Send(pConnection)
	If $$$ISERR(tSC) Quit
		
	Write !,"Test Delete Business - OK"
	
	$$$EPILOGUE
}

}
