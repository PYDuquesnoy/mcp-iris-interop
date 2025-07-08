/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The %SYS.X509Credentials class defines the X.509 credentials which consist
/// of an X.509 certificate and an optionally associated private key.
/// An optional OwnerList may be specified to restrict which users have access to
/// these credentials.  The normal ObjectScript and SQL methods for accessing this
/// data should not be used and will not work with normal security in order to 
/// maintain the security of the credentials.
Class %SYS.X509Credentials Extends (%Persistent, %XML.Adaptor, %SYSTEM.Help) [ Final, System = 4 ]
{

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

Parameter VERSION [ Internal ] = 1;

Parameter SOURCECONTROL [ Internal ] = {"Revision path: $Id: //iris/2025.1.0/databases/sys/cls/SYS/X509Credentials.xml#1 $"_$c(13,10)_"Last Change:   $DateTime: 2025/01/31 13:48:15 $"_$c(13,10)_"Changelist #:  $Change: 7556155 $"};

/// The IDKEY for the credentials is a unique user defined alias.
Index IDIndex On Alias [ IdKey, Unique ];

/// The Alias is defined on import and identifies the X.509 certificate and private key.
Property Alias As %String(MAXLEN = 150) [ Required ];

/// The optional comma separated list of usernames which may access these credentials.
/// If no OwnerList is specified, the credentials are available to any user.
Property OwnerList As %String(MAXLEN = "");

/// The X.509 certificate.
Property Certificate As %Binary(MAXLEN = "") [ Required ];

/// Setter method for Certificate.
Method CertificateSet(certificate As %Binary) As %Status [ Internal ]
{
	Set i%Certificate=certificate
	Set i%Thumbprint=$system.Encryption.SHA1Hash(certificate)
	Set i%SubjectKeyIdentifier=$System.Encryption.X509GetField(certificate,"SubjectKeyIdentifier")
	Set i%SerialNumber=$System.Encryption.X509GetField(certificate,"SerialNumber")
	Set i%IssuerDN=$System.Encryption.X509GetField(certificate,"Issuer")
	Set i%SubjectDN=$System.Encryption.X509GetField(certificate,"Subject")
	Quit $$$OK
}

/// The type of the associated private key.
/// Only RSA is supported initially.
Property PrivateKeyType As %String(VALUELIST = ",RSA,DSA") [ InitialExpression = "RSA", Required ];

/// The private key associated with the certificate stored as PEM encoded text.
/// The private key will be in memory only when set before save.
/// The private key will not be loaded from global during open since transient.
Property PrivateKey As %String(MAXLEN = "", XMLIO = "IN") [ Transient ];

/// Store private key only if user has %Admin_Secure.
Method PrivateKeySet(privateKey As %String) As %Status [ Internal, PlaceAfter = FieldNumber ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		// Throw <CANNOT SET THIS PROPERTY> error
		Do $zu(96,3,158,1)
	}
	Set ..HasPrivateKey=(privateKey'="")
	Set i%PrivateKey=privateKey
	Quit $$$OK
}

/// Get private key only if user has %Admin_Secure.
Method PrivateKeyGet() As %String [ Internal, PlaceAfter = FieldNumber ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	If m%PrivateKey || (i%PrivateKey'="") {
		// PrivateKey may be set locally by caller.
		Set privateKey=i%PrivateKey
	} Else {
		Set privateKey=$listget($get($$$SecurityGlobalX509Credentials(..Alias)),$$$FieldPrivateKey)
	}
	Quit privateKey
}

/// Optional password for the private key.
/// The private key password will be in memory only when set before save.
/// The private key password will not be loaded from global during open since transient.
Property PrivateKeyPassword As %String(MAXLEN = 128, XMLIO = "IN") [ Transient ];

/// Set private key password.
Method PrivateKeyPasswordSet(privateKeyPassword As %String) As %Status [ Internal, PlaceAfter = FieldNumber ]
{
	Set i%PrivateKeyPassword=privateKeyPassword
	Quit $$$OK
}

/// Get private key password only if user has %Admin_Secure.
Method PrivateKeyPasswordGet() As %String [ Internal, PlaceAfter = FieldNumber ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	If m%PrivateKeyPassword || (i%PrivateKeyPassword'="") {
		// PrivateKeyPassword may be set locally in GetByAlias method, or by caller.
		Set privateKeyPassword=i%PrivateKeyPassword
	} Else {
		Set privateKeyPassword=$listget($get($$$SecurityGlobalX509Credentials(..Alias)),$$$FieldPrivateKeyPassword)
	}
	Quit privateKeyPassword
}

/// This property is used internally by InterSystems IRIS. You should not make direct use of it within your applications.
Property PrivateKeyExport As %String(MAXLEN = "", XMLIO = "OUT", XMLNAME = "PrivateKey") [ Internal, Transient ];

Method PrivateKeyExportGet() As %String [ Internal, Private ]
{
	Return i%PrivateKeyExport
}

Method PrivateKeyExportSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%PrivateKeyExport=val
	Return $$$OK
}

/// This property is used internally by InterSystems IRIS. You should not make direct use of it within your applications.
Property PrivateKeyPasswordExport As %String(MAXLEN = 128, XMLIO = "OUT", XMLNAME = "PrivateKeyPassword") [ Internal, Transient ];

Method PrivateKeyPasswordExportGet() As %String [ Internal, Private ]
{
	Return i%PrivateKeyPasswordExport
}

Method PrivateKeyPasswordExportSet(val As %String) As %Status [ Internal, Private ]
{
	Set i%PrivateKeyPasswordExport=val
	Return $$$OK
}

/// Returns if a private key is present even if no privileges.
Property HasPrivateKey As %Boolean [ InitialExpression = 0, Internal ];

/// File containing X.509 certificate(s) of trusted Certificate Authorities.<br>
/// Can be an absolute pathname or a pathname relative to the manager's directory.<br>
/// When WS-Security validates a Signature where the certificate is not included in
/// the SOAP message, the certificate is found in an %SYS.X509Credentials object.
/// If the CAFile property is specified in the %SYS.X509Credentials object, CAFile gives the path of the CA file.
/// If the CAFile property is not specified, then iris.cer in the mgr directory is used as the CA file.
Property CAFile As %String(MAXLEN = 255);

/// PeerNames is an optional comma separated list of peers which expect this 
/// certificate to be used.  Each peer name will normally be a DNS name.
/// However, any application defined name may be used.
Property PeerNames As %String(MAXLEN = "");

/// X.509 SubjectKeyIdentifier from the certificate.
/// This property is only set via the LoadCertificate method.
Property SubjectKeyIdentifier As %Binary;

