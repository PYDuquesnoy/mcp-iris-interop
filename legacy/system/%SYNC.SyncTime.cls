/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYNC.SyncTime Extends %Persistent [ System = 3 ]
{

Property SysId As %String;

Property Namespace As %String;

Property lTRN As %Integer;

Property rTRN As %Integer;

/// Set the last transaction in the SyncTime table for a given system and namespace. 
ClassMethod SetlTrn(syncSYSID As %String, syncNSID As %String, ltrn As %Integer) As %Status
{
	new %ROWID, %ROWCOUNT
	try {
		&sql(select %ID into :stid from SyncTime where Namespace=:syncNSID and SysId=:syncSYSID)
		if 'SQLCODE {
			&sql(update SyncTime set lTRN=:ltrn where %ID =:stid)
		} elseif SQLCODE = 100 {
			&sql(insert into SyncTime (SysId, NameSpace, lTRN) values(:syncSYSID,:syncNSID,:ltrn) )
		}
		if SQLCODE {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$Get(%msg))
		}
		set status = $$$OK
	} catch exception {
		set status = exception.AsStatus()
	}
	return status
}

ClassMethod GetlTrn(syncSYSID As %String, syncNSID As %String, ByRef ltrn As %Integer) As %Status
{
	new %ROWID, %ROWCOUNT
	try {
		&sql(select lTRN into :ltrn from SyncTime where Namespace=:syncNSID and SysId=:syncSYSID)
		if 'SQLCODE return $$$OK
		set ltrn = 0
		if SQLCODE = 100 {
			return $$$ERROR($$$GeneralError,"No matching row")
		} else {
			return $$$ERROR($$$SQLCode,SQLCODE,"Unexpected error while retrieving the last transaction ID from SyncTime: "_$Get(%msg,"no further information available"))
		}
	} catch exception {
		set status = exception.AsStatus()
	}
	return status
}

ClassMethod SetrTrn(syncSYSID As %String, syncNSID As %String, rtrn As %Integer) As %Status
{
	new %ROWID, %ROWCOUNT
	try {
		&sql(select %ID into :stid from SyncTime where Namespace=:syncNSID and SysId=:syncSYSID)
		if 'SQLCODE {
			&sql(update SyncTime set rTRN=:rtrn where %ID =:stid)
		} elseif SQLCODE = 100 {
			&sql(insert into SyncTime (SysId, NameSpace, rTRN) values(:syncSYSID,:syncNSID,:rtrn) )
		}
		if SQLCODE {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE,$Get(%msg))
		}
		set status = $$$OK
	} catch exception {
		set status = exception.AsStatus()
	}
	return status
}

ClassMethod GetrTrn(syncSYSID As %String, syncNSID As %String, ByRef rtrn As %Integer) As %Status
{
	new %ROWID, %ROWCOUNT
	&sql(select  rTRN into :rtrn from SyncTime where Namespace=:syncNSID and SysId=:syncSYSID)
	if 'SQLCODE {
		return $$$OK
	}
	set rtrn=0
	return $$$ERROR($$$GeneralError,"No matching row")
}

Index IndSysidNs On (SysId, Namespace) [ Unique ];

Storage Default
{
<Data name="SyncTimeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Namespace</Value>
</Value>
<Value name="3">
<Value>SysId</Value>
</Value>
<Value name="4">
<Value>TRN</Value>
</Value>
<Value name="5">
<Value>lTRN</Value>
</Value>
<Value name="6">
<Value>rTRN</Value>
</Value>
</Data>
<DataLocation>^Cache.SyncTimeD</DataLocation>
<DefaultData>SyncTimeDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Cache.SyncTimeD</IdLocation>
<IndexLocation>^Cache.SyncTimeI</IndexLocation>
<StreamLocation>^Cache.SyncTimeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
