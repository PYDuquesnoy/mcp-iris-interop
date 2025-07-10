/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occXSLT

/// Defines a set of properties derived from XML Stream objects embedded in class 'Ens.StreamContainer'
/// that can be used in SQL to locate and join to XML documents of interest.
Class Ens.VDoc.XMLSearchTable Extends Ens.VDoc.SearchTable [ Abstract, ProcedureBlock, System = 3 ]
{

Parameter DOCCLASS = "Ens.StreamContainer";

/// Returns True if the given expression will return multiple values
ClassMethod IsListExpression(tGetExpression As %String) As %Boolean [ CodeMode = expression ]
{
1
}

/// Generates an expression that 1) evaluates to a string value and 2) sets status code 'tSCGet'
ClassMethod genGetCode(tGetExpression As %String) As %String [ CodeMode = expression ]
{
"*Only Lists Supported for XPATH*"
}

/// Generates an expression that sets an array of values found in 'tList' and 2) sets status code 'tSCGet'
/// It may evaluate to a string but we intend to ignore that.
ClassMethod genGetCodeList(tGetExpression As %String, tPreExpr As %String, tPostExpr As %String) As %String
{
 	#; cheezy pre-parser for curly-bracket list and square-bracket syntax
	Set (tPreExpr,tPostExpr) = ""
	#; extract piece of expression which appears before all virtual property syntax
	Set:$Case($E(tGetExpression),"{":0,:1) tPreExpr=$P(tGetExpression,"{")
	#; extract piece of expression which appears after all virtual property syntax
	Set:$Case($E(tGetExpression,*),"}":0,:1) tPostExpr=$P(tGetExpression,"}",*)
	Set tGetExpression=$E(tGetExpression,$L(tPreExpr)+1,*-$L(tPostExpr))

	While tGetExpression["{" { Set tGetExpression=$ZSTRIP($P(tGetExpression,"{"),"<>W")_"..GetXPathValues(pDocObj,"""_$ZSTRIP($P(tGetExpression,"{",2,$L(tGetExpression,"{")),"<>W") }
	While tGetExpression["}" { Set tGetExpression=$ZSTRIP($P(tGetExpression,"}"),"<>W")_""",.tList,.tSCGet)"_$ZSTRIP($P(tGetExpression,"}",2,$L(tGetExpression,"}")),"<>W") }
	Quit tGetExpression
}

ClassMethod GetXPathValues(pStream As %RegisteredObject, pExpression As %String, Output pArray, Output pStatus As %Status)
{
	Set pStatus=$$$OK, tID=pStream.%Oid()  Kill pArray
	If tID=$G($$$EnsJobLocal("CurrentXPATHDoc","oid")) { Set tDocument=$$$EnsJobLocal("CurrentXPATHDoc") }
	Else { Kill $$$EnsJobLocal("CurrentXPATHDoc","oid") Set tDocument=$$$NULLOREF }
	If '$IsObject(tDocument) {
		Set pStatus=##class(%XML.XPATH.Document).CreateFromStream($S(pStream.%Extends("Ens.StreamContainer"):pStream.Stream,1:pStream),.tDocument)
		Quit:$$$ISERR(pStatus)  If '$IsObject(tDocument) Set pStatus=$$$ERROR($$$EnsErrGeneral,"Failed to create %XML.XPATHDocument for "_tID)  Quit
		#; Cache the document and its Id value in the local environment
		Set:""'=tID $$$EnsJobLocal("CurrentXPATHDoc","oid")=tID, $$$EnsJobLocal("CurrentXPATHDoc")=tDocument
	}
	// We have the document, evaluate the expression and obtain the match results
	If pExpression["|" { Set tContext=$P(pExpression,"|"), pExpression=$P(pExpression,"|",2,9999) }
	Else { Set tContext="/" }
	Set pStatus=tDocument.EvaluateExpression(tContext,pExpression,.tResults)
	
	Set n=tResults.Count()
	For i=1:1:n {		
		Set tResult = tResults.GetAt(i)
		If $IsObject(tResult) Set tVal=$S(tResult.Type=$$$XPATHDOM:"--XPATHDOM--",1:tResult.Value)  Set:""'=tVal pArray(tVal)=""
	}
}

Storage Default
{
<Data name="XMLSearchTableDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DocId</Value>
</Value>
<Value name="3">
<Value>PropId</Value>
</Value>
<Value name="4">
<Value>PropValue</Value>
</Value>
</Data>
<DataLocation>^Ens.VDoc.XMLSearchTableD</DataLocation>
<DefaultData>XMLSearchTableDefaultData</DefaultData>
<IdLocation>^Ens.VDoc.XMLSearchTableD</IdLocation>
<IndexLocation>^Ens.VDoc.XMLSearchTableI</IndexLocation>
<StreamLocation>^Ens.VDoc.XMLSearchTableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
