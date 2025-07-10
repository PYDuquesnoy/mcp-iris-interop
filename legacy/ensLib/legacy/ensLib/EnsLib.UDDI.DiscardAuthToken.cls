/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

Class EnsLib.UDDI.DiscardAuthToken Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

Method Send(pConnection As EnsLib.UDDI.Connection) As %Status
{
	#dim tClient As %RegisteredObject
	
	$$$PROLOGUE
	
	$$$NEW(tClient,$$$UDDISECURITYCLASS)
	
	#; Set the location
	Set tClient.Location=pConnection.SecurityURL,tClient.Timeout=..Timeout

	#; Perform the operation
	Do tClient.discardauthToken(pConnection.AuthInfo)
	
	$$$EPILOGUE
}

/// Test the class functionality by performing an inquiry for an authorization token
ClassMethod Test(pBaseURL As %String, pAuthToken As %String) As %Status
{
	#dim tSC As %Status
	#dim tPolicy As %RegisteredObject
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tDiscardToken As EnsLib.UDDI.DiscardAuthToken
	
	$$$PROLOGUE
		
	Write !!!,"Test DiscardAuthToken",!!

	#; Create an URL Resolution Policy
	$$$NEW1(tPolicy,$$$URLRESOLVERPOLICYCLASS,pBaseURL)
	
	#; Create a connection using that policy
	$$$NEW1(tConnection,"EnsLib.UDDI.Connection",tPolicy)
	
	#; Plug in the token you wish to discard
	Set tConnection.AuthInfo=pAuthToken

	#; Want to discard an Authentication Token
	$$$NEW(tDiscardToken,"EnsLib.UDDI.DiscardAuthToken")
	
	#; Send the request to the Server
	Do tDiscardToken.Send(tConnection)
		
	$$$EPILOGUE
}

}
