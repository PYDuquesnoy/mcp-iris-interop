/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to retrieve a list of business details. To use the class, instantiate and
/// add one or more business keys with the AddBusinessKey() method and then call Send() to retrieve
/// as output a list of business detail objects 
Class EnsLib.UDDI.GetBusinessDetail Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains a list of BusinessKeys
Property BusinessKeys As list Of EnsLib.UDDI.uddi.businessKey;

Method AddBusinessKey(pKey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	Do ..BusinessKeys.Insert(pKey)
	Quit $$$OK
}

/// Transmits the GetBusinessDetail request to the UDDI Server. Returns as output a list of business
/// objects matching the request criteria. Many UDDI serve rs restrict the number of matching TModels 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, Output pBusinessEntities As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessEntity"), Output pTruncated As %Boolean) As %Status
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

	Do tClient.getbusinessDetail(pConnection.AuthInfo,..BusinessKeys,.pBusinessEntities,.pTruncated)

	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		 
	$$$EPILOGUE
}

/// A list of BusinessInfo objects can be retrieved via the EnsLib.UDDI.FindBusiness() class. This list
/// may be passed to this objects %New() method to intialize the list of BusinessKeys prior to an Inquiry.
Method %OnNew(pBusinessInfos As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessInfo")) As %Status
{
	#dim tSC AS %Status
	#dim tKey As %String
	
	$$$PROLOGUE
	
	If $IsObject($Get(pBusinessInfos)) {
		
		#; Walk the list of BusinessInfo objects and copy the each key to 
		#; this objects key collection.
		Set tKey=pBusinessInfos.Next("")
		While tKey'="" {
			
			Set tSC=..AddBusinessKey(pBusinessInfos.GetAt(tKey).businessKey)
			If $$$ISERR(tSC) Quit
			
			Set tKey=pBusinessInfos.Next(tKey)
		}
	}
		
	$$$EPILOGUE
}

/// Test the class functionality by performing an inquiry for a specific business key
/// and display the results
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pBusinessKey As EnsLib.UDDI.uddi.businessKey) As %Status
{
	#dim tSC As %Status
	#dim tConnection  As EnsLib.UDDI.Connection
	#dim tGetDetail As EnsLib.UDDI.GetBusinessDetail
	#dim tTruncated As %Boolean
	#dim tBusinessEntities As %ListOfObjects
	
	$$$PROLOGUE
		
	Write !!!,"Test GetBusinessDetail",!!

	#; Want to retrieve a specific business
	$$$NEW(tGetDetail,"EnsLib.UDDI.GetBusinessDetail")
	
	#; Retrieve a specific business
	Set tSC=tGetDetail.AddBusinessKey(pBusinessKey)
	If $$$ISERR(tSC) Quit

	#; Send the request to the Server
	Set tSC=tGetDetail.Send(pConnection,.tBusinessEntities,.tTruncated)
	If $$$ISERR(tSC) Quit

	If tTruncated {
		Write !,"The BusinessEntity results have been truncated by the server"
		Write !,"Try increasing MAXROWS property"
	}
	
	Do ..DisplayBusinessEntities(tBusinessEntities)
		
	$$$EPILOGUE
}

/// Method to display a list of business entities
ClassMethod DisplayBusinessEntities(pList As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessEntity"))
{
	#dim tKey As %String
	#dim tEntity As EnsLib.UDDI.uddi.businessEntity
	
	If pList.Count() = 0 {
		Write !,"No BusinessEntities Found"
	} else {
			
		Set tKey=pList.Next("")
		while tKey'="" {
				
			#; Get the BusinessEntity object
			Set tEntity=pList.GetAt(tKey)
				
			#; Display it
			Do ..DisplayBusinessEntity(tEntity)
					
			Write !
			
			Set tKey=pList.Next(tKey)
		}
	}
}

/// Method to display a business entity
ClassMethod DisplayBusinessEntity(pEntity As EnsLib.UDDI.uddi.businessEntity)
{
	Write !,"Business Key:  ",pEntity.businessKey
	Write !,"Business Name: ",..GetList(pEntity.name)
	Write !,"Business Desc: ",..GetList(pEntity.description)
}

}
