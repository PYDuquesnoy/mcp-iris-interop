/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Encryption element.
Class %XML.Security.DataReference Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2001/04/xmlenc#";

Parameter ELEMENTQUALIFIED = 1;

Property content As %XML.String(XMLPROJECTION = "content");

Property URI As %xsd.anyURI(XMLPROJECTION = "attribute") [ Required ];

/// EncryptedData element for data that is to be encrypted.
Property EncryptedData As %XML.Security.EncryptedData(XMLPROJECTION = "none") [ Internal ];

/// The position in the Security header, if referenced EncryptedData is child of the Security header.
Property SecurityPosition As %Integer(XMLPROJECTION = "none") [ Internal ];

/// The type of element referenced: "Body", "Header", "Element" or "".
/// Used only when validating received SOAP messages.
Property ElementType As %String(XMLPROJECTION = "none") [ Internal ];

/// If DoNotReuse is true, then this reference was created by InitializeForService and 
/// should be removed during Reset.
Property DoNotReuse As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// Create a new Reference based on the specified EncryptedData.
ClassMethod Create(data As %XML.Security.EncryptedData)
{
	#dim ref As %XML.Security.DataReference = ..%New()
	Set ref.EncryptedData=data
	Set ref.URI="#"_data.Id
	Quit ref
}

}
