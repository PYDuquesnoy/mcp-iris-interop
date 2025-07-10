/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsAlertErrors

/// <p>Business Service that checks whether any <class>Ens.Alerting.ManagedAlert</class> objects are open and have a next
/// action time that has passed. For each such overdue ManagedAlert, a user callback sequence is initiated from the
/// <method>ProcessOverdueAlert</method>() method. The three stages of the callback sequence are as follows:</p>
/// <ol><li>The first stage of the callback sequence calls <method>OnProcessOverdueAlert</method>(),
/// which is a method that users can override in subclasses to execute any custom code they choose, as well as indicate
/// whether all processing is complete for the current Managed Alert. The default implementation takes no action.</li>
/// <li>The second stage of the callback sequence will check whether <property>OverdueAlertRule</property> is defined.
/// 	<ul><li>If no rule is defined, the default processing in stage 3 will control the behaviour.</li>
/// 	<li>Otherwise, the service will create a rule context object of type <class>Ens.Alerting.Context.OverdueAlert</class> using 
/// the <method>GetOverdueAlertContext</method>() helper method. Users may override the helper method to instantiate 
/// user-defined subclasses of the base context. The newly created context object will then be supplied to the rule defined in 
/// <property>OverdueAlertRule</property>. The rule can update the <var>NewNextActionTime</var> or <var>NewEscalationLevel</var> 
/// properties to indicate the values of the ManagedAlert should be changed. The rule MUST return a boolean value
/// to indicate whether a reminder should be sent. Note that if the <var>EscalationLevel</var> is increased,
/// a notification will ALWAYS be sent to the Notification Manager. Furthermore, any changes made to the ManagedAlert object in the rule 
/// will be discarded by the AlertMonitor.</li></ul></li>
/// <li>If no actions are taken in stages 1 or 2, the default behaviour will always send a simple reminder request to the 
/// Notification Manager.</li></ol>
Class Ens.Alerting.AlertMonitor Extends Ens.BusinessService [ System = 4 ]
{

Parameter SETTINGS = "OverdueAlertRule::ruleSelector";

Parameter ADAPTER = "Ens.InboundAdapter";

Property Adapter As Ens.InboundAdapter;

/// Name of the Business Rule to invoke when determining what action to take for an overdue <class>ManagedAlert</class>. 
/// The rule should be configured to accept a context of type <class>Ens.Alerting.Context.OverdueAlert</class>,
/// which includes properties allowing the user to update values for the <class>ManagedAlert</class>.
Property OverdueAlertRule As %String;

/// Property to keep a reference to the prepared statement to look up open overdue Managed Alerts.
Property %SQLStatement As %SQL.Statement [ Private, Transient ];

/// Every time the adapter calls in to the service, check for any open Managed Alerts that have a
/// next action time in the past.
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	Quit ..CheckForOverdueAlerts()
}

