/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Security.EncryptedData+xml">Encrypting XML Documents</a>.
/// and <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Security.EncryptedData+soap">Encrypting SOAP Security Headers</a>.
/// </p>
/// XML Encryption element.
Class %XML.Security.EncryptedData Extends %XML.Security.EncryptedType [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2001/04/xmlenc#";

Parameter ELEMENTQUALIFIED = 1;

/// Override of %XML.Security.EncryptedType property to allow > 32k of data
Property CipherData As %XML.Security.CipherDataStream(XMLREF = 1) [ Required ];

/// Unchanged override of %XML.Security.EncryptedType property to maintain element position.
Property EncryptionProperties As %XML.Security.EncryptionProperties(XMLREF = 1);

/// ReferenceOption argument from the Create call.
Property ReferenceOption As %String(XMLPROJECTION = "none") [ Internal ];

/// The key element which contains the key material to use for creating the Key.
/// The type of this property depends on the reference option.
Property KeyElement As %XML.Security.EncryptedKey(XMLPROJECTION = "none") [ Internal ];

/// Security header element child to be encrypted.
/// If Body to be encrypted, then "".
Property EncryptedPart As %SOAP.Security.Element(XMLPROJECTION = "none") [ Internal ];

/// If true, then the SOAP Body is encrypted.
Property IsBodyEncrypted As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// Create a EncryptedData element that is to be referenced from a ReferenceList Security element and
/// that is to carry content encrypted with a symmetric key specified by its KeyInfo element.
/// <ul>
/// <li>keyElement is the Security element which will supply the symmetric key.  
/// keyElement is meaningful only when referenceOption specified.  See referenceOption for details.</li>
/// <li>The elementToEncrypt argument specifies the oref of the element to be encrypted.
/// It is currently only valid to encrypt the body or a Security element.
/// The default is "" which means to encrypt the body.</li>
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
/// The keyElement argument must be specified and is the DerivedKeyToken element.
/// The key size to be used for this EncryptedData element must be specified by setting
/// the Algorithm property or by setting the Length property of the DerivedKey.</li>
/// <li>$$$SOAPWSReferenceSCT is reference by wsu:Id to a SecurityContextToken element in this message.
/// The keyElement argument must be specified and is the SecurityContextToken element.</li>
/// <li>$$$SOAPWSReferenceSCTIdentifier is reference by Identifier and Instance to a SecurityContextToken
/// element not necessarily in this message.
/// The keyElement argument must be specified and is the SecurityContextToken element.</li>
/// </ul>
/// </ul>
ClassMethod Create(keyElement As %XML.Security.EncryptedKey = "", elementToEncrypt As %SOAP.Security.Element, referenceOption As %Integer = "") As %XML.Security.EncryptedData
{
	#dim element As %XML.Security.EncryptedData = ..%New()

	If $get(referenceOption)="" {
		Set secref=""
	} ElseIf referenceOption=$$$SOAPWSReferenceEncryptedKeySHA1 {
		If keyElement'="",'$isobject(keyElement) Quit ""
		Set element.Key=$select(keyElement="":"",1:keyElement.Key)
		Set cipher=$select(keyElement="":"",1:keyElement.CipherData.CipherValue)
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetKeyIdentifier($$$SOAPWSEncryptedKeySHA1,cipher)
	} ElseIf referenceOption=$$$SOAPWSReferenceEncryptedKey {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="EncryptedKey")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId())
	} ElseIf referenceOption=$$$SOAPWSReferenceDerivedKey {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="DerivedKeyToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId())
	} ElseIf referenceOption=$$$SOAPWSReferenceSCT {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="SecurityContextToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetDirectReference("#"_keyElement.GetId(),$$$SOAPWSSCToken)
	} ElseIf referenceOption=$$$SOAPWSReferenceSCTIdentifier {
		If ('$isobject(keyElement) || ($$$ClassShortName(keyElement)'="SecurityContextToken")) Quit ""
		Set secref=##class(%SOAP.Security.SecurityTokenReference).GetSCTReference(keyElement)
	} Else {
		// Unknown reference option
		Quit ""
	}
	Set element.ReferenceOption=referenceOption

	Set element.EncryptedPart=$get(elementToEncrypt)
	Set element.Id="Enc-"_$system.Util.CreateGUID()

	If secref'="" {
		#dim keyInfo As %XML.Security.KeyInfo = ##class(%XML.Security.KeyInfo).%New()
		Do keyInfo.KeyInfoClauseList.Insert(secref)
		Set element.KeyInfo=keyInfo
		Set element.KeyElement=keyElement
	}
	
	Quit element
}

