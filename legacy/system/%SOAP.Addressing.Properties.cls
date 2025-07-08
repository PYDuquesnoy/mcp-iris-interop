/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%systemInclude, %soap)

/// %SOAP.Addressing.Properties represents the message properties for WS-Addressing
Class %SOAP.Addressing.Properties Extends %RegisteredObject [ System = 4 ]
{

/// An absolute URI representing the address of the intended receiver of this message.
Property Destination As %String(MAXLEN = "");

/// Reference to the endpoint from which the message originated.
Property SourceEndpoint As %SOAP.Addressing.EndpointReference;

/// An endpoint reference for the intended receiver for replies to this message.
Property ReplyEndpoint As %SOAP.Addressing.EndpointReference;

/// An endpoint reference for the intended receiver for faults related to this message.
Property FaultEndpoint As %SOAP.Addressing.EndpointReference;

/// An absolute IRI that uniquely identifies the semantics implied by this message.
/// Should be SoapAction for SOAP 1.1.
Property Action As %String(MAXLEN = "");

/// An absolute IRI that uniquely identifies the message. 
Property MessageId As %String(MAXLEN = "");

/// A pair of values that indicate how this message relates to another message.
Property Relationship As %SOAP.Addressing.RelatesTo;

/// Corresponds to the value of the [reference parameters] property of the endpoint
/// reference to which the message is addressed.
Property ReferenceParameters As %XML.String(MAXLEN = "");

/// mustUnderstand is a multidimensional property which specifies the mustUnderstand attribute
/// for each of the headers that are created based on the %XML.AddresingProperties class.<br>
///    mustUnderstand(headerName) may be set to the %Boolean value of the mustUnderstand attribute to be produced for headerName.<br>
///    where headerName is "To", "From", "ReplyTo", "FaultTo", "Action", "MessageID", "RelatesTo".
Property mustUnderstand As %Boolean [ MultiDimensional ];

/// The actual namespace used for an imported WS-Addressing header.
/// Multiple namespaces are possible, since there exist multiple implementations
/// of WS-Addressing based on various submissions.
Property WSANamespace As %String [ Internal ];

/// An array of wsu:Id values for the defined WS-Addressing headers.
Property Ids As %String [ Internal, MultiDimensional ];

/// Get the WS-Addressing XML namespace.
/// Use the namespace of the imported headers if possible, otherwise use the 
/// newest specification.
Method Namespace() As %String [ CodeMode = expression ]
{
$select(..WSANamespace="":"http://www.w3.org/2005/08/addressing",1:..WSANamespace)
}

/// Return true if the specified namespace is a supported WS-Addressing namespace.
ClassMethod IsWSANamespace(namespace As %String) As %Boolean
{
	If namespace="http://schemas.xmlsoap.org/ws/2004/08/addressing" Quit 1
	If namespace="http://schemas.xmlsoap.org/ws/2004/03/addressing" Quit 1
	If namespace="http://www.w3.org/2005/08/addressing" Quit 1
	Quit 0
}

/// Get the default Properties for a SOAP request.
ClassMethod GetDefaultRequestProperties(destination As %String, action As %String, addressingNamespace As %String) As %SOAP.Addressing.Properties
{
	Set properties=..%New()
	If $get(addressingNamespace)'="" Set properties.WSANamespace=addressingNamespace
	Set properties.Destination=destination
	Set properties.Action=action
	Set properties.MessageId=..GetUniqueMessageId()
	Set properties.ReplyEndpoint=##class(%SOAP.Addressing.EndpointReference).GetAnonymousEPR()
	Quit properties
}

/// Get the default Properties for a SOAP response.
ClassMethod GetDefaultResponseProperties(requestProperties As %SOAP.Addressing.Properties, action As %String) As %SOAP.Addressing.Properties
{
	Set properties=..%New()
	Set properties.WSANamespace=requestProperties.WSANamespace
	Set properties.Destination=requestProperties.ReplyEndpoint.Address
	If properties.Destination="" {
		Set properties.Destination=##class(%SOAP.Addressing.EndpointReference).Anonymous(properties.WSANamespace)
	}
	If $get(action)="" Set action=requestProperties.Action_"Response"
	Set properties.Action=action
	Set properties.MessageId=..GetUniqueMessageId()
	Set properties.Relationship=##class(%SOAP.Addressing.RelatesTo).%New(requestProperties.MessageId)
	Set properties.ReferenceParameters=requestProperties.ReplyEndpoint.ReferenceParameters
	Quit properties
}

/// Get a unique InterSystems format message id.
ClassMethod GetUniqueMessageId() As %String [ CodeMode = expression ]
{
"urn:uuid:"_$system.Util.CreateGUID()
}

/// Get a unique wsu:Id value.
Method GetId(type As %String) As %String
{
	If $get(..Ids(type))="" {
		Set ..Ids(type)="Id-"_$system.Util.CreateGUID()
	}
	Quit ..Ids(type)
}

/// Define Id's for the defined WS-Addressing headers
Method GetIds(ByRef addressingIds) [ Internal ]
{
	Kill addressingIds

	If ..Action'="" {
		Set addressingIds("Action")=..GetId("Action")
	}

	If ..FaultEndpoint'="" {
		Set addressingIds("FaultTo")=..GetId("FaultTo")
	}

	If ..SourceEndpoint'="" {
		Set addressingIds("From")=..GetId("From")
	}
	
	If ..MessageId'="" {
		Set addressingIds("MessageID")=..GetId("MessageID")
	}

	If ..Relationship'="" {
		Set addressingIds("RelatesTo")=..GetId("RelatesTo")
	}

	If ..ReplyEndpoint'="" {
		Set addressingIds("ReplyTo")=..GetId("ReplyTo")
	}
	
	If ..Destination'="" {
		Set addressingIds("To")=..GetId("To")
	}
}

