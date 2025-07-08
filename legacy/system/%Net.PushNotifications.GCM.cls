/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// // Implements Google Cloud Messaging Service connectivity
Class %Net.PushNotifications.GCM Extends %RegisteredObject
{

/// URL for the Google Cloud Messaging REST interface.
Property PushServer As %String(MAXLEN = 2048) [ InitialExpression = "https://android.googleapis.com/gcm/send", Required ];

/// Configuration name in the table of SSL configurations.
Property SSLConfig As %String [ Required ];

/// REST response timeout period in seconds.
Property Timeout As %Integer [ InitialExpression = 30, Required ];

Property HttpRequest As %Net.HttpRequest [ Internal ];

Parameter SERVICETYPE As STRING = "GCM";

Method Connect() As %Status
{
	Set ..HttpRequest = ##class(%Net.HttpRequest).%New()
		
	Set ..HttpRequest.SSLConfiguration=..SSLConfig
	Set ..HttpRequest.Server = $P(..PushServer,"/",3)
	Set ..HttpRequest.Port = 443
	Set ..HttpRequest.Https=1
	Set ..HttpRequest.Timeout=$S(..Timeout=-1:2123456789,1:..Timeout)

	// Nothing to do here ... we use HTTP
	Quit ..%ValidateObject()
}

Method Disconnect() As %Status
{
	Quit $$$OK
}

Method HTTPPushNotification(pAppIdentifier As %String, ByRef pNotification, ByRef pReply) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tMsg As %String
		#dim tPayload As %String
		#dim tGCMResponse As %ZEN.proxyObject
		
		Set tPayload = ##class(Util).ConvertArrayToJSON(.pNotification)
		
		Set ..HttpRequest.ContentType = "application/json"
		Do ..HttpRequest.SetHeader("Authorization", "key=" _ pAppIdentifier)
		
		Do ..HttpRequest.EntityBody.Write(tPayload)
		Do ..HttpRequest.EntityBody.Rewind()
		
		Set tSC = ..HttpRequest.Post("/"_$P(..PushServer,"/",4,*))
		Quit:$$$ISERR(tSC)

		#dim tHttpResponse As %Net.HttpResponse = ..HttpRequest.HttpResponse
		
		If '$IsObject(tHttpResponse) {
			Set tSC = $$$ERROR($$$GCMConnectionFailed,..PushServer)
			Quit
		}
		
		If +tHttpResponse.StatusCode'?1"2"2N {
			// Non 2xx HTTP response ...
			Set tSC=$$$ERROR($$$GCMHTTPStatus,tHttpResponse.StatusCode,tHttpResponse.StatusLine)
			Quit
		}

		// Now, we must parse the JSON response from the GCM server ...
		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tHttpResponse.Data,,.tGCMResponse)
		Quit:$$$ISERR(tSC)
		
		If tGCMResponse.success {

			Set tSC = ..ParseGCMHTTPSuccessResponse(tGCMResponse,.pReply)
			Quit:$$$ISERR(tSC)
			
			// Otherwise, success!

		} ElseIf tGCMResponse.failure {
			Set tSC = ..ParseGCMHTTPFailureResponse(tGCMResponse)
			Quit
		} Else {
			// Unknown error!
			Set tSC = $$$ERROR($$$GCMPushNotificationFailed)
			Quit
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

Method ParseGCMHTTPSuccessResponse(pGCMResponse As %ZEN.proxyObject, ByRef pReply) As %Status [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tIndex As %Integer
		
		// Remember when we actually delivered it
		Set pReply("DeliveredAtUTC") = $ZDT($system.Util.LocalWithZTIMEZONEtoUTC($H),3)

		// Grab the multicast id
		Set pReply("MulticastId") = pGCMResponse."multicast_id"
		
		// And the underlying message ids
		For tIndex = 1:1:pGCMResponse.results.Count() {
			#dim tResult As %ZEN.proxyObject = pGCMResponse.results.GetAt(tIndex)
			#dim tMsgId As %String = tResult."message_id"
			
			// Add this message id
			Set pReply("MessageIds",tIndex)= tMsgId
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// Parse the JSON response from the GCM HTTP server
Method ParseGCMHTTPFailureResponse(pGCMResponse As %ZEN.proxyObject) As %Status [ Internal ]
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tIndex As %Integer
		
		For tIndex = 1:1:pGCMResponse.results.Count() {
			#dim tResult As %ZEN.proxyObject = pGCMResponse.results.GetAt(tIndex)
			#dim tReason As %String = tResult."error"
			#dim tSC2 As %Status
			
			// Construct a status for this error
			Set tSC2 = $$$ERROR($$$GCMPushNotificationFailedWithReason,tReason)
			Set tSC = $$$ADDSC(tSC,tSC2)
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

}
