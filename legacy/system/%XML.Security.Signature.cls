/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Security.Signature+xml">Signing XML Documents</a>.
/// and <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Security.Signature+soap">Adding Digital Signatures</a>.</p>
/// XML Signature element.
Class %XML.Security.Signature Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2000/09/xmldsig#";

Parameter ELEMENTQUALIFIED = 1;

/// The PreProcessed flag indicates whether the signature data in this signature 
/// is already valid and should not be recalculated when preparing a SOAP request for
/// retransmission. In general this would only be useful when attempting to forward 
/// a specific signed entity such as a SAML assertion which contains a Signature element.
Property PreProcessed As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0, Internal ];

/// Local Id attribute defined for XML Signature
Property Id As %String(MAXLEN = "", XMLPROJECTION = "attribute") [ Internal ];

Property SignedInfo As %XML.Security.SignedInfo [ Internal ];

Property SignatureValue As %xsd.base64Binary(CANONICALXML = 1) [ Internal ];

Property KeyInfo As %XML.Security.KeyInfo [ Internal ];

Property Object As %XML.Security.Object [ Internal ];

/// SignatureOptions specifies which parts of the message are to be signed.
/// See %soap.inc definitions of $$$SOAPWSInclude.... for possibilities.
Property SignatureOptions As %Integer(XMLPROJECTION = "none") [ Internal ];

/// If signing is based on X509 certificate, this is the X509 certificate class.
/// If signing is based on EncryptedKey, BinarySecret, DerivedKeyToken or SecurityContextToken element,
/// then this element and Key property is defined.
Property X509Credentials As %RawString(XMLPROJECTION = "none") [ Internal ];

/// The symmetric key for hmac-sha1 signing.
Property Key As %Binary(XMLPROJECTION = "none") [ Internal ];

/// ReferenceOption argument from the Create call.
Property ReferenceOption As %String(XMLPROJECTION = "none") [ Internal ];

/// The default DigestMethod Algorithm for any references added to this Signature.
Property DigestMethodAlgorithm As %String(XMLPROJECTION = "none") [ Internal ];

/// Save the node id of this element in the tree during import for canonicalizing
/// later during signature verification.
Property NodeId As %String(XMLPROJECTION = "none") [ Internal ];

/// If true, then the SOAP Body is signed
Property IsBodySigned As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// If true, this signature has been confirmed by a WS-Security 1.1 SubjectConfirmation element.
Property Confirmed As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// Save the node if when getting a new class instance.
ClassMethod XMLNew(document As %XML.Document, nodeId As %Integer, containerOref As %RegisteredObject = "") As %RegisteredObject
{
	Set oref=..%New()
	Set oref.NodeId=nodeId
	Quit oref
}

/// Create a Signature element that is to be signed using the RSA private key that 
/// is associated with the specified X509 certificate.
/// <ul>
/// <li>The first argument can be a %SYS.X509Credentials instance, a %SAML.Assertion instance, or a %SOAP.Security.BinarySecurityToken instance. This argument indicates the X509 certificate to use. 
///    <ul>
///    <li>If this argument is a %SYS.X509Credentials instance, the instance should refer to the X509 certificate to use.</li>
///    <li>If this argument is a %SAML.Assertion instance, its SubjectConfirmation should be based on the X.509 credentials to use.</li>
///    <li>If this argument is a %SOAP.Security.BinarySecurityToken instance, it should contain the X.509 certificate to use; this is the technique for a direct reference.</li>
///    </ul></li>
/// <li>The signatureOptions argument specifies the parts of the SOAP message to be signed.
/// The default is to sign all addressing header, body and timestamp.
/// See %soap.inc definitions of $$$SOAPWSInlcude.... for possibilities.</li>
/// <li>The referenceOption argument specifies the type of reference to create.
/// See %soap.inc definitions of $$$SOAPWSReference.... and $$$KeyInfoX509....
/// The default is to use a direct reference if the first argument is a binary security token or to
/// use the Thumbprint if the first argument is a %SYS.X509Credentials instance.</li>
/// <li>If no signature is returned the status argument is set to the error %Status.</li>
/// </ul>
ClassMethod CreateX509(credentials As %SYS.X509Credentials = "", signatureOptions As %Integer, referenceOption As %Integer, Output status As %Status) As %XML.Security.Signature
{
	#dim keyInfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).CreateX509(.credentials,.referenceOption,.status)
	If keyInfo="" Quit ""

	#dim element As %XML.Security.Signature = ..%New()
	Set element.ReferenceOption=referenceOption
	Set element.KeyInfo=keyInfo

	Set element.SignatureOptions=$select($get(signatureOptions)'="":signatureOptions,1:$$$SOAPWSIncludeDefault)
	Set element.X509Credentials=credentials
	If (credentials="") || ($zobjclass(credentials)'="%SYS.X509Credentials") {
		Set status=$$$ERROR($$$SOAPBadSecurityElement,"No credentials specified for reference option "_referenceOption_"."_credentials)
		$$$SOAPLogSecurity("    No credentials specified for reference option "_referenceOption_"."_credentials)
		Quit ""
	}
	If 'credentials.HasPrivateKey {
		Set status=$$$ERROR($$$SOAPBadSecurityElement,"No private key for credentials specified for signature: "_credentials.Alias)
		$$$SOAPLogSecurity("    No private key for credentials specified for signature: "_credentials.Alias)
		Quit ""
	}
	
	Do ..GetDefaultMethods(.digestMethod,.signatureMethod,.hmacMethod)
	If digestMethod="" Quit ""

	#dim signedInfo As %XML.Security.SignedInfo = ##class(%XML.Security.SignedInfo).%New()
	Set signedInfo.CanonicalizationMethod=##class(%XML.Security.Transform).%New()
	Set signedInfo.CanonicalizationMethod.Algorithm=$$$SOAPWSexcc14n
	Set signedInfo.SignatureMethod.Algorithm=signatureMethod
	// References will be filled in later based on the SignatureOptions property.
	Set element.SignedInfo=signedInfo 
	
	// Default digest method for any references.
	Set element.DigestMethodAlgorithm=digestMethod
	
	Quit element
}

