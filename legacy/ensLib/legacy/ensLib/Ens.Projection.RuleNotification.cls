/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Projection.RuleNotification Extends %Projection.AbstractProjection [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String) As %Status
{
	if classname="Ens.Rule.Notification" quit $$$OK
	set ^Ens.Rule.Notification(classname)=""
	quit $$$OK
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String) As %Status
{
	kill ^Ens.Rule.Notification(classname)
	quit $$$OK
}

}
