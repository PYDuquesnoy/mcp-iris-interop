/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RecordMap.BatchResponse Extends (%Persistent, %XML.Adaptor, Ens.Response) [ System = 4 ]
{

Property BatchClass As Ens.DataType.Class;

Property BatchId As %String(MAXLEN = "");

Property RecordCount As %Integer;

Storage Default
{
<Data name="BatchResponseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>BatchClass</Value>
</Value>
<Value name="3">
<Value>BatchId</Value>
</Value>
<Value name="4">
<Value>RecordCount</Value>
</Value>
</Data>
<DataLocation>^EnsLib.RecMap.BatchResponseD</DataLocation>
<DefaultData>BatchResponseDefaultData</DefaultData>
<IdLocation>^EnsLib.RecMap.BatchResponseD</IdLocation>
<IndexLocation>^EnsLib.RecMap.BatchResponseI</IndexLocation>
<StreamLocation>^EnsLib.RecMap.BatchResponseS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
