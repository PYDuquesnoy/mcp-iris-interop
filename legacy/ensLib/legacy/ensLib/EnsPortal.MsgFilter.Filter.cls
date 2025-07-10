/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.MsgFilter.Filter Extends (%SerialObject, %XML.Adaptor) [ System = 4 ]
{

Parameter HEADERCLASS = "Ens.MessageHeader";

/// Message types
Property Type As %String(DISPLAYLIST = ",Session Start,Request,Response,All", VALUELIST = ",0,1,2,3") [ InitialExpression = 0 ];

/// How to sort data
Property SortOrder As %String(DISPLAYLIST = ",Oldest First,Newest First", VALUELIST = ",1,2") [ InitialExpression = 2 ];

/// Number of rows to display
Property MaxRows As %Integer(MINVAL = 1);

/// Time format
Property TimeFormat As %String(DISPLAYLIST = ",Time Only,Complete", VALUELIST = ",12,999") [ InitialExpression = 999 ];

/// Errors
Property IsError As %Integer;

/// Starting date/time
Property StartTime As %String;

/// Starting ID value
Property StartId As %Integer;

/// Message status
Property Status As Ens.DataType.MessageStatus;

/// End date/time
Property EndTime As %String;

/// End ID value
Property EndId As %Integer;

/// Source
Property Source As %String(MAXLEN = 128);

/// Target
Property Target As %String(MAXLEN = 128);

/// Special Sequence Manager-related searches.
Property SequenceManagerSearch As %String(VALUELIST = ",Dups,Gaps,Lates");

/// Number of rows used in a TOP expression.
Property TopCount As %Integer;

/// Not used in new portal at present, but stored from old portal.
Property ColorBy As %String(VALUELIST = ",TimeCreated,SessionId,Status,Error,Source");

/// List of terms for this Filter.
Property Terms As list Of EnsPortal.MsgFilter.Term;

/// Timeout to quit doing PostRS checks from within the query
Property Timeout As %Numeric [ Transient ];

/// SQL statement generated from the supplied criteria. This property
/// is used by the UI to get the SQL statement.
Property GeneratedSQL As %String(MAXLEN = "") [ Transient ];

/// Saves the last search for the current browser tab
/// (%session can be shared among browser windows so we use var>pKey</var> to prevent unwanted mixup between browser windows).
/// Serialize the current Filter to IRISTEMP.
Method SaveToVirtualSession(ByRef pKey As %Integer) As %Status
{
	If $G(pKey)<1 {
		Set pKey = ##class(EnsPortal.SessionEvents).GetTempNode()
	}
	Set tStatus = ..%SerializeObject(.tSerial)
	If $$$ISERR(tStatus) Quit tStatus
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pKey) = tSerial
	Do ..SaveToSession() // Also save to the CSP session
	Quit $$$OK
}

/// Deserialize a Filter from IRISTEMP using the key supplied in <var>pKey</var>.
ClassMethod LoadFromVirtualSession(ByRef pKey As %Integer, Output pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Set tSC = $$$OK
	Set pFilter = $$$NULLOREF
	Set tSerial = $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pKey))
	If tSerial '= "" {
		Set pFilter = ..%Open(tSerial)
	}
	If '$IsObject(pFilter) {
		Set tSC = ..LoadFromSession(.pFilter) // fall back to last filter from this CSP session if this is a new tab
	}
	Quit tSC
}

/// Remove the Filter specified by <var>pKey</var> from IRISTEMP.
ClassMethod DeleteFromVirtualSession(ByRef pKey As %Integer) As %Status
{
	If ($G(pKey)<1) || ('$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pKey))) {
		Quit $$$ERROR($$$DeleteObjectNotFound, $classname(), pKey) 
	}
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
	Kill %session.Data("Ensemble","SearchCriteria",$namespace)
	Set tStatus = ..%SerializeObject(.tSerial)
	If $$$ISERR(tStatus) Quit tStatus
	Set %session.Data("Ensemble","SearchCriteria",$namespace) = tSerial
	Quit $$$OK
}

/// Remove the current saved Filter from the CSP session.
ClassMethod DeleteFromSession() As %Status
{
	If '$IsObject($get(%session)) Quit $$$OK

	Kill %session.Data("Ensemble","SearchCriteria",$namespace)
	Quit $$$OK
}

