/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Having this class that maps onto the data structure for the system log entries allows us
/// to use the SQL projection to query the log. The log entries are inserted without using
/// this class in case objects are not available at that time.
Class %Library.SysLogTable Extends %Library.Persistent [ Not ProcedureBlock, System = 3 ]
{

Property Category As %String(MAXLEN = 24);

Property LogLevel As %Integer;

Property Message As %String(MAXLEN = 256);

Property Pid As %String(MAXLEN = 16);

Property Namespace As %String(MAXLEN = 32);

Property Routine As %String(MAXLEN = 32);

Property TimeAdded As %TimeStamp;

Property Tag As %String(MAXLEN = 16);

Property SessionId As %String(MAXLEN = 16);

Storage Default
{
<Data name="SysLogTableDefaultData">
<Value name="1">
<Value>LogLevel</Value>
</Value>
<Value name="2">
<Value>Category</Value>
</Value>
<Value name="3">
<Value>Message</Value>
</Value>
<Value name="4">
<Value>Pid</Value>
</Value>
<Value name="5">
<Value>Namespace</Value>
</Value>
<Value name="6">
<Value>TimeAdded</Value>
</Value>
<Value name="7">
<Value>Routine</Value>
</Value>
<Value name="8">
<Value>Tag</Value>
</Value>
<Value name="9">
<Value>SessionId</Value>
</Value>
<Value name="10">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^|"%SYS"|ISCLOG("Data")</DataLocation>
<DefaultData>SysLogTableDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^|"%SYS"|ISCLOG("Data")</IdLocation>
<IndexLocation>^|"%SYS"|ISCLOG("Index")</IndexLocation>
<StreamLocation>^%Library.SysLogTableS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
