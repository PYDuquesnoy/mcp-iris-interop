/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class can be used to query the SSL PeerCertificate
/// retrieved by %Net.HttpRequest when SSLCheckIdentityServer is enabled.<br>
/// It also contains convenience wrappers for %SYSTEM.Encryption X509 methods. <br>
/// Passing all the validity checks in this class does not mean the SSL Peer Certificate
/// is valid. <br>
Class %Net.X509Certificate Extends %RegisteredObject [ ServerOnly = 1, System = 3 ]
{

/// X.509 digital certificate
Property Certificate As %Binary(MAXLEN = "");

/// Status returned by <class>%Net.HttpRequest</class> CheckSSLCN
/// method when SSLCheckServerIdentity is true. <br>
/// By examining the return from %Net.HttpRequest Send the <method>RetrievePeerCertificate</method>
/// will set this to $$$OK if the return from Send is $$$OK or the errors SSLCertificateNoMatch or SSLNoCertificate 
/// as returned by %Net.HttpRequest Send <br>
/// If a different error is returned then SSLCNCheck is left as empty <br>
Property SSLCNCheck As %Status;

/// Output from running $SYSTEM.Encryption.X509VerifyCertChain as 
/// executed by <method>VerifyCertChain</method> on <property>Certificate</property> with
/// <property>CAFile</property> and optional <property>CRLFile</property>
Property CertChainCheck As %String(MAXLEN = "");

/// Boolean test result of checking if the number of days between the ValidityNotBefore and 
/// the ValidityNotBefore fields in <property>Certificate</property> is less than the maximum
/// number of days used by <method>VerifyLifeSpan</method> <br>
/// The default maximum days is set to 730.
Property LifeSpanCheck As %Boolean;

/// Boolean test result of checking if ValidityNotBefore field in <property>Certificate</property>
/// is before or the same as the current time.<br>
Property NotBeforeCheck As %Boolean;

/// Boolean test result of checking if ValidityNotAfter field in <property>Certificate</property>
/// is after or the same as the current time.<br>
Property NotAfterCheck As %Boolean;

/// CAFile - Name of a file containing trusted Certificate Authority certificates <br>
/// Used by <method>VerifyCertChain</method>
Property CAFile As %String(MAXLEN = "");

/// CRLFile - Name of a file containing Certificate Revocation lists (optional)
/// Used by <method>VerifyCertChain</method>
Property CRLFile As %String(MAXLEN = "");

Method %OnNew(certificate As %String = "", sslcncheck As %Status = "") As %Status [ Internal ]
{
	If certificate'="" Set i%Certificate = certificate
	If sslcncheck'="" Set i%SSLCNCheck = sslcncheck
	Return $$$OK
}

Method CertificateSet(certificate) As %Status [ Internal ]
{
	Set i%Certificate = certificate
	Set i%SSLCNCheck = ""
	Set i%CertChainCheck = ""
	Set i%LifeSpanCheck = ""
	Set i%NotBeforeCheck = ""
	Set i%NotAfterCheck = ""
	Return $$$OK
}

/// Call X509GetField on the <property>Certificate</property> for the
/// <parameter>pX509Field</paramter> <br>
/// Returns in the <parameter>pStatus</paramter> status of the call. <br>
/// See <class>%SYSTEM.Encryption</class> for documention on the X509GetField method. <br>
Method Field(pX509Field As %String, Output pStatus As %Status = {$$$OK})
{
	#dim ex AS %Exception.AbstractException
	#dim tFieldValue = ""
	Try {
		Set tFieldValue = $SYSTEM.Encryption.X509GetField(i%Certificate,pX509Field)
	} Catch ex {Set pStatus = ex.AsStatus()}
	Return tFieldValue
}

/// Convenience method to prepend Extension: to the <parameter>pX509Extension</parameter> 
/// before calling <method>Field</method> <br>
Method Extension(pX509Extension As %String, Output pStatus As %Status = {$$$OK})
{
	Return ..Field(("Extension:"_pX509Extension), .pStatus)
}

/// Run the methods: <br>
/// <method>VerifyCertChain</method> if <parameter>pVerifyCertChains</parameter> is true (the default is true) <br>
/// <method>VerifyLifeSpan</method> using <parameter>pLifeSpanMaxDays</parameter> (the default is 730 days) <br>
/// <method>VerifyNotBefore</method> <br>
/// <method>VerifyNotAfter</method> <br>
/// This method returns true if the checks that were run passed and
/// and if the initial SSL Server Identity check (SSLCNCheck) passed.<br>
Method RunVerificationChecks(pVerifyCertChain As %Boolean = 1, pLifeSpanMaxDays As %Integer = 730) As %Boolean
{
	#dim tAllOK = 1
	#dim tCheck = ""

	If $$$ISERR(i%SSLCNCheck) Set tAllOK = 0

	If pVerifyCertChain {
		Set tCheck = ..VerifyCertChain()
		If tCheck'="OK" Set tAllOK = 0
	}

	Set tCheck = ..VerifyLifeSpan(pLifeSpanMaxDays)
	If tAllOK && 'tCheck Set tAllOK = 0

	Set tCheck = ..VerifyNotBefore()
	If tAllOK && 'tCheck Set tAllOK = 0

	Set tCheck = ..VerifyNotAfter()
	If tAllOK && 'tCheck Set tAllOK = 0

	Return tAllOK
}

/// Output from running $SYSTEM.Encryption.X509VerifyCertChain as 
/// on <property>Certificate</property> with <property>CAFile</property>
/// and optional <property>CRLFile</property>. <br>
/// Also populates return in <property>CertChainCheck</property>
Method VerifyCertChain() As %String
{
	If i%CAFile '= "" {
		Set i%CertChainCheck = $SYSTEM.Encryption.X509VerifyCertChain(i%Certificate, i%CAFile, i%CRLFile)
	} Else {
		Set i%CertChainCheck = "NO CA File"
	}
	Return i%CertChainCheck
}

