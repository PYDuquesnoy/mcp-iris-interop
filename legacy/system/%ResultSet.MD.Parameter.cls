/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ResultSet.MD.Parameter Extends %SerialObject [ StorageStrategy = rsmdParameter, System = 2 ]
{

Property ODBCType As %Integer;

Property precision As %Integer;

Property scale As %Integer;

Property isNullable As %Boolean;

Property label As %String(MAXLEN = 255);

Property clientType As %Integer;

Storage rsmdParameter
{
<Data name="ParameterState">
<Value name="1">
<Value>ODBCType</Value>
</Value>
<Value name="2">
<Value>precision</Value>
</Value>
<Value name="3">
<Value>scale</Value>
</Value>
<Value name="4">
<Value>isNullable</Value>
</Value>
<Value name="5">
<Value>label</Value>
</Value>
<Value name="6">
<Value>clientType</Value>
</Value>
</Data>
<State>ParameterState</State>
<StreamLocation>^%ResultSet.MetaData.ParameterS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