/// Create a Signature element that is to be signed using the hmac-sha1 algorithm
/// with a symmetric key specified by its KeyInfo element.
/// <ul>
/// <li>keyElement is the Security element which will supply the symmetric key.  
/// keyElement is meaningful only when referenceOption specified.  See referenceOption for details.</li>
/// <li>The signatureOptions argument specifies the parts of the SOAP message to be signed.
/// The default is to sign all addressing header, body and timestamp.
/// See %soap.inc definitions of $$$SOAPWSInlcude.... for possibilities.</li>
/// <li>The referenceOption argument specifies the type of reference which will be in the KeyInfo.
/// If referenceOption is "" or not specified, no KeyInfo is created.  This is the default.
/// <ul>
/// <li>$$$SOAPWSReferenceEncryptedKey is reference to an EncryptedKey element in this message.
/// The keyElement argument must be specified and is the EncryptedKey element.</li>
/// <li>$$$SOAPWSReferenceEncryptedKeySHA1 is reference by the SHA1 hash of the key contained
/// in the EncryptedKey element specified as the first argument.
/// If the keyElement is not specified, the key from the first EncryptedKey element in the received message
/// is used.</li>
/// <li>$$$SOAPWSReferenceDerivedKey is reference to a DerivedKeyToken element in this message.
/// The keyElement argument must be specified and is the DerivedKeyToken element.</li>
/// <li>$$$SOAPWSReferenceSCT is reference by wsu:Id to a SecurityContextToken element in this message.
/// The keyElement argument must be specified and is the SecurityContextToken element.</li>
/// <li>$$$SOAPWSReferenceSCTIdentifier is reference by Identifier and Instance to a SecurityContextToken
/// element not necessarily in this message.
/// The keyElement argument must be specified and is the SecurityContextToken element.</li>
/// <li>$$$SOAPWSSAML is reference to SAML Assertion which contains an EncryptedKey or BinarySecret element
/// in the KeyInfo that is in the SubjectConfirmationData.
/// The keyElement argument must be specified and is the SAML Assertion element.</li>
/// </ul>
/// </ul>
ClassMethod Create(keyElement As %RegisteredObject = "", signatureOptions As %Integer, referenceOption As %Integer = "") As %XML.Security.Signature
{
	#dim element As %XML.Security.Signature = ..%New()

	If $get(referenceOption)="" {
		Set secref=""
	} ElseIf referenceOption=$$$SOAPWSReferenceEncryptedKeySHA1 {
		If keyElement'="",'$isobject(keyElement) Quit ""
		Set element.Key=$select(keyElement="":"",1:keyElement.Key)
		Set cipher=$select(keyElement="":"",1:keyElement.CipherData.CipherValue)
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetKeyIdentifier($$$SOAPWSEncryptedKeySHA1,cipher)
	} ElseIf referenceOption=$$$SOAPWSReferenceEncryptedKey {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="EncryptedKey")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId(),$$$SOAPWSEncryptedKey)
	} ElseIf referenceOption=$$$SOAPWSReferenceDerivedKey {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="DerivedKeyToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId())
	} ElseIf referenceOption=$$$SOAPWSReferenceSCT {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="SecurityContextToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId(),$$$SOAPWSSCToken)
	} ElseIf referenceOption=$$$SOAPWSReferenceSCTIdentifier {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="SecurityContextToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetSCTReference(keyElement)
	} ElseIf referenceOption=$$$SOAPWSSAML {
		If ('$isobject(keyElement) || ($classname(keyElement)'="%SAML.Assertion")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetSAMLKeyIdentifier(keyElement)
	} Else {
		// Unknown reference option
		Quit ""
	}
	Set element.ReferenceOption=referenceOption

	Set element.SignatureOptions=$select($get(signatureOptions)'="":signatureOptions,1:$$$SOAPWSIncludeDefault)
	
	Do ..GetDefaultMethods(.digestMethod,.signatureMethod,.hmacMethod)
	If digestMethod="" Quit ""

	#dim signedInfo As %XML.Security.SignedInfo = ##class(%XML.Security.SignedInfo).%New()
	Set signedInfo.CanonicalizationMethod=##class(%XML.Security.Transform).%New()
	Set signedInfo.CanonicalizationMethod.Algorithm=$$$SOAPWSexcc14n
	Set signedInfo.SignatureMethod.Algorithm=hmacMethod
	// References will be filled in later based on the SignatureOptions property.
	Set element.SignedInfo=signedInfo 
	
	// Default digest method for any references.
	Set element.DigestMethodAlgorithm=digestMethod
	
	If secref'="" {
		#dim keyInfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).%New()
		Do keyInfo.KeyInfoClauseList.Insert(secref)
		Set element.KeyInfo=keyInfo
		If referenceOption=$$$SOAPWSSAML {
			Set element.X509Credentials=keyElement.X509Credentials
		} Else {
			Set element.X509Credentials=keyElement
		}
	}
	
	Quit element
}

/// Get default digest, signature and hmac methods
ClassMethod GetDefaultMethods(Output digest As %String, Output signature As %String, Output hmac As %String) [ Internal ]
{
	Set (digest,signature,hmac)=""
	Set sc=##class(%SYS.System).GetDefaultSignatureHash(.sha)
	If $$$ISOK(sc) {
		If sha="SHA256" {
			Set digest=$$$SOAPWSsha256
			Set signature=$$$SOAPWSrsasha256
			Set hmac=$$$SOAPWShmacsha256
		} ElseIf sha="SHA1" {
			Set digest=$$$SOAPWSsha1
			Set signature=$$$SOAPWSrsasha1
			Set hmac=$$$SOAPWShmacsha1
		} ElseIf sha="SHA384" {
			Set digest=$$$SOAPWSsha384
			Set signature=$$$SOAPWSrsasha384
			Set hmac=$$$SOAPWShmacsha384
		} ElseIf sha="SHA512" {
			Set digest=$$$SOAPWSsha512
			Set signature=$$$SOAPWSrsasha512
			Set hmac=$$$SOAPWShmacsha512
		} ElseIf sha="" {
			Set digest=$$$SOAPWSsha256
			Set signature=$$$SOAPWSrsasha256
			Set hmac=$$$SOAPWShmacsha256
		}
	}
}

/// Set the digest method algorithm to be used for signing.
/// The algorithm is reflected in the Algorithm attribute of the DigestMethod element 
/// of each Reference element of the SignedInfo element of the Signature element.
/// Possible values for algortihm are $$$SOAPWSsha1, $$$SOAPWSsha256, $$$SOAPWSsha384 and $$$SOAPWSsha512.
Method SetDigestMethod(algorithm As %String)
{
	Set ..DigestMethodAlgorithm=algorithm
}

/// Set the signature method algorithm to be used for signing.
/// The algorithm is reflected in the Algorithm attribute of the SignatureMethod element 
/// the SignedInfo element of the Signature element.
/// Possible values for algortihm are $$$SOAPWSrsasha1, $$$SOAPWSrsasha256, $$$SOAPWSrsasha384 and $$$SOAPWSrsasha512.
Method SetSignatureMethod(algorithm As %String)
{
	Set ..SignedInfo.SignatureMethod.Algorithm=algorithm
}

/// SignStream completes the Signature element by adding the SignedInfo based on X509Credentials and 
/// computes the signature value for the XML stream to be signed.
/// <var>messageStream</var> is a stream containing the XML to be signed.<br><br>
/// 
/// If the document is an MTOM document, then the optional <var>mimeAttachments</var> argument
/// contains a single MIME part which has each MIME section as one of its child <var>Parts</var>.<br><br>
/// 
/// The following example creates a stream which contains an XML document whose
/// root object is is given by the oref obj.  This oref is assumed to be an 
/// instance of an XML-enabled class that has the following properties:
/// <ul>
/// <li>A property that is projected to XML as the Id attribute. In this 
/// example, this is the Signed.Id property.</li>
/// <li>property that is intended to contain the signature itself and that is 
/// projected to XML as the <Signature> element. In this example, this is the 
/// Signature property.</li>
/// </ul>
/// 
/// <example>
/// set writer=##class(%XML.Writer).%New()
/// set stream=##class(%FileBinaryStream).%New()
/// set status=writer.OutputToStream(stream)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=writer.RootObject(obj)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// 	
/// set x509 = ##class(%SYS.X509Credentials).GetByAlias("MyCredentials")
/// set signature=##class(%XML.Security.Signature).CreateX509(
///                 x509,$$$SOAPWSIncludeNone,$$$KeyInfoX509Certificate)
/// // Signature based on id of contained Signed element
/// // Note that the name Signed is arbitrary.
/// do signature.AddReference(
///   ##class(%XML.Security.Reference).Create(obj.Signed.id))
/// set status=signature.SignStream(stream)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// // Signature element is property of any name
/// // Signature is an arbitrary property name
/// set obj.Signature=signature
/// 
/// // Output the signed stream now that the signature is computed.
/// set stream=##class(%FileBinaryStream).%New()
/// set status=writer.OutputToStream(stream)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=writer.RootObject(obj)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// </example>
Method SignStream(messageStream As %BinaryStream, mimeAttachments As %Net.MIMEPart = "") As %Status
{
	// Parse the message stream so that pieces may be Canonicalized
	Set sc=##class(%XML.Document).GetDocumentFromStream(messageStream,.document)
	If $$$ISERR(sc) Quit sc

	// Do the actual signing.
	Quit ..Sign(document,,mimeAttachments)
}

