/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a tModel in a UDDI registry
Class EnsLib.UDDI.SaveTModel Extends EnsLib.UDDI.Saver [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Collection of TModels to update the UDDI registry with
Property TModels As list Of EnsLib.UDDI.uddi.tModel;

/// Transmits the SaveTModel request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection, Output pTModels As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModel"), Output pTruncated As %Boolean) As %Status
{
	#dim tClient As %RegisteredObject
	#dim tUploadRegister As %String
	#dim tModels As %ListOfObjects
	
	$$$PROLOGUE
	  
	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)
	
	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Invoke the service
	Set tModels=..TModels
	Do tClient.savetModel(pConnection.AuthInfo,.tModels,.pTruncated)
	Set ..TModels=tModels

	#; Assign the outputs
	Set pTModels=..TModels

	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		 
	$$$EPILOGUE
}

/// Helper method to add a TModel
Method AddTModel(pTModel As EnsLib.UDDI.uddi.tModel) As %Status
{
	Do ..TModels.Insert(pTModel)
	Quit $$$OK
}

/// Test the functionality by creating and saving a new TModel. Note, the registry will assign the key value
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, Output pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status

	#dim tSave As EnsLib.UDDI.SaveTModel
	#dim tTModel As EnsLib.UDDI.uddi.tModel
	#dim tTModels As %ListOfObjects
	#dim tOverviewDoc As EnsLib.UDDI.uddi.overviewDoc
	#dim tCategoryBag As EnsLib.UDDI.uddi.categoryBag
	#dim tTruncated As %Boolean
	
	$$$PROLOGUE
	
	Write !!,"Test Save TModel",!!
		
	#; What to save TModels
	$$$NEW(tSave,"EnsLib.UDDI.SaveTModel")
	
	#; Create an instance of tModel
	$$$NEW(tTModel,"EnsLib.UDDI.uddi.tModel")
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set tTModel.tModelKey=$c(0)
	
	#; Set the name
	Set tTModel.name.content="Almanac Interface"
	
	#; Add a description
	Set tSC=..addDescriptionToList(tTModel.description,"Standard interface for the Almanac Service")
	If $$$ISERR(tSC) Quit
	
	#; Create an overview document
	$$$NEW(tOverviewDoc,"EnsLib.UDDI.uddi.overviewDoc")
	
	#; Add a description of what the document is
	Set tSC=..addDescriptionToList(tOverviewDoc.description,"The WSDL document describing the interface")
	If $$$ISERR(tSC) Quit
	
	#; Set the URL
	Set tOverviewDoc.overviewURL="http://localhost/bogus.cls?WSDL"
	
	#; Add the document to the tModel
	Set tSC=tTModel.overviewDoc.Insert(tOverviewDoc)
	If $$$ISERR(tSC) Quit
	
	#; Create a CategoryBag
	$$$NEW(tCategoryBag,"EnsLib.UDDI.uddi.categoryBag")
	
	#; This TModel may be categorized as a 'Specification for a web service described in WSDL'
	Set tSC=..addReferenceToList(tCategoryBag.keyedReference,$$$UddiOrgTypes,"Specification for a web service described in WSDL","wsdlSpec")
	If $$$ISERR(tSC) Quit
	
	Set tTModel.categoryBag = tCategoryBag
	
	#; Add the TModel to the list of those to be published
	Set tSC=tSave.AddTModel(tTModel)
	If $$$ISERR(tSC) Quit
	
	#; Now publish
	Set tSC=tSave.Send(pConnection,.tTModels,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"Save TModel was truncated"
	}
	
	Do ##class(EnsLib.UDDI.GetTModelDetail).DisplayTModels(tTModels)
	
	#; Retrieve the key and assign the output
	Set pTModelKey=tTModels.GetAt(1).tModelKey

	$$$EPILOGUE
}

}