/// Create an EncryptedData element
ClassMethod CreateFromEncryptedKey(encryptedKey As %XML.Security.EncryptedKey, elementToEncrypt As %SOAP.Security.Element) As %XML.Security.EncryptedData [ Internal ]
{
	#dim element As %XML.Security.EncryptedData = ##class(%XML.Security.EncryptedData).%New()
	Set element.Id="Enc-"_$system.Util.CreateGUID()

	Set element.EncryptedPart=$get(elementToEncrypt)
	Set element.Key=encryptedKey.Key
	Set element.RequireBestEntropy=encryptedKey.RequireBestEntropy
	Set element.Algorithm=encryptedKey.Algorithm
	Set element.ReferenceOption=""

	Quit element
}

/// EncryptStream encrypts messageStream and stores the encrypted content of 
/// messageStream as the CipherData.
/// This completed EncryptedData instance may be exported using %XML.Writer to create an EncyptedData 
/// element as required by the XML Encryption specification.<br><br>
/// 
/// <var>messageStream</var> is the stream containing the data to be encrypted.
/// <var>messageStream</var> must be positioned before calling EncryptStream -- 
/// for example by calling Rewind first.<br><br>
/// 
/// <var>encryptedKeys</var> is a %ListOfObjects of instances of %XML.Security.EncryptedKey.
/// The EncyptedStream method will compute a common random, symmetric key for all the elements
/// in <var>encryptedKeys</var> and store the encrypted symmetric key  in the EncryptedKey instance.
/// Encryption of the symmetric key is done using the 
/// public key from the X.509 credentials associated with the EncyptedKey instance.
/// The result is that <var>messageStream</var> may be decrypted by any 
/// recipient that has the private key associated with the X.509 certificate in
/// one of the EncryptedKey instances.<br><br>
/// 
/// The default value of any property of EncryptedData, such as Algorithm, Type and RequireBestEntropy,
/// may be overridden before calling EncryptStream.<br><br>
/// 
/// The following example encrypts messageStream based on the certifcates in the credentials
/// called cred1 and cred2.<br><br>
/// <example>
/// set encryptedKeys=##class(%ListOfObjects).%New()
/// set x5091 = ##class(%SYS.X509Credentials).GetByAlias("cred1")
/// do encryptedKeys.Insert(##class(#XML.Security.EncryptedKey).CreateX509(
/// 			x5091,,$$$KeyInfoX509SKI))
/// set x5092 = ##class(%SYS.X509Credentials).GetByAlias("cred2")
/// do encryptedKeys.Insert(##class(#XML.Security.EncryptedKey).CreateX509(
/// 			x5092,,$$$KeyInfoX509SKI))
/// set encryptedData=##class(#XML.Security.EncryptedData).%New()
/// set encryptedData.Algorithm=$$$SOAPWSaes256cbc ; default is $$$SOAPWSaes128cbc
/// set encryptedData.Type=$$$SOAPWSEncryptElement ; default is $$$SOAPWSEncryptContent
/// do messageStream.Rewind()
/// set status=encryptedData.EncryptStream(messageStream, encryptedKeys)
/// if $$$ISERR(status) .... handle error ....
/// </example>
Method EncryptStream(messageStream As %BinaryStream, encryptedKeys As %ListOfObjects(ELEMENTTYPE="%XML.Security.EncryptedKey")) As %Status
{
	// Default needed values and initialize the key
	If ..Type="" Set ..Type=$$$SOAPWSEncryptContent
	If ..Id="" Set ..Id="Enc-"_$system.Util.CreateGUID()
	If ..Algorithm="" Set ..Algorithm=$$$SOAPWSaes128cbc
	Set sc=..InitializeKey(,..Algorithm)
	Do ..SetEncryptionMethod(..Algorithm)

	
	For index=1:1:encryptedKeys.Count() {
		Set encryptedKey=encryptedKeys.GetAt(index)
		Set encryptedKey.Algorithm=..Algorithm
		Set encryptedKey.Key=..Key
		Set sc=encryptedKey.EncryptKey()
		If $$$ISERR(sc) Quit
		Do encryptedKey.AddReference(##class(%XML.Security.DataReference).Create($this))
	}
	
	If $$$ISOK(sc) {
		Set sc=..ComputeCipherData(messageStream)
	}
	
	Quit sc
}

/// Validate a %XML.Document containing a parsed XML document which contains an EncryptedData
/// element and EncryptedKey elements.
/// 
/// <var>document</var> is the parsed document.<br><br>
/// If decryption is valid, the <var>document</var> argument is updated with a 
/// new document which has the EncryptedData element replaced by the decypted text
/// and true (1) is returned.  If invalid return false (0).<br><br>
/// 
/// <var>encryptedKeys</var> is a %ListOfObjects of instances of %XML.Security.EncryptedKey.
/// The ValidateDocument method will decrypt the CipherData in the EncryptedData element 
/// found in the document based on one of the EncryptedKey elements in encryptedKeys.
/// Any EncryptedKey elemetns which do not result in successful decryption are ignored.
/// The result is that the EncryptedData in <var>document</var> may be decrypted by any 
/// recipient that has the private key associated with the X.509 certificate in
/// one of the EncryptedKey instances.<br><br>
/// 
/// The following example assumes a single argument web service method with the argument named <var>arg</var>.
/// This will usually be the case with an entire message being the argument since
/// Parameter ARGUMENTSTYLE = "message".  The EncryptedData to validate and decrypt is the SOAP message whose
/// %XML.Document is contained in the ImportHandler property of the service.
/// 
/// <example>
/// // Keys element is property containing a list of EncryptedKey elements.
/// // Keys is an arbitrary property name
/// set document=..ImportHandler
/// if ##class(%XML.Security.EncryptedData).ValidateDocument(.document,arg.Keys) {
/// 	set reader=##class(%XML.Reader).%New()
/// 	set reader.Document=document  ; updated document to a reader instance
/// 	do reader.Correlate(....      ; Use reader to create classes
/// 	... Use Next loop to process payload ...
/// } else {
/// 	... process error ...
/// }
/// </example>
ClassMethod ValidateDocument(ByRef document As %XML.Document, encryptedKeys As %ListOfObjects(ELEMENTTYPE="%XML.Security.EncryptedKey")) As %Boolean
{
	Set ok=0
	For index=1:1:encryptedKeys.Count() {
		Set error=encryptedKeys.GetAt(index).ValidateElement(.document,"")
		If error="" {
			Set ok=1
			Quit
		}
	}
	
	Quit ok
}

/// Initialize will be called from InitializeForService in ReferenceList.
Method Initialize(service As %SOAP.WebBase, header As %SOAP.Security.Header, key As %Binary = "") As %Status [ Internal ]
{
	// Initialize from EncryptedKey, DerivedKeyToken or SecurityContextToken element
	If ..Key="" {
		If ..ReferenceOption=$$$SOAPWSReferenceDerivedKey {
			If $isobject(..KeyElement) {
				If ..KeyElement.Key="" {
					If ..Algorithm="" {
						If ..KeyElement.Length=(128/8) {
							Set ..Algorithm=$$$SOAPWSaes128cbc
						} ElseIf ..KeyElement.Length=(192/8) {
							Set ..Algorithm=$$$SOAPWSaes192cbc
						} Else {
							Set ..Algorithm=$$$SOAPWSaes256cbc
						}
					}
					Set sc=..KeyElement.InitializeKey(service,..Algorithm)
					If $$$ISERR(sc) Quit sc
				}
					
				If ..KeyElement.Implied {
					Do ..KeyInfo.KeyInfoClauseList.Clear()
					Do ..KeyInfo.KeyInfoClauseList.Insert(..KeyElement.SecurityTokenReference)
					Set ..KeyElement.SecurityTokenReference.Nonce=..KeyElement.Nonce
					Set ..KeyElement.SecurityTokenReference.Length=..KeyElement.Length
				}
				Set ..Key=..KeyElement.Key
			}
		} ElseIf $case(..ReferenceOption,$$$SOAPWSReferenceEncryptedKey:1,$$$SOAPWSReferenceSCT:1,$$$SOAPWSReferenceSCTIdentifier:1,:0) {
			If $isobject(..KeyElement) {
				If ..KeyElement.Key="" {
					Set sc=..KeyElement.InitializeKey(service,..Algorithm)
					If $$$ISERR(sc) Quit sc
				}
				Set ..Key=..KeyElement.Key
			}
		} ElseIf ..ReferenceOption=$$$SOAPWSReferenceEncryptedKeySHA1 {
			Set requestHeader=service.SecurityIn
			If $isobject(requestHeader) {
				Set element=requestHeader.FindEncryptedKey(0)
				If $isobject(element) {
					If element.Key="" {
						Set sc=element.InitializeKey(service)
						If $$$ISERR(sc) Quit sc
					}
					Set ..Key=element.Key
					Set ..Algorithm=element.Algorithm
					If element.CipherData'="" Do ..KeyInfo.SetIdentifier(element.CipherData.CipherValue)
				}
			}
		} ElseIf ..ReferenceOption="" {
			Set ..Key=key
		}
	}

	// Add Body reference if needed and validate either Body or Security element
	If ..EncryptedPart="" {
		If ..Type="" Set ..Type=$$$SOAPWSEncryptContent
	} Else {
		If '$isobject(..EncryptedPart) || '..EncryptedPart.%Extends("%SOAP.Security.Element") {
			$$$SOAPLogSecurity("    Encrypted part must be Body or a Security element")
			Quit $$$ERROR($$$WSSECURITYInvalidEncAlgo,"Encrypted part must be Body or a Security element")
		}
		If ..Type="" Set ..Type=$$$SOAPWSEncryptElement
	}
	
	// Validate that key exists and matches the algorithm
	Set error=..ValidateKeyAlgorithm()
	If error'="" {
		$$$SOAPLogSecurity("    Invalid Encryption method specified: "_error)
		Quit $$$ERROR($$$WSSECURITYInvalidEncAlgo,error)
	}

	Do ..SetEncryptionMethod(..Algorithm)

	// Indicate Security header must be rewritten.	
	Set header.IsEncrypted=1

	Quit $$$OK
}

