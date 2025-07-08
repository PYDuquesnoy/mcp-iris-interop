/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The parent class to use for the geenrated API management dispatch class.
Class %REST.disp Extends %CSP.REST [ System = 4 ]
{

ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status [ Internal ]
{
	// This is a bit of a hack, we have to insist that the third piece of the 
	// url is the namespace in order to access check, but so be it ...
	If pUrl="/" {
		Set namespace="%SYS"
	} Else {
		Set namespace=$piece(pUrl,"/",3)
	}

	If '##class(%Api.Mgmnt.v2.impl).%AdjustNamespace(namespace,0) {
		Set pContinue=0
	}
		
	Quit $$$OK
}

/// Override AccessCheck to defer access checking until OnPreDispatch.
ClassMethod AccessCheck(Output pAuthorized As %Boolean = 0) As %Status [ Internal ]
{
	Set sc=$$$OK
	Try {
		Set pAuthorized=1
	} Catch (ex) {
		set sc=ex.AsStatus()
	}
	quit sc
}

}
