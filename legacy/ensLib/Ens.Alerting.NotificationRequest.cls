/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsConstants

/// Encapsulate a notification request for the Managed Alert in <property>ManagedAlert</property>.
Class Ens.Alerting.NotificationRequest Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// The underlying ManagedAlert triggering the notification request.
Property ManagedAlert As Ens.Alerting.ManagedAlert [ Required ];

/// The type of request. It can be for a standard notification, an update or an escalation.
Property NotificationType As Ens.DataType.AlertNotificationType [ InitialExpression = {$$$eAlertNotificationRequest} ];

/// List of eventual targets for the notification.
/// The Notification Operation that handles the request should be able to handle the supplied strings.
Property AlertDestinations As list Of %String(MAXLEN = "");

Storage Default
{
<Data name="NotificationRequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ManagedAlert</Value>
</Value>
<Value name="3">
<Value>AlertDestinations</Value>
</Value>
<Value name="4">
<Value>NotificationType</Value>
</Value>
</Data>
<DataLocation>^Ens.Alerting.NotRequestD</DataLocation>
<DefaultData>NotificationRequestDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Alerting.NotRequestD</IdLocation>
<IndexLocation>^Ens.Alerting.NotRequestI</IndexLocation>
<StreamLocation>^Ens.Alerting.NotRequestS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