/// Validate algorithm and key size
Method ValidateKeyAlgorithm() As %String [ Internal ]
{
	// Validate that key exists
	If ..Key="" {
		$$$SOAPLogSecurity("    Invalid Encryption method specified: No key specified.")
		Quit "No key specified"
	}

	// Check algorithm and compute key size
	Set keysize=$length(..Key)
	If ..Algorithm="" {
		If keysize=(256/8) {
			Set ..Algorithm=$$$SOAPWSaes256cbc
		} ElseIf keysize=(192/8) {
			Set ..Algorithm=$$$SOAPWSaes192cbc
		} ElseIf keysize=(128/8) {
			Set ..Algorithm=$$$SOAPWSaes128cbc
		} Else {
			Quit "Unexpected key size "_keysize
		}
	} Else {
		If $case(..Algorithm,$$$SOAPWSaes128cbc:0,$$$SOAPWSaes192cbc:0,$$$SOAPWSaes256cbc:0,$$$SOAPWSaes256gcm:0,:1) {
			Quit ..Algorithm
		}
		Set error=0
		If ..Algorithm=$$$SOAPWSaes256cbc {
			If keysize'=(256/8) Set error=1
		} ElseIf ..Algorithm=$$$SOAPWSaes192cbc {
			If keysize'=(192/8) Set error=1
		} ElseIf ..Algorithm=$$$SOAPWSaes128cbc {
			If keysize'=(128/8) Set error=1
		} ElseIf ..Algorithm=$$$SOAPWSaes256gcm {
			If keysize'=(256/8) Set error=1
		} Else {
			Set error=1
		}
		// If key specified, then use the specified key.
		If error {
			Quit ..Algorithm_"(Does not match key size "_keysize_")"
		}
	}

	Quit ""
}

