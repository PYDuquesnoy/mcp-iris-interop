/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// AttributeValue
/// This class allows string value, XML content or instance of subclass of %SAML.AttributeValueAbstract.
/// The structure of this class reflects that we do not have a mapping for xs:anyType.
Class %SAML.AttributeValue Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

/// Set any string value as the attribute.	
Property value As %XML.String(MAXLEN = "", XMLPROJECTION = "content") [ Internal, Private ];

/// Dummy property to introduce xsi:type attribute
Property type As %String(REFNAMESPACE = "http://www.w3.org/2001/XMLSchema-instance", XMLPROJECTION = "xattribute", XMLREF = 1) [ Internal, Private ];

///  Subclasses of %SAML.AttributeValueElement can be used as values which
///  are an element as a child of AttributeValue.
Property element As %SAML.AttributeValueElement(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice") [ Internal, Private ];

/// Set AttributeValue as XML content
Method SetXML(xml As %String)
{
	Set ..value=xml
	set ..type=""
}

/// Set AttributeValue as a xs:string
Method SetString(string As %String)
{
	Set ..value=$zcvt(string,"O","XML")
	set ..type="s:string"
}

/// Set AttributeValue as a child element
/// which maps to a subclass of %SAML.AttributeValueElement.
Method SetElement(element As %SAML.AttributeValueElement)
{
	Set ..element=element
	Set ..value=""
	set ..type=""
}

/// Get content of AttributeValue as XML.
Method GetXML() As %String
{
	Quit ..value
}

/// Return true if content of AttributeValue is a string.
Method IsString() As %Boolean
{
	Quit ..value'["<"
}

/// Get content of AttributeValue as a xs:string.
Method GetString() As %String
{
	Quit $zcvt(..value,"I","XML")
}

/// Return true if content of AttributeValue is a child element 
/// which maps to a subclass of %SAML.AttributeValueElement.
Method IsElement() As %Boolean
{
	Quit $isobject(..element)
}

/// Get content of AttributeValue as a xs:string.
Method GetElement() As %SAML.AttributeValueElement
{
	Quit ..element
}

}
