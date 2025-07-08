/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

IncludeGenerator %ZEN.Utils

/// Base class for Zen data documents.
/// A data document presents a document (object graph) that can be served to a web page
/// (via a jsonProvider) and consumed by various visual components.
Class %ZEN.DataModel.AbstractDocument Extends %RegisteredObject [ Abstract, Deprecated, System = 3 ]
{

Projection DocumentProjection As %ZEN.DataModel.DocumentProjection;

/// Logical name of this document class.
/// If not provided, the document class name is used.
/// Names are case-sensitive.
Parameter DOCUMENTCLASS As STRING;

/// Return the logical name of this document class.
ClassMethod %GetDocumentName() As %String [ CodeMode = objectgenerator, Final ]
{
	If (%class.Abstract) {
		Do %code.WriteLine(" Quit """"")
		Quit $$$OK
	}

	Set tClassName = %compiledclass.Name
	Set tDocName = $G(%parameter("DOCUMENTCLASS"))
	Set:tDocName="" tDocName = tClassName

	If (tDocName["/") {
		Quit $$$ERROR($$$GeneralError,"Document name cannot contain '/': " _ tDocName)
	}

	// test for name re-use
	If ($E(%compiledclass.Name)="%") {
		Set tOldName = $G(^%ISC.ZEN.Documents("docs",tDocName))
	}
	Else {
		Set tOldName = $G(^ISC.ZEN.Documents("docs",tDocName))
	}

	If ((tOldName'="") && (tOldName'=tClassName)) {
		Quit $$$ERROR($$$GeneralError,"Document name is already in use: " _ tDocName)
	}

	Do %code.WriteLine(" Quit "_$$$quote(tDocName))
	Quit $$$OK
}

/// Retrieve a data document.<br/>
/// <var>pID</var> is the document instance id.<br/>
/// <var>pParms</var> is an optional set of additional parameters (passed in from a jsonProvider).<br/>
/// <var>pDocument</var> is the data document.<br/>
ClassMethod %GetDocument(pID As %String, ByRef pParms, Output pDocument As %ZEN.proxyObject) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set pDocument = ""
		
		// create an instance of *this* interface object and
		// then use to create a document object
		Set tObj = ..%New()
		Set tSC = tObj.%OnGetDocument(pID,.pParms,.pDocument)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Process a request for a data document.
/// This is implemented by subclasses.<br/>
/// <var>pID</var> is the document instance id.<br/>
/// <var>pParms</var> is an optional set of additional parameters (passed in from a jsonProvider).<br/>
/// <var>pDocument</var> is the data document.<br/>
Method %OnGetDocument(pID As %String, ByRef pParms, Output pDocument As %ZEN.proxyObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pDocument = ##class(%ZEN.proxyObject).%New()
		Set pDocument.name = "Simpson, Homer J."
		Set pDocument.age = 48
		Set pDocument.sex = "M"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
