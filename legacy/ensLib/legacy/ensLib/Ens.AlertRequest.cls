/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.AlertRequest Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Name of the business host that is sending the alert
Property SourceConfigName As %String(MAXLEN = 128);

/// Text of the alert message
Property AlertText As %String(MAXLEN = "");

/// Field for designating the external destination of this alert message
Property AlertDestination As %String(MAXLEN = "");

/// Time at which the alert was created.
Property AlertTime As Ens.DataType.UTC [ InitialExpression = {$$$timeUTC} ];

/// The session in which the Alert occurred.
Property SessionId As %Integer;

Method %OnNew(initvalue As %RawString) As %Status [ Private ]
{
	Set ..SourceConfigName=$lg($g(initvalue),1)
	Set ..AlertText = $lg($g(initvalue),2)
	Set ..AlertDestination = $lg($g(initvalue),3)
	Set ..SessionId = $get($$$JobSessionId)
	Quit $$$OK
}

Storage Default
{
<Data name="AlertRequestDefaultData">
<Subscript>"AlertRequest"</Subscript>
<Value name="1">
<Value>AlertText</Value>
</Value>
<Value name="2">
<Value>SourceConfigName</Value>
</Value>
<Value name="3">
<Value>AlertDestination</Value>
</Value>
<Value name="4">
<Value>AlertTime</Value>
</Value>
<Value name="5">
<Value>SessionId</Value>
</Value>
</Data>
<DefaultData>AlertRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
