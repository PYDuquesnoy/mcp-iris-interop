/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Response message for push notification requests
Class EnsLib.PushNotifications.NotificationResponse Extends Ens.Response [ System = 4 ]
{

/// Time stamp (in UTC) that specifies the time that the notification was sent to the APNS or GCM server.
Property DeliveredAtUTC As %TimeStamp;

/// String that contains the multicast Id returned by the GCM server (not used for APNS).
Property MulticastId As %String(MAXLEN = 512);

/// List of message id(s) returned by the server.
Property MessageIds As list Of %String(MAXLEN = 512);

Storage Default
{
<Data name="NotificationResponseDefaultData">
<Subscript>"NotificationResponse"</Subscript>
<Value name="1">
<Value>DeliveredAtUTC</Value>
</Value>
<Value name="2">
<Value>MulticastId</Value>
</Value>
<Value name="3">
<Value>MessageIds</Value>
</Value>
</Data>
<DefaultData>NotificationResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
