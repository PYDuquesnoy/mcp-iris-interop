/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// XML Encryption element.
Class %XML.Security.ReferenceList Extends %SOAP.Security.Element [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://www.w3.org/2001/04/xmlenc#";

Parameter ELEMENTQUALIFIED = 1;

Property Reference As list Of %RegisteredObject(XMLCHOICELIST = "%XML.Security.DataReference,%XML.Security.KeyReference", XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice");

/// The algorithm used for encryption
Property EncryptionAlgorithm As %String(XMLPROJECTION = "none") [ Internal ];

/// Credentials that stores key information for Body encryption.
Property X509Credentials As %RawString(XMLPROJECTION = "none") [ Internal ];

/// KeyInfo used to encrypt.
Property KeyInfo As %XML.Security.KeyInfo(XMLPROJECTION = "none") [ Internal ];

/// Add a reference to XML element using a %XML.Security.DataReference.
/// The reference may be created by using the ##class(%XML.Security.Reference).Create method.
Method AddReference(reference As %XML.Security.DataReference)
{
	Do ..Reference.Insert(reference)
}

/// Initialize
Method InitializeForService(service As %SOAP.WebBase, header As %SOAP.Security.Header, key As %Binary) As %Status [ Internal ]
{
	Set sc=$$$OK

	Set found=0
	For i=1:1:..Reference.Count() {
		Set ref=..Reference.GetAt(i)
		If $zobjclass(ref)="%XML.Security.DataReference" {
			Set found=1
			Set sc=ref.EncryptedData.Initialize(service,header,.key)
			If $$$ISERR(sc) Quit
		}
	}
	
	If $$$ISOK(sc),'found {
		$$$SOAPLogSecurity("    Encryption failed: No data reference found in ReferenceList")
		Quit $$$ERROR($$$WSSECURITYEncFailed,"No data reference found in ReferenceList")
	}
	
	Quit sc
}

/// Perform encryption
Method Perform(messageStream As %BinaryStream, header As %SOAP.Security.Header) As %Status [ Internal ]
{
	$$$SOAPTimer1Init(WSencrypt)
	Set sc=$$$OK
	For i=1:1:..Reference.Count() {
		Set ref=..Reference.GetAt(i)
		If $zobjclass(ref)="%XML.Security.DataReference" {
			Set sc=ref.EncryptedData.Encrypt(header)
			If $$$ISERR(sc) Quit
		}
	}
	$$$SOAPTimer1(WSencrypt,$select($data(%cspsoapservice):"s",1:"c")_"WSencrypt")
	Quit sc
}

/// Reset the element.
Method Reset() [ Internal ]
{
	Do ##super()
	
	For i=..Reference.Count():-1:1 {
		Set ref=..Reference.GetAt(i)
		If $zobjclass(ref)="%XML.Security.DataReference" {
			If ref.DoNotReuse {
				Do ..Reference.RemoveAt(i)
			} Else {
				Do ref.EncryptedData.Reset()
			}
		}
	}
}

/// Validate the security header element.
/// This method is also called to validate the ReferenceList in an EncryptedKey with the key as the third argument.
/// If invalid return an error code.
Method ValidateElement(ByRef document As %XML.Document, service As %SOAP.WebBase, mimeAttachments As %Net.MIMEPart = "", key As %Binary = "") As %String [ Internal ]
{
	$$$SOAPTimer1Init(WSdecrypt)
	If key="" $$$SOAPLogSecurity("Security Decrypt ReferenceList:")

	Set invalid="InvalidSecurityToken"
	Set unsupported="UnsupportedAlgorithm"
	Set securityElementFound=0
	New %xmlSerialize

	#dim ref As %XML.Security.DataReference
	Set ..EncryptionAlgorithm=""
	For i=1:1:..Reference.Count() {
		Set ref=..Reference.GetAt(i)
		If $zobjclass(ref)="%XML.Security.DataReference" {
			// Decrypt the EncryptedData element
			Set error=##class(%XML.Security.EncryptedData).Decrypt(document,service,ref,key,mimeAttachments)
			If error'="" Quit
			
			Set nodeId=document.GetNodeById($extract(ref.URI,2,*))
			#dim node As %XML.Node = document.GetNode(nodeId)
			Set node.NodeId = nodeId
			Set tValue=%xmlSerialize(%xmlSerialize)
			If ('$isobject(tValue)) {
				Set tValue = $ZCVT(tValue,"I","UTF8")
				Set %xmlSerialize(%xmlSerialize) = tValue
				Do node.ReplaceCharacter($c(1,2,3,4,5,%xmlSerialize))
			}

			$$$SOAPLogSecurity("    Reference "_i_" validated, pos="_ref.SecurityPosition)
			If ref.SecurityPosition'="" Set securityElementFound=1
			If ..EncryptionAlgorithm="" {
				Set ..EncryptionAlgorithm=ref.EncryptedData.Algorithm
			} ElseIf ..EncryptionAlgorithm'=0,..EncryptionAlgorithm'=ref.EncryptedData.Algorithm {
				Set ..EncryptionAlgorithm=0
			}
		}
	}
	If error'="" Quit error
	If ..EncryptionAlgorithm=0 Set ..EncryptionAlgorithm=""

	// Export the modified document to a stream	
	Set docid=document.DocumentId
	Set stream=##class(%GlobalCharacterStream).%New()
	Do ##class(%XML.ImportHandler).SerializeNode(docid,$$$xmlGetDocumentElement(docid),1,1,.stream,1)
	Do stream.Rewind()
	If $$$CheckSOAPLogSecurity,$$$CheckSOAPLogInput {
		If $isobject(service) {
			Set isService=service.%Extends("%SOAP.WebService")
			Do service.LogInput(isService,"*Decrypted message",stream)
			Do service.LogText("")
		} Else {
			Do ##class(%SOAP.WebBase).LogInput(1,"*Decrypted message",stream)
			Do ##class(%SOAP.WebBase).LogText("")
		}
	}
	
	// Import the stream containing the decrypted XML and replace the document
	Set reader=##class(%XML.Reader).%New()
 	Set reader.KeepWhitespace=1 // Need whitespace for XMLImport
	Set sc=reader.OpenStream(stream)
	If $$$ISERR(sc) {
		Kill err
		Do $system.Status.DecomposeStatus(sc,.err)
		$$$SOAPLogSecurity("    Unable to import Decrypted XML: "_err(1))
		Quit invalid
	}
	Set document=reader.Document

	// Need to refresh any decrypted elements
	If securityElementFound,$isobject(%SOAPSecurityHeader) {
		// Import the modified Security header
		Set sc=##class(%SOAP.Security.Header).ImportSecurityHeader(document,"ignoreall",.headerObj,mimeAttachments)
		If $$$ISERR(sc) {
			Kill err
			Do $system.Status.DecomposeStatus(sc,.err)
			$$$SOAPLogSecurity("    Unable to import Decrypted XML: "_err(1))
			Quit invalid
		}
		// Loop over references and replace original Security element with decrypted Security element
		For i=1:1:..Reference.Count() {
			Set ref=..Reference.GetAt(i)
			Set pos=ref.SecurityPosition
			If pos'="",$zobjclass(ref)="%XML.Security.DataReference" {
				Set newElement=headerObj.SecurityElement.GetAt(pos)
				Set newElement.WasEncrypted=1
				Set newElement.OriginalElement=%SOAPSecurityHeader.SecurityElement.GetAt(pos)
				$$$SOAPLogSecurity("    Security reference "_i_" "_$zobjclass(%SOAPSecurityHeader.SecurityElement.GetAt(pos))_"->"_$zobjclass(newElement))
				Do %SOAPSecurityHeader.SecurityElement.SetAt(newElement,pos)
			}
		}
		// Update NodeId of SignedInfo in all Signature elements
		For i=1:1:%SOAPSecurityHeader.SecurityElement.Count() {
			Set element=%SOAPSecurityHeader.SecurityElement.GetAt(i)
			Set class=$zobjclass(element)
			If class="%XML.Security.Signature" {
				Set newElement=headerObj.SecurityElement.GetAt(i)
				Set element.NodeId=newElement.NodeId
				If $isobject(element.SignedInfo) {
					Set element.SignedInfo.NodeId=newElement.SignedInfo.NodeId
				}
			} ElseIf class="%SAML.Assertion" {
				Set newElement=headerObj.SecurityElement.GetAt(i)
				Set element.NodeId=newElement.NodeId
				If $isobject(element.WSSecuritySignature) {
					Set element.WSSecuritySignature.NodeId=newElement.WSSecuritySignature.NodeId
					If $isobject(element.WSSecuritySignature.SignedInfo) {
						Set element.WSSecuritySignature.SignedInfo.NodeId=newElement.WSSecuritySignature.SignedInfo.NodeId
					}
				}
			}
		}
	}
	$$$SOAPTimer1(WSdecrypt,$select(($isobject($get(service)) && service.%Extends("%SOAP.WebClient")):"c",1:"s")_"WSdecrypt")
	Quit ""
}

}
