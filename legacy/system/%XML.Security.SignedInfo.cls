/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Signature element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.SignedInfo Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property CanonicalizationMethod As %XML.Security.Transform;

Property SignatureMethod As %XML.Security.SignatureMethod;

Property Reference As list Of %XML.Security.Reference(XMLPROJECTION = "element");

Property Id As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// Save the node id of this element in the tree during import for canonicalizing
/// later during signature verification.
Property NodeId As %String(XMLPROJECTION = "none") [ Internal ];

/// Save the node if when getting a new class instance.
ClassMethod XMLNew(document As %XML.Document, nodeId As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject
{
	Set oref=..%New()
	Set oref.NodeId=nodeId
	Quit oref
}

}
