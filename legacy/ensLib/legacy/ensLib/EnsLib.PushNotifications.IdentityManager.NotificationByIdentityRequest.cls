/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Notification by identity request
Class EnsLib.PushNotifications.IdentityManager.NotificationByIdentityRequest Extends (Ens.Request, EnsLib.PushNotifications.NotificationInfo) [ System = 4 ]
{

/// Associated Application Token
Property AssociatedAppToken As %String(MAXLEN = 512) [ Required ];

/// Response class
Parameter RESPONSECLASSNAME As %String = "EnsLib.PushNotifications.IdentityManager.NotificationByIdentityResponse";

Storage Default
{
<Data name="Data">
<Attribute>Data</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.PushNotifications.IdentityManager.NotificationByIdentityRequest.Data"</Subscript>
</Data>
<Data name="NotificationByIdentityRequestDefaultData">
<Subscript>"NotificationByIdentityRequest"</Subscript>
<Value name="1">
<Value>AssociatedAppToken</Value>
</Value>
<Value name="2">
<Value>ExpiresUTC</Value>
</Value>
<Value name="3">
<Value>SoundNotification</Value>
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
<Value>CollapseKey</Value>
</Value>
</Data>
<DefaultData>NotificationByIdentityRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
