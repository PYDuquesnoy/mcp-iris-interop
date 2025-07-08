/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// OASIS Web Services Security SOAP header.
Class %SOAP.Security.Header Extends %SOAP.Header [ System = 4 ]
{

Parameter XMLFORMAT = "literal";

Parameter NAMESPACE = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";

Parameter XMLTYPE = "Security";

/// The actual XML namespace for this header
Property Namespace As %String(MAXLEN = "", XMLPROJECTION = "none");

/// Security error code when processing header 
Property ErrorCode As %String(MAXLEN = "", XMLPROJECTION = "none") [ Internal ];

/// The UsernameToken which was in an imported Security header
Property UsernameToken As %SOAP.Security.UsernameToken(XMLPROJECTION = "none");

/// If the Security header has a Signature, then the %XML.Security.Signature instance
/// instance corresponding to the signature is stored here. 
Property Signature As %XML.Security.Signature(XMLPROJECTION = "none");

/// The SecurityContextToken obtained from the received Security header while
/// the SecurityContextToken is being validated.  This token may be used in the response.
Property SecurityContextToken As %SOAP.WSSC.SecurityContextToken(XMLPROJECTION = "none");

/// The security elements projected to XML.
Property SecurityElement As list Of %SOAP.Security.Element(XMLPROJECTION = "element", XMLREF = 1, XMLTYPECONSTRAINT = "choice") [ Internal ];

/// The count of Signature and EncryptedKey element definitions to be output in the WS-Security header.
Property ElementCount As %Integer(XMLPROJECTION = "none") [ Internal ];

/// If true, then there is at least one Signature element.
Property IsSigned As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// If true, then the Body element is encrypted.
Property IsEncrypted As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// If IsSigned or IsEncrypted, then WSStream is the stream used to output the SOAP message.
Property WSStream As %RawString(XMLPROJECTION = "none") [ Internal ];

/// Set order of signing based on WS-Policy rules.
Property WSPolicyOrder As %Boolean(XMLPROJECTION = "none") [ Internal ];

/// Element index of main signature for WS-Policy Asymmetric binding
Property WSPolicySignatureIndex As %Integer(XMLPROJECTION = "none") [ Internal ];

/// Element index of body encryption element (ReferenceList or EncryptedKey) for WS-Policy Asymmetric binding.
Property WSPolicyEncryptionIndex As %Integer(XMLPROJECTION = "none") [ Internal ];

/// %XML.Namespaces instance to be used for exportign Security elements.
Property SecurityNamespaces As %XML.Namespaces(XMLPROJECTION = "none") [ Internal ];

/// The internal buffer index for the body
Property BodyBufferIndex As %Integer(XMLPROJECTION = "none") [ Internal ];

/// The internal buffer index for this Security header
Property HeaderBufferIndex As %Integer(XMLPROJECTION = "none") [ Internal ];

/// Save the SOAP prefix used for this header
Property SoapPrefix As %String(XMLPROJECTION = "none") [ Internal ];

/// Save the SOAP version used for this header
Property SoapVersion As %String(XMLPROJECTION = "none") [ Internal ];

/// If <property>Base64LineBreaks</property> is true (1), then remove line breaks
/// from base64 encoded XML output for all properties of type %Binary or %xsd.base64Binary.
/// The default is 0 which will be to not include line breaks.
/// If this property is specified, then it will override the BASE64LINEBREAKS parameter.
Property Base64LineBreaks As %Boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Return the default WS-Security namespace
ClassMethod GetSecurityNamespace() [ CodeMode = expression ]
{
..#NAMESPACE
}

/// Add an element to the Security header.<br>
/// If position is specified as a %SOAP.Security.Element subclass, then the element is added after this element.
/// Otherwise, position is the %Integer position at which to the element is added.
/// If position=-1, then the element is added after all elements.<br>
/// If position is not specified, the position depends on which type of element is added.
/// Token elements are those which do not specify signature (Signature) or encryption (ReferenceList or EncryptedKey
/// with ReferenceList) are added after all previously added token elements.
/// The exception is the Timestamp element always goes first.<br>
/// If any tokens which are to be encrypted are added,
/// they should be added after the EncryptedKey element is added and
/// should be postioned after the EncryptedKey specified as the position argument.<br>
/// Elements which specify signature (Signature) or encryption (ReferenceList or EncryptedKey
/// with ReferenceList) are added following all tokens elements and thus before all other non-token elements.<br>
/// This method replaces the deprecated methods AddToken and AddElement. 
/// There is no need to modify existing code, but if you choose to do so, 
/// you can simply replace references to AddToken and AddElement with 
/// references to AddSecurityToken. It is not necessary to adjust the argument lists.
Method AddSecurityElement(element As %SOAP.Security.Element, position = "") As %Status
{
	If $isobject(position) {
		Set integerPosition=..GetElementPosition(position)+1
	} Else {
		Set integerPosition=position
	}
	
	Set class=$classname(element)
	If ((class="%XML.Security.EncryptedKey") && (element.ReferenceList'="")) ||
	   (class="%XML.Security.Signature") ||
	   (class="%XML.Security.ReferenceList") ||
	   (class="%XML.Security.EncryptedData") {
		Do ..AddElement(element,integerPosition)
	} Else {
		Do ..AddToken(element,integerPosition)
	}

	Quit $$$OK
}

/// Add a token to the Security header.
/// - element is element to add<br>
/// - baseElement is optional element after which element is added.<br><br>
/// Timestamp element always goes first, followed by token in order added.
/// Signature and Encryption elements should not be added using this method.<br><br>
/// If any tokens which are to be encrypted are added,
/// they should be added after the EncryptedKey element is added and
/// should be postioned after the EncryptedKey specified as the baseElement argument.
Method AddToken(element As %SOAP.Security.Element, baseElement As %SOAP.Security.Element = "") [ Internal ]
{
	Set count=..SecurityElement.Count()
	If $isobject(baseElement) {
		Set pos=..GetElementPosition(baseElement)+1
	} Else {
		Set pos=baseElement
	}
	If pos'="" {
		If pos=-1 Set pos=count-..ElementCount+1
		Do ..SecurityElement.InsertAt(element,pos)
		If (pos-1)>(count-..ElementCount) {
			Set ..ElementCount=..ElementCount+1
		}
		Quit
	}

	If (count=0) || (..ElementCount=0) {
		Do ..SecurityElement.Insert(element)
		
	} ElseIf $zobjclass(element)["Timestamp" {
		If element.TimestampAtEnd {
			If $zobjclass(..SecurityElement.GetAt(count))["Timestamp" {
				Do ..SecurityElement.SetAt(element,count)
			} Else {
				Do ..SecurityElement.Insert(element)
			}
		} Else {
			If $zobjclass(..SecurityElement.GetAt(1))["Timestamp" {
				Do ..SecurityElement.SetAt(element,1)
			} Else {
				Do ..SecurityElement.InsertAt(element,1)
			}
		}
	} Else {
		Do ..SecurityElement.InsertAt(element,count-..ElementCount+1)
	}
}

/// Add a Signature, EncryptedKey or ReferenceList element to the Security header.
/// The signature, EncryptedKey or ReferenceList is inserted at the position indicated by the position argument
/// which defaults to following all tokens and thus before all other non-token elements.
/// If position=-1, then the element is added after all elements.
Method AddElement(element As %RegisteredObject, position As %Integer = "") [ Internal ]
{
	// If EncryptedData, then create and add a ReferenceList
	If $zobjclass(element)="%XML.Security.EncryptedData" {
		Set ref=##class(%XML.Security.DataReference).Create(element)
		Set element=##class(%XML.Security.ReferenceList).%New()
		Do element.Reference.Insert(ref)
	}
	
	// Add the element just after the tokens
	If position=-1 {
		Do ..SecurityElement.Insert(element)
	} Else {
		If position="" {
			Set position=..SecurityElement.Count()-..ElementCount+1
		}
		Do ..SecurityElement.InsertAt(element,position)
	}
	Set ..ElementCount=..ElementCount+1
}

/// Initialize all signature and encryption elements
/// Return true if there any signature or encyption elements.
Method Initialize(service As %SOAP.WebBase, status As %Status) As %Boolean [ Internal ]
{
	Set status=$$$OK
	If ..ElementCount=0 Quit 0
	Set ..IsEncrypted=0
	Set ..IsSigned=0

	$$$SOAPLogSecurity($c(13,10)_"---------------"_$c(13,10)_"Prepare Security header for output"_$select($get(service)="":"",1:": SOAP class="_$classname(service))_", method="_service.MethodName)

	// Initialize all elements
	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		Set status=element.InitializeForService(service,$this)
		If $$$ISERR(status) Quit
	}
	
	// Initialize unreferenced keys
	If $$$ISOK(status) {
		For i=1:1:..SecurityElement.Count() {
			Set element=..SecurityElement.GetAt(i)
			Set status=element.InitializeKey(service)
			If $$$ISERR(status) Quit
		}
	}
	
	Quit (..IsEncrypted || ..IsSigned)
}

/// Write the SOAP Security header to the current device.
Method WriteSecurityHeader(namespaces As %XML.Namespaces, soapPrefix As %String, soapVersion As %String, mimeAttachments As %Net.MIMEPart) As %Status [ Internal ]
{
	// Let lower levels know who we are.
	New %SOAPSecurityHeader
	Set %SOAPSecurityHeader=$this
	
	Set ..SecurityNamespaces=##class(%XML.Namespaces).%New()
	Do ..SecurityNamespaces.Copy(namespaces)
	Set ..SecurityNamespaces.CurrentNamespace=""
	Set ..SecurityNamespaces.DefaultNamespace=""
	Set ..SecurityNamespaces.ElementQualified=1
	Set ..SecurityNamespaces.OutputTypeAttribute=0
	// Force a dummy level to prevent reset of namespace stack.
	Set sc=..SecurityNamespaces.PushNode()
	If $$$ISERR(sc) Quit sc

	// Write the header
	If '$$$XMLIsWrite Set ..HeaderBufferIndex=$$$XMLCurrentIndex
	Set ..SoapPrefix=soapPrefix
	Set ..SoapVersion=soapVersion
	Set fmt="literal"
	If ..Base64LineBreaks Set fmt=fmt_",base64linebreaks"
	Set sc=..WriteHeader("Security",fmt,..Namespace,,soapPrefix,soapVersion,..SecurityNamespaces,mimeAttachments)
		
	Quit sc
}

///  Perform all signature and encryption operations
Method Perform() As %Status [ Internal ]
{
	Set sc=$$$OK
	If ..WSPolicyOrder {
		// For WS-Policy perform operations on elements in reverse order
		// except within set of signatures perform in normal order.
		For i=..SecurityElement.Count():-1:1 {
			Set element=..SecurityElement.GetAt(i)
			If $zobjclass(element)="%XML.Security.Signature" {
				Set j=i
				For {
					Set j=j-1
					Quit:j=0
					Set class=$zobjclass(..SecurityElement.GetAt(j))
					Quit:class="%XML.Security.EncryptedKey"
					Quit:class="%XML.Security.EncryptedData"
					Quit:class="%XML.Security.ReferenceList"
				}
				For k=j+1:1:i {
					Set element=..SecurityElement.GetAt(k)
					$$$SOAPLogSecurity("Element "_k_", "_$zobjclass(element))
					Set sc=element.Perform(0,$this)
					If $$$ISERR(sc) Quit
				}
				Set i=j+1
			} Else {
				$$$SOAPLogSecurity("Element "_i_", "_$zobjclass(element))
				Set sc=element.Perform(0,$this)
			}
			If $$$ISERR(sc) Quit
		}
	} Else {
		// Perform operations on tokens first
		Set end=..SecurityElement.Count()-..ElementCount
		For i=1:1:end {
			Set element=..SecurityElement.GetAt(i)
			$$$SOAPLogSecurity("Token "_i_", "_$zobjclass(element))
			Set sc=element.Perform(0,$this)
			If $$$ISERR(sc) Quit
		}
		If $$$ISERR(sc) Quit sc

		// By default perform operations on elements in reverse order
		Set end=end+1
		For i=..SecurityElement.Count():-1:end {
			Set element=..SecurityElement.GetAt(i)
			$$$SOAPLogSecurity("Element "_i_", "_$zobjclass(element))
			Set sc=element.Perform(0,$this)
			If $$$ISERR(sc) Quit
		}
	}
	
	// Restore the original unencrypted element.
	// The output buffer has already been updated.
	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		While element.OriginalElement'="" {
			Set element=element.OriginalElement
			Do ..SecurityElement.SetAt(element,i)
		}
	}
	
	Quit sc
}

/// Rewrite the Security header
Method UpdateSecurityHeader(mimeAttachments As %Net.MIMEPart = "") As %Status [ Internal ]
{
	$$$XMLReplace(..HeaderBufferIndex)
	Set ..SecurityNamespaces.CurrentNamespace=""
	Set fmt="literal"
	If ..Base64LineBreaks Set fmt=fmt_",base64linebreaks"
	Quit ..WriteHeader("Security",fmt,..Namespace,,..SoapPrefix,..SoapVersion,..SecurityNamespaces,mimeAttachments)
}

/// Reset all signature and encryption elements
Method Reset() [ Internal ]
{
	Set (..IsSigned,..IsEncrypted,..WSPolicyOrder)=0

	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		Do element.Reset()
	}
}

/// Find the first security element of the specified type after position pos and return the element.
/// Return "" if no element of the specified type is found.
/// Types are Timestamp, BinarySecurityToken, UsernameToken, Signature, SignatureConfirmation, EncryptedKey.
Method FindElement(type As %String, ByRef pos As %String) As %SOAP.Security.Element
{
	Set return="",pos=$get(pos,0)
	For i=pos+1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		If $extract($classname(element),*-$length(type)+1,*)=type {
			Set return=element
			Set pos=i
			Quit
		}
	}
	Quit return
}

