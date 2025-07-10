/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter Extends EnsPortal.MsgFilter.Filter [ System = 4 ]
{

Parameter XMLTYPE = "EnterpriseFilter";

/// Number of rows to display. Initialised to 1000 for Enterprise Searches.
Property MaxRows As %Integer(MINVAL = 1) [ InitialExpression = 1000 ];

/// List of client systems to restrict a search to.
Property ClientIDs As list Of %String;

/// Timeout to send to the system actually running the query.
Property Timeout As %Numeric [ InitialExpression = 2 ];

/// Reference to temporary node ID to use when paging through results.
/// The value is stored separately from the main Filter to ensure that
/// new nodes are used each time a query is executed.
Property TempNode As %Integer [ Transient ];

/// Name of the system currently being traversed when paging through results.
Property CurrSystem As %String [ Transient ];

/// Uniquely identifies the last search for the current browser tab
/// (%session can be shared among browser windows so we use this identifier to prevent unwanted mixup between browser tabs).
Property searchIdentifier As %Integer [ InitialExpression = 0, Internal ];

/// Helper method to supply an object of type <class>EnsPortal.MsgFilter.Filter</class>
/// that can be sent to client systems.
Method GetBasicFilter(Output pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set pFilter = ""
	Set tStatus = ..%SerializeObject(.tSerial)
	If $$$ISERR(tStatus) Quit tStatus
	// force the OID to be of type EnsPortal.MsgFiler.Filter
	Set tSerial = $$$oidInsertClassName(tSerial,"EnsPortal.MsgFilter.Filter")
	Set tFilter = ##class(EnsPortal.MsgFilter.Filter).%Open(tSerial,,.tStatus)
	If $$$ISERR(tStatus) Quit tStatus
	Set pFilter = tFilter
	Quit $$$OK
}

/// Update the current temp node storage in the CSP session.
/// If a previous node exists for the session, then the data for the old node is cleared.
ClassMethod SetSessionTempNode(pNode As %Integer = "") As %Status
{
	If '$IsObject($get(%session)) Quit $$$OK
	Set tOldNode = ..GetSessionTempNode()
	If (tOldNode '= "") Do ##class(EnsPortal.SessionEvents).KillTempNode(tOldNode)
	If 'pNode {
		Kill %session.Data("Ensemble","Enterprise","SearchCriteria",$namespace,"TempNode")
	}
	Else {
		Set %session.Data("Ensemble","Enterprise","SearchCriteria",$namespace,"TempNode") = pNode
	}
	Quit $$$OK
}

/// Wrapper method to return the value of the current TempNode ID for this session.
ClassMethod GetSessionTempNode() As %Integer [ CodeMode = expression ]
{
$select('$IsObject($get(%session)): "", 1: $get(%session.Data("Ensemble","Enterprise","SearchCriteria",$namespace,"TempNode")))
}

/// Update the current temp node storage in the CSP virtual session.
/// If a previous node exists for the virtual session, then the data for the old node is cleared.
ClassMethod SetVirtualSessionTempNode(pNode As %Integer = 0, pKey As %Integer = 0) As %Status
{
	If '$IsObject($get(%session)) Quit $$$OK
	Set tOldNode = ..GetVirtualSessionTempNode(pKey)
	If (tOldNode '= "") Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey,tOldNode)
	If 'pNode {
		Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey,"TempNode")
	}
	Else {
		Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey,"TempNode") = pNode
	}
	Quit $$$OK
}

/// Wrapper method to return the value of the current TempNode ID for this virtual session.
ClassMethod GetVirtualSessionTempNode(pKey As %Integer = 0) As %Integer [ CodeMode = expression ]
{
$select('$IsObject($get(%session)): "", 1: $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey,"TempNode")))
}

ClassMethod GetReference(pNode As %Integer = 0, pKey As %Integer = 0) As %String [ CodeMode = expression ]
{
$name(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey,pNode))
}

/// Set property searchIdentifier to the corresponding location <var>pKey</var>, if not set yet.
/// Serialize the current Filter to IRISTEMP.
Method SaveToVirtualSession(ByRef pKey As %Integer) As %Status
{
	If $G(pKey)<1 {
		Set pKey = ..searchIdentifier  // pKey is not passed in when this is called from Ens.Enterprise.Portal.MsgFilter.EnterpriseAssistant::EnumerateExecute()
	}
	If $G(pKey)<1 {
		Do ##class(EnsPortal.SessionEvents).Initialize()
		Set pKey = $increment(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise"))
	}
	Set ..searchIdentifier = pKey
	
	
	Do ..SetVirtualSessionTempNode(0,pKey)
	Set tStatus = ..%SerializeObject(.tSerial)
	If $$$ISERR(tStatus) Quit tStatus
	If ..TempNode Do ..SetVirtualSessionTempNode(..TempNode,pKey)
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey) = tSerial
	Do ..SaveToSession() // Also save to the CSP session
	Quit $$$OK
}

