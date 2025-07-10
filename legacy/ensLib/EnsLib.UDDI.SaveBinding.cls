/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to add or update a binding template in a UDDI registry
Class EnsLib.UDDI.SaveBinding Extends EnsLib.UDDI.Saver [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is a collection of binding template objects to update the UDDI registry with
Property BindingTemplates As list Of EnsLib.UDDI.uddi.bindingTemplate;

/// Transmits the SaveBinding request to the UDDI Server.
Method Send(pConnection As EnsLib.UDDI.Connection, Output pTruncated As %Boolean, Output pBindingTemplates As %ListOfObjects(ELEMENTYPE="EnsLib.UDDI.uddi.bindingTemplate")) As %Status
{
	#dim tClient As %RegisteredObject
	#dim tBindingTemplates As %ListOfObjects
	#dim tListDescription As EnsLib.UDDI.uddi.listDescription
	
	$$$PROLOGUE

	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIPUBLICATIONCLASS)

	#; Set the location
	Set tClient.Location=pConnection.PublicationURL,tClient.Timeout=..Timeout

	#; Set the binding templates
	Set tBindingTemplates=..BindingTemplates
	
	#; Invoke the service
	Do tClient.savebinding(pConnection.AuthInfo,.tBindingTemplates,.tListDescription,.pTruncated)
	Set ..BindingTemplates=tBindingTemplates

	#; Assign the output
	Set pBindingTemplates=..BindingTemplates
	
	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
	
	$$$EPILOGUE
}

/// Add a BindingTemplate
Method AddBindingTemplate(pBindingTemplate As EnsLib.UDDI.uddi.bindingTemplate) As %Status
{
	Do ..BindingTemplates.Insert(pBindingTemplate)
	Quit $$$OK
}

/// Test the functionality by creating and saving a new binding template. Note, the registry will assign the key value
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pBusinessKey As EnsLib.UDDI.uddi.businessKey, pServiceKey As EnsLib.UDDI.uddi.serviceKey, pTModelKey As EnsLib.UDDI.uddi.tModelKey, Output pBindingKey As EnsLib.UDDI.uddi.bindingKey) As %Status
{
	#dim tSC As %Status

	#dim tBindingTemplates As %ListOfObjects
	#dim tSave As EnsLib.UDDI.SaveBinding
	#dim tBindingTemplate As EnsLib.UDDI.uddi.bindingTemplate
	#dim tAccessPoint As EnsLib.UDDI.uddi.accessPoint
	#dim tModelInstanceInfo As EnsLib.UDDI.uddi.tModelInstanceInfo
	#dim tModelInstanceDetails As EnsLib.UDDI.uddi.tModelInstanceDetails
	#dim tTruncated As %Boolean
	#dim tListDescription As EnsLib.UDDI.uddi.listDescription
	
	$$$PROLOGUE
	
	Write !!!,"Test Save Binding",!!
		
	#; Want to save a Binding
	$$$NEW(tSave,"EnsLib.UDDI.SaveBinding")

	#; Create an instance of a binding template
	$$$NEW(tBindingTemplate,"EnsLib.UDDI.uddi.bindingTemplate")
	
	#; Create an access point for the binding template
	$$$NEW(tAccessPoint,"EnsLib.UDDI.uddi.accessPoint")
	
	#; Access point is bogus (need to substitute a reference to a preexisting web service here)
	Set tAccessPoint.useType="http",tAccessPoint.content="http://localhost/bogus.cls"
	
	Set tBindingTemplate.accessPoint=tAccessPoint
	
	#; Set the key, $c(0) means 'missing', UDDI registry will assign new key
	Set tBindingTemplate.bindingKey=$c(0)
	
	#; Must specify the service key, key MUST refernece a pre-existing Service in the registry
	Set tBindingTemplate.serviceKey=pServiceKey
	
	#; Add a description
	Set tSC=..addDescriptionToList(tBindingTemplate.description,"Almanac Service")
	If $$$ISERR(tSC) Quit
	
	#; Must have at least ONE tModelInfo structure
	$$$NEW(tModelInstanceInfo,"EnsLib.UDDI.uddi.tModelInstanceInfo")
	
	#; Use the tModelKey we obtained earlier
	Set tModelInstanceInfo.tModelKey=pTModelKey
	
	$$$NEW(tModelInstanceDetails,"EnsLib.UDDI.uddi.tModelInstanceDetails")
	
	#; Add the tModelInfo to the binding template
	Do tModelInstanceDetails.tModelInstanceInfo.Insert(tModelInstanceInfo)
	
	#; Add the instance details to the binding template
	Set tBindingTemplate.tModelInstanceDetails=tModelInstanceDetails
	
	#; Add this to the binding templates to save/update
	Set tSC=tSave.AddBindingTemplate(tBindingTemplate)
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tSave.Send(pConnection,.tTruncated,.tBindingTemplates)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The SaveBinding operation was truncated"
	}
		
	Do ##class(EnsLib.UDDI.GetBindingDetail).DisplayBindingTemplates(tBindingTemplates)
	
	#; Retrieve the key and assign the output
	Set pBindingKey=tBindingTemplates.GetAt(1).bindingKey
		
	$$$EPILOGUE
}

}
