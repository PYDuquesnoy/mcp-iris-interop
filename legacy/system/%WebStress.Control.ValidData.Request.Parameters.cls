/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.ValidData.Request.Parameters Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Class As %String(TRUNCATE = 1);

Property Instance As %String(TRUNCATE = 1);

Property Version As %Integer;

Property SavedDate As %Date;

Property SavedTime As %Time;

Storage Default
{
<Data name="ParametersState">
<Subscript>"WebStress.Control.ValidData.Request.Parameters"</Subscript>
<Value name="1">
<Value>Class</Value>
</Value>
<Value name="2">
<Value>Instance</Value>
</Value>
<Value name="3">
<Value>SavedDate</Value>
</Value>
<Value name="4">
<Value>SavedTime</Value>
</Value>
<Value name="5">
<Value>Version</Value>
</Value>
</Data>
<State>ParametersState</State>
<StreamLocation>^WebStress.ControD60.ParametersS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
