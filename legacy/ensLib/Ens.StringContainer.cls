/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.StringContainer Extends (%Persistent, %XML.Adaptor) [ ClassType = persistent, Inheritance = right, ProcedureBlock, System = 4 ]
{

Property StringValue As %String(MAXLEN = "");

Method %OnNew(initvalue As %String) As %Status
{
	Set ..StringValue=$g(initvalue)
	Quit $$$OK
}

Storage Default
{
<Data name="StringContainerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>StringValue</Value>
</Value>
</Data>
<DataLocation>^Ens.StringContainerD</DataLocation>
<DefaultData>StringContainerDefaultData</DefaultData>
<IdLocation>^Ens.StringContainerD</IdLocation>
<IndexLocation>^Ens.StringContainerI</IndexLocation>
<StreamLocation>^Ens.StringContainerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
