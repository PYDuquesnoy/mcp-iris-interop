/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class that implements some simple helper methods that actual Notification Operations can make use of.
Class Ens.Alerting.NotificationOperation Extends Ens.BusinessOperation [ Abstract, System = 4 ]
{

Parameter SETTINGS = "SystemName:Basic,IncludeUTCTimes:Basic";

/// Name of the system for inclusion in notifications sent from this system.
/// If this value is empty, then the default value will be the value of <property>InstanceName</property>.
Property SystemName As %String;

/// The current instance name.
Property InstanceName As %String [ InitialExpression = {##class(%SYS.System).GetInstanceName()} ];

/// Flag to control whether UTC times should be included in the text of notifications addition to the time of the local system.
Property IncludeUTCTimes As %Boolean [ InitialExpression = 1 ];

/// Helper method to get a text message describing the update that has been requested.
Method GetUpdateText(pNotificationRequest As Ens.Alerting.NotificationRequest, Output pUpdateText As %String) As %Status
{
	If (pNotificationRequest.NotificationType = $$$eAlertNotificationEscalationChange) {
		Set pUpdateText = $$$Text("This is a message to indicate that the Escalation Level of this alert has changed.","Ensemble")
	}
	Else {
		Set tLastActionTime = pNotificationRequest.ManagedAlert.LastActionTime
		If (tLastActionTime = "") {
			Set pUpdateText = $$$Text("This is a reminder message as no action has been taken for this alert.","Ensemble")
		}
		Else {
			Set pUpdateText = $$$FormatText($$$Text("This is a reminder message as this alert was last updated at %1 [%2 UTC]","Ensemble"),$$$timeUTCtoLocal(tLastActionTime),tLastActionTime)
		}
	}
	Set tNow = $$$timeUTC
	Set tNowLocal = $$$timeUTCtoLocal(tNow)
	Set tTimeMessage = $select(..IncludeUTCTimes: $$$FormatText($$$Text("This message was sent at %1 [%2 UTC]","Ensemble"),tNowLocal,tNow), 1: $$$FormatText($$$Text("This message was sent at %1 ","Ensemble"),tNowLocal))
	Set pUpdateText = pUpdateText _ $select(pUpdateText '= "": $char(10), 1: "") _ tTimeMessage
	Quit $$$OK
}

/// Helper method to get information about the system where the alert originated.
Method GetSystemInfo(pManagedAlert As Ens.Alerting.ManagedAlert = "", Output pSystemName As %String, Output pInstanceName As %String, Output pNodeName As %String) As %Status
{
	Set pInstanceName = ..InstanceName
	Set pSystemName = $select(..SystemName '= "": ..SystemName, 1: pInstanceName)
	Set pNodeName = ##class(%SYS.System).GetNodeName()
	Quit $$$OK
}

}