/// Deserialise a Filter from the current CSP session, or create a new Filter object
/// if no serialised data exists.
ClassMethod LoadFromSession(Output pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Kill pFilter
	If '$IsObject($get(%session))  {
		Set pFilter = ..%New()
	}
	Else {
		Set pFilter = ""
		Set tSerial = $get(%session.Data("Ensemble","SearchCriteria",$namespace))
		If tSerial '= "" {
			Set pFilter = ..%Open(tSerial)
		}
		If '$IsObject(pFilter) {
			Set pFilter = ..%New()
		}
	}
	Quit $$$OK
}

/// Serialise the current Filter to IRISTEMP.
Method SaveToTemp(Output pKey As %Integer) As %Status
{
	Kill pKey
	Set pKey = 0
	Set tStatus = ..%SerializeObject(.tSerial)
	If $$$ISERR(tStatus) Quit tStatus
	
	Set pKey = ##class(EnsPortal.SessionEvents).GetTempNode()
	Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pKey) = tSerial
	Quit $$$OK
}

/// Deserialise a Filter from IRISTEMP using the key supplied in <var>pKey</var>
ClassMethod LoadFromTemp(pKey As %Integer = 0, Output pFilter As EnsPortal.MsgFilter.Filter) As %Status
{
	Kill pFilter
	Set pFilter = ""
	If pKey <= 0 {
		Quit $$$ERROR($$$LoadObjectNotFound,$classname(), pKey) 
	}
	
	Set tSerial = $get(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pKey))
	If tSerial = "" {
		Quit $$$ERROR($$$LoadObjectNotFound,$classname(), pKey) 
	}
	Set pFilter = ..%Open(tSerial)
	If '$IsObject(pFilter) {
		Quit $$$ERROR($$$LoadObjectNotFound,$classname(), pKey) 
	}
	
	Quit $$$OK
}

/// Remove the Filter specified by <var>pKey</var> from IRISTEMP.
ClassMethod DeleteFromTemp(pKey As %Integer = 0) As %Status
{
	If (pKey <= 0) || ('$data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,pKey))) {
		Quit $$$ERROR($$$DeleteObjectNotFound,$classname(), pKey) 
	}
	Do ##class(EnsPortal.SessionEvents).KillTempNode(pKey)
	Quit $$$OK
}

/// Find the next valid term in the terms list, skipping over adjacent OR's and leading or trailing OR's
Method NextTerm(ByRef iTerm) As EnsPortal.MsgFilter.Term
{
	Set tPrev = $$$NULLOREF
	Set tCount = ..Terms.Count()
	Set tFirstIter = (iTerm > 1)
	Set tFirstCall = 'tFirstIter
	Set iTerm = (iTerm - 1)
	For {
		Set iTerm = iTerm + 1
		Quit:(iTerm > tCount)
		Set tTerm = ..Terms.GetAt(iTerm)
		Continue:'$IsObject(tTerm)
		If '(tFirstIter || tTerm.IsValid()) { 
			Set tTerm = $$$NULLOREF
		}
		ElseIf '$IsObject(tPrev) {
			Set tPrev = tTerm
			Set tTerm = $$$NULLOREF
		}
		ElseIf (tPrev.Type = "OR") && ((tTerm.Type = "OR") || tFirstCall) { 
			Set tPrev = tTerm
			Set tTerm = $$$NULLOREF
		}
		Else { Quit }
		Set tFirstIter=0 ; we have already checked iTerm.IsValid() for the first one incoming, except for the very first time.
	}
	If '$IsObject(tPrev) Quit $$$NULLOREF
	If (tPrev.Type = "OR") && '$IsObject(tTerm) Quit $$$NULLOREF
	Quit tPrev
}

ClassMethod HasDefaultVals(pFilter As EnsPortal.MsgFilter.Filter) As %Boolean
{
	Quit:(pFilter.Terms.Count() > 0) 0
	Set tNew = ..%New()
	Set tDefault = 1
	For tProp="Type","IsError","StartTime","StartId","Status","EndTime","EndId","Source","Target","SequenceManagerSearch" {
		If ($property(pFilter,tProp) '= $property(tNew,tProp)) {
			Set tDefault = 0
			Quit
		}
	}
	Quit tDefault
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
<Value>searchIdentifier</Value>
</Value>
</Data>
<State>FilterState</State>
<StreamLocation>^EnsPortal.MsgFilter.FilterS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
