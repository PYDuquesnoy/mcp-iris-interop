/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SOAP.RequestMessage is the abstract base class for objects which represent the request message 
/// for a SOAP request.  Subclasses of %SOAP.RequestMessage serve as the argument to the
/// SendSOAPRequest method of %SOAP..WebClient subclasses.
Class %SOAP.RequestMessage Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, System = 3 ]
{

/// Dummy %RequestName
Property %RequestName As %String(XMLPROJECTION = "none") [ Internal, ServerOnly = 1 ];

/// Save the document containg the return message here.
Property %ResponseDocument As %XML.Document(XMLPROJECTION = "none") [ Internal, ServerOnly = 1 ];

/// Save the node id of the message node of the return message here.
Property %ResponseNodeId As %String(XMLPROJECTION = "none") [ Internal, ServerOnly = 1 ];

/// Callback from %SOAP.WebClient to return the response body.
Method ReturnResponse(document As %XML.Document, messageId As %String) As %Status [ Internal ]
{
	Set ..%ResponseDocument=document
	Set ..%ResponseNodeId=messageId
	Quit $$$OK
}

/// Return document/literal parameters for sending an XML body
ClassMethod GetSoapParameters(ByRef bindingStyle As %String, ByRef bodyUse As %String, ByRef namespace As %String, ByRef xmlimportnamespace As %String, ByRef typeNamespace As %String, ByRef oneWay As %Boolean, ByRef xmlelement As %Boolean, ByRef bare As %Boolean) [ Internal, ServerOnly = 1 ]
{
	Set bindingStyle="document",bodyUse="literal",namespace=..#NAMESPACE,xmlimportnamespace="",typeNamespace="",oneWay=0,xmlelement=1,bare=0
	Quit $$$OK
}

}