/// Do the encryption for this EncryptedData element.
Method Encrypt(header As %SOAP.Security.Header) As %Status [ Internal ]
{
	If $isobject(..EncryptedPart) {
		Quit ..EncryptElement(..EncryptedPart,header)
	} Else {
		Quit ..EncryptBody(header)
	}
}

/// Encryption of a Security element.
Method EncryptElement(element As %SOAP.Security.Element, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	// Export the Security child element to a string.
	$$$SOAPLogSecurity("    Encrypt Security element ")
	$$$XMLUseLast
	Set header.SecurityNamespaces.CurrentNamespace=$$$SOAPWSSEns
	Set header.SecurityNamespaces.DefaultDefined=$$$SOAPWSSEns
	Set sc=element.XMLExport(,"literal"_$select(header.Base64LineBreaks:",base64linebreaks",1:""),header.SecurityNamespaces,,,,,,,,$get(%cspsoapmimeAttachments))
	Set header.SecurityNamespaces.CurrentNamespace=""
	Set header.SecurityNamespaces.DefaultDefined=""
	
	If $$$ISOK(sc) {
		// Encrypt the Security child element and fill in EncryptedData
		$$$XMLRewindSingle($$$XMLCurrentIndex)
		Set sc=..ComputeCipherData(0)
	}
	$$$XMLTruncate

	If $$$ISOK(sc) {
		// Replace Security child element with the EncryptedData element
		Set pos=header.GetElementPosition(element)
		$$$SOAPLogSecurity("    Encrypt Security element "_pos)
		If pos'="" {
			Set ..OriginalElement=element
			Do header.SecurityElement.SetAt($this,pos)
			/// Rewrite the Security header
			Set sc=header.UpdateSecurityHeader($get(%cspsoapmimeAttachments))
		}
	}

	Quit sc
}