/// Deserialize a Filter from IRISTEMP using the key supplied in <var>pKey</var>.
ClassMethod LoadFromVirtualSession(ByRef pKey As %Integer = 0, Output pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set tSC = $$$OK
	Set pFilter = $$$NULLOREF
	Set tSerial = $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey))
	If tSerial '= "" {
		Set pFilter = ..%Open(tSerial)
	}
	If '$IsObject(pFilter) {
		Set tSC = ..LoadFromSession(.pFilter) // fall back to last filter from this CSP session if this is a new tab
	}
	Set pFilter.TempNode = ..GetVirtualSessionTempNode(pKey)
	Quit tSC
}

/// Remove the Filter specified by <var>pKey</var> from IRISTEMP.
ClassMethod DeleteFromVirtualSession(ByRef pKey As %Integer) As %Status
{
	If ($G(pKey)<1) || ('$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,"Enterprise",pKey))) {		
		Quit $$$ERROR($$$DeleteObjectNotFound, $classname(), pKey) 
	}
	Do ..SetVirtualSessionTempNode(0,pKey)
	Set tNew = ..%New()
	Set tSC = tNew.SaveToVirtualSession(pKey) // replace saved filter with default filter
	Quit tSC
}

/// Serialise the current Filter to the CSP session.
Method SaveToSession() As %Status
{
	If '$IsObject($get(%session)) {
		Quit $$$OK
	}
	Do ..SetSessionTempNode("")
	Kill %session.Data("Ensemble","Enterprise","SearchCriteria",$namespace)
	Set tStatus = ..%SerializeObject(.tSerial)
	If $$$ISERR(tStatus) Quit tStatus
	If ..TempNode Do ..SetSessionTempNode(..TempNode)
	Set %session.Data("Ensemble","Enterprise","SearchCriteria",$namespace) = tSerial
	Quit $$$OK
}

/// Remove the current saved Filter from the CSP session.
ClassMethod DeleteFromSession() As %Status
{
	If '$IsObject($get(%session)) Quit $$$OK
	
	Do ..SetSessionTempNode("")
	Kill %session.Data("Ensemble","Enterprise","SearchCriteria",$namespace)
	Quit $$$OK
}

/// Deserialise a Filter from the current CSP session, or create a new Filter object
/// if no serialised data exists.
ClassMethod LoadFromSession(Output pFilter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Status
{
	Kill pFilter
	If '$IsObject($get(%session))  {
		Set pFilter = ..%New()
	}
	Else {
		Set pFilter = ""
		Set tSerial = $get(%session.Data("Ensemble","Enterprise","SearchCriteria",$namespace))
		If tSerial '= "" {
			Set pFilter = ..%Open(tSerial)
			Set pFilter.TempNode = ..GetSessionTempNode()
			Set pFilter.searchIdentifier=0 // do not want to retain the searchIdentifier property from another tab
		}
		If '$IsObject(pFilter) {
			Set pFilter = ..%New()
		}
		
	}
	Quit $$$OK
}

ClassMethod HasDefaultVals(pFilter As Ens.Enterprise.Portal.MsgFilter.EnterpriseFilter) As %Boolean
{
	Quit:(pFilter.ClientIDs.Count() > 0) 0
	Quit ##super(pFilter)
}

Storage Default
{
<Data name="FilterState">
<Value name="1">
<Value>Type</Value>
</Value>
<Value name="2">
<Value>SortOrder</Value>
</Value>
<Value name="3">
<Value>MaxRows</Value>
</Value>
<Value name="4">
<Value>TimeFormat</Value>
</Value>
<Value name="5">
<Value>IsError</Value>
</Value>
<Value name="6">
<Value>StartTime</Value>
</Value>
<Value name="7">
<Value>StartId</Value>
</Value>
<Value name="8">
<Value>Status</Value>
</Value>
<Value name="9">
<Value>EndTime</Value>
</Value>
<Value name="10">
<Value>EndId</Value>
</Value>
<Value name="11">
<Value>Source</Value>
</Value>
<Value name="12">
<Value>Target</Value>
</Value>
<Value name="13">
<Value>SequenceManagerSearch</Value>
</Value>
<Value name="14">
<Value>TopCount</Value>
</Value>
<Value name="15">
<Value>Terms</Value>
</Value>
<Value name="16">
<Value>ColorBy</Value>
</Value>
<Value name="17">
<Value>Clients</Value>
</Value>
<Value name="18">
<Value>ClientIDs</Value>
</Value>
<Value name="19">
<Value>Timeout</Value>
</Value>
<Value name="20">
<Value>searchIdentifier</Value>
</Value>
</Data>
<Type>%Storage.Serial</Type>
}

}
