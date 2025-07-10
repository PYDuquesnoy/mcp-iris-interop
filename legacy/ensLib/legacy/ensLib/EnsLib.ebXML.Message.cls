/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsebXML)

/// ebXML Message instance for signalling etc.  Use MessageWithPayload to include payload/Manifest
Class EnsLib.ebXML.Message Extends (%Persistent, Ens.VDoc.Interface, Ens.Util.MessageBodyMethods, %XML.Adaptor) [ ClassType = persistent, System = 4 ]
{

/// Parameter allows the base package for the ebXML schema classes to be overriden
Parameter SCHEMAPACKAGE As %String = "EnsLib.ebXML.schema";

/// SOAP Headers associated with this ebXML message
Property Headers As array Of EnsLib.ebXML.SOAPHeader(CLASSNAME = 1);

/// Construct reply message headers 
Method BuildReplyHeader(pInReplyTo As EnsLib.ebXML.Message, pMessageId As %String, pAction As %String, pService As %String, pAckRequested As %Boolean = 0) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		If '$IsObject(pInReplyTo) {
			Set tSC = $$$ERROR($$$OrefInvalid)
			Quit
		}
		
		#dim tRqHdr As EnsLib.ebXML.schema.msg.MessageHeader
		#dim tAqHdr As EnsLib.ebXML.schema.msg.MessageHeader
		
		// Grab the request headers
		Set tRqHdr = pInReplyTo.Headers.GetAt("MessageHeader")
				
		// Construct a response header
		Set tAqHdr = ..ConstructSchemaClassInstance("msg.MessageHeader")
		Set tAqHdr.version        = $$$EnsebXMLVersion
		Set tAqHdr.mustUnderstand = 1
				
		// Now, let's swap the To/From and assign a new MessageId and Timestamp	
		Set tAqHdr.To                         = tRqHdr.From.%ConstructClone(1)
		Set tAqHdr.From                       = tRqHdr.To.%ConstructClone(1)
		Set tAqHdr.MessageData.MessageId      = pMessageId
		Set tAqHdr.MessageData.Timestamp      = $$$timeUTC
		Set tAqHdr.MessageData.RefToMessageId = tRqHdr.MessageData.MessageId
		Set tAqHdr.ConversationId             = tRqHdr.ConversationId
		Set tAqHdr.CPAId                      = tRqHdr.CPAId
		Set tAqHdr.Service.content            = pService
		Set tAqHdr.Action                     = pAction
		Do ..Headers.SetAt(tAqHdr,tAqHdr.%ClassName(0))
		
		// Finally, if an AckRequested is needed, inject that
		If pAckRequested {
			#dim tAckRq As EnsLib.ebXML.schema.msg.AckRequested

			Set tAckRq = ..ConstructSchemaClassInstance("msg.AckRequested")
			Set tAckRq.version        = $$$EnsebXMLVersion
			Set tAckRq.mustUnderstand = 1
			Set tAckRq.signed         = 0
			
			Do ..Headers.SetAt(tAckRq,tAckRq.%ClassName(0))
		}
				
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Construct an acknowledgment message to this message
Method BuildAckHeader(pInAckTo As EnsLib.ebXML.Message, pMessageId As %String, pAction As %String = {$$$EnsebXMLMessageServiceAcknowledgmentAction}, pService As %String = {$$$EnsebXMLMessageService}) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		
		Set tSC = ..BuildReplyHeader(pInAckTo, pMessageId, pAction, pService)
		Quit:$$$ISERR(tSC)
		
		#dim tAck   As EnsLib.ebXML.schema.msg.Acknowledgment
		#dim tAqHdr As EnsLib.ebXML.schema.msg.MessageHeader
		
		Set tAqHdr = pInAckTo.Headers.GetAt("MessageHeader")
		
		Set tAck = ..ConstructSchemaClassInstance("msg.Acknowledgment")
		Set tAck.version        = $$$EnsebXMLVersion
		Set tAck.mustUnderstand = 1
		Set tAck.RefToMessageId = tAqHdr.MessageData.MessageId
		Set tAck.Timestamp      = tAqHdr.MessageData.Timestamp
		Set tAck.From           = tAqHdr.To.%ConstructClone(1)
		Do ..Headers.SetAt(tAck,tAck.%ClassName(0))

	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Construct an error response message to this message
