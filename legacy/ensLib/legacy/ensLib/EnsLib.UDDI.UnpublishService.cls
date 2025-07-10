/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.UnpublishService Extends EnsLib.UDDI.Saver [ System = 4 ]
{

Method DeleteAllServicesForBusiness(pBusinessName As %String) As %Status
{
	#dim tSC 			As %Status
	#dim tServiceKeys	As %ListOfDataTypes
	#dim i				As %Integer
	#dim tServiceKey	As EnsLib.UDDI.uddi.serviceKey	
	
	set tSC = ..FindAllServicesForBusiness(pBusinessName,.tServiceKeys)
	If $$$ISERR(tSC) Quit tSC

	Write "Found "_tServiceKeys.Count()_" Services.", !
	
	Set i = ""
	Do {
		Set tServiceKey = tServiceKeys.GetNext(.i)
		Quit:tServiceKey=""
		
		Set tSC = ..DeleteServiceRecursively(tServiceKey)
		If $$$ISERR(tSC) Quit 
	} While (i'="")
	If $$$ISERR(tSC) Quit tSC
	
	Quit tSC
}

Method FindAllServicesForBusiness(pBusinessName As %String, Output pServiceKeys As %ListOfDataTypes) As %Status
{
	#dim tSC 			As %Status
	#dim tTruncated 	As %Boolean
	#dim tFindBusiness	As EnsLib.UDDI.FindBusiness
	#dim tFindService	As EnsLib.UDDI.FindService
	#dim tDescription 	As EnsLib.UDDI.uddi.listDescription
	#dim tBI 			As EnsLib.UDDI.uddi.businessInfos
	#dim tSI 			As EnsLib.UDDI.uddi.serviceInfos
	#dim tBusinessInfos As %ListOfObjects
	#dim tServiceInfos 	As %ListOfObjects
	#dim tBInfoKey	 	As %String
	#dim tSInfoKey	 	As %String
	#dim tBusinessInfo 	As EnsLib.UDDI.uddi.businessInfo
	#dim tServiceInfo 	As EnsLib.UDDI.uddi.serviceInfo
	
	#; Want to find Businesses
	$$$NEW(tFindBusiness,"EnsLib.UDDI.FindBusiness")
	
	#; Searching for a particular business, from the beginning ( listhead = 0)
	Set tSC=tFindBusiness.AddName(pBusinessName)
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC=tFindBusiness.Send(..Connection,0,.tDescription,.tBI,.tTruncated)
	If $$$ISERR(tSC) Quit tSC
	If tTruncated {
		Write !,"The BusinessInfo results have been truncated by the server"
		Write !,"Try increasing MAXROWS property"
	}

	set pServiceKeys = ##class(%ListOfDataTypes).%New()

	If ($g(tBI)="") Quit tSC
	Set tBusinessInfos=tBI.businessInfo
	If ($g(tBusinessInfos)="") Quit tSC
	
	Set tBInfoKey=tBusinessInfos.Next("")
	While tBInfoKey'="" {
		
		#; Get the BusinessInfo object
		Set tBusinessInfo=tBusinessInfos.GetAt(tBInfoKey)
	
		W "Found business: "_tBusinessInfo.businessKey, !
		$$$NEW(tFindService,"EnsLib.UDDI.FindService")
		Set tFindService.BusinessKey = tBusinessInfo.businessKey
		Set tSC=tFindService.Send(..Connection,0,.tDescription,.tSI,.tTruncated)
		If $$$ISERR(tSC) Quit
	
		If tTruncated {
			Write !,"The ServiceInfo results have been truncated by the server"
			Write !,"Try increasing MAXROWS property"
		}
		
		Quit:$g(tSI)=""
		Set tServiceInfos = tSI.serviceInfo
		Quit:$g(tServiceInfos)=""
		
		Set tSInfoKey=tServiceInfos.Next("")
		While tSInfoKey'="" {
		
			#; Get the BusinessInfo object
			Set tServiceInfo=tServiceInfos.GetAt(tSInfoKey)
	
			Do pServiceKeys.Insert(tServiceInfo.serviceKey)
	
			Set tSInfoKey=tServiceInfos.Next(tSInfoKey)
		}
		Set tBInfoKey=tBusinessInfos.Next(tBInfoKey)
	}
	If $$$ISERR(tSC) Quit tSC
	
	Quit tSC
}

