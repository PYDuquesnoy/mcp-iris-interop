/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Interfaces with the Google Cloud Messaging Service
Class EnsLib.PushNotifications.GCM.Operation Extends (Ens.BusinessOperation, %Net.PushNotifications.GCM) [ System = 4 ]
{

/// Specifies the GCM notification protocol.  Has one of the following values: <p>
/// <ul><li> HTTP - HTTP REST protocol</li>
/// <li> XMPP - Reserved for future use.  The GCM operation does not support the XMPP always connected, bi-directional protocol.
Property NotificationProtocol As %String(DISPLAYLIST = ",HTTP,XMPP", VALUELIST = ",http,xmpp") [ Required ];

Property Adapter As Ens.OutboundAdapter;

Parameter INVOCATION = "Queue";

Parameter SETTINGS = "NotificationProtocol,PushServer,SSLConfig,Timeout";

Method PushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
{
	If pRequest.Service'=..#SERVICETYPE {
		Quit $$$ERROR($$$EnsPushNotificationsErrIncompatibleNotificationType,pRequest.Service,..#SERVICETYPE)
	} Else {
		Quit $CASE(..NotificationProtocol,
					  "http":..doHTTPPushNotification(pRequest,.pResponse),
					  "xmpp":..doXMPPPushNotification(pRequest,.pResponse),
					        :$$$ERROR($$$EnsPushNotificationsErrNotificationProtocolNotSupported,..NotificationProtocol))
	}
}

Method doHTTPPushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tMsg As %String
		#dim tReply As %String
		#dim tPayloadArray As %String
		#dim tIndex As %Integer
		
		
		
		Set tSC = ..ConstructGCMHTTPPayloadArray(pRequest,.tPayloadArray)
		Quit:$$$ISERR(tSC)

		Set tSC = ..HTTPPushNotification(pRequest.AppIdentifier, .tPayloadArray, .tReply)
		Quit:$$$ISERR(tSC)

		Set tSC = pRequest.NewResponse(.pResponse)
		Quit:$$$ISERR(tSC)
		
		// Remember when we actually delivered it
		Set pResponse.DeliveredAtUTC = tReply("DeliveredAtUTC")

		// Grab the multicast id
		Set pResponse.MulticastId = tReply("MulticastId")
		
		// And the underlying message ids
		Set tIndex = ""
		For {
			Set tIndex = $ORDER(tReply("MessageIds",tIndex))
			Quit:tIndex=""
			
			// Add this message id
			Do pResponse.MessageIds.Insert(tReply("MessageIds",tIndex))
		}
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method doXMPPPushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
{
	Quit $$$ERROR($$$NotImplemented)
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.PushNotifications.NotificationRequest"> 
		<Method>PushNotification</Method>
	</MapItem>
</MapItems>
}

/// Construct a payload request for GCM (over HTTP)
ClassMethod ConstructGCMHTTPPayloadArray(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pPayloadArray As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tIndex As %Integer
		
		If (pRequest.SoundNotification="")
			&& (pRequest.AlertNotification="")
			&& (pRequest.BadgeNotification="")
			&& (pRequest.Data.Count() = 0) {
				
			// Must have at least one of these properties set ...
			Set tSC = $$$ERROR($$$InvalidNotification)
			Quit
		}
		
		Set pPayloadArray("registration_ids") = ""
		For tIndex = 1:1:pRequest.Identifiers.Count() {
			#dim tRegId As %String = pRequest.Identifiers.GetAt(tIndex)
			Set pPayloadArray("registration_ids") = pPayloadArray("registration_ids") _ $LB(tRegId)
		}
		
		Set:pRequest.SoundNotification'="" pPayloadArray("data", "sound") = pRequest.SoundNotification
		Set:pRequest.AlertNotification'="" pPayloadArray("data", "alert") = pRequest.AlertNotification
		Set:pRequest.BadgeNotification'="" pPayloadArray("data", "badge") = pRequest.BadgeNotification
		Set:pRequest.UrlNotification'="" pPayloadArray("data", "url") = pRequest.UrlNotification
				
		#dim tKey As %String = ""
		#dim tValue As %String
		For {
			Set tValue = pRequest.Data.GetNext(.tKey)
			Quit:tKey=""
			
			Set pPayloadArray("data",tKey) = tValue
		}
		
		Set:pRequest.CollapseKey'="" pPayloadArray("collapse_key") = pRequest.CollapseKey		
		Set:pRequest.ExpiresUTC'="" pPayloadArray("time_to_live") = ##class(%Net.PushNotifications.Util).TimeStampDelta(pRequest.ExpiresUTC,,1)\1
				
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This user callback method is called via initConfig() from %OnNew() or in the case of SOAP Services from OnPreSOAP()
Method OnInit() As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		// TODO: Implement XMPP support
		If ..NotificationProtocol = "xmpp" {
			Set tSC = $$$ERROR($$$EnsPushNotificationsErrNotificationProtocolNotSupported,..NotificationProtocol)
			Quit
		}

		Set tSC = ..Connect()
		Quit:$$$ISERR(tSC)		
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	Quit ..Disconnect()
}

}
