/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a simple EMail Alert Operation. 
/// <p> InterSystems IRIS automatically sends all Ens.AlertRequest messages to the production item named Ens.Alert, if it exists.
/// This production item may be a business operation, like this one, or it may be a routing process 
/// that provides logic to direct alerts to various business operations.</p>
/// <p> InterSystems IRIS sends all Ens.AlertRequest messages to the Event Log, regardless of whether or not Ens.Alert exists.
/// If there is no production item named Ens.Alert, the place to find alert messages is in the Event Log.</p>
/// This class can also send email message for Managed Alerts created by InterSystems IRIS.
Class EnsLib.EMail.AlertOperation Extends Ens.Alerting.NotificationOperation [ ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter ADAPTER = "EnsLib.EMail.OutboundAdapter";

Parameter SETTINGS = "IncludeDetails:Basic,SubjectPrefix:Basic,IncludeNodeinSubject:Basic,IncludeManagedAlertHistory:Basic";

Property Adapter As EnsLib.EMail.OutboundAdapter;

/// Control whether detailed information is added to emails sent for standard <class>Ens.AlertRequest</class>
/// messages. The default is 0 (or False) for backward compatibility reasons.
Property IncludeDetails As %Boolean [ InitialExpression = 0 ];

/// Control whether all Managed Alert actions will be included in the email, and the order in which the actions are included.
Property IncludeManagedAlertHistory As %Integer(DISPLAYLIST = ",False,Oldest First,Newest First", VALUELIST = ",0,1,2") [ InitialExpression = 0 ];

/// Prefix to include in the subject of emails sent by this system.
Property SubjectPrefix As %String;

/// This controls whether network information for the node is included in the subject of the outgoing email.
/// If you have many InterSystems IRIS installations on multiple systems, this may make it much
/// simpler to identify which system issued an alert.
Property IncludeNodeinSubject As %Boolean [ InitialExpression = 0 ];

/// Property to hold the basic text used to separate sub-sections of each email message.
Property SepLine As %String [ InitialExpression = "===============================================================" ];

Method OnMessage(pRequest As %Library.Persistent, Output pResponse As Ens.Response) As %Status
{
	If pRequest.%Extends("Ens.Alerting.NotificationRequest") {
		Quit ..OnAlertNotification(pRequest,.pResponse)
	}
	Quit ..OnAlertRequest(pRequest,.pResponse)
}

/// Main handler for requests of type <class>Ens.AlertRequest</class>.
/// If <property>IncludeDetails</property> is true, then the actual output will be
/// performed in <method>CreateEmailFromAlertRequest</class>.
Method OnAlertRequest(pAlertRequest As Ens.AlertRequest, Output pResponse As Ens.Response) As %Status
{
	If ..IncludeDetails {
		Set tSC = ..CreateEmailFromAlertRequest(pAlertRequest,.tMailMessage)
		If $$$ISERR(tSC) Quit tSC
	}
	Else {
		Set tMailMessage = ##class(%Net.MailMessage).%New()
		Set tMailMessage.Subject = "InterSystems IRIS alert from " _ ..InstanceName _ ":"_pAlertRequest.SourceConfigName
		Set tMailMessage.Charset = "UTF-8"
		If (pAlertRequest.AlertDestination '= "") {
			#; if the Ens.AlertRequest supplied an AlertDestination, then add it to the list of configured Recipients
			Set tSC=..Adapter.AddRecipients(tMailMessage, pAlertRequest.AlertDestination)  Quit:$$$ISERR(tSC) tSC
		}
		Set tSC = tMailMessage.TextData.Write(pAlertRequest.AlertText)
		Quit:$$$ISERR(tSC) tSC
	}
	Quit ..Adapter.SendMail(tMailMessage)
}

/// Create a notification email from a standard <class>Ens.AlertRequest</class> object.
Method CreateEmailFromAlertRequest(pAlertRequest As Ens.AlertRequest, Output pMailMessage As %Net.MailMessage) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set pMailMessage = ##class(%Net.MailMessage).%New()
		Set pMailMessage.Charset = "UTF-8"
		Set pMailMessage.Subject = ..SubjectPrefix _ $select(..SubjectPrefix '= "": " ", 1: "")

		Do ..GetSystemInfo(,.tSystemName,.tInstanceName,.tNodeName)

		If ..IncludeNodeinSubject {
			Set pMailMessage.Subject = pMailMessage.Subject _ $$$FormatText($$$Text("InterSystems IRIS Alert from configuration item '%1' in system '%2' on node '%3'","Ensemble"),pAlertRequest.SourceConfigName,tSystemName,tNodeName)
		}
		Else {
			Set pMailMessage.Subject = pMailMessage.Subject _ $$$FormatText($$$Text("InterSystems IRIS Alert from configuration item '%1' on system '%2'","Ensemble"),pAlertRequest.SourceConfigName,tSystemName)
		}

		If (pAlertRequest.AlertDestination '= "") {
			Set tStatus = ..Adapter.AddRecipients(pMailMessage, pAlertRequest.AlertDestination)
			If $$$ISERR(tStatus) Quit
		}
		Set tNow = $$$timeUTC
		Set tNowLocal = $$$timeUTCtoLocal(tNow)
		Set tTimeMessage = $select(..IncludeUTCTimes: $$$FormatText($$$Text("InterSystems IRIS alert email triggered at %1 [%2 UTC]","Ensemble"),tNowLocal,tNow), 1 : $$$FormatText($$$Text("InterSystems IRIS alert email triggered at %1","Ensemble"),tNowLocal))
		Set tStatus = pMailMessage.TextData.WriteLine(tTimeMessage)
		If $$$ISERR(tStatus) Quit
		Set tStatus = ..AddBasicData(pMailMessage,pAlertRequest.AlertText,pAlertRequest.AlertTime,pAlertRequest.SourceConfigName,$get($$$EnsRuntime("Name")),pAlertRequest.SessionId,tSystemName,tInstanceName)
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Send a notification email for the incoming <class>Ens.Alerting.NotificationRequest</class> in <var>pNotificationRequest</var>.
Method OnAlertNotification(pNotificationRequest As Ens.Alerting.NotificationRequest, Output pResponse As Ens.Response) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tMailMessage = ##class(%Net.MailMessage).%New()
		Set tMailMessage.Charset = "UTF-8"
		Set tMailMessage.Subject = $select(..SubjectPrefix '= "": ..SubjectPrefix _ " ", 1: "")

		Set tManagedAlert = pNotificationRequest.ManagedAlert
		Do ..GetSystemInfo(tManagedAlert,.tSystemName,.tInstanceName,.tNodeName)
		
		If ..IncludeNodeinSubject {
			Set tMailMessage.Subject = tMailMessage.Subject _ $$$FormatText($$$Text("InterSystems IRIS ManagedAlert from configuration item '%1' in system '%2' on node '%3'","Ensemble"),tManagedAlert.SourceConfigName,tSystemName,tNodeName)
		}
		Else {
			Set tMailMessage.Subject = tMailMessage.Subject _ $$$FormatText($$$Text("InterSystems IRIS ManagedAlert from configuration item '%1' on system '%2'","Ensemble"),tManagedAlert.SourceConfigName,tSystemName)
		}
		If pNotificationRequest.NotificationType '= $$$eAlertNotificationRequest {
			Set tUpdateSubject = $case(pNotificationRequest.NotificationType, 
				$$$eAlertNotificationReminder: $$$Text("Reminder","Ensemble"),
				$$$eAlertNotificationEscalationChange: $$$Text("Escalation Change","Ensemble"),
				: "")
			If (tUpdateSubject '= "") {
				Set tMailMessage.Subject = tMailMessage.Subject _ " [" _ tUpdateSubject _ "]"
			}
			Set tStatus = ..GetUpdateText(pNotificationRequest,.tUpdateText)
			If $$$ISERR(tStatus) Quit
			If ($get(tUpdateText) '= "") {
				Set tStatus = tMailMessage.TextData.WriteLine(tUpdateText)
				If $$$ISERR(tStatus) Quit
				Set tStatus = tMailMessage.TextData.WriteLine(..SepLine)
				If $$$ISERR(tStatus) Quit
			}
		}

		For i=1:1:pNotificationRequest.AlertDestinations.Count() {
			Set tDestination = pNotificationRequest.AlertDestinations.GetAt(i)
			If (tDestination '= "") {
				Set tStatus = tMailMessage.To.Insert(tDestination)
				If $$$ISERR(tStatus) Quit
			}
		}
		If $$$ISERR(tStatus) Quit

		Set tStatus = ..AddBasicData(tMailMessage,tManagedAlert.AlertText,tManagedAlert.AlertTime,tManagedAlert.SourceConfigName,tManagedAlert.Production,tSystemName,tInstanceName)
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine(..SepLine)
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Managed Alert Data","Ensemble"))
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine(..SepLine)
		If $$$ISERR(tStatus) Quit

		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Managed Alert ID","Ensemble") _ ":" _ $char(9,9) _ tManagedAlert.%Id())
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Next Action Time","Ensemble") _ ":" _ $char(9,9) _ $$$timeUTCtoLocal(tManagedAlert.NextActionTime) _ $select(..IncludeUTCTimes: "  [" _ tManagedAlert.NextActionTime _ " UTC]", 1: ""))
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Escalation Level","Ensemble") _ ":" _ $char(9,9) _ tManagedAlert.EscalationLevel)
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Current Owner","Ensemble") _ ":" _ $char(9,9) _ $select(tManagedAlert.CurrentOwner = "": "[" _ $$$Text("No current owner","Ensemble") _ "]", 1: tManagedAlert.CurrentOwner))
		If $$$ISERR(tStatus) Quit
		Set tLastActionTime = tManagedAlert.LastActionTime
		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Last Action Time","Ensemble") _ ":" _ $char(9,9) _ $$$timeUTCtoLocal(tLastActionTime) _ $select(..IncludeUTCTimes: "  [" _ tLastActionTime _ " UTC]", 1: ""))
		If $$$ISERR(tStatus) Quit
		Set tStatus = tMailMessage.TextData.WriteLine($$$Text("Next Monitor Time","Ensemble") _ ":" _ $char(9,9) _ $$$timeUTCtoLocal(tManagedAlert.NextMonitorTime) _ $select(..IncludeUTCTimes: "  [" _ tManagedAlert.NextMonitorTime _ " UTC]", 1: ""))
		If $$$ISERR(tStatus) Quit
		
		If ..IncludeManagedAlertHistory {
			Set tStatus = ..AddManagedAlertHistory(tMailMessage,tManagedAlert)
			If $$$ISERR(tStatus) Quit
		}
		
		Set tStatus = ..Adapter.SendMail(tMailMessage)
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Helper method to write properties common to basic <class>Ens.AlertRequest</class> and
/// <class>Ens.Alerting.ManagedAlert</class> instances.
Method AddBasicData(pMailMessage As %Net.MailMessage, pAlertText As %String = "", pAlertTime As Ens.DataType.UTC = "", pSourceConfigName As %String = "", pProduction As %String = "", pSessionId As %Integer = "", pSystemName As %String = "", pInstanceName As %String = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Alert Text","Ensemble") _ ":" _ $char(9,9) _ pAlertText)
		If $$$ISERR(tStatus) Quit
		Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Alert Time","Ensemble") _ ":" _ $char(9,9) _ $select(pAlertTime = "" : $$$Text("Unknown","Ensemble"), 1: $$$timeUTCtoLocal(pAlertTime) _ $select(..IncludeUTCTimes: "  [" _  pAlertTime _ " UTC]", 1: "")))
		If $$$ISERR(tStatus) Quit
		Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Production","Ensemble") _ ":" _ $char(9,9) _ $select(pProduction = "": $$$Text("Unknown","Ensemble"), 1: pProduction))
		If $$$ISERR(tStatus) Quit
		Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Source","Ensemble") _ ":" _ $char(9,9) _ pSourceConfigName)
		If $$$ISERR(tStatus) Quit
		If (pSessionId '= "") {
			Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Session","Ensemble") _ ":" _ $char(9,9) _ pSessionId)
			If $$$ISERR(tStatus) Quit
		}
		If (pSystemName '= "") {
			Set tStatus = pMailMessage.TextData.WriteLine($$$Text("System","Ensemble") _ ":" _ $char(9,9) _ pSystemName)
			If $$$ISERR(tStatus) Quit
		}
		If (pInstanceName '= "") {
			Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Instance","%Utility") _ ":" _ $char(9,9) _ pInstanceName)
			If $$$ISERR(tStatus) Quit
		}
		
		Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Node","Ensemble") _ ":" _ $char(9,9) _ ##class(%SYS.System).GetNodeName())
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

/// Helper method to write out the Managed Alert History for a given ManagedAlert instance.
Method AddManagedAlertHistory(pMailMessage As %Net.MailMessage, pManagedAlert As Ens.Alerting.ManagedAlert) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set tActionCount = pManagedAlert.Actions.Count()
		If (tActionCount > 0) {
			Set tStatus = pMailMessage.TextData.WriteLine(..SepLine)
			If $$$ISERR(tStatus) Quit
			Set tStatus = pMailMessage.TextData.WriteLine($$$Text("Managed Alert Action History","Ensemble"))
			If $$$ISERR(tStatus) Quit
			Set tStatus = pMailMessage.TextData.WriteLine(..SepLine)
			If $$$ISERR(tStatus) Quit
			If ..IncludeManagedAlertHistory = 1 {
				Set tStart = tActionCount
				Set tIncrement = -1
				Set tEnd = 1
			}
			Else {
				Set tStart = 1
				Set tIncrement = 1
				Set tEnd = tActionCount
			}
			For i=tStart:tIncrement:tEnd {
				Set tAction = pManagedAlert.Actions.GetAt(i)
				If $IsObject(tAction) {
					Set tStatus = pMailMessage.TextData.WriteLine("(" _ i _ ")" _ $char(9,9) _ $$$Text("Action Time","Ensemble") _ ": " _ $$$timeUTCtoLocal(tAction.ActionTime) _ $select(..IncludeUTCTimes: " [" _ tAction.ActionTime _ " UTC]", 1: ""))
					If $$$ISERR(tStatus) Quit
					Set tStatus = pMailMessage.TextData.WriteLine($char(9,9) _ $$$Text("User","Ensemble") _ ": " _ tAction.Username)
					If $$$ISERR(tStatus) Quit
					Set tStatus = pMailMessage.TextData.WriteLine($char(9,9) _ $$$Text("Reason","Ensemble") _ ": " _ tAction.Reason)
					If $$$ISERR(tStatus) Quit
					#; Only write out changes if there are any
					If (tAction.OldValues.Next("") '= "") {
						Set tStatus = pMailMessage.TextData.WriteLine($char(9,9) _ $$$Text("Changed Values","Ensemble") _ ":")
						If $$$ISERR(tStatus) Quit
						Set tPropName = ""
						For {
							Set tOldValue = tAction.OldValues.GetNext(.tPropName)
							If (tPropName = "") Quit
							Set tNewValue = tAction.NewValues.GetAt(tPropName)
							Set tStatus = pMailMessage.TextData.WriteLine($char(9,9,9) _ tPropName _": '" _ tOldValue _ "' => '" _ tNewValue _ "'")
							If $$$ISERR(tStatus) Quit
						}
						If $$$ISERR(tStatus) Quit
					}
					Set tStatus = pMailMessage.TextData.WriteLine()
					If $$$ISERR(tStatus) Quit
				}
			}
		}
	}
	Catch {
		Set tStatus = $$$EnsSystemError
	}
	Quit tStatus
}

}
