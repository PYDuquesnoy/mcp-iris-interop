/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSLT

/// 
/// *** Deprecated class, please use %XML.XPATH.Document for XPATH expression evaluation ***
/// 
Class %XML.XPATH.Reader Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property Results As list Of %XML.XPATH.Result;

/// Evaluate an XPATH expression on a previously obtained XPATH document. Return an %XML.XPATH.Reader object which
/// provides facilities to access the results in a simple manner
ClassMethod Evaluate(pDocument As %XML.XPATH.Document, pContext As %String, pExpression As %String, Output pReader As %XML.XPATH.Reader) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	do {
		#; Create an instance of the TreeBuilder, this will be the XPATH result handler
		Set tHandler=##class(%XML.XPATH.Utils.TreeBuilder).%New()
		If '$IsObject(tHandler) Set tSC=%objlasterror Quit
	
		#; The result handler will insert the results into this collection
		Set tHandler.Results=##class(%ListOfObjects).%New("%XML.XPATH.Result")
	
		#; Now evaluate the expression on the supplied XPATH Document
		Set tSC=pDocument.Evaluate(pContext,pExpression,tHandler)
		If $$$ISERR(tSC) Quit
		
		#; Create and return instance of this class
		Set pReader=..%New(tHandler.Results)
		If '$IsObject(pReader) Set tSC=%objlasterror
		
	} while (0)
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Property Keys As array Of %Integer;

/// Initialize
Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..Results=initvalue
	Quit $$$OK
}

ClassMethod Example()
{
	Write !,"*** Deprecated , See %XML.XPATH.Document for examples ***"
}

}