/// SignDocument completes the Signature element by adding the SignedInfo based on X509Credentials and 
/// computes the signature value for the parsed XML document to be signed.
/// <var>document</var> is an %XML.Document obtained by parsing the stream ot be signed.<br><br>
/// 
/// If the document is an MTOM document, then the optional <var>mimeAttachments</var> argument
/// contains a single MIME part which has each MIME section as one of its child <var>Parts</var>.<br><br>
/// 
/// The following example creates a stream which contains an XML document whose
/// root object is is given by the oref obj.  This oref is assumed to be an 
/// instance of an XML-enabled class that has the following properties:
/// <ul>
/// <li>A property that is projected to XML as the Id attribute. In this 
/// example, this is the Signed.Id property.</li>
/// <li>property that is intended to contain the signature itself and that is 
/// projected to XML as the <Signature> element. In this example, this is the 
/// Signature property.</li>
/// </ul>
/// 
/// <example>
/// set writer=##class(%XML.Writer).%New()
/// set stream=##class(%FileBinaryStream).%New()
/// set status=writer.OutputToStream(stream)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=writer.RootObject(obj)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// 	
/// set x509=##class(%SYS.X509Credentials).GetByAlias("MyCredentials")
/// set signature=##class(%XML.Security.Signature).CreateX509(
///                 x509,$$$SOAPWSIncludeNone,$$$KeyInfoX509Certificate)
/// // Signature based on id of contained Signed element 
/// // Note that name Signed is arbitrary.
/// do signature.AddReference(
///   ##class(%XML.Security.Reference).Create(obj.Signed.id))
/// // We parse the stream to create a document which we will sign.
/// set status=
///   ##class(%XML.Document).GetDocumentFromStream(stream,.document)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=signature.SignDocument(document)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// // Signature element is property of any name
/// // Signature is arbitrary property name
/// set obj.Signature=signature
/// 
/// // Output the signed stream now that the signature is computed.
/// set stream=##class(%FileBinaryStream).%New()
/// set status=writer.OutputToStream(stream)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// set status=writer.RootObject(obj)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// </example>
Method SignDocument(document As %XML.Document, mimeAttachments As %Net.MIMEPart = "") As %Status
{
	Quit ..Sign(document,,mimeAttachments)
}

/// Validate a %XML.Document containing a parsed XML document which contains a signature.
/// The %XML.Signature element must be obtained from the same instance of 
/// %XML.Document that you are validating.
/// If invalid return an error %Status.<br><br>
/// 
/// If the document is an MTOM document, then the optional <var>mimeAttachments</var> argument
/// contains a single MIME part which has each MIME section as one of its child <var>Parts</var>.<br><br>
/// 
/// The CAFile argument is the full path of file which contains the certificate authority 
/// certificates which are to be used to validate the signing certificate.<br><br>
/// 
/// The following example assumes a single argument web service method with the argument named <var>arg</var>.
/// This will usually be the case with an entire message being the argument since
/// Parameter ARGUMENTSTYLE = "message".  The document to validate is the SOAP message whose
/// %XML.Document is contained in the ImportHandler property of the service.
/// Also exclusive canonicalization must be used because the entire SOAP envelope is represented in ..Importhandler.
/// If inclusive canonicalization needs to be used, then the ProcessBody or ProcessBodyNode methods
/// must be used which allows access to just the Body contents as a document.
/// 
/// <example>
/// // Signature element is property of any name.
/// // Signature is arbitrary property name
/// set signature=arg.Signature
/// set status=signature.ValidateDocument(..ImportHandler)
/// if $$$ISERR(status) do $system.OBJ.DisplayError(status) quit
/// </example>
Method ValidateDocument(document As %XML.Document, mimeAttachments As %Net.MIMEPart = "", CAFile As %String = "") As %Status
{
	Set sc=$$$OK
	Set error=..ValidateElement(document,,mimeAttachments,CAFile)
	If error'="" Set sc=$$$ERROR($$$SOAPBadSignature,error)
	Quit sc
}

