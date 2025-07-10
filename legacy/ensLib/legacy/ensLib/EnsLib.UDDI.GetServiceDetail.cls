/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to retrieve a list of service details. To use the class, instantiate and
/// add one or more service keys with the AddServiceKey() method and then call Send() to retrieve
/// as output a list of service detail objects 
Class EnsLib.UDDI.GetServiceDetail Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains a list of ServiceKeys
Property ServiceKeys As list Of EnsLib.UDDI.uddi.serviceKey;

Method AddServiceKey(pKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	Do ..ServiceKeys.Insert(pKey)
	Quit $$$OK
}

/// Transmits the GetServiceDetail request to the UDDI Server. Returns as output a list of businessService
/// objects matching the request criteria. Many UDDI servers restrict the number of matching businessService
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, Output pServices As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessService"), Output pTruncated As %Boolean) As %Status
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

	#; Invoke the service
	Do tClient.getserviceDetail(pConnection.AuthInfo,..ServiceKeys,.pServices,.pTruncated)
	
	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		 
	$$$EPILOGUE
}

/// A list of ServiceInfo objects can be retrieved via the EnsLib.UDDI.FindService() class. This list
/// may be passed to this objects %New() method to intialize the list of ServiceKeys prior to an Inquiry.
Method %OnNew(pServiceInfos As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.serviceInfo")) As %Status
{
	#dim tSC As %Status
	#dim tKey As %String
	
	Set $ZT="Trap",tSC=$$$OK
	do {
		If $IsObject($Get(pServiceInfos)) {
			
			#; Walk the list of ServiceInfo objects and copy the each key to 
			#; this objects key collection.
			Set tKey=pServiceInfos.Next("")
			While tKey'="" {
				
				Set tSC=..AddServiceKey(pServiceInfos.GetAt(tKey).serviceKey)
				If $$$ISERR(tSC) Quit
				
				Set tKey=pServiceInfos.Next(tKey)
			}
		}
		
	} while (0)
Exit Quit tSC
Trap Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

/// Test the class functionality by performing an inquiry for a specific service key.
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pServiceKey As EnsLib.UDDI.uddi.serviceKey) As %Status
{
	#dim tSC As %Status
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tGetDetail As EnsLib.UDDI.GetServiceDetail
	#dim tBusinessServices As %ListOfObjects
	#dim tTruncated As %Boolean
	
	$$$PROLOGUE
		
	Write !!!,"Test GetServiceDetail",!!

	#; Want to retrieve a specific service
	$$$NEW(tGetDetail,"EnsLib.UDDI.GetServiceDetail")
	
	#; Retrieve a specific service
	Set tSC=tGetDetail.AddServiceKey(pServiceKey)
	If $$$ISERR(tSC) Quit

	#; Send the request to the Server
	Set tSC=tGetDetail.Send(pConnection,.tBusinessServices,.tTruncated)
	If $$$ISERR(tSC) Quit

	If tTruncated {
		Write !,"The BusinessService results have been truncated by the server"
	}

	Do ..DisplayBusinessServices(tBusinessServices)
	
	$$$EPILOGUE
}

/// Method to display a list of business services
ClassMethod DisplayBusinessServices(pList As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.businessService"))
{
	#dim tKey As %String
	#dim tService As EnsLib.UDDI.uddi.businessService
	
	If pList.Count() = 0 {
		Write !,"No BusinessServices Found"
	} else {
			
		Set tKey=pList.Next("")
		while tKey'="" {
				
			#; Get the BusinessService object
			Set tService=pList.GetAt(tKey)
				
			#; Display it
			Do ..DisplayBusinessService(tService)
					
			Write !
			
			Set tKey=pList.Next(tKey)
		}
	}
}

/// Method to display a business service
ClassMethod DisplayBusinessService(pService As EnsLib.UDDI.uddi.businessService)
{
	Write !,"Service Key:  ",pService.serviceKey
	Write !,"Service Name: ",..GetList(pService.name)
	Write !,"Service Desc: ",..GetList(pService.description)
}

}
