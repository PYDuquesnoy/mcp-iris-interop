/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// 
/// SAML Assert Token for SOAP Security header.
Class %SAML.Assertion Extends (%SOAP.WST.AbstractToken, %SOAP.Security.Element, %SAML.AssertionReference) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Parameter XMLPREFIX = "saml";

/// Need to distinguish the 2 different possible Signature elements.
Parameter XMLSEQUENCE = 1;

Property Issuer As %SAML.NameID(XMLREF = 1) [ Required ];

Property Signature As %XML.Security.Signature(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLREF = 1);

Property Subject As %SAML.Subject(XMLREF = 1);

Property Conditions As %SAML.Conditions(XMLREF = 1);

Property Advice As list Of %SAML.AssertionReference(REFELEMENTQUALIFIED = 1, XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property Statement As list Of %SAML.Statement(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property WSSecuritySignature As %XML.Security.Signature(REFELEMENTQUALIFIED = 1, REFNAMESPACE = "http://www.w3.org/2000/09/xmldsig#", XMLNAME = "Signature", XMLREF = 1) [ Internal ];

Property SAMLID As %String(MAXLEN = "", XMLNAME = "ID", XMLPROJECTION = "attribute") [ Required ];

Property IssueInstant As %xsd.dateTime(XMLPROJECTION = "attribute") [ Required ];

Property Version As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ Required ];

/// Save the node id of this element in the tree during import.
Property NodeId As %String(XMLPROJECTION = "none") [ Internal ];

/// Save the text this element in the tree during import.
Property Text As %String(XMLPROJECTION = "none") [ Internal ];

/// If SubjectConfirmation is based on X509 certificate, this is the X509 certificate class.
/// This property is read-only.
Property X509Credentials As %RawString(XMLPROJECTION = "none") [ Internal ];

/// Internal property to determine whether to place the generated signature in the <property>WSSecuritySignature</property> field
/// or the <property>Signature</property> field. The default is to use <property>WSSecuritySignature</property>. <br>
/// This is controlled by the <b>useWSSecuritySignature<b> parameter in <method>CreateX509</method>.
Property UseWSSecuritySignature As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 1, Internal, Private ];

Method X509CredentialsGet() As %SYS.X509Credentials [ Internal ]
{
	Set error=..ValidateTokenRef("",.tokenType,.credentials)
	
	If error'="" Quit ""
	
	Quit credentials
}

/// Get the X.509 credentials associated with this Security header element on input.
Method GetX509Credentials() As %SYS.X509Credentials [ CodeMode = expression ]
{
..X509Credentials
}

/// The optional prefix list to be used for inclusive namespace prefix when creating WSSecuritySignature.
/// The PrefixList that is specified for this SAML assertion as a list of NMTOKENS.
Property PrefixList As %String(MAXLEN = "", XMLPROJECTION = "none") [ Internal ];

/// Save the node if when getting a new class instance.
ClassMethod XMLNew(document As %XML.Document, nodeId As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject
{
	Set oref=..%New()
	
	// Save the node id
	Set oref.NodeId=nodeId
	
	// Save the original text
	If ##class(%XML.ImportHandler).SerializeNode(document.DocumentId,nodeId,0,1,.text,1) {
		Set oref.Text=text
	}
	
	Quit oref
}

/// Create an unsigned SAML Asssertion
ClassMethod Create() As %SAML.Assertion
{
	Set assertion=..%New()
	Set assertion.SAMLID="Id-"_$system.Util.CreateGUID()
	Set assertion.Version="2.0"
	Quit assertion
}

/// Create a SAML Asssertion with a WS-Security Signature based on X.509 credentials.<br>
/// prefixList that is specified as a list of NMTOKENS for signing this SAML assertion.<br>
/// useWSSecuritySignature determines whether the generated signature will be placed in 
/// the <property>WSSecuritySignature</property> field or the <property>Signature</property> field. 
/// The default is to use <property>WSSecuritySignature</property>.
ClassMethod CreateX509(credentials As %SYS.X509Credentials, referenceOption As %Integer, prefixList As %String = "", useWSSecuritySignature As %Boolean = 1) As %SAML.Assertion
{
	#dim assertion As %SAML.Assertion = ..Create()
	
	If $case($zobjclass(credentials),"%SYS.X509Credentials":0,"%SOAP.Security.BinarySecurityToken":0,:1) {
		Set assertion.WSSecuritySignature=""
		Set assertion.X509Credentials=""
	} Else {
		#dim signature As %XML.Security.Signature 
		Set signature=##class(%XML.Security.Signature).CreateX509(.credentials,$$$SOAPWSIncludeNone,.referenceOption)
		If useWSSecuritySignature {
			Set assertion.WSSecuritySignature=signature
		} Else {
			Set assertion.Signature=signature
			Set assertion.UseWSSecuritySignature=0
		}
		Set assertion.X509Credentials=credentials
	}
	
	Set assertion.PrefixList=prefixList
	
	Quit assertion
}

