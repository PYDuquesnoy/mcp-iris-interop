/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsebXML

/// SOAP Service for ebXML
Class EnsLib.ebXML.Service.SOAPService Extends (EnsLib.SOAP.Service, EnsLib.ebXML.Service.AbstractService) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter USEBOTH = 1;

Parameter ADAPTER;

Parameter NAMESPACE = "http://www.oasis-open.org/committees/ebxml-msg/schema/msg-header-2_0.xsd";

Parameter SERVICENAME = "ebXML";

Parameter SOAPHEADERS = "AckRequested:EnsLib.ebXML.schema.msg.AckRequested,Acknowledgment:EnsLib.ebXML.schema.msg.Acknowledgment,ErrorList:EnsLib.ebXML.schema.msg.ErrorList,MessageHeader:EnsLib.ebXML.schema.msg.MessageHeader,MessageOrder:EnsLib.ebXML.schema.msg.MessageOrder,StatusRequest:EnsLib.ebXML.schema.msg.StatusRequest,StatusResponse:EnsLib.ebXML.schema.msg.StatusResponse,SyncReply:EnsLib.ebXML.schema.msg.SyncReply";

/// Default ebXML message type
Property MessageTypeClass As Ens.DataType.Class(EXTENDS = "EnsLib.ebXML.Message") [ InitialExpression = "EnsLib.ebXML.Message", Required ];

/// Default ebXML message type
Property MessageWithPayloadTypeClass As Ens.DataType.Class(EXTENDS = "EnsLib.ebXML.MessageWithPayload") [ InitialExpression = "EnsLib.ebXML.MessageWithPayload", Required ];

/// Flag to enable validation of the Manifest for messages with payload
Property ValidateManifest As %Boolean [ InitialExpression = 0 ];

/// Settings
Parameter SETTINGS As %String = "MessageTypeClass,MessageWithPayloadTypeClass,ValidateManifest";

Property SOAPAction As %String(MAXLEN = 512) [ Internal, Transient ];

Parameter ARGUMENTSTYLE = "message";

Method Manifest(pManifest As EnsLib.ebXML.schema.msg.Manifest(XMLNAME="Manifest")) As EnsLib.ebXML.schema.msg.Manifest(XMLNAME="Manifest") [ SoapAction = ebXML, WebMethod ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tRequest  As EnsLib.ebXML.Message
		#dim tResponse As EnsLib.ebXML.Message
		#dim tKey      As %String
		#dim tIndex    As %Integer
		#dim tHeader   As %SOAP.Header
		#dim tAttachments
	
	
		// Declare that we want custom code to write out the SOAP body
		Set ..WriteSOAPBodyMethod="outputBody"
	
		If $IsObject(pManifest) {
			#dim tRequestWithPayload As EnsLib.ebXML.MessageWithPayload
			
			Set tRequestWithPayload = ..CreateNewMessageWithPayload()
			
			// Insert the received Manifest object into the request
			Set tRequestWithPayload.Manifest = pManifest

			// Now, process the attachments
			For tIndex=1:1:..Attachments.Count() {
				#dim tContentId        As %String
				#dim tAttachment       As %Net.MIMEPart
				#dim tSerialAttachment As %Net.MIMESerialPart
			
				Set tAttachment       = ..Attachments.GetAt(tIndex)
				Set tContentId        = tAttachment.ContentId
				Set tSerialAttachment = ##class(%Net.MIMESerialPart).CloneFromMIMEPart(tAttachment)
			
				Do tRequestWithPayload.MIMEParts.SetAt(tSerialAttachment, tContentId)
			}
		
			// Validate attachments if specified
			If ..ValidateManifest {
				Set tSC = tRequestWithPayload.ValidateManifest()
				Quit:$$$ISERR(tSC)
			}
	
			Set tRequest = tRequestWithPayload
			
		} Else {
			
			// Construct a message without a payload
			Set tRequest = ..CreateNewMessage()
		}
		
		// Process the inbound SOAP headers
		Set tKey = ""
		For {
			Set tHeader = ..HeadersIn.GetNext(.tKey)
			Quit:tKey=""
			
			// Skip any headers that aren't derived from our SOAPHeader wrapper
			If 'tHeader.%Extends("EnsLib.ebXML.SOAPHeader") Continue
		
			// Add this SOAP header to our list	
			Do tRequest.Headers.SetAt(tHeader, tKey)
		}
		
		// Dispatch via the business service interface; we pass the SOAPAction as the hint in case it's useful
		Set tSC = ..dispatchToBusinessService(..%ConfigName, tRequest, ..SOAPAction, .tResponse)
		Quit:$$$ISERR(tSC)
		
		Do ..HeadersOut.Clear()
		Do ..ResponseAttachments.Clear()
	
		// Setup the response if there is one!
		If $IsObject($GET(tResponse)) {
			
			// Headers
			Set tKey=""
			For {
				Set tHeader = tResponse.Headers.GetNext(.tKey)
				Quit:tKey=""
				
				Do ..HeadersOut.SetAt(tHeader,tKey)
			}
		} Else {
			
			// No response from the application; switch to SOAP OneWay.
			// OneWay means we simply return 202 Accepted, Content-Length: 0
			Do ..ReturnOneWay()
		}

		// If the response has a payload, process that
		If $IsObject($GET(tResponse)) && tResponse.%IsA("EnsLib.ebXML.MessageWithPayload") {
			
			#dim tResponseWithPayload As EnsLib.ebXML.MessageWithPayload = tResponse
			
			// Attach any outbound attachments
			Set tKey=""
			For {
				Set tAttachment = tResponseWithPayload.MIMEParts.GetNext(.tKey)
				Quit:tKey=""
				
				// Process this attachment into the output
				Do ..ResponseAttachments.Insert(tAttachment)
			}
			
			// Set up the custom handler to write the Manifest as the SOAP Body
			Set %ebXMLResult = tResponseWithPayload.Manifest
			
		} Else {
			// We want an empty SOAP body
			Set %ebXMLResult = $$$NULLOREF
		}
	
	} While (0)
