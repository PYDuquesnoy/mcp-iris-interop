/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a tModel in a UDDI registry
Class EnsLib.UDDI.DeleteTModel Extends EnsLib.UDDI.Deleter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Collection of TModels to update the UDDI registry with
Property TModelKeys As list Of EnsLib.UDDI.uddi.tModelKey;

/// Transmits the DeleteTModel request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection) As %Status
{
	#dim tClient As %RegisteredObject

	$$$PROLOGUE
	
	#; Create a the web client instance
    $$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)

	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Do tClient.deletetModel(pConnection.AuthInfo,..TModelKeys)
 
	$$$EPILOGUE
}

/// Helper method to add a TModelKey
Method AddTModelKey(pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	Do ..TModelKeys.Insert(pTModelKey)
	Quit $$$OK
}

/// Test the functionality by deleteing a specifc TModel
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status
	#dim tDelete As EnsLib.UDDI.DeleteTModel
	
	$$$PROLOGUE
		
	Write !!!,"Test Delete TModel",!!
		
	#; Want to delete TModels
	$$$NEW(tDelete,"EnsLib.UDDI.DeleteTModel")
	
	Set tSC=tDelete.AddTModelKey(pTModelKey)
	
	#; Now delete
	Set tSC=tDelete.Send(pConnection)
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

}
