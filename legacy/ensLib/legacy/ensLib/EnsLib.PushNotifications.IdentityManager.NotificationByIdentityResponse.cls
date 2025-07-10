/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsPushNotifications

/// Notification by identity response
Class EnsLib.PushNotifications.IdentityManager.NotificationByIdentityResponse Extends Ens.Response [ System = 4 ]
{

/// Integer that specifies the number of NotificationRequest messages sent to the target of the Identity Manager.
Property NotificationCount As %Integer [ InitialExpression = 0, Required ];

Storage Default
{
<Data name="NotificationByIdentityResponseDefaultData">
<Subscript>"NotificationByIdentityResponse"</Subscript>
<Value name="1">
<Value>NotificationCount</Value>
</Value>
</Data>
<DefaultData>NotificationByIdentityResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
