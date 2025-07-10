/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsConstants

/// The type of request in the <class>Ens.Alerting.NotificationRequest</class> class.
Class Ens.DataType.AlertNotificationType Extends %Library.Integer [ System = 4 ]
{

Parameter VALUELIST = ",0,1,2,3";

/// Helper method to represent the Notification Type using localised text.
ClassMethod GetText(pNotificationType As %Integer = "") As %String [ CodeMode = expression ]
{
$case(pNotificationType, 
	$$$eAlertNotificationRequest: $$$Text("Request","Ensemble"),
	$$$eAlertNotificationReminder: $$$Text("Reminder","Ensemble"),
	$$$eAlertNotificationEscalationChange: $$$Text("Escalation Change","Ensemble"),
	: "")
}

}
