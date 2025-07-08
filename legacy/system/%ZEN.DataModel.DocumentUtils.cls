/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

IncludeGenerator %ZEN.Utils

/// Contains various API methods for Zen data documents.
Class %ZEN.DataModel.DocumentUtils Extends %RegisteredObject [ Abstract, Deprecated, System = 3 ]
{

/// Process a request for a data document.
/// Find the document class with the given document id (class/instance) and dispatch to it
/// to do the work.<br/>
/// <var>pParms</var> is an optional set of additional parameters (passed in from a jsonProvider).<br/>
/// <var>pDocument</var> is the data document.<br/>
ClassMethod %GetDocument(pDocumentId As %String, ByRef pParms, Output pDocument As %ZEN.proxyObject) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set pDocument = ""

		// split id and find class
		Set tDocName = $P(pDocumentId,"/",1)
		Set tDocInstance = $P(pDocumentId,"/",2,999)

		// first look locally, then in the mgr database
		Set tDocClass = $G(^ISC.ZEN.Documents("docs",tDocName))
		Set:tDocClass="" tDocClass = $G(^%ISC.ZEN.Documents("docs",tDocName))

		If (tDocClass="") {
			Set tSC = $$$ERROR($$$GeneralError,"Document not found: ",pDocumentId)
			Quit
		}
		
		// dispatch
		Set tSC = $classmethod(tDocClass,"%GetDocument",tDocInstance,.pParms,.pDocument)
		If $$$ISERR(tSC) Quit

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
