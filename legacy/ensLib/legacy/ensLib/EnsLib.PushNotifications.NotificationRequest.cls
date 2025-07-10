/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Notification send request class for Apple Push Notification Service
Class EnsLib.PushNotifications.NotificationRequest Extends (Ens.Request, NotificationInfo) [ System = 4 ]
{

/// Response class
Parameter RESPONSECLASSNAME As %String = "EnsLib.PushNotifications.NotificationResponse";

/// Identifies whether the device is a GCM or APNS device.
Property Service As %String(DISPLAYLIST = ",Apple Push Notification Service,Google Cloud Messaging", VALUELIST = ",APNS,GCM") [ Required ];

/// String that specifies the devices that are to get the notification.  For APNS, the device is specified by a device token.  For GCM, the device is specified as a registration ID.
Property Identifiers As list Of %String(MAXLEN = 512) [ Required ];

/// String that is only used for GCM notifications and identifies the App that the notification is associated with.
Property AppIdentifier As %String(MAXLEN = 512);

Storage Default
{
<Data name="Data">
<Attribute>Data</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.PushNotifications.NotificationRequest.Data"</Subscript>
</Data>
<Data name="NotificationRequestDefaultData">
<Subscript>"NotificationRequest"</Subscript>
<Value name="1">
<Value>CollapseKey</Value>
</Value>
<Value name="2">
<Value>ExpiresUTC</Value>
</Value>
<Value name="3">
<Value>Identifiers</Value>
</Value>
<Value name="4">
<Value>AlertNotification</Value>
</Value>
<Value name="5">
<Value>BadgeNotification</Value>
</Value>
<Value name="6">
<Value>UrlNotification</Value>
</Value>
<Value name="7">
<Value>AppIdentifier</Value>
</Value>
<Value name="8">
<Value>Service</Value>
</Value>
<Value name="9">
<Value>SoundNotification</Value>
</Value>
</Data>
<DefaultData>NotificationRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