Method BuildErrorList(pInRefTo As EnsLib.ebXML.Message, pMessageId As %String, pAction As %String = {$$$EnsebXMLMessageServiceMessageErrorAction}, pService As %String = {$$$EnsebXMLMessageService}, pStatus As %Status, pSeverity As %String = {$$$EnsebXMLErrorSeverityError}) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tIndex As %Integer
		#dim tStatusInfo
		
		Do $system.Status.DecomposeStatus(pStatus,.tStatusInfo)
		
		/// NOTE: ConstructReplyHeader() will use the From of the source message, however, this
		///		  should only be used if the ErrorURI is not specified in the associated CPA.

		Set tSC = ..BuildReplyHeader(pInRefTo, pMessageId, pAction, pService)
		Quit:$$$ISERR(tSC)
		
		#dim tErrors As EnsLib.ebXML.schema.msg.ErrorList
		#dim tError  As EnsLib.ebXML.schema.msg.Error
		
		Set tErrors = ..ConstructSchemaClassInstance("msg.ErrorList")
		Set tErrors.version         = $$$EnsebXMLVersion
		Set tErrors.mustUnderstand  = 1
		Set tErrors.highestSeverity = pSeverity
		
		// Loop over each error in the supplied status and create a corresponding
		// ebXML Error element.
		For tIndex=1:1:+$G(tStatusInfo) {
			
			#dim tErrorCode   As %String = ""
			#dim tLocation    As %String = ""
			#dim tDescription As %String = ""
			#dim tLanguage    As %String = ""
		
			Set tError = ..ConstructSchemaClassInstance("msg.Error")
			
			Set tErrorCode   = ..MapEnsembleErrorToebXMLError(tStatusInfo(tIndex,"code"))
			Set tLocation    = $SELECT(+$G(tStatusInfo(tIndex,"param"))>0:tStatusInfo(tIndex,"param",1),1:"")
			Set tLanguage    = $$$EnsebXMLDefaultLanguageForMHS
			Set tDescription = tStatusInfo(tIndex)

			Set tError.codeContext = $$$EnsebXMLErrorCodeContext
			Set tError.errorCode   = tErrorCode
			Set tError.severity    = pSeverity
			Set tError.location    = tLocation
		
			Set tError.Description.lang    = tLanguage
			Set tError.Description.content = tDescription
			
			// Add to the error list
			Do tErrors.Error.Insert(tError)
		}
		
		Do ..Headers.SetAt(tErrors,tErrors.%ClassName(0))

	} While (0) 
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Check the ebXML message for an error list, and if present, convert into a %Status value
Method MessageErrorStatus() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tErrors As EnsLib.ebXML.schema.msg.ErrorList

		// Look for an error list
		Set tErrors = ..Headers.GetAt("ErrorList")
		If $IsObject(tErrors) {
			#dim tIndex As %Integer
			
			For tIndex = 1:1:tErrors.Error.Count() {
				#dim tError      As EnsLib.ebXML.schema.msg.Error
				#dim tErrorSC    As %Status
				#dim tSubErrorSC As %Status
				
				Set tError      = tErrors.Error.GetAt(tIndex)
				Set tErrorSC    = $$$ERROR(..MapebXMLErrorToEnsembleError(tError.errorCode))
				Set tSubErrorSC = $$$ERROR($$$EnsebXMLErrebXMLErrorListError,tError.errorCode,tError.severity,tError.Description.lang,tError.Description.content)
				
				// Append this error item to our list of errors
				Set tSC = $$$ADDSC(tSC,$$$EMBEDSC(tErrorSC,tSubErrorSC))
			}
		}
		
	} While (0) 
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// Returns true if this is a status request
Method IsStatusRequest() As %Boolean [ CodeMode = expression ]
{
..Headers.IsDefined("StatusRequest")
}

