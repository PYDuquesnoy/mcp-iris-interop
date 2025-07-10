/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsLib.uddi

Class EnsLib.UDDI.GetAuthToken Extends EnsLib.UDDI.Base [ ClassType = "", ProcedureBlock, System = 4 ]
{

Method Send(pConnection As EnsLib.UDDI.Connection, Output pAuthToken As EnsLib.UDDI.uddi.authToken) As %Status
{
	#dim tClient As %RegisteredObject
	
	$$$PROLOGUE 
		 
	#; Create a the web client instance
	$$$NEW(tClient,$$$UDDISECURITYCLASS)

	#; Set the location
	Set tClient.Location=pConnection.SecurityURL,tClient.Timeout=..Timeout

	#; Find the auth token
	Set pAuthToken=tClient.getauthToken(pConnection.UserName,pConnection.Password)
		 
	$$$EPILOGUE
}

/// Test the class functionality by performing an inquiry for an authorization token
ClassMethod Test(pBaseURL As %String, pUserName As %String, pPassword As %String, Output pAuthToken As %String) As %Status
{
	#dim tSC As %Status
	#dim tPolicy As %RegisteredObject
	#dim tConnection As EnsLib.UDDI.Connection
	#dim tGetToken As EnsLib.UDDI.GetAuthToken
	
	$$$PROLOGUE
	
	Write !!!,"Test GetAuthToken",!!
	
	#; Create an URL Resolution Policy
	$$$NEW1(tPolicy,$$$URLRESOLVERPOLICYCLASS,pBaseURL)
	
	#; Create a connection using that policy
	$$$NEW1(tConnection,"EnsLib.UDDI.Connection",tPolicy)
	
	Set tConnection.UserName=pUserName,tConnection.Password=pPassword
	
	#; Want to retrieve an Authentication Token
	$$$NEW(tGetToken,"EnsLib.UDDI.GetAuthToken")
	
	#; Send the request to the Server
	Set tSC=tGetToken.Send(tConnection,.pAuthToken)
	If $$$ISERR(tSC) Quit
	
	Write !,"Received Authorization Token",!
	Write !,pAuthToken
		
	$$$EPILOGUE
}

}
