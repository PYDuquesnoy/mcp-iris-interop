/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to locate a list of Business entries which match a given set of criteria
Class EnsLib.UDDI.FindBusiness Extends EnsLib.UDDI.Finder [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains a list of business names to match. The percent (%) character is 
/// a wildcard character, matching any number of characters.
Property Name As list Of EnsLib.UDDI.uddi.name;

/// Contains a list of business identifiers
Property IdentifierBag As EnsLib.UDDI.uddi.identifierBag;

/// By default, if the CategoryBag property of a FindBusiness object is non-empty, the Send
/// method of the FindBusiness object retrieves only those BusinessInfo objects that match all 
/// of the category references. You can specify that the BusinessInfo objects can match any of
/// the category references by including the OrAllKeys field in the FindQualifiers property. 
Property CategoryBag As EnsLib.UDDI.uddi.categoryBag;

/// Contains a collection of UUIDs that is assigned to the tModels that are used to locate an appropriate business
Property TModelBag As EnsLib.UDDI.uddi.tModelBag;

/// Contains a FindTModel object
Property FindTModel As EnsLib.UDDI.uddi.findtModel;

/// Contains a list of URLs to be matched against the discovery URL data that is associated with registered business entity information.
Property DiscoveryUrls As EnsLib.UDDI.uddi.discoveryURLs;

/// Contains a FindRelatedBusinessObject
Property FindRelatedBusinesses As EnsLib.UDDI.uddi.findrelatedBusinesses;

/// Sends the FindBusiness request to the UDDI Server. Returns as output a list of BusinessInfo
/// objects matching the request criteria. Many UDDI servers restrict the number of matching BusinessInfos 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, pListHead As %Integer = 0, Output pListDescription As EnsLib.UDDI.uddi.listDescription, Output pBusinessInfos As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessInfo"), Output pTruncated As %Boolean) As %Status
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

	Do tClient.findbusiness(pConnection.AuthInfo,..FindQualifiers,..Name,..IdentifierBag,..CategoryBag,..TModelBag,..FindTModel,..DiscoveryUrls,..FindRelatedBusinesses,..MaxRows,pListHead,.pListDescription,.pBusinessInfos,.pTruncated)

	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		
	$$$EPILOGUE
}

/// Helper method to add a category
Method AddCategory(pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	Quit ..addReferenceToList(..CategoryBag.keyedReference,pTModelKey,pKeyName,pKeyValue)
}

/// Helper method to add an identifier
Method AddIdentifier(pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	Quit ..addReferenceToList(..IdentifierBag.keyedReference, pTModelKey,pKeyName,pKeyValue)
}

/// Helper method to add a name
Method AddName(pName As %String, pLang As %String = {..#Language}) As %Status
{
	Quit ..addNameToList(..Name,pName,pLang)
}

/// Helper method to add a discovery URL
Method AddDiscoveryURL(pUseType As %String, pURL As %String) As %Status
{
	Quit ..addDiscoveryURLToList(..DiscoveryUrls.discoveryURL,pUseType,pURL)
}

/// Helper method to add a TModel key
Method AddTModelKey(pKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	Do ..TModelBag.tModelKey.Insert(pKey)
	Quit $$$OK
}

ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pName As %String) As %Status
{
	
	#dim tSC As %Status
	
	#dim tFind As EnsLib.UDDI.FindBusiness
	#dim tListHead As %Integer
	#dim tDescription As EnsLib.UDDI.uddi.listDescription
	#dim tBusinessInfos,tServices As %ListOfObjects
	#dim tTruncated As %Boolean
	#dim tInfo As EnsLib.UDDI.uddi.businessInfo
	#dim tService As EnsLib.UDDI.uddi.serviceInfo
	#dim tBinding As EnsLib.UDDI.uddi.bindingTemplate
	#dim tModelInfo As EnsLib.UDDI.uddi.tModelInfo
	#dim tInfoKey,tServiceKey,tBindingKey,tModelInfoKey As %String
	
	$$$PROLOGUE
	
	Write !!,"Test Find Business",!!
	
	#; Want to find Businesses
	$$$NEW(tFind,"EnsLib.UDDI.FindBusiness")
	
	#; Searching for a particular business, from the beginning ( listhead = 0)
	Set tSC=tFind.AddName(pName),tListHead=0
	If $$$ISERR(tSC) Quit
	
	#; Invoke the service
	Set tSC=tFind.Send(pConnection,tListHead,.tDescription,.tBusinessInfos,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The BusinessInfo results have been truncated by the server"
		Write !,"Try increasing MAXROWS property"
	}
	
	If $IsObject(tDescription) {
	
		Write !,"Actual Count ",tDescription.actualCount
		Write !,"Include Count ",tDescription.includeCount
		Write !,"List Head ",tDescription.listHead
		
		Write !!
	}
	
	Set tBusinessInfos=tBusinessInfos.businessInfo
	
	Set tInfoKey=tBusinessInfos.Next("")
	While tInfoKey'="" {
		
		#; Get the BusinessInfo object
		Set tInfo=tBusinessInfos.GetAt(tInfoKey)
	
		Write !,"Business Key:  ",tInfo.businessKey
		Write !,"Business Name: ",..GetList(tInfo.name)
		Write !,"Business Desc: ",..GetList(tInfo.description)
		
		Set tInfoKey=tBusinessInfos.Next(tInfoKey)
		
		Write !!
	}
	
	Write !!,"Test Find Business - OK",!!
		
	$$$EPILOGUE
}

}