/// Returns true if the message has a SyncReply header.  Note that in a valid ebXML message,
/// the presence of SyncReply must be consistent with the CPA's syncReplyMode setting.
Method IsSyncReply() As %Boolean [ CodeMode = expression ]
{
..Headers.IsDefined("SyncReply")
}

/// Returns true if the message is requesting an Acknowledgement
Method IsAckRequested() As %Boolean [ CodeMode = expression ]
{
..Headers.IsDefined("AckRequested")
}

/// Returns true if the message is an Acknowledgement
/// If pRefToMessageId is supplied, then there is an additional constraint of matching
/// the RefToMessageId.
Method IsAcknowledgment(pRefToMessageId As %String = "") As %Boolean [ CodeMode = expression ]
{
$CASE(..GetValueAt("Headers(Acknowledgment).RefToMessageId"),
		// If it has a Acknowledgment/RefToMessageId that matches pRefToMessageId
		pRefToMessageId:..Headers.IsDefined("Acknowledgment"),
		
		// Has no Acknowledgement/RefToMessageId, but we didn't ask to match one
		"":(..Headers.IsDefined("Acknowledgment") && (pRefToMessageId="")),

		// This is an Acknowledment, but does not match pRefToMessageId; we only return TRUE if no
		// pRefToMessageId was specified (i.e. match any Acknowledgment).
		:(pRefToMessageId=""))
}

/// Returns true if the message is an Acknowledgement
/// If pRefToMessageId is supplied, then there is an additional constraint of matching
/// the RefToMessageId.
Method IsAcknowledgmentTo(pMessage As EnsLib.ebXML.Message) As %Boolean [ CodeMode = expression ]
{
..IsAcknowledgment(pMessage.GetValueAt("Headers(MessageHeader).MessageData.MessageId"))
}

/// Returns true if the message appears to be in reply to another message
/// If pRefToMessageId is supplied, then there is an additional constraint of matching
/// the RefToMessageId.
Method IsResponse(pRefToMessageId As %String = "") As %Boolean [ CodeMode = expression ]
{
$CASE(..GetValueAt("Headers(MessageHeader).MessageData.RefToMessageId"),
		"":0,					// This is not in reply to any message
		pRefToMessageId:1,		// This is a reply and it matches the specified pRefInMessageId
		
		// This is a reply, but does not match pRefToMessageId; we only return TRUE if no
		// pRefToMessageId was specified (i.e. match any reply).
		:pRefToMessageId="")
}

/// Returns true if this message is a reply to the specified message.
Method IsResponseTo(pMessage As EnsLib.ebXML.Message) As %Boolean [ CodeMode = expression ]
{
..IsResponse(pMessage.GetValueAt("Headers(MessageHeader).MessageData.MessageId"))
}

