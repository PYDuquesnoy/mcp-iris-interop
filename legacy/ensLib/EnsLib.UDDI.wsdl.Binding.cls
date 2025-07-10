/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data from WSDL that is needed to map SOAP Service to UDDI Registry.
/// This class conatins data for SOAP Binding
Class EnsLib.UDDI.wsdl.Binding Extends %SerialObject [ System = 4 ]
{

/// Refers to LocalName of PortType
Property PortType As %String;

Property LocalName As %String;

Property Namespace As %String;

Property SOAPBinding As %Boolean;

Property SOAPTransportURI As %String;

Property HTTPBinding As %Boolean;

Storage Default
{
<Data name="BindingState">
<Value name="1">
<Value>PortType</Value>
</Value>
<Value name="2">
<Value>LocalName</Value>
</Value>
<Value name="3">
<Value>Namespace</Value>
</Value>
<Value name="4">
<Value>SOAPBindingURI</Value>
</Value>
<Value name="5">
<Value>SOAPTransportURI</Value>
</Value>
<Value name="6">
<Value>HTTPBindingURI</Value>
</Value>
<Value name="7">
<Value>SOAPBinding</Value>
</Value>
<Value name="8">
<Value>HTTPBinding</Value>
</Value>
</Data>
<State>BindingState</State>
<StreamLocation>^EnsLib.UDDI.wsdl.BindingS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
