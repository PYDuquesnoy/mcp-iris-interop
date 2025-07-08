/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// EntropyType type from WS-Trust 1.3.
/// Either BinarySecret or EncryptedKey may be specified, but not both.
Class %SOAP.WST.Entropy Extends (%RegisteredObject, %XML.Adaptor) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wst";

Property BinarySecret As %SOAP.WST.BinarySecret(REFNAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-trust/200512", XMLREF = 1);

Property EncryptedKey As %XML.Security.EncryptedKey(REFNAMESPACE = "http://www.w3.org/2001/04/xmlenc#", XMLREF = 1);

/// Create Entropy element with BinarySecret.
/// keysize is the size of the random entropy in bytes. Default keysize is $$$SOAPWSSCDEFAULTKEYSIZE.
ClassMethod CreateBinarySecret(keysize As %Integer, type As %String) As %SOAP.WST.Entropy
{
	Set entropy=..%New()
	If $get(type)="" Set type=$$$SOAPWSTNonce
	Set entropy.BinarySecret=##class(%SOAP.WST.BinarySecret).Create(type,.keysize)
	Quit entropy
}

/// Create Entropy element with an EncryptedKey element containing a binary secret.
/// keysize is the size of the random entropy in bytes. Default keysize is $$$SOAPWSSCDEFAULTKEYSIZE.
ClassMethod CreateX509EncryptedKey(keysize As %Integer, credentials As %SYS.X509Credentials = "", referenceOption As %Integer = "", Output status As %Status) As %SOAP.WST.Entropy
{
	Set encryptedKey=##class(%XML.Security.EncryptedKey).CreateX509(credentials,$$$SOAPWSEncryptNone,referenceOption,.status)
	If $$$ISERR(status) Quit ""
	If $get(keysize)="" {
		Set encryptedKey.KeySize=$$$SOAPWSSCDEFAULTKEYSIZE
	} Else {
		Set encryptedKey.KeySize=keysize
	}
	Set status=encryptedKey.Initialize()
	If $$$ISERR(status) Quit ""
	Set entropy=..%New()
	Set entropy.EncryptedKey=encryptedKey
	Quit entropy
}

}
