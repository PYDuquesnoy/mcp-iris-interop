/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Dataset.Field Extends %SerialObject [ System = 4 ]
{

Property Name As %String(MAXLEN = 200);

Property DisplayName As %String(MAXLEN = 200);

Property Spec As %String(MAXLEN = 200);

Property DataType As %DeepSee.PMML.Datatype.DataType;

Property OpType As %DeepSee.PMML.Datatype.OpType;

Method %OnNew(pName As %String = "", pSpec As %String = "", pDataType As %String = "", pOpType As %String = "", pDisplayName As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	set ..Name = pName
	set ..Spec = pSpec
	set ..DataType = pDataType
	set ..OpType = pOpType
	set ..DisplayName = pDisplayName
	Quit $$$OK
}

Storage Default
{
<Data name="DatasetFieldState">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>Spec</Value>
</Value>
<Value name="3">
<Value>DataType</Value>
</Value>
<Value name="4">
<Value>OpType</Value>
</Value>
<Value name="5">
<Value>DisplayName</Value>
</Value>
</Data>
<State>DatasetFieldState</State>
<StreamLocation>^%DeepSee.PMML.DatasetFieldS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
