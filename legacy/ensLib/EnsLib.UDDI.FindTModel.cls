/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to locate a list of TModel entries which match a given set of criteria
Class EnsLib.UDDI.FindTModel Extends EnsLib.UDDI.Finder [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// The Name property contains the name of the requested tModel. The percent (%) character is 
/// a wildcard character, matching any number of characters. By default, a tModel name search
/// behaves as though a trailing "%" was at the end of the name. You can override this default 
/// behavior by specifying an ExactNameMatch field as one of the FindQualifiers.
Property Name As EnsLib.UDDI.uddi.name;

/// By default, if the IdentifierBag property is non-empty, the Send method retrieves the TModelInfo 
/// objects that match any of the business identifiers. You can specify that the TModelInfo objects must
/// match all of the business identifiers by including the AndAllKeys field in the FindQualifiers property.
Property IdentifierBag As EnsLib.UDDI.uddi.identifierBag;

/// By default, if the CategoryBag property of a FindTModel object is non-empty, the Send
/// method of the FindTModel object retrieves only those TModelInfo objects that match all 
/// of the category references. You can specify that the TModelInfo objects can match any of
/// the category references by including the OrAllKeys field in the FindQualifiers property.
Property CategoryBag As EnsLib.UDDI.uddi.categoryBag;

/// Transmits the FindTModel request to the UDDI Server. Returns as output a list of TModelInfo
/// objects matching the request criteria. Many UDDI servers restrict the number of matching TModelInfos 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, pListHead As %Integer, Output pDescription As EnsLib.UDDI.uddi.listDescription, Output pTModelInfos As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModelInfo"), Output pTruncated As %Boolean) As %Status
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

	Do tClient.findtModel(pConnection.AuthInfo,..FindQualifiers,..Name,..IdentifierBag,..CategoryBag,..MaxRows,pListHead,.pDescription,.pTModelInfos,.pTruncated)

	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
 
	$$$EPILOGUE
}

/// Helper method to add a category to the list
Method AddCategory(pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	Quit ..addReferenceToList(..CategoryBag.keyedReference,pTModelKey,pKeyName,pKeyValue)
}

/// Helper method to add an identifer to the list
Method AddIdentifier(pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	Quit ..addReferenceToList(..IdentifierBag.keyedReference,pTModelKey,pKeyName,pKeyValue)
}

ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pName As %String) As %Status
{
	#dim tSC As %Status
	#dim tListHead As %Integer
	#dim tDescription As EnsLib.UDDI.uddi.listDescription
	#dim tTruncated As %Boolean
	#dim tFind As EnsLib.UDDI.FindTModel
	#dim tModelInfos As %ListOfObjects
	#dim tModelInfo As EnsLib.UDDI.uddi.tModelInfo
	#dim tInfoKey As %String

	$$$PROLOGUE
		
	Write !!!,"Test Find TModel",!!
	
	#; What to find TModels
	$$$NEW(tFind,"EnsLib.UDDI.FindTModel")
	
	#; Searching for a particular business, from the beginning ( listhead = 0)
	Set tFind.Name.content=pName,tListHead=0
	
	#; Send the request to the Server
	Set tSC=tFind.Send(pConnection,tListHead,.tDescription,.tModelInfos,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The TModelInfo results have been truncated by the server"
		Write !,"Try increasing MAXROWS property"
	}
	
	If $IsObject(tDescription) {
	
		Write !,"Actual Count ",tDescription.actualCount
		Write !,"Include Count ",tDescription.includeCount
		Write !,"List Head ",tDescription.listHead
	}

	Set tModelInfos=tModelInfos.tModelInfo
	
	Set tInfoKey=tModelInfos.Next("")
	While tInfoKey'="" {
		
		#; Get the TModelInfo object
		Set tModelInfo=tModelInfos.GetAt(tInfoKey)
	
		Write !,"TModel Key:  ",tModelInfo.tModelKey
		Write !,"TModel Name: ",tModelInfo.name.content
		Write !,"TModel Desc: ",..GetList(tModelInfo.description)
		
		Set tInfoKey=tModelInfos.Next(tInfoKey)
		
		Write !!
	}
		
	$$$EPILOGUE
}

}
