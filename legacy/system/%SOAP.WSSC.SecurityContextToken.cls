/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// SecurityContextToken from WS-SecureConversation 1.3.
Class %SOAP.WSSC.SecurityContextToken Extends (%SOAP.WST.AbstractToken, %SOAP.Security.Element) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/ws-sx/ws-secureconversation/200512";

Parameter ELEMENTQUALIFIED = 1;

Parameter XMLPREFIX = "wsc";

Property Identifier As %xsd.anyURI;

Property Instance As %String(MAXLEN = "");

Property any As %XML.ElementExtension(XMLPROJECTION = "group");

/// The expiration in seconds since December 31, 1840
Property ExpiresInSeconds As %Integer(XMLPROJECTION = "none") [ Internal ];

/// The symmetric key to be used.
Property Key As %Binary(XMLPROJECTION = "none") [ Internal ];

/// The endpoint of the web service to which this token applies
Property AppliesTo As %xsd.anyURI(XMLPROJECTION = "none") [ Internal ];

/// If MustNotSendCancel is true, then token may nopt be cancelled.
Property MustNotSendCancel As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

Method %OnNew(initvalue As %String = "") As %Status [ Internal ]
{
	// Force a wsu:Id
	Do ..GetId()
	Quit $$$OK
}

/// Save this SecurityContextToken in a system wide global.
/// The global format is:
///    ^SYS("SOAPContext",Identifier,Instance)=$lb(type,ExpiresInSeconds,Key,AppliesTo,any,wsuId as $list,MustNotSendCancel)
/// The index for cleanup is
///    ^SYS("SOAPContext",0,ExpiresInSeconds,Identifier,Instance)=""
/// where Instance is $c(0) if no Instance and type is always = 1 for SecurityContextToken.
Method Save() As %Status [ Internal ]
{
	Quit ##class(%SYS.SecurityContextToken).Save($this)
}

/// Retrieve the SecurityContextToken with this identifier for system wide global.
/// See Save method description for details.
ClassMethod Open(identifier As %xsd.anyURI, instance As %String = "") As %SOAP.WSSC.SecurityContextToken [ Internal ]
{
	Quit ##class(%SYS.SecurityContextToken).Open(identifier,instance)
}

/// Retrieve the SecurityContextToken properties for token with this identifier for system wide global.
/// See Save method description for details.
Method Load(keepId As %Boolean = 1) As %Boolean [ Internal ]
{
	Quit ##class(%SYS.SecurityContextToken).Load($this,keepId)
}

/// Copy the specified token to this token
Method Copy(sct As %SOAP.WSSC.SecurityContextToken) [ Internal ]
{
	Set ..ExpiresInSeconds=sct.ExpiresInSeconds
	Set ..Key=sct.Key
	Set ..AppliesTo=sct.AppliesTo
	Set ..any=sct.any
	Set ..MustNotSendCancel=sct.MustNotSendCancel
	Set ..Id=sct.Id
}

/// Log list of SecurityContextTokens
ClassMethod Log(terminal As %Boolean = 0) [ Internal ]
{
	Do ##class(%SYS.SecurityContextToken).Log(terminal)
	Quit
}

/// Remove this token from context list
Method Remove() [ Internal ]
{
	Do ##class(%SYS.SecurityContextToken).Remove($this)
	Quit
}

/// Remove all security contexts
ClassMethod RemoveAll() [ Internal ]
{
	Do ##class(%SYS.SecurityContextToken).RemoveAll()
	Quit
}

