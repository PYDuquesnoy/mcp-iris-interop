/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Sends the notification request to the APNS server to forward to the specified device.  The APNS server pushes the notification to one device for each call.
/// It does not return any information other than if an error occurs, an indication that the error has occurred.
Class EnsLib.PushNotifications.APNS.Operation Extends (Ens.BusinessOperation, %Net.PushNotifications.APNS) [ System = 4 ]
{

/// Specifies the APNS notification protocol.  Has one of the following values: <p>
/// <ul><li> Simple - Simple Notification Protocol, which does not return any value and does not notify you if the protocol message causes an error.</li>
/// <li> Enhanced - Enhanced Notification Protocol, which returns values if the protocol message contains an error.  This protocol does not return a value for messages without errors.</li>
/// <li> Modern - Reserved for future use.  The APNS operation does not support the Modern Notification Protocol.</li></ul>
Property NotificationProtocol As %String(DISPLAYLIST = ",Simple,Enhanced,Modern", VALUELIST = ",simple,enhanced,modern") [ Required ];

Property Adapter As Ens.OutboundAdapter;

Parameter INVOCATION = "Queue";

Parameter SETTINGS = "PushServerAddress,PushServerPort,ConnectTimeout,ResponseTimeout,SSLConfig,NotificationProtocol";

Parameter BUFFERSIZE As %Integer = 16384;

Parameter DEVICETOKENLENGTH As %Integer = 32;

Parameter SERVICETYPE As %String = "APNS";

Method PushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
{
	If pRequest.Service'=..#SERVICETYPE {
		Quit $$$ERROR($$$EnsPushNotificationsErrIncompatibleNotificationType,pRequest.Service,..#SERVICETYPE)
	} Else {
		Quit $CASE(..NotificationProtocol,
					  "simple":..doSimplePushNotification(pRequest,.pResponse),
					"enhanced":..doEnhancedPushNotification(pRequest,.pResponse),
					  "modern":..doModernPushNotification(pRequest,.pResponse),
					          :$$$ERROR($$$EnsPushNotificationsErrNotificationProtocolNotSupported,..NotificationProtocol))
	}
}

Method doSimplePushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tPayloadArray As %String
		#dim tDeviceToken As %String
		
		Set tSC = ..ConstructAPNSPayloadArray(pRequest,.tPayloadArray)
		Quit:$$$ISERR(tSC)
		
		// Grab the device token
		Set tDeviceToken = pRequest.Identifiers.GetAt(1)

		Set tSC = ..SimplePushNotification(tDeviceToken,.tPayloadArray)
		Quit:$$$ISERR(tSC)		
		
		// Presumable, that worked ...
		Set tSC = pRequest.NewResponse(.pResponse)
		Quit:$$$ISERR(tSC)
		
		// Remember when we actually delivered it
		Set pResponse.DeliveredAtUTC = $ZDT($system.Util.LocalWithZTIMEZONEtoUTC($H),3)

	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method doEnhancedPushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		#dim tMsg As %String
		#dim tReply As %String
		#dim tPayloadArray As %String
		#dim tExpiresUTC As %Integer
		#dim tDeviceToken As %String
		
		Set tSC = ..ConstructAPNSPayloadArray(pRequest,.tPayloadArray)
		Quit:$$$ISERR(tSC)
		
		// Grab the device token
		Set tDeviceToken = pRequest.Identifiers.GetAt(1)
		
		Set tSC = ..EnhancedPushNotification(tDeviceToken, pRequest.%Id(), pRequest.ExpiresUTC, .tPayloadArray)
		Quit:$$$ISERR(tSC)		
		
		// Presumably, that worked ...
		Set tSC = pRequest.NewResponse(.pResponse)
		Quit:$$$ISERR(tSC)
		
		// Remember when we actually delivered it
		Set pResponse.DeliveredAtUTC = $ZDT($system.Util.LocalWithZTIMEZONEtoUTC($H),3)
		
	} While (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method doModernPushNotification(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pResponse As EnsLib.PushNotifications.NotificationResponse) As %Status
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

/// Build the intermediate APNS payload array from the message
ClassMethod ConstructAPNSPayloadArray(pRequest As EnsLib.PushNotifications.NotificationRequest, ByRef pPayloadData As %String) As %Status
{
	#dim tSC As %Status
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		If (pRequest.SoundNotification="")
			&& (pRequest.AlertNotification="")
			&& (pRequest.BadgeNotification="")
			&& (pRequest.Data.Count() = 0) {
				
			// Must have at least one of these properties set ...
			Set tSC = $$$ERROR($$$InvalidNotification)
			Quit
		}
		
		Set:pRequest.SoundNotification'="" pPayloadData("aps", "sound") = pRequest.SoundNotification
		Set:pRequest.AlertNotification'="" pPayloadData("aps", "alert") = pRequest.AlertNotification
		Set:pRequest.BadgeNotification'="" pPayloadData("aps", "badge") = pRequest.BadgeNotification
		Set:pRequest.UrlNotification'="" pPayloadData("zenmobile", "url") = pRequest.UrlNotification
		
		#dim tKey As %String = ""
		#dim tValue As %String
		For {
			Set tValue = pRequest.Data.GetNext(.tKey)
			Quit:tKey=""
			
			Set pPayloadData("data",tKey) = tValue
		}
		
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

		// TODO: Implement modern push notification support
		If ..NotificationProtocol = "modern" {
			Set tSC = $$$ERROR($$$EnsPushNotificationsErrNotificationProtocolNotSupported,..NotificationProtocol)
			Quit
		}

		// Now, go and connect
		Set tSC = ..Connect()
	}
	While (0)
Exit	
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

/// This user callback method is called from %OnClose()
Method OnTearDown() As %Status
{
	#dim tSC As %Status = ..Disconnect()
	
	// We probably don't care about any disconnect errors
	
	Quit $$$OK
}

}