Exit
	If $$$ISERR(tSC) Set $ZT="" Do ..ReturnStatusFault(..#SERVICENAME,tSC)
	
	// We handle the output in outputBody
	Quit $$$NULLOREF
	
ItsATrap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method outputBody(pProxy As %SOAP.Descriptor, pTag As %String) As %Status
{
	Set $ZT="ItsATrap"
	
	#dim tBody As EnsLib.ebXML.schema.msg.Manifest
	#dim tNS   As %String
	
    Set tBody = $G(%ebXMLResult)
    If tBody="" Quit $$$OK
    
    Set tNS=##class(%XML.Namespaces).%New()
    Quit tBody.XMLExport(,"literal",tNS)
ItsATrap
	#dim tSC As %Status
 	Set $ZT="",tSC=$$$EnsSystemError
	Quit tSC
}

/// Get the method for this SoapAction
/// No matter what the SoapAction, we always want to call the Manifest method.
Method GetMethod(pAction As %String) As %String
{
	// Record the SOAPAction, but we always use Manifest
	Set ..SOAPAction = pAction
	Quit "Manifest"
}

/// Construct a new instance of an ebXML message
Method CreateNewMessage() As EnsLib.ebXML.Message [ CodeMode = expression ]
{
$ZOBJCLASSMETHOD(..MessageTypeClass,"%New")
}

/// Construct a new instance of an ebXML message with payload
Method CreateNewMessageWithPayload() As EnsLib.ebXML.MessageWithPayload [ CodeMode = expression ]
{
$ZOBJCLASSMETHOD(..MessageWithPayloadTypeClass,"%New")
}

/// Because we implement a delegate, we must "fix" %OnNew otherwise, we get the implementation from Ens.AbstractDelegate
/// and not the one from EnsLib.SOAP.Service which is required.
Method %OnNew(pConfigName As %RegisteredObject) As %Status
{
	Quit ##class(EnsLib.SOAP.Service)$this.%OnNew(.pConfigName)
}

/// The ProcessBodyNode method of %SOAP.WebService will be passed an %XML.Node
/// instance which is positioned at the child of the Body element of the SOAP 
/// which has the contents of the request body.
/// ProcessBodyNode will return the response message body in another character stream.<br>
/// 
/// The return value is 1 (true) if the body was processed and a response 
/// stream produced. If 0 is returned the %SOAP.MsgDescriptor class will be 
/// invoked as usual. If an error occurs during the processing of the request,
/// then a fault should be returned in the usual way using the ReturnFault method.<br>
/// 
/// The arguments to this method are:<br> 
///  action is the SOAPAction for the SOAP request.<br>
///  body is an %XML.Node instance for the contents of the SOAP request body.<br>
///  responseBody is a character stream to which the body of the SOAP response will be written.<br>  
/// <br>
Method ProcessBodyNode(action As %String, body As %XML.Node, ByRef responseBody As %CharacterStream) As %Boolean [ ServerOnly = 1 ]
{
	If '$IsObject(body) {		
		// Record the SOAPAction
		Set ..SOAPAction = action
		
		// Invoke Manifest() with no manifest (i.e. no payload)
		Do ..Manifest($$$NULLOREF)
		
		// NOTE: Since we use our own WriteBodyMethod, we take care of
		//       writing the response back to the client (and thus don't
		//       need to return the manifest here.
		
		Quit 1
	} Else {
		// Allow normal processing
		Quit 0
	}
}

}