/// Boolean test result of checking if the number of days between the ValidityNotBefore and 
/// the ValidityNotBefore fields in <property>Certificate</property> is less than the maximum
/// number of days used by <parameter>pMaxDays</parameter> <br>
/// The default maximum days is set to 730.<br>
/// The result is also stored in <property>LifeSpanCheck</property> <br>
/// If an error is encountered retrieving the value of ValidityNotBefore or ValidityNotAfter 
/// from the certificate the returned value is False.<br>
Method VerifyLifeSpan(pMaxDays As %Integer = 730) As %Boolean
{
	#dim field1Status, field2Status
	Set i%LifeSpanCheck = ($SYSTEM.SQL.DATEDIFF("dd",..Field("ValidityNotBefore",.field1Status),..Field("ValidityNotAfter",.field2Status))<pMaxDays)
	If ($$$ISERR(field1Status) || $$$ISERR(field2Status)) Set i%LifeSpanCheck = 0
	Return i%LifeSpanCheck
}

/// Boolean test result of checking if ValidityNotBefore field in <property>Certificate</property>
/// is before or the same as the current time.<br>
/// The result is also stored in <property>NotBeforeCheck</property> <br>
/// If an error is encountered retrieving the value of ValidityNotBefore from the certificate the returned value is False.<br>
Method VerifyNotBefore() As %Boolean
{
	#dim fieldStatus
	Set i%NotBeforeCheck = ($SYSTEM.SQL.DATEDIFF("ss",..Field("ValidityNotBefore",.fieldStatus),($zdatetime($ztimestamp,3,,3)))>=0)
	If $$$ISERR(fieldStatus) Set i%NotBeforeCheck = 0
	Return i%NotBeforeCheck
}

