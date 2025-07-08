/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// X509SubjectName X509Data element.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.X509SubjectName Extends %XML.Security.X509DataElement [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property value As %String(CONTENT = "escape", MAXLEN = "", XMLPROJECTION = "content") [ Internal ];

/// Create an element based on X509 credentials
ClassMethod Create(credentials As %SYS.X509Credentials) As %XML.Security.X509SubjectName
{
	Set element=..%New()
	Set element.value=credentials.SubjectDN
	Quit element
}

/// Validate and get the certificate with a SubJect Distinguished Name.
/// If valid, set credentials argument and tokenType and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set credentials=""
	If ..value="" {
		$$$SOAPLogSecurity("    Empty Subject Distinguished Name not supported for X509SubjectName.")
		Quit "UnsupportedAlgorithm"
	}

	// Return the certificate.
	Set list=##class(%SYS.X509Credentials).FindByField("SubjectDN",..value)
	If list.Count()'=1 {
		$$$SOAPLogSecurity("    a single unique certificate not found for X509SubjectName: "_..value)
		Quit "SecurityTokenUnavailable"
	}
	Set credentials=list.GetAt(1)
	
	Set tokenType=$$$SOAPWSX509v3
	Quit ""
}

}
