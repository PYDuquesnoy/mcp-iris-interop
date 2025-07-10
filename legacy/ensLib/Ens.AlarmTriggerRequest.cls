/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.AlarmTriggerRequest Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Property AlarmHandle As %String;

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	Set ..AlarmHandle = $g(initvalue)
	Quit $$$OK
}

Storage Default
{
<Data name="AlarmTriggerRequestDefaultData">
<Subscript>"AlarmTriggerRequest"</Subscript>
<Value name="1">
<Value>MessageHeaderId</Value>
</Value>
<Value name="2">
<Value>AlarmHandle</Value>
</Value>
</Data>
<DefaultData>AlarmTriggerRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