/// Initialize the signature based on the SignatureOptions of a web client or service.
/// %XML.Security.Signature may be initialized directly by using calls to AddReference.
Method InitializeForService(service As %SOAP.WebBase, header As %SOAP.Security.Header = "") As %Status [ Internal ]
{
	If $isobject(header) Set header.IsSigned=1
	If ..PreProcessed {
		$$$SOAPLogSecurity("    Skipping initialization of Signature with signature value '"_$system.Encryption.Base64Encode(..SignatureValue,1)_"' as it is marked as Preprocessed.")
		Quit $$$OK
	}

	Set rmSigned=0
	If $isobject(service.AddressingOut) {
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeAddressing,1) {
			Do service.AddressingOut.GetIds(.addressingIds)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeAction,1) &&
		   ($get(addressingIds("Action"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("Action")),1)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeFaultTo,1) &&
		   ($get(addressingIds("FaultTo"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("FaultTo")),1)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeFrom,1) &&
		   ($get(addressingIds("From"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("From")),1)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeMessageId,1) &&
		   ($get(addressingIds("MessageID"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("MessageID")),1)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeRelatesTo,1) &&
		   ($get(addressingIds("RelatesTo"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("RelatesTo")),1)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeReplyTo,1) &&
		   ($get(addressingIds("ReplyTo"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("ReplyTo")),1)
		}
		If $zboolean(..SignatureOptions,$$$SOAPWSIncludeTo,1) &&
		   ($get(addressingIds("To"))'="") {
			   Do ..AddReference(##class(%XML.Security.Reference).Create(addressingIds("To")),1)
		}
	}
	If $isobject(header),$zboolean(..SignatureOptions,$$$SOAPWSIncludeTimestamp,1) {
		Set timestamp=header.SecurityElement.GetAt(1)
		If $zobjclass(timestamp)["Timestamp" {
			Do ..AddReference(##class(%XML.Security.Reference).Create(timestamp.GetId()),1)
		}
	}
	If $zboolean(..SignatureOptions,$$$SOAPWSIncludeRMHeaders,1) {
		Do ..AddRM(service)
		Set rmSigned=1
	}
	If $zboolean(..SignatureOptions,$$$SOAPWSIncludeSoapBody,1) {
		If 'rmSigned,$isobject(service.RMSession),$isobject(..X509Credentials) {
			Set class=$classname(..X509Credentials)
			Set sctid=""
			If class="%SOAP.WSSC.SecurityContextToken" {
				Set sctid=..X509Credentials.Identifier
			} ElseIf class="%SOAP.WSSC.DerivedKeyToken",$classname(..X509Credentials.KeyElement)="%SOAP.WSSC.SecurityContextToken" {
				Set sctid=..X509Credentials.KeyElement.Identifier
			}
			If sctid'="",sctid=service.RMSession.SCTIdentifier {
				Do ..AddRM(service)
			}
		}
		Do ..AddReference(##class(%XML.Security.Reference).Create(service.GetBodyId()),1)
	}
	
	Quit ..InitializeValue(service)
}

/// Add reference to WS-ReliableMessaging headers
Method AddRM(service As %SOAP.WebBase) [ Internal ]
{
	Set sequence=service.HeadersOut.GetAt("Sequence")
	If $isobject(sequence),$classname(sequence)="%SOAP.RM.Sequence" {
		Do ..AddReference(##class(%XML.Security.Reference).Create(sequence.GetId()),1)
	}
	Set ack=service.HeadersOut.GetAt("SequenceAcknowledgement")
	If $isobject(ack),$classname(ack)="%SOAP.RM.SequenceAcknowledgement" {
		Do ..AddReference(##class(%XML.Security.Reference).Create(ack.GetId()),1)
	}
}

/// Validate correct size to the Signature element
Method InitializeValue(service As %SOAP.WebBase) As %Status [ Internal, Private ]
{
	Set sc=$$$OK	

	Set algorithm=..SignedInfo.SignatureMethod.Algorithm
	Set bitlength=$case(algorithm,$$$SOAPWShmacsha1:160,$$$SOAPWShmacsha256:256,$$$SOAPWShmacsha384:384,$$$SOAPWShmacsha512:512,:0)
	If bitlength>0 {  // HMAC algorithm
		Set size=..SignedInfo.SignatureMethod.HMACOutputLength
		If (size'="") && ((size<=0) || (size>bitlength) || (size#8'=0)) {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Unexpected HMACOutputLength "_..SignedInfo.SignatureMethod.HMACOutputLength)
			$$$SOAPLogSecurity("    Unexpected HMACOutputLength "_..SignedInfo.SignatureMethod.HMACOutputLength)
			Quit sc
		}
		
		// Initialize from EncryptedKey, BinarySecret, DerivedKeyToken or SecurityContextToken element
		If ..Key="" {
			If ..ReferenceOption=$$$SOAPWSReferenceDerivedKey {
				If $isobject(..X509Credentials) {
					If ..X509Credentials.Key="" {
						Set sc=..X509Credentials.InitializeKey(service,algorithm)
						If $$$ISERR(sc) Quit sc
					}
					If ..X509Credentials.Implied {
						Do ..KeyInfo.KeyInfoClauseList.Clear()
						Do ..KeyInfo.KeyInfoClauseList.Insert(..X509Credentials.SecurityTokenReference)
						Set ..X509Credentials.SecurityTokenReference.Nonce=..X509Credentials.Nonce
						Set ..X509Credentials.SecurityTokenReference.Length=..X509Credentials.Length
					}
					Set ..Key=..X509Credentials.Key
				}
			} ElseIf $case(..ReferenceOption,$$$SOAPWSReferenceEncryptedKey:1,$$$SOAPWSReferenceSCT:1,$$$SOAPWSReferenceSCTIdentifier:1,$$$SOAPWSSAML:1,:0) {
				If $isobject(..X509Credentials) {
					If ..X509Credentials.Key="" {
						Set sc=..X509Credentials.InitializeKey(service,algorithm)
						If $$$ISERR(sc) Quit sc
					}
					Set ..Key=..X509Credentials.Key
				}
			} ElseIf ..ReferenceOption=$$$SOAPWSReferenceEncryptedKeySHA1 {
				Set requestHeader=service.SecurityIn
				If $isobject(requestHeader) {
					Set element=requestHeader.FindEncryptedKey(1)
					If $isobject(element) {
						If element.Key="" {
							Set sc=element.InitializeKey(service)
							If $$$ISERR(sc) Quit sc
						}
						Set ..Key=element.Key
						If element.CipherData'="" Do ..KeyInfo.SetIdentifier(element.CipherData.CipherValue)
					}
				}
			} Else {
				Set sc=$$$ERROR($$$SOAPBadLogin,"Unexpected referenceOption "_..ReferenceOption)
				$$$SOAPLogSecurity("    Unexpected referenceOption "_..ReferenceOption)
				Quit sc
			}
		}
		
		If ..Key="" {
			Set sc=$$$ERROR($$$SOAPBadLogin,"No key for hmac-sha1 algorithm")
			$$$SOAPLogSecurity("    No key for hmac-sha1 algorithm")
			Quit sc
		}

	} ElseIf $case(algorithm,$$$SOAPWSrsasha1:1,$$$SOAPWSrsasha256:1,$$$SOAPWSrsasha384:1,$$$SOAPWSrsasha512:1,:0) {
		// Validate that we had good credentials
		If (..X509Credentials="") || ($zobjclass(..X509Credentials)'="%SYS.X509Credentials") {
			Set sc=$$$ERROR($$$SOAPBadLogin,"No credentials specified for signature "_..X509Credentials)
			$$$SOAPLogSecurity("    No credentials specified for signature "_..X509Credentials)
			Quit sc
		}
		If '..X509Credentials.HasPrivateKey {
			Set sc=$$$ERROR($$$SOAPBadLogin,"No private key for credentials specified for signature: "_..X509Credentials.Alias)
			$$$SOAPLogSecurity("    No private key for credentials specified for signature: "_..X509Credentials.Alias)
			Quit sc
		}
	
		// Find size of the signature
		try {
			Set size=..X509Credentials.RSASize()
			If size<=0 {
				Set error=$System.Encryption.RSAGetLastError()
				Set sc=$$$ERROR($$$SOAPBadLogin,"Computing signature size failed: "_error)
				$$$SOAPLogSecurity("    Computing signature size failed: "_error)
				$$$SOAPLogSecurity("    credentials: "_..X509Credentials.Alias)
			}
		} catch ex {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Computing signature size failed due to internal error: "_ex.DisplayString())
			$$$SOAPLogSecurity("    Computing signature size failed due to internal failure: "_ex.DisplayString())
			$$$SOAPLogSecurity("    credentials: "_..X509Credentials.Alias)
		}
	} Else {
		Set sc=$$$ERROR($$$SOAPBadLogin,"Unexpected SignatureMethod "_algorithm)
		$$$SOAPLogSecurity("    Unexpected SignatureMethod "_algorithm)
	}
	
	Set ..SignatureValue=""

	Quit sc
}

/// Add a reference to XML element using an %XML.Security.Reference.
/// The reference may be created by using the ##class(%XML.Security.Reference).Create method.
/// If doNotReuse is true, then this reference will be removed during Reset
Method AddReference(reference As %XML.Security.Reference, doNotReuse As %Boolean = 0)
{
	If $isobject(..SignedInfo) {
		// If there is an enveloped signature, then force Id to be defined
		#dim transform As %XML.Security.Transform
		For j=1:1:reference.Transforms.Count() {
			Set transform=reference.Transforms.GetAt(j)
			If transform.Algorithm=$$$SOAPWSEnvelopedSignature {
				Set id=..GetId()
				Quit
			}
		}
		
		// If DigestMethod Algoritm not set by Create, then default it.
		If reference.DigestMethod.Algorithm="" Set reference.DigestMethod.Algorithm=..DigestMethodAlgorithm
		
		// Pad out with digest value for DigestMethod algoritm
		Set bitlength=$case(reference.DigestMethod.Algorithm,$$$SOAPWSsha1:160,$$$SOAPWSsha256:256,$$$SOAPWSsha384:384,$$$SOAPWSsha512:512,:0)
		Set $piece(dummy," ",bitlength\8+1)=""
		Set reference.DigestValue=dummy

		Set reference.DoNotReuse=doNotReuse
		Do ..SignedInfo.Reference.Insert(reference)
	}
}

/// Complete the Signature element and update the message stream with the new SignatureValue
Method Perform(messageStream As %BinaryStream, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	Set sc = $$$OK
	If '..PreProcessed {
		$$$SOAPTimer1Init(WSsign)
		// Parse the message stream so that pieces may be Canonicalized
		Set sc=##class(%XML.Document).GetDocumentFromStream(messageStream,.document)
		If $$$ISERR(sc) Quit sc
 
		// Sign the message stream
		Set sc=..Sign(document,.header,$get(%cspsoapmimeAttachments))
		If $$$ISERR(sc) Quit sc

		/// Rewrite the Security header, if WS-Security signing
		If messageStream=0,$isobject($get(header)) {
			Set sc=header.UpdateSecurityHeader($get(%cspsoapmimeAttachments))
		}
		$$$SOAPTimer1(WSsign,$select($data(%cspsoapservice):"s",1:"c")_"WSsign")

	}
	
	Quit sc
}