/// Actual encryption of the SOAP Body.
Method EncryptBody(header As %SOAP.Security.Header) As %Status [ Internal ]
{
	// Encrypt the body	
	$$$SOAPLogSecurity("    Encrypt Body")
	$$$XMLRewindSingle(header.BodyBufferIndex)
	Set sc=..ComputeCipherData(0)
	
	If $$$ISOK(sc) {
		// Write the EncryptedData element to the block containing the body
		$$$XMLReplace(header.BodyBufferIndex)
		Set sc=..XMLExport(,"literal"_$select(header.Base64LineBreaks:",base64linebreaks",1:""),header.SecurityNamespaces)
	}
	
	Quit sc
}

/// Actual encryption of a stream
Method ComputeCipherData(stream As %FileBinaryStream) As %Status [ Internal ]
{
	Set sc=$$$OK

	Try {
		Set ivlen = $CASE(..Algorithm, $$$SOAPWSaes256gcm:12,:16)
		Set size=$select(stream=0:$$$XMLSize,1:stream.Size)
		Set IV=$system.Encryption.GenCryptRand(ivlen,..RequireBestEntropy)
		Set ..CipherData=##class(%XML.Security.CipherDataStream).%New()
		Set cipher=..CipherData.CipherValue
		Do cipher.Write(IV)
		if ..Algorithm = $$$SOAPWSaes256gcm {
			Do $System.Encryption.AESGCMEncryptInit(..Key,IV)
			While size>0 {
				Set inblock=$select(stream=0:$$$XMLRead(32000),1:stream.Read(32000))
				Set size=size-$length(inblock)
				Set outblock=$System.Encryption.AESGCMEncryptUpdate(inblock)
				Do cipher.Write(outblock)
			}
			Set tag = $System.Encryption.AESGCMEncryptResult()
			Do cipher.Write(tag)
		} else {
			While size>0 {
				Set inblock=$select(stream=0:$$$XMLRead(32000),1:stream.Read(32000))
				Set size=size-$length(inblock)
				Set padding=(size<=0)
				Set outblock=$System.Encryption.AESCBCEncrypt(inblock,..Key,IV,padding,0)
				Set IV=$E(outblock,*-15,*)
				Do cipher.Write(outblock)
			}
		}
		Do cipher.Rewind()

	} Catch ex {
		Set sc=ex.AsStatus()
		Do $system.Status.DecomposeStatus(sc,.err)
		$$$SOAPLogSecurity("    Encryption failed: "_err(1))
	}

	Quit sc
}

/// Reset the element.
Method Reset()
{
	Do ##super()
	
	Set ..IsBodyEncrypted=""
}

