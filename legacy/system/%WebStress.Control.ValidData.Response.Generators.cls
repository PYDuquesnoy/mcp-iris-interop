/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.ValidData.Response.Generators Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Generator As %String(TRUNCATE = 1);

Property OK As %Boolean;

Property Parameters As list Of %WebStress.Control.ValidData.Response.Generators.Data;

Storage Default
{
<Data name="GeneratorsState">
<Subscript>"WebStress.Control.ValidData.Response.Generators"</Subscript>
<Value name="1">
<Value>Generator</Value>
</Value>
<Value name="2">
<Value>OK</Value>
</Value>
<Value name="3">
<Value>Parameters</Value>
</Value>
</Data>
<State>GeneratorsState</State>
<StreamLocation>^WebStress.ControDC6.GeneratorsS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