/// Find the last security element of the specified type and return the element.
/// Return "" if no element of the specified type is found.
/// Types are Timestamp, BinarySecurityToken, UsernameToken, Signature, SignatureConfirmation, EncryptedKey.
Method FindLastElement(type As %String, ByRef pos As %String) As %SOAP.Security.Element
{
	Set return="",pos=$get(pos,0)
	For i=..SecurityElement.Count():-1:1 {
		Set element=..SecurityElement.GetAt(i)
		If $extract($classname(element),*-$length(type)+1,*)=type {
			Set return=element
			Set pos=i
			Quit
		}
	}
	Quit return
}

/// Find the key from an EncryptedKey element which corresponds to the EncryptedKeySHA1 argument.
/// Return the key if found, else "".
Method FindByEncryptedKeySHA1(encryptedKeySHA1 As %Binary) As %SOAP.Security.Element
{
	Set returnElement=""
	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		If $zobjclass(element)="%XML.Security.EncryptedKey" {
			Set enckey=element.GetEncryptedKeySHA1()
			If enckey=encryptedKeySHA1 Set returnElement=element
		}
	}
	Quit returnElement
}

/// Find an EncryptedKey element.
/// Return the key if found, else "".
Method FindEncryptedKey(usedAsSigningKey As %Boolean) As %XML.Security.EncryptedKey
{
	Set returnElement=""
	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		If $zobjclass(element)="%XML.Security.EncryptedKey" {
			If usedAsSigningKey,element.UsedAsSigningKey {
				Set returnElement=element
				Quit
			} ElseIf 'usedAsSigningKey,element.UsedAsEncryptionKey {
				Set returnElement=element
				Quit
			} ElseIf returnElement="" {
				Set returnElement=element
			}
		}
	}
	Quit returnElement
}

