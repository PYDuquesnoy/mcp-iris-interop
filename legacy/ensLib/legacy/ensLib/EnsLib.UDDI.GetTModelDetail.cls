/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to retrieve a list of TModelDetails.
Class EnsLib.UDDI.GetTModelDetail Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains a list of TModelKeys
Property TModelKeys As list Of EnsLib.UDDI.uddi.tModelKey;

Method AddTModelKey(pKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	Do ..TModelKeys.Insert(pKey)
	Quit $$$OK
}

/// Transmits the GetTModelDetail request to the UDDI Server. Returns as output a list of TModel
/// objects matching the request criteria. Many UDDI servers restrict the number of matching TModels 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, Output pTModels As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModel"), Output pTruncated As %Boolean) As %Status
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

	Do tClient.gettModelDetail(pConnection.AuthInfo,..TModelKeys,.pTModels,.pTruncated)
	
	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		 
	$$$EPILOGUE
}

/// A list of TModelInfo object can be retrieved via the EnsLib.UDDI.FindTModel() class. This list
/// may be passed to this objects %New() method to intialize the list of TModelKeys prior to an Inquiry.
Method %OnNew(pTModelInfos As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModelInfo")) As %Status
{
	#dim tSC As %Status
	#dim tKey As %String
	
	$$$PROLOGUE
	
	If $IsObject($Get(pTModelInfos)) {
		
		#; Walk the list of TModelInfo objects and copy the each key to 
		#; this objects key collection.
		Set tKey=pTModelInfos.Next("")
		While tKey'="" {
			
			Set tSC=..AddTModelKey(pTModelInfos.GetAt(tKey).tModelKey)
			If $$$ISERR(tSC) Quit
			
			Set tKey=pTModelInfos.Next(tKey)
		}
	}
		
	$$$EPILOGUE
}

/// Test the class functionality by performing an inquiry for a specific TModel key.
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pTModelKey As EnsLib.UDDI.uddi.tModelKey) As %Status
{
	#dim tSC As %Status
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tGetDetail As EnsLib.UDDI.GetTModelDetail
	#dim tModels As %ListOfObjects
	#dim tTruncated As %Boolean
	
	$$$PROLOGUE
	
	Write !!!,"Test GetTModelDetail",!!
	
	#; Want to retrieve a specific service
	$$$NEW(tGetDetail,"EnsLib.UDDI.GetTModelDetail")
	
	#; Retrieve a specific tmodel
	Set tSC=tGetDetail.AddTModelKey(pTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Send the request to the Server
	Set tSC=tGetDetail.Send(pConnection,.tModels,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The TModel results have been truncated by the server"
	}
		
	Do ..DisplayTModels(tModels)
		
	$$$EPILOGUE
}

/// Method to display a list of TModels
ClassMethod DisplayTModels(pList As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.tModel"))
{
	#dim tKey As %String
	#dim tModel As EnsLib.UDDI.uddi.tModel
	If pList.Count() = 0 {
		Write !,"No TModels Found"
	} else {			
		Set tKey=pList.Next("")
		while tKey'="" {
				
			#; Get the TModel object
			Set tModel=pList.GetAt(tKey)
				
			#; Display it
			Do ..DisplayTModel(tModel)
			
			Write !
					
			Set tKey=pList.Next(tKey)
		}
	}
}

/// Method to display a TModel
ClassMethod DisplayTModel(pModel As EnsLib.UDDI.uddi.tModel)
{
	Write !,"TModel Key:  ",pModel.tModelKey
	Write !,"TModel Name: ",pModel.name.content
	Write !,"TModel Desc: ",..GetList(pModel.description)
}

}
