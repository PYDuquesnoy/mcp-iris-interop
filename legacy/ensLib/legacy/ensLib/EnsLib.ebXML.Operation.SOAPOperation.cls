/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXML)

/// ebXML outbound SOAP operation
Class EnsLib.ebXML.Operation.SOAPOperation Extends (Ens.BusinessOperation, EnsLib.ebXML.Operation.AbstractOperationDelegate) [ Inheritance = right, ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.SOAP.OutboundAdapter";

Parameter INVOCATION = "Queue";

/// Web services client class
Parameter WEBSERVICECLIENTCLASS As %String = "EnsLib.ebXML.Operation.SOAPServiceClient";

/// Custom SOAPAction header (defaults to ebXML)
Property CustomSOAPAction As %String(MAXLEN = 512);

/// Default ebXML message type
Property MessageTypeClass As Ens.DataType.Class(EXTENDS = "EnsLib.ebXML.Message") [ InitialExpression = "EnsLib.ebXML.Message", Required ];

/// Default ebXML message type
Property MessageWithPayloadTypeClass As Ens.DataType.Class(EXTENDS = "EnsLib.ebXML.MessageWithPayload") [ InitialExpression = "EnsLib.ebXML.MessageWithPayload", Required ];

/// Name of a class that implements the EnsLib.ebXML.Operation.AbstractOperationDelegate interface that we can call to do routing
Property OperationDelegateClass As Ens.DataType.Class(EXTENDS = "EnsLib.ebXML.Operation.AbstractOperationDelegate");

/// Flag to enable validation of the Manifest for messages with payload
Property ValidateManifest As %Boolean [ InitialExpression = 0 ];

/// Flag to convert an ebXML ErrorList into a %Status
Property HandleErrorListAsFatal As %Boolean [ InitialExpression = 1 ];

/// Allow HTTP 202 response to have content (note: this is non-standard)
Property Allow202WithContent As %Boolean [ InitialExpression = 1 ];

Property OperationDelegate As EnsLib.ebXML.Operation.AbstractOperationDelegate [ InitialExpression = {$this} ];

Parameter SETTINGS As %String = "CustomSOAPAction,OperationDelegateClass,MessageTypeClass,MessageWithPayloadTypeClass,ValidateManifest,Allow202WithContent,HandleErrorListAsFatal,-WebServiceClientClass";

Parameter OPERATIONDELEGATE As %String = "EnsLib.ebXML.Operation.AbstractOperationDelegate";

/// Cached copy of the "official" WebServiceURL setting
Property initialWebServiceURL As %String(MAXLEN = 1024) [ Internal, Private ];

/// Send an ebXML message to a remote MHS via an HTTP POST operation (note that since ebXML messages are packaged
/// in a SOAP wrapper, this will look like a web service request, although it's technically not).  Depending on
/// the presence of a SyncReply SOAP header, we may get a response from the remote MHS, or just nothing.
Method SendMessage(pRequest As EnsLib.ebXML.Message, ByRef pResponse As EnsLib.ebXML.Message) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tClient         As %SOAP.WebClient
		#dim tKey            As %String
		#dim tMimePart       As %Net.MIMEPart
		#dim tHeader         As %SOAP.Header
		#dim tManifestIn     As EnsLib.ebXML.schema.msg.Manifest
		#dim tManifestOut    As EnsLib.ebXML.schema.msg.Manifest
		#dim tURL            As %String
		#dim tSOAPAction     As %String
		#dim tStatusInfo
		

		// Assume no response
		Set pResponse       = $$$NULLOREF
		
		// Set up to call the web service
		Set tManifestIn     = $$$NULLOREF
		Set tManifestOut    = $$$NULLOREF

		// Determine the SOAP action to use
		Set tSOAPAction     = $CASE(..CustomSOAPAction,"":$$$EnsebXMLSOAPAction,:..CustomSOAPAction)
		
		// Use the original values for the timeout & retry interval from the settings
		Set tURL            = ..initialWebServiceURL

		If $IsObject(..OperationDelegate) {
			// Invoke the delegate to determine the URL and the SOAP action for this message
			Set tSC = ..OperationDelegate.RouteMessageToTargetMHS($this, pRequest, .tURL, .tSOAPAction)
			Quit:$$$ISERR(tSC)
		}

		// Validation ...
		If (tURL="") || (tSOAPAction="") {
			Set tSC = $$$EnsError($$$EnsebXMLErrUnableToRouteMessage,$classname(pRequest)_"["_pRequest.%Id()_"]")
			Quit
		}
		
		// Set up the target URL
		Set ..Adapter.WebServiceURL = tURL
		
		// We need direct access to the %SOAP.WebClient instance in order to process headers and attachments
		Set tClient = ..Adapter.%Client
		Set tClient.CustomSOAPAction = tSOAPAction
		Set tClient.HttpAccept202 = ..Allow202WithContent
		
		Do tClient.Attachments.Clear()
		Do tClient.ResponseAttachments.Clear()
		Do tClient.HeadersOut.Clear()
		Do tClient.HeadersIn.Clear()
		
		// Inject any SOAP headers
		Set tKey = ""
		For {
			Set tHeader = pRequest.Headers.GetNext(.tKey)
			Quit:tKey=""
		
			Do tClient.HeadersOut.SetAt(tHeader, tKey)	
		}

		// If this is a payload message, add any MIME attachments
		If pRequest.%IsA("EnsLib.ebXML.MessageWithPayload") {
			
			#dim tRequestWithPayload As EnsLib.ebXML.MessageWithPayload = pRequest
			
			// Attach any outbound attachments
			Set tKey = ""
			For {
				Set tMimePart = tRequestWithPayload.MIMEParts.GetNext(.tKey)
				Quit:tKey=""

				// Ensure the content length is present
                Do tMimePart.SetHeader("Content-Length",tMimePart.Body.SizeGet())
		
				// Process this attachment into the output
				Do tClient.Attachments.Insert(tMimePart)
			}
			
			// We'll need to send the Manifest out to the remote MHS
			Set tManifestOut = tRequestWithPayload.Manifest
		}
		
		// An ebXML web service can respond with:
		// 		1) Nothing (i.e. Content-Length: 0) which means the message was accepted.
		//			NOTE: This could return either 200 or 202 HTTP status
		//  	2) A message with a SOAP:Header, but no SOAP:Body (e.g. an Acknowledgement)
		//			NOTE: This must be a 200 HTTP status, NOT a 202
		//  	3) A complete message with headers, body and possibly MIME attachments
		//			NOTE: This must be a 200 HTTP status
		// If we're sending a SyncReply, we get #3, if we're asking for an Ack, we'll get #2
		// Otherwise, we could either get #1 or #3 (if the MSH gives an immediate response).

		// Invoke the method expecting a complete response.  Note that if tManifestOut is null,
		// then the SOAP client will not send a SOAP body.
		Set tSC = ..Adapter.InvokeMethod("Manifest", .tManifestIn, tManifestOut)
		If $$$ISOK(tSC) {
			
			If $IsObject(tManifestIn) {
				// This is case 3. We appear to have received a synchronous response with payload
				Set pResponse = ..CreateNewMessageWithPayload()
			
				// If we got a Manifest, store it and process any attachments
				Set pResponse.Manifest = tManifestIn
			
				Set tKey = ""
				For {
					Set tMimePart = tClient.ResponseAttachments.GetNext(.tKey)
					Quit:tKey=""
			
					#dim tContentId        As %String
					#dim tSerialAttachment As %Net.MIMESerialPart
			
					Set tContentId = tMimePart.ContentId
					Set tSerialAttachment = ##class(%Net.MIMESerialPart).CloneFromMIMEPart(tMimePart)
			
					Do pResponse.MIMEParts.SetAt(tSerialAttachment, tContentId)
				}
				
				// Validate the manifest by calling pResponse.ValidateManifest() if specified
				If ..ValidateManifest {
					Set tSC = pResponse.ValidateManifest()
					Quit:$$$ISERR(tSC)
				}
				
			} Else {
				// Case 1 (202 with headers) or 2: Empty manifest, with SOAP headers
				If tClient.HeadersIn.Count() > 0 {
					// NOTE: For a 202 with headers, Allow202WithContent must be set
					Set pResponse = ..CreateNewMessage()
				} // Otherwise, 202/OneWay with no headers
			}
			
		} Else {
			// Inspect the error to determine if we have case 1 or 2.  If so, reset the error
			// so we don't inadvertantly report it.
			Do $system.Status.DecomposeStatus(tSC,.tStatusInfo)
			
			#dim tStatus As %String = tStatusInfo(1,"code")
			#dim tParam  As %String = $GET(tStatusInfo(1,"param",1))
	
			If ((tStatus = $$$ERRORCODE($$$SOAPUnexpectedStatus)) && (tParam="202")) ||
				(tStatus = $$$ERRORCODE($$$SOAPNoResponseBody)) {
				// Case 1: Empty response, one of:
				//				a) 200 OK with Content-Length: 0
				//				b) 202 Accepted (must not have content as per WS-I sec 4.3.6)
				//				   unless setting Allow202WithContent is set.
				Set pResponse = $$$NULLOREF
				Set tSC       = $$$OK
				
			} ElseIf (tStatus = $$$ERRORCODE($$$SOAPNoBody)) {
				// Case 2: 200 OK + Empty manifest, SOAP headers are present
				Set pResponse = ..CreateNewMessage()
				Set tSC       = $$$OK
				
			} Else {
				// This is a real error, must be passed back to the caller for handling
				Quit
			}
		}

		If $IsObject(pResponse) {		
			// Process any returning SOAP headers
			Set tKey = ""
			For {
				Set tHeader = tClient.HeadersIn.GetNext(.tKey)
				Quit:tKey=""

				// Skip any headers that aren't derived from our SOAPHeader wrapper
				If 'tHeader.%Extends("EnsLib.ebXML.SOAPHeader") Continue
			
				Do pResponse.Headers.SetAt(tHeader, tKey)
			}
			
		} /// Otherwise, no response from the remote MHS

		If $IsObject(..OperationDelegate) {
			// Invoke the delegate to process this response message
			Set tSC = ..OperationDelegate.ProcessTargetMHSResponse($this, pRequest, .pResponse)
			Quit:$$$ISERR(tSC)
		}
		
		// If HandleErrorListAsFatal is set, then convert an ErrorList into a failed %Status
		If $IsObject(pResponse),..HandleErrorListAsFatal {
			Set tSC = pResponse.MessageErrorStatus()
			Quit:$$$ISERR(tSC)
			
			// Note: This could cause a retry if FailureTimeout is non-zero.
		}

		// We're done!

	} While (0)
