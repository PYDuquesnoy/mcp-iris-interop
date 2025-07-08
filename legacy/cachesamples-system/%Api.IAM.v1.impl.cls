/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// API for managing the IAM License for InterSystems IRIS.<br/>
/// Business logic class defined by OpenAPI in %Api.IAM.v1.spec<br/>
/// Updated Feb 13, 2025 16:24:20
Class %Api.IAM.v1.impl Extends %REST.Impl
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 1;

/// Get the JSON string of your IAM License Key from your licensed InterSystems IRIS instance.
ClassMethod getLicense() As %DynamicObject
{
    #Dim sc as %Status = $$$OK
	#Dim e as %Exception.AbstractException
	#Dim licensetext as %DynamicObject = {}
	#Dim httpstatus as %String = $PARAMETER("%CSP.REST","HTTP500INTERNALSERVERERROR")

	Try {
		#; Attempt to acquire lock on this URL.
		Lock +^IRIS.iamlicense:5 Else  Set httpstatus = $PARAMETER("%CSP.REST","HTTP423LOCKED"), sc = $$$ERROR($$$LockFailedToAcquireExclusive,"^IRIS.iamlicense") Quit
		
		#; Get the active license key
		Set keylines = $LISTFROMSTRING($ZUTIL(201,2),$CHAR(0)), iniamsection = 0, ptr = 0
		
		#; Loop through key and look for the IAM key
		While $LISTNEXT(keylines,ptr,line) {
			If line = "[ISC.IAM]" Set iniamsection = 1
			If iniamsection, $PIECE(line,"=") = "Key" Set licensetext = ##class(%DynamicObject).%FromJSON($ZSTRIP($PIECE(line,"=",2,*),"<>W")) Quit
		}
		
		#; If we didn't find a key, report a 204 status
		If licensetext.%Size() = 0 {
			Set httpstatus = $PARAMETER("%CSP.REST","HTTP204NOCONTENT")
			Set sc = $$$ERROR($$$IAMKeyDoesNotExist)
		}
	} Catch e {Set sc = e.AsStatus()}
	Lock -^IRIS.iamlicense
	If $$$ISERR(sc) Do ..%ReportRESTError(httpstatus,sc,..#ExposeServerExceptions)
	Quit licensetext
}

}