/// Complete the Signature element by adding the SignedInfo based on X509Credentials and 
/// compute the signature value.
Method Sign(document As %XML.Document, header As %SOAP.Security.Header, mimeAttachments As %Net.MIMEPart) As %Status [ Internal ]
{
	Set sc=$$$OK
	
	// Add references and compute digest based on the Signature options
	Set reflist=..SignedInfo.Reference
	#dim node As %XML.Node = document.GetNode("")
	Set writer=##class(%XML.Writer).%New()
	For i=1:1:reflist.Count() {
		Set signNodeId=""
		#dim ref As %XML.Security.Reference = reflist.GetAt(i)
		Set uri=ref.URI
		If uri="" {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference, no URI")
			$$$SOAPLogSecurity("    Signing invalid reference, no URI")
			Quit
		}
		If uri'=$char(0) Set uri=$extract(uri,2,*)
		#dim transform As %XML.Security.Transform
		Set count=ref.Transforms.Count()
		Set exc=1
		Set enc=0
		If count=2 {
			Set transform=ref.Transforms.GetAt(1)
			Set exc=2,enc=1
			If transform.Algorithm'=$$$SOAPWSEnvelopedSignature {
				Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference: unsupported algorithm: "_transform.Algorithm)
				$$$SOAPLogSecurity("    Signing invalid reference: unsupported algorithm: "_transform.Algorithm)
				Quit
			}
		} ElseIf count=1 {
			Set transform=ref.Transforms.GetAt(1)
			If transform.Algorithm=$$$SOAPWSEnvelopedSignature {
				Set exc=0,enc=1
			} Else {
				Set exc=1,enc=0
			}
		} Else {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference: Only one transform allowed.")
			$$$SOAPLogSecurity("    Signing invalid reference: Only one transform allowed.")
			Quit
		}
		Set isSTR=0
		// If enveloped signature, get enveloping node
		If enc {
			Set signNodeId=document.GetNodeById(..Id)
		} Else {
			If uri=$c(0) {
				Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference, no URI: unsupported algorithm: "_transform.Algorithm)
				$$$SOAPLogSecurity("    Signing invalid reference, no URI: unsupported algorithm: "_transform.Algorithm)
				Quit
			}
		}
		If exc=0 {
			Kill prefixList
		} Else {
			Set transform=ref.Transforms.GetAt(exc)
			If transform.Algorithm=$$$SOAPWSSTRTransform,$isobject($get(header)) {
				Set transformationParameters=transform.TransformationParameters
				Set transform=transformationParameters.CanonicalizationMethod
				Set str=header.GetElementById(uri)
				If '$isobject(str) || ($zobjclass(str)'="%SOAP.Security.SecurityTokenReference") {
					Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference: SecurityTokenReference expected for #STR-Transform. URI="_uri)
					$$$SOAPLogSecurity("    Signing invalid reference: SecurityTokenReference expected for #STR-Transform. URI="_uri)
					Quit
				}
				If str.Reference.Count()'=1 {
					Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference: Only one reference allowed for #STR-Transform. URI="_uri)
					$$$SOAPLogSecurity("    Signing invalid reference: Only one reference allowed for #STR-Transform. URI="_uri)
					Quit
				}
				Set strRef=str.Reference.GetAt(1)
				If $zobjclass(strRef)="%SOAP.Security.Reference" {
					Set uri=$extract(strRef.URI,2,*)
				} ElseIf $zobjclass(strRef)="%SOAP.Security.KeyIdentifier" {
					Set uri=strRef.Identifier
				} Else {
					Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference: Invalid format SecurityTokenReference for #STR-Transform. URI="_uri)
					$$$SOAPLogSecurity("    Signing invalid reference: Invalid format SecurityTokenReference for #STR-Transform. URI="_uri)
					Quit
				}
				Set isSTR=1
			} 
			If transform.Algorithm[$$$SOAPWSexcc14n {
				Set prefixList=""
				If $isobject(transform.InclusiveNamespaces) {
					Set prefixList=transform.InclusiveNamespaces.PrefixList
				}
			} ElseIf transform.Algorithm[$$$SOAPWSc14n {
				Kill prefixList
			} Else {
				Set sc=$$$ERROR($$$SOAPBadLogin,"Signing invalid reference: unsupported algorithm: "_transform.Algorithm)
				$$$SOAPLogSecurity("    Signing invalid reference: unsupported algorithm: "_transform.Algorithm)
				Quit
			}
		}
		If uri=$char(0) {
			Set nodeId=document.GetDocumentNode()  ; Root node of XML document
		} Else {
			Set nodeId=..GetNodeById(uri,document,node)
		}
		If nodeId="" {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Id not found for URI: "_uri)
			$$$SOAPLogSecurity("    Id not found for URI: "_uri)
			Quit
		}
		Set node.NodeId=nodeId
		Set bitlength=$case(ref.DigestMethod.Algorithm,$$$SOAPWSsha1:160,$$$SOAPWSsha256:256,$$$SOAPWSsha384:384,$$$SOAPWSsha512:512,:0)
		If bitlength=0 {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Invalid DigestMethod: "_ref.DigestMethod.Algorithm)
			$$$SOAPLogSecurity("    Invalid DigestMethod: "_ref.DigestMethod.Algorithm)
			Quit
		}
		Set hash=..ComputeSha1Digest(node,signNodeId,writer,.prefixList,bitlength,isSTR,,mimeAttachments)
		If hash="" {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Digest error, URI="_$extract(ref.URI,2,*))
			$$$SOAPLogSecurity("    Digest error, URI="_$extract(ref.URI,2,*))
			Quit
		}
		Set ref.DigestValue=hash
	}
	If $$$ISERR(sc) Quit sc
	
	Set signedInfo=..SignedInfo
	If $isobject(signedInfo.CanonicalizationMethod.InclusiveNamespaces) {
		Set sc=$$$ERROR($$$SOAPBadLogin,"InclusiveNamepaces PrefixList not supported")
		$$$SOAPLogSecurity("    InclusiveNamepaces PrefixList not supported")
		Quit sc
	}
	
	If (signedInfo.CanonicalizationMethod.Algorithm[$$$SOAPWSc14n) || 
	   ('$isobject($get(header)) && (..Id'="")) {
		// Canonicalize the SignedInfo element
		// This is the case for either inclusive canonicalization or
		// either exclusive or inclusive canonicalization if not WS-Security as part of SOAP header
		Set sc=writer.OutputToString()
		If $$$ISERR(sc) {
			Set sc=$$$ERROR($$$SOAPBadLogin,"%XML.Writer OutputToString error")
			Quit sc
		}
		Set sigId=document.GetNodeById(..Id)  ;; Signature node
		If sigId="" {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Canonicalize error: Signature not found")
			Quit sc
		}
		Set node.NodeId=sigId
		Set found=0
		If node.MoveToFirstChild(1) {
			While 'found {
				If node.LocalName="SignedInfo" Set found=1 Quit
				If 'node.MoveToNextSibling(1) Quit
			}
		}
		If 'found {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Canonicalize error: SignedInfo not found")
			Quit sc
		}
		Set signedInfoNodeId=node.NodeId
		Set refCount=0
		If node.MoveToFirstChild(1) {
			For {
				If node.LocalName="Reference" {
					Set refCount=refCount+1
					Set refNodeId=node.NodeId
					If node.MoveToFirstChild(1) {
						For {
							If node.LocalName="DigestValue" {
								Set disgstValueNodeId=node.NodeId
								If node.MoveToFirstChild(0) {
									Do node.ReplaceCharacter($system.Encryption.Base64Encode(reflist.GetAt(refCount).DigestValue,1))
								}
								Set node.NodeId=disgstValueNodeId
							}
							If 'node.MoveToNextSibling(1) Quit
						}
					}
					Set node.NodeId=refNodeId
				}
				If 'node.MoveToNextSibling(1) Quit
			}
		}
		Set node.NodeId=signedInfoNodeId
		If signedInfo.CanonicalizationMethod.Algorithm[$$$SOAPWSc14n {
			Set signingPrefixArray="c14n"
		}
		Set sc=writer.Canonicalize(node,.signingPrefixArray,,,mimeAttachments)
		If $$$ISERR(sc) {
			Set sc=$$$ERROR($$$SOAPBadLogin,"%XML.Writer Canonicalize error: "_$system.Status.GetErrorText(sc))
			Quit sc
		}
		Set signedXML=writer.GetXMLString(.sc)
		If $$$ISERR(sc) {
			Set sc=$$$ERROR($$$SOAPBadLogin,"%XML.Writer GetXMLString error: "_$system.Status.GetErrorText(sc))
			Quit sc
		}
		If $$$CheckSOAPLogVerbose $$$SOAPLogSecurity("    Canonical SignedInfo: "_signedXML)

	} Else {
		// Compute signature
		// Note that SignedInfo setup so that XML produced in this way
		// is Exclusively Canonicalized XML and part of WS-Security in SOAP header.
		// This shortcut works for this most common case and is faster.
		Set needGlobal=$$$XMLIsWrite
		If needGlobal $$$XMLUseGlobal
		$$$XMLUseLast

		Set namespaces=##class(%XML.Namespaces).%New()
		Set namespaces.ElementQualified=1
		Set sc=signedInfo.XMLExport(,"literal",namespaces)
		If $$$ISERR(sc) {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Export of SignedInfo failed.")
			Quit sc
		}

		$$$XMLRewindSingle($$$XMLCurrentIndex)
		Set signedXML=$$$XMLRead()
		$$$XMLTruncate
		If needGlobal $$$XMLUseRestore
	}

	Set hmacbitlength=$case(signedInfo.SignatureMethod.Algorithm,$$$SOAPWShmacsha1:160,$$$SOAPWShmacsha256:256,$$$SOAPWShmacsha384:384,$$$SOAPWShmacsha512:512,:0)
	If hmacbitlength>0 {  // HMAC
		If ..Key="" {
			Set sc=$$$ERROR($$$SOAPBadLogin,"No key specified for signature.")
			$$$SOAPLogSecurity("    No key specified for signature.")
			Quit sc
		}
		
		Set bitlength=signedInfo.SignatureMethod.HMACOutputLength
		$$$SOAPLogSecurity("    Sign with algorithm "_signedInfo.SignatureMethod.Algorithm)
		try {
			Set value=$system.Encryption.HMACSHA(hmacbitlength,signedXML,..Key)
			If bitlength'="" {
				Set ..SignatureValue=$extract(value,1,bitlength/8)
			} Else {
				Set ..SignatureValue=value
			}
		} catch ex {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Signing failed due to internal error")
			$$$SOAPLogSecurity("    Signing failed due to internal failure: "_ex.DisplayString())
		}

	} Else {
		// Validate that we had good credentials
		If (..X509Credentials="") || ($zobjclass(..X509Credentials)'="%SYS.X509Credentials") {
			Set sc=$$$ERROR($$$SOAPBadLogin,"No credentials specified for signature "_..X509Credentials)
			$$$SOAPLogSecurity("    No credentials specified for signature "_..X509Credentials)
			Quit sc
		}
		If '..X509Credentials.HasPrivateKey {
			Set sc=$$$ERROR($$$SOAPBadLogin,"No private key for credentials specified for signature: "_..X509Credentials.Alias)
			$$$SOAPLogSecurity("    No private key for credentials specified for signature: "_..X509Credentials.Alias)
			Quit sc
		}
	
		Set bitlength=$case(signedInfo.SignatureMethod.Algorithm,$$$SOAPWSrsasha1:160,$$$SOAPWSrsasha256:256,$$$SOAPWSrsasha384:384,$$$SOAPWSrsasha512:512,:0)
		If bitlength=0 {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Invalid signature method: "_signedInfo.SignatureMethod.Algorithm)
			$$$SOAPLogSecurity("    Invalid signature method: "_signedInfo.SignatureMethod.Algorithm)
			Quit sc
		}

		$$$SOAPLogSecurity("    Sign using "_..X509Credentials.Alias_$select(bitlength=160:"",1:" with algorithm "_signedInfo.SignatureMethod.Algorithm))
		try {
			;;if $$$CheckSOAPLogVerbose {
			;;	$$$SOAPLogSecurity("       bitlength="_bitlength)
			;;	$$$SOAPLogSecurity("       signedXML="_signedXML)
			;;	$$$SOAPLogSecurity("       SignatureValue="_$system.Encryption.Base64Encode(..SignatureValue))
			;;	$$$SOAPLogSecurity("       certificate="_$system.Encryption.Base64Encode(..X509Credentials.Certificate))
			;;}
			Set ..SignatureValue=..X509Credentials.RSASHASign(bitlength,signedXML)
			If ..SignatureValue="" {
				Set error=$System.Encryption.RSAGetLastError()
				Set sc=$$$ERROR($$$SOAPBadLogin,"Signing failed: "_error)
				$$$SOAPLogSecurity("    Signing failed: "_error)
			}
		} catch {
			Set sc=$$$ERROR($$$SOAPBadLogin,"Signing failed due to internal error")
			$$$SOAPLogSecurity("    Signing failed due to internal failure: "_ex.DisplayString())
		}
	}
	
	Quit sc
}