/// Method to construct instances of ebXML schema classes.  Can be overriden for custom schema
/// classes/packages.
Method ConstructSchemaClassInstance(pClassName As %String) As %RegisteredObject [ CodeMode = expression ]
{
$ZOBJCLASSMETHOD(..#SCHEMAPACKAGE_"."_pClassName,"%New")
}

/// Convert InterSystems IRIS status codes into ebXML Error codes
Method MapEnsembleErrorToebXMLError(pStatusCode As %String) As %String
{
	Quit $CASE(pStatusCode,
				$$$EnsebXMLErrUnableToRouteMessage         : $$$EnsebXMLErrorCodeDeliveryFailure,
				$$$EnsebXMLErrUndeliverableMessage         : $$$EnsebXMLErrorCodeDeliveryFailure,
				$$$EnsErrTargetNotSpecified                : $$$EnsebXMLErrorCodeDeliveryFailure,
				$$$EnsErrBusinessDispatchNameNotRegistered : $$$EnsebXMLErrorCodeDeliveryFailure,
				$$$EnsebXMLErrBadlyFormedMessage           : $$$EnsebXMLErrorCodeInconsistent,
				$$$EnsebXMLErrUnsatisfiedReference         : $$$EnsebXMLErrorCodeMimeProblem,
				$$$EnsebXMLErrDuplicatePayload             : $$$EnsebXMLErrorCodeMimeProblem,
				$$$EnsebXMLErrUnreferencedPayload          : $$$EnsebXMLErrorCodeMimeProblem,
				$$$EnsebXMLErrNotSupported                 : $$$EnsebXMLErrorCodeNotSupported,
				/* Default */                              : $$$EnsebXMLErrorCodeUnknown)
}

/// Convert an ebXML Error code into an appropriate InterSystems IRIS status code
Method MapebXMLErrorToEnsembleError(pebXMLCode As %String) As %String
{
	Quit $CASE(pebXMLCode,
				$$$EnsebXMLErrorCodeDeliveryFailure : $$$EnsebXMLErrUndeliverableMessage,
				$$$EnsebXMLErrorCodeInconsistent    : $$$EnsebXMLErrBadlyFormedMessage,
				$$$EnsebXMLErrorCodeSecurityFailure : $$$EnsebXMLErrSecurityError,
				$$$EnsebXMLErrorCodeNotSupported    : $$$EnsebXMLErrNotSupported,
				/* Default */                       : $$$EnsebXMLErrUnknownebXMLError)
}

/*
#define EnsebXMLErrorCodeValueNotRecognized "ValueNotRecognized"
#define EnsebXMLErrorCodeNotSupported       "NotSupported"
#define EnsebXMLErrorCodeInconsistent       "Inconsistent"
#define EnsebXMLErrorCodeOtherXml			"OtherXml"
#define EnsebXMLErrorCodeDeliveryFailure	"DeliveryFailure"
#define EnsebXMLErrorCodeTimeToLiveExpired	"TimeToLiveExpired"
#define EnsebXMLErrorCodeSecurityFailure	"SecurityFailure"
#define EnsebXMLErrorCodeMimeProblem		"MimeProblem"
#define EnsebXMLErrorCodeUnknown			"Unknown"
*/
/// VDoc style accessor
Method GetValueAt(pPath As %String, pFormat As %String, ByRef pStatus As %Status) As %String
{
	#dim tSC    As %Status
	#dim tValue As %String = ""
	
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tName  As %String
		#dim tSubs  As %String
		#dim tIndex As %Integer
		
		Set tValue = $this
		For tIndex=1:1:$L(pPath,".") {
			Set tName = $P($P(pPath,".",tIndex),"(")
			Set tSubs = $P($P($P(pPath,".",tIndex),"(",2),")")
			Set tValue = $PROPERTY(tValue,tName)
			If tSubs'="" {
				// Process an array/list subscript
				Set tValue = tValue.GetAt(tSubs)
			}
		}
		
		Set tValue = tValue
		
	} While (0)
Exit
	Set pStatus = tSC
	Quit $S($$$ISOK(tSC):tValue,1:"")
	