Method DeleteServiceRecursively(pServiceKey As %String) As %Status
{
	#dim tSC 			As %Status
	#dim tBindingKeys 	As %ListOfDataTypes
	#dim tTModelKeys  	As %ListOfDataTypes
	#dim tModelKey 		As EnsLib.UDDI.uddi.tModelKey
	#dim tBindingKey	As EnsLib.UDDI.uddi.bindingKey
	#dim tDeleteTModel	As EnsLib.UDDI.DeleteTModel
	#dim tDeleteBinding As EnsLib.UDDI.DeleteBinding
	#dim tDeleteService As EnsLib.UDDI.DeleteService
	
	#dim i		 		As %Integer

	Set tBindingKeys = ##class(%ListOfDataTypes).%New()
	Set tTModelKeys  = ##class(%ListOfDataTypes).%New()
	
	Set tSC = ..FindBindingsAndTModels(pServiceKey,.tBindingKeys,.tTModelKeys)
	If $$$ISERR(tSC) Quit tSC

	#; Want to delete TModels
	$$$NEW(tDeleteTModel,"EnsLib.UDDI.DeleteTModel")

	Set i = ""
	Do {
		Set tModelKey = tTModelKeys.GetNext(.i)
		Quit:tModelKey=""
		
		Set tSC=tDeleteTModel.AddTModelKey(tModelKey)
		Quit:$$$ISERR(tSC) 
	} While (i'="")
	If $$$ISERR(tSC) Quit tSC

	#; Now Delete All TModels
	Set tSC=tDeleteTModel.Send(..Connection)
	If $$$ISERR(tSC) Quit tSC
	
	#; Want to delete Bindings
	$$$NEW(tDeleteBinding,"EnsLib.UDDI.DeleteBinding")
	
	Set i = ""
	Do {
		Set tBindingKey = tBindingKeys.GetNext(.i)
		Quit:tBindingKey=""
		
		Set tSC=tDeleteBinding.AddBindingKey(tBindingKey)
		Quit:$$$ISERR(tSC) 
	} While (i'="")
	If $$$ISERR(tSC) Quit tSC
	
	#; Now Delete All Bindings
	Set tSC=tDeleteBinding.Send(..Connection)
	If $$$ISERR(tSC) Quit tSC
	
	
	#; Want to delete Services
	$$$NEW(tDeleteService,"EnsLib.UDDI.DeleteService")
	
	Set tSC=tDeleteService.AddServiceKey(pServiceKey)
	
	#; Now Delete BusinessService
	Set tSC=tDeleteService.Send(..Connection)
	If $$$ISERR(tSC) Quit tSC
	
	Quit tSC
}

Method FindBindingsAndTModels(pServiceKey As %String, pBindingKeys As %Collection.ListOfDT, pTModelKeys As %Collection.ListOfDT) As %Status
{
	#dim tSC 					As %Status
	#dim tService 				As EnsLib.UDDI.uddi.businessService
	#dim tBindingTemplates 		As EnsLib.UDDI.uddi.bindingTemplates
	#dim tBindingTemplate 		As EnsLib.UDDI.uddi.bindingTemplate
	#dim tModelInstanceDetails 	As EnsLib.UDDI.uddi.tModelInstanceDetails
	#dim tModelInstanceInfo 	As EnsLib.UDDI.uddi.tModelInstanceInfo
	#dim tBTKey					As %Integer
	#dim tTMKey					As %Integer
	#dim t						As %ObjectHandle


	set tSC = ..GetService(pServiceKey,.tService)
	If $$$ISERR(tSC) Quit tSC
	
	Quit:$g(tService)="" tSC
	
	set tBindingTemplates = tService.bindingTemplates
	Quit:$g(tBindingTemplates)="" tSC
	Set t = tBindingTemplates.bindingTemplate 
	Quit:$g(t)="" tSC
	
	Set tBTKey=""
	Do {
		Set tBindingTemplate = tBindingTemplates.bindingTemplate.GetNext(.tBTKey)
		Quit:tBindingTemplate=""
		
		Do pBindingKeys.Insert(tBindingTemplate.bindingKey)
		
		Set tModelInstanceDetails = tBindingTemplate.tModelInstanceDetails
		Continue:$g(tModelInstanceDetails)=""
		Set t = tModelInstanceDetails.tModelInstanceInfo
		Continue:$g(t)=""

		Set tTMKey = ""
		Do {
			Set tModelInstanceInfo = tModelInstanceDetails.tModelInstanceInfo.GetNext(.tTMKey)
			Quit:tModelInstanceInfo=""
			
			Do pTModelKeys.Insert(tModelInstanceInfo.tModelKey)
		} While (tTMKey'="")
	}
	While (tBTKey'="")
	
	Quit tSC
}

Method GetService(pServiceKey As %String, Output pService As EnsLib.UDDI.uddi.businessService) As %Status
{
	#dim tSC 			As %Status
	#dim tClient 		As %RegisteredObject
	#dim tServiceKeys 	As %ListOfDataTypes
	#dim tServices 		As %Collection.ListOfObj
	#dim tTruncated 	As %Boolean
	#dim tCount			As %Integer
	
	
	$$$PROLOGUE
	
	#; Validate the Request before Sending
	Set tSC=..validateRequest()
	If $$$ISERR(tSC) Quit
	
	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDIINQUIRYCLASS)

	#; Set the location
	Set tClient.Location=..Connection.InquiryURL,tClient.Timeout=..Timeout
	
	Set tServiceKeys = ##class(%ListOfDataTypes).%New()
	Do tServiceKeys.Insert(pServiceKey)
	
	Do tClient.getserviceDetail(..Connection.AuthInfo,tServiceKeys,.tServices,.tTruncated)

	#; Convert to %Boolean
	Set tTruncated=$$$ToBoolean(tTruncated)
	
	Quit:$g(tServices)="" 
	
	Set tCount = tServices.Count()
	Quit:tCount<1
	
	Set pService = tServices.GetAt(1)
	
	$$$EPILOGUE
}

ClassMethod TestShowKeys(pServerIP As %String, pServiceKey As EnsLib.UDDI.uddi.serviceKey)
{
	#dim tPublisher As UnpublishService
	#dim tSC As %Status
	#dim tBindingKeys 	As %ListOfDataTypes
	#dim tTModelKeys  	As %ListOfDataTypes
	#dim tCount 		As %Integer
	#dim i		 		As %Integer

	Set tBindingKeys = ##class(%ListOfDataTypes).%New()
	Set tTModelKeys  = ##class(%ListOfDataTypes).%New()
	
	$$$NEW(tPublisher,"EnsLib.UDDI.UnpublishService")
	
	Set tSC = tPublisher.Connect(pServerIP)
	Quit:$$$ISERR(tSC)
	
	w "Connected to OpenUDDI Server at "_pServerIP, !
	
	Set tSC = tPublisher.FindBindingsAndTModels(pServiceKey,.tBindingKeys,.tTModelKeys)
	if ($$$ISERR(tSC)) {
		d $system.OBJ.DisplayError(tSC)
		Quit
	}
	
	Set tCount = tBindingKeys.Count()
	W "Binding Keys: "_tCount, !
	For i=1:1:tCount {
		W "    "_tBindingKeys.GetAt(i), !
	}
	
	Set tCount = tTModelKeys.Count()
	W "TModel Keys: "_tCount, !
	For i=1:1:tCount {
		W "    "_tTModelKeys.GetAt(i), !
	}
}

ClassMethod TestDeleteOneService(pServerIP As %String, pServiceKey As EnsLib.UDDI.uddi.serviceKey)
{
	#dim tPublisher As UnpublishService
	#dim tSC As %Status

	$$$NEW(tPublisher,"EnsLib.UDDI.UnpublishService")
	
	Set tSC = tPublisher.Connect(pServerIP)
	Quit:$$$ISERR(tSC)
	
	w "Connected to OpenUDDI Server at "_pServerIP, !
	
	Set tSC = tPublisher.DeleteServiceRecursively(pServiceKey)
	if ($$$ISERR(tSC)) {
		d $system.OBJ.DisplayError(tSC)
	}

	Quit tSC
}

ClassMethod TestDeleteAllServices(pServerIP As %String, pBusinessName As %String)
{
	#dim tPublisher As UnpublishService
	#dim tSC As %Status

	$$$NEW(tPublisher,"EnsLib.UDDI.UnpublishService")
	
	Set tSC = tPublisher.Connect(pServerIP)
	Quit:$$$ISERR(tSC)
	
	w "Connected to OpenUDDI Server at "_pServerIP, !
	
	Set tSC = tPublisher.DeleteAllServicesForBusiness(pBusinessName)
	if ($$$ISERR(tSC)) {
		d $system.OBJ.DisplayError(tSC)
	}

	Quit tSC
}

}
