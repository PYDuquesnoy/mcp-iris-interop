/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a Service in a UDDI registry
Class EnsLib.UDDI.SaveService Extends EnsLib.UDDI.Saver [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is a collection of business service objects to be added or updated
Property BusinessServices As list Of EnsLib.UDDI.uddi.businessService;

/// Transmits the SaveService request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection, Output pBusinessServices As %ListOfObjects(ELEMENTYPE="EnsLib.UDDI.uddi.businessService"), Output pTruncated As %Boolean) As %Status
{
	#dim tClient As %RegisteredObject
	#dim tBusinessServices As %ListOfObjects
	
	$$$PROLOGUE
	
	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)

	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Set tBusinessServices=..BusinessServices
	
	Do tClient.saveservice(pConnection.AuthInfo,.tBusinessServices,.pTruncated)
	Set ..BusinessServices=tBusinessServices

	#; Assign the outputs
	Set pBusinessServices=..BusinessServices

	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		
	$$$EPILOGUE
}

/// Add a BusinessService
Method AddBusinessService(pBusinessService As EnsLib.UDDI.uddi.businessService) As %Status
{
	Do ..BusinessServices.Insert(pBusinessService)
	Quit $$$OK
}

/// Test the functionality of SaveService, UDDI registry will assign the service key
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pBusinessKey As EnsLib.UDDI.uddi.businessKey, Output pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	#dim tSC As %Status
	#dim tTruncated As %Boolean
	#dim tSave As EnsLib.UDDI.SaveService
	#dim tBusinessService As EnsLib.UDDI.uddi.businessService
	#dim tBusinessServices As %ListOfObjects
	
	$$$PROLOGUE

	Write !!,"Test Save Service",!!
	
	#; Want to save a Service
	$$$NEW(tSave,"EnsLib.UDDI.SaveService")
	
	#; Create an instance of BusinessService
	$$$NEW(tBusinessService,"EnsLib.UDDI.uddi.businessService")
	
	#; MUST Set the BusinessKey to that was acquired when we saved a business above
	Set tBusinessService.businessKey=pBusinessKey
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign key 
	Set tBusinessService.serviceKey=$c(0)
	
	#; Set the service name
	Set tSC=..addNameToList(tBusinessService.name,"Almanac Service")
	If $$$ISERR(tSC) Quit
	
	#; Add a description
	Set tSC=..addDescriptionToList(tBusinessService.description,"Dire Predictions Incorporated Almanac Service")
	If $$$ISERR(tSC) Quit
	
	#; Add this to the business services to save/update
	Set tSC=tSave.AddBusinessService(tBusinessService)
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tSave.Send(pConnection,.tBusinessServices,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The Save Service operation was truncated"
	}
	
	Do ##class(EnsLib.UDDI.GetServiceDetail).DisplayBusinessServices(tBusinessServices)
	
	#; Retrieve the service key and assign the output
	Set pServiceKey=tBusinessServices.GetAt(1).serviceKey
	
	Write !,"Test Save Service - OK"
		
	$$$EPILOGUE
}

}