/// Boolean test result of checking if ValidityNotAfter field in <property>Certificate</property>
/// is after or the same as the current time.<br>
/// The result is also stored in <property>NotBeforeAfter</property> <br>
/// If an error is encountered retrieving the value of ValidityNotAfter from the certificate the returned value is False.<br>
Method VerifyNotAfter() As %Boolean
{
	#dim fieldStatus
	Set i%NotAfterCheck = ($SYSTEM.SQL.DATEDIFF("ss",($zdatetime($ztimestamp,3,,3)),..Field("ValidityNotAfter",.fieldStatus))>=0)
	If $$$ISERR(fieldStatus) Set i%NotAfterCheck = 0
	Return i%NotAfterCheck
}

/// Convenience method to make an HTTPS Request that will populate the SSLPeerCertificate
/// property of <class>%Net.HttpRequest</class>
/// using a pre-existing %Net.HttpRequest object and instantiate <parameter>pSSLPeerCert</parameter>
/// of type <class>%Net.X509Certificate</class> if the certificate was retrieved or Server identification check failed.<br>
/// For convenience the property SSLCheckServerIdentity is set to true.<br>
/// <parameter>pURL</parameter> defaults to / <br>
/// <parameter>pVerb</parameter> defaults to OPTIONS <br>
/// The status returned will be the status returned by the %Net.HttpRequest Send method
/// unless the error is $$$SSLNoCertificate or $$$SSLCertificateNoMatch in which an $$$OK will 
/// be returned and the <property>SSLCNCheck</property> will contain SSL Server Identity Check error. <br>
ClassMethod RetrievePeerCertificate(ByRef pHttpRequest As %Net.HttpRequest, pURL As %String = "/", pVerb As %String = "OPTIONS", Output pSSLPeerCert As %Net.X509Certificate) As %Status
{
	Set pHttpRequest.SSLCheckServerIdentity = 1
	#dim tStatus = pHttpRequest.Send(pVerb,pURL)
	If ($$$ISOK(tStatus)||$SYSTEM.Status.Equals(tStatus,$$$ERRORCODE($$$SSLNoCertificate),$$$ERRORCODE($$$SSLCertificateNoMatch))) { 
		Set pSSLPeerCert = ..%New(pHttpRequest.SSLPeerCertificate,tStatus)
		Return $$$OK
	} Else {
		Set pSSLPeerCert = $$$NULLOREF
		Return tStatus
	}
}

/// Convenience method to call <method>RetrievePeerCertificate</method> using a <class>%Library.DynamicObject</class>
/// to create the initial %Net.HttpRequest object and provide the other optional parameters.<br>
/// The structure of the pHttpInfo dynamic object is: <br>
/// {"url":<optional default="/">, <br>
/// {"verb":<optional default=OPTIONS>}, <br>
/// {"request":{"properties of %Net.HttpRequest...","Server":"docs.intersystems.com","SSLConfiguration":"ClientSSLConfig"}}
ClassMethod RetrievePeerCertUsingJSON(pHttpInfo As %DynamicObject, Output pHttpRequest As %Net.HttpRequest, Output pSSLPeerCert As %Net.X509Certificate) As %Status
{
	Set pHttpRequest = ##class(%Net.HttpRequest).%New()
	Set pHttpRequest.Https = 1
	#dim tIterator = pHttpInfo.%GetIterator()
	#dim tProperty, tValue
	#dim tURL = "/"
	#dim tVerb = "OPTIONS"
	While tIterator.%GetNext(.tProperty,.tValue) {
		If $zcvt(tProperty,"l") = "url" {
			Set tURL = tValue
		}ElseIf $zcvt(tProperty,"l") = "verb" {
			Set tVerb = tValue
		}ElseIf $zcvt(tProperty,"l") = "request" {
			#dim tRequestIterator = tValue.%GetIterator()
			#dim tRequestProperty, tRequestValue
			While tRequestIterator.%GetNext(.tRequestProperty,.tRequestValue) {
				Try {Set $property(pHttpRequest,tRequestProperty)=tRequestValue} Catch {}
			}
		}
	}
	Return ..RetrievePeerCertificate(.pHttpRequest, tURL, tVerb, .pSSLPeerCert)
}

}
