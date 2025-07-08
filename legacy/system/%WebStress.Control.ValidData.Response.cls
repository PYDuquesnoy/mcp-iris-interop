/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.ValidData.Response Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property OK As %Boolean;

Property Generators As list Of %WebStress.Control.ValidData.Response.Generators;

Storage Default
{
<Data name="ResponseState">
<Subscript>"WebStress.Control.ValidData.Response"</Subscript>
<Value name="1">
<Value>Generators</Value>
</Value>
<Value name="2">
<Value>OK</Value>
</Value>
</Data>
<State>ResponseState</State>
<StreamLocation>^WebStress.ControlA49.ResponseS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