ItsATrap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method sets the value of the given property.<br>
/// This is implemented by the document class.<br>
/// <var>pPath</var> contains the property name.<br>
/// <var>pAction</var> contains an action code: "set", etc..<br>
/// <var>pKey</var> contains an optional key value.<br>
Method SetValueAt(pValue As %String, pPath As %String, pKey As %String = "", pAction As %String = "set") As %Status
{
	#dim tSC    As %Status
	#dim tValue As %String = ""
	
	Set tSC=$$$OK,$ZT="ItsATrap"
	Do {
		#dim tName  As %String
		#dim tSubs  As %String
		#dim tIndex As %Integer
		#dim tCount As %Integer
		#dim tLast  As %String = ""
		
		Set tValue = $this
		Set tCount = $L(pPath,".")
		
		For tIndex=1:1:tCount {
			Set tName = $P($P(pPath,".",tIndex),"(")
			Set tSubs = $P($P($P(pPath,".",tIndex),"(",2),")")
			
			// Drill down if necessary
			Set tLast  = tValue
			Set tValue = $PROPERTY(tValue,tName)
			
			// Process an array/list subscript
			If tSubs'="" {
				// Note that it may be necessary to inject an element ... check to see if it exists ...
				If $SELECT(tValue.%Extends("%Collection.AbstractList"):tSubs<tValue.Size,1:tValue.IsDefined(tSubs)) {
					// Collection contains the element ... grab it and go
					Set tValue = tValue.GetAt(tSubs)
				} Else {
					// We need to dynamically inject one ...
					#dim tElement As %RegisteredObject

					// If we're injecting elements of type SOAPHeader, then we have to determine the actual type based
					// on the subscript (i.e. the header name).  Otherwise, just create a new instance of the type.
					Set tElement = $SELECT(tValue.ElementType="EnsLib.ebXML.SOAPHeader":..ConstructSchemaClassInstance("msg."_tSubs),
										   $$$classIsDataType(tValue.ElementType):"",
										   tValue.ElementType="":"",
										   1:$CLASSMETHOD(tValue.ElementType,"%New"))

					Set tSC = tValue.SetAt(tElement,tSubs)
					Quit:$$$ISERR(tSC)
					
					// Keep drilling down as necessary
					Set tValue = tElement
				}
			}
		}
		
		// Now, we can set the property
		If pAction = "set" {
			If pKey="" {
				// Regular set ...
				Set $PROPERTY(tLast,tName) = pValue
			} Else {
				// Array/list element set
				Set tSC = tValue.SetAt(pValue,pKey)
			}
		} ElseIf pAction = "append" {
			// Append to a list
			Set tSC = tValue.Insert(pValue)
		} ElseIf pAction = "remove" {
			// Remove from an array/list
			Do tValue.RemoveAt(pKey)
		} ElseIf pAction = "clear" {
			// Clear a list/array
			Set tSC = tValue.Clear()
		}
		
	} While (0)
Exit
	Quit tSC
	
