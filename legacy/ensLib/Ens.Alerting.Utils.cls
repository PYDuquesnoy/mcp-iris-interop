/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Utility class that primarily serves as a wrapper for retrieving configuration data from the
/// current production and supplying defaults otherwise.
Class Ens.Alerting.Utils [ Abstract, System = 4 ]
{

Parameter DEFAULTACTIONWINDOW = 60;

/// Get the default number of minutes in which we expect users to take action.
ClassMethod GetDefaultActionWindow() As %Integer [ CodeMode = expression ]
{
$get($$$ConfigProdSetting("AlertActionWindow"),..#DEFAULTACTIONWINDOW)
}

/// Get the config name of the Notification Manager component in the current production.
ClassMethod GetNotificationManager() As %String [ CodeMode = expression ]
{
$get($$$ConfigProdSetting("AlertNotificationManager"))
}

/// Get the config name of the default Notification Operation in the current production.
ClassMethod GetDefaultNotificationOperation() As %String [ CodeMode = expression ]
{
$get($$$ConfigProdSetting("AlertNotificationOperation"))
}

/// Get a comma-separated list of default recipients for notifications in the current production.
ClassMethod GetDefaultNotificationRecipients() As %String [ CodeMode = expression ]
{
$get($$$ConfigProdSetting("AlertNotificationRecipients"))
}

/// Get the AlertGroups setting for a given config item in the current production.
ClassMethod GetItemAlertGroups(pConfigName As %String = "") As %String [ CodeMode = expression ]
{
$select(pConfigName = "": "", 1: $get($$$ConfigSetting(pConfigName,"Host","AlertGroups")))
}

/// Get the Business partner name for a given config item in the current production.
ClassMethod GetItemBusinessPartner(pConfigName As %String = "") As %String [ CodeMode = expression ]
{
$select(pConfigName = "": "", 1: $get($$$ConfigSetting(pConfigName,"Host","BusinessPartner")))
}

/// Utility method to ensure that a rule actually exists.
ClassMethod ConfirmRuleExists(pRuleName As %String = "") As %Status
{
	Set tRuleClass = ##class(Ens.Projection.Rule).ResolveRuleAlias(pRuleName)
	If tRuleClass = "" Quit $$$ERROR($$$EnsErrRuleAliasNotFound,pRuleName)
	Quit $$$OK
}

/// Function to determine whether a Managed Alert with the same AlertText and
/// SourceConfigName as the supplied <var>pAlertRequest</var> has been created
/// within the previous <var>pSeconds</var> seconds.
/// If such a Managed Alert does exist, the ID of the Managed Alert is returned.
/// If <var>pLogUpdate</var> is true, then this function will assume that a new
/// ManagedAlert will NOT be created and will log an update to the existing
/// ManagedAlert to indicate that the alert has reoccurred.
/// Note that the IsRecentManagedAlert() function in <class>Ens.Alerting.Rule.FunctionSet</class>
/// is a thin wrapper around this method, so care should be taken to maintain compatibility.
ClassMethod FindRecentManagedAlert(pAlertRequest As Ens.AlertRequest = "", pSeconds As %Integer = 300, pLogUpdate As %Boolean = 0) As %Integer
{
	Set tManagedAlertID  = 0
	If $IsObject(pAlertRequest) && (pSeconds > 0) {
		#; Convert Time to ID range to make actual query rely on bitmap indices,
		#; but leave 100 rows as a buffer just in case the AlertTime isn't 
		#; quite monotonically increasing along with the ID
		Set tNow = $$$timeUTC
		Set tCutoffTime = $system.SQL.DATEADD("ss",-pSeconds,tNow)

		&sql(SELECT TOP 1 ID INTO :tCutoffID
			FROM Ens_Alerting.ManagedAlert
			WHERE AlertTime <= :tCutoffTime
			ORDER BY AlertTime DESC, ID ASC
		)
		If SQLCODE = 100 {
			Set tCutoffID = 0
		}
		ElseIf SQLCODE {
			Set tCutoffID = -1
		}
		Else {
			Set tCutoffID = $select(tCutoffID > 100: tCutoffID - 100, 1: 0)
		}
		If (tCutoffID >= 0) {
			#; Perform actual query to find the first ID that matches
			Set tFoundID = 0
			&sql(SELECT TOP 1 ID INTO :tFoundID
			FROM Ens_Alerting.ManagedAlert
			WHERE ID > :tCutoffID
				AND SourceConfigName = :pAlertRequest.SourceConfigName
				AND IsOpen = 1
				AND AlertText = :pAlertRequest.AlertText
				AND AlertTime >= :tCutoffTime ORDER BY ID ASC
			)
			If (SQLCODE = 0) {
				Set tManagedAlertID = tFoundID
			}
			#; Otherwise tManagedAlertID should remain 0

			If (tManagedAlertID && pLogUpdate) {
				Set tStatus = ##class(Ens.Alerting.ManagedAlert).UpdateManagedAlert(tManagedAlertID,$$$eAlertActionReoccurrence,,$$$Text("Alert Reoccurred","Ensemble"))
				If $$$ISERR(tStatus) $$$LOGSTATUS(tStatus)
			}
		}
	}
	Quit tManagedAlertID
}

}
