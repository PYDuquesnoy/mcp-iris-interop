/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to locate a list of Service entries which match a given set of criteria
Class EnsLib.UDDI.FindService Extends EnsLib.UDDI.Finder [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains a list of business names to match. The percent (%) character is 
/// a wildcard character, matching any number of characters.
Property Name As list Of EnsLib.UDDI.uddi.name;

/// By default, if the CategoryBag property of a FindService object is non-empty, the Send
/// method of the findservice object retrieves only those serviceInfo objects that match all 
/// of the category references. You can specify that the serviceInfo objects can match any of
/// the category references by including the OrAllKeys field in the FindQualifiers property.
Property CategoryBag As EnsLib.UDDI.uddi.categoryBag;

/// Contains a collection of UUIDs that is assigned to the tModels that are used to locate an appropriate service
Property TModelBag As EnsLib.UDDI.uddi.tModelBag;

/// Contains a FindTModel object
Property FindTModel As EnsLib.UDDI.uddi.findtModel;

/// The BusinessKey property contains a UUID that is used to specify a particular BusinessEntity instance to search for.
Property BusinessKey As EnsLib.UDDI.uddi.businessKey;

/// Sends the FindService Request to the UDDI Server. Returns as output a list of ServiceInfo
/// objects matching the request criteria. Many UDDI servers restrict the number of matching ServiceInfos 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, pListHead As %Integer = 0, Output pListDescription As EnsLib.UDDI.uddi.listDescription, Output pServiceInfos As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.serviceInfo"), Output pTruncated As %Boolean) As %Status
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

	Do tClient.findservice(pConnection.AuthInfo,..FindQualifiers,..Name,..CategoryBag,..TModelBag,..FindTModel,..MaxRows,..BusinessKey,pListHead,.pListDescription,.pServiceInfos,.pTruncated)
	
	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		
	$$$EPILOGUE
}

/// Helper method to add a category
Method AddCategory(pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	Quit ..addReferenceToList(..CategoryBag,pTModelKey,pKeyName,pKeyValue)
}

/// Helper method to add a name
Method AddName(pName As %String, pLang As %String = {..#Language}) As %Status
{
	Quit ..addNameToList(..Name,pName,pLang)
}

/// Helper method to add a key (e.g.  uuid:8609C81E-EE1F-4D5A-B202-3EB13AD01823)
Method AddTModelKey(pKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	Do ..TModelBag.Insert(pKey)
	Quit $$$OK
}

ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pServiceName As EnsLib.UDDI.uddi.name) As %Status
{
	#dim tSC As %Status
	#dim tTruncated As %Boolean
	#dim tServiceInfos As %ListOfObjects
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tFind As EnsLib.UDDI.FindService
	#dim tDescription As EnsLib.UDDI.uddi.listDescription
	#dim tListHead As %Integer = 0
	#dim tInfoKey As %String
	#dim tInfo As EnsLib.UDDI.uddi.serviceInfo
	
	$$$PROLOGUE
	
	Write !!!,"Test FindService",!!
	
	#; Want to find Services
	$$$NEW(tFind,"EnsLib.UDDI.FindService")
	
	#; Searching for the specified service
	Set tSC=tFind.AddName("Almanac Service")
	If $$$ISERR(tSC) Quit
	
	#; Send the request to the Server
	Set tSC=tFind.Send(pConnection,tListHead,.tDescription,.tServiceInfos,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The ServiceInfo results have been truncated by the server"
		Write !,"Try increasing MAXROWS property"
	}
	
	If $IsObject(tDescription) {
	
		Write !,"Actual Count ",tDescription.actualCount
		Write !,"Include Count ",tDescription.includeCount
		Write !,"List Head ",tDescription.listHead
	}
	
	Set tServiceInfos=tServiceInfos.serviceInfo
	
	Set tInfoKey=tServiceInfos.Next("")
	While tInfoKey'="" {
		
		#; Get the BusinessInfo object
		Set tInfo=tServiceInfos.GetAt(tInfoKey)
	
		Write !,"Service Key:  ",tInfo.serviceKey
		Write !,"Service Name: ",..GetList(tInfo.name)
		Write !,"Business Key: ",tInfo.businessKey
		
		Set tInfoKey=tServiceInfos.Next(tInfoKey)
		
		Write !!
	}
	
	Write !!,"Test Find Service - OK",!!
		
	$$$EPILOGUE
}

}