/// Actually create a resultset using the prepared statement in <property>%SQLStatement</property> and
/// invoke the callback sequence to determine what actions should be taken for each overdue alert. All the 
/// logic for processing the alert is located in the <method>ProcessOverdueAlert</method>() method.
Method CheckForOverdueAlerts() As %Status
{
	Set tStatus = $$$OK
	Try {
		#; Reset SessionId
		Set ..%SessionId = ""
		Kill $$$JobSessionId
				
		Set tRS = ..%SQLStatement.%Execute($$$timeUTC)
		While tRS.%Next() {
			Set tOpenStatus = $$$OK
			Set tManagedAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId(tRS.ID,,.tOpenStatus)
			If $$$ISERR(tOpenStatus) {
				$$$LOGERROR($$$FormatText($$$Text("Unable to open overdue ManagedAlert with ID '%1' due to error: %2","Ensemble"),tRS.ID,$system.Status.GetErrorText(tOpenStatus)))
			}
			Else {
				Do ..ForceSessionId()
				Set tManagedAlert.%IsFrameworkActivity = 1
				Set tProcessStatus = ..ProcessOverdueAlert(tManagedAlert)
				Set tStatus = $$$ADDSC(tProcessStatus,tStatus)
			}
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// The main handler for overdue alerts. The overdue alert is passed in as <var>pManagedAlert</var>,
/// and the method moves through the callback sequence described in the main class documentation 
/// for this class (<class>Ens.Alerting.AlertMonitor</class>).
Method ProcessOverdueAlert(pManagedAlert As Ens.Alerting.ManagedAlert) As %Status
{
	Set tStatus = $$$OK
	Try {
		#; Call OnProcessOverdueAlert() -- user code can do all the work if users so desire.
		Set tStatus = ..OnProcessOverdueAlert(pManagedAlert,.tProcessingComplete)
		If $$$ISERR(tStatus) Quit

		If $get(tProcessingComplete) {
			$$$LOGINFO($$$FormatText($$$Text("Not processing overdue ManagedAlert with ID '%1' due to user override","Ensemble"),pManagedAlert.%Id()))
			// Ensure that we update NextMonitorTime if it hasn't been set or is still in the past
			If ($$$timeUTC ]] pManagedAlert.NextMonitorTime) {
				Set tStatus = pManagedAlert.UpdateNextMonitorTime(1)
				If $$$ISERR(tStatus) Quit
			}
			Quit
		}

		Set tNotificationType = $$$eAlertNotificationReminder
		#; Assume we should send a notification if no rule is specified.
		If ..OverdueAlertRule = "" {
			Set tSendNotification = 1
			Set tStatus = pManagedAlert.UpdateAlert($$$eAlertActionSendUpdate,,$$$Text("Automatic reminder sent for overdue alert.","Ensemble"))
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tStatus = ..GetOverdueAlertContext(pManagedAlert,.tOverdueContext)
			If $$$ISERR(tStatus) Quit

			Set tStatus = ##class(Ens.Rule.Definition).EvaluateRules(..OverdueAlertRule,..%SessionId,tOverdueContext,"",.tSendNotification,.tSendReason)
			If $$$ISERR(tStatus) Quit

			#; Force reload of ManagedAlert from disk -- modifications made in the rule must not be saved accidentally
			Set tAlertID = pManagedAlert.%Id()
			Kill pManagedAlert
			Set pManagedAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId(tAlertID,,.tStatus)
			If $$$ISERR(tStatus) Quit

			// Note that NextMonitorTime *MUST* be updated in this call
			Set tStatus = ..OnProcessOverdueRuleResult(pManagedAlert,tOverdueContext,.tSendNotification,.tNotificationType)
			If $$$ISERR(tStatus) Quit
		}

		If '$get(tSendNotification) {
			$$$LOGINFO($$$FormatText($$$Text("Not sending notification request for ManagedAlert with ID '%1' due to rule '%2'","Ensemble"),pManagedAlert.%Id(),..OverdueAlertRule))
			Quit
		}

		Set tNotificationManager = ##class(Ens.Alerting.Utils).GetNotificationManager()
		If (tNotificationManager = "") {
			Set tStatus = $$$ERROR($$$EnsAlertErrNoNotificationManager,$get($$$EnsRuntime("Name")))
			Quit
		}

		Set tNotificationRequest = ##class(Ens.Alerting.NotificationRequest).%New()
		Set tNotificationRequest.ManagedAlert = pManagedAlert
		Set tNotificationRequest.NotificationType = tNotificationType

		Set tStatus = ..SendRequestAsync(tNotificationManager,tNotificationRequest)
		If $$$ISERR(tStatus) Quit

		#; Reset SessionId
		Set ..%SessionId = ""
		Kill $$$JobSessionId
		Do ..ForceSessionId()
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Callback invoked while processing the overdue alert in <var>pManagedAlert</var>.
/// This method can be overridden in subclasses to take any actions a developer so chooses,
/// and the standard processing of the alert can be bypassed by setting <var>pProcessingComplete</var> to 1.
Method OnProcessOverdueAlert(pManagedAlert As Ens.Alerting.ManagedAlert, Output pProcessingComplete As %Boolean) As %Status
{
	Set pProcessingComplete = 0
	Quit $$$OK
}

/// Helper method to instantiate an <class>Ens.Alerting.Context.OverdueAlert</class> context object
/// for the rule specified in <property>OverdueAlertRule</property>. Users can subclass this method to return
/// an extended context should they wish to.
Method GetOverdueAlertContext(pManagedAlert As Ens.Alerting.ManagedAlert, Output pOverdueContext As Ens.Alerting.Context.OverdueAlert) As %Status
{
	Set pOverdueContext = ##class(Ens.Alerting.Context.OverdueAlert).%New()
	Set pOverdueContext.ManagedAlert = pManagedAlert
	Set pOverdueContext.CurrentTime = $$$timeUTC
	Quit $$$OK
}

/// Helper method to process the result of the rule specified in <property>OverdueAlertRule</property>.
/// Users can override this method, but should ensure that they handle changes to <var>pManagedAlert</var>
/// in their code or by calling ##super() to invoke the base implementation of this method. <var>pSendNotification</var>
/// is the return value from the rule, which indicates whether a notification should be sent. <var>pNotificationType</var>
/// is the type of notification that should be sent.
Method OnProcessOverdueRuleResult(pManagedAlert As Ens.Alerting.ManagedAlert, pOverdueContext As Ens.Alerting.Context.OverdueAlert, ByRef pSendNotification As %Boolean, ByRef pNotificationType As Ens.DataType.AlertNotificationType) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tOverrideNotification = 0
		Set tOverrideFields = ""
		Kill tNewValues
		For tProp = "EscalationLevel", "NextActionTime" {
			Set tNewValue = $property(pOverdueContext,"New" _ tProp)
			Set tOldValue = $property(pManagedAlert,tProp)
			If (tNewValue '= "") && (tNewValue '= tOldValue) {
				Set tNewValues(tProp) = tNewValue
				If (tProp = "EscalationLevel") && (tNewValue > tOldValue) {
					#; Make sure we send a notification if the escalation level has been increased
					Set tOverrideNotification = 1
					Set tOverrideFields = tOverrideFields _ $select(tOverrideFields = "": "", 1: "; ") _ tProp
				}
			}
		}
		
		If tOverrideNotification && 'pSendNotification {
			Set pSendNotification = 1
			$$$LOGINFO($$$FormatText($$$Text("Overriding return from rule '%1'; notification will be sent for ManagedAlert with ID '%2' as the following fields have changed: %3","Ensemble"),..OverdueAlertRule,pManagedAlert.%Id(),tOverrideFields))
		}
		
		Set tUpdated = 0
		If $data(tNewValues) {
			Set tReason = $$$FormatText($$$Text("Automatic changes made due to overdue alert rule '%1'","Ensemble"),..OverdueAlertRule)
			Set tAction = 0
			If $data(tNewValues("EscalationLevel")) {
				Set tAction = tAction + $$$eAlertActionEscalationChange
				Set pNotificationType = $$$eAlertNotificationEscalationChange
			}
			If $data(tNewValues("NextActionTime")) {
				Set tAction = tAction + $$$eAlertActionNextActionChange
			}
			If pSendNotification {
				Set tAction = tAction + $$$eAlertActionSendUpdate
			}
			If tAction {
				Set tStatus = pManagedAlert.UpdateAlert(tAction,.tNewValues,tReason)
				If $$$ISERR(tStatus) Quit
				Set tUpdated = 1
			}
		}
		ElseIf pSendNotification {
			Set tStatus = pManagedAlert.UpdateAlert($$$eAlertActionSendUpdate,,$$$Text("Automatic reminder sent for overdue alert.","Ensemble"))
			If $$$ISERR(tStatus) Quit
			Set tUpdated = 1
		}
		If 'tUpdated {
			Set tStatus = pManagedAlert.UpdateNextMonitorTime(1)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Initialise <property>%SQLStatement</property> and ensure the rule specified in <property>OverdueAlertRule</property> exists.
Method OnInit() As %Status
{
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tStatement.%SelectMode = 0
	Set tStatus = tStatement.%Prepare("SELECT ID FROM Ens_Alerting.ManagedAlert WHERE IsOpen = 1 AND NextMonitorTime <= ?")
	If $$$ISERR(tStatus) Quit tStatus
	Set ..%SQLStatement = tStatement
	
	If ..OverdueAlertRule '= "" {
		Set tStatus = ##class(Ens.Alerting.Utils).ConfirmRuleExists(..OverdueAlertRule)
		If $$$ISERR(tStatus) Quit tStatus
	}
	Quit $$$OK
}

/// Add connection to the Production's AlertNotificationManager
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If $IsObject(pItem) && $IsObject(pItem.Production) {
		Set prod = pItem.Production
		Set notifMgrSetting = prod.FindSettingByName("AlertNotificationManager")
		Set:$IsObject(notifMgrSetting)&&(notifMgrSetting.Value'="") pArray(notifMgrSetting.Value) = ""
	}
	Quit
}

}
