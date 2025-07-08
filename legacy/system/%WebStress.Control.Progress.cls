/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.Progress Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property Time As %String(TRUNCATE = 1);

Property Description As %String(MAXLEN = 255, TRUNCATE = 1);

Storage Default
{
<Data name="ProgressState">
<Subscript>"WebStress.Control.Progress"</Subscript>
<Value name="1">
<Value>Description</Value>
</Value>
<Value name="2">
<Value>Time</Value>
</Value>
</Data>
<State>ProgressState</State>
<StreamLocation>^WebStress.Control.ProgressS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