/// Get node based on id from URI.  Return nodeId
Method GetNodeById(uri As %String, document As %XML.Document, node As %XML.Node) As %String [ Internal, Private ]
{
	Set nodeId=document.GetNodeById(uri)

	// In the case of a SAML Response, the ID attribute will be all caps
	If nodeId="" {
		Set node.NodeId=document.GetDocumentNode()
		//We could also check the namespace, which should be "urn:oasis:names:tc:SAML:2.0:protocol"
		If (node.LocalName="Response") && (node.GetAttributeValue("ID")=uri) {
			Set nodeId=node.NodeId
		}	
	}
	
	// If reference to SAML assertion in enveloped-signature or SecurityToken\Reference,
	/// also check for SAML Assertion ID attribute
	If nodeId="" {
		Set node.NodeId=document.GetDocumentNode()  ; Envelope
		If node.MoveToFirstChild(1) && ; soap:Header
		   (node.LocalName="Header") && 
		   node.MoveToFirstChild(1) { ; first header
			Do {
				If (node.LocalName="Security") && 
				   (node.Namespace=$$$SOAPWSSEns) && 
				   node.MoveToFirstChild(1) {  ; First security element
					Do {
						If (node.LocalName="Assertion") && 
						   (node.Namespace=$$$SAMLns) &&
						   (node.GetAttributeValue("ID")=uri) {
							Set nodeId=node.NodeId
						}
					} While node.MoveToNextSibling(1)
				} ElseIf (node.LocalName="Assertion") && 
						 (node.Namespace=$$$SAMLns) &&
						 (node.GetAttributeValue("ID")=uri) {
					Set nodeId=node.NodeId
				}
			} While node.MoveToNextSibling(1)
		}
	}
	
	quit nodeId
}

/// Reset the Signature element.
Method Reset() [ Internal ]
{
	Do ##super()
	
	If $isobject(..SignedInfo) {
		For i=..SignedInfo.Reference.Count():-1:1 {
			Set ref=..SignedInfo.Reference.GetAt(i)
			If ref.DoNotReuse {
				Do ..SignedInfo.Reference.RemoveAt(i)
			}
		}
	}

	Set ..Confirmed=""
	Set ..IsBodySigned=""
	Set ..Key=""
}