/// Remove the first security element of the specified type and return the element.
/// Return "" if no element of the specified type is found.
/// Types are Timestamp, BinarySecurityToken, UsernameToken, Signature, EncryptedKey.
Method RemoveElement(type As %String) As %RegisteredObject [ Internal ]
{
	Set return=..FindElement(type,.pos)
	If pos>0 Do ..SecurityElement.RemoveAt(pos)
	Quit return
}

/// Return true if the specified namespace is a valid namespace for a WS-Security header
ClassMethod IsSecurityNamespace(namespace As %String) As %Boolean [ CodeMode = expression ]
{
(namespace["secext") && ((namespace["http://schemas.xmlsoap.org/ws/") || (namespace["http://docs.oasis-open.org/wss/"))
}

ClassMethod ImportSecurityHeader(ByRef document As %XML.Document, securityIn As %String, Output headerObj As %SOAP.Security.Header, mimeAttachments As %Net.MIMEPart) As %Status [ Internal ]
{
	#; Find WS-Security header
	Set sc=$$$OK
	Set headerObj=""
	Set tree=document.DocumentId
	Set root=$$$xmlGetDocumentElement(tree)
	$$$xmlaGetChildList(tree,root,baseChildlist,descriptor)
	If ($$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE) || ($$$xmlaGetLocalName(tree,baseChildlist)'="Envelope") {
		Quit $$$ERROR($$$ElementMismatch)
	}
	Set soapVersion=""
	Set soapenv=$$$xmlNamespaceToIndex(tree,$$$SOAPENVns)
	If (soapenv'="") && ($$$xmlaGetNamespaceIndex(tree,baseChildlist)=soapenv) {
		Set soapVersion="1.1"
	} Else {
		Set soapenv=$$$xmlNamespaceToIndex(tree,$$$SOAP12ENVns)
		If (soapenv'="") && ($$$xmlaGetNamespaceIndex(tree,baseChildlist)=soapenv) {
			Set soapVersion="1.2"
		}
	}
	Set node=""
	$$$xmlaFirstChildElement(tree,root,baseChildlist,node,headerDescriptor)
	If node="" Quit $$$OK
	If $$$xmlaGetNodeType(tree,headerDescriptor)'=$$$xmlELEMENTNODE {
		Quit $$$ERROR($$$ElementMismatch)
	}
	#; Process headers
	$$$xmlaGetChildListFromDescriptor(tree,headerDescriptor,headerChildlist)
	If $$$xmlaGetLocalName(tree,headerChildlist)="Header" {
		#; Search for WS-Security header
		$$$xmlaFirstChildElement(tree,node,headerChildlist,element,descriptor)
		While element'="" {
			If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlWHITESPACENODE {
				#; Check the element
				If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE {
					Set sc=$$$ERROR($$$ElementMismatch)
					Quit
				}
				#; Process WS-Security header
				$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
				Set headerName=$$$xmlaGetLocalName(tree,childlist)
				If headerName="Security" {
					If securityIn="ignoreall",$data(mimeAttachments) {
						Set mimeAttachments=mimeAttachments
					} Else {
						Set mimeAttachments=..MTOMAttachments()
					}
					Set headerObj=##class(%SOAP.Security.Header).%New()
					// Get attributes and check for role/actor
					kill attrs
					$$$xmlaForEachAttribute(tree,childlist,o,attribute)
						Set attrname=$$$xmlaGetAttributeName(tree,attribute)
						Set attrs(attrname)=attribute
					$$$xmlaEndForEachAttribute(tree,childlist,o,attribute)
					If (soapVersion="1.2") || (soapVersion="") {
						If $data(attrs("role")) &&
						   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("role"))=soapenv) {
							Set headerObj.actor=$$$xmlaGetAttribute(tree,attrs("role"))
						}
					} 
					If (soapVersion="1.1") || (soapVersion="") {
						If $data(attrs("actor")) &&
						   ($$$xmlaGetAttrNamespaceIndex(tree,attrs("actor"))=soapenv) {
							Set headerObj.actor=$$$xmlaGetAttribute(tree,attrs("actor"))
						}
					}
					If headerObj.ImportHeader(headerName,"literal",.document,element,.sc,mimeAttachments,securityIn,"") {
						If $$$ISERR(sc) {
							If headerObj.Fault'="" Set fault=headerObj.Fault
							Quit
						} 
						
						Set %cspsoapSecurityHeader=headerObj
						Set securityNamespace=headerObj.Namespace
						Set token=headerObj.UsernameToken
						If token'="",token.Password.Type'["PasswordDigest" {
							Set username=token.Username
							Set password=token.Password.content
						}
						// Security header found
						Quit
					}
				}
			}
			$$$xmlaNextChildElement(tree,node,headerChildlist,element,descriptor)
		}
	}
	Quit sc
}

