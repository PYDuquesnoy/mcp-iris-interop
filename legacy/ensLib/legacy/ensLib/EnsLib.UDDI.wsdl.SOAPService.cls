/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.UDDI.wsdl.SOAPService Extends %SerialObject [ System = 4 ]
{

Property LocalName As %String;

Property TargetNamespace As %String;

Property HumanName As %String;

Property Description As %String;

Property Ports As list Of EnsLib.UDDI.wsdl.Port;

Property ImplementedBy As %String;

Storage Default
{
<Data name="SOAPServiceState">
<Value name="1">
<Value>LocalName</Value>
</Value>
<Value name="2">
<Value>TargetNamespace</Value>
</Value>
<Value name="3">
<Value>HumanName</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
<Value name="5">
<Value>Ports</Value>
</Value>
<Value name="6">
<Value>ImplementedBy</Value>
</Value>
</Data>
<State>SOAPServiceState</State>
<StreamLocation>^EnsLib.UDDI.wsdl.SOAPServiceS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
