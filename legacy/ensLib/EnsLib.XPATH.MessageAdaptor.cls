/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occXSLT, EnsXPATHErrors)

/// This is a mixin class that provides a convenient means of evaluating XPATH expressions 
/// the contents of messages containing XML
Class EnsLib.XPATH.MessageAdaptor Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This is the Parsed document against which XPATH expressions are evaluated
Property Document As %XML.XPATH.Document [ Transient ];

/// Override this method in your message subclass to return the XmlStream on which to evaluate XPATH expressions
Method XmlStream(Output pStream As %Stream.Object) As %Status
{
	// Subclass responsibility, this example retrieves its XML stream from the XData block called ExampleXML
	// within THIS class. You will want to return the value of the property which contains YOUR Xml stream.
	Set tSC=##class(Ens.Util.XML.XDataEntityResolver).EntityFromXDATA(.pStream,"EnsLib.XPATH.MessageAdaptor","ExampleXML")
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

/// Evaluate an XPATH expression, obtaining a reader which can be used to read the results
Method Evaluate(pContext As %String, pExpression As %String, Output pResults As %ListOfObjects(CLASSNAME="%XML.XPATH.RESULT")) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	do {

		If '$IsObject(..Document) {
			
			// Get the Stream
			Set tSC=..XmlStream(.tStream) If $$$ISERR(tSC) Quit
			
			// Document doesn't exist so create it
			Set tSC=##class(%XML.XPATH.Document).CreateFromStream(tStream,.tDocument) If $$$ISERR(tSC) Quit
			
			// Cache the document
			Set ..Document=tDocument
		}
		
		// We have the document, evaluate the expression and obtain the reader
		Set tSC=..Document.EvaluateExpression(pContext,pExpression,.pResults)
		
	} while (0)
Exit Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

/// Often you know that a given XPATH expression will retrieve just a single result, this is a convenience method
/// which performs the intermediate steps to evaluate the expression obtain that result for you. If the expression
Method GetSingleValue(pContext As %String, pExpression As %String, Output pResultValue As %String) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	do {
		
		// Evaluate the expression and obtain the reader
		Set tSC=..Evaluate(pContext,pExpression,.tResults) If $$$ISERR(tSC) Quit
		
		If (tResults.Count()=1) {
			
			Set tResult = tResults.GetAt(1)
			
			If tResult.Type=$$$XPATHDOM {
				Set tSC=$$$ERROR($$$EnsXPATHXPathDOMResult) Quit
			}
			Set pResultValue = tResult.Value
				
		} elseif tResults.Count()=0 {
			
			// No match, thats an error
			Set tSC=$$$ERROR($$$EnsXPATHXPathNOResult)
			
		} else {
			
			// Multiple results, thats an error too
			Set tSC=$$$ERROR($$$EnsXPATHXPathMultipleResults)
		}
		
	} while (0)
Exit Quit tSC
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

ClassMethod Example()
{
	Set tSC=$$$OK,$ZT="Trap"
	do {
		Kill %objlasterror
		Set tMessageAdaptor=..%New() If '$IsObject(tMessageAdaptor) Set tSC=%objlasterror Quit
		
		// Should return 2, the number of doc elements
		Set tSC=tMessageAdaptor.GetSingleValue("/staff","count(doc)",.tValue) If $$$ISERR(tSC) Quit
		
		Write !,tValue
		
		Set tSC=tMessageAdaptor.GetSingleValue("/staff/doc/name[@last='Marston']","@first",.tValue) If $$$ISERR(tSC) Quit
		
		Write !,tValue
		
	} while (0)
Exit If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
	Quit
Trap Set tSC=$$$ERROR($$$ObjectScriptError,$ZE) Goto Exit
}

/// This is an example of XML, See the Example() method for details
XData ExampleXML
{
<?xml version="1.0"?>
<staff>
<doc type="consultant">
  <name first="David" last="Marston">Mr. Marston</name>
  <name first="David" last="Bertoni">Mr. Bertoni</name>
  <name first="Donald" last="Leslie">Mr. Leslie</name>
  <name first="Emily" last="Farmer">Ms. Farmer</name>
</doc>
<doc type="GP">
  <name first="Myriam" last="Midy">Ms. Midy</name>
  <name first="Paul" last="Dick">Mr. Dick</name>
  <name first="Scott" last="Boag">Mr. Boag</name>
  <name first="Shane" last="Curcuru">Mr. Curcuru</name>
  <name first="Joseph" last="Kesselman">Mr. Kesselman</name>
  <name first="Stephen" last="Auriemma">Mr. Auriemma</name>
</doc>
</staff>
}

}
