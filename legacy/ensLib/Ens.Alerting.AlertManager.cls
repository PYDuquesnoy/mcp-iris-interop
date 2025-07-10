/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsWorkflow

/// Business Process that should run as Ens.Alert in user productions to handle <class>Ens.AlertRequest</class> requests.
/// The main step in this process is to determine whether the incoming <class>Ens.AlertRequest</class> should be
/// handled as a <class>ManagedAlert</class>.
Class Ens.Alerting.AlertManager Extends Ens.Alerting.BaseProcess [ System = 4 ]
{

Parameter SETTINGS = "CreateManagedAlertRule:Basic:ruleSelector";

/// Name of the rule to invoke when determining whether the incoming <class>Ens.AlertRequest</class> should
/// be handled as a <class>ManagedAlert</class>. 
/// The rule should be configured to accept a context of type <class>Ens.Alerting.Context.CreateAlert</class>,
/// which includes properties allowing the user to initialise values of the <class>ManagedAlert</class>.
Property CreateManagedAlertRule As %String(MAXLEN = 256);

/// Handle incoming requests.
Method OnRequest(pRequest As Ens.AlertRequest, Output pResponse As %Library.Persistent) As %Status
{
	Set pResponse = ""
	Set tStatus = $$$OK
	Try {
		If pRequest.%Extends("Ens.AlertRequest") {
			Set tStatus = ..OnAlertRequest(pRequest)
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tStatus = $$$ERROR($$$EnsErrRequestNotHandled,$classname(pRequest)_"::"_pRequest.%Id())
			Quit 
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Basic method for handling an incoming <class>Ens.AlertRequest</class>.
Method OnAlertRequest(pAlertRequest As Ens.AlertRequest) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = ..OnProcessAlertRequest(pAlertRequest,.tProcessingComplete)
		If $$$ISERR(tStatus)

		If $get(tProcessingComplete) {
			$$$LOGINFO($$$FormatText($$$Text("Not creating managed alert for AlertRequest with ID '%1' due to user override","Ensemble"),pAlertRequest.%Id()))
			Quit
		}

		Set tInitialOwner = ""
		#; If no rule is defined, assume we should create a task
		If ..CreateManagedAlertRule = "" {
			Set tCreateAlert = 1
		}
		Else {
			Set tStatus = ..GetCreateAlertContext(pAlertRequest,.tAlertContext)
			If $$$ISERR(tStatus) Quit
			
			Set tStatus = ##class(Ens.Rule.Definition).EvaluateRules(..CreateManagedAlertRule,..%SessionId,tAlertContext,"",.tCreateAlert,.tCreateReason)
			If $$$ISERR(tStatus) Quit
			Set tInitialOwner = tAlertContext.Owner
		}

		If 'tCreateAlert {
			$$$LOGINFO($$$FormatText($$$Text("Not creating managed alert for AlertRequest with ID '%1' due to rule '%2'","Ensemble"),pAlertRequest.%Id(),..CreateManagedAlertRule))
			Quit
		}

		Set tStatus = ..OnCreateManagedAlert(pAlertRequest,.tManagedAlert,tInitialOwner)
		If $$$ISERR(tStatus) Quit

		Set tStatus = tManagedAlert.%Save()
		If $$$ISERR(tStatus) Quit

		Set tNotificationManager = ##class(Ens.Alerting.Utils).GetNotificationManager()
		If tNotificationManager = "" {
			Set tStatus = $$$ERROR($$$EnsErrGeneral,$$$Text("Notification Manager is not defined for production '%1'","Ensemble"))
			Quit
		}
		
		Set tNotificationRequest = ##class(Ens.Alerting.NotificationRequest).%New()
		Set tNotificationRequest.ManagedAlert = tManagedAlert
		
		Set tStatus = ..SendRequestSimSync(tNotificationManager,tNotificationRequest,0)
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Callback to allow users to implement any actions they choose in subclasses.
/// The <var>pProcessingComplete</var> flag controls whether any further actions should 
/// be taken for the current alert. If all intended actions have been completed, then
/// <var>pProcessingComplete</var> should be set to true.
Method OnProcessAlertRequest(pAlertRequest As Ens.AlertRequest, Output pProcessingComplete As %Boolean) As %Status
{
	Set pProcessingComplete = 0
	Quit $$$OK
}

/// Callback to create the rule context used for the rule to decide whether a ManagedAlert should be
/// created for the AlertRequest supplied in <var>pAlertRequest</var>.
/// Users can override this method in subclasses to supply context objects based on the user's requirements.
Method GetCreateAlertContext(pAlertRequest As Ens.AlertRequest, Output pCreateAlertContext As Ens.Alerting.Context.CreateAlert) As %Status
{
	Set pCreateAlertContext = ##class(Ens.Alerting.Context.CreateAlert).%New()
	Set pCreateAlertContext.AlertRequest = pAlertRequest
	If (pAlertRequest.SourceConfigName '= "") {
		Set pCreateAlertContext.AlertGroups = ##class(Ens.Alerting.Utils).GetItemAlertGroups(pAlertRequest.SourceConfigName)
		Set pCreateAlertContext.BusinessPartner = ##class(Ens.Alerting.Utils).GetItemBusinessPartner(pAlertRequest.SourceConfigName)
	}
	Quit $$$OK
}

/// Callback to create the actual instance of <class>Ens.Alerting.ManagedAlert</class>.
/// Users can override this in subclasses to make use of their own subclass of <class>Ens.Alerting.ManagedAlert</class>.
Method OnCreateManagedAlert(pAlertRequest As Ens.AlertRequest, Output pManagedAlert As Ens.Alerting.ManagedAlert, pInitialOwner As %String = "") As %Status
{
	Set pManagedAlert = ##class(Ens.Alerting.ManagedAlert).Create(pAlertRequest,$get($$$EnsRuntime("Name")),pInitialOwner,.tStatus)
	Quit tStatus
}

/// Ensure that Notification Manager is defined for the current production, and that the rule 
/// specified in <property>CreateManagedAlertRule</property> exists.
Method OnInit() As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tNotificationManager = ##class(Ens.Alerting.Utils).GetNotificationManager()
		If tNotificationManager = "" {
			Set tStatus = $$$ERROR($$$EnsErrGeneral,$$$FormatText($$$Text("Notification Manager is not defined for production '%1'","Ensemble"),$get($$$EnsRuntime("Name"))))
			Quit
		}
		If ..CreateManagedAlertRule '= "" {
			Set tStatus = ##class(Ens.Alerting.Utils).ConfirmRuleExists(..CreateManagedAlertRule)
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Add connection to the Production's AlertNotificationManager
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If $IsObject(pItem) && $IsObject(pItem.Production) {
		Set prod = pItem.Production
		Set notifMgrSetting = prod.FindSettingByName("AlertNotificationManager")
		Set:$IsObject(notifMgrSetting)&&(""'=notifMgrSetting.Value) pArray(notifMgrSetting.Value) = ""
	}
	Quit
}

Storage Default
{
<Data name="AlertManagerDefaultData">
<Subscript>"AlertManager"</Subscript>
<Value name="1">
<Value>CreateManagedAlertRule</Value>
</Value>
</Data>
<DefaultData>AlertManagerDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
