/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Business Process that accepts incoming <class>Ens.Alerting.NotificationRequest</class> messages and determines three things:</p>
/// <ul><li>Whether a notification should actually be sent,</li>
/// <li>which operation (or operations) any notification requests should be sent to, and</li>
/// <li>which eventual recipients should be added to the notification list.</li></ul>
/// <p>For each incoming NotificationRequest, a user callback sequence is initiated from the <method>OnRequest</method>()
/// method. The three stages of the callback sequence are as follows:</p>
/// <ol><li>The <method>OnProcessNotificationRequest</method>() method is invoked. Users can
/// override this method to perform any extended custom processing they choose, as well as indicate
/// whether no further processing should be performed for the current request.</li>
/// <li>The code checks whether <property>NotificationTransform</property> is defined.
/// 	<ul><li>If no transform is defined, the default processing in stage 3 controls the behaviour.</li>
/// <li>Otherwise, the process will call the <method>GetNotifyContext</method>() helper method to create
/// a context object of type <class>Ens.Alerting.Context.Notify</class>. The helper method can be overridden to 
/// return user-defined subclasses of the context class. The incoming <class>NotificationRequest</class> object will be
/// supplied as the source of the transform, and the returned context object will be supplied as the target
/// of the transform specified in <property>NotificationTransform</property>. As a result, the transform should
/// specify create="existing" if you wish to make use of the object created by the <method>GetNotifyContext</method>() callback.
/// The transform should specify any operations that the <class>NotificationRequest</class> should be sent to using the
/// <code>Transforms</code> list of the context object that is in the target, as well as specifying the list of 
/// <code>AlertDestinations</code> for each desired target.
/// The transform should NOT update the <code>AlertDestinations</code> property of the original <class>NotificationRequest</class>,
/// as this property is ignored when processing the data.
/// The transform should specify whether a notification should be sent via the <code>Notify</code> property of the context object.</li></ul></li>
/// <li>If no actions are taken in stages 1 or 2, the process's default behaviour is to send the notification request
/// to the default Notification Operation specified for the current production.</li></ol>
Class Ens.Alerting.NotificationManager Extends Ens.Alerting.BaseProcess [ System = 4 ]
{

Parameter SETTINGS = "NotificationTransform:Basic:dtlSelector";

/// Name of the transform to invoke when determining which config items and eventual recipients the <class>NotificationRequest</class> 
/// should be sent to. 
/// The transform should be configured to accept a target of type <class>Ens.Alerting.Context.Notify</class>,
/// which includes properties allowing the user to choose the config items and alert destinations as well as specifying
/// whether a notification should be sent.
Property NotificationTransform As %String(MAXLEN = 256);

/// Handle notification requests of type <class>Ens.Alerting.NotificationRequest</class> using the callback
/// sequence described in this class comments for <class>Ens.Alerting.NotificationManager</class>.
Method OnRequest(pNotificationRequest As Ens.Alerting.NotificationRequest, Output pResponse As %Library.Persistent) As %Status
{
	Set tStatus = $$$OK
	Set pResponse = ""
	Try {
		Set tStatus = ..OnProcessNotificationRequest(pNotificationRequest,.tProcessingComplete)
		If $$$ISERR(tStatus) Quit

		If $get(tProcessingComplete) {
			$$$LOGINFO($$$FormatText($$$Text("Not sending notification for NotificationRequest with ID '%1' due to user override","Ensemble"),pNotificationRequest.%Id()))
			Quit
		}

		#; Ensure we don't have any lingering or stale destinations.
		Kill tTargets
		Do pNotificationRequest.AlertDestinations.Clear()

		#; If no transform is defined, get fallbacks
		If ..NotificationTransform = "" {
			Set tSendNotification = 1
		}
		Else {
			Set tStatus = ..GetNotifyContext(pNotificationRequest,.tNotificationContext)
			If $$$ISERR(tStatus) Quit
			
			Set tStatus = $classmethod(..NotificationTransform,"Transform",pNotificationRequest,.tNotificationContext)
			If $$$ISERR(tStatus) Quit
			If '$IsObject($get(tNotificationContext)) {
				Set tStatus = $$$ERROR($$$EnsErrGeneral,$$$FormatText("Notification Transform '%1' did not generate a notification context",..NotificationTransform))
				Quit
			}
			ElseIf 'tNotificationContext.%Extends("Ens.Alerting.Context.Notify") {
				Set tStatus = $$$ERROR($$$EnsErrGeneral,$$$FormatText("Notification Transform '%1' did not generated an invalid notification context of type '%2'",..NotificationTransform,$classname(tNotificationContext)))
				Quit
			}
			Set tSendNotification = tNotificationContext.Notify
			#; Make sure Transform doesn't append any AlertDestinations
			Do pNotificationRequest.AlertDestinations.Clear()

			#; Old code where we used a rule
			#; Set tStatus = ##class(Ens.Rule.Definition).EvaluateRules(..NotificationRule,..%SessionId,tNotificationContext,"",.tSendNotification,.tSendReason)
			#; If $$$ISERR(tStatus) Quit
			
			If tSendNotification {
				For i=1:1:tNotificationContext.Targets.Count() {
					Set tReturnedTarget = tNotificationContext.Targets.GetAt(i)
					If $IsObject(tReturnedTarget) && (tReturnedTarget.TargetConfigName '= "") {
						Set tNotification = pNotificationRequest.%ConstructClone(0)
						For j=1:1:tReturnedTarget.AlertDestinations.Count() {
							Do tNotification.AlertDestinations.Insert(tReturnedTarget.AlertDestinations.GetAt(j))
						}
						Set tCounter(tReturnedTarget.TargetConfigName) = $get(tCounter(tReturnedTarget.TargetConfigName)) + 1
						Set tNotifications(tReturnedTarget.TargetConfigName,tCounter(tReturnedTarget.TargetConfigName)) = tNotification
					}
				}
			}
		}

		If 'tSendNotification {
			$$$LOGINFO($$$FormatText($$$Text("Not sending notification for NotificationRequest with ID '%1' due to transform '%2'","Ensemble"),pNotificationRequest.%Id(),..NotificationTransform))
			Quit
		}

		If '$data(tNotifications) {
			Set tDefaultNotificationTarget = ##class(Ens.Alerting.Utils).GetDefaultNotificationOperation()
			If (tDefaultNotificationTarget = "") {
				Set tStatus = $$$ERROR($$$EnsAlertErrNoDefaultNotificationOperation,$get($$$EnsRuntime("Name")))
				Quit
			}

			Set tDefaultRecipients = ##class(Ens.Alerting.Utils).GetDefaultNotificationRecipients()
			If (tDefaultRecipients = "") {
				Set tStatus = $$$ERROR($$$EnsAlertErrNoDefaultNotificationRecipients,$get($$$EnsRuntime("Name")))
				Quit
			}
			Else {
				Set tCommaLen = $length(tDefaultRecipients,",")
				For i=1:1:tCommaLen {
					Set tRecipient = $zstrip($piece(tDefaultRecipients,",",i),"<>W")
					Do pNotificationRequest.AlertDestinations.Insert(tRecipient)
				}
			}
			Set tNotifications(tDefaultNotificationTarget,1) = pNotificationRequest
		}

		If '$data(tNotifications) {
			$$$LOGWARNING($$$FormatText($$$Text("No notification targets specified for NotificationRequest with ID '%1'","Ensemble"),pNotificationRequest.%Id()))
			Quit
		}

		Set tTarget = ""
		For {
			Set tTarget = $order(tNotifications(tTarget))
			Quit:(tTarget = "")
			Set tPos = ""
			For {
				Set tPos = $order(tNotifications(tTarget,tPos),1,tNotification)
				Quit:(tPos = "")
				Set tSendStatus = ..SendRequestSimSync(tTarget,tNotification,0)
				Set tStatus = $$$ADDSC(tSendStatus,tStatus)
			}
		}
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
Method OnProcessNotificationRequest(pNotificationRequest As Ens.Alerting.NotificationRequest, Output pProcessingComplete As %Boolean) As %Status
{
	Set pProcessingComplete = 0
	Quit $$$OK
}

