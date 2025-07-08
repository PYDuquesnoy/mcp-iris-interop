/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Security.EncryptedKey+xml">Encrypting XML Documents</a>.
/// and <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Security.EncryptedKey+soap">Encrypting SOAP Security Headers</a>.
/// </p>
/// XML Encryption element.
Class %XML.Security.EncryptedKey Extends (%XML.Security.KeyInfoClause, %XML.Security.EncryptedType) [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2001/04/xmlenc#";

Parameter ELEMENTQUALIFIED = 1;

Property CipherData As %XML.Security.CipherData(XMLREF = 1) [ Required ];

Property EncryptionProperties As %XML.Security.EncryptionProperties(XMLREF = 1);

Property ReferenceList As %XML.Security.ReferenceList(XMLREF = 1);

Property CarriedKeyName As %String(MAXLEN = "");

Property Recipient As %String(MAXLEN = "", XMLPROJECTION = "attribute");

/// UsedAsSigningKey is true if this EncryptedKey element was used for signing
Property UsedAsSigningKey As %Boolean(XMLPROJECTION = "none");

/// UsedAsEncryptionKey is true if this EncryptedKey element was used for encryption
Property UsedAsEncryptionKey As %Boolean(XMLPROJECTION = "none");

/// EncryptionOptions specifies which parts of the message are to be signed.
/// See %soap.inc definitions of $$$SOAPWSEncrypt.... for possibilities.
Property EncryptionOptions As %Integer(XMLPROJECTION = "none");

/// The algorithm used for encryption
Property EncryptionAlgorithm As %String(XMLPROJECTION = "none") [ Calculated, Internal ];

Method EncryptionAlgorithmGet() As %String [ CodeMode = expression, Internal ]
{
$select($isobject(..ReferenceList):..ReferenceList.EncryptionAlgorithm,1:"")
}

/// Create an EncryptedKey element that is to carry a symmetric key which is encrypted using 
/// an X.509 certificate's public key.
/// <ul>
/// <li>The certificate is specified in the token argument by 
/// a %SYS.X509Credentials instance containing the certificate or
/// a BinarySecurityToken containing the X509 certificate.</li>
/// <li>The encryptionOptions argument specifies the parts of the SOAP message to be encrypted.
/// The default is to encrypt the body - $$$SOAPWSEncryptSoapBody. 
/// $$$SOAPWSEncryptNoBody means body will not be encrypted, but other parts added using AddReference method.
/// $$$SOAPWSEncryptNone means there will be no ReferenceList in the EncryptedKey element.
/// See %soap.inc definitions of $$$SOAPWSEncrypt.... for possibilities.</li>
/// <li>The referenceOption argument specifies the type of reference to create.
/// See %soap.inc definitions of $$$SOAPWSReference....  The default is to use
/// the Thumbprint if the first argument is a %SYS.X509Credentials instance.</li>
/// </ul>
ClassMethod CreateX509(credentials As %SYS.X509Credentials = "", encryptionOptions As %Integer, referenceOption As %Integer, Output status As %Status) As %XML.Security.EncryptedKey
{
	Set status=$$$OK
	#dim element As %XML.Security.EncryptedKey = ..%New()
	If $get(referenceOption)'=$$$SOAPWSSAML {
		#dim keyInfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).CreateX509(.credentials,.referenceOption,.status)
		If $$$ISERR(status) Quit ""
		Set element.KeyInfo=keyInfo
	}

	Set element.EncryptionOptions=$select($get(encryptionOptions)'="":encryptionOptions,1:$$$SOAPWSEncryptDefault)
	If element.EncryptionOptions'=$$$SOAPWSEncryptNone {
		Set element.ReferenceList=##class(%XML.Security.ReferenceList).%New()
	}
	Set element.X509Credentials=credentials
	
	// RSA-OAEP is the default key transport algorithm
	Do element.SetEncryptionMethod($$$SOAPWSrsaoaep)
	
	Set element.CipherData=##class(%XML.Security.CipherData).%New()

	Quit element
}

/// Get EncryptedKeySHA1 format of this EncryptedKey element.
/// Get EncryptedKeySHA1 format of this EncryptedKey element.
Method GetEncryptedKeySHA1() As %Binary
{
	If ..CipherData="" Quit ""
	
	Quit $system.Encryption.SHA1Hash(..CipherData.CipherValue)
}

/// Initialize an EncryptedKey element that is intended for creating EncryptedKey
/// elements which will not be in the Security header.
/// EncryptionMethod, and Algorithm or KeySize are expected to be set or defaulted.
Method Initialize() As %Status
{
	Quit ..InitializeForService("","")
}