/// If MTOM, then return attachments for validation
ClassMethod MTOMAttachments() As %Net.MIMEPart [ Internal ]
{
	// Only check for MTOM if Mime content present
	Set isMTOM=0
	If $isobject($get(%request)),%request.Content="" {
		Set contenttype=%request.CgiEnvs("CONTENT_TYPE")
		If ($zcvt($piece(contenttype,";",1),"L")="multipart/related"),
		   '##class(%Net.HttpRequest).ParseContent($piece(contenttype,";",2,$length(contenttype,";")),.tmparray),
		   $get(tmparray("type"))="application/xop+xml" {
			Set isMTOM=1
			Set start=##class(%Net.MIMEPart).NormalizeContentId($get(tmparray("start")))
			Set startindex=$select(start="":1,1:0)
		}
	}
	If 'isMTOM Quit ""

	// Scan MIME parts and create mimeAttachments part which contains these parts
	Set mimeAttachments=##class(%Net.MIMEPart).%New()
	Set index=%request.NextMimeData("")
	While index'="" {
		Set mimeStream=%request.GetMimeData(index)
		Set part=##class(%Net.MIMEPart).%New(mimeStream)
		Do mimeAttachments.Parts.Insert(part)
		Set headers=$tr(mimeStream.GetAttribute("Headers"),$c(13),"")
		If headers'="" {
			Set len=$length(headers,$c(10))
			For i=1:1:len {
				Set header=$piece(headers,$c(10),i)
				Set name=$zcvt($zstrip($piece(header,":",1),"<>W"),"U")
				Set value=$zstrip($piece(header,":",2,$length(header,":")),"<>W")
				If name="CONTENT-ID" {
					Set part.ContentId=##class(%Net.MIMEPart).NormalizeContentId(value)
				} ElseIf name="CONTENT-LOCATION" {
					Set part.ContentLocation=##class(%Net.MIMEPart).NormalizeContentLocation(value)
				}
			}
		}
		
		If (startindex=0) && (start=part.ContentId) {
			Set startindex=index
		}
		Set index=%request.NextMimeData(index)
	}

	// Remove the XML body from the attachments list
	If startindex>0 {
		Set part=mimeAttachments.Parts.GetAt(startindex)
		Do mimeAttachments.Parts.RemoveAt(startindex)
	}
	
	Quit mimeAttachments
}