/// For SubjectKeyIdentifier to be read-only.
Method SubjectKeyIdentifierSet(value As %Binary) As %Status [ Internal, Private ]
{
	Set i%SubjectKeyIdentifier=value
	Quit $$$OK
}

/// SHA1 Thumbprint of the certificate
/// This property is only set via the LoadCertificate method.
Property Thumbprint As %Binary;

/// For Thumbprint to be read-only.
Method ThumbprintSet(value As %Binary) As %Status [ Internal, Private ]
{
	Set i%Thumbprint=value
	Quit $$$OK
}

/// SerialNumber of the certificate -- unique for the Issuer.
/// This property is only set via the LoadCertificate method.
Property SerialNumber As %String;

/// For SerialNumber to be read-only.
Method SerialNumberSet(value As %Binary) As %Status [ Internal, Private ]
{
	Set i%SerialNumber=value
	Quit $$$OK
}

/// Issuer DistinguishedName of the certificate.
/// This property is only set via the LoadCertificate method.
Property IssuerDN As %String(MAXLEN = "");

/// For IssuerDN to be read-only.
Method IssuerDNSet(value As %String) As %Status [ Internal, Private ]
{
	Set i%IssuerDN=value
	Quit $$$OK
}

/// Subject DistinguishedName of the certificate.
/// This property is only set via the LoadCertificate method.
Property SubjectDN As %String(MAXLEN = "");

/// For SubjectDN to be read-only.
Method SubjectDNSet(value As %String) As %Status [ Internal, Private ]
{
	Set i%SubjectDN=value
	Quit $$$OK
}

/// X.509 ValidityNotBefore from the certificate.
Property ValidityNotBefore As %TimeStamp [ Calculated, ReadOnly, SqlComputeCode = { Set {ValidityNotBefore} = $select({Certificate}="":"",1:$System.Encryption.X509GetField({Certificate},"ValidityNotBefore")) }, SqlComputed, Transient ];

/// Getter for ValidityNotBefore.
Method ValidityNotBeforeGet() As %TimeStamp [ CodeMode = expression, Internal ]
{
$select(i%Certificate="":"",1:$System.Encryption.X509GetField(i%Certificate,"ValidityNotBefore"))
}

/// For ValidityNotBefore to be read-only.
Method ValidityNotBeforeSet(value As %TimeStamp) As %Status [ Internal, Private ]
{
	Quit $$$OK
}

/// X.509 ValidityNotAfter from the certificate.
Property ValidityNotAfter As %TimeStamp [ Calculated, ReadOnly, SqlComputeCode = { Set {ValidityNotAfter} = $select({Certificate}="":"",1:$System.Encryption.X509GetField({Certificate},"ValidityNotAfter")) }, SqlComputed, Transient ];

/// Getter for ValidityNotAfter.
Method ValidityNotAfterGet() As %TimeStamp [ CodeMode = expression, Internal ]
{
$select(i%Certificate="":"",1:$System.Encryption.X509GetField(i%Certificate,"ValidityNotAfter"))
}

/// For ValidityNotAfter to be read-only.
Method ValidityNotAfterSet(value As %TimeStamp) As %Status [ Internal, Private ]
{
	Quit $$$OK
}

/// Version number of the record. <br>
/// Used for Export/Import.<br>
Property Version As %Decimal(SCALE = 1) [ Internal ];

/// Return true if the same credentials -- same certificate in this case.
Method Equals(credentials As %SYS.X509Credentials) As %Boolean
{
	If '$isobject(credentials) Quit 0
	If credentials.%Extends("%SYS.X509Credentials") {
		If ..Certificate'=credentials.Certificate Quit 0
	} ElseIf credentials.%Extends("%XML.Security.RSAKeyValue") {
		If credentials.Modulus'=$System.Encryption.X509GetField(..Certificate,"RSAPublicKeyModulus") Quit 0
		If credentials.Exponent'=$System.Encryption.X509GetField(..Certificate,"RSAPublicKeyExponent") Quit 0
	} Else {
		Quit 0
	}
	
	Quit 1
}

