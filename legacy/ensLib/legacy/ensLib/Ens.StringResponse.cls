/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated; use Ens.StringContainer
Class Ens.StringResponse Extends Ens.Response [ ClassType = persistent, ProcedureBlock, System = 4 ]
{

Property StringValue As %String(MAXLEN = "");

Method %OnNew(initvalue As %String) As %Status
{
	Set ..StringValue=$g(initvalue)
	Quit $$$OK
}

Storage Default
{
<Data name="StringResponseDefaultData">
<Subscript>"StringResponse"</Subscript>
<Value name="1">
<Value>StringValue</Value>
</Value>
</Data>
<DefaultData>StringResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
