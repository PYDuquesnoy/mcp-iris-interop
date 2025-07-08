/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.Processes Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Script As %String(TRUNCATE = 1);

Property Generator As %String(TRUNCATE = 1);

Property WebServer As %String(TRUNCATE = 1);

Property WebServerPort As %Integer [ InitialExpression = 80 ];

Property RequestedProcesses As %Integer;

Property StartedProcesses As %Integer;

Storage Default
{
<Data name="ProcessesState">
<Subscript>"WebStress.Control.Processes"</Subscript>
<Value name="1">
<Value>Generator</Value>
</Value>
<Value name="2">
<Value>RequestedProcesses</Value>
</Value>
<Value name="3">
<Value>Script</Value>
</Value>
<Value name="4">
<Value>StartedProcesses</Value>
</Value>
<Value name="5">
<Value>WebServer</Value>
</Value>
<Value name="6">
<Value>WebServerPort</Value>
</Value>
</Data>
<State>ProcessesState</State>
<StreamLocation>^WebStress.Control.ProcessesS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