/// The Save method saves an X509Credentials object.
/// To save a new X509Credentials object use the following procedure:<br>
/// - get a new object with %New.<br>
/// - set required unique Alias property.<br>
/// - set any needed properties.<br>
/// - load the certificate with the LoadCertificate method.<br>
/// - load the private key with the LoadPrivateKeymethod.<br>
/// - call the Save method.
Method Save() As %Status
{
	s $zt="Error"
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}

	Set sc=..%Save()
	
	Quit sc
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Internal, PlaceAfter = FieldNumber, Private ]
{
	Set $zt="Error"
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	// Save private key and password only after save has been successful.
	Set $list($$$SecurityGlobalX509Credentials(..Alias),$$$FieldPrivateKey)=i%PrivateKey
	Set i%PrivateKey=""
	Set m%PrivateKey=0
	Set $list($$$SecurityGlobalX509Credentials(..Alias),$$$FieldPrivateKeyPassword)=i%PrivateKeyPassword
	Set i%PrivateKeyPassword=""
	Set m%PrivateKeyPassword=0
	Quit $$$OK
Error Set $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Validate the object during save.
/// Note that the PrivateKey property is accessed from memory during save.
Method %OnValidateObject(ReadOnly As %Boolean = 0) As %Status [ Private, ServerOnly = 1 ]
{
 s $ZT="Error"
 // Certificate must be present.
 If (..Certificate="") Quit $$$ERROR($$$MissingX509Certificate)
 // CAFile must exist and be readable if specified.
 If (..CAFile'="") {
	 Set cafile=##class(%File).NormalizeFilename(..CAFile,##class(%File).ManagerDirectory())
	 If '##class(%File).Exists(cafile) q $$$ERROR($$$FileDoesNotExist,cafile)
 } Else {
	 // default CA File
	 Set cafile=##class(%File).NormalizeFilename("iris.cer",$zu(12))
	 If '##class(%File).Exists(cafile) Set cafile="" 
 }
 // Reject expired Certificate.
 Set notAfter="",expired=0
 Try {
	 Set notAfter=$System.Encryption.X509GetField(..Certificate,"ValidityNotAfter")
	 If ($zdt($zts,3)]notAfter) Set expired=1
 }
 Catch {
 }
 If notAfter="" q $$$ERROR($$$InvalidCert,$$$Text("in X.509 Credentials"))
 If expired q $$$ERROR($$$CertificateExpired,$$$Text("in X.509 Credentials"))
 // Only validates the CAFile CertChain if we don't have a PrivateKey
 if cafile'="",'..HasPrivateKey {
 	s rc = $SYSTEM.Encryption.X509VerifyCertChain(..Certificate,cafile)
 	if rc'="OK" q $$$ERROR($$$CertVerifyFailed,$$$Text("in X.509 Credentials"),cafile,rc)
 }
 If (..PrivateKeyType'="RSA") q $$$OK ; Continue checking for RSA
 If ('..HasPrivateKey) q $$$OK ; Optional?
 If (..PrivateKey["ENCRYPTED")&&(..PrivateKeyPassword="") q $$$OK ; password may be requested from user.
 Set plain="InterSystems Corp."
 Set cipher=$SYSTEM.Encryption.RSAEncrypt(plain,..Certificate)
 If cipher="" q $$$ERROR($$$PublicKeyEncryptionFailed,$$$Text("for  X.509 Credentials"))
 Set plain2=$SYSTEM.Encryption.RSADecrypt(cipher,..PrivateKey,..PrivateKeyPassword)
 If (plain2'=plain) {
	 Set err=$SYSTEM.Encryption.RSAGetLastError()
	 If (err["pkcs12 cipherfinal error")||(err["bad decrypt") q $$$ERROR($$$PrivateKeyFileDecryptionFailed,$$$Text("for X.509 Credentials"))
	 q $$$ERROR($$$PublicPriveKeyMismatch,$$$Text("of this %SYS.X509Credentials object"),$$$Text("this %SYS.X509Credentials object"))
 }
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Caller of %Save must have secureity admin resource. 
Method %OnBeforeSave(insert As %Boolean) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}

	set String="", CRLF=$c(13,10)
	set CurrentValues=$$$GetMsg($$$AuditMsg,"CurrentValues")_CRLF, padlen=30, Pad=$j("",padlen) // padlen may need to be increased if the localizations in SystemMessages end up being long.
	if (insert) {
		s i%Version=..#VERSION
		set id=i%Alias // Must use Alias since %Id() isn't valid during an insert
		set Msg=$$$FormatMsg($$$AuditMsg,"CreateHeader",$$$GetMsg($$$X509CredentialsMsg,"X509Credentials"), id)
		// Leave "String" empty, we give no details on Create actions
	} else {
		set id=..%Id()
		set Msg=$$$FormatMsg($$$AuditMsg,"ModifyHeader",$$$GetMsg($$$X509CredentialsMsg,"X509Credentials"), id)
		set Changes=""
	}
	
	for Property="CAFile", "Certificate", "IssuerDN", "OwnerList", "PeerNames", "PrivateKey", "PrivateKeyPassword", "PrivateKeyType", "SerialNumber", "SubjectDN", "SubjectKeyIdentifier", "Thumbprint" { // ValidityNotAfter and ValidityNotBefore are calculated, so we skip them
		// Check display type
		set displayAsHex=((Property="Thumbprint")||(Property="SubjectKeyIdentifier"))
		set displayRedacted=((Property [ "PrivateKey")||(Property="Certificate"))
		
		// Display new/current value
		if (displayRedacted) { set newValueDisplay=$$$GetMsg($$$X509CredentialsMsg,"Redacted") }
		else {
			// PrivateKey* properties are not guaranteed to be in memory, but by now we know we're not redacted / PrivateKey* and can load them safely
			set newValue=$property($this,Property)
			if (displayAsHex) { set newValueDisplay=..BinaryToHexString(newValue) }
			else { set newValueDisplay=newValue }
		}
		set CurrentValues=CurrentValues_$e($$$GetMsg($$$X509CredentialsMsg, Property_"C")_Pad,1,padlen)_newValueDisplay_CRLF
		
		if ('insert&&$method($this, Property_"IsModified")) {
			// Construct changes block
			// Workaround for now GetStored method for private key.
			If $case(Property,"PrivateKey":0,"PrivateKeyPassword":0,:1) {
				set oldValue=$method($this, Property_"GetStored", id)
			} else {
				set oldValue=""
			}
			if (displayRedacted) { set oldValueDisplay=$$$GetMsg($$$X509CredentialsMsg,"Redacted") }
			elseif (displayAsHex) { set oldValueDisplay=..BinaryToHexString(oldValue) }
			else { set oldValueDisplay=oldValue }
			set Changes=Changes_$$$FormatMsg($$$AuditMsg,"Modified",Property)_CRLF
			set Changes=Changes_$$$FormatMsg($$$AuditMsg,"NewValue",newValueDisplay)_CRLF
			set Changes=Changes_$$$FormatMsg($$$AuditMsg,"OldValue",oldValueDisplay)_CRLF
		}
	}

	if (insert) {
		set String=CurrentValues
	} else {
		set String=Changes_CRLF_"--------------------------------------------------"_CRLF_CurrentValues
	}
	do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameX509CredentialsChange,String,Msg)
	
	// Get the PrivateKey and PrivateKeyPassword for later use in %OnAfterSave
	Set i%PrivateKey=..PrivateKey
	Set i%PrivateKeyPassword=..PrivateKeyPassword
	
	Quit $$$OK
}

/// Make sure that HasPrivateKey is always correctly defined
Method %OnOpen() As %Status [ Internal, Private, ServerOnly = 1 ]
{
	Quit $$$OK
}

/// Change the binary data (stored in Thumbprint and SubjectKeyIdentifier) into formatted hex string.
/// Like zzdump, 8-bit strings will be displayed in 1-byte words, ziswide() strings will be displayed in 2-byte words.
ClassMethod BinaryToHexString(input As %Binary) As %String
{
	set len=$l(input), output=""
	if $ziswide(input) { Set digits=4 } Else { Set digits=2 }
	// Code for the hex transform is similar to that in ISCzzdump.inc
	// ##class(%SYS.X509Credentials).BinaryToHexString("InterSystems IRIS")="49 6e 74 65 72 53 79 73 74 65 6d 73 20 49 52 49 53"
	for i=1:1:len {
		set hexValue=$tr($justify($zhex($ascii(input,i)),digits)," ","0")
		set output=output_hexValue_" "
	}
	set output=$extract(output, 1, *-1)
	set output=$zconvert(output, "L")
	return output
}

/// Load a certificate from a certificate file.
Method LoadCertificate(filename As %String) As %Status
{
	// Read .cer file.
	Set file=##class(%File).%New(filename)
	Set sc=file.Open("RSK\RAW\")
	If $$$ISERR(sc) Quit sc
	Set text=file.Read()
	While 'file.AtEnd {
		Set text=text_$c(10)_file.Read()
	}
	// Ignore all CR
	Set text=$tr(text,$c(13),"")
	// Strip begin certificate line and end certificate line
	Set begin="-----BEGIN CERTIFICATE-----"_$c(10)
	Set end=$c(10)_"-----END CERTIFICATE-----"
	If ($length(text,begin)'=2) || ($length(text,end)'=2) {
		Set text=""
	} Else {
		Set text=$piece($piece(text,begin,2),end,1)
	}
	If text="" Quit $$$ERROR($$$WSSECURITYBadCertificate,filename)
	// Decode base64 and store certificate
	Set ..Certificate=$system.Encryption.Base64Decode(text)
	Quit $$$OK
}

/// Load a private key from a private key file.
Method LoadPrivateKey(filename As %String) As %Status
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	// Read .key file.
	Set file=##class(%File).%New(filename)
	Set sc=file.Open("RSK\RAW\")
	If $$$ISERR(sc) Quit sc
	Set privateKey=file.Read()
	While 'file.AtEnd {
		Set privateKey=privateKey_$c(10)_file.Read()
	}
	Set ..PrivateKey=privateKey
	Quit $$$OK
}

/// The Delete method deletes an existing X509Credentials object specified by its alias.
ClassMethod Delete(alias As %String) As %Status
{
	s $zt="Error"
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	
	Set sc=..%DeleteId(alias)
	
	Quit sc
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Caller of %Delete must have security admin resource. 
ClassMethod %OnDelete(oid As %ObjectIdentity) As %Status [ Internal, Private, ServerOnly = 1 ]
{
	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}
	set X509Credential=..%Open(oid,,.Status)
	if '$$$ISOK(Status) q Status
	set Msg=$$$FormatMsg($$$AuditMsg,"DeleteHeader",$$$GetMsg($$$X509CredentialsMsg,"X509Credentials"), X509Credential.Alias)
	do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameX509CredentialsChange,"",Msg)
	Quit $$$OK
}

/// Internal method to return field position based on name.
ClassMethod FieldNumber(fieldName As %String) As %Integer [ Internal, Private ]
{
#define FieldOwnerList				2
#define FieldCertificate			3
#define FieldPrivateKeyType			4
#define FieldPrivateKey				5
#define FieldPrivateKeyPassword		6
#define FieldPeerNames				7
#define FieldSubjectKeyIdentifier	8
#define FieldThumbprint				9
#define FieldSerialNumber			10
#define FieldIssuerDN				11
#define FieldSubjectDN				12
#define FieldAlias                  -1

	If fieldName="OwnerList" {
		Quit $$$FieldOwnerList
	} ElseIf fieldName="Certificate" {
		Quit $$$FieldCertificate
	} ElseIf fieldName="PeerNames" {
		Quit $$$FieldPeerNames
	} ElseIf fieldName="SubjectKeyIdentifier" {
		Quit $$$FieldSubjectKeyIdentifier
	} ElseIf fieldName="Thumbprint" {
		Quit $$$FieldThumbprint
	} ElseIf fieldName="SerialNumber" {
		Quit $$$FieldSerialNumber
	} ElseIf fieldName="IssuerDN" {
		Quit $$$FieldIssuerDN
	} ElseIf fieldName="SubjectDN" {
		Quit $$$FieldSubjectDN
	} Else {
		Quit 0
	}
}

/// Get a X.509 credentials record based on the unique alias.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByAlias(alias As %String, pwd As %String) As %SYS.X509Credentials
{
	If alias="" Quit ""
	Try {
		Set x509=..%OpenId(alias)
	
		// Do not return, if OwnerList specified and current user not in list.
		If (x509'="") && (x509.OwnerList'="") && ((","_x509.OwnerList_",")'[(","_$username_",")) {
			Set x509=""
		}
	
		// Set password from argument if specified
		If (x509'="") && ($get(pwd)'="") Set x509.PrivateKeyPassword=pwd

	} Catch err {
		Throw err
	}
	Quit x509
}

/// Get a X.509 credentials record based on the unique SubjectKeyIdentifier.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetBySubjectKeyIdentifier(searchValue As %Binary) As %SYS.X509Credentials [ PlaceAfter = FieldNumber ]
{
	Quit ..GetByFieldNumber($$$FieldSubjectKeyIdentifier,searchValue)
}

/// Get a X.509 credentials record based on the unique SHA1 Thumbprint.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByThumbprint(searchValue As %Binary) As %SYS.X509Credentials
{
	Quit ..GetByFieldNumber($$$FieldThumbprint,searchValue)
}

/// Get a X.509 credentials record based on the unique X.509 certificate.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByCertificate(searchValue As %Binary) As %SYS.X509Credentials
{
	Quit ..GetByFieldNumber($$$FieldCertificate,searchValue)
}

/// Get a X.509 credentials record based on the unique X.509 certificate for use with a private key.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByCertificateWithPrivateKey(searchValue As %Binary) As %SYS.X509Credentials
{
	Set credentialsList=..FindByField("Certificate",searchValue)
	Set credentials=""
	For i=1:1:credentialsList.Count() {
		If credentialsList.GetAt(i).HasPrivateKey {
			Set credentials=credentialsList.GetAt(i)
			Quit
		}
	}
	Quit credentials
}

/// Get a X.509 credentials record which has a certificate whose
/// public key matches the specified RSAKeyValue.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByRSAKeyValue(searchValue As %XML.Security.RSAKeyValue) As %SYS.X509Credentials
{
	s $zt="Error"
	
	// Loop until next object found that is allowed for current user.
	Set x509=""
	Set alias=$order($$$SecurityGlobalX509Credentials(""))
	While alias'="" {
		Set certificate=$list($$$SecurityGlobalX509Credentials(alias),$$$FieldCertificate)
		If searchValue.Equals(certificate) {
			Set ownerList=$list($$$SecurityGlobalX509Credentials(alias),$$$FieldOwnerList)
			If (ownerList="") || ((","_ownerList_",")[(","_$username_",")) {
				Set x509=..%OpenId(alias)
				Quit
			}
		}
		Set alias=$order($$$SecurityGlobalX509Credentials(alias))
	}
	
	Quit x509
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Get a X.509 credentials record based on the unique field name of the credentials object.
/// The possible field names are Certificate, SubjectKeyIdentifier, Thumbprint, 
/// SerialNumber, IssuerDN, SubjectDN, PeerNames, OwnerList.
/// Note that only Certificate, SubjectKeyIdentifier, Thumbprint are sure to
/// have an exact match.  FindByField shold normally be used for the other fields.
/// The match is exact and case sensitive.  The first match is returned.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByField(fieldName As %Integer, searchValue As %Binary) As %SYS.X509Credentials [ Internal ]
{
	Set number=..FieldNumber(fieldName)
	If number=0 Quit ""
	
	Quit ..GetByFieldNumber(number,searchValue)
}

/// Get a X.509 credentials record based on the unique field number of the credentials object.
/// The record must have a null OwnerList or be owned by the current user to be returned.
ClassMethod GetByFieldNumber(field As %Integer, searchValue As %Binary) As %SYS.X509Credentials [ Internal, Private ]
{
	s $zt="Error"
	
	// Loop until next object found that is allowed for current user.
	Set x509=""
	Set alias=$order($$$SecurityGlobalX509Credentials(""))
	While alias'="" {
		Set value=$list($$$SecurityGlobalX509Credentials(alias),field)
		If value=searchValue {
			Set ownerList=$list($$$SecurityGlobalX509Credentials(alias),$$$FieldOwnerList)
			If (ownerList="") || ((","_ownerList_",")[(","_$username_",")) {
				Set x509=..%OpenId(alias)
				Quit
			}
		}
		Set alias=$order($$$SecurityGlobalX509Credentials(alias))
	}

	Quit x509
Error s $zt=""
	Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Check that the field name is valid for search by FindByField
ClassMethod CheckFieldName(fieldName As %String) As %Boolean [ Internal ]
{
	Quit $case(fieldName,"IssuerDN":1,"IssuerName":1,"SubjectDN":1,"SubjectName":1,"Certificate":1,"SubjectKeyIdentifier":1,"Thumbprint":1,"SerialNumber":1,"PeerNames":1,"OwnerList":1,"Alias":1,:0)
}

/// Find the %SYS.X509Credentials instances which have a match in the specified
/// field to the specified value.
/// If the credentialsList property is specified, then only matches from this
/// list are returned.  Otherwise all matches from the database are returned.<br>
/// The following searches are supported:
/// 		<li>Alias - Unique, exact match on the Alias</li>
/// 		<li>Certificate - Unique, exact match on the certificate</li>
/// 		<li>SubjectKeyIdentifier - Unique, exact match to the SubjectKeyIdentifier</li>
/// 		<li>Thumbprint - Unique, exact match to the Thumbprint</li>
/// 		<li>SerialNumber - Exact match to the serial number</li>
/// 		<li>IssuerDN - Case insensitive match to the Issuer DistinguishedName</li>
/// 		<li>IssuerName - Case insensitive match to any Issuer DistinguishedName which contains the searchValue.</li>
/// 		<li>SubjectDN - Case insensitive match to the Subject DistinguishedName</li>
/// 		<li>SubjectName - Case insensitive match to any Subject DistinguishedName which contains the searchValue</li>
/// 		<li>PeerNames - Case insensitive match to any PeerNames list which contains the searchValue</li>
/// 		<li>OwnerList - Case insensitive match to any OwnerList list which contains the searchValue</li><br>
/// A %ListOfObjects is returned containing the matching %SYS.X509Credentials instances.
/// The %ListOfObjects will have no entries if there are no matches.
/// If the field name is not valid, then "" will be returned.
ClassMethod FindByField(fieldName As %String, searchValue As %String, credentialsList As %ListOfObjects) As %ListOfObjects [ PlaceAfter = FieldNumber ]
{
	If fieldName="IssuerDN" {
		Set field=$$$FieldIssuerDN
		Set caseSensitive=0
		Set contains=0
		Set searchValue=..NormalizeDN(searchValue)
	} ElseIf fieldName="IssuerName" {
		Set field=$$$FieldIssuerDN
		Set caseSensitive=0
		Set contains=1
		Set searchValue=..NormalizeDN(searchValue)
	} ElseIf fieldName="SubjectDN" {
		Set field=$$$FieldSubjectDN
		Set caseSensitive=0
		Set contains=0
		Set searchValue=..NormalizeDN(searchValue)
	} ElseIf fieldName="SubjectName" {
		Set field=$$$FieldSubjectDN
		Set caseSensitive=0
		Set contains=1
		Set searchValue=..NormalizeDN(searchValue)
	} ElseIf fieldName="Certificate" {
		Set field=$$$FieldCertificate
		Set caseSensitive=1
		Set contains=0
	} ElseIf fieldName="SubjectKeyIdentifier" {
		Set field=$$$FieldSubjectKeyIdentifier
		Set caseSensitive=1
		Set contains=0
	} ElseIf fieldName="Thumbprint" {
		Set field=$$$FieldThumbprint
		Set caseSensitive=1
		Set contains=0
	} ElseIf fieldName="SerialNumber" {
		Set field=$$$FieldSerialNumber
		Set caseSensitive=1
		Set contains=0
	} ElseIf fieldName="PeerNames" {
		Set field=$$$FieldPeerNames
		Set caseSensitive=1
		Set contains=1
	} ElseIf fieldName="OwnerList" {
		Set field=$$$FieldOwnerList
		Set caseSensitive=1
		Set contains=1
	} ElseIf fieldName="Alias" {
		Set field=$$$FieldAlias
		Set caseSensitive=1
		Set contains=0
	} Else {
		Quit ""
	}
	
	Quit ..FindByFieldNumber(field,searchValue,caseSensitive,contains,.credentialsList)
}

/// Internal function to find the %SYS.X509Credentials instances which have a match in the specified
/// field number to the specified value.
/// If the credentialsList property is specified, then only matches from this
/// list are returned.  Otherwise all matches from the database are returned.
ClassMethod FindByFieldNumber(field As %Integer, searchValue As %String, caseSensitive As %Boolean, contains As %Boolean, credentialsList As %ListOfObjects) As %ListOfObjects
{
	Try {
	If 'caseSensitive Set searchValue=$zcvt(searchValue,"L")
	Set aliasMatch=(field=$$$FieldAlias)
	
	Set matches=##class(%ListOfObjects).%New()
	
	If $get(credentialsList)="" {
		// Loop and test all objects found that are allowed for current user.
		Set alias=$order($$$SecurityGlobalX509Credentials(""))
		While alias'="" {
			If aliasMatch {
				Set value=alias
			} Else {
				Set value=$list($$$SecurityGlobalX509Credentials(alias),field)
			}
			If 'caseSensitive Set value=$zcvt(value,"L")
			If (contains && (value[searchValue)) || ('contains && (value=searchValue)) {
				Set ownerList=$list($$$SecurityGlobalX509Credentials(alias),$$$FieldOwnerList)
				If (ownerList="") || ((","_ownerList_",")[(","_$username_",")) {
					Set x509=..%OpenId(alias)
					Do matches.Insert(x509)
				}
			}
			Set alias=$order($$$SecurityGlobalX509Credentials(alias))
		}
	} Else {
		// Loop and test all objects in credentialsList that are allowed for current user.
		Set alias=$order($$$SecurityGlobalX509Credentials(""))
		For i=1:1:credentialsList.Count() {
			Set x509=credentialsList.GetAt(i)
			Set alias=x509.Alias
			If aliasMatch {
				Set value=alias
			} Else {
				Set value=$list($$$SecurityGlobalX509Credentials(alias),field)
			}
			If 'caseSensitive Set value=$zcvt(value,"L")
			If (contains && (value[searchValue)) || ('contains && (value=searchValue)) {
				Set ownerList=x509.OwnerList
				If (ownerList="") || ((","_ownerList_",")[(","_$username_",")) {
					Do matches.Insert(x509)
				}
			}
		}
	}
	} catch {
		throw
	}

	Quit matches
}

/// Check if specified peer name is valid for this set of credentials.
Method CheckPeerName(peerName As %String) As %Boolean [ CodeMode = expression ]
{
(..PeerNames="") || ((","_..PeerNames_",")[peerName)
}

/// Return the next X.509 credentials object that is accessible to
/// the current user based on the alias argument.  Return "" if no more objects available.  The alias argument is
/// updated to correspond to the returned object.
ClassMethod GetNext(ByRef alias As %String) As %SYS.X509Credentials
{
	Try {	
	// Loop until next object found that is allowed for current user.
	Set x509=""
	For {
		Set alias=$order($$$SecurityGlobalX509Credentials(alias))
		If alias="" Quit

		// Get the credentials object
		Set x509=..%OpenId(alias)

		// Return if OwnerList not specified or current user not in list.
		If (x509'="") {
			If (x509.OwnerList="") || ((","_x509.OwnerList_",")[(","_$username_",")) {
				Quit
			} Else {
				Set x509=""
			}
		}
	}
	} catch {
	throw
	}
	Quit x509
}

Query ListDetails() As %SQLQuery [ SqlProc ]
{
	SELECT Alias, OwnerList, PeerNames, HasPrivateKey, CAFile FROM X509Credentials
 		ORDER BY Alias
}

Query ListPrivateKey() As %SQLQuery [ SqlProc ]
{
	SELECT Alias, OwnerList, PeerNames, HasPrivateKey FROM X509Credentials
		WHERE HasPrivateKey = 1
 		ORDER BY Alias
}

Query ListAll() As %SQLQuery [ SqlProc ]
{
	SELECT Alias, OwnerList, Certificate, PrivateKeyType, PeerNames, SubjectKeyIdentifier, Thumbprint, SerialNumber, IssuerDN, SubjectDN, CAFile, ValidityNotBefore, ValidityNotAfter FROM X509Credentials
 		ORDER BY Alias
}

/// Convert variants of the string representation of a Distinguished Name as defined by
/// section 4 of RFC 2253 to normal form
ClassMethod NormalizeDN(name As %String) As %String
{
/// Escape special characters in quoted strings, remove quotes
 Set name=$replace(name,"\""",$c(255))
 Set c(1)=",",c(2)="=",c(3)="+",c(4)="<",c(5)=">",c(6)="#",c(7)=";",count=7
 Set first=$find(name,"""")
 While (first>0) {
 	Set last=$find(name,"""",first)
 	If (last=0) quit
 	Set p1=$extract(name,1,first-2)
 	Set p2=$extract(name,first,last-2)
 	Set p3=$extract(name,last,*)
 	For i=1:1:count {
 		Set p2=$replace(p2,c(i),"\"_c(i))
 	}
 	Set name=p1_p2_p3
 	Set first=$find(name,"""")
 }
/// Replace unescaped ";" with ","
 Set name=$replace(name,"\;",$c(255))
 Set name=$replace(name,";",",")
 Set name=$replace(name,$c(255),"\;")
/// Remove extra space around unescaped ",", "+", and "="
 Set ch(1)=",",ch(2)="+",ch(3)="=",count=3
 For i=1:1:count {
 	Set name=$replace(name,"\"_ch(i),$c(255))
 	While ($find(name," "_ch(i)) || $find(name,ch(i)_" ")) {
 		Set name=$replace(name," "_ch(i),ch(i))
 		Set name=$replace(name,ch(i)_" ",ch(i))
 	}
 	Set name=$replace(name,$c(255),"\"_ch(i))
 }
 Quit name
}

/// X509Credential exists.<br>
/// This method checks for the existence of a X509Credential in the security database.<br>
/// Parameters:<br>
/// Name - Name of the X509Credential to check existence of<br>
/// Return values:<br>
/// If Value of the method = 0 (X509Credential does not exist, or some error occurred)<br>
/// X509Credential = Null<br>
/// Status = X509Credential "x" does not exist, or other error message<br><br>
/// If Value of the method = 1 (X509Credential exists)<br>
/// X509Credential = Object handle to X509Credential<br>
/// Status = $$$OK<br>
ClassMethod Exists(Name As %String, ByRef X509Credential As %ObjectHandle, ByRef Status As %Status) As %Boolean
{
 s $zt="Error"
 k X509Credential
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 s X509Credential=..%OpenId(Name,,.Status)
 ;s X509Credential=..%OpenId($zcvt(Name,"L"),,.Status)
 i $$$ISOK(Status) q 1
 i $p($SYSTEM.Status.GetErrorCodes(Status),",")=$$$ERRORCODE($$$LoadObjectNotFound) s Status=$$$ERROR($$$X509CredentialsDoesNotExist,Name)
 q 0
Error s $zt=""
 s Status=$$$ERROR($$$ObjectScriptError,$ze)
 q 0
}

/// This method exports X509Credential records to a file in xml format.<br>
/// Parameters:<br>
/// Filename -  Output file name<br>
/// NumExported (byref) -  Returns number of records exported.<br>
/// X509Credentials - Comma separated list of X509Credentials to export, "*" = All<br>
/// IncludePrivateKey - boolean value. If 1 (true), then the private key and password will be included in the export file, otherwise it will be omitted. 
/// It is the responsibility of the caller to secure the resulting file. <br>
ClassMethod Export(FileName As %String = "X509CredentialsExport.xml", ByRef NumExported As %Integer, X509Credentials As %String = "*", IncludePrivateKey As %Boolean = 0) As %Status
{
 	Try {
		Set NumExported=0
		Set PrivateKeysExported=0
		Set sc = $$$OK
		If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
			Return $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
		}
		If (X509Credentials="*")||(X509Credentials="") {
			#; Create a list query to get all the X509Credential objects.
			Set stmt = ##class(%SQL.Statement).%New()
			Set sc = stmt.%PrepareClassQuery("%SYS.X509Credentials","ListAll")
			If $$$ISERR(sc) Return sc
			Set rs = stmt.%Execute()
			Set aliases = ""
			While rs.%Next() {
				Set aliases = aliases_$lb(rs.%Get("Alias"))
			}
		} Else {
			#; the user gave a comma separated list
			Set aliases = $listfromstring(X509Credentials,",")
		}

		#; Create and initialize an %XML.Writer object
		Set writer=##class(%XML.Writer).%New()
		Set sc=writer.OutputToFile(FileName)
		If $$$ISERR(sc) Quit
		Set writer.Charset="UTF-8"
		Set writer.Indent=1
		Set sc=writer.RootElement("X509CredentialsExport")
		If $$$ISERR(sc) Quit
	 
		Set PrivateKeysExported=0
		For i=1:1:$listlength(aliases) {
			If '..Exists($listget(aliases,i),.oref,.sc) Continue
			#;Perform the export using the object
			If IncludePrivateKey,oref.HasPrivateKey {
				Set PrivateKeysExported = PrivateKeysExported+1
				Set oref.PrivateKeyExport = oref.PrivateKey
				Set oref.PrivateKeyPasswordExport = oref.PrivateKeyPassword
			}
			Set sc=writer.Object(oref)
			If IncludePrivateKey {
				Set oref.PrivateKeyExport=""
				Set oref.PrivateKeyPasswordExport=""
			}
			If $$$ISERR(sc) Quit
				Set NumExported=NumExported+1
			}
			Set sc=writer.EndRootElement()
			If $$$ISERR(sc) Quit
			Do writer.EndDocument() Kill writer
	} Catch e {
		If IncludePrivateKey,$isobject($g(oref)) {
			Set oref.PrivateKeyExport=""
			Set oref.PrivateKeyPasswordExport=""
		}
		Set sc = e.AsStatus()
	}
	#; Clean up in case of error
	Try {
		If $d(writer) Do writer.EndDocument()
	} Catch e {
		Set sc = $$$ADDSC(sc,e.AsStatus())
	}
 	
 	#; Always write to Audit log if we attempted to export a private key. 	
	If IncludePrivateKey,PrivateKeysExported>0 {
		If $$$ISOK(sc) {
			Set String=$$$FormatMsg($$$X509CredentialsMsg,"ExportNumPK",NumExported,FileName,PrivateKeysExported)
			#; write to messages.log
			Do $zu(9,"",String,0,0)
		} Else {
			Set String=$$$FormatMsg($$$X509CredentialsMsg,"ExportNumPKErr",NumExported,FileName,PrivateKeysExported)
		}
	} ElseIf $$$ISOK(sc) {
		Set String=$$$FormatMsg($$$X509CredentialsMsg,"ExportNum",NumExported,FileName)
	}
 
	If $data(String) {
		Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameX509CredentialsChange,String,$$$GetMsg($$$X509CredentialsMsg,"Export"))
	}
 
	Return sc
}

/// Get a X509Credential's properties.<br>
/// Gets a X509Credential's properties from the security database.<br>
/// Parameters:<br>
/// X509Credential - Object handle to a X509Credentials record<br>
/// Return values:<br>
/// Properties - See the Get method for more information on properties returned
ClassMethod GetProperties(X509Credential As %ObjectHandle, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 k Properties
 s Properties("OwnerList")=X509Credential.OwnerList
 s Properties("Certificate")=X509Credential.Certificate
 s Properties("PrivateKeyType")=X509Credential.PrivateKeyType
 s Properties("PrivateKey")=X509Credential.PrivateKey
 s Properties("PrivateKeyPassword")=X509Credential.PrivateKeyPassword
 s Properties("PeerNames")=X509Credential.PeerNames
 s Properties("SubjectKeyIdentifier")=X509Credential.SubjectKeyIdentifier
 s Properties("Thumbprint")=X509Credential.Thumbprint
 s Properties("SerialNumber")=X509Credential.SerialNumber
 s Properties("IssuerDN")=X509Credential.IssuerDN
 s Properties("SubjectDN")=X509Credential.SubjectDN
 s Properties("CAFile")=X509Credential.CAFile
 s Properties("ValidityNotBefore")=X509Credential.ValidityNotBefore
 s Properties("ValidityNotAfter")=X509Credential.ValidityNotAfter
 q $$$OK
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Import X509Credential records from an xml file.<br>
/// Parameters:<br>
/// FileName - Filename to import X509Credential records from<br>
/// NumImported (byref) - Returns number of records imported<br>
/// Flags - Control import<br>
/// Bit 0 - Do not import records, just return count<br>
/// Note: On failure, no records will be imported<br>
ClassMethod Import(FileName As %String = "X509CredentialsExport.xml", ByRef NumImported As %Integer, Flags As %Integer = 0) As %Status
{
 s $zt="Error"
 s NumImported=0
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 #; Create and initialize an %XML.Reader object
 i '$zb(Flags,1,1) {
 	TSTART
 	s TSTART=1
 }
 s reader=##class(%XML.Reader).%New()
#;If called from Security.System:ImportAll(), the filename will be in $list format
#;Piece 1 - Original file imported from, used in audit record
#;Piece 2 - Converted temp file imported from
#;$lb("c:\iris\mgr\export.xml","c:\iris\mgr\temp\udhiue")
 i $listvalid(FileName) {
	 s File=$li(FileName,2)
	 s FileName=$li(FileName,1)
 } else {
	 s File=FileName
 }
 s sc=reader.OpenFile(File)
 i $$$ISERR(sc) goto Rollback
 Do reader.Correlate("X509Credentials","%SYS.X509Credentials")
 While reader.Next(.Object,.sc) {
	i $$$ISERR(sc) q 
#;X509Credentials without version numbers are compatible from several versions ago, so set to version 1.	
    i Object.Version="" s Object.Version=1
    i Object.Version>..#VERSION {
		s sc=$$$ERROR($$$IncompatibleImportVersion1,"%SYS.PhoneProviders",Object.Version,..#VERSION)
		q  
    }
#;Add code here to perform conversion if versions don't match
    i Object.Version'=..#VERSION {
    }
	i $zb(Flags,1,1) {
		s NumImported=NumImported+1
		Continue
	}
	if Object.HasPrivateKey,Object.PrivateKey="" {
		set Object.HasPrivateKey=0
	}
    s tf=..Exists(Object.Alias,,.sc)
    i 'tf {
	    s sc=Object.%Save() 
	    i $$$ISERR(sc) q
    } else {
	   #; set up properties and call Modify to update existing resource
	   s sc=..GetProperties(Object,.Properties)
	   i $$$ISERR(sc) q
	   s sc=..Modify(Object.Alias,.Properties)
       i $$$ISERR(sc) q
    }
    s NumImported=NumImported+1
 }
 i $$$ISERR(sc) goto Rollback
 i $d(TSTART) {
	TCOMMIT
	k TSTART
 }
 i '$zb(Flags,1,1) {
 	s String=$$$FormatMsg($$$X509CredentialsMsg,"ImportNum",NumImported,FileName)
 	Do ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSecurity,$$$NameX509CredentialsChange,String,$$$GetMsg($$$X509CredentialsMsg,"Import"))
 }
 s sc=$$$OK
Exit
 q sc
Rollback
 i $d(TSTART) {
	TROLLBACK 1
	k TSTART
 }
 s NumImported=0
 g Exit
Error s $zt=""
 s sc=$$$ERROR($$$ObjectScriptError,$ze)
 g Rollback
}

/// Modify a X509Credential.<br>
/// Modify an existing X509Credential's properties in the security database.<br>
/// Parameters:<br>
/// Name - Name of the X509Credential to modify<br>
/// Properties - Array of properties to modify.<br>
/// See the Get() method for a description of the Properties parameter.<br>
/// If a specific property is not passed in the properties array, 
/// the value is not modified.<br>
ClassMethod Modify(Name As %String, ByRef Properties As %String) As %Status
{
 s $zt="Error"
 i '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) q $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
 i '..Exists(Name,.X509Credential,.Status) q Status
 s Status=$$$OK
 i $d(Properties("OwnerList")),(Properties("OwnerList")'=X509Credential.OwnerList) s X509Credential.OwnerList=Properties("OwnerList")
 i $d(Properties("Certificate")),(Properties("Certificate")'=X509Credential.Certificate) s X509Credential.Certificate=Properties("Certificate")
 i $d(Properties("PrivateKeyType")),(Properties("PrivateKeyType")'=X509Credential.PrivateKeyType) s X509Credential.PrivateKeyType=Properties("PrivateKeyType")
 i $d(Properties("PrivateKey")),(Properties("PrivateKey")'=X509Credential.PrivateKey) s X509Credential.PrivateKey=Properties("PrivateKey")
 i $d(Properties("PrivateKeyPassword")),(Properties("PrivateKeyPassword")'=X509Credential.PrivateKeyPassword) s X509Credential.PrivateKeyPassword=Properties("PrivateKeyPassword")
 i $d(Properties("PeerNames")),(Properties("PeerNames")'=X509Credential.PeerNames) s X509Credential.PeerNames=Properties("PeerNames")
 i $d(Properties("SubjectKeyIdentifier")),(Properties("SubjectKeyIdentifier")'=X509Credential.SubjectKeyIdentifier) s X509Credential.SubjectKeyIdentifier=Properties("SubjectKeyIdentifier")
 i $d(Properties("Thumbprint")),(Properties("Thumbprint")'=X509Credential.Thumbprint) s X509Credential.Thumbprint=Properties("Thumbprint")
 i $d(Properties("SerialNumber")),(Properties("SerialNumber")'=X509Credential.SerialNumber) s X509Credential.SerialNumber=Properties("SerialNumber")
 i $d(Properties("IssuerDN")),(Properties("IssuerDN")'=X509Credential.IssuerDN) s X509Credential.IssuerDN=Properties("IssuerDN")
 i $d(Properties("SubjectDN")),(Properties("SubjectDN")'=X509Credential.SubjectDN) s X509Credential.SubjectDN=Properties("SubjectDN")
 i $d(Properties("CAFile")),(Properties("CAFile")'=X509Credential.CAFile) s X509Credential.CAFile=Properties("CAFile")
 s Status=X509Credential.%Save()
 q Status
Error s $zt=""
 Quit $$$ERROR($$$ObjectScriptError,$ze)
}

/// Decrypt using the private key and password for these credentials
Method RSADecrypt(ciphertext As %String, encoding As %Integer) As %String
{
	$$$AddAllRoleTemporary
	Quit $system.Encryption.RSADecrypt(ciphertext,..PrivateKey,..PrivateKeyPassword,encoding)
}

/// Find the size of the signature using the private key and password for these credentials
Method RSASize() As %Integer
{
	$$$AddAllRoleTemporary
	Quit $system.Encryption.RSASize(..PrivateKey,..PrivateKeyPassword)
}

/// Sign using the private key and password for these credentials
Method RSASHASign(bitlength As %Integer, data As %String) As %String
{
	$$$AddAllRoleTemporary
	Quit $system.Encryption.RSASHASign(bitlength,data,..PrivateKey,..PrivateKeyPassword)
}

ClassMethod SetHasPrivateKeyWhereUnset() As %Status [ Internal ]
{
	set $zt="SetHasPrivateKeyWhereUnsetError"

	If '$SYSTEM.Security.Check($$$AdminSecureResourceName,$$$PermUseName) {
		Quit $$$ERROR($$$OperationRequires,$$$AdminSecureResourceName_":"_$$$PermUseName)
	}

	set statement=##class(%SQL.Statement).%New()
	set sc=statement.%PrepareClassQuery("%SYS.X509Credentials", "ListAll")
	return:'$$$ISOK(sc) sc

	set resultset=statement.%Execute()
	if ('$isobject(resultset)) { set sc=%objlasterror return sc }

	set totalStatus=$$$OK
	while resultset.%Next() {
		set alias=resultset.%Get("Alias")
		set cred=##class(%SYS.X509Credentials).%OpenId(alias)
		if ('$isobject(cred)) {
			set totalStatus=$$$ADDSC(totalStatus,%objlasterror)
			continue
		}
		continue:cred.HasPrivateKey'="" // We're only trying to fix cases where the value is empty.
		set cred.HasPrivateKey=($l(cred.PrivateKeyGet())>0)
		set sc=cred.%Save()
		if ('$$$ISOK(sc)) { set totalStatus=$$$ADDSC(totalStatus,sc) }
	}
	return totalStatus

SetHasPrivateKeyWhereUnsetError set $zt=""
	return $$$ERROR($$$ObjectScriptError,$ze)
}

Storage Default
{
<Data name="X509CredentialsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OwnerList</Value>
</Value>
<Value name="3">
<Value>Certificate</Value>
</Value>
<Value name="4">
<Value>PrivateKeyType</Value>
</Value>
<Value name="5">
<Value>PrivateKey</Value>
</Value>
<Value name="6">
<Value>PrivateKeyPassword</Value>
</Value>
<Value name="7">
<Value>PeerNames</Value>
</Value>
<Value name="8">
<Value>SubjectKeyIdentifier</Value>
</Value>
<Value name="9">
<Value>Thumbprint</Value>
</Value>
<Value name="10">
<Value>SerialNumber</Value>
</Value>
<Value name="11">
<Value>IssuerDN</Value>
</Value>
<Value name="12">
<Value>SubjectDN</Value>
</Value>
<Value name="13">
<Value>CAFile</Value>
</Value>
<Value name="14">
<Value>HasPrivateKey</Value>
</Value>
<Value name="15">
<Value>Version</Value>
</Value>
</Data>
<DataLocation>^|"^^"_$zu(12)|SYS("Security","X509CredentialsD")</DataLocation>
<DefaultData>X509CredentialsDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"^^"_$zu(12)|SYS("Security","X509CredentialsD")</IdLocation>
<IndexLocation>^|"^^"_$zu(12)|SYS("Security","X509CredentialsI")</IndexLocation>
<StreamLocation>^|"^^"_$zu(12)|SYS("Security","X509CredentialsS")</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