/// Callback to create the rule context used for the rule to decide whether a NotificationRequest should be
/// sent to a Notification Operation, as well as which operations should be called, as well as the recipients for each operation.
/// Users can override this method in subclasses to supply context objects based on the user's requirements.
Method GetNotifyContext(pNotificationRequest As Ens.Alerting.NotificationRequest, Output pNotificationContext As Ens.Alerting.Context.Notify) As %Status
{
	Set pNotificationContext = ##class(Ens.Alerting.Context.Notify).%New()
	Set pNotificationContext.NotificationRequest = pNotificationRequest
	Set pNotificationContext.Notify = 1
	Quit $$$OK
}

/// Ensure that the transform specified in <property>NotificationTransform</property> exists.
Method OnInit() As %Status
{
	If (..NotificationTransform '= "") && ('##class(%Dictionary.CompiledClass).%ExistsId(..NotificationTransform)) {
		Quit $$$ERROR($$$ClassDoesNotExist,..NotificationTransform)
	}
	Quit $$$OK
}

/// Add connection to the Production's AlertNotificationOperation and targets of the NotificationTransform
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	Do ##super(.pArray,pItem)
	If $IsObject(pItem) && $IsObject(pItem.Production) {
		Set prod = pItem.Production
		Set opSetting = prod.FindSettingByName("AlertNotificationOperation")
		Set:$IsObject(opSetting)&&(opSetting.Value'="") pArray(opSetting.Value) = ""
	}
	Set trnSetting = pItem.FindSettingByName("NotificationTransform"), dtl=""
	If $IsObject(trnSetting) && (""'=trnSetting.Value) {
		For i=1:1:$$$defMemberKeyGet(trnSetting.Value,$$$cCLASSxdata,"DTL",$$$cXDATAdata) {
			Set dtl=dtl_$$$defMemberArrayGet(trnSetting.Value,$$$cCLASSxdata,"DTL",$$$cXDATAdata,i)
			#; allow for the possibility that we don't have one action per line
			If dtl[">" {
				For j=1:1:($l(dtl,">")-1) {
					Set line=$p(dtl,">",j)
					Set line = $zStrip(line,"<>W") ; remove excess whitespace
					If "<assign"=$p(line," ",1) Set configName=..findTarget(line)  Set:configName'="" pArray(configName)=""
				}
				Set dtl=$p(dtl,">",*)
			}
		}
		If "<assign"=$p(dtl," ",1) Set configName=..findTarget(dtl)  Set:configName'="" pArray(configName)=""
	}
	Quit
}

ClassMethod findTarget(line) As %String
{
	Set line = $e(line,$l("<assign")+1,*)
	Set line = $tr($zStrip(line,"<>W"),"  "," ") ; remove excess whitespace
	For i=1:1:$l(line," ") {
		Set atr=$p(line," ",i)
		Set:"property"=$p(atr,"=",1) tProp=$p(atr,"=",2)
		Set:"value"=$p(atr,"=",1) tVal=$p(atr,"=",2)
	}
	#; remove enclosing quotation marks
	If $e(tProp,1)="'",$e(tProp,*)="'",$e(tProp,2,*-1)'["'" Set tProp= $p(tProp,"'",2)
	If $e(tProp,1)="""",$e(tProp,*)="""",$e(tProp,2,*-1)'[""""   Set tProp= $p(tProp,"""",2)

	If $e(tVal,1)="'",$e(tVal,*)="'",$e(tVal,2,*-1)'["'" Set tVal= $p(tVal,"'",2)
	If $e(tVal,1)="""",$e(tVal,*)="""",$e(tVal,2,*-1)'[""""   Set tVal= $p(tVal,"""",2)
	
	If tProp?1"target.Targets.(".N1").TargetConfigName" Quit tVal
	Quit ""
}

Storage Default
{
<Data name="NotificationManagerDefaultData">
<Subscript>"NotificationManager"</Subscript>
<Value name="1">
<Value>NotificationTransform</Value>
</Value>
</Data>
<DefaultData>NotificationManagerDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
