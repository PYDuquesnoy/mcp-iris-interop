/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// A SAML Subject
Class %SAML.Subject Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "urn:oasis:names:tc:SAML:2.0:assertion";

Parameter ELEMENTQUALIFIED = 0;

Property NameID As %SAML.BaseID(XMLREF = 1, XMLTYPECONSTRAINT = "choice");

Property SubjectConfirmation As list Of %SAML.SubjectConfirmation(XMLPROJECTION = "element", XMLREF = 1);

/// Create SubjectConfirmation with specified SubjectConfirmation method.
/// The method argument should be $$$SAMLSenderVouches, $$$SAMLHolderOfKey or $$$SAMLBearer.
/// The NameID field must still be set for the Subject.
Method AddConfirmation(method As %String) As %Status
{
	#dim subjectConfirmation As %SAML.SubjectConfirmation = ##class(%SAML.SubjectConfirmation).%New()
	Set subjectConfirmation.Method=method
	Do ..SubjectConfirmation.Insert(subjectConfirmation)
	
	Quit $$$OK
}

/// Create SubjectConfirmation and associated KeyInfo for holder-of-key SubjectConfirmation based X.509 credentials.
/// The NameID field must still be set for the Subject.
Method AddX509Confirmation(credentials As %SYS.X509Credentials, referenceOption As %Integer) As %Status
{
	If referenceOption=$$$SOAPWSReferenceDirect {
		Set sc=$$$ERROR($$$SOAPBadLogin,"BinarySecurityToken not supported for SubjectConfirmation")
		$$$SOAPLogSecurity("    BinarySecurityToken not supported for SubjectConfirmation")
		Quit sc
	}
	
	#dim subjectConfirmation As %SAML.SubjectConfirmation = ##class(%SAML.SubjectConfirmation).%New()
	#dim subjectConfirmationData As %SAML.SubjectConfirmationData = ##class(%SAML.SubjectConfirmationData).%New()
	#dim keyinfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).CreateX509(.credentials,.referenceOption)
	If keyinfo="" {
		Set sc=$$$ERROR($$$SOAPBadLogin,"Unable to create KeyInfo for SubjectConfirmation")
		$$$SOAPLogSecurity("    Unable to create KeyInfo for SubjectConfirmation")
		Quit sc
	}

	Do ..SubjectConfirmation.Insert(subjectConfirmation)
	Set subjectConfirmation.SubjectConfirmationData=subjectConfirmationData
	Set subjectConfirmation.Method=$$$SAMLHolderOfKey
	Do subjectConfirmationData.KeyInfo.Insert(keyinfo)
	
	Quit $$$OK
}

/// Create SubjectConfirmation and associated KeyInfo for holder-of-key SubjectConfirmation based on EncryptedKey.
/// The NameID field must still be set for the Subject.
Method AddEncryptedKeyConfirmation(encryptedKey As %XML.Security.EncryptedKey) As %Status
{
	#dim subjectConfirmation As %SAML.SubjectConfirmation = ##class(%SAML.SubjectConfirmation).%New()
	#dim subjectConfirmationData As %SAML.SubjectConfirmationData = ##class(%SAML.SubjectConfirmationData).%New()
	#dim keyinfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).CreateEncryptedKey(encryptedKey)
	If keyinfo="" {
		Set sc=$$$ERROR($$$SOAPBadLogin,"Unable to create KeyInfo for SubjectConfirmation")
		$$$SOAPLogSecurity("    Unable to create KeyInfo for SubjectConfirmation")
		Quit sc
	}

	Do ..SubjectConfirmation.Insert(subjectConfirmation)
	Set subjectConfirmation.SubjectConfirmationData=subjectConfirmationData
	Set subjectConfirmation.Method=$$$SAMLHolderOfKey
	Do subjectConfirmationData.KeyInfo.Insert(keyinfo)
	
	Quit $$$OK
}

/// Create SubjectConfirmation and associated KeyInfo for holder-of-key SubjectConfirmation based on BinarySecret.
/// The NameID field must still be set for the Subject.
Method AddBinarySecretConfirmation(binarySecret As %SOAP.WST.BinarySecret) As %Status
{
	#dim subjectConfirmation As %SAML.SubjectConfirmation = ##class(%SAML.SubjectConfirmation).%New()
	#dim subjectConfirmationData As %SAML.SubjectConfirmationData = ##class(%SAML.SubjectConfirmationData).%New()
	#dim keyinfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).CreateBinarySecret(binarySecret)
	If keyinfo="" {
		Set sc=$$$ERROR($$$SOAPBadLogin,"Unable to create KeyInfo for SubjectConfirmation")
		$$$SOAPLogSecurity("    Unable to create KeyInfo for SubjectConfirmation")
		Quit sc
	}

	Do ..SubjectConfirmation.Insert(subjectConfirmation)
	Set subjectConfirmation.SubjectConfirmationData=subjectConfirmationData
	Set subjectConfirmation.Method=$$$SAMLHolderOfKey
	Do subjectConfirmationData.KeyInfo.Insert(keyinfo)
	
	Quit $$$OK
}

}
