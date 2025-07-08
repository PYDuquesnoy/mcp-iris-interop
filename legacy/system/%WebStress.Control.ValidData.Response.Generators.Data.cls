/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.ValidData.Response.Generators.Data Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Class As %String(TRUNCATE = 1);

Property Instance As %String(TRUNCATE = 1);

Property ControlVersion As %Integer;

Property ControlSavedDate As %Date;

Property ControlSavedTime As %Time;

Property GeneratorVersion As %Integer;

Property GeneratorSavedDate As %Date;

Property GeneratorSavedTime As %Time;

Property OK As %Boolean;

Storage Default
{
<Data name="DataState">
<Subscript>"WebStress.Control.ValidData.Response.Generators.Data"</Subscript>
<Value name="1">
<Value>Class</Value>
</Value>
<Value name="2">
<Value>ControllerSavedDate</Value>
</Value>
<Value name="3">
<Value>ControllerSavedTime</Value>
</Value>
<Value name="4">
<Value>ControllerVersion</Value>
</Value>
<Value name="5">
<Value>GeneratorSavedDate</Value>
</Value>
<Value name="6">
<Value>GeneratorSavedTime</Value>
</Value>
<Value name="7">
<Value>GeneratorVersion</Value>
</Value>
<Value name="8">
<Value>Instance</Value>
</Value>
<Value name="9">
<Value>OK</Value>
</Value>
<Value name="10">
<Value>ControlSavedDate</Value>
</Value>
<Value name="11">
<Value>ControlSavedTime</Value>
</Value>
<Value name="12">
<Value>ControlVersion</Value>
</Value>
</Data>
<State>DataState</State>
<StreamLocation>^WebStress.Control.Val120E.DataS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
