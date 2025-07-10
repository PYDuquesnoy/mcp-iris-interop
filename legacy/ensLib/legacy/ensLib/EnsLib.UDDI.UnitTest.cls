/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

/// UnitTest for the EnsLib.UDDI package. Assumes using the openUDDI server with version 3 of the UDDI Specification
Class EnsLib.UDDI.UnitTest Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is the base URL used to access the server. You will need
/// to supply a URL to a server to which you have inquiry access
Parameter BaseURL As String = "http://localhost:8080/uddi/services";

/// This is the username required for publishing to a UDDI registry. You will
/// need to provide a legitimate username for the server referenced above.
Parameter UserName As String = "admin";

/// This is the password required for publishing to a UDDI registry. You will
/// need to provide the password corresponding to the UserName above
Parameter Password As String = "admin";

ClassMethod TestBusiness(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tBusinessKey As EnsLib.UDDI.uddi.businessKey
	
	$$$PROLOGUE
		
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit
	
	#; Save a business
	Set tSC=##class(EnsLib.UDDI.SaveBusiness).Test(tConnection,.tBusinessKey)
	If $$$ISERR(tSC) Quit
		
	#; Delete the business
	Set tSC=##class(EnsLib.UDDI.DeleteBusiness).Test(tConnection,tBusinessKey)
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestService(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tBusinessKey As EnsLib.UDDI.uddi.businessKey
	#dim tServiceKey As EnsLib.UDDI.uddi.serviceKey
	
	$$$PROLOGUE
	
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit
	
	#; Save a business
	Set tSC=##class(EnsLib.UDDI.SaveBusiness).Test(tConnection,.tBusinessKey)
	If $$$ISERR(tSC) Quit
		
	#; Create a service, the service references the business we have just created
	Set tSC=##class(EnsLib.UDDI.SaveService).Test(tConnection,tBusinessKey,.tServiceKey)
	If $$$ISERR(tSC) Quit
		
	#; Delete the service
	Set tSC=##class(EnsLib.UDDI.DeleteService).Test(tConnection,tServiceKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the business
	Set tSC=##class(EnsLib.UDDI.DeleteBusiness).Test(tConnection,tBusinessKey)
	If $$$ISERR(tSC) Quit

	$$$EPILOGUE
}

ClassMethod TestTModel(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tTModelKey As EnsLib.UDDI.uddi.tModelKey
	
	$$$PROLOGUE
	
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit
	
	#; Save a TModel
	Set tSC=##class(EnsLib.UDDI.SaveTModel).Test(tConnection,.tTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the TModel
	Set tSC=##class(EnsLib.UDDI.DeleteTModel).Test(tConnection,tTModelKey)
	If $$$ISERR(tSC) Quit

	$$$EPILOGUE
}

ClassMethod TestBinding(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tBusinessKey As EnsLib.UDDI.uddi.businessKey
	#dim tServiceKey As EnsLib.UDDI.uddi.serviceKey
	#dim tTModelKey As EnsLib.UDDI.uddi.tModelKey
	#dim tBindingKey As EnsLib.UDDI.uddi.bindingKey
	
	$$$PROLOGUE
	
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit
	
	#; Save a business
	Set tSC=##class(EnsLib.UDDI.SaveBusiness).Test(tConnection,.tBusinessKey)
	If $$$ISERR(tSC) Quit

	#; Save a service, the service references the business we have just created
	Set tSC=##class(EnsLib.UDDI.SaveService).Test(tConnection,tBusinessKey,.tServiceKey)
	If $$$ISERR(tSC) Quit
	
	#; Save a tModel
	Set tSC=##class(EnsLib.UDDI.SaveTModel).Test(tConnection,.tTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Save a binding
	Set tSC=##class(EnsLib.UDDI.SaveBinding).Test(tConnection,tBusinessKey,tServiceKey,tTModelKey,.tBindingKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the binding
	Set tSC=##class(EnsLib.UDDI.DeleteBinding).Test(tConnection,tBindingKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the tModel
	Set tSC=##class(EnsLib.UDDI.DeleteTModel).Test(tConnection,tTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the service
	Set tSC=##class(EnsLib.UDDI.DeleteService).Test(tConnection,tServiceKey)
	If $$$ISERR(tSC) Quit

	#; Delete the business
	Set tSC=##class(EnsLib.UDDI.DeleteBusiness).Test(tConnection,tBusinessKey)
	If $$$ISERR(tSC) Quit

	$$$EPILOGUE
}

ClassMethod TestFindBusiness(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tBusinessKey As EnsLib.UDDI.uddi.businessKey
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Find the business
	Set tSC=##class(EnsLib.UDDI.FindBusiness).Test(tConnection,"Dire Predictions Incorporated")
	If $$$ISERR(tSC) Quit
		
	$$$EPILOGUE
}

ClassMethod TestFindService(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Find the almanac service
	Set tSC=##class(EnsLib.UDDI.FindService).Test(tConnection,"Almanac Service")
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestFindTModel(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Find the TModel
	Set tSC=##class(EnsLib.UDDI.FindTModel).Test(tConnection,"Almanac Interface")
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestGetBindingDetail(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Get the detail for this binding
	Set tSC=##class(EnsLib.UDDI.GetBindingDetail).Test(tConnection,"uddi:intersystems.com:f5772f15-0e68-4e93-9271-27d27abc6eb9")
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestGetBusinessDetail(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Get the detail for this binding
	Set tSC=##class(EnsLib.UDDI.GetBusinessDetail).Test(tConnection,"uddi:intersystems.com:8a47ddc6-3b20-493c-a6db-a71a71141b7d")
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestGetServiceDetail(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Get the detail for this binding
	Set tSC=##class(EnsLib.UDDI.GetServiceDetail).Test(tConnection,"uddi:intersystems.com:fcfc0d43-16fc-4eba-888f-15b0d473e0c7")
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestGetTModelDetail(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	
	$$$PROLOGUE
	
	#; Create a connection
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit

	#; Get the detail for this binding
	Set tSC=##class(EnsLib.UDDI.GetTModelDetail).Test(tConnection,"uddi:intersystems.com:fa7513da-3cd5-4631-a016-bc65b17e6073")
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

ClassMethod TestFindBinding(pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tBusinessKey As EnsLib.UDDI.uddi.businessKey
	#dim tServiceKey As EnsLib.UDDI.uddi.serviceKey
	#dim tTModelKey As EnsLib.UDDI.uddi.tModelKey
	#dim tBindingKey As EnsLib.UDDI.uddi.bindingKey
	
	$$$PROLOGUE
	
	Set tSC=..CreateConnection(.tConnection,pBaseURL,pUserName,pPassword)
	If $$$ISERR(tSC) Quit
	
	#; Save a business
	Set tSC=##class(EnsLib.UDDI.SaveBusiness).Test(tConnection,.tBusinessKey)
	If $$$ISERR(tSC) Quit

	#; Save a service, the service references the business we have just created
	Set tSC=##class(EnsLib.UDDI.SaveService).Test(tConnection,tBusinessKey,.tServiceKey)
	If $$$ISERR(tSC) Quit
	
	#; Save a tModel
	Set tSC=##class(EnsLib.UDDI.SaveTModel).Test(tConnection,.tTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Save a binding
	Set tSC=##class(EnsLib.UDDI.SaveBinding).Test(tConnection,tBusinessKey,tServiceKey,tTModelKey,.tBindingKey)
	If $$$ISERR(tSC) Quit
	
	#; Find the binding
	Set tSC=##class(EnsLib.UDDI.FindBinding).Test(tConnection,tServiceKey,tTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the binding
	Set tSC=##class(EnsLib.UDDI.DeleteBinding).Test(tConnection,tBindingKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the tModel
	Set tSC=##class(EnsLib.UDDI.DeleteTModel).Test(tConnection,tTModelKey)
	If $$$ISERR(tSC) Quit
	
	#; Delete the service
	Set tSC=##class(EnsLib.UDDI.DeleteService).Test(tConnection,tServiceKey)
	If $$$ISERR(tSC) Quit

	#; Delete the business
	Set tSC=##class(EnsLib.UDDI.DeleteBusiness).Test(tConnection,tBusinessKey)
	If $$$ISERR(tSC) Quit

	$$$EPILOGUE
}

/// Helper method to Create a connection
ClassMethod CreateConnection(Output pConnection As EnsLib.UDDI.Connection, pBaseURL As %String = {..#BaseURL}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password})
{
	#dim tSC As %Status
	#dim tPolicy As %RegisteredObject
	
	$$$PROLOGUE
	
	$$$NEW1(tPolicy,$$$URLRESOLVERPOLICYCLASS,pBaseURL)
	
	#; Create a connection using that policy
	$$$NEW1(pConnection,"EnsLib.UDDI.Connection",tPolicy)
	
	#; Acquire credentials
	Set tSC=pConnection.AcquireAuthorization(pUserName,pPassword)
	If $$$ISERR(tSC) Quit
	
	$$$EPILOGUE
}

}
