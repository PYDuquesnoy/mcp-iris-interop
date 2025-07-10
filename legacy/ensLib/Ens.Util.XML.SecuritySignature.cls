/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, %soap)

/// Used to check SAML Assertion signature outside SOAP framework
Class Ens.Util.XML.SecuritySignature Extends %RegisteredObject [ System = 4 ]
{

/// Check signatures and expiration as specified by <var>pValSpec</var> <br/>
/// This does not validate the XML schema used for the SAML token.<br/>
/// <var>pValSpec</var> Specifies types of Assertion validation to perform: <ul>
/// <li>t - must contain a signed token </li>
/// <li>a - token must contain a signed Assertion. If not found the error text is "No Assertion" </li>
/// <li>u - token must contain an unsigned Assertion. If not found the error text is "No Unsigned Assertion".</li>
/// <li>If both a and u are specified then either a signed or unsigned assertion needs to be present.</li>
/// <li>s - combine with u - if unsigned assertions exist the s requires them be a children of signed elements.
/// Note: The Assertion might be wrapped in a structure that does not follow from schema.</li>
/// <li>r - require Assertions to contain both NotBefore and NotOnOrAfter time conditions.</li>
/// <li>v - verify Assertion signature and, if present, NotBefore/NotOnOrAfter conditions.
/// If option 'u' is specified and 'v' NotBefore/NotOnOrAfter conditions will also be checked.</li>
/// <li>o - validate other signed nodes within the assertion such as TimeStamp. Signed reference elements
/// with attribute name of ID or Id will be searched for.</li>
/// Set <var>pClockSkew</var> to the desired number of seconds
/// or to -1 to prevent NotBefore/NotOnOrAfter condition checking.<br/>
/// To carry out schema validation of the input stream create an instance of %XML.Reader, setting the appropriate properties for validation
/// and pass in as optional parameter pXMLReader</br>
ClassMethod ValidateSAML(pSAML As %GlobalCharacterStream, pValSpec As %String, pTrustedX509File As %String, pClockSkew As %String, ByRef pAttributes As %String, ByRef pAssertionAttributes As %String, Output pResults As %String, pXMLReader As %XML.Reader) As %Status
{

	#dim tSC=$$$OK
	#dim tSC1=$$$OK
	#dim e As %Exception.AbstractException
	#dim tXMLReader As %XML.Reader

	#dim tUnSignedAssertions As %String
	#dim tAssertionsWrappedInSigned As %String
	#dim tAssertionNodesSignedAndUnsigned As %String

	#dim tSigningErrors As %String

	#dim tError=""

	#dim i
	#dim tElementName
	#dim tNodeId
	#dim tLocalName

	#dim tHaveSignedAssertions
	#dim tHaveUnSignedAssertions

	Try {
		If ('$Data(pXMLReader,tXMLReader)#2) || ('$IsObject(tXMLReader)) || ('tXMLReader.%IsA("%XML.Reader")) {
			Set tXMLReader=##class(%XML.Reader).%New()
		}
		If $IsObject(pSAML) { Do pSAML.Rewind() Set tSC=tXMLReader.OpenStream(pSAML) }
		Else { Set tSC=tXMLReader.OpenString(pSAML) }
		If $$$ISERR(tSC) Quit

		#dim tSignedNodes As %String
		Set tSC = ..validateSignatures(tXMLReader,$Get(pTrustedX509File,$Get($$$EnsConfig("SAML","DefaultTrustedX509File"))),.tSignedNodes)
		If $$$ISERR(tSC) Quit

		#; For each tSignedNode that is not an Assertion look to see what Assertions it contains.
		Set tNodeId = $Order(tSignedNodes("NodeId",""),1,tLocalName)
		While (tNodeId'="") {
			If tLocalName'="Assertion" {
				Do ..findAllElementsWithName(/* Passing specific node */,"Assertion",tXMLReader.Document.GetNode(tNodeId),.tAssertionsWrappedInSigned)
				#; Save pointers from signature nodes to Assertion e.g. tSignedNodes("LocalName","Response","0,29","1,89")="0,29"
				Merge tSignedNodes("LocalName",tLocalName,tNodeId)=tAssertionsWrappedInSigned
			}
			Set tNodeId = $Order(tSignedNodes("NodeId",tNodeId),1,tLocalName)
		}
		Merge tAssertionNodesSignedAndUnsigned = tSignedNodes("LocalName","Assertion")

		#; Loop through all document looking for Assertions then remove those that are signed.
		Do ..findAllElementsWithName(tXMLReader.Document,"Assertion",/* Passing parent document */,.tUnSignedAssertions)
		Set tNodeId=$Order(tUnSignedAssertions(""))
		While tNodeId'="" {
			If ($Data(tSignedNodes("NodeId",tNodeId))) Kill tUnSignedAssertions(tNodeId)
			Set tNodeId=$Order(tUnSignedAssertions(tNodeId))
		}
		Merge tAssertionNodesSignedAndUnsigned = tUnSignedAssertions

		/*
			We now have possible arrays of
				tSignedNodes("LocalName",tSignedLocalName,tSignedNodeId)=""
				tSignedNodes("NodeId",tSignedNodeId)=tSignedLocalName
				tSignedNodes("Error",tSignedLocalName,tSignedNodeId)=<error> 
				tSignedNodes("SignatureError",tSignatureNodeId or ".")=<error>
				tAssertionsWrappedInSigned("nodeId") ;<- these may be signed or unsigned Assertions
				tUnSignedAssertions("nodeId")
		*/

		If '$Data(tSignedNodes("LocalName")) && (pValSpec["t") {
			Set tError = "No signatures found"
			Quit
		}

		#; Report general signing error or first signing error of an Assertion if v
		If (pValSpec["v") {
			Set tNodeId = $Order(tSignedNodes("SignatureError",""),1,tError)
			#;Found a basic signature error
			If (tError'="") Quit
			Set tNodeId = $Order(tSignedNodes("Error","Assertion",""),1,tError)
			#;Found an Assertion signed error
			If (tError'="") Quit
		}

		#; Report general signing error or first signing error of an non Assertion if o
		If (pValSpec["o") {
			Set tNodeId = $Order(tSignedNodes("SignatureError",""),1,tError)
			#;Found a basic signature error
			If (tError'="") Quit
			Set tLocalName = $Order(tSignedNodes("Error",""))
			While (tLocalName'="") {
				Set tNodeId = $Order(tSignedNodes("Error",tLocalName,""),1,tError)
				#;Found a non Assertion signed error
				If (tNodeId'="") && (tLocalName'="Assertion") Quit
				Set tError = ""
				Set tLocalName = $Order(tSignedNodes("Error",tLocalName))
			}
			If tError '= "" Quit
		}

		Set tHaveSignedAssertions = ''$Data(tSignedNodes("LocalName","Assertion"))
		Set tHaveUnSignedAssertions = ''$Data(tUnSignedAssertions)

		#; If both a and u specified then only report error for
		#; missing signed assertion if also missing an unsigned assertion.
		If (pValSpec["a") && ('tHaveSignedAssertions && ((pValSpec'["u") || 'tHaveUnSignedAssertions)){
			Set tError = "No Assertion"
			Quit
		}

		If (pValSpec["u") {
			If 'tHaveUnSignedAssertions {
				If (pValSpec'["a") {
					Set tError = "No Unsigned Assertion"
					If $Data(tSignedNodes("LocalName","Assertion")) Set tError = tError_" - Found Signed Assertion"
					Quit
				}
			} ElseIf (pValSpec["s") {
				Set tNodeId = $Order(tUnSignedAssertions(""))
				While (tNodeId'="") {
					If '$Data(tAssertionsWrappedInSigned(tNodeId)) {
						Set tError = "UnSigned Assertion not in a signed element"
						Quit
					}
					Set tNodeId = $Order(tUnSignedAssertions(tNodeId))
				}
			}
		}

		#; Check Assertion NotOnOrAfter/NotOnOrBefore Condition
 		If (pValSpec["v") && (pClockSkew'=-1){
			Set tSC = ..checkAssertionTimeCondition(tXMLReader.Document,(pValSpec["r")/*requires BothNotOn*/,pClockSkew,.tAssertionNodesSignedAndUnsigned,.tError)
			If $$$ISERR(tSC) || (tError'="") Quit
		}

	} Catch {

		Set tSC = $$$SystemError

	}

	If (tError'="") {
		Set tSC1=$$$ERROR($$$SOAPBadSignature,tError), tSC=$$$ADDSC(tSC1,tSC)
	} Else {
		#; Look for saught after attributes
		If $D(pAssertionAttributes) {
			Set pAttributes("SamlVersion") = $S(tXMLReader.Document.FindNamespace($$$SAMLns)>0:2,1:1)
			Set tSC1 = ..FindAssertionAttributes(pSAML,.pAssertionAttributes,.pAttributes)
			If $$$ISERR(tSC1) Set tSC=$$$ADDSC(tSC1,tSC)
		}
	}
	Kill pResults
	Merge pResults("SignedNodes")=tSignedNodes
	Merge pResults("WrappedAssertions")=tAssertionsWrappedInSigned
	Merge pResults("UnsignedAssertions")=tUnSignedAssertions

	Do:$IsObject(pSAML) pSAML.Rewind()
	Quit tSC
}

ClassMethod validateSignatures(pXMLReader As %XML.Reader, pCertFile As %String = "", Output pSignedNodes) As %Status
{
	/* Returns pSignedNodes with possible data of:
		pSignedNodes("LocalName",tSignedLocalName,tSignedNodeId)=""
		pSignedNodes("NodeId",tSignedNodeId)=tSignedLocalName
		pSignedNodes("Error",tSignedLocalName,tSignedNodeId)=<error> 
		pSignedNodes("SignatureError",tSignatureNodeId or ".")=<error>
	*/

	#dim tSC As %Status = $$$OK

	#dim tSignature As %XML.Security.Signature
	#dim tThisError As %String

	#dim tReferences As list Of %XML.Security.Reference
	#dim tRefCount

	#dim tSignedNodeId As %String
	#dim tSignedLocalName As %String
	#dim tSignatureNodeId As %String

	Kill pSignedNodes

	#; Need to be able to look for ID= as well in signed element that contains assertion element. 
	Do pXMLReader.Document.AddIDs()
	Do pXMLReader.Rewind()
	Do pXMLReader.Correlate("Signature","%XML.Security.Signature")
	While pXMLReader.Next(.tSignature,.tSC) {
		Quit:$$$ISERR(tSC)||'$IsObject(tSignature)
		Set tThisError = tSignature.ValidateElement(pXMLReader.Document,,,pCertFile)
		Set tReferences=tSignature.SignedInfo.Reference
		For tRefCount=1:1:tReferences.Count() {
			Set tSignedNodeId = tReferences.GetAt(tRefCount).ElementNodeId
			If tSignedNodeId'="" {
				Set tSignedLocalName = pXMLReader.Document.GetNode(tSignedNodeId).LocalName
				Set pSignedNodes("LocalName",tSignedLocalName,tSignedNodeId)=""
				Set pSignedNodes("NodeId",tSignedNodeId)=tSignedLocalName
				If (tThisError'="") Set pSignedNodes("Error",tSignedLocalName,tSignedNodeId)=tThisError 
			} Else {
				If (tThisError'="") {
					Set tSignatureNodeId = tSignature.NodeId
					If tSignatureNodeId="" Set tSignatureNodeId = "."
					Set pSignedNodes("SignatureError",tSignatureNodeId)=tThisError 
				}
			}
		}
		If (tReferences.Count()=0) && (tThisError'="") {
			Set tSignatureNodeId = tSignature.NodeId
			If tSignatureNodeId="" Set tSignatureNodeId = "."
			Set pSignedNodes("SignatureError",tSignatureNodeId)=tThisError 
		}
	}
	Quit tSC
}

/// Get Assertion node based on id from URI.  Return nodeId.
/// Deprecated.
Method GetNodeById(uri As %String, document As %XML.Document, node As %XML.Node, ByRef pSignedNode As %String) As %String [ Private ]
{
	#define SAML1ns "urn:oasis:names:tc:SAML:1.0:assertion"
	// Look for first Assertion node and check for SAML 1.1 and SAML 2.0 ID
	#dim nodeId = ""
	Set tAttrVal =""
	Set tFoundNodeId = ..FindFirstElementByName(document,"Assertion")
	If (tFoundNodeId '="") {
		Set node = document.GetNode(tFoundNodeId)
		If ((
				(node.Namespace=$$$SAMLns) &&
				(node.GetAttributeValue("ID")=uri)
			  ) ||
			((node.Namespace=$$$SAML1ns) &&
				(node.GetAttributeValue("AssertionID")=uri)
			)) {
			Set nodeId = tFoundNodeId
		}
	}
	If nodeId '= "" {
		Set node = document.GetNode(nodeId)
		Set pSignedNode = node.LocalName
		Set pSignedNode(pSignedNode,"nodeid")=nodeId
		$$$SOAPLogSecurity("    Id found for URI: "_uri)
	}
	Quit nodeId
}

/// Deprecated.
ClassMethod FindFirstElementByName(pDocument As %XML.Document, pElementSought As %String = "", pSpecificContainingNode As %XML.Node) As %String [ Internal ]
{
	Quit:(pElementSought = "") ""
	#dim tElement
	#dim tFound = 0
	#dim tAtEnd = 0

	#dim saughtNodeId
	#dim siblings
	#dim tLastSibling
	#dim tVal

	If '$Data(pSpecificContainingNode,tElement) Set tElement = pDocument.GetDocumentElement()
	While (('tFound) && ('tAtEnd)) {
		If tElement.NodeType = $$$xmlELEMENTNODE {
			If (tElement.LocalName = pElementSought) {
				Set tFound = 1 
				Set saughtNodeId = tElement.NodeId
				Continue
			}
		}
		If tElement.MoveToNextSibling(1) {
			Set siblings($I(siblings))=tElement.NodeId
			Do tElement.MoveToPreviousSibling(1)
		}
		If ((tElement.NodeType'=$$$xmlELEMENTNODE) || 'tElement.MoveToFirstChild(1)) {
			Kill tVal
			Set tLastSibling = $O(siblings(""),-1,tVal)
			If tLastSibling = "" {
				Set tAtEnd = 1
			} Else {
				Set tElement.NodeId = tVal
				Kill siblings(tLastSibling)
			}
		}
	}
	Quit $S(tFound:saughtNodeId,1:"")
}

ClassMethod FindAssertionAttributes(pSAML As %Stream.Object, ByRef pAssertionAttributes, Output pAttributes) As %Status
{
	#define SAML1ns "urn:oasis:names:tc:SAML:1.0:assertion"
	#define iscMAP "samlisc"
	#define SAML1nsMap $$$iscMAP_" "_$$$SAML1ns
	#define SAMLnsMap  $$$iscMAP_" "_$$$SAMLns

	#dim tSC=$$$OK
	#dim err As %Exception.AbstractException

	#dim tAssertAttribName
	#dim tSAMLDoc
	#dim tAttribValues

	Try {
		Do:$IsObject(pSAML) pSAML.Rewind()
		If pAttributes("SamlVersion")=2 {
			Set tSC=##class(%XML.XPATH.Document).CreateFromStream(pSAML,.tSAMLDoc,,,,,$$$SAMLnsMap)
		} Else {
			Set tSC=##class(%XML.XPATH.Document).CreateFromStream(pSAML,.tSAMLDoc,,,,,$$$SAML1nsMap)
		}
		If $$$ISERR(tSC) Quit
		Set tAssertAttribName=$O(pAssertionAttributes(""))
		While (tAssertAttribName'="") {
			Kill tAttribValues
			Set tSC=..GetAssertionAttribute(tSAMLDoc,$$$iscMAP,pAttributes("SamlVersion"),tAssertAttribName,.tAttribValues)
			If $$$ISERR(tSC) Quit
			If tAttribValues>0 {
				Merge pAssertionAttributes(tAssertAttribName)=tAttribValues
			} Else {
				Kill pAssertionAttributes(tAssertAttribName)
			}
			Set tAssertAttribName=$O(pAssertionAttributes(tAssertAttribName))
		}
	} Catch err {Set tSC=err.AsStatus()}

	Quit tSC
}

/// Retrieves SAML Assertion AttributeValue(s) from a SAML XPATH Doc for a given pAssertAttribName <br/>
ClassMethod GetAssertionAttribute(pSAMLDoc As %XML.XPATH.Document, pNSP As %String = "", pSAMLVersion As %Integer = 2, pAssertAttribName As %String, ByRef pAssertAttribValues) As %Status
{
	#define iscMAP "samlisc"
	#dim tSC=$$$OK
	#dim err As %Exception.AbstractException

	#dim tContext As %String
	#dim tExpression As %String

	#dim tResults As %XML.XPATH.ResultHandler
	#dim tResCount As %Integer
	#dim tRC As %Integer

	Try {
		Set tContext = "//samlisc:Assertion/samlisc:AttributeStatement/samlisc:Attribute"
		If (pSAMLVersion=2) {
			Set tExpression="samlisc:AttributeValue[(parent::node()[@Name='"_pAssertAttribName_"'])]/text()"
		} Else {
			Set tExpression="samlisc:AttributeValue[(parent::node()[@AttributeName='"_pAssertAttribName_"'])]/text()"
		}
		If (pNSP'=$$$iscMAP) {
			Set tContext=$REPLACE(tContext,$$$iscMAP_":",pNSP_":")
			Set tExpression=$REPLACE(tExpression,$$$iscMAP_":",pNSP_":")
		}
		Set tSC=pSAMLDoc.EvaluateExpression(tContext,tExpression,.tResults)
		If $$$ISERR(tSC) Quit
		Set tResCount=tResults.Count()
		For tRC=1:1:tResCount {
			Set pAssertAttribValues(tRC)=tResults.GetAt(tRC).Value
		}				
		Set pAssertAttribValues=tResCount
	} Catch err {Set tSC=err.AsStatus()}

	Quit tSC
}

ClassMethod findAllElementsWithName(pDocument As %XML.Document, pElementSought As %String = "", pSpecificContainingNode As %XML.Node, Output pFoundNodes) [ Internal ]
{
	If (pElementSought = "") Quit
	Kill pFoundNodes
	#dim tElement As %XML.Node
	#dim siblings
	#dim tVal
	#dim tLastSibling
	#; Only want to search children of pSpecificContainingNode
	#dim tSkipContainingNodeSiblings As %Boolean = 1
	If '$Data(pSpecificContainingNode,tElement) {
		Set tElement = pDocument.GetDocumentElement()
		Set tSkipContainingNodeSiblings = 0
	}
	#dim tContainingNodeId = tElement.NodeId
	#dim tAtEnd=0

	If tSkipContainingNodeSiblings {
		If 'tElement.MoveToFirstChild(1) Set tAtEnd = 1
	}

	While ('tAtEnd) {
		If tElement.NodeType = $$$xmlELEMENTNODE {
			If (tElement.LocalName = pElementSought) {
				If (tElement.NodeId'="") Set pFoundNodes(tElement.NodeId) = tContainingNodeId
			}
		}
		If tElement.MoveToNextSibling(1) {
			Set siblings($I(siblings))=tElement.NodeId
			Do tElement.MoveToPreviousSibling(1)
		}
		If ((tElement.NodeType'=$$$xmlELEMENTNODE) || 'tElement.MoveToFirstChild(1)) {
			Kill tVal
			Set tLastSibling = $O(siblings(""),-1,tVal)
			If tLastSibling = "" {
				Set tAtEnd = 1
			} Else {
				Set tElement.NodeId = tVal
				Kill siblings(tLastSibling)
			}
		}
	}
}

ClassMethod checkAssertionTimeCondition(pDocument As %XML.Document, pRequiresBothNotOn As %Boolean = 0, pClockSkew As %Integer = 0, ByRef pAssertionNodeIds, Output pError = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tAssertionNodeid = ""

	#dim node As %XML.Node

	Try {
		Set tAssertionNodeid = $Order(pAssertionNodeIds(""))
		While (tAssertionNodeid '="") {
			Set node = pDocument.GetNode(tAssertionNodeid)
			Set tSC = ..checkOneTimeCondition(node,pRequiresBothNotOn,pClockSkew,.pError)
			If $$$ISERR(tSC) || (pError'="") Quit
			Set tAssertionNodeid = $Order(pAssertionNodeIds(tAssertionNodeid))
		}
	} Catch e {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

ClassMethod checkOneTimeCondition(pNode As %XML.Node, pRequiresBothNotOn As %Boolean = 0, pClockSkew As %Integer = 0, Output pError As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException

	#dim tNow = $$$timeUTC
	#dim tPassedTimeCondition = 1
	#dim tNotOnOrAfter=""
	#dim tNotBefore=""

	Try {
		If pNode.MoveToFirstChild(1) {  ; First Assertion element
			Do {
				If (pNode.LocalName="Conditions") {
					Set tNotOnOrAfter = pNode.GetAttributeValue("NotOnOrAfter")
					Set:tNotOnOrAfter'=""&&($$$timeDiff($TR(tNotOnOrAfter,"TZ"," "),tNow)+pClockSkew<=0) tPassedTimeCondition=0 
					Quit:'tPassedTimeCondition
					Set tNotBefore = pNode.GetAttributeValue("NotBefore")
					Set:tNotBefore'=""&&($$$timeDiff($TR(tNotBefore,"TZ"," "),tNow)-pClockSkew>0) tPassedTimeCondition=0
					Quit
				}
			} While pNode.MoveToNextSibling(1)
		}
		If 'tPassedTimeCondition {
			Set pError = "Failed NotBefore/NotOnOrAfter ("_tNotBefore_"/"_tNotOnOrAfter_") date time verification with clock skew of "_pClockSkew_" seconds"
		} ElseIf pRequiresBothNotOn && ((tNotBefore="")||(tNotOnOrAfter="")) {
			Set pError = "NotBefore/NotOnOrAfter Condition attributes not present in Assertion"
		}
	} Catch e {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

}
