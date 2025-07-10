/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.Notification [ Abstract, ProcedureBlock, System = 4 ]
{

Projection NotificationRegistry As Ens.Projection.RuleNotification;

/// This method is to be overridden by the users to be run upon notification.
/// pReason is a string with the name of the notification event. 
/// The current support events are: BeforeSave, AfterSave and Delete
ClassMethod %OnNotify(pReason As %String, pRule As Ens.Rule.RuleDefinition) As %Status
{
	quit $$$OK
}

}
