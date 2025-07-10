/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// This class is used to retrieve a list of Binding details. To use the class, instantiate and
/// add one or more Binding keys with the AddBindingKey() method and then call Send() to retrieve
/// as output a list of BindingTemplate objects 
Class EnsLib.UDDI.GetBindingDetail Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Contains a list of BindingKeys
Property BindingKeys As list Of EnsLib.UDDI.uddi.bindingKey;

Method AddBindingKey(pKey As EnsLib.UDDI.uddi.bindingKey) As %Status
{
	Do ..BindingKeys.Insert(pKey)
	Quit $$$OK
}

/// Transmits the GetBindingDetail request to the UDDI Server. Returns as output a list of Binding
/// objects matching the request criteria. Many UDDI servers restrict the number of matching TModels 
/// that they return for a find request. If your find request exceeds the number set by a UDDI server, 
/// the result is truncated. The pTruncated output parameter will be set to TRUE (1)
Method Send(pConnection As EnsLib.UDDI.Connection, Output pListDescription As EnsLib.UDDI.uddi.listDescription, Output pBindingTemplates As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate"), Output pTruncated As %Boolean) As %Status
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

	Do tClient.getbindingDetail(pConnection.AuthInfo,..BindingKeys,.pListDescription,.pBindingTemplates,.pTruncated)
	
	#; Convert to %Boolean
	Set pTruncated=$$$ToBoolean(pTruncated)
		 
	$$$EPILOGUE
}

/// Test the class functionality by performing an inquiry for a specific Binding key
/// and display the results
ClassMethod Test(pConnection As EnsLib.UDDI.Connection, pBindingKey As EnsLib.UDDI.uddi.bindingKey) As %Status
{
	#dim tSC As %Status
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tGetDetail As EnsLib.UDDI.GetBindingDetail
	#dim tBindingTemplates As %ListOfObject
	#dim tTruncated As %Boolean
	#dim tDescription As EnsLib.UDDI.uddi.listDescription
	
	$$$PROLOGUE	
		
	Write !!!,"Test GetBindingDetail",!!
	
	#; Want to retrieve a specific Binding
	$$$NEW(tGetDetail,"EnsLib.UDDI.GetBindingDetail")
	
	#; Retrieve a specific Binding
	Set tSC=tGetDetail.AddBindingKey(pBindingKey)
	If $$$ISERR(tSC) Quit
	
	#; Send the request to the Server
	Set tSC=tGetDetail.Send(pConnection,.tDescription,.tBindingTemplates,.tTruncated)
	If $$$ISERR(tSC) Quit
	
	If tTruncated {
		Write !,"The BindingTemplate results have been truncated by the server"
	}
	
	If $IsObject(tDescription) {
	
		Write !,"Actual Count ",tDescription.actualCount
		Write !,"Include Count ",tDescription.includeCount
		Write !,"List Head ",tDescription.listHead
	}
		
	Do ..DisplayBindingTemplates(tBindingTemplates)
		
	$$$EPILOGUE
}

/// Method to display a list of BindingTemplates
ClassMethod DisplayBindingTemplates(pList As %ListOfObjects(ELEMENTTYPE="EnsLib.UDDI.uddi.bindingTemplate"))
{
	#dim tKey As %String
	#dim tTemplate As EnsLib.UDDI.uddi.bindingTemplate
	If pList.Count() = 0 {
		Write !,"No BindingTemplates Found"
	} else {
		Set tKey=pList.Next("")
		while tKey'="" {
				
			#; Get the BindingTemplate object
			Set tTemplate=pList.GetAt(tKey)
				
			#; Display it
			Do ..DisplayBindingTemplate(tTemplate)
			
			Write !
					
			Set tKey=pList.Next(tKey)
		}
	}
}

/// Method to display a BindingTemplate
ClassMethod DisplayBindingTemplate(pTemplate As EnsLib.UDDI.uddi.bindingTemplate)
{
	Write !,"Binding Key:                    ",pTemplate.bindingKey
	Write !,"Binding Description:            ",..GetList(pTemplate.description)
	If $IsObject(pTemplate.accessPoint) {
		Write !,"Binding Access Point:           ",pTemplate.accessPoint.content
	} elseif $IsObject(pTemplate.hostingRedirector) {
		Write !,"Binding Hosting Redirector:     ",pTemplate.hostingRedirector.bindingKey
	} else {
		Write !,"Invalid Binding Template, either 'accessPoint' or 'hostingRedirector' must be present"
	}
}

}
