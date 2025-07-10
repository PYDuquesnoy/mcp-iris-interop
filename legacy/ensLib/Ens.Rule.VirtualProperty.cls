/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %occXSLT)

/// Expression Parser for RuleSets.
Class Ens.Rule.VirtualProperty Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// This method evaluate the virtual property syntax: object.(property)
ClassMethod getParenSyntax(object As %RegisteredObject, property As %String) As %String
{
	quit "<"_object.GetValues(property,,"><")_">"
}

/// This method evaluate the virtual property syntax: object.[property]
ClassMethod getSquareSyntax(object As %RegisteredObject, property As %String) As %String
{
	quit "<"_object.FindSegmentValues(property,,"><")_">"
}

/// Deprecated
ClassMethod getAngelSyntax(pStream, pExpression, Output pStatus As %Status) As %String [ CodeMode = expression, Internal ]
{
..getAngleSyntax(.pStream,.pExpression,.pStatus)
}

/// This method evaluate the virtual property syntax: object.<property>
ClassMethod getAngleSyntax(pStream, pExpression, Output pStatus As %Status) As %String
{
	Set tDocument=$G($$$EnsJobLocal("CurrentXPATHDoc")), pStatus=$$$OK
	If '$IsObject(tDocument) {
		If '$IsObject(pStream) {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(##class(%IO.StringStream).%New(pStream),.tDocument)
		} ElseIf pStream.%Extends("%Stream.Object") || pStream.%Extends("%IO.I.Stream") {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(pStream,.tDocument)
		} ElseIf pStream.%Extends("Ens.StringContainer") || pStream.%Extends("Ens.StringRequest") || pStream.%Extends("Ens.StringResponse") {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(##class(%IO.StringStream).%New(pStream.StringValue),.tDocument)
		} ElseIf pStream.%Extends("Ens.StreamContainer") {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(pStream.Stream,.tDocument)
		} Else {
			Set pStatus=##class(%XML.XPATH.Document).CreateFromStream(pStream,.tDocument)
		}
		Quit:$$$ISERR(pStatus) ""  If '$IsObject(tDocument) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Failed to create %XML.XPATHDocument for "_pStream)  Quit ""
		Set $$$EnsJobLocal("CurrentXPATHDoc")=tDocument
		Set:pStream.%IsA("%Persistent") $$$EnsJobLocal("CurrentXPATHDoc","oid")=pStream.%Oid
	}
	// We have the document, evaluate the expression and obtain the reader
	If pExpression["|" { Set tContext=$P(pExpression,"|"), pExpression=$P(pExpression,"|",2,9999) }
	Else { Set tContext="/" }
	Set pStatus=tDocument.EvaluateExpression(tContext,pExpression,.tResults)
	
	Set tResultStr="<"
	Set n=tResults.Count()
	For i=1:1:n {		
		Set tResult = tResults.GetAt(i)
		If $IsObject(tResult) Set tVal=$S(tResult.Type=$$$XPATHDOM:"--XPATHDOM--",1:tResult.Value)  Set:""'=tVal tResultStr=tResultStr_tVal_"><"
	}
	Quit $E(tResultStr,1,*-1)
}

}
