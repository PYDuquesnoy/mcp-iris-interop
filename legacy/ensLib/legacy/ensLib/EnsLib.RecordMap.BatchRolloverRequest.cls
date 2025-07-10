/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RecordMap.BatchRolloverRequest Extends (%Persistent, %XML.Adaptor, Ens.Request) [ System = 4 ]
{

Storage Default
{
<Data name="BatchRolloverRequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^EnsLib.RecMap.BatchRollReqD</DataLocation>
<DefaultData>BatchRolloverRequestDefaultData</DefaultData>
<IdLocation>^EnsLib.RecMap.BatchRollReqD</IdLocation>
<IndexLocation>^EnsLib.RecMap.BatchRollReqI</IndexLocation>
<StreamLocation>^EnsLib.RecMap.BatchRollReqS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
