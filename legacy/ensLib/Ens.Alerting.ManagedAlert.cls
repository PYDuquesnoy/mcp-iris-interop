/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Class to provide the basic infrastructure for managing and tracking Alerts that occur in productions.
Class Ens.Alerting.ManagedAlert Extends (%Persistent, %XML.Adaptor, Ens.Util.BitmapPurge) [ System = 4 ]
{

/// Parameter to control whether the pAction parameter passed to the <method>Update</method>()
/// is explicitly validated against the <class>Ens.DataType.ManagedAlertAction</class> datatype.
/// Users should override this setting if they extend this class and need to add their own actions.
/// Note that InterSystems IRIS reserves all action values up to and including 512 (i.e. 2^9), so any user-defined actions 
/// should start with bit 10 (i.e. 1024).
Parameter VALIDATEACTION As BOOLEAN = 1;

/// The time the original Alert was triggered.
Property AlertTime As Ens.DataType.UTC [ Required ];

/// The name of the production in which the original Alert was triggered.
Property Production As %String(MAXLEN = 128);

/// The config item that triggered the original Alert.
Property SourceConfigName As %String(MAXLEN = 128);

/// The text of the original Alert.
Property AlertText As %String(MAXLEN = "");

/// The session in which the Alert occurred.
Property SessionId As %Integer;

/// The name of the Business Partner associated with the source of the alert.
Property BusinessPartner As %String(MAXLEN = 128);

/// The AlertGroups which should be used to determine where notifications should be sent.
Property AlertGroups As %String(MAXLEN = 2500);

/// The user currently responsible for the ManagedAlert.
Property CurrentOwner As %String(MAXLEN = 256);

/// The escalation level of the ManagedAlert. This can be increased manually or be raised after no activity takes
/// place within a user-defined period of time.
Property EscalationLevel As %Integer [ InitialExpression = 0 ];

/// The history of all previous actions that have been performed on this ManagedAlert.
Property Actions As list Of Ens.Alerting.Action(STORAGEDEFAULT = "array");

/// Flag to indicate whether the ManagedAlert is open or closed.
Property IsOpen As %Boolean [ InitialExpression = 1, Required ];

/// The time before which an action should occur for this ManagedAlert.
Property NextActionTime As Ens.DataType.UTC;

/// Calculated property to dynamically determine the last time an action occurred for this ManagedAlert.
Property LastActionTime As Ens.DataType.UTC [ Calculated, SqlComputeCode = { Set {LastActionTime} = ##class(Ens.Alerting.ManagedAlert).GetLastActionTime({ID}) }, SqlComputed ];

/// The next time the Alert Monitor should check the status of this ManagedAlert.
/// This is calculated automatically using the following logic: <ul style="list-style-type: none;">
/// <li>If a user is updating an alert, and doesn't change the <property>NextActionTime</property>,
/// no change will be made. (This ensures the monitor schedule is regular.)</li>
/// <li>If <property>NextActionTime</property> is in the future, then that time will be used.</li>
/// <li>If <property>NextActionTime</property> is in the past (i.e. an action is overdue), then
/// the production's Alert Action Window setting will be used to calculate the time the
/// Alert Monitor should check the ManagedAlert.</li></ul>
Property NextMonitorTime As Ens.DataType.UTC [ ReadOnly, SqlComputeCode = {Set {NextMonitorTime} = ##class(Ens.Alerting.ManagedAlert).ComputeNextMonitorTime({NextActionTime})}, SqlComputed, SqlComputeOnChange = NextActionTime ];

/// Flag to indicate whether the current manipulation of the ManagedAlert is being performed
/// by the alerting framework. It's primary purpose is to ensure that user actions don't modify
/// <property>NextMonitorTime</property> unless <property>NextActionTime</property> is also modified.
/// This is necessary to ensure that the monitoring behaviour for escalation and reminders is not affected
/// by general changes to an alert.
/// This property should <strong>NOT</strong> be modified by users.
Property %IsFrameworkActivity As %Boolean [ InitialExpression = 0, Internal, Transient ];

Index Open On IsOpen [ Type = bitmap ];

Index AlertTime On AlertTime;

Index CurrentOwner On CurrentOwner [ Type = bitmap ];

Index Source On SourceConfigName [ Type = bitmap ];

Index AlertGroups On AlertGroups(ELEMENTS) As Exact [ Type = bitmap ];

Index EscLevel On EscalationLevel [ Type = bitmap ];

/// NextAction is on both NextActionTime and IsOpen as the UI needs to identify both of these fields as cheaply as possible.
Index NextAction On (IsOpen, NextActionTime);

/// NextMonitor is on both NextActionTime and IsOpen as the AlertMonitor component needs to identify these fields as cheaply as possible.
Index NextMonitor On (IsOpen, NextMonitorTime);

/// Helper method to create a ManagedAlert based on the contents of an <class>Ens.AlertRequest</class> instance.
ClassMethod Create(pAlertRequest As Ens.AlertRequest = "", pProduction As %String = "", pOwner As %String = "", Output pStatus As %Status) As Ens.Alerting.ManagedAlert
{
	Set pStatus = $$$OK
	Set tManagedAlert = ""
	Try {
		Set tManagedAlert = ..%New()
		Set tManagedAlert.AlertText = pAlertRequest.AlertText
		Set tManagedAlert.AlertTime = pAlertRequest.AlertTime
		Set tManagedAlert.SessionId = pAlertRequest.SessionId
		Set tManagedAlert.SourceConfigName = pAlertRequest.SourceConfigName
		If (tManagedAlert.SourceConfigName '= "") {
			Set tManagedAlert.AlertGroups = ##class(Ens.Alerting.Utils).GetItemAlertGroups(pAlertRequest.SourceConfigName)
			Set tManagedAlert.BusinessPartner = ##class(Ens.Alerting.Utils).GetItemBusinessPartner(pAlertRequest.SourceConfigName)
		}
		Set tManagedAlert.Production = $select(pProduction '= "": pProduction, 1: $get($$$EnsRuntime("Name")))
		Set tManagedAlert.CurrentOwner = pOwner
		Set tManagedAlert.NextActionTime = tManagedAlert.GetNextActionTime(.pStatus)
		If $$$ISERR(pStatus) Quit
		// Ensure NextMonitorTime is initialized
		Set pStatus = tManagedAlert.UpdateNextMonitorTime(0)
		If $$$ISERR(pStatus) Quit
	}
	Catch {
		Set pStatus = $$$SystemError
	}
	If $$$ISERR(pStatus) Quit ""
	Quit tManagedAlert
}

/// Method to update a Managed Alert. The arguments are as follows:
/// <ul><li><var>pAction</var> - The bits indicating what actions should take place.</li>
/// <li><var>pNewValues</var> - An array of the new values to set subscripted by property name.</li>
/// <li><var>pReason</var> - A required string to indicate why the action is being taken.</li>
Method UpdateAlert(pAction As Ens.DataType.ManagedAlertAction, ByRef pNewValues As %String, pReason As %String = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		#; Allow users to specify that pAction NOT be validated so that user-specified actions
		#; can be accepted.
		If ..#VALIDATEACTION {
			Set tStatus = ##class(Ens.DataType.ManagedAlertAction).IsValid(pAction)
			If $$$ISERR(tStatus) Quit
		}

		Set tAction = ##class(Ens.Alerting.Action).%New()
		Set tAction.Reason = pReason
		
		If $$$AND(pAction,$$$eAlertActionAssign) {
			Set tStatus = ..UpdateValue($$$eAlertActionAssign,tAction,"CurrentOwner",$get(pNewValues("CurrentOwner")))
			If $$$ISERR(tStatus) Quit
		}

		If $$$AND(pAction,$$$eAlertActionOpenChange) {
			Set tOpen = ''$get(pNewValues("IsOpen"),..IsOpen)
			If (tOpen '= ..IsOpen) {
				Set tStatus = ..UpdateValue($$$eAlertActionOpenChange,tAction,"IsOpen",tOpen)
				If $$$ISERR(tStatus) Quit
			}
		}

		If $$$AND(pAction,$$$eAlertActionEscalationChange) {
			Set tNewLevel = $get(pNewValues("EscalationLevel"),..EscalationLevel)
			If (tNewLevel '= ..EscalationLevel) && (tNewLevel >= 0) && (tNewLevel = +tNewLevel) {
				Set tStatus = ..UpdateValue($$$eAlertActionEscalationChange,tAction,"EscalationLevel",tNewLevel)
				If $$$ISERR(tStatus) Quit
			}
		}

		If $$$AND(pAction,$$$eAlertActionNextActionChange) {
			Set tNextActionTime = $get(pNewValues("NextActionTime"),..NextActionTime)
			If (tNextActionTime '= ..NextActionTime) {
				Set tStatus = ..UpdateValue($$$eAlertActionNextActionChange,tAction,"NextActionTime",tNextActionTime)
				If $$$ISERR(tStatus) Quit
			}
		}

		If $$$AND(pAction,$$$eAlertActionReoccurrence) {
			Set tAction.Action = tAction.Action + $$$eAlertActionReoccurrence
		}

		If $$$AND(pAction,$$$eAlertActionSendUpdate) {
			#; The SendUpdate action only shifts the NextActionTime, which occurs independently
			Set tAction.Action = tAction.Action + $$$eAlertActionSendUpdate
		}

		#; Invoke user callback to handle other possible actions or changes.
		Set tStatus = ..OnUpdateAlert(pAction,.pNewValues,tAction)
		If $$$ISERR(tStatus) Quit

		#; Only add the action if tAction has any bits set
		If (tAction.Action > 0) {
			Set tStatus = ..Actions.Insert(tAction)
			If $$$ISERR(tStatus) Quit

			Set tStatus = ..%Save()
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// User callback invoked from <method>UpdateAlert</method>() to allow users to specify
/// extended action types and extra values.
Method OnUpdateAlert(pActionValue As Ens.DataType.ManagedAlertAction, ByRef pNewValues As %String, pActionObject As Ens.Alerting.Action) As %Status
{
	Quit $$$OK
}

/// Helper method to wrap an update in an <class>Action</class>.
Method UpdateValue(pActionBit As Ens.DataType.ManagedAlertAction = 0, pAction As Ens.Alerting.Action, pProperty As %String, pNewValue As %String) As %Status [ Internal ]
{
	Set tStatus = $$$OK
	Try {
		If '$$$AND(pAction.Action,pActionBit) Set pAction.Action = pAction.Action + pActionBit
		Do pAction.OldValues.SetAt($property($this,pProperty),pProperty)
		Set $property($this,pProperty) = pNewValue
		Do pAction.NewValues.SetAt($property($this,pProperty),pProperty)
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Helper method to return a valid <property>NextMonitorTime</property> value.
/// If <var>pNextActionTime</var> is in the future, then <var>pNextActionTime</var> is returned.
/// Otherwise, the production's Alert Action Window setting is used to calculate the next time.
ClassMethod ComputeNextMonitorTime(pNextActionTime As Ens.DataType.UTC) As Ens.DataType.UTC
{
	Set tNow = $$$timeUTC
	If (pNextActionTime ]] tNow) {
		Quit pNextActionTime
	}
	Set tDefaultWindow = ##class(Ens.Alerting.Utils).GetDefaultActionWindow()
	Quit $system.SQL.DATEADD("mi",tDefaultWindow,tNow)
}

/// Accessor method for <property>LastActionTime</property>.
/// It simply gets the ActionTime from the most recent action in <property>Actions</property>,
/// and the value of <property>AlertTime</property> if no actions have been logged.
Method LastActionTimeGet() As Ens.DataType.UTC
{
	Set tLastAction = ..Actions.GetPrevious("")
	If $IsObject(tLastAction) {
		Quit tLastAction.ActionTime
	}
	Quit ..AlertTime
}

/// Accessor method for <property>LastActionTime</property> that can be invoked from SQL.
/// The method uses the same approach as <method>LastActionTimeGet</method>(), just in SQL.
ClassMethod GetLastActionTime(pID As %Integer) As Ens.DataType.UTC
{
	Set tStatement = ##class(%SQL.Statement).%New()
	Set tStatement.%SelectMode = 0
	If $$$ISOK(tStatement.%Prepare("SELECT TOP 1 Actions_ActionTime As LastActionTime FROM Ens_Alerting.ManagedAlert_Actions WHERE ManagedAlert = ? ORDER BY element_key DESC")) {
		Set tRS = tStatement.%Execute(pID)
		If tRS.%Next() {
			Quit tRS.LastActionTime
		}
	}
	Quit ..AlertTimeGetStored(pID)
}

/// Calculate the next action time for the Managed Alert.
Method GetNextActionTime(Output pStatus As %Status) As Ens.DataType.UTC
{
	Set pStatus = $$$OK
	Set tNextActionTime = $$$timeUTC
	Try {
		Set tStartTime = $$$timeUTC
		Set tActionWindow = ##class(Ens.Alerting.Utils).GetDefaultActionWindow()
		Set tNextActionTime = $system.SQL.DATEADD("mi",tActionWindow,tStartTime)
	}
	Catch {
		Set pStatus = $$$SystemError
	}
	Quit tNextActionTime
}

/// Helper method to allow the individual values in AlertGroups to be indexed.
ClassMethod AlertGroupsBuildValueArray(pAlertGroups As %String = "", Output pValueArray As %String) As %Status
{
	If $get(pAlertGroups) '= "" {
		Set tCount = 0
		For i=1:1:$length(pAlertGroups,",") {
			Set tGroup = $piece(pAlertGroups,",",i)
			If (tGroup '= "") {
				Set tCount = tCount + 1
				Set pValueArray(tCount) = tGroup
			}
		}
	}
	Quit $$$OK
}

/// Helper method to invoke <method>UpdateAlert</method>() when the ManagedAlert
/// instance is not already open.
ClassMethod UpdateManagedAlert(pID As %Integer = "", pAction As Ens.DataType.ManagedAlertAction, ByRef pNewValues As %String, pReason As %String = "") As %Status
{
	If (pID = "") Quit $$$ERROR($$$LoadObjectNotFound,$classname(),pID)
	Set tStatus = $$$OK
	Try {
		Set tManagedAlert = ##class(Ens.Alerting.ManagedAlert).%OpenId(pID,,.tStatus)
		If $$$ISERR(tStatus) Quit

		Set tStatus = tManagedAlert.UpdateAlert(pAction,.pNewValues,pReason)
		If $$$ISERR(tStatus) Quit
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Helper method to update the value of <property>NextMonitorTime</property>.
/// The code is in <method>ComputeNextMonitorTime</method>(), but the logic
/// describing when <method>UpdateNextMonitorTime</method>() should be called
/// and what value it should compute is in the documentation for the
/// <property>NextMonitorTime</property> property.
Method UpdateNextMonitorTime(pSave As %Boolean = 0) As %Status
{
	Set tStatus = $$$OK
	Try {
		Set i%NextMonitorTime = ..ComputeNextMonitorTime(..NextActionTime)
		If (pSave) {
			Set tStatus = ..%Save()
			If $$$ISERR(tStatus) Quit
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

/// API to make it easier to mark some large set of managed alerts as closed.
/// The arguments that control which specific alerts are closed are as follows:
/// <ul><li><var>pErrors</var> - flag to control whether the IDs that aren't removed are 
/// reported in subscripts of the <var>pErrors</var> variable on output. By default only
/// the count is reported in <var>pErrors</var>.</li>
/// <li><var>pDaysToKeep</var> - flag to control the time window that should be closed
/// using the same logic as purges. All managed alerts that occurred more than <var>pDaysToKeep</var>
/// days in the past will be closed. The flag supports a value of -1 to ensure that ALL matching
/// managed alerts are closed, including any that were created in the past day.</li>
/// <li><var>pReason</var> - A required string to indicate why the managed alerts are being closed.</li>
/// <li><var>pConfigName</var> - An optional string to specify that managed alerts from
/// a specific SourceConfigName should be closed.</li>
/// <li><var>pCurrentOwner</var> - An optional string to specify that managed alerts assigned to
/// the specified user should be closed. The default of -1 indicates no filter should be applied,
/// as the empty string ("") is used to indicate that the managed alert is unassigned.</li>
/// <li><var>pText</var> - An optional string to filter the results by specific text. By default,
/// the filter checks whether the AlertText property contains <var>pText</var> ignoring case.
/// To use an equality filter, the first character of <var>pText</var> should be specified as "=",
/// and the remainder of <var>pText</var> will be matched against the AlertText property.
/// <br/><strong>NOTE:</strong> searches matching on AlertText may be very slow if no other filters are supplied.</li></ul>
ClassMethod BulkClose(Output pClosedCount As %Integer, ByRef pErrors As %Integer = 0, pDaysToKeep As %Integer = 30, pReason As %String = "", pConfigName As %String = "", pCurrentOwner As %String = -1, pText As %String = "") As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill pClosedCount
		Set tReportErrorIDs = ''$get(pErrors)
		Kill pErrors
		Set pErrors = 0
		Set pClosedCount = 0
		If (pReason = "") {
			Set tStatus = $$$ERROR($$$EnsErrGeneral,"pReason is required")
			Quit
		}
		If (pDaysToKeep < -1) {
			Set tStatus = $$$ERROR($$$EnsErrGeneral,"pDaysToKeep must be -1 or greater")
			Quit
		}

		Set tArgs = 0
		Set tSQL = "SELECT ID FROM Ens_Alerting.ManagedAlert WHERE IsOpen = 1"
		If (pDaysToKeep > -1) {
			Set tSQL = tSQL _ " AND AlertTime <= ?"
			Set tMidnightLocal = $zdatetime((+$horolog)_",0",3)
			Set tMidnightUTC = $$$timeLocaltoUTC(tMidnightLocal)
			Set tCutoffTime = $system.SQL.DATEADD("dd",-pDaysToKeep,tMidnightUTC)
			Set tArgs = tArgs + 1
			Set tArgs(tArgs) = tCutoffTime
			If (pDaysToKeep > 0) {
				#; Add an ID restriction using a week buffer to allow for much better use of bitmap indices
				Set tIDCutoff = $system.SQL.DATEADD("dd",-pDaysToKeep+7,tMidnightUTC)
				Set tIDRS = ##class(%SQL.Statement).%ExecDirect(,"SELECT TOP 1 ID FROM Ens_Alerting.ManagedAlert WHERE AlertTime <= ? ORDER BY AlertTime DESC, ID ASC",tIDCutoff)
				If tIDRS.%Next() {
					Set tSQL = tSQL _ " AND ID <= ?"
					Set tArgs = tArgs + 1
					Set tArgs(tArgs) = tIDRS.ID
				}
			}
		}
		If (pConfigName '= "") {
			Set tSQL = tSQL _ " AND SourceConfigName = ?"
			Set tArgs = tArgs + 1
			Set tArgs(tArgs) = pConfigName
		}
		If (pCurrentOwner '= -1) {
			If (pCurrentOwner = "") {
				Set tSQL = tSQL _ " AND CurrentOwner IS NULL"
			}
			Else {
				Set tSQL = tSQL _ " AND CurrentOwner = ? AND CurrentOwner IS NOT NULL"
				Set tArgs = tArgs + 1
				Set tArgs(tArgs) = pCurrentOwner
			}
		}
		If (pText '= "") {
			If ($extract(pText,1) = "=") {
				Set tSQL = tSQL _ " AND AlertText = ?"
				Set tArgs = tArgs + 1
				Set tArgs(tArgs) = $extract(pText,2,*)
			}
			Else {
				Set tSQL = tSQL _ " AND %SQLUPPER(AlertText) [ %SQLUPPER(?)"
				Set tArgs = tArgs + 1
				Set tArgs(tArgs) = pText
			}
		}
		Set tSQL = tSQL _ " ORDER BY ID ASC"
		Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tArgs...)
		While tRS.%Next() {
			Try {
				Kill tActionValues
				Set tActionValues("IsOpen") = 0
				Set tUpdateStatus = ##class(Ens.Alerting.ManagedAlert).UpdateManagedAlert(tRS.ID,$$$eAlertActionOpenChange,.tActionValues,pReason)
				If $$$ISOK(tUpdateStatus) {
					Set pClosedCount = pClosedCount + 1
				}
				ElseIf '$system.Status.Equals(tUpdateStatus,$$$LoadObjectNotFound,$$$NotAnInstanceError) {
					Set pErrors = pErrors + 1
					If tReportErrorIDs {
						Set pErrors(tRS.ID) = tUpdateStatus
					}
				}
			}
			Catch {
				Set tStatus = $$$SystemError
			}
			If $$$ISERR(tStatus) Quit
		}
		If $$$ISERR(tStatus) Quit
		If tRS.%SQLCODE && (tRS.%SQLCODE '= 100) {
			Set tStatus = $$$ERROR($$$SQLCode,tRS.%SQLCODE,tRS.%Message)
			Quit
		}
	}
	Catch ex {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pKeepIntegrity As %Boolean = 1, pBitmapPurgeRunLimit As %Integer = 600) As %Status
{
	Set:'$TLEVEL tTransactionSuspendedSwitch = ##class(Ens.Util.Purge.SuspendTransaction).%New($$$EnsPurgeJournalOldDataGet)

	Set tStatus = $$$OK
	Try {
		Kill pDeletedCount
		Set pDeletedCount = 0

		Set tSQL = "SELECT ID FROM Ens_Alerting.ManagedAlert WHERE AlertTime < ?"
		Set tMidnightLocal = $zdatetime((+$horolog)_",0",3)
		Set tMidnightUTC = $$$timeLocaltoUTC(tMidnightLocal)
		Set tCutoffTime = $system.SQL.DATEADD("dd",-pDaysToKeep,tMidnightUTC)

		If pKeepIntegrity {
			Set tSQL = tSQL _ " AND IsOpen = 0"
		}

		Set tRS = ##class(%SQL.Statement).%ExecDirect(,tSQL,tCutoffTime)
		While tRS.%Next() {
			Set tDelStatus = ##class(Ens.Alerting.ManagedAlert).%DeleteId(tRS.ID)
			If $$$ISERR(tDelStatus) {
				If $system.Status.Equals(tDelStatus,$$$DeleteObjectNotFound,$$$NotAnInstanceError) {
					Set tDelStatus = $$$OK
				}
				Else {
					Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsErrGeneral,"ManagedAlert purge error at ID '"_tRS.ID_"'"),tDelStatus)
					Quit
				}
			}
			Else {
				Set pDeletedCount = pDeletedCount + 1
			}
		}
		If $$$ISERR(tStatus) Quit
		If tRS.%SQLCODE && (tRS.%SQLCODE '= 100) {
			Set tStatus = $system.Status.AppendStatus($$$ERROR($$$EnsErrGeneral,"ManagedAlert purge error"),$$$ERROR($$$SQLCode,tRS.%SQLCODE,tRS.%Message))
			Quit
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Set tBitmapSC = ..PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
	Merge pDeletedCount("bitmaps") = tDeletedChunks
	Kill tTransactionSuspendedSwitch
	Quit $$$ADDSC(tStatus,tBitmapSC)
}

/// Helper method to populate which values are available for display in the UI.
/// The tree structure for <var>pProperties</var> should be as follows:<br/>
/// <var>pProperties</var> = $listbuild([names of properties])<br/>
/// <var>pProperties([propName])</var> = $listbuild([Property Title],[Editable],[Action Value],[Datatype],[Empty Value],[Use Display Value])<br/>
/// The tree structure for <var>pCollectionProperties</var> is as follows:<br/>
/// <var>pCollectionProperties</var> = $listbuild([names of collection properties])<br/>
/// <var>pCollectionProperties([collectionName])</var> = $listbuild([Collection Title],[Editable],[Action Value],[Instance Title],$listbuild([list of sub-properties to display]))<br/>
/// <var>pCollectionProperties([collectionName],[propName])</var> = $listbuild([Property Title],[Editable],[Action Value],[Datatype],[Empty Value],[Use Display Value])
ClassMethod GetProperties(Output pProperties As %List, Output pCollectionProperties As %List) As %Status
{
	Set tStatus = $$$OK
	Kill pProperties
	Kill pCollectionProperties

	Set pProperties = $lb("%ID","AlertTime","Production","SourceConfigName","AlertText","AlertGroups","IsOpen","CurrentOwner","EscalationLevel","LastActionTime","NextActionTime","NextMonitorTime")
	Set pProperties("%ID") = $lb($$$Text("ID","Ensemble"), 0, 0, "%Library.Integer")
	Set pProperties("AlertTime") = $lb($$$Text("Alert Time","Ensemble"), 0, 0, "Ens.DataType.UTC", "", 1)
	Set pProperties("Production") = $lb($$$Text("Production","Ensemble"), 0, 0, "%Library.String")
	Set pProperties("SourceConfigName") = $lb($$$Text("Source","Ensemble"), 0, 0, "%Library.String")
	Set pProperties("AlertText") = $lb($$$Text("Alert Text","Ensemble"), 0, 0, "%Library.String")
	Set pProperties("AlertGroups") = $lb($$$Text("Alert Groups","Ensemble"), 0, 0, "%Library.String")
	Set pProperties("IsOpen") = $lb($$$Text("Is Open", "Ensemble"), 1, $$$eAlertActionOpenChange, "%Library.Boolean")
	Set pProperties("CurrentOwner") = $lb($$$Text("Current Owner","Ensemble"), 1, $$$eAlertActionAssign, "%Library.String", "("_$$$Text("Unassigned","Ensemble")_")")
	Set pProperties("EscalationLevel") = $lb($$$Text("Escalation Level","Ensemble"), 1, $$$eAlertActionEscalationChange, "%Library.Integer")
	Set pProperties("NextActionTime") = $lb($$$Text("Next Action Time","Ensemble"), 1, $$$eAlertActionNextActionChange, "Ens.DataType.UTC", "", 1)
	Set pProperties("LastActionTime") = $lb($$$Text("Last Action Time","Ensemble"), 0, 0, "Ens.DataType.UTC", "", 1)
	Set pProperties("NextMonitorTime") = $lb($$$Text("Next Monitor Time","Ensemble"), 0, 0, "Ens.DataType.UTC", "", 1)

	Set pCollectionProperties = $lb("Actions")
	Set pCollectionProperties("Actions") = $lb($$$Text("Actions","Ensemble"), 0, 0, $$$Text("Action %1","Ensemble"), $lb("ActionTime","Username","Action","Reason","OldValues","NewValues"))
	Set pCollectionProperties("Actions","ActionTime") = $lb($$$Text("Action Time","Ensemble"), 0, 0, "Ens.DataType.UTC", "", 1)
	Set pCollectionProperties("Actions","Username") = $lb($$$Text("Username","Ensemble"), 0, 0, "%Library.String")
	Set pCollectionProperties("Actions","Action") = $lb($$$Text("Action","Ensemble"), 0, 0, "Ens.DataType.ManagedAlertAction", "", 1)
	Set pCollectionProperties("Actions","Reason") = $lb($$$Text("Reason","Ensemble"), 0, 0, "%Library.String")
	Set pCollectionProperties("Actions","OldValues") = $lb($$$Text("Old Values","Ensemble"), 0, 0)
	Set pCollectionProperties("Actions","OldValues","NextActionTime") = $lb("", 0, 0, "Ens.DataType.UTC", "", 1)
	Set pCollectionProperties("Actions","OldValues","CurrentOwner") = $lb("", 0, 0, "%Library.String", $$$Text("Unassigned","Ensemble"))
	Set pCollectionProperties("Actions","NewValues") = $lb($$$Text("New Values","Ensemble"), 0, 0)
	Quit tStatus
}

/// Ensure that the current user has permission to edit managed alerts.
/// Also ensure that <method>UpdateNextMonitorTime</method>() is called when saving a new
/// ManagedAlert, or when the alert management framework is performing an update,
/// or when <property>NextActionTime</property> has been modified.
Method %OnAddToSaveSet(depth As %Integer = 3, insert As %Integer = 0, callcount As %Integer = 0) As %Status [ Private, ServerOnly = 1 ]
{
	#; Check if current user has permissions to edit alerts
	If '$system.Security.Check("%Ens_Alerts","WRITE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	#; If the previous owner wasn't "" or current user, check whether user
	#; has USE permissions on %Ens_AlertAdministration
	Set tPreviousOwner = ..CurrentOwnerGetStored(..%Id())
	If (tPreviousOwner '= "") && (tPreviousOwner '= $username) && '$system.Security.Check("%Ens_AlertAdministration","USE") {
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	If insert || ..%IsFrameworkActivity || (..NextActionTime = ..NextActionTimeGetStored(..%Id())) {
		Quit ..UpdateNextMonitorTime(0)
	}
	Quit $$$OK
}

Storage Default
{
<Data name="Actions">
<Attribute>Actions</Attribute>
<Structure>subnode</Structure>
<Subscript>"Actions"</Subscript>
</Data>
<Data name="ManagedAlertDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>AlertTime</Value>
</Value>
<Value name="3">
<Value>Production</Value>
</Value>
<Value name="4">
<Value>SourceConfigName</Value>
</Value>
<Value name="5">
<Value>AlertText</Value>
</Value>
<Value name="6">
<Value>AlertGroups</Value>
</Value>
<Value name="7">
<Value>CurrentOwner</Value>
</Value>
<Value name="8">
<Value>EscalationLevel</Value>
</Value>
<Value name="9">
<Value>IsOpen</Value>
</Value>
<Value name="10">
<Value>NextActionTime</Value>
</Value>
<Value name="11">
<Value>SessionId</Value>
</Value>
<Value name="12">
<Value>BusinessPartner</Value>
</Value>
<Value name="13">
<Value>NextMonitorTime</Value>
</Value>
</Data>
<DataLocation>^Ens.Alerting.ManagedAlertD</DataLocation>
<DefaultData>ManagedAlertDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Alerting.ManagedAlertD</IdLocation>
<IndexLocation>^Ens.Alerting.ManagedAlertI</IndexLocation>
<StreamLocation>^Ens.Alerting.ManagedAlertS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
