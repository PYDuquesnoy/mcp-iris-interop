/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// Base class for members of the EnsLib.UDDI package. Primarily contains helper methods for use with the API
Class EnsLib.UDDI.Base Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Timeout for SOAP requests. The timeout can be varied as appropriate for API calls to the UDDI registry
Property Timeout As %Integer [ InitialExpression = 60 ];

/// Language for names.
Parameter Language As String = "en";

/// Version of the UDDI we need to use
Parameter Generic As String = 3.0;

/// Helper method to add a find qualifier
ClassMethod addFindQualifierToList(pList As %ListOfDataTypes, pQualifier As EnsLib.UDDI.DT.FindQualifier) As %Status
{
	#dim tSC As %Status
	
	$$$PROLOGUE
	
	#; Check that the qualifier is valid
	If '##class(EnsLib.UDDI.DT.FindQualifier).IsValid(pQualifier) {
		Set tSC=$$$ERROR($$$GeneralError,"Invalid FindQualifier: "_pQualifier) Quit
	}
	Do pList.Insert(pQualifier)
	
	$$$EPILOGUE
}

/// Helper method to add a description
/// [Previously private]
ClassMethod addDescriptionToList(pList As %AbstractList, pDescription As %String, pLang As %String = {..#Language}) As %Status
{
	#dim tDescription As EnsLib.UDDI.uddi.description
	
	$$$PROLOGUE
	$$$NEW(tDescription,"EnsLib.UDDI.uddi.description")
	
	Set tDescription.content=pDescription,tDescription.lang=pLang
	Do pList.Insert(tDescription)
	
	$$$EPILOGUE
}

/// Helper method to add a keyed reference to the specified list
/// [Previously private]
ClassMethod addReferenceToList(pList As %AbstractList, pTModelKey As EnsLib.UDDI.uddi.tModelKey, pKeyName As %String, pKeyValue As %String) As %Status
{
	#dim tSC As %Status
	#dim tReference As EnsLib.UDDI.uddi.keyedReference
	
	$$$PROLOGUE
	
	$$$NEW(tReference,"EnsLib.UDDI.uddi.keyedReference")
	Set tReference.tModelKey=pTModelKey,tReference.keyName=pKeyName,tReference.keyValue=pKeyValue
	Do pList.Insert(tReference)
	
	$$$EPILOGUE
}

/// Helper method to add a name to the specified list
/// [Previously private]
ClassMethod addDiscoveryURLToList(pList As %AbstractList, pUseType As %String, pURL As %String) As %Status
{
	#dim tURL As EnsLib.UDDI.uddi.discoveryURL 
	
	$$$PROLOGUE
	
	$$$NEW(tURL,"EnsLib.UDDI.uddi.discoveryURL")
	Set tURL.useType=pUseType,tURL.content=pURL
	Do pList.Insert(tURL)
	
	$$$EPILOGUE
}

/// Helper method to add a contact
ClassMethod addContactToList(pList As %AbstractList, pUseType As %String, pName As %String, pPhone As %String)
{
	#dim tContact As EnsLib.UDDI.uddi.contact
	#dim tPersonName As EnsLib.UDDI.uddi.personName
	#dim tPhone As EnsLib.UDDI.uddi.phone
	
	$$$PROLOGUE
	
	$$$NEW(tContact,"EnsLib.UDDI.uddi.contact")
	Set tContact.useType=pUseType,tContact.personName=pName
	
	#; Create the personName
	$$$NEW(tPersonName,"EnsLib.UDDI.uddi.personName")
	Set tPersonName.lang = "en",tPersonName.content=pName
	
	#; Insert it into the contacts personName list
	do tContact.personName.Insert(tPersonName)
	
	#; Create the phone
	$$$NEW(tPhone,"EnsLib.UDDI.uddi.phone")
	Set tPhone.useType=pUseType,tPhone.content=pPhone
	
	#; Insert it into the contacts phone list
	Do tContact.phone.Insert(tPhone)
	
	#; Now insert the contact into the specified list
	Do pList.Insert(tContact)
	
	$$$EPILOGUE
}

/// Helper method to add a name
ClassMethod addNameToList(pList As %AbstractList, pName As %String, pLang As %String = {..#Language}) As %Status
{
	#dim tName As EnsLib.UDDI.uddi.name
	
	$$$PROLOGUE
	
	$$$NEW(tName,"EnsLib.UDDI.uddi.name")
	Set tName.content=pName,tName.lang=pLang
	Do pList.Insert(tName)
	
	$$$EPILOGUE
}

/// Helper method for retrieving a string from a collection
ClassMethod GetList(pList As %AbstractList) As %String
{
	#dim tString,tKey As %String
	
	Set tString="",tKey=pList.Next("")
	While tKey'="" {
		Set tString=tString_pList.GetAt(tKey).content_" "
		Set tKey=pList.Next(tKey)
	}
	Quit tString
}

/// Helper method to validate the request before sending to the server
/// Subclasses should override this if necessary to apply their own validation
/// criteria
Method validateRequest() As %Status [ Private ]
{
	Quit $$$OK
}

}
