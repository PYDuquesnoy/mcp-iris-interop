/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Rule Assistant for rules that determine what actions to take when a Managed Alert has not been updated
/// within its action window.
Class Ens.Alerting.Rule.OverdueAlertAssist Extends Ens.Rule.Assist [ System = 4 ]
{

ClassMethod GetDescription() As %String [ CodeMode = expression ]
{
$$$Text("Overdue Rule for Managed Alerts","Ensemble")
}

ClassMethod GetContextClass() As %String [ CodeMode = expression ]
{
"Ens.Alerting.Context.OverdueAlert"
}

}
