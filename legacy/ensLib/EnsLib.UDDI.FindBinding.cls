/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to locate a list of Binding entries which match a given set of criteria
Class EnsLib.UDDI.FindBinding Extends EnsLib.UDDI.Finder [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// By default, if the CategoryBag property of a FindBusiness object is non-empty, the Send
/// method of the FindBusiness object retrieves only those BusinessInfo objects that match all 
/// of the category references. You can specify that the BusinessInfo objects can match any of
/// the category references by including the OrAllKeys field in the FindQualifiers property. 
Property CategoryBag As EnsLib.UDDI.uddi.categoryBag;

/// Contains a collection of UUIDs that is assigned to the tModels that are used to locate an appropriate business
Property TModelBag As EnsLib.UDDI.uddi.tModelBag;

/// Contains a FindTModel object
Property FindTModel As EnsLib.UDDI.uddi.findtModel;

/// The ServiceKey property contains a UUID that is used to specify a particular Service instance to search for.
Property ServiceKey As EnsLib.UDDI.uddi.serviceKey;

/// Sends the FindBinding Request to the UDDI Server. Returns as output a list of BindingTemplate
/// objects matching the request criteria. Many UDDI servers restrict the number of matching BindingTemplates 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, pListHead As %Integer = 0, Output pListDescription As EnsLib.UDDI.uddi.listDescription, Output pBindingTemplates As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate"), Output pTruncated As %Boolean) As %Status
{
	#dim tSC As %Status
	#dim tClient As %RegisteredObject
	
	$$$PROLOGUE
	
	#; Validate the Request before Sending
	Set tSC=..validateRequest()
	If $$$ISERR(tSC) Quit

	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIINQUIRYCLASS)
	
	#; Set the location
	Set tClient.Location=pConnection.InquiryURL,tClient.Timeout=..Timeout

	#; Find the bindings
	Do tClient.findbinding(pConnection.AuthInfo,..FindQualifiers,..TModelBag,..FindTModel,..CategoryBag,..MaxRows, ..ServiceKey, pListHead,.pListDescription,.pBindingTemplates,.pTruncated)
	
	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)

	$$$EPILOGUE
}

/// Helper method to add a category
Method AddCategory(pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	Quit ..addReferenceToList(pTModelKey,pKeyName,pKeyValue,..CategoryBag.keyedReference)
}

/// Helper method to add a key (e.g.  uuid:8609C81E-EE1F-4D5A-B202-3EB13AD01823)
Method AddTModelKey(pKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	Do ..TModelBag.tModelKey.Insert(pKey)
	Quit $$$OK
}

/// Helper method to validate the request before sending to the server
Method validateRequest() As %Status [ Private ]
{
	#dim tSC As %Status
	Set tSC=$$$OK
	do {
		If ..ServiceKey="" {
			Set tSC=$$$ERROR($$$GeneralError,"ServiceKey property cannot be empty")
			Quit
		}
		
		If ..TModelBag.tModelKey.Count()=0 {
			Set tSC=$$$ERROR($$$GeneralError,"TModelBag property cannot be empty")
			Quit
		}
	} while (0)
	Quit tSC
}

/// This method tests the FindBinding functionality. FindBinding allows you to find the bindings within 
/// a specified service which define the specified tModelKey. As such, the ServiceKey MUST be specified
/// and AT LEAST ONE tModelKey
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pServiceKey As EnsLib.UDDI.uddi.serviceKey, pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status
	#dim tBindingKey,tModelInfoKey As %String
	#dim tDescription As EnsLib.UDDI.uddi.listDescription
	#dim tBinding As EnsLib.UDDI.uddi.bindingTemplate
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tFind As EnsLib.UDDI.FindBinding
	#dim tModelInfo As EnsLib.UDDI.uddi.tModelInfo
	#dim tBindingTemplates As %ListOfObjects
	#dim tTruncated As %Boolean
	#dim tListHead As %Integer = 0
	
	$$$PROLOGUE
	
	Write !!!,"Test FindBinding",!!

	#; Want to find Bindings
	$$$NEW(tFind,"EnsLib.UDDI.FindBinding")
	
	#; Looking for bindings for a specific service 
	Set tFind.ServiceKey=pServiceKey

	#; Looking for a binding which specifies this tModelKey key
	Do tFind.AddTModelKey(pTModelKey)

	#; Send the request to the Server
	Set tSC=tFind.Send(pConnection,tListHead,.tDescription,.tBindingTemplates,.tTruncated)
	If $$$ISERR(tSC) Quit

	If tTruncated {
		Write !,"The BindingTemplate results have been truncated by the server"
		Write !,"Try increasing MAXROWS property"
	}
	
	If $IsObject(tDescription) {
	
		Write !,"Actual Count ",tDescription.actualCount
		Write !,"Include Count ",tDescription.includeCount
		Write !,"List Head ",tDescription.listHead
	}
	
	Do ##class(EnsLib.UDDI.GetBindingDetail).DisplayBindingTemplates(tBindingTemplates)
			
	$$$EPILOGUE
}

/// This callback method is invoked by the <METHOD>%New</METHOD> method to 
/// provide notification that a new instance of an object is being created.
/// 
/// <P>If this method returns an error then the object will not be created.
/// <p>It is passed the arguments provided in the %New call.
/// When customizing this method, override the arguments with whatever variables and types you expect to receive from %New().
/// For example, if you're going to call %New, passing 2 arguments, %OnNew's signature could be:
/// <p>Method %OnNew(dob as %Date = "", name as %Name = "") as %Status
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	Set ..TModelBag=##class(EnsLib.UDDI.uddi.tModelBag).%New()
	Quit $$$OK
}

}
