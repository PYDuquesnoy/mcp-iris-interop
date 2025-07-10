/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Datatype class for actions that update a <class>Ens.Alerting.ManagedAlert</class>.
/// Values are as follows:
/// <ul><li>1 - Assign to a different owner</li>
/// <li>2 - Change the Open status</li>
/// <li>4 - Change Escalation Level</li>
/// <li>8 - Change Next Action Time</li>
/// <li>16 - Send a notification for a Managed Alert</li>
/// <li>32 - Log an action to indicate that the alert reoccurred</li>
/// </ul>
/// Values up to 512 (inclusive) are reserved for use by InterSystems IRIS.
/// User extensions should use 1024 and greater.
Class Ens.DataType.ManagedAlertAction Extends %Integer [ System = 4 ]
{

Parameter MINVAL = 0;

/// Note that bits up 
Parameter MAXVAL = 63;

/// Check that the value is valid.
ClassMethod IsValid(%val As %RawString) As %Status [ ServerOnly = 0 ]
{
	If (%val = $char(0)) Quit $$$OK
	If (%val < ..#MINVAL) Quit $$$ERROR($$$DTMinVal,%val,..#MINVAL)
	If (%val > ..#MAXVAL) Quit $$$ERROR($$$DTMaxVal,%val,..#MAXVAL)
	Quit $$$OK
}

/// Helper method to represent the action using localised text.
ClassMethod GetText(pAction As %Integer = 0, pSep As %String = " | ") As %String
{
	Set tText = ""
	If $$$AND(pAction,$$$eAlertActionAssign) Set tText = tText _ $listbuild($$$Text("Assign","Ensemble"))
	If $$$AND(pAction,$$$eAlertActionOpenChange) Set tText = tText _ $listbuild($$$Text("Close","Ensemble"))
	If $$$AND(pAction,$$$eAlertActionEscalationChange) Set tText = tText _ $listbuild($$$Text("Change Escalation Level","Ensemble"))
	If $$$AND(pAction,$$$eAlertActionNextActionChange) Set tText = tText _ $listbuild($$$Text("Change Next Action Time","Ensemble"))
	If $$$AND(pAction,$$$eAlertActionSendUpdate) Set tText = tText _ $listbuild($$$Text("Send Update","Ensemble"))
	If $$$AND(pAction,$$$eAlertActionReoccurrence) Set tText = tText _ $listbuild($$$Text("Alert Reoccurred","Ensemble"))
	Quit $select(tText = "": "", 1: $ListToString(tText,pSep))
}

}
