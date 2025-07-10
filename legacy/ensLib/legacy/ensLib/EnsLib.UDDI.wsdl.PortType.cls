/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data from WSDL that is needed to map SOAP Service to UDDI Registry.
/// This class conatins data for SOAP PortType
Class EnsLib.UDDI.wsdl.PortType Extends %SerialObject [ System = 4 ]
{

Property LocalName As %String;

Property Namespace As %String;

Storage Default
{
<Data name="PortTypeState">
<Value name="1">
<Value>LocalName</Value>
</Value>
<Value name="2">
<Value>Namespace</Value>
</Value>
</Data>
<State>PortTypeState</State>
<StreamLocation>^EnsLib.UDDI.wsdl.PortTypeS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