/// Validate the security header element.
/// If invalid return an error code.<br><br>
/// If the document is an MTOM document, then the optional <var>mimeAttachments</var> argument
/// contains a single MIME part which has each MIME section as one of its child <var>Parts</var>.<br><br>
/// The CAFile argument is the full path of file which contains the certificate authority 
/// certificates which are to be used to validate the signing certificate.<br><br>
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase = "", mimeAttachments As %Net.MIMEPart = "", CAFile As %String = "") As %String [ Internal ]
{
	$$$SOAPTimer1Init(WSvalidate)
	$$$SOAPLogSecurity("Security Signature:")
	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"
	Set error=""

	// Get MTOM attachments if we need them
	If $isobject(service),mimeAttachments="",service.IsMTOM {
		If service.%Extends("%SOAP.WebClient") {
			Set attachments=service.ResponseAttachments
		} Else {
			Set attachments=service.Attachments
		}
		Set mimeAttachments=##class(%Net.MIMEPart).%New()
		For i=1:1:attachments.Count() {
			Do mimeAttachments.Parts.Insert(attachments.GetAt(i))
		}
	}

	// SignedInfo element must be specified
	Set signedInfo=..SignedInfo
	If signedInfo="" {
		$$$SOAPLogSecurity("    no SignedInfo")
		Quit invalid
	}

	// Only transforms exclusive and inclusive XML canonicalization supported
	If signedInfo.CanonicalizationMethod.Algorithm[$$$SOAPWSexcc14n {
		Set signingPrefixList=""
		If $isobject(signedInfo.CanonicalizationMethod.InclusiveNamespaces) {
			Set signingPrefixList=signedInfo.CanonicalizationMethod.InclusiveNamespaces.PrefixList
		}
	} ElseIf signedInfo.CanonicalizationMethod.Algorithm'[$$$SOAPWSc14n {
		$$$SOAPLogSecurity("    bad signature transform="_signedInfo.CanonicalizationMethod.Algorithm)
		Quit unsupported
	}
	
	// Validate each signed element
	Set writer=##class(%XML.Writer).%New()
	Set node=document.GetNode("")
	Set references=signedInfo.Reference
	For i=1:1:references.Count() {
		Set signNodeId=""
		Set ref=references.GetAt(i)
		Set uri=ref.URI
		$$$SOAPLogSecurity("    Reference "_i)
		If uri=$char(0) {
		} ElseIf $extract(uri)="#" {
			Set uri=$extract(uri,2,*)
		} Else {
			$$$SOAPLogSecurity("    URI must be fragment")
			Set error=unsupported
			Quit
		}
		// Only #sha1 digest and exclusive canonicalization supported
		Set transforms=ref.Transforms
		Set count=transforms.Count()
		Set exc=1
		Set enc=0
		If count=2 {
			Set transform=ref.Transforms.GetAt(1)
			Set exc=2,enc=1
			If transform.Algorithm'=$$$SOAPWSEnvelopedSignature {
				Set error=unsupported
				$$$SOAPLogSecurity("    bad reference transform="_transform.Algorithm)
				Quit
			}
		} ElseIf count=1 {
			Set transform=ref.Transforms.GetAt(1)
			If transform.Algorithm=$$$SOAPWSEnvelopedSignature {
				Set exc=0,enc=1
			} Else {
				Set exc=1,enc=0
			}
		} Else {
			Set error=unsupported
			$$$SOAPLogSecurity("    only one reference transform allowed="_transforms.Count())
			Quit
		}
		Set isSTR=0
		// If enveloped signature, get enveloping node
		If enc {
			Set signNodeId=..NodeId
		} Else {
			If uri=$c(0) {
				$$$SOAPLogSecurity("    URI must be specified if not enveloped-signature")
				Set error=unsupported
				Quit
			}
		}
		If exc=0 {
			Kill prefixList
		} Else {
			Set transform=transforms.GetAt(exc)
			If transform.Algorithm=$$$SOAPWSSTRTransform,$isobject($get(%SOAPSecurityHeader)) {
				Set transformationParameters=transform.TransformationParameters
				Set transform=transformationParameters.CanonicalizationMethod
				Set str=%SOAPSecurityHeader.GetElementById(uri)
				If '$isobject(str) || ($zobjclass(str)'="%SOAP.Security.SecurityTokenReference") {
					Set error=unsupported
					$$$SOAPLogSecurity("    SecurityTokenReference expected for #STR-Transform. URI="_uri)
					Quit
				}
				If str.Reference.Count()'=1 {
					Set error=unsupported
					$$$SOAPLogSecurity("    Only one reference allowed for #STR-Transform. URI="_uri)
					Quit
				}
				Set strRef=str.Reference.GetAt(1)
				If $zobjclass(strRef)="%SOAP.Security.Reference" {
					Set uri=$extract(strRef.URI,2,*)
				} ElseIf $zobjclass(strRef)="%SOAP.Security.KeyIdentifier" {
					Set uri=strRef.Identifier
				} Else {
					Set error=unsupported
					$$$SOAPLogSecurity("    Invalid format SecurityTokenReference for #STR-Transform. URI="_uri)
					Quit
				}
				Set isSTR=1
			} 
		
			If transform.Algorithm[$$$SOAPWSexcc14n {
				Set prefixList=""
				If $isobject(transform.InclusiveNamespaces) {
					Set prefixList=transform.InclusiveNamespaces.PrefixList
				}
			} ElseIf transform.Algorithm[$$$SOAPWSc14n {
				Kill prefixList
			} Else {
				Set error=unsupported
				$$$SOAPLogSecurity("    bad reference transform="_transform.Algorithm)
				Quit
			}
		}
		Set bitlength=$case(ref.DigestMethod.Algorithm,$$$SOAPWSsha1:160,$$$SOAPWSsha256:256,$$$SOAPWSsha384:384,$$$SOAPWSsha512:512,:0)
		If bitlength=0 {
			$$$SOAPLogSecurity("    bad reference algorithm="_ref.DigestMethod.Algorithm)
			Set error=unsupported
			Quit
		}
		
		If uri=$char(0) {
			Set nodeId=document.GetDocumentNode()  ; Root node of XML document
		} Else {
			// Find DOM node corresponding to the URI fragment 
			Set nodeId=..GetNodeById(uri,document,node)
		}
		If nodeId="" {
			$$$SOAPLogSecurity("    Id not found for URI: "_uri)
			Set error="FailedCheck"
			Quit
		}
		Set node.NodeId=nodeId
		// Save the node id of the signed element
		Set ref.ElementNodeId=nodeId
		;; Checking enveloped is nice to have, but I cannot find a reference that it is required.
		;;// If enveloped, check that the signature is contained in the signed node.
		;;If signNodeId'="",'node.IsAncestor(signNodeId) {
		;;	$$$SOAPLogSecurity("    Enveloped signature is not contained in signed node")
		;;	Set error="FailedCheck"
		;;	Quit
		;;}
	
		// Compute hash of DOM element
		Set hash=..ComputeSha1Digest(node,signNodeId,writer,.prefixList,bitlength,isSTR,.canontext,mimeAttachments)
		If hash="" {
			Set error=invalid
			Quit
		}

		// Check if signed node is child of the SOAP Body element
		If node.LocalName="Body" {
			Set ns=node.Namespace
			If (ns=$$$SOAP12ENVns) || (ns=$$$SOAPENVns) {
				Set ..IsBodySigned=1
				Set ref.ElementType="Body"
			}
		} ElseIf node.MoveToParent(1),node.LocalName="Header" {
			Set ns=node.Namespace
			If (ns=$$$SOAP12ENVns) || (ns=$$$SOAPENVns) {
				Set ref.ElementType="Header"
			}
		} ElseIf uri'=$char(0),$isobject($get(%SOAPSecurityHeader)),$isobject(%SOAPSecurityHeader.GetElementById(uri)) {
			Set ref.ElementType="Element"
		} Else {
			Set ref.ElementType=""
		}
	
		// Validate that computed digest matches the digest from the signature.
		If hash'=ref.DigestValue {
			$$$SOAPLogSecurity("    Digest did not match.")
			If $$$CheckSOAPLogSecurity {
				$$$SOAPLogText($c(13,10)_"*******Canonicalized XML: bitlength="_bitlength)
				Do canontext.Rewind()
				$$$SOAPLogRawText(canontext)
			}
			Set error="FailedCheck"
			Quit
		}

		$$$SOAPLogSecurity("    Digest matched.")
	}
	If error'="" Quit error

	// Canonicalize the SignedInfo element
	Set sc=writer.OutputToString()
	If $$$ISERR(sc) {
		$$$SOAPLogSecurity("    %XML.Writer OutputToString error")
		Quit invalid
	}
	Set node.NodeId=signedInfo.NodeId
	If $data(signingPrefixList) {
		If signingPrefixList'="" {
			Do writer.ParsePrefixList(signingPrefixList,.signingPrefixArray)
		}
	} Else {
		Set signingPrefixArray="c14n"
	}
	Set sc=writer.Canonicalize(node,.signingPrefixArray,,,mimeAttachments)
	If $$$ISERR(sc) {
		$$$SOAPLogSecurity("    %XML.Writer Canonicalize error: "_$system.Status.GetErrorText(sc))
		Quit invalid
	}
	Set signatureText=writer.GetXMLString(.sc)
	If $$$ISERR(sc) {
		$$$SOAPLogSecurity("    %XML.Writer GetXMLString error: "_$system.Status.GetErrorText(sc))
		Quit invalid
	}
	If $$$CheckSOAPLogVerbose $$$SOAPLogSecurity("    Canonical SignedInfo: "_signatureText)

	// KeyInfo with 1 key must be specified to validate signature
	Set keyInfo=..KeyInfo
	If keyInfo="" {
		$$$SOAPLogSecurity("    no KeyInfo")
		Quit invalid
	}
	Set error=keyInfo.ValidateTokenRef(service)
	If error'="" Quit error

	// Validate the signature using the certificate in the BinarySecurityToken
	If keyInfo.KeyType=$$$SOAPWSX509v3 {
		Set bitlength=$case(signedInfo.SignatureMethod.Algorithm,$$$SOAPWSrsasha1:160,$$$SOAPWSrsasha256:256,$$$SOAPWSrsasha384:384,$$$SOAPWSrsasha512:512,:0)
		If bitlength=0 {
			$$$SOAPLogSecurity("    Unexpected signature method: "_signedInfo.SignatureMethod.Algorithm)
			Quit unsupported
		}

		If $zobjclass(keyInfo.X509Credentials)'="%XML.Security.RSAKeyValue" {
			// Get certificate
			Set credentials=keyInfo.X509Credentials
			Set certificate=credentials.Certificate

			// Get CA Certificate file
			If CAFile'="" {
				Set cafile=CAFile
				$$$SOAPLogSecurity("    Signature Verify: user specified CAFile="_cafile)
			} ElseIf $classname(credentials)="%SYS.X509Credentials",credentials.CAFile'="" {
				Set cafile=##class(%File).NormalizeFilename(credentials.CAFile,##class(%File).ManagerDirectory())
				If $$$CheckSOAPLogSecurity {
					Set file=cafile
					If $$$CheckSOAPTestMode {
						Set file=$tr(file,"\","/")
						Set file="internal/"_$piece(file,"/internal/",2)
					}
				}
				$$$SOAPLogSecurity("    Signature Verify: non-default CAFile="_file)
			} Else {
				Set cafile=$zu(12)_"iris.cer"
			}
			Set crlfile=$zu(12)_"iris.crl"
			If $zu(140,4,crlfile)'=0 Set crlfile=""
		
			// Validate the signature.
			Try { 
				$$$SOAPLogSecurity("    Signature Verify"_$select(bitlength=160:"",1:" with algorithm "_signedInfo.SignatureMethod.Algorithm))
				;;if $$$CheckSOAPLogVerbose {
				;;	$$$SOAPLogSecurity("       bitlength="_bitlength)
				;;	$$$SOAPLogSecurity("       signatureText="_signatureText)
				;;	$$$SOAPLogSecurity("       SignatureValue="_$system.Encryption.Base64Encode(..SignatureValue))
				;;	$$$SOAPLogSecurity("       certificate="_$system.Encryption.Base64Encode(certificate))
				;;	$$$SOAPLogSecurity("       cafile="_cafile)
				;;}
				If '$System.Encryption.RSASHAVerify(bitlength,signatureText,..SignatureValue,certificate,cafile,crlfile) {
					$$$SOAPLogSecurity("    Signature verification failed: "_$System.Encryption.RSAGetLastError())
					Set error="FailedCheck"
				}
			} Catch {
				$$$SOAPLogSecurity("    Signature verify internal failure")
				Set error="FailedCheck"
			}
			If error="" {
				$$$SOAPLogSecurity("    SignatureValue matched")
				Set ..X509Credentials=keyInfo.X509Credentials
			} Else {
				If '##class(%File).Exists(cafile) {
					$$$SOAPLogSecurity("    "_cafile_" not found")
				}
			}
		} Else {
			// Get RSAKeyValue
			Set keyValue=keyInfo.X509Credentials
			// Validate the signature.
			Try {
				$$$SOAPLogSecurity("    Signature Verify with RSAKeyValue")
				If '$System.Encryption.RSASHAVerify(bitlength,signatureText,..SignatureValue,keyValue.Modulus,keyValue.Exponent) {
					$$$SOAPLogSecurity("    Signature verification with RSAKeyValue failed: "_$System.Encryption.RSAGetLastError())
					Set error="FailedCheck"
				}
			} Catch {
				$$$SOAPLogSecurity("    Signature verify with RSAKeyValue internal failure")
				Set error="FailedCheck"
			}
			If error="" {
				Set ..X509Credentials=keyInfo.X509Credentials
				$$$SOAPLogSecurity("    SignatureValue matched with RSAKeyValue")
			}
		}
	} ElseIf $case(keyInfo.KeyType,$$$SOAPWSEncryptedKey:1,$$$SOAPWSEncryptedKeySHA1:1,$$$SOAPWSDerivedKey:1,$$$SOAPWSSCToken:1,$$$SOAPWSTSecretSymKey:1,:0) {
		Set error=keyInfo.ValidateKeyElement(service,.key,1)
		If error'="" Quit error

		If key="" {
			$$$SOAPLogSecurity("    No key specified for signature.")
			Quit invalid
		}
	
		Set bitlength=signedInfo.SignatureMethod.HMACOutputLength
		$$$SOAPLogSecurity("    Validate with algorithm "_signedInfo.SignatureMethod.Algorithm)
		try {
			Set hmacbitlength=$case(signedInfo.SignatureMethod.Algorithm,$$$SOAPWShmacsha1:160,$$$SOAPWShmacsha256:256,$$$SOAPWShmacsha384:384,$$$SOAPWShmacsha512:512,:0)
			Set value=$system.Encryption.HMACSHA(hmacbitlength,signatureText,key)
			If bitlength'="" {
				Set value=$extract(value,1,bitlength/8)
			}
			If ..SignatureValue'=value {
				$$$SOAPLogSecurity("    Signature verification with hmac-sha1 failed.")
				Set error="FailedCheck"
			}
		} catch ex {
			$$$SOAPLogSecurity("    Signing failed due to internal failure: "_ex.DisplayString())
			Set error=invalid
		}
		If error="" {
			Set ..X509Credentials=keyInfo.X509Credentials
			$$$SOAPLogSecurity("    SignatureValue matched with hmac-sha1")
		}
	
	} Else {
		$$$SOAPLogSecurity("    signature unexpected TokenType="_keyInfo.KeyType)
		Set error=unsupported
	}

	$$$SOAPTimer1(WSvalidate,$select(($isobject(service) && service.%Extends("%SOAP.WebClient")):"c",1:"s")_"WSvalidate")
	If error="" $$$SOAPLogSecurity("    Validated.")
	Quit error
}

