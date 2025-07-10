/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Alerting.Rule.FunctionSet Extends Ens.Rule.FunctionSet [ System = 4 ]
{

/// Function to determine whether a Managed Alert with the same AlertText and
/// SourceConfigName as the supplied <var>AlertRequest</var> has been created
/// within the previous <var>Seconds</var> seconds.
/// If such a Managed Alert does exist, the ID of the Managed Alert is returned.
/// If <var>LogUpdate</var> is true, then this function will assume that a new
/// ManagedAlert will NOT be created and will log an update to the existing
/// ManagedAlert to indicate that the alert has reoccurred.
ClassMethod IsRecentManagedAlert(AlertRequest As Ens.AlertRequest = "", Seconds As %Integer = 300, LogUpdate As %Boolean = 0) As %Integer
{
	Quit ##class(Ens.Alerting.Utils).FindRecentManagedAlert(AlertRequest,Seconds,LogUpdate)
}

}