/// Validate and decrypt this EncryptedData element for SOAP Body.
ClassMethod Decrypt(document As %XML.Document, service As %SOAP.WebBase, ref As %XML.Security.DataReference, key As %Binary, mimeAttachments As %Net.MIMEPart = "") As %Status [ Internal ]
{
	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"
	Set error=""

	Set uri=ref.URI	
	If $extract(uri)'="#" {
		$$$SOAPLogSecurity("    DataReference URI must be fragment")
		Set error=unsupported
		Quit
	}
	Set encryptedDataId=$extract(uri,2,*)
	Set nodeId=document.GetNodeById(encryptedDataId)

	// Find the referenced EncryptedData element node and import.
	#dim node As %XML.Node = document.GetNode(nodeId)
	If (node.LocalName'="EncryptedData") || (node.Namespace'=..#NAMESPACE) {
		$$$SOAPLogSecurity("    Referenced element is not EncryptedData: "_node.LocalName)
		Quit invalid
	}

	If $get(%SOAPSecurityHeader)'="" {
		Set element=%SOAPSecurityHeader.GetElementById(encryptedDataId,.pos)
	} Else {
		Set element=""
	}
	// Check if EncryptedData is child of the SOAP Body element
	Set ref.SecurityPosition=""
	If $isobject(element) {
		$$$SOAPLogSecurity("    EncryptedData for Security element "_pos)
		Set ref.ElementType="Element"
		Set ref.SecurityPosition=pos
	} ElseIf node.MoveToParent(1) {
		If node.LocalName="Body" {
			Set ns=node.Namespace
			If (ns=$$$SOAP12ENVns) || (ns=$$$SOAPENVns) {
				Set ref.ElementType="Body"
			}
		} ElseIf node.MoveToParent(1),node.LocalName="Header" {
			Set ns=node.Namespace
			If (ns=$$$SOAP12ENVns) || (ns=$$$SOAPENVns) {
				Set ref.ElementType="Header"
			}
		}
		$$$SOAPLogSecurity("    EncryptedData for "_ref.ElementType)
		
		// Return to EncryptedData element
		Set node.NodeId=nodeId

		// Import referenced EncryptedData element.
		Set element=##class(%XML.Security.EncryptedData).%New()
		Set sc=element.XMLImport("EncryptedData","literal",..#NAMESPACE,document,nodeId,,,$select(mimeAttachments="":"",1:mimeAttachments.Parts))
		If $$$ISERR(sc) {
			Kill err
			Do $system.Status.DecomposeStatus(sc,.err)
			$$$SOAPLogSecurity("    Unable to import EncryptedData: "_err(1))
			Quit invalid
		}
		If ref.ElementType="Body" Set element.IsBodyEncrypted=1

	} Else {
		$$$SOAPLogSecurity("    EncryptedData is document root.")
		Quit invalid
	}

	// Validate EncryptedData element
	Set ref.EncryptedData=element
	Set error=element.Validate(key,service)
	If error'="" Quit error
	
	// Get the encrypted XML and decrypt it
	Try {
		Set encryptedXML=element.CipherData.CipherValue
		Set ivlen = $CASE(element.EncryptionMethod.Algorithm, $$$SOAPWSaes256gcm:12, :16)
		Do encryptedXML.Rewind()
		Set IV=encryptedXML.Read(ivlen)
		if element.EncryptionMethod.Algorithm = $$$SOAPWSaes256gcm {
			Set taglen = 16
			Set cipherlen = encryptedXML.Size-ivlen-taglen
			Set cur = 0
			Do $System.Encryption.AESGCMDecryptInit(element.Key,IV)
			Set xmlSerializeStream=##class(%GlobalBinaryStream).%New()
			while cur < cipherlen {
				Set inblock=encryptedXML.Read(cipherlen-cur)
				Set cur = cur + $Length(inblock)
				set outblock=$System.Encryption.AESGCMDecryptUpdate(inblock)
				Do xmlSerializeStream.Write(outblock)
			}
			Set tag = encryptedXML.Read(taglen)
			Set rv = $System.Encryption.AESGCMDecryptValidate(tag)
			if $$$ISERR(rv) Set error = "FailedCheck"
		} else {
			Set xmlSerializeStream=""
			Set padding=encryptedXML.AtEnd
			While 'padding {
				Set inblock=encryptedXML.Read()
				Set padding=encryptedXML.AtEnd
				Set outblock=$System.Encryption.AESCBCDecrypt(inblock,element.Key,IV,padding,0)
				Set IV=$E(inblock,*-15,*)
				If xmlSerializeStream="" {
					Set xmlSerializeStream=outblock
				} ElseIf $isobject(xmlSerializeStream) {
					Do xmlSerializeStream.Write(outblock)
				} Else {
					Set firstblock=xmlSerializeStream
					Set xmlSerializeStream=##class(%GlobalBinaryStream).%New()
					Do xmlSerializeStream.Write(firstblock)
					Do xmlSerializeStream.Write(outblock)
				}
			}
		}
	} Catch ex {
		$$$SOAPLogSecurity("    Symmetric key decryption failed: "_ex.DisplayString())
		Set error="FailedCheck"
	}
	If error'="" Quit error
	
	// Replace the EncryptedData node with the decrypted XML as characters 
	// and then serialize to XML.
	// Special hack in SerializeNode so that the invalid character string $c(1,2,3,4,5) means insert %xmlSerializeStream content
	// Should be at most one stream for the body.
	Set %xmlSerialize($increment(%xmlSerialize))=xmlSerializeStream
	Do node.ReplaceCharacter($c(1,2,3,4,5,%xmlSerialize))
	If $isobject(xmlSerializeStream) {
		Do xmlSerializeStream.Rewind()
	}
	
	Quit ""
}