/// Compute SHA1 digest of an element
Method ComputeSha1Digest(node As %XML.Node, signNodeId As %String, writer As %XML.Writer, prefixList As %String, bitlength As %Integer, isSTR As %Boolean, ByRef text As %FileBinaryStream, mimeAttachments As %Net.MIMEPart) As %xsd.base64Binary
{
	$$$SOAPTimer1Init(WSdcanon)
	// Exclusive canonicalize the node
	Set sc=writer.OutputToStream(.text)
	If $$$ISERR(sc) {
		Do DecomposeStatus^%apiOBJ(sc,.err)
		$$$SOAPLogSecurity("    unable to open stream for digest"_err(1))
		Quit ""
	}
	
	// If enveloped-signature, then mark signature element to be skipped during canonicalization
	if signNodeId'="" {
		$$$SOAPLogSecurity("    Enveloped signature: "_node.QName)
		$$$xmlSetSkipFlag(node.Document.DocumentId,signNodeId,1)
	}
	
	If $data(prefixList) {
		If prefixList'="" {
			Do writer.ParsePrefixList(prefixList,.prefixArray)
		}
	} Else {
		Set prefixArray="c14n"
	}
	Set sc=writer.Canonicalize(node,.prefixArray,,isSTR,mimeAttachments)

	if signNodeId'="" {
		$$$xmlSetSkipFlag(node.Document.DocumentId,signNodeId,0)
	}
	
	If $$$ISERR(sc) {
		Do DecomposeStatus^%apiOBJ(sc,.err)
		$$$SOAPLogSecurity("    unable to canonicalize for digest"_err(1))
		Quit ""
	}

	Do writer.Reset()
	
	If $$$CheckSOAPLogSecurity,$$$CheckSOAPLogVerbose {
		$$$SOAPLogText($c(13,10)_"Canonicalized XML: bitlength="_bitlength_$select(isSTR:" SecurityTokenReference",1:""))
		Do text.Rewind()
		$$$SOAPLogRawText(text)
	}
	$$$SOAPTimer1(WSdcanon,$select($data(%cspsoapservice):"s",1:"c")_"WSdcanon")
	$$$SOAPTimer1Init(WSdhash)

	// Compute and return sha1 digest of the canonicalized element text
	Set digest=$System.Encryption.SHAHashStream(bitlength,text)
	$$$SOAPTimer1(WSdhash,$select($data(%cspsoapservice):"s",1:"c")_"WSdhash")

	Quit digest
}

}
