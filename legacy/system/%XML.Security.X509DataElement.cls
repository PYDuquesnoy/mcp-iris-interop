/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Abstract base class for X509Data elements.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.X509DataElement Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

/// Force any subclass into choice list.
/// This usage of XMLINCLUDEINGROUP is only needed for classes in %XML and %SOAP packages.
Parameter XMLINCLUDEINGROUP = 2;

/// Validate and get the certificate from a KeyIdentifier
/// with either SubJectKeyIdentifier or ThumbprintSHA1.
/// If valid, set credentials argument and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set credentials=""
	Set tokenType=$$$SOAPWSX509v3

	Quit ""
}

}