/// Initialize
Method InitializeForService(service As %SOAP.WebBase, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	// Check algorithm and compute key
	Set sc=..InitializeKey(service)
	If $$$ISERR(sc) Quit sc	
	
	Set sc=..EncryptKey()
	If $$$ISERR(sc) Quit sc	

	// Add reference for elements to encrypt.
	If $zboolean(..EncryptionOptions,$$$SOAPWSEncryptSoapBody,1) {
		Set data=##class(%XML.Security.EncryptedData).CreateFromEncryptedKey($this)
		Do ..AddReference(##class(%XML.Security.DataReference).Create(data),1)
	}
	
	If ..ReferenceList'="" {
		Set sc=..ReferenceList.InitializeForService(service,header,..Key)
	}

	Quit sc
}

/// Encrypt the symmetric key
Method EncryptKey() As %Status [ Internal ]
{
	// Get CA Certificate file
	If $isobject(..X509Credentials),$classname(..X509Credentials)="%SYS.X509Credentials",..X509Credentials.CAFile'="" {
		Set cafile=##class(%File).NormalizeFilename(..X509Credentials.CAFile,##class(%File).ManagerDirectory())
		If $$$CheckSOAPLogSecurity {
			Set file=cafile
			If $$$CheckSOAPTestMode {
				Set file=$tr(file,"\","/")
				If file["/internal/" {
					Set file="internal/"_$piece(file,"/internal/",2)
				}
			}
		}
		$$$SOAPLogSecurity("Encrypt Key: non-default CAFile="_file)
	} Else {
		Set cafile=$zu(12)_"iris.cer"
	}
	Set crlfile=$zu(12)_"iris.crl"
	If $zu(140,4,crlfile)'=0 Set crlfile=""
		
	// Encrypt the key.
	Set sc=$$$OK
	Try {
		If ..EncryptionMethod.Algorithm=$$$SOAPWSrsa15 {
			Set RSAEncoding=2
			$$$SOAPLogSecurity("Encrypt Key using "_..Algorithm_" with Key Transport of RSA-1.5")
		} Else {
			Set RSAEncoding=1
			$$$SOAPLogSecurity("Encrypt Key using "_..Algorithm)
		}
		Set ..CipherData.CipherValue=
		  $System.Encryption.RSAEncrypt(..Key,..X509Credentials.Certificate,cafile,crlfile,RSAEncoding)
		If ..CipherData.CipherValue="" {
			Set error=$System.Encryption.RSAGetLastError()
			Set sc=$$$ERROR($$$WSSECURITYKeyEncFailed,error)
			$$$SOAPLogSecurity("Key encryption failed: "_error)
		}
	} Catch {
		Set error=$System.Encryption.RSAGetLastError()
		Set sc=$$$ERROR($$$WSSECURITYKeyEncFailed,"Internal Error "_error)
		$$$SOAPLogSecurity("Key encryption failed: Internal Error "_error)
	}
	If $$$ISERR(sc) {
		If '##class(%File).Exists(cafile) {
			$$$SOAPLogSecurity("    "_cafile_" not found")
		}
		Quit sc
	}

	Quit $$$OK
}

/// Add a reference to XML element using a %XML.Security.DataReference.
/// The reference may be created by using the ##class(%XML.Security.Reference).Create method.
/// If doNotReuse is true, then this reference will be removed during Reset
Method AddReference(reference As %XML.Security.DataReference, doNotReuse As %Boolean = 0)
{
	If ..ReferenceList="" Set ..ReferenceList=##class(%XML.Security.ReferenceList).%New()
	Set reference.DoNotReuse=doNotReuse
	Do ..ReferenceList.AddReference(reference)
}

/// Perform encryption
Method Perform(messageStream As %BinaryStream, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	If $isobject(..ReferenceList) {
		Quit ..ReferenceList.Perform(messageStream, header)
	}
	
	Quit $$$OK
}

/// Reset the element.
Method Reset()
{
	Do ##super()
	
	If $isobject(..ReferenceList) {
		Do ..ReferenceList.Reset()
	}
}

