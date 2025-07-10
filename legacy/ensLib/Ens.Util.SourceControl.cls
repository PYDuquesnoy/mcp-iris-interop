/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Util.SourceControl Extends %CSP.Portal.SourceControl.Util [ Abstract, System = 4 ]
{

/// Callback to initialize instance of %Studio.SourceControl.Base for InterSystems IRIS Interoperability purposes.
Method OnPortalCreate(pUserData As %ZEN.proxyObject = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = ..OnEnsembleCreate(pUserData)
	}
	Catch ex { // ignore errors
		Set tStatus = $$$OK
	}
	Quit tStatus
}

/// Callback to initialize instance of %Studio.SourceControl.Base for InterSystems IRIS Interoperability purposes.
Method OnEnsembleCreate(pUserData As %ZEN.proxyObject = "") As %Status
{
	Set tStatus = $$$OK
	If ..IsProjectRequired() {
		Set tProject = ..GetCurrentProject(.tLoaded)
		If (tProject '= "") && ('tLoaded) {
			Set tStatus =..OnBeforeLoad(tProject)
			If $$$ISOK(tStatus) {
				Set tStatus = ..OnAfterLoad(tProject)
			}
		}
	}
	Quit tStatus
}

}
