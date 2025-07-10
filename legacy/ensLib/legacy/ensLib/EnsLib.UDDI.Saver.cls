/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.Saver Extends EnsLib.UDDI.Base [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is the username required for publishing to a UDDI registry. You will
/// need to provide a legitimate username for the server referenced above.
Parameter UserName As String = "admin";

/// This is the password required for publishing to a UDDI registry. You will
/// need to provide the password corresponding to the UserName above
Parameter Password As String = "admin";

/// Host of OpenUDDI Server
Parameter Host As %String = "localhost";

/// Port of OpenUDDI Server
Parameter Port As %String = 8080;

Property Connection As Connection;

Method Connect(pHost As %String = {..#Host}, pPort As %String = {..#Port}, pUserName As %String = {..#UserName}, pPassword As %String = {..#Password}) As %Status
{
	#dim tSC As %Status
	#dim url As %String

	Set url = "http://"_pHost_":"_pPort_"/uddi/services"

	#dim tPolicy As %RegisteredObject
	
	$$$PROLOGUE
	
	$$$NEW1(tPolicy,$$$URLRESOLVERPOLICYCLASS,url)
	
	#; Create a connection using that policy
	$$$NEW1(..Connection,"EnsLib.UDDI.Connection",tPolicy)
	
	#; Acquire credentials
	Set tSC=..Connection.AcquireAuthorization(pUserName,pPassword)

	If $$$ISERR(tSC) d $system.OBJ.DisplayError(tSC)
	
	$$$EPILOGUE
}

}
