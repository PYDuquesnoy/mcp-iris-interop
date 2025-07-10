/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.wsdl.Port Extends %SerialObject [ System = 4 ]
{

Property BindingLocalName As %String;

Property PortTypeLocalName As %String;

Property LocationURI As %String;

Property LocationURIType As %String;

Storage Default
{
<Data name="PortState">
<Value name="1">
<Value>BindingLocalName</Value>
</Value>
<Value name="2">
<Value>PortTypeLocalName</Value>
</Value>
<Value name="3">
<Value>LocationURI</Value>
</Value>
<Value name="4">
<Value>LocationURIType</Value>
</Value>
</Data>
<State>PortState</State>
<StreamLocation>^EnsLib.UDDI.wsdl.PortS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