/// Output the SOAP headers that correspond to these properties.
Method WriteSOAPHeaders(namespaces As %XML.Namespaces, soapPrefix As %String, soapVersion As %String) As %Status [ Internal ]
{
	Set saveSuppress=namespaces.SuppressXmlns
	Set namespaces.SuppressXmlns=1
	Set saveDefault=namespaces.DefaultNamespace
	Set namespaces.DefaultNamespace=..Namespace()
	Set saveOTA=namespaces.OutputTypeAttribute
	Set namespaces.OutputTypeAttribute=0
	
	Set sc=$$$OK

	If ..Action'="" {
		Set hdr=##class(%SOAP.Addressing.Action).%New()
		Set hdr.%headerId=$get(..Ids("Action"))
		Set hdr.Action=..Action
		If $data(..mustUnderstand("Action")) {
			Set hdr.mustUnderstand=..mustUnderstand("Action")
		}
		Set sc=hdr.WriteHeader(,"literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}

	If $$$ISOK(sc) && (..FaultEndpoint'="") {
		Set ..FaultEndpoint.%headerId=$get(..Ids("FaultTo"))
		If $data(..mustUnderstand("FaultTo")) {
			Set ..FaultEndpoint.mustUnderstand=..mustUnderstand("FaultTo")
		}
		Set sc=..FaultEndpoint.WriteHeader("FaultTo","literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}

	If $$$ISOK(sc) && (..SourceEndpoint'="") {
		Set ..SourceEndpoint.%headerId=$get(..Ids("From"))
		If $data(..mustUnderstand("From")) {
			Set ..SourceEndpoint.mustUnderstand=..mustUnderstand("From")
		}
		Set sc=..SourceEndpoint.WriteHeader("From","literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}
	
	If $$$ISOK(sc) && (..MessageId'="") {
		Set hdr=##class(%SOAP.Addressing.MessageID).%New()
		Set hdr.%headerId=$get(..Ids("MessageID"))
		Set hdr.MessageID=..MessageId
		If $data(..mustUnderstand("MessageID")) {
			Set hdr.mustUnderstand=..mustUnderstand("MessageID")
		}
		Set sc=hdr.WriteHeader(,"literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}

	If $$$ISOK(sc) && (..Relationship'="") {
		Set ..Relationship.%headerId=$get(..Ids("RelatesTo"))
		If $data(..mustUnderstand("RelatesTo")) {
			Set ..Relationship.mustUnderstand=..mustUnderstand("RelatesTo")
		}
		Set sc=..Relationship.WriteHeader("RelatesTo","literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}

	If $$$ISOK(sc) && (..ReplyEndpoint'="") {
		Set ..ReplyEndpoint.%headerId=$get(..Ids("ReplyTo"))
		If $data(..mustUnderstand("ReplyTo")) {
			Set ..ReplyEndpoint.mustUnderstand=..mustUnderstand("ReplyTo")
		}
		Set sc=..ReplyEndpoint.WriteHeader("ReplyTo","literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}
	
	If $$$ISOK(sc) && (..Destination'="") {
		Set hdr=##class(%SOAP.Addressing.To).%New()
		Set hdr.%headerId=$get(..Ids("To"))
		Set hdr.To=..Destination
		If $data(..mustUnderstand("To")) {
			Set hdr.mustUnderstand=..mustUnderstand("To")
		}
		Set sc=hdr.WriteHeader(,"literal",,1,soapPrefix,soapVersion,namespaces)
		$$$XMLUseNext
	}
	
	If $$$ISOK(sc) && (..ReferenceParameters'="") {
		$$$XMLSetBuffer(..ReferenceParameters)
		$$$XMLWrite
		$$$XMLUseNext
	}
	
	Set namespaces.SuppressXmlns=saveSuppress
	Set namespaces.DefaultNamespace=saveDefault
	Do namespaces.RestoreOutputTypeAttribute(saveOTA)

	Quit sc
}

/// Import a WS-Addressing SOAP header
Method ImportHeader(headerName As %String, handler, message As %Integer, status As %Status) As %Boolean [ Internal ]
{
	Set namespace=..Namespace()
	Set tree=handler.DocumentId
	$$$xmlaGetChildList(tree,message,messageChildlist,d)
	Set name=$$$xmlaGetLocalName(tree,messageChildlist)

	#; Validate message node
	Set nsIndex=$$$xmlNamespaceToIndex(tree,namespace)
	If $$$xmlaGetNamespaceIndex(tree,messageChildlist)'=nsIndex Quit 0
	
	If name="To" {
		Set hdr=##class(%SOAP.Addressing.To).%New()
	} ElseIf name="From" {
		Set hdr=##class(%SOAP.Addressing.From).%New()
	} ElseIf name="ReplyTo" {
		Set hdr=##class(%SOAP.Addressing.ReplyTo).%New()
	} ElseIf name="FaultTo" {
		Set hdr=##class(%SOAP.Addressing.FaultTo).%New()
	} ElseIf name="Action" {
		Set hdr=##class(%SOAP.Addressing.Action).%New()
	} ElseIf name="MessageID" {
		Set hdr=##class(%SOAP.Addressing.MessageID).%New()
	} ElseIf name="RelatesTo" {
		Set hdr=##class(%SOAP.Addressing.RelatesTo).%New()
	} Else {
		Quit 0
	}
	
	
	#; Import message arguments to Msg Class
	Set status=hdr.XMLImport(name,"literal",namespace,handler,message)
	If $$$ISERR(status) Quit 1
	
	#; Assign property
	If name="To" {
		Set ..Destination=hdr.To
	} ElseIf name="From" {
		Set ..SourceEndpoint=hdr
	} ElseIf name="ReplyTo" {
		Set ..ReplyEndpoint=hdr
	} ElseIf name="FaultTo" {
		Set ..FaultEndpoint=hdr
	} ElseIf name="Action" {
		Set ..Action=hdr.Action
	} ElseIf name="MessageID" {
		Set ..MessageId=hdr.MessageID
	} ElseIf name="RelatesTo" {
		Set ..Relationship=hdr
	}
	Set ..Ids(name)=hdr.%headerId
	
	Quit 1
}

ClassMethod ImportAddressingHeaders(document As %XML.Document, headers As %String, baseChildlist As %String, Output addressing As %SOAP.Addressing.Properties) As %Status [ Internal ]
{
	#; Find WS-Addressing headers
	Set sc=$$$OK
	Set addressing=""
	Set tree=document.DocumentId
	Set element=""
	$$$xmlaFirstChildElement(tree,headers,baseChildlist,element,descriptor)
	While element'="" {
		If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlWHITESPACENODE {
			#; Check the element
			If $$$xmlaGetNodeType(tree,descriptor)'=$$$xmlELEMENTNODE {
				Set sc=$$$ERROR($$$ElementMismatch)
				Quit
			}
			#; Process WS-Addressing header
			$$$xmlaGetChildListFromDescriptor(tree,descriptor,childlist)
			Set headerName=$$$xmlaGetLocalName(tree,childlist)
			Set headerNamespace=$$$xmlaGetNamespaceURI(tree,childlist)
			If ##class(%SOAP.Addressing.Properties).IsWSANamespace(headerNamespace) {
				If addressing="" {
					Set addressing=##class(%SOAP.Addressing.Properties).%New()
					Set addressing.WSANamespace=headerNamespace
				}
				If addressing.ImportHeader(headerName,document,element,.sc) {
					If $$$ISERR(sc) Quit
				}
			}
		}
		$$$xmlaNextChildElement(tree,headers,baseChildlist,element,descriptor)
	}
	Quit sc
}

}
