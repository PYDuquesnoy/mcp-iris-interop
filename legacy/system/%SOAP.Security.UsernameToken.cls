/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// UsernameToken for SOAP Security header.
Class %SOAP.Security.UsernameToken Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

Property Username As %String(CONTENT = "escape", MAXLEN = "");

Property Password As %SOAP.Security.Password;

Property Nonce As %Binary(MAXLEN = "");

Property Created As %xsd.dateTime(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd", XMLREF = 1);

/// Create a UsernameToken element containing the specified username.
/// The password is specified by the type argument as follows:
/// <ul>
/// <li>$$$SOAPWSPasswordText is a plain text password.  This is the default.</li>
/// <li>$$$SOAPWSPasswordDigest is a password digest based on the specified password. 
///   The password digest, Nonce and Created timestamp are derived as specified by WS-Security 1.1.<br>
///   $$$SOAPWSPasswordDigest is available only for SOAP clients interacting with third-party servers that support it. 
///   PasswordDigest authentication requires the server to store the plain-text password, which is not acceptable in a 
///   modern security environment. The PasswordDigest algorithm is a legacy feature. To protect the password in a 
///   &lt;UsernameToken>, you should use SSL/TLS, encrypt the &lt;UsernameToken>, or both.</li>
/// <li>$$$SOAPWSPasswordNone means no password element is included.</li>
/// </ul>
ClassMethod Create(username As %String, password As %String, type As %String) As %SOAP.Security.UsernameToken
{
	Set token=..%New()
	Set token.Username=username
	
	If $get(type)="" Set type=$$$SOAPWSPasswordText
	If type=$$$SOAPWSPasswordText {
		Set pwd=##class(%SOAP.Security.Password).%New()
		Set pwd.Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
		Set pwd.content=password
		Set token.Password=pwd

	} ElseIf type=$$$SOAPWSPasswordDigest {
		// Create random nonce of length 20 -- choice of length is somewhat arbitrary.
		Set token.Nonce=$system.Encryption.GenCryptRand(20,0)
		Set token.Created=$zdt($ztimestamp,3)
		Set timestamp=$translate(token.Created," ","T")_"Z"

		Set pwd=##class(%SOAP.Security.Password).%New()
		Set pwd.Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
		Set pwd.content=$system.Encryption.Base64Encode($System.Encryption.SHA1Hash(token.Nonce_timestamp_password),1)
		Set token.Password=pwd
	}

	Quit token
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	Set passwordObj=..Password
	If $isobject(passwordObj) {
		Set type=passwordObj.Type
		If $length(type,"#")=2 {
			Set (type,passwordObj.Type)=$piece(type,"#",2)
		}
	} Else {
		Set type=""
	}

	If ..Username="" {
		$$$SOAPLogSecurity("Security UsernameToken missing password")
		Quit "UnsupportedSecurityToken"
	}
	
	If $case(type,"":0,"PasswordText":0,"PasswordDigest":0,:1) {
		$$$SOAPLogSecurity("Security UsernameToken unsupported password type")
		Quit "UnsupportedSecurityToken"
	}
	
	$$$SOAPLogSecurity("Security UsernameToken validated")

	Quit ""
}

}
