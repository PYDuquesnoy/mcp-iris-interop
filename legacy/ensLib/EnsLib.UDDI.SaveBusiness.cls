/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a Business in a UDDI registry
Class EnsLib.UDDI.SaveBusiness Extends EnsLib.UDDI.Saver [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is a collection of business entity objects to update the UDDI registry with
Property BusinessEntities As list Of EnsLib.UDDI.uddi.businessEntity;

/// Transmits the SaveBusiness request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection, Output pBusinessEntities As %ListOfObjects(ELEMENTYPE="EnsLib.UDDI.uddi.businessEntity"), Output pTruncated As %Boolean) As %Status
{
	#dim tClient As %RegisteredObject
	#dim tBusinessEntities As %ListOfObjects
	
	$$$PROLOGUE
	
	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)
	
	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Set tBusinessEntities=..BusinessEntities
	Do tClient.savebusiness(pConnection.AuthInfo,.tBusinessEntities,.pTruncated)
	Set ..BusinessEntities=tBusinessEntities

	#; Assign the outputs
	Set pBusinessEntities=..BusinessEntities

	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		 
	$$$EPILOGUE
}

/// Add a BusinessEntity
Method AddBusinessEntity(pBusinessEntity As EnsLib.UDDI.uddi.businessEntity) As %Status
{
	Do ..BusinessEntities.Insert(pBusinessEntity)
	Quit $$$OK
}

/// Test the functionality by creating and saving a new Business. Note, the registry will assign the key value
/// and in some cases will also assign it's own discovery URL
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, Output pBusinessKey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	#dim tSC As %Status

	#dim tSave As EnsLib.UDDI.SaveBusiness
	#dim tBusinessEntity As EnsLib.UDDI.uddi.businessEntity
	#dim tDiscoveryURLs As EnsLib.UDDI.uddi.DiscoveryUrls
	#dim tContacts As EnsLib.UDDI.uddi.contacts
	#dim tBusinessEntities As %ListOfObjects
	#dim tTruncated As %Boolean
	
	$$$PROLOGUE
	
	Write !!,"Test Save Business",!!
		
	#; What to save a Business
	$$$NEW(tSave,"EnsLib.UDDI.SaveBusiness")
		
	#; Create an instance of a business entity
	$$$NEW(tBusinessEntity,"EnsLib.UDDI.uddi.businessEntity")
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set tBusinessEntity.businessKey=$c(0)
	
	#; Set the business name
	Set tSC=..addNameToList(tBusinessEntity.name,"Dire Predictions Incorporated")
	If $$$ISERR(tSC) Quit
	
	#; Add a description
	Set tSC=..addDescriptionToList(tBusinessEntity.description,"Soothsayers of repute")
	If $$$ISERR(tSC) Quit
	
	$$$NEW(tDiscoveryURLs,"EnsLib.UDDI.uddi.discoveryURLs")
	
	#; Add a discovery URL
	Set tSC=..addDiscoveryURLToList(tDiscoveryURLs.discoveryURL,"Home Page","http://www.direpredictions.com")
	If $$$ISERR(tSC) Quit
	
	Set tBusinessEntity.discoveryURLs=tDiscoveryURLs
	
	#; Add a contact
	$$$NEW(tContacts,"EnsLib.UDDI.uddi.contacts")
	
	Set tSC=..addContactToList(tContacts.contact,"Business","Eliza Doom","555-555-5555")
	If $$$ISERR(tSC) Quit
	
	Set tBusinessEntity.contacts = tContacts
	
	#; Add this to the business entities to save/update
	Set tSC=tSave.AddBusinessEntity(tBusinessEntity)
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tSave.Send(pConnection,.tBusinessEntities,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The SaveBusiness operation was truncated"
	}
	
	Do ##class(EnsLib.UDDI.GetBusinessDetail).DisplayBusinessEntities(tBusinessEntities)
	
	#; Retrieve the key and assign the output
	Set pBusinessKey=tBusinessEntities.GetAt(1).businessKey
	
	Write !,"Test Save Business - OK"
	
	$$$EPILOGUE
}

}