Exit
	// Set ..Retry appropriately, because we ignore some SOAP errors, we
	// must set or clear ..Retry each time.
	Set ..Retry = $$$ISERR(tSC)
	
	Quit tSC
Trap
	Set $ZT="",tSC=$S($ZE["ZSOA":%objlasterror,1:$$$EnsSystemError)
	Goto Exit
}

/// This user callback method is called just after %OnNew()
Method OnInit() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		Set tSC = ##super()
		Quit:$$$ISERR(tSC)

		// Make copies of these settings
		Set ..initialWebServiceURL  = ..Adapter.WebServiceURL

		Set %objlasterror = $$$OK
		
		// If the setter for this property fails, then it'll set %objlasterror
		Set ..Adapter.WebServiceClientClass = ..#WEBSERVICECLIENTCLASS
		If $$$ISERR($G(%objlasterror,$$$OK)) Set tSC=%objlasterror Quit
		
		// Construct the delegate (if specified)
		Set ..OperationDelegate = ##class(Ens.AbstractDelegate).InitializeDelegate(..OperationDelegateClass,..#OPERATIONDELEGATE,$this,.tSC)
		Quit:$$$ISERR(tSC)
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Because we implement a delegate, we must "fix" %OnNew otherwise, we get the implementation from Ens.AbstractDelegate
/// and not the one from Ens.Host which is required.
Method %OnNew(pConfigName As %RegisteredObject) As %Status
{
	Quit ##class(Ens.BusinessOperation)$this.%OnNew(.pConfigName)
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.ebXML.Message"> 
		<Method>SendMessage</Method>
	</MapItem>
</MapItems>
}

/// Construct a new instance of an ebXML message (no payload)
Method CreateNewMessage() As EnsLib.ebXML.Message [ CodeMode = expression ]
{
$ZOBJCLASSMETHOD(..MessageTypeClass,"%New")
}

/// Construct a new instance of an ebXML message with payload
Method CreateNewMessageWithPayload() As EnsLib.ebXML.MessageWithPayload [ CodeMode = expression ]
{
$ZOBJCLASSMETHOD(..MessageWithPayloadTypeClass,"%New")
}

/// Default implementation for the routing delegate
Method RouteMessageToTargetMHS(pSender As %RegisteredObject, ByRef pRequest As EnsLib.ebXML.Message, ByRef pTargetUrl As %String, ByRef pSOAPAction As %String) As %Status
{
	Quit $$$OK
}

/// Default implemention of the response processing
Method ProcessTargetMHSResponse(pSender As %RegisteredObject, pRequest As EnsLib.ebXML.Message, ByRef pResponse As EnsLib.ebXML.Message) As %Status
{
	Quit $$$OK
}

}