/// Validate and get the credentials from the Assertion's SubjectConfirmationData element 
/// with holder-of-key method.
/// If valid, set credentials argument and return "". 
/// If not valid, return error code.
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, ByRef credentials As %SYS.X509Credentials) As %String [ Internal ]
{
	Set error=""
	Set (tokenType,credentials)=""
	
	#dim subject As %SAML.Subject = ..Subject
	If '$isobject(subject) Quit ""
	#dim subjectConfirmation As %SAML.SubjectConfirmation
	#dim subjectConfirmationData As %SAML.SubjectConfirmationData
	For i=1:1:subject.SubjectConfirmation.Count() {
		Set subjectConfirmation=subject.SubjectConfirmation.GetAt(i)
		If '$isobject(subjectConfirmation) Continue
		If subjectConfirmation.Method'=$$$SAMLHolderOfKey Continue

		Set subjectConfirmationData=subjectConfirmation.SubjectConfirmationData
		If '$isobject(subjectConfirmationData) Continue

		If $case($zobjclass(subjectConfirmationData),"%SAML.SubjectConfirmationData":0,"%SAML.KeyInfoConfirmationData":0,:1) Continue
		If '$isobject(subjectConfirmationData.KeyInfo) Continue
		If subjectConfirmationData.KeyInfo.Count()=0 Continue

		For j=1:1:subjectConfirmationData.KeyInfo.Count() {
			Set keyinfo=subjectConfirmationData.KeyInfo.GetAt(j)
			Set error=keyinfo.ValidateTokenRef(service)
			If error'="" Quit
			If $case(keyinfo.KeyType,$$$SOAPWSX509v3:0,$$$SOAPWSEncryptedKey:0,$$$SOAPWSTSecretSymKey:0,:1) {
				$$$SOAPLogSecurity("    Unsupported tokenType for SAML reference in KeyInfo")
				Set error="UnsupportedAlgorithm"
				Quit
			}
			Set credentials=keyinfo.X509Credentials
			If credentials'="" Quit
		}
		If (error'="") || (credentials'="") Quit
	}
	
	If error'="" Set ..X509Credentials=credentials

	Set tokenType=$$$SOAPWSSAML
	
	Quit error
}

/// Initialize the signature in the SAML assertion.
Method InitializeForService(service As %SOAP.WebBase, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	If ..SAMLID="" Set ..SAMLID="Id-"_$system.Util.CreateGUID()
	
	Set sc=$$$OK
	
	// An uninitialized Signature indicates that we should use the Signature property instead of WSSecuritySignature.
	// This needs to be handled here before the XML is generated so we sign the correct canonicalized XML.
	If i%UseWSSecuritySignature && $isobject(..Signature) && (..Signature.ReferenceOption="") && (..Signature.SignatureOptions="") && (..Signature.KeyInfo="") {
		Set ..Signature = ..WSSecuritySignature
		Set ..WSSecuritySignature = ""
		Set ..UseWSSecuritySignature = 0
	}
	Set signature = $select(i%UseWSSecuritySignature:..WSSecuritySignature, 1:..Signature)

	If $isobject(signature) {
		If 'signature.PreProcessed {
			Set ref=##class(%XML.Security.Reference).Create(..SAMLID,$$$SOAPWSEnvelopedSignature_","_$$$SOAPWSexcc14n,..PrefixList)
			Do signature.AddReference(ref)
		}
		Set sc=signature.InitializeForService(service,header)
	}
	
	Quit sc
}

/// Complete the Signature element by adding the Reference elements to the 
/// SignedInfo based on the SignatureOptions and computing the signature value.
Method Perform(messageStream As %BinaryStream, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	Set sc=$$$OK
	Set signature = $select(i%UseWSSecuritySignature:..WSSecuritySignature, 1:..Signature)
	If $isobject(signature) {
		Set sc=signature.Perform(messageStream,header)
	}
	
	Quit sc
}

/// Reset the SAML assertion.
Method Reset() [ Internal ]
{
	Do ##super()
	
	Set signature = $select(i%UseWSSecuritySignature:..WSSecuritySignature, 1:..Signature)

	If $isobject(signature) {
		Do signature.Reset()
	}
}

/// Validate the SAML assertion.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase, mimeAttachments As %Net.MIMEPart = "") As %String [ Internal ]
{
	If ..SAMLID'="" $$$xmlSetNodeById(document.DocumentId,..SAMLID,..NodeId)
	
	If $isobject(..WSSecuritySignature) {
		$$$SOAPLogSecurity("    checking signature for SAML token")
		Set error=..WSSecuritySignature.ValidateElement(document,service,mimeAttachments)
		$$$SOAPLogSecurity("    signature validation for SAML token returned: "_error)
		If error'="" Quit error
	}
	
	If '$isobject(..Issuer) || (..Issuer.NameID="") {
		$$$SOAPLogSecurity("    unspecified Issuer for SAML token")
		Quit "InvalidSecurityToken"
	}
	
	Quit ""
}

}
