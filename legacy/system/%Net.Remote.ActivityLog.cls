/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Recent activity log for Object Gateway Servers.
Class %Net.Remote.ActivityLog Extends %Persistent [ System = 3 ]
{

Property DateTime As %TimeStamp;

Property RecordType As %String(DISPLAYLIST = ",Debug,Info,Warning,Error", VALUELIST = ",0,1,2,3");

Property GatewayName As %String;

Property GatewayType As %String;

Property Server As %String;

Property Port As %String;

Property Text As %String(MAXLEN = "");

Property Job As %String;

Index NameTSIndex On (GatewayName, DateTime);

Index TSIndex On DateTime;

/// Lookup by Gateway Name.
Query ByName(name As %String) As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,DateTime,RecordType,Job,Text") [ SqlProc ]
{
SELECT %ID, DateTime, RecordType, Job, Text
FROM ActivityLog
WHERE GatewayName = :name
ORDER BY %ID DESC
}

/// Lookup by Gateway Name and DateTime range.
Query ByNameDateTime(name As %String, ts1 As %TimeStamp = "1900-01-10", ts2 As %TimeStamp = "2030-01-10") As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,DateTime,RecordType,Job,Text") [ SqlProc ]
{
SELECT %ID, DateTime, RecordType, Job, Text
FROM ActivityLog
WHERE GatewayName = :name AND DateTime >= :ts1 AND DateTime <= :ts2
ORDER BY %ID DESC
}

/// Lookup all Gateways by DateTime range.
Query ByDateTime(ts1 As %TimeStamp = "1900-01-10", ts2 As %TimeStamp = "2030-01-10") As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID,DateTime,GatewayName,GatewayType,RecordType,Job,Text") [ SqlProc ]
{
 SELECT %ID, DateTime, GatewayName, %EXTERNAL(GatewayType) As Type, %EXTERNAL(RecordType) As RecordType, Job, Text
 FROM ActivityLog
 WHERE DateTime >= :ts1 AND DateTime <= :ts2
 ORDER BY %ID DESC
}

/// Purge Gateway activity log records older than a given number of days (default 7 days).
ClassMethod Purge(pDays As %Integer = 7, Output pDeleted As %Integer) As %Status
{
	Set tSC = $$$OK
	Set pDeleted = 0
	Try {
		Set tKeep = $ZD($P($H,",",1)-pDays,3)_" 23:59:59"
		&sql( DELETE FROM ActivityLog WHERE DateTime <= :tKeep )
		Set pDeleted = $G(%ROWCOUNT)
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, "Error while purging activity log: "_$ZE_" (SQLCODE="_$G(SQLCODE)_")")
	}
	Quit $$$OK
}

Storage Default
{
<Data name="ActivityLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DateTime</Value>
</Value>
<Value name="3">
<Value>RecordType</Value>
</Value>
<Value name="4">
<Value>GatewayName</Value>
</Value>
<Value name="5">
<Value>GatewayType</Value>
</Value>
<Value name="6">
<Value>Server</Value>
</Value>
<Value name="7">
<Value>Port</Value>
</Value>
<Value name="8">
<Value>Text</Value>
</Value>
<Value name="9">
<Value>Job</Value>
</Value>
</Data>
<DataLocation>^IRIS.Temp.Gateway.ActivityLogD</DataLocation>
<DefaultData>ActivityLogDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^IRIS.Temp.Gateway.ActivityLogD</IdLocation>
<IndexLocation>^IRIS.Temp.Gateway.ActivityLogI</IndexLocation>
<StreamLocation>^IRIS.Temp.Gateway.ActivityLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
