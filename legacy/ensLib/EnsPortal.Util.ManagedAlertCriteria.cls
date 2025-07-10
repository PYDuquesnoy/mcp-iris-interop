/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Criteria specifically used by the Managed Alert Viewer.
Class EnsPortal.Util.ManagedAlertCriteria Extends (%SerialObject, EnsPortal.Util.AbstractSearchCriteria) [ System = 4 ]
{

Property SortOrder As %Integer(DISPLAYLIST = ",Newest First,Oldest First,Most Escalated First,Least Escalated First", VALUELIST = ",0,1,2,3") [ InitialExpression = 0 ];

Property CurrentOwner As %String(MAXLEN = 128);

Property IncludeUnassigned As %Boolean [ InitialExpression = 0 ];

Property IsOpen As %Boolean [ InitialExpression = 1 ];

Property MinEscalationLevel As %Integer;

Property MaxEscalationLevel As %Integer;

Property AlertGroup As %String(MAXLEN = 256);

Property PageSize As %Integer(MINVAL = 0) [ InitialExpression = 50 ];

ClassMethod Load(Output pCriteria As EnsPortal.Util.ManagedAlertCriteria, pIgnoreError As %Boolean = 0) As %Status
{
	Set tStatus = $$$OK
	Set pCriteria = ""
	If $data(^EnsPortal.Settings($username,"ManagedAlertViewer","SearchCriteria"),tSerial) {
		Set pCriteria = ..%Open(tSerial,,.tStatus)
		If $$$ISERR(tStatus) {
			If pIgnoreError {
				Set pCriteria = ""
				Set tStatus = $$$OK
			}
			Else {
				Quit tStatus
			}
		}
	}
	If '$IsObject(pCriteria) {
		Set pCriteria = ..%New()
	}
	Quit tStatus
}

Method Save() As %Status
{
	Set tStatus = $$$OK
	Set tInitTLevel = $TLevel
	Try {
		Set tStatus = ..%SerializeObject(.tSerial)
		If $$$ISERR(tStatus) Quit
		TSTART
		Set tStatus = ..Clear()
		If $$$ISERR(tStatus) Quit
		Set ^EnsPortal.Settings($username,"ManagedAlertViewer","SearchCriteria") = tSerial
		TCOMMIT
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	While (tInitTLevel < $TLevel) {
		TROLLBACK
	}
	Quit tStatus
}

ClassMethod Clear() As %Status
{
	Set tStatus = $$$OK
	Try {
		Kill ^EnsPortal.Settings($username,"ManagedAlertViewer","SearchCriteria")
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Quit tStatus
}

Storage Default
{
<Data name="ManagedAlertCriteriaState">
<Value name="1">
<Value>SortOrder</Value>
</Value>
<Value name="2">
<Value>CurrentOwner</Value>
</Value>
<Value name="3">
<Value>IncludeUnassigned</Value>
</Value>
<Value name="4">
<Value>EndTime</Value>
</Value>
<Value name="5">
<Value>MinEscalationLevel</Value>
</Value>
<Value name="6">
<Value>EndId</Value>
</Value>
<Value name="7">
<Value>AlertGroup</Value>
</Value>
<Value name="8">
<Value>PageSize</Value>
</Value>
<Value name="9">
<Value>IsOpen</Value>
</Value>
<Value name="10">
<Value>MaxEscalationLevel</Value>
</Value>
<Value name="11">
<Value>Source</Value>
</Value>
<Value name="12">
<Value>StartId</Value>
</Value>
<Value name="13">
<Value>StartTime</Value>
</Value>
<Value name="14">
<Value>TimeFormat</Value>
</Value>
</Data>
<State>ManagedAlertCriteriaState</State>
<StreamLocation>^EnsPortal2D30.ManagedAler49A6S</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