/// Create a WS-SecureConversation security fault.
ClassMethod MakeFault(faultCode As %String) As %SOAP.Fault [ ServerOnly = 1 ]
{
	If faultCode="BadContextToken" {
		Set faultString="The requested context elements are insufficient or unsupported."
	} ElseIf faultCode="UnsupportedContextToken" {
		Set faultString="Not all of the values associated with the SCT are supported."
	} ElseIf faultCode="UnknownDerivationSource" {
		Set faultString="The specified source for the derivation is unknown."
	} ElseIf faultCode="RenewNeeded" {
		Set faultString="The provided context token has expired"
	} ElseIf faultCode="UnableToRenew" {
		Set faultString="The specified context token could not be renewed."
	} Else {
		Set faultString="Unknown WS-SecureConversation fault."
	}
	Set fault=##class(%SOAP.WebService).MakeFault(faultCode,faultString,"","")
	
	Set fault.faultcode="wsc:"_fault.faultcode
	Set fault.faultPrefixDefinition="xmlns:wsc="""_..#NAMESPACE_""""
	Set fault.WSSecurityFault=1
	
	Quit fault
}

/// Create a SecurityContextToken with Identifier set
ClassMethod Create() As %SOAP.WSSC.SecurityContextToken
{
	Set token=..%New()
	Set token.Identifier="urn:uuid:"_$system.Util.CreateGUID()
	Quit token
}

/// Initialize the SecurityContextToken key.
Method InitializeKey(service As %SOAP.WebBase, algorithm As %String) As %Status [ Internal ]
{
	// Just return if key already initialized
	If ..Key'="" Quit $$$OK

	$$$SOAPLogSecurity("    No key in SecurityContextToken.")
	Quit $$$ERROR($$$WSSCNoKey)
}

/// Validate the SecurityContextToken key.
/// If invalid return an error code.
Method ValidateKey(service As %SOAP.WebBase) As %String [ Internal ]
{
	// Just return if key already initialized
	If ..Key'="" Quit ""
	
	$$$SOAPLogSecurity("Validate SecurityContextToken:")

	If $isobject(service),service.%Extends("%SOAP.WebClient") {
		Set sct=service.SecurityContextToken
		If '$isobject(sct) {
			$$$SOAPLogSecurity("    No Client SecurityContextToken found.")
			Quit "UnsupportedAlgorithm"
		} ElseIf (sct.Identifier'=..Identifier) || (sct.Instance'=..Instance) {
			$$$SOAPLogSecurity("    Client SecurityContextToken from Security header not matched:  Identifier="_sct.Identifier_$select(sct.Instance'="":", Instance="_sct.Instance,1:""))
			Quit "UnsupportedAlgorithm"
		}
		Do ..Copy(sct)
	} Else {
		If '##class(%SYS.SecurityContextToken).Load($this,1) {
			$$$SOAPLogSecurity("    SecurityContextToken from Security header expired or not found.")
			Quit ..MakeFault("RenewNeeded")
		}
		If ..AppliesTo'="" {
			If $isobject($get(%request)) {
				If ..AppliesTo'=%request.URL {
					$$$SOAPLogSecurity("    SecurityContextToken from Security header applies to different web service: "_..AppliesTo)
					Quit ..MakeFault("UnsupportedContextToken")
				}
			} Else {
				$$$SOAPLogSecurity("    SecurityContextToken.AppliesTo not supported since this is not a web service call.")
				Quit "UnsupportedAlgorithm"
			}
		}
	}
	
	If ..Key="" {
		$$$SOAPLogSecurity("    No key found for SecurityContextToken.  Identifier="_..Identifier_$select(..Instance'="":", Instance="_..Instance,1:""))
		Quit "UnsupportedAlgorithm"
	}

	Quit ""
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	Quit ..ValidateKey(service)
}

/// Reset the element.
Method Reset() [ Internal ]
{
	// Save Id
	Set id=..Id
	
	Do ##super()
	
	// And restore the Id since need to use original Id for SCT
	Set ..Id=id
}

/// Return true if the same Key.
Method Equals(credentials As %SOAP.WSSC.SecurityContextToken) As %Boolean
{
	Quit ($isobject(credentials) && (credentials.Identifier=..Identifier) && (credentials.Instance=..Instance))
}

}