ItsATrap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Returns array of properties that make up the <i>contents</i>
/// of this object.<br>
/// This method in implemented within the document class.<br>
/// The content array is in the form:<br>
/// 	pContents(n,"type")="%String"<br>
/// 	pContents(n,"name")="Field"<br>
/// 	pContents(n,"alias")=alias code<br>
/// If pContents(n) is non-zero then the property is a composite type with<br>
/// sub-properties.  The sub-properties are indexed with a similar structure under<br>
///     pContents(n,m) where m is the index of the subtype property.<br>
ClassMethod GetContentArray(Output pContents, pMode As %String = "source", pDocType As %String = "", pLevel As %Integer = 0, pIncludeBase As %Boolean = 0) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tRS       As %ResultSet
		#dim tProperty As %String
		

		// Set up the Headers property
		Set @pContents@($I(@pContents),"type")="%ArrayOfObjects"
		Set @pContents@(@pContents,"name")="Headers"
		
		// Now, we need to find all instances of EnsLib.ebXML.SOAPHeader as possible array elements
		Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinitionQuery:SubclassOf")
		Set tSC = tRS.Execute("EnsLib.ebXML.SOAPHeader")
		Quit:$$$ISERR(tSC)
		
		// Loop over the subclasses of EnsLib.ebXML.SOAPHeader
		While (tRS.Next(.tSC) && $$$ISOK(tSC)) {
			// Populate the contents array for this item
			Set tSC = ..GetContentArrayForClass($NAME(@pContents@(@pContents)),tRS.Data("Name"))
			Quit:$$$ISERR(tSC)
		}

		// Finally, set up other local properties available to DTL
		For tProperty = "TimeCreated" {			
			Set tSC = ..GetContentArrayForProperty($NAME(@pContents), $classname(), tProperty)
			Quit:$$$ISERR(tSC)
		}
		Quit:$$$ISERR(tSC)		
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Helper method for GetContentArray()
ClassMethod GetContentArrayForClass(Output pContents, pClassName As %String, pPropertyName As %String = {$P(pClassName,".",$L(pClassName,"."))}, pInherit As %Boolean = 0) As %Status [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tIndex        As %Integer = $I(@pContents)
		#dim tCurrentClass As %String  = pClassName
	
		// Make an entry for the class
		Set @pContents@(tIndex,"type") = $$$NormalizeClassname(pClassName)
		Set @pContents@(tIndex,"name") = pPropertyName

		Do {
			// Now, process it's properties
			#dim tProperty As %String  = ""
			For {
				Set tProperty = $$$defMemberNext(tCurrentClass,$$$cCLASSproperty,tProperty)
				Quit:tProperty=""
				
				// Filter out unnecessary properties
				If $$$defMemberKeyGet(tCurrentClass,$$$cCLASSproperty,tProperty,$$$cPROPmultidimensional) ||
				   $$$defMemberKeyGet(tCurrentClass,$$$cCLASSproperty,tProperty,$$$cPROPtransient)        ||
				   $$$defMemberKeyGet(tCurrentClass,$$$cCLASSproperty,tProperty,$$$cPROPinternal)         ||
				   $$$defMemberKeyGet(tCurrentClass,$$$cCLASSproperty,tProperty,$$$cPROPprivate) {
					   Continue
				}
		
				// Process this property
				Set tSC = ..GetContentArrayForProperty($NAME(@pContents@(tIndex)), tCurrentClass, tProperty)
				Quit:$$$ISERR(tSC)
			}
			
			// Find the next super class
			Set tCurrentClass = $P($$$defClassKeyGet(tCurrentClass,$$$cCLASSsuper),",")
			
		} While ((tCurrentClass '= "") && pInherit)
	
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Generate a content array entry for the specified class/property
ClassMethod GetContentArrayForProperty(Output pContents, pClass As %String, pProperty As %String, pRecurse As %Boolean = 1) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tRuntimeType  As %String
		#dim tPropertyType As %String

		Set tRuntimeType  = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPruntimetype)
		Set tPropertyType = $$$comMemberKeyGet(pClass,$$$cCLASSproperty,pProperty,$$$cPROPtype)
	
		Set:tRuntimeType="" tRuntimeType = tPropertyType
	
		// Process a datatype class (or a recursive reference)
		If ($$$classIsDataType(tRuntimeType)) || (tPropertyType=pClass) {
			#dim tSubIndex As %Integer = $I(@pContents)
		
			Set @pContents@(tSubIndex,"type") = $$$DenormalizeClassname(tPropertyType)
			Set @pContents@(tSubIndex,"name") = pProperty
		} ElseIf pRecurse {
			// Need to recursively process this ...
			Set tSC = ..GetContentArrayForClass($NAME(@pContents), tPropertyType, pProperty)
			Quit:$$$ISERR(tSC)
		} // Else we don't recurse ...
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// This method is called by the Management Portal to determine
/// the content type that will be returned by the <method>%ShowContents</method>
/// method.
Method %GetContentType() As %String
{
	Quit "text/html"
}

/// Write out style information for the HTML display 
/// produced by the <method>%ShowContents</method> method.
Method %ShowContentsHead(pZenOutput As %Boolean = 0)
{
	&html<
<style type="text/css">
	.divBlock {
		border: 1px solid grey;
		padding: 3px;
		margin-top: 1em;
	}
	h1 {
		padding: 0px;
		margin: 0px;
		font-size: 1.1em;
	}
	h2 {
		padding: 0px;
		margin: 0px;
		font-size: 1em;
		font-weight: bold;
	}
	h3 {
		padding: 0px;
		padding-bottom: 3px;
		margin: 0px;
		font-size: 0.9em;
	}
	pre {
		border: 1px solid grey;
		background-color: white;
		margin: 0px;
		margin-top: 0.5em;
		padding: 3px;
		width: 99%;
		overflow: auto;
	}
	a {
		font-size: 0.9em;
	}
</style>>
}

/// This method is called by the Management Portal to 
/// display a message-specific content viewer.<br>
/// This method displays its content by writing out to the current device.
Method %ShowContents(pZenOutput As %Boolean = 0)
{
	If (%response.ContentType="application/json") {
		Do ..WriteNoJSONFormat($this)
	} Else {
		&html<<div id="contentMain">
		<h1>#($classname($this))#&nbsp;&nbsp;&nbsp;&nbsp;Id: #(..%Id())#</h1>>
		Do ..showTopLinks()
		Do ..showContents()
		&html<</div>>
	}
	Quit
}

/// HTML display helper to simplify output of message properties.
Method showContents()
{
	If $IsObject(..Headers.GetNext("")) {
		&html<<div id="headerDiv" class="divBlock"><h2>SOAP Headers</h2><pre>>
		Set tStream = ##class(%Stream.TmpCharacter).%New()
		Set tWriter = ##class(%XML.Writer).%New()
		Set tWriter.NoXMLDeclaration = 1
		Do tWriter.AddInstanceNamespace()
		Do tWriter.AddSchemaNamespace()
		Set tWriter.Indent = 1
		Do tWriter.OutputToStream(tStream)
		set tHeader=..Headers.GetNext(.tHeaderTag)
		while (tHeaderTag'="") {		
			Do tWriter.RootObject(tHeader)
			Do ..escapeXMLStream(tStream)
			set tHeader=..Headers.GetNext(.tHeaderTag)
		}
		&html<</pre></div>>
	}
}

/// HTML display helper to simplify output of links.
Method showTopLinks()
{
	If $IsObject(..Headers.GetNext("")) {
		&html<<a href="#headerDiv">SOAP Headers</a>&nbsp;&nbsp;&nbsp;>
	}
}

/// Escape XML stream data for HTML display
ClassMethod escapeXMLStream(pStream As %Stream.Object) [ Internal, Private ]
{
	Try {
		Do pStream.Rewind()
		Set tIO = $$GetIO^%SYS.NLS()
		Do SetIO^%SYS.NLS("XML")
		Do pStream.OutputToDevice()
	}
	Catch {}
	If $get(tIO) '= "" Do SetIO^%SYS.NLS(tIO)
	Quit
}

Property RawContent As %String(XMLPROJECTION = "NONE");

Property DocType As %String(XMLPROJECTION = "NONE");

Property DocTypeCategory As %String(XMLPROJECTION = "NONE");

Property DocTypeName As %String(XMLPROJECTION = "NONE");

Property Name As %String(XMLPROJECTION = "NONE");

Property TypeVersion As %String(XMLPROJECTION = "NONE");

Property Identifier As %String(XMLPROJECTION = "NONE");

Storage Default
{
<Data name="Headers">
<Attribute>Headers</Attribute>
<Structure>subnode</Structure>
<Subscript>"Headers"</Subscript>
</Data>
<Data name="MessageHeaderDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DocType</Value>
</Value>
<Value name="3">
<Value>RawContent</Value>
</Value>
<Value name="4">
<Value>DocTypeCategory</Value>
</Value>
<Value name="5">
<Value>DocTypeName</Value>
</Value>
<Value name="6">
<Value>Name</Value>
</Value>
<Value name="7">
<Value>TypeVersion</Value>
</Value>
<Value name="8">
<Value>Identifier</Value>
</Value>
<Value name="9">
<Value>TimeCreated</Value>
</Value>
<Value name="10">
<Value>Source</Value>
</Value>
<Value name="11">
<Value>IsMutable</Value>
</Value>
<Value name="12">
<Value>OriginalDocId</Value>
</Value>
<Value name="13">
<Value>CreatedAt</Value>
</Value>
</Data>
<Data name="UserValues">
<Attribute>UserValues</Attribute>
<Structure>subnode</Structure>
<Subscript>"UserValues"</Subscript>
</Data>
<DataLocation>^EnsLib.ebXML.MessageD</DataLocation>
<DefaultData>MessageHeaderDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^EnsLib.ebXML.MessageD</IdLocation>
<IndexLocation>^EnsLib.ebXML.MessageI</IndexLocation>
<StreamLocation>^EnsLib.ebXML.MessageS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
