/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// Super class for generated classes that represent WebMethods.
/// Subclass %SOAP.MsgDescriptor is the super class for all Service WebMethods.
/// Subclass %SOAP.ProxyDescriptor is the super class for all Client proxy WebMethods.
/// <br>
/// 
/// This class is used internally by InterSystems IRIS. You should not make direct
/// use of it within your applications. There is no guarantee made about either
/// the behavior or future operation of this class."
Class %SOAP.Descriptor Extends (%RegisteredObject, %XML.Adaptor) [ Abstract, Inheritance = right, System = 3 ]
{

/// NAMESPACE - specifies the XML namespace to be used for the XMLExport of the SOAP body's
///  request and response messages.  This parameter directly controls namespace usage by XMLExport.
Parameter NAMESPACE [ Internal ];

/// SOAPBODYUSE - specifies SoapBodyUse keyword for this web method.
Parameter SOAPBODYUSE [ Internal ];

/// SOAPBINDINGSTYLE - specifies SoapBindingStyle keyword for this web method.
Parameter SOAPBINDINGSTYLE [ Internal ];

/// TYPENAMESPACE specifies the XML namespace for the types used for
/// the method arguments and return types in this web client or web service
/// when importing a SOAP message.
Parameter TYPENAMESPACE [ Internal ];

/// XMLIMPORTNAMESPACE specifies the XML namespace for the method definition
/// in the WSDL for the web service when importing a SOAP message.
Parameter XMLIMPORTNAMESPACE [ Internal ];

/// Specifies if part elements of messages in the WSDL use type or element attribute.
/// XMLELEMENT defaults to 1 for "literal" WSDL and to 0 for "encoded" WSDL.
Parameter XMLELEMENT As BOOLEAN [ Internal ];

/// Name of result property
Parameter XMLRESULTNAME [ Internal ];

/// If = 1, then this is a one-way SOAP operation.
Parameter SOAPONEWAY [ Internal ];

/// Make the class parameters available a run time.
ClassMethod GetSoapParameters(ByRef bindingStyle As %String, ByRef bodyUse As %String, ByRef namespace As %String, ByRef xmlimportnamespace As %String, ByRef typeNamespace As %String, ByRef oneWay As %Boolean, ByRef xmlelement As %Boolean, ByRef bare As %Boolean) [ Internal ]
{
	Set bare=($zcvt(..#XMLMAPPING,"L")="sequence")
	Set bindingStyle=..#SOAPBINDINGSTYLE
	Set bodyUse=..#SOAPBODYUSE
	Set namespace=..#NAMESPACE
	Set xmlimportnamespace=..#XMLIMPORTNAMESPACE
	Set typeNamespace=..#TYPENAMESPACE
	Set oneWay=..#SOAPONEWAY
	Set xmlelement=..#XMLELEMENT
	If xmlelement="" Set xmlelement=(bodyUse="literal")
}

/// Determine if the result element in a web client response needs to be adjusted to always match.
ClassMethod NeedsAdjustment(ByRef ResultName As %String) As %Boolean [ CodeMode = generator, Internal, Private ]
{
	If $$$comClassKeyGet(%class,$$$cCLASSabstract) Quit $$$OK

	Set resultPropName=$$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLRESULTNAME",$$$cPARAMdefault)
	If (resultPropName'="") &&
	   ($$$comMemberKeyGet(%class,$$$cCLASSproperty,resultPropName,$$$cPROPcollection)="") {
		Set xmlname=$$$comMemberArrayGet(%class,$$$cCLASSproperty,resultPropName,$$$cPROPparameter,"XMLNAME")
		If xmlname'="" $$$GENERATE(" Set ResultName="""_xmlname_"""")
		$$$GENERATE(" Quit 1")
	} Else {
		$$$GENERATE(" Quit 0")
	}
	Quit $$$OK
}

/// Import the SOAP message -- request if a service and response if a client.
Method ImportSOAPMessage(messageName As %String, ResultName As %String, handler, message, messageChildlist, mimeAttachments As %Net.MIMEPart, checkRequired As %Boolean) As %Status [ Internal ]
{
	Set tree=handler.DocumentId

	#; Get parameters
	Do ..GetSoapParameters(.bindingStyle,.bodyUse,.ns,.xmlimportnamespace,.typeNamespace,.oneWay,.xmlelement,.bare)
	If checkRequired Set bodyUse=bodyUse_",checkrequired"
 
	If bare {
		#; Import message elements to Msg Class
		If message'="" {
			Set sc=..XMLImport($$$xmlaGetLocalName(tree,messageChildlist),bodyUse_",group","",handler,.message,,,mimeAttachments)
		} Else {
			Set sc=$$$OK
		}
 
		If $$$ISOK(sc) && (message'="") && (bodyUse'["encoded") {
			Set sc=$$$ERROR($$$SOAPUnexpectedElement,$$$xmlaGetLocalName(tree,messageChildlist))
		}

	} Else {
		If message="" Quit $$$ERROR($$$SOAPNoBody)

		#; Validate message node
		Set nsIndex=$select(xmlimportnamespace="":"",1:$$$xmlNamespaceToIndex(tree,xmlimportnamespace))
		If $case($$$xmlaGetNamespaceIndex(tree,messageChildlist),0:0,nsIndex:0,:1) {
			Quit $$$ERROR($$$XMLImportNSErr,messageName)
		}

		If ResultName="*" {
			// SOAP Request
			// Force SOAP request tag to be methodName for request handling
			// Force the result name to match the method class.
			$$$xmlSetLocalName(tree,message,messageName)
			$$$xmlaGetChildList(tree,message,messageChildlist,descriptor)
		} Else {
			// Response to SOAP Request
			If ..NeedsAdjustment(.ResultName) {
				// SOAP specifies that the name of message element and the name of the result
				// element (the first element of the message) should not be significant.
				$$$xmlaFirstChildElement(tree,message,messageChildlist,result,descriptor)
				If result'="" {
					If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE Quit $$$ERROR($$$ElementMismatch)
					// Force the result name to match the method class.
					$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
					If ($$$xmlaGetLocalName(tree,childlist)'="result") || ($$$xmlaGetNamespaceURI(tree,childlist)'=$$$SOAP12RPC) {
						Set originalName=$$$xmlaGetLocalName(tree,childlist)
						Set originalNamespaceIndex=$$$xmlaGetNamespaceIndex(tree,childlist)
						$$$xmlSetLocalName(tree,result,ResultName)
						$$$xmlSetNamespaceIndex(tree,result,"")
					}
				}
			}
		}

		#; Import message arguments to Msg Class
		Set sc=..XMLImport($$$xmlaGetLocalName(tree,messageChildlist),bodyUse,"",handler,message,,,mimeAttachments)
		If $data(originalName) {
			$$$xmlSetLocalName(tree,result,originalName)
			$$$xmlSetNamespaceIndex(tree,result,originalNamespaceIndex)
		}
	}

	Quit sc
}

}