Method ImportHeader(headerName As %String, format As %String, ByRef handler As %XML.Document, message As %Integer, ByRef status As %Status, mimeAttachments As %Net.MIMEPart, securityIn As %String, service As %SOAP.WebClient) As %Boolean [ Internal ]
{
	// Remember who we are, for access in Validate method.
	New %SOAPSecurityHeader
	Set %SOAPSecurityHeader=$this
	
	Set tree=handler.DocumentId
	Set status=$$$OK,..ErrorCode="",..Fault=""
	$$$xmlaGetChildList(tree,message,messageChildlist,d)

	#; We expect one of the valid WS-Security namespaces
	#;   "http://www.docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";
	#;   "http://schemas.xmlsoap.org/ws/2003/06/secext";
	#;   "http://schemas.xmlsoap.org/ws/2002/07/secext";
	#;   "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";
	Set namespace=$$$xmlaGetNamespaceURI(tree,messageChildlist)
	If '..IsSecurityNamespace(namespace) Quit 0
	Set ..Namespace=namespace
	
	#; Only look at security headers with no actor
	If (..actor'="") &&
	   (..actor'="http://schemas.xmlsoap.org/soap/actor/next") &&
	   (..actor'="http://www.w3.org/2003/05/soap-envelope/role/next") &&
	   (..actor'="http://www.w3.org/2003/05/soap-envelope/role/ultimateReceiver") {
		Quit 0
	}
	
	Set status=..XMLImport($$$xmlaGetLocalName(tree,messageChildlist),"literal",namespace,handler,message,,,$select(mimeAttachments="":"",1:mimeAttachments.Parts))
	If $$$ISERR(status) {
		Do DecomposeStatus^%apiOBJ(status,.err)
		$$$SOAPLogSecurity("Invalid Security Header import: "_err(1))
		$$$SOAPLogSecurity("mime count= "_$select(mimeAttachments="":"",1:mimeAttachments.Parts.Count()))
		Set ..ErrorCode="InvalidSecurityToken"
		Set ..Fault=##class(%SOAP.WebService).MakeSecurityFault(..ErrorCode,..Namespace)
		Quit 1
	}
	
	If $get(securityIn)="" Set securityIn="ignore"
	If (securityIn'="ignore") && (handler.GetVersion()<2) {
		Do handler.AddWSSecurityIds()
	}
	
	// If refresh as part of Validate then just return.
	If securityIn="ignoreall" Quit 1
	
	#; Define namespaces for outputting Security elements.
	Set ..SecurityNamespaces=##class(%XML.Namespaces).%New()
	Do ..SecurityNamespaces.AddNamespace($$$SOAPWSSEns,"wsse")
	Do ..SecurityNamespaces.DefineAllNamespacePrefixes()
	Set ..SecurityNamespaces.CurrentNamespace=""
	Set ..SecurityNamespaces.DefaultNamespace=$$$SOAPWSSEns
	Set ..SecurityNamespaces.ElementQualified=1
	Set ..SecurityNamespaces.OutputTypeAttribute=0
	// Force a dummy level to prevent reset of namespace stack.
	Set sc=..SecurityNamespaces.PushNode()

	#; Validate Security child elements.
	Set ..SecurityContextToken=""
	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		Set class=$zobjclass(element)
		If (securityIn="ignore") && (class'["UsernameToken") Continue

		$$$SOAPLogSecurity("Validating security element "_i_": "_$piece(element,"@",2))
		// We special case signature and encryption only to avoid having to backport many element classes.
		If $case(class,"%XML.Security.Signature":1,"%SAML.Assertion":1,"%XML.Security.EncryptedKey":1,"%XML.Security.ReferenceList":1,:0) {
			Set ..ErrorCode=element.ValidateElement(.handler,service,.mimeAttachments)
		} Else {
			Set ..ErrorCode=element.ValidateElement(.handler,service)
		}
		If ..ErrorCode'="" Quit

		If class["UsernameToken" Set ..UsernameToken=element
		If ($$$ClassShortName(class)="Signature") && (..Signature="") Set ..Signature=element
	}
	
	If ..ErrorCode'="" {
		If $isobject(..ErrorCode) {
			Set ..Fault=..ErrorCode
			Set status=..Fault.faultcode
		} Else {
			Set ..Fault=##class(%SOAP.WebService).MakeSecurityFault(..ErrorCode,..Namespace)
			Set status=$$$ERROR($$$SOAPBadLogin,..ErrorCode)
		}
	}
	
	Quit 1
}

/// Find and return the security element which is specified by the id argument.
Method GetElementById(id As %String, Output pos As %Integer) As %RegisteredObject [ Internal ]
{
	Set matchedElement="",pos=0

	If id="" Quit id

	For i=1:1:..SecurityElement.Count() {
		Set element=..SecurityElement.GetAt(i)
		If '$isobject(element) Continue
		If (element.Id=id) || (($zobjclass(element)="%SAML.Assertion") && (element.SAMLID=id)) {
			Set matchedElement=element
			Set pos=i
			Quit
		}
	}
	Quit matchedElement
}

/// Find the position of the specified security element.
Method GetElementPosition(element As %SOAP.Security.Element) As %Integer [ Internal ]
{
	Set pos=""
	For i=1:1:..SecurityElement.Count() {
		If element=..SecurityElement.GetAt(i) Set pos=i Quit
	}
	Quit pos
}

}
