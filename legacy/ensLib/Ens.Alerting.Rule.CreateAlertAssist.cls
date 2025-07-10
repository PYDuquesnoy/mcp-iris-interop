/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Rule Assistant for rules that determine whether a Managed Alert should be created.
Class Ens.Alerting.Rule.CreateAlertAssist Extends Ens.Rule.Assist [ System = 4 ]
{

ClassMethod GetDescription() As %String [ CodeMode = expression ]
{
$$$Text("Creation Rule for Managed Alerts","Ensemble")
}

ClassMethod GetContextClass() As %String [ CodeMode = expression ]
{
"Ens.Alerting.Context.CreateAlert"
}

}