/// Validate the key decryption.
/// If invalid return an error code.
Method ValidateKey(service As %SOAP.WebBase) As %String [ Internal ]
{
	// Already validated if Key property set
	If ..Key'="" Quit ""
	
	$$$SOAPLogSecurity("Validate EncryptedKey:")
	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"
	Set error=""

	// Validate EncryptedKey properties
	// Only RSA-OAEP key encryption supported.	
	#dim method As %XML.Security.EncryptionMethod =..EncryptionMethod
	If method="" {
		$$$SOAPLogSecurity("    no EncryptionMethod")
		Quit invalid
	}
	
	If (method.OAEPparams'="") {
		Set error=unsupported
	} ElseIf method.Algorithm=$$$SOAPWSrsaoaep {
		If $case(method.DigestMethod.Algorithm,"":1,$$$SOAPWSsha1:1,:0) {
			Set RSAEncoding=1
		} Else {
			Set error=unsupported
		}
	} ElseIf method.Algorithm=$$$SOAPWSrsa15 {
		If method.DigestMethod.Algorithm="" {
			Set RSAEncoding=2
		} Else {
			Set error=unsupported
		}
	} Else {
		Set error=unsupported
	}
	If error'="" {
		$$$SOAPLogSecurity("    Unsupported EncryptionMethod properties")
		Quit error
	}

	// Make sure encrypted key is present	
	If (..CipherData="") || (..CipherData.CipherValue="") {
		$$$SOAPLogSecurity("    no encrypted data for key")
		Quit unsupported
	}
	
	If ..CipherData.CipherReference'="" {
		$$$SOAPLogSecurity("    CipherReference is not supported")
		Quit unsupported
	}
	
	// KeyInfo must be specified to decrypt key
	Set keyInfo=..KeyInfo
	If keyInfo="" {
		$$$SOAPLogSecurity("    no KeyInfo")
		Quit unsupported
	}
	Set error=keyInfo.ValidateTokenRef(service)
	If error'="" Quit error

	// Only X.509 certificates supported	
	If keyInfo.KeyType=$$$SOAPWSX509v3 {
		// Get certificate
		Set credentials=keyInfo.X509Credentials
		// Get the credentials instance from the database, so private key is included
		If $isobject(credentials) {
			If $zobjclass(credentials)="%XML.Security.RSAKeyValue" {
				$$$SOAPLogSecurity("    RSAKeyValue used for decryption")
				Set credentials=##class(%SYS.X509Credentials).GetByRSAKeyValue(credentials)
				If credentials="" {
					$$$SOAPLogSecurity("    No credentials found for RSAKeyValue used for decryption")
				}
			} ElseIf $zobjclass(credentials)="%SYS.X509Credentials" {
				If (credentials.Alias="") || 'credentials.HasPrivateKey {
					Set credentials=##class(%SYS.X509Credentials).GetByCertificateWithPrivateKey(credentials.Certificate)
				}
			} Else {
				Set credentials=""
				$$$SOAPLogSecurity("    Unexpected credentials type for decryption: "_$zobjclass(credentials))
			}
		} Else {
			Set credentials=""
			$$$SOAPLogSecurity("    Unexpected credentials type for decryption: "_credentials)
		}
		If credentials="" {
			$$$SOAPLogSecurity("    X.509 certificate not found")
			Quit "FailedCheck"
		}
		Set ..X509Credentials=credentials
		If 'credentials.HasPrivateKey {
			$$$SOAPLogSecurity("    Private Key for decryption must be associated with certificate "_credentials.Alias)
			Quit "FailedCheck"
		}

		// Decrypt the symmetric key.
		$$$SOAPLogSecurity("    Decrypt symmetric key using "_credentials.Alias)
		Set sc=$$$OK
		Try {
			Set ..Key=credentials.RSADecrypt(..CipherData.CipherValue,RSAEncoding)
			If ..Key="" {
				Set err=$System.Encryption.RSAGetLastError()
				$$$SOAPLogSecurity("    Key decryption failed: "_err)
				$$$SOAPLogSecurity("    alias: "_credentials.Alias)
				Set error="FailedCheck"
			}
		} Catch {
			$$$SOAPLogSecurity("    Key decryption failed due to internal failure")
			Set error="invalid"
		}
	} ElseIf keyInfo.KeyType=$$$SOAPWSDerivedKey {
		Set derivedKey=keyInfo.X509Credentials
		Set error=derivedKey.ValidateKey(service)
		If error="" Set ..Key=derivedKey.Key
	} ElseIf keyInfo.KeyType=$$$SOAPWSSCToken {
		Set sct=keyInfo.X509Credentials
		Set error=sct.ValidateKey(service)
		If error="" Set ..Key=sct.Key
	} Else {
		$$$SOAPLogSecurity("    unexpected TokenType="_keyInfo.KeyType)
		Set error=unsupported
	}
	Quit error
}

/// Validate this input EncryptedKey used as a KeyInfo clause.
/// If valid, set credentials and tokenType and return "".  credentials is this EncryptedKey element
Method ValidateTokenRef(service As %SOAP.WebBase, ByRef tokenType As %String, Output credentials As %RawString) As %String [ Internal ]
{
	Set tokenType=$$$SOAPWSEncryptedKey
	Set credentials=$this
	Quit ""
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(ByRef document As %XML.Document, service As %SOAP.WebBase, mimeAttachments As %Net.MIMEPart = "") As %String [ Internal ]
{
	$$$SOAPLogSecurity("Security Decrypt:")
	Set error=..ValidateKey(service)
	If error'="" Quit error
	
	If error="",..ReferenceList'="" {
		Set ..UsedAsEncryptionKey=1
		Set error=..ReferenceList.ValidateElement(.document,service,mimeAttachments,..Key)
	}
	
	Quit error
}

/// Return true if the same Key.
Method Equals(credentials As %XML.Security.EncryptedKey) As %Boolean
{
	Quit ($isobject(credentials) && (credentials.Key=..Key))
}

}
