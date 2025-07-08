/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.GeneratorStatus Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Running As %Integer(DISPLAYLIST = ",Running,Not running", VALUELIST = ",0,1");

Property Status As %Integer;

Property GenSystemID As %String(MAXLEN = 255);

Storage Default
{
<Data name="GeneratorStatusState">
<Subscript>"WebStress.Control.GeneratorStatus"</Subscript>
<Value name="1">
<Value>Running</Value>
</Value>
<Value name="2">
<Value>Status</Value>
</Value>
<Value name="3">
<Value>GenSystemID</Value>
</Value>
</Data>
<State>GeneratorStatusState</State>
<StreamLocation>^WebStress.C6B1.GeneratorSta62BS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
