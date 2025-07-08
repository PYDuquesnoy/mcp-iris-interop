/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Control.AppServers Extends (%SerialObject, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Property AppServer As %String(TRUNCATE = 1);

Property Address As %String(TRUNCATE = 1);

Property Port As %Integer;

Property URL As %String(MAXLEN = 255, TRUNCATE = 1);

Property CommunicationStatus As %Boolean;

Property RequestedStatus As %Boolean;

Property CurrentStatus As %Boolean;

Storage Default
{
<Data name="AppServersState">
<Subscript>"WebStress.Control.AppServers"</Subscript>
<Value name="1">
<Value>Address</Value>
</Value>
<Value name="2">
<Value>AppServer</Value>
</Value>
<Value name="3">
<Value>CommunicationStatus</Value>
</Value>
<Value name="4">
<Value>CurrentStatus</Value>
</Value>
<Value name="5">
<Value>Port</Value>
</Value>
<Value name="6">
<Value>RequestedStatus</Value>
</Value>
<Value name="7">
<Value>URL</Value>
</Value>
</Data>
<State>AppServersState</State>
<StreamLocation>^WebStress.Control.AppServersS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