/// Validate received EncryptedData and get key if needed
Method Validate(key As %Binary, service As %SOAP.WebBase) As %String [ Internal ]
{
	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"
	Set error=""

	If (..Type'=$$$SOAPWSEncryptContent) && (..Type'=$$$SOAPWSEncryptElement) {
		$$$SOAPLogSecurity("    Only #Content and #Element supported for EncryptedData: "_..Type)
		Quit unsupported
	}
	
	// Find key from encrypted key in initial request.
	Set keyinfo=..KeyInfo
	If keyinfo="",key="" {
		$$$SOAPLogSecurity("    no KeyInfo")
		Quit invalid
	}
	
	If keyinfo'="" {
		Set error=keyinfo.ValidateTokenRef(service)
		If error'="" Quit error

		Set error=keyinfo.ValidateKeyElement(service,.datakey,0)
		If error'="" Quit error

		If key="" {
			If datakey="" {
				// If no valid key material in EncryptedData or EncryptedKey.
				$$$SOAPLogSecurity("    KeyInfo child of EncryptedData has no valid key material.")
				Quit unsupported
			} Else {
				Set key=datakey
				// Remember the credentials used to encrypt.
				Set ..X509Credentials=keyinfo.X509Credentials
			}
		} ElseIf datakey'="" {
			If key'=datakey {
				// Different key material in EncryptedData and EncryptedKey.
				$$$SOAPLogSecurity("    EncryptedData specified different key than EncryptedKey.")
				Quit unsupported
			} Else {
				$$$SOAPLogSecurity("    EncryptedData and Encrypted both specify key.")
			}
		}

		If $isobject(keyinfo.X509Credentials) {
			Set ..KeyElement=keyinfo.X509Credentials
		}
	}
		
	Set ..Key=key
	
	// Validate that key exists and matches the algorithm
	Set ..Algorithm=..EncryptionMethod.Algorithm
	Set error=..ValidateKeyAlgorithm()
	If error'="" {
		$$$SOAPLogSecurity("    Unsupported Encryption method: "_error)
		Quit unsupported
	}

	// Make sure encrypted data is present	
	If (..CipherData="") || (..CipherData.CipherValue.Size<=0) {
		$$$SOAPLogSecurity("    no encrypted data")
		Quit unsupported
	}
	
	If ..CipherData.CipherReference'="" {
		$$$SOAPLogSecurity("    CipherReference is not supported for data")
		Quit invalid
	}
	
	Quit ""
}

/// Validate the security header element.
/// If invalid return an error code.
Method ValidateElement(document As %XML.Document, service As %SOAP.WebBase) As %String [ Internal ]
{
	$$$SOAPLogSecurity("EncryptedData not yet decrypted.")
	Quit ""
}

}
