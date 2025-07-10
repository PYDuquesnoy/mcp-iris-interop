/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated; use Ens.StringContainer
Class Ens.StringRequest Extends Ens.Request [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Property StringValue As %String(MAXLEN = "");

Method %OnNew(initvalue As %String) As %Status
{
	Set ..StringValue=$g(initvalue)
	Quit $$$OK
}

Storage Default
{
<Data name="StringRequestDefaultData">
<Subscript>"StringRequest"</Subscript>
<Value name="1">
<Value>StringValue</Value>
</Value>
</Data>
<DefaultData>StringRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
