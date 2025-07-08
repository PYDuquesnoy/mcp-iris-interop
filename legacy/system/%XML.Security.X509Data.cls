/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// X509Data reference for SOAP SecurityTokenReference or KeyInfo.
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %XML.Security.X509Data Extends %XML.Security.KeyInfoClause [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

Property Identifiers As list Of %XML.Security.X509DataElement(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice") [ Internal ];

/// Create a X509Data element.<br>
/// credentials is the %SYS.X509Credentials object that defines the X509 data.<br>
/// valueType is a comma separated list of value types.<br>
/// If no X509Data element is returned the status argument is set to the error %Status.
ClassMethod Create(valueType As %String, credentials As %SYS.X509Credentials, Output status As %Status) As %XML.Security.X509Data
{
	Set status=$$$OK
	Set data=..%New()
	For i=1:1:$length(valueType,",") {
		Set type=$piece(valueType,",",i)
		If type=$$$KeyInfoX509Certificate {
			Set element=##class(%XML.Security.X509Certificate).Create(credentials)
		} ElseIf type=$$$KeyInfoX509IssuerSerial {
			Set element=##class(%XML.Security.X509IssuerSerial).Create(credentials)
		} ElseIf type=$$$KeyInfoX509SKI {
			Set element=##class(%XML.Security.X509SKI).Create(credentials)
		} ElseIf type=$$$KeyInfoX509SubjectName {
			Set element=##class(%XML.Security.X509SubjectName).Create(credentials)
		} Else {
			Set status=$$$ERROR($$$SOAPBadSecurityElement,"Unsupported valueType for X509Data "_type)
			$$$SOAPLogSecurity("    Unsupported valueType for X509Data "_type)
			Set data=""
			Quit
		}
		Do data.Identifiers.Insert(element)
	}
	Quit data
}

/// Validate this input X509Data KeyInfo clause.
/// If valid, set credentials and tokenType and return "".  credentials is either %SYS.X509Credentials or %Binary
/// If not valid, return error code.
/// If there are multiple X509 Certificates in the X509 Data Elements then the first certificate is taken as the
/// one to return and we do not check if the subsequent certificates are the same as they are taken to part of the
/// certificate chain - https://www.w3.org/TR/xmldsig-core1/#sec-X509Data
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, Output credentials As %RawString) As %String [ Internal ]
{
	Set error=""
	Set credentials=""
	Set tokenType=""
	Set elements=..Identifiers
	For i=1:1:elements.Count() {
		Set element=elements.GetAt(i)
		If 'element.%Extends("%XML.Security.X509DataElement") {
			$$$SOAPLogSecurity("    Unexpected child element of X509Data")
			Set error="UnsupportedAlgorithm"
			Quit
		}

		Set error=element.ValidateTokenRef(service,.tokenType,.validatedCredentials)
		If error'="" Continue
		
		If tokenType=$$$SOAPWSX509v3 {
			// Save the first certificate.
			If credentials="" {
				Set credentials=validatedCredentials
			} Elseif 'element.%IsA("%XML.Security.X509Certificate") {
				If credentials.Certificate'=validatedCredentials.Certificate {
					$$$SOAPLogSecurity("    Inconsistent credentials supplied in SecurityTokenReference")
					Set error="InvalidSecurityToken"
					Set credentials=""
					Quit
				}
			}
		} Else {
			$$$SOAPLogSecurity("    ValueType not unsupported: "_tokenType)
			Set error="UnsupportedAlgorithm"
			Quit
		}
	}
	
	If credentials'="" Set error=""

	Quit error
}

/// Get description string for logging
Method GetLoggingString() As %String [ CodeMode = expression, Internal ]
{
"X509Data"
}

}
