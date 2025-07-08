/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Monitor Audit event counts.<br>
/// 
Class %Monitor.System.AuditCount Extends %Monitor.System.Adaptor [ System = 4 ]
{

Parameter APPLICATION [ Internal ] = "CACHE";

Parameter INDEX = "EventName";

/// Full name of the event
Property EventName As %Monitor.String;

/// Enabled
Property Enabled As %Monitor.String;

/// Audit events lost
Property Lost As %Monitor.Integer;

/// Audit events written
Property Written As %Monitor.Integer;

/// Total audit events
Property Total As %Monitor.Integer;

Property Rset As %Library.ResultSet [ Internal ];

/// On Startup initialize the query
Method Startup() As %Status
{
 Set ..Rset = ##class(%ResultSet).%New("Security.Events:ListSourceTypeName")
 Quit $$$OK
}

/// On Shutdown close the cconsole file
Method Shutdown() As %Status
{
	Quit $$$OK
}

/// Execute the query
Method Initialize() As %Status
{
 s EventSources="*"
 s EventTypes="*"
 s EventNames="*"
 d ..Rset.Execute(EventSources,EventTypes,EventNames)
 Quit $$$OK
}

/// Get the audit counts
/// A return code of $$$OK indicates there is a new sample instance.
/// A return code of 0 indicates there is no sample instance.
Method GetSample() As %Status
{
	Set rc = ..Rset.Next(.sc)
	If 'rc Q 0
	s ..EventName = ..Rset.Data("EventName")
	s ..Enabled = ..Rset.Data("Enabled")
	s ..Total = ..Rset.Data("Total")
	s ..Written = ..Rset.Data("Written")
	s ..Lost = ..Rset.Data("Lost")
	Q $$$OK
}

}
